---
phase: 02-source-guard-and-header-inventory
plan: "02"
subsystem: source-import
tags: [sas, import, inventory, key-detection, grain-analysis, id-overlap]
dependency_graph:
  requires: [02-01]
  provides: [pdd.header_inventory, pdd.key_analysis, pdd.id_overlap, pdd.source_inventory-enriched]
  affects: [02-03, phase-03, phase-05]
tech_stack:
  added: []
  patterns:
    - XLSX engine (not PROC IMPORT) for all XLSX files
    - dictionary.columns / dictionary.tables for post-import metadata
    - certutil-style macro loop (eval_import + syscc reset)
    - sheet_map accumulator for cross-phase sheet-ds lookups
    - Spine normalisation: strip() for char, cats(strip(put(x,20.))) for numeric
key_files:
  created: []
  modified:
    - sas/02_source_guard.sas
decisions:
  - XLSX files use the XLSX engine exclusively (no PROC IMPORT) per Pitfall 4
  - sheet_map work dataset built during import to enable deterministic grain/overlap lookups without monotonic() fragility
  - nonblank_row_count computed before INSERT to avoid PROC SQL UPDATE (PCM compliance)
  - s09 self-overlap assertion set at 99.5 pct threshold
  - NONE_DETECTED sentinel rows emit WARNING, not %fail_out, so program continues
metrics:
  duration_minutes: ~45
  completed_date: "2026-10-19"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 1
---

# Phase 02 Plan 02: Import Loop, Header Inventory, Key Analysis, ID Overlap — Summary

**One-liner:** SAS macro loop imports all 20 source files (CSV via PROC IMPORT, XLSX via XLSX engine all sheets), builds pdd.header_inventory (file x sheet x column), pdd.key_analysis (candidate key grain per file), pdd.id_overlap (match counts against s09 and s04/s05 crosswalk spines), and enriches pdd.source_inventory with row/col counts and import status.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Import loop + header inventory + enrich source_inventory | 742ec93 | sas/02_source_guard.sas (SECTION 6) |
| 2 | Candidate key detection and grain analysis | 742ec93 | sas/02_source_guard.sas (SECTIONS 8-9) |
| 3 | ID overlap against the s09 spine | 742ec93 | sas/02_source_guard.sas (SECTION 10) |

All three tasks committed together (single file, single atomic addition).

## What Was Built

### SECTION 6 — Import + Header Inventory

- `%eval_import(target=)` macro: checks `&syserr le 4`, sets fstatus/freason, resets `%let syscc=0`.
- `%macro import_all_files`: loops file_id 1..20 from `work.file_list`.
  - **CSV branch**: `options nosyntaxcheck noerrorabend` before each `proc import dbms=csv guessingrows=max`. Raw first-line header captured via `infile obs=1 dsd dlm=','` into `original_header`. Pitfall 6 duplicate-header check on original header text; s15/s17 post-import column name check.
  - **XLSX branch**: `libname _xlw path 'xlsx'` then `dictionary.members where libname='_XLW' and memtype='DATA'` to enumerate all sheets. Letter-start sheets read via unquoted SAS name (`set _xlw.&&_sh&j`); digit-prefix via `%unquote(%superq(...))` name literal (Pitfall 1 guard). Every sheet is imported (no first-sheet-only shortcut).
  - s19 `nonblank_row_count` computed in a DATA step BEFORE the INSERT (not via PROC SQL UPDATE — PCM compliance).
  - `work.sheet_map` accumulator stores `s_code + sheet_name -> work dataset name` for deterministic lookup in grain/overlap sections.
  - s09 row count: unconditional NOTE, WARNING only if outside 41,000-42,000.
- `pdd.header_inventory`: one row per file x sheet x column (s_code, sheet_name blank for CSV, col_name, col_type as 'char'/'num', col_label, col_len).
- Benchmark NOTEs: 7-CSV rows (~701), 7-CSV distinct col_name (~168), all-20 totals.
- `pdd.source_inventory` re-assembled (not in-place rewrite): merged with `work.counts_all` aggregate to add row_count, col_count, sheet_list, import_status, import_reason, nonblank_row_count. `%assert_inventory_rows` still passes (20 rows).

### SECTION 8 — Candidate Key Detection

