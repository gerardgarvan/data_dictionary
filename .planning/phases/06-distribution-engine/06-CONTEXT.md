# Phase 6: Distribution Engine — Context

**Gathered:** 2026-10-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Build `%pdd_profile(lib=, ds=, prefix=, family=, outlib=, export=1, require_name_map=1)` — a reusable SAS macro that classifies every
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
  `small_cell_flag` ($1): `'Y'` if `1 <= n <= 10`, `'N'` otherwise. Empty MISSING rows
  (n=0) are **not** flagged ('N'). Blank on N_DISTINCT and all STAT rows.
  Phase 6 sets the flag only; no suppression or masking in Phase 6. Phase 7 owns display decisions.

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
- **D-07:** Variables where every row is missing are still profiled regardless of var_class
  (LOW_CARD, CONT_NUM, DATE, HIGH_CARD — though HIGH_CARD requires >=21 distinct non-missing
  so D-07 effectively only applies to LOW_CARD/CONT_NUM/DATE in practice).
  Output: exactly one row: stat='MISSING', n=&_p6_total, pct_total=100, pct_nonmiss=.,
  sort_order=99, small_cell_flag per D-04. var_class/date_kind/display_format kept from classifier.
  Branch BEFORE PROC MEANS so all-missing numeric variables never reach it.

### Reconciliation Assertion (class-specific)
- **D-08:** After generating all rows, assert per variable (hard stop via %p6_fail_out):
  - **LOW_CARD:** `sum(n where stat in ('LEVEL','MISSING')) = &_p6_total`
  - **HIGH_CARD:** `sum(n where stat in ('LEVEL','OTHER','MISSING')) = &_p6_total`;
    count(LEVEL rows) = 10; N_DISTINCT n = classifier n_distinct
  - **CONT_NUM/DATE:** `n(N) + n(N_MISSING) = &_p6_total`
  - **SUPPRESSED:** `n(N) + n(MISSING) = &_p6_total`
  - **NUM_TEXT:** `n(N) + n(N_MISSING) + n(N_UNPARSED) = &_p6_total`
  - **D-07 variables (any class):** single MISSING row with n = &_p6_total
  Adding MEAN/SD/MIN/MAX etc. into the sum would incorrectly fail every numeric variable;
  reconciliation is therefore class-specific, not a blanket row sum.

### Value Suppression (D-09)
- **D-09 (decided 2026-10-26):** Certain variables must be suppressed (no LEVEL rows) to protect PII
  or avoid misleading distributions for free-text fields.
- `suppress_file=` parameter added to `%pdd_profile` (default blank = no suppression).
  When provided, `docs/profile_suppress.csv` (columns: `variable`, `reason`) is loaded via PROC IMPORT.
- Engine hard-fails (via `%p6_fail_out`) if any listed variable is absent from the dataset.
- Suppressed variables receive `var_class = 'SUPPRESSED'` (overrides classifier output).
- Suppressed variables emit exactly 5 stat rows (`level` always blank):
  - `N_DISTINCT` (sort_order=0): distinct count from classifier
  - `RANGE_MIN` (sort_order=1): if numeric type OR ≥95% of non-missing values parse as numeric via
    `input(strip(v), ?? best32.) ne .` → value = numeric minimum; else value = minimum char length
    and `display_format = 'LENGTH'`
  - `RANGE_MAX` (sort_order=2): corresponding maximum (numeric or char length)
  - `N` (sort_order=3): non-missing count
  - `MISSING` (sort_order=99): missing count
- No LEVEL rows. `level` column blank on all suppressed rows.
- Seed file `docs/profile_suppress.csv` lists 10 PCNR variables:
  PCNR_SORT_ID, PCNR_aim3_enroll_id (IDs); PCNR_prc_aim1_2_notes,
  PCNR_prc_aim1_2_nurse_notes, PCNR_prc_aim1_2_ph__l_limitation,
  PCNR_Edu_Clock_notes (free text); PCNR_examiner, PCNR_pecan_trainee (staff names);
  PCNR_test_date, PCNR_preop_date (date small cells).

### Numeric Text Detection (D-10)
- **D-10 (decided 2026-10-26):** HIGH_CARD char variables that are predominantly numeric strings
  (e.g., entered measurements, coded responses stored as text) are reclassified to `NUM_TEXT`
  so Phase 7 can display numeric statistics instead of a truncated frequency table.
- `num_text_threshold=0.95` parameter added to `%pdd_profile`.
- For each HIGH_CARD char variable (after classification), one DATA step pass counts:
  - `n_nonmiss`: `strip(v) ne ''`
  - `n_placeholder`: `upcase(strip(v)) in ('NULL','N/A','NA','?','UNKNOWN','.','-')`
  - `n_parse`: `input(strip(v), ?? best32.) ne .` (SAS DATA step; `??` suppresses NOTE)
  - `n_unparsed = n_nonmiss - n_parse`
