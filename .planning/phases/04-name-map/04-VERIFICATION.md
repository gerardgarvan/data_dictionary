# Phase 04 Verification

**Status: VERIFIED 2026-10-21**
**Commit merged to master:** 93f1d09 (from fix/04-decisions)

## Exit criteria — all met

| Criterion | Result |
|-----------|--------|
| NAME_MAP has no duplicate PCNR_ names | 0 collisions |
| No truncation collisions | 0 suffixes applied |
| Elided names present | 31 elided (expected; logged) |
| 0 undecided near-matches | 0 undecided |
| Decisions test SUMMARY failed=0 | 0 failures |
| Pipeline exit=0, warnings=0 | exit=0, warnings=0 |
| Column coverage | 4,795 columns → 1,299 PCNR_ variables |

## Decisions recorded (Phase 4)

### A-series: naming rules (name_abbrev.csv)
- A1–A4: abbreviation modes `always` and `as_needed` codified in `docs/name_abbrev.csv`.
  `always` abbreviations applied unconditionally; `as_needed` only when name would exceed limit.

### B-series: name_map_decisions.csv handling (04-PART-B-DECISIONS.md)
- B1 SAME: transitive union-find merge; final group_id = smallest in merged set.
- B2 DIFFERENT: split group if both sides share one automatic group; no-op if already separate.
- B3 Decision matching: identify sides by (s_code, col_order), verify header_x matches original_header.
- B4 RENAME checks: V7-valid, ≤32 chars with PCNR_ prefix, unique case-insensitively, one RENAME per group.
- B5 Same-file guard: assert no group contains two rows from the same s_code after all decisions.
- B6 Decisions CSV header: 11-column header enforced; Python writer emits same header.
- B7 Suffix re-elision: re-elide via %elide_middle when suffixed name exceeds limit; assert no "___" in final names.
- B8 Synthetic test (tests/04_decisions_test.sas): T1–T9 cases all PASS; no PHI required.

### Near-match decisions (Gerard, 2026-10-21, value sets verified via tools/check_nearmatch_values.sas)
- s06 `ASA_Anest_Record` = s03 `ASA` (Anesth Record): **SAME** — identical value sets confirmed.
- s06 `Holiday` = s03 `Holidays`: **SAME** — identical value sets confirmed.

## Open items forwarded to Phase 5 / pre-release

| Item | Detail | Resolution |
|------|--------|------------|
| Naming rules A1–A4 | name_abbrev.csv, mode=always, always-shortened test prefixes | **Approved by Gerard 2026-10-21.** Price sign-off pending before Phase 7 release. |
| ~~D-21 boundary: 34 COMmoca*/COPYmoca*~~ | ~~Classified as CLOCK; confirm exclusion~~ | **CONFIRMED PCNR_ 2026-10-21 (Gerard)** — MoCA is PCNR, not CLK_. docs/s06_column_class.csv unchanged. Closed. |
| 9 type conflicts | s19 numerics stored as C8; PCNR_YEAR appears as C9 and N8 — keep as character | **Forwarded to Phase 5** — carry as character, document in QC. |
