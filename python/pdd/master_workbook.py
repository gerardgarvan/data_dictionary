"""Phase 19 master data workbook writer (plan 19-05).

Turns the SAS stage files (docs/xlsx_stage_contract.md) into
out\\PCNR_Master_Data_Nov_2026.xlsx: sheets KEY (leftmost) and DATA only.

Rules applied (decide_19, 2026-11-18): K3 keys (PDD-D-43); NUM_TEXT stays text
except Death_Days, which is numeric and blanked when non-numeric (PDD-D-39);
special missing is blank (PDD-D-40); no VARIABLE_LIST / SPECIAL_MISSING sheet
(PDD-D-27, PDD-D-40); PDD_XLS_APPROVE=1 needed (PDD-D-44).

Privacy: this module logs counts and column names only, never a cell value. An
exception that could carry a value (openpyxl's IllegalCharacterError) is caught
and replaced by a message with the column name and a count.
"""
from __future__ import annotations

import csv
import logging
import os
import shutil
import time
from datetime import datetime
from pathlib import Path
from typing import Any

from openpyxl import Workbook
from openpyxl.cell import WriteOnlyCell
from openpyxl.cell.cell import ILLEGAL_CHARACTERS_RE
from openpyxl.utils import get_column_letter
from openpyxl.utils.exceptions import IllegalCharacterError

from pdd import master_rules
from pdd.xlsx_style import ACCENT_FILL, ACCENT_FONT, HEADER_FILL, HEADER_FONT

log = logging.getLogger("pdd.master_workbook")

FINAL_NAME = "PCNR_Master_Data_Nov_2026.xlsx"
SHEET_ORDER = ("KEY", "DATA")
MAX_ROWS = 1_048_576
MAX_COLS = 16_384
MAX_CHARS = 32_767
NAME_FLAG_TOKENS = ("MRN", "ENCRYPT", "ENCOUNTER")
NUMBER_FORMATS = {"DATE": "yyyy-mm-dd", "DATETIME": "yyyy-mm-dd hh:mm:ss", "TIME": "hh:mm:ss"}

# per-column kind codes used in the hot loop
_C, _N, _DATE, _DTTM, _TIME, _OVR = 0, 1, 2, 3, 4, 5
_KIND_CODE = {"C": _C, "N": _N, "DATE": _DATE, "DATETIME": _DTTM, "TIME": _TIME}


class StageError(Exception):
    """A gate or stage problem. Messages carry names and counts, never values."""


# ---------------------------------------------------------------- stage readers
def open_csv(path: Path):
    csv.field_size_limit(1 << 28)
    # SAS FILE encoding='utf-8' writes a BOM; utf-8-sig drops it (and reads BOM-less files too)
    return path.open("r", encoding="utf-8-sig", newline="")


def _clean_name(s: str) -> str:
    return s.replace("﻿", "").strip()


def read_schema(path: Path) -> list[dict[str, str]]:
    with open_csv(path) as fh:
        rd = csv.DictReader(fh)
        if rd.fieldnames:
            rd.fieldnames = [_clean_name(f) for f in rd.fieldnames]
        rows = list(rd)
    for r in rows:
        r["name"] = _clean_name(r.get("name") or "")
    need = {"col_index", "name", "sas_type", "excel_kind"}
    if not rows or not need <= set(rows[0]):
        raise StageError(f"{path.name}: header must have {sorted(need)}")
    for r in rows:
        if r["excel_kind"] not in _KIND_CODE:
            raise StageError(f"{path.name}: unknown excel_kind for column {r['name']}")
    return rows


