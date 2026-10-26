# Phase 6: Distribution Engine — Context

**Gathered:** 2026-10-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Build `%pdd_profile(lib=, ds=, prefix=, family=)` — a reusable SAS macro that classifies every
variable in a dataset by distinct-value count, computes the appropriate distribution statistics,
and writes the result to a long-format SAS dataset in the `pdd` library plus an exchange CSV.

Phase 6 is SAS-only. No Python code. Phase 7 owns xlsx output (D-22).

Out of scope: recoding/cleaning values (PCND_, Phase 13+), other family profiling (Phases 9–12),
cohort restriction.

</domain>

<decisions>
## Implementation Decisions

### Output Table Naming
- **D-01:** Output table named `pdd.prf_&family` (e.g., `pdd.prf_pcnr`). Short; matches `src_*`/`qc_*`
  abbreviation style. Generalizes cleanly across all seven families.

### Percent Denominator — Two Columns Required
- **D-02:** Exchange CSV and pdd table carry two percent columns per row:
  - `pct_total` — `n / total_rows * 100` where `total_rows` = row count of `&lib..&ds` (41,150 for pdd.pcnr).
    All levels + OTHER + MISSING rows for a variable sum to 100%.
  - `pct_nonmiss` — `n / n_nonmiss * 100`. Blank (missing, `.`) on the MISSING row.
- PROC FREQ `MISSING` option is used so SAS includes the missing row; `pct_total` is then
  recalculated manually using total_rows, overriding PROC FREQ's PERCENT column.

### HIGH_CARD Sort Order
- **D-03:** For HIGH_CARD character variables (char, >20 distinct), rows appear in this order:
  1. `sort_order = 0` — N_distinct summary row (`stat = 'N_DISTINCT'`, `n` = count of distinct non-missing values, `pct_total` and `pct_nonmiss` both missing/null)
  2. `sort_order = 1..10` — Top-10 levels by frequency descending
  3. `sort_order = 11` — OTHER row (`stat = 'OTHER'`, `n` = sum of all remaining non-missing levels not in top-10)
  4. `sort_order = 99` — MISSING row (`stat = 'MISSING'`, `pct_nonmiss` = `.`)
- OTHER row `n` + top-10 `n` values + MISSING `n` must reconcile to total_rows (assertion D-08).

### Small-Cell Flag
- **D-04:** Every level row (LOW_CARD levels, HIGH_CARD top-10, OTHER, MISSING) carries
  `small_cell_flag` ($1): `'Y'` if `n < 11`, `'N'` otherwise. Phase 6 sets the flag only;
  no suppression or masking in Phase 6. Phase 7 owns display decisions.

### Variable Exclusions
- **D-05:** Two variable categories are excluded from profiling (not written to `pdd.prf_&family`):
  1. `NORM_PSID` — join key, not a substantive variable.
  2. Variables with `status = 'LINKAGE_ONLY'` in `pdd.name_map` (D-24: ENCRYPTED_MRN,
     ENCRYPTED_ENCOUNTER). At runtime, macro queries `pdd.name_map` to build the exclusion list
     for the current family. If `pdd.name_map` is unavailable (e.g., non-PCNR family call),
     only `NORM_PSID` is excluded and a NOTE is written to the log.

### Date/Datetime/Time Variables — DATE Tier
- **D-06:** Numeric variables whose SAS format resolves to a date/datetime/time category
  receive `var_class = 'DATE'` (fourth tier, in addition to LOW_CARD, CONT_NUM, HIGH_CARD).
  Classification precedence: DATE check runs before LOW_CARD/CONT_NUM split.
  - Detection: check `format` column from `DICTIONARY.COLUMNS`; if format name matches
    `DATE*`, `DATETIME*`, `TIME*`, `YYMMDD*`, `MMDDYY*`, `DDMMYY*`, `JULIAN*`, `MONYY*`,
    `WORDDATX*`, `WEEKDATE*` (case-insensitive prefix match) → DATE tier.
  - Name-pattern fallback: if format is blank AND variable name matches `*_DATE` or `*_DTTM`
    (case-insensitive) → DATE tier.
  - Statistics: same nine as CONT_NUM (N, N_missing, mean, SD, median, Q1, Q3, min, max)
    but `stat` suffix is appended with the variable's format name so Phase 7 can apply
    `PUT(value, format.)` for display. Column `display_format` ($32) added to the table
    schema (blank for non-DATE rows).
  - DATE variables with ≤20 distinct non-missing values still receive DATE tier (not LOW_CARD),
    because date counts have a different interpretive meaning than categorical counts.

### 100% Missing Variables
- **D-07:** Variables where every row is missing are still profiled. Output: a single MISSING row
  with `n = total_rows`, `pct_total = 100`, `pct_nonmiss = .`, `sort_order = 99`. No other rows.
  `var_class` is assigned by storage type: LOW_CARD for any type (0 non-missing distinct values
  satisfies ≤ 20 threshold), except DATE-format numerics which stay DATE.

### Reconciliation Assertion
- **D-08:** After generating all rows for a variable, assert:
  `sum(n for all rows where stat != 'N_DISTINCT') = total_rows`.
  Hard stop (`%fail_out`) if assertion fails for any variable. This catches denominator errors
  before they reach Phase 7.

### Claude's Discretion
- Internal macro structure: section guards (`%_p6_ok`), log routing, generated include file
  location (`&logs_path.\06_generated_freq.sas`), batch size for PROC FREQ TABLE statements
  (recommend ~100 per PROC step to avoid SAS line-length limits).
