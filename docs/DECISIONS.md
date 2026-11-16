# PDD decisions register

Locked decisions PDD-D-01..24 are recorded in `.planning/PROJECT.md` (Locked decisions) and in the
phase CONTEXT files; they are not repeated or reopened here. This file registers decisions opened
from Milestone v2.0 (PCNR_ 2018-2025) onward. Next free number: PDD-D-30.
Brief refs: new-1 = PDD-D-25, new-2 = PDD-D-26, new-3 = PDD-D-27, new-4 = PDD-D-29 (PDD-D-28 is a repo-vs-brief conflict, not a brief item).
Re-registered 2026-11-16 against the revised brief (commit 52f6ad9); numbers from the first registration are kept.

## Register (Milestone v2.0)

| ID | Brief ref | Question | Default if unanswered | Owner | Blocks | Status |
|----|-----------|----------|-----------------------|-------|--------|--------|
| PDD-D-25 | new-1 | Precedence for cases present in both the 2018-2022 and 2023-2025 sources | Existing rule (D-05/D-15): earlier spine wins, newer sources gap-fill; conflicts listed in QC | Gerard | Phase 15 (NEW-05), Phase 18 | OPEN |
| PDD-D-26 | new-2 | Encrypted MRNs do not link across eras: the 2023-2025 files use a different MRN encryption key (K2) from 2018-2022 (K1); confirmed by Gerard 2026-11-16 (brief: probe found 0 of the K2 MRNs in the K1 spine, every K2 value 5 characters longer; probe file not yet committed) | **DECIDED (Gerard, 2026-11-16):** separate K2 PECAN_IDs through the append-only `pdd.pecan_id_registry` (PID-02..PID-05), with linkage deferred to `sas/pecan_id_link.sas` (PID-06) when a crosswalk or common key is available. Patients with surgeries in both eras carry two PECAN_IDs until then, and the dictionary and KEY sheet say so | Gerard | Supersedes the earlier stop-at-gate default. Shapes Phase 17 (PID-02..PID-07), Phases 18-19 | DECIDED |
| PDD-D-27 | new-3 | Include the dictionary as a sheet inside PCNR_Master_Data_Nov_2026.xlsx | No; the dictionary stays its own workbook | Gerard | Phase 19 (XLS-04) | OPEN |
| PDD-D-28 | conflict | What PECAN_ID is in this repo. The brief calls it a rename of the existing `PCNR_ID`, "derived from encrypted MRN", but no `PCNR_ID` exists in `pdd.pcnr`, docs, or SAS code. The current key is `NORM_PSID` (normalized PRECEDE_STUDY_ID, one row per case) and ENCRYPTED_MRN is LINKAGE_ONLY (D-24, not a PCNR_ variable). Options: (a) PECAN_ID = new patient-level key derived from ENCRYPTED_MRN, a new variable, not a rename; (b) PECAN_ID = rename of NORM_PSID (case-level, contradicts "patient-level"); (c) a PCNR_ID exists elsewhere (older project) and Gerard supplies its derivation. Evidence needed: probe ID-shape and overlap output (Phase 14) | None applied. Plans for PID-01, PID-03 (registry seed) and PID-04 (K2 ID format) stay PENDING DECISION. The brief also says the K1 registry is seeded with the "existing K1 IDs exactly as they are": none exist yet | Gerard | Phase 17 (PID-01, PID-03, PID-04), DD-01, DD-03 | OPEN |
| PDD-D-29 | new-4 | How 2022 5-digit case IDs were linked to the spine in Phase 3, and whether the same rule applies to 2023-2025 (all three 2023-2025 files use 5-digit case IDs per the brief) | Read the Phase 3 decision record (PDD-D-19, LOCKED, `cats('Precede', put(input(strip(id), ?? 8.), z5.))`) and apply the same rule to 2023-2025 if the probe shows the same shape. **Conflict:** the brief says the probe shows 0 overlap under the plain `Precede` + 5-digit rule for the 2022 files too, but PDD-D-19 records 9,215/9,215 (s16/s17), 9,215/9,484 (s18) matches under that rule. Probe must show which 2022 files and which spine are meant; not applied until Gerard decides | Gerard | Phase 15 (NEW-03) | OPEN (PENDING DECISION) |

## Carried (not a new number)

| Item | Status | Notes |
|------|--------|-------|
| Price sign-off on PCNR_ naming rules A1-A4 (TD-04) | OPEN since 2026-10-21 | Gerard approved A1-A4 on 2026-10-21. Price sign-off is still required before release of either deliverable. Extended names for 2023-2025 (Phase 16) fall under the same sign-off. |
