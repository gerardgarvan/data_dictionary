# Phase 3: Direct Import of the 20 Sources — Research

**Researched:** 2026-10-19
**Domain:** SAS 9.4 — INFILE/INPUT spec-driven import, LIBNAME XLSX, CALL EXECUTE code generation
**Confidence:** HIGH (all findings from project source code + SAS 9.4 documented behaviour)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **PDD-D-17 FULLY CLOSED:** All 20 files are 1:1 per PRECEDE_STUDY_ID. s01 (41,423 distinct) and
  s08 (3,456 distinct) are NOT multi-row. Both join the spine like any other 1:1 source.
  274 s01 IDs not in spine = QC item only.
- **PDD-D-18 LOCKED:** s04/s05 import into pdd.src_s04/pdd.src_s05 for completeness and ID
  checking; no PCNR_ columns from them; Phase 5 decides linkage; do NOT reference 2022 mismatch
  in any s04/s05 logic.
- **PDD-D-21 scope:** Phase 3 imports ALL s06 columns raw. Column-group profile (pdd.qc_s06_groups
  + qc\s06_column_groups.xlsx) written; Gerard decides scope in Phases 4-5.
- **s18 dup rows:** Log offending IDs, exclude from pdd.src_s18, leave pdd.qc_s18_dup untouched.
- **import_spec.csv schema locked:** file_code, col_order, orig_col_name, sas_name, sas_type,
  length, informat, format, notes. Committed to docs\ (no PHI).
- **Raw pre-pass required:** Read every CSV column as $32767 to get true max observed lengths into
  pdd.raw_char_lengths. Do NOT use pdd.header_inventory col_len for character lengths.
- **ID/code forced to char:** PRECEDE_STUDY_ID, PRECEDE Study ID, Base Procedure Code 1,
  *_ID, *_CODE, CPT*, ICD* (case-insensitive).
- **Duplicate headers:** _dup2/_dup3 suffix; both copies kept; original header becomes LABEL.
- **CSV files (16):** INFILE ENCODING='UTF-8' DLM=',' FIRSTOBS=2 MISSOVER DSD; INPUT via col_order.
- **XLSX files (4 — s06, s08, s11, s19):** LIBNAME XLSX only; DATA step re-casts types.
- **%pdd_norm_psid:** Task 1 confirms presence before any import code runs.
- **PDD-D-02:** Values exactly as in source; no recoding.
- **PDD-D-08:** s19 Sheet1 only; drop rows where PRECEDE_STUDY_ID missing or all data columns
  blank/NULL; log kept/dropped counts.
- **PDD-D-19:** Apply %pdd_norm_psid to all files after raw import; assert _ndis = 0.
- **PDD-D-20:** s17 — set 6 ENCRYPTED_ENCOUNTER values mapping to >1 PRECEDE_STUDY_ID to missing
  for linkage only; raw values unchanged in pdd.src_s17.
- **UTF-8:** Every CSV INFILE uses ENCODING='UTF-8'. XLSX files do not need encoding option.

### Claude's Discretion

- Whether spec-generation code is 03a_build_spec.sas or Section 1 of 03_import.sas.
- Exact column-group pattern-matching heuristic for s06 profile.
- QC row-count reconciliation format (ODS table or %put NOTEs), consistent with Phase 2 style.
- How to re-cast xlsx char/num types in the DATA step (CATS, PUT+INPUT, or conditional assignment).

### Deferred Ideas (OUT OF SCOPE)

