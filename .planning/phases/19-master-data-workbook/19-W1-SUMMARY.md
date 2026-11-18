# Phase 19 Wave 1 summary (exec_19w1 + exec_19w1b)

## Done
- `sas/19_xlsx_macros.sas`, `sas/19_xlsx_test.sas`, `sas/19a_xlsx_preflight.sas`, config block, `19-SAS-RUN.md`, `python/tests/test_phase19_wave1_static.py`, 4 rows in `docs/exchange_schema.csv`.
- Top-code fix: already applied in the macros (`tot - n >= 1 and tot - n <= 10`, also in the summary `max_n`); macros and test T7/T8/T9 agree.
- Lint: `sas_lint` clean on all four SAS files; `sasjs lint` 0 errors; `ruff` clean; `pytest` 461 passed.

## 00_config.sas change (explained)
Adds `xls_final`, `xls_stage_path`, `xls_bak_path` and `PDD_XLS_*` decision variables, all empty by default (PENDING DECISION) except `PDD_XLS_MIN_FREE_GB=15`. An OS env var of the same name overrides. In this run `%_xls_def` was rewritten to set the variable with `call symputx(..., 'G')` instead of `%global &name`, because lint C21 rejects `%global &<param>` inside a macro.

## Fixes this run
- Test: 45 `%str()` quote errors (C16) changed to `%"`; open-code `%global` (C18) moved into a macro.
- 19a: no commas in macro-call arguments; allow-list gate now logs flagged column names (names only).

## Assumptions (headless run)
- Probe CSV in `qc\` is masked like the exchange summary (no exact per-variable counts leave the SAS machine).
- 19a stage folder is created with `dcreate` for the throwaway speed test only.
- Not done (Wave 1 remainder, not needed for the SAS run): Python writer (19-05) and verifier (19-06).

## PENDING SAS RUN
`19_xlsx_test.sas`, then `19a_xlsx_preflight.sas` (see `19-SAS-RUN.md`).
