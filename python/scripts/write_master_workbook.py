r"""
Write out\\PCNR_Master_Data_Nov_2026.xlsx from the 19b stage files (Phase 19, plan 19-05).

Reads:   <stage>/xlsx_schema.csv, xlsx_data.csv, xlsx_expected.csv, <exchange>/comb_key_facts.csv,
         docs/pecan_id_dictionary_text.csv, docs/combined_type_decisions.csv
Writes:  <out>/PCNR_Master_Data_Nov_2026.xlsx (KEY, DATA), <stage>/xlsx_write_counts.csv (exact),
         <qc>/xlsx_master_write.csv (masked), log.
Needs:   PDD_XLS_APPROVE=1 in the environment (set at run time, never in config).
Options: --bench-rows N writes a throwaway file under stage\\ and prints rows/s.
Exit 0 on success, non-zero on any gate or failure. Logs counts only, never a cell value.
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd import master_workbook as mw
from pdd.config import (
    BACKUP_PATH, DOCS_PATH, EXCHANGE_PATH, LOGS_PATH, OUT_PATH, QC_PATH, STAGE_PATH,
)


def setup_logging(log_path: Path) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=[logging.FileHandler(log_path, encoding="utf-8"), logging.StreamHandler(sys.stdout)],
        force=True,
    )


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--bench-rows", type=int, default=None, help="benchmark N rows, write nothing final")
    ap.add_argument("--keys", default=os.environ.get("PDD_XLS_KEYS") or "K3")
    ap.add_argument("--min-free-gb", type=float, default=float(os.environ.get("PDD_XLS_MIN_FREE_GB") or 15))
    ap.add_argument("--log", type=Path, default=LOGS_PATH / "write_master_workbook.log")
    args = ap.parse_args(argv)
    setup_logging(args.log)
    approve = os.environ.get("PDD_XLS_APPROVE")
    try:
        if args.bench_rows:
            r = mw.bench(stage_dir=STAGE_PATH, docs_dir=DOCS_PATH, n_rows=args.bench_rows,
                         approve=approve, keys_code=args.keys)
            print(f"BENCH rows={r['rows']} rows_per_s={r['rows_per_s']:.0f} "
                  f"extrapolated_full_minutes={r['est_minutes']:.1f}")
            return 0
        mw.write_master_workbook(
            stage_dir=STAGE_PATH, exchange_dir=EXCHANGE_PATH, docs_dir=DOCS_PATH, qc_dir=QC_PATH,
            out_dir=OUT_PATH, backup_dir=BACKUP_PATH, keys_code=args.keys,
            approve=approve, min_free_gb=args.min_free_gb,
        )
    except PermissionError as exc:
        logging.error("%s", exc)
        return 2
    except (mw.StageError, ValueError, FileNotFoundError) as exc:
        logging.error("write failed: %s", exc)
        return 1
    logging.info("PASS - master workbook written; run verify_master_workbook.py next")
    return 0


if __name__ == "__main__":
    sys.exit(main())
