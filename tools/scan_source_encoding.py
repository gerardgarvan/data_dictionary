"""
Scan source CSV files for non-UTF-8 byte sequences.

Usage:
    python tools/scan_source_encoding.py [SOURCE_DIR] [--check SPEC_CSV]

SOURCE_DIR: path to the master data folder (default: P:\\PeCAN Master Data\\
            00 Shared Data\\DSS Received Data\\1 Data Files\\Master Data)

--check SPEC_CSV: also verify each file appears in import_spec_generated.csv
                  with the correct src_encoding field.

Exit 0 if all files are clean, exit 1 if any encoding issues are found.
No data values are printed -- only file, line number, byte offset, and hex.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

DEFAULT_SOURCE_DIR = (
    r"P:\PeCAN Master Data\00 Shared Data"
    r"\DSS Received Data\1 Data Files\Master Data"
)


def scan_file(path: Path) -> list[tuple[int, int, bytes]]:
    """Return list of (line_number, byte_offset, hex_bytes) for non-UTF-8 sequences."""
    issues: list[tuple[int, int, bytes]] = []
    raw = path.read_bytes()
    line_no = 1
    line_start = 0
    i = 0
    while i < len(raw):
        b = raw[i]
        # Determine expected UTF-8 sequence length
        if b < 0x80:
            if b == 0x0A:
                line_no += 1
                line_start = i + 1
            i += 1
            continue
        if b < 0xC2:
            # Invalid lead byte (0x80-0xBF = continuation without lead; 0xC0-0xC1 = overlong)
            issues.append((line_no, i - line_start, bytes([raw[i]])))
            i += 1
            continue
        if b < 0xE0:
            seq_len = 2
        elif b < 0xF0:
            seq_len = 3
        elif b < 0xF5:
            seq_len = 4
        else:
            issues.append((line_no, i - line_start, bytes([raw[i]])))
            i += 1
            continue
        seq = raw[i : i + seq_len]
        try:
            seq.decode("utf-8")
        except UnicodeDecodeError:
            issues.append((line_no, i - line_start, seq))
        i += seq_len
    return issues


def load_spec(spec_csv: Path) -> dict[str, str]:
    """Return mapping of filename -> src_encoding from import_spec_generated.csv."""
    spec_map: dict[str, str] = {}
    # We need filename per file_code.  The spec has file_code not filename.
    # Read from the spec's file_list embedded in 03_import context is not available here.
    # Instead: read all rows and return file_code -> src_encoding for --check validation.
    with spec_csv.open(encoding="utf-8", errors="strict", newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            fc = row.get("file_code", "").strip()
            enc = row.get("src_encoding", "utf-8").strip() or "utf-8"
            if fc:
                # Store first occurrence per file_code
                if fc not in spec_map:
                    spec_map[fc] = enc
    return spec_map


# s_code -> expected encoding for 7 wlatin1 files (from D-23 decision)
WLATIN1_FILES = {
    "2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv",
    "2018_2019_X_MASTER_DATASET_20200801.csv",
    "2018_2022_X_MASTER_DATASET_20240402.csv",
    "2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv",
    "2020_X_MASTER_DATASET_20210519.csv",
    "2021_X_MASTER_DATASET_20230512.csv",
    "2022_MASTER_DATASET_20231024.csv",
}

# s_code -> filename mapping (from work.file_list in 03a_build_spec.sas)
SCODE_TO_FILE = {
    "s03": "2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv",
    "s07": "2018_2019_X_MASTER_DATASET_20200801.csv",
    "s09": "2018_2022_X_MASTER_DATASET_20240402.csv",
    "s10": "2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv",
    "s12": "2020_X_MASTER_DATASET_20210519.csv",
    "s15": "2021_X_MASTER_DATASET_20230512.csv",
    "s17": "2022_MASTER_DATASET_20231024.csv",
}
FILE_TO_SCODE = {v: k for k, v in SCODE_TO_FILE.items()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "source_dir",
        nargs="?",
        default=DEFAULT_SOURCE_DIR,
        help="Path to source CSV directory",
    )
    parser.add_argument(
        "--check",
        metavar="SPEC_CSV",
        help="Path to import_spec_generated.csv; enables spec encoding verification",
    )
    args = parser.parse_args()

    source_dir = Path(args.source_dir)
    if not source_dir.exists():
        print(f"ERROR: source directory not found: {source_dir}")
        return 1

    spec_enc: dict[str, str] | None = None
    if args.check:
        spec_path = Path(args.check)
        if not spec_path.exists():
            print(f"ERROR: spec CSV not found: {spec_path}")
            return 1
        spec_enc = load_spec(spec_path)

    csv_files = sorted(source_dir.glob("*.csv"))
    if not csv_files:
        print(f"NOTE: no CSV files found in {source_dir}")
        return 0

    any_issue = False

    for csv_path in csv_files:
        fname = csv_path.name
        expected_enc = "wlatin1" if fname in WLATIN1_FILES else "utf-8"

        # --check mode: verify spec has correct encoding for this file
        if spec_enc is not None:
            sc = FILE_TO_SCODE.get(fname)
            if sc is not None:
                spec_val = spec_enc.get(sc, "")
                if spec_val and spec_val != expected_enc:
                    print(
                        f"CHECK FAIL: {fname} (s_code={sc})"
                        f" expected src_encoding={expected_enc}"
                        f" but spec has {spec_val}"
                    )
                    any_issue = True

        # For wlatin1 files: non-UTF-8 bytes are expected -- skip UTF-8 scan
        if expected_enc == "wlatin1":
            print(f"SKIP (wlatin1): {fname}")
            continue

        issues = scan_file(csv_path)
        if issues:
            any_issue = True
            for line_no, col_idx, seq in issues:
                hex_str = seq.hex(" ")
                # No data values printed -- only location and hex
                print(
                    f"ENCODING ERROR: {fname}"
                    f" line {line_no} col {col_idx}"
                    f" hex [{hex_str}]"
                )
        else:
            print(f"OK: {fname}")

    return 1 if any_issue else 0


if __name__ == "__main__":
    sys.exit(main())
