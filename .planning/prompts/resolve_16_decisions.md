Record Gerard's Phase 16 decisions (2026-11-16) so 16a can pass. Non-interactive; do not ask questions.

## Evidence (Gerard's runs, 2026-11-16)
`qc\name_map_ext_review.xlsx` after 16a + 16b, plus two ad-hoc SAS frequency checks. Counts 1-10 would be
`<11`; none below appear.

- Fraility_Score: 0-5 in s21-s23; PCNR_Frailty_Score 0-5 (old also has .5 steps and NULL in s19).
- Fraility_Category: identical labels to PCNR_Frailty_Category ('0-1 NO FRAILITY', '2-3 INTERMEDIATELY FRAIL',
  '4-5 FRAIL').
- SleepApnea_YN: new Y/N; PCNR_Sleep_Apnea_YN has only Y or blank in s03 s06 s07 s09.
- BRADEN_2024_OUT_* / BRADEN_2025_OUT_*: values 1-4, same as plain Braden in s09 s15 s17.
- preop_edu_years: numeric years (mostly 12/14/16/18; max 114 in s22, 244 in s23 = data-quality outliers).
  PCNR_Education is categorical (COLLEGE, HIGH SCHOOL/GED, ...), so not the same variable. PCNR_Edu_Years
  (numeric, s06 s11, FROZEN) is the match.
- Death_Days_After_Surgery in s21-s23 is text: the only non-numeric value is '#Error'
  (s21 9,782; s22 12,187; s23 12,222). Crossed with Death_Date_Y_N: '#Error' with flag Y = 43 / 43 / 30
  (116 real deaths whose days value failed); blank with flag Y = 524 / 329 / 46 (deaths with no days,
  likely beyond the 365-day window); number always has flag Y (466 / 513 / 421).

## Decisions (all decided_by=Gerard, 2026-11-16)

1. Near-matches, written to `docs/name_map_decisions_new.csv` in the format 16a expects:
   - SAME: Fraility_Score -> PCNR_Frailty_Score; Fraility_Category -> PCNR_Frailty_Category;
     SleepApnea_YN -> PCNR_Sleep_Apnea_YN; BRADEN_2024_OUT_Braden Activity / Mobility / Sensory Perception and
     BRADEN_2025_OUT_Braden Activity / Mobility / Sensory Perception -> PCNR_Braden_Activity /
     PCNR_Braden_Mobility / PCNR_Braden_Sensory_Perception.
   - SAME: preop_edu_years -> **PCNR_Edu_Years** (not the proposed PCNR_Education). If 16a only accepts the
     proposed old name for a candidate, extend it to accept SAME against any existing FROZEN pcnr_name
     (validate the name exists in pdd.name_map_vars; side-b type must be compatible: Num vs Num here), with a
     synthetic test in sas/16_name_map_ext_test.sas and a static pytest. Do not use RENAME for this (it would
     collide with PCNR_Edu_Years).
   One row per new column (s21, s22, s23 where applicable) so n_new_pending_decision reaches 0. The duplicate
   EDIT_DISTANCE / VARIANTS_FILE candidate pairs for the same column are covered by the same rows.
2. New decision PDD-D-31 in docs/DECISIONS.md, "Combined type for TYPE_CONFLICT_EXACT variables (PCNR_ layer,
   values as delivered, DD-02)":
   - Stay numeric (old side is text only because s19 uses 'NULL', treated as missing per D-02b):
     Age_at_Encounter, Admit_BMI, rt_INCISE_to_DRESS_mins, rt_RMS_to_RM_END_mins, rt_RMS_to_INCISION_mins,
     Cognitive_Score, Frailty_Score.
   - Text: YEAR (old values include '2018_2019'); Base_Procedure_Code_1 (a code; new numeric values written as
     text with no decimals or exponent); ASA_Anesth_Record and CPT1_Class unless the runner finds from the
     review workbook that both sides are numeric apart from NULL (then numeric; record which).
   - Text, each era's coding kept: Feels_Exausted, Low_Physical_Activity, Slow_Walking_Speed,
     Unint_Weight_Loss, Week_Grip_Strength (0/1 in 2023-2025; Y/N/YES/NO before). Dictionary note required.
   - Text, '#Error' kept verbatim: Death_Days_After_Surgery. Dictionary note: in 2023-2025 '#Error' means the
     days calculation failed in the delivered extract; it usually means no death recorded, but 116 rows have
     Death_Date_Y_N = Y. Blank with a death flag means a death with no days value (likely beyond 365 days).
     Recoding belongs in a later derived layer.
   - SleepApnea note for the dictionary: before 2023 the source records only Y or blank.
3. Add to `.planning/REQUIREMENTS.md` (Phase 18, DD-01/DD-03): apply PDD-D-31 types; write the dictionary notes
   above; QC count of death-flagged '#Error' rows per file.
4. New file `docs/data_quality_followups.md` (committed; counts and names only): (a) 116 death-flagged
   Death_Days '#Error' rows (43/43/30) - ask DSS whether the days can be recomputed; (b) preop_edu_years
   values above 30 (max 114 in 2024, 244 in 2025) - likely entry errors; (c) Sleep_Apnea_YN pre-2023 records
   only Y.
5. STATE.md cleanup backlog: (4) 16b writes 'WARNING: Defining an array with zero elements' x5 when a source
   has no numeric or no character columns - guard the array; (5) 16b re-reads s06 (3,987 columns) for every
   value pair, ~45 s each - same cache fix as backlog item 2.

Run sas_lint, sasjs lint, ruff, pytest; all green. Commit (decisions file; DECISIONS.md; any 16a change with
its tests; requirements/STATE/followups as separate commits). Report the exact rerun steps for Gerard.
