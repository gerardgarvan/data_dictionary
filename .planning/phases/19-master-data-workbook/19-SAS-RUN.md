# Phase 19 SAS run sheet, Wave 1 (for Gerard)

**Status: PENDING SAS RUN.** Written lint-clean on a machine with no SAS and no P:. Wave 1 only: the synthetic test and the probe/preflight 19a. Nothing here needs a PDD-D-35..44 or PDD-D-27 decision; those stay PENDING DECISION and 19a only lists them.
Later steps (19b stage export, writer, verifier) are Wave 2 and are not in this sheet.

## Before you start
1. Sync branch `pdd-2018-2025-api`. `pdd.pcnr_2018_2025`, `pdd.name_map_vars_ext`, `pdd.pecan_id_registry`, `pdd.pecan_id_dup_link`, `pdd.pecan_id_case_map` must exist on P:.
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. SAS command template:
   `"C:\Program Files\SAS94\SASFoundation\9.4\sas.exe" -sysin "C:\data_dictionary\sas\<program>.sas" -config "C:\Program Files\SAS94\SASFoundation\9.4\nls\u8\sasv9.cfg" -encoding utf8 -nosplash -icon`

## Session rule
Run **each program in a fresh SAS session** and close every table viewer on `pdd` first. The synthetic test repoints `pdd` at WORK and restores it; never run it in the same session as 19a. Do not close SAS before the PASS line is in the log.

## Run order
| Step | Program | Expect | Bring back |
|---|---|---|---|
| 1 | `19_xlsx_test.sas` (synthetic, WORK only; log goes to `<WORK>\19_xlsx_test.log`, PASS/FAIL lines echoed at the end) | `TESTRESULT SUMMARY: ALL TESTS PASSED`; all `[PASS]` lines for T0..T15; no `WARNING` and no `ERROR` line | the log |
| 2 | `19a_xlsx_preflight.sas` | `PASS - preflight complete, limits gate PASS, nothing written to the combined dataset`; `NOTE: ... of 11 PDD_XLS decisions are PENDING DECISION (expected in a probe run)` | `logs\19a_xlsx_preflight.log`; `qc\xlsx_master_pre.csv`; `qc\xlsx_master_probe.csv`; `exchange\xlsx_master_probe_summary.csv` |

Expected PASS lines in step 1 (case names): T0_SESSION_IS_UTF8, T0_PDD_LIBREF_RESTORED, T0_FAIL_MODE_RESTORED, T1_* (inside out_root and out_root itself pass; shared folder, unrelated folder, same-prefix sibling, parent reference, shared name under out_root fail), T2_* (decision gate), T3_* (probe counts against hand counts), T4_* (limits boundaries), T5_* (control character gate), T6_* (allow list), T7_* (keys, mask, top-code), T8_* (mask rule), T9_* (probe report), T10_* (free-space parse), T11_* (benchmark file written and deleted), T12_* (MRN scan 0 and 1 hits), T13_* (25 qadd calls, one write), T14_* (QC dump), T15_NO_WARNINGS_OR_ERRORS_IN_LOG, T15_NO_FAKE_MRN_IN_LOG_OR_CSV. Any `[FAIL]` line: send the log back, change nothing.

## What 19a reads and writes
- Reads: `pdd.pcnr_2018_2025` (once for the probe, once for the key counts, 1,000 rows for the speed test), `pdd.name_map_vars_ext`, and counts of the three pecan_id tables. Read-only everywhere: the registry, dup link and case map row counts are compared at start and end.
- Writes: `pdd.qc_xlsx_pre` (one flush, staged in WORK), the three files above, the log, and a throwaway `out_root\stage\xlsx_bench.csv` (1,000 rows, row-level data) that is deleted at once; the delete is checked and a failure aborts with the file name. Nothing goes to the shared Master Data folder. Path guard runs first on every target.
- If `qc\xlsx_master_pre.csv` shows a failed limit row, the program stops with the reason in the `ERROR` line after writing QC.

