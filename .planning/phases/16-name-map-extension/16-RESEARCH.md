# Phase 16 (M3): Name map extension - Research

**Researched:** 2026-11-16
**Domain:** Base SAS 9.4 metadata program (extend a frozen header-to-PCNR_ map to three new files, human gate for near-matches, per-variable year coverage); Python/openpyxl review workbook
**Confidence:** HIGH for repo facts (Phase 4 algorithm, frozen-map constraints, file/column facts from committed specs and probe). MEDIUM for the predicted counts below (reimplemented offline in Python from committed spec CSVs, not from the real `pdd.name_map` on P:). MEDIUM for SAS idioms (cannot be run here: no SAS, no P:).

## Summary

Phase 16 maps 282 new (file x header) rows (s21 = 2023, s22 = 2024, s23 = 2025, 94 columns each, from `docs/import_spec_new_generated.csv`) onto the existing Phase 4 map without changing any existing PCNR_ name. The decisive finding is that this must be an **extension of a frozen map, not a rerun of `04_name_map.sas`**. Phase 4 hard-asserts `4795` spec rows (`check_import_spec_counts`), reads `pdd.import_spec` only, and its B3 check fails on any decision row whose (s_code, col_order) is not in that spec. The abbreviation table (`docs/name_abbrev.csv`) may also have grown since the Phase 4 run, so recomputing old names is unsafe. New names must come from a lookup against the stored `pdd.name_map` (4,795 rows, 1,297 distinct PCNR_ names per ROADMAP/D-24), not from regeneration. `pdd.name_map` and `pdd.name_map_vars` are on P:, not in git, so no existing name can be verified from this machine.

From the two committed spec files I predicted the split (Python reimplementation of D-02 cleaning, case-insensitive, excluding s04/s05 and s06 CLOCK columns from the "old" side): 100 distinct cleaned header names in the new files; 90 match an old cleaned name exactly (this includes `PRECEDE Study ID`, `ENCRYPTED_MRN`, `ENCRYPTED_ENCOUNTER`, which are KEY / LINKAGE_ONLY, so about 87 are true PCNR reuse); 10 do not match: `preop_edu_years`, `SleepApnea_YN`, `Fraility_Category`, `Fraility_Score` (all s21-s23) and the six year-prefixed Braden columns (`BRADEN_2024_OUT_*` in s22, `BRADEN_2025_OUT_*` in s23). All 10 already have a semantic partner listed in `docs/new_source_header_variants.csv` (status PENDING DECISION). So **after the gate there may be zero genuinely new variables**: every one of the 10 is either merged into an existing variable (SAME) or kept as new (DIFFERENT) by Gerard. Because the D-06 detector (edit distance <= 2 or `_N`/`_dupN` suffix) catches only 3 of them (`SleepApnea_YN`, `Fraility_Category`, `Fraility_Score`) and misses the Braden and `preop_edu_years` cases, the candidate list must be the union of the D-06 detector output and the curated variants file.

MAP-04 (year coverage) is computable only from data (PENDING SAS RUN: needs `pdd.nsrc_s21..s23`, which exist only after the 15c rerun, plus P: datasets). The surgical-year column is `YEAR` (probe: s09 Num, 41,150 non-missing, 5 levels; s08 and s20 Char 9; s21-s23 Num, 1 level each, 10,772 / 13,029 / 12,689 non-missing). Old sources other than s08/s09/s20 have no year column; their year must come from the spine (s09) by `norm_psid`.

**Primary recommendation:** Write new SAS program(s) `sas/16*_name_map_ext.sas` that read the frozen `pdd.name_map` and `pdd.name_map_vars`, never write to them, produce `pdd.name_map_ext` (5,077 rows = 4,795 + 282) and `pdd.name_map_vars_ext`, use a separate decisions file `docs/name_map_decisions_new.csv`, leave undecided near-match columns with a blank PCNR_ name marked `PENDING DECISION`, and compute first/last year and contributing sources from the source datasets.

<user_constraints>
## User Constraints (no CONTEXT.md exists for Phase 16; ROADMAP criteria, REQUIREMENTS, DECISIONS and the task prompt are treated as locked)

### Locked Decisions
- PDD-D-01..23 are closed. Phase 4 rules A1-A4 (naming; D-02 cleaning, D-03 shortening, D-05 two-stage collision, D-06 near-match) apply unchanged. Gerard approved A1-A4 on 2026-10-21.
- PDD-D-29 DECIDED (PDD-D-19 ID rule for 2023-2025). PDD-D-30 DECIDED: the 142 shared s22 x s23 cases are the same surgeries; s22 wins, s23 gap-fills, applied in Phase 18 (not Phase 16).
- PDD-D-24 (in force in 04_name_map): `ENCRYPTED_MRN` / `ENCRYPTED_ENCOUNTER` are LINKAGE_ONLY and excluded from PCNR_ (1,297 PCNR_ variables, not 1,299).
- ROADMAP Phase 16 success criteria 1-5 (verbatim intent):
  1. Exact header matches reuse the existing PCNR_ name (existing map: 1,297 PCNR_ variables after D-24).
  2. Near-matches are listed with value distributions side by side as `PENDING DECISION` for Gerard; none is auto-merged.
  3. New columns get PCNR_ names under rules A1-A4 with 0 collisions and 0 truncation collisions; names already in use keep their meaning.
  4. First and last surgical year with non-missing values, and contributing source files, are recorded per variable.
  5. Price's naming sign-off remains listed as pending.
- Task rules: headless, no questions; Phase 15 SAS reruns not yet done (so `nsrc_s21..s23` do not exist); near-match naming and Price sign-off are PENDING DECISION gates; do not commit.

### Claude's Discretion
- Program/dataset/file names, plan and wave split, how the gate is enforced in SAS, where year comes from for old sources, what "non-missing" means for coverage (recommended below), packaging of the review workbook.