- Whether `p6_classify_vars` uses a single PROC SQL for all distinct counts or a generated
  DATA _NULL_ loop. Either is compliant; research recommends a single work dataset load from
  DICTIONARY.COLUMNS then DATA _NULL_ call symputx loop.
- Acceptance test variable lookup: query `pdd.name_map` at runtime rather than hardcoding
  PCNR_SEX or PCNR_PATIENT_TYPE.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and Design Decisions
- `.planning/REQUIREMENTS.md` §PDD-06 (lines 103–114) — full PDD-D-06 classification spec
- `.planning/PROJECT.md` §Locked decisions — D-22 (SAS/Python split), D-24 (LINKAGE_ONLY exclusion), D-05 (overlap rule)
- `.planning/ROADMAP.md` — Phase 6 done-when criterion and acceptance test definition

### Phase 5 Patterns to Replicate
- `sas/05_build_pcnr_macros.sas` — hash lookup, PROC APPEND accumulator, PROC SQL count pattern, generated include pattern
- `sas/05_build_pcnr.sas` — orchestrator structure: %include macros first, then call; section guards; log routing

### Integration Point
- `sas/99_run_all.sas` lines 337–342 — commented Phase 6 block; must be moved inside `%_run_phases` and uncommented

### Phase 7 Consumer
- `.planning/REQUIREMENTS.md` §PDD-07 (lines 117–130) — what Phase 7 needs from the exchange CSV

### Python Writer Pattern (for exchange CSV column naming consistency)
- `python/pdd/pcnr_qc_workbook.py` — how Phase 5 exchange CSVs are read and validated
- `python/pdd/xlsx_style.py` — write_table, style_sheet conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `%fail_out`, `%assert_rowcount`, `%route_log`, `%restore_log`, `%_p5_ok` — in `05_build_pcnr_macros.sas`; replicate as `%_p6_ok` etc. in `06_profile_macros.sas`
- `%pdd_norm_psid` — in `sas/00_config.sas`; Phase 6 does not call it but must %include 00_config.sas as all phases do
- `pdd.name_map` — queried at runtime for LINKAGE_ONLY exclusion list (D-05)
- `docs/import_spec_generated.csv` — variable type reference if needed offline

### Established Patterns
- All macros defined in `*_macros.sas`; orchestrator `*_profile.sas` %includes macros in Section 0 before any call (C13)
- Generated code: DATA _NULL_ FILE= writes .sas; %include executes it. No CALL EXECUTE anywhere.
- PROC APPEND accumulator: `base=work._accumulator data=work._one_row force`
- Hard stop: `%fail_out(msg=...)` / `%abort cancel`
- Section guard: `%macro %_p6_ok(section=); %if &_p6_status = 0 %then %do; ... %end; %mend;`
- Log routing: `%route_log` / `%restore_log` checking `&in_pipeline`
- Per-section NOTE: `%put NOTE: [06_profile] ...`

### Integration Points
- `sas/99_run_all.sas`: Phase 6 block at lines 337–342 must move inside `%_run_phases` macro,
  wrapped with `%if %_phase_in(6) %then %do;` guard; add `6` to `%let _valid = 2 3 4 5 6 7;` (line 243).
- `%_check_pipeline_ok(phase=6)` guard must precede the `%if` block (matches Phase 3–5 pattern).
- Exchange CSV written to `&exchange_path.\profile_pcnr.csv` (Phase 7 reads it).

</code_context>

<specifics>
## Specific Requirements (from discussion)

### Long-Format Table Schema for `pdd.prf_&family`

| Column | Type | Length | Description |
|--------|------|--------|-------------|
| family | $32 | | e.g. 'PCNR' |
| variable | $200 | | e.g. 'PCNR_SEX' |
| var_class | $12 | | 'LOW_CARD' / 'CONT_NUM' / 'HIGH_CARD' / 'DATE' |
| stat | $40 | | Level value for LOW_CARD/HIGH_CARD; stat name for CONT_NUM/DATE (e.g. 'MEAN'); 'MISSING', 'OTHER', 'N_DISTINCT' |
| n | 8 | | Count for this row |
| pct_total | 8 | | n / total_rows * 100 (blank on N_DISTINCT row) |
| pct_nonmiss | 8 | | n / n_nonmiss * 100 (blank on MISSING and N_DISTINCT rows) |
| sort_order | 8 | | Display sort within variable (0 = N_DISTINCT, 1–10 = top levels, 11 = OTHER, 99 = MISSING, 1–N for LOW_CARD levels) |
| small_cell_flag | $1 | | 'Y' if n < 11, 'N' otherwise (blank on N_DISTINCT row) |
| display_format | $32 | | SAS format name for DATE tier variables; blank for all other tiers |

Exchange CSV `exchange\profile_pcnr.csv` carries identical columns (UTF-8, no index, PROC EXPORT).

### Validation / Acceptance Test
- Run `%pdd_profile(lib=pdd, ds=pcnr, prefix=PCNR_, family=PCNR)`
- Assert `pdd.prf_pcnr` exists with expected column schema
- For PCNR_SEX: level counts match `proc freq data=pdd.pcnr; table PCNR_SEX / missing; run;`
- For PCNR_PATIENT_TYPE (or equivalent): same
- Missing counts for both match `nmiss` from `proc means data=pdd.pcnr nmiss;`
- For every variable: `sum(n where stat != 'N_DISTINCT') = 41,150` (D-08 reconciliation)
- `small_cell_flag = 'Y'` on every row where `n < 11`
- NORM_PSID and LINKAGE_ONLY variables absent from `pdd.prf_pcnr`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 06-distribution-engine*
*Context gathered: 2026-10-26*
