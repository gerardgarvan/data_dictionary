"""Static checks for Phase 16 plan 16-04: sas/16b_name_map_values_cov.sas."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROG = ROOT / "sas" / "16b_name_map_values_cov.sas"
LINT = ROOT / "tools" / "sas_lint.py"


def _text():
    return PROG.read_text(encoding="utf-8")


def _strip_comments(src):
    return re.sub(r"/\*.*?\*/", "", src, flags=re.S)


# ---- Task 1: setup, preconditions, value distributions ---------------------

def test_16b_lint_clean():
    r = subprocess.run(
        [sys.executable, str(LINT), str(PROG)],
        capture_output=True, text=True, cwd=ROOT,
    )
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in (r.stdout + r.stderr).lower()


def test_16b_read_only():
    src = _strip_comments(_text())
    pat = (
        r"(data|create\s+table|out=|delete|base=)\s*"
        r"pdd\.(name_map|name_map_ext|name_map_vars_ext|qc_map_ext_candidates"
        r"|src_s\d\d|nsrc_s2[123])\b"
    )
    assert not re.search(pat, src, flags=re.I)


def test_16b_values_cap():
    src = _text()
    assert re.search(r"<=\s*30|\ble\s+30\b", src, flags=re.I)
    for rt in ("LEVEL", "DISTINCT", "N_MISSING", "MINLEN", "MAXLEN"):
        assert rt in src, rt
    assert "nliteral" in src


def test_16b_no_value_logging():
    src = _strip_comments(_text())
    for stmt in re.findall(r"(?<![%\w])put\s[^;]*;", src, flags=re.I):
        assert not re.search(r"\blevel\b", stmt, flags=re.I), stmt
    assert not re.search(r"proc\s+print\b", src, flags=re.I)


def test_16b_forbidden():
    src = _text()
    assert "call execute" not in src.lower()
    assert not re.search(r"%let\s+syscc\s*=\s*0", src, flags=re.I)
    assert not re.search(r"\b20(1[89]|2[0-5])\b", src)
    for sql in re.findall(r"proc\s+sql.*?quit\s*;", src, flags=re.S | re.I):
        assert "??" not in sql
    assert "name_map_ext_values.csv" in src
