"""
Phase 18 (DD-03, DD-04): PeCAN Data Dictionary workbook for 2018-2025.

Reads (exchange dir):
    comb_key_facts.csv, comb_recon.csv, comb_nodata.csv, comb_d30_conflicts.csv,
    profile_PCNR_2018_2025.csv, profile_PCNR_2018_2025_manifest.csv,
    name_map_vars_coverage.csv, source_inventory.csv (optional)
Reads (docs dir):
    exchange_schema.csv, combined_type_decisions.csv, pecan_id_dictionary_text.csv,
    age_variables.csv (when age_topcode is on)
Writes: out/pdd_2018_2025.xlsx
Sheets: KEY | VARIABLES | DISTRIBUTIONS | NAME_MAP | SOURCES | QC

Reuses the v1.0 helpers of pdd.dictionary_workbook (age topcode, NUM_TEXT mask,
suppression, no-leak guard, variable-stat derivation). No count is hard-coded:
every number in the text comes from the CSVs. Count columns of the exchange
files are strings and may be "<11" (masked 1-10).
"""

from __future__ import annotations

import csv
import datetime
import logging
import re
from pathlib import Path
from typing import Any

import pandas as pd
from openpyxl import Workbook, load_workbook

from pdd.dictionary_workbook import (
    DEFAULT_DISPLAY_CONFIG,
    REQUIRED_PROFILE_COLS,
    _assert_columns,
    _to_num,
    apply_age_topcode,
    apply_suppression,
    build_distributions_sheet,
    build_variables_sheet,
    read_csv,
)
from pdd.xlsx_style import (
    ACCENT_FILL,
    ACCENT_FONT,
    HEADER_FILL,
    HEADER_FONT,
    apply_header_row,
    style_sheet,
    write_table,
)

SHEET_ORDER_2018_2025 = ["KEY", "VARIABLES", "DISTRIBUTIONS", "NAME_MAP", "SOURCES", "QC"]
OUTPUT_NAME = "pdd_2018_2025.xlsx"

KEY_VARIABLES = [
    "PECAN_ID",
    "PRECEDE_STUDY_ID",
    "PECAN_ID_KEY_ERA",
    "KEY_ERA",
    "NORM_PSID",
]

EXCHANGE_FILES = [
    "comb_key_facts.csv",
    "comb_recon.csv",
    "comb_nodata.csv",
    "comb_d30_conflicts.csv",
    "profile_PCNR_2018_2025.csv",
    "profile_PCNR_2018_2025_manifest.csv",
    "name_map_vars_coverage.csv",
]
OPTIONAL_EXCHANGE_FILES = ["source_inventory.csv"]

DOC_REQUIRED_COLS = {
    "combined_type_decisions.csv": ["pcnr_name", "combined_type", "note_kind", "note_text", "decision_ref"],
    "pecan_id_dictionary_text.csv": ["item", "text"],
}

# Item names accepted in comb_key_facts.csv (matched after upper-casing and
# turning non-alphanumerics into "_"). Only ROWS and COLUMNS are required.
_FACT_ALIASES = {
    "rows": ["ROWS", "N_ROWS", "NOBS", "ROW_COUNT", "SURGERY_ROWS"],
    "columns": ["COLUMNS", "N_COLUMNS", "NVARS", "COLUMN_COUNT", "COL_COUNT"],
    "k1_rows": ["K1_ROWS", "N_K1_ROWS"],
    "k2_rows": ["K2_ROWS", "N_K2_ROWS"],
    "shared": ["SHARED_SURGERIES", "N_SHARED", "SHARED_2024_2025", "SHARED_SURGERIES_2024_2025", "D30_SHARED"],
    "dup_pairs": ["DUP_PAIRS", "K1_DUP_PAIRS", "DUP_LINK_PAIRS", "PECAN_ID_DUP_PAIRS", "DUP_LINK_ROWS"],
    "k2_mode": ["PDD_K2_PSID_MODE", "K2_PSID_MODE"],
    "date": ["DATE", "RUN_DATE", "BUILD_DATE"],
}

_MASK_STRINGS = ("<11", "<11 missing", "suppressed", "")


# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