### Deferred Ideas (OUT OF SCOPE)
- PECAN_ID and K1/K2 registry (Phase 17), combined dataset and PDD-D-30 stacking (Phase 18), master xlsx (Phase 19), PDD-D-27 dictionary sheet, MRN linkage across key eras (PDD-D-26). Recoding placeholders; PCNC_/PCND_/CLK_/LAB_/MED_/INTRA_ families.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAP-01 | New headers mapped to existing PCNR_ names with Phase 4 cleaning/abbreviation/collision rules; exact matches reuse the name | Pattern 1 (lookup against frozen map by cleaned header), Pitfalls 1, 2, 7; predicted about 87 PCNR reuse + 3 KEY/LINKAGE rows |
| MAP-02 | Near-matches go to a human gate with value distributions side by side, decided by Gerard | Pattern 3 (candidate union: D-06 detector + variants file), Pattern 4 (value distributions), `docs/name_map_decisions_new.csv`; PENDING DECISION |
| MAP-03 | Genuinely new columns get new PCNR_ names under the same rules; names in use keep their meaning | Pattern 2 (extend-only naming against the frozen name set, hash of used names), Pitfalls 3, 4 |
| MAP-04 | Year coverage per variable (first/last surgical year with any non-missing value, contributing source files) | Pattern 5 (year lookup, per-source arrays, rollup), Pitfall 6; PENDING SAS RUN |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- After any SAS edit: `python tools\sas_lint.py sas\<file>.sas` and `sasjs lint`, zero errors on the edited file.
- After any Python edit: `ruff check python\` and `pytest python\tests`, zero errors / all pass. Interpreter `.venv\Scripts\python.exe`; install via `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`.
- PCM / sas_lint rules: no open-code `%if`/`%else` (C3); no macro keyword in a quoted PUT string (C11); no macro called before its `%macro` in the same file (C13); no bare `data ;`/`set ;` (C14); `LIBNAME libref engine "path"` (C9); no `??` in PROC SQL (C1); no ANSI SQL OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH..AS (C2); recent rule C30 (no semicolons in `%put`/`%fail_out` text).
- Probe-first: only names, types, lengths, counts, encodings from `.planning/schemas/probe_*.md` (and committed specs derived from the SAS runs). Missing facts become a PROBE REQUEST marked `PENDING SAS RUN` in STATE.md. Counts 1-10 appear as `<11` in anything committed to git.
- Headless: no P:, no SAS, no real data; SAS runs are Gerard's; write exact program, log and `qc\`/`exchange\` files to bring back; decision gates are `PENDING DECISION`, no choice applied; never write to the shared Master Data folder; no data in git; commit to current branch, never push.
- Workbooks: KEY sheet leftmost; UF colors #0021A5 / #FA4616 (via `python/pdd/xlsx_style.py`).
- SAS pitfalls: no `%if` in open code; quote or `%superq` text in `%if` comparisons; no commas in macro-call arguments (use a global macro variable); no `RETAIN` with length specs; array declarations after `SET`, helpers after the array; `strip()` before regex anchors; `catx(' ', ...)` where spaces matter; `encoding='wlatin1'` for flagged files; 5-digit IDs normalize to `Precede#####`.

## Facts From the Probe and Committed Specs (only sources of file facts)

| Fact | Value | Source |
|------|-------|--------|
| New files (s-codes per Phase 15 A1) | s21 `2023_X_MASTER_DATASET_20261016.csv`, s22 `2024_...`, s23 `2025_...` | `docs/new_source_files.csv`, probe units 19-21 |
| New spec rows | 282 = 3 x 94; columns `file_code,col_order,src_name,orig_col_name,sas_name,sas_type,length,informat,format,notes,src_encoding` | `docs/import_spec_new_generated.csv` (read) |
| Same-header coverage | 91 header names appear in all 3 files; 9 appear in one only (s21 Braden x3 plain, s22 `BRADEN_2024_OUT_*` x3, s23 `BRADEN_2025_OUT_*` x3) | spec (computed) |
| Full Braden header | `BRADEN_2024_OUT_Braden Sensory Perception` (41 chars cleaned); the **SAS name** is truncated to 32: `BRADEN_2024_OUT_Braden_Sensory_P` | spec rows 186, 280 |
| Year column | `YEAR`: s09 Num 8 (41,150 non-missing, 5 levels); s08 Char 9 (3,456, 4 levels); s20 Char 9; s21/s22/s23 Num 8, 1 level each | probe |
| Other year-like columns (not surgical year) | `precede_aim1_2_year` (14,790, <11 levels, flagged ID-like), `Fiscal year`, `Edu_Years` | probe |
| Case-ID column in new files | `PRECEDE Study ID` (sas_name `PRECEDE_Study_ID`), forced Char | spec row 1 |
| New-only-by-name candidates | `preop_edu_years` (Num), `SleepApnea_YN` (Char 1), `Fraility_Category` (Char 24), `Fraility_Score` (Num), 6 Braden | spec, `docs/new_source_header_variants.csv` |
| Variants file | 16 rows, all `PENDING DECISION`; kinds `year_prefix`, `spelling`, `underscore`, `rename_and_type`, `suffix_and_type`, `type_change` | read |
| Existing decisions | `docs/name_map_decisions.csv`: 2 SAME rows (s06 `ASA_Anest_Record` = s03 `ASA (Anesth Record)`; s06 `Holiday` = s03 `Holidays`); no DIFFERENT, no RENAME | read |
| Exact matches with type change | `Death_Days_After_Surgery` (new Char 6 vs old Num), `Feels_Exausted`, `Low_Physical_Activity`, `Slow_Walking_Speed`, `Unintended_Weight_Loss`, `Week_Grip_Strength` (new Num; same header Char in s14/s15/s17 and, for the `_Value` spellings, Num in s09/s12) | variants file, probe |
| Shared cases | s22 x s23: 142 shared IDs (PDD-D-30); YEAR differs on all 142; 87 of 91 comparable columns identical | `docs/DECISIONS.md`, `.planning/schemas/overlap_s22_s23_20261116.md` |

Facts NOT available here (so Phase 16 SAS must produce them, or PROBE/SAS-RUN REQUEST): the actual `pdd.name_map` / `pdd.name_map_vars` contents and PCNR_ names; `pdd.nsrc_s21..s23` (15c rerun pending); the YEAR value sets (probe gives level counts only, not values: do not assume 2018-2022 or 2023/2024/2025); whether s08/s20 `YEAR` agrees with s09 `YEAR`.

**PROBE REQUEST / PENDING SAS RUN:** none new to `probe_inputs.sas`. Prerequisites: Gerard completes the Phase 15 15c rerun and `run_pipeline.cmd 15` (see `15-SAS-RUN.md` Steps 4-5) so `pdd.nsrc_s21..s23` exist. Then Phase 16 SAS runs themselves are `PENDING SAS RUN`.

## Standard Stack

