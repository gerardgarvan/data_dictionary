# Phase 6 Context — Design Decisions

## D-09 Production Wiring and require_suppress (2026-10-26)

**Decision recorded after Phase 6 4bb258f pipeline run.**

### Problem
`06_profile.sas` called `%pdd_profile` without `suppress_file=`, so suppression was silently skipped ("p6_suppressed: no SUPPRESSED variables -- skipping"). The suppress list `docs/profile_suppress.csv` (10 variables) was correct but never applied.

### Fix
`06_profile.sas` now passes both files as literal paths (same convention as `00_config.sas`):

```
suppress_file="C:\data_dictionary\docs\profile_suppress.csv"
categorical_file="C:\data_dictionary\docs\profile_categorical.csv"
```

### require_suppress=1 guard
`%pdd_profile` gained `require_suppress=1` (default). When 1 and `suppress_file` is blank, the file is missing, or has 0 data rows, the macro calls `%p6_fail_out` and aborts. Unit tests that do not use suppression pass `require_suppress=0` explicitly.

### CSV loading
`profile_suppress.csv` and `profile_categorical.csv` are read with a DATA step INFILE (dsd, firstobs=2, length variable $32 reason $100) instead of PROC IMPORT. This avoids SAS type/length guessing and produces reproducible column lengths.

### D-09 output validation in %p6_write_output
When `work._p6_suppress_raw` exists (suppression was applied), `%p6_write_output` now validates:
1. Every suppress-list variable appears in output with `var_class='SUPPRESSED'`.
2. No LEVEL row exists for any SUPPRESSED variable.
3. All rows for SUPPRESSED variables have blank `level`.

### Pipeline log diagnostic
The NOTE `D-09: N SUPPRESSED variable(s) loaded from suppress_file` is emitted by `%pdd_profile` after reclassification and is checked by `pdd_logdiag` Phase 6 section.

---

## D-11 Categorical Override for NUM_TEXT (2026-10-26)

**Decision recorded after Phase 6 4bb258f pipeline run.**

### Problem
51 variables were classified as NUM_TEXT in production. CPT codes and base procedure codes are legitimate categorical codes whose values happen to be numeric strings. NUM_TEXT reclassification is wrong for these.

### Fix
`%pdd_profile` gained `categorical_file=` parameter. Variables listed in that CSV are excluded from the NUM_TEXT eligibility query in `%p6_numtext`. They remain HIGH_CARD or LOW_CARD as classified by `%p6_classify_vars`.

### Seeded variables in docs/profile_categorical.csv
PCNR_CPT_1, PCNR_ron_CPT_1, PCNR_ron_CPT_2_DIGIT, PCNR_ron_CPT_3_DIGIT,
PCNR_ron_CPT_4_DIGIT, PCNR_CPT1_Class, PCNR_Base_Procedure_Code_1,
PCNR_ron_Base_Procedure_Code_1, PCNR_ron_BPC_4_DIGIT, PCNR_ron_BPC_5_DIGIT,
PCNR_ron_BPC_6_DIGIT, PCNR_ron_BPC_7_DIGIT.

### Validation
`categorical_file` variables are validated: every listed variable must exist in the source dataset (via `work._p6_vars` after prefix filtering). A missing variable triggers `%p6_fail_out`.
