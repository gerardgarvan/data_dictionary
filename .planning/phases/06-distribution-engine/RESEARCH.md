# Phase 6: Distribution Engine — Research

**Researched:** 2026-10-25
**Domain:** SAS macro profiling, PROC MEANS/FREQ, long-format output, PCM compliance
**Confidence:** HIGH (all findings from in-repo source; no external dependency)

---

## Summary

Phase 6 builds `%pdd_profile(lib=, ds=, prefix=, family=)`, a reusable SAS macro that
classifies every variable in a dataset by distinct-value count and computes the appropriate
distribution statistics. Output is a single long-format SAS dataset in the `pdd` library.
Phase 7 reads that dataset and writes it into the dictionary xlsx workbook via Python.

PDD-D-06 is now fully defined in REQUIREMENTS.md (PDD-06 row):
- Character variables or numeric with ≤ 20 distinct levels: count + % per level + missing count
- Numeric with > 20 distinct levels (continuous): N, missing, mean, SD, median, Q1, Q3, min, max
- High-cardinality text (> 20 distinct): N distinct + top-10 by frequency

The macro must run cleanly under all seven PCM compliance rules enforced by sas_lint.py.
The pattern to replicate is `05_build_pcnr_macros.sas` / `05_build_pcnr.sas`: all macros
defined before any call (C13), DATA _NULL_ FILE= for generated code (no CALL EXECUTE),
`%fail_out` for hard stops, `%assert_rowcount` for QC.

**Primary recommendation:** Implement classification with a PROC SQL scan of DICTIONARY.COLUMNS
plus a per-variable PROC FREQ or PROC MEANS pass driven by a DATA _NULL_ FILE= generated
include file. Collect results into one long-format accumulator via PROC APPEND. Export exchange
CSVs for Python Phase 7 writer.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

No CONTEXT.md exists for Phase 6 yet. All constraints come from REQUIREMENTS.md,
ROADMAP.md, CLAUDE.md, and upstream phase artifacts.

### Locked Decisions
- PDD-D-22 LOCKED: SAS owns data computation; Python owns xlsx output.
- PCM compliance rules C1–C3, C9, C11, C13, C14 enforced by sas_lint.py and sasjs lint.
- Generated code pattern: DATA _NULL_ FILE= writes .sas files; %include loads them (no CALL EXECUTE).
- All macros in one file (06_profile_macros.sas); orchestrator in 06_profile.sas.
- Wire Phase 6 into sas/99_run_all.sas under a Phase 6 guard (currently commented-out block exists at lines 337–342).
- pdd library path and macro variable conventions inherit from 00_config.sas (%pdd_lib, &exchange_path, &logs_path, &sas_path).
- No macros/subdirectory exists; macro file goes in sas/ alongside other phase files.

### Claude's Discretion
- Exact classification thresholds (≤ 20 for low-card, > 20 for continuous numeric) — confirmed by PDD-D-06 definition.
- Long-format output table name and column names (must be specified here; Phase 7 will lock them).
- Whether to generate per-variable PROC FREQ/MEANS code via DATA _NULL_ FILE= or drive
  a single PROC FREQ with BY group (both are compliant; generated-include is the established pattern).

### Deferred Ideas (OUT OF SCOPE)
- Recoding or cleaning PCNR_ values (deferred to Phase 13 / PCND_).
- CLK_, LAB_, MED_, INTRA_ family profiling (Phases 9–12).
- Cohort restriction (all 41,150 spine patients profiled as-is).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDD-06-R01 | `%pdd_profile(lib=, ds=, prefix=, family=)` callable by any family | Macro signature defined; all parameters resolve at call time |
| PDD-06-R02 | Classify by distinct-value count per PDD-D-06 | Three tiers: ≤20 distinct → frequency table; numeric >20 → summary stats; high-card char → top-10 |
| PDD-06-R03 | Output: long-format profile table (variable, stat/level, value, n, pct) in pdd library | Table schema defined below |
| PDD-06-R04 | Validation: sex and Patient_Type counts match PROC FREQ; missing counts exact | Acceptance test pattern mirrors Phase 5 assert_rowcount |
</phase_requirements>

---

## Q1: What does PDD-D-06 mean?

