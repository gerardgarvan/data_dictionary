"""
Core logic for the PCNR QC workbook (D-16b, D-22).

Reads:   exchange/pcnr_gapfill.csv
         exchange/pcnr_spine_coverage.csv
         exchange/pcnr_conflicts_summary.csv
         exchange/pcnr_conflicts_summary_class.csv
         exchange/pcnr_conflicts_detail.csv
         exchange/pcnr_typecheck.csv
         exchange/pcnr_typefail.csv
         exchange/pcnr_all_missing.csv      (optional)
         exchange/pcnr_all_missing_src.csv  (optional)
Writes:  qc/pcnr_qc.xlsx
Sheets:  KEY | GAPFILL | SPINE_COVERAGE | CONFLICT_SUMMARY | CONFLICT_CLASS_SUMMARY
         | CONFLICT_DETAIL | TYPECHECK | TYPEFAIL | ALL_MISSING | ALL_MISSING_SRC
"""

from __future__ import annotations

import csv
import logging
import re
from collections import defaultdict
from pathlib import Path

from openpyxl import Workbook, load_workbook

from pdd.xlsx_style import style_sheet, write_table

CONFLICT_DETAIL_CAP = 5000

SHEET_ORDER = [
    "KEY",
    "GAPFILL",
    "SPINE_COVERAGE",
    "CONFLICT_SUMMARY",
    "CONFLICT_CLASS_SUMMARY",
    "CONFLICT_DETAIL",
    "TYPECHECK",
    "TYPEFAIL",
    "ALL_MISSING",
    "ALL_MISSING_SRC",
]

# Required columns per non-KEY sheet (item 18).
# For CONFLICT_CLASS_SUMMARY these validate the *source* CSV columns, not the aggregated sheet.
REQUIRED_COLUMNS: dict[str, list[str]] = {
    "GAPFILL": ["pcnr_name", "n_spine", "n_gapfilled", "n_missing"],
    "SPINE_COVERAGE": ["s_code", "n_keys", "n_keys_not_in_spine", "n_blank_keys", "n_dup_keys"],
    "CONFLICT_SUMMARY": ["pcnr_name", "conflict_type", "n_conflict_events", "n_conflict_cells"],
    "CONFLICT_CLASS_SUMMARY": [
        "pcnr_name", "conflict_type", "conflict_class", "n_conflict_events", "n_conflict_cells",
    ],
    "CONFLICT_DETAIL": [
        "norm_psid", "pcnr_name", "conflict_type", "conflict_class",
        "winning_s_code", "winning_value",
        "candidate_s_code", "candidate_value", "value_type",
    ],
    "TYPECHECK": ["pcnr_name", "resolved_type", "out_length", "n_char_sources", "n_failures", "n_null_as_missing"],
    "TYPEFAIL": ["pcnr_name", "s_code", "raw_value", "n"],
    "ALL_MISSING": ["pcnr_name", "s_codes_contributing", "n_missing_spine", "n_spine"],
    "ALL_MISSING_SRC": ["pcnr_name", "s_code", "n_nonmissing"],
}

# Fixed integer column names (item 18).
_NUMERIC_INT_COLS: frozenset[str] = frozenset([
    "n_conflict_cells",
    "n_conflict_events",
    "n_keys",
    "n_keys_not_in_spine",
    "n_blank_keys",
    "n_dup_keys",
    "n_char_sources",
    "n_parse_failures",
    "n_failures",
    "n_null_as_missing",
    "n_spine",
    "n_gapfilled",
    "n_missing",
    "n_missing_spine",
    "n_nonmissing",
    "n_variables",
    "n_cells",
    "n",
])

