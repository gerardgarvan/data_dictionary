# Phase 19 SAS run sheet, Wave 1 (for Gerard)

**Status: COMPLETE 2026-11-18** (all steps incl. Wave 2 run on real data and passed; see 19-SUMMARY.md). Historical text follows:  Written lint-clean on a machine with no SAS and no P:. Wave 1 only: the synthetic test and the probe/preflight 19a. Nothing here needs a PDD-D-35..44 or PDD-D-27 decision; those stay PENDING DECISION and 19a only lists them.
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
| `allow-list gate failed` | (fix_19a) names with MRN, ENCRYPT or ENCOUNTER fail unless listed in `docs\xlsx_name_exceptions.csv` AND role MAPPED (only `PCNR_Age_at_Encounter` is listed); a listed name that is not in the dataset, is KEY or is not name-flagged also fails; a missing exceptions file fails. QC items `columns_name_flag_excepted` / `columns_name_flag_unexcepted` (gate uses the latter). Otherwise: a column of `pdd.pcnr_2018_2025` is not a key column or mapped PCNR_ name, or has MRN, ENCRYPT or ENCOUNTER in its name. Names are in `work.p19a_cols_flagged` (log the NOTE lines); decide before Wave 2 |
| `limits gate failed` | rows+1 >= 1,048,575, columns >= 16,384, text over 32,767, a control character, or free disk below `PDD_XLS_MIN_FREE_GB` (15): see which `limit_*` row has `isfail` 1. A control character or over-long text is a PENDING DECISION (strip or abort) |
| `read-only guard failed` | registry, dup link or case map row count changed during the run |
| `the benchmark CSV could not be deleted` | delete `out_root\stage\xlsx_bench.csv` by hand, it holds row-level data |

## Time (unmeasured estimate)
Step 1 under 2 minutes. Step 2: one pass over the dataset plus one grouped read, 5-20 minutes.

## Update 2026-11-18 (decide_19)

Decisions PDD-D-35..44 and PDD-D-27 are DECIDED and the `PDD_XLS_*` defaults are set in `sas/00_config.sas` (PDD_XLS_APPROVE stays empty). The Wave 1 run order above is unchanged. 19a will now report `1 of 11 PDD_XLS decisions` empty (APPROVE, by design). For Wave 2 Gerard sets `PDD_XLS_APPROVE` at run time only (`options set=PDD_XLS_APPROVE 1`), never in config. Backlog: the INT_IN_DATE_RANGE probe range was too broad to be informative; the export masks flags/timings 1-10 (change to mask only person/cell counts).

---

# Wave 2, part A: stage export (19b) - PENDING SAS RUN

Wave 1 passed (19_xlsx_test ALL TESTS PASSED, 19a PASS). Decisions are DECIDED. This part runs the SAS side only; the Python writer and verifier (part B) come after and are not in this sheet yet.

## Run order (fresh SAS session for each program, same command template as above)
| Step | Program | Expect | Bring back |
|---|---|---|---|
| 1 | `19_xlsx_test.sas` (now with T16 key set, T17 column list, T18 synthetic stage + expected) | `TESTRESULT SUMMARY: ALL TESTS PASSED`; `[PASS]` for T16_*, T17_*, T18_*; no `WARNING`/`ERROR` line | the log |
| 2 | set `PDD_XLS_APPROVE` to 1 for the run only: `options set=PDD_XLS_APPROVE '1';` before, then `19b_xlsx_stage.sas` | `PASS - stage written, row count equal` in `logs\19b_xlsx_stage.log` | `logs\19b_xlsx_stage.log`; `qc\xlsx_master_stage.csv` |
| 3 | `options set=PDD_XLS_APPROVE '0';` after the run (or end the session). Never put it in `00_config.sas` | - | - |

Without the approval flag 19b stops with `PENDING DECISION: PDD_XLS_APPROVE is empty` before touching any file (nothing is written but the QC row set).
If step 1 shows any `[FAIL]` line, send the log back and do not run step 2.

## What 19b does
1. Decision gate on all 11 `PDD_XLS_*` values (each must be the decided, implemented value; APPROVE must be 1), path guard on every target, required tables.
2. Allow-list gate, then `%p19_columns` with key set K3: `PECAN_ID`, `PRECEDE_STUDY_ID`, `KEY_ERA`, then the PCNR_ variables in dataset order. `NORM_PSID` and `PECAN_ID_KEY_ERA` are never staged.
3. One pass probe plus the XLS-02 limits gate on the real dataset (exported column count).
4. `%p19_stage`: `stage\xlsx_data.csv` and `stage\xlsx_schema.csv`; `PCNR_Death_Days_After_Surgery` is staged as delivered text (the Python writer converts it).
5. Record count of the closed CSV (quote aware) must equal dataset rows + 1.
6. `%p19_expected`: `stage\xlsx_expected.csv` (exact counts, 2,000 row seeded sample list).
7. Registry, dup link and case map row counts unchanged. QC written once.

