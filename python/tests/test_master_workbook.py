"""Synthetic tests for the Phase 19 writer (19-05). No real data."""
from __future__ import annotations

import csv
import logging

import pytest
from openpyxl import load_workbook

from pdd import master_rules, master_workbook as mw
from tests.phase19_fixture import HEADER, KINDS, ROWS, SENT, run_writer, write_stage


def _wb(p):
    return load_workbook(p["out"] / mw.FINAL_NAME, read_only=False)


def test_sheet_order_and_header(tmp_path):
    p = write_stage(tmp_path)
    run_writer(tmp_path, p)
    wb = _wb(p)
    assert wb.sheetnames == ["KEY", "DATA"]
    assert [c.value for c in wb["DATA"][1]] == HEADER
    assert wb["DATA"].max_row == len(ROWS) + 1
    key = wb["KEY"]
    assert key["A1"].fill.fgColor.rgb.endswith("0021A5")
    text = " ".join(str(c.value) for r in key.iter_rows() for c in r)
    assert "approved PeCAN team use only" in text and "pdd_2018_2025.xlsx" in text
    assert "PENDING" in text


def test_text_forced_and_typed(tmp_path):
    p = write_stage(tmp_path)
    run_writer(tmp_path, p)
    ws = _wb(p)["DATA"]
    assert (ws["D3"].value, ws["D3"].data_type) == ("=SUM(1)", "s")
    assert (ws["D4"].value, ws["D4"].data_type) == ("#N/A", "s")
    assert ws["B4"].value == "007"
    assert ws["D5"].value == 'multi\nline, "quoted"'
    assert ws["A2"].value == 1 and isinstance(ws["A2"].value, int)
    assert ws["E3"].value == 2.5
    assert ws["E5"].value == 1000 and isinstance(ws["E5"].value, int)
    assert ws["F2"].value is not None and ws["F2"].number_format == "yyyy-mm-dd"
    assert ws["E4"].value is None


def test_death_days_override_and_blanked(tmp_path):
    p = write_stage(tmp_path)
    r = run_writer(tmp_path, p)
    ws = _wb(p)["DATA"]
    assert [ws.cell(i, 7).value for i in range(2, 7)] == [30, None, None, 12.5, None]
    assert r["blanked"] == 2
    with (p["qc"] / "xlsx_master_write.csv").open() as fh:
        qc = {row["item"]: row["n"] for row in csv.DictReader(fh)}
    assert qc["death_days_nonnumeric_blanked"] == "<11"


def test_boundary_chars(tmp_path):
    rows = [["1", "P", "K1", "y" * 32767, "1", "", "", ""]]
    p = write_stage(tmp_path, rows=rows)
    run_writer(tmp_path, p)
    assert len(_wb(p)["DATA"]["D2"].value) == 32767
    p2 = write_stage(tmp_path / "b", rows=[["1", "P", "K1", "y" * 32768, "1", "", "", ""]])
    with pytest.raises(mw.StageError, match="PCNR_Text"):
        run_writer(tmp_path / "b", p2)
    assert not (p2["out"] / mw.FINAL_NAME).exists()


def test_control_char_stops_without_value(tmp_path, caplog, capsys):
    rows = [["1", "P", "K1", "bad\x01" + SENT, "1", "", "", ""]]
    p = write_stage(tmp_path, rows=rows)
    with pytest.raises(mw.StageError) as ei:
        run_writer(tmp_path, p)
    assert "PCNR_Text" in str(ei.value) and SENT not in str(ei.value)
    assert not (p["out"] / mw.FINAL_NAME).exists()
    assert not (p["out"] / (mw.FINAL_NAME + ".tmp")).exists()


def test_limit_gates(tmp_path):
    p = write_stage(tmp_path)
    with pytest.raises(mw.StageError, match="row limit"):
        run_writer(tmp_path, p, max_rows=3)
    with pytest.raises(mw.StageError, match="column limit"):
        run_writer(tmp_path, p, max_cols=4)
    with pytest.raises(mw.StageError, match="free disk"):
        run_writer(tmp_path, p, min_free_gb=1e9)


