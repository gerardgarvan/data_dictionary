"""
Write the PeCAN Data Dictionary workbook for 2018-2025 (Phase 18, DD-03 / DD-04).

Reads:   <exchange>/comb_key_facts.csv, comb_recon.csv, comb_nodata.csv,
         comb_d30_conflicts.csv, profile_PCNR_2018_2025.csv (+ _manifest),
         name_map_vars_coverage.csv, source_inventory.csv (optional)
         <docs>/exchange_schema.csv, combined_type_decisions.csv,
         pecan_id_dictionary_text.csv
Writes:  <out>/pdd_2018_2025.xlsx
Sheets:  KEY | VARIABLES | DISTRIBUTIONS | NAME_MAP | SOURCES | QC

Exit 0 on success, non-zero on any failure (header, reconciliation, verify).
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

try:
    import openpyxl  # noqa: F401
    import pandas  # noqa: F401
except ImportError as _imp_err:
    _pkg = str(_imp_err).split("'")[-2] if "'" in str(_imp_err) else str(_imp_err)
    print(
        f"{_pkg} not installed for {sys.executable} -- "
        f"run {sys.executable} -m pip install -r requirements.txt",
        file=sys.stderr,
    )
    sys.exit(1)

from pdd.config import DOCS_PATH, EXCHANGE_PATH, LOGS_PATH, OUT_PATH
from pdd.dictionary_2018_2025_workbook import (
    OUTPUT_NAME,
    validate_exchange_headers,
    verify_workbook_2018_2025,
    write_workbook_2018_2025,
)
from pdd.dictionary_workbook import DEFAULT_DISPLAY_CONFIG


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
    parser.add_argument("--out", default=str(OUT_PATH))
    parser.add_argument("--logs", default=str(LOGS_PATH))
    parser.add_argument("--docs", default=str(DOCS_PATH))
    args = parser.parse_args()

    exchange, out, logs, docs = (Path(args.exchange), Path(args.out), Path(args.logs), Path(args.docs))
    setup_logging(logs / "write_dictionary_2018_2025.log")

    errors = validate_exchange_headers(exchange, docs)
    if errors:
        for err in errors:
            logging.error("Header validation: %s", err)
        return 1

    target = out / OUTPUT_NAME
    out.mkdir(parents=True, exist_ok=True)
    try:
        counts = write_workbook_2018_2025(exchange, target, docs, dict(DEFAULT_DISPLAY_CONFIG))
    except PermissionError:
        logging.error("Permission denied writing %s -- close the file in Excel and rerun", target)
        return 1
    except (ValueError, RuntimeError, FileNotFoundError) as exc:
        logging.error("Workbook build failed: %s", exc)
        return 1

    try:
        verify_workbook_2018_2025(target, counts)
    except ValueError as exc:
        logging.error("Workbook verification failed: %s", exc)
        return 1

    print(f"written: {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