def _schema_required(docs_dir: Path) -> dict[str, list[str]]:
    schema_path = docs_dir / "exchange_schema.csv"
    if not schema_path.exists():
        raise FileNotFoundError(f"exchange_schema.csv not found: {schema_path}")
    required: dict[str, list[str]] = {}
    with schema_path.open(newline="", encoding="utf-8-sig") as fh:
        for row in csv.DictReader(fh):
            if (row.get("required") or "").strip().upper() == "Y":
                required.setdefault((row.get("file") or "").strip(), []).append(
                    (row.get("column") or "").strip()
                )
    return required


def validate_exchange_headers(exchange_dir: Path, docs_dir: Path) -> list[str]:
    """Validate required headers of the Phase 18 inputs. Returns error strings (empty = ok)."""
    try:
        required = _schema_required(docs_dir)
    except FileNotFoundError as exc:
        return [str(exc)]
    errors: list[str] = []
    files = list(EXCHANGE_FILES) + [
        f for f in OPTIONAL_EXCHANGE_FILES if (exchange_dir / f).exists()
    ]
    for fname in files:
        path = exchange_dir / fname
        if not path.exists() or path.stat().st_size == 0:
            errors.append(f"Exchange file missing or empty: {path}")
            continue
        if fname not in required:
            errors.append(f"{fname}: not registered in exchange_schema.csv")
            continue
        headers, _ = read_csv(path)
        for col in required[fname]:
            if col not in headers:
                errors.append(f"{fname}: required column missing: {col}")
    for fname, cols in DOC_REQUIRED_COLS.items():
        path = docs_dir / fname
        if not path.exists():
            errors.append(f"Docs file missing: {path}")
            continue
        headers, _ = read_csv(path)
        for col in cols:
            if col not in headers:
                errors.append(f"{fname}: required column missing: {col}")
    return errors


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def _norm_item(s: str) -> str:
    return re.sub(r"[^A-Z0-9]+", "_", s.strip().upper()).strip("_")


def _is_small_int(val: Any) -> bool:
    """True if val is a plain integer string/number between 1 and 10."""
    s = str(val).strip()
    return bool(re.fullmatch(r"\d+", s)) and 1 <= int(s) <= 10


def _as_int(val: Any) -> int | None:
    s = str(val).strip()
    return int(s) if re.fullmatch(r"\d+", s) else None


def _guard_count_cells(label: str, rows: list[dict[str, str]], cols: list[str]) -> None:
    """Hard fail if an exchange count cell holds an unmasked integer 1-10."""
    for i, row in enumerate(rows, start=2):
        for col in cols:
            if _is_small_int(row.get(col, "")):
                raise RuntimeError(f"unmasked small count in {label} row {i} column {col}")


def _guard_pct_cells(
    label: str, rows: list[dict[str, str]], total_rows: int, *, profile: bool = False
) -> None:
    """Hard fail if a pct cell would let a reader back-calculate a count of 1-10.

    A pct_total cell implies a count of round(pct / 100 * total_rows); 1-10 is refused
    in every exchange file. For the profile, any pct cell on a row whose n is blank,
    masked, 1-10 or flagged small is refused too (this also covers pct_nonmiss).
    """
    for i, row in enumerate(rows, start=2):
        for col, val in row.items():
            if not col.startswith("pct"):
                continue
            s = str(val or "").strip()
            if not s:
                continue
            try:
                pct = float(s)
            except ValueError:
                continue
            if col != "pct_nonmiss" and 1 <= round(pct / 100 * total_rows) <= 10:
                raise RuntimeError(f"pct back-calculates a count of 1-10 in {label} row {i} column {col}")
        if profile:
            n = str(row.get("n") or "").strip()
            try:
                n_val: float | None = float(n)
            except ValueError:
                n_val = None  # blank, '<11' or 'suppressed'
            small = (
                n_val is None
                or 1 <= n_val <= 10
                or str(row.get("small_cell_flag") or "").strip().upper() == "Y"
            )
            if small and any(str(row.get(c) or "").strip() for c in ("pct_total", "pct_nonmiss")):
                raise RuntimeError(f"pct present on a blank or masked n row in {label} row {i}")


def load_key_facts(rows: list[dict[str, str]]) -> dict[str, str]:
    """Key facts as {NORMALIZED_ITEM: value}."""
    facts: dict[str, str] = {}
    for r in rows:
        item = _norm_item(r.get("item", ""))
        if item:
            facts[item] = (r.get("value") or "").strip()
    return facts


