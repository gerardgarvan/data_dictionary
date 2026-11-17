"""Tests for the Phase 16 review workbook module and entry point (synthetic data only)."""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

import pytest
from openpyxl import load_workbook

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from pdd.name_map_ext_workbook import (  # noqa: E402
    CONTRACT,
    SHEET_ORDER,
    assert_input,
    privacy_safe_summary,
    read_csv,
    side_by_side,
    verify_workbook,
    write_workbook,
)
from write_name_map_ext_review import main  # noqa: E402

DOCS = Path(__file__).resolve().parents[2] / "docs"
PART_16B = {"name_map_ext_values.csv", "name_map_coverage.csv", "name_map_vars_coverage.csv"}


def _write(path: Path, headers: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=headers)
        w.writeheader()
        w.writerows(rows)


def _fixture(d: Path, with_16b: bool = True) -> None:
    d.mkdir(parents=True, exist_ok=True)
    _write(d / "name_map_ext_new.csv", CONTRACT["name_map_ext_new.csv"], [
        {"s_code": "s21", "col_order": "1", "sas_name": "Foo_Score", "original_header": "Foo Score",
         "status": "PENDING_DECISION", "group_id": "", "pcnr_name": "", "sas_type": "N", "length": "8",
         "map_class": "PENDING_DECISION", "matched_pcnr_name": "", "decision_ref": "", "name_key": "foo_score"},
    ])
    _write(d / "name_map_vars_ext.csv", CONTRACT["name_map_vars_ext.csv"], [
        {"pcnr_name": "PCNR_Bar", "group_id": "3", "result_type": "N", "max_length": "8",
         "type_conflict": "N", "n_sources": "2", "s_codes_contributing": "s03 s21", "var_origin": "EXTENDED"},
    ])
    _write(d / "name_map_ext_candidates.csv", CONTRACT["name_map_ext_candidates.csv"], [
        {"pair_id": "11", "s_code_new": "s21", "col_order_new": "1", "header_new": "Foo_Score",
         "s_codes_new": "s21", "pcnr_name_old": "PCNR_Foo_Scr", "s_codes_old": "s03", "header_old": "Foo Scr",
         "match_type": "EDIT_DISTANCE", "edit_dist": "2", "proposed_name_if_different": "Foo_Score",
         "decision": "", "status": "PENDING_DECISION"},
        {"pair_id": "12", "s_code_new": "s22", "col_order_new": "4", "header_new": "Bar",
         "s_codes_new": "s22", "pcnr_name_old": "PCNR_Bar", "s_codes_old": "s03", "header_old": "Bar",
         "match_type": "TYPE_CONFLICT_EXACT", "edit_dist": "0", "proposed_name_if_different": "",
         "decision": "", "status": "INFO_REUSED"},
    ])
    _write(d / "name_map_ext_collisions.csv", CONTRACT["name_map_ext_collisions.csv"], [])
    _write(d / "name_map_ext_summary.csv", CONTRACT["name_map_ext_summary.csv"], [
        {"metric": "n_new_rows", "value": "282"},
        {"metric": "n_candidates_pending", "value": "3"},
        {"metric": "n_stage2_fail", "value": "0"},
        {"metric": "n_frozen_names_changed", "value": "0"},
    ])
    if not with_16b:
        return
    vals = []
    for side, s, lvl, n in [("NEW", "s21", "yes", "250"), ("OLD", "s03", "YES", "11"),
                            ("NEW", "s21", "rare", "3"), ("OLD", "s03", "other", "10"),
                            ("OLD", "s09", "yes", "5")]:
        vals.append({"pair_id": "11", "side": side, "s_code": s, "col_order": "1", "sas_name": "Foo",
                     "row_type": "LEVEL", "level": lvl, "n": n})
    vals.append({"pair_id": "11", "side": "NEW", "s_code": "s21", "col_order": "1", "sas_name": "Foo",
                 "row_type": "MIN", "level": "7", "n": ""})
    vals.append({"pair_id": "11", "side": "OLD", "s_code": "s03", "col_order": "1", "sas_name": "Foo",
                 "row_type": "N_MISSING", "level": "", "n": "0"})
    _write(d / "name_map_ext_values.csv", CONTRACT["name_map_ext_values.csv"], vals)
    _write(d / "name_map_coverage.csv", CONTRACT["name_map_coverage.csv"], [
        {"var_key": "PCNR_Bar", "pcnr_name": "PCNR_Bar", "s_code": "s21", "first_year": "2023",
         "last_year": "2023", "years_present": "2023", "n_nonmiss": "3", "n_nonmiss_no_year": "0",
         "status": "DATA"},
    ])
    _write(d / "name_map_vars_coverage.csv", CONTRACT["name_map_vars_coverage.csv"], [
        {"var_key": "PCNR_Bar", "pcnr_name": "PCNR_Bar", "first_year": "2023", "last_year": "2023",
         "years_present": "2023", "n_sources_data": "1", "s_codes_with_data": "s21",
         "s_codes_contributing": "s03 s21", "status": "DATA"},
        {"var_key": "PENDING:foo_score", "pcnr_name": "", "first_year": "", "last_year": "",
         "years_present": "", "n_sources_data": "0", "s_codes_with_data": "", "s_codes_contributing": "",
         "status": "NO_DATA"},
    ])


