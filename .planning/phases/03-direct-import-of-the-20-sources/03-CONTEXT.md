# Phase 3: Direct import of the 20 sources — Context

**Gathered:** 2026-10-19
**Updated:** 2026-10-19 (pre-planning review)
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `03_import.sas`: read all 20 source files from the strictly read-only shared folder into
`pdd.src_s01` … `pdd.src_s20` using explicit INFORMATs and LENGTHs from a generated, overridable
spec file. No PROC IMPORT guessing. No recoding. Values exactly as in source (PDD-D-02).

All 20 files are 1:1 per PRECEDE_STUDY_ID except the 2 s18 dup/blank rows (handled below).

Done when: all 20 `pdd.src_s*` datasets exist; row counts reconciled in QC; s06 column-group
profiling output written to `pdd.qc_s06_groups` / `qc\s06_column_groups.xlsx`. PDD-D-21 (which
s06 groups become PCNR_) is deferred to Phases 4-5; Phase 3 imports ALL s06 columns raw.

PDD-D-17 fully closed. PDD-D-18 resolved (see decisions).

</domain>

<decisions>
## Implementation Decisions

### PDD-D-17 — FULLY CLOSED (corrected 2026-10-19 discuss-3)
All 20 source files are 1:1 per PRECEDE_STUDY_ID **except the 2 s18 dup/blank rows**.
- s01 (PACU_STAY): 41,423 rows, 41,423 distinct IDs — NOT multi-row. 274 IDs not in spine = QC item.
- s08 (COLONOSCOPY): 3,456 rows, 3,456 distinct IDs — NOT multi-row.
Both files join the spine in Phase 5 exactly like every other 1:1 source.
The "multi-row" assumption in earlier planning docs was incorrect; all references have been fixed.

### PDD-D-18 — LOCKED (discuss-3)
s04 (ENCOUNTER_Crypto) and s05 (MRN_Crypto) are **linkage/QC only** — not dictionary variables.
- Import into `pdd.src_s04` / `pdd.src_s05` for completeness and ID checking.
- No PCNR_ columns come from s04 or s05.
- s04/s05 matched 0 IDs in the 2022 files; the 2022 ID mismatch is fully resolved by PDD-D-19.
  Do NOT reference the 2022 mismatch in any s04/s05 logic.
- Whether s04/s05 are used in Phase 5 linkage is a Phase 5 decision; Phase 3 just imports them.

### PDD-D-21 — scope clarified (pre-planning review)
Phase 3 imports **ALL columns** from s06 (`2018_2019_Precede_Database.xlsx`) into `pdd.src_s06`
as a raw import — no gating. PDD-D-21 (which column groups become PCNR_ variables) is a
Phases 4-5 decision. Phase 3 must still produce the column-group profile to inform that decision.

**Profile output required (write to `pdd.qc_s06_groups` and `qc\s06_column_groups.xlsx`):**
- One row per column-name group (group = shared prefix/suffix by naming pattern)
- Columns: group name, example column names (first 3), column count, inferred type, median % rows
  non-null across group columns, overlap count with columns already present in s03/s07
- Sorted by column count descending
Gerard reviews this output and marks which groups enter PCNR_ in Phases 4-5.

### s18 duplicate/blank rows
`pdd.qc_s18_dup` already holds the 2 dup/blank PRECEDE_STUDY_ID rows from Phase 2.
03_import.sas must:
1. Log the 2 offending row IDs (or blank values) to the SAS log with a NOTE.
2. Exclude them from `pdd.src_s18` (import all other rows only).
3. Leave them in `pdd.qc_s18_dup` as-is for Gerard to review before Phase 5.
Do NOT silently drop or flag-and-keep — explicit log + QC dataset is the contract.

### import_spec.csv — schema and derivation (locked, pre-planning review)

**Schema** — one row per (file × column):

| Column | Content |
|--------|---------|
| `file_code` | s01 … s20 |
| `col_order` | 1-based position of the column in the source file (required for INPUT statement ordering) |
| `orig_col_name` | Exact header as it appears in the source |
| `sas_name` | V7-valid SAS name, unique per file. Duplicate headers get a `_dup2`, `_dup3` suffix (e.g. s15/s17 second `PRECEDE Study ID` → `PRECEDE_Study_ID_dup2`). Both copies are kept (PDD-D-02). The original header becomes the SAS variable LABEL. |
| `sas_type` | C or N |
| `length` | Character: max observed raw length + 4 for ID/code cols, + 0 otherwise (minimum 8). Numeric: 8. |
| `informat` | SAS informat (e.g. `$64.`, `best32.`) |
| `format` | SAS format, or blank |
| `notes` | Free text; e.g. "forced to char — ID column", "dup header", "forced to char — CPT col" |

