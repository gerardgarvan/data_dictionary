"""Static checks of the Phase 16 wiring in 99_run_all.sas and run_pipeline.cmd."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS = (ROOT / "sas" / "99_run_all.sas").read_text(encoding="utf-8", errors="replace")
CMD = (ROOT / "run_pipeline.cmd").read_text(encoding="utf-8", errors="replace")


def test_valid_tokens():
    assert "%let _valid = 2 3 4 5 6 7 15 16 17 18;" in SAS


def test_phase16_block_order():
    c15 = SAS.index("15c_new_import.sas")
    a = SAS.index('%include "&sas_path.\\16a_name_map_ext.sas";')
    b = SAS.index('%include "&sas_path.\\16b_name_map_values_cov.sas";')
    end = SAS.index("%mend _run_phases;")
    assert c15 < a < b < end
    head = SAS.rfind("%if %_phase_in(16) %then %do;", 0, a)
    assert head != -1
    assert "%_check_pipeline_ok(phase=16);" in SAS[head - 80 : head]
    assert "%_check_pipeline_ok(phase=16);" in SAS[a:b]
    assert "16_name_map_ext_test.sas" not in SAS


def test_default_phases_unchanged():
    assert "%let pdd_phases_run = 2 3 4;" in SAS
    assert 'if "%PDD_PHASES%"=="" set PDD_PHASES=2 3 4' in CMD
    assert SAS.count("15a_new_source_guard.sas") == 1
    assert "write_new_source_qc.py" in CMD


def test_cmd_phase16_block():
    assert 'findstr /i "\\<16\\>"' in CMD
    assert "write_name_map_ext_review.py" in CMD
    p15 = CMD.index('findstr /i "\\<15\\>"')
    p16 = CMD.index('findstr /i "\\<16\\>"')
    scan = CMD.index("REM ---- Scan master log for ERROR lines ----")
    assert p15 < p16 < scan
    block = CMD[p16:scan]
    assert "--docs" in block
    assert "goto :fail" in block


def test_99_lint_clean():
    r = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(ROOT / "sas" / "99_run_all.sas")],
        capture_output=True,
        text=True,
    )
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in (r.stdout + r.stderr).lower()
