"""Tests for pcnr_qc_workbook and write_pcnr_qc script."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from openpyxl import load_workbook

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.pcnr_qc_workbook import (
    CONFLICT_DETAIL_CAP,
    SHEET_ORDER,
    assert_input,
    write_workbook,
    verify_workbook,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

REQUIRED = {
    "GAPFILL": ["pcnr_name", "n_spine", "n_gapfilled", "n_missing"],
    "SPINE_COVERAGE": ["s_code", "n_keys", "n_keys_not_in_spine", "n_blank_keys", "n_dup_keys"],
    "CONFLICT_SUMMARY": ["pcnr_name", "conflict_type", "n_conflict_events", "n_conflict_cells"],
    "CONFLICT_DETAIL": [
        "norm_psid", "pcnr_name", "conflict_type", "winning_s_code", "winning_value",
        "candidate_s_code", "candidate_value", "value_type",
    ],
    "TYPECHECK": ["pcnr_name", "s_code", "raw_value", "n"],
}


def _minimal_sheets() -> dict[str, tuple[list[str], list[list]]]:
    """All 5 non-KEY sheets with required columns and 0 data rows."""
    return {name: (cols, []) for name, cols in REQUIRED.items()}


# ---------------------------------------------------------------------------
# Test 1: KEY is first sheet; SHEET_ORDER enforced
# ---------------------------------------------------------------------------

def test_key_is_first_sheet(tmp_path: Path) -> None:
    out = tmp_path / "pcnr_qc.xlsx"
    write_workbook(_minimal_sheets(), out)

    wb = load_workbook(out, read_only=True)
    assert wb.sheetnames[0] == "KEY"
    assert wb.sheetnames == SHEET_ORDER
    wb.close()


# ---------------------------------------------------------------------------
# Test 2: CONFLICT_DETAIL >5000 rows raises ValueError (not silent truncation)
# ---------------------------------------------------------------------------

def test_conflict_detail_over_cap_raises() -> None:
    headers = REQUIRED["CONFLICT_DETAIL"]
    rows = [["pid"] * len(headers)] * (CONFLICT_DETAIL_CAP + 1)
    with pytest.raises(ValueError, match="5001"):
        assert_input("CONFLICT_DETAIL", headers, rows)


# ---------------------------------------------------------------------------
# Test 3: All sheets present with headers even when 0 data rows
# ---------------------------------------------------------------------------

def test_all_sheets_present_when_empty(tmp_path: Path) -> None:
    out = tmp_path / "empty.xlsx"
    write_workbook(_minimal_sheets(), out)

    wb = load_workbook(out, read_only=True)
    assert set(wb.sheetnames) == set(SHEET_ORDER)
    # Every sheet must have at least 1 row (header)
    for name in SHEET_ORDER:
        ws = wb[name]
        assert ws.max_row >= 1, f"Sheet {name} has no rows"
    wb.close()


# ---------------------------------------------------------------------------
# Test 4: Missing required column raises ValueError naming the missing column
# ---------------------------------------------------------------------------

def test_missing_required_column_raises() -> None:
    # Drop one required column from CONFLICT_DETAIL
    full = list(REQUIRED["CONFLICT_DETAIL"])
    missing_col = full.pop(2)  # remove 'conflict_type'
    with pytest.raises(ValueError, match=missing_col):
        assert_input("CONFLICT_DETAIL", full, [])


# ---------------------------------------------------------------------------
# Test 5: n_filled_* columns treated as integers (optional per plan)
# ---------------------------------------------------------------------------

def test_n_filled_treated_as_int(tmp_path: Path) -> None:
    out = tmp_path / "filled_int.xlsx"
    # GAPFILL with an extra n_filled_s01 column
    headers = REQUIRED["GAPFILL"] + ["n_filled_s01"]
    data = [["PCNR_Age", "100", "5", "2", "5"]]
    sheets = {
        "GAPFILL": (headers, data),
        **{name: (cols, []) for name, cols in REQUIRED.items() if name != "GAPFILL"},
    }
    write_workbook(sheets, out)

    wb = load_workbook(out, read_only=True)
    ws = wb["GAPFILL"]
    rows = list(ws.iter_rows(min_row=2, values_only=True))
    assert rows, "No data rows in GAPFILL"
    n_filled_idx = headers.index("n_filled_s01")
    val = rows[0][n_filled_idx]
    assert isinstance(val, int), f"Expected int, got {type(val).__name__}: {val!r}"
    wb.close()