def _docs(tmp_path: Path) -> Path:
    d = tmp_path / "docs"
    d.mkdir()
    (d / "exchange_schema.csv").write_bytes((DOCS / "exchange_schema.csv").read_bytes())
    return d


def _args(tmp_path: Path, *extra: str) -> list[str]:
    return ["--exchange", str(tmp_path / "ex"), "--qc", str(tmp_path / "qc"),
            "--logs", str(tmp_path / "logs"), "--docs", str(tmp_path / "docs"), *extra]


# ---- module ----------------------------------------------------------------

def test_sheet_order() -> None:
    assert SHEET_ORDER == ["KEY", "SUMMARY", "NEW_ROWS", "CANDIDATES", "VALUES_SIDE_BY_SIDE",
                           "TYPE_CONFLICTS", "COLLISIONS", "COVERAGE", "COVERAGE_BY_SOURCE",
                           "VARIABLES_EXT"]


def test_assert_input_names_missing() -> None:
    with pytest.raises(ValueError, match="n_nonmiss_no_year"):
        assert_input("COVERAGE_BY_SOURCE", ["var_key", "n_nonmiss"], [])


def test_side_by_side(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex")
    _, vals = read_csv(tmp_path / "ex" / "name_map_ext_values.csv")
    _, cands = read_csv(tmp_path / "ex" / "name_map_ext_candidates.csv")
    out = side_by_side(vals, cands)
    assert out[0]["row_type"] == "SHARED_LEVELS"
    assert (out[0]["n_new"], out[0]["n_old"], out[0]["shared"]) == ("2", "2", "1")
    levels = {r["level"]: r for r in out if r["row_type"] == "LEVEL"}
    assert (levels["YES"]["n_new"], levels["YES"]["n_old"], levels["YES"]["shared"]) == ("250", "16", "Y")
    assert levels["RARE"]["shared"] == "N" and levels["RARE"]["n_old"] == "0"
    mn = next(r for r in out if r["row_type"] == "MIN")
    assert mn["side_s_code"] == "NEW:s21" and mn["n_new"] == "7" and mn["n_old"] == ""
    nm = next(r for r in out if r["row_type"] == "N_MISSING")
    assert nm["side_s_code"] == "OLD:s03" and nm["n_old"] == "0"
    assert out[0]["header_new"] == "Foo_Score" and out[0]["pcnr_name_old"] == "PCNR_Foo_Scr"


def test_write_workbook_masks_and_styles(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex")
    _, vals = read_csv(tmp_path / "ex" / "name_map_ext_values.csv")
    _, cands = read_csv(tmp_path / "ex" / "name_map_ext_candidates.csv")
    cov_h, cov_r = read_csv(tmp_path / "ex" / "name_map_coverage.csv")
    sheets = {
        "VALUES_SIDE_BY_SIDE": (["pair_id", "header_new", "pcnr_name_old", "row_type", "side_s_code",
                                 "level", "n_new", "n_old", "shared"], side_by_side(vals, cands)),
        "COVERAGE_BY_SOURCE": (cov_h, cov_r),
    }
    out = tmp_path / "w.xlsx"
    write_workbook(sheets, out)
    verify_workbook(out, {"COVERAGE_BY_SOURCE": 1})
    wb = load_workbook(out)
    assert wb.sheetnames[0] == "KEY"
    assert wb["SUMMARY"]["A1"].value == "(no data)"
    ws = wb["VALUES_SIDE_BY_SIDE"]
    got = {(r[3].value, r[5].value): (r[6].value, r[7].value) for r in ws.iter_rows(min_row=2)}
    assert got[("LEVEL", "RARE")] == ("<11", "0")
    assert got[("LEVEL", "YES")] == ("250", "16")
    assert got[("LEVEL", "OTHER")] == ("0", "<11")
    assert got[("MIN", None)] == ("7", None)
    assert ws["A1"].fill.start_color.rgb.endswith("0021A5")
    cov = wb["COVERAGE_BY_SOURCE"]
    assert cov["G2"].value == "<11" and cov["H2"].value == "0"
    with pytest.raises(ValueError):
        verify_workbook(out, {"COVERAGE_BY_SOURCE": 5})


def test_privacy_safe_summary(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex")
    sheets = {}
    for sheet, f in (("SUMMARY", "name_map_ext_summary.csv"), ("COVERAGE", "name_map_vars_coverage.csv")):
        sheets[sheet] = read_csv(tmp_path / "ex" / f)
    h, rows = read_csv(tmp_path / "ex" / "name_map_ext_candidates.csv")
    sheets["CANDIDATES"] = (h, [r for r in rows if r["match_type"] != "TYPE_CONFLICT_EXACT"])
    sheets["TYPE_CONFLICTS"] = (h, [r for r in rows if r["match_type"] == "TYPE_CONFLICT_EXACT"])
    lines = privacy_safe_summary(sheets)
    assert "GATE MAP-02 near-match: PENDING DECISION n=<11" in lines
    assert "GATE MAP-03 Stage 2: PASS" in lines
    assert "FROZEN NAMES CHANGED: 0" in lines
    assert "METRIC n_new_rows=282" in lines
    assert "METRIC n_candidates_pending=<11" in lines
    assert any(ln.startswith("CANDIDATE pair=11 match_type=EDIT_DISTANCE") for ln in lines)
    assert "COVERAGE vars=<11 no_data=<11" in lines
    assert lines[-1].startswith("PRICE SIGN-OFF: PENDING")


def test_summary_pass_and_not_run() -> None:
    lines = privacy_safe_summary({"SUMMARY": (["metric", "value"], [
        {"metric": "n_candidates_pending", "value": "0"}, {"metric": "n_stage2_fail", "value": "2"}])})
    assert "GATE MAP-02 near-match: PASS (all decided)" in lines
    assert "GATE MAP-03 Stage 2: FAIL" in lines
    assert "COVERAGE: not run (16b PENDING SAS RUN)" in lines


# ---- entry point -----------------------------------------------------------

def test_main_full(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex")
    _docs(tmp_path)
    assert main(_args(tmp_path)) == 0
    assert (tmp_path / "qc" / "name_map_ext_review.xlsx").exists()
    text = (tmp_path / "logs" / "name_map_ext_summary.txt").read_text(encoding="utf-8")
    assert "PRICE SIGN-OFF: PENDING" in text
    assert not re.search(r"=\b([1-9]|10)\b", text)


def test_main_missing_16a(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex")
    _docs(tmp_path)
    (tmp_path / "ex" / "name_map_ext_new.csv").unlink()
    assert main(_args(tmp_path, "--allow-partial")) == 1


def test_main_missing_16b(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex", with_16b=False)
    _docs(tmp_path)
    assert main(_args(tmp_path)) == 1
    assert main(_args(tmp_path, "--allow-partial")) == 0
    wb = load_workbook(tmp_path / "qc" / "name_map_ext_review.xlsx")
    assert wb["VALUES_SIDE_BY_SIDE"]["A1"].value == "(no data)"
    assert wb["COVERAGE"]["A1"].value == "(no data)"
    text = (tmp_path / "logs" / "name_map_ext_summary.txt").read_text(encoding="utf-8")
    assert "COVERAGE: not run (16b PENDING SAS RUN)" in text


def test_main_schema_column_missing(tmp_path: Path) -> None:
    _fixture(tmp_path / "ex")
    _docs(tmp_path)
    _write(tmp_path / "ex" / "name_map_ext_summary.csv", ["metric"], [{"metric": "n_new_rows"}])
    assert main(_args(tmp_path)) == 1
