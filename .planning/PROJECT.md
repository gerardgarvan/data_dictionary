# PeCAN Data Dictionary (PDD)

## What this is
A SAS pipeline that builds the PeCAN analytic database as seven prefixed variable families and documents them in one data dictionary workbook. Variables in every family are listed alphabetically, each with its distribution.

| # | Family | Prefix | Source status |
|---|--------|--------|---------------|
| 1 | Raw master variables | `PCNR_` | **Known**: `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data` (20 files) |
| 2 | PeCAN clinic data | `PCNC_` | Pending: source to be supplied by Gerard |
| 3 | Derived variables | `PCND_` | Pending: definitions to be supplied |
| 4 | Clock variables | `CLK_` | Pending: Gerard researching source |
| 5 | Pre-operative labs | `LAB_` | Pending: separate extract, path TBD |
| 6 | Medications | `MED_` | Pending: separate extract, path TBD |
| 7 | Intra-operative | `INTRA_` | Pending: separate extract, path TBD |

Every family gets the same treatment as `PCNR_`: an alphabetical dictionary sheet with a distribution for every variable (description.txt item "repeat what was done with one").

## Core value
One trustworthy, documented, patient-level dataset (one row per PRECEDE_STUDY_ID) in which every value can be traced to its source file.

## Relationship to the prior project
This project replaces the Master_Renamed_same_format_accross pipeline (`C:\Master_Renamed_same_format_accross`, PCM-xx). It reuses that project's **findings**, but not its intermediate files:
- **Reads the original shared sources directly.** It does not read the renamed `master_data_1..8.xlsx` copies or the `g` library. This removes the xlsx conversion layer, the SAS positional VAR## names, and the encoding loss introduced by the conversion.
- The source folder is the shared, **strictly read-only** original: no program may write, rename, or create anything in it. Output stays under `P:\PeCAN Master Data\Gerard\data_dictionary`.
- An older copy of some files exists at `P:\PeCAN Master Data\Gerard\raw\master` (the prior pipeline's staging area). Phase 2 hash-compares the shared originals against those copies where the same filename exists, to detect any silent modification.
- The source files are overlapping variable sets over one population. PRECEDE_STUDY_ID is unique per row in all 20 master datasets (Phase 2 confirmed -- s01 41,423 distinct, s08 3,456 distinct, both 1:1 per patient). `2018_2022_X_MASTER_DATASET_20240402` (41,150 rows, s09) is the **confirmed spine** (Phase 2).
- Phase 2 authoritative counts: **148 distinct original headers** across the 7-CSV files (the earlier 168 counted SAS positional VARnn names from old xlsx copies â€” accepted unless header_matrix shows otherwise); 41,150-row spine confirmed.
- Known hazards (found in original source files â€” verify in Phase 2):
  - PRECEDE_STUDY_ID and Base Procedure Code 1 were typed character in some files, numeric in others â€” re-confirm in Phase 2 on the shared-folder originals.
  - ALL_AIM2 uses `NULL` as a sentinel value; ~1,048,575 rows, mostly blank â€” re-confirm counts.
  - Base_Procedure_1 contains UTF-8 characters (esophagectomy descriptions) that a non-UTF-8 SAS session damages â€” re-confirm encoding requirement.
  - No leading-zero or >15-digit IDs were found previously â€” re-check in Phase 2.
  - Earlier copies of 2021_X_MASTER_DATASET_20230512.csv and 2022_MASTER_DATASET_20231024.csv carried a second "PRECEDE Study ID" header alongside PRECEDE_STUDY_ID (identical values in 2021). This came from the source query, not the renaming. Check the shared-folder originals for the same pattern.
  - Some files are keyed on ENCRYPTED_MRN or ENCRYPTED_ENCOUNTER rather than PRECEDE_STUDY_ID; the 2018_2019 ENCOUNTER/MRN Crypto files may be crosswalks that resolve the old 2022 ID mismatch â€” to be determined in Phase 2 (PDD-D-18).
  - 2018_2019_Precede_Database.xlsx is ~200 MB; all sheets must be inventoried.

## Source files (PCNR_)
`P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data\` â€” **strictly read-only**

| Code | File | Notes |
|------|------|-------|
| s01 | 2018-2022_PACU_STAY_20260813.csv | 1:1 per PRECEDE_STUDY_ID; 274 IDs not in spine (QC item) |
| s02 | 2018_2019_2020_Induction_Emergent20231121.csv | |
| s03 | 2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv | |
| s04 | 2018_2019_ENCOUNTER_Crypto_Data_20260814.csv | possible crosswalk (PDD-D-18) |
| s05 | 2018_2019_MRN_Crypto_Data20260814.csv | possible crosswalk (PDD-D-18) |
| s06 | 2018_2019_Precede_Database.xlsx | ~200 MB; all sheets |
| s07 | 2018_2019_X_MASTER_DATASET_20200801.csv | |
| s08 | 2018_2022_COLONOSCOPY_20240118.xlsx | 1:1 per PRECEDE_STUDY_ID (Phase 2 confirmed) |
| s09 | 2018_2022_X_MASTER_DATASET_20240402.csv | candidate **spine** (pending Phase 2 confirmation) |
| s10 | 2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv | |
| s11 | 2020_Precede_Database_Edu.xlsx | |
| s12 | 2020_X_MASTER_DATASET_20210519.csv | |
| s13 | 2021_Education_20240124.csv | |
| s14 | 2021_Frailty_20240123.csv | |
| s15 | 2021_X_MASTER_DATASET_20230512.csv | |
| s16 | 2022_Education_20240124.csv | |
| s17 | 2022_MASTER_DATASET_20231024.csv | |
| s18 | 2022_RES_20230927.csv | |
| s19 | ALL_AIM2_MASTER_DATASET_20210917.xlsx | Sheet1 only per prior pipeline |
| s20 | All_YEARS_LAT_LONG_20231127.csv | |

Older copies of some files exist at `P:\PeCAN Master Data\Gerard\raw\master` â€” Phase 2 compares hashes.

## Locked decisions (2026-10-15 / 2026-10-19)
| ID | Decision |
|----|----------|
| PDD-D-01 | PCNR_ draws on **all 20** shared-folder files; all files are 1:1 PRECEDE_STUDY_ID grain (Phase 2 confirmed); files are merged onto the s09 spine; crosswalk-keyed files (s04, s05) follow PDD-D-18 |
| PDD-D-02 | PCNR_ values are **exactly as in source**: no recoding. `?`, `NULL`, `Unknown` are kept as values and appear in distributions. All cleaning belongs in PCND_ |
| PDD-D-03 | New repo, **SAS**, reusing the `00_config.sas` + `run_pipeline.cmd` pattern |
| PDD-D-04 | Distributions cover **all 41,150 spine patients**; no cohort restriction |
| PDD-D-05 | Overlapping variables: **spine wins, other files gap-fill** where the spine is missing. Disagreements between non-missing values go to a QC sheet |
| PDD-D-06 | Distribution display by distinct-value count: â‰¤20 levels â†’ count and % per level plus missing. Numeric with >20 levels â†’ N, missing, mean, SD, median, Q1/Q3, min/max. High-cardinality text â†’ N distinct plus top 10 |
| PDD-D-07 | Names: clean original name, truncate to fit 32 chars (27 after `PCNR_`); full original name kept as the variable label and in a NAME_MAP sheet |
| PDD-D-08 | ALL_AIM2 (s8): drop rows with missing PRECEDE_STUDY_ID or all columns blank/`NULL`; log the counts. Remaining rows gap-fill like any other source |
| PDD-D-09 | Deliverable: **one workbook**. KEY sheet leftmost, then one sheet per family, plus NAME_MAP, SOURCES and QC sheets |
| PDD-D-10 | LAB_, MED_ and INTRA_ are **separate data**, not re-prefixed master columns |
| PDD-D-17 | **CLOSED (2026-10-19).** Every file is one row per PRECEDE_STUDY_ID (case) â€” confirmed by Phase 2. s01 (PACU_STAY) and s08 (COLONOSCOPY) are the only multi-row files. How they enter PCNR_ remains to be decided (aggregate, first/last, wide, or separate long table) â€” Gerard to decide in Phase 3. s18 has 2 duplicate/blank key rows (qc_s18_dup) to be reviewed in Phase 3 |
| PDD-D-19 | **LOCKED (2026-10-19).** 2022 ID normalisation: all-digit IDs (text or numeric) â†’ `cats('Precede', put(input(strip(id), ?? 8.), z5.))`. Already-`Precede99999` unchanged. Run 19:21: s16/s17 9,215; s18 9,215/9,484; s01 41,149/41,423; s08 3,456/3,456; s20 41,150/41,150; 9,001 encounter-linked pairs, 0 disagreements. Assert in 02_source_guard.sas fails if `_ndis > 0`. `%pdd_norm_psid(in=, out=, idvar=)` macro in `00_config.sas` for Phases 3-5. Phase 3 QC: s01 274 not in spine (1 spine case no PACU row); s18 269 not in spine + 2 dup/blank rows (`pdd.qc_s18_dup`); s06 29 and s11 1 not in spine; s04/s05 4 not in spine |
| PDD-D-20 | **LOCKED (2026-10-19).** The 6 s17 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID are treated as an encrypted blank: set to missing for linkage only. Values stay unchanged in PCNR_ |
| PDD-D-21 | **LOCKED (2026-10-20).** Clock-drawing columns (COM*/COPY* + clock token: ClockFace, HH, MH, HandPair, Digit, Hooklet, PCF, Intersect) are EXCLUDED from PCNR_. All other s06 columns are PCNR_ candidates. pdd.src_s06 keeps all 3,987 columns unchanged; split applied from Phase 4 onward via docs/s06_column_class.csv. Clock columns are the candidate CLK_ source (PDD-D-13 note added). |

## Open decisions
| ID | Question | Owner |
|----|----------|-------|
| PDD-D-11 | Source location of PCNC_ clinic data | Gerard |
| PDD-D-12 | PCND_ derived-variable list and definitions | Gerard (Price consulted on naming) |
| PDD-D-13 | Source of CLK_ clock variables (dCDT extract, master columns, or other). **Note (2026-10-20):** s06 clock columns (COM*/COPY* + clock token) are now the confirmed candidate CLK_ source; D-21 LOCKED. D-13 remains open pending confirmation that s06 clock columns are the authoritative CLK_ source. | Gerard (researching) |
| PDD-D-14 | Source paths for LAB_, MED_, INTRA_ extracts and their linkage key | Gerard |
| PDD-D-15 | Gap-fill tie-break order among non-spine sources when the spine is missing and several files disagree | Gerard |
| PDD-D-16 | Whether gap-filled values are flagged per cell (e.g. a `PCNR_<var>_SRC` column) or only summarized in QC | Gerard |
| PDD-D-18 | s04/s05 are linkage/QC files with the same encryption as the masters and 100% match â€” **not dictionary variables**. Pending Gerard confirmation. Linkage path and whether they resolve the old 2022 ID mismatch to be decided in Phase 3 | Gerard |

## Constraints
- No PHI committed to git. Code and docs live in the repo; data, QC output and logs stay on P:.
- Repo stays off the network drive; the earlier project hit git index corruption on P:.
- Every program `%include`s `sas/00_config.sas`. Each program assigns its own libnames.
- SAS on Windows against P:. CSVs are read with explicit UTF-8 encoding.
- UF colors (#0021A5, #FA4616) on any visual deliverable. KEY sheet is leftmost in every workbook.
- Pending decisions on variable naming and cohort go to Price.

## Layout (proposed)
- Repo: `C:\data_dictionary\` (`sas\`, `docs\`, `.planning\`)
- Data/output: `P:\PeCAN Master Data\Gerard\data_dictionary\` (`pdd` library, `qc\`, `logs\`, `out\`)


