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
- **Plans:** 3/3 plans complete

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
- **Status: ✅ VERIFIED 2026-10-20** — live run 9fd8943; all 20 src_s* reconciled (0 MISMATCH); n_pairs=9,001 ndis=0; exit=1 warnings only.
- **Plans:** 3/3 plans complete

Plans:
- [x] 03-01-PLAN.md — 03a_build_spec.sas: raw char-length pre-pass + import_spec.csv generation + s17 ambiguous-encounter extraction (wave 1)
- [x] 03-02-PLAN.md — 03_import.sas: spec-driven CSV + XLSX import of all 20 sources; s19 drop, s18 exclusion, s17 enc_for_linkage, s06 group profile (wave 2)
- [x] 03-03-PLAN.md — %pdd_norm_psid on all 20 + QC row-count reconciliation + wire into 99_run_all.sas (wave 3)

### Phase 4: Name map
- `04_name_map.sas`: original header → cleaned name → `PCNR_` name (≤32 chars, collision-checked) → label
- Reads `docs/s06_column_class.csv`; excludes class=CLOCK rows from the PCNR_ name map (D-21 LOCKED)
- CLOCK columns available as pdd.name_map status=EXCLUDED_CLK (2,747 rows) for Phase 9
- **Gate:** Gerard must review `qc\s06_clock_classification.xlsx` UNSURE sheet and resolve all UNSURE tokens before Phase 4 starts
- **Done when:** NAME_MAP has no duplicates or truncation collisions, and Gerard has reviewed it
- **Status: ✅ VERIFIED 2026-10-21 — all open items closed.** exit=0, warnings=0; 4795→1299 PCNR_, 0 collisions, 0 suffixes, 31 elided, 0 undecided near-matches; merged 93f1d09. Naming rules A1–A4 approved by Gerard 2026-10-21; Price sign-off pending before Phase 7 release. D-21 boundary confirmed: 34 COMmoca*/COPYmoca* stay PCNR_ (Gerard 2026-10-21). 9 type conflicts forwarded to Phase 5 (resolved there: N8 if all values parse, else C).
- **Plans:** 4 plans

Plans:
- [x] 04-01-PLAN.md — Wave 0 scaffold: seed CSVs (name_abbrev, name_map_decisions) + name_map_workbook.py + pytest (wave 1)
- [x] 04-02-PLAN.md — 04_name_map.sas Sections 0-8: load, status (D-04), clean/shorten (D-02/D-03), groups, two-stage collisions (D-05) (wave 2)
- [x] 04-03-PLAN.md — 04_name_map.sas Sections 9-15: near-match (D-06), dup Study ID (D-08), type tracking (D-07), name_map_vars, exports; wire 99_run_all (wave 3)
- [x] 04-04-PLAN.md — write_name_map_review.py + workbook verify + Gerard/Price review gate (wave 4)

### Phase 5: Build PCNR_ on the spine
- `05_build_pcnr.sas`: start from s09 (spine confirmed by Phase 2), left-join 1:1 PRECEDE_STUDY_ID files
- Iterative DATA-step merge loop (two datasets open at a time) in rank order from `docs/pcnr_source_priority.csv` (D-15)
- s01 and s08 join spine 1:1 (PDD-D-17 fully closed); s04/s05 contribute 0 PCNR_ columns, asserted (PDD-D-18)
- s06 columns: only class != CLOCK in `docs/s06_column_class.csv` are included in pdd.pcnr (D-21 LOCKED)
- Overlapping variables: spine value first, gap-fill by rank order (D-05/D-05b); conflicts classified SPINE_VS_SOURCE / SOURCE_VS_SOURCE (D-20)
- Type resolution before build for the 9 type-conflict variables: N8 if all parse, else C (D-02 amendment)
- QC-only provenance (D-16): pdd.qc_pcnr_provenance (2+-source cells); no per-cell _SRC columns
- QC: exchange CSVs → `qc\pcnr_qc.xlsx` (KEY, GAPFILL, SPINE_COVERAGE, CONFLICT_SUMMARY, CONFLICT_DETAIL cap 5,000, TYPECHECK)
- **Status: 🔧 IN PROGRESS — code review 2026-10-21 found blockers (pending fixes: _S alias type clash, conflict/provenance outputs, consolidation SET, PCNR_: keep, generated-file MOD append, pinned pass, reconciliation placeholder, GAPFILL performance). Not yet run.**
- **Done when:** `pdd.pcnr` has 41,150 rows × 1,299 PCNR_ + NORM_PSID, 0 dup/blank keys, 0 CLOCK columns, QC written and reviewed; wired into 99_run_all.sas; tests/05_build_test.sas SUMMARY failed=0; reconciliation sample 0 mismatches; GAPFILL identities hold; Python QC run from run_pipeline.cmd exit 0.
- **Plans:** 6 plans

