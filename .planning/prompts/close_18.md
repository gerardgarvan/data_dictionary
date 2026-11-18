# close_18 - close Phase 18 (combined 2018-2025 dataset + dictionary)

## Verified results on real data (Gerard, 2026-11-18; counts masked)
- 18_combine_test: ALL TESTS PASSED (incl. T10B, T10C).
- 18a PASS: 0 conversion failures, 1,297 variables.
- 18b PASS: pdd.pcnr_2018_2025 = 77,498 rows x 1,302 columns; registry 59,505,
  dup link 1,895, case map 77,498 unchanged. Second run (backup path) PASS:
  backup pcnrcmb_20261118_130341 taken before replace.
- 18c PASS (after fix_18c, full run): all 19 QC items clean - structure 0
  problems, 1,302 = 5 keys + 1,297; profile_pct_scrubbed 1095,
  profile_pct_implied_small 0; recon_unexplained_deltas 0; NO_DATA 56/56/0/0;
  registry/dup link/case map unchanged.
- 18d PASS: hit count 0.
- Writer (after fix_18d): exit 0, out\pdd_2018_2025.xlsx, sheets KEY,
  VARIABLES, DISTRIBUTIONS, NAME_MAP, SOURCES, QC (KEY leftmost).
- An earlier 18c run was interrupted by the user mid-step ("User asked for
  termination"); the full re-run above supersedes it.

## Do
1. Write .planning/phases/18-combined-dataset-and-dictionary/18-SUMMARY.md:
   what was built, the verified results above, fixes fix_18a/18b/18c/18d with
   one line each on root cause (fix_18c's special-missing hypothesis was wrong
   for the 27 failures; the real cause was NUM_TEXT N vs all non-blank, fixed in
   fix_18d), and lessons (verify causal claims against code; don't close SAS
   before the PASS line).
2. DECISIONS.md: mark PDD-D-33 (Precede##### on K2 rows, PDD_K2_PSID_MODE=NORM)
   and PDD-D-34 (special missings count as missing; n_special shown separately)
   CONFIRMED by Gerard 2026-11-18. Remove all stale "PENDING DECISION" wording
   about PDD_K2_PSID_MODE in Phase 18 plans and docs.
3. Replace the Phase 6 pct carry-over PENDING DECISION in 18-SAS-RUN.md with a
   pointer to a new cleanup-backlog item: "06_profile_macros.sas ~L2185-2230:
   pct_total not reset on NUM_TEXT MEAN..MAX rows. Deferred (fixing re-runs
   Phase 6 and changes v1.0 pdd.prf_pcnr). First check, read-only: does the
   published pdd_v1_0.xlsx show pct on those rows? If yes, raise priority -
   masked counts are back-calculable in a delivered workbook."
4. Also add to the backlog: "unexplained blank-n rows" item is RESOLVED (they
   are NUM_TEXT MEAN..MAX stat rows).
5. Phase 19 handoff note (in ROADMAP/STATE and 18-SUMMARY): Phase 19 builds
   PCNR_Master_Data_Nov_2026.xlsx; any percentages must come from the scrubbed
   exchange profile or be recomputed with the same masking, never from
   pdd.prf_PCNR_2018_2025 directly. Output only under
   P:\PeCAN Master Data\Gerard\data_dictionary.
6. Update STATE.md / ROADMAP.md: Phase 18 complete; next Phase 19. Carry
   forward open items: Price naming sign-off, PDD-D-27, backlog 1/2/3/5, DSS
   question on 116 #Error deaths, future cross-era link (loosen 17c total
   check for superseded IDs).

## Constraints (unchanged)
Docs/planning only - no SAS or Python logic changes. No PHI or data values in
git; counts 1-10 as <11. No push, no branch switch, no history rewrite.
Commit on pdd-2018-2025-api.
