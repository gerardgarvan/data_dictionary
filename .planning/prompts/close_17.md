# close_17 -- close Phase 17 (PECAN_ID)

Headless run. Follow RULES and CLAUDE.md. One commit, do not push.

## 1. 17-SUMMARY.md / 17-05-SUMMARY (whichever the plans use): results, masked
SAS runs 2026-11-17 on the SAS machine, synthetic tests 17_pecan_id_test (T1-T18) and
17_pecan_id_link_test (T0-T7) ALL TESTS PASSED, no WARNING/ERROR lines.
- 17a (approved by Gerard via PDD_APPROVE_NEW_BASELINE=1 after reviewing the masked
  proposal 33031/33031/33031/31136): K1 join gate PASS 41150 rows 1:1 on
  PRECEDE_Study_ID -> PRECEDE_STUDY_ID (norm), 0 missing pecan_ID; registry created with
  33031 K1 IDs; 1895 dup pairs appended to pdd.pecan_id_dup_link; blank spine MRN rows 1.
- 17b: PDD-D-30 shared s22 x s23 = 142 (read from docs/new_overlap_decisions.csv);
  K2 distinct MRNs 26474 appended (IDs from 1000001); K2 cases without MRN 0; registry
  59505 rows; case map 77498 rows; registry and case map gates PASS. Rerun: 0 appended.
- 17a rerun after fix_17e: registry not re-seeded, 0 pairs appended, first piddup_ backup.
- 17c: qc\pecan_id_cases_per_patient.csv written, no ERROR/WARNING.
- Backups: pidreg_20261117_152323 (33031, K1 only), pidreg_20261117_152929 (59505,
  current), piddup_20261117_161437 (1895).
Record the run history honestly: an early 17a run inherited FLAG mode from the test
session and wrote the dup link without approval; Gerard deleted it (no backup existed)
before the approved run. Fixed in fix_17d (forced ABORT, gates fail on missing tables,
nothing after a failed guard). QC lock errors on the P: share fixed in fix_17e
(WORK staging + single flush, filelockwait=10).

## 2. Verify and fix if needed (with a synthetic test)
- 17b on a no-op rerun printed no "registry equals its latest backup" line. Confirm
  17b always runs the backup-current assertion (and the link one) before any append,
  including when 0 rows will be appended; fix if it is skipped.
- Confirm qc\pecan_id_cases_per_patient.csv masks counts 1-10 as <11; fix if not.

## 3. STATE.md / ROADMAP.md
Phase 17 complete 2026-11-17; next Phase 18 (combined dataset and dictionary). Record
PDD-D-32 as executed. Carry to Phase 18: join new files on norm_psid to the case map;
apply PDD-D-30 field gap-fill and PDD-D-31 types; ASA and CPT1 Class numeric; flag s06
NO_DATA variables; PECAN_ID dictionary text from docs/pecan_id_dictionary_text.csv;
note the 1895 K1 dup pairs in the dictionary (PECAN_ID is per encryption era until the
link is applied). Note that qc\pecan_id_registry_proposed.csv holds encrypted MRNs and
must not be committed (Gerard deletes it after approval).

## 4. Commit
`docs(17): close Phase 17 -- PECAN_ID registry, K1/K2, dup link, run history`.
Run lint and pytest first. Print files changed and anything fixed in step 2.
