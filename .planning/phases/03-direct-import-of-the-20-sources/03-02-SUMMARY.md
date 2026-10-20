---
phase: 03-direct-import-of-the-20-sources
plan: "02"
subsystem: database
tags: [sas, csv, xlsx, import, spec-driven, raw-fidelity, utf-8]

requires:
  - phase: 03-direct-import-of-the-20-sources
    plan: "01"
    provides: docs/import_spec_generated.csv (populated by Gerard after running 03a_build_spec.sas)
  - phase: 02-source-guard-and-header-inventory
    provides: pdd.source_inventory, pdd.header_inventory, pdd.qc_s18_dup (READ ONLY)

provides:
  - sas/03_import.sas (runtime spec-driven import of all 20 sources)
  - pdd.src_s01..pdd.src_s20 (20 raw source datasets -- runtime)
  - pdd.qc_s06_groups (s06 column-group profile -- runtime)
  - qc/s06_column_groups.xlsx (s06 group profile workbook -- runtime)

affects:
  - 03-03 (pdd.src_s01..pdd.src_s20 consumed by %pdd_norm_psid + QC reconciliation)
  - phase 04 (name map reads pdd.src_s* and pdd.qc_s06_groups)
  - phase 05 (PCNR_ spine build reads pdd.src_s*)

tech-stack:
  added: []
  patterns:
    - "FILE statement (data _null_) generates 03_generated_import.sas per-CSV; %include executes it -- no macro-variable assembly of LENGTH/LABEL/INPUT"
    - "options errors=1 wraps CSV INFILE reads; restored to errors=20 after each file"
    - "LIBNAME XLSX + name-literal branch for digit-prefix sheet names (e.g. 2018_2019_PRECEDE_DATABASE)"
    - "RENAME= dataset option maps src_name -> sas_name; forced-char recast via length _c $N; _c=cats(orig); drop orig; rename _c=orig"
    - "s18 exclusion: PROC SQL NOT IN with strip(put(numeric_id, best32.)) on both sides (char-cast comparison)"
    - "s17 enc_for_linkage: runtime derivation of ambiguous ENCRYPTED_ENCOUNTER tokens via group-by HAVING count(distinct norm_psid)>1"
    - "s06 group profiling: PROC MEANS nmiss + PROC TRANSPOSE to long; group prefix heuristic (first _ or digit run, min 3 chars)"
    - "Override merge: spec_ovr sorted by (file_code, col_order); DATA step MERGE overwrites gen rows; each override logged"

key-files:
  created:
    - sas/03_import.sas
  modified: []

key-decisions:
  - "FILE-generated DATA steps (data _null_ -> FILE -> %include) rather than CALL EXECUTE or macro-variable concatenation: avoids token-length limits and makes generated code inspectable"
  - "s18 exclusion targets work.src_s18_raw (intermediate) from Task 1 CSV generation; pdd.src_s18 created by PROC SQL NOT IN exclusion (char-cast both sides)"
  - "s17 enc_for_linkage derived entirely at runtime from pdd.src_s17 group-by query; 6 tokens stored in _ambig1.._ambig6 global macro vars; not read from any committed file"
  - "s06 profile uses PROC MEANS nmiss (one pass over all cols) + PROC TRANSPOSE to avoid 3987-column per-column queries"
  - "s19 PRECEDE_STUDY_ID may be char or num depending on XLSX engine; put(..., $32767.) used in keep condition to handle both"
  - "ODS Excel UF template (cx0021A5 header, white bold) registered in work.templat; KEY sheet leftmost (PDD-D-09)"

requirements-completed: [PDD-03-R01, PDD-03-R03, PDD-03-R04, PDD-03-R06, PDD-03-R07, PDD-03-R08, PDD-03-R10]

duration: 15min
completed: 2026-10-20
---

# Phase 3 Plan 02: Runtime Import (03_import.sas) Summary

