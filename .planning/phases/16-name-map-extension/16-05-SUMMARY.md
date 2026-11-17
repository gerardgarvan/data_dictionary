---
phase: 16-name-map-extension
plan: 05
subsystem: pipeline-wiring
tags: [sas, pipeline, run-sheet, static-tests, checkpoint]
requires:
  - phase: 16-name-map-extension
    provides: 16a, 16b, review writer (16-01..16-04)
provides:
  - "Phase token 16 in sas/99_run_all.sas and run_pipeline.cmd (16a, check, 16b, then write_name_map_ext_review.py)"
  - "16-SAS-RUN.md run sheet with candidate gate options and evidence"
  - "python/tests/test_phase16_wiring_static.py (5 tests)"
affects: [18]
key-files:
  created:
    - python/tests/test_phase16_wiring_static.py
    - .planning/phases/16-name-map-extension/16-SAS-RUN.md
  modified:
    - sas/99_run_all.sas
    - run_pipeline.cmd
    - python/tests/test_phase15_wiring_static.py
    - .planning/STATE.md
    - .planning/ROADMAP.md
requirements: [MAP-01, MAP-02, MAP-03, MAP-04]
status: "complete"
completed: 2026-11-17
---

# Phase 16 Plan 05: Wiring, run sheet, checkpoint Summary

Phase 16 is wired into the pipeline, run by Gerard on 2026-11-17 and **COMPLETE** (MAP-01..04). Price's naming sign-off remains PENDING (unchanged).

## Tasks

| Task | Commit | Result |
|------|--------|--------|
| 1 Wiring | df1cfaa | `_valid` list gains 16; Phase 16 block after Phase 15 (check, 16a, check, 16b); `run_pipeline.cmd` Phase 16 Python block before the log scans; 5 static tests |
| 2 Run sheet and STATE | 2fb7f1f | `16-SAS-RUN.md` (steps 1-4, decision gate i-vi with options and evidence, bring-back list, A1-A16); STATE.md Phase 16 row, next step, assumption line |
| 3 Gerard SAS run | 2026-11-17 | `.un_pipeline.cmd 16`: PIPELINE PASSED, 0 WARNING lines in 99_run_all.log; `name_map_ext_review.xlsx` written |

## Verification (static only)

