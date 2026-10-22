# Phase 5: Build PCNR_ on the spine — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-21
**Phase:** 05-build-pcnr-on-the-spine
**Areas discussed:** D-15 gap-fill tie-break, D-16 per-cell source flag, s04/s05 Phase 5 role, QC output path, type-conflict rule

---

## D-15: Gap-fill tie-break order

| Option | Description | Selected |
|--------|-------------|----------|
| File order s01→s20 (skip spine) | Deterministic, documentable, matches PROJECT.md source order | ✓ |
| Newest-file wins | Date-parsed from filename; harder to audit | |
| Per-variable specification | Gerard specifies in CSV; full control but high manual effort | |
| Any non-missing wins | Same as option 1 in practice | |

**User's choice:** File order s01→s20 (skipping s09), stored in `docs/pcnr_source_priority.csv` so it can be changed without code edits. Disagreeing multi-source gap-fill goes to conflicts QC. Agreeing values are not conflicts. Optional per-variable pin via `docs/pcnr_source_override.csv` (empty by default).

---

## D-16: Per-cell source flag

| Option | Description | Selected |
|--------|-------------|----------|
| QC-only (no extra columns in pdd.pcnr) | pdd.pcnr stays 1,299 columns; provenance in QC datasets | ✓ |
| Per-cell flag for gap-filled values only | Adds PCNR_<var>_SRC only when gap-filled; sparse growth | |
| Per-cell flag for all 1,299 variables | Doubles dataset width; full inline provenance | |

**User's choice:** QC-only. Two QC outputs: (a) per-variable gap-fill summary → exchange CSV → Python workbook; (b) cell-level `pdd.qc_pcnr_provenance` (gap-filled cells only) in pdd library — not exported.

---

## s04/s05 Phase 5 role

| Option | Description | Selected |
|--------|-------------|----------|
| Fully skip | No Phase 5 code touches s04/s05 | |
| Use as linkage crosswalk | Not applicable — all sources are 1:1 on PRECEDE_STUDY_ID (D-17) | |
| Assert 0 rows and log it | Explicit SAS log NOTE + assertion | ✓ (extended) |

**User's choice:** Assert in log that s04/s05 contribute 0 rows/0 PCNR_ variables. ALSO assert that `pdd.name_map_vars` has no contributing s_codes of s04 or s05. `%fail_out` if either fails.

---

## QC output path

| Option | Description | Selected |
|--------|-------------|----------|
| Exchange for summary; pdd library for cell-level | Gap-fill summary → exchange → Python; conflicts/provenance in pdd library | ✓ (extended) |
| Everything through exchange | Impractical for million-row provenance | |
| Everything direct to qc\ flat file | Breaks D-22 pattern | |

**User's choice:** Option 1, with extensions: conflict summary + first 5,000 detail rows → exchange → Python writes `qc\pcnr_conflicts.xlsx` (KEY first, summary, detail; KEY notes cap and full-table location). Full conflict table in `pdd.qc_pcnr_conflicts`. Provenance in `pdd.qc_pcnr_provenance` only.

---

## Type-conflict rule (D-02 amendment)

| Option | Description | Selected |
|--------|-------------|----------|
| Recast to N8 when all non-blank values parse; else character; check before gap-fill | Lossless; resolves "3" C8 vs 3 N8 as same value; pre-gap-fill type determination | ✓ |
| Always character for all 9 (strict D-02) | Simplest; leaves type resolution to PCND_ | |
| Recast PCNR_YEAR only | Targeted fix for most obvious case | |

**User's choice:** Option 1 applied to all 9 conflict variables. Determine type BEFORE gap-fill: check character values in each contributing source. If all non-blank, non-"." values parse via `INPUT(val, ?? best32.)`: store as N8; else character. Convert all sources to chosen type before merge. Non-parsing values logged + written to `pdd.qc_pcnr_typecheck`. Amendment to D-02: recast is lossless (storage type only, not content).

---

---

## Post-review amendments (Gerard, 2026-10-21)

Applied after initial context session. All changes reflected in CONTEXT.md.

