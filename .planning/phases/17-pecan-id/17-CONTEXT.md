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
- **PDD-D-32 (Gerard, 2026-11-17, supersedes the K1 part of D-28):** K1 PECAN_ID = existing `pecan_ID` from `g.MASTER_DATA_HARMONIZED`, taken row by row through a surgery-level key (spine `pdd.src_s09` to the harmonized dataset; key confirmed by probe PR-3), NOT by MRN lookup in `g.pecan_id_xwalk`; IDs unchanged. Patients with two K1 IDs are kept as is and recorded in the append-only link table `pdd.pecan_id_dup_link` (`pecan_id_a`, `pecan_id_b`, `link_basis`, `n_surgeries_a`, `n_surgeries_b`, `decided_on`); no merge now. Evidence: probe_xwalk_20261117.md, probe_xwalk2_20261117.md (summarized in docs/DECISIONS.md).
- PDD-D-26, D-28 (K1 seed wording superseded): K2 = 1000000 + rank, rank = smallest numeric PRECEDE study number per MRN, MRN tie-break; lookups on (ENCRYPTED_MRN, KEY_ERA); no ID renumbered or reused; backup on every change; abort if registry differs from latest backup before append.
- PDD-D-29 item 1: 2023-2025 case IDs use the D-19 rule (`pdd_norm_psid`, column `norm_psid`).
- PDD-D-30: 142 shared s22 x s23 cases are the same surgeries; s22 (2024) wins, s23 fills blanks; YEAR 2024. For Phase 17 only the case set matters: each normalized case ID is one surgery, counted once, with the s22 MRN (probe: MRN equal on all 142). The value-level gap-fill stays in Phase 18; Phase 17 additionally fills a blank s22 MRN from s23 (gap-fill rule) and reports it.
- PDD-D-31 etc. unrelated.

## Claude's Discretion (assumptions, headless run)
- A1. Approval option for a new baseline: global macro variable `PDD_APPROVE_NEW_BASELINE` (default 0). Needed only when the registry does not exist AND the K1 seed is requested, or when the registry differs from its latest backup; any value other than 1 aborts with counts. Never defaulted to 1; Gerard sets it in the run command.
- A2. Datasets: `pdd.pecan_id_registry`, `pdd.pecan_id_case_map`, `pdd.qc_pecan_id_*`; backups `&out_root.\backup\pecan_id_registry_<yyyymmdd_hhmmss>.sas7bdat`; QC CSVs to `&qc_path.`.
- A3. K1 era = cases from `pdd.src_s09` (spine, 41,150 rows per probe; one K1 case per spine row, ID from the harmonized row), K2 era = `pdd.nsrc_s21..s23` (10,772 / 13,029 / 12,689). Column `ENCRYPTED_MRN` (probe); case key `norm_psid`.
- A4. K2: blank or `NULL` (case-insensitive, after strip) MRN gets no PECAN_ID (matches program 20); these cases appear in `pecan_id_case_map` with missing PECAN_ID and `MRN_STATUS='NO_MRN'`; counted in QC, not a gate failure. K1 (PDD-D-32): the ID comes from the harmonized row, so the one spine row with a blank MRN keeps its `pecan_ID` and gets `MRN_STATUS='NO_MRN'`. The K1 gate reports the blank spine MRN row count on its own line (`BLANK_SPINE_MRN_ROWS`, probe: 1 row; computed at run time). Any K1 row with no harmonized match, a missing `pecan_ID`, or more than one harmonized match IS a gate failure; any K2 case with a usable MRN and no PECAN_ID IS a gate failure.
- A5. PID-07 summary uses `pdd.pecan_id_case_map` only; counts 1-10 are shown as `<11` in anything written to `.planning/`.
- A6. Python style tests as in Phases 15-16 (`python/tests/test_phase17_*_static.py`), no data.
- A7. Planning tools: `gsd-tools` state commands not used (v2.0 frontmatter kept, as Phases 15-16). Research/checker subagents skipped for budget (USD cap); plans self-checked against PID-01..08 (traceability table in 17-VALIDATION.md).
- A8. Spine MRN level count differs between sources: brief/D-28 say 31,136 distinct non-missing, probe unit 9 (spine) lists 31,137 levels (41,149 non-missing of 41,150). Counts are computed at run time and reported; none is hard-coded (41,150 and 1,895 below are expected values written in the plans for orientation only, not in code).
- A9 (PDD-D-32). K1 join key: the key PR-3 names as one-to-one for all 41,150 spine rows, passed to the programs through global macro variables `PDD_K1_SPINE_KEY`, `PDD_K1_HARM_KEY`, `PDD_K1_KEY_MODE` (raw or norm; norm = `pdd_norm_psid`). Until PR-3 is run and reviewed, 17a refuses to run (PENDING SAS RUN). Row order is allowed only if PR-3 finds no real key and the two datasets have equal rows; then it is a PENDING DECISION, not applied.
- A10 (PDD-D-32). K1 gate (QC written first, abort on failure): spine rows = harmonized rows = matched rows (expected 41,150), every spine row matches exactly one harmonized row, 0 spine rows match 0, 0 rows match more than one, 0 missing `pecan_ID`.
- A11 (PDD-D-32). Dup pairs: a spine MRN mapped to more than one distinct `pecan_ID` defines a pair per two IDs (`pecan_id_a` < `pecan_id_b` numerically). `link_basis='SPINE_MRN_MULTI_ID'`, `n_surgeries_a/b` = spine rows carrying each ID at the time of the append, `decided_on` = run date the pair was recorded (it records the PDD-D-32 decision date context, no merge is made). Append-only: only pairs not yet in the table are appended; existing rows are never changed or deleted; dated backup before every append; second run appends 0. The gate reports the pair count at run time (expected near 1,895, not hard-coded).
- A12 (PDD-D-32). Registry K1 rows: one row per distinct K1 `pecan_ID`, `ENCRYPTED_MRN` = the usable spine MRN of the surgeries carrying that ID, `SOURCE='k1_harmonized_join'`. K1 uniqueness is on PECAN_ID (the (MRN, K1) pair is NOT unique for dup patients, by design: that is exactly what the link table records); K2 uniqueness stays on (MRN, K2) and PECAN_ID. K2 lookups unchanged. `g.pecan_id_xwalk` is no longer an input to any Phase 17 program (only the probes read it).
- A13 (PDD-D-32). PENDING DECISION only if PR-3 shows it, not applied: (a) a pecan_ID that has more than one distinct spine MRN (registry K1 row needs one MRN; probe section 2 reports the count), (b) a pecan_ID that occurs only on blank-MRN spine rows (no usable MRN for its registry row). The K1 gate counts both and lists them as `PENDING DECISION` in QC when above 0; the case map still carries the ID.

