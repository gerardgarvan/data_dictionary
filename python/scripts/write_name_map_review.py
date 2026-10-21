"""
Write name-map QC workbook (D-09, D-22).

Reads:   <exchange>/name_map.csv
         <exchange>/name_map_vars.csv
         <exchange>/name_map_collisions.csv
         <exchange>/name_map_nearmatches.csv
         <exchange>/name_abbrev_applied.csv
Asserts: name_map.csv has --expected-name-map rows (default 4795)
Writes:  <qc>/name_map_review.xlsx
Sheets:  KEY | NAME_MAP | VARIABLES | NAME_MAP_COLLISIONS | NEAR_MATCHES | ABBREVIATIONS

Exit 0 on success, non-zero on any failure.
"""

from __future__ import annotations

import argparse
import csv
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import EXCHANGE_PATH, LOGS_PATH, QC_PATH
from pdd.name_map_workbook import (
    DECISIONS_TEMPLATE_COLS,
    EXPECTED_ROWS,
    assert_input,
    build_group_meta,
    make_decisions_template,
    read_csv,
    verify_workbook,
    write_workbook,
)


def setup_logging(log_path: Path) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=[
            logging.FileHandler(log_path, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
        force=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exchange", default=str(EXCHANGE_PATH))
    parser.add_argument("--qc", default=str(QC_PATH))
    parser.add_argument("--logs", default=str(LOGS_PATH))
    parser.add_argument(
        "--expected-name-map",
        type=int,
        default=EXPECTED_ROWS,
        dest="expected_name_map",
    )
    args = parser.parse_args()

    exchange = Path(args.exchange)
    qc = Path(args.qc)
    logs = Path(args.logs)

    setup_logging(logs / "write_name_map_review.log")

    csv_specs = [
        ("name_map.csv", "NAME_MAP"),
        ("name_map_vars.csv", "VARIABLES"),
        ("name_map_collisions.csv", "NAME_MAP_COLLISIONS"),
        ("name_map_nearmatches.csv", "NEAR_MATCHES"),
        ("name_abbrev_applied.csv", "ABBREVIATIONS"),
    ]

    # Verify all CSVs exist and are non-empty (header-only accepted; truly empty rejected)
    for fname, _ in csv_specs:
        p = exchange / fname
        if not p.exists() or p.stat().st_size == 0:
            logging.error("Input not found or empty: %s", p)
            return 1

    # Read all CSVs; read_csv returns (fieldnames, rows) -- fieldnames preserved for header-only files
    csv_data: dict[str, tuple[list[str], list[dict[str, str]]]] = {}
    for fname, sheet_name in csv_specs:
        p = exchange / fname
        logging.info("Reading %s", p)
        csv_data[sheet_name] = read_csv(p)

    name_map_headers, name_map_rows = csv_data["NAME_MAP"]

    try:
        assert_input(name_map_headers, name_map_rows, expected_rows=args.expected_name_map)
    except ValueError as exc:
        logging.error("Assertion failed: %s", exc)
        return 1

    # Build sheets dict; use fieldnames as headers even when data is empty
    sheets: dict[str, tuple[list[str], list[list]]] = {}
    for _, sheet_name in csv_specs:
        headers, rows = csv_data[sheet_name]
        data = [list(r.values()) for r in rows]
        sheets[sheet_name] = (headers, data)

    # Inject group meta into VARIABLES (original_header only) and NAME_MAP_COLLISIONS (both)
    group_meta = build_group_meta(name_map_rows)
    for sheet_name in ("VARIABLES", "NAME_MAP_COLLISIONS"):
        if sheet_name not in sheets:
            continue
        hdrs, rows = sheets[sheet_name]
        if "group_id" not in hdrs:
            continue
        gid_idx = hdrs.index("group_id")
        if sheet_name == "VARIABLES":
            new_hdrs = hdrs + ["original_header"]
            new_rows = [
                row + [group_meta.get(str(row[gid_idx]), {}).get("original_header", "")]
                for row in rows
            ]
        else:
            new_hdrs = hdrs + ["original_header", "s_codes"]
            new_rows = [
                row + [
                    group_meta.get(str(row[gid_idx]), {}).get("original_header", ""),
                    group_meta.get(str(row[gid_idx]), {}).get("s_codes", ""),
                ]
                for row in rows
            ]
        sheets[sheet_name] = (new_hdrs, new_rows)

    xlsx_path = qc / "name_map_review.xlsx"
    write_workbook(sheets, xlsx_path)

    expected_data_rows: dict[str, int] = {}
    for _, sheet_name in csv_specs:
        _, rows = csv_data[sheet_name]
        expected_data_rows[sheet_name] = len(rows)

    try:
        verify_workbook(xlsx_path, expected_data_rows)
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    _, near_rows = csv_data["NEAR_MATCHES"]
    template_rows = make_decisions_template(near_rows)
    template_path = exchange / "name_map_decisions_template.csv"
    with template_path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=DECISIONS_TEMPLATE_COLS)
        w.writeheader()
        w.writerows(template_rows)
    logging.info("Decisions template: %s (%d rows)", template_path, len(template_rows))

    print(f"written: {xlsx_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
