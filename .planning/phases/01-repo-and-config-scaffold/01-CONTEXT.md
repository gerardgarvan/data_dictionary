# Phase 1: Repo and Config Scaffold — Context

**Gathered:** 2026-10-16
**Status:** Ready for planning
**Source:** User inline — references _reference_old pattern

---

<domain>
## Phase Boundary

Deliver the skeleton that every later SAS program builds on:
- `sas/00_config.sas` — all macro path variables, `%pdd_lib` macro, global SAS options
- `run_pipeline.cmd` — batch driver that runs 99_run_all.sas, writes a timestamped log, exits nonzero on ERROR
- `sas/99_run_all.sas` — pipeline runner skeleton (%includes 00_config.sas, commented placeholders for programs 02–07)
- Output folders on P: created automatically (dlcreatedir)

Done when an empty run (99_run_all.sas with no substantive programs yet) writes a clean log with zero ERRORs to `P:\PeCAN Master Data\Gerard\data_dictionary\logs`.

</domain>

<decisions>
## Implementation Decisions

### Pattern source
Mirror the style of `_reference_old\sas\00_config.sas` and `_reference_old\run_pipeline.cmd`.
- Read those files to understand how sas.exe is called, how the per-program log redirect works, and how the `in_pipeline` flag guards against re-entry.
- Do NOT copy their data paths (`Master_Renamed_same_format_accross`, `g` library) or any reference to the renamed xlsx files.
- Never modify anything in `_reference_old`.

### 00_config.sas macro variables (locked)
| Macro | Value |
|-------|-------|
| `raw_master` | `P:\PeCAN Master Data\Gerard\raw\master` |
| `out_root` | `P:\PeCAN Master Data\Gerard\data_dictionary` |
| `qc_path` | `&out_root.\qc` |
| `logs_path` | `&out_root.\logs` |
| `out_path` | `&out_root.\out` |
| `sas_path` | `C:\data_dictionary\sas` |

### %pdd_lib macro
Each program calls `%pdd_lib;` at the top to assign `libname pdd "&out_root." access=rw;` with `dlcreatedir`.
00_config.sas defines this macro once.

### SAS session options (set in 00_config.sas)
- `options validvarname=v7;`
- `options encoding='UTF-8';`
- `options mprint nofmterr nodate nonumber ps=max ls=200;`

### Output folder creation
00_config.sas uses `options dlcreatedir;` and a `libname` assignment against each P: subfolder so that the folders are created automatically if missing.

### in_pipeline flag
Mirror the `_set_pipeline_default` macro pattern exactly from the reference: use `%symexist` guard + `envlen(RUN_ALL)` detection. 99_run_all.sas sets `%let in_pipeline = 1;` after its own %include.

### run_pipeline.cmd design (locked)
- Single driver file at repo root (not inside sas\)
- Uses a `:run_program` subroutine that calls `sas.exe -sysin ... -log ... -nosplash -icon -sasuser WORK -set RUN_ALL 1`
- Writes a timestamped summary line to the master log for each program
- Stops the pipeline (goto :fail) if exit code ≥ 2
- Counts WARNING lines from the per-program log using `findstr`
- Supports a `config.local.cmd` override for the SAS_EXE path
- Default `SAS_EXE` = `C:\Program Files\SAS94\SASFoundation\9.4\sas.exe`
- For Phase 1, the only program called is `99_run_all.sas` (which itself contains the placeholders); later phases will add programs 02–07 to the pipeline call sequence
- Exits nonzero if the log contains ERROR lines (use findstr /b /c:"ERROR" on the master log, count > 0 → exit /b 1)

### 99_run_all.sas design (locked)
- Starts with `options mprint nofmterr nodate nonumber ps=max ls=200;`
- `%include "C:\data_dictionary\sas\00_config.sas";`
- `%let in_pipeline = 1;`
- %put NOTE banners echoing key macro values (raw_master, out_root, logs_path)
- Commented-out %include blocks for programs 02–07, each labelled with the phase name
- Ends with a PIPELINE COMPLETE %put NOTE

### Deliver complete programs
Each of the three deliverables (00_config.sas, run_pipeline.cmd, 99_run_all.sas) must be delivered as a complete file in one block. No stubs or ellipses.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Reference implementation (read-only — do not modify)
- `_reference_old/sas/00_config.sas` — Pattern for macro variable layout, `in_pipeline` guard, shared macros
- `_reference_old/run_pipeline.cmd` — Pattern for :run_program subroutine, log writing, SAS_EXE override, exit-code logic

### Planning source of truth
- `.planning/PROJECT.md` — Locked decisions PDD-D-01..PDD-D-10, constraints, paths, layout
- `.planning/ROADMAP.md` — Phase 1 acceptance criterion (clean log on P:)
- `.planning/REQUIREMENTS.md` — PDD-01 requirement table

</canonical_refs>

<specifics>
## Specific Ideas

- `dlcreatedir` on the libname for each P: subfolder is the cleanest way to auto-create folders without SYSTASK or X commands.
- The `%pdd_lib` macro should be a short 3-line macro: set dlcreatedir, libname pdd, unset dlcreatedir (so subsequent libnames don't accidentally create directories).
- Alternatively: set `options dlcreatedir;` once at the top of 00_config.sas and leave it on for the session — simpler, acceptable.
- Per-program logs for Phase 1: 99_run_all.sas itself is the only program; run_pipeline.cmd directs its -log to `logs_path\99_run_all_<timestamp>.log` (or fixed name, user did not specify — use fixed `99_run_all.log` matching the reference pattern).

</specifics>

<deferred>
## Deferred Ideas

- SHA-256 source guard (Phase 2)
- PROC IMPORT / DATA step imports (Phase 3)
- Name map (Phase 4)
- PCNR_ build, distribution engine, workbook writer (Phases 5–7)
- Per-cell source flags PDD-D-15/PDD-D-16 (open decisions, Phase 5 only)

</deferred>

---

*Phase: 01-repo-and-config-scaffold*
*Context gathered: 2026-10-16 (user inline)*
