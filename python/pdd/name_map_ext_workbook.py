"""
Core logic for the Phase 16 name-map extension review workbook (D-22, MAP-01..MAP-04).

Reads:   exchange/name_map_ext_new.csv, name_map_vars_ext.csv, name_map_ext_candidates.csv,
         name_map_ext_collisions.csv, name_map_ext_summary.csv   (written by 16a)
         exchange/name_map_ext_values.csv, name_map_coverage.csv, name_map_vars_coverage.csv  (16b)
Writes:  qc/name_map_ext_review.xlsx (counts 1..10 masked as <11 in value and coverage counts)
Also:    privacy_safe_summary() -> text lines safe for git (no level text, no MIN/MAX values).
Sheets:  KEY | SUMMARY | NEW_ROWS | CANDIDATES | VALUES_SIDE_BY_SIDE | TYPE_CONFLICTS
         | COLLISIONS | COVERAGE | COVERAGE_BY_SOURCE | VARIABLES_EXT
"""

from __future__ import annotations

import csv
import logging
from pathlib import Path

from openpyxl import Workbook, load_workbook

from pdd.new_source_qc_workbook import mask_small_count
from pdd.xlsx_style import style_sheet, write_table

SHEET_ORDER = [
    "KEY",
    "SUMMARY",
    "NEW_ROWS",
    "CANDIDATES",
    "VALUES_SIDE_BY_SIDE",
    "TYPE_CONFLICTS",
    "COLLISIONS",
    "COVERAGE",
    "COVERAGE_BY_SOURCE",
    "VARIABLES_EXT",
]

SHEET_SOURCES: dict[str, str] = {
    "SUMMARY": "name_map_ext_summary.csv",
    "NEW_ROWS": "name_map_ext_new.csv",
    "CANDIDATES": "name_map_ext_candidates.csv",
    "TYPE_CONFLICTS": "name_map_ext_candidates.csv",
    "VALUES_SIDE_BY_SIDE": "name_map_ext_values.csv",
    "COLLISIONS": "name_map_ext_collisions.csv",
    "COVERAGE": "name_map_vars_coverage.csv",
    "COVERAGE_BY_SOURCE": "name_map_coverage.csv",
    "VARIABLES_EXT": "name_map_vars_ext.csv",
}

# Exchange contract: file -> ordered columns (SAS 16a/16b write exactly these).
CONTRACT: dict[str, list[str]] = {
    "name_map_ext_new.csv": [
        "s_code", "col_order", "sas_name", "original_header", "status", "group_id",
        "pcnr_name", "sas_type", "length", "map_class", "matched_pcnr_name",
        "decision_ref", "name_key",
    ],
    "name_map_vars_ext.csv": [
        "pcnr_name", "group_id", "result_type", "max_length", "type_conflict",
        "n_sources", "s_codes_contributing", "var_origin",
    ],
    "name_map_ext_candidates.csv": [
        "pair_id", "s_code_new", "col_order_new", "header_new", "s_codes_new",
        "pcnr_name_old", "s_codes_old", "header_old", "match_type", "edit_dist",
        "proposed_name_if_different", "decision", "status",
    ],
    "name_map_ext_collisions.csv": [
        "s_code", "col_order", "pcnr_name_base", "pcnr_name_final", "suffix_n", "reason",
    ],
    "name_map_ext_summary.csv": ["metric", "value"],
    "name_map_ext_values.csv": [
        "pair_id", "side", "s_code", "col_order", "sas_name", "row_type", "level", "n",
    ],
    "name_map_coverage.csv": [
        "var_key", "pcnr_name", "s_code", "first_year", "last_year", "years_present",
        "n_nonmiss", "n_nonmiss_no_year", "status",
    ],
    "name_map_vars_coverage.csv": [
        "var_key", "pcnr_name", "first_year", "last_year", "years_present",
        "n_sources_data", "s_codes_with_data", "s_codes_contributing", "status",
    ],
}

INT_COLUMNS_BY_FILE: dict[str, list[str]] = {
    "name_map_ext_new.csv": ["col_order", "group_id", "length"],
    "name_map_vars_ext.csv": ["group_id", "max_length", "n_sources"],
    "name_map_ext_candidates.csv": ["pair_id", "col_order_new", "edit_dist"],
    "name_map_ext_collisions.csv": ["col_order", "suffix_n"],
    "name_map_ext_summary.csv": ["value"],
    "name_map_ext_values.csv": ["pair_id", "col_order", "n"],
    "name_map_coverage.csv": ["first_year", "last_year", "n_nonmiss", "n_nonmiss_no_year"],
    "name_map_vars_coverage.csv": ["first_year", "last_year", "n_sources_data"],
}

SIDE_BY_SIDE_HEADERS = [
    "pair_id", "header_new", "pcnr_name_old", "row_type", "side_s_code",
    "level", "n_new", "n_old", "shared",
]

REQUIRED_COLUMNS: dict[str, list[str]] = {
    sheet: CONTRACT[fname] for sheet, fname in SHEET_SOURCES.items()
}

