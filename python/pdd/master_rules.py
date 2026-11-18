"""Phase 19 workbook rules decided by Gerard on 2026-11-18 (PDD-D-39, 43, 44, 27).

Pure functions, no I/O, no real data. The Wave 2 writer (19-05) imports them; the
stage contract is docs/xlsx_stage_contract.md.
"""
from __future__ import annotations

import math
import re

# PDD-D-43: K3 = exactly these three key columns, in this order. PECAN_ID_KEY_ERA
# (identical to KEY_ERA in every row) and NORM_PSID (identical to
# PRECEDE_STUDY_ID) are dropped. Never an MRN or encounter column.
KEY_SETS: dict[str, tuple[str, ...]] = {
    "K3": ("PECAN_ID", "PRECEDE_STUDY_ID", "KEY_ERA"),
    "K4": ("PECAN_ID", "PRECEDE_STUDY_ID", "PECAN_ID_KEY_ERA", "KEY_ERA"),
}
DEFAULT_KEYS = "K3"

# PDD-D-39: NUM_TEXT stays text except this one variable, written as numeric.
NUMERIC_OVERRIDES: frozenset[str] = frozenset({"PCNR_Death_Days_After_Surgery"})

_NUM_RE = re.compile(r"^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$")


def key_columns(code: str) -> tuple[str, ...]:
    """Key columns of a K-code; an unknown code raises (never a silent default)."""
    try:
        return KEY_SETS[code.strip().upper()]
    except KeyError as exc:
        raise ValueError(f"unknown PDD_XLS_KEYS value: {code!r}") from exc


def override_cell(text: str | None) -> tuple[int | float | None, bool]:
    """Death_Days override for one stage cell (text as delivered).

    Returns (value, blanked). Empty -> (None, False). A number -> (int|float,
    False). Anything else (text starting with '#', any other non-numeric text,
    inf/nan) -> (None, True): the cell is blank and counts as blanked.
    """
    if text is None:
        return None, False
    t = text.strip()
    if not t:
        return None, False
    if not _NUM_RE.match(t):
        return None, True
    v = float(t)
    if not math.isfinite(v):
        return None, True
    if v == int(v) and abs(v) < 1e15:
        return int(v), False
    return v, False


def mask_count(n: int) -> str | int:
    """Counts 1-10 are exported as '<11' (CLAUDE.md); 0 and >= 11 stay."""
    return "<11" if 1 <= n <= 10 else n


def blanked_qc_row(n_blanked: int) -> tuple[str, str | int]:
    """QC item for the Death_Days override (count masked like other counts)."""
    return ("death_days_nonnumeric_blanked", mask_count(n_blanked))


def require_approval(env_value: str | None) -> None:
    """PDD-D-44: the production write needs PDD_XLS_APPROVE=1 set at run time."""
    if (env_value or "").strip() != "1":
        raise PermissionError("PENDING DECISION: PDD_XLS_APPROVE is not 1 (set at run time by Gerard)")


_NOTICE = (
    "THIS WORKBOOK CONTAINS IDENTIFIABLE FIELDS and is for approved PeCAN team use only.",
    "Audience: the PeCAN team under the current IRB protocol. Do not share outside the team.",
    "Identifiable content kept unaltered: PCNR_Latitude and PCNR_Longitude, free-text notes, "
    "staff-name fields and ages.",
    "No MRN, encrypted MRN or encounter column is included.",
    "Dictionary: this workbook has no dictionary sheet (PDD-D-27); see out\\pdd_2018_2025.xlsx.",
)


def key_sheet_notice() -> list[str]:
    """Plain-language audience and identifiable-fields lines for the KEY sheet."""
    return list(_NOTICE)
