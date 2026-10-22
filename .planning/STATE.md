---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: PCNR_ raw layer and dictionary framework
status: Phase 5 statically verified — live run pending
last_updated: "2026-10-21T00:00:00Z"
progress:
  total_phases: 7
  completed_phases: 5
  total_plans: 17
  completed_plans: 17
---

# GSD State: PeCAN Data Dictionary (PDD)

## Current position

Phase: 05 (build-pcnr-on-the-spine) — STATICALLY VERIFIED
Plan: 5 of 5 (all complete)
Next: Phase 06 — Distribution engine OR live run of Phase 5 to close human-verification items
| Field | Value |
|-------|-------|
| Milestone | v1.0 — PCNR_ raw layer and dictionary framework |
| Phase | 05 — Build PCNR_ on the spine |
| Status | Static verification passed (10/10); live run and QC workbook review pending |
| Last updated | 2026-10-21 |
| Stopped at | 05-VERIFICATION.md written |

## Milestone v1.0 phase checklist

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Repo and config scaffold | ✅ Complete |
| 2 | Source guard and header inventory | ✅ Complete — live run passed 2026-10-19 14:15 |
| 3 | Direct import of the 20 sources | ✅ Complete — live run 2026-10-20 20:58 passed all criteria (0 MISMATCH, n_pairs=9001 ndis=0, exit=1 warnings only) |
| 4 | Name map | ✅ Complete — verified 2026-10-21; Price sign-off pending before Phase 7 |
| 5 | Build PCNR_ on the spine | ✅ Statically verified 2026-10-21 (10/10). Live run (pdd.pcnr) and QC workbook human review outstanding. |
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
| PDD-D-15 | Gap-fill tie-break order | Phase 5 |
| PDD-D-16 | Per-cell source flag | Phase 5 |
| PDD-D-17 | **FULLY CLOSED (discuss-3).** All 20 files are 1:1 per PRECEDE_STUDY_ID. s01 (41,423 distinct) and s08 (3,456 distinct) are NOT multi-row -- Phase 2 counts confirm 1:1 grain. 274 s01 IDs not in spine are a QC item. s18 has 2 dup/blank key rows (qc_s18_dup) for Phase 3 review | Phase 3 (s01, s08), Phase 5 (s01, s08) |
| PDD-D-18 | s04/s05 appear to be linkage/QC files (same encryption, 100% match) — not dictionary variables. Pending Gerard confirmation | Phase 3 (s04, s05), Phase 5 (s04, s05) |
| PDD-D-19 | **LOCKED (2026-10-19).** `cats('Precede', put(input(strip(id),??8.),z5.))` — 9,001 pairs, ndis=0 (run 19:21). `%pdd_norm_psid` in `00_config.sas`. Phase 3 QC: s01 274 not in spine (1 spine case no PACU row); s18 269 not in spine, 2 dup/blank rows (`pdd.qc_s18_dup`); s06 29 and s11 1 not in spine; s04/s05 4 not in spine | — |
| PDD-D-20 | **LOCKED.** 6 s17 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID → set to missing for linkage; unchanged in PCNR_ | Phase 3 (s17) |
| PDD-D-21 | **LOCKED (2026-10-20, reviewed Gerard 2026-10-20).** Excluded from PCNR_: 2,747 digital clock columns (COM/COPY clock tokens + LINUS DCTclock summary). Kept in PCNR_: 809 other digital-battery tests (DIGITAL_OTHER) + 431 other columns (PCNR), including clock admin flags and Mini-Cog clock scores. UNSURE=0; Phase 4 gate clear. Split applied Phase 4 onward via docs/s06_column_class.csv. | Phase 4 gate |

## Decisions (Phase 03)

| Date | Decision |
|------|----------|
| 2026-10-19 | 03a_build_spec.sas is separate from 03_import.sas: spec generation is one-time; import is repeatable (per research recommendation) |
| 2026-10-19 | import_spec_generated.csv committed to git (no PHI -- metadata only); overrides via import_spec_overrides.csv (not committed) |
| 2026-10-19 | .gitignore updated with !docs/import_spec_generated.csv exception (blocked by *.csv blanket rule) |
| 2026-10-20 | D-19 assert re-derives ambiguous s17 encounter set from pdd.src_s17 post-norm_psid (Section 13 self-contained; work._s17_ambig cleaned up in Section 6) |
| 2026-10-20 | pdd.qc_import_rowcounts built via SET-union accumulator %do loop (PCM-compliant; no CALL EXECUTE) |

## Notes

- PDD-D-15 and PDD-D-16 block Phase 5 only; Phases 1–4 and 6–7 can proceed.
- PDD-D-17 FULLY CLOSED: all 20 files are 1:1 per PRECEDE_STUDY_ID; s01/s08 are NOT multi-row (Phase 2 + discuss-3 confirmed).
- PDD-D-18 pending Gerard confirmation; PDD-D-19 LOCKED (2026-10-19).
- Repo lives at `C:\data_dictionary`; data/output at `P:\PeCAN Master Data\Gerard\data_dictionary\`.
- Source files are strictly read-only at `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`.
- Older copies exist at `P:\PeCAN Master Data\Gerard\raw\master` for hash comparison only.
- Phase 2 finding: 148 distinct CSV headers (not 168); spine 41,150 rows confirmed.
- `_bridge_analysis_2022` fix committed (a99c259): `work.src_s08_s1` resolved via sheet_map in `_diag_unmatched_ids`; hardcoded override retained in `_bridge_analysis_2022`.