- If `n_parse / (n_nonmiss - n_placeholder) >= &num_text_threshold` → `var_class = 'NUM_TEXT'`
- NUM_TEXT stat rows:
  - `N` (sort_order=3): parsed count
  - `N_MISSING` (sort_order=4): blank count
  - `N_UNPARSED` (sort_order=5): n_unparsed (includes placeholders)
  - `MEAN SD MEDIAN Q1 Q3 MIN MAX` (sort_order 6-12): via PROC MEANS stackodsoutput on parsed values
  - Up to 5 `LEVEL` rows (sort_order 20-24): most frequent unparsed values; small_cell_flag applies
- Below threshold: stays HIGH_CARD; `%put NOTE` with variable and parse rate.
- Log summary: count of NUM_TEXT vars and near-misses (80–95%).

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

### Long-Format Table Schema for `pdd.prf_&family` (LOCKED, 13 columns)

| # | Column | Type | Length | Description |
|---|--------|------|--------|-------------|
| 1 | family | $32 | 32 | e.g. 'PCNR' (uppercased) |
| 2 | variable | $32 | 32 | e.g. 'PCNR_SEX' |
| 3 | var_class | $12 | 12 | 'LOW_CARD' / 'CONT_NUM' / 'HIGH_CARD' / 'DATE' / 'SUPPRESSED' (D-09) / 'NUM_TEXT' (D-10) |
| 4 | stat | $12 | 12 | Row type identifier only (never category text): LEVEL / MISSING / OTHER / N_DISTINCT / N / N_MISSING / MEAN / SD / MEDIAN / Q1 / Q3 / MIN / MAX / RANGE_MIN (D-09) / RANGE_MAX (D-09) / N_UNPARSED (D-10) |
| 5 | level | $&_p6_lvl_len | max(64, max char var length), capped 32767 | Category text on LEVEL rows only; blank elsewhere. Char = strip(value); numeric = strip(put(v,best32.)) |
| 6 | n | 8 | 8 | Count on LEVEL/MISSING/OTHER/N_DISTINCT/N/N_MISSING rows; blank (.) on MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX rows |
| 7 | value | 8 | 8 | Statistic on MEAN/SD/MEDIAN/Q1/Q3/MIN/MAX rows; blank (.) on count rows |
| 8 | pct_total | 8 | 8 | n / total_rows * 100 on LEVEL/OTHER/MISSING/N/N_MISSING rows; blank on N_DISTINCT and STAT rows |
| 9 | pct_nonmiss | 8 | 8 | n / n_nonmiss * 100 on LEVEL and OTHER rows only; blank on MISSING / N_DISTINCT / all STAT rows |
| 10 | sort_order | 8 | 8 | LOW_CARD: 1..k by n desc level asc, 99=MISSING. HIGH_CARD: 0=N_DISTINCT, 1..10=top levels, 11=OTHER, 99=MISSING. CONT_NUM/DATE: N=1 N_MISSING=2 MEAN=3 SD=4 MEDIAN=5 Q1=6 Q3=7 MIN=8 MAX=9 |
| 11 | small_cell_flag | $1 | 1 | 'Y' if 1<=n<=10, 'N' otherwise on LEVEL/OTHER/MISSING rows; blank on N_DISTINCT and all STAT rows |
| 12 | date_kind | $8 | 8 | 'DATE' / 'DATETIME' / 'TIME' on DATE-class rows; blank elsewhere |
| 13 | display_format | $32 | 32 | SAS format name for DATE tier variables; blank for all other tiers. Phase 7 must NOT apply display_format to SD rows (SD is a duration in days/seconds) |

Exchange CSV `exchange\profile_pcnr.csv` carries identical columns in the same order (UTF-8, PROC EXPORT).

### Macro Signature (full)
```
%pdd_profile(lib=, ds=, prefix=, family=, outlib=, export=1, require_name_map=1,
             suppress_file=, num_text_threshold=0.95)
```
- `outlib=` — libref to publish `prf_&family` to (default blank = &lib at runtime; not self-referential in macro definition)
- `export=1` — write `&exchange_path.\profile_&family..csv` (UTF-8); `export=0` skips CSV (test isolation)
- `require_name_map=1` — enforce &lib..name_map for D-05 exclusion
- `suppress_file=` — path to CSV listing variable,reason pairs for D-09 suppression (blank = disabled)
- `num_text_threshold=0.95` — parse rate threshold for D-10 NUM_TEXT reclassification

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
