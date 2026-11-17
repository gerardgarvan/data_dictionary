# PeCAN Data Dictionary — Claude Code Rules

## After any SAS edit

Run both linters before committing:

```
python tools\sas_lint.py sas\<file>.sas
sasjs lint
```

Both must show zero errors on the edited file.

## Python setup

The pipeline interpreter is `.venv\Scripts\python.exe` (default `PDD_PYTHON` in `run_pipeline.cmd`).
Install dependencies into it before running:

```
.venv\Scripts\python.exe -m pip install -r python\requirements.txt
```

## After any Python edit

Run both quality gates before committing:

```
ruff check python\
pytest python\tests
```

Both must show zero errors / all tests pass.

## PCM compliance (enforced by sas_lint.py)

- No open-code `%if`/`%else` outside `%macro … %mend` (C3)
- No macro keyword in a quoted PUT string (C11)
- No macro called before its `%macro` definition in the same file (C13)
- No bare `data ;` / `set ;` with no dataset name (C14)
- `LIBNAME libref <engine> "path"` — engine before path (C9)
- No `??` inside PROC SQL (C1)
- No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH…AS) (C2)

## Data locations

- Repo: `C:\data_dictionary`
- Output/library: `P:\PeCAN Master Data\Gerard\data_dictionary\`
- Source files (read-only): `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`

## Probe-first rule (inputs on P:)

This machine has no P: drive and no SAS. All facts about source files come from the
privacy-safe probe files in `.planning/schemas/` (written by `sas/probe_inputs.sas` on the
SAS machine). Before writing or planning any code that touches a source file or dataset:

1. Read the most recent `.planning/schemas/probe_*.md` that covers it.
2. Use only file names, sheet names, headers, SAS names, types, lengths, ID shapes,
   encodings and counts that appear there. Never guess a column name, file name,
   row count, ID format or encoding.
3. If a needed fact is missing, stop that plan and write a PROBE REQUEST in the plan
   (what to probe and which parameter of `probe_inputs.sas` to set, e.g. `file_regex`,
   `spine_path`). Mark it `PENDING SAS RUN` in STATE.md.

Probe files never contain data values; do not add any. Counts 1–10 stay `<11`.

## Headless runs (pdd_sdk_run.py, API credits)

- No questions: take the documented default, and record every assumption in the
  phase CONTEXT/SUMMARY under "Assumptions (headless run)".
- Never try to reach P:\, run SAS, or read real data. SAS runs are done by Gerard.
- At a step that needs a SAS run: write the exact program(s) to run, the log and
  `qc\` files to bring back, mark the plan `PENDING SAS RUN`, and move on to
  plans that don't depend on it.
- At a decision gate (PDD-D-xx, Price sign-off, near-match names): write the options
  with evidence from the probes, mark `PENDING DECISION`, and do not apply a choice.
  Locked decisions PDD-D-01..23 are not reopened.
- Never write to the shared Master Data folder. Data, QC and logs go only to
  `P:\PeCAN Master Data\Gerard\data_dictionary` through paths in `sas\00_config.sas`.
  No data in git.
- Workbooks: KEY sheet leftmost; UF colors (#0021A5, #FA4616) for header styling.
- Commit to the current branch with clear messages. Never push, switch branches,
  or rewrite history.

## SAS pitfalls already hit in this project (check every new program)

- No `%if` in open code outside a macro; quote or `%superq` text in `%if` comparisons.
- `??` input modifier only in DATA steps, never in PROC SQL.
- No commas inside macro-call arguments (pass via a global macro variable).
- No `RETAIN` with length specs; set lengths in a LENGTH statement.
- `LIBNAME libref engine "path";` (engine before path).
- Declare `array _character_` / `_numeric_` after `SET`; helper variables after the array.
- `strip()` before regex anchors `^`/`$` on padded variables.
- Generated code: `catx(' ', ...)`, not `cats()`, where spaces matter.
- `encoding='wlatin1'` for files the probe marks wlatin1 (PDD-D-23).
- 5-digit case IDs normalize to `Precede#####` exact case (PDD-D-19).
- A DATA step that runs `SET ... POINT=` (directly or through `%p16_shorten` / `%p16_assign_names`) and has no other `SET`/`MERGE`/`INFILE`/`INPUT` reaching end of file must contain `stop;`, or it loops forever and fills WORK (C31).
- Never name a column `case` (or `when`, `then`, `else`, `as`, `on`) if PROC SQL will reference it: PROC SQL reserved word, error 22-322. Use e.g. `tcase`. `CASE WHEN` expressions are fine (C32).
- SAS member names (datasets, backups) are max 32 bytes including any `_YYYYMMDD_HHMMSS` timestamp (16 chars): a longer name is ERROR 307-185 and the table is never written. Backup stems stay at most 16 chars (`pidreg`, `piddup`, `pidmap`, `pidreg_prelink`). Static test and lint C33 check this.
- A macro parameter passed as `cond=%str(...)` and used in `%if` needs `%unquote`: write `%if %unquote(&cond)`. Plain `%if &cond` raises a character-operand ERROR and the check never records PASS or FAIL. Test harness `_chk` presets FAIL so an unevaluable check fails (lint C34).
- PROC SQL `GROUP BY` with no summary function (count, sum, min, ...) and no HAVING warns "GROUP BY clause has been transformed into an ORDER BY clause". Use `select distinct ... order by` (lint C35).
- Production 17 programs (17a, 17b, 17c, pecan_id_link) set `%let p17_fail_mode = ABORT;` right after including 00_config and never inherit FLAG from a test run. Gates (`p17_gate_registry`, `p17_gate_casemap`) fail on a missing table. Run each production program in a fresh SAS session.
- Network share locks: on the P: share a write to a pdd table can fail with `ERROR: A lock is not available for PDD.<table>.DATA` when the previous write has not released the file. Never write to pdd once per row or in a tight series of PROC APPENDs. Stage QC rows in WORK (`%p17_qinit` / `%p17_qadd` write `work.qc_pecan_id_*`) and write them once with `%p17_flush_qc` at the end of the program and in `fail_out` before the abort. `%pdd_lib` assigns pdd with `filelockwait=10` as a safety net.
- Synthetic test logs must have no WARNING and no ERROR lines (T13 / T7 checks fail on both).
- Log scans in test programs must anchor at column 1 (prefix comparison `upcase(_infile_) =: 'ERROR'` / `=: 'WARNING'`, never `substr(_infile_,1,n)`: it raises Invalid SUBSTR NOTEs on short lines and then the ERRORS= limit WARNING), because the log echoes source such as `%put ERROR: ...` in macro definitions. Unanchored `index(...,'ERROR:')` counts the echoed source as an error. Still exclude the TESTRESULT SUMMARY line.