- Which s06 column groups enter PCNR_ (PDD-D-21): Phases 4-5 after profiling review.
- s04/s05 linkage use in Phase 5: Phase 5 planning decision.
- PDD-D-15 (gap-fill tie-break) and PDD-D-16 (per-cell source flag): Phase 5 only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDD-03-R01 | 03_import.sas: one DATA step per file with explicit INFORMATs and LENGTHs | CALL EXECUTE loop over import_spec rows; INFILE/INPUT for CSV; DATA step from XLSX libref |
| PDD-03-R02 | PRECEDE_STUDY_ID and Base Procedure Code 1 read as character in all files | ID/code forced-char rule; LENGTH + RENAME pattern for XLSX re-cast |
| PDD-03-R03 | Every INFILE uses ENCODING='UTF-8' | Verified in 02_source_guard.sas pattern; XLSX needs no option |
| PDD-03-R04 | s19 (ALL_AIM2 Sheet1): drop blank/null rows; log kept/dropped counts | PDD-D-08; post-import DATA step filter; LIBNAME XLSX |
| PDD-03-R05 | Output pdd.src_s01…pdd.src_s20; row counts reconciled in QC | _note_written_ds pattern from Phase 2 |
| PDD-03-R06 | s01 and s08 import as-is; 1:1 confirmed | PDD-D-17 closed; no special handling |
| PDD-03-R07 | s04/s05 import and stage; linkage-only per PDD-D-18 | Plain import; no PCNR_ derivation |
| PDD-03-R08 | s06: import ALL columns raw; profile column groups | LIBNAME XLSX all-column import; PROC SQL pattern-match on column names |
| PDD-03-R09 | import_spec.csv generated and committed before 03_import.sas runs | Spec-gen task (03a or Section 1) reads pdd.header_inventory + pdd.raw_char_lengths |
| PDD-03-R10 | s17 PDD-D-20: 6 ENCRYPTED_ENCOUNTER values set to missing for linkage; raw unchanged | Post-import DATA step; separate linkage-only variable or conditional assignment |
</phase_requirements>

---

## Summary

Phase 3 has two sequential sub-problems: (1) generate `docs\import_spec.csv` from metadata
already on disk, then (2) use that spec at runtime to drive explicit DATA step imports for all 20
sources. Both sub-problems are solved entirely within SAS 9.4 on Windows with no external tools.

The Phase 2 codebase (`02_source_guard.sas`) establishes all required patterns — LIBNAME XLSX,
INFILE/INPUT, CALL EXECUTE accumulation, certutil piping, ODS Excel output, %fail_out, and the
`%pdd_norm_psid` macro in `00_config.sas`. Phase 3 reuses these patterns directly; it introduces
no new third-party libraries.

The two genuine technical risks are (a) the raw pre-pass performance over large CSV files (s19
xlsx is ~1M rows; several CSVs are also large), and (b) LIBNAME XLSX type-casting for the 3,987
columns of s06. Both have established SAS patterns documented below.

**Primary recommendation:** Split into 03a_build_spec.sas (spec generation, committed) and
03_import.sas (runtime import using the committed spec). This separates the one-time metadata
derivation from the repeatable import step and lets Gerard review/override the spec between runs.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SAS 9.4 BASE | 9.4 M7 | INFILE/INPUT, DATA step, PROC SQL | Project constraint; already in use |
| LIBNAME XLSX engine | SAS 9.4 built-in | Read xlsx files without PROC IMPORT | Used in 02_source_guard.sas; avoids PROC IMPORT type guessing |
| CALL EXECUTE | SAS 9.4 built-in | Generate per-file DATA steps from spec dataset rows | Standard spec-driven import pattern |
| ODS Excel | SAS 9.4 built-in | Write QC workbooks (qc_s06_column_groups.xlsx) | Established in Phase 2 with UF colors |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| PROC SQL INSERT INTO | Accumulate rows across files into single QC dataset | Same pattern as Phase 2 hdr_all / counts_all |
| CALL SYMPUTX | Pass per-file metadata (lengths, counts) from DATA step to macro vars | Pre-pass length accumulation |
| certutil (already used) | Not needed in Phase 3 | Phase 2 only |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CALL EXECUTE loop | Macro %DO loop over file list | CALL EXECUTE defers execution to after DATA step; simpler for generating multiple distinct DATA steps from a dataset. Macro %DO loop requires macro vars for every parameter — more code for 20 files. Use CALL EXECUTE. |
| LIBNAME XLSX | PROC IMPORT DBMS=xlsx | PROC IMPORT guesses types; cannot force character. LIBNAME XLSX gives column-level control in the subsequent DATA step. Project decision locked. |
| Separate 03a / 03_import | Single monolithic file | 03a separates spec generation (run once) from import (repeatable). Gerard can override import_spec.csv rows. Use separate files. |

---

## Architecture Patterns

### Recommended Program Structure

```
sas/
├── 03a_build_spec.sas   # Task A: raw pre-pass + spec generation + write docs\import_spec.csv
└── 03_import.sas        # Task B: read import_spec.csv, CALL EXECUTE import loop, QC
docs/
└── import_spec.csv      # generated by 03a, committed to git, overridable by Gerard
```

### Pattern 1: Raw Pre-Pass for True Character Lengths

**What:** Read every CSV column as `$32767` in a DATA step; use `LENGTHN()` to find max observed
byte length per column; write results to `pdd.raw_char_lengths`.

