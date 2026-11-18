"""Synthetic stage builder for the Phase 19 writer and verifier tests (no real data)."""
from __future__ import annotations

import csv
from pathlib import Path

HEADER = [
    "PECAN_ID", "PRECEDE_STUDY_ID", "KEY_ERA", "PCNR_Text", "PCNR_Num", "PCNR_Date",
    "PCNR_Death_Days_After_Surgery", "PCNR_Empty",
]
KINDS = ["N", "C", "C", "C", "N", "DATE", "C", "C"]
SENT = "SENTINEL_CELL_VALUE_QX7"
ROWS = [
    ["1", "P001", "K1", "plain " + SENT, "5", "45000", "30", ""],
    ["2", "P002", "K1", "=SUM(1)", "2.5", "", "#Error", ""],
    ["3", "007", "K2", "#N/A", "", "45001.5", "", ""],
    ["1000001", "P004", "K2", 'multi\nline, "quoted"', "1e3", "", "12.5", ""],
    ["1000002", "P005", "K2", "x" * 40, "0", "", "abc", ""],
]


def write_stage(base: Path, rows=None, header=None, kinds=None) -> dict[str, Path]:
    rows = ROWS if rows is None else rows
    header = header or HEADER
    kinds = kinds or KINDS
    stage, exch, docs = base / "stage", base / "exchange", base / "docs"
    for d in (stage, exch, docs, base / "qc", base / "out", base / "backup"):
        d.mkdir(parents=True, exist_ok=True)
    with (stage / "xlsx_data.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, lineterminator="\r\n")
        w.writerow(header)
        w.writerows(rows)
    with (stage / "xlsx_schema.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["col_index", "name", "sas_type", "excel_kind"])
        for i, (n, k) in enumerate(zip(header, kinds), 1):
            w.writerow([i, n, "N" if k == "N" else "C", k])
    nb = [sum(1 for r in rows if r[i] != "") for i in range(len(header))]
    with (stage / "xlsx_expected.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["kind", "variable", "n_rows", "n_nonblank", "n_special"])
        w.writerow(["ROWS", "", len(rows), "", ""])
        for n, c in zip(header, nb):
            w.writerow(["COL", n, "", c, 0])
        for i in range(1, len(rows) + 1):
            w.writerow(["SAMPLE", "", i, "", ""])
    with (exch / "comb_key_facts.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["item", "value"])
        w.writerows([["ROWS", str(len(rows))], ["K1_ROWS", "<11"], ["K2_ROWS", "<11"],
                     ["DISTINCT_PECAN_ID_K1", "<11"], ["DISTINCT_PECAN_ID_K2", "<11"],
                     ["PDD_K2_PSID_MODE", "SAME"]])
    with (exch / "comb_recon.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["pcnr_name", "n_nonmiss_comb_all", "n_special_comb_all", "explained"])
        for n, c in zip(header, nb):
            if n.startswith("PCNR_"):
                w.writerow([n[5:], "<11" if 1 <= c <= 10 else c, 0, "Y"])
    with (exch / "comb_nodata.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["pcnr_name", "n_nonmiss", "coverage_status", "reconciled"])
        w.writerow(["Empty", 0, "NO_DATA", "Y"])
    (docs / "pecan_id_dictionary_text.csv").write_text(
        "item,text\nPECAN_ID dictionary row,Patient key.\n", encoding="utf-8")
    (docs / "combined_type_decisions.csv").write_text(
        "pcnr_name,combined_type,note_kind,note_text,decision_ref\n"
        "Age,N,TYPE,Numeric in combined layer.,PDD-D-31(1)\n", encoding="utf-8")
    (docs / "xlsx_name_exceptions.csv").write_text(
        "colname,reason,reviewed_by,reviewed_date\n", encoding="utf-8")
    return {"stage": stage, "exchange": exch, "docs": docs, "qc": base / "qc",
            "out": base / "out", "backup": base / "backup"}


def run_writer(base: Path, p: dict[str, Path], **kw):
    from pdd import master_workbook as mw
    args = dict(stage_dir=p["stage"], exchange_dir=p["exchange"], docs_dir=p["docs"],
                qc_dir=p["qc"], out_dir=p["out"], backup_dir=p["backup"], approve="1")
    args.update(kw)
    return mw.write_master_workbook(**args)
