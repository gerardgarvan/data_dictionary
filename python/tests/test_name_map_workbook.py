"""Tests for name_map_workbook logic."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path

import pytest

from pdd.name_map_workbook import (
    DECISIONS_TEMPLATE_COLS,
    SHEET_ORDER,
    assert_input,
    make_decisions_template,
    read_csv,
    verify_workbook,
    write_workbook,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_rows(n: int, pcnr_name: str = "", group_id: str = "g1") -> list[dict[str, str]]:
    """Return n identical synthetic name_map rows."""
    return [
        {"pcnr_name": pcnr_name, "group_id": group_id, "s_code": "s01", "col_order": str(i)}
        for i in range(n)
    ]


def _small_sheets() -> dict[str, tuple[list[str], list[list]]]:
    """Minimal sheets dict with 2 data rows per sheet."""
    data = [["val_a", "1"], ["val_b", "2"]]
    return {
        "NAME_MAP": (["col_a", "col_b"], data),
        "VARIABLES": (["col_a", "col_b"], data),
        "NAME_MAP_COLLISIONS": (["col_a", "col_b"], data),
        "NEAR_MATCHES": (["col_a", "col_b"], data),
        "ABBREVIATIONS": (["col_a", "col_b"], data),
    }


# ---------------------------------------------------------------------------
# Test 1: SHEET_ORDER constant
# ---------------------------------------------------------------------------

def test_sheet_order() -> None:
    assert SHEET_ORDER == [
        "KEY",
        "NAME_MAP",
        "VARIABLES",
        "NAME_MAP_COLLISIONS",
        "NEAR_MATCHES",
        "ABBREVIATIONS",
    ]


# ---------------------------------------------------------------------------
# Test 2: assert_input row count
# ---------------------------------------------------------------------------

def test_assert_input_row_count() -> None:
    headers = ["pcnr_name", "group_id", "s_code", "col_order"]
    rows_ok = _make_rows(4795)
    assert_input(headers, rows_ok)  # must not raise

    rows_short = _make_rows(4794)
    with pytest.raises(ValueError, match="row count"):
        assert_input(headers, rows_short)


# ---------------------------------------------------------------------------
# Test 3: pcnr_name uniqueness within group_id
# ---------------------------------------------------------------------------

def test_no_dup_pcnr_names() -> None:
    headers = ["pcnr_name", "group_id", "s_code", "col_order"]

    # Two rows: same pcnr_name, different group_id -> ValueError
    bad_rows = (
        [{"pcnr_name": "PCNR_Age", "group_id": "g1", "s_code": "s01", "col_order": "1"}]
        + [{"pcnr_name": "PCNR_Age", "group_id": "g2", "s_code": "s02", "col_order": "1"}]
        + _make_rows(4793, pcnr_name="", group_id="")
    )
    with pytest.raises(ValueError, match="pcnr_name"):
        assert_input(headers, bad_rows)

    # Same pcnr_name, same group_id -> allowed (cross-file overlap)
    same_group_rows = (
        [{"pcnr_name": "PCNR_Age", "group_id": "g1", "s_code": "s01", "col_order": "1"}]
        + [{"pcnr_name": "PCNR_Age", "group_id": "g1", "s_code": "s02", "col_order": "1"}]
        + _make_rows(4793, pcnr_name="", group_id="")
    )
    assert_input(headers, same_group_rows)  # must not raise

    # Blank pcnr_name repeated freely -> allowed
    blank_rows = _make_rows(4795, pcnr_name="", group_id="")
    assert_input(headers, blank_rows)  # must not raise


# ---------------------------------------------------------------------------
# Test 4: assert_input fails when required columns missing from headers
# ---------------------------------------------------------------------------

def test_assert_input_missing_columns() -> None:
    # Missing pcnr_name column
    with pytest.raises(ValueError, match="pcnr_name"):
        assert_input(["group_id", "s_code"], _make_rows(4795))

    # Missing group_id column
    with pytest.raises(ValueError, match="group_id"):
        assert_input(["pcnr_name", "s_code"], _make_rows(4795))

    # Both missing
    with pytest.raises(ValueError):
        assert_input(["s_code", "col_order"], _make_rows(4795))


# ---------------------------------------------------------------------------
# Test 5: read_csv preserves headers on header-only (0-data-row) file
# ---------------------------------------------------------------------------

def test_read_csv_header_only(tmp_path: Path) -> None:
    p = tmp_path / "empty.csv"
    p.write_text("col_a,col_b,col_c\n", encoding="utf-8")
    headers, rows = read_csv(p)
    assert headers == ["col_a", "col_b", "col_c"]
    assert rows == []


def test_read_csv_with_data(tmp_path: Path) -> None:
    p = tmp_path / "data.csv"
    p.write_text("col_a,col_b\nval1,val2\nval3,val4\n", encoding="utf-8")
    headers, rows = read_csv(p)
    assert headers == ["col_a", "col_b"]
    assert len(rows) == 2
    assert rows[0]["col_a"] == "val1"


# ---------------------------------------------------------------------------
# Test 6: verify_workbook passes with matching counts; fails on mismatch
# ---------------------------------------------------------------------------

def test_verify_workbook(tmp_path: Path) -> None:
    out = tmp_path / "nm.xlsx"
    sheets = _small_sheets()
    write_workbook(sheets, out)

    # KEY sheet has 24 data rows (25 rows in _key_rows() minus the header row)
    expected = {
        "KEY": 24,
        "NAME_MAP": 2,
        "VARIABLES": 2,
        "NAME_MAP_COLLISIONS": 2,
        "NEAR_MATCHES": 2,
        "ABBREVIATIONS": 2,
    }
    verify_workbook(out, expected)  # must not raise

    with pytest.raises(ValueError):
        verify_workbook(out, {"NAME_MAP": 999})


# ---------------------------------------------------------------------------
# Test 7: written xlsx has exactly 6 sheets in SHEET_ORDER
# ---------------------------------------------------------------------------

def test_write_workbook_sheets(tmp_path: Path) -> None:
    out = tmp_path / "nm2.xlsx"
    write_workbook(_small_sheets(), out)

    from openpyxl import load_workbook as lw
    wb = lw(out, read_only=True)
    assert wb.sheetnames == SHEET_ORDER
    wb.close()


# ---------------------------------------------------------------------------
# Test 8: write_workbook with header-only sheet (0 data rows) writes correct headers
# ---------------------------------------------------------------------------

def test_write_workbook_header_only_sheet(tmp_path: Path) -> None:
    out = tmp_path / "nm_empty.xlsx"
    sheets = {
        "NAME_MAP": (["s_code", "col_order", "pcnr_name"], []),
        "VARIABLES": (["pcnr_name", "group_id"], []),
        "NAME_MAP_COLLISIONS": (["col_a"], []),
        "NEAR_MATCHES": (["col_a"], []),
        "ABBREVIATIONS": (["col_a"], []),
    }
    write_workbook(sheets, out)

    from openpyxl import load_workbook as lw
    wb = lw(out, read_only=True)
    ws = wb["NAME_MAP"]
    header_row = [c.value for c in next(ws.iter_rows(min_row=1, max_row=1))]
    assert header_row == ["s_code", "col_order", "pcnr_name"]
    assert ws.max_row == 1  # header only
    wb.close()


# ---------------------------------------------------------------------------
# Helper: load write_name_map_review script as a module
# ---------------------------------------------------------------------------

def _load_script():
    scripts_dir = Path(__file__).resolve().parent.parent / "scripts"
    if str(scripts_dir) not in sys.path:
        sys.path.insert(0, str(scripts_dir))
    spec = importlib.util.spec_from_file_location(
        "write_name_map_review",
        scripts_dir / "write_name_map_review.py",
    )
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


def _write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


def _make_exchange(exchange: Path, n_name_map: int = 3) -> None:
    """Write minimal synthetic CSVs for all 5 exchange files."""
    exchange.mkdir(parents=True, exist_ok=True)
    nm_cols = ["s_code", "col_order", "sas_name", "original_header", "trunc_flag",
               "status", "group_id", "pcnr_name", "sas_type", "length"]
    nm_rows = [
        {"s_code": "s01", "col_order": str(i), "sas_name": f"col{i}",
         "original_header": f"Header {i}", "trunc_flag": "0",
         "status": "PCNR", "group_id": str(i),
         "pcnr_name": f"PCNR_Var{i}", "sas_type": "C", "length": "20"}
        for i in range(n_name_map)
    ]
    _write_csv(exchange / "name_map.csv", nm_cols, nm_rows)
    _write_csv(
        exchange / "name_map_vars.csv",
        ["pcnr_name", "group_id", "result_type", "max_length", "type_conflict",
         "n_sources", "s_codes_contributing"],
        [{"pcnr_name": f"PCNR_Var{i}", "group_id": str(i), "result_type": "C",
          "max_length": "20", "type_conflict": "N", "n_sources": "1",
          "s_codes_contributing": "s01"}
         for i in range(n_name_map)],
    )
    _write_csv(exchange / "name_map_collisions.csv", ["col_a", "col_b"],
               [{"col_a": "x", "col_b": "y"}])
    _write_csv(
        exchange / "name_map_nearmatches.csv",
        ["s_code_a", "header_a", "col_order_a", "s_code_b", "header_b", "col_order_b", "edit_dist"],
        [{"s_code_a": "s01", "header_a": "Age", "col_order_a": "1",
          "s_code_b": "s02", "header_b": "Age_yrs", "col_order_b": "2", "edit_dist": "4"}],
    )
    _write_csv(exchange / "name_abbrev_applied.csv", ["group_id", "long", "short",
               "cleaned_before", "cleaned_after"],
               [{"group_id": "1", "long": "Number", "short": "N",
                 "cleaned_before": "Number_Score", "cleaned_after": "N_Score"}])


# ---------------------------------------------------------------------------
# Test 9: script builds workbook
# ---------------------------------------------------------------------------

def test_script_builds_workbook(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    exchange = tmp_path / "exchange"
    qc = tmp_path / "qc"
    logs = tmp_path / "logs"
    _make_exchange(exchange, n_name_map=3)

    mod = _load_script()
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "write_name_map_review.py",
            "--exchange", str(exchange),
            "--qc", str(qc),
            "--logs", str(logs),
            "--expected-name-map", "3",
        ],
    )
    rc = mod.main()
    assert rc == 0

    xlsx = qc / "name_map_review.xlsx"
    assert xlsx.exists()

    from openpyxl import load_workbook as lw
    wb = lw(xlsx, read_only=True)
    assert wb.sheetnames == SHEET_ORDER
    wb.close()


# ---------------------------------------------------------------------------
# Test 10: script handles header-only exchange CSVs (0 data rows)
# ---------------------------------------------------------------------------

def test_script_header_only_csvs(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    exchange = tmp_path / "exchange"
    qc = tmp_path / "qc"
    logs = tmp_path / "logs"
    exchange.mkdir(parents=True, exist_ok=True)

    nm_cols = ["s_code", "col_order", "sas_name", "original_header", "trunc_flag",
               "status", "group_id", "pcnr_name", "sas_type", "length"]
    nm_rows = [
        {"s_code": "s01", "col_order": str(i), "sas_name": f"col{i}",
         "original_header": f"H{i}", "trunc_flag": "0", "status": "PCNR",
         "group_id": str(i), "pcnr_name": f"PCNR_V{i}", "sas_type": "C", "length": "8"}
        for i in range(2)
    ]
    _write_csv(exchange / "name_map.csv", nm_cols, nm_rows)
    # All other CSVs: header-only (0 data rows)
    _write_csv(exchange / "name_map_vars.csv",
               ["pcnr_name", "group_id", "result_type"], [])
    _write_csv(exchange / "name_map_collisions.csv", ["group_id", "base_name"], [])
    _write_csv(exchange / "name_map_nearmatches.csv",
               ["s_code_a", "name_a", "s_code_b", "name_b"], [])
    _write_csv(exchange / "name_abbrev_applied.csv",
               ["group_id", "long", "short", "cleaned_before", "cleaned_after"], [])

    mod = _load_script()
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "write_name_map_review.py",
            "--exchange", str(exchange),
            "--qc", str(qc),
            "--logs", str(logs),
            "--expected-name-map", "2",
        ],
    )
    rc = mod.main()
    assert rc == 0

    from openpyxl import load_workbook as lw
    wb = lw(qc / "name_map_review.xlsx", read_only=True)
    ws = wb["VARIABLES"]
    header_row = [c.value for c in next(ws.iter_rows(min_row=1, max_row=1))]
    assert header_row == ["pcnr_name", "group_id", "result_type"]
    wb.close()


# ---------------------------------------------------------------------------
# Test 11: script returns 1 when name_map.csv has wrong row count
# ---------------------------------------------------------------------------

def test_script_wrong_row_count(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    exchange = tmp_path / "exchange"
    _make_exchange(exchange, n_name_map=3)
    mod = _load_script()
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "write_name_map_review.py",
            "--exchange", str(exchange),
            "--qc", str(tmp_path / "qc"),
            "--logs", str(tmp_path / "logs"),
            "--expected-name-map", "999",
        ],
    )
    rc = mod.main()
    assert rc == 1


# ---------------------------------------------------------------------------
# Test 12: read_csv strips UTF-8 BOM from first header
# ---------------------------------------------------------------------------

def test_read_csv_bom(tmp_path: Path) -> None:
    p = tmp_path / "bom.csv"
    p.write_bytes(b"\xef\xbb\xbfcol_a,col_b\nval1,val2\n")
    headers, rows = read_csv(p)
    assert headers[0] == "col_a", f"BOM not stripped; got {headers[0]!r}"
    assert rows[0]["col_a"] == "val1"


# ---------------------------------------------------------------------------
# Test 13: script writes decisions template with correct columns and row count
# ---------------------------------------------------------------------------

def test_decisions_template_written(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    exchange = tmp_path / "exchange"
    qc = tmp_path / "qc"
    logs = tmp_path / "logs"
    _make_exchange(exchange, n_name_map=3)  # writes 1 near-match row

    mod = _load_script()
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "write_name_map_review.py",
            "--exchange", str(exchange),
            "--qc", str(qc),
            "--logs", str(logs),
            "--expected-name-map", "3",
        ],
    )
    rc = mod.main()
    assert rc == 0

    tmpl = exchange / "name_map_decisions_template.csv"
    assert tmpl.exists(), "decisions template not written"
    headers, rows = read_csv(tmpl)
    assert headers == DECISIONS_TEMPLATE_COLS
    assert len(rows) == 1
    # Source columns populated; decision columns blank
    assert rows[0]["s_code_a"] == "s01"
    assert rows[0]["header_a"] == "Age"
    assert rows[0]["decision"] == ""


# ---------------------------------------------------------------------------
# Test 14: make_decisions_template handles missing source columns gracefully
# ---------------------------------------------------------------------------

def test_make_decisions_template_missing_cols() -> None:
    rows = [{"col_a": "x", "col_b": "y"}]
    result = make_decisions_template(rows)
    assert len(result) == 1
    assert result[0]["s_code_a"] == ""
    assert result[0]["decision"] == ""
    assert list(result[0].keys()) == DECISIONS_TEMPLATE_COLS
