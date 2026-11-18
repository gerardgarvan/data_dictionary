"""Static checks for the Phase 19 Wave 1 SAS files and config (no SAS here)."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
MACROS = [
    "p19_init", "p19_fail", "p19_qinit", "p19_qadd", "p19_flush_qc", "p19_dump_qc", "p19_path_guard",
    "p19_need_decision", "p19_mask_ds", "p19_dataset_facts", "p19_probe", "p19_keys", "p19_probe_report",
    "p19_probe_gate_inputs", "p19_limits", "p19_freegb_parse", "p19_freegb", "p19_allowlist",
    "p19_scan_closed", "p19_bench_sas",
]
XLS_VARS = [
    "ROUTE", "NODATA", "ORDER", "DATES", "NUMTEXT", "SPECIAL", "SHEETS", "COMPANION", "KEYS", "APPROVE", "DICT",
]


def _code(name):
    return re.sub(r"/\*.*?\*/", "", (SAS / name).read_text(encoding="utf-8"), flags=re.S)


def test_all_macros_defined():
    code = _code("19_xlsx_macros.sas")
    for m in MACROS:
        assert re.search(rf"%macro {m}\b", code), m


def test_config_decisions_decided_2026_11_18():
    code = _code("00_config.sas")
    want = {
        "ROUTE": "STAGE_CSV", "NODATA": "INCLUDE", "ORDER": "DICT", "DATES": "SERIAL",
        "NUMTEXT": "TEXT", "SPECIAL": "BLANK", "SHEETS": "ONE", "COMPANION": "NONE",
        "KEYS": "K3", "DICT": "NO",
    }
    for v, val in want.items():
        assert re.search(rf"%_xls_def\(name=PDD_XLS_{v}, default={val}\);", code), v
    # PDD-D-44: sign-off is run-time only, never a config default
    assert re.search(r"%_xls_def\(name=PDD_XLS_APPROVE\);", code)
    assert re.search(r"%_xls_def\(name=PDD_XLS_MIN_FREE_GB, default=15\);", code)
    assert len(re.findall(r"%_xls_def\(name=PDD_XLS_\w+, default=", code)) == 11


def test_keyset_macro():
    code = _code("19_xlsx_macros.sas")
    m = re.search(r"%macro p19_keyset\(.*?%mend p19_keyset;", code, flags=re.S)
    assert m
    body = m.group(0)
    assert "PECAN_ID PRECEDE_STUDY_ID KEY_ERA;" in body
    assert "NORM_PSID" not in body.replace("NORM_PSID is never", "")


def test_config_paths_under_out_root():
    code = _code("00_config.sas")
    assert "%let xls_stage_path = &out_root." + chr(92) + "stage;" in code
    assert re.search(r"%let xls_final\s+= PCNR_Master_Data_Nov_2026\.xlsx;", code)


def test_preflight_is_abort_and_read_only():
    code = _code("19a_xlsx_preflight.sas")
    assert "%let p19_fail_mode = ABORT;" in code
    assert not re.search(r"\b(data|create table)\s+pdd\.", code, flags=re.I)
    assert "pdd.pcnr_2018_2025" in code


def test_linter_clean():
    for f in ["00_config.sas", "19_xlsx_macros.sas", "19a_xlsx_preflight.sas", "19_xlsx_test.sas"]:
        r = subprocess.run([sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(SAS / f)],
                           capture_output=True, text=True, cwd=ROOT)
        assert r.returncode == 0, r.stdout


def test_name_exceptions_file_and_allowlist_contract():
    import csv
    rows = list(csv.DictReader((ROOT / "docs" / "xlsx_name_exceptions.csv").open(encoding="utf-8")))
    assert [r["colname"] for r in rows] == ["PCNR_Age_at_Encounter"]
    assert set(rows[0]) == {"colname", "reason", "reviewed_by", "reviewed_date"}
    assert rows[0]["reviewed_by"] == "Gerard" and rows[0]["reviewed_date"] == "2026-11-18"
    code = _code("19_xlsx_macros.sas")
    for item in ("columns_name_flag_excepted", "columns_name_flag_unexcepted"):
        assert item in code
    assert "fileexist(&exc)" in code
    assert re.search(r"%let docs_path\s+=", _code("00_config.sas"))
    test = _code("19_xlsx_test.sas")
    for case in ("T6_FLAGGED_EXCEPTED_MAPPED_PASSES", "T6_EXCEPTED_KEY_COLUMN_FAILS",
                 "T6_FLAGGED_NOT_EXCEPTED_FAILS", "T6_STALE_EXCEPTION_FAILS"):
        assert case in test