def _fact(facts: dict[str, str], key: str) -> str | None:
    for alias in _FACT_ALIASES[key]:
        if alias in facts and facts[alias] != "":
            return facts[alias]
    return None


def _fmt_count(val: str | None) -> str:
    """Thousands separators for plain integers; masked or other text unchanged."""
    if val is None:
        return "(not in key facts)"
    i = _as_int(val)
    return f"{i:,}" if i is not None else val


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def load_inputs(exchange_dir: Path, docs_dir: Path) -> dict[str, Any]:
    """Load and shape-check every input. Raises ValueError/RuntimeError on bad input."""
    data: dict[str, Any] = {}

    kf_h, kf_rows = read_csv(exchange_dir / "comb_key_facts.csv")
    _assert_columns("comb_key_facts.csv", kf_h, ["item", "value"])
    data["facts"] = load_key_facts(kf_rows)

    prof_h, prof_rows = read_csv(exchange_dir / "profile_PCNR_2018_2025.csv")
    _assert_columns("profile_PCNR_2018_2025.csv", prof_h, REQUIRED_PROFILE_COLS)
    data["profile_df"] = pd.DataFrame(prof_rows, columns=prof_h).fillna("")

    _, man_rows = read_csv(exchange_dir / "profile_PCNR_2018_2025_manifest.csv")
    data["manifest"] = man_rows[0] if man_rows else {}

    rec_h, rec_rows = read_csv(exchange_dir / "comb_recon.csv")
    _assert_columns("comb_recon.csv", rec_h, ["pcnr_name", "n_nonmiss_comb_all", "explained"])
    _guard_count_cells(
        "comb_recon.csv", rec_rows,
        [c for c in rec_h if c.startswith(("n_nonmiss", "n_special"))],
    )
    data["recon_headers"], data["recon"] = rec_h, rec_rows

    nd_h, nd_rows = read_csv(exchange_dir / "comb_nodata.csv")
    _assert_columns("comb_nodata.csv", nd_h, ["pcnr_name", "n_nonmiss", "reconciled"])
    _guard_count_cells("comb_nodata.csv", nd_rows, ["n_nonmiss"])
    data["nodata"] = nd_rows

    d30_h, d30_rows = read_csv(exchange_dir / "comb_d30_conflicts.csv")
    _assert_columns("comb_d30_conflicts.csv", d30_h, ["pcnr_name", "n_shared"])
    _guard_count_cells("comb_d30_conflicts.csv", d30_rows, [c for c in d30_h if c.startswith("n_")])
    data["d30_headers"], data["d30"] = d30_h, d30_rows

    cov_h, cov_rows = read_csv(exchange_dir / "name_map_vars_coverage.csv")
    _assert_columns(
        "name_map_vars_coverage.csv", cov_h,
        ["pcnr_name", "first_year", "last_year", "s_codes_with_data", "status"],
    )
    data["cov_headers"], data["coverage"] = cov_h, cov_rows

    inv_path = exchange_dir / "source_inventory.csv"
    data["inventory"] = read_csv(inv_path) if inv_path.exists() else None

    _, dec_rows = read_csv(docs_dir / "combined_type_decisions.csv")
    data["decisions"] = dec_rows
    _, txt_rows = read_csv(docs_dir / "pecan_id_dictionary_text.csv")
    data["texts"] = {(r.get("item") or "").strip(): (r.get("text") or "").strip() for r in txt_rows}
    return data


# ---------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------

VARIABLES_HEADERS = [
    "pcnr_name", "description", "combined_type", "var_class", "n_nonmiss", "pct_missing",
    "n_distinct", "all_missing", "year_first", "year_last", "source_columns",
    "data_status", "type_note", "summary",
]


def _key_descriptions(texts: dict[str, str], k2_mode: str) -> dict[str, str]:
    return {
        "PECAN_ID": texts.get("PECAN_ID dictionary row", ""),
        "PECAN_ID_KEY_ERA": texts.get("PECAN_ID_KEY_ERA dictionary row", ""),
        "PRECEDE_STUDY_ID": (
            f"Normalized Precede##### form on K1 and K2 rows (PDD-D-33; K2 mode {k2_mode})."
        ),
        "NORM_PSID": "Normalized Precede##### join key (PDD-D-19).",
    }


