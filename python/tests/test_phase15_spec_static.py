"""Static checks for Phase 15 plan 15-02: sas/15b_new_inventory_spec.sas
and (once Gerard commits it) docs/import_spec_new_generated.csv."""
import csv
import re
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SAS15B = ROOT / "sas" / "15b_new_inventory_spec.sas"
SPEC = ROOT / "docs" / "import_spec_new_generated.csv"


def _sas():
    return SAS15B.read_text(encoding="utf-8")


def test_15b_lint_clean():
    r = subprocess.run([sys.executable, "tools/sas_lint.py", "sas/15b_new_inventory_spec.sas"],
                       cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "no errors" in r.stdout + r.stderr


def test_15b_inventory_outputs():
    t = _sas()
    for s in ("pdd.header_inventory_new", "pdd.header_matrix_new",
              "header_matrix_new.csv", "header_inventory_new.csv",
              "proc transpose", "prefix=src_", "source_guard_baseline_new.csv",
              "new_source_files.csv"):
        assert s in t, s


def test_15b_encoding_parameterised():
    t = _sas()
    assert not re.search(r"""encoding\s*=\s*['"]utf-8['"]""", t, re.I)
    assert len(re.findall(r'encoding="&', t)) >= 3


def test_15b_no_old_targets():
    t = _sas()
    assert not re.search(r'file\s+"[^"]*import_spec_generated\.csv"', t, re.I)
    for line in t.splitlines():
        if re.match(r"\s*file\s", line, re.I):
            assert "source_guard_baseline" not in line
    assert not re.search(r"data\s+pdd\.header_inventory\s*[;(]", t, re.I)
    assert not re.search(r"%let\s+syscc\s*=\s*0", t, re.I)
    assert not re.search(r"call\s+execute", t, re.I)
    assert not re.search(r"proc\s+print\b", t, re.I)


def test_15b_spec_header_literal():
    t = _sas()
    assert ("file_code,col_order,src_name,orig_col_name,sas_name,sas_type,"
            "length,informat,format,notes,src_encoding") in t
    assert r"C:\data_dictionary\docs\import_spec_new_generated.csv" in t


def test_15b_spec_asserts():
    t = _sas()
    for s in ("raw_char_lengths_new", "PRECEDESTUDYID", "ENCRYPTED_", "best32.",
              "ne 94", "ne 2"):
        assert s in t, s


def test_generated_spec_if_present():
    if not SPEC.exists():
        pytest.skip("docs/import_spec_new_generated.csv not yet committed (PENDING SAS RUN)")
    with open(SPEC, encoding="utf-8-sig", newline="") as fh:
        rows = [{k.strip(): (v or "").strip() for k, v in r.items()}
                for r in csv.DictReader(fh)]
    assert len(rows) == 282
    enc = {"s21": "utf-8", "s22": "wlatin1", "s23": "wlatin1"}
    for fc, e in enc.items():
        sub = [r for r in rows if r["file_code"] == fc]
        assert len(sub) == 94, fc
        assert all(r["src_encoding"] == e for r in sub), fc
        names = [r["sas_name"].lower() for r in sub]
        assert len(names) == len(set(names)), fc
        assert all(len(n) <= 32 for n in names), fc
        pid = [r for r in sub if r["orig_col_name"] == "PRECEDE Study ID"]
        assert len(pid) == 1 and pid[0]["sas_type"] == "C", fc
        for r in sub:
            if r["orig_col_name"].upper().startswith("ENCRYPTED_"):
                assert r["sas_type"] == "C"
