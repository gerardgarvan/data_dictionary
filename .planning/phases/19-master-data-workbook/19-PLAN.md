# Phase 19 PLAN: PCNR_Master_Data_Nov_2026.xlsx

**Planned:** 2026-11-18, headless, planning only (no SAS, no Python implementation, no P:).
**Goal:** write `P:\PeCAN Master Data\Gerard\data_dictionary\out\PCNR_Master_Data_Nov_2026.xlsx` from `pdd.pcnr_2018_2025` and prove it round-trips (XLS-01..XLS-04).
**Context and decisions:** `19-CONTEXT.md` (route comparison, PDD-D-35..44 options, probes P19-1..8, layout, disclosure, QC gates, safety, assumptions). Read it first.
**Status:** decisions DECIDED 2026-11-18 (see "Decisions resolved"), Wave 2 unblocked; PENDING SAS RUN for probes P19-1..8. Waves 1-2 below do not depend on a decision.

## Recommended route (not decided)
(b1): SAS writes a typed stage CSV plus a schema CSV under `out_root\stage\`; Python `openpyxl` write_only builds the workbook (KEY first, then DATA); a separate Python verifier re-reads it. See `19-CONTEXT.md` section 3.

## Decisions resolved (2026-11-18, task 19-01b done)

Gerard decided PDD-D-35..44 and PDD-D-27 on 2026-11-18 using the 19a probe results (`docs/DECISIONS.md`). Audience: PeCAN team only, under the current IRB protocol. Values: ROUTE=STAGE_CSV, NODATA=INCLUDE, ORDER=DICT, DATES=SERIAL (probe: no numeric date format; char dates stay text), NUMTEXT=TEXT with one override (`PCNR_Death_Days_After_Surgery` numeric; `#` and other non-numeric text blank; 34,057 `#` cells in the probe; blanked count is a masked QC item), SPECIAL=BLANK (probe: 0 special missings), SHEETS=ONE, COMPANION=NONE, KEYS=K3 (PECAN_ID, PRECEDE_STUDY_ID, KEY_ERA; PECAN_ID_KEY_ERA and norm_psid are identical copies per probe), DICT=NO (KEY sheet points to `out\pdd_2018_2025.xlsx`). PDD-D-44: `PDD_XLS_APPROVE` stays empty in config and is set by Gerard at run time only. Lat/long, free-text notes, staff names and ages are kept unaltered; the KEY sheet states the workbook contains identifiable fields for approved PeCAN team use only.

Code for these: defaults in `sas/00_config.sas`; `%p19_keyset` (SAS, K3/K4); `python/pdd/master_rules.py` (K3, Death_Days override, KEY notice, masking, approval gate) with `python/tests/test_master_rules.py`; stage contract `docs/xlsx_stage_contract.md` (override applied in the Python writer, SAS stage writes Death_Days as delivered text).

**Wave 2 is unblocked** (19-04, 19-05 writer, 19-07). Wave 2 still needs the PENDING SAS RUN results of Wave 1 (19_xlsx_test, 19a) to be brought back and PASS.

**Backlog (from the 19a probe review):** (1) the INT_IN_DATE_RANGE probe range was too broad to be informative; narrow it if a date check is still wanted. (2) The export masks flags and timings of 1-10 to `<11`; change it to mask only person/cell counts.

## Decision gates (config variables, empty default, each program stops with `PENDING DECISION: <name>` when empty)

| Decision | Config | Recommended |
|---|---|---|
| PDD-D-35 route | `PDD_XLS_ROUTE` | `STAGE_CSV` (b1) |
| PDD-D-36 NO_DATA | `PDD_XLS_NODATA` | `INCLUDE` |
| PDD-D-37 order | `PDD_XLS_ORDER` | `DICT` |
| PDD-D-38 dates | `PDD_XLS_DATES` | `SERIAL` (numeric dates only; char dates stay text) |
| PDD-D-39 NUM_TEXT | `PDD_XLS_NUMTEXT` | `TEXT` |
| PDD-D-40 special missing | `PDD_XLS_SPECIAL` | `BLANK` (decided) |
| PDD-D-41 sheets | `PDD_XLS_SHEETS` | `ONE` |
| PDD-D-42 companion | `PDD_XLS_COMPANION` | `NONE` |
| PDD-D-43 key columns | `PDD_XLS_KEYS` | `K3` (decided) |
| PDD-D-44 disclosure sign-off | `PDD_XLS_APPROVE` | none (must be set to 1 by Gerard) |
| PDD-D-27 dictionary sheet | `PDD_XLS_DICT` | `NO` |

