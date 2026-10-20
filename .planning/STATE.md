---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Ready to execute
last_updated: "2026-10-20T00:48:09.976Z"
progress:
  total_phases: 7
  completed_phases: 2
  total_plans: 8
  completed_plans: 6
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current position

Phase: 03 (direct-import-of-the-20-sources) — EXECUTING
Plan: 2 of 3
Next: Phase 03 Plan 02 — 03_import.sas runtime import
| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 03 — Direct import of the 20 sources |
| Status | Plan 01 complete — 03a_build_spec.sas written; docs/import_spec_generated.csv committed (header only; SAS run required to populate) |
| Last updated | 2026-10-19 |
| Stopped at | Completed 03-01-PLAN.md |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | âœ… Complete |
| 2 | Source guard and header inventory | âœ… Complete â€” live run passed 2026-10-19 14:15 |
| 3 | Direct import of the 20 sources | In progress — Plan 01 complete (03a_build_spec.sas); Plans 02-03 pending |
| 4 | Name map | â¬œ Not started |
| 5 | Build PCNR_ on the spine | â¬œ Blocked (PDD-D-15, PDD-D-16, PDD-D-17 closed, PDD-D-18 pending) |
| 6 | Distribution engine | â¬œ Not started |
| 7 | Dictionary workbook writer | â¬œ Not started |

## Milestone v1.x phase checklist (gated)

| Phase | Title | Gate | Status |
|-------|-------|------|--------|
| 8 | PCNC_ clinic data | PDD-D-11 | â¬œ Gated |
| 9 | CLK_ clock variables | PDD-D-13 | â¬œ Gated |
| 10 | LAB_ pre-op labs | PDD-D-14 | â¬œ Gated |
| 11 | MED_ medications | PDD-D-14 | â¬œ Gated |
| 12 | INTRA_ intra-op | PDD-D-14 | â¬œ Gated |
| 13 | PCND_ derived variables | PDD-D-12 + all inputs | â¬œ Gated |

## Open decisions

| ID | Question | Blocks |
|----|----------|--------|
| PDD-D-11 | PCNC_ source location | Phase 8 |
| PDD-D-12 | PCND_ definitions | Phase 13 |
| PDD-D-13 | CLK_ source | Phase 9 |
| PDD-D-14 | LAB_/MED_/INTRA_ paths | Phases 10â€“12 |
| PDD-D-15 | Gap-fill tie-break order | Phase 5 |
| PDD-D-16 | Per-cell source flag | Phase 5 |
| PDD-D-17 | **FULLY CLOSED (discuss-3).** All 20 files are 1:1 per PRECEDE_STUDY_ID. s01 (41,423 distinct) and s08 (3,456 distinct) are NOT multi-row -- Phase 2 counts confirm 1:1 grain. 274 s01 IDs not in spine are a QC item. s18 has 2 dup/blank key rows (qc_s18_dup) for Phase 3 review | Phase 3 (s01, s08), Phase 5 (s01, s08) |
| PDD-D-18 | s04/s05 appear to be linkage/QC files (same encryption, 100% match) â€” not dictionary variables. Pending Gerard confirmation | Phase 3 (s04, s05), Phase 5 (s04, s05) |
| PDD-D-19 | **LOCKED (2026-10-19).** `cats('Precede', put(input(strip(id),??8.),z5.))` â€” 9,001 pairs, ndis=0 (run 19:21). `%pdd_norm_psid` in `00_config.sas`. Phase 3 QC: s01 274 not in spine (1 spine case no PACU row); s18 269 not in spine, 2 dup/blank rows (`pdd.qc_s18_dup`); s06 29 and s11 1 not in spine; s04/s05 4 not in spine | â€” |
| PDD-D-20 | **LOCKED.** 6 s17 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID â†’ set to missing for linkage; unchanged in PCNR_ | Phase 3 (s17) |
| PDD-D-21 | s06 has 3,987 columns â€” Phase 3 profiles column groups first; Gerard decides scope | Phase 3 (s06) |

## Decisions (Phase 03)

| Date | Decision |
|------|----------|
| 2026-10-19 | 03a_build_spec.sas is separate from 03_import.sas: spec generation is one-time; import is repeatable (per research recommendation) |
| 2026-10-19 | import_spec_generated.csv committed to git (no PHI -- metadata only); overrides via import_spec_overrides.csv (not committed) |
| 2026-10-19 | .gitignore updated with !docs/import_spec_generated.csv exception (blocked by *.csv blanket rule) |

## Notes

- PDD-D-15 and PDD-D-16 block Phase 5 only; Phases 1â€“4 and 6â€“7 can proceed.
- PDD-D-17 FULLY CLOSED: all 20 files are 1:1 per PRECEDE_STUDY_ID; s01/s08 are NOT multi-row (Phase 2 + discuss-3 confirmed).
- PDD-D-18 pending Gerard confirmation; PDD-D-19 LOCKED (2026-10-19).
- Repo lives at `C:\data_dictionary`; data/output at `P:\PeCAN Master Data\Gerard\data_dictionary\`.
- Source files are strictly read-only at `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`.
- Older copies exist at `P:\PeCAN Master Data\Gerard\raw\master` for hash comparison only.
- Phase 2 finding: 148 distinct CSV headers (not 168); spine 41,150 rows confirmed.
- `_bridge_analysis_2022` fix committed (a99c259): `work.src_s08_s1` resolved via sheet_map in `_diag_unmatched_ids`; hardcoded override retained in `_bridge_analysis_2022`.
