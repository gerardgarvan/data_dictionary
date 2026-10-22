---
phase: 05-build-pcnr-on-the-spine
plan: 05
subsystem: sas-pipeline
tags: [phase5, orchestrator, pcnr, pipeline-wiring]
dependency_graph:
  requires: [05-01, 05-02, 05-04]
  provides: [phase5-runnable]
  affects: [99_run_all, run_pipeline.cmd]
tech_stack:
  added: []
  patterns: [pcm-c13-include-before-call, section-guard-pattern]
key_files:
  created:
    - sas/05_build_pcnr.sas
  modified:
    - sas/99_run_all.sas
    - run_pipeline.cmd
decisions:
  - "Phase 5 Python step added inline in run_pipeline.cmd (not via :run_python subroutine) to support --exchange/--qc/--logs path args"
  - "05_build_pcnr.sas contains zero %macro definitions; all macros sourced via %include of 05_build_pcnr_macros.sas (C13)"
metrics:
  duration_minutes: 8
  completed_date: "2026-10-21"
  tasks_completed: 2
  files_changed: 3
requirements: [PDD-05-A, PDD-05-I, PDD-05-J]
---

# Phase 05 Plan 05: Wire Phase 5 orchestrator and pipeline integration Summary

Phase 5 SAS orchestrator wires 7 entry-point macros in order via %include of macro library, with Phase 5 enabled in 99_run_all.sas loop and Python QC step added to run_pipeline.cmd.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write 05_build_pcnr.sas orchestrator body | 617986d | sas/05_build_pcnr.sas (created) |
| 2 | Wire Python step in run_pipeline.cmd; enable Phase 5 in 99_run_all.sas | c09d83d | sas/99_run_all.sas, run_pipeline.cmd |

## What Was Built

`sas/05_build_pcnr.sas` replaces the Plan 01 stub with a full orchestrator:
- Section 0: `%include 00_config.sas`, `%pdd_lib`, `%include 05_build_pcnr_macros.sas`
- Sections 1-7: `%_p5_ok(section=N)` guard followed by macro call
- Section 8: `%put NOTE` emitting the Python QC command for operators (no x/systask)
- Zero `%macro` definitions (all in macros file — C13 satisfied)

`sas/99_run_all.sas` adds Phase 5 block inside `%_run_phases` after Phase 4, with `%_check_pipeline_ok(phase=5)`, `%_phase_in(5)` guard, `%include` of `05_build_pcnr.sas`, timing puts, and `pdd_phases_done` append. Old commented block removed.

`run_pipeline.cmd` adds Phase 5 Python step after Phase 4 Python: invokes `write_pcnr_qc.py` with `--exchange`, `--qc`, `--logs` path args; console redirected to `write_pcnr_qc_console.txt`; exit-code check with `goto :fail` on failure.

## Verification

- `python tools/sas_lint.py sas/05_build_pcnr.sas` — clean
- `python tools/sas_lint.py sas/99_run_all.sas` — clean (4 pre-existing warnings, zero errors)
- `sasjs lint` — warnings only (pre-existing across all files), no errors on new/modified files
- `%include` of `05_build_pcnr_macros.sas` present in orchestrator
- All 7 macro calls present: `p5_preflight`, `p5_spine_coverage`, `p5_resolve_types`, `p5_build_accumulator`, `p5_run_gapfill`, `p5_finalize_pcnr`, `p5_write_qc`
- `%_p5_ok(section=` appears 7 times (sections 1-7)
- `write_pcnr_qc.py` in `%put NOTE` in orchestrator (no x/systask)
- `write_pcnr_qc.py` in run_pipeline.cmd with `write_pcnr_qc_console.txt` and `ERRORLEVEL` check
- `%_phase_in(5)` inside `%_run_phases` in 99_run_all.sas
- `_valid = 2 3 4 5 6 7` unchanged in 99_run_all.sas
- Default `pdd_phases_run` unchanged (`2 3 4`)

## Deviations from Plan

**1. [Rule 3 - Blocking] Phase 5 Python added inline rather than via :run_python subroutine**
- Found during: Task 2
- Issue: `:run_python` subroutine in run_pipeline.cmd accepts only label + script name with no mechanism for extra CLI args; `write_pcnr_qc.py` requires `--exchange`, `--qc`, `--logs` path args
- Fix: Added inline CMD block after Phase 4 `:run_python` call, deriving paths from already-set `LOGS_PATH` variable
- Files modified: run_pipeline.cmd
- Commit: c09d83d

## Known Stubs

None. Phase 5 is runnable end-to-end pending live SAS execution (pdd.pcnr and qc/pcnr_qc.xlsx production require the P: drive data).

## Self-Check: PASSED

- sas/05_build_pcnr.sas: FOUND (617986d)
- sas/99_run_all.sas modified: FOUND (c09d83d)
- run_pipeline.cmd modified: FOUND (c09d83d)
- Both commits verified in git log
