"""Static checks for Phase 15 plan 15-03: sas/15c_new_import.sas and the
exchange contract shared by 15a/15b/15c."""
import csv
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


def test_15c_gates_present():
    t = _sas()
    for s in ("PDD-D-29 item 3", "PDD-D-17", "PDD-D-25", "PAIRWISE_NEW",
              "OLD20_UNION", "SHARED_COL_CONFLICT", "NOT_APPLICABLE"):
        assert s in t, s
    assert "do not stack" in t.lower()
    assert t.count("PENDING DECISION") >= 3


def test_15c_exports_before_gates():
    t = _sas()
    for export, gate in (
        (r'outfile="&exchange_path.\new_one_to_one.csv"',
         "PENDING DECISION -- file(s)"),
        (r'outfile="&exchange_path.\new_overlap.csv"',
         "PENDING DECISION -- s21 shares normalized"),
        (r'outfile="&exchange_path.\new_overlap_conflicts.csv"',
         "PENDING DECISION -- s22-s23 overlap does not match"),
    ):
        assert export in t, export
        assert gate in t, gate
        assert t.index(export) < t.index(gate)


def test_15c_no_dedupe():
    assert not re.search(r"nodupkey", _sas(), re.I)


def test_exchange_contract():
    with SCHEMA.open(newline="", encoding="utf-8") as fh:
        in_schema = {row["file"] for row in csv.DictReader(fh)}
    sas_text = "".join(
        (ROOT / "sas" / n).read_text(encoding="utf-8")
        for n in ("15a_new_source_guard.sas", "15b_new_inventory_spec.sas",
                  "15c_new_import.sas"))
    for name in ("new_source_guard.csv", "header_inventory_new.csv",
                 "header_matrix_new.csv", "new_rowcounts.csv",
                 "new_one_to_one.csv", "new_overlap.csv", "new_overlap_conflicts.csv",
                 "new_type_changes.csv", "new_nonascii.csv"):
        assert name in in_schema, name
        assert name in sas_text, name


def test_15c_pdd_d30_gate_inputs():
    t = _sas()
    assert "new_overlap_decisions.csv" in t
    for token in ("expected_n_shared", "id_min", "id_max", "ENCRYPTED_MRN", "ENCRYPTED_ENCOUNTER",
                  "DECIDED", "COMPARED"):
        assert token in t, token


def test_fail_out_prints_error_before_restore_log():
    for name in ("15a_new_source_guard", "15b_new_inventory_spec", "15c_new_import"):
        text = (ROOT / "sas" / f"{name}.sas").read_text(encoding="utf-8")
        m = re.search(r"%macro fail_out\(msg=\);(.*?)%mend fail_out;", text, re.S)
        assert m, name
        body = m.group(1)
        assert body.index("%put ERROR:") < body.index("%restore_log") < body.index("%abort cancel"), name
