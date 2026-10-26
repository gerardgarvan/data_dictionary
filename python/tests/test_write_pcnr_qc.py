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
)

# _scripts: path to write_pcnr_qc.py (used by D-23 tests below)
_scripts = Path(__file__).resolve().parent.parent / "scripts"

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
    "TYPECHECK": ["pcnr_name", "resolved_type", "out_length", "n_char_sources", "n_failures", "n_null_as_missing"],
    "TYPEFAIL": ["pcnr_name", "s_code", "raw_value", "n"],
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


# ---------------------------------------------------------------------------
# D-23: _extract_pcnr_name and UnicodeDecodeError reporting
# ---------------------------------------------------------------------------


def _import_extract() -> object:
    """Import _extract_pcnr_name from write_pcnr_qc without executing main."""
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "write_pcnr_qc",
        _scripts / "write_pcnr_qc.py",
    )
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    # Patch argv so argparse in module-level code does not fire
    old_argv = sys.argv
    sys.argv = ["write_pcnr_qc.py", "--help"]
    try:
        spec.loader.exec_module(mod)  # type: ignore[union-attr]
    except SystemExit:
        pass
    finally:
        sys.argv = old_argv
    return mod._extract_pcnr_name  # type: ignore[attr-defined]


def test_extract_pcnr_name_returns_field1(tmp_path: Path) -> None:
    """_extract_pcnr_name reads field 1 (0-indexed) from the line at byte_offset."""
    extract = _import_extract()
    # Row with Windows-1252 byte 0xDF at a known position after two comma fields
    # norm_psid,pcnr_name,value -- bad byte in value (field 2), pcnr_name is field 1
    good_rows = b"norm_psid,pcnr_name,value\n" + b"P001,PCNR_Base_Procedure_1," + b"\xdf\n"
    p = tmp_path / "test.csv"
    p.write_bytes(good_rows)
    # byte_offset of 0xDF
    offset = good_rows.index(b"\xdf")
    result = extract(p, offset)
    assert result == "PCNR_Base_Procedure_1", f"Got: {result!r}"


def test_extract_pcnr_name_unknown_on_bad_path(tmp_path: Path) -> None:
    """_extract_pcnr_name returns 'unknown' when file cannot be read."""
    extract = _import_extract()
    result = extract(tmp_path / "nonexistent.csv", 0)
    assert result == "unknown"


def test_extract_pcnr_name_single_field(tmp_path: Path) -> None:
    """_extract_pcnr_name returns 'unknown' when line has fewer than 2 fields."""
    extract = _import_extract()
    p = tmp_path / "single.csv"
    p.write_bytes(b"onlyone\xdf\n")
    result = extract(p, 7)
    assert result == "unknown"


# ---------------------------------------------------------------------------
# New tests: TYPEFAIL sheet, TYPECHECK new cols, schema-vs-required
# ---------------------------------------------------------------------------


def test_typefail_sheet_present_when_data_provided(tmp_path: Path) -> None:
    """TYPEFAIL sheet is written when data rows are provided."""
    out = tmp_path / "typefail.xlsx"
    sheets = dict(_minimal_sheets())
    # Provide a data row for TYPEFAIL
    sheets["TYPEFAIL"] = (
        REQUIRED["TYPEFAIL"],
        [["PCNR_AGE", "s01", "abc", "3"]],
    )
    write_workbook(sheets, out)

    wb = load_workbook(out, read_only=True)
    assert "TYPEFAIL" in wb.sheetnames
    ws = wb["TYPEFAIL"]
    # Header row + 1 data row
    assert ws.max_row == 2, f"Expected 2 rows (header+data), got {ws.max_row}"
    wb.close()


def test_typecheck_new_required_columns(tmp_path: Path) -> None:
    """TYPECHECK required columns include resolved_type, out_length, n_char_sources,
    n_failures, n_null_as_missing."""
    out = tmp_path / "typecheck_cols.xlsx"
    sheets = dict(_minimal_sheets())
    typecheck_row = ["PCNR_AGE", "N8", "8", "2", "0", "1"]
    sheets["TYPECHECK"] = (REQUIRED["TYPECHECK"], [typecheck_row])
    # Should not raise
    write_workbook(sheets, out)

    wb = load_workbook(out, read_only=True)
    ws = wb["TYPECHECK"]
    header = [cell.value for cell in next(ws.iter_rows(min_row=1, max_row=1))]
    for col in ["resolved_type", "out_length", "n_char_sources", "n_failures", "n_null_as_missing"]:
        assert col in header, f"Column '{col}' missing from TYPECHECK header"
    wb.close()


def test_exchange_schema_matches_required(tmp_path: Path) -> None:
    """exchange_schema.csv columns match REQUIRED_COLUMNS in pcnr_qc_workbook."""
    import csv as csv_mod

    from pdd.pcnr_qc_workbook import REQUIRED_COLUMNS

    schema_path = Path(__file__).resolve().parent.parent.parent / "docs" / "exchange_schema.csv"
    if not schema_path.exists():
        pytest.skip("docs/exchange_schema.csv not present")

    file_to_sheet = {
        "pcnr_typecheck.csv": "TYPECHECK",
        "pcnr_typefail.csv": "TYPEFAIL",
        "pcnr_gapfill.csv": "GAPFILL",
        "pcnr_conflicts_summary.csv": "CONFLICT_SUMMARY",
        "pcnr_conflicts_detail.csv": "CONFLICT_DETAIL",
        "pcnr_spine_coverage.csv": "SPINE_COVERAGE",
    }

    # Build {file: [columns]} from schema
    schema_cols: dict[str, list[str]] = {}
    with schema_path.open(encoding="utf-8", newline="") as fh:
        reader = csv_mod.DictReader(fh)
        for row in reader:
            f = row["file"].strip()
            c = row["column"].strip()
            schema_cols.setdefault(f, []).append(c)

    for fname, sheet in file_to_sheet.items():
        if sheet not in REQUIRED_COLUMNS:
            continue
        if fname not in schema_cols:
            pytest.fail(f"File '{fname}' not found in exchange_schema.csv")
        schema = schema_cols[fname]
        required = REQUIRED_COLUMNS[sheet]
        assert schema == required, (
            f"{fname} schema columns {schema} != REQUIRED_COLUMNS[{sheet!r}] {required}"
        )
