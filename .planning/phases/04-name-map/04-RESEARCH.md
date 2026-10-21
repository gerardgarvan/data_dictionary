# Phase 4: Name Map — Research

**Researched:** 2026-10-21
**Domain:** SAS name cleaning / collision resolution / Python xlsx output (PDD pipeline)
**Confidence:** HIGH — all decisions locked in CONTEXT.md; codebase patterns confirmed from source

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01** — NAME_MAP grain: one row per (s_code, col_order). PK = (s_code, col_order). Assert 4,795 rows at start. Source: pdd.import_spec (has col_order); pdd.header_inventory has NO col_order column — join header_inventory on (s_code, col_name=sas_name) to retrieve original_header_trunc only.
- **D-01a** — Same-variable rule: equal cleaned names (case-insensitive) across files = same variable, one PCNR_ name. Same-file cleaned-name collision = separate variable, suffix _2.
- **D-01b** — Processing order: (1) assign statuses, (2) clean+shorten, (3) apply decisions.csv overrides, (4) form variable groups, (5) collision suffix between groups, (6) Stage 2 hard-stop validation.
- **D-02** — Name cleaning: trim → replace non-alnum runs with _ → strip leading/trailing _ → prefix N_ if digit-start → keep case → abbreviate if >27 chars after PCNR_ → prefix PCNR_.
- **D-03** — Name shortening: abbreviation table first (`docs/name_abbrev.csv`), then elide middle with __ if still too long; never drop COM/COPY prefix; full name goes to LABEL.
- **D-04** — Status taxonomy and precedence: DUPLICATE_DROPPED > KEY > LINKAGE_ONLY > EXCLUDED_CLK > PCNR. Exactly one KEY row per file with PRECEDE_STUDY_ID in pdd.key_analysis. EXCLUDED_CLK count for s06 must equal 2,747.
- **D-05** — Collision resolution: Stage 1 auto-suffix _2/_3… between groups; all pairs to pdd.qc_name_map_collisions; Stage 2 %fail_out if any case-insensitive dup, >32 chars, or invalid V7 name after Stage 1.
- **D-06** — Near-match detection: cross-file pairs differing by trailing suffix or edit distance ≤ 2; never auto-merged; >200 pairs → %fail_out; ≤200 → export CSV → Python sheet → Gerard resolves via docs/name_map_decisions.csv; phase not complete while undecided pairs remain.
- **D-07** — Type tracking: sas_type and length from pdd.import_spec per row; name_map_vars gets result_type (C wins), max_length, type_conflict flag.
- **D-08** — Duplicate Study ID (s15, s17): compare after normalisation in Plan 02 Section 3, BEFORE any cleaning or grouping. %fail_out on any disagreement; mark DUPLICATE_DROPPED on full agreement. DUPLICATE_DROPPED is final before Section 4 (cleaning) runs.
- **D-09** — Output files: pdd.name_map, pdd.name_map_vars, pdd.qc_name_map_collisions; exchange CSVs; Python writes qc\name_map_review.xlsx (6 sheets); docs/name_map_decisions.csv and docs/name_abbrev.csv committed to git.
- **D-10** — Done criteria: 4,795 rows with status; no dup/invalid PCNR_ names; zero undecided near-matches; decisions.csv integrity check; SAS row counts = Python sheet row counts; labels = full original header; Gerard review; Price naming approval.
- **D-21 LOCKED** — s06 class=CLOCK (2,747 rows) → status=EXCLUDED_CLK, blank PCNR_ name; DIGITAL_OTHER (809) + PCNR (431) → PCNR_ candidates. Gate clear (UNSURE=0 confirmed 2026-10-20).
- **D-22 LOCKED** — SAS owns data and CSV export; Python owns xlsx output.
- **PDD-D-18** — s04/s05 → LINKAGE_ONLY status.
- **options validvarname=v7** already set in 00_config.sas.

### Claude's Discretion

None — all major decisions locked.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 4 scope.
</user_constraints>

---

## Summary

