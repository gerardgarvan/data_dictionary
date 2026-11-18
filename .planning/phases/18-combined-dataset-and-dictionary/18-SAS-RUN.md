# Phase 18 SAS run sheet (for Gerard)

**Status: COMPLETE 2026-11-18.** All steps run and verified by Gerard; see `18-SUMMARY.md`. (Originally written lint-clean on a machine with no SAS and no P:.)
**PDD-D-33 is DECIDED** (Gerard, 2026-11-17): K2 `PRECEDE_STUDY_ID` is the normalized `Precede#####` form. `PDD_K2_PSID_MODE` defaults to NORM in `sas/00_config.sas`; no parameter is needed on any run command.
**Price naming sign-off:** still pending, unrelated to this phase.

## Re-run after fix_18d (NUM_TEXT reconciliation)
Only the Python writer changed (`reconcile()` now checks NUM_TEXT as N + N_UNPARSED). No SAS code changed, so **re-run the writer only**: `.venv\Scripts\python.exe python\scripts\write_dictionary_2018_2025.py` (exit 0 expected). The existing 18c outputs are reused.
Bring back: the console line and `logs\write_dictionary_2018_2025.log`.
**Do not close SAS until 18c's PASS line is in the log** (a previous run was interrupted mid-step).
Known and not changed: Phase 6 (`06_profile_macros.sas`, NUM_TEXT stat rows, ~line 2185-2230) sets `pct_total` on N_UNPARSED and never resets it, so the MEAN..MAX rows output after it inherit that value. 18c's `p18_pct_scrub` blanks it on every row whose n is blank. Deferred to the cleanup backlog in `.planning/STATE.md` (item 6): fixing it at source would re-run Phase 6 and change the v1.0 `pdd.prf_pcnr`.
If a SAS re-run of 18c is ever needed, order is: 18_combine_test, 18c, 18d (fresh sessions), then the writer.

## Re-run after fix_18c (PDD-D-34)
Written after Gerard's first run (18a-18d PASS, writer exit 1 on 27 special-missing variables). 18a and 18b do **not** need a re-run. Re-run, each in a fresh SAS session:
1. `18_combine_test.sas` (new T10B special-missing and T10C pct-scrub checks; expect `ALL TESTS PASSED`)
2. `18c_comb_profile_qc.sas` (now counts `not missing`, writes `n_special_comb_all`, scrubs pct on blank/masked/small-n profile rows and rewrites `profile_PCNR_2018_2025.csv`; QC rows `profile_pct_scrubbed` and `profile_pct_implied_small` = 0)
3. `18d_comb_scan.sas` (fresh session, after 18c)
4. `.venv\Scripts\python.exe python\scripts\write_dictionary_2018_2025.py` (new pct guard; exit 0 expected)
Bring back: the 4 logs, `qc\comb_profile.csv`, `exchange\comb_recon.csv` (check `n_special_comb_all` on the 27 variables and that no pct on masked rows), `qc\comb_scan.csv`.

## Before you start
1. Sync branch `pdd-2018-2025-api`. Phase 15, 16 and 17 outputs must exist on P: (`pdd.pcnr`, `pdd.name_map*`, `pdd.nsrc_s21..s23`, `pdd.pecan_id_registry`, `pdd.pecan_id_dup_link`, `pdd.pecan_id_case_map`, `pdd.prf_pcnr`).
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. SAS command template (as in 16-SAS-RUN.md):
   `"C:\Program Files\SAS94\SASFoundation\9.4\sas.exe" -sysin "C:\data_dictionary\sas\<program>.sas" -config "C:\Program Files\SAS94\SASFoundation\9.4\nls\u8\sasv9.cfg" -encoding utf8 -nosplash -icon`

## Session rule (read first)
Run **each program in a fresh SAS session** (a new `sas -sysin ...` process, or restart SAS if you use the interactive client) and **close every table viewer open on `pdd`** (and on the backup folder) first, so no `A lock is not available` error appears on the P: share. The synthetic test repoints `pdd` and the backup folder at WORK and restores them at the end; never run it in the same session as a production program. Each production program forces `ABORT` right after the config include and never inherits `FLAG` from a test.

## Run order
| Step | Program | Expect | Bring back (masked, counts only) |
|---|---|---|---|
| 1 | `18_combine_test.sas` (synthetic, WORK only) | `TESTRESULT SUMMARY: ALL TESTS PASSED`, no `WARNING` and no `ERROR` line (T17) | the log (PASS/FAIL lines are echoed at the end) |
| 2 | `18a_comb_preflight.sas` | `PASS - preflight complete`. Read-only on every pdd table | log; `qc\comb_pre.csv`; `qc\comb_pre_inventory.csv` (column names and types of `pdd.pcnr` and the three new sources, status MAPPED / KEY / UNEXPLAINED / SOURCE); `exchange\comb_type_delta.csv`. **This step answers the open facts:** the `pdd.pcnr` 1,298-vs-1,297 column question (UNEXPLAINED rows) and the ASA_Anesth_Record / CPT1_Class numeric check (rows `non_numeric_values_*` in `qc\comb_pre.csv`) |
| 3 | `18b_comb_build.sas` | gates PASS, `pdd.pcnr_2018_2025` written once, `PASS - ... written with N rows` | log; `qc\comb_build.csv`; `exchange\comb_d30_conflicts.csv`; listing of `pcnrcmb_*` in the backup folder if a previous copy existed |
| 4 | `18b_comb_build.sas` again (fresh session) | backup `pcnrcmb_<stamp>` taken, same counts | log, `qc\comb_build.csv` (row `previous_copy_backed_up` = 1) |
| 5a | `18c_comb_profile_qc.sas` | `PASS`; profile, recon, NO_DATA flags, KEY facts | log; `qc\comb_profile.csv`; `exchange\comb_recon.csv`; `exchange\comb_nodata.csv`; `exchange\comb_key_facts.csv`; `exchange\profile_PCNR_2018_2025_manifest.csv` (the profile CSV itself stays on P:) |
| 5b | `18d_comb_scan.sas` (own fresh session, after 18c, so the 18a-18c logs are closed) | `PASS - hit count 0` | log; `qc\comb_scan.csv` (hits must all be 0) |
| 6 | `.venv\Scripts\python.exe python\scripts\write_dictionary_2018_2025.py` | exit 0, `out\pdd_2018_2025.xlsx` written, KEY sheet leftmost | the console line with the workbook path; `logs\write_dictionary_2018_2025.log` |

