"""
Write PCNR QC workbook (D-16b, D-22).

Reads:   <exchange>/pcnr_gapfill.csv
         <exchange>/pcnr_spine_coverage.csv
         <exchange>/pcnr_conflicts_summary.csv
         <exchange>/pcnr_conflicts_summary_class.csv
         <exchange>/pcnr_conflicts_detail.csv
         <exchange>/pcnr_typecheck.csv
         <exchange>/pcnr_typefail.csv
         <exchange>/pcnr_all_missing.csv      (optional)
         <exchange>/pcnr_all_missing_src.csv  (optional)
Writes:  <qc>/pcnr_qc.xlsx
Sheets:  KEY | GAPFILL | SPINE_COVERAGE | CONFLICT_SUMMARY | CONFLICT_CLASS_SUMMARY
         | CONFLICT_DETAIL | TYPECHECK | TYPEFAIL | ALL_MISSING | ALL_MISSING_SRC

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


def _extract_pcnr_name(path: Path, byte_offset: int) -> str:
    """Return pcnr_name from the CSV row containing byte_offset.

    Reads file as latin-1 (always succeeds) to locate the physical line at
    byte_offset, then splits on comma and returns field index 1 (pcnr_name
    column in all Phase 5 exchange CSVs).  Returns 'unknown' on any failure.
    No data values are logged -- only the column name.
    """
    try:
        raw = path.read_bytes()
        # Find the start of the line containing byte_offset
        line_start = raw.rfind(b"\n", 0, byte_offset) + 1
        line_end = raw.find(b"\n", byte_offset)
        if line_end == -1:
            line_end = len(raw)
        # Decode with latin-1: always succeeds for any byte sequence
        line = raw[line_start:line_end].decode("latin-1")
        fields = line.split(",")
        if len(fields) >= 2:
            return fields[1].strip().strip('"')
    except Exception:
        pass
    return "unknown"


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

    # Required CSVs: (filename, sheet_name)
    csv_specs = [
        ("pcnr_gapfill.csv", "GAPFILL"),
        ("pcnr_spine_coverage.csv", "SPINE_COVERAGE"),
        ("pcnr_conflicts_summary.csv", "CONFLICT_SUMMARY"),
        ("pcnr_conflicts_summary_class.csv", "CONFLICT_CLASS_SUMMARY"),
        ("pcnr_conflicts_detail.csv", "CONFLICT_DETAIL"),
        ("pcnr_typecheck.csv", "TYPECHECK"),
        ("pcnr_typefail.csv", "TYPEFAIL"),
    ]

    # Optional CSVs: skipped if absent (ALL_MISSING sheets may not exist when 0 all-missing vars)
    csv_specs_optional = [
        ("pcnr_all_missing.csv", "ALL_MISSING"),
        ("pcnr_all_missing_src.csv", "ALL_MISSING_SRC"),
    ]

    # Verify all required CSVs exist and are non-empty (header-only accepted; truly empty rejected)
    for fname, _ in csv_specs:
        p = exchange / fname
        if not p.exists() or p.stat().st_size == 0:
            logging.error("Input not found or empty: %s", p)
            return 1

    def _read_with_error(fname: str, sheet_name: str) -> tuple[list[str], list[dict[str, str]]] | None:
        p = exchange / fname
        logging.info("Reading %s", p)
        try:
            return read_csv(p)
        except UnicodeDecodeError as exc:
            pcnr_name_found = _extract_pcnr_name(p, exc.start)
            try:
                raw = p.read_bytes()
                line_no = raw[: exc.start].count(b"\n") + 1
                col_no = exc.start - raw[: exc.start].rfind(b"\n") - 1
                bad_hex = raw[exc.start : exc.start + 4].hex()
            except Exception:
                line_no = "?"
                col_no = exc.start
                bad_hex = "?"
            print(
                f"ERROR: UnicodeDecodeError in {p}"
                f" line {line_no} col {col_no}"
                f" hex {bad_hex}"
                f" pcnr_name={pcnr_name_found}"
            )
            sys.exit(1)

    # Read all required CSVs
    csv_data: dict[str, tuple[list[str], list[dict[str, str]]]] = {}
    for fname, sheet_name in csv_specs:
        result = _read_with_error(fname, sheet_name)
        if result is not None:
            csv_data[sheet_name] = result

    # Read optional CSVs (skip if absent)
    for fname, sheet_name in csv_specs_optional:
        p = exchange / fname
        if p.exists() and p.stat().st_size > 0:
            result = _read_with_error(fname, sheet_name)
            if result is not None:
                csv_data[sheet_name] = result
        else:
            logging.info("Optional CSV absent, skipping: %s", p)

    # Validate required columns and cap before writing (item 18)
    # CONFLICT_CLASS_SUMMARY validation is on the source CSV (not the aggregated sheet)
    for _, sheet_name in csv_specs:
        headers, rows = csv_data[sheet_name]
        try:
            assert_input(sheet_name, headers, rows)
        except ValueError as exc:
            logging.error("Validation failed for %s: %s", sheet_name, exc)
            return 1

    # Validate optional sheets if present
    for _, sheet_name in csv_specs_optional:
        if sheet_name in csv_data:
            headers, rows = csv_data[sheet_name]
            try:
                assert_input(sheet_name, headers, rows)
            except ValueError as exc:
                logging.error("Validation failed for %s: %s", sheet_name, exc)
                return 1

    # D-24: assert no CSV column starts with PCNR_ENCRYPTED_
    for fname, sheet_name in csv_specs + csv_specs_optional:
        if sheet_name not in csv_data:
            continue
        headers, _ = csv_data[sheet_name]
        enc_cols = [h for h in headers if h.upper().startswith("PCNR_ENCRYPTED_")]
        if enc_cols:
            logging.error(
                "D-24 violation in %s (%s): column(s) starting with PCNR_ENCRYPTED_: %s",
                fname, sheet_name, enc_cols,
            )
            return 1

    # Build sheets dict.
    # CONFLICT_CLASS_SUMMARY: pass raw dict rows so write_workbook can aggregate.
    # All other sheets: (headers, rows_as_lists).
    sheets: dict[str, tuple[list[str], list]] = {}
    for _, sheet_name in csv_specs + csv_specs_optional:
        if sheet_name not in csv_data:
            continue
        headers, rows = csv_data[sheet_name]
        if sheet_name == "CONFLICT_CLASS_SUMMARY":
            # Pass dict rows for aggregation in write_workbook
            sheets[sheet_name] = (headers, rows)  # type: ignore[assignment]
        else:
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

    # Build expected row counts for verification.
    # CONFLICT_CLASS_SUMMARY: expected = aggregated rows (unknown here; skip in verify).
    # Optional absent sheets: excluded from verify.
    expected_data_rows: dict[str, int] = {}
    for _, sheet_name in csv_specs:
        if sheet_name == "CONFLICT_CLASS_SUMMARY":
            continue  # aggregated sheet — row count not predictable from source CSV
        _, rows = csv_data[sheet_name]
        expected_data_rows[sheet_name] = len(rows)
    for _, sheet_name in csv_specs_optional:
        if sheet_name in csv_data:
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
