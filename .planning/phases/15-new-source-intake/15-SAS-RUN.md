# Phase 15 SAS run sheet (for Gerard)

**Status:** 15a done (baseline approved and committed). 15b done (spec committed). 15c run 1 stopped at PDD-D-29 item 3 (s22-s23 = 142 shared cases), now resolved by PDD-D-30. **Next: rerun 15c (Step 4), then `run_pipeline.cmd 15` (Step 5).**
**Decision:** PDD-D-30 DECIDED (s22 wins, s23 gap-fills, applied in Phase 18). Any other gate that fires is still PENDING DECISION.

Claude has no SAS and no P: drive and chose nothing at any gate.

## Before you start
1. Sync branch `pdd-2018-2025-api` to the SAS machine.
2. `.venv\Scripts\python.exe -m pip install -r python\requirements.txt`
3. A v1.0 run must exist on P: (`pdd.src_s01..s20`, `pdd.src_s09`).

SAS command used below (use SAS_EXE / SAS_CFG from `config.local.cmd` if set):
`"C:\Program Files\SAS94\SASFoundation\9.4\sas.exe" -sysin "C:\data_dictionary\sas\<program>.sas" -config "C:\Program Files\SAS94\SASFoundation\9.4\nls\u8\sasv9.cfg" -encoding utf8 -nosplash -icon`

## Step 1 - independent encoding check
`.venv\Scripts\python.exe -I tools\scan_source_encoding.py` (default source dir).

Expected: `OK: 2023_X_MASTER_DATASET_20261016.csv`; `ENCODING ERROR` lines for the 2024 and 2025 files (probe: 18 and 26 non-UTF-8 lines).
Bring back: number of ENCODING ERROR lines per new file only (no hex).
If 2023 shows errors, or 2024/2025 show none: **PENDING DECISION (spec encoding)**. Stop.

## Step 2 - 15a standalone, first run
Program: `15a_new_source_guard.sas`.

Expected log: `PASS -- all 20 SHA-256 values ...`, then
`ERROR: [15a_new_source_guard] PENDING DECISION -- new-file baseline not approved`, and `qc\new_source_hashes_proposed.csv`.

**Decision gate - PENDING DECISION (Gerard):**
- (a) Approve: confirm the three filenames in the proposed file are the 2023/2024/2025 files listed in `docs/new_source_files.csv`, then rerun with `-set PDD_APPROVE_NEW_BASELINE 1`. Expected NOTE: `new baseline seeded by explicit approval`. Commit `docs/source_guard_baseline_new.csv`.
- (b) Hold: do not approve (for example, files expected to be re-delivered). Phase 15 stays blocked.

Evidence: probe file table units 19-21 (rows, columns, modified dates). Claude does not choose.

After approval, rerun 15a without the flag. Expected: `PASS -- all 3 new-file SHA-256 values match`.

## Step 3 - 15b standalone
Program: `15b_new_inventory_spec.sas`.

Expected NOTEs: inventory 94 headers per file; `docs\import_spec_new_generated.csv written`.
Commit `docs/import_spec_new_generated.csv`.
Bring back `logs\15b_new_inventory_spec.log` (ERROR/WARNING lines and the Braden header NOTE lines only) so Claude can complete the two `Braden Sensory P` rows in `docs/new_source_header_variants.csv`.

## Step 4 - 15c standalone
Program: `15c_new_import.sas`.

Expected: row counts MATCH (10,772 / 13,029 / 12,689), 1:1 PASS for s21/s22/s23, `PASS -- s21-s22 0, s21-s23 0, s22-s23 142 per PDD-D-30`.

Rerun after PDD-D-30: the overlap gate now passes only when the s22-s23 shared count, case-ID range and MRN/encounter equality match `docs/new_overlap_decisions.csv` (142, 65370-65511, 0 mismatches). Expected NOTE: `PASS -- s21-s22 0, s21-s23 0, s22-s23 142 per PDD-D-30`. New file: `exchange\new_overlap_conflicts.csv` (counts per differing column). `sas/15d_overlap_diag.sas` is a committed one-off diagnostic (it produced `.planning/schemas/overlap_s22_s23_20261116.md`) and is not part of the pipeline run.

Gates that may fire, each **PENDING DECISION**:
- NEW-04 not 1:1: PDD-D-17 extension.
- PDD-D-29 item 3: any shared IDs for s21-s22 or s21-s23, or an s22-s23 overlap that differs from `docs/new_overlap_decisions.csv` (do not stack). The 142-case s22-s23 overlap itself is DECIDED (PDD-D-30). Evidence: the pair counts in `exchange\new_overlap.csv`.
- OLD20_UNION overlap (reopen PDD-D-25).

The `ERROR:` gate line now lands in the program's own log file as well as the SAS Log window. If a gate fires, run `.venv\Scripts\python.exe python\scripts\write_new_source_qc.py --allow-partial` and bring back the summary text.

## Step 5 - pipeline
`run_pipeline.cmd 15`. Expected: exit 0, `Pipeline PASSED`, `qc\new_source_intake.xlsx` (KEY sheet leftmost).

## Bring back
Paste into the Phase 15 SUMMARY (counts 1-10 written `<11`):
- `logs\new_source_qc_summary.txt` (already masked)
- ERROR/WARNING line counts from `logs\99_run_all.log`, the 15a/15b/15c logs, and `tools\check_test_log.ps1` output
- the committed `docs/source_guard_baseline_new.csv` and `docs/import_spec_new_generated.csv`

Do not paste lines from `qc\` or `exchange\` files.

## Assumptions (headless run)
| ID | Assumption | Plan |
|----|------------|------|
| A1 | s21=2023, s22=2024, s23=2025; probe unit numbers 19-21 are not s-codes | 15-01 |
| A2 | Baseline approval is env var `PDD_APPROVE_NEW_BASELINE=1`; Gerard approves, never Claude | 15-01 |
| A3 | Existing 20-file programs (02, 03, 03a, 05) are not modified | 15-01 |
| A4 | Both 15c gates write QC CSVs then `%fail_out`; the old-source gate also fires on a non-zero spine count | 15-03 |
| A5 | Non-ASCII counts after transcoding are informational, not a guard | 15-03 |
| A6 | QC is exchange CSVs plus a Python-written `qc\new_source_intake.xlsx` | 15-04 |
| A7 | 2024 and 2025 files are wlatin1, 2023 is UTF-8 (probe); confirmed by Step 1 | 15-02 |
| A8 | `tools\scan_source_encoding.py` is used unchanged as an independent check | 15-05 |
| A9 | Probe `Num 8` guesses are provisional; the best32. parse probe decides final N vs C | 15-02 |
| A10 | `findstr /i "\<15\>"` does not match the `\<5\>` block (read, not run) | 15-05 |
| A11 | Datasets are `pdd.nsrc_s21..s23` so the Phase 3 `SRC_S__` norm_psid loop never sweeps them | 15-03 |