Phase 4 builds `04_name_map.sas` plus `python/scripts/write_name_map_review.py`. The SAS program reads `pdd.header_inventory` (4,795 rows), assigns statuses (D-04 precedence), cleans and shortens names (D-02/D-03), applies override CSVs, forms variable groups, resolves collisions in two stages (D-05), detects near-matches (D-06), tracks types (D-07), and exports exchange CSVs. The Python script reads those CSVs and writes `qc\name_map_review.xlsx` with 6 sheets using the established `write_table` / `xlsx_style.py` pattern from the D-22 pilot.

The algorithmic complexity is entirely in the SAS half: group formation, two-stage collision logic, Levenshtein near-match, and multiple hard-stop assertions. The Python half follows the pilot script exactly — read CSVs, assert row counts, write sheets, verify workbook.

All decisions are locked; planning has no discretion areas to research. The main planning risk is implementing D-01b processing order correctly — status must be assigned before cleaning, and collision suffixing happens after group formation, not before.

**Primary recommendation:** Structure 04_name_map.sas with numbered sections mirroring D-01b step order. Implement Levenshtein in a SAS macro using a DO-loop DP table (no CALL EXECUTE, PCM-compliant). Wire into 99_run_all.sas after Phase 3.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SAS Base (00_config.sas) | — | Data processing, %fail_out, %pdd_lib | Established pipeline pattern |
| `pdd.header_inventory` | Phase 2 output | Input: 4,795 rows to map | Authoritative source |
| `pdd.import_spec` | Phase 3 output | sas_type / length per (file × column) | Type tracking D-07 |
| `pdd.key_analysis` | Phase 2 output | Identify KEY rows (key_column_type='PRECEDE_STUDY_ID') | D-04 KEY status |
| `docs/s06_column_class.csv` | repo | CLOCK/PCNR/DIGITAL_OTHER classification | D-21 LOCKED |
| `docs/name_map_decisions.csv` | repo (may be empty) | SAME/DIFFERENT/RENAME overrides | D-06, D-05 |
| `docs/name_abbrev.csv` | repo | Abbreviation table for shortening | D-03 |
| openpyxl | installed (Phase 3 pilot used it) | Python xlsx writing | D-22, established |
| `python/pdd/xlsx_style.py` | repo | UF colors, write_table, freeze/autofit | D-22 pilot pattern |

### No New Dependencies

Phase 4 requires nothing not already installed. Python package (`python/pdd/`) and openpyxl are confirmed present from D-22 pilot.

---

## Architecture Patterns

### Recommended SAS Program Structure

```
sas/04_name_map.sas
  Section 0  — %include 00_config.sas, %pdd_lib, %fail_out definition
  Section 1  — Assertions: 4,795 rows in header_inventory, unique on (s_code, col_order)
  Section 2  — Load inputs: header_inventory + import_spec + key_analysis + s06_column_class.csv
               + name_map_decisions.csv + name_abbrev.csv
  Section 3  — Assign status (D-04 precedence order)
               Assert: exactly one KEY per file with PRECEDE_STUDY_ID
               Assert: s06 EXCLUDED_CLK count = 2,747
  Section 4  — Clean and shorten names (D-02 steps 1-6, then PCNR_ prefix) for PCNR rows
               Apply abbreviation table (D-03 step 1)
               Apply elide-middle if still too long (D-03 step 2)
  Section 5  — Apply name_map_decisions.csv overrides (SAME / DIFFERENT / RENAME)
  Section 6  — Form variable groups: D-01a case-insensitive match + SAME decisions
  Section 7  — Stage 1 collision suffix between groups (D-05); write pdd.qc_name_map_collisions
  Section 8  — Stage 2 hard-stop validation (D-05): dup/length/V7 → %fail_out
  Section 9  — Near-match detection (D-06): compute pairs, print count, %fail_out if >200,
               export exchange\name_map_nearmatches.csv
  Section 10 — D-08: duplicate Study ID check (s15/s17 normalised comparison)
  Section 11 — Type tracking (D-07): join import_spec, compute result_type / max_length / type_conflict
               Log type-conflict variables
  Section 12 — Build pdd.name_map_vars (one row per PCNR_ variable)
  Section 13 — D-10 integrity checks: decisions.csv cross-reference
  Section 14 — Export exchange CSVs (name_map, name_map_vars, name_map_collisions,
               name_map_nearmatches, name_abbrev_applied)
  Section 15 — Wire into 99_run_all.sas (add %include after Phase 3)
```

