---
phase: 03-direct-import-of-the-20-sources
plan: "01"
subsystem: database
tags: [sas, csv, xlsx, spec-generation, raw-char-lengths, import-spec]

requires:
  - phase: 02-source-guard-and-header-inventory
    provides: pdd.header_inventory, pdd.source_inventory (READ ONLY -- type inference and sheet names)

provides:
  - sas/03a_build_spec.sas (one-time spec generator program)
  - docs/import_spec_generated.csv (header committed; populated after SAS run)
  - pdd.raw_char_lengths (runtime: true max observed char lengths per CSV column)
  - pdd.import_spec (runtime: full spec driving 03_import.sas)

affects:
  - 03-02 (03_import.sas reads import_spec_generated.csv at runtime)

tech-stack:
  added: []
  patterns:
    - "Raw $32767 pre-pass over CSV files for true max observed character lengths (pdd.raw_char_lengths)"
    - "Batched pre-pass in groups of 200 columns when ncols > 500 (Pitfall 3 compliance)"
    - "Colon-modified list input (:$32767.) for DSD-correct pre-pass reads"
    - "Self-join PROC SQL dup-rank pattern for case-insensitive sas_name deduplication"
    - "Forced-char priority rules (ENCRYPTED_, _ID/_CODE, CPT/ICD, PRECEDESTUDYID, exact names)"
    - "Numeric informat probing: best32. then datetime variants; force C if none parse 100%"
    - "CALL EXECUTE not used here -- spec is written to CSV; 03_import.sas uses it at runtime"

key-files:
  created:
    - sas/03a_build_spec.sas
    - docs/import_spec_generated.csv
  modified:
    - .gitignore (added !docs/import_spec_generated.csv exception)

key-decisions:
  - "03a_build_spec.sas is separate from 03_import.sas: spec generation is one-time; import is repeatable"
  - "import_spec_generated.csv committed to git (no PHI -- metadata only); overrides via import_spec_overrides.csv"
  - "Raw pre-pass skips XLSX files (engine handles types); CSV-only pre-pass (16 files)"
  - "docs/import_spec_generated.csv header committed as placeholder; SAS run populates with all 20 files"

patterns-established:
  - "Pattern: _csv_prepass macro handles one CSV file at a time; batches to 200 cols if ncols > 500"
  - "Pattern: spec_ranked PROC SQL self-join for dup detection (avoids hash-object cross-BY-group complexity)"
  - "Pattern: _probe_numeric_cols macro per CSV file tests best32. then 5 datetime informats"

requirements-completed: [PDD-03-R02, PDD-03-R09, PDD-03-R10]

duration: 35min
completed: 2026-10-19
---

# Phase 3 Plan 01: Spec Generator Summary

**03a_build_spec.sas: raw $32767 CSV pre-pass + forced-char import spec generator for all 20 PDD source files, writing docs/import_spec_generated.csv**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-10-19T20:41:46Z
- **Completed:** 2026-10-19T21:16:00Z
- **Tasks:** 2 (Tasks 1 and 2 both implemented in 03a_build_spec.sas)
- **Files modified:** 3

## Accomplishments

- Created sas/03a_build_spec.sas: 7-section SAS program covering preconditions, pre-pass, spec build, and CSV output
- Raw pre-pass logic (Section 4): loops 16 CSV files; batches columns in 200s if ncols > 500 to avoid Pitfall 3 memory issue; writes pdd.raw_char_lengths
- Spec build (Section 5): union of CSV (authoritative col_order from pre-pass) and XLSX (header_inventory varnum order) rows; sas_name V7 derivation with case-insensitive self-join dup detection; 5 forced-char priority rules; numeric informat probing (best32. + 5 datetime informats; force C if none parse 100%); length derivation per type and file type
- CSV output (Section 6): DSD-quoted UTF-8 10-column header row + data rows via data _null_ FILE
- .gitignore updated to allow docs/import_spec_generated.csv

## Task Commits

1. **Task 1: Program scaffold + preconditions + raw char-length pre-pass** - `dc3d815` (feat)
2. **Task 2: Build import_spec for all 20 files + write docs/import_spec_generated.csv** - `b7ed7de` (feat)

## Files Created/Modified

- `sas/03a_build_spec.sas` - One-time spec generator: raw pre-pass + import_spec build + CSV write
- `docs/import_spec_generated.csv` - Header-only placeholder; SAS run populates with all 20 files
- `.gitignore` - Added !docs/import_spec_generated.csv exception

## Decisions Made

- Committed docs/import_spec_generated.csv as header-only placeholder because SAS cannot run in this shell environment (P: drive data required); Gerard runs 03a_build_spec.sas to populate it
- Self-join PROC SQL for dup detection instead of DATA step hash object (hash objects don't persist across BY groups in SET without complex retained state)
- Separate 03a_build_spec.sas and 03_import.sas per research recommendation (one-time vs. repeatable)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] .gitignore blocked docs/import_spec_generated.csv from being committed**
- **Found during:** Task 2 (write CSV output)
- **Issue:** .gitignore had `*.csv` as a blanket exclusion; git add rejected the file
- **Fix:** Added `!docs/import_spec_generated.csv` exception to .gitignore (same pattern as source_guard_baseline.csv)
- **Files modified:** .gitignore
- **Committed in:** b7ed7de (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - blocking .gitignore issue)
**Impact on plan:** Required for plan artifact to be committable. No scope creep.

## Known Stubs

- `docs/import_spec_generated.csv` contains only the header row. The file is populated by running `sas/03a_build_spec.sas` with SAS 9.4 (requires P: drive access and pdd.header_inventory from Phase 2). This is intentional: the SAS program is the artifact; the CSV output is a runtime product. Plan 03-02 depends on this file being populated before 03_import.sas can run.

## Issues Encountered

- SAS is not available in the executor shell; the SAS programs are code artifacts designed to run in the SAS 9.4 environment with P: drive access. Acceptance criteria that check runtime SAS outputs (pdd.raw_char_lengths row counts, pdd.import_spec distinct file_codes) require manual verification after running 03a_build_spec.sas.

## Next Phase Readiness

- 03a_build_spec.sas is ready to run. Gerard runs it once to produce pdd.raw_char_lengths, pdd.import_spec, and docs/import_spec_generated.csv (then commits the populated CSV).
- After the populated CSV is committed, Plan 03-02 (03_import.sas) can proceed.
- import_spec_overrides.csv: Gerard creates this file (same 10-column header, only changed rows) before running 03_import.sas to override any spec rows; do NOT commit import_spec_overrides.csv.

---
*Phase: 03-direct-import-of-the-20-sources*
*Completed: 2026-10-19*
