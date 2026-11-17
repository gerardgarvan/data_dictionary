"""Offline D-02 classification of the 282 new spec rows against committed spec CSVs."""

from __future__ import annotations

import csv
import re
from pathlib import Path

DOCS = Path(__file__).resolve().parents[2] / "docs"


def clean_name(s: str) -> str:
    """Phase 4 %clean_name: runs of non-alphanumerics -> '_', trim '_', N_ prefix on leading digit."""
    s = re.sub(r"[^A-Za-z0-9]+", "_", s.strip()).strip("_")
    if s[:1].isdigit():
        s = "N_" + s
    return s


def _rows(name: str) -> list[dict[str, str]]:
    with (DOCS / name).open(encoding="utf-8-sig", newline="") as fh:
        return [{k: (v or "").strip() for k, v in r.items()} for r in csv.DictReader(fh)]


def _new() -> list[dict[str, str]]:
    return _rows("import_spec_new_generated.csv")


def _old_keys() -> set[str]:
    clock = {r["sas_name"] for r in _rows("s06_column_class.csv") if r["class"] == "CLOCK"}
    keys = set()
    for r in _rows("import_spec_generated.csv"):
        if r["file_code"] in {"s04", "s05"}:
            continue
        if r["file_code"] == "s06" and r["sas_name"] in clock:
            continue
        keys.add(clean_name(r["orig_col_name"]).lower())
    return keys


def test_clean_name_rules() -> None:
    assert clean_name("BRADEN_2024_OUT_Braden Sensory Perception") == "BRADEN_2024_OUT_Braden_Sensory_Perception"
    assert clean_name(" ASA (Anesth Record) ") == "ASA_Anesth_Record"
    assert clean_name("2nd value") == "N_2nd_value"


def test_new_spec_shape() -> None:
    rows = _new()
    assert len(rows) == 282
    codes = [r["file_code"] for r in rows]
    assert set(codes) == {"s21", "s22", "s23"}
    assert all(codes.count(c) == 94 for c in set(codes))


def test_old_side_keys() -> None:
    keys = _old_keys()
    assert keys
    assert "precede_study_id" in keys
    assert all(k == k.lower() for k in keys)


def _variant_keys() -> set[str]:
    return {clean_name(r["new_header"]).lower() for r in _rows("new_source_header_variants.csv")}


def _nonmatching() -> set[str]:
    old = _old_keys()
    return {
        clean_name(r["orig_col_name"])
        for r in _new()
        if clean_name(r["orig_col_name"]).lower() not in old
    }


def test_nonmatching_headers_are_listed() -> None:
    unlisted = {h for h in _nonmatching() if h.lower() not in _variant_keys()}
    assert not unlisted, f"unlisted new near-match headers: {sorted(unlisted)}"


def test_predicted_split() -> None:
    new_keys = {clean_name(r["orig_col_name"]).lower() for r in _new()}
    old = _old_keys()
    exact = new_keys & old
    assert len(new_keys) == 100
    assert len(exact) == 90
    assert _nonmatching() == {
        "preop_edu_years", "SleepApnea_YN", "Fraility_Category", "Fraility_Score",
        "BRADEN_2024_OUT_Braden_Activity", "BRADEN_2024_OUT_Braden_Mobility",
        "BRADEN_2024_OUT_Braden_Sensory_Perception", "BRADEN_2025_OUT_Braden_Activity",
        "BRADEN_2025_OUT_Braden_Mobility", "BRADEN_2025_OUT_Braden_Sensory_Perception",
    }
    for k in ("precede_study_id", "encrypted_mrn", "encrypted_encounter"):
        assert k in exact