def read_expected(path: Path) -> dict[str, Any]:
    """xlsx_expected.csv -> {'rows': int, 'cols': {name: (nonblank, special)}, 'sample': [row numbers]}."""
    out: dict[str, Any] = {"rows": None, "cols": {}, "sample": []}
    with open_csv(path) as fh:
        rd = csv.DictReader(fh)
        if [_clean_name(f) for f in rd.fieldnames or []] != ["kind", "variable", "n_rows", "n_nonblank", "n_special"]:
            raise StageError(f"{path.name}: unexpected header")
        rd.fieldnames = [_clean_name(f) for f in rd.fieldnames]
        for r in rd:
            if r["kind"] == "ROWS":
                out["rows"] = int(r["n_rows"])
            elif r["kind"] == "COL":
                out["cols"][r["variable"]] = (int(r["n_nonblank"]), int(r["n_special"] or 0))
            elif r["kind"] == "SAMPLE":
                out["sample"].append(int(r["n_rows"]))
    if out["rows"] is None:
        raise StageError(f"{path.name}: no ROWS record")
    return out


def read_exceptions(path: Path) -> set[str]:
    if not path.exists():
        return set()
    with open_csv(path) as fh:
        return {r["colname"].strip() for r in csv.DictReader(fh) if r.get("colname")}


def check_columns(
    header: list[str], schema: list[dict[str, str]], keys_code: str, exceptions: set[str]
) -> None:
    """Gate: header == schema; K-set first; only PCNR_ variables after; no MRN-like names."""
    names = [r["name"] for r in schema]
    if header != names:
        raise StageError("data CSV header differs from xlsx_schema.csv (names or order)")
    if len(set(names)) != len(names):
        raise StageError("duplicate column names in the stage schema")
    keys = master_rules.key_columns(keys_code)
    if tuple(names[: len(keys)]) != keys:
        raise StageError(f"first columns are not the {keys_code} key set {list(keys)}")
    for name in names[len(keys):]:
        if not name.startswith("PCNR_"):
            raise StageError(f"unexpected non-PCNR_ column after the keys: {name}")
    for name in names:
        up = name.upper()
        if any(t in up for t in NAME_FLAG_TOKENS) and name not in exceptions:
            raise StageError(f"column name flagged (MRN, ENCRYPT or ENCOUNTER) and not excepted: {name}")


# ---------------------------------------------------------------- cell conversion
def convert_cell(code: int, text: str) -> Any:
    """Stage text -> Python value (None = blank). Death_Days (_OVR) returns (value, blanked)."""
    if code == _OVR:
        return master_rules.override_cell(text)
    if text == "":
        return None
    if code == _C:
        return text
    v = float(text)  # ValueError -> caller names the column
    if v != v or v in (float("inf"), float("-inf")):
        raise ValueError("non-finite")
    if code == _N and v == int(v) and abs(v) < 1e15:
        return int(v)
    return v


def _kinds(schema: list[dict[str, str]]) -> list[int]:
    return [
        _OVR if r["name"] in master_rules.NUMERIC_OVERRIDES else _KIND_CODE[r["excel_kind"]]
        for r in schema
    ]


def _text_cell(ws, text: str) -> WriteOnlyCell:
    c = WriteOnlyCell(ws, value=text)
    c.data_type = "s"
    return c


def _abandon(wb: Workbook) -> None:
    """Release the temp files of a failed write-only workbook (quiet, no values)."""
    for ws in list(wb._sheets):  # noqa: SLF001 - no public iterator for write-only sheets
        try:
            ws.close()
        except Exception:  # noqa: BLE001 - best effort cleanup of a failed run
            pass


def _illegal_columns(rec: list[str], names: list[str]) -> list[str]:
    return [n for n, t in zip(names, rec) if t and ILLEGAL_CHARACTERS_RE.search(t)]


# ---------------------------------------------------------------- pre-pass
def prepass(data_csv: Path, schema: list[dict[str, str]]) -> dict[str, int]:
    """One cheap pass: record count (excl. header) and Death_Days blanked count."""
    names = [r["name"] for r in schema]
    dd = [i for i, n in enumerate(names) if n in master_rules.NUMERIC_OVERRIDES]
    rows = blanked = 0
    with open_csv(data_csv) as fh:
        rd = csv.reader(fh)
        next(rd, None)
        for rec in rd:
            rows += 1
            for i in dd:
                if i < len(rec) and master_rules.override_cell(rec[i])[1]:
                    blanked += 1
    return {"rows": rows, "blanked": blanked}


