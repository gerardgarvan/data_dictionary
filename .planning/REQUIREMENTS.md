# Requirements: PeCAN Data Dictionary (PDD)

Requirement IDs map one-to-one to roadmap phases within Milestone v1.0 and v1.x.
Locked decisions are referenced by their original IDs (PDD-D-01 … PDD-D-16).

---

## Milestone v1.0: PCNR_ raw layer and dictionary framework

### PDD-01 — Repo and config scaffold
**Roadmap phase:** Phase 1

The repository skeleton must be in place before any SAS program runs.

| Requirement | Detail |
|-------------|--------|
| Git repo at `C:\data_dictionary` with `.gitignore` excluding all data | No PHI ever committed |
| `sas/00_config.sas` defines macro variables for all paths and assigns the `pdd` libname | Every subsequent program `%include`s it and assigns its own libnames (PDD-D-03) |
| UTF-8 SAS session options set globally | Required for Base_Procedure_1 rows (see Phase 3) |
| `run_pipeline.cmd` and `99_run_all.sas` skeleton in place | Provides consistent invocation entry point |
| Log directory `P:\PeCAN Master Data\Gerard\data_dictionary\logs` writable | An empty run writes a clean log there |

**Acceptance:** an empty run produces a clean log with zero ERRORs or WARNINGs.

---

### PDD-02 — Source guard and header inventory
**Roadmap phase:** Phase 2

Protects the read-only source layer and documents the raw variable universe across all 20 files.

| Requirement | Detail |
|-------------|--------|
| `02_source_guard.sas` computes SHA-256 of all 20 shared-folder files and stores the baseline | Run fails with an ERROR if any checksum changes; shared folder is strictly read-only |
| Per-file metadata: SHA-256, file size, last-modified date, row count, column count; for xlsx files: sheet list with row/column counts per sheet | Stored in `pdd.source_inventory` and `qc\source_inventory.xlsx` |
| Candidate key analysis per file: identify PRECEDE_STUDY_ID, ENCRYPTED_MRN, ENCRYPTED_ENCOUNTER, or other ID columns; test whether the key is unique per row (grain = patient) or has multiple rows per patient | Drives PDD-D-17 and PDD-D-18 |
| ID overlap: for each candidate key per file, count how many values match the s09 spine | Quantifies linkage coverage |
| Hash comparison against older copies in `P:\PeCAN Master Data\Gerard\raw\master` where the same filename exists | Report as: identical / different / no older copy |
| Header inventory reads directly from the 20 source files (not renamed copies, not the `g` library) | PDD-D-03: removes the xlsx conversion layer |
| Header × file matrix across all 20 files | Stored in `pdd.header_matrix` and `qc\header_matrix.xlsx` |
| Re-check prior expectations: ~701 CSV header instances, ~168 unique variables, ~41,150-row spine (s09) | These are expectations from the prior pipeline; Phase 2 establishes the authoritative counts |

**Blocks on:** PDD-D-17 (multi-row files) and PDD-D-18 (crosswalk-keyed files) are both **decided after** this phase based on its output.

---

### PDD-03 — Direct import of the 20 sources
**Roadmap phase:** Phase 3

Imports raw data with full fidelity, no PROC IMPORT guessing.

| Requirement | Detail |
|-------------|--------|
| `03_import.sas`: one DATA step per file with explicit INFORMATs and LENGTHs | PDD-D-02: values exactly as in source |
| PRECEDE_STUDY_ID and Base Procedure Code 1 read as **character** in all files | Avoids numeric/character type conflict hazard |
| Every INFILE uses `ENCODING='UTF-8'` | Required for esophagectomy descriptions in Base_Procedure_1 |
| s19 (ALL_AIM2.xlsx Sheet1): drop rows where PRECEDE_STUDY_ID is missing or all data columns are blank/`NULL`; log kept/dropped counts | PDD-D-08 |
| Output: `pdd.src_s01` … `pdd.src_s20` | Row counts reconciled in QC |
| Multi-row files (s01 PACU_STAY, s08 COLONOSCOPY): import as-is; how they enter PCNR_ follows PDD-D-17 | **Blocks on PDD-D-17** for s01, s08 |
| Crosswalk-keyed files (s04 ENCOUNTER Crypto, s05 MRN Crypto) and others not keyed on PRECEDE_STUDY_ID: import and assess; linkage method follows PDD-D-18 | **Blocks on PDD-D-18** for affected files |

---

### PDD-04 — Name map
**Roadmap phase:** Phase 4

Establishes the authoritative variable naming contract for PCNR_.

| Requirement | Detail |
|-------------|--------|
| `04_name_map.sas`: original header → cleaned name → `PCNR_` prefixed name | PDD-D-07 |
| Names truncated to ≤ 32 characters (≤ 27 after the `PCNR_` prefix); full original name kept as the SAS label and in the NAME_MAP sheet | PDD-D-07 |
| Collision detection: no two variables share the same `PCNR_` name | Logged as ERROR if any collision found |
| Output: `pdd.name_map` and `qc\name_map.xlsx` for Gerard review | Phase gate requires Gerard sign-off |

---

### PDD-05 — Build PCNR_ on the spine
**Roadmap phase:** Phase 5

Assembles the integrated PCNR_ analytic dataset.