Writes: `stage\xlsx_data.csv`, `stage\xlsx_schema.csv`, `stage\xlsx_expected.csv` (all under `P:\PeCAN Master Data\Gerard\data_dictionary\stage`), `pdd.qc_xlsx_stage`, `qc\xlsx_master_stage.csv` (masked), the log. `xlsx_data.csv` is row-level identifiable data: do not copy it, do not bring it back. It is deleted by the verifier on PASS (part B); delete it by hand if you stop here. Nothing is written to the shared Master Data folder.

## PowerShell checks (counts only, from `P:\PeCAN Master Data\Gerard\data_dictionary`)
```
# the PASS line and no problem lines
Select-String -Path logs\19b_xlsx_stage.log -Pattern 'PASS - stage written'
Select-String -Path logs\19b_xlsx_stage.log -Pattern '^(ERROR|WARNING)' | Measure-Object | Select-Object Count
# QC table (masked): every isfail 0
Import-Csv qc\xlsx_master_stage.csv | Format-Table tbl,item,n,isfail -AutoSize
Import-Csv qc\xlsx_master_stage.csv | Where-Object { $_.isfail -ne '0' }
# stage sizes (bytes) and header column count; no values printed
Get-ChildItem stage\xlsx_*.csv | Select-Object Name,Length
(Get-Content stage\xlsx_schema.csv | Measure-Object -Line).Lines - 1
# expected counts file: row count and sample size only
Select-String -Path stage\xlsx_expected.csv -Pattern '^ROWS,'
(Select-String -Path stage\xlsx_expected.csv -Pattern '^SAMPLE,' | Measure-Object).Count
# schema must not list the copies or MRN fields (expect 0)
(Select-String -Path stage\xlsx_schema.csv -Pattern 'NORM_PSID|PECAN_ID_KEY_ERA|MRN|ENCRYPT' | Measure-Object).Count
```
Expected: `stage_csv_records_incl_header` equals `dataset_rows` + 1 in the QC CSV (counts in QC may show `<11` only for 1-10); `export_columns` = dataset columns minus 2 (the two excluded key copies); sample count = 2000; schema line count = `export_columns`.

## If 19b stops
| Stop text | Meaning |
|---|---|
| `PENDING DECISION: PDD_XLS_APPROVE is empty` | the approval flag was not set for this session (step 2) |
| `PENDING DECISION: PDD_XLS_<x> is empty` / `... outside the allowed list` | config value empty or one that 19b does not implement (route (a)/(c), DROP, ERA sheets, CODE_TEXT, CONVERT): revise plan 19 |
| `path guard - ...` | a target is outside `out_root` or holds the shared folder or `..` |
| `allow-list gate failed` / `export column gate failed` | a column is not a key of K3 and not a mapped PCNR_ variable, or has an MRN-like name without a reviewed exception; names are in the log NOTE lines |
| `limits gate failed` | rows, columns, text length, control character or free disk: see the `limit_*` row with `isfail` 1 |
| `stage CSV record count differs from dataset rows plus one` | stage CSV is wrong: delete the three stage files, send the log back |
| `read-only guard failed` | registry, dup link or case map row count changed during the run |

## Time (estimate, unmeasured)
Step 1 under 2 minutes. 19b: one probe pass, one stage pass, one expected-count pass plus a read of the CSV: 10-40 minutes (the 19a benchmark gives the pass time to scale from).

---

# Wave 2, part B: Python writer and verifier (after 19b PASS) - PENDING RUN

No SAS needed. Run from `C:\data_dictionary` in PowerShell on the machine that sees `P:`. Needs 19b to have PASSed (stage files present) and `pandas`/`openpyxl` from `python\requirements.txt` (`read_sas` is part of pandas; no extra package). The approval flag is set for this PowerShell session only; clear it at the end.

