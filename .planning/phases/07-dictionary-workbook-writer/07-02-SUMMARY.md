---
phase: 07-dictionary-workbook-writer
plan: "02"
subsystem: python
tags: [workbook, suppression, age-topcode, openpyxl, pandas, tdd]
dependency_graph:
  requires: [06-distribution-engine]
  provides: [python/pdd/dictionary_workbook.py, python/tests/test_dictionary_workbook.py]
  affects: [07-03-write_dictionary-script]
tech_stack:
  added: []
  patterns: [pandas DataFrame transforms, openpyxl internal hyperlinks via Hyperlink(ref=,location=), locked transform order]
key_files:
  created:
    - python/pdd/dictionary_workbook.py
    - python/tests/test_dictionary_workbook.py
  modified: []
decisions:
  - "Complementary suppression tie-break: suppress ALL tied candidates (conservative); documented in KEY sheet"
  - "No-leak guard runs inside apply_suppression before dropping tracking columns; raises RuntimeError on any integer 1-10 in suppressed rows"
  - "age_variables.csv hard-fail on missing file or zero data rows (never silently use empty set)"
  - "Stat-class suppression: N/N_MISSING/N_UNPARSED checked directly for 1<=n<=10 (small_cell_flag blank for these rows in Phase 6 output)"
metrics:
  duration: "~25 min"
  completed: "2026-10-27"
  tasks: 2
  files: 2
---

# Phase 07 Plan 02: Dictionary Workbook Core Module Summary

Implemented `python/pdd/dictionary_workbook.py` (core workbook logic) and `python/tests/test_dictionary_workbook.py` (39-test pytest suite). Module reads three exchange CSVs, applies display transforms in locked order, and writes a 12-sheet xlsx workbook with full suppression and age top-coding logic.

## What Was Built

### python/pdd/dictionary_workbook.py

Locked transform order:
1. Load profile_PCNR.csv
2. `apply_age_topcode` — LEVEL rows >89 merged to '90+' (sum n, recompute pct, recompute small_cell_flag); STAT rows MIN/MAX/MEDIAN/Q1/Q3 value>89 set to '90+'; MEAN/SD unchanged; reads age_variables.csv with hard-fail on missing/empty
3. `apply_numtext_mask` — NUM_TEXT LEVEL rows with n<=10 get level='other text entry' (called inside apply_suppression, before primary pass)
4. `apply_suppression` — LEVEL-class primary+complementary, then stat-class (N/N_MISSING/N_UNPARSED); no-leak guard at end raises RuntimeError if any suppressed row still holds integer 1-10
5. Build dist_row map from final df
6. Build all 12 sheets

Suppression semantics:
- `'<11'` = PRIMARY suppressed only (1<=n<=10)
- `'suppressed'` = COMPLEMENTARY suppressed only
- When N itself is primary-suppressed: blank all stat value cells (MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX/RANGE_MIN/RANGE_MAX); VARIABLES summary = "fewer than 11 values"; n_nonmiss='<11'
- When N is complementary-suppressed: n_nonmiss='suppressed'; stats unchanged
- MISSING row suppressed: VARIABLES n_nonmiss='<11 missing'

Internal hyperlinks: `Hyperlink(ref=cell.coordinate, location='DISTRIBUTIONS!AX')` — no '#DISTRIBUTIONS' string shortcut.

`write_workbook` returns `dict[str, int]` with keys VARIABLES, DISTRIBUTIONS, NAME_MAP.

### python/tests/test_dictionary_workbook.py

39 test functions using 13-column fixture schema. Coverage:
- Age file hard fail (FileNotFoundError includes path)
- Transform order (topcode before suppression; merged n=15 not suppressed)
- Suppress/raw/asterisk modes
- Complementary suppression (fires, no-fire on 2 primary, all-ties suppressed)
- NUM_TEXT level masking
- Age topcode (LEVEL aggregation, STAT value, MEAN unchanged, non-age var unchanged)
- VARIABLES n_nonmiss per var_class; n_distinct; all_missing flag; MISSING row leak
- Stat-class suppression (N_MISSING primary, N_UNPARSED primary, N itself primary, complementary)
- Summary text (LOW_CARD %, all_missing, cont_num mean prefix, SUPPRESSED range/length)
- Workbook structure (sheet order, internal hyperlink, NAME_MAP columns, SOURCES no-notes, dist row count, placeholder A1 text)
- No-leak scan across VARIABLES and DISTRIBUTIONS sheets

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Asterisk mode test selected by level text after asterisk appended**
- Found during: Task 1 test / Task 2 red-green cycle
- Issue: Test looked for `level == "Yes"` after asterisk mode set it to `"Yes*"` — IndexError
- Fix: Changed test to select by stat column, then assert endswith('*')
- Files modified: python/tests/test_dictionary_workbook.py
- Commit: 7c77aed

**2. [Rule 1 - Bug] Minimal fixture age_variables.csv had zero data rows, triggering hard-fail**
- Found during: Task 2 green pass
- Issue: Two test fixtures wrote header-only age_variables.csv; apply_age_topcode correctly rejected it
- Fix: Added a placeholder data row `PCNR_PLACEHOLDER,test` to both fixtures
- Files modified: python/tests/test_dictionary_workbook.py
- Commit: 7c77aed

**3. [Rule 1 - Bug] No-leak scan flagged SOURCES sheet col_count=5 as suppressed leak**
- Found during: Task 2 green pass
- Issue: Forbidden set {7, 5, 3} scanned all sheets; source_inventory col_count=5 is not a profile count
- Fix: Limited integer leak check to VARIABLES and DISTRIBUTIONS sheets only; forbidden_text check still spans all sheets
- Files modified: python/tests/test_dictionary_workbook.py
- Commit: 7c77aed

## Self-Check: PASSED

- python/pdd/dictionary_workbook.py: FOUND
- python/tests/test_dictionary_workbook.py: FOUND
- Commit 2ad0236 (test): FOUND
- Commit 7c77aed (feat): FOUND
