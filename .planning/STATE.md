---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Phase 18 COMPLETE 2026-11-18; next Phase 19
last_updated: "2026-11-17T00:19:56.099Z"
progress:
  total_phases: 8
  completed_phases: 7
  total_plans: 25
  completed_plans: 26
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current milestone: v2.0 - PCNR_ 2018-2025, PECAN_ID, PCNR_Master_Data_Nov_2026 (started 2026-11-16)

**Phase 15 status (2026-11-16):** 15a done (new baseline approved and committed). 15b done (spec committed). 15c PASS after PDD-D-30 (s22 wins, s23 gap-fills). `run_pipeline.cmd 15` passed (Pipeline PASSED 2026-11-16 17:11); `qc
ew_source_intake.xlsx` written. **Phase 15 COMPLETE (NEW-01..NEW-05, NEW-03a).** **Next step:** Phase 16 SAS runs per `16-05-PLAN.md` (16a and 16b can both run now).

Earlier note (superseded, Phase 15 closed): Phase 15 (M2) could be planned: the Phase 14 probe is committed (`.planning/schemas/probe_master_data_20261116.md`, strip-fix rerun, 2026-11-16). Phase 14 is complete: `sas/probe_inputs.sas` now has 0 `sas_lint` errors and 0 `sasjs lint` errors (style warnings only: line length and indentation). Phase 15 gate: count normalized case IDs shared between each pair of the 2023, 2024 and 2025 files (PDD-D-29 item 3).

| Phase | Milestone label | Title | Status |
|-------|-----------------|-------|--------|
| 14 | M1 | Probe and headless setup | Complete (PRB-01..03, RUN-01 satisfied) |
| 15 | M2 | New-source intake | Complete 2026-11-16 (NEW-01..NEW-05, NEW-03a satisfied; 15a/15b/15c and pipeline 15 run and passed) |
| 16 | M3 | Name map extension | Complete 2026-11-17 (MAP-01..04 satisfied; test T1-T9 passed, 16a PASS, 16b 1297 variables / 56 NO_DATA, `run_pipeline.cmd 16` PASSED, 0 WARNING) |
| 17 | M4 | PECAN_ID | Complete 2026-11-17 (PID-01..08; tests T1-T18 and T0-T7 passed; 17a approved 41150 rows 1:1 / 33031 K1 IDs / 1895 dup pairs; 17b 26474 K2 MRNs, registry 59505, case map 77498; see 17-SUMMARY.md) |
| 18 | M5 | Combined dataset and dictionary 2018-2025 | Complete 2026-11-18 (DD-01..DD-04; test, 18a-18d and writer PASS on real data; see 18-SUMMARY.md) |
| 19 | M6 | Master Excel export | Planned 2026-11-18 (19-PLAN.md); decisions PDD-D-35..44 PENDING; code not started |

**Phase 18 COMPLETE (2026-11-18).** Verified by Gerard: test ALL TESTS PASSED; 18a PASS; 18b PASS (77,498 x 1,302; backup path also PASS); 18c PASS (19 QC items clean); 18d PASS (0 hits); writer exit 0 (`out\pdd_2018_2025.xlsx`). PDD-D-33 and PDD-D-34 CONFIRMED 2026-11-18. See `18-SUMMARY.md`.

**Phase 19 PLANNED (2026-11-18, headless, docs only):** `.planning/phases/19-master-data-workbook/19-PLAN.md` + `19-CONTEXT.md`. Recommended route (b1): SAS stage CSV + schema -> Python openpyxl write_only -> separate Python verifier. **PENDING DECISION:** PDD-D-35..44 (route, NO_DATA, order, dates, NUM_TEXT, special missing, sheets, companion files, key columns, disclosure sign-off) and PDD-D-27; rows added to `docs/DECISIONS.md`. **PENDING SAS RUN:** `19_xlsx_test.sas` and `19a_xlsx_preflight.sas` (probes P19-1..8) once those programs are implemented; then 19b, writer, verifier. Waves 1 (config, macros, test, 19a, writer, verifier code) can start now.

