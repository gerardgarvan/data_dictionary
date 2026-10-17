# PeCAN Data Dictionary (PDD)

## What this is
A SAS pipeline that builds the PeCAN analytic database as seven prefixed variable families and documents them in one data dictionary workbook. Variables in every family are listed alphabetically, each with its distribution.

| # | Family | Prefix | Source status |
|---|--------|--------|---------------|
| 1 | Raw master variables | `PCNR_` | **Known**: `P:\PeCAN Master Data\Gerard\raw\master` (8 files) |
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
- **Reads the original sources in `raw\master` directly.** It does not read the renamed `master_data_1..8.xlsx` copies or the `g` library. This removes the xlsx conversion layer, the SAS positional VAR## names, and the encoding loss introduced by the conversion.
- The 8 masters are overlapping variable sets over one population. PRECEDE_STUDY_ID is unique per row in every file. `2018_2022_X_MASTER_DATASET_20240402` (41,150 rows) is a complete superset of patients and serves as the **spine**.
- The 7 CSVs hold 701 header instances, roughly 168 unique variables, and only 14 are common to all files.
- Known hazards:
  - PRECEDE_STUDY_ID and Base Procedure Code 1 are character in some files and numeric in others.
  - Files 6 and 7 carry a duplicate "PRECEDE Study ID" column; it is identical to PRECEDE_STUDY_ID in file 6.
  - ALL_AIM2 uses `NULL` as a sentinel.
  - ALL_AIM2 has 1,048,575 rows, mostly blank.
  - Base_Procedure_1 has UTF-8 characters (esophagectomy descriptions) that a non-UTF-8 SAS session damages.
  - No leading-zero or >15-digit IDs were found in any source.

## Source files (PCNR_)
`P:\PeCAN Master Data\Gerard\raw\master\`

| Code | File |
|------|------|
| s1 | 2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv |
| s2 | 2018_2019_X_MASTER_DATASET_20200801.csv |
| s3 | 2018_2022_X_MASTER_DATASET_20240402.csv  ← **spine** |
| s4 | 2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv |
| s5 | 2020_X_MASTER_DATASET_20210519.csv |
| s6 | 2021_X_MASTER_DATASET_20230512.csv |
| s7 | 2022_MASTER_DATASET_20231024.csv |
| s8 | ALL_AIM2_MASTER_DATASET_20210917.xlsx (Sheet1) |

`raw\master` is read-only to this pipeline. A hash baseline guards it.

## Locked decisions (2026-10-15)
| ID | Decision |
|----|----------|
| PDD-D-01 | PCNR_ draws on **all 8** raw\master files, merged 1:1 on PRECEDE_STUDY_ID onto the s3 spine |
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
| PDD-D-15 | Gap-fill tie-break order among s1, s2, s4–s8 when the spine is missing and several files disagree | Gerard |
| PDD-D-16 | Whether gap-filled values are flagged per cell (e.g. a `PCNR_<var>_SRC` column) or only summarized in QC | Gerard |

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