**When to use:** Before spec generation. One pass per CSV file; persist results; never rerun
unless source files change (SHA-256 guard from Phase 2 covers this).

**Key detail:** INFILE with `$32767` informats for ALL columns works because MISSOVER prevents
record truncation and DSD handles embedded commas in quoted fields.

```sas
/* Source: SAS 9.4 INFILE/INPUT documentation + established Phase 2 pattern */
/* Per-file raw pre-pass — run inside a %DO loop over file_list */
data work._prepass_&_scode;
  length _max_len_1-_max_len_&_ncols 8;
  retain _max_len_1-_max_len_&_ncols 0;
  infile "&_full" encoding='utf-8' dlm=',' dsd missover firstobs=2 lrecl=32767;
  array _c {&_ncols} $32767 _c1-_c&_ncols;
  input _c{*} $32767.;
  array _m {&_ncols} _max_len_1-_max_len_&_ncols;
  do _j = 1 to &_ncols;
    if lengthn(_c{_j}) > _m{_j} then _m{_j} = lengthn(_c{_j});
  end;
  keep _max_len_1-_max_len_&_ncols;
run;

/* Extract the single retained row of maxima */
data work._prepass_row;
  set work._prepass_&_scode(obs=1);
  /* transpose into (col_order, max_len) pairs */
run;
```

**Performance note:** For s01 (41K rows × ~40 cols) and s17/s09 (41K rows), this is fast. For
files with many columns or large lrecl, SAS may be slow at $32767 allocation. Mitigate by running
the pre-pass once and checkpointing to `pdd.raw_char_lengths` before spec generation proceeds.

### Pattern 2: CALL EXECUTE Import Loop from Spec Dataset

**What:** Read `pdd.import_spec` (loaded from `docs\import_spec.csv`) grouped by file_code; build
INFILE/INPUT or LIBNAME XLSX DATA step text; submit via CALL EXECUTE.

**Critical rule:** CALL EXECUTE text executes in a *separate* step boundary after the DATA step
ends. Never reference WORK datasets created in the same DATA step inside CALL EXECUTE-submitted code.

```sas
/* Source: SAS 9.4 CALL EXECUTE documentation */
/* One CALL EXECUTE call builds the complete DATA step per file */
data _null_;
  set work.spec_csv;  /* filtered to ftype='csv', one row per column */
  by file_code;

  /* Open the DATA step on the first column of each file */
  if first.file_code then do;
    call execute(cats(
      'data pdd.src_', file_code, '; ',
      'infile "', strip(full_path), '" ',
      'encoding=''utf-8'' dlm='','' dsd missover firstobs=2 lrecl=32767; ',
      'length '
    ));
    /* Length declarations: accumulate across columns */
  end;

  /* Emit per-column length and informat */
  if sas_type = 'C' then
    call execute(cats(sas_name, ' $', put(length, 8.), ' '));
  else
    call execute(cats(sas_name, ' 8 '));

  /* Close with INPUT and label statements on last column */
  if last.file_code then do;
    call execute('; input ');
    /* ... emit column names in col_order sequence ... */
    call execute('; run;');
  end;
run;
```

**Limitation:** Building the INPUT statement requires a two-pass strategy because CALL EXECUTE
emits text incrementally. Preferred approach: use PROC SQL to build the complete DATA step text as
a single macro variable (or a series of %LET calls), then CALL EXECUTE that full text. For 20
files this is tractable.

**Recommended alternative to piecemeal CALL EXECUTE:** For each file_code, PROC SQL assembles the
full INPUT statement into a macro var; a single CALL EXECUTE submits the whole DATA step. This
avoids the "building across rows" complexity.

```sas
/* Assemble full INPUT text per file_code, then CALL EXECUTE once per file */
proc sql noprint;
  select cats(sas_name,
              case when sas_type='C' then cats(' $', put(length,8.), '.')
                   else ' best32.' end)
         into :_input_cols separated by ' '
  from pdd.import_spec
  where file_code = "&_scode"
  order by col_order;
quit;
/* Then: call execute(full DATA step string using &_input_cols); */
```

### Pattern 3: LIBNAME XLSX Import with Type Re-cast

**What:** Assign LIBNAME XLSX; SET from the relevant sheet member; re-cast columns that XLSX
engine inferred incorrectly (e.g., ID columns inferred as numeric).

**XLSX engine behaviour in SAS 9.4:**
- Reads Excel dates as SAS numeric dates (numeric with DATE or DATETIME format).
- Reads text columns as character.
- Reads numeric columns as numeric.
- Column names from header row become SAS variable names (V7 rules applied automatically by engine).

