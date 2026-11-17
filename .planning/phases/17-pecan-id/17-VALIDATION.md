---
phase: 17
slug: pecan-id
status: planned (revised 2026-11-17 for PDD-D-32)
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-17
---

# Phase 17 - Validation Strategy

Headless limit: nothing that reads data runs here. Validation = static lint + pytest static tests + the synthetic SAS tests (Gerard) + the QC files from the real run, checked against probe numbers.

| Requirement | Plan | Check |
|---|---|---|
| PID-01 values unchanged | 17-02 | K1 `pecan_ID` copied from `g.master_data_harmonized` through the PR-3 surgery key (PDD-D-32); K1 gate: matched rows = spine rows = harmonized rows, 1:1, 0 missing pecan_ID, 0 multi-match; static test forbids arithmetic on pecan_ID and forbids an MRN lookup in `pecan_id_xwalk` |
| PDD-D-32 dup link | 17-01/02 | `pdd.pecan_id_dup_link` append-only; gate reports pair count at run time (expected near 1,895, not hard-coded); synthetic test has a 1:1 join case and a dup-pair case; blank spine MRN rows reported on their own line |
| PID-02 key eras | 17-01/03 | KEY_ERA in (K1,K2) gate; lookups on (MRN,ERA); no cross-era compare |
| PID-03 append-only registry | 17-01/02/03 | backup before append (K1 rows from the PDD-D-32 join; K1 unique on PECAN_ID, K2 unique on (MRN,K2) and PECAN_ID); assert_backup_current; no delete/rewrite (static); idempotent rerun appends 0 |
| PID-04 K2 = 1000000 + rank | 17-01/03 | synthetic T-rank, T-max+1; gate K2 >= 1000001, K1 < 1000000 |
| PID-05 key era + caveat | 17-03/05 | PECAN_ID_KEY_ERA in case map; caveat text file and 17c rows |
| PID-06 link program | 17-04 | synthetic link test; never run; not in any phase token |
| PID-07 cases per patient | 17-05 | 17c reconciles to case map totals |
| PID-08 g read-only | 17-01/02 | `access=readonly`; static test no write to g |
| PDD-D-30 before IDs | 17-01/03 | synthetic dedupe test; 142 / 0 pair gate; 36,348 expected case total reported |
| Gates fail on duplicate or unmapped IDs | 17-01/03 | negative synthetic tests (FLAG mode) + real-run gates |

Lint rules: C30 (no semicolons in %put/%fail_out text), C31 (stop; in POINT= steps), C32 (no reserved column names in PROC SQL), plus C1, C3, C9, C11, C13, C14.

Commands: `python tools\sas_lint.py sas\<file>.sas`; `sasjs lint`; `ruff check python\`; `.venv\Scripts\python.exe -m pytest python\tests -q`.
