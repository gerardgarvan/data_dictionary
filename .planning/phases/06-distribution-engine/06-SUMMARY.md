# Phase 6 — Distribution Engine: SUMMARY

**Completed:** 2026-10-26
**Merged to master:** e912941
**Branch:** fix/04-decisions

---

## What was built

`sas/06_profile_macros.sas` — full macro library:
- `%_p6_init_globals`, `%p6_fail_out`, `%_p6_ok`, `%p6_assert_rowcount` — utility layer
- `%p6_route_log` / `%p6_restore_log` — standalone vs. pipeline log routing
- `%p6_preflight` — dataset + name_map existence guard; require_name_map= flag
- `%p6_classify_vars` — four-tier classification (DATE, LOW_CARD, CONT_NUM, HIGH_CARD) from DICTIONARY.COLUMNS
- `%_p6_attrib` — locked 13-column schema declaration macro
- `%_p6_read_varlist(file=, out=)` — shared CSV reader for suppress/categorical lists; strips quote-wrapping via `%qsysfunc(dequote())`, uses `filename` ref + INFILE dsd firstobs=2; fails on missing file or syserr>4
- `%p6_freq_lowcard` — PROC FREQ batched (100 vars/batch) for LOW_CARD variables
- `%p6_stats_contnum` — PROC MEANS stackodsoutput for CONT_NUM/DATE variables
- `%p6_freq_highcard` — PROC FREQ batched top-10 + OTHER + N_DISTINCT for HIGH_CARD variables
- `%p6_suppressed` — D-09: one DATA step over all SUPPRESSED vars; emits N_DISTINCT, RANGE_MIN, RANGE_MAX, N, MISSING (level always blank); RANGE uses numeric min/max if ≥95% parse else char lengths with display_format='LENGTH'
- `%p6_numtext` — D-10: one DATA step pass counts parse rates for all HIGH_CARD char vars; reclassifies vars meeting num_text_threshold to NUM_TEXT; emits N, N_MISSING, N_UNPARSED, MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX, up to 5 LEVEL rows for unparsed values
- `%p6_write_output` — D-08 reconciliation, HIGH_CARD level/N_DISTINCT checks, variable-set check, 13-column schema check, integrity checks (blank variable, duplicates, mixed var_class), D-09 SUPPRESSED output validation; publishes to `&outlib..prf_&family`; exports UTF-8 CSV when export=1
- `%pdd_profile` — entry point; signature: `lib= ds= prefix= family= outlib= export=1 require_name_map=1 suppress_file= require_suppress=1 categorical_file= num_text_threshold=0.95`

`sas/06_profile.sas` — orchestrator: calls `%p6_route_log`, `%pdd_profile`, `%p6_restore_log`; wired into `sas/99_run_all.sas`.

`tests/06_profile_test.sas` — 138-assertion synthetic + integration test suite:
- TC-01..TC-12: classification, schema, reconciliation, rerun safety, DATE tier, D-07 all-missing, D-05 exclusions, D-04 small_cell_flag, LOW_CARD/HIGH_CARD row counts
- TC-13..TC-19: zero-missing fix, date format detection, suppression (D-09), NUM_TEXT (D-10), parse rate below threshold, NUM_TEXT level rows
- TC-20..TC-22: NUM_TEXT statistics, no-fail on synthetic profile, NUM_TEXT LEVEL rows exact
- TC-24: require_suppress=1 expected-fail when suppress_file omitted
- TC-25: categorical_file lists T_NUMTXT → stays HIGH_CARD, no NUM_TEXT reclassification
- TC-03: integration on pdd.pcnr (pdd.pcnr required on machine; skipped if absent)

`docs/profile_suppress.csv` — 10 PCNR variables: 2 IDs, 4 free-text, 2 staff names, 2 date small-cell vars.

`docs/profile_categorical.csv` — 12 CPT/BPC code variables excluded from NUM_TEXT reclassification (D-11).

`docs/06-CONTEXT.md` — D-09 production wiring, require_suppress guard, D-11 categorical override decisions.

`tools/check_test_log.ps1` — PowerShell external log hygiene checker; `-Log <path>` required, `-Phase <label>` optional for 99_run_all.log scoping.

`.gitignore` — exceptions added for `docs/profile_suppress.csv` and `docs/profile_categorical.csv`.

---

## Key decisions made during Phase 6

| Decision | Resolution |
|----------|------------|
| D-09 suppress wiring | `require_suppress=1` default; DATA step INFILE reader via `%_p6_read_varlist`; shared reader strips quote-wrapping |
| D-11 categorical override | `categorical_file=` param; listed HIGH_CARD vars skip NUM_TEXT check; validated vs. dataset |
| NLEVELS batch keep= | `keep=(TableVar NLevels NNonMissLevels)` on each batch to suppress `TableVarLabel` "Multiple lengths" WARNING |
| vname() SUBSTR bug | Replaced with macro-generated IF chain (`if _j=1 then varname="&&_p6_ntrv_1"; ...`) |
| proc printto removed | All in-SAS log scanning deleted; replaced with external `tools/check_test_log.ps1` |
| call missing(of _all_) | Added to every DATA step that uses `%_p6_attrib` to prevent uninitialized variable NOTEs |

---

## Pipeline run results (production)

- `pdd.prf_pcnr`: 5,642 rows / 1,297 variables
- Classification breakdown: LOW_CARD 1,097 | CONT_NUM 123 | NUM_TEXT 38 | HIGH_CARD 29 | SUPPRESSED 10
- D-08 reconciliation: PASS (all variables)
- D-09 validation: PASS (10 SUPPRESSED variables, no LEVEL rows, blank level)
- Tests: passed=138 failed=0
- `check_test_log.ps1`: PASS
- Pipeline: exit 0, 0 warnings

---

## Files changed

| File | Change |
|------|--------|
| `sas/06_profile_macros.sas` | Created (2,800+ lines) |
| `sas/06_profile.sas` | Created |
| `tests/06_profile_test.sas` | Created (1,950+ lines) |
| `docs/profile_suppress.csv` | Created |
| `docs/profile_categorical.csv` | Created |
| `docs/06-CONTEXT.md` | Created |
| `tools/check_test_log.ps1` | Created |
| `sas/99_run_all.sas` | Phase 6 block wired in |
| `.gitignore` | Exceptions for Phase 6 docs CSVs |