# Masked count columns in the workbook; those sheets store text, so they are not int-typed.
_MASKED_COLUMNS: dict[str, frozenset[str]] = {
    "VALUES_SIDE_BY_SIDE": frozenset({"n_new", "n_old"}),
    "COVERAGE_BY_SOURCE": frozenset({"n_nonmiss", "n_nonmiss_no_year"}),
}

INT_COLUMNS: dict[str, frozenset[str]] = {
    sheet: frozenset(INT_COLUMNS_BY_FILE[fname]) - _MASKED_COLUMNS.get(sheet, frozenset())
    for sheet, fname in SHEET_SOURCES.items()
}
INT_COLUMNS["VALUES_SIDE_BY_SIDE"] = frozenset({"pair_id"})

_COUNT_ROW_TYPES = {"LEVEL", "DISTINCT", "N_MISSING", "N"}
_TEXT_ROW_TYPES = {"MIN", "MAX"}


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


def _to_int(val: object) -> int | None:
    try:
        return int(str(val).strip())
    except (ValueError, TypeError):
        return None


def _num(val: object) -> int:
    n = _to_int(val)
    return 0 if n is None else n


def side_by_side(
    values_rows: list[dict[str, str]],
    candidate_rows: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Pivot 16b value rows to one NEW-vs-OLD comparison table (counts unmasked here)."""
    cand: dict[str, dict[str, str]] = {r.get("pair_id", ""): r for r in candidate_rows}

    def meta(pid: str) -> tuple[str, str]:
        c = cand.get(pid, {})
        return c.get("header_new", ""), c.get("pcnr_name_old", "")

    pairs: list[str] = []
    for r in values_rows:
        pid = r.get("pair_id", "")
        if pid not in pairs:
            pairs.append(pid)

    def pair_key(pid: str) -> tuple[int, int | str]:
        n = _to_int(pid)
        return (0, n) if n is not None else (1, pid)

    out: list[dict[str, str]] = []
    for pid in sorted(pairs, key=pair_key):
        header_new, old_name = meta(pid)
        rows = [r for r in values_rows if r.get("pair_id", "") == pid]
        levels: dict[str, list[int]] = {}
        order: list[str] = []
        others: list[dict[str, str]] = []
        for r in rows:
            rt = r.get("row_type", "")
            if rt == "LEVEL":
                key = r.get("level", "").strip().upper()
                if key not in levels:
                    levels[key] = [0, 0]
                    order.append(key)
                levels[key][0 if r.get("side") == "NEW" else 1] += _num(r.get("n"))
            else:
                others.append(r)

        def row(row_type: str, side_s: str, level: str, n_new: str, n_old: str,
                shared: str, pid=pid, header_new=header_new, old_name=old_name) -> dict[str, str]:
            return {
                "pair_id": pid, "header_new": header_new, "pcnr_name_old": old_name,
                "row_type": row_type, "side_s_code": side_s, "level": level,
                "n_new": n_new, "n_old": n_old, "shared": shared,
            }

        n_shared = sum(1 for v in levels.values() if v[0] > 0 and v[1] > 0)
        out.append(row(
            "SHARED_LEVELS", "ALL", "",
            str(sum(1 for v in levels.values() if v[0] > 0)),
            str(sum(1 for v in levels.values() if v[1] > 0)),
            str(n_shared),
        ))
        for key in sorted(order):
            n_new, n_old = levels[key]
            out.append(row("LEVEL", "ALL", key, str(n_new), str(n_old),
                           "Y" if n_new > 0 and n_old > 0 else "N"))
        for r in others:
            rt = r.get("row_type", "")
            is_new = r.get("side") == "NEW"
            val = r.get("level", "") if rt in _TEXT_ROW_TYPES else r.get("n", "")
            out.append(row(
                rt, f"{r.get('side', '')}:{r.get('s_code', '')}", "",
                val if is_new else "", "" if is_new else val, "",
            ))
    return out


def _mask_values_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    masked = []
    for r in rows:
        r = dict(r)
        if r.get("row_type") in _COUNT_ROW_TYPES:
            r["n_new"] = mask_small_count(r.get("n_new", ""))
            r["n_old"] = mask_small_count(r.get("n_old", ""))
        masked.append(r)
    return masked


def _mask_coverage_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    masked = []
    for r in rows:
        r = dict(r)
        for c in ("n_nonmiss", "n_nonmiss_no_year"):
            r[c] = mask_small_count(r.get(c, ""))
        masked.append(r)
    return masked


def privacy_safe_summary(
    sheets: dict[str, tuple[list[str], list[dict[str, str]]]],
) -> list[str]:
    """Text safe for git: counts 1..10 as <11; no level text, MIN/MAX values or paths."""
    def rows_of(name: str) -> list[dict[str, str]]:
        return sheets.get(name, ([], []))[1]

    metrics = {r.get("metric", ""): r.get("value", "") for r in rows_of("SUMMARY")}
    lines = [f"METRIC {r.get('metric', '')}={mask_small_count(r.get('value', ''))}"
             for r in rows_of("SUMMARY")]

    pending = _num(metrics.get("n_candidates_pending"))
    if pending > 0:
        lines.append(f"GATE MAP-02 near-match: PENDING DECISION n={mask_small_count(pending)}")
    else:
        lines.append("GATE MAP-02 near-match: PASS (all decided)")
    lines.append("GATE MAP-03 Stage 2: PASS" if _num(metrics.get("n_stage2_fail")) == 0
                 else "GATE MAP-03 Stage 2: FAIL")
    lines.append(f"FROZEN NAMES CHANGED: {mask_small_count(metrics.get('n_frozen_names_changed', '0'))}")

    cands = rows_of("CANDIDATES") + rows_of("TYPE_CONFLICTS")
    cands = sorted(cands, key=lambda r: (_num(r.get("pair_id")), r.get("pair_id", "")))
    for r in cands:
        lines.append(
            f"CANDIDATE pair={r.get('pair_id', '')} match_type={r.get('match_type', '')} "
            f"status={r.get('status', '')} new={r.get('header_new', '')} old={r.get('pcnr_name_old', '')}"
        )

    if "COVERAGE" in sheets and sheets["COVERAGE"][0]:
        cov = rows_of("COVERAGE")
        no_data = sum(1 for r in cov if r.get("status") == "NO_DATA")
        lines.append(f"COVERAGE vars={mask_small_count(len(cov))} no_data={mask_small_count(no_data)}")
    else:
        lines.append("COVERAGE: not run (16b PENDING SAS RUN)")
    lines.append("PRICE SIGN-OFF: PENDING (naming rules A1-A4; Phase 16 names included)")
    return lines


def _key_rows() -> list[list[str]]:
    """Documentation rows for the KEY sheet."""
    return [
        ["Section", "Item", "Description"],
        ["Sheet", "SUMMARY", "16a metrics: row counts, frozen-name check, candidates pending, Stage 2 failures."],
        ["Sheet", "NEW_ROWS", "One row per new column (s21-s23): status KEY | LINKAGE_ONLY | PCNR | PENDING_DECISION, "
         "map_class, reused or new pcnr_name."],
        ["Sheet", "CANDIDATES", "Near-match pairs (new header vs existing PCNR_ name) awaiting your decision. "
         "match_type EDIT_DISTANCE | TRAILING_SUFFIX | VARIANTS_FILE | AMBIGUOUS | NONPCNR_EXACT."],
        ["Sheet", "VALUES_SIDE_BY_SIDE", "Value distributions NEW vs OLD per pair. SHARED_LEVELS row first "
         "(distinct levels each side, count shared); then LEVEL rows (case-insensitive) and per-source stats. "
         "Counts 1-10 shown as <11."],
        ["Sheet", "TYPE_CONFLICTS", "TYPE_CONFLICT_EXACT: exact header match with a different type. "
         "The stored old name is reused (A6, MAP-01); informational, add DIFFERENT later if wrong."],
        ["Sheet", "COLLISIONS", "Names that needed a suffix after shortening (Stage 2 uniqueness)."],
        ["Sheet", "COVERAGE", "Per variable: first_year, last_year, years_present (MAP-04)."],
        ["Sheet", "COVERAGE_BY_SOURCE", "Per variable and source: year range and non-missing counts "
         "(<11 masked). n_nonmiss_no_year = non-missing cells with no year (NO_YEAR bucket)."],
        ["Sheet", "VARIABLES_EXT", "Variable-level map after extension: var_origin FROZEN | EXTENDED | NEW."],
        ["Gate", "MAP-02", "A blank pcnr_name means PENDING DECISION; nothing is auto-merged (A5)."],
        ["How to", "Record a decision", "Add a row to docs/name_map_decisions_new.csv: side a = new column "
         "(s21-s23), side b = old column. decision = SAME | DIFFERENT | RENAME; for RENAME give new_name "
         "(27 chars or fewer, without the PCNR_ prefix)."],
        ["Definition", "Coverage year", "Old sources: spine YEAR joined on normalized case ID (A3); new files use "
         "their own YEAR. IDs not in the spine go to NO_YEAR, never dropped."],
        ["Definition", "Non-missing", "not missing(x); for character columns of type-conflict variables "
         "'NULL' in any case also counts as missing (A4, D-02b). Placeholders count as data."],
        ["Definition", "years_present", "Space-separated years ascending, computed at run time."],
        ["Code map", "s21 / s22 / s23", "s21=2023, s22=2024, s23=2025."],
        ["Note", "Price sign-off", "Price sign-off: PENDING (naming rules A1-A4; Phase 16 names included)."],
        ["Note", "Privacy", "Counts 1-10 are shown as <11. Level text stays on P: and is not committed."],
    ]


def write_workbook(
    sheets: dict[str, tuple[list[str], list]],
    out_path: Path,
) -> None:
    """Write sheets in SHEET_ORDER; KEY from _key_rows(); absent sheet -> '(no data)'.

    sheets maps sheet name to (headers, rows); VALUES_SIDE_BY_SIDE rows must already be
    side_by_side() output (unmasked); masking is applied here.
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
                if name == "VALUES_SIDE_BY_SIDE":
                    rows = _mask_values_rows(rows)
                elif name == "COVERAGE_BY_SOURCE":
                    rows = _mask_coverage_rows(rows)
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
