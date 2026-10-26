---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Phase 5 complete — merged to master at b5d37b5 (2026-10-26); QC workbook polish on fix/04-decisions
last_updated: "2026-10-26T00:00:00Z"
progress:
  total_phases: 7
  completed_phases: 5
  total_plans: 17
  completed_plans: 17
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current position

Phase: 05 (build-pcnr-on-the-spine) — IN PROGRESS
Plan: 5 of 6 (05-06 unchecked — tests/05_build_test.sas run)
Next: Live run of Phase 5 (run_pipeline.cmd); tests/05_build_test.sas SUMMARY failed=0 required first
| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 05 — Build PCNR_ on the spine |
| Status | Code review fixes applied 2026-10-21 (commit 6649f69); not yet run against P: data |
| Last updated | 2026-10-25 |
| Stopped at | Code review fixes committed; tests/05_build_test.sas extended to TC-24 |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | ✅ Complete |
| 2 | Source guard and header inventory | ✅ Complete — live run passed 2026-10-19 14:15 |
| 3 | Direct import of the 20 sources | ✅ Complete — live run 2026-10-20 20:58 passed all criteria (0 MISMATCH, n_pairs=9001 ndis=0, exit=1 warnings only) |
| 4 | Name map | ✅ Complete — verified 2026-10-21; Price sign-off pending before Phase 7 |
| 5 | Build PCNR_ on the spine | ✅ Complete — merged to master at b5d37b5 (2026-10-26); QC workbook polish in progress on fix/04-decisions. |
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

## D-22 (2026-10-21)

SAS/Python split locked. SAS owns data; Python owns xlsx output. Phase 3 unchanged. Python package at `python/pdd/`; entry-point scripts at `python/scripts/`; tests at `python/tests/`. Exchange dir `<out_root>\exchange\` on P: for SAS→Python CSV handoff. Pilot: 03b writes `exchange\s06_class_nn.csv`; `python\scripts\write_s06_clock_classification.py` writes `qc\s06_clock_classification.xlsx`.

## Open decisions

| ID | Question | Blocks |
|----|----------|--------|
| PDD-D-11 | PCNC_ source location | Phase 8 |
| PDD-D-12 | PCND_ definitions | Phase 13 |
| PDD-D-13 | CLK_ source. **Note (2026-10-20):** s06 clock columns (COM*/COPY* + clock token) identified as candidate CLK_ source; pending confirmation this is the authoritative source. | Phase 9 |
| PDD-D-14 | LAB_/MED_/INTRA_ paths | Phases 10–12 |

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