def build_variables_2018_2025(
    profile_df: pd.DataFrame, data: dict[str, Any], total_rows: int, config: dict
) -> list[list]:
    """VARIABLES rows: PECAN_ID, other key rows, then profile variables alphabetically."""
    _, base_rows = build_variables_sheet(
        profile_df, pd.DataFrame(), {}, config, total_rows=total_rows
    )
    base = {r[0]: r for r in base_rows}  # pcnr_name, _, _, _, var_class, n_nonmiss, pct, n_dist, all_miss, summary

    cov = {r["pcnr_name"].strip(): r for r in data["coverage"]}
    notes: dict[str, list[str]] = {}
    ctype: dict[str, str] = {}
    for d in data["decisions"]:
        name = (d.get("pcnr_name") or "").strip()
        if not name:
            continue
        if (d.get("combined_type") or "").strip():
            ctype[name] = d["combined_type"].strip()
        text = (d.get("note_text") or "").strip()
        if text:
            kind = (d.get("note_kind") or "").strip()
            ref = (d.get("decision_ref") or "").strip()
            notes.setdefault(name, []).append(f"{kind}: {text} ({ref})" if ref else f"{kind}: {text}")

    k2_mode = _fact(data["facts"], "k2_mode") or "NORM"
    desc = _key_descriptions(data["texts"], k2_mode)

    prof_vars = sorted(
        {v for v in base if v not in KEY_VARIABLES}, key=lambda s: (s.casefold(), s)
    )
    out: list[list] = []
    for name in KEY_VARIABLES + prof_vars:
        b = base.get(name)
        c = cov.get(name, {})
        n_nm = b[5] if b else ""
        pct = b[6] if b else ""
        if isinstance(n_nm, int) and 1 <= n_nm <= 10:
            n_nm, pct = "<11", ""  # never show a count of 1-10
        if n_nm in ("<11", "<11 missing", "suppressed"):
            pct = ""
        all_missing = "Y" if (isinstance(n_nm, int) and n_nm == 0) else ("N" if b else "")
        out.append([
            name,
            desc.get(name, ""),
            ctype.get(name, ""),
            b[4] if b else "",
            n_nm,
            pct,
            b[7] if b else "",
            all_missing,
            _to_num(c.get("first_year", "") or ""),
            _to_num(c.get("last_year", "") or ""),
            (c.get("s_codes_with_data") or "").strip(),
            "NO_DATA" if (c.get("status") or "").strip().upper() == "NO_DATA" else "",
            " | ".join(notes.get(name, [])),
            b[9] if b else "",
        ])
    return out


# ---------------------------------------------------------------------------
# Reconciliation (hard fail)
# ---------------------------------------------------------------------------

def reconcile(
    var_rows: list[list],
    profile_df: pd.DataFrame,
    data: dict[str, Any],
    total_rows: int,
) -> dict[str, int]:
    """Check the VARIABLES rows against the exchange files; raise ValueError on any failure."""
    errors: list[str] = []
    facts = data["facts"]

    n_cols = _as_int(_fact(facts, "columns") or "")
    if n_cols is None:
        errors.append("key facts: columns count missing or not an integer")
    elif len(var_rows) != n_cols:
        errors.append(f"VARIABLES rows {len(var_rows)} != columns declared in key facts {n_cols}")

    man_nobs = _as_int(str(data["manifest"].get("pcnr_nobs", "")))
    if man_nobs is not None and man_nobs != total_rows:
        errors.append(f"profile manifest pcnr_nobs {man_nobs} != key facts rows {total_rows}")

    recon = {r["pcnr_name"].strip(): r for r in data["recon"]}
    prof_set = set(profile_df["variable"].unique()) - set(KEY_VARIABLES)
    var_set = {r[0] for r in var_rows} - set(KEY_VARIABLES)
    if prof_set != var_set:
        errors.append("profile variable set differs from VARIABLES variable set")
    if set(recon) != prof_set:
        only_r = len(set(recon) - prof_set)
        only_p = len(prof_set - set(recon))
        errors.append(
            f"comb_recon variable set differs from profile variable set "
            f"({only_r} only in recon, {only_p} only in profile)"
        )

    n_checked = n_masked_skip = 0
    for row in var_rows:
        name, n_nm = row[0], row[4]
        if name in KEY_VARIABLES or name not in recon:
            continue
        rc = recon[name]
        if (rc.get("explained") or "").strip().upper() == "N":
            errors.append(f"comb_recon explained=N for {name}")
        exp = (rc.get("n_nonmiss_comb_all") or "").strip()
        exp_int = _as_int(exp)
        if isinstance(n_nm, int):
            if exp == "<11":
                errors.append(f"{name}: n_nonmiss shown but comb_recon masks it")
            elif exp_int is None or exp_int != n_nm:
                errors.append(f"{name}: n_nonmiss differs from comb_recon n_nonmiss_comb_all")
            else:
                n_checked += 1
        elif n_nm == "<11":
            if exp != "<11" and (exp_int is None or exp_int <= 10):
                errors.append(f"{name}: n_nonmiss masked but comb_recon is not a masked count")
            else:
                n_checked += 1
        else:
            n_masked_skip += 1  # profile-side suppression hides it; not comparable

    # no-leak: no integer 1-10 in VARIABLES n_nonmiss
    for row in var_rows:
        if isinstance(row[4], int) and 1 <= row[4] <= 10:
            errors.append(f"suppression leak in VARIABLES n_nonmiss for {row[0]}")

    # NO_DATA flagged variables must have zero non-missing cells
    for row in var_rows:
        if row[11] == "NO_DATA" and isinstance(row[4], int) and row[4] != 0:
            errors.append(f"{row[0]} is flagged NO_DATA but has non-missing cells")

    if errors:
        for e in errors[:50]:
            logging.error("Reconciliation: %s", e)
        raise ValueError(f"reconciliation failed ({len(errors)} problem(s)); first: {errors[0]}")
    return {"checked": n_checked, "not_comparable": n_masked_skip}


