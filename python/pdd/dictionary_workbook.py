"""
Core logic for the PeCAN Data Dictionary workbook (D-22, PDD-07).

Reads:   exchange/profile_PCNR.csv
         exchange/name_map_dict.csv
         exchange/source_inventory.csv
Writes:  out/pdd_v1_0.xlsx
Sheets:  KEY | VARIABLES | DISTRIBUTIONS | NAME_MAP | SOURCES | QC |
         PCNC_ | PCND_ | CLK_ | LAB_ | MED_ | INTRA_

LOCKED TRANSFORM ORDER:
  1. Load profile_PCNR.csv
  2. apply_age_topcode (LEVEL rows + STAT value column) — if age_topcode=True
  3. apply_numtext_mask (NUM_TEXT LEVEL rows with n<=10)
  4. apply_suppression (primary then complementary: LEVEL-class, then stat-class)
  5. Build dist_row map from final df
  6. Build sheets

Display rules:
  - '<11'       : PRIMARY suppressed rows only (1<=n<=10)
  - 'suppressed': COMPLEMENTARY suppressed rows only
  - Blank pct_total / pct_nonmiss for all suppressed rows

Age topcode:
  - Tie-break for complementary suppression: suppress ALL tied candidates (conservative)
  - Variable list from docs/age_variables.csv; hard fail if missing or empty
"""

from __future__ import annotations

import csv
import logging
from pathlib import Path
from typing import Any

import pandas as pd
from openpyxl import Workbook, load_workbook
from openpyxl.worksheet.hyperlink import Hyperlink

from pdd.xlsx_style import HEADER_FILL, HEADER_FONT, apply_header_row, style_sheet, write_table

SHEET_ORDER = [
    "KEY",
    "VARIABLES",
    "DISTRIBUTIONS",
    "NAME_MAP",
    "SOURCES",
    "QC",
    "PCNC_",
    "PCND_",
    "CLK_",
    "LAB_",
    "MED_",
    "INTRA_",
]

DEFAULT_DISPLAY_CONFIG: dict[str, Any] = {
    "small_cell_mode": "suppress",
    "age_topcode": True,
    "age_variables_file": "age_variables.csv",  # filename only; resolved vs docs_dir at runtime
    "all_missing_label": "No values (100% missing)",
}

# STAT rows where the VALUE column holds the statistic (not n column)
_STAT_VALUE_ROWS = frozenset(["MEAN", "SD", "MEDIAN", "Q1", "Q3", "MIN", "MAX", "RANGE_MIN", "RANGE_MAX"])

# STAT rows subject to age topcode (value column)
_AGE_TOPCODE_STAT_ROWS = frozenset(["MIN", "MAX", "MEDIAN", "Q1", "Q3"])

# Stat rows considered count-like (n column holds an integer count)
_COUNT_STAT_ROWS = frozenset(["N", "N_MISSING", "N_UNPARSED"])

# Level-class rows eligible for small-cell suppression
_LEVEL_CLASS_ROWS = frozenset(["LEVEL", "OTHER", "MISSING"])

# Var classes that have count-stat rows for stat-class suppression
_STAT_CLASS_VAR_CLASSES = frozenset(["CONT_NUM", "DATE", "NUM_TEXT", "SUPPRESSED"])

PLACEHOLDER_TEXT = {
    "PCNC_": "(source pending — Phase 8)",
    "PCND_": "(source pending — Phase 13)",
    "CLK_": "(source pending — Phase 9)",
    "LAB_": "(source pending — Phase 10)",
    "MED_": "(source pending — Phase 11)",
    "INTRA_": "(source pending — Phase 12)",
}

REQUIRED_PROFILE_COLS = [
    "family", "variable", "var_class", "stat", "level",
    "n", "value", "pct_total", "pct_nonmiss", "sort_order",
    "small_cell_flag", "date_kind", "display_format",
]

REQUIRED_NAMEMAP_COLS = [
    "s_code", "col_order", "sas_name", "original_header", "trunc_flag",
    "status", "group_id", "pcnr_name", "sas_type", "length",
]

REQUIRED_INVENTORY_COLS = ["s_code", "filename", "row_count", "col_count", "sha256", "mod_date"]


# ---------------------------------------------------------------------------
# CSV reading
# ---------------------------------------------------------------------------

