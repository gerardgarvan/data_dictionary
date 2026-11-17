# Phase 18 validation map

Checks marked **static** run here (pytest, sas_lint); **SAS** checks run on Gerard's machine (`18-SAS-RUN.md`). Test files live in `python/tests/` (established location, `test_phaseNN_*_static.py`).

| Requirement / gate | Plan | Check | File |
|---|---|---|---|
| DD-01 one row per surgery, PECAN_ID and PRECEDE_STUDY_ID first | 18-02, 18-04 | SAS gate `p18_gate_rows` (distinct norm_psid = rows = old + s21 + s22 + s23 - shared = case map rows), `p18_gate_vars(order=1)`; synthetic T4, T8 | `18_combine_macros.sas`, `18b_comb_build.sas`, `18_combine_test.sas` |
| DD-01 PDD-D-30 (s22 wins, s23 fills, YEAR 2024, conflicts counted) | 18-02, 18-04 | `p18_d30_merge`, counts per column to `qc_comb_d30`; shared count equals `docs/new_overlap_decisions.csv`; synthetic T3 | same |
| DD-01 PDD-D-33 K2 PRECEDE_STUDY_ID normalized | 18-01, 18-02 | config default NORM; `p18_psid_mode`; synthetic T5, T16; static `test_phase18_seed_static.py`, `test_phase18_macros_static.py` | `00_config.sas` |
| DD-02 values as source, decided types only | 18-02, 18-03 | `p18_build_source` conversion rules (NULL as missing, num-to-char no decimals or exponent); 18a dry conversion and `p18_gate_conv`; synthetic T1, T2 | |
| DD-02 ASA and CPT1 conditional numeric | 18-01, 18-03 | seed rows CONDITIONAL; 18a rows `non_numeric_values_*`, stop at PENDING DECISION on any non-numeric value | `combined_type_decisions.csv` |
| No encrypted column, no MRN in logs or QC | 18-02, 18-05 | `p18_gate_vars` ENCRYPTED check; `18d_comb_scan.sas` over closed logs and CSVs (min token length from the registry); synthetic T6, T15, T17 | |
| Read-only registry, dup link, case map | 18-02..05 | `p18_ro_start`/`p18_ro_end`; synthetic T12 | |
| Rerun safe, backup first | 18-04 | `p18_backup_comb` before the single write (`pcnrcmb`, 23 bytes); static order test; synthetic T11 | `test_phase18b_static.py` |
| QC staging, one flush | 18-02..05 | `p18_qinit/qadd/flush_qc`; synthetic T14; static flush counts | `test_phase18a_static.py`, `test_phase18c_static.py` |
| DD-03 profile and workbook | 18-05, 18-06 | `18c` `%pdd_profile` family PCNR_2018_2025; writer tests (sheet order, KEY leftmost, UF colors, PECAN_ID first, alphabetical, NO_DATA, type notes, caveat texts) | `test_dictionary_2018_2025.py` |
| DD-04 dictionary rows = dataset columns; non-missing counts match | 18-05, 18-06 | 18c `columns` key fact and profile variable count; writer hard-fail reconciliation | writer module |
| DD-04 2018-2022 matches the previous dictionary | 18-05 | `p18_recon`: non-missing counts exact except NULL-to-missing, distinct counts vs `pdd.prf_pcnr`; **limit stated on the KEY sheet: counts and distinct values, not level-by-level frequencies** | `comb_recon.csv` |
| NO_DATA (56 s06 variables, computed) | 18-05 | `p18_nodata_flags` against `pdd.name_map_vars_coverage`; synthetic T9 | |
| Pipeline token 18, existing wiring unchanged | 18-07 | `test_phase18_wiring_static.py`; pinned `_valid` lists updated in the phase 15, 16 and 17 tests | `99_run_all.sas`, `run_pipeline.cmd` |
| Lint C30-C36, PCM rules | all | `sas_lint` zero errors on every 18 file; `sasjs lint` zero errors | |
