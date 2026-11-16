# Phase 15 (M2): New-source intake - Research

**Researched:** 2026-11-16
**Domain:** Base SAS 9.4 batch pipeline extension (source guard, header inventory, spec-driven CSV import, key checks); Python/openpyxl QC workbook
**Confidence:** HIGH for file facts (read directly from the committed probe) and for existing-code constraints (read directly from the repo). MEDIUM for the exact SAS idioms in new programs (cannot be run here; no SAS, no P:).

## Summary

Phase 15 adds three CSV files (2023, 2024, 2025 `*_X_MASTER_DATASET_20261016.csv`) to the pipeline without touching the 20 existing sources. The probe (`.planning/schemas/probe_master_data_20261116.md`) gives everything needed to specify the work: all three have 94 columns, 0 all-blank rows, one row per distinct 5-digit `PRECEDE Study ID`, and no case ID in the 2018-2022 spine. Row counts to reconcile are 10,772 (2023), 13,029 (2024) and 12,689 (2025). Only 2024 (18 non-UTF-8 lines) and 2025 (26) are wlatin1. 2023 is UTF-8.

The main finding is structural. The existing programs hard-code "20 files" in at least 25 assertions: `02_source_guard.sas` (baseline `ne 20`, inventory rows, `n_files = 20`), `03_import.sas` (`%do _ifc = 1 %to 20`, `_nqc = 20`), `03a_build_spec.sas` (`_nfc ne 20`, `_n_wlatin ne 7`), `99_run_all.sas` (`_n_filelist ne 20`) and `05_build_pcnr_macros.sas` (s_codes must be exactly s01..s20). Editing them in place would break the v1.0 reproducibility that success criterion 1 protects. **Recommendation: add new, parallel Phase 15 programs and datasets (new s-codes s21-s23, new baseline file, new spec file) and leave the six existing programs' 20-file logic unchanged.** The only edits to existing files are additive: `99_run_all.sas` phase token `15`, `run_pipeline.cmd` phase block, `docs/exchange_schema.csv` rows.

Everything in this phase ends in `PENDING SAS RUN`. The explicit baseline approval for the new hashes is a human step. The within-new-files case-ID overlap check (PDD-D-29 item 3) is a hard gate that the SAS program enforces.

**Primary recommendation:** Build four plans (guard, inventory+spec, import+checks, QC workbook+wiring) as new `sas/15*.sas` programs that follow the Phase 2/3 patterns exactly, assert 3 new files (not 23), and never re-baseline silently.

<user_constraints>
## User Constraints (no CONTEXT.md exists for this phase; ROADMAP success criteria, REQUIREMENTS and DECISIONS are treated as locked)

### Locked Decisions
- PDD-D-01..23 are closed. PDD-D-17 (1:1 per case) is extended by NEW-04. PDD-D-19 (`cats('Precede', put(input(strip(id), ?? 8.), z5.))`) is applied unchanged to 2023-2025. PDD-D-23 (`encoding='wlatin1'` for flagged files).
- PDD-D-29 DECIDED 2026-11-16: (1) PDD-D-19 rule unchanged for 2023-2025; (2) no 2023-2025 normalized ID in the 2018-2022 spine, PDD-D-25 closed; (3) Phase 15 must count normalized case IDs shared between each pair of the 2023, 2024 and 2025 files; if any are shared, stop at a decision gate (do not stack) and list the counts per pair.
- PDD-D-25 CLOSED - NOT NEEDED. PDD-D-26/28 DECIDED (not Phase 15 work).
- ROADMAP success criteria 1-6 and REQUIREMENTS NEW-01..NEW-05, NEW-03a (verbatim intent):
  1. Existing 20-file SHA-256 baseline matches unchanged; new files get their own baseline entries by an explicit approved step, not a silent re-baseline.
  2. Header inventory covers the same file x header matrix for the new files.
  3. New files import with explicit informats/lengths, IDs/codes as character, wlatin1 for probe-flagged files, PDD-D-19 rule unchanged; row counts reconcile to the probe.
  4. Header variants (Braden columns by year, `Fraility_Score`, `SleepApnea_YN`, `Preop_Edu_Years`) are mapped, not renamed at source; type changes (`Death_Days_After_Surgery`, five frailty components) go to the map review.
  5. Each new file is checked 1:1 per case; any non-1:1 file stops at a decision gate.
  6. Era-overlap counts and conflicting shared-column values are reported to QC; the three-file pairwise gate.

### Claude's Discretion
- File/program naming, s-codes for the new files, how the QC output is packaged, plan/wave split, and the mechanism for the explicit baseline approval (all recommended below).

### Deferred Ideas (OUT OF SCOPE)
- Name map extension (Phase 16), PECAN_ID registry and K1/K2 keys (Phase 17), combined dataset (Phase 18), master xlsx (Phase 19), MRN linkage across key eras (PDD-D-26, deferred). PDD-D-27 is open and not Phase 15.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NEW-01 | Existing 20-file baseline unchanged; new files get own baseline by explicit approved step | Separate `docs/source_guard_baseline_new.csv`; reuse the existing lightweight 20-file check pattern in `99_run_all.sas`; approval flag `PDD_APPROVE_NEW_BASELINE=1`; see Pattern 1 |
| NEW-02 | Header inventory extended to new files, same file x header matrix | New `pdd.header_inventory_new` with identical columns as `pdd.header_inventory`; matrix output `qc\header_matrix_new.xlsx` or CSV via exchange; Pattern 2 |
| NEW-03 | Import with Phase 3 conventions; wlatin1 for 2024/2025; PDD-D-19 | New spec `docs/import_spec_new_generated.csv` in the existing 11-column layout; `src_encoding` utf-8/wlatin1/wlatin1; `%pdd_norm_psid`; Pattern 3 |
| NEW-03a | Header variants mapped not renamed; type changes to map review | `docs/new_source_header_variants.csv` (seeded from the probe) and `exchange\new_type_changes.csv`; Pattern 4; Phase 16 consumes |
| NEW-04 | 1:1 per case on each new file, non-1:1 stops at decision gate | Probe already shows 1:1 for all three; SAS asserts it on `norm_psid` after import; non-1:1 writes PENDING DECISION and aborts; Pattern 5 |
| NEW-05 | Era overlap + conflicting shared columns reported; within-new-files pairwise gate | Overlap against ALL 20 sources' `norm_psid` (not just spine) plus 3 pairwise counts; hard gate; Pattern 6 |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- After any SAS edit run `python tools\sas_lint.py sas\<file>.sas` and `sasjs lint`; both zero errors on edited files.
- After any Python edit run `ruff check python\` and `pytest python\tests`; zero errors, all pass. Interpreter `.venv\Scripts\python.exe`; install via `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`.
- PCM compliance (sas_lint): no open-code `%if`/`%else` outside `%macro..%mend` (C3); no macro keyword in quoted PUT string (C11); no macro called before its `%macro` in the same file (C13); no bare `data ;`/`set ;` (C14); `LIBNAME libref engine "path"` (C9); no `??` in PROC SQL (C1); no ANSI SQL OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH..AS (C2).
- Probe-first: only names, types, lengths, counts, encodings in the probe may be used; missing facts become a PROBE REQUEST. Probe files never contain data values; counts 1-10 stay `<11` (applies to anything written into git, including QC summaries committed to `.planning/`).
- Headless: no questions; record assumptions; never reach P:, run SAS, or read real data; SAS runs are Gerard's (write exact program, log and `qc\` files to bring back, mark `PENDING SAS RUN`); decision gates are `PENDING DECISION`; never write to the shared Master Data folder; no data in git; commit to current branch (`pdd-2018-2025-api`), never push or switch.
- Workbooks: KEY sheet leftmost; UF colors `#0021A5`, `#FA4616` for headers.
- SAS pitfalls: no `%if` in open code; quote or `%superq` text in `%if` comparisons; `??` only in DATA steps; no commas in macro-call arguments (use a global macro variable); no `RETAIN` with length specs; `LIBNAME libref engine "path"`; declare `array _character_/_numeric_` after `SET`, helper variables after the array; `strip()` before regex anchors on padded vars; `catx(' ', ...)` not `cats()` where spaces matter; `encoding='wlatin1'` for probe-flagged files; 5-digit IDs normalize to `Precede#####`.