**Phase 19 handoff:** Phase 19 builds `PCNR_Master_Data_Nov_2026.xlsx`. Any percentages must come from the scrubbed exchange profile or be recomputed with the same masking, never from `pdd.prf_PCNR_2018_2025` directly. Output only under `P:\PeCAN Master Data\Gerard\data_dictionary`.

**Open items carried forward:** Price naming sign-off; PDD-D-27 (dictionary as a sheet in the master file, default no); cleanup backlog 1, 2, 3, 5, 6; DSS question on the 116 `#Error` deaths with Death_Date_Y_N = Y; future cross-era link (loosen the 17c total check for superseded IDs).

(Historical, superseded by the close above.) **Phase 18 planned (2026-11-17, headless):** plans 18-01 (type seed, config, exchange schema), 18-02 (macros + synthetic test), 18-03 (18a preflight/probe), 18-04 (18b build), 18-05 (18c profile/recon, 18d MRN scan), 18-06 (dictionary workbook writer), 18-07 (wiring, 18-SAS-RUN, checkpoint). **PENDING SAS RUN:** 18_combine_test, 18a, 18b, 18c, 18d, writer (after execution of the plans). **PDD-D-33 DECIDED (Gerard, 2026-11-17):** K2 PRECEDE_STUDY_ID = normalized `Precede#####` (default `PDD_K2_PSID_MODE`=NORM, no stop). 18a is also the probe for the pdd.pcnr 1298-vs-1297 column question and the ASA/CPT1 numeric check (PDD-D-31 item 2, conditional). Research subagent skipped for budget; plan checker run once (3 blockers fixed: split 18-01, no PDD-D-33 default, CONDITIONAL ASA/CPT1).

