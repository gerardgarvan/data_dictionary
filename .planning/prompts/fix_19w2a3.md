# fix_19w2a3 - %p19_expected writes a space into empty fields

Evidence (synthetic s1_exp.csv from 19_xlsx_test run 2; spaces shown as ·):
  [ROWS,,6,·,]          expected [ROWS,,6,,]
  [SAMPLE,,1,·,] ...    expected [SAMPLE,,1,,]
COL lines are correct. Cause: the final DATA step of %p19_expected builds _l
with ifc(missing(x), '', strip(put(x, best12.))); the IFC result is padded to
the other argument's length, so an empty field becomes one blank (the last
field's blank is dropped by PUT trimming). T18_EXPECTED_COUNTS_... fails.

Do:
1. In %p19_expected (sas/19_xlsx_macros.sas), replace the ifc() expressions:
   length _a _b _c $12; set each to '' when missing, else
   strip(put(x, best12.)); then
   _l = strip(p19_kind) || ',' || strip(p19_var) || ',' || strip(_a) || ','
        || strip(_b) || ',' || strip(_c);
   Grep sas/ for any other ifc(...) used inside a || concatenation written to a
   CSV and fix the same way.
2. Add lint rule C41 (warning or error, your call, explain): ifc() used as an
   operand of || .
3. Check python/pdd/master_verify.py parses xlsx_expected.csv per the
   contract with empty fields as missing; add a unit test with an empty field.
4. Lint + ruff + pytest green.

Constraints unchanged. Commit on pdd-2018-2025-api; no push.