# ---------------------------------------------------------------- KEY sheet
def _read_pairs(path: Path, cols: tuple[str, ...]) -> list[list[str]]:
    with open_csv(path) as fh:
        rd = csv.DictReader(fh)
        missing = [c for c in cols if c not in (rd.fieldnames or [])]
        if missing:
            raise StageError(f"{path.name}: missing columns {missing}")
        return [[r[c] for c in cols] for r in rd]


def build_key_rows(
    exchange_dir: Path, docs_dir: Path, rows: int, cols: int, keys: tuple[str, ...], blanked: int,
    stamp: str,
) -> list[tuple[str, str, str]]:
    """KEY sheet body as (section, item, text) rows. Counts only; no data values."""
    out: list[tuple[str, str, str]] = []
    for line in master_rules.key_sheet_notice():
        out.append(("NOTICE", "", line))
    out.append(("THIS_WORKBOOK", "SHEETS", "KEY, DATA"))
    out.append(("THIS_WORKBOOK", "DATA_ROWS", str(master_rules.mask_count(rows))))
    out.append(("THIS_WORKBOOK", "DATA_COLUMNS", str(cols)))
    out.append(("THIS_WORKBOOK", "KEY_COLUMNS", ", ".join(keys)))
    out.append(("THIS_WORKBOOK", "BUILT", stamp))
    for item, val in _read_pairs(exchange_dir / "comb_key_facts.csv", ("item", "value")):
        out.append(("FACTS_PCNR_2018_2025", item, val))
    for item, text in _read_pairs(docs_dir / "pecan_id_dictionary_text.csv", ("item", "text")):
        out.append(("ID_TEXT", item, text))
    out.append((
        "MISSING_VALUES", "BLANK",
        "A blank cell is missing. Ordinary and special missing values (.A-.Z, ._) are all blank (PDD-D-40).",
    ))
    out.append((
        "MISSING_VALUES", "TEXT_NUMBERS",
        "Numeric-looking columns that arrive as text stay text (PDD-D-39), except "
        "PCNR_Death_Days_After_Surgery, which is numeric.",
    ))
    dd_name, dd_n = master_rules.blanked_qc_row(blanked)
    out.append((
        "MISSING_VALUES", dd_name,
        f"{dd_n} Death_Days cell(s) held non-numeric text (for example an error code) and are blank here.",
    ))
    out.append(("K2_PSID_RULE", "PDD_K2_PSID_MODE", "see the PDD_K2_PSID_MODE row of FACTS_PCNR_2018_2025"))
    out.append(("REVIEW", "PRICE_SIGN_OFF", "PENDING: Price sign-off has not been given."))
    for name, ctype, kind, text, ref in _read_pairs(
        docs_dir / "combined_type_decisions.csv",
        ("pcnr_name", "combined_type", "note_kind", "note_text", "decision_ref"),
    ):
        out.append(("ERA_NOTES", name, f"[{kind}] {text} ({ref}; combined type {ctype})"))
    return out


def _write_key(ws, key_rows: list[tuple[str, str, str]]) -> None:
    for letter, width in (("A", 24), ("B", 36), ("C", 120)):
        ws.column_dimensions[letter].width = width
    ws.freeze_panes = "A2"
    head = []
    for h in ("section", "item", "text"):
        c = WriteOnlyCell(ws, value=h)
        c.fill, c.font = HEADER_FILL, HEADER_FONT
        head.append(c)
    ws.append(head)
    for section, item, text in key_rows:
        first = WriteOnlyCell(ws, value=section)
        if section == "NOTICE":
            first.fill, first.font = ACCENT_FILL, ACCENT_FONT
        ws.append([first, _text_cell(ws, item) if item[:1] in ("=", "#") else item, _text_cell(ws, text)])


