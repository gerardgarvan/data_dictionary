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
- **Status: ✅ COMPLETE — merged to master at fbf3c35 (2026-10-26). SAS tests passed=94 failed=0; pipeline exit 0, 0 warnings; pdd.pcnr 41,150 × 1,298 PCNR_ + NORM_PSID; recon 0 mismatches; conflicts 97,194 events / 95,840 cells (REAL 51,835; CODING_EQUIV 29,644; PLACEHOLDER 13,038; ROUNDING 1,956; NUMERIC_CLOSE 473; TOPCODE 248); provenance 342,605; ALL_MISSING 56.**
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
- **Status: ✅ COMPLETE — merged to master e912941 (2026-10-26). Tests passed=138 failed=0; pipeline exit 0, 0 warnings. pdd.prf_pcnr 5,642 rows / 1,297 vars: LOW_CARD 1,097 | CONT_NUM 123 | NUM_TEXT 38 | HIGH_CARD 29 | SUPPRESSED 10. D-08 recon PASS; D-09 validation PASS. require_suppress=1 guard; categorical_file= D-11 override; check_test_log.ps1 external log hygiene tool added.**
- **Done when:** run on `pdd.pcnr`, its sex and Patient_Type counts match PROC FREQ and missing counts are exact
- **Plans:** 4/4 plans complete

Plans:
- [x] 06-01-PLAN.md — 06_profile_macros.sas Section 0 utilities + %p6_preflight + %p6_classify_vars (four-tier D-06 + D-05 exclusions) (wave 1)
- [x] 06-02-PLAN.md — 06_profile_macros.sas tier computation + %p6_write_output (D-02/D-03/D-04/D-07/D-08) + %pdd_profile entry point (wave 2)
- [x] 06-03-PLAN.md — 06_profile.sas orchestrator + wire Phase 6 into 99_run_all.sas (wave 3)
- [x] 06-04-PLAN.md — tests/06_profile_test.sas TC-01..TC-25 acceptance suite + D-09/D-10/D-11 + check_test_log.ps1 (wave 4)

### Phase 7: Dictionary workbook writer
- SAS writes distribution data to `pdd` library; Python (`python\scripts\write_dictionary.py`) writes the xlsx workbook (PDD-D-22)
- Sheet order: KEY (leftmost) | PCNR_ | NAME_MAP | SOURCES | QC; UF header colors via `python\pdd\xlsx_style.py`
- Placeholder sheets for PCNC, PCND, CLK, LAB, MED, INTRA, each marked "source pending"
- **Done when:** Gerard reviews the workbook and v1.0 ships
- **Plans:** 3/3 plans complete

Plans:
- [x] 07-01-PLAN.md -- SAS orchestrator (07_build_profile.sas), exchange_schema.csv extension, source_notes.csv seed
- [x] 07-02-PLAN.md -- python/pdd/dictionary_workbook.py core module + test suite (wave 2, parallel with 07-01)
- [x] 07-03-PLAN.md -- python/scripts/write_dictionary.py entry point + run_pipeline.cmd Phase 7 block (wave 3)
 (completed 2026-10-27)

## Milestone v2.0: PCNR_ 2018-2025, PECAN_ID, PCNR_Master_Data_Nov_2026
Two deliverables covering surgical cases 2018-2025: (A) a data dictionary with `PECAN_ID` first and `PCNR_` variables alphabetical with distributions, (B) `PCNR_Master_Data_Nov_2026.xlsx`. Source brief: `.planning/MILESTONE_BRIEF_2018_2025.md` (revised 52f6ad9). Requirements: `.planning/REQUIREMENTS.md`. Phases M1-M6 are numbered 14-19 (continuing after Phase 13). The first probe is committed (`.planning/schemas/probe_master_data_20261116.md`, strip-fix rerun, 2026-11-16), so Phase 15 is unblocked. Decisions PDD-D-25..29 are in `docs/DECISIONS.md` (PDD-D-26, PDD-D-28, PDD-D-29 DECIDED; PDD-D-25 CLOSED - NOT NEEDED; PDD-D-27 OPEN).

Phases 8-13 (v1.x) stay gated and independent; v2.0 depends only on the completed v1.0 (Phases 1-7).

