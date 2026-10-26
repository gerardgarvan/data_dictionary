---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Phase 5 fully complete — merged to master at fbf3c35 (2026-10-26); Phase 6 next
last_updated: "2026-10-26T00:00:00Z"
progress:
  total_phases: 7
  completed_phases: 5
  total_plans: 17
  completed_plans: 17
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current position

| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 06 — Distribution engine (next to start) |
| Status | Phase 5 complete; Phase 6 not started |
| Last updated | 2026-10-26 |
| Stopped at | Phase 5 merged to master fbf3c35; wrap-up commit pending push |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | ✅ Complete |
| 2 | Source guard and header inventory | ✅ Complete — live run passed 2026-10-19 14:15 |
| 3 | Direct import of the 20 sources | ✅ Complete — live run 2026-10-20 20:58 passed all criteria (0 MISMATCH, n_pairs=9001 ndis=0, exit=1 warnings only) |
| 4 | Name map | ✅ Complete — verified 2026-10-21; Price sign-off pending before Phase 7 |
| 5 | Build PCNR_ on the spine | ✅ Complete — merged to master at fbf3c35 (2026-10-26). SAS tests passed=94 failed=0; pipeline exit 0, 0 warnings; pdd.pcnr 41,150 × 1,298 PCNR_ + NORM_PSID; recon 0 mismatches; conflicts 97,194 events / 95,840 cells; conflict_class breakdown: REAL 51,835 / CODING_EQUIV 29,644 / PLACEHOLDER 13,038 / ROUNDING 1,956 / NUMERIC_CLOSE 473 / TOPCODE 248; provenance 342,605; ALL_MISSING 56. |
| 6 | Distribution engine | ⬜ Not started |
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