# ---------------------------------------------------------------------------
# KEY sheet
# ---------------------------------------------------------------------------

def build_key_rows(
    data: dict[str, Any], n_rows_dist: int, n_nodata: int, generated_at: str
) -> list[list[str]]:
    facts = data["facts"]
    texts = data["texts"]
    rows_n = _fmt_count(_fact(facts, "rows"))
    cols_n = _fmt_count(_fact(facts, "columns"))
    k1 = _fact(facts, "k1_rows")
    k2 = _fact(facts, "k2_rows")
    shared = _fact(facts, "shared")
    if shared is None:  # fall back to the shared count carried by the D30 file
        for r in data["d30"]:
            if (r.get("n_shared") or "").strip():
                shared = r["n_shared"].strip()
                break
    dup = _fact(facts, "dup_pairs")
    k2_mode = _fact(facts, "k2_mode") or "NORM (PDD-D-33 default; no PDD_K2_PSID_MODE row in key facts)"
    manifest = data["manifest"]

    era = ""
    if k1 is not None or k2 is not None:
        era = f" K1 rows (2018-2022): {_fmt_count(k1)}; K2 rows (2023-2025): {_fmt_count(k2)}."

    rows: list[list[str]] = [
        ["Item", "Name", "Description"],
        ["Title", "PeCAN Data Dictionary 2018-2025", "Combined surgery-level dataset, pdd.pcnr_2018_2025."],
        ["Generated", generated_at, ""],
        ["Source run", str(manifest.get("run_dttm", "")), f"Profile manifest pcnr_nobs: {manifest.get('pcnr_nobs', '')}"],
        ["Scope", "Surgeries 2018-2025",
         f"One row per surgery: {rows_n} rows and {cols_n} columns (5 key columns plus the PCNR variables).{era}"],
        ["Sheet", "KEY", "This sheet: scope, caveats, limits and conventions."],
        ["Sheet", "VARIABLES",
         "One row per dataset column: PECAN_ID first, the other key columns, then the PCNR variables alphabetically. "
         "Adds year_first, year_last, source_columns (s_codes_with_data), data_status (NO_DATA) and type_note."],
        ["Sheet", "DISTRIBUTIONS", f"Long-format profile of the combined dataset ({n_rows_dist} rows), small cells suppressed."],
        ["Sheet", "NAME_MAP", "Variable coverage by year and source (name_map_vars_coverage)."],
        ["Sheet", "SOURCES", "Source files (source_inventory) when supplied."],
        ["Sheet", "QC", "Reconciliation against the previous dictionary (DD-04), NO_DATA list and PDD-D-30 shared-surgery counts."],
        ["PECAN_ID", "PECAN_ID", texts.get("PECAN_ID dictionary row", "")],
        ["PECAN_ID", "PECAN_ID_KEY_ERA", texts.get("PECAN_ID_KEY_ERA dictionary row", "")],
        ["PECAN_ID", "Caveat", texts.get("KEY sheet caveat", "")],
        ["PECAN_ID", "Dup pairs",
         f"{_fmt_count(dup)} K1 dup pairs are recorded in pdd.pecan_id_dup_link, not merged. PECAN_ID is per "
         "encryption era until the link is applied, so distinct PECAN_ID counts overestimate patients."],
        ["PDD-D-33", "PRECEDE_STUDY_ID",
         f"K2 PRECEDE_STUDY_ID is the normalized Precede##### form, the same as K1 and norm_psid. Mode: {k2_mode}."],
        ["PDD-D-30", "Shared surgeries",
         f"{_fmt_count(shared)} surgeries appear in both the 2024 and 2025 deliveries. The 2024 value wins, "
         "2025 fills gaps where 2024 is missing, and YEAR is 2024."],
        ["Limit", "DD-04 reconciliation",
         "The 2018-2022 slice is compared with the previous dictionary on non-missing counts and distinct-value "
         "counts, NOT level-by-level frequencies. Level-by-level frequencies are not re-profiled on the 2018-2022 slice "
         "(see QC and 18c)."],
        ["Missing values", "Convention",
         "Values as delivered. NULL is read as missing for type-converted variables; placeholders are kept; "
         "no recoding (PDD-D-31 rules)."],
        ["Type", "ASA_Anesth_Record / CPT1_Class", _conditional_text(data)],
        ["NO_DATA", "Variables",
         f"{n_nodata} s06 variables are flagged NO_DATA: they exist in the name map but have no non-missing "
         "value in any source year (VARIABLES.data_status)."],
        ["Naming", "Price sign-off", "Variable naming sign-off by Price is pending; names are as in the frozen name map."],
        ["Suppression", "Small cells",
         "Counts of 1-10 are shown as '<11'. 'suppressed' marks complementary suppression. Ages above 89 are top-coded."],
    ]
    return rows