**Finding (HIGH confidence — direct from REQUIREMENTS.md PDD-06 row):**

PDD-D-06 is now fully specified:

| Variable class | Condition | Statistics |
|---|---|---|
| Low-card (any type) | ≤ 20 distinct non-missing values | count + % per level; plus one "MISSING" row with n and % |
| Continuous numeric | numeric AND > 20 distinct non-missing values | N, N_missing, mean, SD, median, Q1, Q3, min, max |
| High-card character | character AND > 20 distinct non-missing values | N_distinct, plus top-10 levels by frequency (n, pct each) |

Missing % denominator: total rows in the dataset (41,150 for pdd.pcnr).

---

## Q2: What variables exist in pdd.pcnr?

**Finding (HIGH confidence — from pdd.name_map_vars, asserted in Phase 5):**

- 1,299 PCNR_ columns + NORM_PSID key, 41,150 rows.
- Schema in `pdd.name_map_vars` (1,299 rows): columns `pcnr_name`, `group_id`,
  `result_type` ($1: 'C'|'N'), `max_length`, `type_conflict` ($1: 'Y'|'N'),
  `n_sources`, `s_codes_contributing`.
- `result_type` gives the nominal type; 9 variables have `type_conflict='Y'`
  (resolved in Phase 5 to N8 or C).
- Confirmed variables for acceptance test: `Sex` maps to a PCNR_ name (character,
  likely low-card); `Patient_Type` similarly.
- To find exact PCNR_ names for Sex and Patient_Type at runtime: query
  `pdd.name_map where original_header like '%Sex%'` etc., or read
  `docs/import_spec_generated.csv` (Sex confirmed C $8 in s03).

**Implication for %pdd_profile:** macro must read classification metadata at runtime
from DICTIONARY.COLUMNS (actual storage type and distinct count), not from name_map_vars,
because type_conflict resolution may have changed storage type.

---

## Q3: Classification scheme for distinct-value count

**Recommended scheme (HIGH confidence — matches PDD-D-06 exactly):**

```
Step 1. For each variable in &lib..&ds:
        a. Read storage type (C or N) from DICTIONARY.COLUMNS.
        b. Run PROC SQL to count distinct non-missing values → &_ndist.
        c. Assign class:
             LOW_CARD  if &_ndist <= 20
             CONT_NUM  if storage=N and &_ndist > 20
             HIGH_CARD if storage=C and &_ndist > 20
```

Boundary rule: a variable with 0 non-missing values (all missing) → LOW_CARD with 0 levels;
the "MISSING" row still records n=total rows, pct=100.

Do NOT classify by name_map_vars result_type; use actual DICTIONARY.COLUMNS type so the
macro works for any family, not just PCNR_.

---

## Q4: Long-format output table schema

**Recommended schema for `pdd.prf_&family` (or a generic `pdd.profile_&family`):**

| Column | Type | Length | Description |
|--------|------|--------|-------------|
| family | $32 | $32 | e.g. 'PCNR' |
| variable | $200 | $200 | e.g. 'PCNR_SEX' |
| var_class | $12 | $12 | 'LOW_CARD' / 'CONT_NUM' / 'HIGH_CARD' |
| stat | $40 | $40 | Level value for LOW_CARD/HIGH_CARD; stat name for CONT_NUM (e.g. 'MEAN') |
| n | 8 | 8 | Count for this row |
| pct | 8 | 8 | Percent (0–100, 2 decimal places) |
| sort_order | 8 | 8 | Display sort within variable (1=first level, 99=MISSING row) |

The `stat` column doubles as the level label for frequency rows and as the statistic
name for continuous rows. Phase 7 Python writer discriminates by `var_class`.

**Acceptance test variables and expected column names:**
- Look up pcnr_name for Sex: query `pdd.name_map where upcase(original_header)='SEX'`
  and `status='PCNR'` to get the exact PCNR_ name at runtime.
- Same for Patient_Type.

**Exchange CSV:** write `exchange\profile_&family..csv` (long-format, same columns)
so Phase 7 Python writer reads it without touching the pdd library directly
(follows Phase 5 exchange pattern).

---

## Q5: How does Phase 7 consume the profile output?

**Finding (HIGH confidence — from REQUIREMENTS.md PDD-07 and pcnr_qc_workbook.py pattern):**