Programs implement the recommended value and any value that is cheap (parameter switch). A value that needs new code (route (a)/(c), `ERA`/`DOMAIN` sheets, `CONVERT`, `SOURCE` order) stops with `PENDING DECISION: not implemented, revise plan 19`. Gerard's choice is written to `docs/DECISIONS.md` and `sas/00_config.sas` in task 19-01b after the decision, never by a headless run.

## Tasks

Naming: SAS programs `19a`, `19b`; macros `sas/19_xlsx_macros.sas` (prefix `%p19_`); test `sas/19_xlsx_test.sas`; Python `python/pdd/master_workbook.py` with scripts `python/scripts/write_master_workbook.py` and `python/scripts/verify_master_workbook.py`. All follow `CLAUDE.md` rules (both linters zero errors on every SAS file; `ruff check python\` and `pytest python\tests` zero errors; all SAS pitfalls: `%unquote` for `cond=`/`where=`, `%global` for cross-macro variables, `stop;` after `POINT=`, no `??` in PROC SQL, `GROUP BY` only with a summary function, no `case` as a column name, backup stems at most 16 chars, WORK-staged QC written once, test logs with no WARNING or ERROR lines, column-1 anchored log scans).

### Wave 1 (no decision needed, no SAS run)

**19-01a Config, schema, probe request.** Add to `sas/00_config.sas` (after the Phase 18 block): `xls_final = PCNR_Master_Data_Nov_2026.xlsx`, `xls_stage_path = &out_root.\stage`, `xls_bak_path = &backup_path`, `PDD_XLS_MIN_FREE_GB = 15`, and the empty-default `PDD_XLS_*` variables of the decision table (env override pattern as `PDD_K2_PSID_MODE`; empty is valid, meaning PENDING). Add rows for the new CSVs to `docs/exchange_schema.csv` (`xlsx_master_verify_summary.csv`: item, n, fail, all str, counts masked). Static test `python/tests/test_phase19_seed_static.py`: no `PDD_XLS_*` has a non-empty default except `MIN_FREE_GB`; `xls_stage_path` and the final path start with `&out_root`.
Verify: `pytest python\tests`, `sas_lint`, `sasjs lint` on `00_config.sas`.

**19-01b (after Gerard decides, small).** Record decisions in `docs/DECISIONS.md` (rows PDD-D-35..44 become DECIDED with date), set the defaults in `00_config.sas`. Until then the rows stay PENDING DECISION (added as such by this planning run). Depends on: Gerard.

**19-02 SAS macros and synthetic test.** `sas/19_xlsx_macros.sas`:
- `%p19_init`, `%p19_fail`, `%p19_qinit/%p19_qadd/%p19_flush_qc` (WORK staged, written once; pattern of `p18_*`), `%p19_path_guard(path=)` (stop unless path starts with `&out_root` and does not contain `Master Data\00 Shared Data`), `%p19_need_decision(var=, allowed=)` (empty value -> `PENDING DECISION`, invalid value -> stop; uses `%superq` and `%unquote` per pitfalls).
- `%p19_columns(in=, out=)`: expected DATA column list from `dictionary.columns` of `pdd.pcnr_2018_2025` applying PDD-D-36/37/43 (drops `NORM_PSID` under K4/K3, NO_DATA columns under DROP), allow-list gate (`PECAN_ID`, `PRECEDE_STUDY_ID`, `PECAN_ID_KEY_ERA`, `KEY_ERA` or the variables of `pdd.name_map_vars_ext`; anything else including `MRN`/`ENCOUNTER`/`NORM_PSID` where excluded stops).
- `%p19_probe(...)`: P19-1..P19-6 as counts only (no values): numeric date-format variables, max length, control-character cells, leading `=`/`#`/`+`/`-`/`@` cells per variable, cells over 255 chars, numeric precision >15 digits, special-missing codes per variable, KEY_ERA x PECAN_ID_KEY_ERA crosstab, NORM_PSID vs PRECEDE_STUDY_ID difference count. Output through `%p18_mask`.
- `%p19_limits(...)`: XLS-02 gate: `rows + 1 < 1048575`, `cols < 16384`, max trimmed char length `<= 32767`, control-character count 0, free-disk gate.
- `%p19_stage(ds=, cols=, out=, schema=)`: stage writer. DATA step `_null_` with `FILE ... encoding='utf-8' lrecl=32767 dsd`; numerics via `best32.` with missing as empty; special missing printed per PDD-D-40 (BLANK: empty; CODE_TEXT: `.A`; BOTH: empty plus count); dates per PDD-D-38; character values `strip`ped only of trailing blanks (SAS padding), never recoded. Schema CSV: `col_index, name, sas_type, excel_kind` (N, C, DATE, DATETIME, TIME), no values.
- `%p19_expected(ds=, cols=, out=)`: exact per-variable non-missing, special and distinct-not-required counts and the row count, written to `stage\xlsx_expected.csv` (not `exchange\`; exact counts stay on P:), a 2,000-row seeded sample row-number list, and the sample's stage values read back by Python from the stage CSV itself.
- `%p19_scan_closed(...)`: closed-file scan for registry MRN tokens (reuse `%p18_scan_no_mrn`).
Test `sas/19_xlsx_test.sas` (WORK only, repoints `pdd`/backup at WORK and restores, never run beside production): T1 path guard rejects shared-folder and non-out_root paths; T2 decision gate stops on empty and invalid values; T3 stage of a 6-row synthetic table incl. `.A`, `._`, ordinary missing, a leading-zero text, `=SUM(1)`, `#N/A`, a 40,000-char-limit boundary row at 32,767, embedded comma/quote/newline, a SAS date and datetime; the CSV text is read back and compared for all three PDD-D-40 values; T4 limits gate trips on a synthetic over-limit count (rows, cols, text); T5 control-character gate; T6 column list drops `NORM_PSID`/NO_DATA per setting and rejects an extra `ENCRYPTED_MRN` column; T7 expected counts for NUM_TEXT and special-missing columns equal hand-computed values (`not missing`); T8 MRN scan hits = 0 on clean and = 1 on a planted synthetic token; T9 log has no WARNING or ERROR (anchored `=:`). `_chk` preset FAIL, `num=1` for decimals.
Lint: C13 (macro defined before use), C31, C33, C34, C37, C38.
Verify: both linters zero errors (no SAS run here). **PENDING SAS RUN: `19_xlsx_test.sas`, expect `ALL TESTS PASSED`.**

**19-03 Preflight program `sas/19a_xlsx_preflight.sas`** (read-only, fresh session; `%let p19_fail_mode = ABORT;` right after config). Steps: path guard; require `pdd.pcnr_2018_2025`, `pdd.name_map_vars_coverage`; probes P19-1..P19-6 (counts; mask 1-10 as `<11`); limits gate (XLS-02) **against the real dataset**; free-disk check; ro-start/end counts of registry, dup link, case map (fail if changed); records which decisions are still empty and prints `PENDING DECISION` lines (does not stop for a probe-only run: `PDD_XLS_PROBE_ONLY=1` default for 19a, since its job is to supply the facts the decisions need). Outputs: `qc\xlsx_master_pre.csv` (item, n, fail), `qc\xlsx_master_probe.csv` (variable, check, n; masked), `exchange\xlsx_master_probe_summary.csv` (masked, safe to bring back), log. **PENDING SAS RUN: 19a. Bring back: log, the three CSVs.** Time 5-20 min (estimate).
Depends on: 19-02 (macros) and 19-01a.

**19-05 Python writer `python/pdd/master_workbook.py` + `python/scripts/write_master_workbook.py`.** Behavior: reads `stage\xlsx_schema.csv` and `stage\xlsx_data.csv` (streaming `csv.reader`, never `pandas.read_csv` of the whole file); gate checks (rows/cols/char limit, exact column list vs schema, allow list, `PDD_XLS_APPROVE=1`, free disk); no-overwrite rule (existing final file moved to `backup\..._<stamp>.xlsx` first; write to `<final>.tmp`, rename on success, delete tmp on failure); `Workbook(write_only=True)`; sheets created in this order: **KEY** (UF header `#0021A5`/`#FA4616` via `xlsx_style.py`, facts from `exchange\comb_key_facts.csv`, ID text from `docs/pecan_id_dictionary_text.csv`, missing-value convention, era notes from `docs/combined_type_decisions.csv`, K2 PSID rule, no-MRN statement, Price sign-off pending, dictionary link), **DATA**, then optional VARIABLE_LIST (PDD-D-27) and SPECIAL_MISSING (PDD-D-40 = BOTH); cell typing per schema: N -> `int` if integral and `abs < 1e15` else `float` (`repr`), C -> `str` forced to `data_type='s'` via `WriteOnlyCell` for any string starting `=` or `#` (and any string openpyxl would map to a formula or error code), DATE/DATETIME -> serial float with `number_format`; blanks are `None` (cell not written); `IllegalCharacterError` is caught and stops the run with the column name and count (no value, no silent strip); `--bench-rows N` writes a throwaway file under `stage\` and prints rows/s and the extrapolated time (P19-7); logs counts only.
Tests `python/tests/test_master_workbook.py` (synthetic CSV, tmp_path): KEY leftmost; DATA header order; `=SUM(1)` and `#N/A` read back as strings of data_type `s`; leading zeros preserved; embedded newline/comma/quote; boundary 32,767 chars ok and 32,768 stops; control char stops; row and column limit gates via lowered limits; unexpected column (`ENCRYPTED_MRN`, `NORM_PSID` under K4) stops; existing final file is moved to `backup` and the new file is complete; failure leaves no file at the final name; numeric integral stored as int; date serial value and `number_format`; special-missing BLANK/CODE_TEXT/BOTH; NO_DATA INCLUDE/DROP; sheet order. Ruff clean.
Verify: `ruff check python\`, `pytest python\tests`. Depends on: 19-02 (stage format contract; define the contract in `docs/` or the module docstring first so both sides agree) and the decision config names.

**19-06 Python verifier `python/pdd/master_verify.py` + `python/scripts/verify_master_workbook.py`** (XLS-03). One streaming pass over the xlsx (`openpyxl` `read_only=True`): sheet order (KEY first), header row equals expected list, row count, per-column non-blank counts, per-cell type tally on the sample rows, sample value equality with the stage, date round trip, KEY fact equality, disclosure scan (header names; every text cell token against registry `ENCRYPTED_MRN` read **in memory** with `pandas.read_sas`; hit count only); compares counts to `stage\xlsx_expected.csv` (exact) and to `exchange\comb_recon.csv` (masked <11 tolerant; NUM_TEXT = N + N_UNPARSED; NO_DATA = 0; special per PDD-D-40). Outputs `qc\xlsx_master_verify.csv`, `exchange\xlsx_master_verify_summary.csv` (masked), log; exit 0 only if every item passes; on PASS deletes the stage files unless PDD-D-42 keeps the CSV.
Tests `python/tests/test_master_verify.py`: pass case; each failure injected (extra row, missing column, swapped column order, wrong non-blank count, formula cell, planted synthetic MRN token, KEY fact mismatch) is detected; masked-count tolerance; NUM_TEXT and special-missing rules; no value ever printed in logs (assert on captured output).

### Wave 2 (after PENDING SAS RUN results and Gerard's decisions)

**19-04 Stage export `sas/19b_xlsx_stage.sas`** (production, fresh session, ABORT mode, `%p19_need_decision` for every config choice and `PDD_XLS_APPROVE`). Path guard, limits gate, `%p19_columns`, `%p19_stage` -> `stage\xlsx_data.csv`, `stage\xlsx_schema.csv`, `%p19_expected` -> `stage\xlsx_expected.csv`, row-count equality of CSV lines vs dataset rows (anchored read of the closed CSV), registry/dup/case-map unchanged gate, QC `qc\xlsx_master_stage.csv`. **PENDING SAS RUN: 19b.** Time 10-40 min (estimate). Depends on: 19-02, 19-03 results, 19-01b.

**19-07 Wiring and run sheet.** `run_pipeline.cmd 19` (19a is standalone and run first alone; then `19b`, `write_master_workbook.py`, `verify_master_workbook.py`, each via `:run_program` / `:run_python`, ERROR/WARNING log checks), token 19 in `99_run_all.sas` (19a and 19b only; Python steps in the cmd as for Phase 18), `19-SAS-RUN.md`, `19-VALIDATION.md`, static tests (`test_phase19_wiring_static.py`). Updates `STATE.md`, `ROADMAP.md` plans list.

**19-08 Checkpoint.** Gerard runs the SAS run sheet; summary and close-out (`19-SUMMARY.md`); decide stage retention and file copy location; backlog item for XlsxWriter if the benchmark misses the time budget.

## Dependency waves

| Wave | Tasks | Needs |
|---|---|---|
| 1 | 19-01a, 19-02, 19-03, 19-05, 19-06 (code and tests only; 19-05/19-06 need the stage contract from 19-02 and the config names from 19-01a) | nothing external |
| SAS run 1 | `19_xlsx_test`, then `19a` | Gerard; answers P19-1..8; gives measured sizes and speeds |
| Decision | PDD-D-35..44, PDD-D-27 | Gerard, using the probe summary |
| 2 | 19-01b, 19-04, 19-07 | decisions and SAS run 1 |
| SAS/Python run 2 | `19b`, writer, verifier | Gerard |
| 3 | 19-08 close | run 2 PASS |

## SAS run sheet outline (details go to `19-SAS-RUN.md`, template as `18-SAS-RUN.md`)

Fresh SAS session per program; close table viewers on `pdd` first; do not close SAS before the PASS line; `.venv\Scripts\python.exe -m pip install -r python\requirements.txt` first.

| Step | Program | Expect | Bring back | Est. time (unmeasured) |
|---|---|---|---|---|
| 1 | `19_xlsx_test.sas` | `ALL TESTS PASSED`, no WARNING/ERROR line | log | < 2 min |
| 2 | `19a_xlsx_preflight.sas` | `PASS - preflight complete`, limits gate PASS | log, `qc\xlsx_master_pre.csv`, `qc\xlsx_master_probe.csv`, `exchange\xlsx_master_probe_summary.csv` | 5-20 min |
| 3 | `.venv\Scripts\python.exe python\scripts\write_master_workbook.py --bench-rows 1000` | rows/s and extrapolated minutes printed | console line | < 1 min |
| - | **Gerard decides PDD-D-35..44** (and PDD-D-27) from steps 2-3 | rows DECIDED in `docs/DECISIONS.md` | - | - |
| 4 | `19b_xlsx_stage.sas` | `PASS - stage written`, row count equal | log, `qc\xlsx_master_stage.csv` | 10-40 min |
| 5 | `write_master_workbook.py` | exit 0, final file under `out\` | console line, `logs\write_master_workbook.log` | 20-90 min |
| 6 | `verify_master_workbook.py` | exit 0, hit count 0, every gate PASS | console, `qc\xlsx_master_verify.csv`, `exchange\xlsx_master_verify_summary.csv`, log | 30-120 min |
| 7 | rerun steps 4-6 | backup of the first workbook taken, same counts | logs | repeat of 4-6 |

First full run about 1.5-4.5 h; the benchmark and 19a replace this range with measured values before steps 4-6.

## Requirement coverage

| Req | Covered by |
|---|---|
| XLS-01 KEY leftmost + DATA in `out\` | 19-05 (sheet order, KEY content), 19-06 (sheet order check), tests |
| XLS-02 pre-export limits | `%p19_limits` in 19a and 19b; 19-05 write-time checks; test T4/T5 and pytest limit tests |
| XLS-03 round trip to `qc\` | 19-06 verifier, gates in `19-CONTEXT.md` section 8 |
| XLS-04 dictionary sheet (PDD-D-27) | `PDD_XLS_DICT` gate; default NO; VARIABLE_LIST optional |
| Handoff: percentages scrubbed | no percentages in KEY or DATA; if any are added they come from `profile_PCNR_2018_2025.csv` (writer asserts source) |
| Disclosure | allow list, header scan, in-memory MRN scan, closed-log scan |

## PENDING lists

- **(resolved 2026-11-18, kept for history) PDD-D-35, 36, 37, 38, 39, 40, 41, 42, 43, 44 and the existing PDD-D-27 (options, evidence and recommendations in `19-CONTEXT.md` section 4; none applied). Price naming sign-off (carried).
- **PENDING SAS RUN:** `19_xlsx_test.sas`, `19a_xlsx_preflight.sas` (probes P19-1..8), then after decisions `19b`, writer, verifier.

## Assumptions (headless run)

See `19-CONTEXT.md` section "Assumptions (headless run)" A1-A11. Added here: the task split 19-01a/19-01b separates what can be built now from what waits for Gerard; no program writes to `pdd`; Phase 19 adds no change to Phase 18 outputs; `docs/DECISIONS.md` rows PDD-D-35..44 were added as PENDING DECISION only.
