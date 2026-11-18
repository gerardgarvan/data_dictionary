# Phase 19: Master data workbook PCNR_Master_Data_Nov_2026.xlsx - Context

**Gathered:** 2026-11-18 (headless planning run; no SAS, no P:, no data read)
**Status:** PLANNED, execution blocked on PENDING DECISIONs PDD-D-35..44 (section "Open design choices") for the tasks that depend on them. Tasks that do not depend on a decision can start (see 19-PLAN.md waves).
**Requirements:** XLS-01, XLS-02, XLS-03, XLS-04 (`.planning/REQUIREMENTS.md` lines 70-73).
**Inputs read:** `18-SUMMARY.md`, `18-CONTEXT.md`, `18-SAS-RUN.md`, `docs/DECISIONS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` (Phase 19 block), `docs/combined_type_decisions.csv`, `docs/exchange_schema.csv`, `docs/pecan_id_dictionary_text.csv`, `sas/18_combine_macros.sas`, `sas/00_config.sas`, `run_pipeline.cmd`, `python/requirements.txt`, `.planning/schemas/probe_master_data_20261116.md`.

## 1. Facts this plan stands on (all from files in the repo)

| Fact | Source |
|---|---|
| `pdd.pcnr_2018_2025`: 77,498 rows x 1,302 columns = 5 key columns + 1,297 PCNR_ variables; values as delivered (no recoding) | 18-SUMMARY |
| The 5 key columns, in order: `PECAN_ID` (num 8), `PRECEDE_STUDY_ID` ($64), `PECAN_ID_KEY_ERA` ($2), `KEY_ERA` ($2), `NORM_PSID`. Then PCNR_ variables alphabetical (D18-4) | `p18_order_cols`, `p18_gate_vars` |
| Combined types are only `N` (numeric, length 8) or `C` (character, length = max over sources); no other type exists in the PCNR_ layer | `docs/combined_type_decisions.csv`, `p18_set_lengths` |
| NUM_TEXT variables exist (27 seen in 18c): character columns holding numbers; profile N counts only cells that parse, `n_nonmiss_comb_all` counts every non-blank cell (N + N_UNPARSED) | fix_18d, PDD-D-34 |
| Special missings `.A-.Z`, `._` count as missing everywhere; `n_special_comb_all` in `exchange\comb_recon.csv` counts them (masked <11) | PDD-D-34 |
| 56 NO_DATA variables (all from s06, no value in any row); `exchange\comb_nodata.csv` | 16-05, 18-SUMMARY |
| Source dates: the probe shows source date-like columns as **Char** (`preop_date` Char 8, `test_date` Char 31, no format). Whether any PCNR_ variable is a numeric SAS date/datetime is **not in a probe** | probe_master_data_20261116.md; see PROBE REQUEST P19-1 |
| Python is available on the SAS machine (`.venv`, `run_pipeline.cmd :run_python`); `openpyxl==3.1.5` and `pandas>=3.0` are pinned, `XlsxWriter` and `pyarrow` are **not** in `python/requirements.txt` | `python/requirements.txt`, `run_pipeline.cmd` |
| Registry `pdd.pecan_id_registry` holds `ENCRYPTED_MRN`; `p18_scan_no_mrn` is the existing scan pattern (hit count only) | `18_combine_macros.sas` |
| Handoff: any percentage in the workbook comes from the scrubbed `profile_PCNR_2018_2025.csv` or is recomputed with the same masking; never from `pdd.prf_PCNR_2018_2025`. Output only under `P:\PeCAN Master Data\Gerard\data_dictionary` | 18-SUMMARY |

Size arithmetic (orientation, computed from the counts above): 77,498 x 1,297 = 100,512,506 PCNR_ cells (+ 4 x 77,498 key cells) = about 100.8 million cells. 77,499 rows with the header is 7.4 % of the 1,048,576 row limit; 1,297 to 1,301 columns is 8 % of 16,384.

## 2. PROBE REQUESTS (PENDING SAS RUN)

Facts missing from every probe. Program 19a (read-only, planned in 19-03) answers all of them; nothing is guessed in the meantime.

