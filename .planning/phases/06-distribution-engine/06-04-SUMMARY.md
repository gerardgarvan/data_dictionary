---
phase: 06-distribution-engine
plan: "04"
subsystem: test-suite
tags: [sas, testing, profiler, acceptance]
dependency_graph:
  requires: ["06-02"]
  provides: ["TC-01..TC-12 acceptance tests for pdd_profile"]
  affects: ["06_profile_macros.sas verification"]
tech_stack:
  added: []
  patterns:
    - "Flag-based _assert macro (pre-computed 0/1, not raw expression)"
    - "_assert_fail checks p6_fail=1 AND message contains expected_text"
    - "TC-03 wrapped in macro to allow open-code %include of 00_config (C3)"
    - "Synthetic fixture 50 rows; TC-12 rerun-safety verified by matching sum(n)"
key_files:
  created:
    - tests/06_profile_test.sas
  modified: []
decisions:
  - "TC-03 skips (not fails) when pdd.pcnr absent — SKIP counts in SUMMARY"
  - "TC-04 calls p6_write_output directly with hand-built _p6_rows to test D-08 path"
  - "name_map fixture has T_LINK LINKAGE_ONLY even though T_LINK not in _t_ds (tests exclusion logic)"
  - "17 T_ vars expected in prf_test (T_LINK excluded from count as not in _t_ds)"
metrics:
  duration_min: 25
  tasks_completed: 2
  files_created: 1
  completed_date: "2026-10-26"
---

# Phase 6 Plan 04: Profile Test Suite Summary

Test suite `tests/06_profile_test.sas` created with TC-01..TC-12 covering the full acceptance gate for `%pdd_profile`. Synthetic fixture (50 rows, 17 T_ variables) exercises every classification boundary, date format, tie-break, reserved-level, UTF-8, and 100%-missing case. Integration block (TC-03) runs read-only on pdd.pcnr when available.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Harness + TC-01/02/05/07/08/09/10/11 | e5023e3 | tests/06_profile_test.sas (created) |
| 2 | TC-03/04/06/12 + SUMMARY line | e5023e3 (same commit) | tests/06_profile_test.sas |

## Test Coverage

| TC | Description | Type | Status |
|----|-------------|------|--------|
| TC-01 | var_class: LOW_CARD/CONT_NUM/HIGH_CARD/DATE boundaries | synthetic | PENDING SAS run |
| TC-02 | Schema: 13 columns, names, types, order, level length >= 300 | synthetic | PENDING SAS run |
| TC-03 | Integration on pdd.pcnr: 1297 vars, 56 all-missing, PROC FREQ match, independent missing counts, recon 41150 | integration | PENDING SAS run (SKIP if pdd absent) |
| TC-04 | D-08 expected-fail per class (LOW_CARD/HIGH_CARD/CONT_NUM); prf_bad not published | synthetic | PENDING SAS run |
| TC-05 | small_cell_flag Y/N/blank; boundaries 0,1,10,11 present | synthetic | PENDING SAS run |
| TC-06 | Exclusions: T_LINK/LINKAGE_ONLY absent, ZZ_OUT absent, NORM_PSID absent; missing name_map fail | synthetic | PENDING SAS run |
| TC-07 | date_kind DATE/DATETIME/TIME; display_format set; 9 STAT rows; SD present | synthetic | PENDING SAS run |
| TC-08 | 100%-missing: one MISSING row, n=50, pct=100, sort_order=99; T_ALLMD keeps DATE class | synthetic | PENDING SAS run |
| TC-09 | HIGH_CARD: N_DISTINCT+10 LEVEL+OTHER+MISSING=50; tie-break V10 rank 10 (ascending) | synthetic | PENDING SAS run |
| TC-10 | T_LONG untruncated (>200 chars); T_RSV level='OTHER'/level='MISSING' + own MISSING row; T_NA ß UTF-8 | synthetic | PENDING SAS run |
| TC-11 | T_L21 N+N_MISSING=50; MEAN/MIN/MAX match PROC MEANS (tol 1e-9) | synthetic | PENDING SAS run |
| TC-12 | Rerun after TC-04 failures: p6_fail=0, row count and sum(n) per var identical | synthetic | PENDING SAS run |

## Deviations from Plan

None — plan executed exactly as written. Both tasks committed in a single commit because Task 2 appended to the file created in Task 1 (no interim state worth a separate commit on a no-SAS machine).

## Linter Gates

| Gate | Result |
|------|--------|
| `python tools\sas_lint.py tests\06_profile_test.sas` | PASS — 0 errors, 55 warnings (W1/W2 advisory) |
| `sasjs lint` (project-wide) | PASS — warnings only, no errors; pre-existing project state |

## SAS Execution Gates (PENDING)

These gates require running SAS on the target machine (no SAS on dev machine):

1. `%include "tests/06_profile_test.sas"` on SAS with pdd available
2. Check log for `TESTRESULT: SUMMARY passed=N failed=0 skipped=0` (or `skipped=1` if pdd.pcnr absent)
3. Acceptance: `failed=0` — `skipped=0` required for full integration coverage

## Known Stubs

None. All assertions compute against real profiler output or PROC MEANS/FREQ reference counts. No hardcoded expected values except the 1297/56/41150/50 constants from Phase 5 and CONTEXT.

## Self-Check: PASSED

- `tests/06_profile_test.sas` exists: FOUND
- Commit e5023e3 exists: FOUND (git log confirms)
- `sas_lint.py` zero errors: CONFIRMED
