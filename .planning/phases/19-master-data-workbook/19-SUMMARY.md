# Phase 19 SUMMARY: Master Excel export

**Status: COMPLETE 2026-11-18** (verified on real data by Gerard; counts masked, 1-10 shown as <11).
Requirements XLS-01, XLS-02, XLS-03, XLS-04 satisfied.

## Deliverable
`out\PCNR_Master_Data_Nov_2026.xlsx` (75.7 MB) under `P:\PeCAN Master Data\Gerard\data_dictionary`: KEY sheet leftmost (facts, notice, Price naming pending) and one DATA sheet, 77,499 records, 1,300 columns (K3 keys PECAN_ID, PRECEDE_STUDY_ID, KEY_ERA + 1,297 variables; PECAN_ID_KEY_ERA and norm_psid excluded). Route: SAS stage CSV + typed schema (19b), Python openpyxl write_only writer, separate Python verifier. Stage files deleted after verification.

## Decisions (docs/DECISIONS.md)
- PDD-D-27: dictionary stays its own workbook (`out\pdd_2018_2025.xlsx`); KEY points to it.
- PDD-D-35..44: STAGE_CSV route; 56 NO_DATA variables included; dataset (DICT) column order; SERIAL dates (nothing converts); NUM_TEXT stays text except `PCNR_Death_Days_After_Surgery` numeric; special missings blank; one DATA sheet; no companion files; K3 key set; run-time-only `PDD_XLS_APPROVE`.
- Audience: PeCAN team only. Content kept as is (no redaction/recoding).

## Verified results (Gerard, 2026-11-18)
- `19_xlsx_test`: ALL TESTS PASSED (after fix_19w2a, a2, a3).
- 19a preflight PASS (after fix_19a).
- 19b stage PASS: 1,300 columns, 77,499 records = 77,499 physical lines, limits clean (max cell length 199, 0 control chars), Phase 17 tables unchanged.
- Writer: bench 403 rows/s; full write PASS in about 2 min (after fix_19w2b1).
- Verifier PASS: 2,687 items, 0 failed (nonblank counts vs stage 1,300 and vs recon 1,297; NO_DATA 56; sample values/types; 0 formula/error cells; 0 registry token hits; KEY facts/notice/Price pending).

## Fix chain (one-line root causes)
- **fix_19a:** the name allow-list gate gave a false positive on legitimate variable names; added an exceptions file with tests.
- **fix_19w2a (lint C39):** the stage built a character variable of length $65540, above SAS's 32,767 limit; character cells are now written in pieces.
- **fix_19w2a2 (lint C40):** `_INFILE_` with LRECL above 32767 fails at run time; readers now stream raw 32,767-byte blocks (`p19_csv_scan`).
- **fix_19w2a3 (lint C41):** `ifc()` pads its result to the longest branch, so `||` picked up a blank; `p19_expected` now writes empty fields.
- **fix_19w2b1:** SAS-written CSVs carry a UTF-8 BOM that became U+FEFF in the first header name; readers use `utf-8-sig`, strip header names, and assert no U+FEFF in the DATA header.

## Lint rules added
C39 (character LENGTH above 32767, including generated `put "..."` text), C40 (INFILE LRECL above 32767 in a step that references `_INFILE_`), C41 (`ifc()` as an operand of `||`).

## Lessons
- Run-time-only limits (variable length, `_INFILE_`/LRECL, padding functions) are invisible to a synthetic test with small values: add max-length cells to the test (T18) and a lint rule for each such failure.
- SAS-written CSVs may have a BOM; always read with `utf-8-sig` and assert on the header.
- A separate verifier that compares against stage and recon counts caught nothing new only because the fix chain had already closed the gaps; keep it independent of the writer.
- Benchmark the writer before the full write (403 rows/s gave a reliable time estimate).

## Backlog added
See STATE.md "Backlog (added at Phase 19 close)".

## Open items carried forward
Price naming sign-off; DSS question on the `#Error` deaths with Death_Date_Y_N = Y; cleanup items 1, 2, 3, 5; future cross-era link.

## Assumptions (headless run)
- Fix-chain root causes taken from the close_19 prompt and commit messages d2e7cc4, 07c4098, 7d1f919, 1b76d9d, 22802e8.
- Docs and planning only; no SAS or Python logic changed.