### Core (all in repo; no new dependencies)
| Tool | Version | Purpose | Why standard |
|------|---------|---------|--------------|
| Base SAS 9.4 (UTF-8 session) | 9.4 (cannot be probed here) | `sas/16*.sas` | Whole pipeline is Base SAS; D-22 SAS owns data |
| `sas/00_config.sas` | repo | paths, `%pdd_lib`, `&exchange_path.`, `&sas_path.` | single config source |
| `sas/04_name_map_macros.sas` | repo | reusable `%elide_middle` (D-03) | include, do not copy; contains no open-code statements |
| Python .venv + pandas 3.x + openpyxl 3.1.5 | per `python/requirements.txt` | review workbook (D-22) | existing `xlsx_style.py`, `name_map_workbook.py`, `new_source_qc_workbook.py` patterns |
| pytest 8.3.3, ruff 0.7.1, `tools/sas_lint.py`, `sasjs lint` | pinned | gates | CLAUDE.md |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New extension program on the frozen map | Edit `04_name_map.sas` to read 23 files | Breaks `4795` assertion, B3 on s21+ decisions, and risks renaming existing variables if abbreviations changed. Rejected. |
| Separate `docs/name_map_decisions_new.csv` | Append s22/s23 rows to `docs/name_map_decisions.csv` | A Phase 4 rerun would fail B3 (nonexistent s_code in import_spec). Keep separate; same 11-column header. |
| Year from spine by `norm_psid` for old sources | Use s08/s20 `YEAR` (Char 9) | Those are 2 of 20 files; spine is complete (41,150 non-missing) and numeric. |

**Installation:** none (`.venv\Scripts\python.exe -m pip install -r python\requirements.txt` already satisfied). **Version verification:** no new packages; pins are in `python/requirements.txt`.

## Architecture Patterns