- PROC SQL over `pdd.header_inventory` assigns `key_column_type` using `compress(upcase(col_name),' _-')` patterns:
  - `PRECEDE_STUDY_ID`: PRECEDESTUDYID, STUDYID, PRECEDEID
  - `ENCRYPTED_MRN`: ENCRYPTEDMRN or contains ENCRYPTED + MRN
  - `ENCRYPTED_ENCOUNTER`: contains ENCRYPTED + ENCOUNTER
  - `UNENC_MRN`: bare MRN
  - `UNENC_ENCOUNTER`: ENCOUNTER or ENCOUNTERID
  - `RECORD_ID`: RECORDID
  - Label-based fallbacks for all above types
- Left join against all file x sheet combinations ensures every file x sheet has at least one row.
- `NONE_DETECTED` sentinel: emits `%put WARNING:` (not `%fail_out`); program continues.
- `match_basis` flag: 'name', 'loose' (bare STUDYID), or 'label'.

### SECTION 9 — Grain Test

- Loops over `pdd.key_analysis` rows where `key_column_type ne 'NONE_DETECTED'`.
- Uses `work.sheet_map` to locate the correct work dataset per sheet.
- `COUNT(*) into :_n_rows` and `COUNT(DISTINCT key_var) WHERE non-missing into :_n_dist`.
- DATA step assigns `grain = 'unique'` if n_rows = n_distinct, else `'multi-row'`.
- NONE_DETECTED rows pass through with n_rows/n_distinct/grain missing.
- s01 and s08 grain logged as informational NOTEs (not assertions).
- `%macro assert_key_analysis`: fails via %fail_out only if pdd.key_analysis has zero total rows.

### SECTION 10 — ID Overlap

- Three primary spine tables from `work.src_s09`: `work.spine_psid`, `work.spine_mrn`, `work.spine_enc`.
  - Char columns: `strip(x)` normalisation. Numeric columns: `cats(strip(put(x,20.)))`. Never upcase() a numeric.
- Secondary spine tables for s04/s05 crosswalk testing: `spine_s16_mrn`, `spine_s17_psid`, `spine_s18_psid`.
- `%macro _compute_overlap`: computes n_in_file (distinct non-missing keys), n_matching_spine (inner join to spine), pct_overlap with divide-by-zero guard.
- spine_source column distinguishes 's09', 's16', 's17', 's18'.
- s04 and s05 compute overlap against ALL four spines; NOTEs echo their counts for PDD-D-18.
- `%macro assert_overlap`: fails if zero rows OR if s09/PRECEDE_STUDY_ID self-overlap < 99.5%.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PROC SQL UPDATE replaced with pre-computed INSERT**
- **Found during:** Task 1 implementation review
- **Issue:** Two PROC SQL UPDATE statements (for nonblank_row_count and sheet_list) violated PCM compliance rule "No PROC SQL UPDATE"
- **Fix:** nonblank_row_count computed before the INSERT and included as a column value; sheet_list UPDATE removed as redundant (already in INSERT)
- **Files modified:** sas/02_source_guard.sas
- **Commit:** 742ec93

**2. [Rule 1 - Bug] monotonic()-based sheet index lookup replaced**
- **Found during:** Task 2/3 implementation
- **Issue:** Sheet-to-dataset mapping in grain test and overlap loop used `monotonic()` function in a subquery, which is unreliable in PROC SQL
- **Fix:** Added `work.sheet_map` accumulator during XLSX import to store `s_code + sheet_name -> work dataset name`; grain test and overlap loop read from sheet_map
- **Files modified:** sas/02_source_guard.sas
- **Commit:** 742ec93

**3. [Rule 1 - Bug] Spurious rename no-op removed**
- **Found during:** Code review
- **Issue:** `set work.key_grain_base(rename=(key_var_name=key_var_name))` was a no-op that would generate a SAS warning
- **Fix:** Removed the rename option
- **Files modified:** sas/02_source_guard.sas
- **Commit:** 742ec93

## Known Stubs

None. All columns are populated from live import data.

## Self-Check: PASSED

- sas/02_source_guard.sas: FOUND
- .planning/phases/02-source-guard-and-header-inventory/02-02-SUMMARY.md: FOUND
- Commit 742ec93: FOUND
