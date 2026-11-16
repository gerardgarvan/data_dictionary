"""Static checks of the Phase 15 wiring in 99_run_all.sas and run_pipeline.cmd."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS = (ROOT / "sas" / "99_run_all.sas").read_text(encoding="utf-8", errors="replace")
CMD = (ROOT / "run_pipeline.cmd").read_text(encoding="utf-8", errors="replace")


def test_valid_tokens():
    assert "%let _valid = 2 3 4 5 6 7 15;" in SAS


def test_phase15_block_order():
    p7 = SAS.index("07_build_profile.sas")
    a = SAS.index('%include "&sas_path.\\15a_new_source_guard.sas";')
    b = SAS.index('%include "&sas_path.\\15b_new_inventory_spec.sas";')
    c = SAS.index('%include "&sas_path.\\15c_new_import.sas";')
    end = SAS.index("%mend _run_phases;")
    assert p7 < a < b < c < end
    head = SAS.rfind("%if %_phase_in(15) %then %do;", 0, a)
    assert head != -1
    assert "%_check_pipeline_ok(phase=15);" in SAS[head - 80 : head]


def test_default_phases_unchanged():
    assert "%let pdd_phases_run = 2 3 4;" in SAS
    assert 'if "%PDD_PHASES%"=="" set PDD_PHASES=2 3 4' in CMD


def test_cmd_phase15_block():
    assert 'findstr /i "\\<15\\>"' in CMD
    assert "write_new_source_qc.py" in CMD
    assert "--docs" in CMD
    p7 = CMD.index('findstr /i "\\<7\\>"')
    p15 = CMD.index('findstr /i "\\<15\\>"')
    scan = CMD.index("REM ---- Scan master log for ERROR lines ----")
    assert p7 < p15 < scan


def test_99_lint_clean():
    r = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(ROOT / "sas" / "99_run_all.sas")],
        capture_output=True,
        text=True,
    )
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in (r.stdout + r.stderr).lower()
