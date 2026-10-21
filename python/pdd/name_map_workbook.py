"""
Core logic for the name-map QC workbook (D-09, D-22).

Reads:   exchange/name_map.csv  (and other exchange CSVs)
Writes:  qc/name_map_review.xlsx
Sheets:  KEY | NAME_MAP | VARIABLES | NAME_MAP_COLLISIONS | NEAR_MATCHES | ABBREVIATIONS
"""

from __future__ import annotations

import csv
import logging
from pathlib import Path

from openpyxl import Workbook, load_workbook

from pdd.xlsx_style import style_sheet, write_table

EXPECTED_ROWS = 4795
SHEET_ORDER = [
    "KEY",
    "NAME_MAP",
    "VARIABLES",
    "NAME_MAP_COLLISIONS",
    "NEAR_MATCHES",
    "ABBREVIATIONS",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def assert_input(
    name_map_rows: list[dict[str, str]],
    expected_rows: int = EXPECTED_ROWS,
) -> None:
    """Raise ValueError if row count or pcnr_name uniqueness rules are violated.

    Rules:
    - len(name_map_rows) must equal expected_rows.
    - Any non-blank pcnr_name (case-insensitive) must map to exactly one
      distinct group_id. Blank pcnr_name values are unconstrained.
    """
    if len(name_map_rows) != expected_rows:
        raise ValueError(
            f"row count {len(name_map_rows)} != expected {expected_rows}"
        )
    # Build map: pcnr_name (lower) -> set of group_ids
    name_to_groups: dict[str, set[str]] = {}
    for r in name_map_rows:
        name = r.get("pcnr_name", "").strip()
        if not name:
            continue
        key = name.lower()
        group = r.get("group_id", "")
        if key not in name_to_groups:
            name_to_groups[key] = set()
        name_to_groups[key].add(group)
    for name_lower, groups in name_to_groups.items():
        if len(groups) > 1:
            raise ValueError(
                f"pcnr_name '{name_lower}' maps to multiple group_ids: {sorted(groups)}"
            )
    logging.info("Input asserts passed: %d rows", len(name_map_rows))


def _key_rows() -> list[list[str]]:
    """D-02 cleaning-rule documentation for the KEY sheet."""
    return [
        ["Rule", "Step", "Description"],
        ["D-02", "1", "Trim leading/trailing whitespace from the original header."],
        [
            "D-02",
            "2",
            "Replace every run of characters that are not ASCII letters or digits "
            "with a single underscore (non-ASCII treated as non-keeping).",
        ],
        [
            "D-02",
            "3",
            "Strip leading and trailing underscores. "
            "A header that cleans to empty causes %fail_out.",
        ],
        [
            "D-02",
            "4",
            "If the result starts with a digit, prefix N_.",
        ],
        [
            "D-02",
            "5",
            "Keep original letter case.",
        ],
        [
            "D-02",
            "6",
            "Apply abbreviation table (D-03) only if the result would exceed 27 chars "
            "after PCNR_ prefix. Applies to all files.",
        ],
        [
            "D-02",
            "7",
            "Prefix PCNR_.",
        ],
        [
            "D-03",
            "Abbrev",
            "Abbreviation table (docs/name_abbrev.csv): Delayed->Dly, Recall->Rcl, "
            "Recognition->Recog, Number->N, Norm_ZScore->Z, AgeScaled->AgeSc, Percent->Pct.",
        ],
        [
            "D-03",
            "Elide",
            "If still >27 chars after abbreviation: keep first N and last M chars "
            "separated by __ (double underscore) to preserve COM/COPY prefix and suffix.",
        ],
    ]


def write_workbook(
    sheets: dict[str, tuple[list[str], list[list]]],
    out_path: Path,
) -> None:
    """Write the name-map review workbook.

    Parameters
    ----------
    sheets:
        Mapping of sheet name to (headers, data_rows). KEY sheet is always
        written as the hard-coded D-02 cleaning-rule text; KEY entry in
        ``sheets`` is ignored if present.
    out_path:
        Destination path for the xlsx file. Parent directories are created.
    """
    wb = Workbook()
    wb.remove(wb.active)  # type: ignore[arg-type]

    for sheet_name in SHEET_ORDER:
        ws = wb.create_sheet(sheet_name)
        if sheet_name == "KEY":
            key_data = _key_rows()
            # First row of _key_rows() is the header
            headers = key_data[0]
            data = key_data[1:]
            write_table(ws, headers, data)
        elif sheet_name in sheets:
            headers, data_rows = sheets[sheet_name]
            write_table(ws, headers, data_rows)
        else:
            # Empty placeholder sheet
            ws.append(["(no data)"])
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
        # Assert sheet order matches SHEET_ORDER
        if actual_names != SHEET_ORDER:
            raise ValueError(
                f"sheet order mismatch: {actual_names} != {SHEET_ORDER}"
            )
        # Assert per-sheet data-row counts
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
