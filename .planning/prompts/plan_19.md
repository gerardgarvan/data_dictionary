# plan_19 - PCNR_Master_Data_Nov_2026.xlsx

## Context
Phase 18 is complete: pdd.pcnr_2018_2025 (77,498 rows x 1,302 columns =
5 key columns + 1,297 PCNR_ variables) on P:, plus the 2018-2025 dictionary
out\pdd_2018_2025.xlsx. Phase 19 delivers the patient-level master data
workbook PCNR_Master_Data_Nov_2026.xlsx. Read 18-SUMMARY.md, DECISIONS.md,
STATE.md, ROADMAP.md, docs/combined_type_decisions.csv and the Phase 18 code
before planning.

## Do (plan only - no SAS/Python implementation in this run)
Write .planning/phases/19-master-data-workbook/19-PLAN.md and 19-CONTEXT.md:
1. Build route: compare (a) SAS PROC EXPORT DBMS=XLSX, (b) SAS -> parquet/CSV
   in WORK -> Python openpyxl write_only, (c) SAS ODS EXCEL. Weigh runtime and
   memory for ~100M cells, Excel limits (1,048,576 rows; 16,384 cols; 32,767
   chars/cell), date/time types, numeric precision, formats, file size, and
   the fact that it must run on the SAS machine (P: access). Recommend one.
2. Workbook layout: KEY sheet leftmost (Gerard's standing rule), then DATA,
   then anything else (e.g. a short variable list linking to pdd_2018_2025.xlsx).
3. Disclosure / content review: which key columns go in (PECAN_ID,
   PCNR_PRECEDE_STUDY_ID, era/source key...) and confirm no encrypted MRN or
   norm_psid helper columns leave SAS; how a scan (like 18d) verifies the
   finished xlsx.
4. QC gates: row/column counts vs pdd.pcnr_2018_2025, per-variable non-missing
   counts vs comb_recon (respecting NUM_TEXT and special-missing rules from
   fix_18c/18d), type checks on a sample, date round-trip, KEY facts.
5. Safety: output only under P:\PeCAN Master Data\Gerard\data_dictionary\out;
   never the shared Master Data folder; backup/no-overwrite rule for an
   existing workbook; synthetic test first; fresh SAS session per program;
   fail-loud ABORT mode.
6. List every open design choice as PENDING DECISION (PDD-D-35 onward) with
   options and a recommended option - do NOT decide them. At minimum:
   - include or drop the 56 NO_DATA variables;
   - column order (dictionary order vs source/era order);
   - date/time representation in Excel;
   - NUM_TEXT variables: keep as text or convert;
   - special missing codes (.A-.Z) in Excel: blank, code text, or both;
   - one DATA sheet vs split by era (K1/K2) or by domain;
   - companion CSV / sas7bdat alongside the xlsx or not.
7. Break the work into tasks with the programs to write (19a... with tests),
   the SAS run sheet outline, and a time estimate per run.

## Constraints (unchanged)
Planning docs only. No PHI or data values in git; counts 1-10 as <11. No push,
no branch switch, no history rewrite. Commit on pdd-2018-2025-api.
