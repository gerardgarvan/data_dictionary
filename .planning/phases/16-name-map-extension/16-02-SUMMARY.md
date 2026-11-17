---
phase: 16-name-map-extension
plan: 02
subsystem: sas-naming
tags: [sas, name-map, macros, static-tests]
requires: []
provides:
  - "sas/16_name_map_ext_macros.sas: p16_clean_name, p16_load_abbrev, p16_shorten, p16_assign_names, p16_stage2"
  - "sas/16_name_map_ext_test.sas: synthetic tests T1-T8"
affects: [16-03, 16-04, 16-05]
tech-stack:
  patterns: ["hash seeded with all existing names for extend-only suffixing", "no open code in macro files"]
key-files:
  created:
    - sas/16_name_map_ext_macros.sas
    - sas/16_name_map_ext_test.sas
    - python/tests/test_phase16_macros_static.py
decisions:
  - "p16_stage2 gets an optional quiet=1 parameter (NOTE instead of ERROR) so the synthetic negative test does not put ERROR lines in the log"
  - "suffix_n is set inside the search loop, not read from the DO index after exit"
metrics:
  completed: 2026-11-16
  tasks: 2
  files: 3
requirements: [MAP-01, MAP-03]
---

# Phase 16 Plan 02: Naming macros Summary

Side-effect-free copies of the Phase 4 naming rules (clean, always/as_needed abbreviation, elide to 27, PCNR_ prefix) plus an extend-only suffix macro that seeds a hash with every existing final name, so existing names are never changed.

Status: `PENDING SAS RUN (16_name_map_ext_test.sas)`. Gerard runs it with synthetic data only (no P: access needed) and brings back the log; look for `TESTRESULT SUMMARY: ALL TESTS PASSED`.

## Commits

- 7777016: macros file and static pytest
- 9a74183: synthetic SAS test program

## Verification here

- `sas_lint` 0 errors on both SAS files (W1/W2 warnings only, same pattern as other count asserts).
- `sasjs lint`: style warnings only (indentation, line length, Doxygen header); no errors on the new files.
- `ruff check python\` clean. `pytest python\tests`: 226 pass (run with `--ignore=python/tests/test_name_map_ext_workbook.py`, which belongs to concurrent plan 16-01 and was mid-write: its module `write_name_map_ext_review` did not exist yet).
- `sas/04_name_map.sas` and `sas/04_name_map_macros.sas` unchanged.
- The SAS macros were not executed (no SAS here). Correctness of hash and DO logic is checked only by reading until the SAS run.

## Deviations from Plan

**1. [Rule 2 - Robustness] `quiet` parameter on `%p16_stage2`**
- Intended failures in T7 would otherwise write ERROR lines that log checkers treat as failures. Default `quiet=0` keeps the plan behavior.

**2. [Rule 1 - Bug avoided] suffix_n from loop**
- The DO index value after an UNTIL exit is uncertain, so `suffix_n` is assigned when the free name is found.

**3. Lint summary location**
- `sas_lint.py` prints its summary on stderr; the static test reads stdout and stderr.

## Assumptions (headless run)

- A1-A16 from 16-01 apply. The abbreviation validation in `%p16_load_abbrev` counts bad rows in a single query (blank short, long equals short, non-word chars, long not starting with a letter, invalid mode); blank `long` rows are dropped on read as in Phase 4.
- `%p16_shorten` and `%p16_assign_names` rely on callers declaring the helper variables documented in the macro comments; the test program shows the pattern.
- The T2 expectation (name length 27 or less and contains `Perc`) assumes the synthetic always row applies to `Perception` at a token boundary.

## Known Stubs

None.

## Self-Check: PASSED

Files and both commits verified present.