- `sas_lint sas/99_run_all.sas`: 0 errors (4 pre-existing W1/W2 warnings). `sasjs lint`: 0 errors. `ruff check python\`: clean. `pytest python\tests`: 265 passed.
- Default phase list (`2 3 4`) and Phase 2-7 and 15 blocks unchanged. `16_name_map_ext_test.sas` is not included by 99_run_all.
- Nothing was executed in SAS (no SAS, no P: here).

## Deviations from Plan

**1. [Rule 3 - Blocking] Phase 15 wiring test updated.** `test_phase15_wiring_static.py::test_valid_tokens` pinned the old token list `2 3 4 5 6 7 15`; it now expects `... 15 16`. Committed in df1cfaa.

**2. ROADMAP.md updated by hand** (plan counts and 16-05 line); gsd-tools state advance commands were not used (v2.0 STATE frontmatter, as in earlier Phase 15/16 plans).

## Assumptions (headless run)

- 16-01 A1-A16 apply unchanged (table in `16-SAS-RUN.md`).
- `findstr /i "\<16\>"` does not match the `\<15\>`, `\<5\>` or `\<6\>` blocks (word boundaries); verified by reading.
- Pipeline order for token 16 is check, 16a, check, 16b; 16a is run standalone first because 16b needs `pdd.nsrc_s21..s23`.
- Gate evidence in the run sheet is taken from the plan's candidate list (probe and `docs/new_source_header_variants.csv`); no option was chosen or applied.

## Known Stubs

None.

## Pending results (to paste after Gerard's run)

`logs\name_map_ext_summary.txt`, ERROR/WARNING counts for the 16a, 16b and 99_run_all logs, the Step 1 TESTRESULT line, and the committed `docs/name_map_decisions_new.csv`. Phase 16 closes when the test passes, 16a reports `PASS -- all candidates decided`, 16b coverage is written and the pipeline exits 0.

## Self-Check: PASSED

Files present; commits df1cfaa and 2fb7f1f verified.

## SAS run results (2026-11-17, masked; counts 1-10 shown as <11)

Synthetic test `16_name_map_ext_test.sas`: TESTRESULT SUMMARY ALL TESTS PASSED (T1-T9).

**16a** - PASS, all candidates decided. `n_new_rows` = 282 = key 3 + linkage_only 6 + exact_reuse 255 + same_decided 18 + named 0 + pending_decision 0 (reconciles).

**16b**
- `pdd.qc_map_ext_values`: 1987 rows.
- MAP-04 coverage: 1297 variables, 56 NO_DATA, 0 PENDING keys. `pdd.name_map_coverage` 2279 rows; `pdd.name_map_vars_coverage` 1297 rows.

| Source | Variables | NO_DATA | NO_YEAR cells | Distinct years |
|--------|-----------|---------|---------------|----------------|
| s01 | 2 | 0 | 534 | 5 |
| s02 | 2 | 0 | <11 | 3 |
| s03 | 99 | 0 | 0 | 2 |
| s06 | 1237 | 56 | 8616 | 2 |
| s07 | 102 | 0 | 0 | 2 |
| s08 | 7 | 0 | 0 | 5 |
| s09 | 121 | 0 | 0 | 5 |
| s10 | 111 | 0 | 0 | 1 |
| s11 | 2 | 0 | <11 | 1 |
| s12 | 83 | 0 | 0 | 1 |
| s13 | 1 | 0 | 0 | 1 |
| s14 | 5 | 0 | 0 | 1 |
| s15 | 81 | 0 | 0 | 1 |
| s16 | 1 | 0 | 0 | 1 |
| s17 | 81 | 0 | 0 | 1 |
| s18 | 3 | 0 | 807 | 1 |
| s19 | 65 | 0 | 0 | 3 |
| s20 | 3 | 0 | 0 | 5 |
| s21 | 91 | 0 | 0 | 1 |
| s22 | 91 | 0 | 0 | 1 |
| s23 | 91 | 0 | 0 | 1 |

- s04 and s05 have no coverage line: confirmed by design. `16b_name_map_values_cov.sas` selects only status PCNR or PENDING_DECISION columns per source and, when a source has none, logs "has no mapped variables -- skipped" (line 404). s04 and s05 have no mapped PCNR/pending columns in `pdd.name_map_ext`.
- **Observation for Phase 18:** all 56 NO_DATA variables are in s06. This is not a failure; the dictionary should flag them.

## Fixes made during the 2026-11-17 run (already committed by Gerard)

- `16_name_map_ext_test.sas`: T2/T3 DATA step had no driving SET and `%p16_shorten` reads with `SET ... POINT=`, so the step never ended and filled the C: drive (WORK). Added `stop;`. Column `case` renamed `tcase` (CASE is reserved in PROC SQL; T2/T3 SQL checks failed with 22-322).
- `16b_name_map_values_cov.sas`: generated coverage step declares placeholders `_p16_dn 8` and `_p16_dc $1` before `array _an[*] _numeric_` / `array _ac[*] _character_`, removing 5 "Defining an array with zero elements" warnings (s08, s13 and three others).

## Lint rules added at close

- C31 (SET ... POINT= without STOP) and C32 (PROC SQL reserved word as column) in `tools/sas_lint.py`, with tests in `python/tests/test_sas_lint.py`. Over `sas/*.sas`: 0 hits for both (no true positives to fix). Replaying the pre-fix test file (99991a5^) fires C31 once and C32 six times. See CLAUDE.md pitfalls.

## Assumptions (headless run)

- Run results were taken from the prompt text; no log or data files were read (no P: or SAS here).
- C31/C32 are heuristics: C31 ignores `if 0 then set` (attribute-only) and quoted text; C32 only checks files that contain PROC SQL.
