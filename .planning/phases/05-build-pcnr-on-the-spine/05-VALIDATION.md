---
phase: 5
slug: build-pcnr-on-the-spine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-21
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (python/tests/) + SAS log assertion macros |
| **Config file** | pytest.ini or pyproject.toml (existing) |
| **Quick run command** | `ruff check python\ && pytest python\tests` |
| **Full suite command** | `ruff check python\ && pytest python\tests && python tools\sas_lint.py sas\05_build_pcnr.sas && sasjs lint` |
| **Estimated runtime** | ~30 seconds (pytest) + ~5 min (SAS run) |

---

## Sampling Rate

- **After every task commit:** Run `ruff check python\ && pytest python\tests`
- **After every plan wave:** Run full suite including SAS lint
- **Before `/gsd:verify-work`:** Full suite must be green; `pdd.pcnr` row count = 41,150
- **Max feedback latency:** 60 seconds (Python gates); SAS run is manual verification

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 5-??-?? | TBD | TBD | PDD-D-02 | lint | `python tools\sas_lint.py sas\05_build_pcnr.sas` | ❌ W0 | ⬜ pending |
| 5-??-?? | TBD | TBD | PDD-D-05 | manual | SAS log: row count = 41,150 | N/A | ⬜ pending |
| 5-??-?? | TBD | TBD | D-19 | manual | `exchange\pcnr_spine_coverage.csv` exists | ❌ W0 | ⬜ pending |
| 5-??-?? | TBD | TBD | D-16b | unit | `pytest python\tests\test_write_pcnr_qc.py` | ❌ W0 | ⬜ pending |
| 5-??-?? | TBD | TBD | D-20 | manual | SAS log: 0 CLOCK columns | N/A | ⬜ pending |

*Task IDs and plan numbers to be filled in after planning. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `sas/05_build_pcnr.sas` — stub file passes `sasjs lint` and `sas_lint.py` with zero errors
- [ ] `python/scripts/write_pcnr_qc.py` — stub (argparse skeleton, assert_input, write_workbook, verify_workbook pattern from write_name_map_review.py)
- [ ] `python/tests/test_write_pcnr_qc.py` — at minimum one test asserting KEY sheet is first and CONFLICT_DETAIL is capped at 5,000 rows
- [ ] `docs/pcnr_source_priority.csv` — generated with s01=rank 1 … s20=rank 20
- [ ] `docs/pcnr_source_override.csv` — empty file with header (pcnr_name, s_code)
- [ ] `exchange/` directory exists (already from Phase 4)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| pdd.pcnr row count = 41,150 | PDD-D-01 | SAS dataset on P: | Check SAS log: NOTE: The data set PDD.PCNR has 41150 observations |
| 0 CLOCK columns in pdd.pcnr | D-21 | Requires SAS PROC CONTENTS cross-ref to docs/s06_column_class.csv | Run assertion macro; inspect SAS log NOTE |
| No blank norm_psid in spine | Domain done criterion | Requires SAS data check | SAS log NOTE: 0 blank norm_psid in pdd.src_s09 |
| Variable labels = representative original_header | Domain done criterion | PROC CONTENTS visual check | Review PROC CONTENTS output for first 20 variables |
| s04/s05 contribute 0 PCNR_ variables | D-18 | SAS log assertion | SAS log NOTE confirms 0 rows from name_map check |
| SPINE_COVERAGE sheet in qc\pcnr_qc.xlsx | D-19 | File existence + sheet content | Open workbook, verify SPINE_COVERAGE sheet has one row per source |
| CONFLICT_DETAIL capped at 5,000 rows | D-16b | File inspection | Open CONFLICT_DETAIL sheet, confirm ≤5,000 rows; KEY sheet references pdd.qc_pcnr_conflicts |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s (Python gates)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
