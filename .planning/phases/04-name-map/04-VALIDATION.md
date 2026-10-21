---
phase: 4
slug: name-map
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-21
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (python\tests) + SAS log inspection |
| **Config file** | pytest.ini or pyproject.toml (existing) |
| **Quick run command** | `pytest python\tests -q` |
| **Full suite command** | `ruff check python\ && pytest python\tests` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `pytest python\tests -q`
- **After every plan wave:** Run `ruff check python\ && pytest python\tests`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 4-02-01 | 02 | 2 | D-01/D-04 | SAS log check | `grep "NOTE: 4795 rows" "P:\PeCAN Master Data\Gerard\data_dictionary\logs\99_run_all.log"` (pipeline) or `04_name_map.log` (standalone) | ❌ W0 | ⬜ pending |
| 4-02-02 | 02 | 2 | D-08 | SAS log check | `grep "NOTE: D-08" "P:\PeCAN Master Data\Gerard\data_dictionary\logs\04_name_map.log"` | ❌ W0 | ⬜ pending |
| 4-02-03 | 02 | 2 | D-04 s06 | SAS log check | `grep "NOTE: EXCLUDED_CLK=2747" "P:\PeCAN Master Data\Gerard\data_dictionary\logs\04_name_map.log"` | ❌ W0 | ⬜ pending |
| 4-02-04 | 02 | 2 | D-02 | SAS log check | `grep "NOTE: 0 empty-clean headers" "P:\PeCAN Master Data\Gerard\data_dictionary\logs\04_name_map.log"` | ❌ W0 | ⬜ pending |
| 4-02-05 | 02 | 2 | D-05 | SAS log check | `grep "NOTE: Stage 2 passed" "P:\PeCAN Master Data\Gerard\data_dictionary\logs\04_name_map.log"` | ❌ W0 | ⬜ pending |
| 4-03-01 | 03 | 2 | D-09 | pytest | `pytest python\tests\test_name_map_workbook.py -q` | ❌ W0 | ⬜ pending |
| 4-04-01 | 04 | 2 | D-10 | SAS log + file | `python tools\sas_lint.py sas\04_name_map.sas` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `P:\PeCAN Master Data\Gerard\data_dictionary\logs\04_name_map.log` — created by standalone SAS run; pipeline writes to `99_run_all.log` instead
- [ ] `python\tests\test_name_map_workbook.py` — stubs verifying sheet names and row counts
- [ ] `docs\name_map_decisions.csv` — header-only file (empty); must exist before SAS run
- [ ] `docs\name_abbrev.csv` — 7-row abbreviation seed (D-03 standard abbreviations)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Near-match count ≤ 200 | D-06 | Count depends on real data | Check SAS log for "near-match pair count"; if >200 SAS %fail_out stops the run |
| Gerard review of name_map_review.xlsx | D-10 item 7 | Human judgment | Open qc\name_map_review.xlsx; review NEAR_MATCHES and NAME_MAP_COLLISIONS sheets |
| Price approval of naming conventions | D-10 item 8 | Stakeholder sign-off | Send naming_conventions section of NAME_MAP sheet to Price; record approval date |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
