"""Synthetic tests for the Phase 19 verifier (19-06). No real data."""
from __future__ import annotations

import csv
import logging
import sys
from pathlib import Path

import pytest
from openpyxl import load_workbook

from pdd import master_verify as mv, master_workbook as mw
from tests.phase19_fixture import SENT, run_writer, write_stage

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

TOKEN = "MRNTOKEN_ABCDEF123456"


@pytest.fixture(autouse=True)
def _registry(monkeypatch):
    monkeypatch.setattr(mv, "load_registry_tokens", lambda path: {TOKEN, "OTHERTOKEN_XYZ98765"})


def _built(tmp_path):
    p = write_stage(tmp_path)
    run_writer(tmp_path, p)
    return p, p["out"] / mw.FINAL_NAME


def _verify(p, xlsx):
    return mv.verify(xlsx=xlsx, stage_dir=p["stage"], exchange_dir=p["exchange"],
                     docs_dir=p["docs"], registry_path=Path("registry.sas7bdat"))


def _failed(res):
    return {(c, v) for c, v, _, _, ok in res if not ok}


def _tamper(xlsx, fn):
    wb = load_workbook(xlsx)
    fn(wb)
    wb.save(xlsx)


def test_pass_case(tmp_path):
    p, x = _built(tmp_path)
    assert _failed(_verify(p, x)) == set()


def test_noop_roundtrip_still_passes(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: None)
    assert _failed(_verify(p, x)) == set()


def test_extra_row(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].append([9, "P", "K1", "a", 1, None, None, None]))
    assert ("row_count", "") in _failed(_verify(p, x))


def test_missing_column(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].delete_cols(8))
    assert ("header_equals_expected", "") in _failed(_verify(p, x))


def test_swapped_columns(tmp_path):
    p, x = _built(tmp_path)

    def swap(wb):
        ws = wb["DATA"]
        a, b = ws["D1"].value, ws["E1"].value
        ws["D1"], ws["E1"] = b, a

    _tamper(x, swap)
    assert ("header_equals_expected", "") in _failed(_verify(p, x))


def test_wrong_nonblank_count_and_no_data(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].__setitem__("H2", "oops"))
    f = _failed(_verify(p, x))
    assert ("nonblank_vs_stage", "PCNR_Empty") in f
    assert ("no_data_zero", "PCNR_Empty") in f


def test_formula_cell(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].__setitem__("H2", "=SUM(1)"))
    # openpyxl stores the loaded-and-assigned string as a formula
    assert ("formula_cells", "") in _failed(_verify(p, x))


def test_planted_mrn_token(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].__setitem__("D2", "see " + TOKEN + " here"))
    res = _verify(p, x)
    assert ("disclosure_registry_token_hits", "") in _failed(res)
    hit = [r for r in res if r[0] == "disclosure_registry_token_hits"][0]
    assert hit[2] == 1
    assert TOKEN not in repr(res)


def test_key_fact_mismatch(tmp_path):
    p, x = _built(tmp_path)

    def edit(wb):
        for row in wb["KEY"].iter_rows(min_row=2):
            if row[0].value == "FACTS_PCNR_2018_2025" and row[1].value == "ROWS":
                row[2].value = "999"

    _tamper(x, edit)
    assert ("key_facts_equal_file", "") in _failed(_verify(p, x))


def test_sample_value_mismatch(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].__setitem__("E2", 6))
    f = _failed(_verify(p, x))
    assert ("sample_value_mismatch_column", "PCNR_Num") in f


def test_header_name_flag(tmp_path):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].__setitem__("D1", "PCNR_ENCRYPTED_MRN"))
    assert ("disclosure_header_names", "") in _failed(_verify(p, x))


