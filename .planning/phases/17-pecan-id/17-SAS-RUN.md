# Phase 17 SAS run sheet (for Gerard)

**Status: PENDING SAS RUN.** Nothing below has been run. Programs written and lint-clean 2026-11-17 (PDD-D-32). Claude has no SAS and no P: drive and applied no decision.
**PENDING DECISION:** none open. One arises only if a gate stops (see "If a gate stops the run").
**Price naming sign-off:** still pending, unrelated to this phase.

## Before you start
1. Sync branch `pdd-2018-2025-api`. Phase 15 and 16 outputs must exist (`pdd.src_s09`, `pdd.nsrc_s21..s23`).
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. (Done) `probe_xwalk2` and `probe_xwalk3` are committed; the key hand-off below matches probe_xwalk3 sections 1a and 1c.
4. SAS command template as in 16-SAS-RUN.md, with `-sysin "C:\data_dictionary\sas\<program>.sas"`.

## Session rule (read first)
Run **each production program in a fresh SAS session** (a new `sas -sysin ...` process, or restart SAS if you use the interactive client), and **close any table viewers open on `pdd`** (and on `p17bak` backups) first, so no library is locked. The two synthetic tests run in FLAG mode and repoint `pdd` and `p17bak` at WORK; they restore both at the end, but never run 17a/17b/17c in the same session as a test. 17a, 17b, 17c and `pecan_id_link.sas` also force `p17_fail_mode = ABORT` themselves, and the registry and case map gates fail on a missing table.

## K1 key hand-off (PR-3, reviewed)
`PDD_K1_SPINE_KEY=PRECEDE_Study_ID`, `PDD_K1_HARM_KEY=PRECEDE_STUDY_ID`, `PDD_K1_KEY_MODE=norm` (PDD-D-19). 17a uses these as defaults when the variables are empty, so no `-set` is needed; to override, put `%let PDD_K1_..=...;` before the include or use the same names in the run command.

## Run order
| Step | Program | Expect | Bring back |
|---|---|---|---|
| 1 | `17_pecan_id_test.sas`, then `17_pecan_id_link_test.sas` (each its own session) | `TESTRESULT SUMMARY: ALL TESTS PASSED`, no WARNING | the PASS/FAIL lines (echoed to the log at the end) |
| 2a | `17a_pecan_id_k1_seed.sas` (no approval) | first run on an empty library stops by design: `ERROR ... PENDING DECISION - registry baseline not approved`; registry NOT created; K1 gate counts in `qc\pecan_id_k1.csv` | log, `qc\pecan_id_k1.csv`, `qc\pecan_id_registry_proposed_summary.csv` (masked counts; review `qc\pecan_id_registry_proposed.csv` yourself, it holds encrypted MRNs, do not send or commit) |
| 2 | `17a_pecan_id_k1_seed.sas` with `-set PDD_APPROVE_NEW_BASELINE 1` | K1 join gate PASS: spine rows = harmonized rows = matched rows (expected 41,150, computed), none 0, more than one 0, missing pecan_ID 0; `BLANK_SPINE_MRN_ROWS=` (expected 1); dup pairs (expected 1,895); registry created (33,031 K1 rows expected, one per distinct ID) and backed up; `pdd.pecan_id_dup_link` appended | log, `qc\pecan_id_k1.csv`, `qc\pecan_id_dup_pairs_by_year.csv` |
| 3 | `17a` again (no approval) | `registry exists, K1 build skipped`, dup link appended 0 | log, `qc\pecan_id_k1.csv` |
| 4 | `17b_pecan_id_k2.sas` | shared s22 x s23 = expected_n_shared in `docs/new_overlap_decisions.csv` row s22_s23 (142), s21 overlap 0, cases 36,348 (orientation only), gates PASS, K2 rows appended, case map written; `K2_NO_MRN_CASES` reported (the 1 NO_MRN row in the spine is K1 and keeps its ID) | log, `qc\pecan_id_k2_summary.csv`, `qc\pecan_id_gate.csv` |
| 5 | `17b` again | `rows appended 0` (idempotence) | log |
| 6 | `17c_pecan_id_summary.sas` | summary reconciles to the case map | `qc\pecan_id_cases_per_patient.csv` |

Whole phase in one go: `run_pipeline.cmd 17` (17a, 17b, 17c; no Python step).

`pecan_id_link.sas` is NOT run in this phase (needs a crosswalk and a PDD decision). The xwalk is not an input to any 17 program.

## Expected values (computed at run time, shown for orientation only)
41,150 spine rows joined 1:1, 0 missing pecan_ID, 33,031 distinct K1 IDs, 1,895 dup pairs, 0 pecan_IDs with more than one spine MRN, 1 NO_MRN spine row (K1, keeps its ID), K2 distinct MRNs from the 36,348 deduped cases. Registry K1 rows: one per distinct ID. Counts 1-10 become `<11` if copied into `.planning/`.

## Approval option
`PDD_APPROVE_NEW_BASELINE=1` (e.g. `-set PDD_APPROVE_NEW_BASELINE 1`; default 0). Use only if a program reports that the registry differs from its latest backup and you accept the registry as the new baseline. Also required for the FIRST creation of the registry in 17a (step 2): without it 17a writes the proposal and masked summary to qc and stops. Without it any other program aborts with counts. Nothing reseeds silently. Only the value 1 approves; `00_config.sas` copies the env var into the macro variable the Phase 17 macros read.

## If a gate stops the run
QC files are written first (`qc\pecan_id_k1.csv`, `qc\pecan_id_gate.csv`, `qc\pecan_id_k2_summary.csv`); send them and the log back. Claude applies no choice (PENDING DECISION). Stops that are decisions, not bugs: K1 pecan_ID with more than one spine MRN or only on blank-MRN rows (registry not created, `pdd.pecan_id_k1_cases` still written); shared s22 x s23 count differs from `docs/new_overlap_decisions.csv` row s22_s23, or the row/file is missing (change the CSV only after Gerard decides); registry baseline not approved (17a, rerun with approval after reviewing the proposal); any s21 overlap.
No MRNs, IDs or data values appear in logs or QC files meant for git.
