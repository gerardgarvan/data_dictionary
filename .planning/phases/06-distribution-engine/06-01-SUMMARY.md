---
phase: 06-distribution-engine
plan: "01"
subsystem: sas-profile-engine
tags: [classification, nlevels, date-tier, exclusions, macros]
dependency_graph:
  requires: [05_build_pcnr_macros.sas, pdd.name_map, DICTIONARY.COLUMNS]
  provides: [sas/06_profile_macros.sas, work._p6_vars, work._p6_excl]
  affects: [06_profile.sas (plan 02), pdd.prf_pcnr (plan 02)]
tech_stack:
  added: []
  patterns: [batched PROC FREQ NLEVELS, DATA _NULL_ FILE= generated include, p6_* namespace, failure contract]
key_files:
  created: [sas/06_profile_macros.sas]
  modified: []
decisions:
  - "name_map columns locked: PCNR_NAME (variable name) and STATUS (LINKAGE_ONLY flag)"
  - "NLEVELS batch size set to 100 variables per PROC FREQ call"
  - "Name-pattern fallback (_DATE/_DTTM) uses PROC MEANS min/max plausibility range -3653 to 36525"
  - "Character *_date/*_dttm variables logged as NOTEs and fall to LOW_CARD/HIGH_CARD"
metrics:
  duration: "~20 minutes"
  completed: "2026-10-26T17:56:49Z"
  tasks_completed: 2
  files_created: 1
---

# Phase 6 Plan 01: Section 0 Utilities + Classification Engine Summary

**One-liner:** p6_*-namespaced macro library with batched PROC FREQ NLEVELS distinct counting and DATE-first four-tier classification via exact format-set matching.

## What Was Built

`sas/06_profile_macros.sas` contains two groups of macros:

**Section 0 utilities (p6_* namespace):**
- `%_p6_init_globals` — declares and resets p6_fail, p6_fail_msg, p6_test_mode globals; called immediately after definition
- `%p6_fail_out(msg=)` — ERROR log + test-mode sets p6_fail=1 and returns; production aborts
- `%_p6_ok(section=)` — fail-fast guard checking p6_fail=1, obs=0, or syserr>4
- `%p6_assert_rowcount(ds=, expected=, label=)` — PROC SQL count(*) assertion
- `%p6_route_log` / `%p6_restore_log` — log redirect when in_pipeline=0

**Classification macros:**
- `%p6_preflight(lib=, ds=, require_name_map=1)` — verifies dataset exists, has rows, and (when required) name_map exists with PCNR_NAME + STATUS columns
- `%p6_classify_vars(lib=, ds=, prefix=, family=, require_name_map=1)` — builds work._p6_vars

## name_map Columns Locked

| Column | Role |
|--------|------|
| `pcnr_name` | Variable name to match against profiled variables for LINKAGE_ONLY exclusion |
| `status` | Value `'LINKAGE_ONLY'` triggers exclusion (D-05) |

These were confirmed from `sas/04_name_map.sas` line 123 and `sas/05_build_pcnr_macros.sas` line 123.

## Classification Logic (work._p6_vars columns)

| Column | Type | Description |
|--------|------|-------------|
| name | $200 | Variable name |
| type | $8 | 'char' or 'num' |
| length | 8 | Column length |
| format | $32 | Raw SAS format |
| n_distinct | 8 | NNonMissLevels from PROC FREQ NLEVELS |
| var_class | $12 | 'DATE' / 'LOW_CARD' / 'CONT_NUM' / 'HIGH_CARD' |
| date_kind | $12 | 'DATE' / 'DATETIME' / 'TIME' or blank |
| display_format | $32 | Strip(format) for DATE tier; 'DATE9.' for name-pattern dates; blank for non-DATE |

**Tier precedence (D-06):** DATE checked first via exact format-set match, then name-pattern fallback (_DATE/_DTTM with PROC MEANS plausibility). After DATE: n_distinct <= 20 = LOW_CARD, num >= 21 = CONT_NUM, char >= 21 = HIGH_CARD.

**Boundary:** 20 = LOW_CARD, 21 = CONT_NUM or HIGH_CARD (per plan).

## Exclusion Logic (D-05)

1. NORM_PSID always excluded (inserted directly into work._p6_excl)
2. LINKAGE_ONLY variables from `&lib..name_map` where upcase(strip(status))='LINKAGE_ONLY' and pcnr_name ne ''
3. prefix= filter via DICTIONARY.COLUMNS LIKE upcase("&prefix.%")
4. When require_name_map=0 and name_map absent: NOTE logged, only NORM_PSID excluded

## Distinct Counting

ONE batched PROC FREQ NLEVELS pass per ~100 variables. Generated file written to `&logs_path.\06_generated_nlevels_&family..sas` via DATA _NULL_ FILE= (not MOD — rerun safe). NNonMissLevels column used directly. Row count assertion verifies every meta variable has exactly one n_distinct result.

No `count(distinct ...)` PROC SQL calls anywhere in the file.

## PCM Compliance

- C1: No ?? in PROC SQL
- C2: No ANSI SQL
- C3: No open-code %if outside %macro (DATA-step logic used for classification)
- C9: No LIBNAME in this file (macro-only)
- C11: No macro keyword in quoted PUT string (fixed: %superq() in %put replaced with &msg)
- C13: All macros defined before any call; %_p6_init_globals called immediately after definition
- C14: No bare data;/set;
- C26: No literal "pdd." in any macro body — always uses &lib parameter

## Deviations from Plan

**1. [Rule 1 - Bug] C11b: %superq() in %put**
- **Found during:** Task 1 verification (sas_lint.py)
- **Issue:** `%put ERROR: [06_profile] %superq(msg);` triggers C11b — macro invocation inside %put
- **Fix:** Changed to `%put ERROR: [06_profile] &msg;` (Phase 5 pattern)
- **Files modified:** sas/06_profile_macros.sas line 53
- **Commit:** d3a4ffe (same commit, pre-commit fix)

## Commits

| Hash | Message |
|------|---------|
| d3a4ffe | feat(06-01): add Section 0 utilities + %p6_preflight + %p6_classify_vars |

## Self-Check

- [x] sas/06_profile_macros.sas exists and has 619 lines (> 200 minimum)
- [x] sas_lint.py: 0 errors, 17 warnings
- [x] sasjs lint: 0 errors, warnings only
- [x] All 15 acceptance criteria checks pass
- [x] Commit d3a4ffe verified in git log

## Self-Check: PASSED
