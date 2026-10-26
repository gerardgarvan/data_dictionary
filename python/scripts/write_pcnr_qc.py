"""
Write PCNR QC workbook (D-16b, D-22).

Reads:   <exchange>/pcnr_gapfill.csv
         <exchange>/pcnr_spine_coverage.csv
         <exchange>/pcnr_conflicts_summary.csv
         <exchange>/pcnr_conflicts_detail.csv
         <exchange>/pcnr_typecheck.csv
Writes:  <qc>/pcnr_qc.xlsx
Sheets:  KEY | GAPFILL | SPINE_COVERAGE | CONFLICT_SUMMARY | CONFLICT_DETAIL | TYPECHECK

Exit 0 on success, non-zero on any failure.
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import EXCHANGE_PATH, LOGS_PATH, QC_PATH
from pdd.pcnr_qc_workbook import (
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
    args = parser.parse_args()

    exchange = Path(args.exchange)
    qc = Path(args.qc)
    logs = Path(args.logs)

    setup_logging(logs / "write_pcnr_qc.log")

    csv_specs = [
        ("pcnr_gapfill.csv", "GAPFILL"),
        ("pcnr_spine_coverage.csv", "SPINE_COVERAGE"),
        ("pcnr_conflicts_summary.csv", "CONFLICT_SUMMARY"),
        ("pcnr_conflicts_detail.csv", "CONFLICT_DETAIL"),
        ("pcnr_typecheck.csv", "TYPECHECK"),
    ]

    # Verify all CSVs exist and are non-empty (header-only accepted; truly empty rejected)
    for fname, _ in csv_specs:
        p = exchange / fname
        if not p.exists() or p.stat().st_size == 0:
            logging.error("Input not found or empty: %s", p)
            return 1

    # Read all CSVs
    csv_data: dict[str, tuple[list[str], list[dict[str, str]]]] = {}
    for fname, sheet_name in csv_specs:
        p = exchange / fname
        logging.info("Reading %s", p)
        try:
            csv_data[sheet_name] = read_csv(p)
        except UnicodeDecodeError as exc:
            # Count newlines in raw bytes up to error start to get accurate line number.
            # exc.start is a byte offset in the raw stream (D-23 hardening -- no values).
            try:
                raw = p.read_bytes()
                line_no = raw[: exc.start].count(b"\n") + 1
                col_no = exc.start - raw[: exc.start].rfind(b"\n") - 1
            except Exception:
                line_no = "?"
                col_no = exc.start
            print(
                f"ERROR: UnicodeDecodeError in {p}"
                f" line {line_no} col {col_no}"
                f" hex {exc.object[exc.start:exc.end].hex()}"
                f" pcnr_name=unknown"
            )
            sys.exit(1)

    # Validate columns and cap before writing (item 18)
    for _, sheet_name in csv_specs:
        headers, rows = csv_data[sheet_name]
        try:
            assert_input(sheet_name, headers, rows)
        except ValueError as exc:
            logging.error("Validation failed for %s: %s", sheet_name, exc)
            return 1

    # Build sheets dict: (headers, rows_as_lists)
    sheets: dict[str, tuple[list[str], list[list]]] = {}
    for _, sheet_name in csv_specs:
        headers, rows = csv_data[sheet_name]
        data = [list(r.values()) for r in rows]
        sheets[sheet_name] = (headers, data)

    xlsx_path = qc / "pcnr_qc.xlsx"
    try:
        write_workbook(sheets, xlsx_path)
    except PermissionError:
        logging.error(
            "Permission denied writing %s -- close the file in Excel and rerun", xlsx_path
        )
        return 1

    expected_data_rows: dict[str, int] = {}
    for _, sheet_name in csv_specs:
        _, rows = csv_data[sheet_name]
        expected_data_rows[sheet_name] = len(rows)

    try:
        verify_workbook(xlsx_path, expected_data_rows)
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    print(f"written: {xlsx_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
