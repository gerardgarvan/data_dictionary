"""Static checks for sas/18b_comb_build.sas (no SAS here)."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
NAME = "18b_comb_build.sas"


def _code():
    return re.sub(r"/\*.*?\*/", "", (SAS / NAME).read_text(encoding="utf-8"), flags=re.S)


def test_abort_forced_after_include():
    code = _code()
    assert code.index("00_config.sas") < code.index("%let p18_fail_mode = ABORT;")


def test_write_after_gates_and_backup_before_write():
    code = _code()
    gate_vars = code.index("%p18_gate_vars(")
    gate_rows = code.rindex("%p18_gate_rows(")
    backup = code.index("%p18_backup_comb(")
    write = code.index("data pdd.&comb_ds;")
    assert code.index("%p18_gate_conv(") < code.index("%p18_gate_overlap(") < gate_vars < gate_rows < backup < write
    assert code.count("data pdd.&comb_ds;") == 1


def test_no_write_to_pecan_id_tables_or_v1_outputs():
    code = _code()
    assert not re.search(r"(data|create table|proc append[^;]*base=|modify)\s*pdd\.pecan_id", code, flags=re.I)
    assert "profile_PCNR.csv" not in code and "pdd.prf_pcnr;" not in code
    assert "pdd.pcnr;" not in code.replace("pdd.pcnr ", "pdd.pcnr_")  # pdd.pcnr is only read


def test_no_value_leaks_and_no_constants():
    code = _code()
    low = code.lower()
    assert "put _all_" not in low and not re.search(r"proc\s+print\b", low)
    for lit in ("77498", "41150", "142"):
        assert not re.search(rf"(=|\bne\b|\beq\b)\s*{lit}\b", code), lit


def test_psid_mode_validated_not_defaulted_here():
    code = _code()
    assert "%p18_psid_mode;" in code
    assert not re.search(r"%let\s+PDD_K2_PSID_MODE\s*=", code)
    macros = (SAS / "18_combine_macros.sas").read_text(encoding="utf-8")
    assert "DELIVERED" in macros and "BLANK" in macros and "NORM" in macros


def test_macros_include_exists_and_lint():
    assert "18_combine_macros.sas" in _code() and (SAS / "18_combine_macros.sas").exists()
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(SAS / NAME)],
                       capture_output=True, text=True, cwd=ROOT)
    assert "no errors" in r.stdout + r.stderr or "clean" in r.stdout + r.stderr


def test_member_names_fit():
    code = (ROOT / "sas" / "00_config.sas").read_text(encoding="utf-8")
    stem = re.search(r"%let comb_backup_stem\s*=\s*(\w+);", code).group(1)
    assert len(stem) + 16 <= 32
    for m in re.findall(r"pdd\.(qc_comb_\w+)", _code()):
        assert len(m) <= 32
