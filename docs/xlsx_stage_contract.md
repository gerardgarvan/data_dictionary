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

## Stage file formats (written by `sas/19b_xlsx_stage.sas`)

- `xlsx_data.csv`: UTF-8, CRLF line ends, no BOM. First record is the header (column names in export order).
  A field with a comma, double quote, CR or LF is quoted with `"` and inner quotes doubled; nothing else is
  quoted. Empty field = blank cell (ordinary and special missing numerics, blank text). Numerics are
  `BEST32.` text. Numeric dates and datetimes are Excel serials (none exist in the current dataset).
  Records, not physical lines, equal dataset rows + 1 (a text cell can hold CR LF). Read with `csv.reader`
  on a file opened with `newline=''`.
- `xlsx_schema.csv`: header `col_index,name,sas_type,excel_kind`; `sas_type` is `N` or `C`; `excel_kind` is
  `N`, `C`, `DATE`, `DATETIME` or `TIME`. Row order = column order of the data CSV.
- `xlsx_expected.csv`: header `kind,variable,n_rows,n_nonblank,n_special`. `ROWS` has the dataset row count in
  `n_rows`. One `COL` row per exported column in export order (`n_nonblank` = non-blank text cells or
  non-missing numbers, `n_special` = special missing numbers, 0 for text). `SAMPLE` rows hold in `n_rows` a
  1-based data row number (min(rows, 2000) distinct rows, seed 19). Counts only, exact, kept on P: under `stage`.