- **P19-1 Numeric date/time variables.** Count and list (names only) the PCNR_ variables that are numeric with a SAS date, time or datetime format, and numeric variables with no format whose name ends `_date`/`_dttm` and whose values fall in the SAS date range. Decides PDD-D-38 scope (if 0, PDD-D-38 reduces to "text dates stay text").
- **P19-2 Character width.** Maximum `length` of any character column and the maximum actual trimmed length over all cells (limit 32,767). Count of cells with a control character (`'00'x-'08'x, '0B'x, '0C'x, '0E'x-'1F'x`), which Excel/openpyxl cannot store (`IllegalCharacterError`).
- **P19-3 Excel-hostile text.** Per character variable, count of cells starting with `=`, `#` (openpyxl turns `#N/A`-style strings into error cells), `+`, `-`, `@`; cells with leading zeros that look numeric; cells longer than 255 characters. Counts only.
- **P19-4 Numeric precision.** Count of numeric variables with any value whose absolute value is >= 1e15 or that has more than 15 significant digits (Excel shows 15).
- **P19-5 Special missings.** Number of numeric variables with `n_special_comb_all` > 0 (readable already from `exchange\comb_recon.csv`; 19a repeats it from the dataset and lists the distinct codes per variable, codes only).
- **P19-6 Key columns.** Crosstab counts of `KEY_ERA` x `PECAN_ID_KEY_ERA`, and whether `NORM_PSID` = `PRECEDE_STUDY_ID` on every row (count of differing rows). Needed for PDD-D-43.
- **P19-7 Disk and speed.** Free space on the drive that holds `out_root` and on the Python temp drive; a timed benchmark: SAS stage-export of 1,000 rows, and Python writing 1,000 rows x 1,297 columns to a throwaway xlsx under `stage\`, with the extrapolated full-run time. Replaces every estimate in section 5 with a measured value.
- **P19-8 Encoding.** Whether the stage CSV round-trips every character (count of cells whose UTF-8 re-read differs from the SAS value, in a sample).

## 3. Route comparison (decision PDD-D-35, recommendation (b))

Workload: about 100.8 million cells, 77,498 rows, 1,301 columns, mostly sparse (many NO_DATA / era-specific columns blank), mix of 8-byte numerics and character text, runs on the SAS machine (P: access, `.venv` Python available, SAS 9.4).

| Criterion | (a) SAS `PROC EXPORT DBMS=XLSX` (or `LIBNAME XLSX`) | (b) SAS stage CSV (+ typed schema file) -> Python `openpyxl` write_only | (c) SAS `ODS EXCEL` |
|---|---|---|---|
| Runtime at ~100M cells | Single threaded, builds the sheet in memory first; expected hours or failure; unmeasured, no way to check without SAS | SAS CSV write is a straight DATA step `PUT` (minutes); openpyxl write_only streams rows (about 0.1-0.5 M cells/s, so tens of minutes); both stages restartable | ODS builds styled XML per cell and per-cell style metadata; slowest of the three, usually impractical past a few million cells |
| Memory | Whole sheet in memory in SAS/ACCESS PC Files; real risk at 100M cells | Constant: one row at a time in Python; SAS streams | High |
| Excel limits | Stops or truncates silently on limit breach (rows, 32,767 chars); no pre-check hook | Own pre-checks (XLS-02) before and during the write; fails loud | Same as (a) |
| Dates/times | Honors SAS format; Excel date only if a date format is attached | Full control: serial number plus `number_format`, or text; schema file says which | Format dependent |
| Numeric precision | Doubles, ok | Doubles via `repr`; SAS `best32.` in the stage keeps 17 digits | Doubles, but ODS may apply the display format (rounding) |
| Special missing | Written as blank; no control | Control: blank, code text or both (PDD-D-40) | Format dependent (`MISSING=` option) |
| Text safety | No control over formula/error interpretation | Control: force `data_type='s'` for strings starting `=` or `#` (openpyxl otherwise writes `=...` as a formula and `#N/A` as an error cell) | Partial |
| KEY sheet styling (UF `#0021A5`, `#FA4616`), KEY leftmost, frozen header, column widths | Not possible with PROC EXPORT; possible only by post-editing | Full control; reuses `python/pdd/xlsx_style.py` and the Phase 18 writer pattern | Possible but heavy |
| File size | Similar; sparse cells written as empty cells | Sparse cells are skipped (not written); smaller | Larger (style per cell) |
| Runs on the SAS machine | Yes, needs SAS/ACCESS to PC Files licensed (not checked) | Yes: `run_pipeline.cmd :run_python` already runs `.venv` Python there (Phase 18 writer) | Yes |
| Fits repo patterns | No Python tests possible on this machine | Yes: writer and verifier are unit-testable here with synthetic data; SAS side follows the 17/18 program pattern | No |
| Independent verification | Reading back through the same engine proves little | Verifier is a separate code path (streaming read, header scan, MRN scan) | Same engine |

