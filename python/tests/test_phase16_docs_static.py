"""Static checks on Phase 16 docs seeds (decisions file, exchange schema rows, Price pending)."""

from __future__ import annotations

import csv
import subprocess
from pathlib import Path

DOCS = Path(__file__).resolve().parents[2] / "docs"
REPO = DOCS.parent

INT = {
    "name_map_ext_new.csv": ("col_order,group_id,length", "s_code,col_order,sas_name,original_header,status,group_id,pcnr_name,sas_type,length,map_class,matched_pcnr_name,decision_ref,name_key"),
    "name_map_vars_ext.csv": ("group_id,max_length,n_sources", "pcnr_name,group_id,result_type,max_length,type_conflict,n_sources,s_codes_contributing,var_origin"),
    "name_map_ext_candidates.csv": ("pair_id,col_order_new,edit_dist", "pair_id,s_code_new,col_order_new,header_new,s_codes_new,pcnr_name_old,s_codes_old,header_old,match_type,edit_dist,proposed_name_if_different,decision,status"),
    "name_map_ext_collisions.csv": ("col_order,suffix_n", "s_code,col_order,pcnr_name_base,pcnr_name_final,suffix_n,reason"),
    "name_map_ext_summary.csv": ("value", "metric,value"),
    "name_map_ext_values.csv": ("pair_id,col_order,n", "pair_id,side,s_code,col_order,sas_name,row_type,level,n"),
    "name_map_coverage.csv": ("first_year,last_year,n_nonmiss,n_nonmiss_no_year", "var_key,pcnr_name,s_code,first_year,last_year,years_present,n_nonmiss,n_nonmiss_no_year,status"),
    "name_map_vars_coverage.csv": ("first_year,last_year,n_sources_data", "var_key,pcnr_name,first_year,last_year,years_present,n_sources_data,s_codes_with_data,s_codes_contributing,status"),
}


def _rows(name: str) -> list[dict[str, str]]:
    with (DOCS / name).open(encoding="utf-8-sig", newline="") as fh:
        return [{k: v.strip() for k, v in r.items()} for r in csv.DictReader(fh)]


def test_decisions_new_header() -> None:
    new = (DOCS / "name_map_decisions_new.csv").read_text(encoding="utf-8").splitlines()
    old = (DOCS / "name_map_decisions.csv").read_text(encoding="utf-8").splitlines()
    assert new[0] == old[0]
    # header plus the 18 SAME rows Gerard decided on 2026-11-16 (see test_phase16a_static)
    assert len([ln for ln in new if ln.strip()]) == 19


def test_no_new_codes_in_phase4_decisions() -> None:
    for r in _rows("name_map_decisions.csv"):
        assert r["s_code_a"] not in {"s21", "s22", "s23"}
        assert r["s_code_b"] not in {"s21", "s22", "s23"}


def test_exchange_schema_phase16() -> None:
    rows = _rows("exchange_schema.csv")
    for fname, (ints, cols) in INT.items():
        expected = {(c, "int" if c in ints.split(",") else "str") for c in cols.split(",")}
        got = [r for r in rows if r["file"] == fname]
        assert {(r["column"], r["type"]) for r in got} == expected
        assert len(got) == len(expected)
        assert all(r["required"] == "Y" for r in got)


def test_preexisting_schema_rows_unchanged() -> None:
    res = subprocess.run(
        ["git", "show", "HEAD:docs/exchange_schema.csv"],
        cwd=REPO, capture_output=True, check=False,
    )
    if res.returncode != 0:
        return
    head = res.stdout.decode("utf-8-sig").splitlines()
    now = (DOCS / "exchange_schema.csv").read_text(encoding="utf-8-sig").splitlines()
    assert now[: len(head)] == head


def test_price_signoff_pending() -> None:
    text = (DOCS / "DECISIONS.md").read_text(encoding="utf-8")
    hits = [ln for ln in text.splitlines() if "Price sign-off" in ln and "OPEN" in ln]
    assert hits
    assert any("Phase 16" in ln for ln in hits)
