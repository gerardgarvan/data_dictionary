"""Phase 19 master workbook verifier (plan 19-06, XLS-03).

Re-reads out\\PCNR_Master_Data_Nov_2026.xlsx and checks it against the stage files
(exact counts, sample rows) and the 18c reference (comb_recon, comb_key_facts).
Every result is a name plus counts; no cell value is ever returned, logged or
written. Counts 1-10 are masked as '<11' in the output files; comparisons are
made on exact values in memory.
"""
from __future__ import annotations

import csv
import re
import zipfile
from collections import Counter
from datetime import date, datetime
from pathlib import Path
from typing import Any

from openpyxl import load_workbook
from openpyxl.utils.datetime import to_excel

from pdd import master_rules
from pdd import master_workbook as mw

Result = tuple[str, str, int | str, int | str, bool]  # (check, variable, n, expected, ok)

_TOKEN_SPLIT = re.compile(r"[\s,;:|]+")


def _m(n: int) -> str | int:
    return master_rules.mask_count(n)


def _mask_any(x: int | str) -> int | str:
    return _m(x) if isinstance(x, int) else x


def masked_match(expected_text: str, actual: int) -> bool | None:
    """Compare a possibly masked count with an exact one. None = not comparable."""
    t = (expected_text or "").strip()
    if t == "<11":
        return 1 <= actual <= 10
    m = re.fullmatch(r">\(?(\d+)\)?", t)
    if m:
        return actual > int(m.group(1))
    if re.fullmatch(r"\d+", t):
        return actual == int(t)
    return None


def _recon_key(name: str) -> str:
    return re.sub(r"^PCNR_", "", name.strip(), flags=re.I).upper()


def _expected_cell(kind: str, name: str, text: str) -> Any:
    if name in master_rules.NUMERIC_OVERRIDES:
        return master_rules.override_cell(text)[0]
    code = mw._KIND_CODE[kind]  # noqa: SLF001 - same typing rules as the writer
    return mw.convert_cell(code, text)


def _read_stage_sample(data_csv: Path, wanted: set[int]) -> dict[int, list[str]]:
    out: dict[int, list[str]] = {}
    last = max(wanted) if wanted else 0
    with mw.open_csv(data_csv) as fh:
        rd = csv.reader(fh)
        next(rd, None)
        for i, rec in enumerate(rd, 1):
            if i in wanted:
                out[i] = rec
            if i >= last:
                break
    return out


def _formula_scan(xlsx: Path) -> tuple[int, int]:
    """Count formula elements and error-typed cells over all worksheet XML parts."""
    f = e = 0
    with zipfile.ZipFile(xlsx) as zf:
        for part in zf.namelist():
            if not (part.startswith("xl/worksheets/") and part.endswith(".xml")):
                continue
            with zf.open(part) as fh:
                tail = b""
                while chunk := fh.read(1 << 20):
                    buf = tail + chunk
                    f += len(re.findall(rb"<f[ >/]", buf))
                    e += len(re.findall(rb't="e"', buf))
                    tail = buf[-8:]
    return f, e


def load_registry_tokens(path: Path) -> set[str]:
    """ENCRYPTED_MRN values of the registry, in memory only (never logged or written)."""
    import pandas as pd

    df = pd.read_sas(path, format="sas7bdat", encoding="latin-1")
    col = next((c for c in df.columns if str(c).upper() == "ENCRYPTED_MRN"), None)
    if col is None:
        raise ValueError("registry has no ENCRYPTED_MRN column")
    return {str(v).strip() for v in df[col].dropna() if str(v).strip()}


