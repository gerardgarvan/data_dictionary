# Phase 3: Direct import of the 20 sources — Context

**Gathered:** 2026-10-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `03_import.sas`: read all 20 source files from the strictly read-only shared folder into
`pdd.src_s01` … `pdd.src_s20` using explicit INFORMATs and LENGTHs derived from Phase 2 output.
No PROC IMPORT guessing. No recoding. Values exactly as in source (PDD-D-02).

Done when: all 20 `pdd.src_s*` datasets exist; row counts reconciled in QC; s06 column-group
profiling output written so Gerard can decide scope (PDD-D-21).

Blocks on PDD-D-18 for s04/s05 are resolved (see decisions). PDD-D-17 is fully closed.

</domain>

<decisions>
## Implementation Decisions

### PDD-D-17 — FULLY CLOSED (corrected 2026-10-19 discuss-3)
All 20 source files are 1:1 per PRECEDE_STUDY_ID. Phase 2 counts confirm:
- s01 (PACU_STAY): 41,423 rows, 41,423 distinct IDs — NOT multi-row. 274 IDs not in spine = QC item.
- s08 (COLONOSCOPY): 3,456 rows, 3,456 distinct IDs — NOT multi-row.
Both files join the spine in Phase 5 exactly like every other 1:1 source.
The "multi-row" assumption in earlier planning docs was incorrect; all references have been fixed.

### PDD-D-18 — LOCKED (discuss-3)
s04 (ENCOUNTER_Crypto) and s05 (MRN_Crypto) are **linkage/QC only** — not dictionary variables.
- Import into `pdd.src_s04` / `pdd.src_s05` for completeness and ID checking.
- No PCNR_ columns come from s04 or s05.
- s04/s05 matched 0 IDs in the 2022 files; the 2022 ID mismatch is fully resolved by PDD-D-19.
  Do not reference the 2022 mismatch in any s04/s05 logic.
- Whether s04/s05 are used in Phase 5 linkage is a Phase 5 decision; Phase 3 just imports them.

### PDD-D-21 — partial decision (discuss-3)
s06 (2018_2019_Precede_Database.xlsx, 3,987 columns) column-scope decision is deferred to after
the Phase 3 profiling output. 03_import.sas must produce a column-group profile before importing
s06 in full.

**Profile output required (write to `pdd.qc_s06_groups` and `qc\s06_column_groups.xlsx`):**
- One row per column-name group (group = shared prefix/suffix by naming pattern)
- Columns: group name, example column names (first 3), column count, inferred type, median % rows
  non-null across group columns, overlap count with columns already present in s03/s07 (the 2018-2019
  master and CPT rollup files)
- Sorted by column count descending
Gerard reviews this output and marks which groups to include before import of the full s06 column
set proceeds (may be a separate Phase 3 sub-task or Phase 4 pre-step).

### s18 duplicate/blank rows
`pdd.qc_s18_dup` already holds the 2 dup/blank PRECEDE_STUDY_ID rows from Phase 2.
03_import.sas must:
1. Log the 2 offending row IDs (or blank values) to the SAS log with a NOTE.
2. Exclude them from `pdd.src_s18` (import all other rows only).
3. Leave them in `pdd.qc_s18_dup` as-is for Gerard to review before Phase 5.
Do NOT silently drop or flag-and-keep — explicit log + QC dataset is the contract.

### INFORMAT/LENGTH derivation (D-new, locked discuss-3)
**Approach:** programmatic derivation from `pdd.header_inventory` → editable spec file.

Steps the planner must include:
1. A setup step reads `pdd.header_inventory` (from Phase 2) and generates
   `docs\import_spec.csv` — one row per (file, column) with: file_code (s01..s20), orig_col_name,
   sas_type (C/N), length, informat, format, notes.
2. Override rules applied during generation:
   - PRECEDE_STUDY_ID, Base_Procedure_Code_1, and any `*_ID` or `*_CODE` column → type C, length = max observed + 4 (headroom).
   - All other columns: type and length from Phase 2 inferred type and max observed length/value.
   - Length minimum: 8 for character, no minimum for numeric.
3. Gerard may hand-edit `docs\import_spec.csv` before running `03_import.sas` proper.
   The spec file is committed to git (no PHI, just metadata).
4. `03_import.sas` reads `docs\import_spec.csv` at runtime and generates DATA steps via
   CALL EXECUTE (or equivalent macro loop), one DATA step per source file.
5. Every INFILE uses `ENCODING='UTF-8'`.
6. `%pdd_norm_psid` (from `00_config.sas`) is applied to every file's PRECEDE_STUDY_ID
   after the raw import to produce `norm_psid` alongside the original ID (PDD-D-19).

### Locked import rules carried from earlier phases
- **PDD-D-02:** Values exactly as in source — no recoding. `?`, `NULL`, `Unknown` stay as values.
- **PDD-D-08:** s19 (ALL_AIM2, Sheet1 only): drop rows where PRECEDE_STUDY_ID is missing or all
  data columns are blank/`NULL`; log kept/dropped counts.
