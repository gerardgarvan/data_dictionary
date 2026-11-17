"""Static checks for sas/18a_comb_preflight.sas (no SAS here)."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
NAME = "18a_comb_preflight.sas"


def _code():
    return re.sub(r"/\*.*?\*/", "", (SAS / NAME).read_text(encoding="utf-8"), flags=re.S)


def test_abort_forced_right_after_config_include():
    code = _code()
    i = code.index("00_config.sas")
    j = code.index("%let p18_fail_mode = ABORT;")
    assert i < j < code.index("%include " + chr(34) + "&sas_path." + chr(92) + "18_combine_macros.sas")


def test_macros_included_and_exist():
    code = _code()
    assert "18_combine_macros.sas" in code
    assert (SAS / "18_combine_macros.sas").exists()


def test_writes_only_qc_via_staging():
    code = _code()
    assert not re.search(r"create\s+table\s+pdd\.", code, flags=re.I)
    assert not re.search(r"\bdata\s+pdd\.", code, flags=re.I)
    assert not re.search(r"proc\s+append[^;]*pdd\.", code, flags=re.I)
    assert "pcnr_2018_2025" not in code and "&comb_ds" not in code
    assert code.count("%p18_flush_qc;") == 1
    assert "pdd.qc_comb_pre" in code


def test_no_raw_value_and_no_print():
    code = _code().lower()
    assert "raw_value" not in code and "put _all_" not in code
    assert not re.search(r"proc\s+print\b", code)


def test_expected_shared_read_from_csv_not_constant():
    code = _code()
    assert "%p18_read_expected(file=C:" in code
    assert not re.search(r"%let\s+\w+\s*=\s*142\b", code)
    assert "142" not in code


def test_checks_are_stops_with_pending_decision_text():
    code = _code()
    for frag in ("PENDING DECISION - decided type", "neither NORM_PSID nor a mapped PCNR_ name",
                 "no source column", "%p18_gate_conv", "ASA_ANESTH_RECORD", "CPT1_CLASS"):
        assert frag in code, frag


def test_sas_lint_zero_errors():
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(SAS / NAME)],
                       capture_output=True, text=True, cwd=ROOT)
    assert "no errors" in r.stdout + r.stderr or "clean" in r.stdout + r.stderr
