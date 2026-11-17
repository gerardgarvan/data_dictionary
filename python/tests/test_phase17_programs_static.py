"""Static checks for Phase 17 programs 17a, 17b, 17c, the link program and the wiring (no SAS here)."""
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
PROGRAMS = [
    "17a_pecan_id_k1_seed.sas",
    "17b_pecan_id_k2.sas",
    "17c_pecan_id_summary.sas",
    "pecan_id_link.sas",
    "17_pecan_id_macros.sas",
    "17_pecan_id_link_macros.sas",
]
DEL = re.compile(r"(proc\s+delete|drop\s+table|\bdelete\b)[^;]*pecan_id_(registry|dup_link)", re.I | re.S)


def _code(name):
    return re.sub(r"/\*.*?\*/", "", (SAS / name).read_text(encoding="utf-8"), flags=re.S)


def _all_code(names=PROGRAMS):
    return "\n".join(_code(n) for n in names)


def test_no_control_characters_in_phase17_files():
    files = list(SAS.glob("17*.sas")) + [SAS / "pecan_id_link.sas", SAS / "99_run_all.sas", SAS / "00_config.sas"]
    for f in files:
        for ch in f.read_text(encoding="utf-8"):
            assert ch in "\n\r\t" or ord(ch) >= 32, f.name


@pytest.mark.parametrize("name", PROGRAMS)
def test_g_is_never_written(name):
    code = _code(name)
    assert not re.search(r"(\bdata|out=|base=|create\s+table|modify)\s+g\.", code, flags=re.I)
    assert not re.search(r"proc\s+(append|datasets|delete)[^;]*\bg\b", code, flags=re.I)


@pytest.mark.parametrize("name", PROGRAMS)
def test_registry_and_link_never_deleted(name):
    assert not DEL.search(_code(name))


@pytest.mark.parametrize("name", PROGRAMS)
def test_xwalk_is_not_an_input(name):
    assert "pecan_id_xwalk" not in _code(name).lower()


def test_17a_structure():
    code = _code("17a_pecan_id_k1_seed.sas")
    assert "%pdd_lib_g;" in code
    assert "%p17_k1_registry_link(" in code
    mac = _code("17_pecan_id_macros.sas")
    rl = mac[mac.index("%macro p17_k1_registry_link"):mac.index("%mend p17_k1_registry_link")]
    assert "exist(pdd.pecan_id_registry)" in rl
    assert "registry exists, K1 build skipped" in rl
    assert "%p17_append_dup_link" in rl
    # the dup link append sits behind the failure guard, after the baseline guard
    guard = rl.index("%if &_p17_failed = 0 %then %do;", rl.index("%p17_registry_baseline("))
    assert guard < rl.index("%p17_append_dup_link")
    assert rl.index("%p17_registry_baseline(") < rl.index("%p17_gate_registry(", rl.index("%p17_registry_baseline("))
    # QC written before the gate verdict, join before the gate
    j = code.index("%p17_k1_join(")
    d = code.index("%p17_dump_qc(tables=k1", j)
    g = code.index("%p17_gate_k1;")
    assert j < d < g
    # k1_cases only after the gate, registry only after k1_cases
    assert g < code.index("data pdd.pecan_id_k1_cases") < code.index("%p17_k1_registry_link(")
    # registry is never created directly in 17a; only through the approval guard
    assert not re.search(r"data\s+pdd\.pecan_id_registry\b", code, flags=re.I)
    assert "pecan_id_registry_proposed.csv" in code and "pecan_id_registry_proposed_summary.csv" in code
    macros = _code("17_pecan_id_macros.sas")
    body = macros[macros.index("%macro p17_registry_baseline"):macros.index("%mend p17_registry_baseline")]
    assert '"&PDD_APPROVE_NEW_BASELINE" = "1"' in body
    assert body.index('"&PDD_APPROVE_NEW_BASELINE" = "1"') < body.index("data pdd.pecan_id_registry;")
    assert "%p17_backup;" in body and "%p17_fail(" in body
    assert "PRECEDE_Study_ID" in code and "PRECEDE_STUDY_ID" in code and "norm" in code
    assert re.search(r"pecan_id_dup_pairs_by_year\.csv", code) and "pecan_id_k1.csv" in code
    assert "BLANK_SPINE_MRN_ROWS" in code


