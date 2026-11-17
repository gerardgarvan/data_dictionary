---
phase: 16-name-map-extension
plan: 03
subsystem: name-map
tags: [sas, name-map, exact-reuse, near-match-gate, naming, static-tests]
requires:
  - phase: 16-01
    provides: exchange contract, header-only docs/name_map_decisions_new.csv
  - phase: 16-02
    provides: sas/16_name_map_ext_macros.sas
provides:
  - "sas/16a_name_map_ext.sas: pdd.name_map_ext (5,077 rows), pdd.name_map_vars_ext, pdd.qc_map_ext_candidates, pdd.qc_map_ext_collisions, pdd.qc_map_ext_summary and five exchange CSVs"
affects: [16-04, 16-05, 18]
key-files:
  created:
    - sas/16a_name_map_ext.sas
    - python/tests/test_phase16a_static.py
key-decisions:
  - "A decision applies to every row of a cleaned header (group level); conflicting outcomes in one group fail"
  - "RENAME groups are named first so a forced name is never suffixed"
requirements: [MAP-01, MAP-02, MAP-03]
completed: 2026-11-16
---

# Phase 16 Plan 03: 16a name map extension Summary

One lint-clean SAS program extends the frozen Phase 4 map to the 282 new s21-s23 rows: exact cleaned-header matches reuse the stored name by lookup, near-matches (complev <= 2, _N/_dup suffix, variants file) wait for Gerard with a blank name, and only genuinely new columns are named under A1-A4 with extend-only suffixing.

Status: `PENDING SAS RUN (16a, Gerard)`. Gate: `PENDING DECISION (near-match candidates)`. Price naming sign-off remains PENDING.

## What was built

- Sections: frozen asserts (4795 rows, 4795 keys, 1297 names, 1297 vars; frozen copy kept for compare), spec load (282 = 3 x 94), status (KEY 3, LINKAGE_ONLY 6, CLOCK clash and same-file duplicate guards), exact lookup, candidate union with pair_id, decisions, naming, final datasets, exports, gate NOTE.
- Frozen safety: pdd.name_map and pdd.name_map_vars are only ever read. `n_frozen_names_changed` must be 0 (fail_out otherwise); FROZEN variables in name_map_vars_ext must equal pdd.name_map_vars.
- Exports are written before the PENDING DECISION NOTE; the gate is a NOTE not a stop (A11).
- Tests: 13 static tests in `python/tests/test_phase16a_static.py`.

## Verification

- `sas_lint` 0 errors (W1/W2 warnings only, same pattern as other count asserts); `sasjs lint` 0 errors.
- `ruff check python\` clean; `pytest python\tests`: 260 passed.
- Phase 4 programs and docs inputs unchanged.
- The program was NOT executed (no SAS here). Hash, SQL and DATA step logic is checked only by reading until Gerard's run.

## Deviations from Plan

**1. Tasks 1 and 2 committed together (351481f).** The program was written as one file and verified once; tests cover both task scopes. No functional effect.

**2. [Rule 1 - test fix] Static test regexes** matched `proc printto` and `infile`; narrowed to `proc print(?!to)` and `(?<![a-z])file`. The macro-order test accepts calls with arguments.

## Assumptions (headless run)

- A1, A2, A5, A6, A7, A8, A11, A13 from 16-01 apply (read-only frozen map, separate decisions file, undecided = blank name and PENDING_DECISION, exact reuse even on type change, KEY/LINKAGE rules, 16a does not stop on pending).
- Sanity stop: more than 200 candidate pairs -> fail_out (not a gate).
- Decision matching: side a by cleaned lowercase `header_a` within `s_code_a` files (blank = s21-s23), `col_order_a` narrows. Applied to the whole cleaned-header group; conflicting outcomes in one group fail. A decision whose side a is already settled by an exact match fails (not silently ignored). Side b resolves to exactly one frozen PCNR name.
- RENAME `new_name` may be given with or without the `PCNR_` prefix; the prefix is stripped before the 27-char, v7 and uniqueness checks.
- RENAME groups are named before the others, so they are never suffixed.
- NONPCNR_EXACT candidate rows carry blank `s_codes_old` and `header_old` (only a NOTE-level fact).
- `n_candidates` excludes TYPE_CONFLICT_EXACT info rows; they are counted in `n_type_conflict_exact`.
- Proposed names for undecided groups come from a second `%p16_assign_names` run whose used set includes the names assigned in the first; they appear only in `proposed_name_if_different`.

## Known Stubs

None.

## Gates

- PENDING SAS RUN: `sas\16a_name_map_ext.sas` (Gerard). Bring back `logs\16a_name_map_ext.log` and the five `exchange\name_map_ext_*.csv` / `name_map_vars_ext.csv`.
- PENDING DECISION: every near-match candidate (Gerard fills `docs/name_map_decisions_new.csv`, then reruns 16a).
- Price naming sign-off: PENDING.

## Self-Check: PASSED

sas/16a_name_map_ext.sas and python/tests/test_phase16a_static.py exist; commit 351481f present.