def verify(
    *, xlsx: Path, stage_dir: Path, exchange_dir: Path, docs_dir: Path, registry_path: Path,
    keys_code: str = master_rules.DEFAULT_KEYS,
) -> list[Result]:
    res: list[Result] = []

    def add(check: str, var: str, n: int | str, exp: int | str, ok: bool) -> None:
        res.append((check, var, n, exp, bool(ok)))

    schema = mw.read_schema(stage_dir / "xlsx_schema.csv")
    names = [r["name"] for r in schema]
    kinds = {r["name"]: r["excel_kind"] for r in schema}
    expected = mw.read_expected(stage_dir / "xlsx_expected.csv")
    exceptions = mw.read_exceptions(docs_dir / "xlsx_name_exceptions.csv")
    wc_path = stage_dir / "xlsx_write_counts.csv"
    blanked = 0
    if wc_path.exists():
        with mw.open_csv(wc_path) as fh:
            blanked = sum(int(r["n_blanked"] or 0) for r in csv.DictReader(fh))
    ncols = len(names)

    wb = load_workbook(xlsx, read_only=True, data_only=False)
    add("sheet_order", "", len(wb.sheetnames), 2, wb.sheetnames == list(mw.SHEET_ORDER))
    if "DATA" not in wb.sheetnames or "KEY" not in wb.sheetnames:
        return res
    key_rows = [tuple("" if v is None else str(v) for v in r[:3]) for r in wb["KEY"].iter_rows(values_only=True)]

    # disclosure: registry tokens in memory only
    try:
        tokens = load_registry_tokens(registry_path)
        minlen = min((len(t) for t in tokens), default=0)
        reg_ok = bool(tokens)
    except Exception:  # noqa: BLE001 - reason is not logged; it can name paths only
        tokens, minlen, reg_ok = set(), 0, False
    add("registry_tokens_loaded", "", len(tokens), "<>0", reg_ok)

    def hits(s: str) -> int:
        if len(s) < minlen or not tokens:
            return 0
        if s.strip() in tokens:
            return 1
        return sum(1 for t in _TOKEN_SPLIT.split(s) if t in tokens)

    disclosure = sum(hits(t) for r in key_rows for t in r)
    ws = wb["DATA"]
    nonblank = [0] * ncols
    era_idx = names.index("KEY_ERA") if "KEY_ERA" in names else -1
    id_idx = names.index("PECAN_ID") if "PECAN_ID" in names else -1
    era_rows: Counter[str] = Counter()
    era_ids: dict[str, set[str]] = {"K1": set(), "K2": set()}
    sample = set(expected["sample"])
    got_sample: dict[int, tuple] = {}
    header: list[str] = []
    nrows = 0
    over_wide = 0
    for ri, row in enumerate(ws.iter_rows(values_only=True)):
        if ri == 0:
            header = ["" if v is None else str(v) for v in row]
            continue
        nrows += 1
        if len(row) > ncols and any(v not in (None, "") for v in row[ncols:]):
            over_wide += 1
        for ci in range(min(ncols, len(row))):
            v = row[ci]
            if v is None or v == "":
                continue
            nonblank[ci] += 1
            if isinstance(v, str):
                disclosure += hits(v)
        if era_idx >= 0 and era_idx < len(row) and row[era_idx] is not None:
            era = str(row[era_idx])
            era_rows[era] += 1
            if era in era_ids and id_idx < len(row) and row[id_idx] is not None:
                era_ids[era].add(str(row[id_idx]))
        if nrows in sample:
            got_sample[nrows] = tuple(row[:ncols]) + (None,) * (ncols - len(row[:ncols]))
    wb.close()

    add("header_equals_expected", "", len(header), ncols, header == names)
    add("header_key_columns", "", len(header), ncols, tuple(header[: 3 if keys_code == "K3" else 4])
        == master_rules.key_columns(keys_code))
    add("row_count", "", _m(nrows), _m(expected["rows"]), nrows == expected["rows"])
    add("no_extra_columns", "", over_wide, 0, over_wide == 0)
    bad_hdr = [h for h in header if any(t in h.upper() for t in mw.NAME_FLAG_TOKENS) and h not in exceptions]
    add("disclosure_header_names", "", len(bad_hdr), 0, not bad_hdr)
    add("disclosure_registry_token_hits", "", disclosure, 0, disclosure == 0)

    # per-column counts: exact vs stage expected, masked-tolerant vs comb_recon, NO_DATA = 0
    with mw.open_csv(exchange_dir / "comb_recon.csv") as fh:
        recon = {_recon_key(r["pcnr_name"]): r["n_nonmiss_comb_all"] for r in csv.DictReader(fh)}
    nodata: set[str] = set()
    nd_path = exchange_dir / "comb_nodata.csv"
    if nd_path.exists():
        with mw.open_csv(nd_path) as fh:
            nodata = {_recon_key(r["pcnr_name"]) for r in csv.DictReader(fh) if (r["n_nonmiss"] or "").strip() == "0"}
    for name, got in zip(names, nonblank):
        is_dd = name in master_rules.NUMERIC_OVERRIDES
        exp_nb = expected["cols"].get(name, (None, 0))[0]
        want = None if exp_nb is None else (exp_nb - blanked if is_dd else exp_nb)
        add("nonblank_vs_stage", name, _m(got), "?" if want is None else _m(want), want is not None and got == want)
        rk = _recon_key(name)
        if name.startswith("PCNR_") and rk in recon:
            cmp_n = got + blanked if is_dd else got
            ok = masked_match(recon[rk], cmp_n)
            if ok is not None:
                add("nonblank_vs_recon", name, _m(cmp_n), recon[rk], ok)
        if rk in nodata:
            add("no_data_zero", name, _m(got), 0, got == 0)

    # sample rows: equality with the stage, type tally
    stage_rows = _read_stage_sample(stage_dir / "xlsx_data.csv", sample)
    add("sample_rows_found", "", len(got_sample), len(sample), set(got_sample) == sample == set(stage_rows))
    mism: Counter[str] = Counter()
    tally: Counter[str] = Counter()
    type_bad: Counter[str] = Counter()
    for i, rec in stage_rows.items():
        got = got_sample.get(i)
        if got is None:
            continue
        for name, text, v in zip(names, rec, got):
            kind = kinds[name]
            want = _expected_cell(kind, name, text)
            tally[f"{kind}:{type(v).__name__}"] += 1
            if want is None:
                ok = v in (None, "")
            elif isinstance(want, str):
                ok = isinstance(v, str) and v == want
            elif isinstance(v, (datetime, date)):
                ok = kind != "N" and abs(float(to_excel(v)) - float(want)) < 1e-6
            else:
                ok = isinstance(v, (int, float)) and not isinstance(v, bool) and v == want
            if not ok:
                mism[name] += 1
            if v is not None and ((kind == "C" and name not in master_rules.NUMERIC_OVERRIDES
                                   and not isinstance(v, str))
                                  or (kind == "N" and isinstance(v, str))):
                type_bad[name] += 1
    add("sample_value_mismatch_cells", "", sum(mism.values()), 0, not mism)
    for name in sorted(mism):
        add("sample_value_mismatch_column", name, _m(mism[name]), 0, False)
    add("sample_type_violations", "", sum(type_bad.values()), 0, not type_bad)
    for k in sorted(tally):
        add("sample_type_tally", k, _m(tally[k]), "info", True)

    # formulas and error cells anywhere in the file
    nf, ne = _formula_scan(xlsx)
    add("formula_cells", "", nf, 0, nf == 0)
    add("error_cells", "", ne, 0, ne == 0)

    # KEY sheet facts
    text_all = "\n".join(r[2] for r in key_rows)
    for line in master_rules.key_sheet_notice():
        add("key_notice_line", "", 1, 1, line in text_all)
    add("key_first_sheet_header", "", len(key_rows), "?", bool(key_rows) and key_rows[0] == ("section", "item", "text"))
    kv = {(s, i): t for s, i, t in key_rows}
    add("key_data_rows", "", _m(nrows), kv.get(("THIS_WORKBOOK", "DATA_ROWS"), "?"),
        masked_match(kv.get(("THIS_WORKBOOK", "DATA_ROWS"), ""), nrows) is True)
    add("key_data_columns", "", ncols, kv.get(("THIS_WORKBOOK", "DATA_COLUMNS"), "?"),
        kv.get(("THIS_WORKBOOK", "DATA_COLUMNS")) == str(ncols))
    add("key_price_pending", "", 1, 1, "PENDING" in kv.get(("REVIEW", "PRICE_SIGN_OFF"), ""))
    with mw.open_csv(exchange_dir / "comb_key_facts.csv") as fh:
        facts = {r["item"]: r["value"] for r in csv.DictReader(fh)}
    same = all(kv.get(("FACTS_PCNR_2018_2025", k)) == v for k, v in facts.items())
    add("key_facts_equal_file", "", len(facts), len(facts), same)
    derived = {
        "ROWS": nrows, "K1_ROWS": era_rows["K1"], "K2_ROWS": era_rows["K2"],
        "DISTINCT_PECAN_ID_K1": len(era_ids["K1"]), "DISTINCT_PECAN_ID_K2": len(era_ids["K2"]),
    }
    for item, val in derived.items():
        if item in facts:
            ok = masked_match(facts[item], val)
            if ok is not None:
                add("key_fact_vs_data", item, _m(val), facts[item], ok)
    return res