## Facts From the Probe (the only source of file facts)

All from `.planning/schemas/probe_master_data_20261116.md` (generated 2026-11-16, strip-fix rerun). The probe's unit numbers are probe order, not s-codes: probe unit 19 is the 2023 file but existing `s19` is `ALL_AIM2_MASTER_DATASET_20210917.xlsx`. Never reuse probe unit numbers as s-codes.

| Probe unit | File (exact name) | Rows | Cols | Encoding guess | Non-ASCII / not-UTF-8 lines | Distinct case IDs | 1 row per ID | In spine | Case-ID shape |
|---|---|---|---|---|---|---|---|---|---|
| 19 | `2023_X_MASTER_DATASET_20261016.csv` | 10,772 | 94 | utf-8 | 0 / 0 | 10,772 | yes | 0 | `99999` on 10,772 rows |
| 20 | `2024_X_MASTER_DATASET_20261016.csv` | 13,029 | 94 | wlatin1 | 18 / 18 | 13,029 | yes | 0 | `99999` on 13,029 rows |
| 21 | `2025_X_MASTER_DATASET_20261016.csv` | 12,689 | 94 | wlatin1 | 26 / 26 | 12,689 | yes | 0 | `99999` on 12,689 rows |

Other verified facts:
- Case-ID column header and SAS name in all three: `PRECEDE Study ID` (note: the spine s09 header is `PRECEDE_Study_ID`). PROC IMPORT guessed it as `Num 8` in the probe, so the import spec MUST force it to character (the s09 spec forces char with `$22.`); the 5-digit shape means PDD-D-19's `prxmatch('/^\d+$/')` branch applies to every row.
- `ENCRYPTED_MRN` and `ENCRYPTED_ENCOUNTER` are Char. Max lengths observed by the probe: 2023 51/63, 2024 45/55, 2025 49/54. Probe lengths are PROC-IMPORT guesses from the sample, so use the 03a `$32767` pre-pass for true max lengths, not these.
- The three files have the same 94 columns in the same order, with exactly these header differences between them (computed from the probe): columns 89-91 (Braden). 2023: `Braden Activity`, `Braden Mobility`, `Braden Sensory Perception`. 2024: `BRADEN_2024_OUT_Braden Activity`, `..._Braden Mobility`, `..._Braden Sensory P`. 2025: same with `2025`. The probe's 32-character cut of `Braden Sensory P` is a probe limit (SAS name length); the Phase 2 header read of the real first line will show the full header (see Open Question 1).
- Same-name columns differ in observed probe length across the three files (ENCRYPTED_*, `Service` 49/49/32, `Base Procedure 1` 201/200/201, `CPT 1 Description` 70/72/70, `Admit Source` 28/40/40, `Dischg Disposition` 28/38/29). Lengths must be per-file from the pre-pass (no shared length), and Phase 16/18 must take the maximum.
- Type facts relevant to NEW-03a: `Death_Days_After_Surgery` is `Char 6` in all three new files; it is `Num 8` in s09 (probe unit 9), s12, s15 (as listed). The frailty components `Feels_Exausted`, `Low_Physical_Activity`, `Slow_Walking_Speed`, `Unintended_Weight_Loss`, `Week_Grip_Strength` are `Num 8` in all three new files; `Feels_Exausted` is `Char` in s15-era 2021/2022 files (probe units 15 and 17: `Char 1` and `Char 3`). `preop_edu_years` is `Num 8` in all three (lowercase header in the probe; REQUIREMENTS writes `Preop_Edu_Years`, so match case-insensitively); `Education` in the older files is `Char 19`.
- Names that exist in the new files and not (by case/underscore-normalized name) in the spine s09: `Feels_Exausted`, `Fraility_Category`, `Fraility_Score`, `ICD10 Principal Diagnosis POA`, `Low_Physical_Activity`, `preop_edu_years`, `SleepApnea_YN`, `Slow_Walking_Speed`, `Unintended_Weight_Loss`, `Week_Grip_Strength`. Equivalents seen in s09: `Frailty_Score`, `Sleep_Apnea_YN`, `Education`, `Feels_Exausted_Value`. Whether the other five frailty components or the POA column exist elsewhere in the 20 sources is for Phase 16 to establish; do not assert it here.
- No column in the new files is a date column (the probe's `years` column is empty for all three).
- All three have 0 placeholder counts on the ID columns; several free-text/category columns have placeholder counts (for example `Marital Status` 900 in 2023). Placeholder handling is Phase 5/16 territory, not intake.

Facts the probe does NOT provide (so Phase 15 must produce them, not assume them): the three files' true header text beyond 32 characters; which of the 20 existing sources' case IDs (other than the spine's) overlap the new files; case-ID overlap between the three new files; the exact byte positions/columns of the non-ASCII characters in 2024/2025; the post-transcoding character lengths.

## Standard Stack

### Core (all already in the repo; no new dependencies)
| Tool | Version | Purpose | Why standard |
|------|---------|---------|--------------|
| Base SAS 9.4 (UTF-8 session via `nls\u8\sasv9.cfg`) | 9.4 (Gerard's machine; cannot be probed here) | Guard, inventory, import, checks | Entire pipeline is Base SAS; `%check_encoding` enforces UTF-8 |
| `sas/00_config.sas` | repo | Paths, `%pdd_lib`, `%pdd_norm_psid` | Single source of truth; PDD-D-19 macro lives here |
| `certutil -hashfile ... SHA256` via PIPE | Windows built-in | SHA-256 (as in `02_source_guard.sas` Section 5) | Phase 2 pattern; no PROC needed |
| Python (.venv, 3.14.2 present) + pandas 3.x + openpyxl 3.1.5 | per `python/requirements.txt` | xlsx QC writer (D-22: SAS owns data, Python owns xlsx) | Existing `pdd/pcnr_qc_workbook.py`, `xlsx_style.py` |
| pytest 8.3.3 / ruff 0.7.1 | pinned in requirements.txt | Python gates | CLAUDE.md |
| `tools/sas_lint.py`, `sasjs lint`, `tools/check_test_log.ps1` | repo | Static + log hygiene | CLAUDE.md; `check_test_log.ps1` scans SAS logs |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New parallel programs and datasets | Edit 02/03/03a/05 to accept 23 files | Breaks 25+ hard-coded "20"/"7"/"s01..s20" assertions and the committed v1.0 baseline semantics; high regression risk with no SAS here to test. Rejected. |
| SAS writes QC CSV to `exchange\`, Python writes xlsx | SAS ODS Excel | D-22 locks the SAS/Python split; Phase 2 predates it. Use D-22. |
| `docs/import_spec_new_generated.csv` | Append rows to `docs/import_spec_generated.csv` | `03_import.sas` and `03a` read/assert the whole file (4,795 rows, 20 file_codes, 7 wlatin1). Appending breaks them. Keep separate. |

**Installation:** none beyond `.venv\Scripts\python.exe -m pip install -r python\requirements.txt` (already satisfied if `.venv` exists).
**Version verification:** Python packages are pinned in `python/requirements.txt` and not changed by this phase. SAS version cannot be verified on this machine (no SAS). LOW-risk since no new library is introduced.

## Architecture Patterns

### Recommended Project Structure (additions only)
```
sas/
  15a_new_source_guard.sas     # NEW-01 hash guard (20 unchanged + 3 new baseline)
  15b_new_inventory_spec.sas   # NEW-02 header inventory; NEW-03 pre-pass + spec build
  15c_new_import.sas           # NEW-03 import + norm_psid; NEW-04 1:1; NEW-05 overlap + gate; row-count reconcile
  15_new_intake_macros.sas     # optional shared macros (only if >1 program needs them; define before use, C13)
docs/
  source_guard_baseline_new.csv      # created ONLY by approved step (3 rows, same 3 columns)
  import_spec_new_generated.csv      # same 11-column layout as import_spec_generated.csv
  new_source_files.csv               # s_code,filename,ftype,src_encoding (s21..s23) -- file list used by all 15x programs
  new_source_header_variants.csv     # NEW-03a seed (committed; no data values)
python/pdd/new_source_qc_workbook.py + python/scripts/write_new_source_qc.py + python/tests/test_new_source_qc.py
```
New datasets (all in `pdd` library on P:, never in git): `pdd.source_inventory_new`, `pdd.header_inventory_new`, `pdd.raw_char_lengths_new`, `pdd.import_spec_new`, `pdd.src_s21`, `pdd.src_s22`, `pdd.src_s23` (each with `norm_psid`), `pdd.qc_import_rowcounts_new`, `pdd.qc_new_overlap`, `pdd.qc_new_type_changes`.

s-code assignment (recorded assumption A1): `s21` = 2023, `s22` = 2024, `s23` = 2025. Existing s01..s20 never change. Phase 5 and the priority file expect exactly s01..s20, so Phase 18 (not 15) decides how s21..s23 enter the build.

### Pattern 1: Guard that cannot silently re-baseline (NEW-01)
**What:** `15a` does two independent checks. (a) Re-hash the 20 existing files and compare with `docs/source_guard_baseline.csv` exactly as `99_run_all.sas` `%run_hash_guard` does (read baseline CSV for file list, certutil, compare `s_code`, `filename`, `sha256`; abort on any mismatch; require exactly 20 rows). That file is never written. (b) Hash the 3 new files from `docs/new_source_files.csv`. If `docs/source_guard_baseline_new.csv` exists with 3 rows, compare and abort on drift. If it is absent or empty: DO NOT seed (this is the difference from `02_source_guard` Section 11, whose first-run branch seeds automatically). Instead write the proposed hashes to `qc\new_source_hashes_proposed.csv`, log `PENDING DECISION: approve new baseline`, and `%fail_out`.
**Approval mechanism (recommended):** Gerard reviews the proposed hashes, then reruns with OS env var `PDD_APPROVE_NEW_BASELINE=1` (read with `%sysfunc(envlen(...))`/`%sysget`, same mechanism `00_config.sas` uses for `RUN_ALL`). Only with that flag and an absent baseline does the program write `docs/source_guard_baseline_new.csv` (header `s_code,filename,sha256`, then 3 rows) and log `NOTE: new baseline seeded by explicit approval`. A seeded baseline is committed by Gerard. The flag with an existing baseline is ignored (never overwrites). Mark the phase step `PENDING DECISION` (approval) and `PENDING SAS RUN`.
**Do not:** add rows to `docs/source_guard_baseline.csv` (breaks the `ne 20` assertions in `02_source_guard.sas` and `99_run_all.sas` and violates "unchanged").
**Source:** `sas/02_source_guard.sas` lines 297-333 (certutil loop), 397-508 (seed-or-compare); `sas/99_run_all.sas` `%run_hash_guard`.

### Pattern 2: Header inventory for the new files (NEW-02)
**What:** Reuse the Phase 2 CSV branch logic (PROC IMPORT `guessingrows=max` under `options nosyntaxcheck noerrorabend nomprint`, then `dictionary.columns`, plus the raw first-line header capture parsed with `dsd dlm=','`, `lrecl=32767`) for the three files, producing `pdd.header_inventory_new` with exactly the columns of `pdd.header_inventory` (same `s_code`, `sheet_name`, `col_name`, `col_type`, `original_header`, `original_header_trunc`, label). Then reuse the Section 13 PROC TRANSPOSE (`by col_name`, `id hdr_src`) so the matrix has the same file x header layout. Output the matrix to `exchange\header_matrix_new.csv` for the Python writer (or ODS Excel `qc\header_matrix_new.xlsx` if the planner prefers parity with Phase 2; recommend CSV plus Python per D-22).
**Assert:** exactly 3 file codes, 94 header rows per file, no all-blank headers, and (independent check against the probe) per-file column count 94.
**Encoding note:** read the header line with `encoding='utf-8'` for s21 and `encoding='wlatin1'` for s22/s23, so any non-ASCII byte in a header (not seen in the probe's ASCII header names) is not mangled. Add the match-to-probe assertion: each file's column count equals 94.

### Pattern 3: Spec-driven import with per-file encoding (NEW-03)
**What:** Copy the 03a/03 approach, scoped to three files:
1. Raw pre-pass: read every column as `$32767` to get true maximum lengths per column (03a `%_csv_prepass`, batches of 200 columns; 94 columns = 1 batch). Use `encoding='wlatin1'` for s22/s23 in the pre-pass INFILE, because the existing macro hard-codes `encoding='utf-8'`; reusing it unchanged would measure the wrong lengths (UTF-8 reading of invalid bytes) for the two flagged files. This requires a parameterised copy (encoding as a macro parameter), not an edit of the original.
2. Spec: one row per column with `file_code`, `col_order`, `src_name`, `orig_col_name`, `sas_name`, `sas_type`, `length`, `informat`, `format`, `notes`, `src_encoding` (the 11 columns of `import_spec_generated.csv`). Forced character: `PRECEDE Study ID`, `ENCRYPTED_*` (03a `_check_forced_char` rules: `PRECEDESTUDYID` compress match, `(_ID|_CODE)$`, `^ENCRYPTED_`). Numeric columns get `best32.` after the parse-fail probe (03a `_probe_numeric_cols`). Types follow what the probe guessed, subject to the probe/probe-run check (Open Question 2).
3. `src_encoding` values: s21 `utf-8`, s22 `wlatin1`, s23 `wlatin1`. Assert exactly 2 wlatin1 file codes and 0 blank/other values (the new analogue of 03a `_assert_src_encoding`, which expects 7 for the old set).
4. Import via a generated DATA step with `infile ... encoding='<src_encoding>' dsd dlm=',' firstobs=2 truncover lrecl=32767` (03_import pattern: write a `.sas` file with `data _null_` + `FILE`, then `%include`). Because the SAS session is UTF-8, SAS transcodes wlatin1 to UTF-8 on read; a single non-ASCII character becomes 2 bytes, so `length` for character variables must come from the post-transcoding pre-pass and must not be the probe length (see Pitfall 3).
5. Post-import `%pdd_norm_psid(in=work.x, out=pdd.src_s2N, idvar=PRECEDE_Study_ID)` (the macro in `00_config.sas`). The SAS name that results from `validvarname=v7` for `PRECEDE Study ID` must be checked in the spec (existing sources show `PRECEDE_Study_ID`, spine s09 header is already underscored); pass whatever the spec's `sas_name` says. Do not call it with the default `idvar` without confirming.
6. Reconcile: nobs of `pdd.src_s21/22/23` equals 10,772 / 13,029 / 12,689 and equals the raw line count minus 1 (Phase 3 `qc_import_rowcounts` pattern, written to `pdd.qc_import_rowcounts_new`). These counts are asserted constants taken from the probe, and a mismatch is a hard fail.
7. Post-import encoding guard (03a `%p3_assert_encoding` analogue): after import with wlatin1, 0 character cells with bytes > 127 that are not valid after transcoding is not directly testable; keep the Phase 3 proxy `verify(val, collate(0,127)) > 0` count per column for information and log it as NOTE with counts only (no values). Do not fail on non-zero for s22/s23, because transcoded characters such as the sharp s are legitimately non-ASCII in UTF-8 and the Phase 3 guard's pass condition was specific to its 7 files; record counts for QC and let Gerard review (Assumption A5).

### Pattern 4: Header variants and type changes (NEW-03a)
**What:** Do not rename anything in `pdd.src_s2N`; keep `sas_name` equal to the cleaned source header. Produce two artifacts for Phase 16:
- `docs/new_source_header_variants.csv` (committed; metadata only): `file_code, new_header, comparable_header_in_older_sources, variant_kind, older_source_codes, note`. Seed it from the probe with: Braden (s21 `Braden Activity/Mobility/Sensory Perception` equals s09's; s22 `BRADEN_2024_OUT_*`; s23 `BRADEN_2025_OUT_*`; s17 uses `Braden_Activity` form), `Fraility_Score` vs `Frailty_Score` (s09), `Fraility_Category` (no s09 equivalent found by name; flag), `SleepApnea_YN` vs `Sleep_Apnea_YN` (s09), `preop_edu_years` (Num) vs `Education` (Char 19), `Feels_Exausted` vs `Feels_Exausted_Value` (s09) and `Feels_Exausted` (s15, s17). `variant_kind` values: `year_prefix`, `spelling`, `underscore`, `rename_and_type`, `new_in_2023`. Mark every row `PENDING DECISION` for Phase 16/MAP-02; none is merged here.
- `exchange\new_type_changes.csv` (runtime, from `dictionary.columns` of `pdd.src_s21..s23` versus `pdd.src_s01..s20` joined on a normalized-name key `compress(upcase(name), ' _')`): rows where type differs, with both types and lengths, and the file codes. Must include `Death_Days_After_Surgery` (Char in new, Num in old per probe) and the five frailty components. The normalized-name join cannot catch spelling variants (`Fraility_*`), which is why the seeded variants file exists; the QC workbook shows both.

### Pattern 5: 1:1 per case on each new file (NEW-04)
**What:** After normalization, `select count(*), count(distinct norm_psid)` per file, plus count of blank `norm_psid`. Assert `n_rows = n_distinct` and `n_blank = 0` for each file, expected 10,772 / 13,029 / 12,689 distinct per the probe. If not 1:1: write `exchange\new_nonone.csv` with counts only, log `PENDING DECISION: file sNN not 1:1 per case (PDD-D-17 extension)`, and `%fail_out`. Do not dedupe, do not pick a row.
**Also report (information, not a gate):** the number of distinct `ENCRYPTED_MRN` per file (probe: 8,984 / 10,645 / 11,124, fewer than rows, so multi-case patients exist within each file; K2 only) and distinct `ENCRYPTED_ENCOUNTER` (probe: 10,045 / 12,251 / 12,302, fewer than rows). These are the PDD-D-17 "1:1 per case" caveat; they do not break 1:1 per case and must not be mistaken for it. PDD-D-20 (an encounter mapping to more than one case) was handled for s17 only; report the equivalent count for the new files (distinct case count per encounter token > 1) as information for Phase 17/18, no fix applied.

### Pattern 6: Era overlap and the three-file gate (NEW-05, PDD-D-29 item 3)
**What:** Three computations on `norm_psid`, all written to `pdd.qc_new_overlap` and `exchange\new_overlap.csv`:
1. Pairwise within the new files: `|s21 ∩ s22|`, `|s21 ∩ s23|`, `|s22 ∩ s23|` (PROC SQL inner join on `norm_psid`, count distinct). **Hard gate:** if any is > 0, write the three counts and `PENDING DECISION: new files share case IDs (PDD-D-29 item 3); do not stack`, then `%fail_out`. Do not stack, do not choose a precedence. If all are 0, log `NOTE: pairwise overlap 0/0/0`.
2. Against the 2018-2022 sources: for each of s21, s22, s23, count of `norm_psid` found in the spine (s09) AND in the union of `norm_psid` over all 20 old sources `pdd.src_s01..s20` (the probe only tested the spine; s01 has 274 IDs and s18 has 269 IDs outside the spine, probe unit 1/18, so an overlap through those is not excluded by the probe). Expected 0 per the probe (spine). If the union count is > 0 for any file: write counts, `PENDING DECISION: reopen PDD-D-25`, `%fail_out`. (PDD-D-25 is CLOSED only on the spine evidence.)
3. Conflicting shared-column values: only defined where cases overlap. With the expected 0 overlap it is 0 by construction, so report `n_overlap_cases=0, n_conflicting_cells=0, status=NOT_APPLICABLE`. Do not attempt a column-matched comparison now (the column mapping is Phase 16's job); if overlap is ever > 0, the gate in item 1 or 2 stops the run first.
**Output hygiene:** any count 1-10 that is copied into a committed file or message is written `<11`. Runtime outputs on P: may carry exact counts, since they are outside git.

### Pattern 7: Wiring (additive)
- `sas/99_run_all.sas`: add `15` to `_valid` in `%_validate_phases` (currently `2 3 4 5 6 7`) and a Phase 15 block (include `15a`, `15b`, `15c` in order) guarded by `%_phase_in(15)`. Do not change the default phase list. Phase 15 must call the lightweight 20-file guard (`%run_hash_guard`) if Phase 2 is not in the run, as the Phase 3 path already does.
- `run_pipeline.cmd`: add a Phase 15 Python block mirroring Phase 7 (`findstr /i "\<15\>"`), running `write_new_source_qc.py`. The existing `\<4\>` tokens do not match `15` (word-boundary on whole token), but test the `findstr` pattern for `15` vs `1` and `5` since `\<5\>` is used for Phase 5: `15` contains `5` after a digit, and `\<` requires a word start, so `\<5\>` does not match `15`. Verify by reading, not by running.
- `docs/exchange_schema.csv`: add rows for each new exchange CSV (`file,column,type,required`), as 07-01 did, because the Python writers call `assert_input` against this schema.
- Standalone first: Gerard's first run should be each `15x` program standalone (route_log pattern, `in_pipeline = 0`), then in pipeline.

### Anti-Patterns to Avoid
- **Editing the "20" assertions or the existing spec/baseline files.** Breaks v1.0 and criterion 1.
- **Seeding the new baseline on first run.** That is the silent re-baseline the roadmap forbids.
- **Using probe unit numbers as s-codes** (probe 19 = 2023, s19 = AIM2).
- **Treating MRN non-overlap as proof of no repeat patients.** K1 and K2 use different keys (PDD-D-26); 0 MRN overlap is expected from the key change and says nothing about shared patients. Only the case-ID check is meaningful here.
- **Letting PROC IMPORT guess the case-ID type.** The probe shows `PRECEDE Study ID` guessed `Num 8`; the spec must force `$`.
- **Printing values in logs.** Counts and names only (CLAUDE.md privacy rule); no `proc print` of data.
- **CALL EXECUTE for generated code.** Phase 3 explicitly used FILE + `%include` and SET-union accumulators for PCM compliance.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Case-ID normalization | A new regex/format rule | `%pdd_norm_psid` in `00_config.sas` (PDD-D-19, PDD-D-29) | Locked; verified 9,001 pairs / 0 disagreements |
| SHA-256 | A SAS hash function over the file | The Phase 2 `certutil -hashfile` PIPE loop | Same algorithm as the baseline, so hashes are comparable |
| Hash compare + file list from baseline | A new compare routine | `%run_hash_guard` pattern in `99_run_all.sas` (reads the baseline CSV, no DATALINES) | Already handles dup/only-in-one-side/filename cases |
| Raw max-length measurement | Trusting PROC IMPORT lengths or probe lengths | 03a `$32767` pre-pass (parameterise encoding) | Probe lengths are sample guesses and the files have long text (`Base Procedure 1` 200-201) |
| Header matrix | A new layout | Phase 2 Section 13 PROC TRANSPOSE | NEW-02 requires the same file x header matrix |
| Generated import code | CALL EXECUTE | FILE + `%include` (03_import) | Locked PCM-compliant pattern |
| QC xlsx styling | New openpyxl styling | `python/pdd/xlsx_style.py` and `pcnr_qc_workbook.py` helpers (`assert_input`, `read_csv`, `write_workbook`, `verify_workbook`) | KEY sheet first, UF colors already implemented |

**Key insight:** Phase 15 is a re-application of Phases 2-3 to three files plus three new checks (approval gate, 1:1, pairwise overlap). Every piece of logic exists; the work is parameterising it for three files and keeping the old assertions untouched.

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted per instructions, with one note: Phase 15 creates new persistent state on P: (new `pdd.*_new` datasets, `pdd.src_s21..s23`) and one new committed file (`docs/source_guard_baseline_new.csv`, created by an approved step). Re-runs must `proc datasets delete` the new datasets first (pattern in `_delete_stale_outputs`) and must never delete `docs/source_guard_baseline_new.csv` automatically.

## Common Pitfalls

### Pitfall 1: Hard-coded "20" and "7" assertions fire when new rows are added
**What goes wrong:** `ne 20` in the baseline compare, `_nfc ne 20` in the spec check, `_n_wlatin ne 7`, `%do _ifc = 1 %to 20`, and `s01..s20` in Phase 5 priority checks abort the run.
**Why it happens:** the 20-file set is a locked assumption in v1.0 code.
**How to avoid:** parallel programs and datasets; assert 3 and 2 in the new programs; do not modify the old ones.
**Warning signs:** any plan task whose `files_modified` lists `02_source_guard.sas`, `03_import.sas`, `03a_build_spec.sas` or `05_build_pcnr*.sas`.

### Pitfall 2: Silent re-baseline
**What goes wrong:** the existing guard seeds when the baseline file is empty/missing.
**How to avoid:** Pattern 1; seeding only with `PDD_APPROVE_NEW_BASELINE=1` and only when the file is absent; verified by reading the log line.

### Pitfall 3: wlatin1 transcoding and character lengths
**What goes wrong:** with a UTF-8 session and `encoding='wlatin1'`, one non-ASCII source byte becomes 2 UTF-8 bytes, so a column whose longest value was measured in source bytes (or the probe's PROC IMPORT length) can truncate on import. The probe shows `Base Procedure 1` at 200-201 and the Phase 3 history records the `ß` in this column.
**How to avoid:** measure lengths in the pre-pass with the same INFILE encoding as the import; add an assertion that no imported value equals its column length where the pre-pass maximum was shorter (the Phase 3 `_assert_raw_char_lengths` idea); record counts only. Also pass `encoding='wlatin1'` explicitly on the pre-pass INFILE for s22/s23 (the existing macro hard-codes utf-8).
**Warning signs:** a log NOTE about truncation of a character variable; pre-pass max less than final length by more than the transcoding expansion.

### Pitfall 4: Probe's UTF-8-session warning
**What goes wrong:** the probe file says the CSV byte scan "may be unreliable" under a UTF-8 session. The encoding calls for s22/s23 (wlatin1) and s21 (utf-8) come from that scan and agree with the brief; they are not independently proven.
**How to avoid:** run `tools\scan_source_encoding.py` (exists in repo, byte-level, Python) on the three files on Gerard's machine as an independent check, and record the result. If it disagrees with the spec, stop at a decision gate. (Open Question 3.)

### Pitfall 5: Case-ID column name with spaces and `validvarname=v7`
**What goes wrong:** `PRECEDE Study ID` becomes `PRECEDE_Study_ID` under v7 naming (the spine header is already `PRECEDE_Study_ID`), and `%pdd_norm_psid` requires the right `idvar`. A wrong name yields a hard error or an all-blank `norm_psid`.
**How to avoid:** the spec's `sas_name` drives the `idvar`; assert `n_blank_norm_psid = 0` and `count(distinct norm_psid) = probe count` per file.

### Pitfall 6: Long Braden names
**What goes wrong:** `BRADEN_2024_OUT_Braden Sensory Perception` is 41 characters after underscore conversion (if the real header is that; probe shows only a 32-character cut). Names over 32 characters are truncated and could collide.
**How to avoid:** reuse 03a `_assert_and_fix_names` logic (it exists to handle > 32 and collisions) in the parameterised copy, and assert 0 duplicate `sas_name` per file. Keep `orig_col_name` as the full header for the variants file.

### Pitfall 7: Probe-unit vs s-code mix-up in QC and docs
**How to avoid:** every committed table uses file names and the new s-codes, never probe unit numbers.

### Pitfall 8: `findstr` phase tokens in `run_pipeline.cmd`
**What goes wrong:** adding phase `15` next to `1`, `5` tokens. `\<5\>` does not match `15` (word boundary), but `PDD_PHASES` validation in `99_run_all.sas` is `indexw`-based and only accepts tokens listed in `_valid`; `15` must be added there or the run aborts.

### Pitfall 9: Privacy in committed summaries
Probe and QC summaries committed to git must not show counts 1-10; use `<11`. Pairwise overlap counts in particular are likely 0 or small; when copying them into STATE/DECISIONS write `0` or `<11`, never 1-10.

## Code Examples

Patterns taken from the repo (not from external docs), to be copied and parameterised.

### Approval-gated baseline seeding (new; shape follows `run_hash_guard`)
```sas
/* Source: pattern from sas/02_source_guard.sas run_hash_guard; approval gate is new */
%macro run_new_hash_guard;
  %local _bp _n_base _approve;
  %let _bp = C:\data_dictionary\docs\source_guard_baseline_new.csv;
  %let _n_base = 0;
  %let _approve = 0;
  %if %sysfunc(envlen(PDD_APPROVE_NEW_BASELINE)) > 0 %then %do;
    %if "%sysget(PDD_APPROVE_NEW_BASELINE)" = "1" %then %let _approve = 1;
  %end;
  %if %sysfunc(fileexist(&_bp)) %then %do;
    data _null_;
      infile "&_bp" dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
      input;
      _cnt + 1;
      if _eof then call symputx('_n_base', _cnt, 'L');
    run;
  %end;
  %if &_n_base = 0 and &_approve = 1 %then %do;
    /* seed: header then 3 rows from work.sha_new */
  %end;
  %else %if &_n_base = 0 %then %do;
    /* write qc\new_source_hashes_proposed.csv, then: */
    %fail_out(msg=%str(PENDING DECISION -- new baseline not approved. Review qc new_source_hashes_proposed.csv then rerun with PDD_APPROVE_NEW_BASELINE=1));
  %end;
  %else %do;
    /* compare 3 rows; abort on any drift, exact row count 3 */
  %end;
%mend run_new_hash_guard;
```

### Pairwise overlap gate (PROC SQL, no `??`, no ANSI-only syntax)
```sas
/* Source: PDD-D-29 item 3 and the PROC SQL style used in 02_source_guard.sas */
proc sql noprint;
  select count(distinct a.norm_psid) into :_n_2324 trimmed
    from pdd.src_s21 a inner join pdd.src_s22 b on a.norm_psid = b.norm_psid
    where a.norm_psid ne '';
  select count(distinct a.norm_psid) into :_n_2325 trimmed
    from pdd.src_s21 a inner join pdd.src_s23 b on a.norm_psid = b.norm_psid
    where a.norm_psid ne '';
  select count(distinct a.norm_psid) into :_n_2425 trimmed
    from pdd.src_s22 a inner join pdd.src_s23 b on a.norm_psid = b.norm_psid
    where a.norm_psid ne '';
quit;
```
Then, inside a macro, `%if &_n_2324 > 0 or &_n_2325 > 0 or &_n_2425 > 0 %then %fail_out(...)`, with the three counts in the message. (Macro variable names to be chosen by the planner; the example names are illustrative.)

### 1:1 check
```sas
proc sql noprint;
  select count(*), count(distinct norm_psid), sum(norm_psid = '')
    into :_n_rows trimmed, :_n_dist trimmed, :_n_blank trimmed
    from pdd.src_s21;
quit;
```

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Probe run reported 0 case-ID overlap for 2022 (padded value vs `^\d{1,5}$`) | Strip-fix rerun: 2022 files 100% match under PDD-D-19 | 2026-11-16 | PDD-D-29 decided; the same rule applies to 2023-2025 |
| New-source precedence rule (PDD-D-25) | CLOSED - NOT NEEDED | 2026-11-16 | No precedence logic to build; only the check and report |
| Brief-asserted wlatin1 for 2024/2025 | Probe confirms (18 and 26 non-UTF-8 lines) | 2026-11-16 | NEW-03 can state it as fact (subject to the UTF-8-session caveat) |

**Deprecated/outdated:** the MILESTONE_BRIEF's 0-overlap-for-2022 claim (superseded); the first probe runs before the strip fix.

## Open Questions

1. **True header text of the three Braden Sensory columns in 2024 and 2025**
   - What we know: probe shows both SAS name and header cut at 32 characters (`BRADEN_2024_OUT_Braden Sensory P`).
   - What's unclear: whether the real header is `...Sensory Perception` (likely) or something else.
   - Recommendation: no new probe needed. The Phase 15 header inventory reads the CSV first line directly (`original_header`, 256 character cap, flagged if truncated) and therefore resolves it. Record in the variants file from that output (`PENDING SAS RUN`).

2. **Actual types/lengths and informats to use for numeric columns**
   - What we know: the probe's PROC IMPORT guesses (many `Num 8` best.; `Death_Days_After_Surgery` `Char 6`; case/MRN/encounter `Char`).
   - What's unclear: whether any numeric-guessed column contains non-numeric text beyond the probe's sampled rows. The probe's `guessingrows` is not stated in the file, and I did not confirm it.
   - Recommendation: reuse 03a's parse-fail probe (`parse_fail_best32=0` rule) per numeric column; any numeric column with parse failures becomes character with a note, and goes to the type-change QC. Do not guess from the probe alone.

3. **Independent encoding check for the three files**
   - What we know: probe flags 2024/2025 wlatin1 under a UTF-8 session with a stated reliability warning.
   - Recommendation: Gerard runs `python -I tools\scan_source_encoding.py` on the three files (confirm its CLI first; it was not read in this research) and pastes the output into the Phase 15 SUMMARY. Mark `PENDING SAS RUN` (really a Python run on the P: machine). If it disagrees with the spec, `PENDING DECISION`.

4. **Overlap with the other 19 old sources**
   - What we know: probe compares to the spine only.
   - Recommendation: covered by Pattern 6 item 2. Needs a SAS run; expected 0.

5. **Where the s21-s23 datasets enter the build**
   - Not a Phase 15 question (Phase 18). Phase 15 only guarantees `pdd.src_s21..s23` with `norm_psid` and a stable spec.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| SAS 9.4 (UTF-8 config) | all `sas/15*.sas` runs | No (this machine); Gerard's machine yes | - | None: steps end `PENDING SAS RUN` |
| P: drive (raw_master, out_root) | guard, import | No (this machine) | - | None: Gerard runs |
| `.venv` Python | ruff, pytest, QC writer | Yes (`.venv` exists; system Python 3.14.2) | 3.14.2 | - |
| `sasjs` CLI | lint gate | Not probed here (command not run) | - | `tools\sas_lint.py` is pure Python; `sasjs lint` must be run by whoever edits SAS; report if absent |
| `certutil` | SHA-256 | Windows built-in on Gerard's machine | - | - |

**Missing dependencies with no fallback:** SAS and P: (by design). All SAS-dependent work is `PENDING SAS RUN`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Static: `tools\sas_lint.py`, `sasjs lint`. Python: pytest 8.3.3 + ruff 0.7.1. Runtime: SAS log assertions (`%fail_out`, `%put NOTE`) as in Phases 2-3, scanned with `tools\check_test_log.ps1`; QC files produced by Gerard's runs |
| Config file | none for SAS; `python/conftest.py`; no pytest.ini seen (not probed further) |
| Quick run command | `python tools\sas_lint.py sas\15a_new_source_guard.sas` (repeat per file); `.venv\Scripts\python.exe -m pytest python\tests\test_new_source_qc.py -x` |
| Full suite command | `sasjs lint`, `ruff check python\`, `.venv\Scripts\python.exe -m pytest python\tests` |

Headless limit: nothing that reads data can run here. Validation here = static lint + Python tests on synthetic fixtures + QC files returned from Gerard's SAS runs, checked against probe constants.

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NEW-01 | 20-file check present and untouched; new guard never seeds without flag; baseline file name/rows | static + log | `python tools\sas_lint.py sas\15a_new_source_guard.sas`; Python test that greps `15a` for the approval gate and absence of writes to `source_guard_baseline.csv`; log line `PASS -- all 20` + `new baseline` from Gerard's run | No, Wave 0 (`python/tests/test_phase15_static.py`) |
| NEW-01 | `git diff` shows `docs/source_guard_baseline.csv` unchanged | static | `git diff --exit-code -- docs/source_guard_baseline.csv` | n/a |
| NEW-02 | Matrix covers 3 files x 94 headers | log/QC | `qc` file `header_matrix_new` row/col counts; Python test of the writer on a synthetic matrix | No, Wave 0 |
| NEW-03 | Spec has 94 rows per file, forced-char ID, `src_encoding` utf-8/wlatin1/wlatin1; row counts 10,772/13,029/12,689 | static + log | Python test that reads `docs/import_spec_new_generated.csv` once committed (counts rows per file_code = 94; no blank encoding; exactly 2 wlatin1); log `qc_import_rowcounts_new` all `match` | No, Wave 0 |
| NEW-03a | Variants file lists the probe-named variants; type-change file includes `Death_Days_After_Surgery` and the 5 frailty components | static | Python test over `docs/new_source_header_variants.csv` (required headers and rows) | No, Wave 0 |
| NEW-04 | 1:1 per case, no blank `norm_psid` | log/QC | log NOTE `1:1 pass` for s21, s22, s23; `exchange\new_one_to_one.csv` n_rows = n_distinct | After SAS run |
| NEW-05 | Pairwise overlap 0/0/0 or hard stop; union-of-20 overlap 0 | log/QC | `exchange\new_overlap.csv`; log NOTE `pairwise overlap`; Python writer test that a non-zero count renders and masks 1-10 as `<11` in committed output | After SAS run; writer test Wave 0 |
| All | no data values in committed files | static | Python test scanning new `docs/*.csv` and `.planning` outputs for suppressed counts | Wave 0 |

### Sampling Rate
- **Per task commit:** `python tools\sas_lint.py sas\<file>.sas`, `sasjs lint`, and for Python edits `ruff check python\` + `pytest python\tests`.
- **Per wave merge:** full suite above.
- **Phase gate:** all static gates green here, plus Gerard's returned logs/QC files (below) showing zero ERROR/WARNING and the probe constants matched, before `/gsd:verify-work`.

### Files Gerard brings back (PENDING SAS RUN)
For each of `15a`, `15b`, `15c` standalone and then `run_pipeline.cmd 15`: the `.log` from `P:\...\data_dictionary\logs\`, plus from `...\qc\` and `...\exchange\`: `new_source_hashes_proposed.csv`, `header_matrix_new` output, `new_overlap.csv`, `new_one_to_one.csv`, `new_type_changes.csv`, `qc_import_rowcounts_new` export, and the `qc\new_source_intake.xlsx` written by the Python step. Also the one-line output of `tools\scan_source_encoding.py` for the three files. Counts 1-10 become `<11` before anything is pasted into git.

### Wave 0 Gaps
- [ ] `python/tests/test_phase15_static.py` - static checks listed above (approval gate present, no write to old baseline/spec, 3-file and 2-wlatin1 constants, variants file content).
- [ ] `python/tests/test_new_source_qc.py` - writer tests with synthetic CSVs (KEY sheet leftmost, UF colors, `<11` masking).
- [ ] `docs/new_source_files.csv` and the seeded `docs/new_source_header_variants.csv` (needed by tests and programs).
- Framework install: none.

## Plan Split Recommendation (for the planner)

| Plan | Wave | Content | Runs headless? |
|------|------|---------|----------------|
| 15-01 | 1 | `docs/new_source_files.csv`; `sas/15a_new_source_guard.sas` (NEW-01); seeded variants file; static tests | Write + lint here; run `PENDING SAS RUN`; baseline approval `PENDING DECISION` |
| 15-02 | 2 (needs 15-01 file list) | `sas/15b_new_inventory_spec.sas`: header inventory (NEW-02), pre-pass, spec (`docs/import_spec_new_generated.csv`, committed after Gerard's run) | Write + lint; `PENDING SAS RUN` |
| 15-03 | 3 (needs spec) | `sas/15c_new_import.sas`: import, `norm_psid`, row reconcile, type-change report, 1:1 (NEW-04), overlap and gate (NEW-05) | Write + lint; `PENDING SAS RUN` |
| 15-04 | 2 (parallel with 15-02; Python only) | Exchange schema rows, `python/pdd/new_source_qc_workbook.py`, script, tests, `99_run_all` token 15, `run_pipeline.cmd` block | Fully verifiable here (ruff + pytest + sas_lint on `99_run_all.sas`) |

Only 15-04 can be fully verified here. Plans 15-01..15-03 each end with the exact programs and files to bring back. 15-02 and 15-03 depend on a SAS run of the previous program, so after 15-01 the chain is mostly serial on Gerard's runs. The planner should write all three programs now and gate only their execution.

## Assumptions (headless run)

| # | Assumption | Basis | Risk if wrong |
|---|-----------|-------|---------------|
| A1 | New s-codes are `s21` (2023), `s22` (2024), `s23` (2025) | Next free codes after s20; avoids probe-unit confusion | Low; renaming is trivial before first run |
| A2 | New baseline lives in a separate file `docs/source_guard_baseline_new.csv`; approval is via env var `PDD_APPROVE_NEW_BASELINE=1` | Roadmap requires "explicit approved step"; no approval mechanism was specified | Gerard may prefer another mechanism; mark `PENDING DECISION` |
| A3 | Existing 20-file programs stay unmodified; v2.0 combined build (Phase 18) decides how s21-s23 join the 20 | Hard-coded 20-file assertions found by grep | Phase 18 planner must handle the join |
| A4 | The pairwise gate and the union-of-20 overlap gate abort the run (`%fail_out`) when non-zero | PDD-D-29 item 3 says stop at a decision gate | None |
| A5 | Post-import non-ASCII counts in s22/s23 are informational, not a failing guard | The Phase 3 guard's zero-violation condition was written for the 7 old files; sharp-s etc. legitimately appear as non-ASCII after transcoding | Gerard may want a stricter rule |
| A6 | QC delivered as exchange CSVs plus a Python-written `qc\new_source_intake.xlsx` | D-22 split | Low |
| A7 | Probe encoding calls (utf-8 / wlatin1 / wlatin1) are taken as correct; an independent `scan_source_encoding.py` check is requested | Probe warning on UTF-8 session | Spec encoding would need correction before import |
| A8 | `tools\scan_source_encoding.py` usage was not read; CLI to be confirmed by the planner | Not opened | None until used |
| A9 | The probe's `Num 8` guesses are provisional; the 03a numeric parse probe decides final types | Probe does not state `guessingrows` | Some numeric columns may become character |
| A10 | `sasjs lint` availability on this machine was not checked | Time | CLAUDE.md requires it; run before commit and report if absent |

## Sources

### Primary (HIGH confidence; read directly)
- `.planning/schemas/probe_master_data_20261116.md` - file table, units 19-21 columns, ID-like table, shape table (all new-file facts).
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` (Phase 15 section), `.planning/STATE.md`, `docs/DECISIONS.md` (PDD-D-25..29), `CLAUDE.md`.
- `sas/00_config.sas` (`%pdd_norm_psid`, paths, `RUN_ALL` env mechanism), `sas/02_source_guard.sas` (Sections 3, 5, 11, 12, header inventory and matrix), `sas/03_import.sas` (structure and hard-coded 20), `sas/03a_build_spec.sas` (pre-pass, forced-char, D-23 assertion, spec CSV layout), `sas/99_run_all.sas` (`%run_hash_guard`, phase validation), `run_pipeline.cmd`, `docs/source_guard_baseline.csv`, `docs/import_spec_generated.csv` (header and layout), `docs/exchange_schema.csv`, `python/requirements.txt`, `python/tests/test_sas_lint.py`, `python/scripts/write_pcnr_qc.py`.
- `.planning/phases/03-direct-import-of-the-20-sources/03-03-SUMMARY.md` and Phase 2/3 RESEARCH pitfall headings.

### Secondary / Tertiary
- None. No web or library documentation was needed (no new libraries). SAS behavior claims (transcoding byte expansion, `validvarname=v7` naming, PROC SQL forms) rest on existing repo behavior and general SAS knowledge; they are MEDIUM confidence until Gerard's run confirms them.

## Metadata

**Confidence breakdown:**
- File facts: HIGH - read from the committed probe.
- Existing-code constraints (hard-coded 20/7, seed-on-first-run): HIGH - read in the source.
- Standard stack: HIGH - no new dependencies.
- Architecture (parallel programs, approval flag, gate behavior): MEDIUM - sound but untestable here and partly my recommendation.
- SAS runtime details (transcoding lengths, name truncation, PROC IMPORT behavior on these exact files): MEDIUM - verify via the logs Gerard returns.
- Pitfalls: HIGH for repo-derived ones, MEDIUM for transcoding.

**Research date:** 2026-11-16
**Valid until:** 2026-12-16 (stable; invalidated if the probe is rerun or any of the 20 baseline files or the three new files change)
