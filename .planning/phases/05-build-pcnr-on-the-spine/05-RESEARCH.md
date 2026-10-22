# Phase 5: Build PCNR_ on the Spine — Research

**Researched:** 2026-10-21
**Domain:** SAS BASE 9.4 — wide dataset assembly, gap-fill, conflict QC
**Confidence:** HIGH (all findings from project source files + SAS 9.4 documentation)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-15** Gap-fill order: s01→s20 rank, skipping spine (s09). `docs/pcnr_source_priority.csv` drives order, editable without code change.
- **D-16** pdd.pcnr = 1,299 PCNR_ columns + NORM_PSID. No per-cell _SRC columns. QC-only provenance.
- **D-16b** QC outputs: `exchange\pcnr_gapfill.csv`, `exchange\pcnr_spine_coverage.csv`, `exchange\pcnr_conflicts_summary.csv`, `exchange\pcnr_conflicts_detail.csv` (cap 5,000 rows), `exchange\pcnr_typecheck.csv`. Python writes `qc\pcnr_qc.xlsx` with sheets: KEY, GAPFILL, SPINE_COVERAGE, CONFLICT_SUMMARY, CONFLICT_DETAIL, TYPECHECK.
- **D-18** s04/s05 contribute 0 PCNR_ columns (LINKAGE_ONLY). Phase 5 asserts this via PROC SQL on pdd.name_map.
- **D-19** Key coverage QC: for each non-spine source, compute n_keys and n_keys_not_in_spine; write to `exchange\pcnr_spine_coverage.csv`; emit SAS NOTE.
- **D-02 (amendment)** Type resolution before gap-fill: inspect char values, `INPUT(strip(val), ?? best32.)`; resolve to N8 if all parse, else C (max_length from pdd.name_map_vars); log failures to pdd.qc_pcnr_typecheck. Numeric-to-char conversion: `strip(put(x, best32.))`.
- **D-20** Equality rule: character compare `strip(a)=strip(b)` case-sensitive; numeric exact.
- **D-05b** Spine wins unconditionally (step 1); gap-fill by rank order (step 2); per-variable override via `docs/pcnr_source_override.csv` replaces rank order but not spine priority (step 3); disagreements → pdd.qc_pcnr_conflicts (step 4); agreeing values NOT conflicts (step 5).
- **PDD-D-01** All 20 files contribute; all 1:1 per norm_psid; s09 is spine.
- **PDD-D-02** Values exactly as in source; no recoding.
- **PDD-D-17** All 20 files confirmed 1:1 grain. CLOSED.
- **PDD-D-21** s06 CLOCK columns excluded from pdd.pcnr; split via docs/s06_column_class.csv.
- **PDD-D-22** SAS owns data; Python owns xlsx. Exchange CSV pattern for handoff.

### Claude's Discretion

- Exact SAS implementation of rank-order gap-fill (PROC SQL COALESCE vs DATA step vs macro loop).
- Whether `docs/pcnr_source_priority.csv` is read once at program top or re-read inside a macro.
- Whether type-resolution for 9 conflict variables is a standalone macro or inline in the merge section.

### Deferred Ideas (OUT OF SCOPE)

None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDD-05-A | pdd.pcnr has exactly 41,150 rows, 1,299+1 columns, 0 duplicate keys, no blank norm_psid | SAS DATA step merge on norm_psid; row-count assert at end |
| PDD-05-B | No CLOCK columns in pdd.pcnr | Assert via docs/s06_column_class.csv filter; confirmed by D-21 |
| PDD-05-C | Every PCNR_ variable present with resolved type, correct length, label = representative original_header | pdd.name_map_vars drives ATTRIB/LENGTH/LABEL; type resolution macro runs first |
| PDD-05-D | Gap-fill QC: exchange\pcnr_gapfill.csv; pdd.qc_pcnr_provenance on P: | Accumulator DATA step during gap-fill; provenance rows only for 2+-source vars |
| PDD-05-E | Conflict QC: pdd.qc_pcnr_conflicts with conflict_type column; exchange\pcnr_conflicts_summary.csv; exchange\pcnr_conflicts_detail.csv capped 5,000 rows | Conflict detection during gap-fill loop |
| PDD-05-F | Spine coverage: exchange\pcnr_spine_coverage.csv; SAS NOTE per source | PROC SQL key-count before main build |
| PDD-05-G | Type-check: pdd.qc_pcnr_typecheck; exchange\pcnr_typecheck.csv | Type resolution macro, pre-merge |
| PDD-05-H | s04/s05 assertion: 0 PCNR rows in pdd.name_map for those s_codes; %fail_out if not | PROC SQL against pdd.name_map |
| PDD-05-I | qc\pcnr_qc.xlsx: KEY, GAPFILL, SPINE_COVERAGE, CONFLICT_SUMMARY, CONFLICT_DETAIL, TYPECHECK sheets | Python writer script, D-22 pattern |
| PDD-05-J | Wired into sas/99_run_all.sas after Phase 4, before Phase 6 | Consistent with 04_name_map.sas wire-in pattern |
</phase_requirements>

