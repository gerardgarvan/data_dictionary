"""Static checks for Phase 15 plan 15-03: sas/15c_new_import.sas and the
exchange contract shared by 15a/15b/15c."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SAS15C = ROOT / "sas" / "15c_new_import.sas"
SCHEMA = ROOT / "docs" / "exchange_schema.csv"


def _sas():
    return SAS15C.read_text(encoding="utf-8")


def test_15c_lint_clean():
    r = subprocess.run([sys.executable, "tools/sas_lint.py", "sas/15c_new_import.sas"],
                       cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in r.stdout + r.stderr


def test_15c_dataset_names():
    t = _sas()
    assert "pdd.nsrc_" in t
    assert not re.search(r"pdd\.src_s2[123]", t)


def test_15c_norm_psid_call():
    assert re.search(r"%pdd_norm_psid\(in=work\.p15c_raw_", _sas())


def test_15c_encoding_from_spec():
    t = _sas()
    assert "encoding='&_enc'" in t
    assert not re.search(r"""encoding\s*=\s*['"]utf-8['"]""", t, re.I)


def test_15c_reconcile_constants_from_file_list():
    t = _sas()
    assert "expected_rows" in t and "new_source_files.csv" in t
    assert not re.search(r"10772|13029|12689", t)


def test_15c_forbidden():
    t = _sas()
    assert not re.search(r"%let\s+syscc\s*=\s*0", t, re.I)
    assert not re.search(r"call\s+execute", t, re.I)
    assert not re.search(r"proc\s+print\b", t, re.I)
    for line in t.splitlines():
        if re.match(r"\s*file\s", line, re.I):
            assert r"C:\data_dictionary\docs" not in line
            assert "&raw_master" not in line
