"""
Write PeCAN Data Dictionary workbook (Phase 7, D-22).

Reads:   <exchange>/profile_PCNR.csv
         <exchange>/name_map_dict.csv
         <exchange>/source_inventory.csv
         <docs>/source_notes.csv  (optional)
         <docs>/exchange_schema.csv  (for header validation)
Writes:  <out>/pdd_v1_0.xlsx
Sheets:  KEY | VARIABLES | DISTRIBUTIONS | NAME_MAP | SOURCES | QC
         | PCNC_ | PCND_ | CLK_ | LAB_ | MED_ | INTRA_

Exit 0 on success, non-zero on any failure.
"""

from __future__ import annotations

import argparse
import csv
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import DOCS_PATH, EXCHANGE_PATH, LOGS_PATH, OUT_PATH
from pdd.dictionary_workbook import (
    DEFAULT_DISPLAY_CONFIG,
    SHEET_ORDER,
    verify_workbook,
    write_workbook,
)

# Silence unused-import warning from linter: SHEET_ORDER is imported for
# callers and documentation purposes.
__all__ = ["SHEET_ORDER"]


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


def validate_exchange_headers(exchange_dir: Path, docs_dir: Path) -> list[str]:
    """Validate required headers in Phase 7 exchange CSVs against exchange_schema.csv.

    Returns a list of error strings.  Empty list means all headers present.
    """
    schema_path = docs_dir / "exchange_schema.csv"
    if not schema_path.exists():
        return [f"exchange_schema.csv not found: {schema_path}"]

    # Build required-column index: {filename: [col, ...]}
    required: dict[str, list[str]] = {}
    phase7_files = {"profile_PCNR.csv", "name_map_dict.csv", "source_inventory.csv"}
    with schema_path.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            fname = row.get("file", "").strip()
            col = row.get("column", "").strip()
            req = row.get("required", "").strip().upper()
            if fname in phase7_files and req == "Y":
                required.setdefault(fname, []).append(col)

    errors: list[str] = []
    for fname in sorted(phase7_files):
        csv_path = exchange_dir / fname
        if not csv_path.exists():
            errors.append(f"Exchange file missing: {csv_path}")
            continue
        with csv_path.open(newline="", encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            actual = set(reader.fieldnames or [])
        expected = required.get(fname, [])
        missing = [c for c in expected if c not in actual]
        for col in missing:
            errors.append(f"{fname}: required column missing: {col}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exchange", default=str(EXCHANGE_PATH))
    parser.add_argument("--out", default=str(OUT_PATH))
    parser.add_argument("--logs", default=str(LOGS_PATH))
    parser.add_argument("--docs", default=str(DOCS_PATH))
    args = parser.parse_args()

    exchange = Path(args.exchange)
    out = Path(args.out)
    logs = Path(args.logs)
    docs = Path(args.docs)

    setup_logging(logs / "write_dictionary.log")

    # Verify required exchange CSVs exist and are non-empty
    required_csvs = ["profile_PCNR.csv", "name_map_dict.csv", "source_inventory.csv"]
    for fname in required_csvs:
        p = exchange / fname
        if not p.exists() or p.stat().st_size == 0:
            logging.error("Input not found or empty: %s", p)
            return 1

    # Validate headers against exchange_schema.csv
    header_errors = validate_exchange_headers(exchange, docs)
    if header_errors:
        for err in header_errors:
            logging.error("Header validation: %s", err)
        return 1

    # Write workbook
    out.mkdir(parents=True, exist_ok=True)
    try:
        counts = write_workbook(
            exchange_dir=exchange,
            out_path=out / "pdd_v1_0.xlsx",
            docs_dir=docs,
            config=DEFAULT_DISPLAY_CONFIG,
        )
    except PermissionError:
        logging.error(
            "Permission denied writing %s -- close the file in Excel and rerun",
            out / "pdd_v1_0.xlsx",
        )
        return 1

    # Verify workbook integrity
    try:
        verify_workbook(out / "pdd_v1_0.xlsx", expected_data_rows=counts)
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    print(f"written: {out / 'pdd_v1_0.xlsx'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