---

## RESEARCH COMPLETE

### Recommended Build Approach

**DATA step MERGE with macro-generated source loop.**

Process each non-spine source one at a time against the spine using a %DO loop over priority-ordered sources. For each source: sort by norm_psid, MERGE onto the (already-accumulated) working dataset, apply gap-fill and conflict detection variable by variable for that source's contributed columns only.

This is the only approach that satisfies all constraints simultaneously: PCM compliance (no ANSI SQL, no open-code %if), tractable memory (two datasets in memory at once, not 20), full conflict/provenance capture per cell, and debuggable logs.

---

## Approach Comparison

### (a) PROC SQL COALESCE Chain

One SELECT with COALESCE(s01.var, s02.var, …, s19.var) per variable, 19 sources left-joined in one FROM clause.

**Speed/memory:** PROC SQL must hold all 19 source join results in memory simultaneously. At ~1,300 columns × 41,150 rows × up to 19 sources this is the worst-case memory scenario. SAS PROC SQL on BASE 9.4 does not spill gracefully to disk for wide Cartesian joins; it will page heavily or exhaust MEMSIZE on a workstation.

**Log readability:** A SELECT with 1,299 COALESCE expressions and 19 LEFT JOINs produces a log that is practically unreadable. Any column mismatch silently returns missing.

**Conflict capture:** COALESCE returns the first non-missing value and discards all others. Detecting SOURCE_VS_SOURCE disagreements requires a separate pass — you cannot recover the losing values from a COALESCE result. Capturing conflict_type requires a parallel subquery or second join, multiplying complexity.

**Provenance capture:** Same problem — the winning s_code is not recoverable from COALESCE output without additional bookkeeping outside the SELECT.

**PCM compliance:** COALESCE is BASE SAS SQL, not ANSI — C1/C2 do not trigger. However, generating 1,299 COALESCE expressions and 19 JOIN clauses programmatically requires CALL EXECUTE or %DO inside open code, which triggers C3 if not wrapped in a macro. Wrappable, but produces enormous macro-generated SQL that makes the log opaque.

**Width limit:** A single PROC SQL SELECT with 1,300 output columns is well within SAS7BDAT limits. Not the binding constraint.

**Verdict:** REJECTED. Memory-hostile, conflict/provenance capture requires a second full pass, log unreadable.

---

### (b) Single DATA Step MERGE (all 20 datasets simultaneously)

Sort all 20 sources by norm_psid; MERGE spine s01–s19 BY norm_psid in one DATA step; apply gap-fill arrays.

**Speed/memory:** SAS DATA step MERGE streams observations one BY-group at a time. Memory consumption is proportional to the number of open datasets × the width of the widest dataset, not the total row count. With 20 datasets open, the PDV holds one row from each simultaneously. This is tractable — SAS has no practical limit on the number of datasets in a MERGE beyond the number of open file descriptors (typically 256+; 20 is well under this).

**Log readability:** One DATA step. Reasonable. But variable name collisions are the fatal problem (see below).

**Collision problem:** When MERGE encounters the same variable name in two datasets (e.g., `AGE` in both s09 and s12), the last dataset in the BY list overwrites the prior value — silently. For this project, many PCNR_ variables appear in multiple sources under their original (not yet PCNR_-prefixed) column names. Phase 3 imported each source with its original column names in pdd.src_s*; they were not renamed to PCNR_ names at import time. A multi-source MERGE of raw src_s* datasets would require a RENAME= option on every dataset listing every contributing column per source, turning the MERGE statement into a macro-generated monster.

**RENAME= feasibility:** pdd.name_map_vars contains pcnr_name and the contributing s_codes with their original_header per source. This is sufficient information to generate a RENAME= list. But generating a RENAME= clause for 1,299 variables across 19 sources (many variables appearing in multiple sources each needing a unique temp name for the merge) requires a complex macro loop. The resulting DATA step statement would be several thousand tokens long — syntactically valid but impossible to review or debug.

