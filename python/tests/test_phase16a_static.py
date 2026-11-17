"""Static checks for Phase 16 plan 16-03: sas/16a_name_map_ext.sas (not run here, no SAS)."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "sas" / "16a_name_map_ext.sas"
LINT = ROOT / "tools" / "sas_lint.py"


def _text():
    return SRC.read_text(encoding="utf-8")


def _code():
    return re.sub(r"/\*.*?\*/", "", _text(), flags=re.S)


def test_16a_lint_clean():
    r = subprocess.run([sys.executable, str(LINT), str(SRC)], capture_output=True, text=True, cwd=ROOT)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in (r.stdout + r.stderr).lower()


def test_16a_frozen_read_only():
    code = _code()
    assert not re.search(
        r"(data|create\s+table|out=|delete)\s+pdd\.name_map(_vars)?\b(?!_)", code, flags=re.I
    )
    for blk in re.findall(r"proc\s+datasets.*?quit\s*;", code, flags=re.S | re.I):
        assert not re.search(r"\bname_map\s", blk, flags=re.I)
        assert not re.search(r"\bname_map_vars\s", blk, flags=re.I)


def test_16a_no_phase4_include():
    code = _code()
    assert not re.search(r"%include\s+\"[^\"]*04_name_map\.sas\"", code, flags=re.I)
    assert "04_name_map_macros.sas" in code
    assert "16_name_map_ext_macros.sas" in code


def test_16a_asserts():
    t = _text()
    assert "4795" in t and "1297" in t and "282" in t
    assert "1299" not in t


def test_16a_candidate_union():
    t = _text()
    for tok in ("EDIT_DISTANCE", "TRAILING_SUFFIX", "VARIANTS_FILE", "TYPE_CONFLICT_EXACT",
                "AMBIGUOUS", "NONPCNR_EXACT", "complev(", "new_source_header_variants.csv"):
        assert tok in t, tok


def test_16a_forbidden():
    t = _text()
    code = _code()
    assert not re.search(r"%let\s+syscc\s*=\s*0", code, flags=re.I)
    assert not re.search(r"call\s+execute", code, flags=re.I)
    assert not re.search(r"proc\s+print(?!to)", code, flags=re.I)
    assert not re.search(r"(?<![a-z])file\s+[\"'][^\"']*data_dictionary\\docs", code, flags=re.I)
    assert not re.search(r"(?<![a-z])file\s+[\"']&raw_master", code, flags=re.I)
    for blk in re.findall(r"proc\s+sql.*?quit\s*;", t, flags=re.S | re.I):
        assert "??" not in blk


def test_16a_exports():
    code = _code()
    for f in ("name_map_ext_new.csv", "name_map_vars_ext.csv", "name_map_ext_candidates.csv",
              "name_map_ext_collisions.csv", "name_map_ext_summary.csv"):
        assert f in code, f
        assert re.search(r"&exchange_path\.\\" + re.escape(f), code), f


def test_16a_pending_gate():
    code = _code()
    assert "PENDING_DECISION" in code
    assert "PENDING DECISION" in code
    assert "n_new_pending_decision" in code
    m = re.search(r"%put\s+NOTE:[^;]*PENDING DECISION --", code)
    assert m, "gate must be a %put NOTE"
    assert not re.search(r"%fail_out\([^;]*PENDING DECISION --", code)


def test_16a_exports_before_gate_note():
    t = _text()
    assert t.index("name_map_ext_candidates.csv") < t.index("PENDING DECISION --")
    assert t.rindex("proc export") < t.index("PENDING DECISION --")


def test_16a_frozen_compare():
    code = _code()
    assert "n_frozen_names_changed" in code
    assert re.search(r"%fail_out\(msg=%str\([^;]*frozen", code)


def test_16a_stage2():
    code = _code()
    assert re.search(r"%p16_stage2\(ds=(pdd\.name_map_ext|work\.)", code)
    assert re.search(r"%if\s+&p16_stage2_fail\s*>\s*0", code)


def test_16a_no_auto_merge():
    code = _code()
    assert not re.search(r"(?<![a-z])file\s+[^;]*name_map_decisions_new", code, flags=re.I)
    assert not re.search(r"outfile=[^;]*name_map_decisions_new", code, flags=re.I)


def test_16a_assign_names_called_twice_and_macro_order():
    code = _code()
    assert len(re.findall(r"%p16_assign_names\(", code)) >= 2
    # every p16a macro defined before its call (C13)
    for name in re.findall(r"%macro\s+(p16a_\w+)", code):
        d = code.index("%macro " + name)
        uses = [m.start() for m in re.finditer(r"%" + name + r"(?!\w)", code)]
        uses = [u for u in uses if not code[max(0, u - 7):u].lower().endswith(("%macro ", " %mend "))
                and not code[max(0, u - 6):u].lower().endswith("%mend ")]
        assert uses and min(uses) > d, name
