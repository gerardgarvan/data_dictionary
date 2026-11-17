# Phase 17 SAS run sheet (for Gerard)

**Status: PENDING SAS RUN.** Nothing below has been run. Revised 2026-11-17 for PDD-D-32. Only `17_probe_xwalk3.sas` exists today; the other programs are the contract the executed plans (17-01..17-05) must satisfy, and this sheet is finalized when 17-05 is executed.
**PENDING DECISION:** none open. One arises only if PR-3 shows a pecan_ID with more than one distinct spine MRN, a pecan_ID only on blank-MRN rows, or no real key (row order only); or if a K1 gate fails.
**Price naming sign-off:** still pending, unrelated to this phase.

## Before you start
1. Sync branch `pdd-2018-2025-api`. Phase 15 and 16 outputs must exist (`pdd.src_s09`, `pdd.nsrc_s21..s23`).
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. SAS command template as in 16-SAS-RUN.md, with `-sysin "C:\data_dictionary\sas\<program>.sas"`.

## Run order
| Step | Program | Expect | Bring back |
|---|---|---|---|
| 1 | `17_pecan_id_test.sas`, `17_pecan_id_link_test.sas` | `TESTRESULT SUMMARY: ALL TESTS PASSED`, no WARNING | PASS/FAIL lines |
| 2a | `17_probe_xwalk.sas` (PR-1) and `17_probe_xwalk2.sas` (PR-2) | DONE 2026-11-17 | `probe_xwalk_20261117.md`, `probe_xwalk2_20261117.md` |
| 2b | **`17_probe_xwalk3.sas` (PR-3, run FIRST, PENDING SAS RUN)** | report `.planning/schemas/probe_xwalk3_<date>.md` (written by the program, no qc copy): section 1b names the key giving a one-to-one match of all 41,150 spine rows; section 2 spine MRN to pecan_ID histogram and the dup pair count; section 3 pairs by YEAR; section 4 YEAR of the unmatched MRNs; `BLANK OR NULL SPINE MRN ROWS` on its own line. Check that no section 1a candidate pattern missed your key | the `.md`, and the SAS log; commit the `.md`; then set `PDD_K1_SPINE_KEY`, `PDD_K1_HARM_KEY`, `PDD_K1_KEY_MODE` from section 1c |
| 3 | `17a_pecan_id_k1_seed.sas` (K1 join, PDD-D-32) | K1 join gate PASS: spine rows = harmonized rows = matched rows (expected 41,150), 0 unmatched, 0 multi-match, 0 missing pecan_ID; `BLANK_SPINE_MRN_ROWS` line; dup pair count (expected near 1,895, computed); registry created and backed up; `pdd.pecan_id_dup_link` appended (second run appends 0); if the registry already exists: `registry exists, K1 build skipped` | log, `qc\pecan_id_k1.csv`, `qc\pecan_id_dup_pairs_by_year.csv` |
| 4 | `17b_pecan_id_k2.sas` | PDD-D-30 shared 142, s21 overlap 0, gates PASS, K2 rows appended | log, `qc\pecan_id_k2_summary.csv`, `qc\pecan_id_gate.csv` |
| 5 | `17b` again | 0 rows appended (idempotence) | log |
| 6 | `17c_pecan_id_summary.sas` | summary reconciles to case map | `qc\pecan_id_cases_per_patient.csv` |

`pecan_id_link.sas` is NOT run in this phase. The xwalk is no longer an input to 17a (PDD-D-32).

## Approval option
`PDD_APPROVE_NEW_BASELINE=1` (e.g. `-set PDD_APPROVE_NEW_BASELINE 1`). Default 0. Use only if a program reports that the registry differs from its latest backup and you accept the registry as the new baseline. Without it the program aborts with counts. Nothing reseeds silently.

## If a gate stops the run
QC is written first; send back the QC CSVs and log. Claude applies no choice (PENDING DECISION).
No MRNs, IDs or data values appear in logs or QC files meant for git.