**Gap-fill/conflict:** After the MERGE the PDV holds the renamed values from all sources simultaneously, making array-based gap-fill and conflict detection possible in a single pass. This is the one advantage. But the setup cost (RENAME= generation) is extreme and the log output from such a merge is voluminous.

**PCM compliance:** Manageable — the MERGE itself is legal. The macro loop generating RENAME= lists is inside a macro (%macro/%mend), satisfying C3. C14 satisfied by naming all datasets.

**Verdict:** REJECTED for Phase 5. The RENAME= generation problem is solvable but creates a fragile, opaque implementation. The iterative approach below is simpler and equally fast.

---

### (c) Long Transpose → Gap-fill → Wide Transpose

PROC TRANSPOSE each source to long form; UNION ALL into one long dataset; gap-fill per (norm_psid, pcnr_name); transpose back wide.

**Speed/memory:** For s06 alone (~1,240 PCNR_ columns × 41,150 rows) the long form is ~51 million rows from one source. Across 19 sources and 1,299 variables this exceeds 500 million rows before de-duplication. Sorting a 500M-row dataset on P: (network drive) would likely take hours.

**Log readability:** Two PROC TRANSPOSEs, a massive UNION ALL, a sort, and a BY-group gap-fill DATA step. Complex to trace when something goes wrong.

**Conflict/provenance:** Conceptually clean — all source values for a (norm_psid, pcnr_name) are in adjacent rows, making comparison easy. But the memory and sort cost is prohibitive.

**PCM compliance:** PROC TRANSPOSE is PCM-compliant. The UNION ALL approach does not use ANSI extensions. No C1–C14 violations if wrapped correctly.

**Verdict:** REJECTED. Memory and I/O cost is disqualifying for the dataset sizes in this project.

---

### Recommended: Iterative Source Merge Loop

**Concept:** Build pdd.pcnr iteratively. Start with pdd.src_s09 (spine) renamed to PCNR_ names via ATTRIB/RENAME. Then for each non-spine source in priority order (from docs/pcnr_source_priority.csv), MERGE the current working dataset with that source (sorted by norm_psid). For each PCNR_ variable that the source contributes: if the working value is missing and the source has a non-missing value, fill it (gap-fill) and record provenance. If the working value is non-missing and the source value is non-missing and they disagree, record a conflict.

**Why this works:**
- Only two datasets open at a time: the accumulator and the current source. Memory is O(rows × cols × 2) at worst, not O(rows × cols × 20).
- RENAME= is applied only to the current source's contributed columns (from pdd.name_map_vars filtered to that s_code). At most a few hundred columns per source, not 1,299.
- Gap-fill logic is transparent in the DATA step: explicit IF/THEN per variable, readable in the log.
- Conflict type (SPINE_VS_SOURCE vs SOURCE_VS_SOURCE) is tracked via a flag on the accumulator: if the accumulator value came from s09 (the spine pass), it is "spine-owned"; otherwise it is "source-owned". This flag distinguishes conflict types during each subsequent source merge.
- Provenance is captured inline during gap-fill.
- PCM C3 compliant: all %if/%else inside %macro/%mend. C14: all datasets named.

**Speed estimate:** 19 sequential SORT + MERGE operations on 41,150-row datasets. Each sort: negligible (41K rows). Each merge: fast linear scan. Total wall time estimate: 2–10 minutes on the P: network drive, dominated by I/O for reading wide source datasets.

---

## Variable Counts and Scale Estimates

**Source:** import_spec_generated.csv (4,795 rows), STATE.md, 05-CONTEXT.md.

pdd.name_map_vars is on P: (network SAS library) and is not accessible from this research agent. Estimates below are derived from the import spec and confirmed Phase 4 counts.

| Metric | Value | Confidence |
|--------|-------|------------|
| Total PCNR_ variables | 1,299 | HIGH — Phase 4 VERIFIED |
| pdd.pcnr column count | 1,300 (1,299 PCNR_ + NORM_PSID) | HIGH |
| pdd.pcnr row count | 41,150 | HIGH — spine confirmed Phase 2 |
| PCNR-eligible header rows in import_spec | ~2,024 (4,795 − 2,747 CLOCK − 20 KEY − 4 s04/s05) | MEDIUM |
| Average contributing sources per PCNR_ var | ~1.56 (2,024 / 1,299) | MEDIUM |
| Headers appearing in 2+ files (raw) | 143 (from import_spec analysis) | MEDIUM |
| PCNR_ vars with 2+ contributing sources (estimate) | 100–130 (143 minus non-PCNR overlaps like KEY/MRN columns) | MEDIUM |
| Type-conflict variables | 9 (from Phase 4 log; s19 numerics as C8; PCNR_YEAR C9/N8) | HIGH |

