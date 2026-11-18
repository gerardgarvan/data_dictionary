r"""
Verify out\PCNR_Master_Data_Nov_2026.xlsx against the 19b stage files (Phase 19, plan 19-06).

Reads:   <out>/PCNR_Master_Data_Nov_2026.xlsx, <stage>/xlsx_{schema,data,expected,write_counts}.csv,
         <exchange>/comb_recon.csv, comb_nodata.csv, comb_key_facts.csv, <out_root>/pecan_id_registry.sas7bdat
         (ENCRYPTED_MRN read in memory only, hit count printed).
Writes:  <qc>/xlsx_master_verify.csv, <exchange>/xlsx_master_verify_summary.csv (both masked), log.
Exit 0 only if every item passes; on PASS the stage CSV files are deleted (PDD-D-42 = NONE).
Logs counts and names only, never a cell value.
"""
from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd import master_verify as mv
from pdd import master_workbook as mw
from pdd.config import DOCS_PATH, EXCHANGE_PATH, LOGS_PATH, OUT_PATH, OUT_ROOT, QC_PATH, STAGE_PATH


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
    ap.add_argument("--keys", default="K3")
    ap.add_argument("--log", type=Path, default=LOGS_PATH / "verify_master_workbook.log")
    args = ap.parse_args(argv)
    setup_logging(args.log)
    try:
        results = mv.verify(
            xlsx=OUT_PATH / mw.FINAL_NAME, stage_dir=STAGE_PATH, exchange_dir=EXCHANGE_PATH,
            docs_dir=DOCS_PATH, registry_path=OUT_ROOT / "pecan_id_registry.sas7bdat",
            keys_code=args.keys,
        )
    except (mw.StageError, FileNotFoundError, ValueError, OSError) as exc:
        logging.error("verify could not run: %s", type(exc).__name__)
        return 1
    ok = mv.write_outputs(results, QC_PATH / "xlsx_master_verify.csv",
                          EXCHANGE_PATH / "xlsx_master_verify_summary.csv")
    failed = [r for r in results if not r[4]]
    for c, v, n, e, _ in failed:
        logging.error("FAIL %s %s n=%s expected=%s", c, v, mv._mask_any(n), mv._mask_any(e))
    logging.info("checked %d items, %d failed", len(results), len(failed))
    if not ok:
        logging.error("FAIL - verification failed; stage files kept")
        return 1
    removed = mv.delete_stage(STAGE_PATH)
    logging.info("stage files deleted: %s", ", ".join(removed))
    logging.info("PASS - master workbook verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
