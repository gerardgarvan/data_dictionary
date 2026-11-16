"""Static checks for Phase 15 plan 15-01: docs seeds and sas/15a_new_source_guard.sas."""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"


def _rows(path):
    with open(path, encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def _header(path):
    with open(path, encoding="utf-8-sig", newline="") as fh:
        return next(csv.reader(fh))


def test_new_source_files_rows():
    p = DOCS / "new_source_files.csv"
    assert _header(p) == [
        "s_code", "filename", "ftype", "src_encoding",
        "expected_rows", "expected_cols", "expected_distinct_psid",
    ]
    rows = _rows(p)
    assert len(rows) == 3
    assert [r["s_code"] for r in rows] == ["s21", "s22", "s23"]
    assert [r["src_encoding"] for r in rows] == ["utf-8", "wlatin1", "wlatin1"]
    assert [r["expected_rows"] for r in rows] == ["10772", "13029", "12689"]
    assert all(r["expected_cols"] == "94" for r in rows)
    assert all(r["expected_distinct_psid"] == r["expected_rows"] for r in rows)


def test_new_source_files_no_old_scodes():
    old = _rows(DOCS / "source_guard_baseline.csv")
    old_codes = {r["s_code"] for r in old}
    old_names = {r["filename"] for r in old}
    for r in _rows(DOCS / "new_source_files.csv"):
        assert r["s_code"] not in old_codes
        assert r["filename"] not in old_names


VARIANTS = DOCS / "new_source_header_variants.csv"
KINDS = {"year_prefix", "spelling", "underscore", "rename_and_type",
         "suffix_and_type", "type_change"}


def test_variants_header_and_status():
    assert _header(VARIANTS) == [
        "file_codes", "new_header", "new_type", "older_header",
        "older_source_codes", "older_type", "variant_kind", "note", "status",
    ]
    for r in _rows(VARIANTS):
        assert r["status"] == "PENDING DECISION"
        assert r["variant_kind"] in KINDS


def test_variants_required_rows():
    required = [
        "BRADEN_2024_OUT_Braden Activity", "BRADEN_2024_OUT_Braden Mobility",
        "BRADEN_2024_OUT_Braden Sensory P", "BRADEN_2025_OUT_Braden Activity",
        "BRADEN_2025_OUT_Braden Mobility", "BRADEN_2025_OUT_Braden Sensory P",
        "Fraility_Score", "Fraility_Category", "SleepApnea_YN",
        "preop_edu_years", "Feels_Exausted", "Low_Physical_Activity",
        "Slow_Walking_Speed", "Unintended_Weight_Loss", "Week_Grip_Strength",
        "Death_Days_After_Surgery",
    ]
    rows = _rows(VARIANTS)
    assert len(rows) == 16
    assert sorted(r["new_header"] for r in rows) == sorted(required)


def test_variants_no_counts():
    for r in _rows(VARIANTS):
        for v in r.values():
            assert not re.fullmatch(r"\s*(10|[1-9])\s*", v or "")


def test_gitignore_exceptions():
    lines = (ROOT / ".gitignore").read_text(encoding="utf-8").splitlines()
    for want in ("!docs/new_source_files.csv",
                 "!docs/new_source_header_variants.csv",
                 "!docs/source_guard_baseline_new.csv",
                 "!docs/import_spec_new_generated.csv"):
        assert want in lines


def test_new_baseline_if_present():
    p = DOCS / "source_guard_baseline_new.csv"
    if not p.exists():
        return
    assert _header(p) == ["s_code", "filename", "sha256"]
    rows = _rows(p)
    files = _rows(DOCS / "new_source_files.csv")
    assert [r["s_code"] for r in rows] == ["s21", "s22", "s23"]
    assert [r["filename"] for r in rows] == [r["filename"] for r in files]
    assert all(re.fullmatch(r"[0-9a-f]{64}", r["sha256"]) for r in rows)
