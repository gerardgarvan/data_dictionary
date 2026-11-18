# fix_19w2b1 - stage CSVs start with a UTF-8 BOM; writer rejects the schema header

Real run (19b PASS) then write_master_workbook.py --bench-rows 20000 failed:
  ERROR write failed: xlsx_schema.csv: header must have
  ['col_index', 'excel_kind', 'name', 'sas_type']
Bytes: stage\xlsx_schema.csv and stage\xlsx_data.csv both start EF BB BF
(SAS FILE encoding='utf-8' writes a BOM); header text is otherwise exact.
Also: python/pdd/master_rules.py:78 SyntaxWarning invalid escape '\p' in
"... see out\pdd_2018_2025.xlsx."

Do:
1. Every Python read of a SAS-written CSV (stage\xlsx_schema.csv,
   xlsx_data.csv, xlsx_expected.csv, exchange\*.csv, qc\*.csv) in
   python/pdd/master_workbook.py, master_verify.py, master_rules.py and any
   shared reader: open with encoding='utf-8-sig'. Also strip whitespace from
   header names. The DATA sheet header must never contain U+FEFF - add an
   explicit assertion before writing the header row.
2. Fix the '\p' escape (raw string or doubled backslash); grep python/ for
   other invalid escapes (python -W error -c "import ..." or ruff W605).
3. docs/xlsx_stage_contract.md: state that SAS-written files start with a
   UTF-8 BOM and readers must use utf-8-sig.
4. Tests: writer and verifier fixtures written WITH a BOM (schema, data,
   expected) pass, and the DATA header's first cell equals 'PECAN_ID'.
   Ruff + pytest green.

Constraints unchanged. No run against real data. Commit on
pdd-2018-2025-api; no push.