## What the probe answers (P19-1..P19-8)
| Probe | Where to read it |
|---|---|
| P19-1 numeric date-like variables | `xlsx_master_probe.csv`, rows `INT_IN_DATE_RANGE`, `INT_IN_DTTM_RANGE` per variable (a hint, counts only; formats are not probed) |
| P19-2 text length, control chars, newlines, non-ASCII, replacement char | rows `MAXLEN` (exact length), `GT255`, `CTRL`, `NEWLINE`, `NONASCII`, `REPLCHAR` |
| P19-3 formula risk, leading zeros | rows `LEAD_EQ`, `LEAD_HASH`, `LEAD_PLUS`, `LEAD_MINUS`, `LEAD_AT`, `LEAD_ZERO` |
| P19-4 numeric precision | rows `GE_1E15`, `NO_15SIG_ROUNDTRIP` |
| P19-5 special missing | rows `SPECIAL_A`..`SPECIAL_Z`, `SPECIAL__` |
| P19-6 key columns | rows `XTAB_<KEY_ERA>_<PECAN_ID_KEY_ERA>`, `ERA_ROWS_<era>`, `PSID_DIFFERS_<era>` (variable `KEYS`) |
| P19-7 speed and disk | `qc\xlsx_master_pre.csv` rows `sas_bench_seconds_1000_rows_x100` (seconds x 100, rounded up), `sas_bench_estimate_full_minutes`, `limit_free_disk_gb_min` (-1 free disk means XCMD is off: check by hand, row `free_disk_not_measurable_check_by_hand`). The Python writer benchmark is Wave 2 |
| P19-8 dataset facts | rows `dataset_rows`, `dataset_columns`, `dataset_character_columns`, `dataset_numeric_columns`, `dataset_encoding_is_utf8_1_else_0` |

Masking: counts 1-10 appear as `<11`; a count within 10 of its total is top-coded as `>(total-11)`; `MAXLEN` is a length and stays exact. `qc\xlsx_master_pre.csv` holds exact table-level counts (rows, columns) and stays on P: if you prefer; the probe CSVs are masked. No cell values, IDs or MRNs appear in any file.

## Extracting the counts (PowerShell, from `P:\PeCAN Master Data\Gerard\data_dictionary`)
```
# limits and facts
Import-Csv qc\xlsx_master_pre.csv | Format-Table tbl,item,n,isfail -AutoSize
# any failed row
Import-Csv qc\xlsx_master_pre.csv | Where-Object { $_.isfail -ne '0' }
# probe: variables with control characters, formula-risk text, special missing
Import-Csv qc\xlsx_master_probe.csv | Where-Object { $_.chk -in 'CTRL','REPLCHAR','LEAD_EQ','LEAD_HASH','LEAD_PLUS','LEAD_MINUS','LEAD_AT' } | Format-Table -AutoSize
Import-Csv qc\xlsx_master_probe.csv | Where-Object { $_.chk -like 'SPECIAL_*' } | Group-Object chk | Select-Object Name,Count
# longest text and cells over 255
Import-Csv qc\xlsx_master_probe.csv | Where-Object { $_.chk -in 'MAXLEN','GT255' } | Sort-Object { [int]($_.n_masked -replace '[<>]','') } -Descending | Select-Object -First 10
# key columns
Import-Csv qc\xlsx_master_probe.csv | Where-Object { $_.variable -eq 'KEYS' } | Format-Table -AutoSize
# summary per check (safe to bring back)
Import-Csv exchange\xlsx_master_probe_summary.csv | Format-Table -AutoSize
# log must have no problem lines
Select-String -Path logs\19a_xlsx_preflight.log -Pattern '^(ERROR|WARNING)' | Measure-Object | Select-Object Count
Select-String -Path logs\19a_xlsx_preflight.log -Pattern 'PASS - preflight complete'
```

## If 19a stops
| Stop text | Meaning |
|---|---|
| `path guard - ...` | a target path is outside `out_root`, inside the shared Master Data folder, or has `..`: config problem |
| `allow-list gate failed` | a column of `pdd.pcnr_2018_2025` is not a key column or mapped PCNR_ name, or has MRN, ENCRYPT or ENCOUNTER in its name. Names are in `work.p19a_cols_flagged` (log the NOTE lines); decide before Wave 2 |
| `limits gate failed` | rows+1 >= 1,048,575, columns >= 16,384, text over 32,767, a control character, or free disk below `PDD_XLS_MIN_FREE_GB` (15): see which `limit_*` row has `isfail` 1. A control character or over-long text is a PENDING DECISION (strip or abort) |
| `read-only guard failed` | registry, dup link or case map row count changed during the run |
| `the benchmark CSV could not be deleted` | delete `out_root\stage\xlsx_bench.csv` by hand, it holds row-level data |

## Time (unmeasured estimate)
Step 1 under 2 minutes. Step 2: one pass over the dataset plus one grouped read, 5-20 minutes.
