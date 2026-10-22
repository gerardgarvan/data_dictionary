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

## Claude's Discretion

- Exact SAS implementation of rank-order gap-fill (COALESCE vs sorted merge vs macro loop)
- Whether `docs/pcnr_source_priority.csv` is read once at the top or inside a macro
- Whether type-resolution is a standalone macro or inline in the merge section

## Deferred Ideas

None — discussion stayed within Phase 5 scope.
