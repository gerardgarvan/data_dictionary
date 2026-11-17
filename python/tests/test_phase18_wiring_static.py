"""Static checks for the Phase 18 pipeline wiring (no SAS here)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS = (ROOT / "sas" / "99_run_all.sas").read_text(encoding="utf-8", errors="replace")
CMD = (ROOT / "run_pipeline.cmd").read_text(encoding="utf-8", errors="replace")
BS = chr(92)


def test_valid_tokens_include_18():
    assert "%let _valid = 2 3 4 5 6 7 15 16 17 18;" in SAS


def test_phase18_block_order_and_checks():
    a = SAS.index('%include "&sas_path.' + BS + '18a_comb_preflight.sas";')
    b = SAS.index('%include "&sas_path.' + BS + '18b_comb_build.sas";')
    c = SAS.index('%include "&sas_path.' + BS + '18c_comb_profile_qc.sas";')
    d = SAS.index('%include "&sas_path.' + BS + '18d_comb_scan.sas";')
    end = SAS.index("%mend _run_phases;")
    assert SAS.index("17c_pecan_id_summary.sas") < a < b < c < d < end
    assert "%_check_pipeline_ok(phase=18);" in SAS[a:b]
    assert "%_check_pipeline_ok(phase=18);" in SAS[b:c]
    assert "%_check_pipeline_ok(phase=18);" in SAS[c:d]


def test_synthetic_test_and_probes_not_in_pipeline():
    includes = " ".join(re.findall(r"%include[^;]*;", SAS))
    assert "18_combine_test" not in includes and "_test.sas" not in includes


def test_default_phase_list_unchanged():
    assert "%let pdd_phases_run = 2 3 4;" in SAS
    assert 'if "%PDD_PHASES%"=="" set PDD_PHASES=2 3 4' in CMD


def test_cmd_runs_writer_and_scans_18d_log():
    assert "write_dictionary_2018_2025.py" in CMD
    assert BS + "<18" + BS + ">" in CMD
    i = CMD.index("write_dictionary_2018_2025.py")
    assert i < CMD.index("18d_comb_scan.log") < CMD.index("Scan master log for ERROR lines")
    assert (ROOT / "python" / "scripts" / "write_dictionary_2018_2025.py").exists()


def test_no_control_characters_in_wired_files():
    files = [ROOT / "sas" / "99_run_all.sas", ROOT / "run_pipeline.cmd"] + list((ROOT / "sas").glob("18*.sas"))
    for f in files:
        for ch in f.read_text(encoding="utf-8", errors="replace"):
            assert ch in "\n\r\t" or ord(ch) >= 32, f.name
