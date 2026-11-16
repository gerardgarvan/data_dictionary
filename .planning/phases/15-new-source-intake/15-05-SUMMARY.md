---
phase: 15-new-source-intake
plan: 05
subsystem: pipeline-wiring
tags: [sas, cmd, run-sheet, pending-sas-run]
requires: ["15-01", "15-02", "15-03", "15-04"]
provides:
  - Phase token 15 and 15a/15b/15c block in sas/99_run_all.sas
  - Phase 15 Python block in run_pipeline.cmd
  - python/tests/test_phase15_wiring_static.py
  - .planning/phases/15-new-source-intake/15-SAS-RUN.md
key-files:
  created:
    - python/tests/test_phase15_wiring_static.py
    - .planning/phases/15-new-source-intake/15-SAS-RUN.md
  modified:
    - sas/99_run_all.sas
    - run_pipeline.cmd
    - .planning/STATE.md
decisions: []
metrics:
  tasks: 2 of 3 (Task 3 is a human checkpoint, pending)
  completed: 2026-11-16
requirements-completed: []
---

# Phase 15 Plan 05: Wiring and run sheet Summary

`run_pipeline.cmd 15` now runs 15a, 15b, 15c inside `99_run_all.sas` and then writes `qc\new_source_intake.xlsx`. Gerard's run sheet is written. **Final status: PENDING SAS RUN; PENDING DECISION (new baseline approval; any gate that fires).** Phase 15 is not closed.

## Tasks
1. Additive wiring in `99_run_all.sas` and `run_pipeline.cmd`, plus 5 static tests - bd0135f
2. Run sheet `15-SAS-RUN.md` and STATE.md markers - committed with this summary
3. Checkpoint (human-action): Gerard runs Phase 15 on the SAS machine - **PENDING SAS RUN, not executed**

Verification here: `sas_lint` on `99_run_all.sas` 0 errors (4 pre-existing warnings); `sasjs lint` 0 errors; `ruff check python\` clean; `pytest python\tests` 197 passed, 1 skipped.

## Deviations from Plan
None. The only change to the planned test was reading `sas_lint` output from stderr as well as stdout (the "no errors" line is printed on stderr).

## Checkpoint status
Pending. Gerard follows `15-SAS-RUN.md` Steps 1-5. On resume, Claude records the masked summary here, completes the two `Braden Sensory P` rows in `docs/new_source_header_variants.csv`, and reruns the static suite. No results exist yet; none are claimed.

## Assumptions (headless run)
- Repo is on the SAS machine at `C:\data_dictionary`, branch `pdd-2018-2025-api`; Claude commits locally and never pushes.
- `findstr /i "\<15\>"` does not match the `\<5\>` block (word boundaries); verified by reading, not by running.
- `tools\scan_source_encoding.py` is used unchanged; expected OK for 2023 and ENCODING ERROR for 2024/2025.
- STATE.md was hand-edited (progress note and phase table row); frontmatter untouched; gsd-tools state commands not used (v2.0 format not parsed).
- All A1-A11 are listed in the run sheet.

## Known Stubs
None.

## Self-Check: PASSED