- **PDD-D-19:** Apply `%pdd_norm_psid` to all files; assert `_ndis = 0` (no disagreements after
  normalisation). Already asserted in Phase 2; Phase 3 must not break this.
- **PDD-D-20:** s17 — set the 6 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID to
  missing **for linkage only**; raw values remain unchanged in `pdd.src_s17`.
- **UTF-8:** Every INFILE uses `ENCODING='UTF-8'`. s06 is an xlsx; use PROC IMPORT or LIBNAME
  XLSX with explicit sheet selection.

### Claude's Discretion
- Exact column-group pattern-matching heuristic for s06 (prefix length, delimiter, fallback for
  no obvious pattern) — Claude chooses a reasonable approach.
- Whether `docs\import_spec.csv` is generated by a standalone macro or inline in `03_import.sas`
  Section 1 — Claude chooses.
- QC row-count reconciliation format (proc print, ODS table, or %put NOTE lines) — Claude chooses,
  consistent with Phase 2 style.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning source of truth
- `.planning/PROJECT.md` — Locked decisions PDD-D-01..PDD-D-21, constraints, source file table
- `.planning/ROADMAP.md` — Phase 3 acceptance criterion and done-when statement
- `.planning/REQUIREMENTS.md` — PDD-03 requirement table (explicit INFORMATs, UTF-8, s19, etc.)

### Prior phase context
- `.planning/phases/01-repo-and-config-scaffold/01-CONTEXT.md` — 00_config.sas pattern, path macros, in_pipeline guard
- `sas/00_config.sas` — `%pdd_norm_psid` macro (PDD-D-19), `%pdd_lib`, path macros — read before coding

### Phase 2 output (data on P: — not in git)
- `pdd.header_inventory` — column names, inferred types, max lengths per file; **primary input for spec generation**
- `pdd.source_inventory` — SHA-256, row counts, sheet lists (xlsx); use for QC row-count reconciliation
- `pdd.qc_s18_dup` — 2 dup/blank s18 rows; must remain untouched in Phase 3

### Reference implementation (read-only)
- `_reference_old/sas/00_config.sas` — Pattern for macro layout; do NOT copy data paths or g-library refs

No external ADRs or specs beyond the above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sas/00_config.sas`: `%pdd_lib`, `%pdd_norm_psid`, `%check_encoding`, `%check_pdd_lib`, all path
  macros — include at top of `03_import.sas`; do not redefine any of these macros locally.
- `sas/02_source_guard.sas`: pattern for reading P: files, PROC IMPORT xlsx sheets, logging — read
  for style reference before writing 03_import.sas.

### Established Patterns
- Every program: `%include "C:\data_dictionary\sas\00_config.sas";` then `%pdd_lib;`
- Per-program log redirect when `in_pipeline = 0` (see Phase 1 context)
- QC output: ODS Excel with UF colors (#0021A5, #FA4616); KEY sheet leftmost
- `%fail_out` pattern for fatal errors (defined locally in each program, called by check macros)

### Integration Points
- Output: `pdd.src_s01`…`pdd.src_s20` consumed by Phase 4 (name map) and Phase 5 (PCNR_ build)
- `docs\import_spec.csv` committed to git — readable by planner and executor without P: access
- `pdd.qc_s06_groups` and `qc\s06_column_groups.xlsx` → Gerard reviews before s06 full import
- Wire `03_import.sas` into `sas/99_run_all.sas` after the Phase 2 %include block

</code_context>

<specifics>
## Specific Ideas

- `docs\import_spec.csv` schema: columns = file_code, orig_col_name, sas_type, length, informat,
  format, notes. One row per (file × column). Gerard can add override rows.
- ID/code columns forced to character: PRECEDE_STUDY_ID, Base_Procedure_Code_1, any col matching
  `*_ID` or `*_CODE` pattern (case-insensitive).
- Character length headroom: max observed + 4 (guards against slightly longer values in future
  extracts without blowing up the spec).
- s06 group profiling overlap check: compare column names against `pdd.header_inventory` rows where
  file_code IN ('s03','s07') — those are the 2018-2019 master and CPT rollup already covering that
  cohort.
- Phase 3 QC note items (from PDD-D-19 run stats): s06 has 29 IDs not in spine; s11 has 1; these
  are expected — log them as NOTEs, not WARNINGs.

</specifics>

<deferred>
## Deferred Ideas

- Deciding which s06 column groups enter PCNR_ (PDD-D-21): deferred until Phase 3 profiling output
  is reviewed by Gerard. May require a Phase 3 sub-task or early Phase 4 step.
- s04/s05 linkage use in Phase 5: deferred to Phase 5 planning.
- PDD-D-15 (gap-fill tie-break order) and PDD-D-16 (per-cell source flag): Phase 5 decisions only.

None — discussion stayed within Phase 3 scope.

</deferred>

---

*Phase: 03-direct-import-of-the-20-sources*
*Context gathered: 2026-10-19*