# ---------------------------------------------------------------- DATA sheet
def _write_data(
    wb, data_csv: Path, schema: list[dict[str, str]], keys_code: str, exceptions: set[str],
    limit_rows: int | None, max_rows: int, max_chars: int, sheet_title: str = "DATA",
) -> dict[str, Any]:
    names = [r["name"] for r in schema]
    ncols = len(names)
    kinds = _kinds(schema)
    fmts = [NUMBER_FORMATS.get(r["excel_kind"]) for r in schema]
    ws = wb.create_sheet(sheet_title)
    ws.freeze_panes = "A2"
    nonblank = [0] * ncols
    blanked = 0
    n = 0
    with open_csv(data_csv) as fh:
        rd = csv.reader(fh)
        header = next(rd, None)
        if header is None:
            raise StageError("data CSV is empty")
        header = [_clean_name(h) for h in header]
        check_columns(header, schema, keys_code, exceptions)
        assert not any("﻿" in h for h in names), "BOM in DATA header"
        head = []
        for h in names:
            c = WriteOnlyCell(ws, value=h)
            c.fill, c.font = HEADER_FILL, HEADER_FONT
            head.append(c)
        ws.append(head)
        for rec in rd:
            if len(rec) != ncols:
                raise StageError(f"record {n + 1} has {len(rec)} fields, expected {ncols}")
            if n + 1 >= max_rows:  # header + n rows must stay <= max_rows
                raise StageError(f"row limit {max_rows} would be exceeded")
            row: list[Any] = []
            for i, text in enumerate(rec):
                k = kinds[i]
                if k == _C:
                    if text == "":
                        row.append(None)
                        continue
                    if len(text) > max_chars:
                        raise StageError(f"text over {max_chars} characters in column {names[i]}")
                    nonblank[i] += 1
                    row.append(_text_cell(ws, text) if text[0] in "=#" else text)
                    continue
                try:
                    v = convert_cell(k, text)
                except ValueError:
                    raise StageError(f"unparseable numeric text in column {names[i]}") from None
                if k == _OVR:
                    v, was_blanked = v
                    blanked += was_blanked
                if v is None:
                    row.append(None)
                    continue
                nonblank[i] += 1
                if fmts[i]:
                    c = WriteOnlyCell(ws, value=v)
                    c.number_format = fmts[i]
                    v = c
                row.append(v)
            try:
                ws.append(row)
            except IllegalCharacterError:
                bad = _illegal_columns(rec, names)
                raise StageError(
                    f"illegal control character in {len(bad)} column(s): {', '.join(bad)}"
                ) from None
            n += 1
            if limit_rows is not None and n >= limit_rows:
                break
    ws.auto_filter.ref = f"A1:{get_column_letter(ncols)}{n + 1}"
    return {"rows": n, "cols": names, "nonblank": nonblank, "blanked": blanked}


