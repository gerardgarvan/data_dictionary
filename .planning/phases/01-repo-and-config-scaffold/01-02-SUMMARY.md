---
phase: 01-repo-and-config-scaffold
plan: 02
subsystem: pipeline-runner
tags: [cmd-driver, sas-runner, batch, pipeline]
dependency_graph:
  requires: [01-01]
  provides: [run_pipeline.cmd, sas/99_run_all.sas]
  affects: [all-later-phases]
tech_stack:
  added: [Windows CMD batch driver]
  patterns: [:run_program subroutine, master-log scan, config.local.cmd override]
key_files:
  created:
    - run_pipeline.cmd
    - sas/99_run_all.sas
  modified: []
decisions:
  - "Phase 1 skeleton calls only 99_run_all.sas; programs 02-07 added in later phases"
  - "WARNING scan of master log (in addition to ERROR scan) exits nonzero per PDD-01"
  - "Per-program log named <prog>.log (same stem as .sas file) in LOGS_PATH"
metrics:
  duration_minutes: 5
  completed_date: "2026-10-17"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 1 Plan 2: Batch Driver and Pipeline Runner Skeleton Summary

**One-liner:** CMD batch driver with :run_program subroutine, per-program WARNING count, dual ERROR+WARNING master-log scan, and a SAS pipeline runner skeleton that %includes 00_config.sas and contains commented-out blocks for phases 02-07.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write run_pipeline.cmd — complete batch driver | 219dfa6 | run_pipeline.cmd |
| 2 | Write sas/99_run_all.sas — pipeline runner skeleton | 90de076 | sas/99_run_all.sas |

## What Was Built

### run_pipeline.cmd
- Fixed path variables: `SAS_PATH`, `LOGS_PATH`, `MASTER_LOG`
- Initialises master log with timestamp before any program runs
- `:run_program` subroutine: calls `sas.exe -sysin -log -nosplash -icon -sasuser WORK -set RUN_ALL 1`, captures exit code, counts WARNING lines per-program log via `findstr`, writes summary line to master log, stops pipeline on exit code >= 2
- `:main` section: `config.local.cmd` override, default `SAS_EXE=C:\Program Files\SAS94\SASFoundation\9.4\sas.exe`, SAS_EXE existence guard
- Phase 1 skeleton calls only `99_run_all.sas`
- Post-run ERROR scan of master log (exits 1 if count > 0)
- Post-run WARNING scan of master log (exits 1 if count > 0)
- `:fail` label with timestamped footer

### sas/99_run_all.sas
- `options mprint nofmterr nodate nonumber ps=max ls=200;`
- `%include "C:\data_dictionary\sas\00_config.sas";`
- `%let in_pipeline = 1;`
- `%put NOTE` banner echoing `sas_path`, `raw_master`, `out_root`, `logs_path`
- Six commented-out phase blocks (02-07), each using `&sas_path.` in the `%include` path
- `PIPELINE COMPLETE` footer

## Decisions Made

- Phase 1 skeleton calls only 99_run_all.sas; later phases uncomment the corresponding `:run_program` call in run_pipeline.cmd and the `%include` block in 99_run_all.sas.
- Master log WARNING scan added alongside the ERROR scan (both exit nonzero) per PDD-01 acceptance criterion (zero WARNINGs required for a clean run).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both files are complete with no placeholder content.

## Self-Check: PASSED

- `run_pipeline.cmd` exists at `C:\data_dictionary\run_pipeline.cmd`
- `sas/99_run_all.sas` exists at `C:\data_dictionary\sas\99_run_all.sas`
- Commit `219dfa6` exists (run_pipeline.cmd)
- Commit `90de076` exists (sas/99_run_all.sas)
- LOGS_PATH points to `P:\PeCAN Master Data\Gerard\data_dictionary\logs`
- %include path is exactly `"C:\data_dictionary\sas\00_config.sas"`
- 00_config.sas defines `%let logs_path = &out_root.\logs`
- No stubs (`...` in echo statement is display output, not a code stub)
- Both ERROR and WARNING scans of master log present, each exiting nonzero on count > 0