**Re-cast pattern for forced-char columns:**

```sas
/* Source: SAS 9.4 LIBNAME XLSX documentation + Phase 2 Section 6 XLSX branch */
libname _xl xlsx "&raw_master.\2018_2022_COLONOSCOPY_20240118.xlsx";

data pdd.src_s08;
  set _xl.'Sheet1'n;

  /* Force ID column to character if XLSX engine read it as numeric */
  length PRECEDE_STUDY_ID_c $32;
  PRECEDE_STUDY_ID_c = cats(PRECEDE_STUDY_ID);
  drop PRECEDE_STUDY_ID;
  rename PRECEDE_STUDY_ID_c = PRECEDE_STUDY_ID;

  /* Keep date columns as numeric SAS dates -- retain their FORMAT */
  /* format surgery_date date9.; */  /* only if needed */
run;

libname _xl clear;
```

**Important:** The DROP + RENAME trick requires that the new variable name not collide with the
original variable name before the RENAME executes. SAS resolves RENAMEs at compile time in a DATA
step, so `DROP orig; RENAME new = orig;` works correctly.

For s06 (3,987 columns), iterating this pattern manually is infeasible. Use an ARRAY of character
variables or generate the re-cast DATA step via CALL EXECUTE over import_spec rows filtered to
file_code='s06', sas_type='C'.

### Pattern 4: Duplicate Column Name Handling

**What:** SAS V7 names: alphanumeric + underscore, start with letter or underscore, max 32 chars.
Non-alphanumeric chars in orig_col_name replaced with `_`. Trailing `_` stripped. Collision
detection within the same file_code.

**Algorithm (for 03a_build_spec.sas):**
1. `sas_name_raw = prxchange('s/[^A-Za-z0-9_]/_/o', -1, strip(orig_col_name))` — replaces all
   non-word chars with `_`.
2. If starts with digit: prepend `_`.
3. Truncate to 32 chars.
4. Within file_code, check for collisions using a running hash or a self-join. Second occurrence
   gets `_dup2` suffix (truncate base to 27 chars to fit). Third gets `_dup3`, etc.
5. Label = orig_col_name (exact, up to 256 chars — SAS label length limit).

**Known collision:** s15 and s17 each have `PRECEDE Study ID` as a second header alongside
`PRECEDE_STUDY_ID`. The sanitised form of both is `PRECEDE_Study_ID`. Second occurrence →
`PRECEDE_Study_ID_dup2`. Both kept (PDD-D-02).

### Pattern 5: s19 Blank-Row Drop (PDD-D-08)

**What:** After importing s19 Sheet1 via LIBNAME XLSX, filter out rows where PRECEDE_STUDY_ID is
missing AND all data columns are blank/NULL. Log kept/dropped counts.

```sas
/* Source: Phase 2 _s19_nonblank_pre macro pattern (02_source_guard.sas Section 6) */
data pdd.src_s19_raw pdd.src_s19_dropped;
  set work.s19_raw;
  array _c {*} _character_;
  array _n {*} _numeric_;
  _any_data = 0;
  do _k = 1 to dim(_c); if strip(_c{_k}) not in ('', 'NULL') then _any_data = 1; end;
  do _k = 1 to dim(_n); if not missing(_n{_k}) then _any_data = 1; end;
  if missing(PRECEDE_STUDY_ID) or strip(PRECEDE_STUDY_ID) = '' then do;
    if not _any_data then output pdd.src_s19_dropped;
    else output pdd.src_s19;  /* has data but no ID -- keep with warning */
  end;
  else output pdd.src_s19;
  drop _k _any_data;
run;
/* Log counts */
```

**Note:** The CONTEXT.md definition of PDD-D-08 says drop rows where PRECEDE_STUDY_ID is missing
OR all data columns are blank/NULL. The two conditions are OR (either alone triggers drop). Confirm
the exact logical combination with the existing project definition before coding.

Re-reading CONTEXT.md: "drop rows where PRECEDE_STUDY_ID is missing or all data columns are
blank/NULL". This means: drop if (ID missing) OR (all data cols blank). Keep if ID present AND at
least one data col non-blank.

### Pattern 6: s06 Column-Group Profiling

**What:** 3,987 columns, mostly with systematic prefixes/suffixes. Profile groups by shared prefix
(longest common prefix before a delimiter character — `_`, space, or digit boundary).