### Recommended structure (additions only; no edits to 02/03/03a/04/05 programs)
```
sas/
  16_name_map_ext_macros.sas    # optional; define macros before use (C13); no open-code statements
  16a_name_map_ext.sas          # MAP-01..03: status, exact lookup, candidates, naming, final ext datasets, exchange CSVs
  16b_name_map_values_cov.sas   # MAP-02 value distributions side by side; MAP-04 year coverage
docs/
  name_map_decisions_new.csv    # header-only seed, same 11 columns as name_map_decisions.csv
python/pdd/name_map_ext_workbook.py
python/scripts/write_name_map_ext_review.py
python/tests/test_phase16_*.py
```
New datasets (pdd library on P:, never git): `pdd.name_map_ext` (5,077 rows: 4,795 frozen + 282 new), `pdd.name_map_vars_ext`, `pdd.qc_map_ext_candidates`, `pdd.qc_map_ext_collisions`, `pdd.qc_map_ext_values`, `pdd.name_map_coverage`. Exchange CSVs (UTF-8) to `&exchange_path.\` with matching rows added to `docs/exchange_schema.csv` (the Python writers `assert_input` against it). Output workbook `qc\name_map_ext_review.xlsx` (sheets: KEY | NEW_ROWS | CANDIDATES | VALUES_SIDE_BY_SIDE | TYPE_CONFLICTS | COLLISIONS | COVERAGE | VARIABLES_EXT).
Frozen inputs (read-only; assert before use): `pdd.name_map` has 4,795 rows unique on (s_code, col_order); distinct non-blank `pcnr_name` of status PCNR = 1,297 (value from ROADMAP/D-24, assert at run time and abort with counts on difference); `pdd.name_map_vars` has 1,297 rows. Never `proc sort`/`data` to these names; use `work` copies.

### Pattern 1: Status and exact-match reuse (MAP-01)
**What:** For each new row apply the D-04 precedence with the same SAS rules: KEY if header is the case-ID column (`upcase(col_name)='PRECEDE_STUDY_ID'`; new files have no `pdd.key_analysis` rows, so do not join to it: use the header, which is the s21-s23 case-ID column per the spec); `LINKAGE_ONLY` if `ENCRYPTED_MRN`/`ENCRYPTED_ENCOUNTER` (D-24 rule, check both `col_name` and `original_header`); no CLOCK class applies to new files (`docs/s06_column_class.csv` is s06-only: assert 0 new rows match its `sas_name`); else PCNR. For PCNR rows compute `key = lowcase(clean_name(original_header))` with the Phase 4 `%clean_name` rules (copy the 5-line macro or `%include` it from a small shared file; `04_name_map.sas` itself must not be included because it has executable code). Compute the same key for the frozen `pdd.name_map` rows with status PCNR (`cleaned_pre_short` is not stored in `pdd.name_map`: recompute from `original_header`, which is stored). Left join new to frozen on key; the existing `pcnr_name` is reused verbatim. Reuse is by name lookup, never by regenerating (abbreviations in `docs/name_abbrev.csv` may differ now from the Phase 4 run).
**Edge cases to assert:** (a) one key maps to exactly one distinct existing `pcnr_name` (several frozen groups can share a cleaned key when a same-file `_2` duplicate exists; if more than one distinct name, take none and list it as `AMBIGUOUS` PENDING DECISION); (b) a new column whose key matches a frozen row with a non-PCNR status (KEY/LINKAGE_ONLY/EXCLUDED_CLK/DUPLICATE_DROPPED only) is not reused: list it; (c) within a new file two headers with the same key are not expected (computed: 0) but assert (`SAME_FILE_CLEANED_DUPLICATE` rule: later col_order gets a new group, D-01a).
**Source:** `sas/04_name_map.sas` `%build_status` (lines 265-389), `%apply_cleaning`, D-01a.

### Pattern 2: Naming genuinely new columns (MAP-03)
**What:** Only columns that finish the gate as new (no exact match, and DIFFERENT or no candidate) get names. Apply D-02 step 6 and D-03: always-abbreviations, then as_needed longest-first until <= 27 chars (without the `PCNR_` prefix), then `%elide_middle(nm=, target=27)` from `04_name_map_macros.sas`; prefix `PCNR_`. Reuse the Phase 4 abbreviation logic by copying the pass-1/pass-2 loop (lines 777-834) into a macro in the new file, because it is inline in `%form_groups_and_shorten`. Then collision resolution as Stage 1: seed a hash with **all existing final names lowercased (all 1,297 frozen names, including already-suffixed ones)** and treat new groups as later in order (s21..s23); if a candidate base is in the hash, try `_2`, `_3`, ... (re-elide the base to `27 - length(suffix)` first, B7), picking the first unused. Existing names are never changed. Stage 2 hard checks on the whole of `pdd.name_map_ext`: no case-insensitive duplicate PCNR_ name across different groups, none > 32 chars (including prefix), `nvalid(name,'v7')`, no `___`; `%fail_out` on any failure.
**RENAME:** a decision row with `new_name` (same schema as Phase 4, prefix `PCNR_` stripped, <= 27 chars, V7-valid, unique case-insensitively against all final names) overrides the generated name. Needed for naming options in the Braden gate below.
**Truncation collisions (criterion 3):** the Braden names are the only new names that exceed 27 chars (41-char cleaned form; the 6 `rt_..._mins` names in the new files already exist and are reused). The elided forms for 2024 and 2025 differ in the head (`BRADEN_2024_O...` vs `BRADEN_2025_O...`) so they cannot collide with each other, but assert 0 duplicates anyway.

### Pattern 3: Near-match candidates and the human gate (MAP-02)
**Candidate set (union, all pairs cross-file by construction):**
1. D-06 detector re-run between each new PCNR group and every frozen PCNR group: `complev(lowcase(a),lowcase(b)) <= 2` (with `abs(length diff) <= 2` prefilter), or trailing `_\d+|_dup\d*` suffix equality in either direction. Reuse the SQL of `section9_nearmatches` (lines 1578-1637). Run only for new groups not exact-matched. Do **not** apply the 200-pair fail threshold blindly: the expected count is small (<< 200); keep it as a sanity stop.
2. Curated pairs from `docs/new_source_header_variants.csv` (needed because the detector provably misses `BRADEN_2024_OUT_Braden_*` vs `Braden_*` and `preop_edu_years` vs `Education`).
3. **Exact matches with a type change or a known semantic hazard** are listed for review but NOT blocked: MAP-01 makes exact matches reuse automatically. These are `Death_Days_After_Surgery` and the five frailty components (`Feels_Exausted`, `Low_Physical_Activity`, `Slow_Walking_Speed`, `Unintended_Weight_Loss`, `Week_Grip_Strength`). They match same-named old columns that are Char (len 1-3) in s14/s15/s17, while the new Num columns resemble the `_Value` Num columns in s09/s12. The variable gets `result_type = C` / `type_conflict = Y` per D-07 (PDD-D-02). Put them on a TYPE_CONFLICTS sheet with distributions so Gerard can confirm meaning (or issue a DIFFERENT later); the gate list for them is informational, default = reuse (the requirement).
**Gate mechanics (extend D-06 workflow):** SAS writes `pdd.qc_map_ext_candidates` and exchange CSV with columns `pair_id, s_code_new, header_new, col_order_new, group/pcnr_name_old, s_codes_old, header_old, match_type (EDIT_DISTANCE|TRAILING_SUFFIX|VARIANTS_FILE), proposed_name_if_different, status`. A pair is decided when `docs/name_map_decisions_new.csv` has a SAME or DIFFERENT row covering the new column (match by (s_code, col_order) when given, else lowcase header; same matching code as Phase 4 B3). SAME: the new column joins the existing group and takes its `pcnr_name`. DIFFERENT: new group, named by Pattern 2. **Undecided:** `status='PENDING_DECISION'`, `pcnr_name` blank, no name generated (only the `proposed_name_if_different` shown on the review sheet), and `%put NOTE: PENDING DECISION n undecided` plus a count. Recommended enforcement: Phase 16 programs finish (outputs written) with a NOTE and a non-zero `n_pending_decision` in `pdd.name_map_vars_ext` metadata; Phase 18's preconditions hard-stop on `n_pending_decision > 0`. (Phase 4 used the same "phase not complete while undecided" semantics.) SAME is forbidden between two columns of the same s_code (B5 guard) and a SAME decision is never undone by suffixing.
**Do not:** auto-merge any candidate; apply a naming default; write any decision row (Claude does not decide).
**Evidence for the gate (probe/variants file only):**
- `preop_edu_years` (Num 8, 6,377 / 6,787 / 6,750 non-missing, about 30-35 levels) vs `Education` (Char 19 in s03, s06, s07, s09, s10, s12, s13, s16, s19); the older numeric `Edu_Years` also exists (probe: Num 8, s03/s13: 11,361 and 5,114 non-missing). Three-way question for Gerard: SAME as `PCNR_Education`, SAME as `PCNR_Edu_Years`-group, or DIFFERENT. Value distributions needed (Pattern 4).
- Braden `BRADEN_2024_OUT_*` / `BRADEN_2025_OUT_*` vs `Braden_*`: s21 already uses the plain header; a DIFFERENT choice leaves 2024/2025 cases missing the plain Braden variables and creates six one-year variables.
- `Fraility_Score` / `Fraility_Category` vs `Frailty_*`; `SleepApnea_YN` vs `Sleep_Apnea_YN` (s10/s12 use `Sleep_Apnea`).
- Naming sign-off by Price remains PENDING (criterion 5): carry a row in the KEY sheet and `docs/DECISIONS.md` "Carried"; extended names fall under it (already noted in DECISIONS.md).

### Pattern 4: Value distributions side by side (MAP-02)
**What:** Generalise `tools/check_nearmatch_values.sas` (`%nm_check`, which only writes to the log) into a macro writing a dataset: for each candidate side, look up `sas_name` in `pdd.name_map` / `pdd.name_map_ext` by (s_code, col_order), choose the dataset (`pdd.src_sNN` for s01-s20, `pdd.nsrc_s2N` for new), `proc freq ... / missing out=` and keep `side, s_code, header, level (vvalue), n`. If distinct levels <= 30 emit levels with counts (as in `nm_check`); if > 30 emit only summary rows (distinct, n_missing, and for Num: n, min, max; for Char: min/max length). Output `side-by-side` joins on `upcase(level)` with shared / only-in-one counts, mirroring the `shared_values` log line. **Mask counts 1-10 as `<11`** in the exported CSV/xlsx (the workbook goes to reviewers; it stays on P:, and nothing from `qc\`/`exchange\` is pasted into git: `15-SAS-RUN.md` rule). For pairs with different types (Num `preop_edu_years` vs Char `Education`) compare `strip(vvalue(x))` strings and add a numeric-parse flag. Commas inside macro-call arguments are not allowed (CLAUDE.md): pass lists via global macro variables or one macro call per pair via a driving `%do` over a dataset.
**Source:** `tools/check_nearmatch_values.sas`.

### Pattern 5: Year coverage (MAP-04)
**What:** Per (pcnr_name, s_code): first_year, last_year, n_nonmiss (+ optional `years_present` string, because first/last hides gaps such as a variable present in 2018-2022 and 2025 but absent in 2023-2024), then roll up to `pdd.name_map_vars_ext`: `first_year`, `last_year`, `n_sources`, `s_codes_with_data` (alongside the existing `s_codes_contributing`, which is header presence, not data presence), `years_present`.
- **Year source:** new files: own `YEAR` (Num) from `pdd.nsrc_s21..s23`. Old files: `YEAR` of the spine `pdd.src_s09` joined on `norm_psid`. Cases in old sources that are not in the spine (probe: s01 has 274, s18 has 269) get year missing: count them in a `NO_YEAR` bucket, never drop silently. Assumption A3 below. Do not hard-code year ranges: read `min/max` and distinct values at run time (the probe gives level counts, not values).
- **Non-missing definition:** identical to Phase 5 (`sas/05_build_pcnr_macros.sas` ~line 1521): `not missing(x)`, and additionally `upcase(strip(x)) ne 'NULL'` for char columns of type-conflict variables (D-02b). Placeholders (`?`, `YES` in ICD10 codes, etc.) are values and count as non-missing (the PCNR_ layer keeps source values; recoding is out of scope).
- **Implementation:** one DATA step per source dataset: `set src;` (merge with the year lookup via hash or sorted merge), then `array _num _numeric_; array _chr _character_;` declared after `SET`, helper arrays after, accumulating `first/last/n` per variable index into arrays, output one row per variable at `end`. Do not use `RETAIN` with length specs; no `CALL EXECUTE` (Phase 3 convention: FILE + `%include` for generated code). Restrict to columns whose (s_code, col_name) have status PCNR in `pdd.name_map_ext` (the 2,747 s06 CLOCK columns are excluded) and skip `norm_psid`. s06 has the most PCNR columns (about 1,240): a single pass over s06 with arrays is fine.
- **Reference:** `pdd.qc_pcnr_provenance` (Phase 5; pcnr_name, s_code, n_nonmissing over spine rows) is the 20-source analogue for contributing files; reconcile `n_nonmiss` totals for s01-s20 against it only where the spine restriction matches (it counts spine rows, MAP-04 counts all source rows): treat differences for s01/s18 as expected, not errors.
- **Reconciliation for Phase 18/DD-04:** MAP-04 is per source file with each source's own `YEAR`. For the 142 shared s22 x s23 cases YEAR differs (s23 has its own YEAR), so s23's coverage includes its own year for those rows; PDD-D-30 stacking happens in Phase 18, so Phase 18 should recompute first/last from the combined dataset and compare to this table.

### Anti-Patterns to Avoid
- **Rerunning or editing `04_name_map.sas`** or any existing program: breaks the 4795 assertion and "names keep their meaning". Not wired into `99_run_all` Phase 4.
- **Writing to `pdd.name_map`, `pdd.name_map_vars`, `docs/name_map_decisions.csv`, `docs/name_abbrev.csv`:** Phase 5/6/7 read these; changing abbreviations changes Phase 4 reproducibility. If a new abbreviation is truly needed, prefer a RENAME decision in the new decisions file; if an abbreviation is added, mark it `as_needed` only after checking no frozen name would change (it cannot change frozen names because they are looked up, but a Phase 4 rerun would).
- **Applying the D-06 detector alone:** it misses the Braden and `preop_edu_years` pairs.
- **Silently reusing exact matches that conflict in type:** list them (TYPE_CONFLICTS) even though MAP-01 reuses them.
- **Giving `PENDING_DECISION` columns provisional PCNR_ names in the dataset:** Phase 18 could then build variables Gerard has not approved.
- **Probe unit numbers as s-codes**, printing data values to the log beyond the capped `nm_check` pattern, and committing any count 1-10.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Header cleaning | New regex rules | The Phase 4 `%clean_name` steps (replace non-alnum runs with `_`, strip `_`, `N_` prefix, keep case) | Locked D-02; must reproduce frozen cleaning to match keys |
| Middle elision | New truncation | `%elide_middle` in `sas/04_name_map_macros.sas` | Locked D-03; handles `__` join and COM/COPY prefixes |
| Abbreviation passes | New abbreviation scheme | Copy the pass-1 (always) / pass-2 (as_needed, longest-first) loop from `%form_groups_and_shorten`; read `docs/name_abbrev.csv` | Same token-boundary rules |
| Near-match detection | New similarity metric | `complev` + suffix SQL from `section9_nearmatches` | D-06 is the approved definition |
| Decision matching/validation | New matcher | B3/B4/B5 logic from `04_name_map_macros.sas` (`%_check_rename_targets`, existence/header checks, same-file guard); note `%_apply_same_closure` reads `work._group_assign`/`_same_dec`, so feed it the same work tables | tested in `sas/04_decisions_test.sas` |
| Value-set comparison | New profiler | `tools/check_nearmatch_values.sas` pattern (`proc freq` + case-insensitive shared values) | Established, privacy-capped |
| Workbook styling and `read_csv`/`assert_input`/`verify_workbook` | New openpyxl styling | `python/pdd/xlsx_style.py`, `name_map_workbook.py`, `new_source_qc_workbook.py` (`mask_small_count`) | KEY leftmost, UF colors, `<11` masking exist |

**Key insight:** every piece of logic already exists in Phase 4; the work is a lookup-first extension that preserves existing names, plus one new computation (year coverage) and one new human gate.

## Runtime State Inventory

Not a rename/refactor, but the frozen-map rule makes stored state central:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `pdd.name_map` (4,795), `pdd.name_map_vars` (1,297), `pdd.pcnr` (41,150 x 1,297 PCNR_ + NORM_PSID), `pdd.prf_pcnr`, `pdd.qc_pcnr_provenance`, `exchange\name_map*.csv`: all on P: | No edit. Phase 16 reads only; writes new `*_ext` datasets. Assert row counts at start. |
| Live service config | None - verified: no external service holds these names | none |
| OS-registered state | None - verified: no scheduled task depends on the names | none |
| Secrets/env vars | None for naming. (`PDD_APPROVE_NEW_BASELINE` is Phase 15.) | none |
| Build artifacts | `docs/name_abbrev.csv` and `docs/name_map_decisions.csv` are inputs to a Phase 4 rerun | leave unchanged |

## Common Pitfalls

### Pitfall 1: Regenerating old names instead of looking them up
**What goes wrong:** Recomputing PCNR_ names for exact matches from the current `name_abbrev.csv` yields a name different from the Phase 4 name (e.g. `ICD10 Principal Diagnosis POA` exists in s15/s17 and is >27 chars cleaned, so its stored name is abbreviated/elided; `rt_RM_START_to_*_mins` likewise).
**How to avoid:** join on cleaned header key to the stored `pcnr_name`; assert 0 changed names between `pdd.name_map` and the frozen part of `pdd.name_map_ext` (full compare on (s_code, col_order, pcnr_name)).
**Warning signs:** any difference in the frozen-vs-ext compare.

### Pitfall 2: Exact match to a non-PCNR old row or to several groups
**What goes wrong:** the new `PRECEDE Study ID` matches old KEY rows, `ENCRYPTED_*` match LINKAGE_ONLY rows; same-file `_2` duplicates make one cleaned key map to two names.
**How to avoid:** status first (Pattern 1), then lookup against PCNR-status frozen rows only; assert one name per key; list `AMBIGUOUS`.

### Pitfall 3: Existing name collisions after prefix/suffix
**What goes wrong:** a new base name equals an existing already-suffixed name (e.g. `Foo_2` existing from a collision, new header `Foo_2`).
**How to avoid:** hash seeded with all 1,297 existing final names (case-insensitive), pick next unused suffix; final Stage 2 check across the whole 5,077-row table.

### Pitfall 4: Truncation / 32-char SAS names
**What goes wrong:** the new Braden sas_names are already truncated to 32 (`BRADEN_2024_OUT_Braden_Sensory_P`), and a PCNR_ name over 32 is invalid V7 length. Keys must be built from `original_header` (full, 41 chars), not `sas_name`; dataset column references (coverage, values) must use `sas_name`.
**How to avoid:** use `orig_col_name`/`original_header` for naming, `sas_name` for data access; Stage 2 asserts <= 32 including prefix and <= 27 without.

### Pitfall 5: Decisions file shared with Phase 4
**What goes wrong:** s22/s23 rows in `docs/name_map_decisions.csv` make a later Phase 4 run fail (B3, nonexistent s_code in `pdd.import_spec`).
**How to avoid:** separate `docs/name_map_decisions_new.csv`; add a static test that `name_map_decisions.csv` has no s21-s23 rows.

### Pitfall 6: Year coverage definition traps
**What goes wrong:** (a) s08/s20 `YEAR` are Char 9 (non-numeric parse); (b) old sources without `YEAR` give missing years; (c) non-spine IDs (s01 274, s18 269) have no spine year; (d) first/last hides gaps; (e) counting `NULL`/blank as data.
**How to avoid:** spine year lookup via `norm_psid`, `NO_YEAR` bucket reported, `years_present`, Phase 5 non-missing definition; assert `n_nonmiss(by year) + n_nonmiss(NO_YEAR) = n_nonmiss(total)` per (pcnr_name, s_code).

### Pitfall 7: Semantic false friends among exact matches
**What goes wrong:** `Feels_Exausted` etc. match by header to Char columns in s14/s15/s17 while the new Num columns correspond to the `_Value` columns; automatic reuse merges possibly different measures, and `Death_Days_After_Surgery` is Num in old, Char in new.
**How to avoid:** MAP-01 reuse stands, but list them with distributions (TYPE_CONFLICTS), set `type_conflict=Y`, `result_type=C`; Gerard may later add DIFFERENT. Phase 18 must apply PDD-D-02 type conversion.

### Pitfall 8: Privacy
**What goes wrong:** levels and counts copied into git; counts 1-10 shown.
**How to avoid:** mask `<11`; keep value sheets in `qc\` on P:; bring back only masked summaries (privacy-safe text like `logs\new_source_qc_summary.txt`).

## Code Examples

Patterns from this repo (SAS cannot run here; MEDIUM confidence until Gerard's run).

### Exact-match lookup against the frozen map
```sas
/* Source: pattern from sas/04_name_map.sas apply_cleaning and D-01a; lookup-first extension is new */
data work._old_keys;
  set pdd.name_map (where=(status = 'PCNR' and strip(pcnr_name) ne ''));
  length key $200;
  %clean_name(raw=original_header, out=key);
  key = lowcase(key);
  keep key pcnr_name;
