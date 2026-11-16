---
phase: 6
slug: distribution-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-26
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SAS macro test (tests/06_profile_test.sas) + pytest (python/tests/) |
| **Config file** | none — SAS standalone script; pytest.ini already exists |
| **Quick run command** | `python -m pytest python/tests -q` |
| **Full suite command** | `python -m pytest python/tests -q && python tools/sas_lint.py sas/06_profile_macros.sas` |
| **Estimated runtime** | ~5 seconds (pytest); SAS test requires SAS 9.4 on target machine |

---

## Sampling Rate

- **After every task commit:** Run `python -m pytest python/tests -q`
- **After every plan wave:** Run full suite + `python tools/sas_lint.py sas/06_profile_macros.sas`
- **Before `/gsd:verify-work`:** Full suite must be green; SAS test SUMMARY failed=0
- **Max feedback latency:** ~5 seconds (Python); SAS test run separately on SAS machine

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | PDD-06-R01 | unit | `sas_lint.py sas/06_profile_macros.sas` | ❌ W0 | ⬜ pending |
| 6-01-02 | 01 | 1 | PDD-06-R02 | unit | `tests/06_profile_test.sas` (TC-01 classification) | ❌ W0 | ⬜ pending |
| 6-01-03 | 01 | 1 | PDD-06-R03 | unit | `tests/06_profile_test.sas` (TC-02 schema) | ❌ W0 | ⬜ pending |
| 6-02-01 | 02 | 2 | PDD-06-R04 | integration | `tests/06_profile_test.sas` (TC-03 PROC FREQ match) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/06_profile_test.sas` — stubs for TC-01 (classification), TC-02 (schema), TC-03 (PROC FREQ match), TC-04 (reconciliation assert), TC-05 (small_cell_flag), TC-06 (exclusions), TC-07 (DATE tier), TC-08 (100% missing var)

*Existing infrastructure covers Python/pytest; SAS test file is the only new artifact.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PROC FREQ match on pdd.pcnr live data | PDD-06-R04 | Requires P: drive access; not available in CI | Run `sas -sysin tests/06_profile_test.sas` on SAS machine; check SUMMARY failed=0 |
| Exchange CSV written to P:\...\exchange\ | PDD-06-R03 | P: drive not available in dev | Check file exists after live run; open in Excel and verify columns |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