| # | Amendment | Decision node |
|---|-----------|---------------|
| 1 | SPINE_VS_SOURCE conflict type added: spine non-missing AND non-spine non-missing AND disagree → spine wins, written to pdd.qc_pcnr_conflicts with conflict_type = SPINE_VS_SOURCE. conflict_type column (SPINE_VS_SOURCE \| SOURCE_VS_SOURCE) added to conflict table and summary. | D-15 / D-05 |
| 2 | pdd.qc_pcnr_provenance: rows only for variables with 2+ contributing sources; single-source provenance implied by name_map. Row count logged. | D-16 |
| 3 | Spine-coverage QC added (D-19): per source, n_keys and n_keys_not_in_spine → exchange\pcnr_spine_coverage.csv → SPINE_COVERAGE sheet; NOTE in SAS log. | D-19 (new) |
| 4 | s04/s05 name-map assertion clarified: query pdd.name_map (s_code IN ('s04','s05')), NOT pdd.name_map_vars (which has comma-list s_codes_contributing, no s_code column). | D-18 ext |
| 5 | Equality rule (D-20 new): character → strip(a) = strip(b), case-sensitive; numeric → exact equality. | D-20 (new) |
| 6 | Type-conflict resolves to character: numeric source values converted with strip(put(x, best32.)) before merge. Documented in D-02 note as the only representation change. | D-02 amend |
| 7 | Override semantics: spine still wins unconditionally; pcnr_source_override.csv replaces rank order only (step 2). If pinned source is missing for a row, fall back to rank order for that row. | D-05b |
| 8 | QC workbook consolidated: qc\pcnr_qc.xlsx (Python, D-22) with sheets KEY, GAPFILL, SPINE_COVERAGE, CONFLICT_SUMMARY, CONFLICT_DETAIL (capped 5,000), TYPECHECK. Replaces separate qc\pcnr_conflicts.xlsx and the deferred Phase 7 gap-fill sheet. Phase 5 QC now fully reviewable. | D-16b (new) |
| 9 | Done criteria extended: no CLOCK columns in pdd.pcnr; no blank norm_psid in spine; every PCNR_ variable present with resolved type/length; variable labels = representative original_header. | Domain |

---

## Claude's Discretion

- Exact SAS implementation of rank-order gap-fill (COALESCE vs sorted merge vs macro loop)
- Whether `docs/pcnr_source_priority.csv` is read once at the top or inside a macro
- Whether type-resolution is a standalone macro or inline in the merge section

## Deferred Ideas

None — discussion stayed within Phase 5 scope.

---

## Plan-review amendments (Gerard + external review, 2026-10-21)

Applied before execution. All items below supersede the initial plans (05-03 through 05-05)
and introduce plan 05-06 (synthetic test). Changes reflected in the plan files.