```
python/scripts/write_name_map_review.py
  Reads:  exchange/name_map.csv, name_map_vars.csv, name_map_collisions.csv,
          name_map_nearmatches.csv, name_abbrev_applied.csv
  Asserts row counts match SAS log values (pass via --expected-* args or embedded constants)
  Writes: qc/name_map_review.xlsx
  Sheets: KEY | NAME_MAP | VARIABLES | NAME_MAP_COLLISIONS | NEAR_MATCHES | ABBREVIATIONS

python/pdd/name_map_workbook.py   (core logic, mirroring s06_workbook.py)
python/tests/test_write_name_map_review.py
```

### Pattern 1: Status Assignment (D-04 precedence)

```sas
/* Source: CONTEXT.md D-04 */
/* Assign statuses in DATA step using cascading IF-ELSE so highest precedence wins */
data work.name_map_base;
  set work.headers_with_keys;  /* header_inventory joined to key flags */
  length status $20;
  if duplicate_study_id = 1 then status = 'DUPLICATE_DROPPED';
  else if key_column_type = 'PRECEDE_STUDY_ID' then status = 'KEY';
  else if s_code in ('s04','s05') then status = 'LINKAGE_ONLY';
  else if class = 'CLOCK' then status = 'EXCLUDED_CLK';
  else status = 'PCNR';
run;
```

### Pattern 2: Name Cleaning (D-02)

```sas
/* Source: CONTEXT.md D-02 */
%macro clean_name(raw=, out=);
  /* Steps 1-3: trim, replace non-alnum runs with _, strip leading/trailing _ */
  &out = strip(&raw);
  &out = prxchange('s/[^A-Za-z0-9]+/_/', -1, &out);
  &out = prxchange('s/^_+|_+$//o', -1, &out);   /* strip leading/trailing _ */
  /* Step 4: digit-start prefix */
  if prxmatch('/^\d/', &out) then &out = cats('N_', &out);
  /* Steps 5-6 (abbreviation + elide) handled separately */
%mend clean_name;
```

Note: PCM rule C3 — wrap in `%macro … %mend`. No open-code `%if/%else`.

### Pattern 3: Near-Match Detection (D-06) — COMPLEV built-in

Use the SAS built-in `COMPLEV` function (available in Base SAS). No macro needed. Cross-join distinct (s_code, cleaned_pre_short) rows from DIFFERENT files via PROC SQL:

```sas
proc sql;
  create table work.near_match_candidates as
  select a.s_code as s_code_a, a.cleaned_pre_short as name_a,
         b.s_code as s_code_b, b.cleaned_pre_short as name_b
  from work.pcnr_distinct a, work.pcnr_distinct b
  where a.s_code ne b.s_code
    and a.key < b.key   /* each pair once */
    and a.group_id ne b.group_id  /* exclude already-same-group */
    and abs(length(a.cleaned_pre_short) - length(b.cleaned_pre_short)) <= 2
    and complev(lowcase(a.cleaned_pre_short), lowcase(b.cleaned_pre_short)) <= 2
    and lowcase(a.cleaned_pre_short) ne lowcase(b.cleaned_pre_short);
quit;
```

Add the trailing-suffix rule separately via `prxmatch`. No `%levenshtein` macro — COMPLEV handles edit distance directly. Pre-filter on length difference eliminates most pairs before COMPLEV runs.

Alternative: export distinct cleaned names to exchange CSV, compute in Python (standard `difflib` or `rapidfuzz`), import result back. Python is faster for large cross-joins. **Recommended if pair count estimation shows risk of SAS timeout on 4,795×4,795 cross-join.** Estimated PCNR-status rows: ~1,240 (s06 PCNR subset) + non-s06 rows. Cross-join ceiling: ~1,500×1,500 = 2.25M pairs filtered to cross-file only. SAS DATA step DP on 2M pairs is feasible but slow; Python `rapidfuzz` batch is ~1 second. Document choice in plan.