**sas/03_import.sas: spec-driven FILE-generated DATA steps for 16 CSV sources + LIBNAME XLSX for 4 XLSX sources + s19 blank-row drop + s18 char-cast exclusion + s17 runtime enc_for_linkage + s06 column-group profile**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-10-20T00:39:00Z
- **Completed:** 2026-10-20T00:54:32Z
- **Tasks:** 3 (all written in one pass; single artifact sas/03_import.sas)
- **Files modified:** 1

## Accomplishments

- **Section 0-3:** Scaffold: %include 00_config.sas, %pdd_lib, utility macros (%fail_out, %route_log, %restore_log, %_note_written_ds, %_note_written_xlsx), preconditions (import_spec_generated.csv + pdd.qc_s18_dup + pdd.source_inventory), 20-row work.file_list DATALINES
- **Section 4:** Spec load: reads import_spec_generated.csv with ENCODING='UTF-8' dsd; merges import_spec_overrides.csv if present (override wins; each applied row logged with file_code/col_order/sas_name); work.spec joined with file_list for full_path/ftype
- **Section 5:** CSV DATA step generation: data _null_ FILE writes 03_generated_import.sas for all 16 CSV files; each step has LENGTH/LABEL/INPUT written line-by-line; options errors=1 wraps each file; s18 targets work.src_s18_raw; %include executes the generated file
- **Section 6:** s18 exclusion: logs 2 dup IDs from pdd.qc_s18_dup (char-cast from numeric); PROC SQL NOT IN exclusion (strip(put(d.PRECEDE_STUDY_ID, best32.)) on both sides) creates pdd.src_s18; asserts pdd.qc_s18_dup unchanged (2 rows). s17 enc_for_linkage: %pdd_norm_psid applied; PROC SQL group-by HAVING derives 6 ambiguous ENCRYPTED_ENCOUNTER tokens; tokens loaded to global macro vars; _ambig_quoted_list built; pdd.src_s17 rebuilt with enc_for_linkage column (6 tokens blanked); raw ENCRYPTED_ENCOUNTER unchanged
- **Section 7:** XLSX imports: %_get_sheet_name macro looks up sheet from pdd.source_inventory (fallback to known names); %_import_xlsx macro assigns LIBNAME XLSX, builds RENAME= clause, uses name-literal ("&_sheet"n) for all sheets, recasts C-type cols via _c temp var pattern; s08, s11, s06 -> pdd.src_s*; s19 -> work._s19_raw then PDD-D-08 drop
- **Section 8:** Final verification loop over all 20 pdd.src_s* datasets
- **Section 9-10:** s06 column-group profile: PROC MEANS nmiss (all cols) + PROC TRANSPOSE to long; group prefix heuristic (chars before first _ or digit, min 3 chars, max 20, else _SINGLETON_); pdd.qc_s06_groups built with group/example_cols/col_count/inferred_type/median_pct_nonnull/overlap_s03_s07; sum(col_count) asserted against header_inventory count; ODS Excel writes qc\s06_column_groups.xlsx (KEY sheet + S06_GROUPS sheet, UF colors)

## Task Commits

1. **Task 1: Scaffold + spec load + override merge + 16 CSV generation** - `01eb8a2` (feat)
2. **Task 2: XLSX imports + s19 drop + s18 exclusion + s17 enc_for_linkage** - `01eb8a2` (same commit -- all three tasks written in single pass to one file)
3. **Task 3: s06 column-group profile + qc\s06_column_groups.xlsx** - `01eb8a2` (same commit)

## Files Created/Modified

- `sas/03_import.sas` (1037 lines) -- runtime spec-driven import of all 20 sources

## Decisions Made

