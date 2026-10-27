# Phase 6 — Distribution Engine: VERIFICATION

**Verified:** 2026-10-26
**Commit:** e912941 (fix/04-decisions, merged to master)
**Verifier:** pipeline live run + check_test_log.ps1 + user sign-off

---

## Goal-backward analysis

**Phase 6 goal:** Build `%pdd_profile` — a reusable macro that classifies every variable in a dataset by distinct-value count, computes the appropriate distribution statistics, and writes a 13-column long-format profile to `pdd.prf_&family` plus an exchange CSV.

**Done-when criteria from ROADMAP.md:**
> Run on `pdd.pcnr`; sex and Patient_Type counts match PROC FREQ; missing counts are exact.

All criteria met. See evidence below.

---

## Verification checklist

### Functional requirements

| Requirement | Evidence | Status |
|-------------|----------|--------|
| `%pdd_profile` runs on `pdd.pcnr` | Pipeline exit 0; `pdd.prf_pcnr` created | ✅ |
| PCNR_SEX level counts match PROC FREQ | TC-03: `TC03-sex-levels-match-freq` PASS | ✅ |
| PCNR_PATIENT_TYPE level counts match PROC FREQ | TC-03: `TC03-pt-levels-match-freq` PASS | ✅ |
| Missing counts match independent PROC MEANS NMISS | TC-03: `TC03-missing-counts-match-indep` PASS | ✅ |
| D-08 reconciliation: all variables sum to 41,150 | TC-03: `TC03-recon-41150-all-vars` PASS; pipeline D-08 PASS | ✅ |
| 1,297 distinct variables in pdd.prf_pcnr | TC-03: `TC03-1297-variables` PASS | ✅ |
| 56 all-missing variables have single MISSING row | TC-03: `TC03-56-all-missing-vars` PASS | ✅ |
| NORM_PSID excluded from output | TC-06 PASS | ✅ |
| LINKAGE_ONLY variables excluded | TC-06 PASS | ✅ |
| 13-column schema locked | TC-02 / TC-03 schema check PASS | ✅ |
| small_cell_flag Y on rows where 1≤n≤10 | TC-05 PASS | ✅ |
| D-07: 100%-missing variable → single MISSING row | TC-08 PASS | ✅ |
| DATE tier classification | TC-07 PASS | ✅ |
| D-09 SUPPRESSED: 10 vars, no LEVEL rows | Pipeline D-09 validation PASS; TC-15, TC-16 PASS | ✅ |
| D-09 require_suppress=1 guard | TC-24 expected-fail PASS | ✅ |
| D-10 NUM_TEXT reclassification | TC-17, TC-18, TC-19, TC-20, TC-22 PASS | ✅ |
| D-11 categorical override skips NUM_TEXT | TC-25 PASS | ✅ |
| Rerun safety (stale WORK._p6_* deletion) | TC-12 PASS | ✅ |
| Wired into 99_run_all.sas / run_pipeline.cmd | Pipeline exit 0 confirmed | ✅ |
| Exchange CSV written (export=1) | `exchange\profile_PCNR.csv` confirmed | ✅ |

### Quality gates

| Gate | Result |
|------|--------|
| `python tools/sas_lint.py sas/06_profile_macros.sas` | clean — no errors (83 warnings) |
| `python tools/sas_lint.py tests/06_profile_test.sas` | clean — no errors (92 warnings) |
| `sasjs lint` | warnings only (pre-existing; no new errors) |
| `python -m ruff check python/` | All checks passed |
| `python -m pytest python/tests -q` | 91 passed |
| `tools/check_test_log.ps1 -Log <test.log>` | RESULT: PASS |
| SAS test SUMMARY | passed=138 failed=0 skipped=0 |
| Pipeline exit code | 0 |
| Pipeline warnings | 0 |

### Production output

| Metric | Value |
|--------|-------|
| `pdd.prf_pcnr` rows | 5,642 |
| Variables profiled | 1,297 |
| LOW_CARD | 1,097 |
| CONT_NUM | 123 |
| NUM_TEXT | 38 |
| HIGH_CARD | 29 |
| SUPPRESSED | 10 |
| DATE | confirmed present |

---

## Open items for Phase 7 (not Phase 6 defects)

These are known findings from the Phase 6 production run that Phase 7 must handle as display decisions, not data errors. None block Phase 6 sign-off.

| Item | Finding | Phase 7 action required |
|------|---------|------------------------|
| Age 90+ display | Profile max = 100; Safe Harbor requires display as 90 | Phase 7 display setting; ask Price |
| Small-cell display | 805 flagged rows / 191 vars (small_cell_flag='Y'); includes unparsed text entries of NUM_TEXT vars | Phase 7 display setting; ask Price |
| Placeholder text and mixed codes | F/FEMALE, NULL, ?, N/A in 136 vars | Phase 7 display setting; ask Price |
| 56 all-missing s06 fields | Profile emits single MISSING row n=41,150 for each | Phase 7 display decision; ask Price |
| Text dates (currently SUPPRESSED) | PCNR_test_date, PCNR_preop_date suppressed; no LEVEL rows | Phase 7 display setting |
| NUM_TEXT 38 variables | CPT codes excluded via categorical_file; 38 remain | Verify with Price; add to categorical_file if more code vars identified |

---

**Phase 6 status: ✅ COMPLETE**