### Pattern 4: Variable Group Formation (D-01a + SAME decisions)

```sas
/* Assign group_id: start from case-insensitive cleaned name as group key,
   then merge SAME decisions to unify disparate groups */
/* Use PROC SORT + DATA step with retained group counter */
/* SAME decisions in decisions.csv link two (s_code, col_order) pairs;
   union-find logic or iterative merge passes resolve transitive closure */
```

Transitive SAME closure (A=B, B=C → A=B=C) requires either iterative DATA step passes or a hash-based union-find. Plan should include one pass with a WARNING if circular SAMEs detected.

### Pattern 5: Exchange CSV Export (established)

```sas
/* Source: 03b_classify_s06.sas pattern */
proc export data=pdd.name_map
  outfile="&exchange_path.\name_map.csv"
  dbms=csv replace;
run;
```

### Pattern 6: Python Workbook (mirroring D-22 pilot)

```python
# Source: python/scripts/write_s06_clock_classification.py pattern
from pdd.xlsx_style import write_table, style_sheet
from pdd.name_map_workbook import write_workbook, assert_input

rows = read_csv(exchange / "name_map.csv")
assert_input(rows, expected_rows=4795)
write_workbook(rows, qc / "name_map_review.xlsx")
verify_workbook(xlsx_path, expected_sheet_row_counts)
```

### Anti-Patterns to Avoid

- **Open-code %if/%else outside %macro**: PCM C3 violation — sas_lint.py will reject.
- **CALL EXECUTE for macro loops**: PCM risk — use %do loops inside macros instead.
- **data X; set X; in-place rewrite**: Avoid; use work intermediate then rename/copy.
- **Collision suffix before group formation**: Stage 1 suffixes apply to groups, not raw rows — if done pre-grouping, same-variable overlaps get incorrectly suffixed.
- **Cleaning PCNR-status rows only**: D-02 says apply to all status rows that get a PCNR_ name — but actually only PCNR status rows get names. Confirm: only PCNR rows run through D-02/D-03. KEY/EXCLUDED_CLK/LINKAGE_ONLY/DUPLICATE_DROPPED leave PCNR_ name blank.
- **SAS LABEL > 256 chars**: Phase 2 logged 16 truncation warnings for long headers. Phase 4 must log which labels were truncated (D-10 criterion 6). Use ATTRIB with LABEL= in DATA step; SAS silently truncates at 256 — detect via length(original_header) > 256 before assignment.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| xlsx output with UF colors | Custom ODS Excel | `python/pdd/xlsx_style.py` + openpyxl | D-22 LOCKED; pilot already works |
| Name validity check | Custom regex | `options validvarname=v7` already set; PROC DATASETS will reject invalid V7 names | SAS enforces at assignment |
| CSV export from SAS | DATA step FILE | PROC EXPORT dbms=csv | Established pattern from Phase 3 |
| Edit distance | Custom %levenshtein macro or Python rapidfuzz | `COMPLEV` SAS built-in in PROC SQL | Simpler, no macro, no roundtrip; length pre-filter keeps cross-join small |

---

## Common Pitfalls

### Pitfall 1: Same-file cleaned-name collision vs. cross-file overlap

**What goes wrong:** Two columns in the same file clean to the same name. D-01a says these are separate variables (suffix _2), not the same variable. Cross-file identical cleans are the same variable (no suffix between groups). Implementing this wrong merges same-file duplicates or splits cross-file matches.

**How to avoid:** Group formation must know s_code. Within-group same-file duplicates (more than one row from same s_code in a group formed by D-01a) are an error — log them and apply _2 suffix only to same-file collisions, not to cross-file matches.

**Warning signs:** PCNR_ variable with only one source file but two col_orders in name_map.

### Pitfall 2: Processing order violation (D-01b)

**What goes wrong:** Applying abbreviations before status assignment, or forming groups before applying decisions.csv SAME overrides. Either causes incorrect group membership → wrong collision results.

**How to avoid:** Implement sections in strict D-01b order. Section headers in the SAS file should call out the D-01b step number.

### Pitfall 3: Levenshtein cross-join explosion

