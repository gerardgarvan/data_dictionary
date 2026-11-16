"""
Core logic for the Phase 15 new-source intake QC workbook (D-22, A6).

Reads:   exchange/new_source_guard.csv, header_inventory_new.csv, header_matrix_new.csv,
         new_rowcounts.csv, new_one_to_one.csv, new_overlap.csv, new_type_changes.csv,
         new_nonascii.csv; docs/new_source_header_variants.csv (VARIANTS)
Writes:  qc/new_source_intake.xlsx (exact counts; lives on P:, not in git)
Also:    privacy_safe_summary() -> text lines with every count 1..10 written <11.
Sheets:  KEY | GUARD | ROWCOUNTS | ONE_TO_ONE | OVERLAP | HEADER_MATRIX
         | HEADER_INVENTORY | TYPE_CHANGES | VARIANTS | NONASCII
"""

from __future__ import annotations

import csv
import logging
import re
from pathlib import Path

from openpyxl import Workbook, load_workbook

from pdd.xlsx_style import style_sheet, write_table

SHEET_ORDER = [
    "KEY",
    "GUARD",
    "ROWCOUNTS",
    "ONE_TO_ONE",
    "OVERLAP",
    "HEADER_MATRIX",
    "HEADER_INVENTORY",
    "TYPE_CHANGES",
    "VARIANTS",
    "NONASCII",
]

SHEET_SOURCES: dict[str, str] = {
    "GUARD": "new_source_guard.csv",
    "ROWCOUNTS": "new_rowcounts.csv",
    "ONE_TO_ONE": "new_one_to_one.csv",
    "OVERLAP": "new_overlap.csv",
    "HEADER_MATRIX": "header_matrix_new.csv",
    "HEADER_INVENTORY": "header_inventory_new.csv",
    "TYPE_CHANGES": "new_type_changes.csv",
    "VARIANTS": "new_source_header_variants.csv",
    "NONASCII": "new_nonascii.csv",
}

# Exchange contract: file -> ordered columns (SAS plans 15a/15b/15c write exactly these).
CONTRACT: dict[str, list[str]] = {
    "new_source_guard.csv": ["s_code", "filename", "sha256", "baseline_status"],
    "header_inventory_new.csv": [
        "s_code", "col_order", "col_name", "col_type", "col_len",
        "original_header", "original_header_trunc",
    ],
    "header_matrix_new.csv": ["col_name", "src_s21", "src_s22", "src_s23"],
    "new_rowcounts.csv": [
        "s_code", "filename", "src_encoding", "expected_rows",
        "raw_data_lines", "n_imported", "status",
    ],
    "new_one_to_one.csv": [
        "s_code", "n_rows", "n_distinct_psid", "n_blank_psid", "n_distinct_mrn",
        "n_distinct_enc", "n_enc_multi_case", "status",
    ],
    "new_overlap.csv": ["check_type", "file_a", "file_b", "n_shared", "status"],
    "new_type_changes.csv": [
        "norm_key", "new_s_code", "new_sas_name", "new_type", "new_length",
        "old_s_code", "old_sas_name", "old_type", "old_length",
    ],
    "new_nonascii.csv": ["s_code", "sas_name", "n_nonascii_cells"],
}

# Integer columns per exchange file (schema type `int`).
INT_COLUMNS_BY_FILE: dict[str, list[str]] = {
    "header_inventory_new.csv": ["col_order", "col_len", "original_header_trunc"],
    "new_rowcounts.csv": ["expected_rows", "raw_data_lines", "n_imported"],
    "new_one_to_one.csv": [
        "n_rows", "n_distinct_psid", "n_blank_psid", "n_distinct_mrn",
        "n_distinct_enc", "n_enc_multi_case",
    ],
    "new_overlap.csv": ["n_shared"],
    "new_type_changes.csv": ["new_length", "old_length"],
    "new_nonascii.csv": ["n_nonascii_cells"],
}

VARIANTS_COLUMNS = [
    "file_codes", "new_header", "new_type", "older_header", "older_source_codes",
    "older_type", "variant_kind", "note", "status",
]

REQUIRED_COLUMNS: dict[str, list[str]] = {
    sheet: CONTRACT[fname] for sheet, fname in SHEET_SOURCES.items() if fname in CONTRACT
}
REQUIRED_COLUMNS["VARIANTS"] = VARIANTS_COLUMNS

INT_COLUMNS: dict[str, frozenset[str]] = {
    sheet: frozenset(INT_COLUMNS_BY_FILE.get(fname, [])) for sheet, fname in SHEET_SOURCES.items()
}