Whole phase in one go: `run_pipeline.cmd 18` (18a, 18b, 18c, 18d, then the writer and the 18d log check). In pipeline mode the logs are the open master log, so 18d scans only the CSVs and `run_pipeline.cmd` checks the 18d log. Preferred: the step-by-step order above, each in a fresh session.

## What each program reads and writes
- 18a: read-only. Writes `pdd.qc_comb_pre`, `pdd.qc_comb_asacpt` (once, WORK staging flush), the CSVs above, the log. It never creates or changes `pdd.pcnr_2018_2025`.
- 18b: writes `pdd.pcnr_2018_2025` (backs up an existing copy as `pcnrcmb_YYYYMMDD_HHMMSS` first), `pdd.qc_comb_build`, `pdd.qc_comb_d30`, `pdd.qc_comb_typeconv`. Registry, dup link and case map are read-only; their row counts are compared at start and end.
- 18c: writes `pdd.prf_PCNR_2018_2025`, `pdd.qc_comb_profile`, the exchange CSVs. v1.0 outputs (`pdd.prf_pcnr`, `profile_PCNR.csv`, `pdd_v1_0.xlsx`) are never touched.
- 18d: writes `pdd.qc_comb_scan`, `qc\comb_scan.csv`.

## If a gate stops the run
QC is written first, then the program aborts with the reason in the `ERROR` line. Nothing is written to `pdd.pcnr_2018_2025` by a failed 18b gate.
| Stop text | Meaning | PENDING DECISION it creates |
|---|---|---|
| `PENDING DECISION - ... name map rows still carry PENDING_DECISION` | `pdd.name_map_ext` has `PENDING_DECISION` rows (16 carried from Phase 16) | resolve in `docs/name_map_decisions_new.csv`, rerun 16a/16b |
| `... decisions CSV key(s) match no mapped variable` | a name in `docs/combined_type_decisions.csv` is spelled differently in the map (for example `Sleep_Apnea_YN`) | correct the CSV key or record a decision; no value changes |
| `... pdd.pcnr column(s) are neither NORM_PSID nor a mapped PCNR_ name` | the 1,298-vs-1,297 question: an unexpected column in `pdd.pcnr` (names are in `comb_pre_inventory.csv`, status UNEXPLAINED) | decide: map it, drop it, or document it |
| `... mapped variable(s) have no source column` | a PCNR_ variable has no source column anywhere | name-map issue, back to Phase 16 |
| `... value(s) cannot be converted to the decided type` | a char-to-num conversion failed for some variable and source (counts per variable in `qc_comb_typeconv`; **ASA_Anesth_Record or CPT1_Class show up here if either side holds a non-numeric value**, rows `non_numeric_values_*`) | for ASA/CPT1 the type stays text until Gerard decides (PDD-D-31 item 2); otherwise a new type decision |
| `case overlap gate failed` / `row count gate failed` | s21 shares cases with s22 or s23, old era shares with new era, s22 x s23 differs from `docs/new_overlap_decisions.csv`, or row counts disagree | PDD-D-29 / PDD-D-30 follow-up |
| `id attach gate failed` / `case map has duplicate norm_psid keys` | a combined row has no case map entry or no PECAN_ID | Phase 17 follow-up; no change here |
| `variable gate failed` | variable missing, wrong type, extra PCNR_ column, ENCRYPTED_ column, or wrong order | bug report with the `qc\comb_build.csv` rows |
| `reconciliation has unexplained ... count differences` | K1 slice non-missing or distinct counts differ from `pdd.pcnr` / v1.0 profile by more than the NULL-to-missing conversions. If this appears only for variables with small-cell flags in the v1.0 profile, report it: it may be profile suppression, not data | decision with Gerard |
| `a coverage NO_DATA variable has data` | s06 NO_DATA flag contradicted by the combined data | name-map coverage follow-up |
| `MRN scan found ...` | an encrypted MRN value appears in a closed log or QC file | delete the file, find the leak, rerun |
| `invalid PDD_K2_PSID_MODE` | only if you override with something other than NORM, DELIVERED, BLANK | none, fix the value |

## Phase 18 SUMMARY must record (after the runs)
1. ASA_Anesth_Record and CPT1_Class: numeric (both sides parse) or stopped at PENDING DECISION (from `non_numeric_values_*`).
2. PDD-D-33 mode used (KEY fact `PDD_K2_PSID_MODE`, expected NORM).
3. The `pdd.pcnr` unexplained-column result (0 UNEXPLAINED, or the names).
4. Final counts, masked: rows, columns, K1 rows, K2 rows, shared 2024/2025 surgeries, distinct PECAN_ID per era, dup pairs, NO_DATA variables.
5. Test result line, 18d hit counts, workbook path.

Phase 18 closes only when the test passes, all gates PASS, 18c recon has no unexplained delta, the workbook is written, and Gerard has reviewed the results. Claude does not close it.