@pytest.mark.parametrize("name", ["17a_pecan_id_k1_seed.sas", "17b_pecan_id_k2.sas",
                                  "17c_pecan_id_summary.sas", "pecan_id_link.sas"])
def test_production_programs_force_abort_mode(name):
    """Production programs never inherit FLAG from a test run in the same session."""
    code = _code(name)
    cfg = code.index('%include "C:\\data_dictionary\\sas\\00_config.sas";')
    m = re.search(r"%let\s+p17_fail_mode\s*=\s*ABORT\s*;", code)
    assert m and m.start() > cfg
    assert m.start() < code.index("%pdd_lib;")
    assert "FLAG" not in code


def test_gates_fail_on_missing_table():
    mac = _code("17_pecan_id_macros.sas")
    for macro in ("p17_gate_registry", "p17_gate_casemap"):
        body = mac[mac.index("%macro " + macro):mac.index("%mend " + macro)]
        assert "%sysfunc(exist(" in body and "%return;" in body, macro
        assert body.index("%sysfunc(exist(") < body.index("proc sql"), macro


@pytest.mark.parametrize("name", ["17_pecan_id_test.sas", "17_pecan_id_link_test.sas"])
def test_tests_restore_session_state(name):
    code = (SAS / name).read_text(encoding="utf-8")
    assert "_saved_fail_mode" in code and "_saved_pdd_path" in code
    assert "fresh SAS session" in code
    assert "libname p17bak clear" in code


def test_baseline_not_approved_test_present():
    t = (SAS / "17_pecan_id_test.sas").read_text(encoding="utf-8")
    for tag in ("T15_NO_APPROVAL_FAILS", "T15_NO_APPROVAL_LINK_NOT_WRITTEN",
                "T15_NO_APPROVAL_NO_LINK_BACKUP", "T15_APPROVED_LINK_WRITTEN", "T16_GATE_MISSING_REGISTRY_FAILS"):
        assert tag in t, tag
    assert "%p17_k1_registry_link(" in t


def test_log_scans_use_prefix_comparison():
    for name in ("17_pecan_id_test.sas", "17_pecan_id_link_test.sas", "04_decisions_test.sas",
                 "16_name_map_ext_test.sas"):
        code = (SAS / name).read_text(encoding="utf-8")
        assert "substr(_infile_" not in code, name
        assert "upcase(_infile_) =: 'WARNING'" in code, name


def test_link_table_only_touched_by_proc_append():
    for n in PROGRAMS:
        code = _code(n)
        assert not re.search(r"\bdata\s+pdd\.pecan_id_dup_link\b", code, flags=re.I)
        assert not re.search(r"create\s+table\s+pdd\.pecan_id_dup_link\b", code, flags=re.I)


def test_no_pecan_id_arithmetic_in_17a():
    code = _code("17a_pecan_id_k1_seed.sas")
    assert not re.search(r"pecan_id\s*=\s*[^;]*[-+*/]", code, flags=re.I)