**Phase 18 executed, headless (2026-11-17):** 18-01 (seed `docs/combined_type_decisions.csv`, config `comb_ds`, `comb_backup_stem`, `PDD_K2_PSID_MODE` default NORM, exchange schema), 18-02 (`sas/18_combine_macros.sas`, `sas/18_combine_test.sas`), 18-03 (`18a_comb_preflight.sas`), 18-04 (`18b_comb_build.sas`), 18-05 (`18c_comb_profile_qc.sas`, `18d_comb_scan.sas`), 18-06 (`python/pdd/dictionary_2018_2025_workbook.py`, `python/scripts/write_dictionary_2018_2025.py`), 18-07 (token 18 in `99_run_all.sas` and `run_pipeline.cmd`, `18-SAS-RUN.md`, `18-VALIDATION.md`). PDD-D-33 DECIDED (K2 PRECEDE_STUDY_ID = normalized Precede#####, default NORM, stop removed). ASA_Anesth_Record and CPT1_Class stay conditional numeric: 18a measures both sides and stops at PENDING DECISION on any non-numeric value. Plan-checker items applied (KEY sheet states the DD-04 limit: counts and distinct values, not level-by-level frequencies; tests in `python/tests/`; `test_phase17_programs_static.py` and the phase 15/16 wiring tests updated for token 18). **PENDING SAS RUN (Gerard):** `18_combine_test.sas`, then 18a, 18b, 18c, 18d (each in a fresh session), then the writer. **PENDING DECISION:** none open; one arises only if a gate stops (see the table in 18-SAS-RUN.md). Price naming sign-off still pending. Assumptions: `18-CONTEXT.md` section Assumptions (headless run), A9-A15.

**Phase 17 COMPLETE (2026-11-17).** PDD-D-32 EXECUTED. **Next:** Phase 18 (combined dataset and dictionary). Price naming sign-off remains PENDING.

**Carry to Phase 18 (from Phase 17):**
- Join the new files (`pdd.nsrc_s21..s23`) on `norm_psid` to `pdd.pecan_id_case_map` (K2 rows carry `PRECEDE_STUDY_ID` blank).
- Apply PDD-D-30 field gap-fill (s22 wins, s23 fills) and PDD-D-31 combined types; ASA and CPT1 Class numeric.
- Flag the 56 s06 NO_DATA variables in the dictionary.
- PECAN_ID dictionary text from `docs/pecan_id_dictionary_text.csv`.
- State in the dictionary that 1895 K1 dup pairs (`pdd.pecan_id_dup_link`) exist: PECAN_ID is per encryption era until the link is applied (patients in both eras and K1 patients with two IDs have two PECAN_IDs).
- `qc\pecan_id_registry_proposed.csv` holds encrypted MRNs. It is gitignored and must never be committed; Gerard deletes it after approval.
- Open at close: rerun `17_pecan_id_test.sas` (T19) and `17c_pecan_id_summary.sas` (masked `<11` output) in fresh SAS sessions.

**Phase 18 notes:** ASA and CPT1 Class are numeric (PDD-D-31 combined types); PDD-D-30 (s22 wins, s23 gap-fills) applies in Phase 18. **Observation (16b, 2026-11-17):** all 56 NO_DATA variables are in s06; the Phase 18 dictionary should flag them.

Decisions (`docs/DECISIONS.md`): **PDD-D-33 DECIDED 2026-11-17 (K2 `PRECEDE_STUDY_ID` = normalized `Precede#####`, same as K1 and norm_psid).** **PDD-D-32 DECIDED 2026-11-17 (K1 PECAN_ID = `pecan_ID` of `g.MASTER_DATA_HARMONIZED` taken row by row through a surgery-level key, not an MRN lookup in `g.pecan_id_xwalk`; IDs unchanged; patients with two K1 IDs kept and recorded in append-only `pdd.pecan_id_dup_link`, no merge now; K2 unchanged). The old wording "K1 seeded from `g.pecan_id_xwalk`" in PDD-D-28 / PID-03 is SUPERSEDED.** PDD-D-26 DECIDED (separate K2 PECAN_IDs via append-only registry, linkage deferred). PDD-D-28 DECIDED 2026-11-16 (PECAN_ID = master-merge `pecan_ID`; K1 seed from `g.pecan_id_xwalk`; K2 = 1000000 + rank). PDD-D-29 DECIDED 2026-11-16 (D-19 rule applies to 2023-2025; no cross-era overlap; Phase 15 must check overlap between the three new files). PDD-D-30 DECIDED 2026-11-16 (142 shared s22 x s23 cases are the same surgeries: s22 wins, s23 gap-fills, applied in Phase 18). PDD-D-25 CLOSED - NOT NEEDED (per PDD-D-29 item 2). PDD-D-31 DECIDED 2026-11-16 (combined types for TYPE_CONFLICT_EXACT variables; near-matches decided in `docs/name_map_decisions_new.csv`, 18 SAME rows; rerun 16a and 16b: **PENDING SAS RUN**). PENDING DECISION, default not applied: PDD-D-27 dictionary sheet in master xlsx. Price naming sign-off still pending.

**Phase 15 progress:** 15-04 complete 2026-11-16 (QC writer `python/scripts/write_new_source_qc.py`, exchange schema rows for 8 Phase 15 CSVs; 170 pytest pass). Run it after 15a-15c SAS runs (`--allow-partial` if stopped at the gate).

### Assumptions (headless run)

- Milestone re-registered 2026-11-16 against the revised brief (52f6ad9); the first registration (73881aa) used the older brief. PDD numbers 25-28 were kept; PDD-D-26 changed to DECIDED; PDD-D-29 added for new-4.
- v1.0 treated as closed: audit PASSED 2026-10-27, all 7 phases complete, Gerard reviewed pdd_v1_0.xlsx. REQUIREMENTS.md was already archived to `milestones/v1.0-REQUIREMENTS.md` (not re-archived). The v1.0 sections below are stale (Phase 7 shows "Not started"; 07-01..07-03 are complete) and `/gsd:complete-milestone` was never run.
- Probe committed 2026-11-16 (`.planning/schemas/probe_master_data_20261116.md`, strip-fix rerun). The brief's "0 overlap for 2022 5-digit IDs" was a probe bug (padded value vs `^\d{1,5}$`) and is superseded; other brief-quoted findings should be read from the probe file, not the brief.
- `CLAUDE_md_addition.md` no longer exists: its content was merged into CLAUDE.md in 73881aa. CLAUDE.md already contains the probe-first, headless and SAS-pitfall sections, so it was not changed.

- Phase 15 (A11): new-file datasets are `pdd.nsrc_s21..s23`, not `pdd.src_s2N`, because 03_import `_norm_psid_loop` sweeps `SRC_S__`. Baseline approval (A2) is env var `PDD_APPROVE_NEW_BASELINE=1`, set only by Gerard.
- Phase 16 (A1, A2, A11): extension datasets pdd.name_map_ext / pdd.name_map_vars_ext, frozen pdd.name_map read-only; decisions in docs/name_map_decisions_new.csv; 16a writes outputs and a PENDING DECISION NOTE, Phase 18 must hard-stop on n_new_pending_decision > 0.

---

## v1.0 state (as of 2026-10-27; historical)

## Current position

Phase: 16 (name-map-extension) — EXECUTING
Plan: 1 of 5
| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 07 — Dictionary workbook writer (in progress) |
| Status | 07-02 complete — dictionary_workbook.py + 39 tests; ruff+pytest green |
| Last updated | 2026-10-27 |
| Stopped at | Completed 07-02-PLAN.md |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | ✅ Complete |
| 2 | Source guard and header inventory | ✅ Complete — live run passed 2026-10-19 14:15 |
| 3 | Direct import of the 20 sources | ✅ Complete — live run 2026-10-20 20:58 passed all criteria (0 MISMATCH, n_pairs=9001 ndis=0, exit=1 warnings only) |
| 4 | Name map | ✅ Complete — verified 2026-10-21; Price sign-off pending before Phase 7 |
| 5 | Build PCNR_ on the spine | ✅ Complete — merged to master at fbf3c35 (2026-10-26). SAS tests passed=94 failed=0; pipeline exit 0, 0 warnings; pdd.pcnr 41,150 × 1,298 PCNR_ + NORM_PSID; recon 0 mismatches; conflicts 97,194 events / 95,840 cells; conflict_class breakdown: REAL 51,835 / CODING_EQUIV 29,644 / PLACEHOLDER 13,038 / ROUNDING 1,956 / NUMERIC_CLOSE 473 / TOPCODE 248; provenance 342,605; ALL_MISSING 56. |
| 6 | Distribution engine | ✅ Complete — merged to master e912941. Tests passed=138 failed=0; check_test_log PASS; pipeline exit 0, 0 warnings. pdd.prf_pcnr: 5,642 rows / 1,297 vars (LOW_CARD 1,097 \| CONT_NUM 123 \| NUM_TEXT 38 \| HIGH_CARD 29 \| SUPPRESSED 10). D-08 recon PASS; D-09 validation PASS. |
| 7 | Dictionary workbook writer | ⬜ Not started |

## Milestone v1.x phase checklist (gated)

| Phase | Title | Gate | Status |
|-------|-------|------|--------|
| 8 | PCNC_ clinic data | PDD-D-11 | ⬜ Gated |
| 9 | CLK_ clock variables | PDD-D-13 | ⬜ Gated |
| 10 | LAB_ pre-op labs | PDD-D-14 | ⬜ Gated |
| 11 | MED_ medications | PDD-D-14 | ⬜ Gated |
| 12 | INTRA_ intra-op | PDD-D-14 | ⬜ Gated |
| 13 | PCND_ derived variables | PDD-D-12 + all inputs | ⬜ Gated |

## Phase 6 inputs required from Phase 5

Phase 6 (distribution engine) will run `%pdd_profile` on `pdd.pcnr`. It needs:

| Input | Source | Notes |
|-------|--------|-------|
| `pdd.pcnr` | Phase 5 output | 41,150 rows × 1,298 PCNR_ + NORM_PSID; must exist in the pdd library before Phase 6 runs |
| `pdd.name_map_vars` | Phase 4/5 output | Supplies `pcnr_name`, `result_type` (N8 vs C), `max_length`, `label` for each variable; Phase 6 uses this to classify variables by type |
| `docs/pcnr_source_priority.csv` | Phase 5 fixture | s_code rank order; Phase 6 may use for per-source breakdowns |
| QC outputs in exchange/ | Phase 5 output | `pcnr_gapfill.csv`, `pcnr_conflicts_summary_class.csv`; Phase 6 profile adds distribution counts alongside these |
| `pdd.qc_pcnr_provenance` | Phase 5 output | Multi-source cells; Phase 6 profile should exclude or flag these for distribution counts if needed |

Phase 6 does NOT need to re-read the 20 source files. It operates only on `pdd.pcnr` and metadata tables already in the pdd library.

## D-22 (2026-10-21)

SAS/Python split locked. SAS owns data; Python owns xlsx output. Phase 3 unchanged. Python package at `python/pdd/`; entry-point scripts at `python/scripts/`; tests at `python/tests/`. Exchange dir `<out_root>\exchange\` on P: for SAS→Python CSV handoff. Pilot: 03b writes `exchange\s06_class_nn.csv`; `python\scripts\write_s06_clock_classification.py` writes `qc\s06_clock_classification.xlsx`.

## Open decisions

| ID | Question | Blocks |
|----|----------|--------|
| PDD-D-11 | PCNC_ source location | Phase 8 |
| PDD-D-12 | PCND_ definitions | Phase 13 |
| PDD-D-13 | CLK_ source. **Note (2026-10-20):** s06 clock columns (COM*/COPY* + clock token) identified as candidate CLK_ source; pending confirmation this is the authoritative source. | Phase 9 |
| PDD-D-14 | LAB_/MED_/INTRA_ paths | Phases 10–12 |

## Pending decisions — for Price review (Phase 5 findings)

These are QC findings from the Phase 5 live run that require Price's input before Phase 7 (dictionary workbook). Not resolved; recorded here for the review meeting.

| Item | Finding | Question |
|------|---------|----------|
| ICD10 placeholders | Spine (s09) contains '?' and 'YES' in ICD10 code columns; these beat real codes from other sources by rank order | Include as-is in PCNR_? Or treat as missing (D-13/PCND_)? |
| MAC/ISO/SEV definitions | s09 and s19 use different definitions for MAC, ISO, SEV anesthesia columns | Which source is authoritative? Resolve in PCNR_ or flag for PCND_? |
| Frailty source | s06 and s19 both contribute frailty variables; s06 beats s19 by rank | Confirm s06 is the intended frailty source |
| Age 90+ display | Safe Harbor requires age ≥ 90 to be displayed as 90 | Apply TOPCODE in PCNR_ now, or in PCND_? |
| Death_Date_Y_N | 187 patients have disagreement between sources for Death_Date_Y_N | Investigate and confirm correct value; update pcnr_source_priority.csv if needed |
| ALL_MISSING 56 vars | 56 PCNR_ variables are entirely missing across all 41,150 rows; all are s06 fields | Are these REDCap section/descriptive fields that should be dropped from PCNR_? Or include as empty columns for completeness? |
| Naming sign-off | PCNR_ naming rules A1–A4 approved by Gerard 2026-10-21 | Price sign-off required before Phase 7 release |
| D-02b confirmation | NULL (any case) treated as missing for type-conflict variables | Confirm this is the correct handling |
| D-24 confirmation | ENCRYPTED_MRN and ENCRYPTED_ENCOUNTER have status=LINKAGE_ONLY; excluded from PCNR_ (1297 PCNR_ vars not 1299) | Confirm LINKAGE_ONLY is correct; these appear in name_map but not pdd.pcnr |

## Decided (closed)

| ID | Decided | Resolution |
|----|---------|------------|
| PDD-D-09 | 2026-10-26 | Value suppression: suppress_file= param to %pdd_profile; lists variable,reason pairs; engine hard-fails if var absent from dataset; var_class=SUPPRESSED; emits N_DISTINCT, RANGE_MIN, RANGE_MAX, N, MISSING (no LEVEL rows); RANGE uses numeric min/max if ≥95% parse else char lengths with display_format='LENGTH'; seed file docs/profile_suppress.csv with 10 PCNR vars |
| PDD-D-10 | 2026-10-26 | Numeric text detection: num_text_threshold=0.95 param; HIGH_CARD char vars where n_parse/(n_nonmiss-n_placeholder) >= threshold → var_class=NUM_TEXT; emits N, N_MISSING, N_UNPARSED, MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX, up to 5 LEVEL rows for unparsed values; reconciliation N+N_MISSING+N_UNPARSED=total |
| PDD-D-15 | 2026-10-21 | Gap-fill tie-break: rank order from docs/pcnr_source_priority.csv; spine wins unconditionally |
| PDD-D-16 | 2026-10-21 | QC-only provenance (pdd.qc_pcnr_provenance); no per-cell _SRC columns in pdd.pcnr |
| PDD-D-17 | 2026-10-19 | FULLY CLOSED. All 20 files 1:1 per PRECEDE_STUDY_ID. s01 (41,423 distinct) and s08 (3,456 distinct) NOT multi-row. 274 s01 IDs not in spine are QC item. s18 has 2 dup/blank key rows (qc_s18_dup). |
| PDD-D-18 | 2026-10-19 | s04/s05 confirmed as linkage/QC files — not dictionary variables; contribute 0 PCNR_ columns (asserted). |
| PDD-D-19 | 2026-10-19 | LOCKED. `cats('Precede', put(input(strip(id),??8.),z5.))` — 9,001 pairs, ndis=0. `%pdd_norm_psid` in `00_config.sas`. |
| PDD-D-20 | 2026-10-19 | LOCKED. 6 s17 ENCRYPTED_ENCOUNTER values mapping to >1 PRECEDE_STUDY_ID set to missing for linkage; unchanged in PCNR_. |
| PDD-D-21 | 2026-10-20 | LOCKED. Excluded from PCNR_: 2,747 digital clock columns. Kept: 809 DIGITAL_OTHER + 431 PCNR columns. UNSURE=0. Split via docs/s06_column_class.csv. |

## Decisions (Phase 03)

| Date | Decision |
|------|----------|
| 2026-10-19 | 03a_build_spec.sas is separate from 03_import.sas: spec generation is one-time; import is repeatable (per research recommendation) |
| 2026-10-19 | import_spec_generated.csv committed to git (no PHI -- metadata only); overrides via import_spec_overrides.csv (not committed) |
| 2026-10-19 | .gitignore updated with !docs/import_spec_generated.csv exception (blocked by *.csv blanket rule) |
| 2026-10-20 | D-19 assert re-derives ambiguous s17 encounter set from pdd.src_s17 post-norm_psid (Section 13 self-contained; work._s17_ambig cleaned up in Section 6) |
| 2026-10-20 | pdd.qc_import_rowcounts built via SET-union accumulator %do loop (PCM-compliant; no CALL EXECUTE) |

## Notes

- D-15, D-16, D-17, D-18, D-19, D-20, D-21 all closed. See Decided table above.
- Repo lives at `C:\data_dictionary`; data/output at `P:\PeCAN Master Data\Gerard\data_dictionary\`.
- Source files are strictly read-only at `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`.
- Older copies exist at `P:\PeCAN Master Data\Gerard\raw\master` for hash comparison only.
- Phase 2 finding: 148 distinct CSV headers (not 168); spine 41,150 rows confirmed.
- `_bridge_analysis_2022` fix committed (a99c259): `work.src_s08_s1` resolved via sheet_map in `_diag_unmatched_ids`; hardcoded override retained in `_bridge_analysis_2022`.

### Phase 15 progress (15-01, 2026-11-16)

- 15-01 complete: `sas/15a_new_source_guard.sas` lint-clean, docs seeds committed. **PENDING SAS RUN** (15a, Gerard) and **PENDING DECISION** (approve new baseline via `PDD_APPROVE_NEW_BASELINE=1`). `gsd-tools state advance-plan` could not parse the v2.0 STATE format, so position was not auto-advanced.

### Phase 15 progress (15-02, 2026-11-16)

- 15-02 complete: `sas/15b_new_inventory_spec.sas` lint-clean (0 errors), 182 pytest pass. **PENDING SAS RUN** (15b, Gerard, after 15a approval); `docs/import_spec_new_generated.csv` is produced by that run and committed by Gerard. NEW-02, NEW-03 spec half written. State commands not used (v2.0 frontmatter kept).

### Phase 15 progress (15-05, 2026-11-16)

- 15-05 tasks 1-2 complete: Phase 15 wired into `99_run_all.sas` (token 15) and `run_pipeline.cmd`; run sheet `15-SAS-RUN.md` written. Checkpoint (Task 3) is **PENDING SAS RUN** (Gerard) and **PENDING DECISION** (new baseline approval; any gate that fires). Phase 15 is not closed.

### Phase 15 progress (15-03, 2026-11-16)

- 15-03 complete: `sas/15c_new_import.sas` lint-clean (0 errors), 192 pytest pass. **PENDING SAS RUN** (15c, Gerard, after 15b spec is committed). Gates (NEW-04 1:1, PDD-D-29 item 3 pairwise, old-source overlap) write QC first and stop at **PENDING DECISION** if triggered; no choice applied. Datasets named `pdd.nsrc_s21..s23` (A11). State commands not used (v2.0 frontmatter kept).

### Phase 15 closed (2026-11-16)

- Masked summary: GUARD MATCH x3; ROWCOUNTS MATCH x3 (10772/13029/12689); ONE_TO_ONE PASS x3; PAIRWISE_NEW 0/0/142 DECIDED (PDD-D-30); SPINE 0 x3; OLD20_UNION 0 x3; TYPE_CHANGES 138; NONASCII cells 0/18/26; GATE PDD-D-29 item 3 PASS; GATE OLD20_UNION PASS; GATE 1:1 PASS.
- Full detail in `phases/15-new-source-intake/15-05-SUMMARY.md`.

### Phase 16 progress (16-02, 2026-11-16)

- 16-02 complete: `sas/16_name_map_ext_macros.sas` and `sas/16_name_map_ext_test.sas` lint-clean (0 errors), 226 pytest pass. **PENDING SAS RUN** (`16_name_map_ext_test.sas`, Gerard, synthetic data only). State advance commands not used (v2.0 frontmatter kept).

### Phase 16 progress (16-04, 2026-11-16)

- 16-04 complete: `sas/16b_name_map_values_cov.sas` lint-clean (0 errors; sasjs lint 0 errors), `python/tests/test_phase16b_static.py` (11 tests pass). Value distributions per candidate pair (MAP-02 evidence) and year coverage per variable and source with NO_YEAR bucket (MAP-04). **PENDING SAS RUN** (16b, Gerard, after 16a; Phase 15 prerequisites done). State advance commands not used (v2.0 frontmatter kept).

### Phase 16 progress (16-03, 2026-11-16)

- 16-03 complete: `sas/16a_name_map_ext.sas` lint-clean (sas_lint and sasjs lint 0 errors), `python/tests/test_phase16a_static.py` (13 tests; full suite 260 pass). Frozen map read-only and asserted; exact reuse by lookup; candidate union; decisions file applied; undecided stay PENDING_DECISION with blank names. **PENDING SAS RUN** (16a, Gerard) and **PENDING DECISION** (near-match candidates in `docs/name_map_decisions_new.csv`). Price sign-off **PENDING**. State advance commands not used (v2.0 frontmatter kept).

### Phase 16 closed (2026-11-17)

- Gerard ran `.
un_pipeline.cmd 16`: PIPELINE PASSED, 0 WARNING lines, review workbook written. Test T1-T9 passed. Details in `16-05-SUMMARY.md`. Lint rules C31 and C32 added (0 hits on sas/); CLAUDE.md pitfalls updated.

### Phase 16 progress (16-05, 2026-11-16)

- 16-05 tasks 1-2 complete: Phase 16 wired into `99_run_all.sas` (token 16) and `run_pipeline.cmd`; run sheet `16-SAS-RUN.md` written; 265 pytest pass. Task 3 checkpoint is **PENDING SAS RUN** (Gerard) and **PENDING DECISION** (near-match candidates; TYPE_CONFLICT_EXACT confirm). Price sign-off **PENDING**. Phase 16 not closed. State advance commands not used (v2.0 frontmatter kept).

### Phase 16 progress (16-01, 2026-11-16)

- 16-01 complete: exchange contract for the 8 Phase 16 CSVs in `docs/exchange_schema.csv` (68 rows), header-only `docs/name_map_decisions_new.csv`, offline expectation test (100 keys, 90 exact, 10 non-matching all listed in variants file), `python/pdd/name_map_ext_workbook.py` and `python/scripts/write_name_map_ext_review.py` (ruff clean, 16-01 tests pass). MAP-01..04 not yet satisfied (need 16a/16b SAS runs). Near-match naming **PENDING DECISION**; Price sign-off **PENDING**. State advance commands not used (v2.0 frontmatter kept).

## Cleanup backlog

1. 15c PASS message prints `65370.65511`: needs a double dot after the macro variable (`&var..`) so the range shows `65370-65511` style text correctly.
2. Cache the 20 old sources' `norm_psid` set once, so 15c does not re-read every old dataset from P: on each run (s06 alone takes about 45 s).
3. Narrow lint rule C30 to plain `%put` text, so the masked semicolons in `00_config.sas`, `02_source_guard.sas` and `05_build_pcnr_macros.sas` stop being flagged.
4. DONE 2026-11-17: 16b zero-element array warnings removed (generated coverage step declares placeholders `_p16_dn 8` and `_p16_dc $1` before the `_numeric_`/`_character_` arrays).
5. 16b re-reads s06 (3,987 columns) for every value pair, about 45 s each: use the same cache fix as backlog item 2 (read each source once per run).
6. `06_profile_macros.sas` ~L2185-2230: `pct_total` not reset on NUM_TEXT MEAN..MAX rows. Deferred (fixing re-runs Phase 6 and changes v1.0 `pdd.prf_pcnr`). First check, read-only: does the published `pdd_v1_0.xlsx` show pct on those rows? If yes, raise priority - masked counts are back-calculable in a delivered workbook.
7. RESOLVED 2026-11-18: the "unexplained blank-n rows" item. They are the NUM_TEXT MEAN..MAX stat rows (n blank by design).


**Phase 17 planned (2026-11-17, headless):** plans 17-01 (config g read-only, macros, synthetic test), 17-02 (xwalk probe + K1 seed), 17-03 (PDD-D-30 dedupe + K2 assign + case map + gates), 17-04 (pecan_id_link.sas written/tested/not run), 17-05 (summary, wiring, SAS-RUN). Approval option PDD_APPROVE_NEW_BASELINE (default 0). Open facts: xwalk never probed (MRN length $40 in D-28 vs spine 41); spine MRN levels 31,137 (probe) vs 31,136 (D-28), gate compares at run time. Assumptions in 17-CONTEXT.md. Research/checker subagents skipped for budget.

**Phase 17 revised for PDD-D-32 (2026-11-17, headless):** 17-CONTEXT, 17-01, 17-02, 17-03, 17-05, 17-VALIDATION, 17-SAS-RUN updated (K1 = spine to `g.MASTER_DATA_HARMONIZED` row-by-row join, gate 41,150 matched 1:1 / 0 missing pecan_ID / 0 multi-match; dup-pair link table; blank spine MRN count on its own line). New `sas/17_probe_xwalk3.sas` (PR-3, lint clean, PENDING SAS RUN): `probe_xwalk3_<date>.md` names the key, then MRN-to-pecan_ID histogram, dup pairs, pairs by YEAR, YEAR of unmatched MRNs. PENDING SAS RUN: PR-3. PENDING DECISION (only if PR-3 shows it): registry K1 row for a pecan_ID that has more than one spine MRN, or only on the blank-MRN row.
