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
