"""
Write the Phase 15 new-source intake QC workbook (D-22, A6).

Reads:   <exchange>/new_source_guard.csv, header_inventory_new.csv, header_matrix_new.csv,
         new_rowcounts.csv, new_one_to_one.csv, new_overlap.csv, new_type_changes.csv,
         new_nonascii.csv
         <docs>/new_source_header_variants.csv  (optional; VARIANTS sheet)
         <docs>/exchange_schema.csv             (required-column validation)
Writes:  <qc>/new_source_intake.xlsx
         <logs>/new_source_qc_summary.txt       (counts 1..10 masked as <11)
Sheets:  KEY | GUARD | ROWCOUNTS | ONE_TO_ONE | OVERLAP | HEADER_MATRIX
         | HEADER_INVENTORY | TYPE_CHANGES | VARIANTS | NONASCII

--allow-partial: missing exchange CSVs are skipped (sheet shows "(no data)"), e.g. a run
stopped at the 15c gate.  Exit 0 on success, 1 on any failure.
"""

from __future__ import annotations

import argparse
import csv
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import DOCS_PATH, EXCHANGE_PATH, LOGS_PATH, QC_PATH
from pdd.new_source_qc_workbook import (
    CONTRACT,
    SHEET_SOURCES,
    assert_input,
    privacy_safe_summary,
    read_csv,
    verify_workbook,
    write_workbook,
)

VARIANTS_FILE = SHEET_SOURCES["VARIANTS"]


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


def schema_required(docs_dir: Path) -> dict[str, list[str]] | None:
    """Required columns per Phase 15 exchange file from docs/exchange_schema.csv."""
    path = docs_dir / "exchange_schema.csv"
    if not path.exists():
        logging.error("exchange_schema.csv not found: %s", path)
        return None
    required: dict[str, list[str]] = {}
    with path.open(newline="", encoding="utf-8-sig") as fh:
        for row in csv.DictReader(fh):
            fname = row.get("file", "").strip()
            if fname in CONTRACT and row.get("required", "").strip().upper() == "Y":
                required.setdefault(fname, []).append(row.get("column", "").strip())
    return required


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exchange", default=str(EXCHANGE_PATH))
    parser.add_argument("--qc", default=str(QC_PATH))
    parser.add_argument("--logs", default=str(LOGS_PATH))
    parser.add_argument("--docs", default=str(DOCS_PATH))
    parser.add_argument("--allow-partial", action="store_true")
    args = parser.parse_args(argv)

    exchange, qc, logs, docs = (Path(p) for p in (args.exchange, args.qc, args.logs, args.docs))
    setup_logging(logs / "write_new_source_qc.log")

    required = schema_required(docs)
    if required is None:
        return 1

    sheets: dict[str, tuple[list[str], list]] = {}
    failed = False
    for sheet, fname in SHEET_SOURCES.items():
        is_variants = fname == VARIANTS_FILE
        path = (docs if is_variants else exchange) / fname
        if not path.exists() or path.stat().st_size == 0:
            if is_variants or args.allow_partial:
                logging.warning("Input absent, sheet will show (no data): %s", fname)
                continue
            logging.error("Required exchange file missing or empty: %s", fname)
            failed = True
            continue
        try:
            headers, rows = read_csv(path)
        except UnicodeDecodeError:
            logging.error("%s is not valid UTF-8", fname)
            failed = True
            continue
        missing = [c for c in required.get(fname, []) if c not in headers]
        if missing:
            logging.error("%s: required column missing: %s", fname, ", ".join(missing))
            failed = True
            continue
        try:
            assert_input(sheet, headers, rows)
        except ValueError as exc:
            logging.error("Validation failed: %s", exc)
            failed = True
            continue
        sheets[sheet] = (headers, rows)
    if failed:
        return 1

    xlsx_path = qc / "new_source_intake.xlsx"
    try:
        write_workbook(sheets, xlsx_path)
    except PermissionError:
        logging.error("Permission denied writing %s -- close the file in Excel and rerun", xlsx_path)
        return 1

    try:
        verify_workbook(xlsx_path, {s: len(r) for s, (_, r) in sheets.items()})
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    lines = privacy_safe_summary(sheets)  # type: ignore[arg-type]
    summary_path = logs / "new_source_qc_summary.txt"
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    for line in lines:
        print(line)
    print(f"written: {xlsx_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
