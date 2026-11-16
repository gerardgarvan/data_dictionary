---
phase: 15-new-source-intake
plan: 04
subsystem: qc-writer
tags: [python, openpyxl, exchange-schema, privacy]
requires: []
provides:
  - python/pdd/new_source_qc_workbook.py
  - python/scripts/write_new_source_qc.py
  - exchange contract rows for 8 Phase 15 CSVs in docs/exchange_schema.csv
affects: [15-01, 15-02, 15-03]
tech-stack:
  added: []
  patterns: [exchange-CSV handoff (D-22), count masking <11]
key-files:
  created:
    - python/pdd/new_source_qc_workbook.py
    - python/scripts/write_new_source_qc.py
    - python/tests/test_new_source_qc.py
  modified:
    - docs/exchange_schema.csv
decisions:
  - "Variants CSV (docs/new_source_header_variants.csv) is optional: absent -> VARIANTS shows (no data) with a warning"
  - "Summary file references only s_codes; file_a/file_b reduced to an s-code token (else 'file')"
metrics:
  tasks: 2
  files: 4
  completed: 2026-11-16
requirements-completed: [NEW-01, NEW-02, NEW-04, NEW-05]
---

# Phase 15 Plan 04: New-source QC writer Summary

QC workbook writer `qc\new_source_intake.xlsx` (KEY leftmost, UF header fill) plus a privacy-safe summary (counts 1..10 as `<11`, PASS/STOP gate lines) and the SAS-to-Python exchange schema for the eight Phase 15 CSVs.

## Tasks
1. Module, tests and schema rows - 111bd8d
2. CLI entry point with --allow-partial - a4b01c5

Verification: `ruff check python\` clean; `pytest python\tests` 170 passed (19 new). Schema row counts: guard 4, one_to_one 8, overlap 5; pcnr_typecheck unchanged (6).

## Deviations from Plan
None - plan executed as written. The variants CSV did not yet exist in docs/ when executed; handled as optional input (see decisions).

## Assumptions (headless run)
- A6: QC is delivered as exchange CSVs plus a Python-written `qc\new_source_intake.xlsx`.
- The workbook lives on P: and shows exact counts; only the summary text is masked.
- Gate lines print `NO DATA (PENDING SAS RUN)` when the relevant CSV rows are absent (not specified in the plan).
- NONASCII and TYPE_CHANGES are summarized as aggregate masked counts, not per-column lines, to avoid emitting column names.
- Not run against real exchange files (no P:, no SAS). Pending: Gerard runs `python\scripts\write_new_source_qc.py` after 15a-15c.

## Known Stubs
None.

## Self-Check: PASSED
