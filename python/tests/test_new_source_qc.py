"""Tests for the Phase 15 new-source QC writer (module and script). Synthetic data only."""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

import pytest
from openpyxl import load_workbook

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from pdd import new_source_qc_workbook as m  # noqa: E402
from write_new_source_qc import main  # noqa: E402

HASH = "a" * 64

FILES = {
    "new_source_guard.csv": (
        ["s_code", "filename", "sha256", "baseline_status"],
        [["s21", "fake_name_2023.csv", HASH, "MATCH"], ["s22", "fake_name_2024.csv", HASH, "PROPOSED"]],
    ),
    "header_inventory_new.csv": (
        ["s_code", "col_order", "col_name", "col_type", "col_len", "original_header", "original_header_trunc"],
        [["s21", "1", "colA", "char", "8", "Col A", "0"]],
    ),
    "header_matrix_new.csv": (
        ["col_name", "src_s21", "src_s22", "src_s23"],
        [["colA", "Y", "Y", ""]],
    ),
    "new_rowcounts.csv": (
        ["s_code", "filename", "src_encoding", "expected_rows", "raw_data_lines", "n_imported", "status"],
        [["s21", "fake_name_2023.csv", "utf-8", "10772", "10772", "10772", "MATCH"]],
    ),
    "new_one_to_one.csv": (
        [
            "s_code", "n_rows", "n_distinct_psid", "n_blank_psid", "n_distinct_mrn",
            "n_distinct_enc", "n_enc_multi_case", "status",
        ],
        [["s21", "10772", "10772", "0", "10772", "10772", "3", "PASS"]],
    ),
    "new_overlap.csv": (
        ["check_type", "file_a", "file_b", "n_shared", "status"],
        [
            ["PAIRWISE_NEW", "s21", "s22", "3", "SHARED"],
            ["PAIRWISE_NEW", "s21", "s23", "0", "ZERO"],
            ["OLD20_UNION", "s21", "old20", "0", "ZERO"],
        ],
    ),
    "new_type_changes.csv": (
        [
            "norm_key", "new_s_code", "new_sas_name", "new_type", "new_length",
            "old_s_code", "old_sas_name", "old_type", "old_length",
        ],
        [["k", "s21", "x", "char", "8", "s01", "x", "num", "8"]],
    ),
    "new_nonascii.csv": (
        ["s_code", "sas_name", "n_nonascii_cells"],
        [["s21", "colA", "10"], ["s22", "colB", "11"]],
    ),
}

VARIANTS_HEADER = [
    "file_codes", "new_header", "new_type", "older_header", "older_source_codes",
    "older_type", "variant_kind", "note", "status",
]