def write_outputs(results: list[Result], qc_path: Path, summary_path: Path) -> bool:
    """qc CSV (masked per item) and masked summary CSV. Returns True if every item passed."""
    qc_path.parent.mkdir(parents=True, exist_ok=True)
    with qc_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["check", "variable", "n", "expected", "status"])
        for c, v, n, e, ok in results:
            w.writerow([c, v, _mask_any(n), _mask_any(e), "PASS" if ok else "FAIL"])
    by: dict[str, list[bool]] = {}
    for c, _, _, _, ok in results:
        by.setdefault(c, []).append(ok)
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    with summary_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["check", "n_items", "n_failed", "status"])
        for c, oks in by.items():
            nf = sum(1 for o in oks if not o)
            w.writerow([c, _m(len(oks)), 0 if nf == 0 else "FAIL", "PASS" if nf == 0 else "FAIL"])
    return all(ok for *_, ok in results)


STAGE_FILES = ("xlsx_data.csv", "xlsx_schema.csv", "xlsx_expected.csv", "xlsx_write_counts.csv")


def delete_stage(stage_dir: Path) -> list[str]:
    """PDD-D-42 = NONE: remove the row-level stage CSV and its companions after PASS."""
    gone = []
    for f in STAGE_FILES:
        p = stage_dir / f
        if p.exists():
            p.unlink()
            gone.append(f)
    return gone
