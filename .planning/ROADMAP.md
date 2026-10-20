# Roadmap: PeCAN Data Dictionary (PDD)

## Milestone v1.0: PCNR_ raw layer and dictionary framework
Builds everything that has a known source. All later families plug into the same framework.

### Phase 1: Repo and config scaffold
- `C:\data_dictionary` git repo, `.gitignore` excluding all data
- `sas/00_config.sas`: paths (raw\master, P: output root), `pdd` libname helper, UTF-8 options
- `run_pipeline.cmd`, `99_run_all.sas` skeleton, log directory convention
- **Done when:** an empty run writes a clean log to `P:\...\data_dictionary\logs`
- **Plans:** 2/2 plans complete

Plans:
- [x] 01-01-PLAN.md — Create sas/00_config.sas (macro variables, %pdd_lib, in_pipeline guard, SAS options)
- [x] 01-02-PLAN.md — Create run_pipeline.cmd and sas/99_run_all.sas (batch driver + pipeline runner skeleton)

### Phase 2: Source guard and header inventory
- `02_source_guard.sas`: SHA-256 baseline of all 20 shared-folder files; run fails with ERROR if any checksum changes; shared folder is strictly read-only
- Per-file metadata: SHA-256, file size, modified date, row count, column count; sheet list for xlsx files
- Candidate key analysis: PRECEDE_STUDY_ID, ENCRYPTED_MRN, ENCRYPTED_ENCOUNTER, or other; grain (unique vs. multi-row per patient)
- ID overlap: match counts against the s09 spine candidate for each candidate key
- Hash comparison of shared-folder files against older copies in `P:\PeCAN Master Data\Gerard\raw\master` (identical / different / no older copy)
- Header × file matrix across all 20 files; inferred type per column
- Re-check prior expectations: ~701 header instances, ~168 unique variables, ~41,150-row spine
- **Done when:** source inventory, key/grain analysis, hash comparison, and header matrix are written to `pdd` library and `qc\`; PDD-D-17 and PDD-D-18 can be decided from the output
- **Plans:** 1/3 plans executed

Plans:
- [x] 02-01-PLAN.md — Program scaffold, 20-file list, FINFO metadata, certutil SHA-256, two-branch hash baseline guard, pdd.source_inventory (wave 1)
- [x] 02-02-PLAN.md — Import loop (CSV + XLSX), header inventory, candidate key + grain analysis, ID overlap vs s09 spine (wave 2)
- [x] 02-03-PLAN.md — ODS Excel QC workbooks (KEY sheet, UF colors), output assertions + log restore, wire into 99_run_all.sas (wave 3)

### Phase 3: Direct import of the 20 sources
- `03_import.sas`: one data step per file with explicit INFORMATs/LENGTHs. IDs and codes read as character; no PROC IMPORT guessing.
- `ENCODING='UTF-8'` on every infile; check the Base_Procedure_1 esophagectomy rows render correctly
- s19 (ALL_AIM2): read Sheet1, drop blank/no-ID rows (PDD-D-08), log kept/dropped counts
- s01 PACU_STAY and s08 COLONOSCOPY: import as-is; both confirmed 1:1 per PRECEDE_STUDY_ID (PDD-D-17 fully closed); join spine like any 1:1 file
- Crosswalk-keyed files (s04, s05) and other non-PRECEDE_STUDY_ID-keyed files: import and stage; linkage follows PDD-D-18
- **Done when:** `pdd.src_s01`…`pdd.src_s20` exist; row counts reconciled in QC; **blocks on PDD-D-17 and PDD-D-18 for affected files**
- **Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md — 03a_build_spec.sas: raw char-length pre-pass + import_spec.csv generation + s17 ambiguous-encounter extraction (wave 1)
- [ ] 03-02-PLAN.md — 03_import.sas: spec-driven CSV + XLSX import of all 20 sources; s19 drop, s18 exclusion, s17 enc_for_linkage, s06 group profile (wave 2)
- [ ] 03-03-PLAN.md — %pdd_norm_psid on all 20 + QC row-count reconciliation + wire into 99_run_all.sas (wave 3)

### Phase 4: Name map
- `04_name_map.sas`: original header → cleaned name → `PCNR_` name (≤32 chars, collision-checked) → label
- **Done when:** NAME_MAP has no duplicates or truncation collisions, and Gerard has reviewed it

### Phase 5: Build PCNR_ on the spine
- `05_build_pcnr.sas`: start from s09 (spine confirmed by Phase 2), left-join 1:1 PRECEDE_STUDY_ID files
- s01 and s08 join spine 1:1 (PDD-D-17 fully closed); crosswalk-keyed files (s04, s05) integrated per PDD-D-18
- Overlapping variables: spine value first, gap-fill from the other files (PDD-D-05; tie-break waits on PDD-D-15)
- Values exactly as in source (PDD-D-02); type-conflicting columns kept as character
- QC: gap-fill counts per variable, non-missing disagreements written to `qc\pcnr_conflicts`
- **Done when:** `pdd.pcnr` has one row per spine patient, contains every variable from the inventory, and QC has signed off; **blocks on PDD-D-17 and PDD-D-18 for s01, s04, s05, s08**

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

## Open decisions (phase gates)
| ID | Blocks | Description |
|----|--------|-------------|
| PDD-D-15 | Phase 5 | Gap-fill tie-break order among non-spine sources |
| PDD-D-16 | Phase 5 | Per-cell source flag vs. QC-only summary |
| PDD-D-17 | Phase 3 (s01, s08), Phase 5 (s01, s08) | Multi-row-per-patient files — aggregate / first-last / wide / separate long table — decided after Phase 2 |
| PDD-D-18 | Phase 3 (s04, s05), Phase 5 (s04, s05) | MRN/encounter-keyed crosswalk files — linkage path and ID mismatch resolution — decided after Phase 2 |

## Not in scope (v1.0)
- Cohort restriction (all spine patients are profiled)
- Recoding or cleaning PCNR_ values
