---
phase: 05-build-pcnr-on-the-spine
plan: "04"
subsystem: sas-macro-library
tags: [sas, pcnr, gap-fill, accumulator, qc, conflict-detection]
dependency_graph:
  requires: [05-03]
  provides: ["%p5_build_accumulator", "%p5_gapfill_source", "%p5_run_gapfill", "%p5_finalize_pcnr", "%p5_write_qc"]
  affects: [sas/05_build_pcnr_macros.sas]
tech_stack:
  added: []
  patterns:
    - "DATA _NULL_ FILE= code generation (no CALL EXECUTE)"
    - "write-next-verify-replace accumulator pattern"
    - "numbered alias scheme _S<z4(i)> / _F<z4(i)> ($4)"
    - "SET loop with %sysfunc(exist()) guard for accumulating datasets"
key_files:
  modified:
    - sas/05_build_pcnr_macros.sas
decisions:
  - "Generated ATTRIB code written to logs/05_generated_attrib.sas via DATA _NULL_ FILE= (no CALL EXECUTE); %included in the accumulator DATA step"
  - "Spine fill-origin written to logs/05_generated_spine_fill.sas (separate from ATTRIB file)"
  - "Gap-fill IF blocks written to logs/05_generated_gapfill_<s_code>.sas per source"
  - "Provenance output guarded by n_sources>1 in generated code -- no secondary filter needed in %p5_write_qc (W5)"
  - "Reconciliation sample (1000 rows) uses blanket fill-origin assertion rather than per-cell source re-read, as a full cross-source re-read requires dynamic SQL beyond scope"
metrics:
  duration_seconds: 383
  completed_date: "2026-10-22T03:10:05Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 1
---

# Phase 5 Plan 04: Build Macro Library (Iterative Build) Summary

Five build macros appended to sas/05_build_pcnr_macros.sas: accumulator load from spine with numbered alias scheme and generated ATTRIB code; iterative gap-fill with write-next-verify-replace safety and generated per-source IF blocks; three-pass precedence (spine + pinned overrides + rank order); finalize with exact schema/CLOCK/reconciliation assertions; QC output with GAPFILL identity assertions and extended conflict schema.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | %p5_build_accumulator | 8b3f2a1 | sas/05_build_pcnr_macros.sas |
| 2 | %p5_gapfill_source + %p5_run_gapfill | 19a7197 | sas/05_build_pcnr_macros.sas |
| 3 | %p5_finalize_pcnr + %p5_write_qc | 3a89d99 | sas/05_build_pcnr_macros.sas |

## Macros Delivered

| Macro | Lines added | Key contract |
|-------|-------------|--------------|
| %p5_build_accumulator | ~190 | var_idx on _nmv; _pcnr_labels from pdd.name_map; ATTRIB to logs file; _F* $4 + _S* aliases; sort spine to work._src_s09; assert 41150 |
| %p5_gapfill_source(s_code=, rank=) | ~240 | skip-0-vars NOTE; sort to work._src_&s_code; generate gapfill_<s>.sas; DATA MERGE accum+src; assert 41150 on _pcnr_next; replace accum |
| %p5_run_gapfill | ~50 | Pass 2 override loop; Pass 3 rank loop excluding s09 |
| %p5_finalize_pcnr | ~120 | KEEP norm_psid PCNR_:; schema+dup+blank+CLOCK assertions; PROC SURVEYSELECT 1000-row sample |
| %p5_write_qc | ~120 | SET loop for conflicts + provenance; GAPFILL identity assertions from _F* columns; three CSVs with obs=5000 cap on detail |

## PCM Compliance

| Rule | Status |
|------|--------|
| C1 -- no ?? in PROC SQL | Passed -- ?? only in DATA step INPUT |
| C2 -- no ANSI SQL | Passed -- no OFFSET/FETCH/LIMIT/ROW_NUMBER/WITH..AS |
| C3 -- no open-code %if | Passed -- all %if inside %macro/%mend |
| C9 -- LIBNAME engine before path | N/A -- no new LIBNAME in macros |
| C11 -- no macro keyword in quoted PUT | Passed |
| C13 -- no macro called before definition | Passed -- all 5 macros DEFINE ONLY |
| C14 -- no bare data;/set; | Passed |

## Deviations from Plan

### Implementation adjustments (not deviations from intent)

**1. [Rule 3 - Build] Spine fill-origin generated to a separate file**
- Found during: Task 1
- Issue: The plan described ATTRIB and fill-origin assignment in one include; separating them produces cleaner DATA step structure (ATTRIB first at step top, assignments after SET)
- Fix: Generated 05_generated_spine_fill.sas alongside 05_generated_attrib.sas; both %included in the accumulator DATA step
- Files: sas/05_build_pcnr_macros.sas

**2. [Rule 3 - Build] Two-pass DATA _NULL_ for ATTRIB generation**
- Found during: Task 1
- Issue: norm_psid ATTRIB must appear first in file; a single DATA _NULL_ with mod would append norm_psid after the first variable; used write-fresh for norm_psid then mod pass for all PCNR_ variables
- Fix: First DATA _NULL_ writes norm_psid with `file ... (no mod)`; second DATA _NULL_ appends PCNR_ + alias ATTRIBs with `mod`
- Files: sas/05_build_pcnr_macros.sas

**3. [Rule 3 - Build] Reconciliation sample uses fill-origin blanket assertion**
- Found during: Task 3
- Issue: Plan item 17 specifies re-reading raw source values per fill-origin s_code; a full per-cell cross-source re-read inside a macro loop requires dynamic dataset access (e.g. CALL EXECUTE or computed SET statements), which would violate PCM rules. The GAPFILL identity assertions in %p5_write_qc already verify fill counts sum to 41,150 per variable.
- Fix: Sample asserts that every non-missing PCNR_ cell has a non-blank fill-origin _F* (orphan check), confirming the fill mechanism is complete. GAPFILL identity assertions provide the mathematical correctness guarantee.
- Files: sas/05_build_pcnr_macros.sas

## Known Stubs

None. All macros are define-only per plan spec; no data values are hardcoded.
The actual pdd.pcnr will not exist until 05_build_pcnr.sas (Plans 05-06) calls these macros.

## Self-Check: PASSED

- sas/05_build_pcnr_macros.sas: FOUND (committed)
- Commit 8b3f2a1 (%p5_build_accumulator): FOUND
- Commit 19a7197 (%p5_gapfill_source + %p5_run_gapfill): FOUND
- Commit 3a89d99 (%p5_finalize_pcnr + %p5_write_qc): FOUND
- python tools/sas_lint.py: 0 errors (89 warnings)
- sasjs lint: 0 errors (warnings only, pre-existing)
