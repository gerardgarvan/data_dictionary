Resolve PDD-D-28 non-interactively and unblock Phase 17 (PECAN_ID). Do not ask questions.

## Facts (from Gerard, 2026-11-16)

"PCNR_ID" in the brief means `pecan_ID` from the earlier master-merge project
(repo `C:\Master_Renamed_same_format_accross`, v2.0, program `sas/20_pecan_id.sas`, a copy is at
`docs/reference/20_pecan_id.sas`). What that program establishes:

- `g.pecan_id_xwalk` (SAS library g = `P:\PeCAN Master Data\Gerard\Master_Renamed_same_format_accross\merge`),
  columns `ENCRYPTED_MRN $40`, `pecan_ID` (numeric). One row per distinct encrypted MRN.
- Built from `g.master_data_merged` (same case set and MRNs as
  `2018_2022_X_MASTER_DATASET_20240402.csv`, checked by its D-14 cross-check). MRNs whose value is
  blank or the literal `NULL` are excluded.
- `pecan_ID` = 1..N, MRNs ranked by their smallest numeric PRECEDE study number (digits after
  the `Precede` prefix), MRN as tie-breaker.
- Append-only: re-runs keep existing IDs, new MRNs get `max(pecan_ID) + n`; dated backups
  `pecan_id_xwalk_<B8601DT15>` in `&xwalk_backup_path`; aborts if the crosswalk differs from the
  latest backup.
- The 2026-11-16 probe shows 31,136 distinct non-missing MRNs in the 2018-2022 spine CSV, so the
  crosswalk should hold 31,136 rows unless NULL-sentinel MRNs reduce it.
- The 2023-2025 `ENCRYPTED_MRN` column imports as $51 (probe), longer than the crosswalk's $40.

## Decision text for PDD-D-28 (status DECIDED, decided by Gerard 2026-11-16)

PECAN_ID is the existing master-merge `pecan_ID`, carried into PDD without changing any value.

1. **K1 seed.** `pdd.pecan_id_registry` is seeded once from `g.pecan_id_xwalk` (read-only; PDD
   never writes to the g library). Every row is copied unchanged, `KEY_ERA='K1'`. Seed checks:
   the row count and the sum of pecan_ID match the source; pecan_ID is unique; every
   ENCRYPTED_MRN is unique; and the seeded MRN set equals the distinct non-blank, non-NULL MRNs of
   the 2018-2022 spine (abort with counts on any difference).
2. **Registry columns.** `PECAN_ID` (numeric, 8), `ENCRYPTED_MRN $64`, `KEY_ERA $2`,
   `ASSIGNED_RUN` (date), `SOURCE $32` (`master_merge_xwalk` for K1 seed, else the PDD program),
   `LINKED_TO_PECAN_ID` (numeric, blank), `LINK_SOURCE $64` (blank), `STATUS $10` (ACTIVE).
   MRN width $64 because K2 values reach $51.
3. **K2 IDs.** Numeric, `PECAN_ID = 1000000 + rank`. Rank uses the same rule as K1 (smallest
   numeric PRECEDE study number per MRN, MRN as tie-breaker) over the 2023-2025 files. The offset
   keeps K2 apart from K1 and leaves room for K1 to grow. K2 assignment is append-only like K1:
   re-runs keep existing IDs; new K2 MRNs get `max(K2 PECAN_ID) + n`.
4. **Uniqueness is per era.** An MRN string is unique within its KEY_ERA; registry lookups always
   join on (ENCRYPTED_MRN, KEY_ERA). K1 and K2 MRNs are never compared.
5. **Backups.** Every registry change writes a dated backup (same pattern as program 20) under
   the PDD output root on P:. Abort if the registry differs from its latest backup before an
   append.
6. **Name.** In PDD the variable is `PECAN_ID` (no PCNR_ prefix). The dictionary row says:
   "Patient key. Same values as pecan_ID in g.pecan_id_xwalk (master-merge v2.0) for 2018-2022
   (K1); 2023-2025 MRNs use a different encryption key and get IDs from 1,000,001 (K2). Patients
   with surgeries in both eras currently have two PECAN_IDs."
7. **Later linkage** is unchanged from the brief (PID-06): `sas/pecan_id_link.sas` fills
   LINKED_TO_PECAN_ID / LINK_SOURCE, marks matched K2 rows SUPERSEDED, and linked patients carry
   their K1 PECAN_ID. K2 IDs are never reused.

## Edits

1. `docs/DECISIONS.md`: set PDD-D-28 to DECIDED with the text above.
2. `.planning/REQUIREMENTS.md` (and `.planning/MILESTONE_BRIEF_2018_2025.md` to match):
   - PID-01 becomes: "PECAN_ID = master-merge `pecan_ID`, carried unchanged (PDD-D-28)." Remove
     the rename-of-PCNR_ID wording everywhere.
   - PID-03 seeds from `g.pecan_id_xwalk` with the seed checks in item 1.
   - PID-04 uses the K2 rule in item 3.
   - Add PID-08: "Phase 17 reads `g.pecan_id_xwalk` read-only through a libname defined in
     `sas/00_config.sas` (new macro variable for the master-merge g path); no PDD program writes
     to that library."
3. `.planning/ROADMAP.md` / `STATE.md`: Phase 17 is no longer blocked on PDD-D-28 (still
   depends on Phases 15-16).
4. Do not change any other decision.
5. Commit: `decision: PDD-D-28 PECAN_ID = master-merge pecan_ID; K2 offset 1000000`.

Report the edits made and anything in the existing docs that conflicts with this.
