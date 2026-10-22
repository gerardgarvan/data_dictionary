# Phase 5: Build PCNR_ on the spine — Context

**Gathered:** 2026-10-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `05_build_pcnr.sas`: start from `pdd.src_s09` (spine, 41,150 rows), left-join all
other 1:1 PRECEDE_STUDY_ID sources using the Phase 4 name map, apply gap-fill and type
resolution, and write `pdd.pcnr` with one row per spine patient and every PCNR_ variable.

Done when: `pdd.pcnr` has exactly 41,150 rows; column count = 1,299 PCNR_ variables +
NORM_PSID key; 0 duplicate keys; no CLOCK columns in `pdd.pcnr`; no blank norm_psid in
spine; every PCNR_ variable present with resolved type and length; variable labels equal
the representative original_header from name_map; gap-fill QC and conflict QC written
and reviewed; `qc\pcnr_qc.xlsx` produced with KEY, GAPFILL, SPINE_COVERAGE,
CONFLICT_SUMMARY, CONFLICT_DETAIL, TYPECHECK sheets; s04/s05 assertions pass;
type-conflict variables resolved and logged; wired into `99_run_all.sas`.

</domain>

<decisions>
## Implementation Decisions

### D-15 — Gap-fill tie-break order (LOCKED 2026-10-21, Gerard)

Default order: s01 → s20, skipping spine (s09). When the spine is missing and a non-spine
source is non-missing, the highest-ranked source (lowest rank number) wins.

**Source priority file:** `docs/pcnr_source_priority.csv` (s_code, rank, note). Generated
once from s01→s20 order; may be edited before rerun — no code change needed to change order.
Committed to git (no PHI — s_codes and rank only).

**Conflicts (D-05):** Two conflict types are captured in `pdd.qc_pcnr_conflicts`:

- **SPINE_VS_SOURCE:** Spine is non-missing AND a non-spine source is non-missing AND they
  disagree. Spine still wins; cell is written to conflicts with conflict_type = SPINE_VS_SOURCE.
- **SOURCE_VS_SOURCE:** Spine is missing, 2+ non-spine sources are non-missing and DISAGREE.
  Highest-ranked wins; cell written with conflict_type = SOURCE_VS_SOURCE.

Agreeing values (same value across multiple sources) are NOT conflicts and do NOT go to the conflict QC.

`pdd.qc_pcnr_conflicts` includes a `conflict_type` column (SPINE_VS_SOURCE | SOURCE_VS_SOURCE).
Conflict summary CSV includes conflict_type breakdown.

**Per-variable override:** `docs/pcnr_source_override.csv` (pcnr_name, s_code) — empty by
default; allows pinning a specific source for a specific PCNR_ variable. Committed to git.
If a row is present for a variable, that s_code is used instead of priority-order logic.

### D-16 — Per-cell source flag (LOCKED 2026-10-21, Gerard)

**pdd.pcnr stays at 1,299 PCNR_ columns + NORM_PSID key.** No PCNR_<var>_SRC columns.

Gap-fill traceability is QC-only, in two places:

**(a) Per-variable gap-fill summary** (exchange → Python workbook):
- `exchange\pcnr_gapfill.csv`: one row per PCNR_ variable
- Columns: pcnr_name, n_spine (non-missing from spine), n_gapfilled (filled from non-spine),
  n_missing (still missing after gap-fill), plus one n_filled_<s_code> column per contributing
  source showing how many cells it filled.
- Python writes this as a sheet in the Phase 7 workbook.

**(b) Cell-level provenance** (pdd library on P: only, no export):
- `pdd.qc_pcnr_provenance`: one row per gap-filled cell
- Columns: norm_psid, pcnr_name, src_s_code
- Rows ONLY where spine was missing and another source filled the value, AND only for
  variables with 2+ contributing sources (single-source provenance is implied by name_map).
- Not exported to xlsx. Use for trace-to-source audits only.
- Log its row count at end of QC section.

### D-18 (Phase 5 extension) — s04/s05 role (LOCKED 2026-10-21, Gerard)

s04 and s05 contribute no PCNR_ columns (D-18 locked). Phase 5 adds two assertions:

1. **Log assertion:** write a NOTE to the SAS log confirming `pdd.src_s04` and `pdd.src_s05`
   contribute 0 rows and 0 PCNR_ variables to `pdd.pcnr`.
2. **Name-map assertion:** verify that no row in `pdd.name_map` where s_code IN ('s04','s05')
   has PCNR status. Query `pdd.name_map` (not `pdd.name_map_vars`). `%fail_out` if assertion fails.

### D-19 — Spine key coverage QC (LOCKED 2026-10-21, Gerard)

For each non-spine source joined to the spine (left join on norm_psid):
- Compute `n_keys` (total norm_psid in that source) and `n_keys_not_in_spine` (norm_psid in
  source but absent from spine).
- Write to `exchange\pcnr_spine_coverage.csv` (s_code, n_keys, n_keys_not_in_spine).
- Python writes this as the SPINE_COVERAGE sheet in `qc\pcnr_qc.xlsx`.
- Emit a SAS NOTE in log: "SOURCE <s_code>: <n_keys_not_in_spine> of <n_keys> keys not in spine."

