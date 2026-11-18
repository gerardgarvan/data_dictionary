# fix_19a - allow-list name heuristic false positive

19a_xlsx_preflight on real data stopped at the allow-list gate:
columns_not_key_and_not_mapped = 0, but
columns_with_mrn_encrypt_encounter_in_name = 1 -> PCNR_Age_at_Encounter
(role MAPPED). This is a mapped age variable, not an identifier.

Do:
1. Add docs/xlsx_name_exceptions.csv (columns: colname, reason, reviewed_by,
   reviewed_date) with one row: PCNR_Age_at_Encounter, "mapped age variable,
   not an encounter identifier", Gerard, 2026-11-18.
2. p19_allowlist: a column whose name matches MRN/ENCRYPT/ENCOUNTER fails the
   gate unless it is listed in the exceptions file AND its role is MAPPED.
   KEY or UNLISTED columns can never be excepted. Log excepted names (names
   only) and add QC items columns_name_flag_excepted and
   columns_name_flag_unexcepted (the gate uses the latter). Fail loudly if the
   exceptions file is missing or lists a column not in the dataset.
3. Tests: extend sas/19_xlsx_test.sas (flagged+excepted MAPPED passes;
   flagged+excepted KEY fails; flagged not excepted fails; stale exception
   fails) and the Python static test. Lint + pytest.
4. Note in 19-SAS-RUN.md. Record in 19-CONTEXT.md that age top-coding (ages
   >= 90) must be raised as a PENDING DECISION for the master workbook if not
   already among PDD-D-35..44.

Constraints unchanged (see exec_19w1.md). Commit on pdd-2018-2025-api; no push.