**What goes wrong:** Full 4,795×4,795 cross-join before filtering produces ~23M pairs. Even filtering to cross-file PCNR rows, the pair count may be large enough to cause SAS memory issues or very slow runtime.

**How to avoid:** Filter to PCNR-status rows only before cross-join. Further filter: pairs where ABS(length(a) - length(b)) > 2 cannot have edit distance ≤ 2 — pre-filter eliminates most pairs. If >200 pairs survive, %fail_out reports patterns before any xlsx write.

### Pitfall 4: SAS label truncation silent failure

**What goes wrong:** SAS truncates ATTRIB LABEL= at 256 chars silently. Phase 2 found 16 headers longer than 256 chars. If Phase 4 doesn't log them, D-10 criterion 6 is unmet.

**How to avoid:** Before assigning LABEL, compute length of original_header. If > 256, write a NOTE to the log and record in a QC dataset.

### Pitfall 5: decisions.csv integrity check (D-10 criterion 4)

**What goes wrong:** A SAME/DIFFERENT/RENAME decision references a (s_code, header) that doesn't exist in name_map — typo in the CSV. This silently does nothing.

**How to avoid:** After applying overrides, verify every row in decisions.csv matched at least one name_map row. %fail_out on any unmatched decision row.

### Pitfall 6: SAS_LINT violations

**What goes wrong:** Any open-code %if, macro called before %macro definition, bare data;/set;, or ANSI SQL fails sas_lint.py and blocks commit.

**How to avoid:** All conditional logic inside %macro blocks. Define all macros in Section 0/1 before first call. Run `python tools\sas_lint.py sas\04_name_map.sas` and `sasjs lint` before every commit (CLAUDE.md rule).

---

## Code Examples

### Verified Exchange CSV Export Pattern

```sas
/* Source: sas/03b_classify_s06.sas established pattern */
proc export data=pdd.name_map
  outfile="&exchange_path.\name_map.csv"
  dbms=csv replace;
run;
```

### Verified Python Sheet Write Pattern

```python
# Source: python/pdd/s06_workbook.py + python/scripts/write_s06_clock_classification.py
from pdd.xlsx_style import write_table

headers = ["s_code","col_order","original_header","pcnr_name","status","label","sas_type","length"]
data    = [[r[h] for h in headers] for r in rows]
write_table(ws, headers, data, int_cols=frozenset([1]))  # col_order is int
```

### Verified %fail_out Pattern

```sas
/* Source: sas/03_import.sas */
%macro fail_out(msg=);
  %put ERROR: [04_name_map] &msg;
  %abort cancel;
%mend fail_out;
```

---

## Environment Availability

Step 2.6: All external tools confirmed present from Phase 3 pipeline. No new dependencies.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| SAS with pdd library | 04_name_map.sas | Yes | Phase 3 confirmed | — |
| Python + openpyxl | write_name_map_review.py | Yes | D-22 pilot confirmed | — |
| `pdd.header_inventory` | Section 1 assertion | Yes | Phase 2 output | — |
| `pdd.import_spec` | D-07 type tracking | Yes | Phase 3 output | — |
| `pdd.key_analysis` | D-04 KEY status | Yes | Phase 2 output | — |
| `docs/s06_column_class.csv` | D-21 CLOCK filter | Yes | repo, committed | — |
| `docs/name_map_decisions.csv` | D-06 overrides | Must create (may be empty) | — | Empty file is valid start state |
| `docs/name_abbrev.csv` | D-03 abbreviations | Must create | — | Pre-populated from D-03 standard tokens |

**Missing — must create before plan executes:**
- `docs/name_map_decisions.csv` — empty file with header: `s_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,note,decided_by,date`
- `docs/name_abbrev.csv` — pre-populated: `Delayed,Dly / Recall,Rcl / Recognition,Recog / Number,N / Norm_ZScore,Z / AgeScaled,AgeSc / Percent,Pct`

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | pytest (confirmed installed, Phase 3 pilot test exists) |
| Config file | none (run from repo root) |
| Quick run command | `pytest python/tests/test_write_name_map_review.py -x` |
| Full suite command | `pytest python/tests/ -x` |

