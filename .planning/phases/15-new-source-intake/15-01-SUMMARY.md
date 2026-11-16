---
phase: 15-new-source-intake
plan: 01
subsystem: source-intake
tags: [sas, source-guard, sha256, header-variants]
requires: []
provides:
  - docs/new_source_files.csv (s21-s23 file list for all sas/15*.sas)
  - docs/new_source_header_variants.csv (NEW-03a seed, 16 rows)
  - sas/15a_new_source_guard.sas (NEW-01 guard)
affects: [15-02, 15-03, 15-05, 16]
tech-stack:
  added: []
  patterns: [env-var approval gate (PDD_APPROVE_NEW_BASELINE), read-only baseline copy]
key-files:
  created:
    - docs/new_source_files.csv
    - docs/new_source_header_variants.csv
    - sas/15a_new_source_guard.sas
    - python/tests/test_phase15_guard_static.py
  modified:
    - .gitignore
key-decisions:
  - "New-file baseline is separate (docs/source_guard_baseline_new.csv) and seeded only with PDD_APPROVE_NEW_BASELINE=1"
requirements-completed: [NEW-01, NEW-03a]
duration: ~20 min
completed: 2026-11-16
---

# Phase 15 Plan 01: New-source guard Summary

Approval-gated SHA-256 guard for the three 2023-2025 files (s21-s23), plus the file list and a 16-row header-variant seed for the Phase 16 map review.

Status: PENDING SAS RUN (15a) / PENDING DECISION (new baseline approval)

## What was built

- `docs/new_source_files.csv`: s21/s22/s23 with probe encodings (utf-8, wlatin1, wlatin1) and probe counts.
- `docs/new_source_header_variants.csv`: 16 variants (6 Braden year-prefix, Fraility_Score/Category, SleepApnea_YN, preop_edu_years, 5 frailty components, Death_Days_After_Surgery), all PENDING DECISION, names and types only.
- `.gitignore`: four `!docs/` exceptions (two used now, two for later plans).
- `sas/15a_new_source_guard.sas`: `%p15a_old_guard` (20-file check, read only, `ne 20`), `%p15a_load_new_list`, `%p15a_hash_new`, `%p15a_new_guard` (`ne 3`). Branch A seeds on approval, B writes `qc\new_source_hashes_proposed.csv` and stops with PENDING DECISION, C compares and never overwrites. `exchange\new_source_guard.csv` is written in every branch before any fail_out (except structural count assertions in branch C after the write).
- `python/tests/test_phase15_guard_static.py`: 13 static tests.

## Verification

- `sas_lint.py`: 0 errors (13 W1/W2 warnings, same as the existing programs). `sasjs lint`: 0 errors (style warnings only).
- `pytest python\tests`: 176 passed. `ruff check python\`: clean.
- `docs/source_guard_baseline.csv`, 02, 03, 03a unchanged.
- The program was not run (no SAS, no P:).

## Deviations from Plan

**1. [Rule 1 - Bug] Test regex too broad.** `proc\s+print` matched `proc printto` (log routing). Added `\b`. Also `no errors` is printed to stderr by sas_lint; test checks stdout+stderr. Commit 0404db7 (74e48f4 was committed with one failing test before this fix).

TDD RED phase was not run separately for Task 1 (tests and fixtures written together).

## Assumptions (headless run)

- A1: s21=2023, s22=2024, s23=2025. Probe unit numbers 19/20/21 are not s-codes.
- A2: approval is the OS env var `PDD_APPROVE_NEW_BASELINE=1` (`-set PDD_APPROVE_NEW_BASELINE 1`). Gerard approves, never Claude.
- A3: existing 20-file programs (02, 03, 03a, 05) not modified.
- Probe-unit mapping: units 1-18 = s01-s18, unit 22 = s19, unit 23 = s20, units 19/20/21 = s21/s22/s23.
- Full Braden "Sensory P" headers are cut at 32 chars by the probe; full names come from 15b (PENDING SAS RUN).

## Pending

- PENDING SAS RUN: Gerard runs `sas\15a_new_source_guard.sas` standalone; bring back `logs\15a_new_source_guard.log`, `qc\new_source_hashes_proposed.csv`, `exchange\new_source_guard.csv`.
- PENDING DECISION: review the proposed hashes, rerun with `PDD_APPROVE_NEW_BASELINE=1`, commit `docs/source_guard_baseline_new.csv`.

## Known Stubs

None.

## Commits

- 9df4d48 file list, variant seed, gitignore, docs tests
- 74e48f4 15a_new_source_guard.sas and static tests
- 0404db7 test fix

## Self-Check: PASSED