Plans:
- [x] 05-01-PLAN.md — Wave 0 scaffold: docs/pcnr_source_priority.csv + pcnr_source_override.csv + lint-clean 05_build_pcnr.sas stub (wave 1)
- [x] 05-02-PLAN.md — Python QC writer: pcnr_qc_workbook.py + write_pcnr_qc.py + test_write_pcnr_qc.py (KEY-first, 5,000 cap) (wave 1)
- [x] 05-03-PLAN.md — 05_build_pcnr_macros.sas: Section 0 + %p5_preflight (D-18) + %p5_spine_coverage (D-19) + %p5_resolve_types (D-02) (wave 2)
- [x] 05-04-PLAN.md — 05_build_pcnr_macros.sas: %p5_build_accumulator + %p5_gapfill_source + %p5_finalize_pcnr + %p5_write_qc (wave 3)
- [x] 05-05-PLAN.md — 05_build_pcnr.sas orchestrator + Python QC invoke + wire Phase 5 into 99_run_all.sas (wave 4)
- [ ] 05-06-PLAN.md — tests/05_build_test.sas: TC-01..TC-24 covering all blockers (wave 5)

### Phase 6: Distribution engine (reusable macro)
- `%pdd_profile(lib=, ds=, prefix=, family=)`: classifies each variable by distinct-value count and computes distributions per PDD-D-06
- Writes long-format profile tables (variable, stat/level, value, n, pct) that any family can reuse
- **Done when:** run on `pdd.pcnr`, its sex and Patient_Type counts match PROC FREQ and missing counts are exact

### Phase 7: Dictionary workbook writer
- SAS writes distribution data to `pdd` library; Python (`python\scripts\write_dictionary.py`) writes the xlsx workbook (PDD-D-22)
- Sheet order: KEY (leftmost) | PCNR_ | NAME_MAP | SOURCES | QC; UF header colors via `python\pdd\xlsx_style.py`
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
| PDD-D-11 | Phase 8 | PCNC_ source location |
| PDD-D-12 | Phase 13 | PCND_ definitions |
| PDD-D-13 | Phase 9 | CLK_ authoritative source (s06 clock columns are candidate; pending confirmation) |
| PDD-D-14 | Phases 10–12 | LAB_/MED_/INTRA_ paths and linkage keys |

## Decided (closed)
| ID | Decided | Resolution |
|----|---------|------------|
| PDD-D-15 | 2026-10-21 | Gap-fill tie-break: rank order from docs/pcnr_source_priority.csv; spine wins unconditionally |
| PDD-D-16 | 2026-10-21 | QC-only provenance (pdd.qc_pcnr_provenance); no per-cell _SRC columns in pdd.pcnr |
| PDD-D-17 | 2026-10-19 | FULLY CLOSED. All 20 files are 1:1 per PRECEDE_STUDY_ID. s01 (41,423 distinct) and s08 (3,456 distinct) are NOT multi-row. 274 s01 IDs not in spine are a QC item. s18 has 2 dup/blank key rows (qc_s18_dup). |
| PDD-D-18 | 2026-10-19 | s04/s05 confirmed as linkage/QC files (same encryption, 100% match) — not dictionary variables; contribute 0 PCNR_ columns (asserted). |

## Not in scope (v1.0)
- Cohort restriction (all spine patients are profiled)
- Recoding or cleaning PCNR_ values
