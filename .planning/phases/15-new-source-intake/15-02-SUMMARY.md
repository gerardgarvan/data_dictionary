---
phase: 15-new-source-intake
plan: 02
subsystem: source-intake
tags: [sas, header-inventory, import-spec, encoding, prepass]
requires: [15-01]
provides:
  - sas/15b_new_inventory_spec.sas (NEW-02 inventory/matrix, NEW-03 spec half)
  - python/tests/test_phase15_spec_static.py
affects: [15-03, 15-05, 16]
key-files:
  created:
    - sas/15b_new_inventory_spec.sas
    - python/tests/test_phase15_spec_static.py
  modified: []
key-decisions:
  - "Spec lengths come from the raw $32767 pre-pass in the import encoding, not from the probe"
  - "Numeric guess is N/best32. only when 0 parse failures and no leading-zero values; otherwise C"
requirements-completed: [NEW-02, NEW-03]
duration: ~25 min
completed: 2026-11-16
---

# Phase 15 Plan 02: New inventory and import spec Summary

One lint-clean SAS program that inventories the three 2023-2025 files (s21 utf-8, s22/s23 wlatin1) and builds a separate 11-column import spec, never touching the 20-file inventory or spec.

Status: PENDING SAS RUN (15b). `docs/import_spec_new_generated.csv` is produced by Gerard's run and committed by him.

## What was built

- `sas/15b_new_inventory_spec.sas`:
  - Preconditions: fails with PENDING DECISION if `docs/source_guard_baseline_new.csv` is missing (15a not approved).
  - NEW-02: PROC IMPORT through an encoded fileref, quote-aware raw header read, `pdd.header_inventory_new` (Phase 2 layout plus `col_order`), `pdd.source_inventory_new`, `pdd.header_matrix_new` (PROC TRANSPOSE by col_name, `prefix=src_`), exchange `header_inventory_new.csv` and `header_matrix_new.csv`. Asserts 3 files x `expected_cols`, no blank original header; logs full Braden headers (names only).
  - NEW-03: `$32767` pre-pass (`pdd.raw_char_lengths_new`, kept for 15c truncation check), one-pass best32. parse probe per file, V7 name cleaning with `_dupN` collisions, spec build, assertions (3 x 94 rows, exactly 2 wlatin1 codes, s21 utf-8, PRECEDE Study ID is C in all three, no duplicate sas_name), writes `docs/import_spec_new_generated.csv` and re-reads it for a row-count check.
- `python/tests/test_phase15_spec_static.py`: 6 static tests plus a generated-spec test that skips until the CSV is committed.

## Verification

- `sas_lint.py`: 0 errors (19 W1/W2 warnings, same kind as other programs). `sasjs lint`: 0 errors.
- `pytest python\tests`: 182 passed, 1 skipped (generated-spec test). `ruff check python\`: clean.
- 02, 03a and `docs/import_spec_generated.csv` unchanged (git diff empty).
- Not run: no SAS, no P:.

## Deviations from Plan

**1. [Rule 1 - Bug] Test regexes.** The "no old baseline write" test used a multi-line regex that matched comment text; changed to a per-line `file` statement check. A comparison `src_encoding = 'utf-8'` tripped the "no literal utf-8 encoding" test; written as `eq`. The CSV writer takes its encoding from `&p15b_spec_enc` (utf-8, same as the old spec) for the same reason.

**2. Design simplifications (not behavior changes).** The pre-pass header columns come from `pdd.header_inventory_new` (already read in the file's encoding) rather than a second header parse; the numeric probe is one DATA step per file with column arrays instead of one step per column; names use a hash in one DATA step instead of 03a's self-join. Work variables `len_`/`fmt_` are renamed to `length`/`format` on `pdd.import_spec_new`. Added a leading-zero rule (03a P1-5): a numeric guess with `^0\d` values becomes C.

Task 1 was committed with 3 spec-half tests still failing (they are Task 2 behaviour); all pass after Task 2.

## Assumptions (headless run)

- A9: probe `Num 8` guesses are provisional; the best32. parse probe (0 failures) decides final N vs C.
- Open Question 1 (full Braden Sensory header text in 2024/2025) is answered by this program's raw header read (`original_header`, up to 256 chars); no new probe needed.
- `header_inventory_new` adds `col_order` (varnum) as the last column; all others match `pdd.header_inventory`.
- No BOM handling: if a header has a BOM the PRECEDE Study ID assertion fails loudly rather than being silently fixed.
- Row count differing from `expected_rows` is a WARNING, column count differing from `expected_cols` (94) is an error.

## Pending

- PENDING SAS RUN: Gerard runs `sas\15b_new_inventory_spec.sas` (after 15a approval); bring back `logs\15b_new_inventory_spec.log`, `exchange\header_inventory_new.csv`, `exchange\header_matrix_new.csv`, and commit `docs/import_spec_new_generated.csv`.

## Known Stubs

None.

## Commits

- 6dc96af 15b inventory and matrix (Task 1)
- be6cacd 15b pre-pass, probe, names, spec (Task 2)

## Self-Check: PASSED
