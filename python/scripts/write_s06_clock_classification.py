"""
Write s06 clock-classification QC workbook (D-21, D-22).

Reads:   <exchange>/s06_class_nn.csv
Asserts: 3987 rows; CLOCK=2747 DIGITAL_OTHER=809 PCNR=431 UNSURE=0
Writes:  <qc>/s06_clock_classification.xlsx
Sheets:  KEY | SUMMARY | CLOCK | DIGITAL_OTHER | PCNR | ALL_COLUMNS

Exit 0 on success, non-zero on any failure.
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import EXCHANGE_PATH, LOGS_PATH, QC_PATH
from pdd.s06_workbook import (
    EXPECTED_ROWS,
    assert_input,
    read_csv,
    verify_workbook,
    write_workbook,
)

KEY_SHEET_DATA_ROWS = 10  # 6 output-column rows + 4 class-value rows


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
    args = parser.parse_args()

    exchange = Path(args.exchange)
    qc = Path(args.qc)
    logs = Path(args.logs)

    setup_logging(logs / "write_s06_clock_classification.log")

    csv_path = exchange / "s06_class_nn.csv"
    xlsx_path = qc / "s06_clock_classification.xlsx"

    if not csv_path.exists() or csv_path.stat().st_size == 0:
        logging.error("Input not found or empty: %s", csv_path)
        return 1

    logging.info("Reading %s", csv_path)
    rows = read_csv(csv_path)

    try:
        assert_input(rows)
    except ValueError as exc:
        logging.error("Assertion failed: %s", exc)
        return 1

    write_workbook(rows, xlsx_path)

    clock_n = sum(1 for r in rows if r["class"] == "CLOCK")
    do_n = sum(1 for r in rows if r["class"] == "DIGITAL_OTHER")
    pcnr_n = sum(1 for r in rows if r["class"] == "PCNR")

    try:
        verify_workbook(
            xlsx_path,
            {
                "KEY": KEY_SHEET_DATA_ROWS,
                "CLOCK": clock_n,
                "DIGITAL_OTHER": do_n,
                "PCNR": pcnr_n,
                "ALL_COLUMNS": EXPECTED_ROWS,
            },
        )
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    logging.info(
        "written: %s  CLOCK=%d DIGITAL_OTHER=%d PCNR=%d",
        xlsx_path,
        clock_n,
        do_n,
        pcnr_n,
    )
    print(f"written: {xlsx_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
