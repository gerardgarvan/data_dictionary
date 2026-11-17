# Phase 17: PECAN_ID - Context

**Gathered:** 2026-11-17 (headless run)
**Status:** Ready for planning
**Requirements:** PID-01..PID-08 (brief `.planning/MILESTONE_BRIEF_2018_2025.md`)

<domain>
## Phase Boundary
Give every 2018-2025 surgery a `PECAN_ID` and `PECAN_ID_KEY_ERA` through the append-only `pdd.pecan_id_registry`; apply PDD-D-30 before ID assignment; ship a tested-but-not-run `sas/pecan_id_link.sas`. Phase 17 does NOT build the combined PCNR_ dataset (Phase 18, DD-01); it produces the surgery-level key table `pdd.pecan_id_case_map` that Phase 18 joins on `norm_psid`.
</domain>

<decisions>
## Locked (not reopened)
- PDD-D-26, D-28: K1 = master-merge `pecan_ID` seeded once from `g.pecan_id_xwalk` (read-only); K2 = 1000000 + rank, rank = smallest numeric PRECEDE study number per MRN, MRN tie-break; lookups on (ENCRYPTED_MRN, KEY_ERA); no ID renumbered or reused; backup on every change; abort if registry differs from latest backup before append.
- PDD-D-29 item 1: 2023-2025 case IDs use the D-19 rule (`pdd_norm_psid`, column `norm_psid`).
- PDD-D-30: 142 shared s22 x s23 cases are the same surgeries; s22 (2024) wins, s23 fills blanks; YEAR 2024. For Phase 17 only the case set matters: each normalized case ID is one surgery, counted once, with the s22 MRN (probe: MRN equal on all 142). The value-level gap-fill stays in Phase 18; Phase 17 additionally fills a blank s22 MRN from s23 (gap-fill rule) and reports it.
- PDD-D-31 etc. unrelated.

## Claude's Discretion (assumptions, headless run)
- A1. Approval option for a new baseline: global macro variable `PDD_APPROVE_NEW_BASELINE` (default 0). Needed only when the registry does not exist AND the K1 seed is requested, or when the registry differs from its latest backup; any value other than 1 aborts with counts. Never defaulted to 1; Gerard sets it in the run command.
- A2. Datasets: `pdd.pecan_id_registry`, `pdd.pecan_id_case_map`, `pdd.qc_pecan_id_*`; backups `&out_root.\backup\pecan_id_registry_<yyyymmdd_hhmmss>.sas7bdat`; QC CSVs to `&qc_path.`.
- A3. K1 era = cases from `pdd.src_s09` (spine, 41,150 rows per probe), K2 era = `pdd.nsrc_s21..s23` (10,772 / 13,029 / 12,689). Column `ENCRYPTED_MRN` (probe); case key `norm_psid`.
- A4. Blank or `NULL` (case-insensitive, after strip) MRN gets no PECAN_ID (matches program 20); these cases appear in `pecan_id_case_map` with missing PECAN_ID and `MRN_STATUS='NO_MRN'`; counted in QC, not a gate failure. Any case with a usable MRN and no PECAN_ID IS a gate failure.
- A5. PID-07 summary uses `pdd.pecan_id_case_map` only; counts 1-10 are shown as `<11` in anything written to `.planning/`.
- A6. Python style tests as in Phases 15-16 (`python/tests/test_phase17_*_static.py`), no data.
- A7. Planning tools: `gsd-tools` state commands not used (v2.0 frontmatter kept, as Phases 15-16). Research/checker subagents skipped for budget (USD cap); plans self-checked against PID-01..08 (traceability table in 17-VALIDATION.md).
- A8. Spine MRN level count differs between sources: brief/D-28 say 31,136 distinct non-missing, probe unit 9 (spine) lists 31,137 levels (41,149 non-missing of 41,150). The gate therefore compares the registry to the spine set computed at run time and reports both numbers; no constant is hard-coded.

## PROBE REQUESTS (PENDING SAS RUN)
- PR-1. `g.pecan_id_xwalk` has never been probed (probe covers CSV/XLSX sources only). Needed: dataset exists, row count, variable names/types/lengths (D-28 says ENCRYPTED_MRN $40 but the spine MRN is length 41 and K2 up to 51, so truncation risk must be checked), whether pecan_ID is numeric, min/max, count of blank/NULL MRN. Plan 17-02 includes `sas/17_probe_xwalk.sas` (PROC CONTENTS + counts only, no values) to run first. Until it is run, 17-02 seed program asserts length instead of assuming it.
- PR-2. NULL-sentinel MRNs in s21-s23: probe placeholders column is 0 for MRN in units 19-21, so none expected; the K2 program counts and reports them anyway.
</decisions>

<canonical_refs>
- `.planning/MILESTONE_BRIEF_2018_2025.md` PID-01..08, DD-01
- `docs/DECISIONS.md` PDD-D-26, 28, 29, 30
- `docs/reference/20_pecan_id.sas` (backup/append pattern, ranking, guards)
- `.planning/schemas/probe_master_data_20261116.md` (units 9, 19-21; ID-like table), `.planning/schemas/overlap_s22_s23_20261116.md`
- `sas/00_config.sas` (`pdd_norm_psid`, paths), `sas/15c_new_import.sas` (nsrc datasets), `sas/16_name_map_ext_test.sas` (test pattern), `tools/sas_lint.py` (C1-C32)
</canonical_refs>