_SCODE_RE = re.compile(r"(?<![A-Za-z0-9])s\d{2}(?![A-Za-z0-9])", re.IGNORECASE)
_PLAIN_RE = re.compile(r"^[A-Za-z0-9_]{1,12}$")


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Return (fieldnames, rows); fieldnames is non-empty even for header-only files."""
    with path.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)
        headers = list(reader.fieldnames or [])
    return headers, rows


def assert_input(sheet_name: str, headers: list[str], rows: list) -> None:
    """Raise ValueError naming missing required columns."""
    missing = [c for c in REQUIRED_COLUMNS.get(sheet_name, []) if c not in headers]
    if missing:
        raise ValueError(f"{sheet_name} missing required columns: {', '.join(missing)}")


def mask_small_count(val: object) -> str:
    """Counts 1..10 -> '<11'; 0 and >=11 unchanged; blanks and non-numeric text unchanged."""
    s = str(val).strip() if val is not None else ""
    if not re.fullmatch(r"-?\d+", s):
        return "" if val is None else str(val)
    n = int(s)
    return "<11" if 1 <= n <= 10 else str(n)


def _scode(val: str) -> str:
    """Reduce a file reference to an s_code token; never emit filename text."""
    m = _SCODE_RE.search(val or "")
    if m:
        return m.group(0).lower()
    if _PLAIN_RE.match(val or ""):
        return val
    return "file"


def _to_int(val: object) -> int | None:
    try:
        return int(str(val).strip())
    except (ValueError, TypeError):
        return None


def _gate(label: str, rows: list[dict[str, str]], ok) -> str:
    if not rows:
        return f"GATE {label}: NO DATA (PENDING SAS RUN)"
    return f"GATE {label}: {'PASS' if all(ok(r) for r in rows) else 'STOP (PENDING DECISION)'}"


def privacy_safe_summary(
    sheets: dict[str, tuple[list[str], list[dict[str, str]]]],
) -> list[str]:
    """Text summary safe to paste into git: counts 1..10 shown as <11, no hashes/headers/filenames."""
    def rows_of(name: str) -> list[dict[str, str]]:
        return sheets.get(name, ([], []))[1]

    lines: list[str] = []
    for r in rows_of("GUARD"):
        lines.append(f"GUARD {r.get('s_code', '')} baseline_status={r.get('baseline_status', '')}")
    for r in rows_of("ROWCOUNTS"):
        lines.append(
            f"ROWCOUNTS {r.get('s_code', '')} expected_rows={mask_small_count(r.get('expected_rows'))} "
            f"raw_data_lines={mask_small_count(r.get('raw_data_lines'))} "
            f"n_imported={mask_small_count(r.get('n_imported'))} status={r.get('status', '')}"
        )
    for r in rows_of("ONE_TO_ONE"):
        parts = " ".join(f"{c}={mask_small_count(r.get(c))}" for c in INT_COLUMNS_BY_FILE["new_one_to_one.csv"])
        lines.append(f"ONE_TO_ONE {r.get('s_code', '')} {parts} status={r.get('status', '')}")
    for r in rows_of("OVERLAP"):
        lines.append(
            f"OVERLAP {r.get('check_type', '')} {_scode(r.get('file_a', ''))} {_scode(r.get('file_b', ''))} "
            f"n_shared={mask_small_count(r.get('n_shared'))} status={r.get('status', '')}"
        )
    tc = rows_of("TYPE_CHANGES")
    if "TYPE_CHANGES" in sheets:
        lines.append(f"TYPE_CHANGES n_rows={mask_small_count(len(tc))}")
    by_s: dict[str, list[int]] = {}
    for r in rows_of("NONASCII"):
        by_s.setdefault(r.get("s_code", ""), []).append(_to_int(r.get("n_nonascii_cells")) or 0)
    for s, vals in sorted(by_s.items()):
        lines.append(
            f"NONASCII {s} n_columns={mask_small_count(len(vals))} n_cells={mask_small_count(sum(vals))}"
        )

    def shared_zero(r: dict[str, str]) -> bool:
        return _to_int(r.get("n_shared")) == 0

    ov = rows_of("OVERLAP")
    lines.append(_gate(
        "PDD-D-29 item 3", [r for r in ov if r.get("check_type") == "PAIRWISE_NEW"], shared_zero))
    lines.append(_gate(
        "OLD20_UNION", [r for r in ov if r.get("check_type") == "OLD20_UNION"], shared_zero))
    lines.append(_gate("1:1 (NEW-04)", rows_of("ONE_TO_ONE"), lambda r: r.get("status") == "PASS"))
    return lines


def _key_rows() -> list[list[str]]:
    """Documentation rows for the KEY sheet."""
    return [
        ["Section", "Item", "Description"],
        ["Sheet", "GUARD", "One row per new source file: s_code, filename, sha256, baseline_status "
         "(MATCH | DRIFT | PROPOSED | SEEDED). NEW-01 approval gate."],
        ["Sheet", "ROWCOUNTS", "Expected vs raw data lines vs imported rows per file; "
         "status MATCH | MATCH_RAWDIFF | MISMATCH."],
        ["Sheet", "ONE_TO_ONE", "NEW-04 gate: one row per PRECEDE_STUDY_ID per file; status PASS | FAIL."],
        ["Sheet", "OVERLAP", "Shared normalized case IDs. check_type PAIRWISE_NEW (PDD-D-29 item 3), "
         "SPINE, OLD20_UNION (reopens PDD-D-25 if SHARED), SHARED_COL_CONFLICT. "
         "status ZERO | SHARED | NOT_APPLICABLE."],
        ["Sheet", "HEADER_MATRIX", "Column presence per new file (src_s21, src_s22, src_s23)."],
        ["Sheet", "HEADER_INVENTORY", "Per-file column order, SAS name, type, length, original header."],
        ["Sheet", "TYPE_CHANGES", "Columns whose type or length differs from the older 20 sources."],
        ["Sheet", "VARIANTS", "Header variants (docs/new_source_header_variants.csv) for review."],
        ["Sheet", "NONASCII", "Count of cells containing non-ASCII bytes per column (no values)."],
        ["Gate", "NEW-01", "Guard baseline_status DRIFT or PROPOSED needs Gerard approval before import."],
        ["Gate", "NEW-04", "Every ONE_TO_ONE status must be PASS."],
        ["Gate", "PDD-D-29 item 3", "All PAIRWISE_NEW n_shared must be 0; otherwise PENDING DECISION."],
        ["Gate", "OLD20_UNION", "Any SHARED row reopens PDD-D-25; PENDING DECISION."],
        ["Code map", "s21 / s22 / s23", "s21=2023, s22=2024, s23=2025. Probe unit numbers are not s-codes."],
        ["Note", "MRN overlap", "MRN non-overlap is expected across key eras (PDD-D-26) "
         "and is not evidence of distinct patients."],
        ["Note", "Privacy", "This workbook shows exact counts and stays on P:. "
         "The text summary masks counts 1..10 as <11 for git."],
    ]


def write_workbook(
    sheets: dict[str, tuple[list[str], list]],
    out_path: Path,
) -> None:
    """Write sheets in SHEET_ORDER; KEY from _key_rows(); absent sheet -> '(no data)'.

    sheets maps sheet name to (headers, rows) where rows are list[list] or list[dict].
    """
    wb = Workbook()
    wb.remove(wb.active)  # type: ignore[arg-type]
    for name in SHEET_ORDER:
        ws = wb.create_sheet(name)
        if name == "KEY":
            key = _key_rows()
            write_table(ws, key[0], key[1:])
        else:
            headers, rows = sheets.get(name, ([], []))
            if not headers:
                ws.append(["(no data)"])
            else:
                assert_input(name, headers, rows)
                data = [[r.get(h, "") for h in headers] if isinstance(r, dict) else list(r) for r in rows]
                ints = INT_COLUMNS.get(name, frozenset())
                write_table(ws, headers, data, int_cols=frozenset(i for i, h in enumerate(headers) if h in ints))
        style_sheet(ws)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    wb.save(out_path)
    logging.info("Saved %s", out_path)


def verify_workbook(path: Path, expected_data_rows: dict[str, int]) -> None:
    """Re-open; raise ValueError on wrong sheet order or data-row mismatch."""
    wb = load_workbook(path, read_only=True)
    try:
        if wb.sheetnames != SHEET_ORDER:
            raise ValueError(f"sheet order mismatch: {wb.sheetnames} != {SHEET_ORDER}")
        for name, exp in expected_data_rows.items():
            if name not in wb.sheetnames:
                raise ValueError(f"sheet '{name}' not found in workbook")
            actual = wb[name].max_row - 1
            if actual != exp:
                raise ValueError(f"sheet {name}: {actual} data rows != expected {exp}")
    finally:
        wb.close()
