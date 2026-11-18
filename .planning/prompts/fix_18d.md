# fix_18d - NUM_TEXT reconciliation + pct carry-over in 18c

## Facts (Gerard's run after fix_18c; counts masked)
- 18c (fixed code) PASS, all 19 QC items clean, 18d PASS. Writer still exits 1
  on the same 27 variables. n_special_comb_all = 0 for all checked ones, so
  fix_18c's special-missing hypothesis did NOT explain them.
- All 27 are var_class NUM_TEXT (character holding numbers). Profile rows:
  N (parses as numeric), N_MISSING (blank), N_UNPARSED (non-blank, does not
  parse; masked <11), then MEAN..MAX (n blank by design) and LEVEL rows
  (the unparsed text values, small_cell_flag=Y).
  N + N_UNPARSED + N_MISSING = 77,498. comb_recon n_nonmiss_comb_all = all
  non-blank = N + N_UNPARSED (e.g. 1408 + <11 = 1415).
- Before fix_18c's scrub, the MEAN..MAX rows of NUM_TEXT variables carried the
  same pct_total as the preceding N_UNPARSED row: a value carried over between
  rows in 18c's profile output, not a real percentage.

## Do
1. Writer reconcile() in python/pdd/dictionary_2018_2025_workbook.py: for
   var_class NUM_TEXT, expected = N + N_UNPARSED. If N_UNPARSED is a number,
   require exact equality with n_nonmiss_comb_all. If it is "<11", require
   1 <= (n_nonmiss_comb_all - N) <= 10. If N_UNPARSED is absent or 0, require
   equality with N. All other var_class values: unchanged.
2. Decide what VARIABLES shows as n_nonmiss for NUM_TEXT by checking how the
   v1.0 workbook writer handles NUM_TEXT, and match v1.0. Report which and
   where in the summary. If v1.0 shows N with unparsed separately, keep that.
3. 18c: find where pct_total (and any other column) carries over from the
   N_UNPARSED row onto MEAN..MAX rows (likely a RETAIN or a variable not reset
   between output rows) and fix it at the source. Keep p18_pct_scrub as a
   defence. Do not change pdd.prf_pcnr or any v1.0 output.
4. DECISIONS.md PDD-D-34: keep the decision (special missings count as
   missing; n_special shown separately) but correct the note: it did not cause
   the 27 writer failures; the cause was NUM_TEXT N vs non-blank.
5. Tests: python/tests/test_dictionary_2018_2025.py - NUM_TEXT variable with
   unmasked N_UNPARSED reconciles; with "<11" and a gap of 1-10 reconciles;
   with "<11" and a gap of 0 or 11+ fails; numeric variables unchanged. If
   step 3 changes SAS, add a check to sas/18_combine_test.sas that stat rows
   with blank n have blank pct_total before the scrub. Run pytest + lint.
6. Update 18-SAS-RUN.md with the re-run order: if step 3 changed SAS code ->
   18_combine_test, 18c, 18d (fresh sessions), writer; if not -> writer only.
   Also note: do not close SAS until 18c's PASS line is in the log (a previous
   run was interrupted mid-step).

## Constraints (unchanged)
Verify every causal claim against the code before stating it; say plainly if
unconfirmed. No PHI or data values in git; counts 1-10 as <11. Never write to
the shared Master Data folder. No push, no branch switch, no history rewrite.
Do not touch registry, dup link, case map or pdd.pcnr_2018_2025. Commit on
pdd-2018-2025-api.
