"""Tests for name_map_workbook logic."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path

import pytest

from pdd.name_map_workbook import (
    SHEET_ORDER,
    assert_input,
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
    rows_ok = _make_rows(4795)
    assert_input(rows_ok)  # must not raise

    rows_short = _make_rows(4794)
    with pytest.raises(ValueError, match="row count"):
        assert_input(rows_short)


# ---------------------------------------------------------------------------
# Test 3: pcnr_name uniqueness within group_id
# ---------------------------------------------------------------------------

def test_no_dup_pcnr_names() -> None:
    # Two rows: same pcnr_name, different group_id -> ValueError
    bad_rows = (
        [{"pcnr_name": "PCNR_Age", "group_id": "g1", "s_code": "s01", "col_order": "1"}]
        + [{"pcnr_name": "PCNR_Age", "group_id": "g2", "s_code": "s02", "col_order": "1"}]
        + _make_rows(4793, pcnr_name="", group_id="")
    )
    with pytest.raises(ValueError, match="pcnr_name"):
        assert_input(bad_rows)

    # Same pcnr_name, same group_id -> allowed (cross-file overlap)
    same_group_rows = (
        [{"pcnr_name": "PCNR_Age", "group_id": "g1", "s_code": "s01", "col_order": "1"}]
        + [{"pcnr_name": "PCNR_Age", "group_id": "g1", "s_code": "s02", "col_order": "1"}]
        + _make_rows(4793, pcnr_name="", group_id="")
    )
    assert_input(same_group_rows)  # must not raise

    # Blank pcnr_name repeated freely -> allowed
    blank_rows = _make_rows(4795, pcnr_name="", group_id="")
    assert_input(blank_rows)  # must not raise


# ---------------------------------------------------------------------------
# Test 4: verify_workbook passes with matching counts; fails on mismatch
# ---------------------------------------------------------------------------

def test_verify_workbook(tmp_path: Path) -> None:
    out = tmp_path / "nm.xlsx"
    sheets = _small_sheets()
    write_workbook(sheets, out)

    # KEY sheet has 9 data rows (10 rows in _key_rows() minus the header row)
    expected = {
        "KEY": 9,
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
# Test 5: written xlsx has exactly 6 sheets in SHEET_ORDER
# ---------------------------------------------------------------------------

def test_write_workbook_sheets(tmp_path: Path) -> None:
    out = tmp_path / "nm2.xlsx"
    write_workbook(_small_sheets(), out)

    from openpyxl import load_workbook as lw
    wb = lw(out, read_only=True)
    assert wb.sheetnames == SHEET_ORDER
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


def _write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    if not rows:
        path.write_text("col\n", encoding="utf-8")
        return
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


def _make_exchange(exchange: Path, n_name_map: int = 3) -> None:
    """Write minimal synthetic CSVs for all 5 exchange files."""
    exchange.mkdir(parents=True, exist_ok=True)
    nm_rows = [
        {"pcnr_name": f"PCNR_Var{i}", "group_id": f"g{i}", "s_code": "s01", "col_order": str(i)}
        for i in range(n_name_map)
    ]
    _write_csv(exchange / "name_map.csv", nm_rows)
    _write_csv(
        exchange / "name_map_vars.csv",
        [{"pcnr_name": f"PCNR_Var{i}", "result_type": "N"} for i in range(n_name_map)],
    )
    _write_csv(exchange / "name_map_collisions.csv", [{"col_a": "x", "col_b": "y"}])
    _write_csv(exchange / "name_map_nearmatches.csv", [{"col_a": "x", "col_b": "y"}])
    _write_csv(exchange / "name_abbrev_applied.csv", [{"original": "x", "abbrev": "y"}])


# ---------------------------------------------------------------------------
# Test 6: script builds workbook
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
# Test 7: script returns 1 on verify_workbook row-count mismatch
# ---------------------------------------------------------------------------

def test_script_row_count_mismatch(tmp_path: Path) -> None:
    # Build a valid workbook first via write_workbook directly
    out = tmp_path / "nm.xlsx"
    sheets = _small_sheets()
    write_workbook(sheets, out)

    # verify_workbook with wrong count -> ValueError
    with pytest.raises(ValueError):
        verify_workbook(out, {"NAME_MAP": 999})
