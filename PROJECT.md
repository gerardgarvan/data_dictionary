# PeCAN Data Dictionary — Project Decisions

## Phase 5 Decisions

D-24 (Gerard, 2026-10-26): ENCRYPTED_MRN and ENCRYPTED_ENCOUNTER are linkage keys.
Status LINKAGE_ONLY in name_map for all sources. PCNR_ENCRYPTED_MRN and
PCNR_ENCRYPTED_ENCOUNTER removed. PCNR variable count: 1299 -> 1297. Phase 3
linkage (D-19, s17 enc_for_linkage) unaffected — ENCRYPTED_ENCOUNTER used as
join key only, never as a PCNR_ variable.