Phase 7 spec (REQUIREMENTS.md lines 117–130):
- SAS `07_build_profile.sas` writes distribution data to pdd library.
- Python `python\scripts\write_dictionary.py` writes the xlsx workbook.
- PCNR_ sheet: variables listed alphabetically; distribution inline next to each variable.
- Sheet order: KEY | PCNR_ | NAME_MAP | SOURCES | QC.

**What Phase 7 needs from Phase 6:**
1. Long-format profile table in pdd library (one row per variable × stat/level).
2. Exchange CSV at `exchange\profile_pcnr.csv` (or `profile_&family..csv`).
3. Column names must be stable before Phase 7 plans (lock them in this phase).

**Pattern match with Phase 5 Python writer:**
- `pcnr_qc_workbook.py` reads CSVs from `exchange\`; validates required columns;
  writes sheets via `write_table` + `style_sheet` from `xlsx_style.py`.
- Phase 6 should produce the exchange CSV; Phase 7 Python writer reads it with
  the same `read_csv` → `write_table` pattern.

---

## Q6: Phase 5 QC patterns to follow

**Finding (HIGH confidence — from pcnr_qc_workbook.py and 05_build_pcnr_macros.sas):**

| Pattern | Phase 5 Implementation | Phase 6 Replication |
|---|---|---|
| Exchange CSVs | PROC EXPORT to `&exchange_path.\pcnr_*.csv` | PROC EXPORT to `&exchange_path.\profile_&family..csv` |
| Hard stop | `%fail_out(msg=...)` / `%abort cancel` | Same macro, same convention |
| Row count assert | `%assert_rowcount(ds=, expected=, label=)` | Define `%p6_assert` or reuse pattern |
| Section guards | `%_p5_ok(section=)` | `%_p6_ok(section=)` |
| Log routing | `%route_log` / `%restore_log` checking `&in_pipeline` | Same |
| Per-section NOTE | `%put NOTE: [05_build_pcnr] ...` | `%put NOTE: [06_profile] ...` |
| Generated code | DATA _NULL_ FILE= + %include | Same — generate per-variable PROC FREQ/MEANS calls |
| Standalone guard | `%if &in_pipeline = 0 %then` | Same |

**No CALL EXECUTE.** The established pattern generates a .sas file with a DATA step that
writes code lines, then `%include`s that file.

---

## Q7: Macro patterns from 05_build_pcnr_macros.sas to replicate

**Key patterns (HIGH confidence — directly read from source):**

### Hash object for lookup
```sas
/* Source: sas/05_build_pcnr_macros.sas lines 788-795 */
if _n_ = 1 then do;
  declare hash htr(dataset: 'work._type_resolution');
  htr.definekey('pcnr_name');
  htr.definedata('resolved_type', 'out_length');
  htr.definedone();
end;
```
Use for: loading DICTIONARY.COLUMNS metadata into a hash for fast per-variable lookup.

### PROC SQL count into macro variable
```sas
/* Source: sas/05_build_pcnr_macros.sas line 69 */
proc sql noprint;
  select count(*) into :_arc_n trimmed from &ds;
quit;
```

### PROC APPEND accumulator
```sas
/* Source: sas/05_build_pcnr_macros.sas line 443 */
proc append base=work._spine_coverage data=work._cov_row force; run;
```
Use for: accumulating one profile row per variable per stat/level.

### Loop over variables from DICTIONARY.COLUMNS
Phase 5 uses `firstobs=&_i obs=&_i` in PROC SQL to iterate. For 1,299 variables this
is expensive (1,299 queries). Better pattern for Phase 6: load all variable metadata
into a work dataset once, then loop with macro variable arrays built by PROC SQL +
`into :var1-:var999 separated by ...`.

**Scalable loop pattern:**
```sas
/* Load variable list once */
proc sql noprint;
  create table work._p6_vars as
  select name, type, length
  from dictionary.columns
  where libname = upcase("&lib")
    and memname = upcase("&ds")
    and upcase(name) ne 'NORM_PSID'
  order by name;
  select count(*) into :_p6_nv trimmed from work._p6_vars;
quit;