run;
proc sql noprint;
  create table work._old_key_names as
  select key, min(pcnr_name) as pcnr_name length=200, count(distinct pcnr_name) as n_names
  from work._old_keys group by key;
quit;
```
Then join the new PCNR rows (`key` computed the same way from `original_header`); `n_names > 1` rows go to `AMBIGUOUS`.

### Hash seeded with every existing final name (extend-only collision rule)
```sas
/* Source: pattern from stage1_suffix (lines 942-981); seeding from the frozen names is new */
data work._ext_names;
  if _N_ = 1 then do;
    declare hash _used();
    _used.defineKey('_k');
    _used.defineDone();
    do until (_eof);
      set work._old_final_names end=_eof;   /* one row per existing pcnr_name without PCNR_ */
      _k = lowcase(strip(name_nop));
      _used.replace();
    end;
  end;
  set work._new_groups;                      /* ordered s21..s23, then col_order */
  /* try base, then base_2, base_3 ... with %elide_middle target = 27 - length(suffix) */
run;
```

### Candidate detection across old and new (D-06 reuse)
```sas
/* Source: sas/04_name_map.sas section9_nearmatches lines 1594-1636 */
proc sql noprint;
  create table work._cand_edit as
  select n.group_id as grp_new, o.pcnr_name as pcnr_old, n.key as key_new, o.key as key_old,
         complev(n.key, o.key) as edit_dist, 'EDIT_DISTANCE' as match_type length=20
  from work._new_open as n, work._old_keys_d as o
  where abs(length(n.key) - length(o.key)) <= 2
    and complev(n.key, o.key) <= 2
    and n.key ne o.key;
