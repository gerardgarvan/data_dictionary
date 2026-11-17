"""Static checks for the Phase 18 seed files and config additions (no SAS here)."""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEED = ROOT / "docs" / "combined_type_decisions.csv"
NUMERIC = "Age_at_Encounter Admit_BMI rt_INCISE_to_DRESS_mins rt_RMS_to_RM_END_mins rt_RMS_to_INCISION_mins Cognitive_Score Frailty_Score".split()
TEXT = (
    "YEAR Base_Procedure_Code_1 Feels_Exausted Low_Physical_Activity Slow_Walking_Speed "
    "Unint_Weight_Loss Week_Grip_Strength Death_Days_After_Surgery"
).split()


def _rows():
    with SEED.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def test_seed_header_and_types():
    rows = {r["pcnr_name"]: r for r in _rows()}
    assert list(_rows()[0]) == ["pcnr_name", "combined_type", "note_kind", "note_text", "decision_ref"]
    assert {n for n in NUMERIC} <= {n for n, r in rows.items() if r["combined_type"] == "N"}
    assert {n for n in TEXT} <= {n for n, r in rows.items() if r["combined_type"] == "C"}
    for n in ("ASA_Anesth_Record", "CPT1_Class"):
        assert rows[n]["combined_type"] == "N" and rows[n]["note_kind"] == "CONDITIONAL"
        assert rows[n]["decision_ref"] == "PDD-D-31(2) conditional"
    assert "116" in rows["Death_Days_After_Surgery"]["note_text"]
    assert "Y or blank" in rows["Sleep_Apnea_YN"]["note_text"]


def test_seed_has_no_data_cells():
    for r in _rows():
        assert not re.fullmatch(r"[\d.,]+", r["note_text"].strip())


def test_exchange_rows_present():
    t = (ROOT / "docs" / "exchange_schema.csv").read_text(encoding="utf-8")
    for f in ("comb_key_facts.csv", "comb_type_delta.csv", "comb_nodata.csv", "comb_recon.csv",
              "comb_d30_conflicts.csv", "profile_PCNR_2018_2025.csv", "profile_PCNR_2018_2025_manifest.csv"):
        assert f + "," in t, f
    assert "comb_recon.csv,n_distinct_k1" in t and "comb_recon.csv,n_distinct_prf_v1" in t


def test_config_psid_default_is_norm():
    cfg = (ROOT / "sas" / "00_config.sas").read_text(encoding="utf-8")
    assert "%let PDD_K2_PSID_MODE = NORM;" in cfg
    assert "%let comb_ds          = pcnr_2018_2025;" in cfg
    stem = re.search(r"%let comb_backup_stem\s*=\s*(\w+);", cfg).group(1)
    assert len(stem) + 16 <= 32
    assert not re.search(r"PDD_K2_PSID_MODE\s*=\s*(DELIVERED|BLANK)\s*;", cfg)
