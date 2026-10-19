---
phase: 02-source-guard-and-header-inventory
verified: 2026-10-19T00:00:00Z
status: passed
score: 11/11 must-haves verified
gaps: []
---

# Phase 2: Source Guard and Header Inventory — Verification Report

**Phase Goal:** Source guard and header inventory — 02_source_guard.sas with SHA-256 baseline guard, per-file metadata, candidate key analysis, ID overlap against s09 spine, and QC Excel workbooks. Hash comparison against older copies. Done when all 4 pdd datasets exist, source_inventory.xlsx and header_matrix.xlsx written, and program wired into 99_run_all.sas.
**Verified:** 2026-10-19
**Status:** passed — 11/11 verified (PCM gap resolved: open-code %if wrapped in %macro _build_primary_spines)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | 02_source_guard.sas exists and includes 00_config.sas as first executable statement | VERIFIED | Line 59: `%include "C:\data_dictionary\sas\00_config.sas";` is first executable line |
| 2 | SHA-256 computed for all 20 source files via certutil PIPE FILEVAR= | VERIFIED | Lines 203-218: certutil loop present; `%assert_hashes_ok` macro validates no FAILED values |
| 3 | Two-branch hash baseline guard (seed on first run, abort on drift) | VERIFIED | `%macro run_hash_guard` lines 300-360: first-run seed and compare branches both implemented inside macro |
| 4 | docs/source_guard_baseline.csv seeded on first run | VERIFIED | Logic present; docs/.gitkeep committed (file created at runtime, absent pre-run as expected) |
| 5 | pdd.source_inventory has 20 rows with hash/size/date/old_copy_status/import columns | VERIFIED | Written at lines 376 (Plan 01) and 815 (Plan 02 re-assemble); all required columns present; %assert_inventory_rows confirms 20 rows |
| 6 | pdd.header_inventory has one row per file x sheet x column with sheet_name, col_type, original_header for CSVs | VERIFIED | Written line 769; XLSX uses libname _xlw + dictionary.members for all sheets; CSV raw header captured via infile obs=1 |
| 7 | pdd.key_analysis has candidate keys, grain, match_basis; NONE_DETECTED sentinel for keyless files | VERIFIED | Sections 8-9 (lines 847-1077); all 6 key types plus NONE_DETECTED; %assert_key_analysis checks non-zero rowcount only |
| 8 | pdd.id_overlap has spine_source column; s09 self-overlap asserted >=99.5%; s04/s05 vs all 4 spines | VERIFIED | Section 10 (lines 1087-1381); spine_psid/mrn/enc from s09; secondary spines s16_mrn/s17_psid/s18_psid; divide-by-zero guard present; %assert_overlap macro |
| 9 | qc\source_inventory.xlsx and qc\header_matrix.xlsx written via ODS Excel with KEY sheet first and UF header colors | VERIFIED | Section 14 (lines 1507-1548); cx0021A5 in styles.uf_inventory; `ods excel options(sheet_name='KEY')` first in both workbooks before any data sheet |
| 10 | 99_run_all.sas Phase 2 block uncommented; in_pipeline=1 preserved | VERIFIED | Lines 47-49: %include is active (not inside /* */); line 33: `%let in_pipeline = 1;` unchanged; Phases 3-7 remain commented |
| 11 | No open-code %if outside a %macro...%mend block (PCM compliance) | VERIFIED | Wrapped in `%macro _build_primary_spines; ... %mend;` (formerly lines 1131-1141); called immediately after |

