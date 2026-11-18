# fix_18c - special-missing definition mismatch + pct back-calculation leak

## Facts (from Gerard's run, counts masked)
- 18a/18b/18c/18d all PASS. write_dictionary_2018_2025.py exits 1: reconcile() in
  python/pdd/dictionary_2018_2025_workbook.py reports 27 variables where profile N
  != comb_recon n_nonmiss_comb_all (neuropsych HVLT/COWA/animal fluency/MMSE/WAIS
  span + blood APTT/INR LAB_VAL). All 27 have n_nonmiss_comb_k2 = 0, delta_k1 = 0,
  n_distinct_k1 = n_distinct_prf_v1.
- For every one, (n_nonmiss_comb_all - profile N) equals the total of the
  variable's special-missing block in profile_PCNR_2018_2025.csv (.A-.Z, ._).
  Variables without special missings reconcile.
- In that block, rows with n masked (<11) or blank still carry an exact pct_total
  (e.g. 0.00129036 = 1/77,498). That back-calculates masked counts.

## Do
1. Read the 18c code (sas/18c_comb_profile_qc.sas, sas/18_combine_macros.sas) and
   confirm how n_nonmiss_pcnr_old / n_nonmiss_comb_k1/k2/all are counted versus
   how the profile computes N and the special-missing block. Confirm or refute
   the hypothesis in your summary before changing code.
2. Make comb_recon match SAS semantics: n_nonmiss_* counts only `not missing(x)`
   (special missings are missing) - for pcnr_old, k1, k2 and all alike, so
   delta_k1 stays like-for-like. Add n_special_comb_all (masked <11 like the
   other counts) so special-missing codes stay visible. Update
   exchange_schema.csv, _assert_columns and _guard_count_cells as needed.
3. Close the pct leak in 18c: on any profile row whose n is masked or blank,
   pct_total and pct_nonmiss must be blank. Explain in the summary what the
   blank-n rows inside the special-missing block are and fix them if they are
   an artifact.
4. Add a writer guard: refuse to write (hard fail, like _guard_count_cells) any
   pct cell whose implied count (pct/100 * total_rows, rounded) is 1-10, in any
   exchange file the workbook reads.
5. Tests: extend sas/18_combine_test.sas with a variable holding .A/.B values
   (recon n_nonmiss excludes them, n_special counts them, pct blank on masked
   rows). Extend python/tests/test_dictionary_2018_2025.py: special-missing
   variable reconciles; pct back-calculation guard fails. Run pytest + lint.
6. Record decision PDD-D-34 (special missings count as missing for N; shown
   separately as n_special) in the decisions log. Update 18-SAS-RUN.md with the
   re-run order: 18_combine_test, 18c (fresh session), 18d (fresh session),
   writer. 18a/18b do not need a re-run.

## Constraints (unchanged)
No PHI or data values in git; counts 1-10 as <11. Never write to the shared
Master Data folder. No push, no branch switch, no history rewrite. Do not
touch registry, dup link, case map or pdd.pcnr_2018_2025. Do not seed any
baseline. Commit on pdd-2018-2025-api with a clear message.
