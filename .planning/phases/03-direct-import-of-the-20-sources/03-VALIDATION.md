---
phase: 3
slug: direct-import-of-the-20-sources
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-19
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SAS log assertions via `%put NOTE` / `%fail_out` / `%_note_written_ds` (no external test runner) |
| **Config file** | none — inline assertion macros per program (consistent with Phase 2) |
| **Quick run command** | `sas -config "C:\Program Files\SAS94\SASFoundation\9.4\nls\u8\sasv9.cfg" -sysin "C:\data_dictionary\sas\03a_build_spec.sas"` or `03_import.sas` |
| **Full suite command** | `run_pipeline.cmd` (calls 99_run_all.sas which chains all phases) |
| **Estimated runtime** | ~5–15 min (raw pre-pass over 16 CSVs; s06 xlsx 3,987 cols) |

---

## Sampling Rate

- **After every task commit:** Check SAS log for zero ERRORs; run `%_note_written_ds` assertions
- **After every plan wave:** Run the wave's programs standalone; verify output datasets exist with expected row counts
- **Before `/gsd:verify-work`:** Full `run_pipeline.cmd` must complete with zero ERRORs
- **Max feedback latency:** One full program run (~5–15 min) per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 03-A-01 | 03a | 1 | PDD-03-R01 | smoke | `%if not %sysfunc(exist(pdd.qc_s18_dup)) %then %fail_out(...)` | ⬜ pending |
| 03-A-02 | 03a | 1 | PDD-03-R09 | smoke | raw pre-pass: `pdd.raw_char_lengths` exists with ≥1 row per CSV file_code | ⬜ pending |
| 03-A-03 | 03a | 1 | PDD-03-R09 | unit | `docs\import_spec.csv` exists; columns: file_code, col_order, orig_col_name, sas_name, sas_type, length, informat, format, notes | ⬜ pending |
| 03-A-04 | 03a | 1 | PDD-03-R02 | unit | PRECEDE_STUDY_ID rows in import_spec.csv have sas_type='C' for all 20 file_codes | ⬜ pending |
| 03-B-01 | 03 | 2 | PDD-03-R03 | smoke | `%check_encoding` passes; log contains "sysencoding check passed (UTF-8 confirmed)" | ⬜ pending |
| 03-B-02 | 03 | 2 | PDD-03-R09 | smoke | `fileexist("C:\data_dictionary\docs\import_spec.csv")` = 1 at program start | ⬜ pending |
| 03-B-03 | 03 | 2 | PDD-03-R01 | smoke | `pdd.src_s01`…`pdd.src_s20` all exist after run; `%_note_written_ds` for each | ⬜ pending |
| 03-B-04 | 03 | 2 | PDD-03-R05 | unit | PROC SQL: row counts in pdd.src_s* match pdd.source_inventory nrows for matching file_codes (within tolerance for s18 −2, s19 −dropped) | ⬜ pending |
| 03-B-05 | 03 | 2 | PDD-03-R06 | unit | `proc sql; select count(*) from pdd.src_s01;` = 41,423 (±0); `pdd.src_s08` nrows = 3,456 | ⬜ pending |
| 03-B-06 | 03 | 2 | PDD-03-R04 | unit | s19 log: "kept N rows / dropped M rows" NOTE present; kept + dropped = Sheet1 total from pdd.source_inventory | ⬜ pending |
| 03-B-07 | 03 | 2 | PDD-03-R08 | smoke | `pdd.qc_s06_groups` exists with ≥1 row; `qc\s06_column_groups.xlsx` exists (fileexist) | ⬜ pending |
| 03-B-08 | 03 | 2 | PDD-03-R10 | unit | `pdd.src_s17` has column `enc_for_linkage`; `ENCRYPTED_ENCOUNTER` also present unchanged | ⬜ pending |
| 03-B-09 | 03 | 2 | PDD-03-R07 | smoke | `pdd.src_s04` and `pdd.src_s05` exist; no variable names starting with `PCNR_` in either dataset | ⬜ pending |
| 03-C-01 | 03 | 3 | PDD-03-R19 | unit | `%pdd_norm_psid` applied to all 20 datasets; norm_psid column exists in each; `_ndis = 0` assertion passes | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — test infrastructure is inline SAS assertions consistent with Phase 2 style. No external
test files or framework installation needed. Patterns (`%fail_out`, `%_note_written_ds`) are
already defined in existing programs and must be copied verbatim into 03a / 03_import.sas.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `Base_Procedure_1` esophagectomy descriptions render correctly (UTF-8 characters intact) | PDD-03-R03 | Requires human reading of cell content | After run: `proc print data=pdd.src_s07(obs=20); var PRECEDE_STUDY_ID Base_Procedure_1; run;` — verify multibyte chars not garbled (should show ≥ one row with non-ASCII in Base_Procedure_1) |
| import_spec.csv reviewed and overrides applied by Gerard before 03_import.sas runs | PDD-03-R09 | Human sign-off step | Gerard reviews `docs\import_spec.csv` for correctness; edits any misclassified columns; commits changes |
| s06 column-group profile reviewed | PDD-D-21 | Human decision on PCNR_ scope | Gerard reviews `qc\s06_column_groups.xlsx`; marks groups for Phase 4-5 inclusion |
| s18 dup rows reviewed | s18 decision | Human review of `pdd.qc_s18_dup` | Gerard inspects 2 rows and decides Phase 5 handling |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0: no items needed (inline assertions only)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15 min per full program run
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
