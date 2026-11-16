---
phase: 16
slug: name-map-extension
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-16
---

# Phase 16 — Validation Strategy

> Headless limit: nothing that reads real data runs here. Validation = static lint, pytest on committed `docs/*.csv` and synthetic fixtures, plus logs/QC returned from Gerard's SAS runs (PENDING SAS RUN).

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.3.3, ruff 0.7.1, `tools\sas_lint.py`, `sasjs lint` |
| **Config file** | `python/conftest.py` |
| **Quick run command** | `.venv\Scripts\python.exe -m pytest python\tests\test_phase16_static.py -x` |
| **Full suite command** | `sasjs lint`, `ruff check python\`, `.venv\Scripts\python.exe -m pytest python\tests` |
| **Estimated runtime** | ~60 seconds |

## Sampling Rate

- **After every task commit:** quick run; `python tools\sas_lint.py sas\<file>.sas` for SAS edits
- **After every plan wave:** full suite command
- **Before `/gsd:verify-work`:** full suite green plus Gerard's returned 16a/16b logs
- **Max feedback latency:** 90 seconds

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| MAP-01 | 16a never writes frozen map; no `04_name_map.sas` include | static | `pytest python\tests\test_phase16_static.py::test_frozen_map_untouched` | ❌ W0 | ⬜ pending |
| MAP-01 | 282 new spec rows classify offline | unit | `pytest python\tests\test_phase16_expectations.py` | ❌ W0 | ⬜ pending |
| MAP-02 | decisions_new header; no s21-s23 in Phase 4 decisions | static | `pytest python\tests\test_phase16_static.py -k decisions` | ❌ W0 | ⬜ pending |
| MAP-02 | PENDING_DECISION rows blank name; `<11` masking; KEY leftmost | unit | `pytest python\tests\test_name_map_ext_workbook.py` | ❌ W0 | ⬜ pending |
| MAP-03 | 0 collisions / 0 >32 chars across 5,077 rows | log/QC | 16a Stage 2 NOTEs (Gerard) | after SAS run | ⬜ pending |
| MAP-04 | coverage first<=last year; NO_YEAR bucket reconciles | log/QC | 16b log NOTEs (Gerard) | after SAS run | ⬜ pending |
| Crit 5 | Price sign-off still pending | static | `pytest ...::test_price_signoff_pending` | ❌ W0 | ⬜ pending |

## Wave 0 Requirements

- [ ] `python/tests/test_phase16_static.py`
- [ ] `python/tests/test_phase16_expectations.py`
- [ ] `python/tests/test_name_map_ext_workbook.py`
- [ ] `docs/name_map_decisions_new.csv` (header-only) and exchange_schema rows
- [ ] `sas/16_name_map_ext_test.sas` (synthetic; Gerard runs)

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 16a/16b SAS runs and returned logs | MAP-01..04 | No SAS or P: here | Follow `16-SAS-RUN.md` |
| Near-match decisions, Price sign-off | MAP-02 | Human decision gates | Gerard fills `docs/name_map_decisions_new.csv` |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] No watch-mode flags
- [ ] Wave 0 complete (set after 16-01 executes)

**Approval:** pending
