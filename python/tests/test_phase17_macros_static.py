"""Static checks for Phase 17 plan 17-01: macros, config additions, synthetic test (no SAS here)."""
import re
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
LINT = ROOT / "tools" / "sas_lint.py"
ALL17 = [
    "00_config.sas",
    "17_pecan_id_macros.sas",
    "17_pecan_id_test.sas",
    "17_pecan_id_link_macros.sas",
    "17_pecan_id_link_test.sas",
    "pecan_id_link.sas",
    "17a_pecan_id_k1_seed.sas",
    "17b_pecan_id_k2.sas",
    "17c_pecan_id_summary.sas",
]


def _text(name):
    return (SAS / name).read_text(encoding="utf-8")


def _code(name):
    return re.sub(r"/\*.*?\*/", "", _text(name), flags=re.S)


def _macro_body(name, macro):
    code = _code(name)
    m = re.search(r"%macro\s+" + macro + r"\b.*?%mend\s+" + macro + r"\s*;", code, flags=re.S | re.I)
    assert m, macro
    return m.group(0)


@pytest.mark.parametrize("name", ALL17)
def test_lint_clean(name):
    r = subprocess.run([sys.executable, str(LINT), str(SAS / name)], capture_output=True, text=True, cwd=ROOT)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in (r.stdout + r.stderr).lower() or "clean" in (r.stdout + r.stderr).lower()


def test_config_additions():
    t = _text("00_config.sas")
    assert r"%let g_path      = P:\PeCAN Master Data\Gerard\Master_Renamed_same_format_accross\merge;" in t
    assert "access=readonly" in t
    assert "%macro pdd_lib_g;" in t
    assert re.search(r"libname g base \"&g_path\.\" access=readonly;", t)
    assert "%let PDD_APPROVE_NEW_BASELINE = 0;" in t
    assert r"%let backup_path = &out_root.\backup;" in t


def _open_code_if(name):
    depth = 0
    bad = []
    for i, line in enumerate(_code(name).splitlines(), 1):
        if re.match(r"\s*%macro\b", line, flags=re.I):
            depth += 1
        if depth == 0 and re.search(r"%(if|else)\b", line, flags=re.I):
            bad.append(i)
        if re.match(r"\s*%mend\b", line, flags=re.I):
            depth -= 1
    return bad


@pytest.mark.parametrize("name", ALL17)
def test_no_open_code_if(name):
    assert _open_code_if(name) == []


@pytest.mark.parametrize("name", ALL17)
def test_no_double_question_in_proc_sql(name):
    for blk in re.findall(r"proc\s+sql.*?quit\s*;", _code(name), flags=re.S | re.I):
        assert "??" not in blk


@pytest.mark.parametrize("name", ALL17)
def test_no_point_step(name):
    assert not re.search(r"\bpoint\s*=", _code(name), flags=re.I)


@pytest.mark.parametrize("name", ["17_pecan_id_macros.sas", "17_pecan_id_link_macros.sas"])
def test_macros_file_has_no_open_code_besides_init(name):
    code = _code(name)
    stripped = re.sub(r"%macro\s+(\w+).*?%mend\s+\1\s*;", "", code, flags=re.S | re.I)
    leftover = [ln.strip() for ln in stripped.splitlines() if ln.strip()]
    assert leftover in ([], ["%p17_init;"]), leftover


def test_required_macros_exist():
    t = _code("17_pecan_id_macros.sas")
    for m in [
        "p17_usable_mrn", "p17_rank_k2", "p17_pdd_d30_cases", "p17_backup", "p17_assert_backup_current",
        "p17_gate_registry", "p17_gate_casemap", "p17_k1_join", "p17_gate_k1", "p17_dup_pairs",
        "p17_append_dup_link", "p17_backup_link", "p17_k2_append", "p17_casemap", "p17_k1_reg_rows",
    ]:
        assert re.search(r"%macro\s+" + m + r"\b", t, flags=re.I), m


def test_append_dup_link_never_deletes():
    body = _macro_body("17_pecan_id_macros.sas", "p17_append_dup_link")
    assert not re.search(r"proc\s+delete|drop\s+table|\bdelete\b", body, flags=re.I)
    assert "proc append base=pdd.pecan_id_dup_link" in body
    assert body.index("%p17_backup_link") < body.index("proc append base=pdd.pecan_id_dup_link")


def test_k1_join_copies_pecan_id_unchanged_and_uses_globals():
    body = _macro_body("17_pecan_id_macros.sas", "p17_k1_join")
    for g in ("PDD_K1_SPINE_KEY", "PDD_K1_HARM_KEY", "PDD_K1_KEY_MODE"):
        assert g in body
    assert not re.search(r"pecan_id\s*=\s*[^;]*[-+*/(]", body, flags=re.I)
    assert "??" not in body or "pdd_norm_psid" in body  # ?? only lives in the config macro


