---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Phase 2 complete — Phase 3 planning next
last_updated: "2026-10-19T00:00:00Z"
progress:
  total_phases: 7
  completed_phases: 2
  total_plans: 5
  completed_plans: 5
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current position

Phase: 02 (source-guard-and-header-inventory) — COMPLETE
Next: Phase 03 — Direct import of the 20 sources
| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 02 — Source guard and header inventory |
| Status | Phase 2 complete — live run 2026-10-19 14:15 passed (exit=1, warnings only, no ERRORs) |
| Last updated | 2026-10-19 |
| Stopped at | Phase 3 planning |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | ✅ Complete |
| 2 | Source guard and header inventory | ✅ Complete — live run passed 2026-10-19 14:15 |
| 3 | Direct import of the 20 sources | ⬜ Not started |
| 4 | Name map | ⬜ Not started |
| 5 | Build PCNR_ on the spine | ⬜ Blocked (PDD-D-15, PDD-D-16, PDD-D-17 closed, PDD-D-18 pending) |
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

## Open decisions

| ID | Question | Blocks |
|----|----------|--------|
| PDD-D-11 | PCNC_ source location | Phase 8 |
| PDD-D-12 | PCND_ definitions | Phase 13 |
| PDD-D-13 | CLK_ source | Phase 9 |
| PDD-D-14 | LAB_/MED_/INTRA_ paths | Phases 10–12 |
| PDD-D-15 | Gap-fill tie-break order | Phase 5 |
| PDD-D-16 | Per-cell source flag | Phase 5 |
| PDD-D-17 | **CLOSED.** Grain confirmed: every file is 1 row per case except s01 and s08. Integration method for s01/s08 still to be decided (Gerard, Phase 3). s18 has 2 dup/blank key rows (qc_s18_dup) for Phase 3 review | Phase 3 (s01, s08), Phase 5 (s01, s08) |
| PDD-D-18 | s04/s05 appear to be linkage/QC files (same encryption, 100% match) — not dictionary variables. Pending Gerard confirmation | Phase 3 (s04, s05), Phase 5 (s04, s05) |
| PDD-D-19 | 2022 ID normalisation — pending verification QC step in 02_source_guard.sas | Phase 3 import |
| PDD-D-20 | **LOCKED.** 6 s17 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID → set to missing for linkage; unchanged in PCNR_ | Phase 3 (s17) |
| PDD-D-21 | s06 has 3,987 columns — Phase 3 profiles column groups first; Gerard decides scope | Phase 3 (s06) |

## Notes

- PDD-D-15 and PDD-D-16 block Phase 5 only; Phases 1–4 and 6–7 can proceed.
- PDD-D-17 grain question closed; s01/s08 integration method still open (Gerard, Phase 3).
- PDD-D-18 pending Gerard confirmation; PDD-D-19 pending one more verification run.
- Repo lives at `C:\data_dictionary`; data/output at `P:\PeCAN Master Data\Gerard\data_dictionary\`.
- Source files are strictly read-only at `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`.
- Older copies exist at `P:\PeCAN Master Data\Gerard\raw\master` for hash comparison only.
- Phase 2 finding: 148 distinct CSV headers (not 168); spine 41,150 rows confirmed.
- `_bridge_analysis_2022` macro fix needed before next run: `work.src_s08` → `work.src_s08_s1`.
