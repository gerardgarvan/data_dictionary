# PDD decisions register

Locked decisions PDD-D-01..24 are recorded in `.planning/PROJECT.md` (Locked decisions) and in the
phase CONTEXT files; they are not repeated or reopened here. This file registers decisions opened
from Milestone v2.0 (PCNR_ 2018-2025) onward. Next free number: PDD-D-29.

## Open (Milestone v2.0)

| ID | Brief ref | Question | Default if unanswered | Owner | Blocks | Status |
|----|-----------|----------|-----------------------|-------|--------|--------|
| PDD-D-25 | new-1 | Precedence for cases present in both the 2018-2022 and 2023-2025 sources | Existing rule (D-05/D-15): earlier spine wins, newer sources gap-fill; conflicts listed in QC | Gerard | Phase 15 (NEW-05), Phase 18 | OPEN |
| PDD-D-26 | new-2 | What to do if encrypted MRNs do not link across eras (PID-03) | Stop; no PECAN_ID for 2023-2025 until resolved (MRN/ENCOUNTER crypto files or DSS) | Gerard (DSS if needed) | Phase 17 (PID-03), Phases 18-19 | OPEN |
| PDD-D-27 | new-3 | Include the dictionary as a sheet inside PCNR_Master_Data_Nov_2026.xlsx | No; the dictionary stays its own workbook | Gerard | Phase 19 (XLS-04) | OPEN |
| PDD-D-28 | conflict | What PECAN_ID is in this repo. The brief calls it a rename of the existing `PCNR_ID`, "derived from encrypted MRN", but no `PCNR_ID` exists in `pdd.pcnr`, docs, or SAS code. The current key is `NORM_PSID` (normalized PRECEDE_STUDY_ID, one row per case) and ENCRYPTED_MRN is LINKAGE_ONLY (D-24, not a PCNR_ variable). Options: (a) PECAN_ID = new patient-level key derived from ENCRYPTED_MRN, a new variable, not a rename; (b) PECAN_ID = rename of NORM_PSID (case-level, contradicts "patient-level"); (c) a PCNR_ID exists elsewhere (older project) and Gerard supplies its derivation. Evidence needed: probe ID-shape and overlap output (Phase 14) | None applied. Plans for PID-01/PID-02 stay PENDING DECISION | Gerard | Phase 17, DD-01, DD-03 | OPEN |

## Carried (not a new number)

| Item | Status | Notes |
|------|--------|-------|
| Price sign-off on PCNR_ naming rules A1-A4 (TD-04) | OPEN since 2026-10-21 | Gerard approved A1-A4 on 2026-10-21. Price sign-off is still required before release of either deliverable. Extended names for 2023-2025 (Phase 16) fall under the same sign-off. |