quit;
```
(No `??`, no ANSI-only syntax: C1/C2.)

### Coverage accumulation (one source dataset)
```sas
/* Source: Phase 5 non-missing rule (05_build_pcnr_macros.sas ~1521); array pattern per CLAUDE.md pitfalls */
data work._cov_s21 (keep=var_name first_year last_year n_nonmiss);
  set pdd.nsrc_s21 end=_eof;
  array _n[*] _numeric_;
  array _c[*] _character_;
  /* helper arrays AFTER the arrays above */
  array _nf[1000] _temporary_;  /* sized from a macro variable set from dictionary.columns */
  /* for each var: if nonmissing then update first/last/n using YEAR */
run;
```

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 4 builds the map from `pdd.import_spec` (20 files, 4,795 rows) | Frozen map + parallel extension for s21-s23 | 2026-11-16 (v2.0) | `04_name_map.sas` unchanged; Phase 18 consumes `pdd.name_map_ext` |
| 1,299 PCNR_ names in the brief | 1,297 PCNR_ variables after D-24 (ENCRYPTED_* LINKAGE_ONLY) | 2026-10 | Assert 1,297, not 1,299 |
| Near-match gate only on edit distance / suffix | Plus curated variants file | v2.0 | catches year-prefix and rename-and-type cases |

**Deprecated/outdated:** MILESTONE_BRIEF's "existing 1,299 PCNR_ names" (superseded by REQUIREMENTS/ROADMAP wording); the brief's probe overlap claim (superseded).

## Open Questions

1. **Actual stored PCNR_ names and the 1,297 count**
   - Known: ROADMAP/STATE say 1,297; `pdd.name_map` is on P:.
   - Unclear: exact names, so the exact-reuse predictions (about 87) are MEDIUM.
   - Recommendation: Phase 16 SAS asserts counts first; `PENDING SAS RUN`.
2. **Decisions on the 10 candidates (and the type-conflict exact matches)**
   - `PENDING DECISION` for Gerard; options and evidence are in Pattern 3. Naming of any DIFFERENT result (especially the Braden 2024/2025 names, which would otherwise be elided) is also Gerard's; Price sign-off remains pending.
3. **Year values and s08/s20 vs s09 YEAR agreement**
   - Probe shows level counts only. Recommendation: runtime derivation (Pattern 5); if a QC comparison of s08/s20 `YEAR` vs spine is wanted, it is a counts-only SAS check in 16b, not a probe request.
4. **Whether `n_pending_decision > 0` should hard-stop Phase 16**
   - Recommended: NOTE + outputs, hard stop in Phase 18. Planner may choose `%fail_out` after writing QC (Phase 15 style); either keeps "no auto choice".
5. **Does Phase 18 need `pdd.name_map_ext` or merged `pdd.name_map`?**
   - Out of scope here; Phase 16 guarantees `pdd.name_map_ext` has the same columns as `pdd.name_map` plus `map_class`, `matched_pcnr_name`, `decision_ref`, so Phase 18 can read either shape.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| SAS 9.4 (UTF-8 cfg) | all `sas/16*.sas` runs | No (this machine); Gerard's machine yes | n/a | none: steps end `PENDING SAS RUN` |
| P: drive (`pdd` library) | frozen map, `pdd.src_s01..s20`, `pdd.nsrc_s21..s23` | No (this machine) | n/a | none |
| Phase 15 SAS reruns (15c, `run_pipeline.cmd 15`) | `pdd.nsrc_s21..s23`, type-change CSV | Not yet done | n/a | blocks 16b value distributions and coverage; 16a (names) needs only the committed spec and the frozen map |
| `.venv` Python | ruff, pytest, writers | Yes (per Phase 15 research) | 3.14.2 | n/a |
| `sasjs` CLI | lint gate | Not probed here | n/a | `tools\sas_lint.py` is pure Python; report if `sasjs` absent |

**Missing dependencies with no fallback:** SAS, P:, and the 15c rerun output (by design; mark `PENDING SAS RUN`).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Static: `tools\sas_lint.py`, `sasjs lint`. Python: pytest 8.3.3, ruff 0.7.1. Runtime: SAS log assertions and `%fail_out` as Phases 2-5, scanned with `tools\check_test_log.ps1`. |
| Config file | `python/conftest.py`; no pytest.ini seen |
| Quick run command | `python tools\sas_lint.py sas\16a_name_map_ext.sas` (repeat per file); `.venv\Scripts\python.exe -m pytest python\tests\test_phase16_static.py -x` |
| Full suite command | `sasjs lint`, `ruff check python\`, `.venv\Scripts\python.exe -m pytest python\tests` |

Headless limit: nothing that reads real data runs here. Validation here = static lint, Python tests on committed metadata (`docs/*.csv`) and synthetic fixtures, plus logs/QC files returned from Gerard's SAS runs checked against the assertions below.

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAP-01 | 16a looks up stored names (reads `pdd.name_map`), never writes `pdd.name_map`/`pdd.name_map_vars`, does not `%include` `04_name_map.sas` | static | `pytest python\tests\test_phase16_static.py::test_frozen_map_untouched -x` (greps SAS text) + `sas_lint` | No, Wave 0 |
| MAP-01 | Offline expectation: the 282 spec rows classify into KEY/LINKAGE/exact/candidate using committed spec only; every non-exact header is listed in `new_source_header_variants.csv` | unit | `pytest python\tests\test_phase16_expectations.py -x` (reimplement D-02 cleaning; compares with `docs/import_spec_generated.csv` minus s04/s05/CLOCK) | No, Wave 0 |
| MAP-01 | Runtime: frozen-vs-ext compare 0 diffs; ext rows = 5,077; 1,297 frozen names | log/QC | Gerard's 16a log NOTEs | After SAS run |
| MAP-02 | `docs/name_map_decisions_new.csv` has the 11-column header; no s21-s23 rows in `docs/name_map_decisions.csv`; no decision rows written by Claude | static | `pytest ...::test_decisions_new_header`, `::test_no_new_codes_in_phase4_decisions` | No, Wave 0 |
| MAP-02 | Gate: undecided candidates have blank `pcnr_name` and status `PENDING_DECISION`; value sheets mask 1-10 as `<11` | unit | `pytest python\tests\test_name_map_ext_workbook.py -x` (synthetic CSVs; KEY leftmost; UF colors; `<11`) | No, Wave 0 |
| MAP-03 | 0 duplicate (case-insensitive), 0 > 32 chars, 0 `___`, V7-valid across all 5,077 rows; new names never equal frozen names | log/QC | 16a Stage 2 NOTEs + `qc_map_ext_collisions` | After SAS run |
| MAP-03 | Elision/suffix logic on a synthetic spec | SAS test | `sas/16_name_map_ext_test.sas` standalone (synthetic, no P: data), PASS/FAIL per case as `sas/04_decisions_test.sas` | No, Wave 0 (written here, run by Gerard) |
| MAP-04 | Coverage table: every PCNR variable has first_year <= last_year or `NO_DATA`; per-source n reconciles incl. `NO_YEAR` bucket | log/QC | 16b log NOTEs; exchange `name_map_coverage.csv` row count = distinct (pcnr_name, s_code) | After SAS run |
| MAP-04 | Writer renders coverage and sources columns | unit | `pytest python\tests\test_name_map_ext_workbook.py` | No, Wave 0 |
| Criterion 5 | Price sign-off still listed as pending (KEY sheet text, STATE.md, DECISIONS.md) | static | `pytest ...::test_price_signoff_pending` (greps `docs/DECISIONS.md` and the writer's KEY text) | No, Wave 0 |
| All | No data values or small counts in committed files | static | scan new `docs/*.csv` and `.planning/` outputs for numeric cells 1-10 where a count column exists | No, Wave 0 |

### Sampling Rate
- **Per task commit:** `python tools\sas_lint.py sas\<file>.sas`, `sasjs lint`; for Python edits `ruff check python\` and `pytest python\tests`.
- **Per wave merge:** full suite above.
- **Phase gate:** static gates green here, plus Gerard's returned logs and masked summaries showing zero ERROR/WARNING, 5,077 rows, 0 changed frozen names, 0 collisions and `n_pending_decision` stated, before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `python/tests/test_phase16_static.py` - SAS text checks (frozen map untouched, no `04_name_map.sas` include, decisions files, Price pending).
- [ ] `python/tests/test_phase16_expectations.py` - offline classification of 282 spec rows.
- [ ] `python/tests/test_name_map_ext_workbook.py` - writer tests with synthetic CSVs.
- [ ] `docs/name_map_decisions_new.csv` (header-only) and `docs/exchange_schema.csv` rows for new exchange CSVs.
- [ ] `sas/16_name_map_ext_test.sas` synthetic test (optional but recommended; Gerard runs).
- Framework install: none.

### Files Gerard brings back (PENDING SAS RUN)
Logs `16a_name_map_ext.log`, `16b_name_map_values_cov.log` (ERROR/WARNING lines and NOTE counts), and masked summary text from the Python step. Do not paste lines from `qc\` or `exchange\`; counts 1-10 become `<11`.

## Plan Split Recommendation (for the planner)

| Plan | Wave | Content | Runs headless? |
|------|------|---------|----------------|
| 16-01 | 1 | `docs/name_map_decisions_new.csv` seed, exchange-schema rows, Python writer + workbook + tests (incl. offline expectation test), `99_run_all`/`run_pipeline.cmd` wiring (add `16` to `_valid`, now `2 3 4 5 6 7 15`; `findstr` token `\<16\>`) | Fully verifiable here (ruff, pytest, sas_lint on `99_run_all.sas`) |
| 16-02 | 1 or 2 | `sas/16a_name_map_ext.sas`: status, exact lookup, candidates, naming, Stage 2, final `*_ext` datasets, exchange CSVs | Write + lint here; `PENDING SAS RUN`; gate PENDING DECISION |
| 16-03 | 2 (needs 15c rerun for runtime) | `sas/16b_name_map_values_cov.sas`: side-by-side value distributions, year coverage (MAP-04) | Write + lint here; `PENDING SAS RUN` (needs `pdd.nsrc_s21..s23`) |
| 16-04 | 3 checkpoint | Run sheet `16-SAS-RUN.md` (commands, files to bring back), STATE.md update (Phase 16 `PENDING SAS RUN`, `PENDING DECISION` list, Price sign-off pending); Gerard decisions entered into `docs/name_map_decisions_new.csv` by Gerard, rerun 16a | Docs here; run is Gerard's |

Phase 16 is not closed until Gerard has run 16a/16b, decided every candidate, and `n_pending_decision = 0`.

## Assumptions (headless run)

| # | Assumption | Basis | Risk if wrong |
|---|-----------|-------|---------------|
| A1 | Extension, not rerun: new programs `sas/16a/16b`, new datasets `pdd.name_map_ext`, `pdd.name_map_vars_ext` | Phase 4 hard-codes 4,795 and reads only `pdd.import_spec`; frozen names must keep meaning | Low; Gerard may prefer other names |
| A2 | Separate decisions file `docs/name_map_decisions_new.csv` (11-column Phase 4 schema) | Phase 4 B3 would fail on s21+ rows | Low |
| A3 | Old-source year comes from spine `pdd.src_s09.YEAR` via `norm_psid`; new files use their own `YEAR`; non-spine IDs go to `NO_YEAR` | Probe: only s08/s09/s20 have `YEAR`, s09 complete (41,150) | Medium: if Gerard wants s08/s20 `YEAR` or another definition, change the lookup |
| A4 | Coverage non-missing = Phase 5 rule (`not missing`, plus `NULL` for type-conflict char variables); placeholders count as data | Phase 5 convention, PCNR_ layer keeps source values | Low |
| A5 | Undecided near-matches keep a blank PCNR_ name, status `PENDING_DECISION`; hard stop is in Phase 18 | CLAUDE.md "do not apply a choice"; D-06 "never auto-merge" | Low |
| A6 | Exact header matches reuse the stored name even with a type change; they are listed (TYPE_CONFLICTS), not gated | MAP-01 says exact matches reuse | Medium: Gerard may want these gated |
| A7 | KEY = the case-ID header (`PRECEDE_Study_ID`) and LINKAGE_ONLY = `ENCRYPTED_*` for s21-s23 (no `pdd.key_analysis` rows exist for them) | D-04/D-24 rules applied by header | Low |
| A8 | Predicted counts (about 87 reuse, 10 candidates, 0-10 new) come from a Python reimplementation of D-02 on committed spec CSVs | cannot read `pdd.name_map` | Medium; verified at run time |
| A9 | Value distributions (levels <= 30 with counts, masked `<11`) stay in `qc\` on P:, never git | Privacy rule, Phase 4 precedent | Low |
| A10 | `sasjs lint` availability here was not checked | time | CLAUDE.md requires it; report if absent |

## Sources

### Primary (HIGH confidence; read directly)
- `.planning/ROADMAP.md` (Phase 16), `.planning/REQUIREMENTS.md` (MAP-01..04), `.planning/STATE.md`, `.planning/MILESTONE_BRIEF_2018_2025.md`, `CLAUDE.md`, `docs/DECISIONS.md` (PDD-D-29/30, Price sign-off carried row).
- `.planning/schemas/probe_master_data_20261116.md` (YEAR rows for units 8, 9, 19-21; Education/Edu_Years rows) and `.planning/schemas/overlap_s22_s23_20261116.md`.
- `.planning/phases/04-name-map/04-CONTEXT.md`, `04-PART-B-DECISIONS.md`; `sas/04_name_map.sas` (build_status, apply_cleaning, form_groups_and_shorten, stage1_suffix, section9_nearmatches, 4795 assertion), `sas/04_name_map_macros.sas`, `tools/check_nearmatch_values.sas`.
- `.planning/phases/15-new-source-intake/15-RESEARCH.md`, `15-03-SUMMARY.md`, `15-SAS-RUN.md`.
- `docs/import_spec_new_generated.csv`, `docs/import_spec_generated.csv`, `docs/new_source_header_variants.csv`, `docs/name_map_decisions.csv`, `docs/name_abbrev.csv`, `docs/name_map_schema.csv`, `docs/exchange_schema.csv`, `docs/s06_column_class.csv`.
- `sas/99_run_all.sas` (`_valid`), `sas/05_build_pcnr_macros.sas` (non-missing rule, provenance), `python/pdd/*.py`, `python/scripts/write_name_map_review.py`, `python/requirements.txt`.

### Secondary / Tertiary
- None. No external documentation was needed (no new libraries). SAS behavior claims rest on repo behavior and general SAS knowledge (MEDIUM until Gerard's run).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (no new dependencies).
- Architecture (frozen-map extension, separate decisions file, gate semantics): HIGH for the constraint analysis (read in code), MEDIUM for the recommended design (untestable here).
- Predicted classification counts: MEDIUM (offline reimplementation; actual map on P:).
- Year coverage design: MEDIUM (probe gives only level counts for YEAR; values unknown).
- Pitfalls: HIGH (repo-derived).

**Research date:** 2026-11-16
**Valid until:** 2026-12-16 (invalidated if `pdd.name_map` is rebuilt, `docs/name_abbrev.csv` or the new spec changes, or the probe is rerun)
