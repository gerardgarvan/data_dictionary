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

Protects the read-only source layer and documents the raw variable universe.

| Requirement | Detail |
|-------------|--------|
| `02_source_guard.sas` computes SHA-256 of all 8 `raw\master` files and stores the baseline | Run fails with an ERROR if any checksum changes |
| Header inventory reads directly from the 8 source files (not the renamed xlsx copies, not the `g` library) | PDD-D-03: removes the xlsx conversion layer |
| Inventory output: file × header matrix, inferred type, row count | Stored in `pdd` library and/or `qc\` |
| Inventory reproduces **701** CSV header instances and approximately **168** unique variables | QC acceptance criterion |

---

### PDD-03 — Direct import of the 8 sources
**Roadmap phase:** Phase 3

Imports raw data with full fidelity, no PROC IMPORT guessing.

| Requirement | Detail |
|-------------|--------|
| `03_import.sas`: one DATA step per file with explicit INFORMATs and LENGTHs | PDD-D-02: values exactly as in source |
| PRECEDE_STUDY_ID and Base Procedure Code 1 read as **character** in all files | Avoids numeric/character type conflict hazard |
| Every INFILE uses `ENCODING='UTF-8'` | Required for esophagectomy descriptions in Base_Procedure_1 |
| s8 (ALL_AIM2.xlsx Sheet1): drop rows where PRECEDE_STUDY_ID is missing or all data columns are blank/`NULL`; log kept/dropped counts | PDD-D-08 |
| Duplicate "PRECEDE Study ID" column in s6/s7 dropped after confirming equality to PRECEDE_STUDY_ID | Documents the confirmation in QC |
| Output: `pdd.src_s1` … `pdd.src_s8`, each with one row per PRECEDE_STUDY_ID | Row counts reconciled in QC |

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
| `05_build_pcnr.sas`: start from `pdd.src_s3` (41,150 rows = spine) | PDD-D-01, PDD-D-04 |
| Left-join s1, s2, s4–s8 on PRECEDE_STUDY_ID | PDD-D-01 |
| Spine value wins for overlapping variables; other files gap-fill where spine is missing | PDD-D-05 |
| Tie-break order among gap-fill sources (s1, s2, s4–s8) follows PDD-D-15 once resolved | **Blocks on PDD-D-15 (open)** |
| Per-cell source flag (`PCNR_<var>_SRC`) follows PDD-D-16 once resolved | **Blocks on PDD-D-16 (open)** |
| Type-conflicting columns kept as character; no recoding | PDD-D-02 |
| `NULL` sentinel in ALL_AIM2 retained as-is | PDD-D-02 |
| QC output: gap-fill counts per variable; non-missing disagreements written to `qc\pcnr_conflicts` | PDD-D-05 |
| Output: `pdd.pcnr` with exactly 41,150 rows and every variable from the inventory | QC sign-off required |

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
