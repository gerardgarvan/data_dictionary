# Phase 4: Name map — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-21
**Phase:** 04-name-map
**Areas discussed:** NAME_MAP grain, CLK_ candidate list, Collision behavior, s06 PCNR_ name shortening

---

## NAME_MAP grain

| Option | Description | Selected |
|--------|-------------|----------|
| One row per PCNR_ variable | Deduplicated; clean inventory; if same header in many files, one row | |
| One row per source × header pair | Full provenance; shows overlap; PRECEDE_STUDY_ID gets 18+ rows | ✓ |
| Both | Separate SAS datasets for each grain | |

**User's choice:** One row per source × header (primary table), with a VARIABLES derived view (one row per PCNR_ variable listing source files).

**Notes:** The source × header grain is needed to see how overlap works and to support gap-fill (D-05). The VARIABLES view derives from it and feeds the workbook NAME_MAP sheet and Phase 5. Dedup rule: matching cleaned original names (case/spaces/punctuation normalised). Near-matches (same name ± suffix or slight variation) go to a QC sheet rather than being auto-merged. `docs/name_map_decisions.csv` is the decision file (SAME | DIFFERENT | RENAME; no data values; committed to git). SAME pairs map to one PCNR_ variable; DIFFERENT stay separate; undecided pairs appear on NEAR_MATCHES sheet. Phase 4 not complete while undecided count > 0.

Follow-up — NEAR_MATCHES output location:

| Option | Description | Selected |
|--------|-------------|----------|
| pdd.name_map_nearmatches + sheet in name_map_review.xlsx | SAS dataset; Python adds sheet to single workbook | ✓ |
| qc\\name_map_nearmatches.xlsx only | Separate workbook | |

**Notes:** Single workbook `qc\name_map_review.xlsx` with sheets: KEY | NAME_MAP | VARIABLES | NAME_MAP_COLLISIONS | NEAR_MATCHES | ABBREVIATIONS.

---

## CLK_ candidate list

| Option | Description | Selected |
|--------|-------------|----------|
| pdd.clk_candidates + CLOCK sheet in name_map_review.xlsx | Stage CLK_ data alongside PCNR_ work | |
| pdd.clk_candidates only (no xlsx yet) | Defer xlsx to Phase 9 | |
| Separate qc\\clk_candidates.xlsx | Isolated workbook | |
| CLOCK rows in NAME_MAP with status=EXCLUDED_CLK | docs/s06_column_class.csv is already the record | ✓ |

**User's choice:** No separate CLK_ dataset. CLOCK-class columns stay in `pdd.name_map` with `status=EXCLUDED_CLK` and no PCNR_ name. `docs/s06_column_class.csv` already records the classification. Phase 9 handles CLK_ when D-13 is settled.

---

## Collision behavior

| Option | Description | Selected |
|--------|-------------|----------|
| ERROR + abort | Stops on any collision; Gerard must resolve before continuing | |
| WARNING + QC continue | Risk of duplicate PCNR_ names reaching Phase 5 | |
| Two-stage: auto-suffix then hard stop | Stage 1 auto-resolves with suffixes and logs; Stage 2 hard stop if any final name is still invalid | ✓ |

**User's choice:** Two-stage. Stage 1: auto-suffix _2, _3 … in s01→s20 then column order; all pairs listed in NAME_MAP_COLLISIONS; run continues. Override via name_map_decisions.csv (RENAME) or name_abbrev.csv. Stage 2: %fail_out if any final PCNR_ name is duplicate, >32 chars, or invalid SAS name.

---

## s06 PCNR_ name shortening

| Option | Description | Selected |
|--------|-------------|----------|
| Blind left-to-right cut + name_abbrev.csv override | Default cut; abbreviations added retroactively | |
| Pre-defined abbreviation table first, then cut | More upfront work; cleaner names from start | partial |
| Reuse import_spec_generated.csv sas_name directly | Skip re-derivation; risk of wrong truncation point | |
| Fixed order: abbreviation table → elide middle | Preserves distinguishing suffix; COM/COPY never dropped | ✓ |

**User's choice:** Fixed order: (a) apply `docs/name_abbrev.csv` abbreviation table; (b) if still >27 chars, keep start + end and cut middle; (c) never drop COM/COPY prefix (COM and COPY versions of same test must be distinguishable). Full original name always in LABEL and NAME_MAP (D-07). Naming conventions require Price approval — output is a proposal for review.

**Standard abbreviation seeds for docs/name_abbrev.csv:**
Delayed→Dly, Recall→Rcl, Recognition→Recog, Number→N, Norm_ZScore→Z, AgeScaled→AgeSc, Percent→Pct.

---

## Additional decisions (captured inline)

**D-02 — Name cleaning rule:**
Trim → replace non-letter/digit/underscore runs with `_` → strip leading/trailing `_` → digit-start prefix `N_` → keep case → abbreviate if needed → prefix PCNR_. Document rule in KEY sheet.

**D-04 — Status taxonomy:**
PCNR | KEY | EXCLUDED_CLK | DERIVED | LINKAGE_ONLY | DUPLICATE_DROPPED

**D-07 — Type conflict:**
Record sas_type and length per (file × header). Type conflict across sources → result=character (Phase 5); VARIABLES shows TYPE_CONFLICT=Y; list in log for review.

**D-08 — Duplicate "PRECEDE Study ID" (s15, s17):**
SAS confirms values equal primary Study ID every row before DUPLICATE_DROPPED. %fail_out if any differ.

**D-09 — s04/s05:**
All columns: status=LINKAGE_ONLY, no PCNR_ name (PDD-D-18).

**D-10 — Done criteria:**
All 4,795 rows covered; no duplicate/invalid PCNR_ names; zero undecided NEAR_MATCHES; Gerard reviewed workbook; naming flagged for Price.

## Claude's Discretion

None — all decisions specified by user.

## Deferred Ideas

None.
