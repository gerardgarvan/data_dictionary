"""Tests for s06 workbook logic using 10-row synthetic data."""

from __future__ import annotations

import csv
from pathlib import Path

import pytest

from pdd.s06_workbook import (
    assert_input,
    read_csv,
    verify_workbook,
    write_workbook,
)

# ---------------------------------------------------------------------------
# Synthetic 10-row dataset: 3 CLOCK, 2 DIGITAL_OTHER, 4 PCNR, 1 UNSURE
# (used for workbook-write tests; NOT for assert_input which checks exact counts)
# ---------------------------------------------------------------------------
_SYNTHETIC = [
    {"sas_name": "COMDigit1", "orig_col_name": "COMDigit1", "token": "Digit1", "class": "CLOCK", "rule": "COM + clock token", "pct_nonnull": "50.0"},
    {"sas_name": "COMHand2", "orig_col_name": "COMHand2", "token": "Hand2", "class": "CLOCK", "rule": "COM + clock token", "pct_nonnull": "40.0"},
    {"sas_name": "LINUS_Scr", "orig_col_name": "LINUS_Score", "token": "LINUS", "class": "CLOCK", "rule": "LINUS prefix", "pct_nonnull": "30.0"},
    {"sas_name": "COMMoca1", "orig_col_name": "COMMoca1", "token": "Moca1", "class": "DIGITAL_OTHER", "rule": "COM + digital token", "pct_nonnull": "80.0"},
    {"sas_name": "COMMoca2", "orig_col_name": "COMMoca2", "token": "Moca2", "class": "DIGITAL_OTHER", "rule": "COM + digital token", "pct_nonnull": "75.0"},
    {"sas_name": "Age", "orig_col_name": "Age", "token": "", "class": "PCNR", "rule": "No prefix", "pct_nonnull": "100.0"},
    {"sas_name": "Sex", "orig_col_name": "Sex", "token": "", "class": "PCNR", "rule": "No prefix", "pct_nonnull": "99.5"},
    {"sas_name": "BMI", "orig_col_name": "BMI", "token": "", "class": "PCNR", "rule": "No prefix", "pct_nonnull": "95.0"},
    {"sas_name": "Clock_Flag", "orig_col_name": "clock_flag", "token": "", "class": "PCNR", "rule": "No prefix", "pct_nonnull": "20.0"},
    {"sas_name": "COMUnkwn", "orig_col_name": "COMUnkwn", "token": "Unkwn", "class": "UNSURE", "rule": "COM -- token not recognized", "pct_nonnull": "5.0"},
]
_FIELDNAMES = ["sas_name", "orig_col_name", "token", "class", "rule", "pct_nonnull"]


def _write_synthetic_csv(path: Path) -> None:
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=_FIELDNAMES)
        writer.writeheader()
        writer.writerows(_SYNTHETIC)


# ---------------------------------------------------------------------------
# Tests: read_csv
# ---------------------------------------------------------------------------

def test_read_csv_roundtrip(tmp_path: Path) -> None:
    csv_path = tmp_path / "test.csv"
    _write_synthetic_csv(csv_path)
    rows = read_csv(csv_path)
    assert len(rows) == 10
    assert rows[0]["sas_name"] == "COMDigit1"
    assert rows[0]["class"] == "CLOCK"


# ---------------------------------------------------------------------------
# Tests: assert_input
# ---------------------------------------------------------------------------

def test_assert_input_passes_with_matching_counts() -> None:
    custom_counts = {"CLOCK": 3, "DIGITAL_OTHER": 2, "PCNR": 4, "UNSURE": 1}
    assert_input(_SYNTHETIC, expected_rows=10, expected_counts=custom_counts)


def test_assert_input_fails_on_wrong_total() -> None:
    with pytest.raises(ValueError, match="row count"):
        assert_input(_SYNTHETIC, expected_rows=5, expected_counts={"CLOCK": 3, "DIGITAL_OTHER": 2, "PCNR": 4, "UNSURE": 1})


def test_assert_input_fails_on_wrong_class_count() -> None:
    with pytest.raises(ValueError, match="class=CLOCK"):
        assert_input(_SYNTHETIC, expected_rows=10, expected_counts={"CLOCK": 99, "DIGITAL_OTHER": 2, "PCNR": 4, "UNSURE": 1})


def test_assert_input_fails_on_nonzero_unsure() -> None:
    with pytest.raises(ValueError, match="class=UNSURE"):
        # Expected UNSURE=0 but data has 1
        assert_input(_SYNTHETIC, expected_rows=10, expected_counts={"CLOCK": 3, "DIGITAL_OTHER": 2, "PCNR": 4, "UNSURE": 0})


# ---------------------------------------------------------------------------
# Tests: write_workbook + verify_workbook
# ---------------------------------------------------------------------------

def test_write_workbook_creates_all_sheets(tmp_path: Path) -> None:
    out = tmp_path / "test.xlsx"
    write_workbook(_SYNTHETIC, out)
    assert out.exists()

    from openpyxl import load_workbook as lw
    wb = lw(out, read_only=True)
    assert wb.sheetnames[0] == "KEY"
    for sheet in ["KEY", "SUMMARY", "CLOCK", "DIGITAL_OTHER", "PCNR", "ALL_COLUMNS"]:
        assert sheet in wb.sheetnames, f"Missing sheet: {sheet}"
    wb.close()


def test_write_workbook_sheet_row_counts(tmp_path: Path) -> None:
    out = tmp_path / "test.xlsx"
    write_workbook(_SYNTHETIC, out)
    verify_workbook(
        out,
        {
            "KEY": 10,
            "CLOCK": 3,
            "DIGITAL_OTHER": 2,
            "PCNR": 4,
            "ALL_COLUMNS": 10,
        },
    )


def test_write_workbook_csv_roundtrip(tmp_path: Path) -> None:
    csv_path = tmp_path / "s06_class_nn.csv"
    _write_synthetic_csv(csv_path)
    rows = read_csv(csv_path)
    out = tmp_path / "out.xlsx"
    write_workbook(rows, out)
    assert out.exists()
    assert out.stat().st_size > 0
