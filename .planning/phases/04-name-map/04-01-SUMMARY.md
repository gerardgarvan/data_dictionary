# Phase 04-01 Summary — Name Map Seed Files and Workbook Module

**Completed:** 2026-10-21

## What was built

### Seed CSVs (docs/)
- `docs/name_abbrev.csv` — 7 abbreviation rows (Delayed→Dly, Recall→Rcl, Recognition→Recog, Number→N, Norm_ZScore→Z, AgeScaled→AgeSc, Percent→Pct)
- `docs/name_map_decisions.csv` — header-only decision file (s_code_a, header_a, col_order_a, s_code_b, header_b, col_order_b, decision, note, decided_by, date)
- `.gitignore` updated with `!docs/name_abbrev.csv` and `!docs/name_map_decisions.csv` exceptions; both confirmed committable (`git check-ignore` returns empty)

### Python module (python/pdd/name_map_workbook.py)
- `EXPECTED_ROWS = 4795`
- `SHEET_ORDER = ["KEY","NAME_MAP","VARIABLES","NAME_MAP_COLLISIONS","NEAR_MATCHES","ABBREVIATIONS"]`
- `read_csv(path)` — stdlib csv.DictReader
- `assert_input(name_map_rows, expected_rows)` — checks row count; checks non-blank pcnr_name maps to exactly one group_id (cross-file overlaps with same group_id allowed; blanks unrestricted)
- `write_workbook(sheets, out_path)` — KEY sheet = hard-coded D-02 cleaning rule text; remaining sheets from caller-supplied dict; all sheets styled via `style_sheet`; created in SHEET_ORDER
- `verify_workbook(path, expected_data_rows)` — asserts sheet order equals SHEET_ORDER; asserts per-sheet data-row counts

### Tests (python/tests/test_name_map_workbook.py)
5 tests, all pass:
1. `test_sheet_order` — constant value check
2. `test_assert_input_row_count` — 4795 passes, 4794 raises ValueError
3. `test_no_dup_pcnr_names` — cross-group conflict raises; same-group overlap passes; blank repeats pass
4. `test_verify_workbook` — matching counts pass; mismatch raises ValueError
5. `test_write_workbook_sheets` — written xlsx has exactly 6 sheets in SHEET_ORDER

## Verification

```
cd python && python -m pytest tests/test_name_map_workbook.py -q
# 5 passed in 1.07s

ruff check pdd/name_map_workbook.py tests/test_name_map_workbook.py
# All checks passed!
```
