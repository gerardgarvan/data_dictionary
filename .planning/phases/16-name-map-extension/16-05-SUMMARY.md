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
status: "awaiting SAS run"
completed: 2026-11-16
---

# Phase 16 Plan 05: Wiring, run sheet, checkpoint Summary

Phase 16 is wired into the pipeline additively and handed to Gerard with a run sheet. Tasks 1 and 2 are complete; Task 3 (SAS run and candidate decisions) is a human checkpoint and is NOT done.

**Status: awaiting SAS run. PENDING SAS RUN** (16_name_map_ext_test, 16a, 16b, `run_pipeline.cmd 16`). **PENDING DECISION** (every near-match candidate; confirm TYPE_CONFLICT_EXACT reuse). **Price sign-off PENDING.**

## Tasks

| Task | Commit | Result |
|------|--------|--------|
| 1 Wiring | df1cfaa | `_valid` list gains 16; Phase 16 block after Phase 15 (check, 16a, check, 16b); `run_pipeline.cmd` Phase 16 Python block before the log scans; 5 static tests |
| 2 Run sheet and STATE | 2fb7f1f | `16-SAS-RUN.md` (steps 1-4, decision gate i-vi with options and evidence, bring-back list, A1-A16); STATE.md Phase 16 row, next step, assumption line |
| 3 Gerard SAS run | - | PENDING SAS RUN / PENDING DECISION (headless; not waited on) |

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