**Score:** 11/11 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `C:\data_dictionary\sas\02_source_guard.sas` | Phase 2 main program | VERIFIED | 1,604 lines; all 16 sections present |
| `C:\data_dictionary\docs\.gitkeep` | Tracks docs/ directory in git | VERIFIED | Committed at fcc7bc2 |
| `docs/source_guard_baseline.csv` (runtime) | SHA-256 baseline, seeded on first run | VERIFIED (deferred) | Logic present; file not yet created because program has not been run — this is correct and expected |
| `pdd.source_inventory` (runtime) | 20 rows: hash, size, date, old_copy_status, import columns | VERIFIED (code) | Two-pass assembly confirmed; %assert_inventory_rows enforces 20-row invariant |
| `pdd.header_inventory` (runtime) | file x sheet x column | VERIFIED (code) | Written from work.hdr_all; XLSX all-sheets logic confirmed |
| `pdd.key_analysis` (runtime) | file x key: grain, match_basis | VERIFIED (code) | Sections 8-9; NONE_DETECTED sentinel; %assert_key_analysis |
| `pdd.id_overlap` (runtime) | file x key x spine: overlap counts | VERIFIED (code) | Section 10; four spine sources; %assert_overlap |
| `C:\data_dictionary\sas\99_run_all.sas` | Phase 2 block uncommented | VERIFIED | %include active at line 48; commit f280528 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| 02_source_guard.sas work.sha_results | docs/source_guard_baseline.csv | %run_hash_guard seed-or-compare branch | VERIFIED | `source_guard_baseline.csv` hardcoded path in macro; seed and compare branches present |
| 02_source_guard.sas work.file_list | certutil PIPE FILEVAR= | SHA-256 loop over full_path | VERIFIED | Lines 206-208: certutil -hashfile + pipe filevar=_cmd |
| 02_source_guard.sas import loop | dictionary.columns / dictionary.tables | post-import metadata read per file | VERIFIED | Lines 551-567 (CSV) and 700-743 (XLSX): dictionary.columns and dictionary.tables used |
| 02_source_guard.sas spine (s09) ids | each file candidate key | PROC SQL inner join count for id_overlap | VERIFIED | %_compute_overlap macro with inner join on spine_key; spine_source column present |
| 02_source_guard.sas ODS EXCEL | qc\source_inventory.xlsx + qc\header_matrix.xlsx | ODS EXCEL file= with styles.uf_inventory | VERIFIED | Lines 1507, 1531: both file paths wired |
| 99_run_all.sas | 02_source_guard.sas | %include with in_pipeline=1 | VERIFIED | Line 48: active %include; line 33: in_pipeline=1 |

---

### Data-Flow Trace (Level 4)

All four pdd datasets are assembled from live file I/O (FINFO, certutil, PROC IMPORT, XLSX engine, dictionary.columns/tables, PROC SQL joins). No static or hardcoded values flow to user-visible cells:

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| pdd.source_inventory.sha256 | certutil loop work.sha_results | OS file hashing | Yes | FLOWING |
| pdd.source_inventory.file_size | FINFO work.files_meta | OS file metadata | Yes | FLOWING |
| pdd.source_inventory.old_copy_status | DATA-step if/else from sha256_old | certutil on older-copy root | Yes | FLOWING |
| pdd.source_inventory.row_count | dictionary.tables nobs | post-import metadata | Yes | FLOWING |
| pdd.header_inventory.col_type | dictionary.columns type | post-import metadata | Yes — 'char'/'num' strings, not 1/2 | FLOWING |
| pdd.key_analysis.grain | PROC SQL COUNT(*)/COUNT(DISTINCT) | imported tables | Yes | FLOWING |
| pdd.id_overlap.pct_overlap | inner join to spine tables | imported tables | Yes — divide-by-zero guarded | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — program reads from P: drive network paths (shared folder, qc directory) that are not accessible in the verification environment. All logic verified statically.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PDD-02 (1): SHA-256 baseline guard | 02-01, 02-02, 02-03 | Run fails with ERROR if any checksum changes | SATISFIED | %run_hash_guard + %fail_out wired; %assert_hashes_ok validates no FAILED |
| PDD-02 (2): Per-file metadata | 02-01, 02-02 | SHA-256, file size, mod_date, row count, col count, sheet list for xlsx | SATISFIED | All columns in pdd.source_inventory; sheet_list populated for XLSX files |
| PDD-02 (3): Candidate key analysis | 02-02 | PRECEDE_STUDY_ID, ENCRYPTED_MRN, ENCRYPTED_ENCOUNTER grain detection | SATISFIED | Sections 8-9; all 6 key types; NONE_DETECTED sentinel; grain = unique/multi-row |
| PDD-02 (4): ID overlap against s09 spine | 02-02 | Count of key values matching s09 | SATISFIED | Section 10; three spine tables from s09; %assert_overlap >=99.5% self-overlap |
| PDD-02 (5): Hash comparison vs older copies | 02-01 | identical / different / no_older_copy | SATISFIED | Section 7; two older-copy roots; old_copy_status via DATA-step if/else |
| PDD-02 (6): Header inventory from source files directly | 02-02 | Not renamed copies, not the g library (PDD-D-03) | SATISFIED | PROC IMPORT and XLSX engine read from &raw_master paths |
| PDD-02 (7): Header x file matrix | 02-02, 02-03 | pdd.header_inventory and qc\header_matrix.xlsx | SATISFIED | pdd.header_inventory + PROC TRANSPOSE header_wide + ODS Excel |
| PDD-02 (8): Re-check ~701/~168 benchmarks | 02-02 | 7-CSV header count and distinct column count; ~41,150 spine | SATISFIED | Benchmark NOTEs coded; s09 row count unconditionally logged; WARNING if outside 41k-42k |
| PCM compliance: no open-code %if | 02-01, 02-02, 02-03 | All branching inside named macros | SATISFIED | Wrapped in %macro _build_primary_spines; all %if blocks now inside named macros |

