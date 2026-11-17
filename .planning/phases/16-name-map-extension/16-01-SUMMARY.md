---
phase: 16-name-map-extension
plan: 01
subsystem: name-map
tags: [exchange-contract, openpyxl, review-workbook, privacy-masking]
requires:
  - phase: 15-new-source-intake
    provides: docs/import_spec_new_generated.csv, docs/new_source_header_variants.csv, new_source_qc_workbook.mask_small_count
provides:
  - Fixed exchange contract for the 8 Phase 16 CSVs (docs/exchange_schema.csv, 68 rows)
  - Header-only docs/name_map_decisions_new.csv (separate from Phase 4)
  - Offline proof that every non-exact new header is already in the variants file
  - python/pdd/name_map_ext_workbook.py and python/scripts/write_name_map_ext_review.py
affects: [16-03, 16-04, 16-05]
tech-stack:
  added: []
  patterns: [SAS writes CSV, Python writes xlsx (D-22), counts 1-10 masked as <11]
key-files:
  created:
    - docs/name_map_decisions_new.csv
    - python/pdd/name_map_ext_workbook.py
    - python/scripts/write_name_map_ext_review.py
    - python/tests/test_phase16_docs_static.py
    - python/tests/test_phase16_expectations.py
    - python/tests/test_name_map_ext_workbook.py
  modified:
    - docs/exchange_schema.csv
    - .gitignore
key-decisions:
  - "Decisions file is a separate header-only CSV; Claude records no decisions"
  - "Masking applies to value and coverage counts in the workbook; MIN/MAX/MINLEN/MAXLEN and SHARED_LEVELS counts are not masked"
duration: ~25min
completed: 2026-11-16
---

# Phase 16 Plan 01: Exchange contract and review workbook writer Summary

Fixed the SAS-to-Python contract for the eight Phase 16 exchange CSVs, seeded a header-only decisions file, proved offline that the variants file covers every non-exact new header, and built a tested review-workbook writer (KEY first, UF header fill, side-by-side value distributions, `<11` masking, MAP-02 gate text with Price sign-off PENDING).

Status: complete here; feeds 16-03/16-04/16-05.

## Tasks

| Task | Commit | Result |
|------|--------|--------|
| 1 Decisions seed, schema rows, static and expectation tests | 6e55fdd | 68 schema rows, header-only decisions file, 10 tests |
| 2 name_map_ext_workbook module | 019effa | side_by_side, masking, privacy_safe_summary, write/verify |
| 3 write_name_map_ext_review entry point | 1b6da08 | CLI with --allow-partial, schema validation, masked summary file |

## Verification

- `ruff check python\`: 0 errors.
- Plan 16-01 test modules: all pass (test_phase16_docs_static, test_phase16_expectations, test_name_map_ext_workbook = 20 tests).
- Full suite at last run: 232 passed, 4 failed; the 3 failures in my own test file were fixed afterward (10/10 pass). The one remaining failure, `test_phase16_macros_static.py::test_macros_lint_clean`, belongs to plan 16-02 (concurrent executor; asserts "no errors" text while sas_lint prints "clean -- no errors" with warnings). Not touched here.
- Protected files (`name_map_decisions.csv`, `name_abbrev.csv`, `new_source_header_variants.csv`) unchanged.
- `sasjs lint` not run: no SAS files edited in this plan (A10).

## Offline expectation result

test_predicted_split matched 16-RESEARCH.md exactly: 100 distinct new keys, 90 exact old matches, 10 non-matching headers (preop_edu_years, SleepApnea_YN, Fraility_Category, Fraility_Score, and six BRADEN_2024/2025 headers), all listed in the variants file. No difference to record.

## Deviations from Plan

**1. [Rule 3 - Blocking] .gitignore blanket `*.csv` ignored docs/name_map_decisions_new.csv**
- **Fix:** added `!docs/name_map_decisions_new.csv` exception (metadata only, same pattern as Phase 15 docs).
- **Files:** .gitignore. **Commit:** 6e55fdd.

**2. [Test adjustment] Synthetic pair ids use 11/12 not 1/2** so the plan's "no bare 1..10 after `=`" regex does not match `pair=1` (an id, not a count). Production summary lines print `pair=<id>`; pair ids 1..10 will therefore match that regex on real data, but ids are not counts and are not masked.

## Assumptions (headless run)

A1-A16 from the plan apply unchanged:

| # | Assumption |
|---|-----------|
| A1 | Extension, not rerun: new programs 16a/16b, datasets `pdd.name_map_ext` (4,795 + 282 = 5,077) and `pdd.name_map_vars_ext`; 04_name_map.sas and its datasets read-only |
| A2 | Separate decisions file `docs/name_map_decisions_new.csv`; side a = new (s21-s23), side b = old |
| A3 | Old-source year = spine `pdd.src_s09.YEAR` via `norm_psid`; new files use own YEAR; unmatched IDs to NO_YEAR |
| A4 | Non-missing = Phase 5 rule plus NULL (any case) for char columns of type-conflict variables |
| A5 | Undecided candidates keep blank `pcnr_name`, status PENDING_DECISION; no provisional name |
| A6 | Exact header matches reuse stored name even with type change; listed as TYPE_CONFLICT_EXACT |
| A7 | KEY = `PRECEDE Study ID`; LINKAGE_ONLY = ENCRYPTED_MRN / ENCRYPTED_ENCOUNTER for s21-s23 |
| A8 | Predicted split (about 87 reuse + 3 KEY/LINKAGE + 10 candidate headers) from offline reimplementation; SAS asserts at run time |
| A9 | Value distributions stay on P:; workbook masks 1-10 as `<11`; nothing committed |
| A10 | `sasjs lint` availability checked at execution (no SAS edited here) |
| A11 | 16a does not hard-stop on undecided candidates; Phase 18 must stop on `n_new_pending_decision > 0` |
| A12 | 16b writes `pdd.name_map_coverage` and `pdd.name_map_vars_coverage` |
| A13 | 16a reads committed `docs/import_spec_new_generated.csv`; 16b needs `pdd.nsrc_s21..s23` |
| A14 | Pending variables get `var_key = PENDING:<name_key>` in coverage |
| A15 | Old side of a value comparison = every frozen (s_code, col_order) carrying the old `pcnr_name` |
| A16 | Pipeline token `16` runs 16a, 16b, then the Python writer |

Additional (executor): MIN/MAX/MINLEN/MAXLEN rows and SHARED_LEVELS counts are not masked (they are values or level counts, not case counts); only LEVEL, DISTINCT, N_MISSING and N counts are masked.

## Known Stubs

None.

## Gates

- Near-match naming: PENDING DECISION (Gerard) after 16a runs.
- Price naming sign-off: PENDING.
- Phase 16 SAS runs: PENDING SAS RUN (16-03/16-04/16-05).

## Self-Check: PASSED

Files and commits 6e55fdd, 019effa, 1b6da08 verified present.
