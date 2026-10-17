# Roadmap: PeCAN Data Dictionary (PDD)

## Milestone v1.0: PCNR_ raw layer and dictionary framework
Builds everything that has a known source. All later families plug into the same framework.

### Phase 1: Repo and config scaffold
- `C:\data_dictionary` git repo, `.gitignore` excluding all data
- `sas/00_config.sas`: paths (raw\master, P: output root), `pdd` libname helper, UTF-8 options
- `run_pipeline.cmd`, `99_run_all.sas` skeleton, log directory convention
- **Done when:** an empty run writes a clean log to `P:\...\data_dictionary\logs`

### Phase 2: Source guard and header inventory
- `02_source_guard.sas`: SHA-256 baseline of the 8 raw\master files; fails the run if any file changes
- Header inventory from the raw CSV/XLSX headers (not the renamed copies): file × header matrix, inferred type, row count
- **Done when:** the inventory reproduces 701 CSV header instances and about 168 unique variables

### Phase 3: Direct import of the 8 sources
- `03_import.sas`: one data step per CSV with explicit INFORMATs/LENGTHs. IDs and codes read as character; no PROC IMPORT guessing.
- `ENCODING='UTF-8'` on every infile; check the Base_Procedure_1 esophagectomy rows render correctly
- s8 (ALL_AIM2): read Sheet1, drop blank/no-ID rows (PDD-D-08), log kept/dropped counts
- Drop the duplicate "PRECEDE Study ID" column in s6/s7 after confirming it equals PRECEDE_STUDY_ID
- **Done when:** each `pdd.src_s1..s8` has one row per PRECEDE_STUDY_ID and the row counts are reconciled in QC

### Phase 4: Name map
- `04_name_map.sas`: original header → cleaned name → `PCNR_` name (≤32 chars, collision-checked) → label
- **Done when:** NAME_MAP has no duplicates or truncation collisions, and Gerard has reviewed it

### Phase 5: Build PCNR_ on the spine
- `05_build_pcnr.sas`: start from s3 (41,150 rows), then left-join s1, s2, s4–s8 on PRECEDE_STUDY_ID
- Overlapping variables: spine value first, gap-fill from the other files (PDD-D-05; tie-break waits on PDD-D-15)
- Values exactly as in source (PDD-D-02); type-conflicting columns kept as character
- QC: gap-fill counts per variable, non-missing disagreements written to `qc\pcnr_conflicts`
- **Done when:** `pdd.pcnr` is 41,150 rows, contains every variable from the inventory, and QC has signed off

### Phase 6: Distribution engine (reusable macro)
- `%pdd_profile(lib=, ds=, prefix=, family=)`: classifies each variable by distinct-value count and computes distributions per PDD-D-06
- Writes long-format profile tables (variable, stat/level, value, n, pct) that any family can reuse
- **Done when:** run on `pdd.pcnr`, its sex and Patient_Type counts match PROC FREQ and missing counts are exact

### Phase 7: Dictionary workbook writer
- `07_dictionary_xlsx.sas`: one workbook with sheets KEY (leftmost) | PCNR | NAME_MAP | SOURCES | QC
- Variables listed alphabetically; the distribution sits next to each variable; UF header colors
- Placeholder sheets for PCNC, PCND, CLK, LAB, MED, INTRA, each marked "source pending"
- **Done when:** Gerard reviews the workbook and v1.0 ships

## Milestone v1.x: Remaining families (each gated on its open decision)
Each phase repeats Phases 2–7 for its family: source guard, import, name map, build, profile, sheet.

| Phase | Family | Gate |
|-------|--------|------|
| 8 | `PCNC_` clinic data | PDD-D-11 source supplied |
| 9 | `CLK_` clock variables | PDD-D-13 source identified |
| 10 | `LAB_` pre-op labs | PDD-D-14 path and linkage key |
| 11 | `MED_` medications | PDD-D-14 path and linkage key |
| 12 | `INTRA_` intra-op | PDD-D-14 path and linkage key |
| 13 | `PCND_` derived variables | PDD-D-12 definitions; built from PCNR_ and the other families. This is where `?`/`NULL`/`Unknown` cleaning happens |

Phases 8–13 have no fixed order. Whichever gate clears first runs first, except PCND_, which depends on its inputs.

## Not in scope (v1.0)
- Cohort restriction (all 41,150 patients are profiled)
- Recoding or cleaning PCNR_ values
- Resolving the 2022 raw-file ID mismatch (prior PCM-D-16); revisit only if a family's source needs it