def test_recon_masked_tolerance_and_mismatch(tmp_path):
    p, x = _built(tmp_path)
    path = p["exchange"] / "comb_recon.csv"
    rows = list(csv.reader(path.open()))
    for r in rows[1:]:
        if r[0] == "Text":
            r[1] = "<11"  # exact count is 5 -> masked 1..10 is consistent
    csv.writer(path.open("w", newline="")).writerows(rows)
    assert _failed(_verify(p, x)) == set()
    for r in rows[1:]:
        if r[0] == "Num":
            r[1] = "50"
    csv.writer(path.open("w", newline="")).writerows(rows)
    assert ("nonblank_vs_recon", "PCNR_Num") in _failed(_verify(p, x))


def test_death_days_rule_uses_blanked(tmp_path):
    p, x = _built(tmp_path)
    res = _verify(p, x)
    dd = [r for r in res if r[1] == "PCNR_Death_Days_After_Surgery" and r[0] != "sample_type_tally"]
    assert dd and all(r[4] for r in dd)
    (p["stage"] / "xlsx_write_counts.csv").unlink()  # blanked unknown -> counts no longer reconcile
    assert ("nonblank_vs_stage", "PCNR_Death_Days_After_Surgery") in _failed(_verify(p, x))


@pytest.mark.parametrize(
    "txt,n,expect",
    [("<11", 5, True), ("<11", 0, False), ("<11", 11, False), ("12", 12, True), ("12", 13, False),
     (">(1000)", 1001, True), (">1000", 999, False), ("abc", 1, None), ("", 1, None)],
)
def test_masked_match(txt, n, expect):
    assert mv.masked_match(txt, n) is expect


def test_outputs_masked_and_no_values(tmp_path, caplog, capsys):
    p, x = _built(tmp_path)
    res = _verify(p, x)
    ok = mv.write_outputs(res, p["qc"] / "v.csv", p["exchange"] / "s.csv")
    assert ok
    for name in ("v.csv",):
        text = (p["qc"] / name).read_text()
        assert SENT not in text and "multi" not in text
    summary = (p["exchange"] / "s.csv").read_text()
    assert SENT not in summary
    with (p["qc"] / "v.csv").open() as fh:
        ns = [r["n"] for r in csv.DictReader(fh)]
    assert not any(n.isdigit() and 1 <= int(n) <= 10 for n in ns)


def _script(monkeypatch, p, tmp_path):
    import verify_master_workbook as vs

    for name, key in (("STAGE_PATH", "stage"), ("EXCHANGE_PATH", "exchange"), ("DOCS_PATH", "docs"),
                      ("QC_PATH", "qc"), ("OUT_PATH", "out")):
        monkeypatch.setattr(vs, name, p[key])
    monkeypatch.setattr(vs, "OUT_ROOT", tmp_path)
    return vs


def test_script_pass_deletes_stage_and_logs_no_values(tmp_path, monkeypatch, caplog, capsys):
    p, x = _built(tmp_path)
    vs = _script(monkeypatch, p, tmp_path)
    with caplog.at_level(logging.DEBUG):
        code = vs.main(["--log", str(tmp_path / "v.log")])
    assert code == 0
    assert not list(p["stage"].glob("xlsx_*.csv"))
    out = capsys.readouterr()
    for blob in (caplog.text, out.out, out.err, (tmp_path / "v.log").read_text()):
        assert SENT not in blob and TOKEN not in blob
    assert (p["qc"] / "xlsx_master_verify.csv").exists()


def test_script_fail_keeps_stage(tmp_path, monkeypatch):
    p, x = _built(tmp_path)
    _tamper(x, lambda wb: wb["DATA"].append([9, "P", "K1", "a", 1, None, None, None]))
    vs = _script(monkeypatch, p, tmp_path)
    assert vs.main(["--log", str(tmp_path / "v.log")]) == 1
    assert (p["stage"] / "xlsx_data.csv").exists()


def test_registry_unreadable_fails(tmp_path, monkeypatch):
    p, x = _built(tmp_path)

    def boom(path):
        raise OSError("nope")

    monkeypatch.setattr(mv, "load_registry_tokens", boom)
    assert ("registry_tokens_loaded", "") in _failed(_verify(p, x))
