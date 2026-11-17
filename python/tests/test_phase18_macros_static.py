"""Static checks for sas/18_combine_macros.sas and sas/18_combine_test.sas (no SAS here)."""
import re
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SAS = ROOT / "sas"
FILES = ["18_combine_macros.sas", "18_combine_test.sas"]
MACROS = [
    "p18_init", "p18_fail", "p18_qinit", "p18_qadd", "p18_flush_qc", "p18_load_types", "p18_psid_mode",
    "p18_srcmap", "p18_set_lengths", "p18_build_source", "p18_d30_merge", "p18_stack", "p18_attach_ids",
    "p18_order_cols", "p18_gate_overlap", "p18_gate_rows", "p18_gate_vars", "p18_gate_conv",
    "p18_backup_comb", "p18_nodata_flags", "p18_recon", "p18_mask", "p18_ro_start", "p18_ro_end",
    "p18_scan_no_mrn", "p18_export", "p18_stats", "p18_read_expected",
]


def _code(name):
    return re.sub(r"/\*.*?\*/", "", (SAS / name).read_text(encoding="utf-8"), flags=re.S)


def test_all_macros_defined():
    code = _code("18_combine_macros.sas")
    for m in MACROS:
        assert re.search(rf"%macro {m}\b", code), m


def test_macros_include_phase17_first():
    raw = (SAS / "18_combine_macros.sas").read_text(encoding="utf-8").lstrip()
    assert raw.startswith("%include " + chr(34) + "C:" + chr(92) + "data_dictionary" + chr(92) + "sas" + chr(92) + "17_pecan_id_macros.sas" + chr(34) + ";")


def test_every_include_target_exists():
    for f in SAS.glob("18*.sas"):
        for m in re.finditer(r'%include\s+"([^"]+)"', f.read_text(encoding="utf-8"), flags=re.I):
            tgt = m.group(1).replace("&sas_path.", str(SAS))
            if "&" in tgt:
                continue
            assert Path(tgt.replace("C:" + chr(92) + "data_dictionary", str(ROOT))).exists(), (f.name, tgt)


def test_no_question_question_in_proc_sql_and_no_case_column():
    code = _code("18_combine_macros.sas")
    for blk in re.findall(r"proc\s+sql.*?quit;", code, flags=re.S | re.I):
        assert "??" not in blk
        assert not re.search(r"\bas\s+case\b", blk, flags=re.I)


def test_point_steps_have_stop():
    code = _code("18_combine_macros.sas")
    assert "point=" not in code.lower()


def test_backup_stem_fits():
    code = _code("18_combine_macros.sas")
    stem = re.search(r"%macro p18_backup_comb\(ds=, stem=(\w+)\)", code).group(1)
    assert stem == "pcnrcmb" and len(stem) + 16 <= 32


def test_scan_has_no_fixed_token_length():
    code = _code("18_combine_macros.sas")
    blk = code[code.index("%macro p18_scan_no_mrn"):code.index("%mend p18_scan_no_mrn")]
    assert "&_minlen" in blk and "min(length(strip(ENCRYPTED_MRN)))" in blk
    assert not re.search(r"lengthn\(raw\)\s*>=\s*\d", blk)


def test_psid_mode_has_no_stop_for_empty():
    code = _code("18_combine_macros.sas")
    blk = code[code.index("%macro p18_psid_mode"):code.index("%mend p18_psid_mode")]
    assert "%let PDD_K2_PSID_MODE = NORM;" in blk
    assert "NORM or &PDD_K2_PSID_MODE = DELIVERED" in blk.replace("\n", " ").replace("      ", " ")


def test_no_value_leaks_in_macros():
    code = _code("18_combine_macros.sas").lower()
    assert "put _all_" not in code and "proc print" not in code and "raw_value" not in code


@pytest.mark.parametrize("name", FILES)
def test_sas_lint_zero_errors(name):
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "sas_lint.py"), str(SAS / name)],
                       capture_output=True, text=True, cwd=ROOT)
    assert "no errors" in r.stderr + r.stdout, (r.stdout + r.stderr)[-400:]


def test_test_file_header_and_anchored_scan():
    t = (SAS / "18_combine_test.sas").read_text(encoding="utf-8")
    assert "PENDING SAS RUN" in t and "TESTRESULT SUMMARY" in t
    assert "upcase(_infile_) =: 'WARNING'" in t and "upcase(_infile_) =: 'ERROR'" in t
    assert "substr(_infile_" not in t
