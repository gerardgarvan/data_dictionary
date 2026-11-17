---
phase: 16-name-map-extension
plan: 04
subsystem: name-map
tags: [sas, value-distributions, year-coverage, hash, static-tests]
requires:
  - phase: 16-name-map-extension
    provides: exchange contract (16-01); 16a datasets at run time (16-03)
provides:
  - "sas/16b_name_map_values_cov.sas: pdd.qc_map_ext_values, pdd.name_map_coverage, pdd.name_map_vars_coverage and 3 exchange CSVs"
affects: [16-05, 18]
tech-stack:
  patterns: ["generated DATA step via FILE + %include (no CALL EXECUTE)", "hash counts per (variable, year) with spine year lookup"]
key-files:
  created:
    - sas/16b_name_map_values_cov.sas
    - python/tests/test_phase16b_static.py
decisions:
  - "Coverage hash is keyed by upper-case variable name and year, not by a numeric variable index; roll-up joins back on upcase(sas_name)"
  - "Reconcile check also bounds n_nonmiss by rows times mapped columns of the variable (the year plus NO_YEAR identity alone is true by construction)"
metrics:
  completed: 2026-11-16
  tasks: 2
  files: 2
requirements: [MAP-02, MAP-04]
---

# Phase 16 Plan 04: Value distributions and year coverage Summary

`sas/16b_name_map_values_cov.sas` writes (1) per candidate pair value distributions for the new and old columns side by side (LEVEL rows for 30 or fewer distinct levels, otherwise DISTINCT, N_MISSING, N and MIN/MAX or MINLEN/MAXLEN) and (2) first and last year, years present and contributing sources per PCNR variable and per pending column (`PENDING:<name_key>`). Old sources take the year from the spine (`pdd.src_s09` YEAR by `norm_psid`, hash); new files use their own YEAR. Rows without a year are counted in NO_YEAR, never dropped.

Status: `PENDING SAS RUN (16b; Phase 15 prerequisites done)`. Gerard runs it after 16a. Bring back `logs\16b_name_map_values_cov.log` and the exchange CSVs `name_map_ext_values.csv`, `name_map_coverage.csv`, `name_map_vars_coverage.csv`.

## Tasks

| Task | Commit | Result |
|------|--------|--------|
| 1 Sections 0-3: setup, preconditions, value distributions | 28111b9 | read-only inputs, YEAR type and spine-uniqueness asserts, nliteral + PROC FREQ per column, no values logged |
| 2 Sections 4-6: coverage, rollup, exports | 9f781e8 | generated hash step per source, NULL rule, reconcile, per-variable rollup, 2 CSVs |

## Verification

- `sas_lint` 0 errors (W1/W2 warnings only, same pattern as other count asserts). `sasjs lint`: 0 errors.
- `ruff check python\`: clean. `pytest python\tests`: 257 passed, 3 failed. All 3 failures are in `test_phase16a_static.py`, which belongs to concurrent plan 16-03 (mid-write); `test_phase16b_static.py` (11 tests) passes.
- `sas/05_build_pcnr_macros.sas`, `sas/15c_new_import.sas`, `tools/check_nearmatch_values.sas` unchanged.
- The SAS was not run (no SAS here). Hash and generated-code logic is verified by reading and static tests only.

## Deviations from Plan

**1. [Design adjustment] Hash keyed by variable name, not variable index**
- The plan keyed the hash on `_vi _yr`. Positions in `_numeric_`/`_character_` arrays do not match the driving-table order, so the key is `_vn` (upper-case `vname`) plus `_yr`. This removes the second lookup step the plan allowed. Roll-up joins on `upcase(strip(sas_name))`.

**2. [Design adjustment] Flag arrays sized from the variable count**
- Temporary flag arrays use dimension (mapped variables + 5), an upper bound for both the numeric array (includes the END= variable) and the character array.

**3. [Rule 2 - Robustness] Extra reconcile bound**
- Besides years + NO_YEAR = total, `n_nonmiss` must not exceed source rows times mapped columns of that variable. Also: mapped columns must all exist in the dataset, 23 source codes expected, vars coverage must match `pdd.name_map_vars_ext` one-to-one.

## Assumptions (headless run)

- A3 (old-source year from spine by `norm_psid`; new files own YEAR; no year goes to NO_YEAR), A4 (Phase 5 non-missing plus NULL for char columns of type-conflict variables; placeholders count as data), A12 (16b writes `pdd.name_map_coverage` and `pdd.name_map_vars_coverage`), A14 (pending keys `PENDING:<name_key>`, blank `pcnr_name`), A15 (old side = every frozen PCNR row carrying the old `pcnr_name`) apply as in 16-01.
- YEAR type assertion: YEAR must be numeric in `pdd.src_s09` and `pdd.nsrc_s21..s23`, else `%fail_out` (no silent parse). Spine `norm_psid` must be unique and non-blank (PDD-D-17).
- Column types and names of 16a outputs follow the 16-01 contract (`candidates.s_code_new` char, `col_order_new` numeric, `type_conflict` char Y/N, `pdd.name_map_vars_ext` holds PCNR variables only). The program asserts column presence at start; type mismatches would surface at run time.
- `side` values are `NEW` and `OLD` (matches `name_map_ext_workbook.py`). `n` is blank for MIN/MAX/MINLEN/MAXLEN rows (value in `level`).
- Source dataset names: `pdd.nsrc_<s>` for s21-s23, `pdd.src_<s>` otherwise; `s_code` values are compared case-insensitively.

## Known Stubs

None.

## Gates

- Phase 16 SAS runs: PENDING SAS RUN (16a then 16b, Gerard).
- Near-match naming: PENDING DECISION (Gerard) after 16a; Price naming sign-off PENDING.

## Self-Check: PASSED

Files and commits 28111b9, 9f781e8 verified present.