| Requirement | Detail |
|-------------|--------|
| `05_build_pcnr.sas`: start from `pdd.src_s09` (spine, confirmed by Phase 2) | PDD-D-01, PDD-D-04 |
| Left-join 1:1 PRECEDE_STUDY_ID files on the spine; multi-row files (s01, s08) and crosswalk-keyed files (s04, s05) integrated per PDD-D-17 / PDD-D-18 | **Blocks on PDD-D-17, PDD-D-18** for those files |
| Spine value wins for overlapping variables; other files gap-fill where spine is missing | PDD-D-05 |
| Tie-break order among gap-fill sources follows PDD-D-15 once resolved | **Blocks on PDD-D-15 (open)** |
| Per-cell source flag (`PCNR_<var>_SRC`) follows PDD-D-16 once resolved | **Blocks on PDD-D-16 (open)** |
| Type-conflicting columns kept as character; no recoding | PDD-D-02 |
| `NULL` sentinel in ALL_AIM2 retained as-is | PDD-D-02 |
| QC output: gap-fill counts per variable; non-missing disagreements written to `qc\pcnr_conflicts` | PDD-D-05 |
| Output: `pdd.pcnr` with one row per spine patient and every variable from the inventory | Row count confirmed by Phase 2; QC sign-off required |

---

### PDD-06 — Distribution engine (reusable macro)
**Roadmap phase:** Phase 6

Provides a single profiling macro reused by all seven families.

| Requirement | Detail |
|-------------|--------|
| `%pdd_profile(lib=, ds=, prefix=, family=)` macro in `sas/macros/` | Called by every family's build phase |
| Classification logic per PDD-D-06: ≤ 20 distinct levels → count + % per level + missing count; numeric > 20 levels → N, missing, mean, SD, median, Q1/Q3, min, max; high-cardinality text → N distinct + top 10 | PDD-D-06 |
| Output: long-format profile table (variable, stat/level, value, n, pct) stored in `pdd` library | Standardized structure for the workbook writer |
| Validation: sex and Patient_Type counts from `pdd.pcnr` match PROC FREQ; missing counts exact | QC acceptance criterion |

---

### PDD-07 — Dictionary workbook writer
**Roadmap phase:** Phase 7

Produces the v1.0 deliverable workbook.

| Requirement | Detail |
|-------------|--------|
| `07_dictionary_xlsx.sas` writes one ODS Excel workbook | PDD-D-09 |
| Sheet order: KEY (leftmost), PCNR_, NAME_MAP, SOURCES, QC | PDD-D-09 |
| PCNR_ sheet: variables listed alphabetically; distribution inline next to each variable | PDD-D-06, PDD-D-09 |
| Placeholder sheets for PCNC_, PCND_, CLK_, LAB_, MED_, INTRA_ marked "source pending" | Communicates roadmap status |
| UF colors (#0021A5, #FA4616) in workbook header | Constraint from PROJECT.md |
| Output: `P:\PeCAN Master Data\Gerard\data_dictionary\out\pdd_v1_0.xlsx` | Gerard reviews and approves for v1.0 ship |

---

## Milestone v1.x: Remaining families

Each phase below repeats the source-guard → import → name-map → build → profile → sheet cycle for its family. Phases have no fixed order; whichever gate clears first runs first, except PDD-13 which depends on its inputs.

### PDD-08 — PCNC_ clinic data
**Roadmap phase:** Phase 8
**Gate:** PDD-D-11 (source location supplied by Gerard)

### PDD-09 — CLK_ clock variables
**Roadmap phase:** Phase 9
**Gate:** PDD-D-13 (source identified by Gerard)

### PDD-10 — LAB_ pre-operative labs
**Roadmap phase:** Phase 10
**Gate:** PDD-D-14 (path and linkage key confirmed)

### PDD-11 — MED_ medications
**Roadmap phase:** Phase 11
**Gate:** PDD-D-14 (path and linkage key confirmed)

### PDD-12 — INTRA_ intra-operative
**Roadmap phase:** Phase 12
**Gate:** PDD-D-14 (path and linkage key confirmed)

### PDD-13 — PCND_ derived variables
**Roadmap phase:** Phase 13
**Gate:** PDD-D-12 (definitions supplied by Gerard); depends on PCNR_ and all other resolved families.
This is where `?`, `NULL`, and `Unknown` cleaning and recoding happens (PDD-D-02 defers all cleaning here).

---

## Open decisions blocking v1.x

| ID | Blocks | Question |
|----|--------|----------|
| PDD-D-11 | PDD-08 | PCNC_ source location |
| PDD-D-12 | PDD-13 | PCND_ derived-variable list and definitions |
| PDD-D-13 | PDD-09 | CLK_ source |
| PDD-D-14 | PDD-10, PDD-11, PDD-12 | LAB_/MED_/INTRA_ paths and linkage keys |
| PDD-D-15 | PDD-05 | Gap-fill tie-break order among non-spine sources |
| PDD-D-16 | PDD-05 | Per-cell source flag vs. QC-only summary |
| PDD-D-17 | PDD-03 (s01, s08), PDD-05 (s01, s08) | Multi-row-per-patient files (PACU_STAY, COLONOSCOPY): aggregate, first/last, wide, or separate long table |
| PDD-D-18 | PDD-03 (s04, s05), PDD-05 (s04, s05) | Crosswalk-keyed files (ENCOUNTER/MRN Crypto): linkage path, whether they resolve old 2022 ID mismatch |
