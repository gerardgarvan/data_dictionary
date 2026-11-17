"""Static checks for Phase 16 plan 16-02: sas/16_name_map_ext_macros.sas and its synthetic test."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MACROS = ROOT / "sas" / "16_name_map_ext_macros.sas"
TEST = ROOT / "sas" / "16_name_map_ext_test.sas"
PHASE4 = ROOT / "sas" / "04_name_map.sas"
LINT = ROOT / "tools" / "sas_lint.py"


def _text(path):
    return path.read_text(encoding="utf-8")


def _lint(path):
    return subprocess.run(
        [sys.executable, str(LINT), str(path)],
        capture_output=True, text=True, cwd=ROOT,
    )


def _strip_comments(src):
    return re.sub(r"/\*.*?\*/", "", src, flags=re.S)


def _macro_body(src, name):
    m = re.search(
        r"%macro\s+" + re.escape(name) + r"\s*\(.*?\)\s*;(.*?)%mend\s+" + re.escape(name) + r"\s*;",
        src, flags=re.S | re.I,
    )
    assert m, f"macro {name} not found"
    return m.group(1)


def _norm_lines(body):
    return [re.sub(r"\s+", " ", ln).strip() for ln in body.splitlines() if ln.strip()]


# ---- macros file ----------------------------------------------------------

def test_macros_lint_clean():
    r = _lint(MACROS)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in (r.stdout + r.stderr).lower()


def test_clean_name_parity():
    p16 = _norm_lines(_macro_body(_strip_comments(_text(MACROS)), "p16_clean_name"))
    p4 = _norm_lines(_macro_body(_strip_comments(_text(PHASE4)), "clean_name"))
    assert len(p4) == 5
    assert p16 == p4


def test_no_open_code():
    src = _strip_comments(_text(MACROS))
    rest = re.sub(r"%macro\s.*?%mend\s+\w+\s*;", "", src, flags=re.S | re.I)
    assert rest.strip() == "", rest


def test_macros_defined():
    src = _text(MACROS)
    for name in ("p16_clean_name", "p16_load_abbrev", "p16_shorten",
                 "p16_assign_names", "p16_stage2"):
        assert re.search(r"%macro\s+" + name + r"\b", src, flags=re.I), name


def test_no_frozen_writes():
    src = _text(MACROS)
    pat = r"(data|create\s+table|out=)\s*pdd\.name_map(_vars)?\b(?!_)"
    assert not re.search(pat, src, flags=re.I)
    assert "%include" not in src
    assert "call execute" not in src.lower()


# ---- synthetic test program -----------------------------------------------

def test_ext_test_lint_clean():
    r = _lint(TEST)
    assert r.returncode == 0, r.stdout + r.stderr


def test_ext_test_synthetic_only():
    src = _text(TEST)
    for bad in ("pdd.", "P:\\", "name_abbrev.csv", "%pdd_lib"):
        assert bad not in src, bad


def test_ext_test_cases():
    src = _text(TEST)
    for i in range(1, 9):
        assert re.search(rf"\bT{i}\b|T{i}_", src), f"T{i}"
    assert "TESTRESULT SUMMARY" in src