_N_FILLED_RE = re.compile(r"^n_filled_")


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Return (fieldnames, rows).  fieldnames is non-empty even for header-only files."""
    with path.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)
        headers = list(reader.fieldnames or [])
    return headers, rows


def _int_col_indices(headers: list[str]) -> frozenset[int]:
    """Return 0-based indices of integer columns: fixed set OR matching n_filled_* (item 18)."""
    return frozenset(
        i
        for i, h in enumerate(headers)
        if h in _NUMERIC_INT_COLS or _N_FILLED_RE.match(h)
    )


def _build_conflict_class_summary(
    rows: list[dict[str, str]],
) -> tuple[list[str], list[list]]:
    """Aggregate source CSV rows into CONFLICT_CLASS_SUMMARY sheet content.

    Source CSV columns: pcnr_name, conflict_type, conflict_class,
                        n_conflict_events, n_conflict_cells.
    Output sheet columns: conflict_class, n_variables, n_cells, top_5_vars_by_cells.
    Includes a TOTALS row where n_cells sums to total conflicts (97,194).
    """
    # Aggregate by conflict_class
    class_n_vars: dict[str, set[str]] = defaultdict(set)
    class_n_cells: dict[str, int] = defaultdict(int)
    class_var_cells: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    for r in rows:
        cls = r.get("conflict_class", "")
        name = r.get("pcnr_name", "")
        try:
            cells = int(r.get("n_conflict_cells", 0) or 0)
        except (ValueError, TypeError):
            cells = 0
        class_n_vars[cls].add(name)
        class_n_cells[cls] += cells
        class_var_cells[cls][name] += cells

    headers = ["conflict_class", "n_variables", "n_cells", "top_5_vars_by_cells"]
    data: list[list] = []

    total_cells = 0
    total_vars: set[str] = set()

    for cls in sorted(class_n_vars.keys()):
        n_vars = len(class_n_vars[cls])
        n_cells = class_n_cells[cls]
        top5 = ", ".join(
            v for v, _ in sorted(
                class_var_cells[cls].items(), key=lambda kv: kv[1], reverse=True
            )[:5]
        )
        data.append([cls, n_vars, n_cells, top5])
        total_cells += n_cells
        total_vars.update(class_n_vars[cls])

    # Totals row
    data.append(["TOTAL", len(total_vars), total_cells, ""])

    return headers, data


def _key_rows() -> list[list[str]]:
    """Documentation rows for the KEY sheet."""
    return [
        ["Rule", "Item", "Description"],
        # Sheet purposes
        ["Sheet", "GAPFILL",
         "One row per PCNR_ variable. Counts: n_spine (from spine), n_gapfilled (filled "
         "from non-spine source), n_missing (still missing after gap-fill). "
         "One n_filled_<s_code> column per contributing source."],
        ["Sheet", "SPINE_COVERAGE",
         "One row per source file (s_code). Key matching counts: n_keys (total NORM_PSID "
         "values), n_keys_not_in_spine, n_blank_keys, n_dup_keys."],
        ["Sheet", "CONFLICT_SUMMARY",
         "One row per (pcnr_name, conflict_type) combination. "
         "n_conflict_events = number of disagreements (one per patient x variable pair that differs). "
         "n_conflict_cells = distinct patient x variable pairs with a conflict."],
        ["Sheet", "CONFLICT_CLASS_SUMMARY",
         "One row per conflict_class. Aggregated from pcnr_conflicts_summary_class.csv. "
         "Columns: conflict_class, n_variables (distinct pcnr_names), n_cells (sum of "
         "n_conflict_cells), top_5_vars_by_cells (comma-joined top 5 pcnr_names by n_cells). "
         "Includes a TOTAL row. n_cells across all data rows sums to total conflicts (97,194)."],
        ["Sheet", "CONFLICT_DETAIL",
         f"One row per conflicting cell. Capped at {CONFLICT_DETAIL_CAP} rows in this workbook. "
         f"Full table is pdd.qc_pcnr_conflicts on P:. "
         "Each row shows the winning value and the losing candidate value."],
        ["Sheet", "TYPECHECK",
         "One row per pcnr_name with a type conflict. "
         "type resolution = N8 when all values parse via input(strip(val), best32.) else C. "
         "Columns: pcnr_name, resolved_type, out_length, n_char_sources, n_failures, n_null_as_missing."],
        ["Sheet", "TYPEFAIL",
         "One row per (pcnr_name, s_code, raw_value) combination for values that failed "
         "numeric parse during type resolution. Shows n (count of occurrences)."],
        ["Sheet", "ALL_MISSING",
         "One row per PCNR_ variable that is entirely missing across all 41,150 spine rows. "
         "Columns: pcnr_name, s_codes_contributing (space-delimited), n_missing_spine, n_spine. "
         "Present only when at least one all-missing variable exists; sheet shows (no data) otherwise."],
        ["Sheet", "ALL_MISSING_SRC",
         "One row per (pcnr_name, s_code) for all-missing PCNR_ variables. "
         "n_nonmissing = count of non-missing values in the source dataset (always 0 for truly "
         "all-missing variables). Companion to ALL_MISSING."],
        # Conflict types (D-15)
        ["conflict_type", "SPINE_VS_SOURCE",
         "Spine is non-missing AND a non-spine source is non-missing AND they disagree. "
         "Spine value wins. Recorded for audit."],
        ["conflict_type", "SOURCE_VS_SOURCE",
         "Spine is missing AND 2+ non-spine sources are non-missing AND they disagree. "
         "Highest-ranked source (lowest rank in docs/pcnr_source_priority.csv) wins."],
        # Provenance scope (item 14, D-16)
        ["Provenance", "pdd.qc_pcnr_provenance",
         "Cell-level provenance table on P: (not exported to xlsx). "
         "Contains one row per gap-filled cell ONLY for variables with 2+ contributing sources. "
         "Spine-origin cells are NOT listed in pdd.qc_pcnr_provenance — they are the default. "
         "Only gap-filled cells for 2+-source variables appear there."],
        ["Provenance", "pdd.pcnr",
         "Final analytic dataset: 41,150 rows (one per spine patient), "
         "1,297 PCNR_ columns + NORM_PSID. No PCNR_<var>_SRC columns (D-16). "
         "D-24: ENCRYPTED_MRN and ENCRYPTED_ENCOUNTER are linkage keys (status=LINKAGE_ONLY) "
         "and are excluded from PCNR_ output. PCNR variable count: 1299 -> 1297."],
        # Type resolution
        ["Type", "N8 vs C",
         "N8 if every non-missing source value parses as numeric (literal NULL treated as "
         "missing per D-02b); otherwise C."],
        # conflict_class values (Item 1)
        ["conflict_class", "PLACEHOLDER",
         "Either the candidate_value or the winning_value is one of: ?, NULL, N/A, UNKNOWN "
         "(case-insensitive, stripped). Checked first."],
        ["conflict_class", "CODING_EQUIV",
         "The (pcnr_name, value_a, value_b) pair appears in docs/pcnr_value_equiv.csv "
         "(order-insensitive). Known coding synonyms (e.g. FEMALE/F, MALE/M)."],
        ["conflict_class", "TOPCODE",
         "AGE variable where candidate_value='89' and winning_value > 89. "
         "Top-coded value (89=highest reportable) vs the actual higher value. "
         "Restricted to variables whose pcnr_name contains 'AGE' (case-insensitive)."],
        ["conflict_class", "NUMERIC_CLOSE",
         "Both values parse as numeric and abs(a-b)/max(abs(a),abs(b)) <= 0.01 (within 1%)."],
        ["conflict_class", "REAL",
         "All other conflicts. Genuine data disagreement requiring review."],
        # Row cap note
        ["Cap", "CONFLICT_DETAIL",
         f"CONFLICT_DETAIL is capped at {CONFLICT_DETAIL_CAP} data rows in this workbook. "
         "The SAS step caps the export at that limit before writing the CSV. "
         "If the input CSV exceeds this cap, write_pcnr_qc.py raises an error (not silent truncation)."],
    ]


def assert_input(
    sheet_name: str,
    headers: list[str],
    rows: list,
) -> None:
    """Validate required columns and (for CONFLICT_DETAIL) row cap.

    Raises ValueError listing missing columns, or if CONFLICT_DETAIL exceeds cap (item 18).
    """
    if sheet_name in REQUIRED_COLUMNS:
        missing = [c for c in REQUIRED_COLUMNS[sheet_name] if c not in headers]
        if missing:
            raise ValueError(
                f"{sheet_name} missing required columns: {', '.join(missing)}"
            )
    if sheet_name == "CONFLICT_DETAIL" and len(rows) > CONFLICT_DETAIL_CAP:
        raise ValueError(
            f"CONFLICT_DETAIL has {len(rows)} rows, max {CONFLICT_DETAIL_CAP}"
        )


def write_workbook(
    sheets: dict[str, tuple[list[str], list[list]]],
    out_path: Path,
) -> None:
    """Write the PCNR QC workbook.

    Parameters
    ----------
    sheets:
        Mapping of sheet name to (headers, data_rows). KEY is always written
        from the hard-coded _key_rows(); any KEY entry in sheets is ignored.
        CONFLICT_CLASS_SUMMARY is built by aggregating source rows in sheets
        under that key (list[dict]) if present, or empty otherwise.
    out_path:
        Destination path for the xlsx file. Parent directories are created.
    """
    wb = Workbook()
    wb.remove(wb.active)  # type: ignore[arg-type]

    for sheet_name in SHEET_ORDER:
        ws = wb.create_sheet(sheet_name)
        if sheet_name == "KEY":
            key_data = _key_rows()
            headers = key_data[0]
            data = key_data[1:]
            write_table(ws, headers, data)
        elif sheet_name == "CONFLICT_CLASS_SUMMARY":
            # Build aggregated view from source CSV rows stored as dict list
            raw_entry = sheets.get(sheet_name)
            if raw_entry and raw_entry[0]:
                # raw_entry is (headers, rows_as_lists) -- but for aggregation we need
                # the raw dict rows from the CSV; the caller may pass list[dict] as the
                # rows element when sheet_name == CONFLICT_CLASS_SUMMARY.
                raw_rows = raw_entry[1]
                # Support both list[dict] and list[list] (list[list] from standard path)
                if raw_rows and isinstance(raw_rows[0], dict):
                    src_rows = raw_rows
                else:
                    # Reconstruct dicts from headers + list rows
                    src_hdrs = raw_entry[0]
                    src_rows = [dict(zip(src_hdrs, r)) for r in raw_rows]
                agg_headers, agg_data = _build_conflict_class_summary(src_rows)
            else:
                agg_headers, agg_data = ["conflict_class", "n_variables", "n_cells", "top_5_vars_by_cells"], []
            if not agg_data:
                ws.append(["(no data)"])
            else:
                write_table(ws, agg_headers, agg_data, int_cols=_int_col_indices(agg_headers))
        else:
            headers, data_rows = sheets.get(sheet_name, ([], []))
            assert_input(sheet_name, headers, data_rows)
            if not headers:
                ws.append(["(no data)"])
            else:
                write_table(ws, headers, data_rows, int_cols=_int_col_indices(headers))
        style_sheet(ws)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    wb.save(out_path)
    logging.info("Saved %s", out_path)


def verify_workbook(path: Path, expected_data_rows: dict[str, int]) -> None:
    """Re-open and confirm expected sheets, order, and row counts.

    Raises ValueError on any mismatch.
    """
    wb = load_workbook(path, read_only=True)
    try:
        actual_names = wb.sheetnames
        if actual_names != SHEET_ORDER:
            raise ValueError(
                f"sheet order mismatch: {actual_names} != {SHEET_ORDER}"
            )
        # Check CONFLICT_DETAIL cap
        if "CONFLICT_DETAIL" in wb.sheetnames:
            ws_cd = wb["CONFLICT_DETAIL"]
            cd_rows = ws_cd.max_row - 1  # subtract header
            if cd_rows > CONFLICT_DETAIL_CAP:
                raise ValueError(
                    f"CONFLICT_DETAIL has {cd_rows} data rows, max {CONFLICT_DETAIL_CAP}"
                )
        for sheet_name, exp in expected_data_rows.items():
            if sheet_name not in wb.sheetnames:
                raise ValueError(f"sheet '{sheet_name}' not found in workbook")
            ws = wb[sheet_name]
            actual = ws.max_row - 1  # subtract header
            if actual != exp:
                raise ValueError(
                    f"sheet {sheet_name}: {actual} data rows != expected {exp}"
                )
    finally:
        wb.close()
    logging.info("Workbook verified: %s", path)
