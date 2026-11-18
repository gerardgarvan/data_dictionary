# Phase 19 stage contract (SAS stage CSV -> Python writer)

Decided 2026-11-18 (PDD-D-35 STAGE_CSV). Applies to `stage\xlsx_schema.csv` and `stage\xlsx_data.csv`.

- Columns: key columns of `PDD_XLS_KEYS` (K3 = PECAN_ID, PRECEDE_STUDY_ID, KEY_ERA; PDD-D-43), then the
  PCNR_ variables in dictionary order (PDD-D-37), NO_DATA variables included (PDD-D-36). One DATA sheet
  (PDD-D-41); no companion file (PDD-D-42); no dictionary sheet (PDD-D-27).
- Dates: numeric variables are Excel serials (PDD-D-38; the probe found no numeric date format, so
  nothing converts). Character dates stay text. Special missings are blank (PDD-D-40).
- NUM_TEXT variables stay text (PDD-D-39), **except** `PCNR_Death_Days_After_Surgery`.
- **Death_Days override is applied in the Python writer, not in SAS.** The SAS stage writes the variable
  as delivered text (schema type C, so the stage stays a faithful copy of `pdd.pcnr_2018_2025`). The
  writer calls `pdd.master_rules.override_cell` for every cell of a variable in `NUMERIC_OVERRIDES`:
  numeric text becomes a number; text starting with `#` and any other non-numeric text becomes blank.
  The writer records the count of blanked cells as QC item `death_days_nonnumeric_blanked`
  (`blanked_qc_row`, counts 1-10 shown as `<11`). The verifier expects this variable numeric and its
  non-blank count equal to the stage count of numeric-parsing cells.
- KEY sheet: first sheet; carries `key_sheet_notice()` (identifiable fields, approved PeCAN team use
  only) and points to `out\pdd_2018_2025.xlsx` for the dictionary.
- Gate: the production write needs `PDD_XLS_APPROVE=1` set at run time (`require_approval`); never in config.
