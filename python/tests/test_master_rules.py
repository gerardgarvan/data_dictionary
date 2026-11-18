"""Synthetic tests for the Phase 19 decided rules (no real data)."""
import pytest

from pdd import master_rules as r


def test_k3_exact_and_drops():
    assert r.key_columns("k3") == ("PECAN_ID", "PRECEDE_STUDY_ID", "KEY_ERA")
    assert r.DEFAULT_KEYS == "K3"
    for bad in ("NORM_PSID", "PECAN_ID_KEY_ERA"):
        assert bad not in r.key_columns("K3")
    with pytest.raises(ValueError):
        r.key_columns("K9")


@pytest.mark.parametrize(
    "text,expect",
    [
        ("40", (40, False)), ("-3", (-3, False)), ("12.5", (12.5, False)), (" 7 ", (7, False)),
        ("", (None, False)), (None, (None, False)), ("   ", (None, False)),
        ("#Error", (None, True)), ("#N/A", (None, True)), ("abc", (None, True)),
        ("nan", (None, True)), ("inf", (None, True)), ("1,2", (None, True)),
    ],
)
def test_override_cell(text, expect):
    assert r.override_cell(text) == expect


def test_override_only_death_days():
    assert r.NUMERIC_OVERRIDES == {"PCNR_Death_Days_After_Surgery"}


def test_blanked_count_masked():
    assert r.blanked_qc_row(0) == ("death_days_nonnumeric_blanked", 0)
    assert r.blanked_qc_row(7)[1] == "<11"
    assert r.blanked_qc_row(10)[1] == "<11"
    assert r.blanked_qc_row(34057)[1] == 34057


def test_key_sheet_notice():
    text = " ".join(r.key_sheet_notice())
    assert "IDENTIFIABLE" in text and "approved PeCAN team use only" in text
    assert "pdd_2018_2025.xlsx" in text
    assert "Latitude" in text and "staff-name" in text


def test_approval_run_time_only():
    for v in (None, "", "0", "yes"):
        with pytest.raises(PermissionError):
            r.require_approval(v)
    r.require_approval("1")