### Phase Requirements → Test Map

| Behavior | Test Type | Automated Command | File Exists? |
|----------|-----------|-------------------|-------------|
| 4,795 rows in output | unit | `pytest python/tests/test_write_name_map_review.py::test_assert_input_row_count` | No — Wave 0 |
| No duplicate PCNR_ names | unit | `pytest python/tests/test_write_name_map_review.py::test_no_dup_pcnr_names` | No — Wave 0 |
| Sheet row counts match SAS | integration | `pytest python/tests/test_write_name_map_review.py::test_verify_workbook` | No — Wave 0 |
| Workbook has 6 sheets in order | unit | `pytest python/tests/test_write_name_map_review.py::test_sheet_order` | No — Wave 0 |
| SAS lint passes | manual / pre-commit | `python tools/sas_lint.py sas/04_name_map.sas` | N/A |

### Wave 0 Gaps

- `python/tests/test_write_name_map_review.py` — covers all Python output assertions
- `python/pdd/name_map_workbook.py` — core logic module (mirrors s06_workbook.py)
- `docs/name_map_decisions.csv` — empty decision file with correct header
- `docs/name_abbrev.csv` — pre-populated abbreviation table

---

## Open Questions

1. **Levenshtein implementation location**
   - What we know: D-06 requires edit distance ≤ 2 for cross-file pairs; SAS has no built-in.
   - What's unclear: Whether SAS DO-loop DP or Python roundtrip is faster given actual PCNR-status row count (~1,240 + non-s06).
   - Recommendation: Plan both paths. SAS macro first; if pair count exceeds 500 after pre-filtering, switch to Python batch and re-import result via exchange CSV. Document the threshold in plan.

2. **Transitive SAME closure in decisions.csv**
   - What we know: D-06 says SAME decisions form groups alongside D-01a. A→B and B→C decisions should merge all three.
   - What's unclear: Whether current decisions.csv will have transitive chains at Phase 4 start (it's empty).
   - Recommendation: Implement simple two-pass merge: first apply direct SAMEs, second pass propagates groups. Flag circular SAMEs as %fail_out.

3. **99_run_all.sas wiring**
   - What we know: Phase 3 plans wired 03_import.sas; Phase 4 must add 04_name_map.sas after it.
   - Recommendation: Plan includes a dedicated task to add the %include to 99_run_all.sas and verify standalone run before pipeline run.

---

## Sources

### Primary (HIGH confidence)

- `.planning/phases/04-name-map/04-CONTEXT.md` — all decisions D-01 through D-10
- `sas/00_config.sas` — macro patterns, path variables, %fail_out, %pdd_lib
- `python/pdd/xlsx_style.py`, `python/pdd/s06_workbook.py` — Python workbook patterns
- `python/scripts/write_s06_clock_classification.py` — D-22 pilot script structure
- `.planning/REQUIREMENTS.md` PDD-04 — acceptance criteria
- `docs/s06_column_class.csv` — verified CLOCK=2747, DIGITAL_OTHER=809, PCNR=431, UNSURE=0

### Secondary (MEDIUM confidence)

- `.planning/STATE.md` — phase status and D-21/D-22 lock dates
- `.planning/ROADMAP.md` — Phase 4 done criteria

---

## Project Constraints (from CLAUDE.md)

Every plan task that produces a SAS edit must enforce:

1. Run `python tools\sas_lint.py sas\04_name_map.sas` — zero errors before commit.
2. Run `sasjs lint` — zero errors before commit.
3. Run `ruff check python\` and `pytest python\tests` before any Python commit — zero errors / all pass.
4. PCM rules in effect: no open-code %if/%else (C3), no macro keyword in quoted PUT (C11), no macro called before its %macro definition (C13), no bare data;/set; (C14), LIBNAME engine before path (C9), no ?? in PROC SQL (C1), no ANSI SQL (C2).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components confirmed present in repo
- Architecture: HIGH — all decisions locked; section order directly from D-01b
- Pitfalls: HIGH — derived from locked decision edge cases, confirmed against existing code patterns

**Research date:** 2026-10-21
**Valid until:** Until any locked decision is revised (stable)
