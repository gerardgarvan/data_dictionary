# Phase 17 SAS run sheet (for Gerard)

**Status: PENDING SAS RUN.** Nothing below has been run. The programs do not exist yet; this sheet is the contract the executed plans (17-01..17-05) must satisfy, and is finalized when 17-05 is executed.
**PENDING DECISION:** none open. One arises only if a seed check fails or the xwalk MRN length is shorter than the longest spine MRN.
**Price naming sign-off:** still pending, unrelated to this phase.

## Before you start
1. Sync branch `pdd-2018-2025-api`. Phase 15 and 16 outputs must exist (`pdd.src_s09`, `pdd.nsrc_s21..s23`).
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. SAS command template as in 16-SAS-RUN.md, with `-sysin "C:\data_dictionary\sas\<program>.sas"`.

## Run order
| Step | Program | Expect | Bring back |
|---|---|---|---|
| 1 | `17_pecan_id_test.sas`, `17_pecan_id_link_test.sas` | `TESTRESULT SUMMARY: ALL TESTS PASSED`, no WARNING | PASS/FAIL lines |
| 2 | `17_probe_xwalk.sas` (PROBE REQUEST PR-1) | report with variable names, lengths, row count | `qc\probe_xwalk.md`; commit as `.planning/schemas/probe_xwalk_<date>.md` |
| 3 | `17a_pecan_id_k1_seed.sas` | registry created, backup written, seed checks PASS; if the registry already exists: `seed skipped` | log, `qc\pecan_id_seed.csv` |
| 4 | `17b_pecan_id_k2.sas` | PDD-D-30 shared 142, s21 overlap 0, gates PASS, K2 rows appended | log, `qc\pecan_id_k2_summary.csv`, `qc\pecan_id_gate.csv` |
| 5 | `17b` again | 0 rows appended (idempotence) | log |
| 6 | `17c_pecan_id_summary.sas` | summary reconciles to case map | `qc\pecan_id_cases_per_patient.csv` |

`pecan_id_link.sas` is NOT run in this phase.

## Approval option
`PDD_APPROVE_NEW_BASELINE=1` (e.g. `-set PDD_APPROVE_NEW_BASELINE 1`). Default 0. Use only if a program reports that the registry differs from its latest backup and you accept the registry as the new baseline. Without it the program aborts with counts. Nothing reseeds silently.

## If a gate stops the run
QC is written first; send back the QC CSVs and log. Claude applies no choice (PENDING DECISION).
No MRNs, IDs or data values appear in logs or QC files meant for git.
