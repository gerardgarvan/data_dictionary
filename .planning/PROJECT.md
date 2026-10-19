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
- The source files are overlapping variable sets over one population. PRECEDE_STUDY_ID is unique per row in the master datasets; some files (PACU_STAY, COLONOSCOPY) have multiple rows per patient. `2018_2022_X_MASTER_DATASET_20240402` (41,150 rows, s09) is the candidate spine — confirmed by Phase 2.
- Prior findings (701 header instances across the original 8 files, ~168 unique variables, 41,150-row spine) are expectations to re-check in Phase 2, not established facts.
- Known hazards (found in original source files — verify in Phase 2):
  - PRECEDE_STUDY_ID and Base Procedure Code 1 were typed character in some files, numeric in others — re-confirm in Phase 2 on the shared-folder originals.
  - ALL_AIM2 uses `NULL` as a sentinel value; ~1,048,575 rows, mostly blank — re-confirm counts.
  - Base_Procedure_1 contains UTF-8 characters (esophagectomy descriptions) that a non-UTF-8 SAS session damages — re-confirm encoding requirement.
  - No leading-zero or >15-digit IDs were found previously — re-check in Phase 2.
  - Earlier copies of 2021_X_MASTER_DATASET_20230512.csv and 2022_MASTER_DATASET_20231024.csv carried a second "PRECEDE Study ID" header alongside PRECEDE_STUDY_ID (identical values in 2021). This came from the source query, not the renaming. Check the shared-folder originals for the same pattern.
  - Some files are keyed on ENCRYPTED_MRN or ENCRYPTED_ENCOUNTER rather than PRECEDE_STUDY_ID; the 2018_2019 ENCOUNTER/MRN Crypto files may be crosswalks that resolve the old 2022 ID mismatch — to be determined in Phase 2 (PDD-D-18).
  - PACU_STAY and COLONOSCOPY have multiple rows per patient; how they enter PCNR_ is an open decision (PDD-D-17).
  - 2018_2019_Precede_Database.xlsx is ~200 MB; all sheets must be inventoried.

## Source files (PCNR_)
`P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data\` — **strictly read-only**

| Code | File | Notes |
|------|------|-------|
| s01 | 2018-2022_PACU_STAY_20260813.csv | multi-row per patient (PDD-D-17) |
| s02 | 2018_2019_2020_Induction_Emergent20231121.csv | |
| s03 | 2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv | |
| s04 | 2018_2019_ENCOUNTER_Crypto_Data_20260814.csv | possible crosswalk (PDD-D-18) |
| s05 | 2018_2019_MRN_Crypto_Data20260814.csv | possible crosswalk (PDD-D-18) |
| s06 | 2018_2019_Precede_Database.xlsx | ~200 MB; all sheets |
| s07 | 2018_2019_X_MASTER_DATASET_20200801.csv | |
| s08 | 2018_2022_COLONOSCOPY_20240118.xlsx | multi-row per patient (PDD-D-17) |
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

Older copies of some files exist at `P:\PeCAN Master Data\Gerard\raw\master` — Phase 2 compares hashes.

## Locked decisions (2026-10-15)
| ID | Decision |
|----|----------|
| PDD-D-01 | PCNR_ draws on **all 20** shared-folder files; files with a 1:1 PRECEDE_STUDY_ID grain are merged onto the s09 spine; multi-row files (s01, s08) and crosswalk-keyed files (s04, s05) follow PDD-D-17 / PDD-D-18 |
| PDD-D-02 | PCNR_ values are **exactly as in source**: no recoding. `?`, `NULL`, `Unknown` are kept as values and appear in distributions. All cleaning belongs in PCND_ |
| PDD-D-03 | New repo, **SAS**, reusing the `00_config.sas` + `run_pipeline.cmd` pattern |
| PDD-D-04 | Distributions cover **all 41,150 spine patients**; no cohort restriction |
| PDD-D-05 | Overlapping variables: **spine wins, other files gap-fill** where the spine is missing. Disagreements between non-missing values go to a QC sheet |
| PDD-D-06 | Distribution display by distinct-value count: ≤20 levels → count and % per level plus missing. Numeric with >20 levels → N, missing, mean, SD, median, Q1/Q3, min/max. High-cardinality text → N distinct plus top 10 |
| PDD-D-07 | Names: clean original name, truncate to fit 32 chars (27 after `PCNR_`); full original name kept as the variable label and in a NAME_MAP sheet |
| PDD-D-08 | ALL_AIM2 (s8): drop rows with missing PRECEDE_STUDY_ID or all columns blank/`NULL`; log the counts. Remaining rows gap-fill like any other source |
| PDD-D-09 | Deliverable: **one workbook**. KEY sheet leftmost, then one sheet per family, plus NAME_MAP, SOURCES and QC sheets |
| PDD-D-10 | LAB_, MED_ and INTRA_ are **separate data**, not re-prefixed master columns |

## Open decisions
| ID | Question | Owner |
|----|----------|-------|
| PDD-D-11 | Source location of PCNC_ clinic data | Gerard |
| PDD-D-12 | PCND_ derived-variable list and definitions | Gerard (Price consulted on naming) |
| PDD-D-13 | Source of CLK_ clock variables (dCDT extract, master columns, or other) | Gerard (researching) |
| PDD-D-14 | Source paths for LAB_, MED_, INTRA_ extracts and their linkage key | Gerard |
| PDD-D-15 | Gap-fill tie-break order among non-spine sources when the spine is missing and several files disagree | Gerard |
| PDD-D-16 | Whether gap-filled values are flagged per cell (e.g. a `PCNR_<var>_SRC` column) or only summarized in QC | Gerard |
| PDD-D-17 | How multi-row-per-patient files (s01 PACU_STAY, s08 COLONOSCOPY) enter PCNR_: aggregate, first/last, wide, or a separate long table — decided after Phase 2 | Gerard |
| PDD-D-18 | Files keyed on MRN/encounter rather than PRECEDE_STUDY_ID (s04, s05, possibly others): linkage path, whether s04/s05 are crosswalks, and whether they resolve the old 2022 ID mismatch — decided after Phase 2 | Gerard |

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
