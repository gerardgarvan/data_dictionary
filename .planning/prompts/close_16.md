# close_16 -- close Phase 16 (name map extension)

Headless run. Follow the RULES block and CLAUDE.md. Do not push, do not switch
branches, do not rewrite history. Commit once at the end.

## 1. Fill .planning/phases/16-*/16-05-SUMMARY.md

Gerard ran `.\run_pipeline.cmd 16` on 2026-11-17 on the SAS machine:
PIPELINE PASSED, 0 WARNING lines in 99_run_all.log, review workbook
name_map_ext_review.xlsx written. Synthetic test 16_name_map_ext_test.sas:
TESTRESULT SUMMARY ALL TESTS PASSED (T1-T9).

Masked results (counts 1-10 already shown as <11 where they count data cells):

16a
- PASS -- all candidates decided
- n_new_rows=282 = key 3 + linkage_only 6 + exact_reuse 255 + same_decided 18
  + named 0 + pending_decision 0 (reconciles)

16b
- pdd.qc_map_ext_values: 1987 rows
- MAP-04 coverage: 1297 variables, 56 NO_DATA, 0 PENDING keys
- pdd.name_map_coverage: 2279 rows; pdd.name_map_vars_coverage: 1297 rows
- Per source (variables / NO_DATA / NO_YEAR cells / distinct years):
  s01 2/0/534/5, s02 2/0/<11/3, s03 99/0/0/2, s06 1237/56/8616/2,
  s07 102/0/0/2, s08 7/0/0/5, s09 121/0/0/5, s10 111/0/0/1, s11 2/0/<11/1,
  s12 83/0/0/1, s13 1/0/0/1, s14 5/0/0/1, s15 81/0/0/1, s16 1/0/0/1,
  s17 81/0/0/1, s18 3/0/807/1, s19 65/0/0/3, s20 3/0/0/5,
  s21 91/0/0/1, s22 91/0/0/1, s23 91/0/0/1
- s04 and s05 have no coverage line (no mapped PCNR/pending columns, skipped
  by design). Confirm against pdd.name_map_ext logic in 16b and say so.
- All 56 NO_DATA variables are in s06. Record as an observation for Phase 18
  (dictionary should flag them), not a failure.

Fixes made on 2026-11-17 during the run (already committed by Gerard):
- 16_name_map_ext_test.sas: T2/T3 DATA step had no driving SET and
  %p16_shorten reads with SET ... POINT=, so the step never ended and filled
  the C: drive (WORK). Added STOP. Column `case` renamed `tcase` because CASE
  is reserved in PROC SQL (T2/T3 SQL checks failed with 22-322).
- 16b_name_map_values_cov.sas: generated coverage step now declares
  placeholders `_p16_dn 8` and `_p16_dc $1` before
  `array _an[*] _numeric_` / `array _ac[*] _character_`, removing 5
  "Defining an array with zero elements" warnings (s08, s13 and three others).

## 2. STATE.md / ROADMAP.md

- Mark Phase 16 complete (2026-11-17). Next: Phase 17 (PECAN_ID).
- Cleanup backlog item 4 (16b zero-element array warnings): DONE, cite the
  16b fix. Leave items 1, 2, 3, 5 open.
- Keep the Phase 18 notes (ASA and CPT1 Class numeric; PDD-D-30, PDD-D-31)
  and add the s06 NO_DATA observation.

## 3. CLAUDE.md SAS pitfalls + lint

Add two pitfalls to the SAS pitfalls list in CLAUDE.md and two lint rules next
to C30 (same lint script, same style, with a test case each):

- C31: A DATA step that executes SET ... POINT= (directly or through a macro)
  and has no other SET/MERGE/INPUT that reaches end of file must contain
  STOP. Without it the step loops forever. Lint heuristic: flag a DATA step
  containing `point=` (or a call to a macro known to use POINT=, starting with
  %p16_shorten and %p16_assign_names) with no plain SET/MERGE/INFILE and no
  `stop;`. Run it on all sas/*.sas and report hits; fix only true positives.
- C32: Do not name a column `case` (or other PROC SQL reserved words used as
  bare identifiers: case, when, then, else, end, as, on) when the column is
  referenced in PROC SQL. Lint heuristic: flag `where case` / `select case =`
  patterns and `case $` / `case =` assignments in DATA steps of files that
  also use PROC SQL on that dataset. Keep false positives low; CASE WHEN
  expressions are fine.

Run the lint over sas/ and include the hit list (file:line, rule) in the
summary. Do not change program logic beyond true-positive fixes.

## 4. Commit

One commit: `docs(16): close Phase 16 -- summary, state, pitfalls C31 C32`.
Print the final summary with files changed and lint hits.
