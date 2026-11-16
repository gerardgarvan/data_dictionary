---
phase: 15-new-source-intake
plan: 03
subsystem: source-intake
tags: [sas, import, norm_psid, gates, overlap, encoding]
requires: [15-02, 15-04]
provides:
  - sas/15c_new_import.sas (NEW-03 import half, NEW-03a, NEW-04, NEW-05)
  - python/tests/test_phase15_import_static.py
affects: [16, 17]
key-files:
  created:
    - sas/15c_new_import.sas
    - python/tests/test_phase15_import_static.py
  modified: []
key-decisions:
  - "Datasets are pdd.nsrc_s21..s23 so the Phase 3 SRC_S__ norm_psid loop never sweeps them (A11)"
  - "Gates write QC and exchange CSVs first, then stop at PENDING DECISION; no dedupe, stacking or precedence"
requirements-completed: [NEW-03, NEW-03a, NEW-04, NEW-05]
completed: 2026-11-16
---

# Phase 15 Plan 03: New import, 1:1 and overlap gates Summary

One lint-clean SAS program that imports s21/s22/s23 from the 15b spec (generated DATA step, per-file encoding), adds norm_psid, reconciles counts, and runs the NEW-04 1:1 gate and the NEW-05 overlap gates including the PDD-D-29 item 3 pairwise check.

Status: PENDING SAS RUN (15c). Gates end in PENDING DECISION if triggered; no choice is applied.

## What was built

- Preconditions (spec CSV, file list, approved baseline, pre-pass lengths, spine, exactly 20 old `SRC_S__` datasets), spec load with checks (3 x 94 rows, encodings utf-8/wlatin1/wlatin1, one char PRECEDE Study ID per file).
- Per-file import via generated code in WORK (`infile ... encoding='<spec enc>' dsd`, explicit LENGTH and `:informat` input); `%pdd_norm_psid` unchanged; row count reconcile against `docs/new_source_files.csv` (MATCH / MATCH_RAWDIFF / MISMATCH, MISMATCH stops); exactly one `norm_psid` per dataset.
- Truncation check (post-import max length vs `pdd.raw_char_lengths_new`), non-ASCII counts (informational), type-change report against the old sources with NOTEs for Death_Days_After_Surgery and the five frailty component keys.
- 1:1 gate (`new_one_to_one.csv` exported, then PENDING DECISION on FAIL), overlap rows PAIRWISE_NEW / SPINE / OLD20_UNION / SHARED_COL_CONFLICT (`new_overlap.csv` exported, then pairwise gate, then old-source/spine gate).

## Verification

- `sas_lint.py`: 0 errors (26 W1/W2 warnings). `sasjs lint`: 0 errors. `ruff`: clean. `pytest python\tests`: 192 passed, 1 skipped.
- `sas/03_import.sas` and `sas/00_config.sas` unchanged. Not run: no SAS, no P:.

## Deviations from Plan

**1. [Rule 1 - Bug] Test and lint fixes.** `src_encoding = 'utf-8'` comparison tripped the literal-encoding test (written as `eq`); a `prxmatch` anchor needed `strip()` (lint C8). The exports-before-gates test compares the `outfile=` export line to the gate message, since header comments mention the file names earlier. The non-ASCII and truncation passes are one DATA step per file instead of two macros. 1:1 and overlap sections were added by Task 2 as planned.

## Assumptions (headless run)

- A11: dataset names `pdd.nsrc_s21..s23` (not `pdd.src_s2N`); recorded in the plan.
- A4: both gates (`PAIRWISE_NEW` > 0, spine/`OLD20_UNION` > 0) end in `%fail_out` after writing the QC CSVs. The old-source gate also fires on a non-zero spine count (the spine is part of the union).
- A5: non-ASCII counts after transcoding are informational, not a guard.
- SHARED_COL_CONFLICT is NOT_APPLICABLE; n_shared is 0 when every overlap is 0, otherwise -1 (value comparison is Phase 16 work).
- MRN overlap across eras is not computed (K1 and K2 keys differ, PDD-D-26).
- The spec CSV is read as utf-8 (as 15b writes it). Frailty keys checked are the new-header spellings; the `Fraility_*` and `_Value` variants do not share a match key with the old names and are covered by `docs/new_source_header_variants.csv`.

## Pending

- PENDING SAS RUN: after 15b output `docs/import_spec_new_generated.csv` is committed, Gerard runs `sas\15c_new_import.sas`; bring back `logs\15c_new_import.log` and `exchange\new_rowcounts.csv`, `new_one_to_one.csv`, `new_overlap.csv`, `new_type_changes.csv`, `new_nonascii.csv`; then `python\scripts\write_new_source_qc.py` (`--allow-partial` if stopped at a gate).
- PENDING DECISION (only if triggered): non-1:1 files (PDD-D-17 extension), shared IDs between new files (PDD-D-29 item 3), shared IDs with 2018-2022 (reopen PDD-D-25).

## Known Stubs

None.

## Commits

- 75f764d import, reconcile, truncation, non-ASCII, type changes (Task 1)
- 163be63 1:1 gate, overlap, pairwise gate, contract test (Task 2)

## Self-Check: PASSED