/* Store names in macro vars via call symputx in DATA step */
data _null_;
  set work._p6_vars;
  call symputx(cats('_p6v_', _n_), strip(name), 'L');
  call symputx(cats('_p6t_', _n_), strip(type), 'L');
run;
```
Then `%do _i = 1 %to &_p6_nv;` with `&&_p6v_&_i`.

### Generated include file
```sas
/* Source: sas/05_build_pcnr_macros.sas line 772 */
data _null_;
  file "&logs_path.\06_generated_profile.sas" encoding='utf-8';
  put '/* generated by %p6_generate_freq_code */';
  ...
run;
%include "&logs_path.\06_generated_profile.sas";
```

---

## Q8: Existing profile-related Python code

**Finding (HIGH confidence — ls + read of python/pdd/):**

No profile-related Python code exists yet. Existing modules:
- `python/pdd/__init__.py` — empty init
- `python/pdd/config.py` — path configuration
- `python/pdd/name_map_workbook.py` — Phase 4 workbook
- `python/pdd/pcnr_qc_workbook.py` — Phase 5 QC workbook
- `python/pdd/s06_workbook.py` — Phase 3 s06 workbook
- `python/pdd/xlsx_style.py` — shared styling (write_table, style_sheet, UF colors)

Phase 6 SAS produces the exchange CSV. Phase 7 Python (`write_dictionary.py`) will read it.
Phase 6 itself needs no Python code — Phase 7 owns the xlsx output (D-22).

---

## Architecture Patterns

### Recommended Project Structure

```
sas/
├── 06_profile_macros.sas   # All %macro definitions (Section 0)
├── 06_profile.sas          # Orchestrator: %include macros, then call them
logs/  (P: drive)
├── 06_generated_freq.sas   # Generated PROC FREQ code (per-family pass)
exchange/  (P: drive)
├── profile_pcnr.csv        # Long-format profile for Phase 7
```

### Pattern: Three-tier classification

```
Section 0 (macros file):
  %macro fail_out / %_p6_ok / %route_log / %restore_log / %assert_rowcount
  %macro p6_preflight       -- assert pdd.pcnr 41,150 rows, 1,297+1 cols (D-24: was 1,299)
  %macro p6_classify_vars   -- build work._p6_vars with n_distinct, var_class
  %macro p6_freq_lowcard    -- PROC FREQ for LOW_CARD vars (≤20 distinct)
  %macro p6_stats_contnum   -- PROC MEANS for CONT_NUM vars (>20 distinct, numeric)
  %macro p6_freq_highcard   -- PROC FREQ + keep top 10 for HIGH_CARD char vars
  %macro p6_write_output    -- assemble pdd.profile_&family + exchange CSV
  %macro pdd_profile        -- entry-point macro; calls above in order

Section 1 (orchestrator):
  %pdd_profile(lib=pdd, ds=pcnr, prefix=PCNR_, family=PCNR)
