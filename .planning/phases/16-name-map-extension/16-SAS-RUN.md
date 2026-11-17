# Phase 16 SAS run sheet (for Gerard)

**Status: PENDING SAS RUN** (`16_name_map_ext_test`, `16a_name_map_ext`, `16b_name_map_values_cov`, `run_pipeline.cmd 16`).
**PENDING DECISION:** near-match candidates (see Decision gate); confirm reuse of the TYPE_CONFLICT_EXACT names.
**Price naming sign-off: PENDING** (does not block closing Phase 16; blocks release).

Claude has no SAS and no P: drive and chose nothing at any gate.

## Before you start
1. Sync branch `pdd-2018-2025-api` to the SAS machine.
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. The v1.0 map must exist on P: (`pdd.name_map` 4,795 rows, `pdd.name_map_vars` 1,297) and Phase 15 is complete (`pdd.nsrc_s21..s23`, `docs/import_spec_new_generated.csv`).

SAS command template (same as 15-SAS-RUN.md; use SAS_EXE / SAS_CFG from `config.local.cmd` if set):
`"C:\Program Files\SAS94\SASFoundation\9.4\sas.exe" -sysin "C:\data_dictionary\sas\<program>.sas" -config "C:\Program Files\SAS94\SASFoundation\9.4\nls\u8\sasv9.cfg" -encoding utf8 -nosplash -icon`

## Step 1 - synthetic test
Program: `16_name_map_ext_test.sas` (synthetic data only).
Expected: `TESTRESULT SUMMARY: ALL TESTS PASSED`, no WARNING lines.
Bring back the PASS/FAIL lines.

## Step 2 - 16a standalone (can run now; needs no Phase 15 dataset)
Program: `16a_name_map_ext.sas`.

Expected NOTEs: frozen asserts 4795 / 1297 / 1297; 282 new rows; 3 KEY, 6 LINKAGE_ONLY; 5077 ext rows; `n_frozen_names_changed=0`; Stage 2 0 failures; then either
`PENDING DECISION -- ... wait for Gerard` (expected on the first run, because `docs/name_map_decisions_new.csv` is header-only) or `PASS -- all candidates decided`.
Any ERROR other than a decision-file validation error is a bug: bring back the ERROR lines.

Then run:
`.venv\Scripts\python.exe python\scripts\write_name_map_ext_review.py --allow-partial`
and bring back `logs\name_map_ext_summary.txt` (already masked).

## Decision gate - PENDING DECISION (Gerard)
Open `qc\name_map_ext_review.xlsx` (CANDIDATES, VALUES_SIDE_BY_SIDE after Step 3, COVERAGE). For each candidate add one row to `docs/name_map_decisions_new.csv` (side a = new header / s_code, side b = old header or s_code + col_order; `decided_by=Gerard`; ISO date). Claude applied no choice. Rerun 16a after each edit of the file until the NOTE reads `PASS -- all candidates decided`. Commit the decisions file.

Evidence below comes from the probe and `docs/new_source_header_variants.csv` only (no data values).

### (i) `preop_edu_years` (Num; s21, s22, s23)
Candidates on the old side: `Education` (Char 19; s03 s06 s07 s09 s10 s12 s13 s16 s19) and `Edu_Years` (Num; s03, s13).
- SAME as `Education`: merges the new years into the Char education variable (type differs: Num vs Char 19).
- SAME as `Edu_Years`: merges into the Num variable (types agree; only two old sources carry it).
- DIFFERENT: new variable `PCNR_PREOP_EDU_YEARS`-style name by A1-A4; no merge.

### (ii) Braden year-prefixed columns: `BRADEN_2024_OUT_Braden *` (s22) and `BRADEN_2025_OUT_Braden *` (s23), three columns each
Old side: plain `Braden Activity`, `Braden Mobility`, `Braden Sensory Perception` (s09 s15 s21).
- SAME as the plain Braden variables: 2024 and 2025 cases get the plain variables filled (one row per column pair).
- DIFFERENT: 2024 and 2025 cases have no values in the plain variables, and six one-year variables are added (names would be elided under A1-A4; RENAME is available to force a name).

### (iii) `Fraility_Score` / `Fraility_Category` vs `Frailty_Score` / `Frailty_Category` (spelling)
- SAME: merges into the correctly spelled variables.
- DIFFERENT: separate `Fraility_*` variables are created.

### (iv) `SleepApnea_YN` vs `Sleep_Apnea_YN` (s03 s06 s07 s09; s10 and s12 use `Sleep_Apnea`)
- SAME as `Sleep_Apnea_YN`.
- DIFFERENT: new variable for `SleepApnea_YN`.