### Phase 14 (M1): Probe and headless setup
- **Goal:** Make facts about the old and new source files available to the Claude Code machine, and make headless runs safe.
- **Depends on:** Phase 7 (v1.0 complete)
- **Requirements:** PRB-01, PRB-02, PRB-03, RUN-01
- **Status:** COMPLETE. Probe committed: `.planning/schemas/probe_master_data_20261116.md` (strip-fix rerun, 2026-11-16; PRB-02, success criterion 3 met; PDD-D-28 and PDD-D-29 decided from it). PRB-03 done (CLAUDE.md rules). RUN-01: `pdd_sdk_run.py` in repo; `logs/api_runs/ledger.csv` shows `sdk_test` runs. Success criterion 1 met: `sas_lint` reports 0 errors on `sas/probe_inputs.sas`; `sasjs lint` reports style warnings only (line length, indentation), no errors.
- **Success criteria:**
  1. `sas/probe_inputs.sas` passes `python tools\sas_lint.py` and `sasjs lint` with zero errors.
  2. Gerard's run writes `.planning/schemas/probe_master_data_<yyyymmdd>.md` listing every file and sheet (the 20 existing and every new 2023-2025 file) with the PRB-01 fields, counts 1-10 shown as `<11`, no data values; it is committed.
  3. The probe reports ID-like columns (shapes, 1:1 check, overlap with spine case IDs and encrypted MRNs), so the brief's key-change findings (0 K2 MRNs in the K1 spine, K2 values 5 characters longer) are confirmed from a committed file, and PDD-D-28 and PDD-D-29 can be decided.
  4. `pdd_sdk_run.py` refuses main/master and dirty trees, logs cost per step to `logs/api_runs/`, and refuses new steps at the cap (verified by `sdk_test`).
  5. CLAUDE.md contains the probe-first and headless rules and the SAS pitfalls list (already true).
- **Plans:** TBD (plan-phase may run now; it ends in PENDING SAS RUN)

### Phase 15 (M2): New-source intake
- **Goal:** Guard, inventory, import and check the new 2023-2025 files without disturbing the 20 existing ones.
- **Depends on:** Phase 14 (probe committed)
- **Requirements:** NEW-01, NEW-02, NEW-03, NEW-03a, NEW-04, NEW-05
- **Success criteria:**
  1. The existing 20-file SHA-256 baseline matches unchanged; new files get their own baseline entries by an explicit approved step, not a silent re-baseline.
  2. Header inventory covers the same file x header matrix for the new files.
  3. New files import with explicit informats/lengths, IDs/codes as character, `encoding='wlatin1'` for the files the probe flags (brief: 2024 and 2025; 2023 is UTF-8) per D-23; 5-digit case IDs use the PDD-D-19 rule unchanged (PDD-D-29, DECIDED); row counts reconcile to the probe.
  4. Header variants (Braden columns by year, `Fraility_Score`, `SleepApnea_YN`, `Preop_Edu_Years`) are mapped, not renamed at source; type changes (`Death_Days_After_Surgery`, five frailty components) go to the map review.
  5. Each new file is checked 1:1 per case; any non-1:1 file stops at a decision gate.
  6. Era-overlap counts and conflicting shared-column values are reported to QC; the probe found 0 overlap with the spine, so PDD-D-25 (precedence) is CLOSED - NOT NEEDED. **Gate (PDD-D-29 item 3):** also count normalized case IDs shared between each pair of the 2023, 2024 and 2025 files; if any are shared, stop at a decision gate (do not stack) and list the counts per pair.
- **Plans:** 5 plans (written headless 2026-11-16; execution ends PENDING SAS RUN, baseline approval PENDING DECISION)

Plans:
- [ ] 15-01-PLAN.md — docs/new_source_files.csv, header-variant seed (NEW-03a), sas/15a_new_source_guard.sas: 20-file check unchanged + approval-gated 3-file baseline (wave 1)
- [ ] 15-02-PLAN.md — sas/15b_new_inventory_spec.sas: header inventory + matrix (NEW-02), per-encoding pre-pass and docs/import_spec_new_generated.csv (NEW-03) (wave 2)
- [ ] 15-03-PLAN.md — sas/15c_new_import.sas: import to pdd.nsrc_s21..s23 + norm_psid, reconcile, type changes, 1:1 gate (NEW-04), overlap + PDD-D-29 item 3 gate (NEW-05) (wave 3)
- [ ] 15-04-PLAN.md — Python QC writer qc\new_source_intake.xlsx + exchange_schema rows + <11-masked summary (wave 1)
- [ ] 15-05-PLAN.md — wire phase 15 into 99_run_all.sas and run_pipeline.cmd, run sheet 15-SAS-RUN.md, STATE markers, SAS-run checkpoint (wave 4)

