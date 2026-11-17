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
  tasks: 3 of 3
  completed: 2026-11-16
requirements-completed: [NEW-01, NEW-02, NEW-03, NEW-03a, NEW-04, NEW-05]
---

# Phase 15 Plan 05: Wiring and run sheet Summary

`run_pipeline.cmd 15` now runs 15a, 15b, 15c inside `99_run_all.sas` and then writes `qc\new_source_intake.xlsx`. Gerard's run sheet is written. **Final status: COMPLETE 2026-11-16.** Gerard's SAS run finished; Phase 15 is closed.

## Tasks
1. Additive wiring in `99_run_all.sas` and `run_pipeline.cmd`, plus 5 static tests - bd0135f
2. Run sheet `15-SAS-RUN.md` and STATE.md markers - committed with this summary
3. Checkpoint (human-action): Gerard ran Phase 15 on the SAS machine - done (see Results)

Verification here: `sas_lint` on `99_run_all.sas` 0 errors (4 pre-existing warnings); `sasjs lint` 0 errors; `ruff check python\` clean; `pytest python\tests` 197 passed, 1 skipped.

## Deviations from Plan
None. The only change to the planned test was reading `sas_lint` output from stderr as well as stdout (the "no errors" line is printed on stderr).

## Results (Gerard's SAS run, masked summary, verbatim)
GUARD MATCH x3; ROWCOUNTS MATCH x3 (10772/13029/12689); ONE_TO_ONE PASS x3; PAIRWISE_NEW 0/0/142 DECIDED (PDD-D-30); SPINE 0 x3; OLD20_UNION 0 x3; TYPE_CHANGES 138; NONASCII cells 0/18/26; GATE PDD-D-29 item 3 PASS; GATE OLD20_UNION PASS; GATE 1:1 PASS.

- 15a: baseline approved and committed. 15b: spec committed (`docs/import_spec_new_generated.csv`). 15c: PASS after PDD-D-30.
- `run_pipeline.cmd 15` passed (Pipeline PASSED 2026-11-16 17:11); `qc
ew_source_intake.xlsx` written; git tree clean after the pipeline's 15b rerun, so the committed spec is unchanged.
- Closing checks here: `pytest python\tests` 208 passed; `ruff check python\` clean; `sas_lint` on `15a`/`15b`/`15c` and `99_run_all.sas` 0 errors (warnings only).

## Assumptions (headless run)
- Repo is on the SAS machine at `C:\data_dictionary`, branch `pdd-2018-2025-api`; Claude commits locally and never pushes.
- `findstr /i "\<15\>"` does not match the `\<5\>` block (word boundaries); verified by reading, not by running.
- `tools\scan_source_encoding.py` is used unchanged; expected OK for 2023 and ENCODING ERROR for 2024/2025.
- STATE.md was hand-edited (progress note and phase table row); frontmatter untouched; gsd-tools state commands not used (v2.0 format not parsed).
- All A1-A11 are listed in the run sheet.

## Known Stubs
None.

## Self-Check: PASSED
