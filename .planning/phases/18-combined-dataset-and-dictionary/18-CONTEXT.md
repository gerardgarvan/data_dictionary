# Phase 18: Combined dataset and dictionary 2018-2025 - Context

**Gathered:** 2026-11-17 (headless run, no SAS, no P:)
**Status:** Ready for execution (plans 18-01..18-07). Research subagent skipped for budget; sources below were read directly. Counts quoted from earlier phases (41,150 / 36,348 / 77,498 / 142 / 1,895 / 56) are orientation only ("echo only"): no program or test uses them as a gate constant; each is computed or read from a CSV at run time.
**Requirements:** DD-01, DD-02, DD-03, DD-04 (brief M5). Feeds Phase 19 (XLS-01..04: DATA sheet = the combined dataset; KEY sheet text from this phase).

<domain>
## Phase boundary

Deliver (a) one case-level dataset `pdd.pcnr_2018_2025` on P: (never in git), one row per surgery, PECAN_ID and PRECEDE_STUDY_ID first, every PCNR_ variable of the name map with its decided type; (b) its profile; (c) the regenerated dictionary workbook `pdd_2018_2025.xlsx` (KEY leftmost). No master Excel export (Phase 19). No recoding of values (DD-02): only the type rules already decided in PDD-D-31 and NULL-as-missing (D-02b, same as the existing layer).

Out of scope: PCND_/PCNC_ families, linking PECAN_IDs (`pecan_id_link.sas` stays unrun), reopening PDD-D-01..23, writing to the registry, dup link or case map (read-only here).
</domain>

<decisions>
## Locked inputs (not reopened)

- PDD-D-19/29: `norm_psid` = `Precede#####` exact case; join key to `pdd.pecan_id_case_map`.
- PDD-D-26/28/32: PECAN_ID per encryption era; K1 from the harmonized join, K2 = 1000000 + rank; 1,895 K1 dup pairs in `pdd.pecan_id_dup_link` (counted at run time, never hard-coded).
- PDD-D-30: for the shared s22 x s23 surgeries (count read from `docs/new_overlap_decisions.csv` row `s22_s23`, 142), s22 (2024) wins, s23 fills only values that are missing in s22, field by field; YEAR stays the s22 value (2024); conflicts counted per column to QC, no values.
- PDD-D-31 combined types: see `docs/combined_type_decisions.csv` (written in 18-01 from the decision text). Dictionary notes: frailty components era coding; Death_Days `#Error`; Sleep_Apnea_YN pre-2023 Y or blank; s06 NO_DATA variables.
- 16-05: 56 NO_DATA variables, all in s06; `pdd.name_map_coverage` (2279 rows), `pdd.name_map_vars_coverage` (1297 rows); `pdd.name_map_vars_ext` and `pdd.name_map_ext` (5077 rows, 282 new). Phase 18 hard-stops if any `PENDING_DECISION` row remains (16 carry).
- 17: registry 59,505 rows, case map 77,498 rows; QC staging pattern `%p17_qinit/%p17_qadd/%p17_flush_qc`; production programs force ABORT mode; fresh SAS session per production program.

## Design decisions made here (all from the sources above)

- **D18-1 Old era rows come from the frozen `pdd.pcnr`** (Phase 5 output, 41,150 rows, built from `pdd.src_s01..s20` through the frozen name map). Re-running the Phase 5 gap-fill is not repeated: the frozen map is asserted unchanged inside `name_map_ext` (16a), so the Phase 5 result is by construction the old-era answer. Only column types are converted to the decided combined type.
- **D18-2 New era rows are built from `pdd.nsrc_s21..s23`** through `pdd.name_map_ext` (status PCNR, non-blank `pcnr_name`, `s_code` in s21..s23, source variable `sas_name`); generated code, no column names typed in the program.
- **D18-3 Decided type** per PCNR_ variable = row in `docs/combined_type_decisions.csv` if present, else `name_map_vars_ext.result_type`. 18a writes the delta report (ext type, decided type, pcnr actual type, new-source types); an unexplained delta stops the run.
- **D18-4 Column order:** `PECAN_ID`, `PRECEDE_STUDY_ID`, `PECAN_ID_KEY_ERA`, `KEY_ERA`, `NORM_PSID`, then the PCNR_ variables alphabetically. No encrypted MRN or encounter column ever enters the dataset (gate).
- **D18-5 Missing after conversion** is the fill test for PDD-D-30 (blank, or `NULL` in any case for text variables, as in D-02b).
- **D18-6 Datasets:** `pdd.pcnr_2018_2025` (replaced on rerun; the previous copy is backed up first with stem `pcnrcmb` + `_YYYYMMDD_HHMMSS`, 7 + 16 = 23 bytes, lint C33), QC tables `pdd.qc_comb_*` written once per program with a WORK staging flush, profile `pdd.prf_pcnr_2018_2025`. v1.0 outputs (`pdd.pcnr`, `pdd.prf_pcnr`, `pdd_v1_0.xlsx`, `profile_PCNR.csv`) are never overwritten.
- **D18-7 The only append-only tables touched** are none: `pdd.pecan_id_registry`, `pdd.pecan_id_dup_link`, `pdd.pecan_id_case_map` are opened read-only in logic; each program records their row counts at start and end and fails if they changed. Backups are taken for the replaced combined dataset.