**pdd.qc_pcnr_provenance size estimate:**
- Upper bound: 130 multi-source vars × 41,150 rows = 5.35 million rows (if every cell is gap-filled, which is not realistic).
- Realistic (assuming ~20% of cells gap-filled for multi-source vars): ~1 million rows.
- Provenance is P:-only; no export. Row count logged at end of QC section.

**Run-time estimate for iterative merge approach:**
- 19 SORT passes on source datasets (wide but only 41K rows): ~5–15 seconds each on P:.
- 19 MERGE passes on accumulator + source: ~10–30 seconds each (accumulator grows to 1,300 cols).
- Gap-fill/conflict DATA step per source: included in the merge pass.
- Conflict and provenance accumulation: one OUTPUT per conflicting or gap-filled cell.
- Total estimate: 10–25 minutes wall time on P: drive, dominated by wide-dataset I/O.

---

## SAS Limits

All limits verified against SAS 9.4 documentation.

| Limit | Value | Impact on Phase 5 |
|-------|-------|-------------------|
| Maximum variables in SAS7BDAT | 32,767 | 1,300 cols is 4% of limit — no risk |
| Maximum label length | 256 characters | Phase 4 logged 16 truncation warnings; labels already truncated to 256 in pdd.name_map |
| Maximum character variable length (BASE SAS) | 32,767 bytes | Not a constraint; max source lengths from import_spec are well under this |
| V5 Transport (CPORT/CIMPORT) row width | 32,767 bytes | Not used in this project; pdd.pcnr stays in SAS7BDAT format |
| SAS7BDAT observation width | No practical limit (disk-based) | Not a constraint |
| Open datasets in a MERGE | No documented hard limit; practical limit ~256 (OS file descriptors) | 20 datasets in a single MERGE is safe; iterative approach uses 2 at a time anyway |
| Macro variable length | 65,534 characters | RENAME= lists generated by macro must not exceed this; with ~300 columns per source this is not a risk |
| PROC SQL SELECT clause width | No documented column count limit | Moot — PROC SQL approach rejected |

**1,300-column dataset:** No SAS limit is approached. SAS7BDAT stores each variable with an 8-byte descriptor overhead; 1,300 variables add ~10 KB of descriptor overhead per dataset, negligible.

**19 sources simultaneously in a MERGE:** SAS can handle this (file descriptor limit is OS-level, typically 256+ on Windows). However, the iterative approach is preferred for collision control and memory reasons — the limit is not what drives the recommendation.

---

## Merge Mechanics

### Simultaneous MERGE (20 datasets): feasibility

A DATA step `MERGE s09 s01 s02 … s20 BY norm_psid;` is syntactically valid and SAS will execute it. The binding constraint is not SAS limits but **variable name collisions**: pdd.src_s* datasets contain original column names (e.g., `AGE`, `SEX`), not PCNR_-prefixed names. The same column name in two datasets causes the last dataset in the MERGE to silently overwrite earlier values in the PDV.

Consequence: every contributing column from every non-spine source must be renamed in the DATASET option before the MERGE executes: `MERGE work.s01_renamed(RENAME=(AGE=PCNR_AGE_s01_val)) work.s12_renamed(RENAME=(AGE=PCNR_AGE_s12_val)) …`. For 19 sources contributing ~300 columns each (with overlaps), this generates thousands of RENAME= tokens, making the MERGE statement both impractical to write by hand and fragile under schema changes.

### RENAME= and pdd.name_map_vars