**Recommendation: (b).** It is the only route that gives pre-write limit checks, explicit type and date control, safe handling of `=`/`#` text, special-missing control, KEY sheet styling, constant memory, restartable stages and tests runnable on this machine. Cost: a staged CSV (about 100M cells of text, estimated 1-3 GB, unmeasured) under `out_root\stage\`, deleted after the verifier passes unless PDD-D-42 keeps it. Two sub-variants for the stage: (b1) CSV plus a typed schema CSV (recommended: no new dependency, special missings controllable); (b2) `pandas.read_sas` on the sas7bdat directly (no stage file, but loses special-missing codes and depends on encoding of the dataset; not recommended). Parquet needs `pyarrow`, not in the pinned requirements; it would need a new dependency and a sign-off, no benefit at this size. XlsxWriter in `constant_memory` mode is faster than openpyxl and is the fallback if the benchmark (P19-7) projects more than the time budget; adding it is a dependency change and goes through a PDD-D decision, not applied here.

## 4. Open design choices (all PENDING DECISION; Gerard decides; none applied)

Next free number was PDD-D-34; these use PDD-D-35..44. Each program reads its choice from a config macro variable (`PDD_XLS_*`, added in task 19-01 with an **empty** default); an empty value stops the program with `PENDING DECISION: <name>`. The recommended option is what the plan implements and tests first. A non-recommended option is built only after Gerard picks it.

| ID | Choice | Options (evidence) | Recommended | Config |
|---|---|---|---|---|
| **PDD-D-35** | Build route | (a) PROC EXPORT, (b) SAS stage CSV -> openpyxl write_only, (c) ODS EXCEL; table in section 3 | (b1) | `PDD_XLS_ROUTE` |
| **PDD-D-36** | The 56 NO_DATA variables | INCLUDE (all-blank columns; matches the dataset and the dictionary 1:1; 56 of 1,297 = 4.3 % of columns, 0 cells) / DROP (workbook has 1,241 PCNR_ columns; smaller, but the column count differs from the SAS dataset and from the dictionary, so QC must exclude them) / INCLUDE with header marked in the KEY sheet list | INCLUDE (DD-02 "no recoding", columns are 1:1 with the dictionary; blank cells cost nothing in a sparse writer) | `PDD_XLS_NODATA` = INCLUDE or DROP |
| **PDD-D-37** | Column order | DICT (dataset order: 5 keys then PCNR_ alphabetical, D18-4; same as `pdd.pcnr_2018_2025` and dictionary VARIABLES) / SOURCE (source/era order: spine variables in their old order, then 2023-2025-only variables; needs a new order table, not in the repo) / DOMAIN (grouped by domain; needs a domain map that does not exist) | DICT (the only order that already exists and is checked by `p18_gate_vars`) | `PDD_XLS_ORDER` |
| **PDD-D-38** | Date/time representation | TEXT_AS_DELIVERED for character dates (no change) and, for any numeric SAS date/datetime/time (count from P19-1): EXCEL_SERIAL (real Excel date, `number_format` `yyyy-mm-dd` / `yyyy-mm-dd hh:mm:ss`; serial = SAS date + 21916 for dates, datetime seconds/86400 + 21916 for datetimes; 1900 epoch) / ISO_TEXT (`2025-03-04`) / RAW_NUMBER (SAS day count, not human readable). Excel cannot show dates before 1900-01-01 | Character dates stay text (DD-02); numeric dates EXCEL_SERIAL. If P19-1 finds 0 numeric date variables the decision reduces to the first clause | `PDD_XLS_DATES` |
| **PDD-D-39** | NUM_TEXT variables (27 seen; character columns holding numbers) | KEEP_TEXT (value as delivered; text cell; Excel shows the "number stored as text" marker; keeps `n_nonmiss_comb_all` = non-blank text count and leading zeros / non-numeric tokens like `<5`) / CONVERT (numeric cells for the parsable values; unparsable stay text in a numeric column: mixed column; changes DD-02 and the QC rule from fix_18d) | KEEP_TEXT (values as delivered; the PCNR_ layer is a no-recoding layer; conversion belongs in a derived layer) | `PDD_XLS_NUMTEXT` |
| **PDD-D-40** | Special missing codes `.A-.Z`, `._` in numeric cells | BLANK (empty cell; same as PDD-D-34 "special missing = missing"; the code is lost in the xlsx) / CODE_TEXT (cell holds the text `.A` / `._`; numeric column becomes mixed; counted separately from N) / BOTH (cell blank in DATA, plus a sheet SPECIAL_MISSING with per-variable per-code counts masked <11, no cell-level locations) | BOTH (keeps DATA columns purely numeric; code information survives at count level). If P19-5 shows 0 variables with specials this choice is moot | `PDD_XLS_SPECIAL` |
| **PDD-D-41** | DATA sheet layout | ONE (single DATA sheet, 77,498 rows x up to 1,301 columns) / ERA (DATA_K1 and DATA_K2 by `KEY_ERA`; K2 holds only 2023-2025 rows and most K1-only columns would be blank there; two sheets double the header and break "one patient row set") / DOMAIN (needs a domain map that does not exist) | ONE (fits the limits with a wide margin; era is a column; one sheet is what the requirement says) | `PDD_XLS_SHEETS` |
| **PDD-D-42** | Companion files next to the xlsx | NONE / CSV (the stage CSV kept as `PCNR_Master_Data_Nov_2026.csv`; Excel cannot reliably open a 100M-cell sheet on a normal PC, a CSV or sas7bdat is the usable form for analysis) / SAS7BDAT (copy of `pdd.pcnr_2018_2025` under `out\`) / BOTH. Each companion is full row-level data and widens the disclosure surface | NONE by default; flag to Gerard that the xlsx may be too large for some Excel installs and that the dataset itself already exists on P: | `PDD_XLS_COMPANION` |
| **PDD-D-43** | Key columns in the DATA sheet | K4: `PECAN_ID`, `PRECEDE_STUDY_ID`, `PECAN_ID_KEY_ERA`, `KEY_ERA`; `NORM_PSID` dropped (helper, join key; in NORM mode it equals `PRECEDE_STUDY_ID`, P19-6 confirms) / K5: all five / K3: `PECAN_ID`, `PRECEDE_STUDY_ID`, `KEY_ERA` (drops `PECAN_ID_KEY_ERA`, whose dictionary text says it is the key era of the ID; P19-6 shows if it ever differs from `KEY_ERA`). No encrypted MRN or encounter column is ever an option | K4 | `PDD_XLS_KEYS` |
| **PDD-D-44** | Disclosure sign-off for a row-level workbook | The DATA sheet is patient-level data (not a masked count table): small-cell masking (1-10 -> `<11`) does not apply to cells, only to every count in KEY, QC and logs. Options: PROCEED (Gerard accepts; the file stays under `out\` on P:, never in git, never in the shared Master Data folder) / HOLD until the Price naming sign-off and PDD-D-27 are answered / RESTRICT (listed output folder with a note on who may copy it) | Needs Gerard; no default. The workbook is not written by the production run until this is answered | `PDD_XLS_APPROVE` (0 or 1, default 0) |
| PDD-D-27 (existing, OPEN) | Dictionary as a sheet in the master file | No (default, brief) / Yes: a VARIABLES sheet copy of `pdd_2018_2025.xlsx` | No. A short sheet VARIABLE_LIST (name, type, era coverage flag, link text "see pdd_2018_2025.xlsx") is planned as an add-on of the KEY workbook; if Gerard answers Yes, task 19-05 copies the dictionary VARIABLES sheet instead. The plan builds either behind `PDD_XLS_DICT` (NO default) | `PDD_XLS_DICT` |

Also open and not a Phase 19 gate: the Price naming sign-off (stated on the KEY sheet as pending, like the dictionary) and the DSS question on the 116 `#Error` deaths (a dictionary note, carried into the KEY sheet note list).

