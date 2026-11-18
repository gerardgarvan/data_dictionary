"""
Tests for python/pdd/dictionary_2018_2025_workbook.py (Phase 18 plan 06).

Synthetic CSV fixtures only: no real data, no MRNs.
"""

from __future__ import annotations

import csv
import subprocess
import sys
from pathlib import Path

import pytest
from openpyxl import load_workbook

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pdd.dictionary_2018_2025_workbook import (  # noqa: E402
    SHEET_ORDER_2018_2025,
    validate_exchange_headers,
    verify_workbook_2018_2025,
    write_workbook_2018_2025,
)
from pdd.dictionary_workbook import DEFAULT_DISPLAY_CONFIG  # noqa: E402

DOCS = Path(__file__).resolve().parent.parent.parent / "docs"
SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "write_dictionary_2018_2025.py"
CFG = dict(DEFAULT_DISPLAY_CONFIG, age_topcode=False)

TOTAL = 120
# name -> (N in the profile, n_nonmiss_comb_all in comb_recon)
VARS = {
    "Zeta_Var": ("100", "100"),
    "Alpha_Var": ("90", "90"),
    "Sleep_Apnea_YN": ("50", "50"),
    "Death_Days_After_Surgery": ("40", "40"),
    "ASA_Anesth_Record": ("80", "80"),
    "Rare_Var": ("5", "<11"),
    "NoData_Var": ("0", "0"),
    "Special_Var": ("60", "60"),  # also holds .A/.B cells: missing for N (PDD-D-34)
}
N_SPECIAL = {"Special_Var": "25"}
PROFILE_COLS = [
    "family", "variable", "var_class", "stat", "level", "n", "value", "pct_total",
    "pct_nonmiss", "sort_order", "small_cell_flag", "date_kind", "display_format",
]
RECON_COLS = [
    "pcnr_name", "n_nonmiss_pcnr_old", "n_nonmiss_comb_k1", "n_nonmiss_comb_k2",
    "n_nonmiss_comb_all", "n_special_comb_all", "delta_k1", "n_distinct_k1", "n_distinct_prf_v1", "explained",
]


