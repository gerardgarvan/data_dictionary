---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Ready to execute
last_updated: "2026-10-19T14:39:30.457Z"
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 5
  completed_plans: 4
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current position

Phase: 02 (source-guard-and-header-inventory) — EXECUTING
Plan: 3 of 3
| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 02 — Source guard and header inventory |
| Status | Executing — Plan 02 complete, Plan 03 next |
| Last updated | 2026-10-19 |
| Stopped at | Completed 02-02-PLAN.md |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | ✅ Complete |
| 2 | Source guard and header inventory | 🔄 Executing (Plan 2 of 3 complete) |
| 3 | Direct import of the 20 sources | ⬜ Not started |
| 4 | Name map | ⬜ Not started |
| 5 | Build PCNR_ on the spine | ⬜ Blocked (PDD-D-15, PDD-D-16, PDD-D-17, PDD-D-18) |
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
| PDD-D-17 | Multi-row-per-patient files (PACU_STAY, COLONOSCOPY) — integration method | Phase 3 (s01, s08), Phase 5 (s01, s08) — decided after Phase 2 |
| PDD-D-18 | MRN/encounter-keyed files (ENCOUNTER/MRN Crypto) — linkage path | Phase 3 (s04, s05), Phase 5 (s04, s05) — decided after Phase 2 |

## Notes

- PDD-D-15 and PDD-D-16 block Phase 5 only; Phases 1–4 and 6–7 can proceed.
- PDD-D-17 and PDD-D-18 block Phases 3 and 5 for the affected files only; Phase 2 produces the data needed to decide them.
- Repo lives at `C:\data_dictionary`; data/output at `P:\PeCAN Master Data\Gerard\data_dictionary\`.
- Source files are strictly read-only at `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`.
- Older copies exist at `P:\PeCAN Master Data\Gerard\raw\master` for hash comparison only.