## 5. Time and size estimate (UNMEASURED; replaced by P19-7 measured values after the first run)

| Run | Est. wall time | Basis |
|---|---|---|
| 19_xlsx_test (synthetic, WORK only) | under 2 min | SAS + small tables |
| 19a preflight (read-only counts, probes P19-1..P19-8, expected counts) | 5-20 min | 1,297 variable full scan of 77,498 rows; one pass per variable batch |
| 19b stage export (CSV + schema + expected counts) | 10-40 min | DATA step PUT of about 100M cells to a local-share file; network share is the main risk |
| 19c Python write | 20-90 min | openpyxl write_only at about 0.1-0.5 M cells/s plus CSV parse; the benchmark gives the real number. Sparse cells are skipped |
| 19d Python verify (streaming read-back, header scan, MRN scan) | 30-120 min | read_only reading is as slow as writing; one pass does counts, types, MRN scan |
| Total for the first full run | about 1.5-4.5 hours | spread over three sessions |

Disk: stage CSV 1-3 GB, xlsx 0.5-2 GB (sparse, compressed), openpyxl temp part files in the Python temp directory about the size of the uncompressed XML (3-10 GB). The preflight stops if free space is under 15 GB on either drive (adjustable `PDD_XLS_MIN_FREE_GB`, default 15). Memory: Python constant (streaming); SAS well under 2 GB.