| # | Item | Affects |
|---|------|---------|
| 1 | Preflight extended: assert pdd.src_s09 has exactly 41,150 rows, 0 blank norm_psid, 0 duplicate norm_psid before any build step. Every contributing pdd.src_s* must have 0 duplicate non-blank norm_psid (fail naming the source); report n_blank_keys per source. Spine-coverage CSV adds n_blank_keys, n_dup_keys columns. | 05-03 Task 1 |
| 2 | Never sort pdd.src_* in place. All sorts produce PROC SORT ... out=work._src_<s>; input sources untouched. | 05-04 Tasks 1-2 |
| 3 | Priority file validation: assert exactly 20 rows (s01..s20), ranks form a permutation of 1..20, s09 note=spine; sort work._priority by numeric rank before the gap-fill loop. Override file validation: assert no duplicate pcnr_name; each override s_code must exist in pdd.name_map contributing that pcnr_name (status='PCNR'); never pin to s09. %fail_out on any violation. | 05-03 Task 1 |
| 4 | Fileexist pattern: use the project's existing pattern — no literal quotes inside %sysfunc(fileexist(...)). Match exactly how 04_name_map.sas checks for CSV files. | 05-03 Tasks 1-3 |
| 5 | Log exchange\name_map.csv SHA-256 (via certutil PIPE) plus name_map and name_map_vars row counts read during preflight, so any name-map drift is captured in the Phase 5 log. | 05-03 Task 1 |
| 6 | Temp/helper columns in work._pcnr_accum/_pcnr_next use numbered aliases generated from a var_idx in work._nmv: _S0001.._S1299 (source value per variable) and _F0001.._F1299 ($4 fill-origin per variable). The alias<->pcnr_name<->raw_column<->type map is stored in work._nmv (add var_idx column). Never derive temp column names from pcnr_name strings (avoids illegal-name risk for 32-char PCNR_ names). | 05-04 Tasks 1-2 |
| 7 | Precedence model changed. Three-pass structure: (1) spine pass — load from pdd.src_s09; (2) pinned-source pass — for each pcnr_name in work._override, run a dedicated merge of the pinned source immediately after spine load; (3) rank-order loop — remaining sources in work._priority rank order, skipping spine and already-applied pinned sources; sources contributing 0 PCNR_ variables to a given merge are skipped with a NOTE in the log. Remove the per-row "pinned source still has a value" fallback logic — if pin is missing for a row the rank-order loop will fill it. Conflict detection model unchanged (SPINE_VS_SOURCE / SOURCE_VS_SOURCE). | 05-04 Tasks 1-2 |
| 8 | Each merge pass outputs to work._pcnr_next (plus work._conflicts_<s> and work._prov_<s>); asserts row count = 41,150; then DATA work._pcnr_accum: set work._pcnr_next replaces the accumulator. work._pcnr_next is then dropped. This makes each pass verifiable and avoids in-place modification of the accumulator. | 05-04 Task 2 |
| 9 | Generated SAS code: per-variable ATTRIB/LABEL statements and per-variable gap-fill/conflict IF blocks are written by DATA _NULL_ to logs\05_generated_attrib.sas and logs\05_generated_gapfill_<s>.sas respectively, then %included. No CALL EXECUTE; no per-variable PROC SQL inside %do loops. This keeps the SAS log readable and the generated code auditable. | 05-04 Tasks 1-2 |
| 10 | Type-resolution datasets: work._type_resolution = exactly one row per pcnr_name (resolved_type, out_length); work._typecheck_sources = one row per (pcnr_name, s_code) with per-source diagnostics. Assert key uniqueness on both datasets after creation. | 05-03 Task 3 |
| 11 | C-resolved output length = max(name_map max_length, max length of strip(put(x, best32.)) over all numeric sources contributing to that variable). N8 conversion during merge: count failures; assert 0 (preflight pre-scanned all values, so any failure = bug). Recast (N->C or C->N) applies only to type_conflict='Y' variables. | 05-03 Task 3 |
| 12 | pdd.qc_pcnr_typefail replaces (or supplements) pdd.qc_pcnr_typecheck for individual parse-failure records: schema = pcnr_name, s_code, raw_value, n. Exported to exchange\pcnr_typecheck.csv which feeds the TYPECHECK sheet in pcnr_qc.xlsx. | 05-03 Task 3, 05-02 Task 1 |
| 13 | GAPFILL counts derived from final fill-origin (_F*) columns in work._pcnr_accum, not from intermediate counters. Assert per variable: n_spine + n_gapfilled + n_missing = 41,150, and n_gapfilled = sum(n_filled_<s> across all sources). | 05-04 Task 3 |
| 14 | Provenance unchanged (D-16 stands). KEY sheet note added: spine-origin cells are not listed in pdd.qc_pcnr_provenance; only gap-filled cells for 2+-source variables appear. | 05-02 Task 1 |
| 15 | Conflicts: winning_value and candidate_value stored as character $200 in pdd.qc_pcnr_conflicts; numeric values converted via strip(put(x, best32.)) before storage; value_type column ('C' or 'N') records the original type. Conflict summary reports both n_conflict_events (total OUTPUT rows) and n_conflict_cells (count distinct norm_psid x pcnr_name), grouped by pcnr_name and conflict_type. | 05-04 Task 3 |
| 16 | Final schema assertion: pdd.pcnr must have EXACTLY the 1,299 pcnr_names from pdd.name_map_vars plus norm_psid; fail on any extra or missing column. CLOCK check: assert via pdd.name_map that every CLOCK sas_name in s06_column_class.csv has status='EXCLUDED_CLK' and blank pcnr_name — this is a name_map integrity check, not a raw-name vs PCNR-name comparison. | 05-04 Task 3 |
| 17 | Reconciliation sample: after pdd.pcnr is written, select 1,000 random spine rows; for each non-blank cell, read its fill-origin s_code, re-read the raw value from pdd.src_<s_code> (with type conversion), and assert pdd.pcnr value equals it. %fail_out if any mismatch. | 05-04 Task 3 |
| 18 | Python writer: reject >5,000 rows in CONFLICT_DETAIL input (do not truncate silently — raise error). All sheets always written with headers even if 0 data rows. Validate required columns per CSV before writing each sheet. Columns matching n_filled_* treated as integers. | 05-02 Tasks 1-2 |
| 19 | Pipeline wiring: Python step invoked from run_pipeline.cmd for Phase 5 using the Phase 4 pattern (console output to logs\write_pcnr_qc_console.txt; exit code checked; Phase 5 not COMPLETE if Python fails). Add run_pipeline.cmd to Plan 05-05 files_modified. No x/systask command in SAS. | 05-05 Tasks 1-2 |
| 20 | %fail_out defined once in 05_build_pcnr_macros.sas. The orchestrator (05_build_pcnr.sas) must NOT redefine it — the %include already makes it available. Remove the stub definition from the orchestrator. | 05-05 Task 1 |
| 21 | New Plan 05-06: tests/05_build_test.sas — synthetic standalone SAS test. No P: data. Calls real macros with dataset parameters (srclib=, name_map=, name_map_vars=, priority=, override=). 16 test cases (see plan). Each emits %put TESTRESULT: <case> PASS|FAIL. Final SUMMARY from pass/fail counters. No WARNING lines in test log. No macro-only statements in open code. | 05-06 (new) |