**Derivation steps (spec-generation task, run before 03_import.sas proper):**

1. **Raw pre-pass** (new — overrides Phase 2 col_len for character length): read every CSV column as
   `$32767` character text using INFILE + INPUT + character informats; record max observed raw byte
   length per (file_code, col_order). This is the authoritative character length source.
   (`pdd.header_inventory` col_len = PROC IMPORT's guess of 8 for numerics — do NOT use it for
   char lengths; use it for type inference only.)

2. **Populate spec**: for each (file_code, col_order, orig_col_name) from `pdd.header_inventory`:
   - Assign `sas_name`: sanitise orig_col_name to V7 (replace non-alphanumeric with `_`, truncate
     to 32 chars). Detect duplicates within the same file_code; suffix `_dup2`, `_dup3`, etc.
   - `sas_type`:
     - Force **C** if col matches (case-insensitive): `PRECEDE_STUDY_ID`, `PRECEDE Study ID`,
       `Base Procedure Code 1`, `*_ID`, `*_CODE`, `CPT*`, `ICD*`.
     - Otherwise inherit from `pdd.header_inventory` inferred type.
   - `length`: for C columns, use raw pre-pass max + 4 for ID/code cols, raw pre-pass max for
     others (minimum 8). For N columns, use 8.
   - `informat`: `$<length>.` for C; `best32.` for N (planner may refine for date columns).
   - `col_order`: from header_inventory position or pre-pass scan order.

3. Write `docs\import_spec.csv` to the git repo (no PHI — metadata only). Gerard may override any
   row before running the import. 03_import.sas reads this file at runtime.

### Reading method by file type (locked, pre-planning review)

**16 CSV files (s01–s05, s07, s09–s10, s12–s18, s20):**
- INFILE with `ENCODING='UTF-8'`, `DLM=','`, `FIRSTOBS=2`, `MISSOVER`, `DSD`.
- INPUT statement uses sas_name, informat, in col_order sequence.
- Generated via CALL EXECUTE loop over import_spec rows for that file_code.

**4 xlsx files (s06, s08, s11, s19):**
- Use `LIBNAME <ref> XLSX "path\file.xlsx";` — never PROC IMPORT.
- A DATA step reads from the XLSX libref member (one sheet = one member) and applies the spec:
  rename orig column names to sas_name, set variable labels, force ID/code columns to character
  with the spec-defined lengths using CATS/PUT/INPUT as needed (XLSX libname reads everything as
  its inferred type; the DATA step re-casts).
- s06: all sheets inventoried; Sheet1 imported in full (all columns). If multiple data sheets
  exist, import each; profile distinguishes them.
- s11: standard xlsx import.
- s19 (ALL_AIM2): Sheet1 only; apply PDD-D-08 drop logic after import.
- INFILE/INFORMAT rule does NOT apply to xlsx files.

### %pdd_norm_psid availability (pre-planning review)
`%pdd_norm_psid` already exists in `sas/00_config.sas` (PDD-D-19 locked, added Phase 2).
**Task 1 of Phase 3 plan must verify it is present** (grep / read 00_config.sas) before coding
any import step that calls it. If for any reason it is absent, Task 1 creates it using the locked
D-19 rule. Do not proceed to spec generation until confirmed.

### Locked import rules carried from earlier phases
- **PDD-D-02:** Values exactly as in source — no recoding. `?`, `NULL`, `Unknown` stay as values.
- **PDD-D-08:** s19 (ALL_AIM2, Sheet1 only): drop rows where PRECEDE_STUDY_ID is missing or all
  data columns are blank/`NULL`; log kept/dropped counts.
- **PDD-D-19:** Apply `%pdd_norm_psid` to all files after raw import to produce `norm_psid`
  alongside the original ID. Assert `_ndis = 0`.
- **PDD-D-20:** s17 — set the 6 ENCRYPTED_ENCOUNTER values that map to >1 PRECEDE_STUDY_ID to
  missing **for linkage only**; raw values remain unchanged in `pdd.src_s17`.
- **UTF-8:** Every CSV INFILE uses `ENCODING='UTF-8'`. xlsx imports via LIBNAME XLSX (no encoding
  option needed — xlsx is Unicode natively).

### Claude's Discretion
- Exact column-group pattern-matching heuristic for s06 profile (prefix length, delimiter, fallback
  for no obvious pattern).
- Whether spec-generation code is a standalone SAS program (`03a_build_spec.sas`) or Section 1 of
  `03_import.sas`.