- FILE-generated DATA steps (not CALL EXECUTE / macro-variable concatenation) to avoid token-length limits and keep generated code inspectable by Gerard
- s18 raw CSV read to work.src_s18_raw (intermediate); pdd.src_s18 created by PROC SQL exclusion; pdd.qc_s18_dup is strictly read-only
- s17 enc_for_linkage derived at runtime (not from any committed file); 6 tokens stored in global macro vars
- s06 PROC MEANS nmiss (single pass) + PROC TRANSPOSE chosen over 3987 individual queries
- ODS Excel UF template registered in work.templat (session-local; not persisted)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] s19 PRECEDE_STUDY_ID type guard**
- **Found during:** Task 2 (s19 drop logic)
- **Issue:** Plan used `not missing(PRECEDE_STUDY_ID) and strip(PRECEDE_STUDY_ID) ne ''` assuming char type, but XLSX engine may import it as numeric depending on column content
- **Fix:** Used `strip(put(PRECEDE_STUDY_ID, $32767.)) ne ''` to handle both char and numeric without type errors
- **Files modified:** sas/03_import.sas (Section 7, s19 drop DATA step)
- **Commit:** 01eb8a2

**2. [Rule 2 - Missing critical] Work intermediate for s17 rewrite**
- **Found during:** Task 2 (s17 enc_for_linkage)
- **Issue:** Plan specified `data pdd.src_s17; set pdd.src_s17;` which is an in-place rewrite (PCM compliance rule prohibits it)
- **Fix:** Write to work._s17_enc first, then `data pdd.src_s17; set work._s17_enc;` -- same outcome, PCM-compliant
- **Files modified:** sas/03_import.sas (Section 6)
- **Commit:** 01eb8a2

---

**Total deviations:** 2 auto-fixed (Rule 2 -- correctness/compliance)
**Impact on plan:** No scope change; both fixes make the code more robust.

## Known Stubs

None. All logic is fully implemented. Runtime outputs (pdd.src_s01..pdd.src_s20, pdd.qc_s06_groups, qc\s06_column_groups.xlsx) require Gerard to:
1. Run `sas/03a_build_spec.sas` to populate `docs/import_spec_generated.csv`
2. Run `sas/03_import.sas` with SAS 9.4 (P: drive, UTF-8 config)

## Acceptance Criteria Status

All acceptance criteria require SAS runtime outputs (P: drive access). Manual verification required after running 03_import.sas:

| Criterion | Status |
|-----------|--------|
| pdd.src_s01 = 41,423 rows | Requires SAS run |
| pdd.src_s08 = 3,456 rows | Requires SAS run |
| PRECEDE_STUDY_ID is char in src_s01 | Requires SAS run (spec forces char via sas_type='C') |
| No Base_Procedure_Code_1 as numeric in src_s07 | Requires SAS run |
| s19 kept= and dropped= logged (PDD-D-08) | Requires SAS run |
| enc_for_linkage column in src_s17 | Requires SAS run |
| ENCRYPTED_ENCOUNTER unchanged in src_s17 | Requires SAS run |
| pdd.qc_s18_dup unchanged (2 rows) | Requires SAS run |
| s18 exclusion correct (0 dup IDs in src_s18) | Requires SAS run |
| No PCNR_ columns in src_s04/src_s05 | Confirmed by spec (s04/s05 have no PCNR_-prefixed sas_names) |
| pdd.qc_s06_groups >= 1 row | Requires SAS run |
| qc\s06_column_groups.xlsx written | Requires SAS run |
| Zero ERROR lines in log | Requires SAS run |

## Issues Encountered

- SAS is not available in the executor shell; 03_import.sas is a code artifact designed to run in the SAS 9.4 environment with P: drive access. All runtime acceptance criteria require manual verification after running the program.

## Next Phase Readiness

- 03_import.sas is ready. Gerard runs it after populating import_spec_generated.csv (via 03a_build_spec.sas).
- Plan 03-03 (normalization + QC reconciliation via %pdd_norm_psid) reads pdd.src_s01..pdd.src_s20.

---
*Phase: 03-direct-import-of-the-20-sources*
*Completed: 2026-10-20*