def _w(path: Path, header: list[str], rows: list[list[str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as fh:
        wr = csv.writer(fh)
        wr.writerow(header)
        wr.writerows(rows)


def make_exchange(
    tmp_path: Path,
    *,
    columns: int | None = None,
    rows: int = TOTAL,
    recon_override: dict[str, str] | None = None,
    explained_n: str | None = None,
    dup_pairs: str = "17",
    k2_mode: str | None = "NORM",
) -> Path:
    ex = tmp_path / "exchange"
    ex.mkdir()
    facts = [
        ["rows", str(rows)],
        ["columns", str(columns if columns is not None else 5 + len(VARS))],
        ["dup_pairs", dup_pairs],
        ["shared_surgeries", "142"],
    ]
    if k2_mode:
        facts.append(["PDD_K2_PSID_MODE", k2_mode])
    _w(ex / "comb_key_facts.csv", ["item", "value"], facts)

    prof = []
    for i, (name, (n, _)) in enumerate(VARS.items(), start=1):
        rec = {c: "" for c in PROFILE_COLS}
        rec.update(family="PCNR", variable=name, var_class="CONT_NUM", stat="N", n=n, sort_order=str(i))
        prof.append([rec[c] for c in PROFILE_COLS])
    _w(ex / "profile_PCNR_2018_2025.csv", PROFILE_COLS, prof)
    _w(
        ex / "profile_PCNR_2018_2025_manifest.csv",
        ["pcnr_modate", "pcnr_nobs", "run_dttm"],
        [["01JAN2026", str(rows), "2026-01-01 00:00"]],
    )

    recon = []
    for name, (_, rc) in VARS.items():
        if recon_override and name in recon_override:
            rc = recon_override[name]
        exp = explained_n if (explained_n and name == "Alpha_Var") else "Y"
        recon.append([name, rc, rc, "0", rc, N_SPECIAL.get(name, "0"), "0", "3", "3", exp])
    _w(ex / "comb_recon.csv", RECON_COLS, recon)
    _w(ex / "comb_nodata.csv", ["pcnr_name", "n_nonmiss", "coverage_status", "reconciled"],
       [["NoData_Var", "0", "NO_DATA", "Y"]])
    _w(ex / "comb_d30_conflicts.csv",
       ["pcnr_name", "n_shared", "n_s22_missing_filled", "n_conflict_kept_s22"],
       [["Alpha_Var", "142", "<11", "0"]])
    cov_cols = ["var_key", "pcnr_name", "first_year", "last_year", "years_present", "n_sources_data",
                "s_codes_with_data", "s_codes_contributing", "status"]
    cov = []
    for name in VARS:
        nodata = name == "NoData_Var"
        cov.append([name, name, "" if nodata else "2018", "" if nodata else "2025", "2018 2025",
                    "0" if nodata else "2", "" if nodata else "s01 s21", "s01 s21",
                    "NO_DATA" if nodata else "PCNR"])
    _w(ex / "name_map_vars_coverage.csv", cov_cols, cov)
    return ex


def build(tmp_path: Path, **kw) -> Path:
    ex = make_exchange(tmp_path, **kw)
    out = tmp_path / "out" / "pdd_2018_2025.xlsx"
    counts = write_workbook_2018_2025(ex, out, DOCS, CFG)
    verify_workbook_2018_2025(out, counts)
    return out


def _texts() -> dict[str, str]:
    with (DOCS / "pecan_id_dictionary_text.csv").open(encoding="utf-8-sig", newline="") as fh:
        return {r["item"]: r["text"] for r in csv.DictReader(fh)}


def _blob(ws) -> str:
    return "\n".join(str(c.value) for row in ws.iter_rows() for c in row if c.value is not None)


def test_sheet_order_key_leftmost_and_colors(tmp_path):
    wb = load_workbook(build(tmp_path))
    assert wb.sheetnames == SHEET_ORDER_2018_2025
    assert wb.sheetnames[0] == "KEY"
    for name in SHEET_ORDER_2018_2025:
        assert wb[name]["A1"].fill.fgColor.rgb.endswith("0021A5")
    accents = [c for row in wb["KEY"].iter_rows() for c in row if c.fill.fgColor.rgb.endswith("FA4616")]
    assert accents, "accent color FA4616 expected on KEY"


def test_variables_order_pecan_id_first_then_alphabetical(tmp_path):
    ws = load_workbook(build(tmp_path))["VARIABLES"]
    names = [r[0].value for r in ws.iter_rows(min_row=2)]
    assert names[:5] == ["PECAN_ID", "PRECEDE_STUDY_ID", "PECAN_ID_KEY_ERA", "KEY_ERA", "NORM_PSID"]
    rest = names[5:]
    assert rest == sorted(rest, key=str.casefold)
    assert len(names) == 5 + len(VARS)


def test_pecan_id_row_text_verbatim(tmp_path):
    ws = load_workbook(build(tmp_path))["VARIABLES"]
    d = [c.value for c in ws[1]].index("description") + 1
    texts = _texts()
    assert ws.cell(row=2, column=d).value == texts["PECAN_ID dictionary row"]
    assert ws.cell(row=4, column=d).value == texts["PECAN_ID_KEY_ERA dictionary row"]


def test_no_data_flag_and_type_notes(tmp_path):
    ws = load_workbook(build(tmp_path))["VARIABLES"]
    h = {c.value: i for i, c in enumerate(ws[1])}
    by = {r[0].value: r for r in ws.iter_rows(min_row=2)}
    assert by["NoData_Var"][h["data_status"]].value == "NO_DATA"
    assert by["Alpha_Var"][h["data_status"]].value is None
    assert by["Alpha_Var"][h["source_columns"]].value == "s01 s21"
    assert by["Alpha_Var"][h["year_first"]].value == 2018
    note = by["Death_Days_After_Surgery"][h["type_note"]].value
    assert "#Error" in note and "116" in note
    assert "Y or blank" in by["Sleep_Apnea_YN"][h["type_note"]].value
    assert "Numeric per STATE carry" in by["ASA_Anesth_Record"][h["type_note"]].value
    assert by["Alpha_Var"][h["type_note"]].value is None


def test_masked_count_stays_masked(tmp_path):
    ws = load_workbook(build(tmp_path))["VARIABLES"]
    h = {c.value: i for i, c in enumerate(ws[1])}
    by = {r[0].value: r for r in ws.iter_rows(min_row=2)}
    assert by["Rare_Var"][h["n_nonmiss"]].value == "<11"
    assert by["Alpha_Var"][h["n_nonmiss"]].value == 90
    for row in ws.iter_rows(min_row=2):
        v = row[h["n_nonmiss"]].value
        assert not (isinstance(v, int) and 1 <= v <= 10)


def test_key_sheet_text(tmp_path):
    blob = _blob(load_workbook(build(tmp_path))["KEY"])
    texts = _texts()
    for item in ("PECAN_ID dictionary row", "PECAN_ID_KEY_ERA dictionary row", "KEY sheet caveat"):
        assert texts[item] in blob
    assert "17 K1 dup pairs" in blob
    assert "pecan_id_dup_link" in blob
    assert "non-missing counts and distinct-value counts, NOT level-by-level frequencies" in blob
    assert "PDD-D-33" in blob and "normalized Precede#####" in blob and "Mode: NORM" in blob
    assert "PDD-D-30" in blob and "142" in blob
    assert "1 s06 variables are flagged NO_DATA" in blob  # computed from the fixture
    assert "Price" in blob and "pending" in blob
    assert "NULL is read as missing" in blob
    assert "120 rows and 13 columns" in blob


def test_k2_mode_from_key_facts(tmp_path):
    blob = _blob(load_workbook(build(tmp_path, k2_mode="DELIVERED"))["KEY"])
    assert "Mode: DELIVERED" in blob


def test_masked_dup_pairs_shown_as_is(tmp_path):
    blob = _blob(load_workbook(build(tmp_path, dup_pairs="<11"))["KEY"])
    assert "<11 K1 dup pairs" in blob


def test_reconcile_fails_on_count_mismatch(tmp_path):
    ex = make_exchange(tmp_path, recon_override={"Alpha_Var": "91"})
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_reconcile_fails_when_recon_masks_visible_count(tmp_path):
    ex = make_exchange(tmp_path, recon_override={"Alpha_Var": "<11"})
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_reconcile_fails_on_column_count_mismatch(tmp_path):
    ex = make_exchange(tmp_path, columns=99)
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_reconcile_fails_on_row_count_mismatch(tmp_path):
    ex = make_exchange(tmp_path)
    (ex / "profile_PCNR_2018_2025_manifest.csv").write_text(
        "pcnr_modate,pcnr_nobs,run_dttm\n01JAN2026,5,x\n", encoding="utf-8"
    )
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_reconcile_fails_on_explained_n(tmp_path):
    ex = make_exchange(tmp_path, explained_n="N")
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_unmasked_small_count_in_exchange_fails(tmp_path):
    ex = make_exchange(tmp_path, recon_override={"Rare_Var": "5"})
    with pytest.raises(RuntimeError, match="unmasked small count"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_header_validation_reports_missing_column(tmp_path):
    ex = make_exchange(tmp_path)
    assert validate_exchange_headers(ex, DOCS) == []
    (ex / "comb_nodata.csv").write_text("pcnr_name,n_nonmiss\nX,0\n", encoding="utf-8")
    errs = validate_exchange_headers(ex, DOCS)
    assert any("comb_nodata.csv" in e and "reconciled" in e for e in errs)


def test_script_exit_codes(tmp_path):
    ex = make_exchange(tmp_path)
    out = tmp_path / "o"
    base = [sys.executable, str(SCRIPT), "--exchange", str(ex), "--out", str(out),
            "--logs", str(tmp_path / "logs"), "--docs", str(DOCS)]
    res = subprocess.run(base, capture_output=True, text=True)
    assert res.returncode == 0, res.stdout + res.stderr
    assert (out / "pdd_2018_2025.xlsx").exists()
    (ex / "comb_recon.csv").unlink()
    assert subprocess.run(base, capture_output=True, text=True).returncode != 0


def _read_profile(ex: Path) -> tuple[list[str], list[list[str]]]:
    with (ex / "profile_PCNR_2018_2025.csv").open(encoding="utf-8", newline="") as fh:
        rd = list(csv.reader(fh))
    return rd[0], rd[1:]


def _add_profile_row(ex: Path, **cells: str) -> None:
    header, rows = _read_profile(ex)
    rec = {c: "" for c in PROFILE_COLS}
    rec.update(family="PCNR", variable="Zeta_Var", var_class="CONT_NUM", stat="LEVEL", sort_order="50")
    rec.update(cells)
    rows.append([rec[c] for c in PROFILE_COLS])
    _w(ex / "profile_PCNR_2018_2025.csv", header, rows)


def test_special_missing_variable_reconciles(tmp_path):
    # profile N = recon n_nonmiss_comb_all = 60; 25 special missings shown only as n_special
    ws = load_workbook(build(tmp_path))["VARIABLES"]
    h = {c.value: i for i, c in enumerate(ws[1])}
    by = {r[0].value: r for r in ws.iter_rows(min_row=2)}
    assert by["Special_Var"][h["n_nonmiss"]].value == 60


def test_reconcile_fails_when_recon_counts_special_missings_as_values(tmp_path):
    # the pre-PDD-D-34 behaviour: n_nonmiss_comb_all = N + special total
    ex = make_exchange(tmp_path, recon_override={"Special_Var": "85"})
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_unmasked_small_n_special_fails(tmp_path):
    ex = make_exchange(tmp_path)
    header, rows = _read_profile(ex)
    rc = (ex / "comb_recon.csv").read_text(encoding="utf-8").replace(",25,", ",7,")
    (ex / "comb_recon.csv").write_text(rc, encoding="utf-8")
    with pytest.raises(RuntimeError, match="unmasked small count"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_pct_on_masked_n_row_fails(tmp_path):
    ex = make_exchange(tmp_path)
    _add_profile_row(ex, n="<11", pct_total="0.5", small_cell_flag="Y")
    with pytest.raises(RuntimeError, match="pct"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_pct_on_blank_n_row_fails(tmp_path):
    ex = make_exchange(tmp_path)
    _add_profile_row(ex, n="", pct_total="50", small_cell_flag="N")
    with pytest.raises(RuntimeError, match="blank or masked n"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_pct_implying_small_count_fails_even_with_large_n(tmp_path):
    # 1/120 * 100 = 0.8333: implied count 1 of TOTAL 120
    ex = make_exchange(tmp_path)
    _add_profile_row(ex, n="50", pct_total="0.83333333", small_cell_flag="N")
    with pytest.raises(RuntimeError, match="back-calculates"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_pct_guard_applies_to_other_exchange_files(tmp_path):
    ex = make_exchange(tmp_path)
    (ex / "comb_nodata.csv").write_text(
        "pcnr_name,n_nonmiss,coverage_status,reconciled,pct_total\nNoData_Var,0,NO_DATA,Y,2.5\n",
        encoding="utf-8",
    )
    with pytest.raises(RuntimeError, match="back-calculates"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


def test_blank_pct_on_masked_rows_and_large_pct_pass(tmp_path):
    ex = make_exchange(tmp_path)
    _add_profile_row(ex, n="<11", pct_total="", small_cell_flag="Y")
    _add_profile_row(ex, n="50", pct_total="41.6667", small_cell_flag="N")
    out = tmp_path / "o.xlsx"
    write_workbook_2018_2025(ex, out, DOCS, CFG)
    assert out.exists()


def _add_numtext(tmp_path: Path, n: str, unp: str | None, comb_all: str) -> Path:
    ex = make_exchange(tmp_path, columns=5 + len(VARS) + 1)
    stats = [("N", n)] + ([("N_UNPARSED", unp)] if unp is not None else [])
    for k, (stat, val) in enumerate(stats):
        _add_profile_row(ex, variable="Text_Var", var_class="NUM_TEXT", stat=stat, n=val,
                         sort_order=str(60 + k))
    with (ex / "comb_recon.csv").open("a", newline="", encoding="utf-8") as fh:
        csv.writer(fh).writerow(["Text_Var", comb_all, comb_all, "0", comb_all, "0", "0", "3", "3", "Y"])
    return ex


@pytest.mark.parametrize(
    ("n", "unp", "comb_all"),
    [("100", "20", "120"), ("100", "<11", "105"), ("100", "<11", "110"), ("100", "<11", "101"),
     ("100", None, "100"), ("100", "0", "100")],
)
def test_numtext_reconciles(tmp_path, n, unp, comb_all):
    ex = _add_numtext(tmp_path, n, unp, comb_all)
    write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)


@pytest.mark.parametrize(
    ("n", "unp", "comb_all"),
    [("100", "20", "119"), ("100", "<11", "100"), ("100", "<11", "111"),
     ("100", None, "105"), ("100", "0", "101")],
)
def test_numtext_reconcile_fails(tmp_path, n, unp, comb_all):
    ex = _add_numtext(tmp_path, n, unp, comb_all)
    with pytest.raises(ValueError, match="reconciliation failed"):
        write_workbook_2018_2025(ex, tmp_path / "o.xlsx", DOCS, CFG)
