# Phase 04 Plan 02 — Summary

**Completed:** 2026-10-21
**File created:** `sas/04_name_map.sas`

## What was built

`sas/04_name_map.sas` — 8-section SAS program (Sections 0–8) implementing the algorithmic core of Phase 4 name mapping.

### Section 0 — Macros (all defined before first call, PCM C13)
- `%fail_out` — hard stop with ERROR log
- `%clean_name(raw=, out=)` — D-02 steps 1–4: trim, replace non-alnum runs, strip leading/trailing `_`, prefix `N_` for digit-start
- `%elide_middle(nm=)` — D-03 middle-elide to fit 27 chars, preserves COM/COPY prefix (min 4 chars before `__`)
- `%assert_rowcount` — generic row-count assertion helper
- `%d08_check` — D-08 duplicate Study ID value comparison (s15/s17)
- `%build_status` — D-04 status assignment + KEY/EXCLUDED_CLK assertions
- `%apply_cleaning` — Section 4 body
- `%apply_decisions_rename` — Section 5 body
- `%form_groups_and_shorten` — Section 6 body
- `%stage1_suffix` — Section 7 body
- `%stage2_validate` — Section 8 body

### Section 1 — Assertions
- Total row count = 4795 in `pdd.import_spec`
- Distinct `(file_code, col_order)` = 4795
- Per-s_code counts match `pdd.header_inventory`
- Logs: `NOTE: [04_name_map] 4795 rows`

### Section 2 — Load inputs
- `work.headers` — import_spec LEFT JOIN header_inventory; fails if any row unmatched
- `work.keyanalysis`, `work.s06class`, `work.decisions`, `work.abbrev`
- `work.abbrev` sorted descending by `length(long)` for longest-first application

### Section 3 — D-08 then status assignment
- D-08: identifies duplicate PSID columns in s15/s17 via `prxmatch('/PRECEDE.Study.ID/i')`; compares values using inline replication of `%pdd_norm_psid` logic; `%fail_out` on any disagreement
- Status assigned via DATA step IF/ELSE (D-04 precedence): DUPLICATE_DROPPED > KEY > LINKAGE_ONLY > EXCLUDED_CLK > PCNR
- Asserts: exactly 1 KEY row per file; s06 EXCLUDED_CLK = 2747
- Logs: `NOTE: [04_name_map] EXCLUDED_CLK=2747`

### Section 4 — D-02 cleaning (PCNR rows only)
- Applies `%clean_name` macro; tracks empty-clean count
- Logs: `NOTE: [04_name_map] 0 empty-clean headers`
- Output: `work.name_map_cleaned` with `cleaned_pre_short`

### Section 5 — Decision RENAME overrides
- Reads `docs/name_map_decisions.csv`; gracefully handles empty file
- Verifies every decision row matches an existing name_map row; `%fail_out` on unmatched
- Applies RENAME decisions to set `pcnr_name_override`

### Section 6 — Group formation and D-03 shortening
- Groups PCNR rows by `lowcase(cleaned_pre_short)` across files; same-file collision rows get new group_id + `_same_file_collision=1` flag
- Applies SAME decisions with same-file-conflict validation
- Abbreviation table applied longest-first via SET POINT loop; hits recorded in `work._abbrev_hits`
- Elide middle (`__`) applied if still > 27 chars
- `pcnr_name_base` assigned per group

### Section 7 — Stage 1 collision suffix
- Orders groups: s01→s20 file order, then col_order
- Assigns `_2`, `_3`… suffixes between groups with same `pcnr_name_base`
- Ensures suffixed name ≤ 27 chars (trims base if needed)
- Writes `pdd.qc_name_map_collisions` (BETWEEN_GROUP_SUFFIX + SAME_FILE_CLEANED_DUPLICATE)
- `pcnr_name = cats('PCNR_', pcnr_name_final)`

### Section 8 — Stage 2 hard-stop
- Case-insensitive duplicate check
- Length > 32 check
- `nvalid(pcnr_name, 'v7')` check
- `%fail_out` on any violation
- Logs: `NOTE: [04_name_map] Stage 2 passed`
- Persists `work.name_map_core`; logs truncated labels (> 256 chars)

## Lint results
- `python tools/sas_lint.py sas/04_name_map.sas` — **0 errors**, 38 warnings (W1/W2 advisory only)
- `sasjs lint find` — **0 errors** for 04_name_map.sas

## PCM compliance
All C1–C14 rules verified: no open-code `%if/%else`, no bare `data;/set;`, no ANSI SQL, no `??` in PROC SQL, no macro called before definition, no `RETAIN` with `$` length specifier.

## Acceptance strings confirmed present
`%macro fail_out`, `%macro clean_name`, `pdd.import_spec`, `pdd.header_inventory`, `pdd.key_analysis`, `s06_column_class`, `4795 rows`, `EXCLUDED_CLK=2747`, `NOTE: D-08`, `0 empty-clean headers`, `Stage 2 passed`, `duplicate_study_id`, `%pdd_norm_psid`, `prxchange`, `cleaned_pre_short`, `qc_name_map_collisions`, `nvalid`, `__`, `abbrev_applied`
