"""Static checks for sas/18c_comb_profile_qc.sas and sas/18d_comb_scan.sas (no SAS here)."""
import re
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
NAMES = ["18c_comb_profile_qc.sas", "18d_comb_scan.sas"]


def _code(name):
    return re.sub(r"/\*.*?\*/", "", (SAS / name).read_text(encoding="utf-8"), flags=re.S)


@pytest.mark.parametrize("name", NAMES)
def test_abort_forced_and_includes_exist(name):
    code = _code(name)
    assert code.index("00_config.sas") < code.index("%let p18_fail_mode = ABORT;")
    assert "18_combine_macros.sas" in code and (SAS / "18_combine_macros.sas").exists()
    assert not re.search(r"proc\s+print\b", code, flags=re.I)
    assert not re.search(r"(data|create table|modify)\s*pdd\.pecan_id", code, flags=re.I)


def test_18c_never_scans_and_flushes_once():
    code = _code("18c_comb_profile_qc.sas")
    assert "%p18_scan_no_mrn(" not in code
    assert code.count("%p18_flush_qc;") == 1
    assert "(06_profile_macros.sas)" not in code and "06_profile_macros.sas" in code
    assert "family=PCNR_2018_2025" in code


def test_18c_does_not_write_v1_outputs():
    code = _code("18c_comb_profile_qc.sas")
    assert "profile_PCNR.csv" not in code and "profile_PCNR_manifest.csv" not in code
    assert not re.search(r"pdd\.prf_pcnr\s*;", code, flags=re.I)
    assert "comb_key_facts.csv" in code and "comb_recon.csv" in code and "comb_nodata.csv" in code


def test_18d_scans_closed_files_and_never_its_own_log():
    code = _code("18d_comb_scan.sas")
    assert "%p18_scan_no_mrn(" in code
    files = code[code.index("%let p18_scan_files = &p18_scan_files."):]
    assert "18d_comb_scan.log" not in files.split("%p18_scan_no_mrn(")[0].replace(
        'log="&logs_path.' + chr(92) + '18d_comb_scan.log"', "")
    assert "profile_PCNR_2018_2025.csv" not in files.split("%p18_scan_no_mrn(")[0]
    assert "comb_scan.csv" in code and code.count("%p18_flush_qc;") == 1


@pytest.mark.parametrize("name", NAMES)
def test_sas_lint_zero_errors(name):
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(SAS / name)],
                       capture_output=True, text=True, cwd=ROOT)
    assert "no errors" in r.stdout + r.stderr or "clean" in r.stdout + r.stderr