def _conditional_text(data: dict[str, Any]) -> str:
    parts = []
    for d in data["decisions"]:
        if (d.get("note_kind") or "").strip().upper() == "CONDITIONAL":
            parts.append(f"{d['pcnr_name']}: {d['note_text']}")
    return " ".join(parts) if parts else "(no conditional type notes)"


# ---------------------------------------------------------------------------
# QC sheet
# ---------------------------------------------------------------------------

def _append_table(ws: Any, headers: list[str], rows: list[list]) -> None:
    ws.append(headers)
    for cell in ws[ws.max_row]:
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
    for r in rows:
        ws.append([None if v == "" else v for v in r])
    ws.append([])


def build_qc(ws: Any, data: dict[str, Any], rec_info: dict[str, int], n_vars: int, n_nodata: int) -> None:
    ws.append(["metric", "value"])
    apply_header_row(ws)
    for m, v in [
        ("n_dataset_columns", n_vars),
        ("n_variables_checked_against_recon", rec_info["checked"]),
        ("n_variables_not_comparable_masked", rec_info["not_comparable"]),
        ("n_no_data_variables", n_nodata),
        ("n_recon_rows_explained_Y", sum(1 for r in data["recon"] if (r.get("explained") or "").strip().upper() == "Y")),
    ]:
        ws.append([m, v])
    ws.append([])
    rec_cols = data["recon_headers"]
    _append_table(ws, rec_cols, [[r.get(c, "") for c in rec_cols] for r in data["recon"]])
    nd_cols = ["pcnr_name", "n_nonmiss", "coverage_status", "reconciled"]
    _append_table(ws, nd_cols, [[r.get(c, "") for c in nd_cols] for r in data["nodata"]])
    d_cols = data["d30_headers"]
    _append_table(ws, d_cols, [[r.get(c, "") for c in d_cols] for r in data["d30"]])


# ---------------------------------------------------------------------------
# write / verify
# ---------------------------------------------------------------------------