def test_gate_k1_fails_on_each_condition():
    body = _macro_body("17_pecan_id_macros.sas", "p17_gate_k1")
    for v in ("p17_n_harm", "p17_n_m1", "p17_n_m0", "p17_n_m2", "p17_n_missid"):
        assert v in body


def test_k2_append_order_assert_append_gate_backup():
    body = _macro_body("17_pecan_id_macros.sas", "p17_k2_append")
    a = body.index("%p17_assert_backup_current")
    b = body.index("proc append base=pdd.pecan_id_registry")
    c = body.index("%p17_gate_registry")
    d = body.index("%p17_backup;")
    assert a < b < c < d
    assert not re.search(r"proc\s+delete|drop\s+table|\bdelete\b", body, flags=re.I)


def test_no_case_column_in_proc_sql():
    for name in ALL17:
        for blk in re.findall(r"proc\s+sql.*?quit\s*;", _code(name), flags=re.S | re.I):
            assert not re.search(r"\bas\s+(case|when|then|else|as|on)\b", blk, flags=re.I)


def test_synthetic_test_covers_plan_cases():
    t = _text("17_pecan_id_test.sas")
    for tag in [
        "T1_K2_RANK_AND_TIEBREAK", "T3_S23_FILLS_BLANK_S22", "T3_SHARED_COUNT", "T4_S21_OVERLAP_FAILS",
        "T5_K1_GATE_PASSES", "T5_BLANK_MRN_LINE", "T5_BLANK_MRN_ROW_KEEPS_ID",
        "T6_SPINE_ROW_MATCHING_NONE_FAILS", "T6_SPINE_ROW_MATCHING_TWO_FAILS", "T6_MISSING_PECAN_ID_FAILS",
        "T7_ONE_DUP_PAIR", "T7_PAIR_VALUES", "T8_SECOND_APPEND_ADDS_0", "T8_EXISTING_ROW_UNCHANGED",
        "T9_SECOND_RUN_APPENDS_0", "T9_NEW_MRN_GETS_MAX_PLUS_1", "T9_K2_IDS_1000000_PLUS_RANK",
        "T10_DUPLICATE_PECAN_ID_FAILS", "T10_DUPLICATE_MRN_K2_FAILS", "T10_K2_ID_BELOW_1000001_FAILS",
        "T10_K1_ID_AT_OR_ABOVE_1000000_FAILS", "T11_UNMAPPED_USABLE_MRN_CASE_FAILS",
        "T12_DIFFERING_REGISTRY_FAILS_WITHOUT_APPROVAL", "T13_NO_WARNINGS_OR_ERRORS_IN_LOG",
    ]:
        assert tag in t, tag
    assert "TESTRESULT SUMMARY" in t
    assert "PENDING SAS RUN" in t
    code = _code("17_pecan_id_test.sas")
    assert "P:\\" not in code and "libname g" not in code.lower()
    assert "%pdd_lib" not in code and "00_config.sas" not in code


def test_test_norm_psid_copy_matches_config():
    def body(name):
        m = re.search(r"%macro pdd_norm_psid\(.*?%mend pdd_norm_psid;", _code(name), flags=re.S)
        assert m
        return re.sub(r"\s+", " ", m.group(0))

    assert body("17_pecan_id_test.sas") == body("00_config.sas")


def test_backup_member_names_at_most_32_chars():
    """Every backup stem used anywhere, plus the 16-char timestamp, fits 32 bytes."""
    import re
    stems = set()
    for f in (ROOT / "sas").glob("17*.sas"):
        code = f.read_text(encoding="utf-8")
        stems.update(re.findall(r"stem\s*=\s*([A-Za-z_]\w*)", code))
    assert {"pidreg", "piddup", "pidmap", "pidreg_prelink"} <= stems, stems
    stamp = "_20260101_010101"
    assert len(stamp) == 16
    for s in stems:
        assert len(s + stamp) <= 32, f"{s}{stamp} is {len(s + stamp)} chars"
    macros = (ROOT / "sas" / "17_pecan_id_macros.sas").read_text(encoding="utf-8")
    assert "stem=pecan_id" not in macros
    assert "b8601dt15." in macros and "%length(&_p17_last_backup) > 32" in macros


def test_test_harness_chk_uses_unquote_and_fails_on_error():
    for name in ("17_pecan_id_test.sas", "17_pecan_id_link_test.sas"):
        code = (ROOT / "sas" / name).read_text(encoding="utf-8")
        assert "%if %unquote(&cond)" in code, name
        assert "%if &cond" not in code, name
        assert "upcase(_infile_) =: 'ERROR'" in code, name
        assert "upcase(_infile_) =: 'WARNING'" in code, name
        assert "substr(_infile_" not in code, name
        assert "index(upcase(_infile_), 'ERROR:')" not in code, name
