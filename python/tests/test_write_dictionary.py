"""
Tests for python/scripts/write_dictionary.py.

Covers: validate_exchange_headers with BOM-prefixed CSVs.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from write_dictionary import validate_exchange_headers  # noqa: E402

# Minimal required columns per exchange_schema.csv (just enough for header check)
_SCHEMA_ROWS = (
    "file,column,type,required\n"
    "profile_PCNR.csv,family,str,Y\n"
    "profile_PCNR.csv,variable,str,Y\n"
    "profile_PCNR.csv,var_class,str,Y\n"
    "name_map_dict.csv,s_code,str,Y\n"
    "name_map_dict.csv,pcnr_name,str,N\n"
    "source_inventory.csv,s_code,str,Y\n"
    "source_inventory.csv,filename,str,Y\n"
)

# Minimal valid headers for each exchange file (plain UTF-8)
_PROFILE_HEADERS = (
    "family,variable,var_class,stat,level,n,value,"
    "pct_total,pct_nonmiss,sort_order,small_cell_flag,date_kind,display_format\n"
)
_NAMEMAP_HEADERS = (
    "s_code,col_order,sas_name,original_header,trunc_flag,"
    "status,group_id,pcnr_name,sas_type,length\n"
)
_INVENTORY_HEADERS = "s_code,filename,row_count,col_count,sha256,mod_date\n"


def _write_exchange(exchange_dir: Path, profile_bytes: bytes | None = None) -> None:
    """Write minimal exchange CSVs; profile_bytes allows BOM injection."""
    if profile_bytes is None:
        (exchange_dir / "profile_PCNR.csv").write_text(_PROFILE_HEADERS, encoding="utf-8")
    else:
        (exchange_dir / "profile_PCNR.csv").write_bytes(profile_bytes)
    (exchange_dir / "name_map_dict.csv").write_text(_NAMEMAP_HEADERS, encoding="utf-8")
    (exchange_dir / "source_inventory.csv").write_text(_INVENTORY_HEADERS, encoding="utf-8")


def test_validate_exchange_headers_clean(tmp_path):
    """No BOM, all required headers present — expect zero errors."""
    exchange_dir = tmp_path / "exchange"
    exchange_dir.mkdir()
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    (docs_dir / "exchange_schema.csv").write_text(_SCHEMA_ROWS, encoding="utf-8")
    _write_exchange(exchange_dir)

    errors = validate_exchange_headers(exchange_dir, docs_dir)
    assert errors == [], f"Unexpected errors: {errors}"


def test_validate_exchange_headers_bom_profile(tmp_path):
    """profile_PCNR.csv with UTF-8 BOM — must NOT raise 'family missing'."""
    exchange_dir = tmp_path / "exchange"
    exchange_dir.mkdir()
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    (docs_dir / "exchange_schema.csv").write_text(_SCHEMA_ROWS, encoding="utf-8")

    # Write profile_PCNR.csv with UTF-8 BOM prefix (as SAS PROC EXPORT produces)
    bom_bytes = "﻿".encode("utf-8") + _PROFILE_HEADERS.encode("utf-8")
    _write_exchange(exchange_dir, profile_bytes=bom_bytes)

    errors = validate_exchange_headers(exchange_dir, docs_dir)
    assert errors == [], (
        "BOM-prefixed profile_PCNR.csv must not produce header errors; got: " + str(errors)
    )


def test_validate_exchange_headers_schema_bom(tmp_path):
    """exchange_schema.csv itself with BOM — must still parse correctly."""
    exchange_dir = tmp_path / "exchange"
    exchange_dir.mkdir()
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    bom_schema = "﻿".encode("utf-8") + _SCHEMA_ROWS.encode("utf-8")
    (docs_dir / "exchange_schema.csv").write_bytes(bom_schema)
    _write_exchange(exchange_dir)

    errors = validate_exchange_headers(exchange_dir, docs_dir)
    assert errors == [], f"BOM in exchange_schema.csv caused errors: {errors}"


def test_validate_exchange_headers_missing_required_col(tmp_path):
    """Missing required column — expect error."""
    exchange_dir = tmp_path / "exchange"
    exchange_dir.mkdir()
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    (docs_dir / "exchange_schema.csv").write_text(_SCHEMA_ROWS, encoding="utf-8")
    # profile missing 'family'
    bad_profile = "variable,var_class,stat,level,n,value,pct_total,pct_nonmiss,sort_order,small_cell_flag,date_kind,display_format\n"
    (exchange_dir / "profile_PCNR.csv").write_text(bad_profile, encoding="utf-8")
    (exchange_dir / "name_map_dict.csv").write_text(_NAMEMAP_HEADERS, encoding="utf-8")
    (exchange_dir / "source_inventory.csv").write_text(_INVENTORY_HEADERS, encoding="utf-8")

    errors = validate_exchange_headers(exchange_dir, docs_dir)
    assert any("family" in e for e in errors), f"Expected 'family' error, got: {errors}"
