# revise_17 -- PDD-D-32 and K1 source change

Headless run. Follow RULES and CLAUDE.md. Commit once, do not push.

## Findings (probe_xwalk_20261117.md, probe_xwalk2_20261117.md)
- s06 uses a different MRN encryption than the rest of 2018-2022: 13,044 distinct
  MRNs, 0 in spine, all in xwalk. s03/s07: 13,044 distinct, all in spine, 1,895 in xwalk.
- g.pecan_id_xwalk (33,031) = 19,987 spine-format MRNs + 13,044 s06-format MRNs.
- The 11,149 spine MRNs not in the xwalk = s03/s07 patients whose MRN was replaced by
  the s06 version in the master merge (13,044 - 1,895).
- g.MASTER_DATA_HARMONIZED: 41,150 rows (= spine rows), pecan_ID on every row,
  33,031 distinct IDs = distinct MRNs. 33,031 - 31,136 spine patients = ~1,895
  patients likely carrying two pecan_IDs (one per encryption). Looser MRN rules gain 0.

## Decision PDD-D-32 (Gerard, 2026-11-17)
- K1 PECAN_ID = existing pecan_ID from g.MASTER_DATA_HARMONIZED, taken row by row
  through a surgery-level key, NOT by MRN lookup in g.pecan_id_xwalk. IDs unchanged.
- Patients with two K1 IDs are kept as is and recorded in an append-only link table
  pdd.pecan_id_dup_link (pecan_id_a, pecan_id_b, link_basis, n_surgeries_a/b,
  decided_on), so they can be merged later. No merge now.
- K2 (2023-2025) unchanged: 1000000 + rank, registry, PDD-D-26.
Record PDD-D-32 in STATE.md decisions and MILESTONE_BRIEF_2018_2025.md (PID section);
mark the old "K1 from xwalk" wording superseded.

## Revise Phase 17 plans
Update 17-CONTEXT, the affected 17-0x plans, 17-VALIDATION and 17-SAS-RUN:
- K1 join: spine pdd.src_s09 to g.MASTER_DATA_HARMONIZED on the surgery key that
  probe 3 confirms; gate = 41,150 rows matched 1:1, 0 missing pecan_ID, 0 rows
  matching more than one harmonized row.
- Dup link: a spine MRN mapped to more than one pecan_ID defines a pair. Gate reports
  the pair count; expected near 1,895 but computed at run time, not hard-coded.
- Synthetic test 17_pecan_id_test.sas gets cases for both (1:1 join, a dup pair).
- Report the count of blank spine MRNs (1 row) on its own line.

## Write sas/17_probe_xwalk3.sas (PR-3), same privacy rules as PR-1/PR-2
Output .planning/schemas/probe_xwalk3_<date>.md, counts and names only, 1-10 as <11.
1. Candidate surgery keys present in both pdd.src_s09 and g.MASTER_DATA_HARMONIZED
   (norm_psid, any PSID/surgery/case ID columns found via dictionary.columns, and row
   order as a last resort): for each, distinct count on each side, matched rows,
   rows matching 0 or >1. Name the key that gives 41,150 one-to-one.
2. Using the best key: spine distinct MRN -> number of distinct pecan_IDs
   (histogram 1, 2, 3+); pecan_IDs with more than one spine MRN; total implied
   dup pairs.
3. For the dup patients: counts by spine YEAR on each side of the pair.
4. Spine YEAR distribution of the 11,149 unmatched MRNs (re-check of PR-2 section 3).
Fix the PUTN label bug from PR-2 pattern (no %sysfunc(putn) inside %str labels).
Run lint C30-C32, commit, do not push.