def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Return (fieldnames, rows). fieldnames is non-empty even for header-only files."""
    with path.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)
        headers = list(reader.fieldnames or [])
    return headers, rows


# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

def _assert_columns(label: str, headers: list[str], required: list[str]) -> None:
    missing = [c for c in required if c not in headers]
    if missing:
        raise ValueError(f"{label}: missing required columns: {', '.join(missing)}")


# ---------------------------------------------------------------------------
# Numeric helpers
# ---------------------------------------------------------------------------

def _numeric_gt89(val: Any) -> bool:
    try:
        return float(val) > 89
    except (TypeError, ValueError):
        return False


def _to_int_n(val: Any) -> int | None:
    """Convert n column value to int; return None if not a plain integer string."""
    if val is None or str(val).strip() in ("", "<11", "suppressed"):
        return None
    try:
        f = float(val)
        if f == int(f):
            return int(f)
        return None
    except (TypeError, ValueError):
        return None


# ---------------------------------------------------------------------------
# Age topcode
# ---------------------------------------------------------------------------

def apply_age_topcode(df: pd.DataFrame, age_file: Path) -> pd.DataFrame:
    """
    Apply age top-coding to df.

    age_file: path to age_variables.csv (columns: variable, reason).
    Raises FileNotFoundError if file missing; ValueError if file has no data rows.

    For age variables:
      - LEVEL rows with level > 89: set level='90+'; aggregate multiple such rows.
      - STAT rows (MIN/MAX/MEDIAN/Q1/Q3) with value > 89: set value='90+'.
      - MEAN/SD: unchanged.
    After aggregating '90+' LEVEL rows: recompute pct_total, pct_nonmiss, small_cell_flag.
    """
    if not age_file.exists():
        raise FileNotFoundError(
            f"Age variables file not found: {age_file}"
        )
    age_df = pd.read_csv(age_file, dtype=str)
    if age_df.empty or "variable" not in age_df.columns:
        raise ValueError(
            f"Age variables file is empty or missing 'variable' column: {age_file}"
        )
    age_vars = set(age_df["variable"].dropna().str.strip())
    if not age_vars:
        raise ValueError(
            f"Age variables file has no variable entries: {age_file}"
        )

    df = df.copy()

    mask_age = df["variable"].isin(age_vars)

    # --- STAT rows: value column ---
    mask_stat = mask_age & df["stat"].isin(_AGE_TOPCODE_STAT_ROWS)
    df.loc[mask_stat, "value"] = df.loc[mask_stat, "value"].apply(
        lambda v: "90+" if _numeric_gt89(v) else v
    )

    # --- LEVEL rows: level column; aggregate if multiple map to '90+' ---
    mask_level = mask_age & (df["stat"] == "LEVEL")

    # For each age variable separately
    for var_name in df.loc[mask_level, "variable"].unique():
        var_mask = mask_level & (df["variable"] == var_name)
        var_level_rows = df[var_mask].copy()

        # Find rows where level > 89
        topcode_mask = var_level_rows["level"].apply(_numeric_gt89)
        topcode_rows = var_level_rows[topcode_mask]
        keep_rows = var_level_rows[~topcode_mask]

        if topcode_rows.empty:
            continue

        # Get total_rows for this variable from N stat row
        n_stat = df[(df["variable"] == var_name) & (df["stat"] == "N")]
        total_rows_var = None
        n_nonmiss_var = None
        if not n_stat.empty:
            try:
                total_rows_var = float(n_stat.iloc[0]["n"])
            except (TypeError, ValueError):
                total_rows_var = None

        # n_nonmiss for pct_nonmiss recompute — use N stat row value
        n_nonmiss_var = total_rows_var  # N stat = non-missing count for CONT_NUM

        # Aggregate topcode rows
        n_sum = 0.0
        for _, r in topcode_rows.iterrows():
            try:
                n_sum += float(r["n"])
            except (TypeError, ValueError):
                pass

        # Build merged row from first topcode row
        merged = topcode_rows.iloc[0].copy()
        merged["level"] = "90+"
        merged["n"] = str(int(n_sum)) if n_sum == int(n_sum) else str(n_sum)

        # Recompute pct_total and pct_nonmiss
        if total_rows_var and total_rows_var > 0:
            merged["pct_total"] = str(round(n_sum / total_rows_var * 100, 1))
        if n_nonmiss_var and n_nonmiss_var > 0:
            merged["pct_nonmiss"] = str(round(n_sum / n_nonmiss_var * 100, 1))

        # Recompute small_cell_flag
        merged["small_cell_flag"] = "Y" if 1 <= n_sum <= 10 else "N"

        # Replace topcode rows with merged row in df
        df = df[~var_mask].copy()
        # Rebuild: keep_rows + merged
        combined = pd.concat([keep_rows, pd.DataFrame([merged])], ignore_index=True)
        df = pd.concat([df, combined], ignore_index=True)

    return df


# ---------------------------------------------------------------------------
# NUM_TEXT level masking
# ---------------------------------------------------------------------------

def apply_numtext_mask(df: pd.DataFrame) -> pd.DataFrame:
    """
    For NUM_TEXT rows where stat='LEVEL' and 1<=n<=10, replace level with 'other text entry'.
    Runs BEFORE suppression.
    """
    df = df.copy()
    mask = (
        (df["var_class"] == "NUM_TEXT") &
        (df["stat"] == "LEVEL")
    )
    numeric_n = pd.to_numeric(df.loc[mask, "n"], errors="coerce")
    small_mask = mask.copy()
    small_mask[mask] = (numeric_n >= 1) & (numeric_n <= 10)
    df.loc[small_mask, "level"] = "other text entry"
    return df


# ---------------------------------------------------------------------------
# Suppression
# ---------------------------------------------------------------------------

def apply_suppression(df: pd.DataFrame, config: dict) -> pd.DataFrame:
    """
    Apply primary and complementary suppression.

    Modes:
      suppress (default): replace n with '<11', blank pct cols.
      raw: no changes.
      asterisk: append '*' to level text; n unchanged.

    Complementary suppression (suppress mode only):
      After primary, for each variable: if exactly 1 LEVEL-class row is primary-suppressed,
      suppress next-smallest non-zero n row. Ties: suppress ALL tied rows.
      '<11' = primary only. 'suppressed' = complementary only.

    Stat-class suppression (suppress mode only):
      For CONT_NUM/DATE/NUM_TEXT/SUPPRESSED variables:
        N, N_MISSING, N_UNPARSED rows (n column).
        Primary: 1<=n<=10 -> '<11', pct blank.
        Complementary: if exactly 1 primary, suppress next-smallest -> 'suppressed', pct blank.
      When N itself is primary-suppressed (1<=N<=10):
        - Blank all stat value cells (MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX/RANGE_MIN/RANGE_MAX).
    """
    mode = config.get("small_cell_mode", "suppress")
    df = df.copy()

    if mode == "raw":
        return df

    if mode == "asterisk":
        mask = df["small_cell_flag"] == "Y"
        df.loc[mask & df["stat"].isin(_LEVEL_CLASS_ROWS), "level"] = (
            df.loc[mask & df["stat"].isin(_LEVEL_CLASS_ROWS), "level"].apply(
                lambda v: str(v) + "*" if not str(v).endswith("*") else v
            )
        )
        return df

    # suppress mode
    # --- Apply NUM_TEXT masking first ---
    df = apply_numtext_mask(df)

    # Track which rows were primary-suppressed (for stat-class n-value blanking)
    df["_primary_suppressed"] = False
    df["_comp_suppressed"] = False
    df["_stat_primary"] = False
    df["_stat_comp"] = False

    # --- Step 1: LEVEL-class primary suppression ---
    prim_mask = (df["small_cell_flag"] == "Y") & df["stat"].isin(_LEVEL_CLASS_ROWS)
    df.loc[prim_mask, "_primary_suppressed"] = True
    df.loc[prim_mask, "n"] = "<11"
    df.loc[prim_mask, "pct_total"] = ""
    df.loc[prim_mask, "pct_nonmiss"] = ""

    # --- Step 2: LEVEL-class complementary suppression ---
    for var_name in df["variable"].unique():
        var_mask = df["variable"] == var_name
        var_rows = df[var_mask].copy()

        level_class = var_rows[var_rows["stat"].isin(_LEVEL_CLASS_ROWS)]
        n_primary = level_class["_primary_suppressed"].sum()

        if n_primary != 1:
            continue

        candidates = level_class[
            ~level_class["_primary_suppressed"] &
            level_class["n"].apply(lambda v: _to_int_n(v) is not None and _to_int_n(v) > 0)
        ]
        if candidates.empty:
            continue

        min_n = candidates["n"].apply(lambda v: _to_int_n(v)).min()
        tie_idx = candidates[candidates["n"].apply(lambda v: _to_int_n(v)) == min_n].index

        df.loc[tie_idx, "_comp_suppressed"] = True
        df.loc[tie_idx, "n"] = "suppressed"
        df.loc[tie_idx, "pct_total"] = ""
        df.loc[tie_idx, "pct_nonmiss"] = ""

    # --- Step 3: Stat-class suppression (N / N_MISSING / N_UNPARSED) ---
    for var_name in df["variable"].unique():
        var_mask = df["variable"] == var_name
        var_rows = df[var_mask]
        if var_rows["var_class"].iloc[0] not in _STAT_CLASS_VAR_CLASSES:
            continue

        count_stat_mask = var_mask & df["stat"].isin(_COUNT_STAT_ROWS)
        count_rows = df[count_stat_mask].copy()
        if count_rows.empty:
            continue

        # Primary: 1<=n<=10
        primary_idx = []
        for idx, row in count_rows.iterrows():
            n_val = _to_int_n(row["n"])
            if n_val is not None and 1 <= n_val <= 10:
                primary_idx.append(idx)

        if not primary_idx:
            continue

        df.loc[primary_idx, "_stat_primary"] = True
        df.loc[primary_idx, "n"] = "<11"
        df.loc[primary_idx, "pct_total"] = ""
        df.loc[primary_idx, "pct_nonmiss"] = ""

        # If N itself is primary-suppressed: blank all stat value rows for this variable
        n_row_idx = count_rows[count_rows["stat"] == "N"].index
        n_was_primary = any(idx in primary_idx for idx in n_row_idx)
        if n_was_primary:
            stat_val_mask = var_mask & df["stat"].isin(_STAT_VALUE_ROWS)
            df.loc[stat_val_mask, "value"] = ""

        # Complementary: if exactly 1 primary, suppress next-smallest
        if len(primary_idx) == 1:
            remaining = count_rows.drop(index=primary_idx)
            candidates = remaining[remaining["n"].apply(
                lambda v: _to_int_n(v) is not None and _to_int_n(v) > 0
            )]
            if not candidates.empty:
                min_n = candidates["n"].apply(lambda v: _to_int_n(v)).min()
                tie_idx_c = candidates[candidates["n"].apply(lambda v: _to_int_n(v)) == min_n].index
                df.loc[tie_idx_c, "_stat_comp"] = True
                df.loc[tie_idx_c, "n"] = "suppressed"
                df.loc[tie_idx_c, "pct_total"] = ""
                df.loc[tie_idx_c, "pct_nonmiss"] = ""

    # --- No-leak guard ---
    _assert_no_leak(df)

    # Clean up internal tracking columns
    df = df.drop(columns=["_primary_suppressed", "_comp_suppressed", "_stat_primary", "_stat_comp"])

    return df


def _assert_no_leak(df: pd.DataFrame) -> None:
    """
    Assert no row that was subject to suppression still holds a raw integer 1-10.
    Raises RuntimeError('suppression leak detected') if any leak found.
    """
    suppressed_rows = df[
        df["_primary_suppressed"] | df["_comp_suppressed"] |
        df["_stat_primary"] | df["_stat_comp"]
    ]
    for _, row in suppressed_rows.iterrows():
        n_val = _to_int_n(row["n"])
        if n_val is not None and 1 <= n_val <= 10:
            raise RuntimeError(
                f"suppression leak detected: variable={row['variable']} "
                f"stat={row['stat']} n={row['n']!r}"
            )


# ---------------------------------------------------------------------------
# VARIABLES sheet
# ---------------------------------------------------------------------------

def build_variables_sheet(
    profile_df: pd.DataFrame,
    namemap_df: pd.DataFrame,
    dist_row: dict[str, int],
    config: dict,
    total_rows: int | None = None,
) -> tuple[list[str], list[list]]:
    """
    Build VARIABLES sheet.
    Returns (headers, data_rows) where each data row is a list.
    dist_row: pcnr_name -> first row number in DISTRIBUTIONS (for hyperlinks, applied later).
    total_rows: total rows in the dataset (for pct_missing calculation).
    """
    headers = [
        "pcnr_name",
        "original_headers",
        "source_s_codes",
        "storage_type",
        "var_class",
        "n_nonmiss",
        "pct_missing",
        "n_distinct",
        "all_missing",
        "summary",
    ]

    # Build name_map lookup: pcnr_name -> {original_headers, source_s_codes, storage_type}
    nm_lookup: dict[str, dict] = {}
    if not namemap_df.empty:
        for _, row in namemap_df.iterrows():
            pname = str(row.get("pcnr_name", "") or "").strip()
            if not pname:
                continue
            if pname not in nm_lookup:
                nm_lookup[pname] = {
                    "original_headers": [],
                    "source_s_codes": set(),
                    "storage_type": str(row.get("sas_type", "") or ""),
                }
            orig = str(row.get("original_header", "") or "").strip()
            if orig:
                nm_lookup[pname]["original_headers"].append(orig)
            sc = str(row.get("s_code", "") or "").strip()
            if sc:
                nm_lookup[pname]["source_s_codes"].add(sc)

    variables = profile_df["variable"].unique()
    rows_out = []

    for var_name in sorted(variables):
        var_rows = profile_df[profile_df["variable"] == var_name]
        var_class = str(var_rows["var_class"].iloc[0])

        # --- n_nonmiss derivation ---
        n_nonmiss, pct_missing = _derive_n_nonmiss(var_rows, var_class, total_rows)

        # --- n_distinct derivation ---
        n_distinct = _derive_n_distinct(var_rows, var_class)

        # --- all_missing ---
        all_missing = "N"
        if isinstance(n_nonmiss, int) and n_nonmiss == 0:
            all_missing = "Y"
        elif n_nonmiss == 0:
            all_missing = "Y"

        # --- summary text ---
        summary = _build_summary(var_rows, var_class, n_nonmiss, config)

        # --- name_map lookup ---
        nm = nm_lookup.get(var_name, {})
        original_headers = " | ".join(nm.get("original_headers", []))
        source_s_codes = " ".join(sorted(nm.get("source_s_codes", set())))
        storage_type = nm.get("storage_type", "")

        rows_out.append([
            var_name,
            original_headers,
            source_s_codes,
            storage_type,
            var_class,
            n_nonmiss,
            pct_missing,
            n_distinct,
            all_missing,
            summary,
        ])

    return headers, rows_out


def _derive_n_nonmiss(
    var_rows: pd.DataFrame,
    var_class: str,
    total_rows: int | None,
) -> tuple[Any, Any]:
    """
    Returns (n_nonmiss_display, pct_missing_display).
    Returns strings like '<11', 'suppressed', '<11 missing' when suppression applies.
    """
    if var_class in ("LOW_CARD", "HIGH_CARD"):
        missing_row = var_rows[var_rows["stat"] == "MISSING"]
        if missing_row.empty:
            # No MISSING row -> all values present
            if total_rows is not None:
                return total_rows, 0.0
            return "", ""

        miss_n_raw = str(missing_row.iloc[0]["n"]).strip()
        if miss_n_raw == "<11":
            return "<11 missing", ""
        if miss_n_raw == "suppressed":
            return "suppressed", ""

        miss_n = _to_int_n(miss_n_raw)
        if miss_n is None:
            return "", ""

        if total_rows is not None:
            n_nm = total_rows - miss_n
            pct_miss = round(miss_n / total_rows * 100, 1) if total_rows > 0 else 0.0
            return n_nm, pct_miss
        return "", ""

    elif var_class in ("CONT_NUM", "DATE", "SUPPRESSED"):
        n_row = var_rows[var_rows["stat"] == "N"]
        if n_row.empty:
            return "", ""
        n_raw = str(n_row.iloc[0]["n"]).strip()
        return _resolve_count_cell(n_raw, total_rows)

    elif var_class == "NUM_TEXT":
        n_row = var_rows[var_rows["stat"] == "N"]
        unp_row = var_rows[var_rows["stat"] == "N_UNPARSED"]

        n_raw = str(n_row.iloc[0]["n"]).strip() if not n_row.empty else ""
        unp_raw = str(unp_row.iloc[0]["n"]).strip() if not unp_row.empty else ""

        # If either is suppressed, propagate
        if n_raw in ("<11", "suppressed"):
            return _resolve_count_cell(n_raw, total_rows)
        if unp_raw in ("<11", "suppressed"):
            return _resolve_count_cell(unp_raw, total_rows)

        n_val = _to_int_n(n_raw)
        unp_val = _to_int_n(unp_raw) or 0
        if n_val is None:
            return "", ""
        n_nm = n_val + unp_val
        pct_miss = ""
        if total_rows and total_rows > 0:
            miss = total_rows - n_nm
            pct_miss = round(miss / total_rows * 100, 1)
        return n_nm, pct_miss

    return "", ""


def _resolve_count_cell(n_raw: str, total_rows: int | None) -> tuple[Any, Any]:
    """Resolve a count cell that might be suppressed."""
    if n_raw == "<11":
        return "<11", ""
    if n_raw == "suppressed":
        return "suppressed", ""
    n_val = _to_int_n(n_raw)
    if n_val is None:
        return "", ""
    pct_miss = ""
    if total_rows and total_rows > 0:
        miss = total_rows - n_val
        pct_miss = round(miss / total_rows * 100, 1)
    return n_val, pct_miss


def _derive_n_distinct(var_rows: pd.DataFrame, var_class: str) -> Any:
    """Derive n_distinct per var_class."""
    if var_class == "LOW_CARD":
        return int((var_rows["stat"] == "LEVEL").sum())
    elif var_class in ("HIGH_CARD", "NUM_TEXT", "SUPPRESSED"):
        nd_row = var_rows[var_rows["stat"] == "N_DISTINCT"]
        if not nd_row.empty:
            n_val = _to_int_n(str(nd_row.iloc[0]["n"]))
            return n_val if n_val is not None else ""
        return ""
    # CONT_NUM, DATE: blank
    return ""


def _build_summary(
    var_rows: pd.DataFrame,
    var_class: str,
    n_nonmiss: Any,
    config: dict,
) -> str:
    """Build summary text for a variable."""
    all_missing_label = config.get("all_missing_label", "No values (100% missing)")

    # Check all_missing
    if isinstance(n_nonmiss, int) and n_nonmiss == 0:
        return all_missing_label
    if n_nonmiss == 0:
        return all_missing_label

    # N primary-suppressed
    if n_nonmiss == "<11":
        return "fewer than 11 values"

    if var_class == "LOW_CARD":
        return _summary_low_card(var_rows)
    elif var_class == "HIGH_CARD":
        return _summary_high_card(var_rows)
    elif var_class in ("CONT_NUM", "DATE"):
        return _summary_cont_num(var_rows)
    elif var_class == "NUM_TEXT":
        return _summary_num_text(var_rows)
    elif var_class == "SUPPRESSED":
        return _summary_suppressed(var_rows)
    return ""


def _summary_low_card(var_rows: pd.DataFrame) -> str:
    level_rows = var_rows[var_rows["stat"] == "LEVEL"].copy()
    try:
        level_rows["_sort"] = pd.to_numeric(level_rows["sort_order"], errors="coerce")
        level_rows = level_rows.sort_values("_sort")
    except Exception:
        pass

    parts = []
    for _, row in level_rows.head(3).iterrows():
        lbl = str(row["level"])
        if len(lbl) > 20:
            lbl = lbl[:20] + "…"
        n_raw = str(row["n"]).strip()
        if n_raw == "<11":
            parts.append(f"{lbl} <11")
        elif n_raw == "suppressed":
            parts.append(f"{lbl} suppressed")
        else:
            pct = str(row["pct_total"]).strip()
            if pct:
                try:
                    parts.append(f"{lbl} {float(pct):.1f}%")
                except (TypeError, ValueError):
                    parts.append(lbl)
            else:
                parts.append(lbl)

    return ", ".join(parts)


def _summary_high_card(var_rows: pd.DataFrame) -> str:
    nd_row = var_rows[var_rows["stat"] == "N_DISTINCT"]
    n_dist = ""
    if not nd_row.empty:
        n_dist = str(nd_row.iloc[0]["n"]).strip()

    level_rows = var_rows[var_rows["stat"] == "LEVEL"].copy()
    try:
        level_rows["_sort"] = pd.to_numeric(level_rows["sort_order"], errors="coerce")
        level_rows = level_rows.sort_values("_sort")
    except Exception:
        pass

    top_parts = []
    for _, row in level_rows.head(2).iterrows():
        lbl = str(row["level"])[:20]
        pct = str(row["pct_total"]).strip()
        try:
            top_parts.append(f"{lbl} {float(pct):.1f}%")
        except (TypeError, ValueError):
            top_parts.append(lbl)

    if top_parts:
        return f"N distinct: {n_dist}; top: {', '.join(top_parts)}"
    return f"N distinct: {n_dist}"


def _summary_cont_num(var_rows: pd.DataFrame) -> str:
    def _get_val(stat_name: str) -> str:
        row = var_rows[var_rows["stat"] == stat_name]
        if row.empty:
            return ""
        v = str(row.iloc[0]["value"]).strip()
        return v if v else ""

    mean = _get_val("MEAN")
    sd = _get_val("SD")
    median = _get_val("MEDIAN")
    q1 = _get_val("Q1")
    q3 = _get_val("Q3")
    min_v = _get_val("MIN")
    max_v = _get_val("MAX")

    parts = []
    if mean:
        parts.append(f"mean {mean}")
        if sd:
            parts[-1] += f" (SD {sd})"
    if median:
        part = f"median {median}"
        if q1 and q3:
            part += f" [{q1}–{q3}]"
        parts.append(part)
    if min_v and max_v:
        parts.append(f"min {min_v} – max {max_v}")
    return "; ".join(parts)


def _summary_num_text(var_rows: pd.DataFrame) -> str:
    def _get_val(stat_name: str) -> str:
        row = var_rows[var_rows["stat"] == stat_name]
        if row.empty:
            return ""
        v = str(row.iloc[0]["value"]).strip()
        return v if v else ""

    def _get_n(stat_name: str) -> str:
        row = var_rows[var_rows["stat"] == stat_name]
        if row.empty:
            return ""
        return str(row.iloc[0]["n"]).strip()

    mean = _get_val("MEAN")
    sd = _get_val("SD")
    median = _get_val("MEDIAN")
    n_unp = _get_n("N_UNPARSED")

    parts = []
    if mean:
        parts.append(f"mean {mean}" + (f" (SD {sd})" if sd else ""))
    if median:
        parts.append(f"median {median}")
    if n_unp:
        parts.append(f"{n_unp} unparsed")
    return "; ".join(parts)


def _summary_suppressed(var_rows: pd.DataFrame) -> str:
    disp_fmt = ""
    for _, row in var_rows.iterrows():
        v = str(row.get("display_format", "") or "").strip()
        if v:
            disp_fmt = v
            break

    def _get_val(stat_name: str) -> str:
        row = var_rows[var_rows["stat"] == stat_name]
        if row.empty:
            return ""
        v = str(row.iloc[0]["value"]).strip()
        return v if v else ""

    min_v = _get_val("RANGE_MIN") or _get_val("MIN")
    max_v = _get_val("RANGE_MAX") or _get_val("MAX")

    if disp_fmt.upper() == "LENGTH":
        return f"Values withheld; length {min_v}–{max_v}"
    return f"Values withheld; range {min_v}–{max_v}"


# ---------------------------------------------------------------------------
# DISTRIBUTIONS sheet
# ---------------------------------------------------------------------------

def build_distributions_sheet(
    profile_df: pd.DataFrame,
) -> tuple[list[str], list[list]]:
    """Return (headers, data_rows) for DISTRIBUTIONS sheet."""
    headers = list(profile_df.columns)
    rows_out = []
    for _, row in profile_df.iterrows():
        rows_out.append([row[c] for c in headers])
    return headers, rows_out


# ---------------------------------------------------------------------------
# NAME_MAP sheet
# ---------------------------------------------------------------------------

def build_name_map_sheet(
    namemap_df: pd.DataFrame,
) -> tuple[list[str], list[list]]:
    """Return (headers, data_rows) for NAME_MAP sheet."""
    headers = REQUIRED_NAMEMAP_COLS
    rows_out = []
    for _, row in namemap_df.sort_values(
        by=["s_code", "col_order"],
        key=lambda s: s.apply(lambda v: (int(float(v)) if str(v).replace(".", "").isdigit() else 0) if s.name == "col_order" else v),
    ).iterrows():
        rows_out.append([str(row.get(c, "") or "") for c in headers])
    return headers, rows_out


# ---------------------------------------------------------------------------
# SOURCES sheet
# ---------------------------------------------------------------------------

def build_sources_sheet(
    inventory_df: pd.DataFrame,
    docs_dir: Path,
) -> tuple[list[str], list[list]]:
    """Return (headers, data_rows) for SOURCES sheet. source_notes.csv is optional."""
    try:
        notes_df = pd.read_csv(docs_dir / "source_notes.csv", dtype=str)
    except FileNotFoundError:
        notes_df = pd.DataFrame(columns=["s_code", "description"])

    merged = inventory_df.merge(notes_df[["s_code", "description"]], on="s_code", how="left")

    headers = ["s_code", "filename", "row_count", "col_count", "sha256_short", "mod_date", "description"]
    rows_out = []
    for _, row in merged.iterrows():
        sha = str(row.get("sha256", "") or "")
        sha_short = sha[:12] if sha else ""
        rows_out.append([
            str(row.get("s_code", "") or ""),
            str(row.get("filename", "") or ""),
            str(row.get("row_count", "") or ""),
            str(row.get("col_count", "") or ""),
            sha_short,
            str(row.get("mod_date", "") or ""),
            str(row.get("description", "") or ""),
        ])
    return headers, rows_out


# ---------------------------------------------------------------------------
# QC sheet
# ---------------------------------------------------------------------------

def build_qc_sheet(profile_df: pd.DataFrame, ws: Any) -> None:
    """Write QC sheet to ws with two tables."""
    # Table 1: var_class breakdown
    var_classes = profile_df.groupby("variable")["var_class"].first()
    class_counts = var_classes.value_counts().sort_index()

    t1_headers = ["var_class", "n_variables"]
    ws.append(t1_headers)
    apply_header_row(ws)
    for vc, cnt in class_counts.items():
        ws.append([vc, int(cnt)])

    ws.append([])  # blank separator row

    # Table 2: scalar metrics
    n_small_cell_vars = int(
        profile_df[profile_df["small_cell_flag"] == "Y"]["variable"].nunique()
    )
    n_suppressed_vars = int((var_classes == "SUPPRESSED").sum())

    # Derive n_all_missing by checking each variable's n_nonmiss
    all_missing_count = 0
    for var_name in profile_df["variable"].unique():
        var_rows = profile_df[profile_df["variable"] == var_name]
        vc = str(var_rows["var_class"].iloc[0])
        n_nm, _ = _derive_n_nonmiss(var_rows, vc, None)
        if isinstance(n_nm, int) and n_nm == 0:
            all_missing_count += 1
        elif n_nm == 0:
            all_missing_count += 1

    t2_start_row = ws.max_row + 1
    t2_headers = ["metric", "value"]
    ws.append(t2_headers)
    # Style t2 header
    for cell in ws[t2_start_row]:
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT

    ws.append(["n_small_cell_vars", n_small_cell_vars])
    ws.append(["n_suppressed_vars", n_suppressed_vars])
    ws.append(["n_all_missing_vars", all_missing_count])


# ---------------------------------------------------------------------------
# KEY sheet
# ---------------------------------------------------------------------------

def _key_rows() -> list[list[str]]:
    """Documentation rows for KEY sheet."""
    return [
        ["Item", "Name", "Description"],
        # Sheet purposes
        ["Sheet", "KEY", "This sheet. Documents all sheets, columns, and display rules."],
        ["Sheet", "VARIABLES", "One row per PCNR_ variable (1,297 rows). pcnr_name hyperlinks to DISTRIBUTIONS sheet."],
        ["Sheet", "DISTRIBUTIONS", "One row per (variable, stat/level) from profile_PCNR.csv. Long format. n and value in separate columns."],
        ["Sheet", "NAME_MAP", "All name_map rows. Every source column and its fate (PCNR / KEY / EXCLUDED_CLK / LINKAGE_ONLY / DUPLICATE_DROPPED)."],
        ["Sheet", "SOURCES", "Source files from pdd.source_inventory. Left-joined with docs/source_notes.csv for descriptions."],
        ["Sheet", "QC", "Summary counts: variables by var_class, n flagged small-cell, n SUPPRESSED, n all-missing."],
        ["Sheet", "PCNC_", "(source pending — Phase 8)"],
        ["Sheet", "PCND_", "(source pending — Phase 13)"],
        ["Sheet", "CLK_", "(source pending — Phase 9)"],
        ["Sheet", "LAB_", "(source pending — Phase 10)"],
        ["Sheet", "MED_", "(source pending — Phase 11)"],
        ["Sheet", "INTRA_", "(source pending — Phase 12)"],
        # Transform order
        ["Transform", "1. Load", "profile_PCNR.csv loaded into DataFrame with 13-column schema."],
        ["Transform", "2. Age topcode", "LEVEL rows level>89 merged to '90+' (sum n, recompute pct, recompute small_cell_flag). STAT rows MIN/MAX/MEDIAN/Q1/Q3 value>89 set to '90+'. MEAN/SD unchanged. Variables from docs/age_variables.csv."],
        ["Transform", "3. NUM_TEXT mask", "NUM_TEXT LEVEL rows with n<=10 have level replaced with 'other text entry' before suppression."],
        ["Transform", "4. Suppression", "Primary then complementary (LEVEL-class), then stat-class (N/N_MISSING/N_UNPARSED)."],
        ["Transform", "5. dist_row map", "Built from final transformed df. Row index maps pcnr_name to first DISTRIBUTIONS row."],
        ["Transform", "6. Build sheets", "All sheets built from transformed df only."],
        # Suppression rules
        ["Suppression", "Primary", "small_cell_flag='Y' LEVEL/OTHER/MISSING rows: n replaced with '<11', pct_total and pct_nonmiss blanked."],
        ["Suppression", "Complementary", "If exactly 1 primary-suppressed row per variable: next-smallest non-zero n row also suppressed as 'suppressed'. Tie-break: ALL tied rows suppressed (conservative)."],
        ["Suppression", "<11 vs suppressed", "'<11' is ONLY for primary-suppressed cells. 'suppressed' is ONLY for complementary-suppressed cells."],
        ["Suppression", "Stat-class", "N/N_MISSING/N_UNPARSED rows: primary if 1<=n<=10. Complementary if exactly 1 primary and other count rows exist. When N itself is primary: blank MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX/RANGE_MIN/RANGE_MAX."],
        ["Suppression", "No-leak guard", "After transforms, RuntimeError raised if any suppressed row still holds integer 1-10."],
        # Age topcode
        ["Age topcode", "Variables", "From docs/age_variables.csv (variable, reason). Hard fail if file missing or empty."],
        ["Age topcode", "Tie-break", "Multiple LEVEL rows >89 all merged to '90+'. n summed. pct recomputed. small_cell_flag recomputed."],
        # VARIABLES columns
        ["Column", "VARIABLES.n_nonmiss", "LOW/HIGH_CARD: total_rows - MISSING n. CONT_NUM/DATE/SUPPRESSED: N stat n. NUM_TEXT: N + N_UNPARSED. If MISSING row suppressed: '<11 missing'. If N primary-suppressed: '<11'. If N complementary-suppressed: 'suppressed'."],
        ["Column", "VARIABLES.pct_missing", "Derived: (total_rows - n_nonmiss) / total_rows * 100. Blank if any suppression involved."],
        ["Column", "VARIABLES.n_distinct", "LOW_CARD: count of LEVEL rows. HIGH_CARD/NUM_TEXT/SUPPRESSED: N_DISTINCT stat n. CONT_NUM/DATE: blank."],
        ["Column", "VARIABLES.all_missing", "Y if n_nonmiss==0, N otherwise."],
        ["Column", "VARIABLES.summary", "Rule-generated text. 'fewer than 11 values' if N is primary-suppressed. 'No values (100% missing)' if all-missing."],
    ]


# ---------------------------------------------------------------------------
# write_workbook
# ---------------------------------------------------------------------------

def write_workbook(
    exchange_dir: Path,
    out_path: Path,
    docs_dir: Path,
    config: dict | None = None,
) -> dict[str, int]:
    """
    Read exchange CSVs, apply transforms, write 12-sheet workbook.

    Returns dict[str, int] with row counts for VARIABLES, DISTRIBUTIONS, NAME_MAP.
    """
    if config is None:
        config = dict(DEFAULT_DISPLAY_CONFIG)

    # --- Load CSVs ---
    profile_headers, profile_rows = read_csv(exchange_dir / "profile_PCNR.csv")
    _assert_columns("profile_PCNR.csv", profile_headers, REQUIRED_PROFILE_COLS)

    nm_headers, nm_rows = read_csv(exchange_dir / "name_map_dict.csv")
    _assert_columns("name_map_dict.csv", nm_headers, REQUIRED_NAMEMAP_COLS)

    inv_headers, inv_rows = read_csv(exchange_dir / "source_inventory.csv")
    _assert_columns("source_inventory.csv", inv_headers, REQUIRED_INVENTORY_COLS)

    # Convert to DataFrames
    profile_df = pd.DataFrame(profile_rows, columns=profile_headers)
    namemap_df = pd.DataFrame(nm_rows, columns=nm_headers)
    inventory_df = pd.DataFrame(inv_rows, columns=inv_headers)

    # --- Derive total_rows from profile ---
    # Use mode of N stat rows across all variables (or max)
    n_vals = pd.to_numeric(
        profile_df[profile_df["stat"] == "N"]["n"], errors="coerce"
    ).dropna()
    if len(n_vals) > 0:
        total_rows = int(n_vals.max())
    else:
        # Try MISSING + non-missing sum for LOW_CARD
        total_rows = None

    # --- LOCKED TRANSFORM ORDER ---

    # Step 2: age topcode
    if config.get("age_topcode", True):
        age_file = docs_dir / str(config.get("age_variables_file", "age_variables.csv"))
        profile_df = apply_age_topcode(profile_df, age_file)

    # Step 3+4: suppression (numtext mask runs inside apply_suppression)
    profile_df = apply_suppression(profile_df, config)

    # Step 5: build dist_row map
    dist_row: dict[str, int] = {}
    row_num = 2  # row 1 = header
    for _, row in profile_df.iterrows():
        var_name = str(row["variable"])
        if var_name not in dist_row:
            dist_row[var_name] = row_num
        row_num += 1

    # Step 6: build sheets
    var_headers, var_rows = build_variables_sheet(
        profile_df, namemap_df, dist_row, config, total_rows=total_rows
    )
    dist_headers, dist_rows = build_distributions_sheet(profile_df)
    nm_sheet_headers, nm_sheet_rows = build_name_map_sheet(namemap_df)
    src_headers, src_rows = build_sources_sheet(inventory_df, docs_dir)

    # --- Write workbook ---
    out_path.parent.mkdir(parents=True, exist_ok=True)
    wb = Workbook()
    wb.remove(wb.active)  # type: ignore[arg-type]

    for sheet_name in SHEET_ORDER:
        ws = wb.create_sheet(sheet_name)

        if sheet_name == "KEY":
            key_data = _key_rows()
            headers = key_data[0]
            data = key_data[1:]
            write_table(ws, headers, data)
            style_sheet(ws)

        elif sheet_name == "VARIABLES":
            ws.append(var_headers)
            apply_header_row(ws)
            pcnr_col = var_headers.index("pcnr_name") + 1
            for ri, row_data in enumerate(var_rows, start=2):
                ws.append(row_data)
                # Add hyperlink to DISTRIBUTIONS
                var_name = row_data[0]
                target = dist_row.get(var_name)
                if target:
                    cell = ws.cell(row=ri, column=pcnr_col)
                    cell.hyperlink = Hyperlink(
                        ref=cell.coordinate,
                        location=f"DISTRIBUTIONS!A{target}",
                    )
                    cell.style = "Hyperlink"
            style_sheet(ws)

        elif sheet_name == "DISTRIBUTIONS":
            write_table(ws, dist_headers, dist_rows)
            style_sheet(ws)

        elif sheet_name == "NAME_MAP":
            write_table(ws, nm_sheet_headers, nm_sheet_rows)
            style_sheet(ws)

        elif sheet_name == "SOURCES":
            write_table(ws, src_headers, src_rows)
            style_sheet(ws)

        elif sheet_name == "QC":
            build_qc_sheet(profile_df, ws)
            style_sheet(ws)

        elif sheet_name in PLACEHOLDER_TEXT:
            ws["A1"] = PLACEHOLDER_TEXT[sheet_name]
            style_sheet(ws)

    wb.save(out_path)
    logging.info("Saved %s", out_path)

    return {
        "VARIABLES": len(var_rows),
        "DISTRIBUTIONS": len(dist_rows),
        "NAME_MAP": len(nm_sheet_rows),
    }


# ---------------------------------------------------------------------------
# verify_workbook
# ---------------------------------------------------------------------------

def verify_workbook(path: Path, expected_data_rows: dict[str, int]) -> None:
    """Re-open and confirm expected sheets, order, and row counts."""
    wb = load_workbook(path, read_only=True)
    try:
        actual_names = wb.sheetnames
        if actual_names != SHEET_ORDER:
            raise ValueError(
                f"sheet order mismatch: {actual_names} != {SHEET_ORDER}"
            )
        for sheet_name, exp in expected_data_rows.items():
            if sheet_name not in wb.sheetnames:
                raise ValueError(f"sheet '{sheet_name}' not found in workbook")
            ws = wb[sheet_name]
            actual = ws.max_row - 1
            if actual != exp:
                raise ValueError(
                    f"sheet {sheet_name}: {actual} data rows != expected {exp}"
                )
    finally:
        wb.close()
    logging.info("Workbook verified: %s", path)