### D-16b — QC output path (LOCKED 2026-10-21, Gerard)

| Output | Path | Mechanism |
|--------|------|-----------|
| Gap-fill summary | `exchange\pcnr_gapfill.csv` → Python → GAPFILL sheet | D-22 pattern |
| Spine coverage | `exchange\pcnr_spine_coverage.csv` → Python → SPINE_COVERAGE sheet | D-19 |
| Conflict summary | `exchange\pcnr_conflicts_summary.csv` (pcnr_name, n_conflict_cells, conflict_type, s_codes_involved, winning_s_code) → CONFLICT_SUMMARY sheet | D-22 pattern |
| Conflict detail (capped) | `exchange\pcnr_conflicts_detail.csv` — first 5,000 rows of `pdd.qc_pcnr_conflicts` → CONFLICT_DETAIL sheet | D-22 pattern |
| Type-check | `exchange\pcnr_typecheck.csv` → Python → TYPECHECK sheet | D-02 |
| **Phase 5 QC workbook** | **`qc\pcnr_qc.xlsx`** — sheets: KEY, GAPFILL, SPINE_COVERAGE, CONFLICT_SUMMARY, CONFLICT_DETAIL (capped 5,000), TYPECHECK; KEY notes cap and references `pdd.qc_pcnr_conflicts` on P: | Python writes per D-22 |
| Full conflict table | `pdd.qc_pcnr_conflicts` on P: — all rows, all detail, conflict_type column | pdd library only |
| Cell-level provenance | `pdd.qc_pcnr_provenance` on P: — gap-filled cells, 2+ source vars only | pdd library only |

Nothing in git. All data on P:. Phase 5 QC is reviewable via `qc\pcnr_qc.xlsx` — not deferred to Phase 7.

### D-02 (type resolution amendment) — Type-conflict rule (LOCKED 2026-10-21, Gerard)

For the 9 PCNR_ variables that have mixed character/numeric sources (including s19 numerics
stored as C8, PCNR_YEAR C9/N8):

**Determine type BEFORE gap-fill and conflict detection**, by inspecting character values in
each contributing source (`pdd.src_<s>`):

1. Collect all non-blank, non-"." values from all character-typed sources for this variable.
2. Apply `INPUT(strip(val), ?? best32.)` to each.
3. If ALL parse (0 failures): resolved type = **N8**. Convert all sources to N8 before
   merge/gap-fill. "3" in C8 source and 3 in N8 source are the SAME value — not a conflict.
4. If ANY parse failure: resolved type = **C** (max length from `pdd.name_map_vars`). Keep
   values exactly as-is (PDD-D-02). Non-parsing values logged + written to
   `pdd.qc_pcnr_typecheck` (variable, s_code, raw_value, n_occurrences).
5. Blank and "." are treated as missing in the parse check.

**D-02 note:** recast is lossless — only storage type changes, not content. A variable
stored as C8 where all values are numeric strings is stored as N8 in pdd.pcnr but every
value is identical when printed. Variables with parse failures remain character exactly as-is.

When a type-conflict variable resolves to **character** (any parse failure), numeric-typed
source values must be converted to character before merge: use `strip(put(x, best32.))`.
This conversion is documented in the TYPECHECK QC output.

`pdd.qc_pcnr_typecheck` records the resolution and any failures for audit.

### D-20 — Equality rule for conflict detection (LOCKED 2026-10-21, Gerard)

- **Character variables:** compare using `strip(a) = strip(b)`, case-sensitive. Blank and " " are both missing.
- **Numeric variables:** exact equality (`a = b`). No tolerance.

### D-05b — Spine-first join mechanics

The join follows this sequence for every PCNR_ variable:
1. Spine value (`pdd.src_s09`) is used if non-missing.
2. If spine is missing, walk sources in `docs/pcnr_source_priority.csv` rank order (lowest
   rank first, skipping s09). First non-missing wins.
3. Per-variable override in `docs/pcnr_source_override.csv` pins a specific s_code,
   bypassing rank order for that variable. Spine still wins unconditionally (step 1).
   Override replaces rank order only (step 2). If the pinned source is missing for a given
   row, fall back to normal rank order for that row.
4. Disagreements (step 2 cases where 2+ sources are non-missing and disagree) → `pdd.qc_pcnr_conflicts`.
5. Agreeing values are not conflicts.

PCNR_PRECEDE_STUDY_ID is built from `norm_psid` (Phase 4 convention; one value per row by
construction — no gap-fill needed).

### Claude's Discretion

- Exact SAS implementation of rank-order gap-fill (PROC SQL multi-source COALESCE vs DATA step
  with sorted priority merge vs macro loop per source). Choose the most readable approach that
  respects PCM compliance rules.
- Whether `docs/pcnr_source_priority.csv` is read once at the top of the program or re-read
  inside a macro.
- Whether type-resolution for the 9 conflict variables is a standalone macro or inline in the
  merge section.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 5 scope and requirements