@pytest.mark.parametrize("extra", ["ENCRYPTED_MRN", "NORM_PSID"])
def test_unexpected_column_stops(tmp_path, extra):
    header = HEADER + [extra]
    rows = [r + ["x"] for r in ROWS]
    p = write_stage(tmp_path, rows=rows, header=header, kinds=KINDS + ["C"])
    with pytest.raises(mw.StageError):
        run_writer(tmp_path, p)


def test_k4_allows_era_copy_and_k3_rejects(tmp_path):
    header = ["PECAN_ID", "PRECEDE_STUDY_ID", "PECAN_ID_KEY_ERA", "KEY_ERA", "PCNR_Text"]
    rows = [["1", "P", "K1", "K1", "a"]]
    p = write_stage(tmp_path, rows=rows, header=header, kinds=["N", "C", "C", "C", "C"])
    with pytest.raises(mw.StageError):
        run_writer(tmp_path, p)
    run_writer(tmp_path, p, keys_code="K4")


def test_approval_required(tmp_path):
    p = write_stage(tmp_path)
    with pytest.raises(PermissionError):
        run_writer(tmp_path, p, approve=None)
    with pytest.raises(PermissionError):
        run_writer(tmp_path, p, approve="0")
    assert not (p["out"] / mw.FINAL_NAME).exists()


def test_existing_final_moved_to_backup(tmp_path):
    p = write_stage(tmp_path)
    (p["out"] / mw.FINAL_NAME).write_bytes(b"old")
    run_writer(tmp_path, p)
    baks = list(p["backup"].glob("PCNR_Master_Data_Nov_2026_*.xlsx"))
    assert len(baks) == 1 and baks[0].read_bytes() == b"old"
    assert _wb(p).sheetnames == ["KEY", "DATA"]


def test_failure_leaves_no_final(tmp_path):
    p = write_stage(tmp_path, rows=[["1", "P", "K1", "a", "notanumber", "", "", ""]])
    (p["out"] / mw.FINAL_NAME).write_bytes(b"old")
    with pytest.raises(mw.StageError, match="PCNR_Num"):
        run_writer(tmp_path, p)
    assert not (p["out"] / mw.FINAL_NAME).exists()
    assert not list(p["out"].glob("*.tmp"))
    assert list(p["backup"].glob("*.xlsx"))


def test_row_mismatch_with_expected_stops(tmp_path):
    p = write_stage(tmp_path)
    with (p["stage"] / "xlsx_data.csv").open("a", newline="") as fh:
        fh.write("9,P,K1,a,1,,,\r\n")
    with pytest.raises(mw.StageError, match="record count"):
        run_writer(tmp_path, p)


def test_no_cell_value_in_logs(tmp_path, caplog, capsys):
    p = write_stage(tmp_path)
    with caplog.at_level(logging.DEBUG):
        run_writer(tmp_path, p)
    out = capsys.readouterr()
    assert caplog.text
    for blob in (caplog.text, out.out, out.err):
        assert SENT not in blob and "multi" not in blob
    with (p["qc"] / "xlsx_master_write.csv").open() as fh:
        assert SENT not in fh.read()


def test_bench(tmp_path):
    p = write_stage(tmp_path)
    with pytest.raises(PermissionError):
        mw.bench(stage_dir=p["stage"], docs_dir=p["docs"], n_rows=3, approve=None)
    r = mw.bench(stage_dir=p["stage"], docs_dir=p["docs"], n_rows=3, approve="1")
    assert r["rows"] == 3 and r["rows_per_s"] > 0
    assert not (p["stage"] / "xlsx_bench.xlsx").exists()


def test_write_counts_file(tmp_path):
    p = write_stage(tmp_path)
    run_writer(tmp_path, p)
    with (p["stage"] / "xlsx_write_counts.csv").open() as fh:
        rows = {r["variable"]: r for r in csv.DictReader(fh)}
    assert rows["PCNR_Death_Days_After_Surgery"]["n_blanked"] == "2"
    assert rows["PCNR_Death_Days_After_Surgery"]["n_nonblank"] == "2"
    assert rows["PCNR_Empty"]["n_nonblank"] == "0"
    assert master_rules.NUMERIC_OVERRIDES
