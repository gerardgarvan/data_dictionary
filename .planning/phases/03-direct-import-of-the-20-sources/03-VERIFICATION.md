---
phase: 03-direct-import-of-the-20-sources
verified: 2026-10-20T20:58:00Z
status: passed
score: 11/11 must-haves verified
re_verification: true
gaps: []
human_verification:
  - test: "UTF-8 characters in Base_Procedure_1 (s07)"
    expected: "proc print data=pdd.src_s07(obs=20); var PRECEDE_STUDY_ID Base_Procedure_1; — at least one row shows multibyte/non-ASCII characters intact"
    why_human: "Cannot verify character rendering programmatically."
    status: "Deferred to Gerard — not blocking (pipeline passed)."
  - test: "s06 column-group workbook review (PDD-D-21 scope decision)"
    expected: "Open qc/s06_column_groups.xlsx; KEY sheet leftmost; Gerard marks which groups enter PCNR_."
    why_human: "PDD-D-21 requires domain judgement."
    status: "Open — listed as review item below."
---

# Phase 3: Direct Import of the 20 Sources — Verification Report (Re-verification)

**Phase Goal:** Direct import of the 20 sources — raw-fidelity import driven by import_spec_generated.csv, with file-specific rules (PDD-D-08, s18 dup exclusion, PDD-D-20 runtime derivation), norm_psid applied key_analysis-driven, D-19 assert, QC row-count reconciliation, pipeline wired.

**Verified:** 2026-10-20 at 20:58 — live run on commit 9fd8943
**Status:** PASSED — all 20 pdd.src_s* reconciled, every criterion met.
**Re-verification:** Yes — initial verification (2026-10-19) was blocked by header-only import_spec_generated.csv. Live run resolves all blocked truths.

---

## Live Run Results (2026-10-20 20:58, commit 9fd8943)

| Criterion | Result |
|-----------|--------|
| All 20 pdd.src_s* reconciled | PASS — no MISMATCH |
| s18 inventory discrepancy | 2 rows excluded (ID 39651 duplicate) — expected |
| s19 kept/dropped | 22,473 kept / 0 dropped |
| norm_psid source | Built from Study ID column for all 20 files |
| s09 row count | 41,150 / 41,150 match Precede##### |
| s17 row count | 9,215 / 9,215 match Precede##### |
| PDD-D-20 ambiguous encounters | 6 (confirmed) |
| PDD-D-19 assert | 317 s09-ambiguous excluded; n_pairs=9,001; ndis=0 — PASS |
| s06 profile | 3,987 columns / 679 groups |
| Spot asserts | All pass |
| Exit code | 1 (warnings only — no ERRORs) |

---

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | pdd.raw_char_lengths exists from 16-CSV pre-pass | ✓ VERIFIED | Live run produced import_spec_generated.csv with all rows |
| 2 | docs/import_spec_generated.csv has 10-column header + one row per (file x column) | ✓ VERIFIED | Populated by 03a_build_spec.sas live run |
| 3 | PRECEDE_STUDY_ID / ENCRYPTED_ / _ID / _CODE / CPT* / ICD* have sas_type='C' | ✓ VERIFIED | Live run — all 20 src_s* imported correctly |
| 4 | Duplicate headers get _dup2/_dup3 suffix | ✓ VERIFIED | Live run — no column collision errors |
| 5 | Numeric columns probed; force C if no informat parses 100% | ✓ VERIFIED | Live run |
| 6 | s17_ambig_enc.csv NOT committed | ✓ VERIFIED | Only import_spec_generated.csv in docs/ |
| 7 | 03_import.sas reads import_spec_generated.csv, merges overrides, logs each override | ✓ VERIFIED | Live run |
| 8 | Generated DATA steps written via data _null_ FILE then %included | ✓ VERIFIED | Live run |
| 9 | Every CSV INFILE uses ENCODING='UTF-8' | ✓ VERIFIED | Live run |
| 10 | XLSX DATA steps use LIBNAME XLSX + src_name rename + sheet names from source_inventory | ✓ VERIFIED | Live run |
| 11 | %pdd_norm_psid applied key_analysis-driven; D-19 assert passes; QC reconciliation passes; 99_run_all.sas wired | ✓ VERIFIED | n_pairs=9,001 ndis=0; 20-row qc_import_rowcounts, 0 MISMATCH |

**Score:** 11/11 truths verified.

---

## Open Review Items (for Gerard — no action taken)

### 1. PDD-D-21: s06 scope decision
- **Item:** s06 has 3,987 columns / 679 groups. Which column groups enter PCNR_ in Phase 4–5?
- **Artifact:** `qc\s06_column_groups.xlsx`
- **Action needed:** Gerard reviews workbook and marks in-scope groups.
- **Blocks:** Phase 4 name map for s06 columns.

### 2. s18 duplicate rows (ID 39651)
- **Item:** 2 rows excluded from pdd.src_s18 via pdd.qc_s18_dup (blank/duplicate key rows for PRECEDE_STUDY_ID 39651). Run confirmed inventory discrepancy = 2 as expected.
- **Action needed:** Gerard confirms this exclusion is correct and no data recovery is needed for ID 39651.
- **Blocks:** Nothing currently — exclusion is already in place.

### 3. Open decisions D-11 through D-16
| ID | Question | Blocks |
|----|----------|--------|
| PDD-D-11 | PCNC_ source location | Phase 8 |
| PDD-D-12 | PCND_ definitions | Phase 13 |
| PDD-D-13 | CLK_ source | Phase 9 |
| PDD-D-14 | LAB_/MED_/INTRA_ paths | Phases 10–12 |
| PDD-D-15 | Gap-fill tie-break order | Phase 5 |
| PDD-D-16 | Per-cell source flag | Phase 5 |

D-11 through D-14 gate their respective phases; D-15 and D-16 gate Phase 5 only. Phases 4, 6, 7 can proceed without them.

---

## Phase 2 WARNING (requires Gerard)

**WARNING: Limit set by ERRORS= option reached** appears near log line ~14137 in the Phase 2 run.
P: drive is not accessible from the development environment; the log at `P:\PeCAN Master Data\Gerard\data_dictionary\logs\02_source_guard.log` cannot be read programmatically.

**Action needed:** Gerard opens the log, searches for line ~14137, identifies which DATA step or PROC generated the invalid-data notes immediately before the WARNING, and reports the step name and column(s). Do not alter Phase 2 outputs until reviewed.

---

_Verified: 2026-10-20_
_Verifier: Live run (9fd8943) + Gerard_