### Phase 16 (M3): Name map extension
- **Goal:** Map new headers to PCNR_ names under the Phase 4 rules and record year coverage per variable.
- **Depends on:** Phase 15
- **Requirements:** MAP-01, MAP-02, MAP-03, MAP-04
- **Success criteria:**
  1. Exact header matches reuse the existing PCNR_ name (existing map: 1,297 PCNR_ variables after D-24; the brief's 1,299 counts the two LINKAGE_ONLY columns).
  2. Near-matches are listed with value distributions side by side as `PENDING DECISION` for Gerard; none is auto-merged.
  3. New columns get PCNR_ names under rules A1-A4 with 0 collisions and 0 truncation collisions; names already in use keep their meaning.
  4. First and last surgical year with non-missing values, and contributing source files, are recorded per variable.
  5. Price's naming sign-off remains listed as pending.
- **Plans:** TBD

### Phase 17 (M4): PECAN_ID
- **Goal:** Give every 2018-2025 case a `PECAN_ID` through an append-only, key-era-aware registry, and ship a tested linkage program for later.
- **Depends on:** Phases 15-16. PDD-D-28 (PECAN_ID = master-merge `pecan_ID`) and PDD-D-26 are DECIDED, so Phase 17 is no longer blocked on a decision.
- **Requirements:** PID-01, PID-02, PID-03, PID-04, PID-05, PID-06, PID-07, PID-08
- **Success criteria:**
  1. PDD-D-28 is DECIDED and recorded; K2 IDs are `1000000 + rank` (PID-04) and cannot collide with K1 IDs.
  2. `PECAN_ID` carries master-merge `pecan_ID` values unchanged (PID-01); the K1 seed passes the PDD-D-28 seed checks; `g.pecan_id_xwalk` is read-only via a `00_config.sas` libname (PID-08); the dictionary row uses the PDD-D-28 wording.
  3. Every encrypted MRN is tagged K1 or K2 and never compared across eras; `pdd.pecan_id_registry` (on P:, not in git) is append-only, seeded from `g.pecan_id_xwalk` unchanged; reruns keep known IDs and no ID is renumbered or reused; K2 assignment is deterministic.
  4. Combined dataset carries `PECAN_ID` and `PECAN_ID_KEY_ERA`; dictionary and master KEY sheet state that patients in both eras have two PECAN_IDs until linked.
  5. `sas/pecan_id_link.sas` is written and tested but not run; a QC report lists every ID that would change.
  6. Cases-per-patient summary (PECAN_ID vs PRECEDE_STUDY_ID) exists per era and combined with the caveat.
- **Plans:** TBD

### Phase 18 (M5): Combined dataset and dictionary 2018-2025
- **Goal:** One combined case-level PCNR_ dataset and the regenerated dictionary workbook.
- **Depends on:** Phases 15, 16, 17 (PDD-D-25 closed, not needed)
- **Requirements:** DD-01, DD-02, DD-03, DD-04
- **Success criteria:**
  1. Combined dataset in the `pdd` library on P: (not in git) has PECAN_ID and PRECEDE_STUDY_ID first.
  2. Values equal source values (no recoding).
  3. Dictionary workbook: KEY sheet leftmost, PECAN_ID first, PCNR_ variables alphabetical, distributions over all 2018-2025 cases, plus year coverage and source columns (MAP-04); UF colors.
  4. Reconciliation: dictionary rows = dataset columns; per-variable non-missing counts match; 2018-2022 distributions match the v1.0 dictionary except where new cases add rows.
- **Plans:** TBD

### Phase 19 (M6): Master Excel export
- **Goal:** Write `PCNR_Master_Data_Nov_2026.xlsx` and prove it round-trips.
- **Depends on:** Phase 18
- **Requirements:** XLS-01, XLS-02, XLS-03, XLS-04
- **Success criteria:**
  1. Workbook at `P:\PeCAN Master Data\Gerard\data_dictionary\out\` has KEY leftmost (source, date, row/column counts, ID definitions, missing-value convention) and DATA.
  2. Pre-export checks stop the run at rows >= 1,048,575, columns >= 16,384, or any text cell > 32,767 characters.
  3. Round-trip QC in `qc\` matches row count, column names in order, and per-column non-missing counts with the SAS dataset.
  4. Whether the dictionary is a sheet in this file follows PDD-D-27 (OPEN, default no).
- **Plans:** TBD

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
v2.0 decisions PDD-D-25..29 (PDD-D-26, PDD-D-28, PDD-D-29 DECIDED; PDD-D-25 CLOSED - NOT NEEDED) and Price's naming sign-off are in `docs/DECISIONS.md`.

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
