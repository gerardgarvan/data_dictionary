# Phase 18 SUMMARY: Combined dataset and dictionary 2018-2025

**Status: COMPLETE 2026-11-18** (verified on real data by Gerard; counts masked, 1-10 shown as <11).
Requirements DD-01, DD-02, DD-03, DD-04 satisfied.

## What was built
- `pdd.pcnr_2018_2025`: one row per surgery, PECAN_ID and PRECEDE_STUDY_ID first, values as delivered (no recoding), 77,498 rows x 1,302 columns (5 keys + 1,297 PCNR_ variables). Built by `sas/18b_comb_build.sas` from `pdd.pcnr` (2018-2022), `pdd.nsrc_s21..s23` (2023-2025) and `pdd.name_map_ext`, with PDD-D-30 (s22 wins, s23 fills blanks) and PDD-D-31 combined types (`docs/combined_type_decisions.csv`).
- `18a_comb_preflight.sas` (read-only preflight and type delta), `18c_comb_profile_qc.sas` (profile, reconciliation, NO_DATA flags, pct scrub), `18d_comb_scan.sas` (MRN scan), macros in `18_combine_macros.sas`, synthetic test `18_combine_test.sas`.
- Dictionary workbook writer `python/scripts/write_dictionary_2018_2025.py` (`python/pdd/dictionary_2018_2025_workbook.py`) producing `out\pdd_2018_2025.xlsx`, sheets KEY (leftmost), VARIABLES, DISTRIBUTIONS, NAME_MAP, SOURCES, QC.
- Token 18 wired into `99_run_all.sas` and `run_pipeline.cmd`; run sheet `18-SAS-RUN.md`.

## Verified results (real data, Gerard, 2026-11-18)
- `18_combine_test`: ALL TESTS PASSED (including T10B special-missing and T10C pct-scrub).
- 18a PASS: 0 conversion failures, 1,297 variables.
- 18b PASS: 77,498 rows x 1,302 columns; registry 59,505, dup link 1,895, case map 77,498, all unchanged. Second run (backup path) PASS; backup `pcnrcmb_20261118_130341` taken before replace.
- 18c PASS (full run after fix_18c): all 19 QC items clean. Structure 0 problems; 1,302 = 5 keys + 1,297; `profile_pct_scrubbed` 1095; `profile_pct_implied_small` 0; `recon_unexplained_deltas` 0; NO_DATA 56/56/0/0; registry, dup link and case map unchanged.
- 18d PASS: hit count 0.
- Writer (after fix_18d): exit 0, `out\pdd_2018_2025.xlsx`, KEY leftmost.
- An earlier 18c run was interrupted by the user mid-step ("User asked for termination"); the full re-run above supersedes it.

## Decisions confirmed
- PDD-D-33 (K2 `PRECEDE_STUDY_ID` = `Precede#####`, `PDD_K2_PSID_MODE`=NORM): CONFIRMED by Gerard 2026-11-18.
- PDD-D-34 (special missings count as missing; `n_special_comb_all` shown separately): CONFIRMED by Gerard 2026-11-18.

## Fixes during the SAS runs (one line each)
- **fix_18a/18b (first SAS run, commits 975ffdb, e871dd0):** the synthetic test and macros failed on first real execution. Root causes: `where=` text not `%unquote`d (22-322); `%if` on a decimal comparison (character operand); `&_dec` macro variables local to `%_fixtures` instead of `%global`; `CREATE TABLE x AS SELECT ... FROM x` (recursive reference); `p18_order_cols` and `p18_load_types` failing obscurely on missing columns or CSV. Lint C37/C38 and CLAUDE.md pitfalls were added. (The separate fix_18a/18b prompt files do not exist in the repo; this line is taken from the commit messages.)
- **fix_18c:** the writer reported 27 variables where profile N differed from `n_nonmiss_comb_all`. The hypothesis was that special missings (`.A-.Z`, `._`) were counted as non-missing in recon. **That hypothesis was wrong for the 27 failures** (`n_special_comb_all` was 0 on them). The change itself is kept as the PDD-D-34 decision: recon counts `not missing(x)`, adds `n_special_comb_all`, and 18c now scrubs pct on blank, masked or small-n profile rows (the pct leak was real).
- **fix_18d:** the real cause of the 27 failures: all are NUM_TEXT (character holding numbers). Profile N counts only cells that parse as numbers; `n_nonmiss_comb_all` counts every non-blank cell (N + N_UNPARSED). The writer `reconcile()` now checks NUM_TEXT as N + N_UNPARSED (exact when N_UNPARSED is a number; gap 1-10 when masked <11).

## Lessons
- Verify causal claims against the code and the data before changing code. fix_18c asserted a cause from a correlation in the output and fixed the wrong thing; reading how the profile counts NUM_TEXT would have found the real cause at once.
- Do not close SAS before the PASS line is in the log (an interrupted 18c run cost a re-run).
- Test harness checks need to be able to fail when they cannot be evaluated (preset FAIL), and macro-quoting pitfalls (`%unquote`, `%global`) show up only on a real SAS run; keep them in lint.

## Phase 19 handoff
Phase 19 builds `PCNR_Master_Data_Nov_2026.xlsx`. Any percentages in it must come from the scrubbed exchange profile (`profile_PCNR_2018_2025.csv` after 18c) or be recomputed with the same masking. **Never read them from `pdd.prf_PCNR_2018_2025` directly.** Output only under `P:\PeCAN Master Data\Gerard\data_dictionary`.

## Open items carried forward
Price naming sign-off; PDD-D-27 (dictionary as a sheet in the master file, default no); cleanup backlog items 1, 2, 3, 5 and 6 (see STATE.md); DSS question on the 116 `#Error` deaths (Death_Date_Y_N = Y); future cross-era link (loosen the 17c total check for superseded IDs).

## Assumptions (headless run)
- fix_18a/18b root causes were reconstructed from commit messages 975ffdb and e871dd0, since no prompt files for them are in the repo.
- Docs and planning only; no SAS or Python logic changed in this close-out.
