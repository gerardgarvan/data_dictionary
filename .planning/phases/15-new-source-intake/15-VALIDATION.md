---
phase: 15
slug: new-source-intake
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-16
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Headless limit: nothing that reads data can run on this machine (no SAS, no P:). Validation here = static lint + Python tests (synthetic fixtures and static reads of the SAS text) + the QC files from Gerard's SAS run, checked against the probe constants.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.3.3 + ruff 0.7.1 (python/requirements.txt); `tools\sas_lint.py` and `sasjs lint` for SAS; runtime SAS log assertions (`%fail_out`) on Gerard's machine |
| **Config file** | `python/conftest.py` (sys.path); no pytest.ini |
| **Quick run command** | `.venv\Scripts\python.exe tools\sas_lint.py sas\<file>.sas` and `.venv\Scripts\python.exe -m pytest python\tests\<module>.py -q` |
| **Full suite command** | `ruff check python\` ; `.venv\Scripts\python.exe -m pytest python\tests -q` ; `sasjs lint` (0 `Error ` lines) |
| **Estimated runtime** | ~15 seconds (pytest + sas_lint); `sasjs lint` ~30-60 seconds |

---

## Sampling Rate

- **After every task commit:** quick commands for the touched file (sas_lint on the edited .sas file; the plan's pytest module)
- **After every plan wave:** full suite (ruff, pytest python\tests, sasjs lint)
- **Before `/gsd:verify-work`:** full suite green here, plus Gerard's returned `logs\new_source_qc_summary.txt` showing rowcounts MATCH x3, ONE_TO_ONE PASS x3, `GATE PDD-D-29 item 3: PASS`, `GATE OLD20_UNION: PASS`
- **Max feedback latency:** 15 seconds for per-task checks (sasjs lint runs per wave)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | NEW-01, NEW-03a | unit (docs CSV content) | `.venv\Scripts\python.exe -m pytest python\tests\test_phase15_guard_static.py -q -k "new_source_files or variants or gitignore or new_baseline"` | ❌ W0 (created in task, TDD) | ⬜ pending |
| 15-01-02 | 01 | 1 | NEW-01 | static (lint + SAS text) | `.venv\Scripts\python.exe tools\sas_lint.py sas\15a_new_source_guard.sas && .venv\Scripts\python.exe -m pytest python\tests\test_phase15_guard_static.py -q` | ❌ W0 | ⬜ pending |
| 15-02-01 | 02 | 2 | NEW-02 | static | `.venv\Scripts\python.exe tools\sas_lint.py sas\15b_new_inventory_spec.sas && .venv\Scripts\python.exe -m pytest python\tests\test_phase15_spec_static.py -q` | ❌ W0 | ⬜ pending |
| 15-02-02 | 02 | 2 | NEW-03 | static (+ generated-spec test after Gerard commits the spec) | same as 15-02-01 | ❌ W0 | ⬜ pending |
| 15-03-01 | 03 | 3 | NEW-03, NEW-03a | static | `.venv\Scripts\python.exe tools\sas_lint.py sas\15c_new_import.sas && .venv\Scripts\python.exe -m pytest python\tests\test_phase15_import_static.py -q` | ❌ W0 | ⬜ pending |
| 15-03-02 | 03 | 3 | NEW-04, NEW-05 | static + exchange contract | `.venv\Scripts\python.exe tools\sas_lint.py sas\15c_new_import.sas && .venv\Scripts\python.exe -m pytest python\tests -q` | ❌ W0 | ⬜ pending |
| 15-04-01 | 04 | 1 | NEW-02, NEW-04, NEW-05 | unit (synthetic CSVs) | `.venv\Scripts\python.exe -m pytest python\tests\test_new_source_qc.py -q && ruff check python\` | ❌ W0 | ⬜ pending |
| 15-04-02 | 04 | 1 | NEW-01, NEW-05 | unit (script main, exit codes, <11 masking) | `.venv\Scripts\python.exe -m pytest python\tests -q` | ❌ W0 | ⬜ pending |
| 15-05-01 | 05 | 4 | NEW-01..NEW-05 (wiring) | static | `.venv\Scripts\python.exe tools\sas_lint.py sas\99_run_all.sas && .venv\Scripts\python.exe -m pytest python\tests -q` | ❌ W0 | ⬜ pending |
| 15-05-02 | 05 | 4 | all (handover) | doc grep | `grep -c "PENDING SAS RUN" .planning/phases/15-new-source-intake/15-SAS-RUN.md` | ❌ (created in task) | ⬜ pending |
| 15-05-03 | 05 | 4 | NEW-01..NEW-05 (runtime) | manual SAS run (checkpoint) | `.venv\Scripts\python.exe -m pytest python\tests -q` after resume; runtime evidence = Gerard's summary | n/a | ⬜ PENDING SAS RUN |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each test module is written first inside its own task (TDD, RED then GREEN), so there is no separate Wave 0 plan:

- [ ] `python/tests/test_phase15_guard_static.py` — docs seeds, .gitignore exceptions, 15a approval gate / no write to old baseline (15-01)
- [ ] `python/tests/test_phase15_spec_static.py` — 15b encodings, matrix layout, spec header; generated-spec checks skip until the spec is committed (15-02)
- [ ] `python/tests/test_phase15_import_static.py` — 15c names (`pdd.nsrc_`), gates, exports-before-gates, exchange contract (15-03)
- [ ] `python/tests/test_new_source_qc.py` — QC writer: KEY leftmost, UF header fill, (no data), `<11` masking, exit codes (15-04)
- [ ] `python/tests/test_phase15_wiring_static.py` — 99_run_all token 15 and block order; run_pipeline.cmd Phase 15 block (15-05)
- Framework install: none (pytest/ruff pinned in python/requirements.txt; sasjs CLI present on this machine)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 20-file baseline still matches; new baseline seeded only with approval | NEW-01 | Needs SAS + P: (certutil over source files) | 15-SAS-RUN.md Step 2; log lines `PASS -- all 20 ...`, then `PENDING DECISION`, then after approval `PASS -- all 3 new-file ...` |
| Header matrix 3 files x 94 headers | NEW-02 | Reads source files | 15-SAS-RUN.md Step 3; summary/HEADER_MATRIX sheet |
| Import with wlatin1 for s22/s23, row counts 10,772 / 13,029 / 12,689, no truncation | NEW-03 | Reads source files | Step 1 (scan_source_encoding.py) and Step 4; ROWCOUNTS sheet all MATCH |
| Type changes reported; variants listed | NEW-03a | Needs pdd.src_s01..s20 | TYPE_CHANGES and VARIANTS sheets |
| 1:1 per case | NEW-04 | Reads imported data | ONE_TO_ONE sheet PASS x3 |
| Era overlap and pairwise gate | NEW-05 | Reads imported data | OVERLAP sheet; summary `GATE PDD-D-29 item 3: PASS`, `GATE OLD20_UNION: PASS` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (each test module is created by its own TDD task)
- [x] No watch-mode flags
- [x] Feedback latency < 15s (per-task commands)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (runtime evidence PENDING SAS RUN)