## 6. Workbook layout (XLS-01)

1. **KEY** (sheet 1, leftmost, Gerard's standing rule; UF header styling `#0021A5` header fill, `#FA4616` accents): source (`pdd.pcnr_2018_2025`, built 18b, PCNR_ 2018-2025), build date, row count, column count in DATA, K1/K2 row counts, distinct PECAN_ID per era, shared surgeries (142, from the 18c KEY facts), dup pairs (1,895), ID definitions (rows of `docs/pecan_id_dictionary_text.csv`), missing-value convention (blank = missing; NULL in text read as missing, D-02b; special missings per PDD-D-40; `#Error` kept verbatim in `Death_Days_After_Surgery`), era notes (frailty components coded 0/1 in 2023-2025, Y/N/YES/NO before; Sleep_Apnea_YN pre-2023 Y or blank; YEAR text with `2018_2019`), NUM_TEXT note, the K2 `PRECEDE_STUDY_ID` rule (PDD-D-33), the "values as delivered, no recoding" statement, the statement that no encrypted MRN, encounter id or `NORM_PSID` helper is in the file, the Price naming sign-off as pending, link to `out\pdd_2018_2025.xlsx` for definitions, and the verification result line written by 19d (counts only, masked <11). The KEY sheet carries stage-time facts only (a write_only workbook cannot be reopened); verification results live in `qc/xlsx_master_verify.csv`, `exchange/xlsx_master_verify_summary.csv` and the run log, not in the xlsx.
2. **DATA**: frozen header row and first key column, one row per surgery, columns per PDD-D-37/43, header = SAS variable names exactly (no renaming), autofilter off (100M cells), no per-cell styling.
3. **VARIABLE_LIST** (optional per PDD-D-27, only if answered): variable name, SAS type, decided combined type, DATA column index, link text. No distributions (those stay in `pdd_2018_2025.xlsx`; any percentage would come from the scrubbed exchange profile).
4. **SPECIAL_MISSING** (only if PDD-D-40 = BOTH): variable, code, count masked <11.

## 7. Disclosure and content review (XLS section 3 of the brief)

- **In:** per PDD-D-43 (recommended K4). **Never in:** `ENCRYPTED_MRN`, any MRN or encounter column, `NORM_PSID` (helper). `pdd.pcnr_2018_2025` holds only the 5 key columns and PCNR_ variables (D18-4, gate in 18b), so the source has none of these; the writer additionally rejects any column not in the allow list (`PECAN_ID`, `PRECEDE_STUDY_ID`, `PECAN_ID_KEY_ERA`, `KEY_ERA`, plus the PCNR_ names of `pdd.name_map_vars_ext`).
- **Stage and temp files** contain the same row-level data: they live under `out_root\stage\` only, are deleted by 19d after PASS (unless PDD-D-42 keeps the CSV), and are never read by `p18_scan_no_mrn`-style scans of logs.
- **Verification scan of the finished xlsx (like 18d, applied to the file):**
  1. Header scan: DATA header row equals the expected column list exactly; no name containing `MRN`, `NORM_PSID`, `ENCRYPT`, `ENCOUNTER`.
  2. MRN scan: 19d streams every text cell of DATA and KEY, and every sheet name and defined name, and counts cells whose tokens equal a registry `ENCRYPTED_MRN`. The registry is read **in memory** with `pandas.read_sas` from the read-only registry file (no MRN list written to disk, no hash file); the hit count is the only output. Hit count must be 0 (any other value fails).
  3. The same scan runs on the 19a/19b/19c/19d logs and `qc\` CSVs (reuse `18d` pattern, closed files only).
  4. Raw numeric tokens are not scanned (an encrypted MRN is text by construction); the xlsx is also scanned for the 32-character-or-longer hex-like tokens only if the registry shows MRNs of that shape (checked by 19a without printing values).
- **Row-level data note:** the DATA sheet is not "masked counts only". Small-cell masking applies to KEY, SPECIAL_MISSING, QC CSVs and logs; PDD-D-44 asks Gerard to sign off on the row-level file.

## 8. QC gates (XLS-02, XLS-03), all fail-loud

Pre-write (19a, 19c start): rows < 1,048,575; columns < 16,384 (also write-time `ws.max_column` check); max trimmed character length <= 32,767; no cell with an Excel-illegal control character (else stop, PENDING DECISION: strip or abort, never silent change); free disk; column set equals `pdd.pcnr_2018_2025` columns minus dropped ones; `PDD_XLS_APPROVE` = 1.

Post-write (19d), against the exact expected counts that 19b computes in SAS from `pdd.pcnr_2018_2025` and the 18c reference `exchange\comb_recon.csv`:
1. Row count: DATA rows - 1 = SAS rows (77,498 echo only; compared to the dataset count at run time, not a constant).
2. Column names in order = expected list (PDD-D-37/43); column count = dataset columns minus dropped.
3. Per-variable non-blank count in DATA = `n_nonmiss_comb_all` from the stage's exact counts and equals comb_recon `n_nonmiss_comb_all` when comb_recon is exact; where comb_recon is masked `<11` the exact count must be in 1..10. Rules: numeric non-missing = `not missing(x)` (specials excluded, PDD-D-34); with PDD-D-40 = CODE_TEXT the non-blank count = non-missing + special; NUM_TEXT variables compare non-blank text cells to `n_nonmiss_comb_all` (= N + N_UNPARSED, fix_18d); NO_DATA variables must be 0 (or absent under DROP).
4. Type check on a fixed sample (seeded; 2,000 rows chosen in 19b and listed by row number in the stage, not by value): numeric columns hold numeric cells (`data_type` n) and char columns hold string cells (`s`); no cell converted to a formula (`f`) or error (`e`); sample values equal the stage values (numbers exactly via `repr` round trip, strings exactly).
5. Date round trip (only if numeric date variables exist): sample values read back from the xlsx convert to the SAS date within 0 days (datetimes within 1 s).
6. KEY facts: the KEY sheet rows ROWS, COLUMNS, K1_ROWS, K2_ROWS, DISTINCT_PECAN_ID_K1/K2, SHARED_SURGERIES, DUP_PAIRS equal the DATA counts and the 18c `comb_key_facts.csv`.
7. Disclosure scan (section 7) hit count 0.
8. File exists only under `out\`; the shared Master Data folder is untouched (path guard in every program).

Outputs: `qc\xlsx_master_pre.csv`, `qc\xlsx_master_stage.csv`, `qc\xlsx_master_verify.csv` (item, n, fail; counts masked <11 in anything copied to `exchange\`), `exchange\xlsx_master_verify_summary.csv` (masked), logs under `logs\`.

## 9. Safety rules (apply to every program)

- Output only under `&out_root` (`out\`, `qc\`, `logs\`, `exchange\`, `stage\`, `backup\`). A path guard stops if any target path does not start with `&out_root` or contains `Master Data\00 Shared Data`.
- **No-overwrite:** if `out\PCNR_Master_Data_Nov_2026.xlsx` exists, the writer renames it to `backup\PCNR_Master_Data_Nov_2026_<YYYYMMDD_HHMMSS>.xlsx` first (copy then verify size, then write the new file to a `.tmp` name and rename on success). The partial `.tmp` is deleted on failure. SAS member name rule (32 bytes, lint C33) applies to any SAS backup stem; the xlsx backup is a file, not a member.
- Synthetic test first (`19_xlsx_test.sas` for SAS side; pytest for Python side); each SAS program in a **fresh SAS session**; production programs set `%let p19_fail_mode = ABORT;` right after the config include and never inherit FLAG; QC rows staged in WORK and written once (P: lock pitfall); no `pdd` write per row. 19a, 19b write only to `qc\`, `exchange\`, `stage\`; none writes `pdd`.
- Fail-loud: any limit breach, any unexpected column, count mismatch, hit > 0, missing config choice -> nonzero exit, no partial file left at the final name.
- No data in git; counts 1-10 as `<11` in everything committed or copied to `exchange\`. Percentages only from the scrubbed profile.
- Never reads P:\ and never runs SAS in the headless planning/implementation run: all SAS/real-data steps are PENDING SAS RUN.

## Assumptions (headless run)

- A1 The recommendation (b1) is a recommendation only; PDD-D-35 stays PENDING DECISION and the plan still builds the shared pieces (macros, test, 19a) that every route needs.
- A2 PDD-D-36..44 are written as new numbered decisions (next free was 34, DECISIONS.md header says 34; PDD-D-33/34 are in the table, so 35 is next). They are rows in `docs/DECISIONS.md` marked PENDING DECISION, not decided.
- A3 Time and size numbers are estimates with stated basis; none is a measurement. P19-7 replaces them.
- A4 `NORM_PSID` is treated as a helper column to drop (user brief names "norm_psid helper columns"); the dataset does contain it as column 5.
- A5 Whether `PECAN_ID_KEY_ERA` and `KEY_ERA` ever differ is not in any probe (both `$2`); P19-6 reports it and PDD-D-43 options are given without assuming.
- A6 Whether SAS/ACCESS to PC Files is licensed on the SAS machine is not known; this only matters for route (a), which is not recommended.
- A7 openpyxl behaviors (string starting `=` becomes a formula; strings equal to Excel error codes become error cells; illegal control characters raise) are properties of `openpyxl==3.1.5` taken from its documented behavior and are to be proven by the synthetic pytest (T-XL-3/4/5) before the real run, not assumed.
- A8 Whether the SAS `MISSING=` option affects special missing in `PUT` output is not verified; the stage writer prints numerics through an explicit conditional (a missing test that prints the special code letter, otherwise `put(x, best32.)`), and test T3 proves it.
- A9 The SPECIAL_MISSING sheet is not required by XLS-01; it exists only if PDD-D-40 = BOTH.
- A10 The Python verifier reads the registry from its sas7bdat with `pandas.read_sas` (pandas is pinned). If the registry library path or encoding cannot be read, the verifier stops (PENDING SAS RUN: SAS-side export of a hashed token list as the fallback, to be approved first).
- A11 No subagent was used; plan checker run not performed in this planning run (budget); the plan lists its own verification matrix (19-PLAN.md section "Requirement coverage").

## fix_19a addendum (2026-11-18)
- Allow-list name heuristic false positive: `PCNR_Age_at_Encounter` (MAPPED age variable) matched ENCOUNTER. Handled by `docs/xlsx_name_exceptions.csv` (reviewed Gerard, 2026-11-18); KEY and UNLISTED columns can never be excepted.
- **PENDING DECISION (new, not applied): age top-coding.** Ages >= 90 are a HIPAA identifier category; PDD-D-35..44 do not cover it. Before the master workbook is released, decide whether `PCNR_Age_at_Encounter` and other age variables (`docs/age_variables.csv`) are top-coded at 90 (e.g. "90+"), left as is, or dropped. Options and probe evidence (count of age values >= 90, masked <11) to be requested from a SAS probe; no choice applied here.
