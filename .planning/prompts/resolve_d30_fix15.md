Record PDD-D-30 and apply the Phase 15 fixes from Gerard's first SAS run. Non-interactive; do not ask questions.

## Evidence (committed)
- `.planning/schemas/overlap_s22_s23_20261116.md` (sas/15d_overlap_diag.sas): s22 (2024) and s23 (2025) share
  142 normalized case IDs, one contiguous block 65370-65511 (s23's lowest ID is 65370). ENCRYPTED_MRN and
  ENCRYPTED_ENCOUNTER match on all 142. 87 of 91 compared columns are identical for every shared case.
  Differences: YEAR (all 142), ICU_LOS_TOTAL_TIME_HOURS (37), CognitiveDisorder_YN (15), EmployeeStatus (<11).
  92 cases differ only in YEAR.
- Gerard's 15c run summary: rowcounts MATCH x3; ONE_TO_ONE PASS x3; PAIRWISE_NEW s21-s22 0, s21-s23 0,
  s22-s23 142; SPINE 0 x3; OLD20_UNION 0 x3; GATE PDD-D-29 item 3 STOP; GATE OLD20_UNION PASS; GATE 1:1 PASS.

## PDD-D-30 (DECIDED, Gerard 2026-11-16)
The 142 shared cases are the same surgeries delivered in both the 2024 and 2025 extracts (overlapping extract
windows), not an ID collision. Precedence: **s22 (2024) wins; s23 (2025) only fills values that are blank in
s22** (same rule as the existing PCNR_ spine-wins/gap-fill build). YEAR for these cases is 2024. Conflicting
non-blank values are reported to QC (counts per column), never silently merged. No row is dropped at import:
`pdd.nsrc_s22` and `pdd.nsrc_s23` stay exactly as delivered; the rule is applied when the combined dataset is
built (Phase 18).

## Edits

1. `docs/DECISIONS.md`: add PDD-D-30 (DECIDED) with the text above and the evidence table. Update PDD-D-29
   item 3 to cite PDD-D-30 as its resolution for the s22 x s23 pair.
2. New committed file `docs/new_overlap_decisions.csv` (add a `.gitignore` exception; metadata only):
   `pair,expected_n_shared,id_min,id_max,rule,decision`
   `s22_s23,142,65370,65511,EARLIER_WINS_GAPFILL,PDD-D-30`
3. `sas/15c_new_import.sas`, overlap gate:
   - s21-s22 and s21-s23 must be 0 (unchanged: any non-zero is PENDING DECISION).
   - s22-s23: PASS only if n_shared equals `expected_n_shared` from docs/new_overlap_decisions.csv AND the shared
     IDs' numeric range equals id_min..id_max AND ENCRYPTED_MRN and ENCRYPTED_ENCOUNTER are equal for every
     shared case (count mismatches; must be 0). Otherwise `%fail_out` with PENDING DECISION and the counts.
   - Write `exchange\new_overlap_conflicts.csv` (`pair,column,n_cases_differ`), counts only, for every column
     that differs on the shared cases; add it to docs/exchange_schema.csv and to the QC workbook as sheet
     `OVERLAP_CONFLICTS` (python/pdd/new_source_qc_workbook.py, tests updated, KEY rows updated). The summary
     line becomes `GATE PDD-D-29 item 3: PASS (s22-s23 = 142 per PDD-D-30)` when the decided case holds.
4. Bug fix, all three programs (15a, 15b, 15c): `ERROR 180-322` came from semicolons inside `%put` text
   (e.g. the 1:1 PASS NOTE "(multi-case patients make distinct MRN below row count; ...)", the row-count NOTE,
   the "shared cases exist" NOTE). Remove every semicolon from `%put` text and from `%str()` messages passed to
   `%fail_out` (use a comma or dash). Add a check for this to `tools/sas_lint.py` (new rule: `;` inside the text
   of a `%put` before its terminating semicolon, or inside `%str(` arguments to `%fail_out`) with a test in
   python/tests/test_sas_lint.py, then run it on every sas/*.sas and fix what it finds in the 15x programs only.
5. Bug fix, `%fail_out` in 15a, 15b, 15c: print the `ERROR:` line BEFORE `%restore_log` so the gate message
   lands in the program's log file (Gerard's run showed it only in the SAS Log window).
6. `docs/new_source_header_variants.csv`: the two Braden Sensory rows get the full headers from the 15b log:
   `BRADEN_2024_OUT_Braden Sensory Perception` and `BRADEN_2025_OUT_Braden Sensory Perception`. Remove the
   "probe cuts header at 32 chars" note. Update the variants test if it checks the header text.
7. `.planning/REQUIREMENTS.md` / brief: add to Phase 18 (DD-01) "apply PDD-D-30: s22 wins, s23 gap-fills for
   the 142 shared cases; QC the conflicts". Record in STATE.md: 15a done (baseline approved and committed),
   15b done (spec committed), 15c run 1 stopped at PDD-D-29 item 3, now resolved by PDD-D-30; next step is
   rerunning 15c, then `run_pipeline.cmd 15`.
8. Keep `sas/15d_overlap_diag.sas` as a committed one-off diagnostic; mention it in 15-SAS-RUN.md.

Run sas_lint, sasjs lint, ruff, and pytest; all green. Commit as separate commits (decision, 15c gate,
lint rule and semicolon fixes, fail_out fix, variants). Report what changed and the exact rerun steps.