## DECIDED: PDD-D-33 (Gerard, 2026-11-17)

`PCNR_PRECEDE_STUDY_ID` on K2 (2023-2025) rows uses the normalized `Precede#####` form (PDD-D-19), same as K1 rows and the `norm_psid` join key. `PDD_K2_PSID_MODE` defaults to NORM in `sas/00_config.sas`; the stop for it in 18b and `%p18_psid_mode` is removed (only an invalid explicit value, not NORM, DELIVERED or BLANK, still stops). The KEY facts report the mode used.

## Assumptions (headless run)

- A1 Facts about `pdd.pcnr` columns (1298 PCNR_ plus NORM_PSID per STATE vs 1297 in the map) are not in a probe: 18a is the probe. It lists every unexplained column by name and stops. **PROBE REQUEST / PENDING SAS RUN: 18a.**
- A2 ASA_Anesth_Record and CPT1_Class numeric (STATE carry and the user's brief). 18a checks every non-missing value on both sides parses as a number; any failure counts stop the run at PENDING DECISION and the SUMMARY records the result.
- A3 `%pdd_profile` requires `&lib..name_map` (`pcnr_name`, `status`). Executor reads `p6_preflight` and `p6_classify_vars`; the combined profile runs with `lib` = a staging library whose `name_map` is a view-compatible copy of `pdd.name_map_ext` (PCNR rows), or `require_name_map=0` if classification does not need it. No change to Phase 6 behavior for `pdd.pcnr`.
- A4 DD-04 "2018-2022 distributions match the previous dictionary": checked in 18c as per-variable non-missing counts on the K1 slice vs `pdd.pcnr` (exact, differences only from the listed NULL-to-missing conversions) plus per-variable distinct-value counts on the K1 slice vs the v1.0 `pdd.prf_pcnr` (LOW_CARD level count and N_DISTINCT stat; differences only for converted variables). Level-by-level frequencies are not re-profiled on the K1 slice; the limit is stated on the KEY sheet.
- A8 The ENCRYPTED_MRN scan (`18d_comb_scan.sas`) is a fourth production program, run last in its own fresh session, so it can scan the closed 18a, 18b and 18c logs; no program scans a log it still holds open.
- A5 Counts only in QC and logs; counts 1-10 exported as `<11`. No raw values in type-failure QC (Phase 5's `raw_value` column is not copied).
- A6 Python: new module and script; v1.0 `write_dictionary.py` untouched and its tests keep passing.
- A7 No new PDD-D numbers other than PDD-D-33 (decided); Price naming sign-off remains PENDING and is stated on the KEY sheet.

</decisions>

<canonical_refs>
## Canonical references

- `.planning/MILESTONE_BRIEF_2018_2025.md` (DD-01..04, XLS needs: KEY text, ID definitions, missing-value convention, row and column counts)
- `docs/DECISIONS.md` (PDD-D-26..32), `.planning/STATE.md` (Phase 18 carry list)
- `.planning/phases/16-name-map-extension/16-05-SUMMARY.md`, `.planning/phases/17-pecan-id/17-SUMMARY.md`, `17-SAS-RUN.md`, `17-VALIDATION.md`
- `docs/name_map_decisions_new.csv`, `docs/new_overlap_decisions.csv`, `docs/pecan_id_dictionary_text.csv`, `docs/exchange_schema.csv`
- `.planning/schemas/probe_master_data_20261116.md`, `overlap_s22_s23_20261116.md`, `probe_xwalk*_20261117.md`
- `sas/05_build_pcnr_macros.sas` (type resolution, NULL handling), `sas/06_profile_macros.sas`, `sas/17_pecan_id_macros.sas` (QC staging, backup, fail mode), `python/pdd/dictionary_workbook.py`, `python/pdd/xlsx_style.py`
- CLAUDE.md SAS pitfalls list and lint C30-C36
</canonical_refs>