def test_17b_structure():
    code = _code("17b_pecan_id_k2.sas")
    assert not re.search(r"data\s+pdd\.pecan_id_registry\b", code, flags=re.I)
    d30 = code.index("%p17_pdd_d30_cases(")
    k2 = code.index("%p17_k2_append(")
    cm = code.index("%p17_casemap(")
    gate = code.index("%p17_gate_casemap(")
    assert d30 < k2 < cm < gate
    assert "base=&PDD_K2_BASE" in code and "%let PDD_K2_BASE = 1000000;" in code
    assert "%p17_gate_registry" in code[k2:]
    assert "pecan_id_k2_summary.csv" in code and "pecan_id_gate.csv" in code
    assert "PENDING DECISION" in code
    assert "PDD_EXPECT_SHARED" in code
    # expected count comes from the decisions csv, no default in code
    assert "new_overlap_decisions.csv" in code and "s22_s23" in code
    assert not re.search(r"let\s+PDD_EXPECT_SHARED\s*=\s*\d", code, flags=re.I)
    assert "142" not in code
    assert code.index("%p17b_read_expected;") < code.index("%p17_pdd_d30_cases(")
    csv = (ROOT / "docs" / "new_overlap_decisions.csv").read_text(encoding="utf-8").splitlines()
    assert csv[0].split(",")[1] == "expected_n_shared"
    assert any(r.startswith("s22_s23,") for r in csv[1:])
    t = (SAS / "17_pecan_id_test.sas").read_text(encoding="utf-8")
    for tag in ("T14_NO_APPROVAL_FAILS", "T14_NO_APPROVAL_REGISTRY_NOT_CREATED", "T14_APPROVAL_1_NO_FAILURE"):
        assert tag in t, tag


def test_17c_structure():
    code = _code("17c_pecan_id_summary.sas")
    assert "pecan_id_cases_per_patient.csv" in code
    assert "pdd.pecan_id_dup_link" in code
    assert "does not reconcile" in code
    assert not re.search(r"\b(data|out=)\s*pdd\.", code, flags=re.I)


def test_17c_top_codes_instead_of_cell_masking():
    code = _code("17c_pecan_id_summary.sas")
    assert "%p17_topcode(in=work.p17c_dist" in code
    assert "work.p17c_all" in code[code.index("proc export"):]
    # scope total dropped for a masked scope; small without-ID count hides the case totals
    assert "row_masked = 1" in code and "1 <= &_n_noid <= 10" in code
    m = _code("17_pecan_id_macros.sas")
    assert "%macro p17_topcode" in m
    t = (SAS / "17_pecan_id_test.sas").read_text(encoding="utf-8")
    for tag in ("T20_NO_ROW_WITH_1_TO_10_IDS", "T20_NO_N_CASES_DIVIDES_TO_SMALL_N_IDS",
                "T20_BUCKET_9_MERGED_UP_TO_2PLUS", "T20_SCOPE_UNDER_11_IDS_MASKED"):
        assert tag in t, tag
    assert "n_ids = 3; n_cases = 27" in t


def test_17b_k2_append_asserts_backup_before_zero_row_rerun():
    m = _code("17_pecan_id_macros.sas")
    body = m[m.index("%macro p17_k2_append"):m.index("%mend p17_k2_append")]
    # assertion sits before (outside) the 'new > 0' branch
    assert body.index("%p17_assert_backup_current") < body.index("p17_n_k2_new > 0 %then")
    t = (SAS / "17_pecan_id_test.sas").read_text(encoding="utf-8")
    assert "T19_NOOP_RERUN_FAILS_WHEN_REGISTRY_DIFFERS_FROM_BACKUP" in t


def test_no_hardcoded_expected_counts_in_code():
    for n in ("17a_pecan_id_k1_seed.sas", "17c_pecan_id_summary.sas", "17_pecan_id_macros.sas"):
        code = _code(n)
        for num in ("41150", "41,150", "1895", "1,895", "33031", "33,031", "31136", "31137"):
            assert num not in code, (n, num)
    b = _code("17b_pecan_id_k2.sas")
    assert "36348" in b  # orientation row only, isfail 0


