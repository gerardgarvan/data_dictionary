# Phase 17 Summary (execution, headless, 2026-11-17)

**Status: COMPLETE 2026-11-17.** Programs written headless; SAS runs done by Gerard on the SAS machine (results below, masked). No SAS or P: access on the writing machine; no data read there.

## SAS run results (Gerard, 2026-11-17, masked)
Synthetic tests `17_pecan_id_test` (T1-T18) and `17_pecan_id_link_test` (T0-T7): ALL TESTS PASSED, no WARNING or ERROR lines. (T19 was added at close, see "Close-out fixes"; rerun the test once to include it.)

| Step | Result |
|---|---|
| 17a (approved) | Approved by Gerard with `PDD_APPROVE_NEW_BASELINE=1` after reviewing the masked proposal 33031 / 33031 / 33031 / 31136. K1 join gate PASS: 41150 rows 1:1 on `PRECEDE_Study_ID` -> `PRECEDE_STUDY_ID` (norm), 0 missing pecan_ID. Registry created with 33031 K1 IDs. 1895 dup pairs appended to `pdd.pecan_id_dup_link`. Blank spine MRN rows 1. |
| 17b | PDD-D-30 shared s22 x s23 = 142 (read from `docs/new_overlap_decisions.csv`). K2 distinct MRNs 26474 appended (IDs from 1000001). K2 cases without MRN 0. Registry 59505 rows, case map 77498 rows. Registry and case map gates PASS. Rerun: 0 appended. |
| 17a rerun (after fix_17e) | Registry not re-seeded, 0 pairs appended, first `piddup_` backup taken. |
| 17c | `qc\pecan_id_cases_per_patient.csv` written, no ERROR or WARNING. |
| Backups | `pidreg_20261117_152323` (33031, K1 only), `pidreg_20261117_152929` (59505, current), `piddup_20261117_161437` (1895). |

## Run history (honest record)
- An early 17a run inherited FLAG mode from the test session and wrote the dup link without approval. No backup of the link existed. Gerard deleted `pdd.pecan_id_dup_link` before the approved run. Fixed in **fix_17d**: production programs force `p17_fail_mode = ABORT`, the registry and case map gates fail on a missing table, and nothing registry- or link-related runs after a failed guard.
- QC lock errors on the P: share (`A lock is not available for PDD.<table>.DATA`) came from per-row QC writes. Fixed in **fix_17e**: QC rows staged in WORK and written once with `%p17_flush_qc`, `filelockwait=10` in `%pdd_lib`.

## Close-out fixes (close_17)
- **17b no-op rerun**: the rerun printed no "registry equals its latest backup" line because `%p17_k2_append` ran `%p17_assert_backup_current` only inside the `new > 0` branch (confirmed by reading the macro). Now the assertion runs on every run before any append decision, also when 0 rows will be appended; after a failed check nothing is appended. The dup link check (`%p17_append_dup_link`) already ran outside the new-rows branch (an existing link is always checked), so no change there. New synthetic test T19 in `17_pecan_id_test.sas` (no-op rerun passes with equal backup; registry differing from backup fails with 0 appended) and a static test.
- **17c top-coding (replaces cell masking)**: cell masking still disclosed counts (`n_cases` on a `<11` row = bucket x `n_ids`, e.g. bucket 9 with `n_cases` 27 is 3 IDs; scope totals reveal the sum of masked cells). `qc\pecan_id_cases_per_patient.csv` is now top-coded per scope by `%p17_topcode` (in `17_pecan_id_macros.sas`): from the highest bucket, buckets merge into one `N+` bucket until every row has at least 11 IDs (`n_cases` summed). A scope with under 11 IDs in total becomes one `<11` row and its TOTALS row is dropped. Scope totals and the dup-pair row stay; the dup-pair row is masked in both columns if either count is 1-10. If the without-ID count is 1-10 it is `<11` and the K2 and ALL `n_cases` totals are blanked (total minus bucket sums would reveal it). Test T20 (synthetic, bucket 9 with 3 IDs / 27 cases merges to `2+`; no row with 1-10 IDs; no `n_cases` divides back to a small `n_ids`) plus a static test. The file on P: from earlier 17c runs is not safe to copy; rerun 17c (fresh session) and rerun the synthetic test (T20 is new).
- `qc\pecan_id_registry_proposed.csv` holds encrypted MRNs. It is gitignored (`*.csv`) and must never be committed; Gerard deletes it after approval.

