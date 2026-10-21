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
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import EXCHANGE_PATH, LOGS_PATH, QC_PATH
from pdd.name_map_workbook import (
    EXPECTED_ROWS,
    assert_input,
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

    # Verify all CSVs exist and are non-empty
    for fname, _ in csv_specs:
        p = exchange / fname
        if not p.exists() or p.stat().st_size == 0:
            logging.error("Input not found or empty: %s", p)
            return 1

    # Read all CSVs
    csv_data: dict[str, list[dict[str, str]]] = {}
    for fname, sheet_name in csv_specs:
        p = exchange / fname
        logging.info("Reading %s", p)
        csv_data[sheet_name] = read_csv(p)

    name_map_rows = csv_data["NAME_MAP"]

    try:
        assert_input(name_map_rows, expected_rows=args.expected_name_map)
    except ValueError as exc:
        logging.error("Assertion failed: %s", exc)
        return 1

    # Build sheets dict (KEY is handled internally by write_workbook)
    sheets: dict[str, tuple[list[str], list[list]]] = {}
    for _, sheet_name in csv_specs:
        rows = csv_data[sheet_name]
        if rows:
            headers = list(rows[0].keys())
            data = [list(r.values()) for r in rows]
        else:
            headers = []
            data = []
        sheets[sheet_name] = (headers, data)

    xlsx_path = qc / "name_map_review.xlsx"
    write_workbook(sheets, xlsx_path)

    # D-10 item 5: verify SAS row counts equal Python workbook sheet row counts
    expected_data_rows: dict[str, int] = {}
    for _, sheet_name in csv_specs:
        expected_data_rows[sheet_name] = len(csv_data[sheet_name])

    try:
        verify_workbook(xlsx_path, expected_data_rows)
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    print(f"written: {xlsx_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
