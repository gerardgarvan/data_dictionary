---
phase: 02-source-guard-and-header-inventory
plan: "01"
subsystem: source-guard
tags: [sas, sha256, hash-baseline, file-metadata, source-inventory]
dependency_graph:
  requires: [01-02]
  provides: [pdd.source_inventory, docs/source_guard_baseline.csv, 02_source_guard.sas scaffold]
  affects: [02-02, 02-03]
tech_stack:
  added: []
  patterns:
    - certutil PIPE FILEVAR= SHA-256 for binary files (CSV and XLSX)
    - FOPEN/FINFO for file_size and mod_date metadata
    - Two-branch hash baseline guard (seed-or-compare) inside a named macro
    - PCM compliance: no open-code %IF, %abort cancel only in %fail_out
key_files:
  created:
    - C:\data_dictionary\sas\02_source_guard.sas
    - C:\data_dictionary\docs\.gitkeep
  modified: []
decisions:
  - Two older-copy roots searched (raw\master primary, raw\ secondary) per plan spec; both defined locally in 02_source_guard.sas, not added to 00_config.sas
  - source_guard_baseline.csv placed on C: drive at docs/source_guard_baseline.csv for git traceability (Pitfall 5 from RESEARCH)
  - mod_date stored as raw $30 character string without parsing (Pitfall 7 from RESEARCH)
  - %restore_log intentionally omitted from this plan; added by Plan 03 final task
metrics:
  duration_minutes: 25
  completed_date: "2026-10-19"
  tasks_completed: 3
  tasks_total: 3
  files_created: 2
  files_modified: 0
---

# Phase 2 Plan 01: Source Guard and File-Level Audit Foundation Summary

**One-liner:** SHA-256 hash guard for 20 shared-folder source files using certutil PIPE FILEVAR=, with seed-or-compare baseline logic and pdd.source_inventory assembly (file_size, mod_date, sha256, old_copy_status).

## What Was Built

`C:\data_dictionary\sas\02_source_guard.sas` (434 lines) implements sections 0-5, 7, 11, and 12 of the Phase 2 scaffold:

- **Section 0:** `%include "C:\data_dictionary\sas\00_config.sas"` as first executable statement; `%pdd_lib;`; `raw_master_old` and `raw_master_old2` defined locally
- **Section 1:** Four named utility macros: `%route_log`, `%restore_log`, `%fail_out`, `%check_dir`; `%abort cancel` appears exactly once inside `%fail_out`
- **Section 2:** Preconditions — `docs/` directory creation via `options dlcreatedir`, `%check_dir` assertions for `&raw_master`, `&qc_path`, `&logs_path`
- **Section 3:** `work.file_list` — 20-row DATALINES block (s01-s20) with correct filenames from PROJECT.md
- **Section 4:** `work.files_meta` — FOPEN/FINFO metadata (`file_size` numeric, `mod_date` $30 raw string)
- **Section 5:** `work.sha_results` — certutil SHA-256 loop; `%assert_hashes_ok` macro validates no FAILED values
- **Section 7:** `work.sha_old` — older-copy hash comparison against `raw_master_old` (primary) and `raw_master_old2` (secondary); non-recursive filename-only join
- **Section 11:** `%run_hash_guard` — two-branch seed-or-compare logic; seeds `docs/source_guard_baseline.csv` on first run; aborts on drift on subsequent runs
- **Section 12:** `pdd.source_inventory` — DATA step merge of all component datasets; `old_copy_status` derived inline (identical/different/no_older_copy); `%assert_inventory_rows` confirms 20 rows

## Tasks

| Task | Name | Commit | Key Output |
|------|------|--------|------------|
| 1 | Scaffold, utility macros, file list, metadata loop | 8aa690c | 02_source_guard.sas sections 0-4 |
| 2 | SHA-256 loop and two-branch hash baseline guard | fcc7bc2 | sections 5, 7, 11; docs/.gitkeep |
| 3 | Assemble pdd.source_inventory | 8ed8bb7 | section 12; pdd.source_inventory (runtime) |

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

### Notes

- All three task sections were implemented in a single file write (the SAS program is one coherent artifact spanning all tasks). Commits are logically grouped by task section to preserve traceability.
- `%restore_log` is intentionally absent per plan spec — Plan 03's final task appends it.
- The `docs/` directory is created at runtime via `options dlcreatedir` in Section 2; `docs/.gitkeep` ensures the directory is tracked in git before the first program run.

## Known Stubs

None. `pdd.source_inventory` is a fully-wired runtime output — all columns are derived from actual file I/O (FINFO, certutil). No placeholder or hardcoded values flow to the table.

Import-derived columns (row_count, col_count, sheet_list) are explicitly deferred to Plan 02 per plan spec — this is intentional and documented.

## Self-Check: PASSED

- `C:\data_dictionary\sas\02_source_guard.sas` exists (434 lines)
- `C:\data_dictionary\docs\.gitkeep` exists
- Commits 8aa690c, fcc7bc2, 8ed8bb7 verified in git log
- `%include "C:\data_dictionary\sas\00_config.sas"` is first executable statement (line 64)
- `raw_master_old` and `raw_master_old2` both defined at lines 66-67
- `%macro route_log`, `%macro fail_out`, `%macro check_dir` all present
- `%abort cancel` appears exactly once (line 95, inside `%fail_out`)
- All 20 s01-s20 codes present in DATALINES block (lines 146-165)
- `certutil -hashfile` and `pipe filevar=_cmd` both present
- `%macro run_hash_guard` and `%macro assert_hashes_ok` both present
- `source_guard_baseline.csv` hardcoded to C: drive path
- `pdd.source_inventory` write present; `%macro assert_inventory_rows` present
- `old_copy_status` values: 'no_older_copy', 'identical', 'different' all present
- No PROC SQL UPDATE in file
- No open-code `%if` outside a `%macro`...`%mend` block