**Heuristic (Claude's discretion — recommended approach):**
1. Load column names from `pdd.header_inventory` where file_code = 's06'.
2. Extract prefix: take characters up to the first occurrence of `_` or first digit run, minimum 3
   chars, maximum 20 chars. This is the candidate group key.
3. Count columns per group; store example_cols (first 3 alphabetically).
4. Compute median % non-null across group columns using `pdd.src_s06` after import.
5. Overlap check: join group column names against `pdd.header_inventory` where file_code IN
   ('s03','s07'); count matches.
6. Output one row per group to `pdd.qc_s06_groups`; sort by col_count descending.
7. Write `qc\s06_column_groups.xlsx` via ODS Excel (UF colors, KEY sheet leftmost).

**Fallback for no obvious pattern:** Any column whose prefix matches no other column gets group
`_SINGLETON_`. Planner may want to group these separately.

**PROC SQL pattern-match on prefix:**

```sas
/* Extract candidate prefix: chars before first _ or digit */
data work.s06_cols;
  set pdd.header_inventory(where=(file_code='s06'));
  length prefix $32;
  _pos = prxmatch('/[_\d]/', strip(col_name));
  if _pos > 3 then prefix = substr(strip(col_name), 1, _pos - 1);
  else prefix = substr(strip(col_name), 1, min(length(strip(col_name)), 8));
run;
```

### Pattern 7: s18 Dup Row Exclusion

**What:** `pdd.qc_s18_dup` already exists from Phase 2. Phase 3 reads it to get the offending IDs
and excludes those rows from the import.

```sas
/* Read offending IDs into a macro var or use a WHERE NOT IN */
proc sql noprint;
  create table pdd.src_s18 as
  select a.*
  from work.s18_raw a
  where a.PRECEDE_STUDY_ID not in (
    select PRECEDE_STUDY_ID from pdd.qc_s18_dup
    where not missing(PRECEDE_STUDY_ID)
  )
  and not missing(a.PRECEDE_STUDY_ID)
  and strip(a.PRECEDE_STUDY_ID) ne '';
quit;
/* Log counts with %put NOTE */
```

**Do NOT recreate or overwrite pdd.qc_s18_dup.** Read it only.

### Pattern 8: PDD-D-20 — s17 Linkage-Only Blank

**What:** After importing s17, create a linkage_encounter variable (or modify for linkage use).
The raw `ENCRYPTED_ENCOUNTER` column stays unchanged in `pdd.src_s17`. A derived column
`enc_for_linkage` = . for the 6 ambiguous values, = ENCRYPTED_ENCOUNTER otherwise.

```sas
/* The 6 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID were identified in Phase 2.
   Store them as a lookup in a DATALINES dataset or hardcode in the DATA step WHERE. */
data pdd.src_s17;
  set work.s17_raw;
  length enc_for_linkage $64;  /* or numeric if enc is numeric */
  /* raw ENCRYPTED_ENCOUNTER unchanged */
  enc_for_linkage = ENCRYPTED_ENCOUNTER;
  if ENCRYPTED_ENCOUNTER in (&_s17_ambig_enc_list) then enc_for_linkage = '';
  label enc_for_linkage = 'ENCRYPTED_ENCOUNTER with ambiguous values blanked for linkage (PDD-D-20)';
run;
```

**Open question for planner:** The 6 specific ambiguous ENCRYPTED_ENCOUNTER values need to be read
from `pdd.key_analysis` or hardcoded. Confirm the source.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Excel file reading | Custom byte-parser | LIBNAME XLSX engine | SAS built-in; handles .xlsx format, sheet enumeration, column metadata |
| UTF-8 byte handling | Custom encoding conversion | ENCODING='UTF-8' on INFILE | SAS handles transcoding natively when session is UTF-8 |
| Column name sanitisation | Custom regex | PRXCHANGE with /[^A-Za-z0-9_]/_/ | One call; handles all non-word chars |
| Duplicate name detection | Custom counter | PROC SQL self-join + ROW_NUMBER equivalent (MONOTONIC() or retained counter) | Standard SAS duplicate detection |
| Type inference for spec | Custom guesser | Inherit from pdd.header_inventory + override rules | Phase 2 already built the inventory |
| Row-count QC | Custom comparison | pdd.source_inventory row_count vs DATA step N= | source_inventory is the authoritative row count from Phase 2 |

---

## Common Pitfalls

### Pitfall 1: CALL EXECUTE Text-Building Across Multiple Rows
**What goes wrong:** Building an INPUT statement across multiple CALL EXECUTE calls works for some
patterns but fails when SAS compiles each CALL EXECUTE fragment independently (semicolons inside
the text can terminate early).
**Why it happens:** CALL EXECUTE submits text to the input stack; a `;` in the submitted text
terminates the current statement in the deferred step.
**How to avoid:** Assemble the full DATA step text as a single macro variable using PROC SQL +
`separated by ' '`. Submit the complete DATA step in one CALL EXECUTE call.
**Warning signs:** "Statement is not valid" or "Expected name" errors for the generated DATA step.

### Pitfall 2: LIBNAME XLSX — Column Name Collision with SAS Keywords
**What goes wrong:** s06 has 3,987 columns; some names may be SAS keywords (DATE, TIME, YEAR,
FORMAT, etc.) or may start with digits. XLSX engine applies V7 rules but may still produce
unexpected names.
**How to avoid:** After `SET _xl.Sheet1n`, immediately check `dictionary.columns` for the sheet
dataset and compare expected vs actual names. Use the import_spec sas_name as the authoritative
target name and rename accordingly.

### Pitfall 3: Raw Pre-Pass Memory — Large $32767 Arrays
**What goes wrong:** An array of N columns × $32767 allocates N × 32767 bytes per observation.
For s06 (3,987 cols), that is ~130 MB per row in PDV. SAS may exceed memory limits.
**How to avoid:** For XLSX files, skip the raw pre-pass (XLSX types come from the engine, not raw
text). Run raw pre-pass only on CSV files. For CSVs with many columns, split into batches of 200
columns per pass if memory errors occur.
**Warning signs:** "Insufficient memory" or "Unable to allocate" in SAS log.

### Pitfall 4: LIBNAME XLSX Sheet Name with Spaces or Special Characters
**What goes wrong:** Sheet named "Sheet 1" or "2018 Data" fails `SET _xl.Sheet1n` syntax.
**How to avoid:** Use name literal syntax: `SET _xl."Sheet 1"n;`. Phase 2 already handles this
with the `prxmatch(/^[A-Za-z_]\w*$/)` branch vs name-literal branch (02_source_guard.sas
Section 6, lines 895-908). Copy that pattern.

### Pitfall 5: pdd.qc_s18_dup Absent on Re-run
**What goes wrong:** If 03_import.sas runs before 02_source_guard.sas on a fresh system,
`pdd.qc_s18_dup` does not exist and the WHERE NOT IN subquery fails.
**How to avoid:** Add a precondition check: `%if not %sysfunc(exist(pdd.qc_s18_dup)) %then
%fail_out(...)`. This is the same pattern as `%check_pdd_lib` in 00_config.sas.

### Pitfall 6: s19 ALL_AIM2 — NULL String vs Missing
**What goes wrong:** s19 uses the string literal `'NULL'` as a sentinel (PDD-D-02). After XLSX
import, these are character values, not SAS missing. A `missing()` test will NOT catch them.
**How to avoid:** In the PDD-D-08 blank-row filter, test `strip(_c{_k}) not in ('', 'NULL')` for
character columns, not `not missing()`.

### Pitfall 7: ENCODING='UTF-8' on INFILE vs Session Encoding
**What goes wrong:** If the SAS session is not UTF-8 (e.g., run outside run_pipeline.cmd),
ENCODING='UTF-8' on INFILE transcodes bytes from UTF-8 to the session encoding, potentially
corrupting multibyte characters in Base_Procedure_1.
**How to avoid:** `%check_encoding` is already in 00_config.sas and must be called at the top of
03_import.sas (after %fail_out is defined). This aborts the run if session encoding is wrong.

### Pitfall 8: col_order vs Actual Column Position
**What goes wrong:** If import_spec.csv col_order does not match the actual column position in the
source CSV (e.g., if a file was regenerated with different column order), the INPUT statement reads
wrong data into wrong variables silently.
**How to avoid:** The raw pre-pass traverses columns in physical file order (INPUT position =
file position). Spec col_order must be derived from the same physical scan, not from
pdd.header_inventory varnum (which comes from PROC IMPORT, which may reorder). Assert at spec
generation that col_order sequence for each file_code is gapless 1..N.

### Pitfall 9: LENGTH Declaration Must Precede INPUT
**What goes wrong:** In a DATA step, if INPUT assigns a value before LENGTH is declared, SAS uses
a default length (usually 8 for character). Subsequent LENGTH statement does not resize.
**How to avoid:** Always put LENGTH statements before INPUT in the generated DATA step. In the
CALL EXECUTE pattern, emit LENGTH first, then INPUT.

### Pitfall 10: RENAME in Same DATA Step as DROP
**What goes wrong:** `DROP orig_var; RENAME new_var = orig_var;` — SAS resolves DROP and RENAME
at compile time. If `new_var` is also named `orig_var` before rename, the DROP will drop the
wrong variable.
**How to avoid:** Use a distinct temporary name (`PRECEDE_STUDY_ID_c`) that does not collide with
any existing variable. Only after dropping the original can the new var be renamed to the original
name. Verify with `dictionary.columns` check after the DATA step.

---

## Runtime State Inventory

> This is NOT a rename/refactor phase. Section included for completeness; all categories are empty.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | pdd.qc_s18_dup (2 rows from Phase 2) | READ ONLY — do not overwrite |
| Stored data | pdd.header_inventory (Phase 2 output) | READ ONLY — source of type inference |
| Stored data | pdd.source_inventory (Phase 2 output) | READ ONLY — source of row count QC |
| Live service config | None | — |
| OS-registered state | None | — |
| Secrets/env vars | None — paths in 00_config.sas only | — |
| Build artifacts | None | — |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| SAS 9.4 LIBNAME XLSX engine | s06, s08, s11, s19 import | Yes (confirmed — used in Phase 2) | SAS 9.4 | None; PROC IMPORT type guessing is unacceptable per locked decisions |
| P: drive (read-only source) | All 20 file reads | Yes (Phase 2 confirmed accessible) | — | None |
| P: drive (pdd library write) | pdd.src_s01..s20 output | Yes (Phase 2 wrote pdd.source_inventory) | — | None |
| docs\ git folder (C:) | import_spec.csv write | Yes (Phase 2 wrote source_guard_baseline.csv there) | — | None |
| certutil | Not needed in Phase 3 | — | — | — |
| UTF-8 SAS session | ENCODING='UTF-8' on INFILE | Yes (run_pipeline.cmd sets -config nls\u8\sasv9.cfg) | — | %check_encoding aborts if absent |

---

## Code Examples

### Verified Pattern: LIBNAME XLSX Sheet Access (from 02_source_guard.sas lines 895-908)

```sas
/* Standard sheet name — no spaces */
data work.&_sh_ds;
  set _xlw.&&_sh&j;
run;

/* Non-standard sheet name (starts with digit or has spaces) */
data work.&_sh_ds;
  set _xlw."%unquote(%superq(_sh&j))"n;
run;
```

### Verified Pattern: %fail_out (from 02_source_guard.sas Section 1)

```sas
%macro fail_out(msg=);
  %put ERROR: [03_import] &msg;
  %abort cancel;
%mend fail_out;
```

### Verified Pattern: _note_written_ds (from 02_source_guard.sas Section 1)

```sas
%macro _note_written_ds(ds=, label=);
  %local _nw;
  %let _nw = 0;
  %if %sysfunc(exist(&ds)) %then %do;
    proc sql noprint;
      select count(*) into :_nw trimmed from &ds;
    quit;
    %if &_nw > 0 %then
      %put NOTE: [03_import] &label written (&_nw rows);
    %else
      %put WARNING: [03_import] &label written but has 0 rows;
  %end;
  %else
    %put WARNING: [03_import] &label was NOT written;
%mend _note_written_ds;
```

### Verified Pattern: INFILE UTF-8 CSV (from 02_source_guard.sas Section 6, line 697-700)

```sas
data _null_;
  infile "&_full" obs=1 dsd dlm=',' truncover
         lrecl=32767 encoding='utf-8';
  input;
  _line = _infile_;
  call symputx('_rawhdrs', _line, 'L');
  stop;
run;
```

### Verified Pattern: %pdd_norm_psid (from 00_config.sas Section 8)

```sas
%pdd_norm_psid(in=pdd.src_s01, out=pdd.src_s01, idvar=PRECEDE_STUDY_ID);
/* Assert _ndis = 0 after each call */
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | SAS log assertions via %put / %fail_out (no external test runner) |
| Config file | none — inline assertion macros per program |
| Quick run command | `sas -config "...\nls\u8\sasv9.cfg" -sysin "C:\data_dictionary\sas\03_import.sas"` |
| Full suite command | `run_pipeline.cmd` (calls 99_run_all.sas which chains all phases) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| PDD-03-R01 | All 20 pdd.src_s* exist after run | smoke | `%_note_written_ds` for each | In-program assertion |
| PDD-03-R02 | ID/code cols have type='char' | unit | `dictionary.columns` check after each import | Assert in spec-gen |
| PDD-03-R03 | UTF-8 session active | smoke | `%check_encoding` at program start | Aborts if wrong |
| PDD-03-R04 | s19 row counts: kept + dropped = total | unit | `%put NOTE` count check | In-program after filter |
| PDD-03-R05 | pdd.src_* row counts match pdd.source_inventory | unit | PROC SQL compare per file_code | QC dataset |
| PDD-03-R06 | s01 41,423 rows; s08 3,456 rows | unit | `%put NOTE` count check | In-program |
| PDD-03-R07 | s04/s05 imported; no PCNR_ derivation | smoke | dataset exists; no pcnr_ col names | In-program |
| PDD-03-R08 | pdd.qc_s06_groups written; qc\s06_column_groups.xlsx exists | smoke | `%_note_written_ds` + fileexist | In-program |
| PDD-03-R09 | docs\import_spec.csv committed; readable by 03_import.sas | smoke | fileexist check at 03_import.sas start | In-program |
| PDD-03-R10 | pdd.src_s17 has enc_for_linkage col; raw ENCRYPTED_ENCOUNTER unchanged | unit | `dictionary.columns` + spot check | In-program |

### Wave 0 Gaps

None — test infrastructure is inline SAS assertions consistent with Phase 2 style. No external
test files needed.

---

## Open Questions

1. **The 6 s17 ENCRYPTED_ENCOUNTER ambiguous values — where are they stored?**
   - What we know: Phase 2 identified them (key_analysis grain='multi-row' for ENCRYPTED_ENCOUNTER
     in s17).
   - What's unclear: Are they stored in pdd.key_analysis or only in the Phase 2 log? Planner must
     confirm how 03_import.sas reads them at runtime.
   - Recommendation: In 03a_build_spec.sas, extract the 6 values from pdd.key_analysis into a
     DATALINES table committed to git (no PHI — encrypted tokens only). 03_import.sas reads this
     table to apply PDD-D-20.

2. **Raw pre-pass memory for wide CSV files**
   - What we know: s06 (3,987 cols) is XLSX — pre-pass not needed. Widest CSV files are unknown.
   - What's unclear: Which CSV has the most columns?
   - Recommendation: Run `proc sql; select file_code, max(col_order) from pdd.header_inventory
     where ftype='csv' group by file_code; quit;` in Task A to determine worst-case width.
     If any CSV > 500 columns, batch the pre-pass.

3. **03a standalone or Section 1 of 03_import.sas?**
   - Recommendation: Separate 03a_build_spec.sas. Spec generation is a one-time derivation;
     import is repeatable. Keeping them separate lets Gerard edit import_spec.csv between runs
     without re-triggering the expensive pre-pass.

---

## Sources

### Primary (HIGH confidence)
- `sas/00_config.sas` — %pdd_norm_psid, %check_encoding, %check_pdd_lib, path macros (read 2026-10-19)
- `sas/02_source_guard.sas` — LIBNAME XLSX pattern, INFILE/INPUT pattern, %fail_out, _note_written_ds, CALL EXECUTE loop pattern, _s19_nonblank_pre, sheet-name quoting (read 2026-10-19)
- `.planning/phases/03-direct-import-of-the-20-sources/03-CONTEXT.md` — all locked decisions (read 2026-10-19)
- `.planning/PROJECT.md` — source file table, locked decisions PDD-D-01..PDD-D-21 (read 2026-10-19)
- `.planning/REQUIREMENTS.md` — PDD-03 requirement table (read 2026-10-19)

### Secondary (MEDIUM confidence)
- SAS 9.4 CALL EXECUTE documentation (behaviour verified against existing Phase 2 macro patterns that use CALL EXECUTE-style deferred execution)
- SAS 9.4 LIBNAME XLSX engine documentation (behaviour confirmed by Phase 2 successful XLSX imports)

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use in Phase 2; no new dependencies
- Architecture patterns: HIGH — all patterns extracted directly from existing project code
- Pitfalls: HIGH — derived from Phase 2 code comments (PCM compliance notes) and SAS documented behaviours

**Research date:** 2026-10-19
**Valid until:** Stable — SAS 9.4 APIs do not change; re-verify only if SAS version changes