def test_link_program_rules():
    prog = (SAS / "pecan_id_link.sas").read_text(encoding="utf-8")
    assert "written and tested, NOT RUN" in prog
    assert "PDD_LINK_MODE = DRYRUN" in prog
    macros = _code("17_pecan_id_link_macros.sas")
    assert 'PDD_APPROVE_NEW_BASELINE" ne "1"' in macros
    assert "pecan_id_registry_next" in macros
    assert macros.index("%p17_backup_table(ds=&reg, stem=pidreg_prelink)") < macros.index("data &reg;")
    t = (SAS / "17_pecan_id_link_test.sas").read_text(encoding="utf-8")
    for tag in ("T1_DRYRUN_REGISTRY_UNCHANGED", "T2_APPLY_WITHOUT_APPROVAL_FAILS", "T4_REAPPLY_LINKS_0",
                "T5_K2_MRN_TO_TWO_K1_MRNS_REFUSED", "T5_K1_MRN_NOT_IN_K1_REGISTRY_REFUSED",
                "T5_K2_MRN_NOT_IN_K2_REGISTRY_REFUSED", "TESTRESULT SUMMARY"):
        assert tag in t, tag


def test_wiring():
    s = (SAS / "99_run_all.sas").read_text(encoding="utf-8", errors="replace")
    cmd = (ROOT / "run_pipeline.cmd").read_text(encoding="utf-8", errors="replace")
    assert "%let _valid = 2 3 4 5 6 7 15 16 17 18;" in s
    a = s.index('%include "&sas_path.\\17a_pecan_id_k1_seed.sas";')
    b = s.index('%include "&sas_path.\\17b_pecan_id_k2.sas";')
    c = s.index('%include "&sas_path.\\17c_pecan_id_summary.sas";')
    end = s.index("%mend _run_phases;")
    assert s.index("16b_name_map_values_cov.sas") < a < b < c < end
    head = s.rfind("%if %_phase_in(17) %then %do;", 0, a)
    assert "%_check_pipeline_ok(phase=17);" in s[head - 80:head]
    assert "%_check_pipeline_ok(phase=17);" in s[a:b] and "%_check_pipeline_ok(phase=17);" in s[b:c]
    includes = " ".join(re.findall(r"%include[^;]*;", s))
    for banned in ("pecan_id_link", "probe_xwalk", "_test.sas"):
        assert banned not in includes
    assert "%let pdd_phases_run = 2 3 4;" in s
    assert 'if "%PDD_PHASES%"=="" set PDD_PHASES=2 3 4' in cmd
    assert 'findstr /i "\\<17\\>"' not in cmd


def _defs_with_includes(name, seen=None):
    seen = seen if seen is not None else set()
    if name in seen or not (SAS / name).exists():
        return set()
    seen.add(name)
    raw = re.sub(r"/\*.*?\*/", "", (SAS / name).read_text(encoding="utf-8"), flags=re.S)
    defs = {m.lower() for m in re.findall(r"%macro\s+(p1[67]_\w+)", raw, re.I)}
    for inc in re.findall(r'%include\s+"([^"]+)"', raw, re.I):
        defs |= _defs_with_includes(re.split(r"[\\/]", inc)[-1], seen)
    return defs


@pytest.mark.parametrize("name", ["17a_pecan_id_k1_seed.sas", "17b_pecan_id_k2.sas",
                                  "17c_pecan_id_summary.sas", "pecan_id_link.sas"])
def test_production_program_macros_are_defined_or_included(name):
    called = {m.lower() for m in re.findall(r"%(p1[67]_\w+)", _code(name), re.I)}
    missing = called - _defs_with_includes(name)
    assert not missing, f"{name} calls undefined macros: {sorted(missing)}"


def test_17c_includes_macros_forces_abort_and_fails_loudly():
    code = _code("17c_pecan_id_summary.sas")
    assert code.index("00_config.sas") < code.index("%let p17_fail_mode = ABORT;")
    assert '%include "&sas_path.\\17_pecan_id_macros.sas";' in code
    main = code[code.index("%macro p17c_main"):]
    for needle in ("SYSERR", "0 data rows", "does not equal registry rows"):
        assert needle in main
    assert main.index("does not equal registry rows") < main.index("proc export")
    assert main.index("0 data rows") < main.index("proc export")