## Run order
| Step | Command | Expect | Bring back |
|---|---|---|---|
| 0 | `$env:PDD_XLS_APPROVE='1'` | - | - |
| 1 (bench first) | `.venv\Scripts\python.exe python\scripts\write_master_workbook.py --bench-rows 20000` | `BENCH rows=20000 rows_per_s=<n> extrapolated_full_minutes=<m>`; throwaway `stage\xlsx_bench.xlsx` is deleted at once | the BENCH line and `logs\write_master_workbook.log` |
| 2 | `.venv\Scripts\python.exe python\scripts\write_master_workbook.py` | `PASS - master workbook written`; `out\PCNR_Master_Data_Nov_2026.xlsx`; an older final file is first moved to `backup\PCNR_Master_Data_Nov_2026_<stamp>.xlsx` | `logs\write_master_workbook.log`; `qc\xlsx_master_write.csv` |
| 3 | `.venv\Scripts\python.exe python\scripts\verify_master_workbook.py` | `PASS - master workbook verified` and `stage files deleted: ...`; exit code 0 | `logs\verify_master_workbook.log`; `exchange\xlsx_master_verify_summary.csv` (masked, safe) |
| 4 | `Remove-Item Env:PDD_XLS_APPROVE` | - | - |

If the bench extrapolation looks too long, send the BENCH line back before step 2 (backlog: XlsxWriter). The writer takes minutes to hours depending on rows x columns; the output file is large, check free disk first (the gate wants 15 GB).

## What the writer does
KEY sheet first (UF header colors, identifiable-fields notice, pointer to `out\pdd_2018_2025.xlsx`, facts, ID text, missing-value convention, Price sign-off PENDING, era notes), then DATA with the K3 keys and the PCNR_ variables. `PCNR_Death_Days_After_Surgery` is numeric; non-numeric text there is blank and counted (`death_days_nonnumeric_blanked`, `<11` if 1-10). Text beginning `=` or `#` is stored as text. The file is written to `<name>.tmp` and renamed only on success; on any failure no file is left at the final name (the previous file is already in `backup\`). It also writes `stage\xlsx_write_counts.csv` (exact counts for the verifier; deleted on PASS). Log lines carry counts and column names only.

## What the verifier checks (items in `qc\xlsx_master_verify.csv`, counts 1-10 shown `<11`)
sheet order (KEY, DATA); header equals the stage schema and the K3 keys come first; row count; per-column non-blank counts equal `stage\xlsx_expected.csv` exactly (Death_Days: expected minus blanked) and agree with `exchange\comb_recon.csv` (masked `<11` tolerated; text columns that hold numbers compare as text counts; NO_DATA variables from `comb_nodata.csv` must be 0); 2,000-row sample equality with the stage CSV and a type tally; no formula element or error cell anywhere in the sheet XML; KEY notice lines, DATA_ROWS, DATA_COLUMNS, facts equal `comb_key_facts.csv`, and K1/K2 row and distinct-ID facts agree with the DATA sheet; disclosure scan: flagged header names, and every text cell token against the registry ENCRYPTED_MRN values read in memory from `pecan_id_registry.sas7bdat` (hit count only; expect 0). Exit 0 only if every item is PASS; on PASS the four stage files are deleted (PDD-D-42 = NONE). On FAIL the stage files are kept: send `qc\xlsx_master_verify.csv` rows with `status=FAIL` (names and masked counts) and the log.

## PowerShell checks (counts only, from `P:\PeCAN Master Data\Gerard\data_dictionary`)
```
Select-String -Path logs\write_master_workbook.log -Pattern 'PASS - master workbook written'
Select-String -Path logs\verify_master_workbook.log -Pattern 'PASS - master workbook verified'
Import-Csv qc\xlsx_master_verify.csv | Where-Object { $_.status -ne 'PASS' }
Import-Csv exchange\xlsx_master_verify_summary.csv | Format-Table -AutoSize
Get-ChildItem stage\xlsx_*.csv    # expect nothing after PASS
Get-Item out\PCNR_Master_Data_Nov_2026.xlsx | Select-Object Name,Length
```

## If a step stops
| Stop text | Meaning |
|---|---|
| `PENDING DECISION: PDD_XLS_APPROVE is not 1` | step 0 not done in this session |
| `data CSV header differs from xlsx_schema.csv` / `unexpected non-PCNR_ column` / `column name flagged` | stage and schema disagree or an MRN-like column slipped in: re-run 19b, do not edit the CSV |
| `illegal control character in N column(s): <names>` / `text over 32767 characters in column <name>` | a cell cannot be stored: PENDING DECISION (strip or abort), no value is shown |
| `unparseable numeric text in column <name>` | a numeric column holds text: fix upstream |
| `stage record count differs from xlsx_expected ROWS` | stage CSV and expected counts are out of step: re-run 19b |
| `free disk ... below` | free space on the out folder |
| verifier exit 1 with `FAIL <check> <column>` lines | see the check table above; stage kept |