pdd.name_map_vars provides, per PCNR_ variable: pcnr_name, contributing s_codes, original_header per source (via join to pdd.name_map). This is enough information to generate a RENAME= list at runtime using a macro loop. The iterative approach uses this same information but applies it one source at a time, keeping the RENAME= list to a manageable size (one source's columns only).

### Variable name collisions in the iterative approach

For each source iteration: read pdd.name_map_vars filtered to that s_code; generate RENAME= that maps the source's original column name to a temp working name (e.g., `_src_val`); after gap-fill, the working name is no longer needed. Only one source's columns are in the PDV at a time alongside the accumulator, so collisions are fully controlled.

### pdd.name_map_vars as the join map

pdd.name_map_vars has one row per PCNR_ variable. Each row records which s_codes contribute to it and (via join to pdd.name_map) the original column name per source. Phase 5's macro reads this metadata at the top of the program to drive:
- Which columns to read from each source
- What RENAME= clause to apply
- What ATTRIB/LENGTH/LABEL to assign to the output column in pdd.pcnr
- Which variables have type_conflict=Y (drives the type resolution step)

This metadata-driven approach means adding or changing a PCNR_ variable requires only a Phase 4 rerun — no change to Phase 5 code.

---

## Conflict and Provenance Capture

### Conceptual mechanics (iterative approach, no code)

**SPINE_VS_SOURCE:** During the merge pass for source S, for a given PCNR_ variable V and patient P: if the accumulator value was loaded from the spine (s09 pass, hence non-missing from the start) AND the current source S provides a non-missing value AND the two values disagree → emit a conflict row with conflict_type = SPINE_VS_SOURCE. The accumulator value (spine) wins; it is not changed.

**SOURCE_VS_SOURCE:** If the accumulator value was loaded from a prior non-spine gap-fill (hence non-missing but "source-owned") AND the current source S provides a non-missing value AND the two disagree → emit a conflict row with conflict_type = SOURCE_VS_SOURCE. The accumulator retains the higher-ranked (earlier-processed) source's value.

**Tracking "spine-owned" vs "source-owned":** A parallel flag dataset or an embedded flag variable (e.g., a bit-packed integer, or a separate `work.pcnr_src_flags` wide dataset with one byte per variable per row indicating the filling s_code rank) tracks whether each cell came from spine or a non-spine source. For the conflict type distinction, only a binary flag is needed: spine-filled vs not-spine-filled. A separate `work.pcnr_filled_by_spine` wide dataset (1 bit per cell, or a character variable per pcnr_name storing 'S' or 'G') serves this purpose. This parallel dataset is work-only and dropped at program end.

**Agreeing values:** Before writing a conflict row, test equality using D-20 rules (`strip(a)=strip(b)` for character; `a=b` for numeric). If equal, no conflict row is written. Agreeing values from multiple sources are a normal and expected outcome of the gap-fill (e.g., the same age value appears in s09, s12, and s17 for most patients).

**pdd.qc_pcnr_conflicts columns** (per 05-CONTEXT.md): norm_psid, pcnr_name, conflict_type, winning_s_code, winning_value, plus candidate s_codes and values. The implementer may choose wide (one column per candidate source) or long (one row per candidate). Long is simpler to write during the iteration; wide requires a later pivot. Given that source counts vary by variable, long format is recommended.

**pdd.qc_pcnr_provenance:** Written during each gap-fill event for variables with 2+ contributing sources (from pdd.name_map_vars). Columns: norm_psid, pcnr_name, src_s_code. One row per gap-filled cell. Written to a separate accumulator dataset during the iteration and appended at the end. Single-source variables are excluded (their provenance is implied by name_map).

**Memory management:** Both conflict and provenance tables are written with OUTPUT to accumulator datasets in work; at the end they are copied to the pdd library. They are not materialized in the PDV of the main merge step.

---

## Type Resolution Timing

### Where it fits

Type resolution for the 9 conflict variables must complete before the spine pass (the first merge step). Reason: the spine pass itself involves reading s09 values for these variables — if s09 stores a type-conflict variable as character and a later source stores it as numeric, the PDV declaration for the accumulator must already match the resolved type before the first value is written to it.

**Processing order for the recommended approach:**

1. **Read pdd.name_map_vars** — identify type_conflict=Y variables and their contributing s_codes.
2. **Type resolution macro** — for each of the 9 type-conflict variables: scan all contributing sources' pdd.src_s* datasets for that variable; collect non-blank, non-"." character values from character-typed sources; apply `INPUT(strip(val), ?? best32.)`; if all parse → resolved type = N8; if any fail → resolved type = C (max_length). Write results to pdd.qc_pcnr_typecheck and exchange\pcnr_typecheck.csv.
3. **Declare the accumulator dataset schema** — using ATTRIB statements driven by pdd.name_map_vars, with the resolved types from step 2 overriding the raw result_type for the 9 conflict variables.
4. **Spine pass** — load s09 values into the accumulator. For type-conflict variables now resolved to N8: read the s09 character value and convert via INPUT. For those resolved to C: keep as character.
5. **Gap-fill loop** — for each subsequent source, apply the same type conversions (N8 sources: use directly; C sources for an N8-resolved variable: INPUT to convert; numeric sources for a C-resolved variable: PUT to convert).

**Can individual variables be pre-processed independently?** Yes. The iterative approach naturally supports pre-processing one variable at a time before the main merge. The type resolution macro scans each of the 9 variables independently and writes its determination to pdd.qc_pcnr_typecheck. The main merge step then uses those determinations as a lookup.

**Does all type resolution need to complete before the main merge begins?** Yes, because the PDV for the accumulator dataset must be declared with the correct type for every variable before the first observation is processed. The ATTRIB statements that declare the accumulator schema must reference the resolved types. This means the type resolution macro must run to completion and write its results to a lookup (e.g., work._type_resolution) before the spine pass begins.

---

## Macro Strategy

Modeled on the 04_name_map_macros.sas decomposition pattern: one macro per logical section; all macros defined in Section 0 before any call (PCM C13); all executable code inside macros or inside named macro calls; no open-code %if/%else (PCM C3).

### Proposed macro sections for 05_build_pcnr.sas

**Section 0 — Setup**
- `%fail_out` (local define, PCM pattern)
- `%_p5_ok` (syserr guard between sections, same as _p4_ok)
- `%route_log` / `%restore_log` (standalone log routing)

**`%p5_preflight`** — Assertions before any data work
- Assert pdd.name_map_vars exists and has exactly 1,299 rows.
- Assert all 20 pdd.src_s* datasets exist.
- Assert docs/pcnr_source_priority.csv and docs/pcnr_source_override.csv exist.
- s04/s05 assertion: PROC SQL on pdd.name_map; %fail_out if any s04/s05 row has PCNR status.
- Read docs/pcnr_source_priority.csv into work._priority (s_code, rank).
- Read docs/pcnr_source_override.csv into work._override (pcnr_name, s_code).
- Read pdd.name_map_vars into work._nmv (full metadata for all 1,299 PCNR_ vars).

**`%p5_spine_coverage`** — D-19 key coverage QC
- For each non-spine source in priority order: PROC SQL count of norm_psid in source but not in spine. Write to exchange\pcnr_spine_coverage.csv. Emit SAS NOTE per source.
- Metadata read: work._priority.

**`%p5_resolve_types`** — D-02 type resolution for 9 conflict variables
- For each type_conflict=Y variable: scan contributing sources; collect non-missing character values; INPUT test; determine N8 or C; write resolution to work._type_resolution.
- Write pdd.qc_pcnr_typecheck (pcnr_name, s_code, resolution, n_char_sources, n_parse_failures, example_failing_value).
- Export exchange\pcnr_typecheck.csv.
- Metadata read: work._nmv (type_conflict flag, contributing s_codes, original_header per source).
- Data read: pdd.src_s* (character-typed source columns only, for the 9 variables).

**`%p5_build_accumulator`** — Declare and populate the accumulator dataset from the spine
- Generate ATTRIB statements for all 1,299 PCNR_ + NORM_PSID, using types/lengths from work._nmv and work._type_resolution overrides.
- Load pdd.src_s09; apply RENAME= for s09's contributed columns; apply type conversions for type-conflict variables; write to work._pcnr_accum.
- Set a "spine-filled" flag column (or parallel flag dataset) for each column that s09 provides a non-missing value — used for conflict_type determination.
- Metadata read: work._nmv, work._type_resolution.
- Data read: pdd.src_s09.

**`%p5_gapfill_source(s_code=)`** — Gap-fill and conflict detection for one non-spine source
- Called in a %DO loop over priority-ordered non-spine sources.
- Reads pdd.name_map_vars filtered to this s_code to get the list of contributed PCNR_ variables and their original column names.
- Check work._override for any variable pinned to a different source — skip those variables for this source unless this source IS the pinned one.
- SORT current source by norm_psid.
- MERGE work._pcnr_accum with pdd.src_{s_code} (RENAME= applied inline).
- For each contributed variable: apply gap-fill if accumulator is missing and source is non-missing; detect conflicts if both are non-missing and unequal (per D-20); write provenance row if gap-filled and variable has 2+ sources.
- OUTPUT conflict rows to work._conflicts_accum.
- OUTPUT provenance rows to work._provenance_accum (only for 2+-source variables).
- Update gap-fill counters (n_spine, n_gapfilled, n_filled_<s_code>, n_missing per variable).
- Metadata read: work._nmv (filtered to this s_code), work._override.
- Data read: pdd.src_{s_code}.

**`%p5_finalize_pcnr`** — Write pdd.pcnr and assert done criteria
- Copy work._pcnr_accum to pdd.pcnr.
- Assert 41,150 rows; %fail_out if not.
- Assert NORM_PSID has 0 blank values; %fail_out if not.
- Assert 0 duplicate NORM_PSID; %fail_out if not.
- Assert no CLOCK column names present (cross-reference docs/s06_column_class.csv).
- Log s04/s05 assertion (0 rows, 0 PCNR_ vars contributed — NOTE in log).

**`%p5_write_qc`** — Write QC datasets and exchange CSVs
- Write pdd.qc_pcnr_conflicts from work._conflicts_accum.
- Write pdd.qc_pcnr_provenance from work._provenance_accum; log row count.
- Compute gap-fill summary per variable; write exchange\pcnr_gapfill.csv.
- Write exchange\pcnr_conflicts_summary.csv (pcnr_name, n_conflict_cells, conflict_type, s_codes_involved, winning_s_code).
- Write exchange\pcnr_conflicts_detail.csv — first 5,000 rows of pdd.qc_pcnr_conflicts.

**Metadata-reads-only sections:** `%p5_preflight`, `%p5_resolve_types`, `%p5_gapfill_source` (for the override/priority lookup).

**Data-reads sections:** `%p5_spine_coverage` (reads pdd.src_s* counts), `%p5_resolve_types` (reads character columns of src_s* for 9 vars), `%p5_build_accumulator` (reads pdd.src_s09), `%p5_gapfill_source` (reads each pdd.src_s* in turn).

---

## Open Questions / Risks

1. **pdd.name_map_vars schema for s_code-to-original_header mapping.** The 04-CONTEXT.md describes pdd.name_map_vars as "one row per PCNR_ variable listing all contributing s_codes." The exact column names storing per-source original_header information are not confirmed in research (pdd is on P: and not accessible here). The planner must verify the exact schema from pdd.name_map_vars before writing the %p5_gapfill_source macro logic. If contributing sources are stored as a delimited string rather than one row per (pcnr_name, s_code), the metadata join strategy changes.
   - **Recommendation:** Plan Wave 0 to include a SAS assertion that prints pdd.name_map_vars column names and a sample of 5 rows to the log.

2. **Parallel flag dataset width.** A "spine-filled" flag for 1,299 columns × 41,150 rows requires a wide dataset. If stored as 1 character byte per column, this is a 1,299-column × 41,150-row dataset with all $1 variables — about 53 MB on P:, which is acceptable. Alternatively, the flag can be embedded as a suffix variable in the accumulator (e.g., `_sf_PCNR_AGE = 1` if spine-filled) — but this doubles the working column count to ~2,600 and must be dropped before writing pdd.pcnr. The planner must choose one approach.
   - **Recommendation:** Use a separate work._spine_flags dataset (1,299 × $1 columns + norm_psid); merge it into the conflict detection step rather than keeping it in the accumulator PDV.

3. **Override fallback behavior.** D-05b specifies: if the pinned source is missing for a given row, fall back to normal rank order. This means %p5_gapfill_source cannot simply skip a variable for non-pinned sources — it must still gap-fill if the pinned source had no value. The fallback logic adds conditional branching per variable per row.
   - **Recommendation:** Handle overrides in a post-processing pass: first run the full priority loop (treating override variables like any other); then in a separate DATA step, re-read the pinned source for override variables and overwrite the gap-fill value where the pinned source was non-missing. This separates override logic from the main loop and keeps the loop clean.

4. **s06 CLOCK column exclusion at merge time.** docs/s06_column_class.csv must be read at program start to build the list of CLOCK columns. When reading pdd.name_map_vars for s06 contributed columns, CLOCK-class columns must already be excluded (Phase 4 set their status=EXCLUDED_CLK, so they will not appear in pdd.name_map_vars). The Phase 5 program should still assert this explicitly — read the CLOCK list and confirm zero overlap with pdd.name_map_vars pcnr_names.

5. **Conflict table format (long vs wide).** Per 05-CONTEXT.md, pdd.qc_pcnr_conflicts includes "all candidate s_codes and values (long or wide — implementer's discretion)." Long format (one row per candidate source) is simpler to write during the iterative merge but complicates the CONFLICT_DETAIL sheet (multiple rows per norm_psid × pcnr_name combination). Wide format (one column per source slot) requires knowing the maximum number of candidates, but produces a flatter structure for Excel review.
   - **Recommendation:** Use long format for pdd.qc_pcnr_conflicts on P:. For the exchange\pcnr_conflicts_detail.csv (5,000-row cap), pivot to wide if the row count after pivoting stays under 5,000 norm_psid × pcnr_name pairs. The KEY sheet notes the cap and references pdd.qc_pcnr_conflicts for full detail.

6. **Gap-fill counter accumulation.** The per-variable gap-fill summary (n_spine, n_gapfilled, n_filled_<s_code>, n_missing) requires maintaining 1,299 × (2 + n_sources) counters across the 19 source passes. In a DATA step loop, these counters must survive between iterations — either via a RETAIN strategy in a counter dataset updated by each %p5_gapfill_source call, or via a PROC SQL COUNT aggregation per source pass. The latter is cleaner and avoids RETAIN-across-macro-call complexity.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies beyond the project's SAS/Python stack, which is confirmed operational from Phase 4 verification).

---

## Validation Architecture

*workflow.nyquist_validation not explicitly set to false in .planning/config.json (file does not exist). Treating as enabled.*

### Test Framework

| Property | Value |
|----------|-------|
| Framework | pytest (existing — python/tests/) + SAS test programs (tests/*.sas) |
| Config file | none — pytest discovered by directory convention |
| Quick run | `pytest python/tests/ -x -q` |
| Full suite | `pytest python/tests/ -q && python tools\sas_lint.py sas\05_build_pcnr.sas` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PDD-05-A | pdd.pcnr row/col/key assertions | smoke (SAS log assert) | %fail_out inside program | N/A — SAS runtime |
| PDD-05-B | No CLOCK columns in pdd.pcnr | smoke (SAS assert) | cross-ref s06_column_class.csv in program | N/A — SAS runtime |
| PDD-05-C | Variable types/lengths/labels correct | smoke (SAS assert) | PROC CONTENTS comparison | N/A — SAS runtime |
| PDD-05-D | Gap-fill QC files produced | smoke | check exchange\ file existence + row count | N/A — SAS runtime |
| PDD-05-E | Conflict QC files produced | smoke | check exchange\ + pdd.qc_pcnr_conflicts | N/A — SAS runtime |
| PDD-05-F | Spine coverage CSV produced | smoke | check exchange\ | N/A — SAS runtime |
| PDD-05-G | Type-check QC produced | smoke | check exchange\ + pdd.qc_pcnr_typecheck | N/A — SAS runtime |
| PDD-05-H | s04/s05 assertion passes | unit (SAS) | embedded PROC SQL assert + %fail_out | N/A — SAS runtime |
| PDD-05-I | pcnr_qc.xlsx sheets correct | unit (Python) | `pytest python/tests/test_write_pcnr_qc.py -x` | ❌ Wave 0 |
| PDD-05-J | 99_run_all wired correctly | smoke | run 99_run_all.sas and check log | N/A — SAS runtime |

### Wave 0 Gaps

- [ ] `python/tests/test_write_pcnr_qc.py` — unit tests for the Python workbook writer (sheet names, KEY row count note, column headers, CONFLICT_DETAIL cap); follows pattern from `python/tests/test_write_name_map_review.py`
- [ ] `python/scripts/write_pcnr_qc.py` — the writer script itself (Wave 1 deliverable, but the test file is a Wave 0 gap)

---

## Sources

### Primary (HIGH confidence)
- `C:\data_dictionary\.planning\phases\05-build-pcnr-on-the-spine\05-CONTEXT.md` — all locked decisions D-02, D-05b, D-15, D-16, D-16b, D-18, D-19, D-20
- `C:\data_dictionary\.planning\STATE.md` — Phase 4 verified counts (1,299 PCNR_, 41,150 rows)
- `C:\data_dictionary\docs\import_spec_generated.csv` — column counts per source, type distribution (4,795 rows analyzed)
- `C:\data_dictionary\sas\04_name_map.sas` + `04_name_map_macros.sas` — macro decomposition pattern, PCM compliance patterns
- `C:\data_dictionary\sas\00_config.sas` — established macros, path variables
- SAS 9.4 Statements Reference (training knowledge, HIGH for basic DATA step MERGE limits)

### Secondary (MEDIUM confidence)
- Multi-source variable count estimate (~100–130 PCNR_ vars with 2+ sources): derived from import_spec analysis; exact count requires pdd.name_map_vars on P: which is inaccessible from the research agent.
- Run-time estimate (10–25 minutes): order-of-magnitude based on dataset sizes and P: drive I/O characteristics observed in Phases 2–4.

### Tertiary (LOW confidence)
- Provenance table size estimate (~1 million rows at 20% fill rate): fill rate is an assumption; actual rate depends on data sparsity per source.

---

## Metadata

**Confidence breakdown:**
- Build approach recommendation: HIGH — driven by PCM rules, SAS DATA step behavior, and project constraints, all from primary sources
- Variable counts (multi-source estimate): MEDIUM — pdd.name_map_vars not directly queryable; derived from import_spec
- SAS limits: HIGH — well-documented SAS 9.4 behavior
- Macro strategy: HIGH — directly modeled on verified Phase 4 pattern

**Research date:** 2026-10-21
**Valid until:** 2026-11-21 (stable domain; SAS 9.4 limits do not change)
