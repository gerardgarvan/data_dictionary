---
phase: 03-direct-import-of-the-20-sources
plan: "03"
subsystem: database
tags: [sas, norm_psid, key_analysis, d19-assert, qc-rowcounts, pipeline-wiring]

requires:
  - phase: 03-direct-import-of-the-20-sources
    plan: "02"
    provides: sas/03_import.sas (Sections 0-11), pdd.src_s01..pdd.src_s20
  - phase: 02-source-guard-and-header-inventory
    provides: pdd.key_analysis (key_var_name per file), pdd.source_inventory (row_count), pdd.header_inventory (READ ONLY)

provides:
  - sas/03_import.sas (Sections 12-15 appended: norm_psid loop + D-19 assert + QC rowcounts)
  - pdd.src_s01..pdd.src_s20 with norm_psid column (runtime)
  - pdd.qc_import_rowcounts (runtime: 20 rows, per-file reconciliation)
  - sas/99_run_all.sas (Phase 3 include active; phases enabled: 2,3)

affects:
  - phase 04 (name map reads pdd.src_s* with norm_psid)
  - phase 05 (PCNR_ spine build reads pdd.src_s* with norm_psid)

tech-stack:
  added: []
  patterns:
    - "key_analysis-driven norm_psid: data _null_ loads s_code/key_var_name/key_column_type into macro arrays; %do loop calls %pdd_norm_psid(idvar=&_kv) per file"
    - "D-19 re-derives work._s17_ambig_d19 from pdd.src_s17 (post-norm_psid) via PROC SQL group-by HAVING count(distinct norm_psid)>1"
    - "D-19 encounter join: PROC SQL inner join pdd.src_s17 -> pdd.src_s09 on ENCRYPTED_ENCOUNTER excluding ambiguous on both sides via NOT IN subquery"
    - "qc_rowcounts: %do loop counts pdd.src_&fc via PROC SQL; assembles work._qc_rc_accum by SET union; writes pdd.qc_import_rowcounts"
    - "s18 status logic: expected-diff if imported = inventory - 2; s19: expected-diff if imported <= inventory; others: match if equal"

key-files:
  created: []
  modified:
    - sas/03_import.sas (Sections 12-15 appended, +337 lines)
    - sas/99_run_all.sas (Phase 3 block uncommented; completion NOTE updated)

key-decisions:
  - "D-19 assert re-derives ambiguous token set from pdd.src_s17 (norm_psid present) rather than relying on work._s17_ambig deleted in Section 6"
  - "s09 encounter column looked up from pdd.header_inventory at runtime; falls back to ENCRYPTED_ENCOUNTER if not found (defensive)"
  - "qc_rowcounts loop uses work._qc_rc_accum SET-union pattern instead of CALL EXECUTE to stay PCM-compliant and inspectable"

requirements-completed: [PDD-03-R05]

duration: 25min
completed: 2026-10-20
---

# Phase 3 Plan 03: Normalisation + QC Reconciliation + Pipeline Wiring Summary

**sas/03_import.sas Sections 12-15: key_analysis-driven %pdd_norm_psid loop + D-19 encounter-join assert (n_pairs=9001, ndis=0) + pdd.qc_import_rowcounts (20 rows, no MISMATCH) + 99_run_all.sas Phase 3 wired in**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-10-20
- **Tasks:** 3 (Tasks 1+2 in one commit to 03_import.sas; Task 3 in one commit to 99_run_all.sas)
- **Files modified:** 2

## Accomplishments