def write_workbook_2018_2025(
    exchange_dir: Path,
    out_path: Path,
    docs_dir: Path,
    config: dict | None = None,
) -> dict[str, int]:
    """Build, reconcile and write the workbook. Returns data-row counts per sheet."""
    config = dict(DEFAULT_DISPLAY_CONFIG) if config is None else config
    data = load_inputs(exchange_dir, docs_dir)

    total_rows = _as_int(_fact(data["facts"], "rows") or "")
    if total_rows is None:
        raise ValueError("comb_key_facts.csv: rows count missing or not an integer")

    profile_df = data["profile_df"]
    # PDD-D-34 pct guard on the raw exchange files, before any suppression blanks a cell
    _guard_pct_cells("profile_PCNR_2018_2025.csv", profile_df.to_dict("records"), total_rows, profile=True)
    for lbl, key in (("comb_recon.csv", "recon"), ("comb_nodata.csv", "nodata"),
                     ("comb_d30_conflicts.csv", "d30"), ("name_map_vars_coverage.csv", "coverage")):
        _guard_pct_cells(lbl, data[key], total_rows)
    if config.get("age_topcode", True):
        profile_df = apply_age_topcode(
            profile_df, docs_dir / str(config.get("age_variables_file", "age_variables.csv"))
        )
    profile_df = apply_suppression(profile_df, config)  # includes the v1.0 no-leak guard

    var_rows = build_variables_2018_2025(profile_df, data, total_rows, config)
    rec_info = reconcile(var_rows, profile_df, data, total_rows)

    dist_headers, dist_rows = build_distributions_sheet(profile_df)
    n_nodata = sum(1 for r in var_rows if r[11] == "NO_DATA")
    key_rows = build_key_rows(
        data, len(dist_rows), n_nodata, datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    )

    cov_h = data["cov_headers"]
    num_cols = {"first_year", "last_year", "n_sources_data"}
    nm_rows = [
        [(_to_num(r.get(c, "")) if c in num_cols else r.get(c, "")) for c in cov_h]
        for r in data["coverage"]
    ]
    if data["inventory"] is not None:
        inv_h, inv_rows = data["inventory"]
        src_headers = [h for h in inv_h if h != "sha256"] + ["sha256_short"]
        src_rows = [
            [r.get(h, "") for h in inv_h if h != "sha256"] + [(r.get("sha256", "") or "")[:12]]
            for r in inv_rows
        ]
    else:
        src_headers = ["note"]
        src_rows = [["source_inventory.csv not supplied in the exchange folder"]]

    out_path.parent.mkdir(parents=True, exist_ok=True)
    wb = Workbook()
    wb.remove(wb.active)  # type: ignore[arg-type]
    for name in SHEET_ORDER_2018_2025:
        ws = wb.create_sheet(name)
        if name == "KEY":
            write_table(ws, key_rows[0], key_rows[1:])
            for r in range(2, ws.max_row + 1):
                if ws.cell(row=r, column=1).value == "Limit":
                    ws.cell(row=r, column=1).fill = ACCENT_FILL
                    ws.cell(row=r, column=1).font = ACCENT_FONT
        elif name == "VARIABLES":
            write_table(ws, VARIABLES_HEADERS, var_rows)
        elif name == "DISTRIBUTIONS":
            write_table(ws, dist_headers, dist_rows)
        elif name == "NAME_MAP":
            write_table(ws, cov_h, nm_rows)
        elif name == "SOURCES":
            write_table(ws, src_headers, src_rows)
        else:
            build_qc(ws, data, rec_info, len(var_rows), n_nodata)
            style_sheet(ws)
    wb.save(out_path)
    logging.info("Saved %s", out_path)
    return {
        "VARIABLES": len(var_rows),
        "DISTRIBUTIONS": len(dist_rows),
        "NAME_MAP": len(nm_rows),
    }


def verify_workbook_2018_2025(path: Path, expected_data_rows: dict[str, int]) -> None:
    """Re-open and confirm sheet order (KEY leftmost) and data-row counts."""
    wb = load_workbook(path, read_only=True)
    try:
        if wb.sheetnames != SHEET_ORDER_2018_2025:
            raise ValueError(f"sheet order mismatch: {wb.sheetnames} != {SHEET_ORDER_2018_2025}")
        for name, exp in expected_data_rows.items():
            actual = wb[name].max_row - 1
            if actual != exp:
                raise ValueError(f"sheet {name}: {actual} data rows != expected {exp}")
    finally:
        wb.close()
    logging.info("Workbook verified: %s", path)
