"""
Write the Phase 16 name-map extension review workbook (D-22, MAP-01..MAP-04).

Reads:   <exchange>/name_map_ext_new.csv, name_map_vars_ext.csv, name_map_ext_candidates.csv,
         name_map_ext_collisions.csv, name_map_ext_summary.csv      (16a, required)
         <exchange>/name_map_ext_values.csv, name_map_coverage.csv,
         name_map_vars_coverage.csv                                  (16b, optional with --allow-partial)
         <docs>/exchange_schema.csv                                  (required-column validation)
Writes:  <qc>/name_map_ext_review.xlsx   (counts 1..10 masked as <11)
         <logs>/name_map_ext_summary.txt (privacy-safe, counts 1..10 masked)
Sheets:  KEY | SUMMARY | NEW_ROWS | CANDIDATES | VALUES_SIDE_BY_SIDE | TYPE_CONFLICTS
         | COLLISIONS | COVERAGE | COVERAGE_BY_SOURCE | VARIABLES_EXT

--allow-partial: missing 16b CSVs are skipped (sheets show "(no data)"). A missing 16a CSV is
always an error.  Exit 0 on success, 1 on any failure.
"""

from __future__ import annotations

import argparse
import csv
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.config import DOCS_PATH, EXCHANGE_PATH, LOGS_PATH, QC_PATH
from pdd.name_map_ext_workbook import (
    CONTRACT,
    SHEET_SOURCES,
    assert_input,
    privacy_safe_summary,
    read_csv,
    side_by_side,
    verify_workbook,
    write_workbook,
)

PART_16B = frozenset({"name_map_ext_values.csv", "name_map_coverage.csv", "name_map_vars_coverage.csv"})
SIDE_HEADERS = [
    "pair_id", "header_new", "pcnr_name_old", "row_type", "side_s_code",
    "level", "n_new", "n_old", "shared",
]


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
    """Required columns per Phase 16 exchange file from docs/exchange_schema.csv."""
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
    setup_logging(logs / "write_name_map_ext_review.log")

    required = schema_required(docs)
    if required is None:
        return 1

    loaded: dict[str, tuple[list[str], list[dict[str, str]]]] = {}
    failed = False
    for fname in CONTRACT:
        path = exchange / fname
        if not path.exists() or path.stat().st_size == 0:
            if fname in PART_16B and args.allow_partial:
                logging.warning("16b input absent, sheet will show (no data): %s", fname)
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
        loaded[fname] = (headers, rows)
    if failed:
        return 1

    sheets: dict[str, tuple[list[str], list]] = {}
    cand = loaded["name_map_ext_candidates.csv"]
    for sheet, fname in SHEET_SOURCES.items():
        if fname not in loaded:
            continue
        headers, rows = loaded[fname]
        if sheet == "CANDIDATES":
            rows = [r for r in rows if r.get("match_type") != "TYPE_CONFLICT_EXACT"]
        elif sheet == "TYPE_CONFLICTS":
            rows = [r for r in rows if r.get("match_type") == "TYPE_CONFLICT_EXACT"]
        elif sheet == "VALUES_SIDE_BY_SIDE":
            headers, rows = SIDE_HEADERS, side_by_side(rows, cand[1])
        try:
            if sheet != "VALUES_SIDE_BY_SIDE":
                assert_input(sheet, headers, rows)
        except ValueError as exc:
            logging.error("Validation failed: %s", exc)
            return 1
        sheets[sheet] = (headers, rows)

    xlsx_path = qc / "name_map_ext_review.xlsx"
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
    summary_path = logs / "name_map_ext_summary.txt"
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    for line in lines:
        print(line)
    print(f"written: {xlsx_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