### (v) Any extra pair the run lists
Every other EDIT_DISTANCE, TRAILING_SUFFIX, AMBIGUOUS or NONPCNR_EXACT pair that appears in CANDIDATES needs SAME, DIFFERENT or RENAME. Evidence: the CANDIDATES and VALUES_SIDE_BY_SIDE sheets.

### (vi) TYPE_CONFLICT_EXACT - confirm reuse (MAP-01)
Exact cleaned-header matches reuse the stored name even when the type changes. Confirm, or add a DIFFERENT row to separate:
- `Death_Days_After_Surgery`: new Char, old Num.
- `Feels_Exausted`, `Low_Physical_Activity`, `Slow_Walking_Speed`, `Unintended_Weight_Loss`, `Week_Grip_Strength`: new Num; same names are Char in s14, s15, s17; `_Value` variants are Num in s09 and s12.
Confirming needs no row.

## Step 3 - 16b (Phase 15 is complete, so it can run now)
Program: `16b_name_map_values_cov.sas`.
Expected NOTEs: YEAR numeric in s09 and s21-s23; `MAP-04 coverage written`; no reconcile failure.
NO_YEAR counts for s01 and s18 are expected (non-spine IDs).

## Step 4 - pipeline
`run_pipeline.cmd 16`
Expected: exit 0, `Pipeline PASSED`, `qc\name_map_ext_review.xlsx` with KEY leftmost.

## Bring back
Paste into `16-05-SUMMARY.md` (counts 1-10 as `<11`):
- `logs\name_map_ext_summary.txt`
- ERROR and WARNING line counts from `logs\16a_name_map_ext.log`, `logs\16b_name_map_values_cov.log`, `logs\99_run_all.log`
- the Step 1 TESTRESULT line
- the committed `docs/name_map_decisions_new.csv`

Do not paste rows from `qc\` or `exchange\`.

## Phase 16 closes when
Test PASS; 16a PASS with `n_new_pending_decision = 0`; 16b coverage written; pipeline exit 0. Price sign-off stays PENDING.

## Assumptions (headless run)
| ID | Assumption |
|----|-----------|
| A1 | Extension, not rerun: `16a`/`16b`, datasets `pdd.name_map_ext` (5,077 rows) and `pdd.name_map_vars_ext`; `04_name_map.sas`, `pdd.name_map`, `pdd.name_map_vars` read-only. |
| A2 | Separate decisions file `docs/name_map_decisions_new.csv`; side a = new column (s21-s23), side b = old column or name. |
| A3 | Old-source year = spine `pdd.src_s09.YEAR` by `norm_psid`; new files use their own `YEAR`; IDs without a year go to NO_YEAR, never dropped. |
| A4 | Coverage non-missing = Phase 5 rule plus `NULL` for char columns of type-conflict variables (D-02b). Placeholders count as data. |
| A5 | Undecided candidates keep a blank `pcnr_name` and status `PENDING_DECISION`. |
| A6 | Exact header matches reuse the stored name even with a type change; listed as TYPE_CONFLICT_EXACT. |
| A7 | KEY = `PRECEDE Study ID`; LINKAGE_ONLY = `ENCRYPTED_MRN` / `ENCRYPTED_ENCOUNTER` for s21-s23. |
| A8 | Predicted split (about 87 reuse + 3 KEY/LINKAGE + 10 candidate headers) comes from an offline reimplementation; SAS asserts at run time. |
| A9 | Value distributions stay in `qc\` / `exchange\` on P:; the workbook masks counts 1-10 as `<11`; nothing committed. |
| A10 | `sasjs lint` availability is checked at execution; absence is reported. |
| A11 | 16a does not hard-stop on undecided candidates; it writes outputs and a PENDING DECISION NOTE; Phase 18 must hard-stop on `n_new_pending_decision > 0`. |
| A12 | 16b writes `pdd.name_map_coverage` and `pdd.name_map_vars_coverage`; never rewrites 16a outputs. |
| A13 | 16a reads the committed `docs/import_spec_new_generated.csv`, so it needs no Phase 15 dataset; 16b needs `pdd.nsrc_s21..s23`. |
| A14 | Pending variables appear in coverage as `PENDING:<name_key>`. |
| A15 | Old side of a value comparison = every frozen (s_code, col_order) carrying the old `pcnr_name`, one side row per s_code. |
| A16 | Pipeline token `16` runs 16a then 16b, then the Python writer. |
| 05-a | `findstr /i "\<16\>"` does not match the `\<15\>`, `\<5\>` or `\<6\>` blocks (word boundaries); verified by reading. |
| 05-b | Pipeline order for token 16: check, 16a, check, 16b. 16b fails its preconditions if `pdd.nsrc_s21..s23` are missing, hence 16a runs standalone first. |