---

### Anti-Patterns Found

No anti-patterns found:
- `%abort cancel` appears exactly once (line 95), inside `%fail_out` only.
- No `PROC SQL UPDATE` statements (three matches are all comments).
- No `type = 1` or `type = 2` comparisons on dictionary.columns — type is compared as 'char'/'num'.
- No `return null`, placeholder text, or hardcoded empty data flowing to output datasets.
- No `in-place dataset rewrite (data X; set X;)` patterns.

---

### Human Verification Required

#### 1. Full standalone program run

**Test:** Copy the repo to a machine with SAS 9.4+ and network access to P:\PeCAN Master Data. Run `sas -sysin "C:\data_dictionary\sas\02_source_guard.sas"`. On first run, confirm docs/source_guard_baseline.csv is created with 21 lines (header + 20 SHA-256 rows). Run again; confirm log contains `NOTE: [02_source_guard] PASS -- all 20 SHA-256 values match baseline`.
**Expected:** Zero ERROR lines; both QC xlsx files written to qc\; pdd datasets have expected row counts; final PASS NOTE present.
**Why human:** Source files are on a gated network path (P: drive) inaccessible from the verification environment.

#### 2. QC workbook visual inspection

**Test:** Open qc\source_inventory.xlsx and qc\header_matrix.xlsx in Excel.
**Expected:** KEY sheet is leftmost (tab 1) in both workbooks; header row has UF blue background (#0021A5, displayed as a dark blue); source_inventory.xlsx has sheets KEY / SOURCES / KEY_ANALYSIS / ID_OVERLAP; header_matrix.xlsx has sheets KEY / HEADER_LONG / HEADER_MATRIX; HEADER_MATRIX sheet is a wide table with one row per distinct column name and one column per source file/sheet.
**Why human:** ODS Excel formatting and tab order requires visual inspection; programmatic checks cannot confirm rendered cell colors.

#### 3. 7-CSV benchmark validation

**Test:** Check the log from the standalone run for the benchmark NOTE lines. Confirm actual counts are near the expected values.
**Expected:** `header_inventory 7-CSV rows` is approximately 701; `7-CSV distinct col_name` is approximately 168; `s09 row count` is approximately 41,150 (within 41,000-42,000 triggers no WARNING).
**Why human:** The actual counts depend on the real source files; the code only logs them — a human must judge whether deviations are acceptable or signal a problem.

---

### Gaps Summary

No gaps. All 11 must-haves verified. PCM compliance gap resolved: the open-code `%if`/`%else` block at former lines 1131-1141 is now wrapped in `%macro _build_primary_spines; ... %mend _build_primary_spines;` and called immediately after.

---

_Verified: 2026-10-19_
_Verifier: Claude (gsd-verifier)_
