---
phase: 2
slug: source-guard-and-header-inventory
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-19
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SAS log inspection + ODS output file existence checks |
| **Config file** | none — validation is log-based and file-presence-based |
| **Quick run command** | `findstr /b /c:"ERROR" P:\PeCAN Master Data\Gerard\data_dictionary\logs\02_source_guard.log` (exit 1 if any found) |
| **Full suite command** | Run `02_source_guard.sas` end-to-end; check log is ERROR/WARNING-free and all output datasets exist |
| **Estimated runtime** | ~5–15 minutes (dominated by XLSX reads and certutil hashing of 20 files) |

---

## Sampling Rate

- **After every task commit:** Verify the specific output dataset or file written by that task exists and has > 0 rows (SAS `PROC CONTENTS` or `PROC SQL SELECT COUNT(*)`)
- **After every plan wave:** Run full `02_source_guard.sas`; scan log for ERRORs and WARNINGs
- **Before `/gsd:verify-work`:** Full run must be ERROR/WARNING-free; all output tables must exist with expected structure
- **Max feedback latency:** ~15 minutes per wave

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 2-01-01 | 01 | 1 | PDD-02 (hash baseline) | file+log | `test -f docs/source_guard_baseline.csv` + log ERROR scan | ⬜ pending |
| 2-01-02 | 01 | 1 | PDD-02 (guard check) | log | log contains `NOTE: [02_source_guard] PASS` or ERROR on mismatch | ⬜ pending |
| 2-01-03 | 01 | 1 | PDD-02 (file metadata) | dataset | `pdd.source_inventory` exists, rowcount = 20 | ⬜ pending |
| 2-02-01 | 02 | 1 | PDD-02 (header inventory) | dataset | `pdd.header_inventory` exists, rowcount > 0 | ⬜ pending |
| 2-02-02 | 02 | 1 | PDD-02 (grain/key analysis) | dataset | `pdd.key_analysis` exists; grain column populated for all 20 files | ⬜ pending |
| 2-02-03 | 02 | 2 | PDD-02 (ID overlap) | dataset | `pdd.id_overlap` exists; spine file row present for all candidate keys | ⬜ pending |
| 2-02-04 | 02 | 2 | PDD-02 (older-copy hash compare) | dataset | `pdd.source_inventory` has `old_copy_status` column; values in {identical, different, no_older_copy} | ⬜ pending |
| 2-03-01 | 03 | 3 | PDD-02 (QC output) | file | `qc\source_inventory.xlsx` and `qc\header_matrix.xlsx` exist after ODS run | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — this phase writes new SAS programs from scratch. No test stubs or framework installation required. All verification is log-based or file/dataset existence checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| XLSX sheet list for 2018_2019_Precede_Database.xlsx is complete | PDD-02 (sheet list) | Sheet names can only be confirmed by a human with access to P: | Open the file in Excel; compare sheet list to what appears in `pdd.source_inventory` |
| Older-copy hash comparison results make sense | PDD-02 (hash comparison) | Requires human judgment about which files were expected to change | Review `old_copy_status` column in `qc\source_inventory.xlsx`; flag unexpected `different` entries to Gerard |
| PDD-D-17 and PDD-D-18 can be decided from Phase 2 output | Phase 2 done-when criterion | Requires Gerard's judgment | Review grain column and ID overlap counts; schedule decision meeting |

---

## Validation Sign-Off

- [ ] All tasks have log-scan or dataset-existence verification
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0: not required (new programs, no framework)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15 minutes per wave
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