# ---------------------------------------------------------------- orchestration
def _write_csv(path: Path, header: list[str], rows: list[list[Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        w.writerows(rows)


def write_master_workbook(
    *, stage_dir: Path, exchange_dir: Path, docs_dir: Path, qc_dir: Path, out_dir: Path,
    backup_dir: Path, final_name: str = FINAL_NAME, keys_code: str = master_rules.DEFAULT_KEYS,
    approve: str | None = None, min_free_gb: float = 0.0, max_rows: int = MAX_ROWS,
    max_cols: int = MAX_COLS, max_chars: int = MAX_CHARS, now: datetime | None = None,
) -> dict[str, Any]:
    """Production write. Returns counts. Raises PermissionError / StageError on any gate."""
    master_rules.require_approval(approve)
    schema = read_schema(stage_dir / "xlsx_schema.csv")
    data_csv = stage_dir / "xlsx_data.csv"
    if not data_csv.exists():
        raise StageError("stage\\xlsx_data.csv is missing")
    expected = read_expected(stage_dir / "xlsx_expected.csv")
    if len(schema) >= max_cols:
        raise StageError(f"column limit: {len(schema)} columns, limit {max_cols}")
    pre = prepass(data_csv, schema)
    if pre["rows"] != expected["rows"]:
        raise StageError("stage record count differs from xlsx_expected ROWS")
    if pre["rows"] + 1 > max_rows:
        raise StageError(f"row limit: {pre['rows']} data rows, limit {max_rows}")
    out_dir.mkdir(parents=True, exist_ok=True)
    free_gb = shutil.disk_usage(out_dir).free / 1e9
    if free_gb < min_free_gb:
        raise StageError(f"free disk {free_gb:.1f} GB is below the {min_free_gb} GB minimum")
    exceptions = read_exceptions(docs_dir / "xlsx_name_exceptions.csv")
    stamp_dt = now or datetime.now()
    keys = master_rules.key_columns(keys_code)
    key_rows = build_key_rows(
        exchange_dir, docs_dir, pre["rows"], len(schema), keys, pre["blanked"],
        stamp_dt.strftime("%Y-%m-%d"),
    )

    final = out_dir / final_name
    tmp = out_dir / (final_name + ".tmp")
    if final.exists():
        backup_dir.mkdir(parents=True, exist_ok=True)
        bak = backup_dir / f"{Path(final_name).stem}_{stamp_dt.strftime('%Y%m%d_%H%M%S')}.xlsx"
        shutil.move(str(final), str(bak))
        log.info("existing final file moved to backup\\%s", bak.name)
    t0 = time.time()
    wb = Workbook(write_only=True)
    try:
        _write_key(wb.create_sheet("KEY"), key_rows)
        res = _write_data(wb, data_csv, schema, keys_code, exceptions, None, max_rows, max_chars)
        if res["rows"] != expected["rows"]:
            raise StageError("rows written differ from xlsx_expected ROWS")
        wb.save(tmp)
        os.replace(tmp, final)
    except BaseException:
        _abandon(wb)
        if tmp.exists():
            tmp.unlink()
        raise
    secs = time.time() - t0
    _write_csv(
        stage_dir / "xlsx_write_counts.csv", ["variable", "n_rows", "n_nonblank", "n_blanked"],
        [[n, res["rows"], nb, res["blanked"] if n in master_rules.NUMERIC_OVERRIDES else 0]
         for n, nb in zip(res["cols"], res["nonblank"])],
    )
    _write_csv(
        qc_dir / "xlsx_master_write.csv", ["item", "n"],
        [["data_rows", master_rules.mask_count(res["rows"])],
         ["data_columns", len(res["cols"])],
         ["seconds", int(secs)],
         list(master_rules.blanked_qc_row(res["blanked"]))],
    )
    log.info("wrote %s: %d data rows, %d columns, %d seconds", final_name, res["rows"], len(res["cols"]), secs)
    return {"rows": res["rows"], "cols": len(res["cols"]), "blanked": res["blanked"], "final": final}


def bench(
    *, stage_dir: Path, docs_dir: Path, n_rows: int, approve: str | None = None,
    keys_code: str = master_rules.DEFAULT_KEYS,
) -> dict[str, float]:
    """Write the first n_rows to a throwaway file under stage\\ and report rows/s."""
    master_rules.require_approval(approve)
    schema = read_schema(stage_dir / "xlsx_schema.csv")
    expected = read_expected(stage_dir / "xlsx_expected.csv")
    tmp = stage_dir / "xlsx_bench.xlsx"
    exceptions = read_exceptions(docs_dir / "xlsx_name_exceptions.csv")
    t0 = time.time()
    wb = Workbook(write_only=True)
    try:
        res = _write_data(
            wb, stage_dir / "xlsx_data.csv", schema, keys_code, exceptions, n_rows, MAX_ROWS, MAX_CHARS
        )
        wb.save(tmp)
    finally:
        _abandon(wb)
        if tmp.exists():
            tmp.unlink()
    secs = max(time.time() - t0, 1e-9)
    rate = res["rows"] / secs
    est = expected["rows"] / rate if rate else float("inf")
    log.info("bench: %d rows in %.1f s = %.0f rows/s; extrapolated full file %.1f min for %d rows",
             res["rows"], secs, rate, est / 60, expected["rows"])
    return {"rows": res["rows"], "seconds": secs, "rows_per_s": rate, "est_minutes": est / 60}
