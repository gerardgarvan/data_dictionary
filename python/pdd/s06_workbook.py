"""
Core logic for the s06 clock-classification QC workbook (D-21, D-22).

Reads:   exchange/s06_class_nn.csv
Writes:  qc/s06_clock_classification.xlsx
Sheets:  KEY | SUMMARY | CLOCK | DIGITAL_OTHER | PCNR | ALL_COLUMNS
"""

from __future__ import annotations

import csv
import logging
from collections import Counter
from pathlib import Path

from openpyxl import Workbook, load_workbook

from pdd.xlsx_style import ACCENT_FILL, ACCENT_FONT, apply_header_row, autofit_columns, freeze_and_filter

EXPECTED_ROWS = 3987
EXPECTED_COUNTS: dict[str, int] = {
    "CLOCK": 2747,
    "DIGITAL_OTHER": 809,
    "PCNR": 431,
    "UNSURE": 0,
}

SHEET_ORDER = ["KEY", "SUMMARY", "CLOCK", "DIGITAL_OTHER", "PCNR", "ALL_COLUMNS"]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def assert_input(
    rows: list[dict[str, str]],
    expected_rows: int = EXPECTED_ROWS,
    expected_counts: dict[str, int] | None = None,
) -> None:
    """Raise ValueError if row count or class counts do not match expectations."""
    if expected_counts is None:
        expected_counts = EXPECTED_COUNTS
    if len(rows) != expected_rows:
        raise ValueError(f"row count {len(rows)} != expected {expected_rows}")
    counts = Counter(r["class"] for r in rows)
    for cls, exp in expected_counts.items():
        actual = counts.get(cls, 0)
        if actual != exp:
            raise ValueError(f"class={cls} count={actual} != expected {exp}")
    logging.info("Input asserts passed: %d rows, %s", len(rows), dict(counts))


def _key_rows() -> list[list[str]]:
    return [
        ["Output column", "sas_name", "SAS variable name in pdd.src_s06 (max 32 chars; from pdd.import_spec)"],
        ["Output column", "orig_col_name", "Original column header from the source file"],
        ["Output column", "token", "Text after COM/COPY prefix; LINUS for LINUS-prefix columns; blank otherwise"],
        ["Output column", "class", "Classification: CLOCK | DIGITAL_OTHER | PCNR | UNSURE"],
        ["Output column", "rule", "Text description of the matching classification rule"],
        ["Output column", "pct_nonnull", "% rows in pdd.src_s06 with a non-missing value (0-100)"],
        ["Class value", "CLOCK", "Clock-drawing features: COM/COPY + clock token OR LINUS DCTclock. Excluded from PCNR_. n=2,747 (D-21)."],
        ["Class value", "DIGITAL_OTHER", "Other digital cognitive battery tests: COM/COPY + non-clock digital token. Stay in PCNR_. n=809."],
        ["Class value", "PCNR", "All other source columns. Always PCNR_. n=431. Includes clock admin flags and Mini-Cog scores."],
        ["Class value", "UNSURE", "COM/COPY prefix with unrecognized token. Must be 0 after D-21 review."],
    ]


def _summary_tables(
    rows: list[dict[str, str]],
) -> tuple[list[list[str]], list[list[str]]]:
    class_counts = Counter(r["class"] for r in rows)
    class_rows = [[cls, str(class_counts.get(cls, 0))] for cls in ("CLOCK", "DIGITAL_OTHER", "PCNR", "UNSURE")]

    rule_class: dict[tuple[str, str], int] = {}
    for r in rows:
        key = (r["rule"], r["class"])
        rule_class[key] = rule_class.get(key, 0) + 1
    rule_rows = [[rule, cls, str(n)] for (rule, cls), n in sorted(rule_class.items())]

    return class_rows, rule_rows


def _write_rows(ws, headers: list[str], data: list[list[str]]) -> None:
    ws.append(headers)
    apply_header_row(ws)
    for row in data:
        ws.append(row)
    freeze_and_filter(ws)
    autofit_columns(ws)


def _accent_column(ws, col_idx: int) -> None:
    """Orange accent on data cells (row 2+) in the given 1-based column."""
    for row in ws.iter_rows(min_row=2, min_col=col_idx, max_col=col_idx):
        for cell in row:
            cell.fill = ACCENT_FILL
            cell.font = ACCENT_FONT


def write_workbook(rows: list[dict[str, str]], out_path: Path) -> None:
    """Write the classification workbook; does not validate row counts."""
    clock = [r for r in rows if r["class"] == "CLOCK"]
    do = [r for r in rows if r["class"] == "DIGITAL_OTHER"]
    pcnr = [r for r in rows if r["class"] == "PCNR"]
    class_rows, rule_rows = _summary_tables(rows)

    wb = Workbook()
    wb.remove(wb.active)  # type: ignore[arg-type]

    # KEY
    ws_key = wb.create_sheet("KEY")
    _write_rows(ws_key, ["Section", "Item", "Description"], _key_rows())

    # SUMMARY: class counts, then rule x class below
    ws_sum = wb.create_sheet("SUMMARY")
    _write_rows(ws_sum, ["Class", "Column count"], class_rows)
    _accent_column(ws_sum, 1)
    ws_sum.append([])
    ws_sum.append(["Rule", "Class", "Column count"])
    for row in rule_rows:
        ws_sum.append(row)

    def _subset_data(subset: list[dict[str, str]]) -> list[list[str]]:
        return [[r["sas_name"], r["orig_col_name"], r["token"], r["rule"], r["pct_nonnull"]] for r in subset]

    sub_headers = ["SAS Name", "Original Column", "Token", "Rule", "% Non-null"]

    ws_clock = wb.create_sheet("CLOCK")
    _write_rows(ws_clock, sub_headers, _subset_data(clock))

    ws_do = wb.create_sheet("DIGITAL_OTHER")
    _write_rows(ws_do, sub_headers, _subset_data(do))

    ws_pcnr = wb.create_sheet("PCNR")
    _write_rows(ws_pcnr, sub_headers, _subset_data(pcnr))

    ws_all = wb.create_sheet("ALL_COLUMNS")
    all_data = [
        [r["sas_name"], r["orig_col_name"], r["token"], r["class"], r["rule"], r["pct_nonnull"]]
        for r in rows
    ]
    _write_rows(ws_all, ["SAS Name", "Original Column", "Token", "Class", "Rule", "% Non-null"], all_data)
    _accent_column(ws_all, 4)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    wb.save(out_path)
    logging.info("Saved %s", out_path)


def verify_workbook(path: Path, expected_data_rows: dict[str, int]) -> None:
    """Re-open and confirm expected sheets and row counts. Raises ValueError on mismatch."""
    wb = load_workbook(path, read_only=True)
    try:
        missing = [s for s in SHEET_ORDER if s not in wb.sheetnames]
        if missing:
            raise ValueError(f"missing sheets: {missing}")
        for sheet_name, exp in expected_data_rows.items():
            ws = wb[sheet_name]
            actual = ws.max_row - 1  # subtract header
            if actual != exp:
                raise ValueError(f"sheet {sheet_name}: {actual} data rows != expected {exp}")
    finally:
        wb.close()
    logging.info("Workbook verified: %s", path)