- `.planning/ROADMAP.md` §Phase 5 — phase goal, done criteria
- `.planning/REQUIREMENTS.md` §PDD-05 — acceptance criteria table

### Locked decisions that govern this phase
- `.planning/PROJECT.md` — PDD-D-01 (all 20 files, s09 spine), PDD-D-02 (values as-is, type
  resolution lossless), PDD-D-05 (spine wins, gap-fill, conflicts to QC), PDD-D-17 (all 1:1),
  PDD-D-18 (s04/s05 LINKAGE_ONLY), PDD-D-21 (CLOCK excluded), PDD-D-22 (SAS/Python split)
- `.planning/phases/04-name-map/04-CONTEXT.md` — name map contract; pdd.name_map_vars schema;
  type_conflict flag; PCNR_PRECEDE_STUDY_ID from norm_psid; 9 type conflicts carried from Phase 4

### Source data contracts (on P:, not in git)
- `pdd.name_map_vars` — one row per PCNR_ variable; pcnr_name, contributing s_codes,
  result_type, max_length, type_conflict flag; Phase 5's primary join map
- `pdd.src_s01`…`pdd.src_s20` — Phase 3 imports; all contain norm_psid
- `docs/s06_column_class.csv` — CLOCK exclusion; Phase 5 must assert CLOCK columns absent

### Override / priority files (generated, committed to git, no PHI)
- `docs/pcnr_source_priority.csv` — s_code, rank, note; generated s01→s20; editable
- `docs/pcnr_source_override.csv` — pcnr_name, s_code; empty by default; optional per-variable pin

### PCM compliance
- `CLAUDE.md` — SAS lint rules (C1–C14); run `python tools\sas_lint.py sas\05_build_pcnr.sas`
  and `sasjs lint` with zero errors before commit

No external ADRs. Requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sas/00_config.sas` — `%pdd_lib`, `&exchange_path.`, `%pdd_norm_psid`, `%check_encoding`,
  `%check_pdd_lib`; available via `%include`
- `sas/04_name_map.sas` — `%fail_out`, `%assert_rowcount`, PROC SQL join patterns,
  exchange CSV export pattern; replicate in Phase 5
- `sas/04_name_map_macros.sas` — macro decomposition pattern (one macro per section); use
  same structure for 05_build_pcnr.sas
- `python/scripts/write_name_map_review.py` — Python workbook writer pattern; replicate for
  `write_pcnr_conflicts.py`

### Established Patterns
- `%fail_out(msg=...)` — fatal error macro; define locally per PCM (not in 00_config.sas)
- Exchange CSV: `PROC EXPORT … outfile="&exchange_path.\<name>.csv" dbms=csv replace;`
- Python writer: argparse CLI, assert_input, write_workbook, verify_workbook; KEY sheet first
- `options validvarname=v7` already set in `00_config.sas`
- Log routing via `%route_log` / `%restore_log` macros (Phase 4 pattern)

### Integration Points
- Reads `pdd.name_map_vars` (Phase 4 output) — must exist; assert row count = 1,299 at start
- Reads `pdd.src_s01`…`pdd.src_s20` (Phase 3 output) — must all exist
- Reads `docs/pcnr_source_priority.csv` and `docs/pcnr_source_override.csv` at runtime
- Writes `pdd.pcnr` — consumed by Phase 6 (distribution engine) and Phase 7 (workbook writer)
- Writes exchange CSVs — consumed by Python conflict workbook writer
- Must be wired into `sas/99_run_all.sas` after Phase 4 and before Phase 6

</code_context>

<specifics>
## Specific Ideas

- `docs/pcnr_source_priority.csv` schema: s_code, rank (1-based integer), note (e.g. "spine" for s09).
  Generate at start of Phase 5 planning: s01=rank 1, …, s08=rank 8, s09=rank 9 (spine, used first
  but skipped in gap-fill priority), s10=rank 10, …, s20=rank 20.
- `docs/pcnr_source_override.csv` schema: pcnr_name, s_code. Empty initially.
- `pdd.qc_pcnr_typecheck` columns: pcnr_name, s_code, resolution (N8 or C), n_char_sources,
  n_parse_failures, example_failing_value.
- `pdd.qc_pcnr_provenance` columns: norm_psid, pcnr_name, src_s_code. Rows only for gap-filled cells.
- `pdd.qc_pcnr_conflicts` columns: norm_psid, pcnr_name, conflict_type (SPINE_VS_SOURCE |
  SOURCE_VS_SOURCE), winning_s_code, winning_value, all candidate s_codes and values
  (long or wide — implementer's discretion).
- Conflict export cap: 5,000 rows for detail CSV; KEY sheet in conflicts.xlsx must note cap
  and reference `pdd.qc_pcnr_conflicts on P:` for full data.
- s04/s05 assertion: check PROC SQL against `pdd.name_map` where s_code IN ('s04','s05')
  and PCNR status; expect 0 rows.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 5 scope.

</deferred>

---

*Phase: 05-build-pcnr-on-the-spine*
*Context gathered: 2026-10-21*