- QC row-count reconciliation format (ODS table or %put NOTEs), consistent with Phase 2 style.
- How to re-cast xlsx char/num types in the DATA step (CATS, PUT+INPUT, or conditional assignment).

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
- `sas/00_config.sas` — `%pdd_norm_psid` (D-19), `%pdd_lib`, `%check_encoding`, `%check_pdd_lib`
  — read before coding; Task 1 must confirm `%pdd_norm_psid` is present

### Phase 2 output (data on P: — not in git)
- `pdd.header_inventory` — col names, inferred types, position; used for type inference and sas_name
  generation; **not** used for char lengths (PROC IMPORT guesses 8 for numerics — use raw pre-pass)
- `pdd.source_inventory` — SHA-256, row counts, sheet lists (xlsx); use for QC row-count reconciliation
- `pdd.qc_s18_dup` — 2 dup/blank s18 rows; must remain untouched in Phase 3

### Reference implementation (read-only)
- `_reference_old/sas/00_config.sas` — Pattern for macro layout; do NOT copy data paths or g-library refs
- `sas/02_source_guard.sas` — Pattern for reading P: files, LIBNAME XLSX, logging style

No external ADRs or specs beyond the above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sas/00_config.sas`: `%pdd_lib`, `%pdd_norm_psid`, `%check_encoding`, `%check_pdd_lib`, all path
  macros — %include at top of 03_import.sas; do not redefine any locally.
- `sas/02_source_guard.sas`: LIBNAME XLSX usage, PROC IMPORT pattern, FINFO metadata, ODS Excel
  with UF colors — read for style before writing 03_import.sas.

### Established Patterns
- Every program: `%include "C:\data_dictionary\sas\00_config.sas";` then `%pdd_lib;`
- Per-program log redirect when `in_pipeline = 0` (see Phase 1 context)
- QC output: ODS Excel with UF colors (#0021A5, #FA4616); KEY sheet leftmost
- `%fail_out` macro for fatal errors (defined locally per program)

### Integration Points
- Output: `pdd.src_s01`…`pdd.src_s20` consumed by Phase 4 (name map) and Phase 5 (PCNR_ build)
- `docs\import_spec.csv` committed to git — readable by planner and executor without P: access
- `pdd.qc_s06_groups` + `qc\s06_column_groups.xlsx` → Gerard reviews before Phases 4-5 s06 scope
- Wire `03_import.sas` into `sas/99_run_all.sas` after the Phase 2 %include block

</code_context>

<specifics>
## Specific Ideas

- import_spec.csv col_order is 1-based; INPUT statement must list columns in col_order sequence.
- Duplicate header handling (s15/s17 `PRECEDE Study ID` + `PRECEDE_STUDY_ID`): sas_name for the
  second occurrence = `PRECEDE_Study_ID_dup2`; both kept; label = exact orig_col_name. This is the
  PDD-D-02 requirement — keep both, recode nothing.
- Raw pre-pass for char lengths: one INFILE DATA step per CSV, all columns as `$32767`, CALL SYMPUT
  or PROC SQL to extract max(length(col)) per column. Expensive for large files — run once and
  persist results in `pdd.raw_char_lengths` before spec generation.
- ID/code forced-to-char patterns (case-insensitive match): `PRECEDE_STUDY_ID`, `PRECEDE Study ID`,
  `Base Procedure Code 1`, suffix `_ID`, suffix `_CODE`, prefix `CPT`, prefix `ICD`.
- LIBNAME XLSX re-cast: after SET from XLSX member, use `LENGTH new_var $N; new_var = CATS(orig_var);
  DROP orig_var; RENAME new_var = orig_var;` pattern for forced-char columns. Watch for date
  columns that come through XLSX as numeric SAS dates — retain their format.
- s06 group profiling overlap check: compare column names against `pdd.header_inventory` where
  file_code IN ('s03','s07').
- Phase 3 QC NOTEs (expected, from D-19 run): s06 29 IDs not in spine, s11 1 not in spine —
  log as NOTEs, not WARNINGs.

</specifics>

<deferred>
## Deferred Ideas

- Which s06 column groups enter PCNR_ (PDD-D-21): deferred to Phases 4-5 after profiling review.
- s04/s05 linkage use in Phase 5: Phase 5 planning decision.
- PDD-D-15 (gap-fill tie-break order) and PDD-D-16 (per-cell source flag): Phase 5 only.

</deferred>

---

*Phase: 03-direct-import-of-the-20-sources*
*Context gathered: 2026-10-19*
*Updated: 2026-10-19 pre-planning review (items 1–8)*
