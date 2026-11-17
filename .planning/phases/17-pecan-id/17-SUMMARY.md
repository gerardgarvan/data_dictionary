# Phase 17 Summary (execution, headless, 2026-11-17)

**Status: programs written, lint and pytest green, SAS runs PENDING SAS RUN (Gerard).** No SAS or P: access here; no data read.

## Delivered
| Plan | Files |
|---|---|
| 17-01 | `sas/00_config.sas` (g_path, backup_path, `%pdd_lib_g` read-only, approval default), `sas/17_pecan_id_macros.sas`, `sas/17_pecan_id_test.sas` (T1-T13 synthetic) |
| 17-02 | `sas/17a_pecan_id_k1_seed.sas` (K1 join PDD-D-32, k1_cases, registry K1 rows, dup link) |
| 17-03 | `sas/17b_pecan_id_k2.sas` (PDD-D-30 dedupe, K2 append, case map, gates) |
| 17-04 | `sas/17_pecan_id_link_macros.sas`, `sas/pecan_id_link.sas` (NOT run), `sas/17_pecan_id_link_test.sas` |
| 17-05 | `sas/17c_pecan_id_summary.sas`, `sas/99_run_all.sas` token 17, `docs/pecan_id_dictionary_text.csv`, `17-SAS-RUN.md`, STATE |
| Tests | `python/tests/test_phase17_macros_static.py`, `test_phase17_programs_static.py` (pytest 347 passed, ruff clean); `sas_lint` 0 errors on every 17 file and `00_config.sas`, `99_run_all.sas`; `sasjs lint` 0 errors (style warnings only, as elsewhere) |

## Assumptions (headless run)
- **Key hand-off from the user's message**: `PDD_K1_SPINE_KEY=PRECEDE_Study_ID`, `PDD_K1_HARM_KEY=PRECEDE_STUDY_ID`, `PDD_K1_KEY_MODE=norm`. `probe_xwalk2` and `probe_xwalk3` `.md` files are NOT in the repo (only PR-1 is), so these names were not verified against a committed probe; the spine names match probe_master_data unit 9. 17a uses them as defaults only when the globals are empty. Gerard should commit the two reports.
- Expected counts (41,150, 1,895, 33,031, 142, 36,348) are never hard-coded as gates. Only `PDD_EXPECT_SHARED` (default 142, from the locked PDD-D-30 overlap probe) is a gate; 36,348 is an orientation QC row.
- **Approval (A1) refined**: creating the registry in 17a needs no approval (guarded by `exist()`); approval is needed only to accept a registry that differs from its latest backup, and for link APPLY (which additionally checks backup-current with approval switched off).
- **Backup order in 17b**: plan text said backup before append. Implemented: assert registry = latest backup (so a pre-append backup exists), append, gate, then new backup (otherwise the next run's backup-current check would fail). Link APPLY takes an extra `pecan_id_registry_prelink_*` backup before replacing.
- **Case map columns**: `PRECEDE_STUDY_ID` as delivered is carried for K1 rows (spine). The nsrc ID column name is not in a probe I could rely on (probe lists "PRECEDE Study ID", Num), so K2 rows carry it blank; Phase 18 joins on `norm_psid`.
- K2 min numeric study number = digits of `norm_psid`.
- QC dumps (`p17_dump_qc`) run before every abort so QC always exists; stale QC tables are reset at the start of 17b.
- `p17_casemap` is link-aware (K2 MRN with `LINKED_TO_PECAN_ID` carries the K1 ID, `PECAN_ID_KEY_ERA='K1'`, KEY_ERA stays K2). Link macros live in an extra file `17_pecan_id_link_macros.sas` so the test can include them.
- Dup-link refusal added beyond plan: a K1 MRN with more than one registry ID, a K2 row already linked to another K1 ID, blank crosswalk MRN.
- `00_config.sas` pre-existing C30 error (semicolon in a `%fail_out` message) fixed (message wording only).
- Earlier wiring tests for phases 15/16 updated for the new `_valid` string.
- `run_pipeline.cmd`: documentation lines only; no Python step for phase 17.

## Not done / pending
- All SAS runs (17-SAS-RUN.md). Nothing pushed.
- No new PDD-D decisions; both pending cases (A13) are 0 per user.