## Assumptions (headless run, close-out)
- T19 numbering follows T18. The tests Gerard ran (T1-T18) did not include it, so the PASS list on the SAS machine stays T1-T18 until the test is rerun.
- Counts quoted are from Gerard's run report in the close_17 prompt, not from a probe file or log in the repo.

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
- **Key hand-off from the user's message**: `PDD_K1_SPINE_KEY=PRECEDE_Study_ID`, `PDD_K1_HARM_KEY=PRECEDE_STUDY_ID`, `PDD_K1_KEY_MODE=norm`. **Verified** against the committed `.planning/schemas/probe_xwalk3_20261117.md`: section 1a lists `PRECEDE_STUDY_ID` as a char(12) column on g.MASTER_DATA_HARMONIZED (spine `PRECEDE_Study_ID` char(16)); section 1c names spine `PRECEDE_Study_ID`, harmonized `PRECEDE_STUDY_ID`, mode `norm`, one-to-one for all spine rows. 17a uses these as defaults only when the globals are empty.
- Expected counts (41,150, 1,895, 33,031, 142, 36,348) are never hard-coded as gates. Only the shared s22 x s23 count is a gate, and 17b reads it from `docs/new_overlap_decisions.csv` (row `s22_s23`, column `expected_n_shared`, 142) into `PDD_EXPECT_SHARED` with no default; missing file, missing row or non-numeric value fails 17b; 36,348 is an orientation QC row.
- **Approval (A1), revised**: 17a no longer creates `pdd.pecan_id_registry` silently. When the registry is absent, `%p17_registry_baseline` (same pattern as 15a) without `PDD_APPROVE_NEW_BASELINE=1` writes `qc\pecan_id_registry_proposed.csv` (encrypted MRNs, qc only, never git) and `qc\pecan_id_registry_proposed_summary.csv` (masked counts, 1-10 shown `<11`), creates nothing, and stops with `ERROR ... PENDING DECISION`. With approval it creates the registry and its first backup. `pdd.pecan_id_k1_cases` is already written at that point; the dup link is not touched. Approval is also needed to accept a registry that differs from its latest backup, and for link APPLY (which additionally checks backup-current with approval switched off). Only the value 1 approves.
- **Approval plumbing fix**: `-set PDD_APPROVE_NEW_BASELINE 1` is an OS env var, but the Phase 17 macros read a macro variable. `00_config.sas` `_set_approve_default` now copies env value 1 into the macro variable (only 1 approves).
- **New tests**: `17_pecan_id_test.sas` T14 (no approval and value 2: proposal + summary written, registry absent, failure; approval 1: registry created, backup current). Static tests cover the guard order, the 17b CSV read and the absence of a 142 default.
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
- `pecan_id_link.sas` is written and tested but not run (needs a crosswalk and a PDD decision).
- Rerun `17_pecan_id_test.sas` (T19) and `17c_pecan_id_summary.sas` (masked output), each in a fresh session.
- Nothing pushed. No new PDD-D decisions.

## Assumptions (headless run, top-coding)
- Merging continues downward past the smallest sub-11 bucket until the merged bucket has at least 11 IDs, so a merged bucket can start below that sub-11 bucket (fixture: buckets 1, 2, 9 with 500, 200, 3 IDs give `1` and `2+`). Only the top bucket is merged; lower buckets stay single.
- The note column marks top-coded rows. Not yet run in SAS: T20 and 17c are PENDING SAS RUN (Gerard).