## PROBE REQUESTS
- PR-1 and PR-2: RUN 2026-11-17 (`probe_xwalk_20261117.md`, `probe_xwalk2_20261117.md`); findings drove PDD-D-32. Original PR-1 text kept below.
- PR-3 (PENDING SAS RUN): `sas/17_probe_xwalk3.sas` writes `.planning/schemas/probe_xwalk3_<date>.md`: candidate surgery keys present in both `pdd.src_s09` and `g.master_data_harmonized` (norm_psid, PSID/surgery/case/ID columns via dictionary.columns, row order last) with distinct counts, matches 0/1/more; the key giving 41,150 one-to-one; spine MRN to pecan_ID histogram; pecan_IDs with more than one spine MRN; implied dup pairs; dup pairs by spine YEAR; YEAR of the unmatched MRNs; blank spine MRN rows. Plans 17-02/03 take the key name from this report.
- PR-1 (original). `g.pecan_id_xwalk` had never been probed (probe covers CSV/XLSX sources only). Needed: dataset exists, row count, variable names/types/lengths (D-28 says ENCRYPTED_MRN $40 but the spine MRN is length 41 and K2 up to 51, so truncation risk must be checked), whether pecan_ID is numeric, min/max, count of blank/NULL MRN. Plan 17-02 includes `sas/17_probe_xwalk.sas` (PROC CONTENTS + counts only, no values) to run first. Until it is run, 17-02 seed program asserts length instead of assuming it.
- PR-2. NULL-sentinel MRNs in s21-s23: probe placeholders column is 0 for MRN in units 19-21, so none expected; the K2 program counts and reports them anyway.
</decisions>

<canonical_refs>
- `.planning/MILESTONE_BRIEF_2018_2025.md` PID-01..08, DD-01
- `docs/DECISIONS.md` PDD-D-26, 28, 29, 30
- `docs/reference/20_pecan_id.sas` (backup/append pattern, ranking, guards)
- `.planning/schemas/probe_master_data_20261116.md` (units 9, 19-21; ID-like table), `.planning/schemas/overlap_s22_s23_20261116.md`
- `sas/00_config.sas` (`pdd_norm_psid`, paths), `sas/15c_new_import.sas` (nsrc datasets), `sas/16_name_map_ext_test.sas` (test pattern), `tools/sas_lint.py` (C1-C32)
</canonical_refs>