- **Section 12 (norm_psid loop):** Reads pdd.key_analysis at runtime; loads s_code/key_column_type/key_var_name into macro arrays; %do loop applies `%pdd_norm_psid(in=pdd.src_&fc, out=pdd.src_&fc, idvar=&_kv)` for each file whose key_var_name is non-blank and key_column_type is not NONE_DETECTED; skipped files logged with "skipped -- no key column in pdd.key_analysis"; spot asserts norm_psid present on src_s01 and src_s09 via dictionary.columns
- **Section 13 (D-19 assert):** Re-derives ambiguous s17 ENCRYPTED_ENCOUNTER set from pdd.src_s17 (now has norm_psid); looks up s09 encounter column from pdd.header_inventory (fallback ENCRYPTED_ENCOUNTER); PROC SQL inner join s17->s09 on ENCRYPTED_ENCOUNTER excluding ambiguous tokens on both sides via NOT IN subquery; fail_out if n_pairs=0 or ndis>0; expected: n_pairs=9001 ndis=0
- **Section 14 (QC rowcounts):** Spot asserts s01=41423 and s08=3456 via fail_out; %do loop builds pdd.qc_import_rowcounts (20 rows) via SET-union accumulator; s18 status=expected-diff (imported=inventory-2); s19 status=expected-diff (imported<=inventory); others match/MISMATCH; fail_out on any MISMATCH row; %_note_written_ds confirmation
- **Task 3 (pipeline wiring):** 99_run_all.sas Phase 3 block uncommented; `%include "&sas_path.\03_import.sas";` active after Phase 2; completion NOTE updated to "(phases enabled: 2,3)"; Phases 4-7 and 03a_build_spec.sas remain commented

## Task Commits

1. **Task 1+2: norm_psid loop + D-19 assert + QC rowcounts (Sections 12-15 in 03_import.sas)** - `88e2ab3` (feat)
2. **Task 3: Wire 03_import.sas into 99_run_all.sas** - `cd8cfd3` (feat)

## Files Created/Modified

- `sas/03_import.sas` (+337 lines: Sections 12-15)
- `sas/99_run_all.sas` (Phase 3 block uncommented, completion NOTE updated)

## Decisions Made

- D-19 assert re-derives the ambiguous encounter set from pdd.src_s17 post-norm_psid (not from work._s17_ambig which was cleaned up in Section 6). This makes Section 13 self-contained and correct regardless of run order.
- s09 encounter column retrieved from pdd.header_inventory at runtime with ENCRYPTED_ENCOUNTER fallback — avoids hard-coding while handling cases where Phase 2 populated header_inventory with a renamed column.
- QC rowcounts use a work SET-union accumulator pattern instead of CALL EXECUTE per PCM compliance.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All logic is fully implemented. Runtime outputs require Gerard to run the full pipeline with SAS 9.4 (P: drive, UTF-8 config).

## Acceptance Criteria Status

All acceptance criteria require SAS runtime outputs. Manual verification required after running 99_run_all.sas (or 03_import.sas standalone):

| Criterion | Status |
|-----------|--------|
| Log: "PDD-D-19 assert passed -- n_pairs=9001 ndis=0" | Requires SAS run |
| norm_psid column on pdd.src_s01 | Requires SAS run |
| norm_psid column on pdd.src_s09 | Requires SAS run |
| Skipped-file NOTE for any NONE_DETECTED key | Requires SAS run |
| pdd.qc_import_rowcounts = 20 rows | Requires SAS run |
| No MISMATCH rows in pdd.qc_import_rowcounts | Requires SAS run |
| pdd.qc_import_rowcounts s01 imported_rows = 41423 | Requires SAS run |
| pdd.qc_import_rowcounts s08 imported_rows = 3456 | Requires SAS run |
| pdd.qc_import_rowcounts s18 status = expected-diff | Requires SAS run |
| 99_run_all.sas has uncommented %include "...03_import.sas" | Confirmed by code review |
| 99_run_all.sas has "(phases enabled: 2,3)" | Confirmed by code review |
| Full-run log: "---- Phase 3 complete" | Requires SAS run |
| Full-run log: zero ERROR lines | Requires SAS run |
| Source guard PASS (SHA baseline unchanged) | Requires SAS run |

## Issues Encountered

- SAS is not available in the executor shell; runtime acceptance criteria require manual verification with SAS 9.4 (P: drive).

## Self-Check: PASSED

- `sas/03_import.sas` exists and was modified (Sections 12-15 appended)
- `sas/99_run_all.sas` exists and was modified (Phase 3 block active)
- Commit `88e2ab3` exists (03_import.sas changes)
- Commit `cd8cfd3` exists (99_run_all.sas changes)

---
*Phase: 03-direct-import-of-the-20-sources*
*Completed: 2026-10-20*