def _write_csv(path: Path, headers: list[str], rows: list[list[str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(headers)
        w.writerows(rows)


def _schema_rows() -> list[list[str]]:
    out = []
    for fname, (headers, _) in FILES.items():
        for h in headers:
            out.append([fname, h, "str", "Y"])
    return out


@pytest.fixture
def dirs(tmp_path: Path) -> dict[str, Path]:
    ex, qc, logs, docs = (tmp_path / n for n in ("ex", "qc", "logs", "docs"))
    for fname, (h, r) in FILES.items():
        _write_csv(ex / fname, h, r)
    _write_csv(docs / "exchange_schema.csv", ["file", "column", "type", "required"], _schema_rows())
    _write_csv(docs / "new_source_header_variants.csv", VARIANTS_HEADER, [["s21", "h", "c", "o", "s01", "c", "CASE", "", "OK"]])
    return {"ex": ex, "qc": qc, "logs": logs, "docs": docs}


def _argv(d: dict[str, Path], *extra: str) -> list[str]:
    return [
        "--exchange", str(d["ex"]), "--qc", str(d["qc"]),
        "--logs", str(d["logs"]), "--docs", str(d["docs"]), *extra,
    ]


# ---- module ----

def test_sheet_order() -> None:
    assert m.SHEET_ORDER == [
        "KEY", "GUARD", "ROWCOUNTS", "ONE_TO_ONE", "OVERLAP", "HEADER_MATRIX",
        "HEADER_INVENTORY", "TYPE_CHANGES", "VARIANTS", "NONASCII",
    ]
    assert m.SHEET_SOURCES["VARIANTS"] == "new_source_header_variants.csv"
    assert m.SHEET_SOURCES["OVERLAP"] == "new_overlap.csv"


def test_required_columns_match_contract() -> None:
    assert m.REQUIRED_COLUMNS["OVERLAP"] == ["check_type", "file_a", "file_b", "n_shared", "status"]


def test_assert_input_names_missing() -> None:
    with pytest.raises(ValueError, match="n_shared"):
        m.assert_input("OVERLAP", ["check_type", "file_a", "file_b", "status"], [])


@pytest.mark.parametrize(
    "val,exp",
    [("0", "0"), ("1", "<11"), ("10", "<11"), ("11", "11"), ("13029", "13029"), ("", ""), ("abc", "abc"), (5, "<11")],
)
def test_mask_small_count(val, exp) -> None:
    assert m.mask_small_count(val) == exp


def _sheets() -> dict:
    out = {}
    for fname, (h, r) in FILES.items():
        sheet = next(s for s, f in m.SHEET_SOURCES.items() if f == fname)
        out[sheet] = (h, [dict(zip(h, row)) for row in r])
    return out


def test_privacy_safe_summary() -> None:
    lines = m.privacy_safe_summary(_sheets())
    text = "\n".join(lines)
    assert "OVERLAP PAIRWISE_NEW s21 s22 n_shared=<11 status=SHARED" in text
    assert "ONE_TO_ONE s21 n_rows=10772 n_distinct_psid=10772" in text
    assert "status=PASS" in text
    assert HASH not in text and "fake_name" not in text and "colA" not in text
    assert not re.search(r"=\b([1-9]|10)\b", text)
    assert "GATE PDD-D-29 item 3: STOP (PENDING DECISION)" in text
    assert "GATE OLD20_UNION: PASS" in text
    assert "GATE 1:1 (NEW-04): PASS" in text


def test_gate_pass_when_all_zero() -> None:
    s = _sheets()
    s["OVERLAP"] = (s["OVERLAP"][0], [r for r in s["OVERLAP"][1] if r["n_shared"] == "0"])
    assert "GATE PDD-D-29 item 3: PASS" in m.privacy_safe_summary(s)


def test_write_workbook_order_fill_nodata(tmp_path: Path) -> None:
    out = tmp_path / "w.xlsx"
    h, r = FILES["new_source_guard.csv"]
    m.write_workbook({"GUARD": (h, r)}, out)
    wb = load_workbook(out)
    assert wb.sheetnames == m.SHEET_ORDER
    assert wb["GUARD"]["A1"].fill.fgColor.rgb.endswith("0021A5")
    assert wb["OVERLAP"]["A1"].value == "(no data)"
    assert wb["KEY"]["A1"].fill.fgColor.rgb.endswith("0021A5")
    m.verify_workbook(out, {"GUARD": 2})
    with pytest.raises(ValueError):
        m.verify_workbook(out, {"GUARD": 5})


def test_schema_rows_appended() -> None:
    schema = Path(__file__).resolve().parents[2] / "docs" / "exchange_schema.csv"
    rows = list(csv.DictReader(schema.open(encoding="utf-8-sig", newline="")))
    got = {(r["file"], r["column"]): r for r in rows}
    for fname, cols in m.CONTRACT.items():
        for c in cols:
            assert (fname, c) in got and got[(fname, c)]["required"] == "Y"
    assert got[("new_overlap.csv", "n_shared")]["type"] == "int"


# ---- script ----

def test_main_full(dirs) -> None:
    assert main(_argv(dirs)) == 0
    assert (dirs["qc"] / "new_source_intake.xlsx").exists()
    summary = (dirs["logs"] / "new_source_qc_summary.txt").read_text(encoding="utf-8")
    assert "<11" in summary
    assert not re.search(r"=\b([1-9]|10)\b", summary)


def test_main_missing_file(dirs) -> None:
    (dirs["ex"] / "new_overlap.csv").unlink()
    assert main(_argv(dirs)) == 1
    assert "new_overlap.csv" in (dirs["logs"] / "write_new_source_qc.log").read_text(encoding="utf-8")


def test_main_partial(dirs) -> None:
    for f in list(dirs["ex"].iterdir()):
        if f.name != "new_source_guard.csv":
            f.unlink()
    assert main(_argv(dirs, "--allow-partial")) == 0
    wb = load_workbook(dirs["qc"] / "new_source_intake.xlsx")
    assert wb["OVERLAP"]["A1"].value == "(no data)"


def test_main_missing_column(dirs) -> None:
    _write_csv(dirs["ex"] / "new_overlap.csv", ["check_type", "file_a", "file_b", "status"], [["PAIRWISE_NEW", "s21", "s22", "ZERO"]])
    assert main(_argv(dirs)) == 1