```

### Anti-Patterns to Avoid

- **CALL EXECUTE:** banned by project pattern; use DATA _NULL_ FILE= + %include.
- **Open-code %if/%else:** all conditional logic inside %macro/%mend (C3).
- **Bare data;/set;:** always name the dataset (C14).
- **Per-variable PROC FREQ in a macro loop for 1,299 variables:** 1,299 separate
  PROC steps is slow; batch variables into one generated include file.
- **Hardcoding variable names:** classification must work for any family (CLK_, LAB_, etc.).
- **PROC SQL OFFSET/FETCH/ROW_NUMBER OVER:** banned (C2).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Distinct count per variable | Custom DATA step hash | `PROC SQL count(distinct &var)` | Correct handling of missing |
| Summary statistics | Manual calculation | `PROC MEANS n nmiss mean std median q1 q3 min max` | Exact and efficient |
| Frequency table | Manual sort + count | `PROC FREQ` with ODS OUTPUT CellFreqs | Handles character and numeric, exact |
| Type metadata | Parsing macro variable lists | `DICTIONARY.COLUMNS` in PROC SQL | Authoritative storage type |
| Accumulator pattern | Re-writing whole dataset | `PROC APPEND base= data= force` | Same pattern as Phase 5 |

---

## Common Pitfalls

### Pitfall 1: PROC FREQ output dataset structure
**What goes wrong:** ODS OUTPUT creates different table names in different SAS versions.
**Why it happens:** PROC FREQ with `/ out=` on the TABLE statement is more stable.
**How to avoid:** Use `PROC FREQ; TABLE &var / out=work._freq_out(keep=&var count percent) missing; run;`
rather than ODS OUTPUT. The OUT= dataset always has `COUNT` and `PERCENT` columns.
**Warning signs:** Missing `percent` or `count` variable in the generated dataset.

### Pitfall 2: Missing values in PROC FREQ
**What goes wrong:** By default PROC FREQ excludes missing values from the table and from %.
**Why it happens:** Default behavior; denominator is non-missing N.
**How to avoid:** Use the `MISSING` option on the TABLE statement. This includes a "." or blank
row in the output. Then use total N (including missing) as denominator for pct computation.
The `PERCENT` column from PROC FREQ with `MISSING` uses total-N denominator automatically.
**Warning signs:** Missing count in output doesn't match `nmiss` from PROC MEANS.

### Pitfall 3: 1,299-variable loop performance
**What goes wrong:** 1,299 separate PROC SQL distinct-count queries may run slowly.
**Why it happens:** One query per variable in a macro loop.
**How to avoid:** Generate a single pass: for CONT_NUM use one PROC MEANS with a VAR
statement listing all numeric vars (one step, all stats in one pass). For LOW_CARD character
and numeric vars, generate one .sas file with multiple TABLE statements in one PROC FREQ
(or batched across several).
**Warning signs:** Phase 6 taking > 10 minutes on pdd.pcnr.

### Pitfall 4: C3 violation — open-code %if
**What goes wrong:** sas_lint.py flags any `%if` or `%else` outside `%macro/%mend`.
**Why it happens:** Forgetting that orchestrator sections cannot have naked conditionals.
**How to avoid:** All conditional logic in macros. The orchestrator (06_profile.sas)
calls macros only; no open-code %if.

### Pitfall 5: C13 violation — macro called before definition
**What goes wrong:** Lint fails if `%pdd_profile` is called before it is `%macro`-defined.
**Why it happens:** Splitting macros across files without %include order discipline.
**How to avoid:** 06_profile.sas must `%include` 06_profile_macros.sas in Section 0
before any macro call, mirroring `05_build_pcnr.sas` pattern exactly.

### Pitfall 6: pct denominator mismatch
**What goes wrong:** Acceptance test fails because pct uses non-missing N, not total N.
**Why it happens:** PROC FREQ without `MISSING` option uses non-missing N.
**How to avoid:** Always use the `MISSING` option. Recalculate pct manually if needed:
`pct = (count / &_total_n) * 100` where `&_total_n` is total rows (e.g., 41,150).

---

## 99_run_all.sas Integration

The Phase 6 block already exists at lines 337–342 as a commented block:
```sas
/*
%put NOTE: ---- Phase 6: %pdd_profile distribution engine -------------;
%include "&sas_path.\06_profile.sas";
%put NOTE: ---- Phase 6 complete --------------------------------------;
*/
```

This must be uncommented and wrapped inside `%_run_phases` under a `%if %_phase_in(6) %then %do;`
guard matching the Phase 3–5 pattern. Also add `6` to `%let _valid = 2 3 4 5 6 7;` (already present,
line 243). The `%_check_pipeline_ok(phase=6)` guard must precede the `%if` block.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | SAS macro test (tests/06_profile_test.sas) — matches Phase 5 pattern |
| Config file | none — standalone SAS script |
| Quick run command | `sas -sysin "C:\data_dictionary\tests\06_profile_test.sas"` |
| Full suite command | same |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Notes |
|--------|----------|-----------|-------|
| PDD-06-R01 | Macro callable with all 4 params | unit | Call with lib=work ds=_test_ds prefix=T_ family=TEST |
| PDD-06-R02 | Three-tier classification fires correctly | unit | Synthetic dataset: one binary var, one high-card num, one high-card char |
| PDD-06-R03 | Long-format table has correct columns | unit | PROC CONTENTS + column-name assert |
| PDD-06-R04 | Sex and Patient_Type counts match PROC FREQ | integration | Run on pdd.pcnr; compare pdd.profile_pcnr to PROC FREQ output |

### Acceptance criterion (from ROADMAP.md)
Run `%pdd_profile(lib=pdd, ds=pcnr, prefix=PCNR_, family=PCNR)` and assert:
1. Sex variable level counts in pdd.profile_pcnr match `proc freq data=pdd.pcnr; table PCNR_SEX / missing; run;`
2. Patient_Type variable level counts match the same
3. Missing counts for both variables match `nmiss` from `proc means data=pdd.pcnr nmiss; var ...; run;`

---

## Environment Availability

Step 2.6: SKIPPED — Phase 6 is SAS-only computation. No external tools beyond SAS 9.4 (already
confirmed available from prior phases). Python is not invoked in Phase 6 (D-22: Phase 7 owns xlsx).

---

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| CALL EXECUTE for dynamic code | DATA _NULL_ FILE= + %include | Established pattern in this repo — do not deviate |
| Hardcoded variable names | Runtime metadata from DICTIONARY.COLUMNS | Macro reusable across all families |
| Separate PROC steps per variable | Batched generated code in one include | Performance on 1,299 vars |

---

## Open Questions

1. **Exact PCNR_ name for Sex and Patient_Type**
   - What we know: `Sex` appears in s03 as `Sex` ($8); `Patient_Type` likely maps to a PCNR_ name.
   - What's unclear: exact pcnr_name values (depend on Phase 4 name-map run output).
   - Recommendation: acceptance test queries `pdd.name_map where upcase(strip(original_header)) in ('SEX','PATIENT_TYPE')` at runtime rather than hardcoding.

2. **Output table naming: `pdd.profile_pcnr` vs `pdd.prf_pcnr`**
   - What we know: no convention set yet; Phase 7 plan doesn't exist.
   - What's unclear: whether Phase 7 will want a fixed prefix or use `&family` parameter.
   - Recommendation: use `pdd.prf_&family` (short, no collision with src_* or qc_* naming conventions).

3. **Batch size for generated PROC FREQ code**
   - What we know: 1,299 TABLE statements in one PROC FREQ may hit SAS line-length or memory limits.
   - Recommendation: batch into groups of 100 variables per PROC FREQ call (generates ~13 PROC steps).

4. **Phase 6 guard in 99_run_all.sas**
   - The existing `%_run_phases` macro ends at line 331 before the Phase 6 block.
   - Phase 6 must move inside `%_run_phases` to participate in `pdd_phases_done` tracking and
     `%_check_pipeline_ok`. This is a small but non-obvious structural change needed in the plan.

---

## Sources

### Primary (HIGH confidence)
- `C:\data_dictionary\.planning\REQUIREMENTS.md` — PDD-D-06 definition (lines 103–114)
- `C:\data_dictionary\.planning\ROADMAP.md` — Phase 6 done-when criterion
- `C:\data_dictionary\sas\05_build_pcnr_macros.sas` — macro patterns to replicate
- `C:\data_dictionary\sas\05_build_pcnr.sas` — orchestrator structure
- `C:\data_dictionary\sas\99_run_all.sas` — Phase 6 integration point (lines 337–342)
- `C:\data_dictionary\python\pdd\pcnr_qc_workbook.py` — exchange CSV / Python writer pattern
- `C:\data_dictionary\python\pdd\xlsx_style.py` — write_table, style_sheet conventions
- `C:\data_dictionary\docs\import_spec_generated.csv` — variable types for pdd.pcnr variables

### Secondary (MEDIUM confidence)
- SAS PROC FREQ documentation (OUT= dataset columns COUNT, PERCENT, MISSING option) — standard SAS 9.4 behavior, confirmed by project usage in Phase 3 s06 profile (03-02-SUMMARY.md reference to PROC MEANS nmiss).

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all SAS built-ins; no new dependencies
- Architecture: HIGH — directly derived from Phase 5 patterns in repo
- Pitfalls: HIGH — PCM rules enforced by linter; PROC FREQ missing-option behavior is documented SAS 9.4 behavior
- PDD-D-06 definition: HIGH — found verbatim in REQUIREMENTS.md

**Research date:** 2026-10-25
**Valid until:** Until Phase 7 locks the exchange CSV schema (then update column names if needed)
