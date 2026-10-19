# Phase 3: Direct import of the 20 sources — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-19
**Phase:** 03-direct-import-of-the-20-sources
**Areas discussed:** PDD-D-17 correction, s04/s05 role (D-18), s06 column scope (D-21),
s18 dup/blank rows, INFORMAT/LENGTH strategy

---

## PDD-D-17 Correction

| Option | Description | Selected |
|--------|-------------|----------|
| Multi-row files — integration method open | Earlier planning assumed s01/s08 were multi-row per patient | |
| 1:1 per patient — D-17 fully closed | Phase 2 counts: s01 41,423 rows / 41,423 distinct; s08 3,456/3,456 | ✓ |

**User's choice:** D-17 is fully closed. s01 and s08 are NOT multi-row. 274 s01 IDs not in spine
are a QC item, not a grain problem. All planning docs updated to reflect this.

---

## s04/s05 Role (PDD-D-18)

| Option | Description | Selected |
|--------|-------------|----------|
| Linkage/QC only — no PCNR_ columns | Import for completeness; no PCNR_ columns | ✓ |
| Dictionary variables | Their columns enter name map and PCNR_ | |
| Claude's discretion | Treat as linkage-only unless told otherwise | |

**User's choice:** Linkage/QC only. Import into pdd.src_s04/s05; no PCNR_ columns.
**Notes:** s04/s05 matched 0 IDs in the 2022 files. The 2022 ID mismatch is fully resolved by
PDD-D-19 normalisation — do not reference the 2022 mismatch in s04/s05 logic.

---

## s06 Column Scope (PDD-D-21)

| Option | Description | Selected |
|--------|-------------|----------|
| Group summary table | Prefix/suffix groups with counts, fillrate, overlap | ✓ (with additions) |
| Full column list | One row per column with sample values | |
| Two-stage (summary then detail) | Group summary first, detail on request | |

**User's choice:** Profile column groups by name pattern. Output: group name, example column names,
column count, inferred type, share of rows filled in, overlap with columns already in s03/s07.
Then Gerard chooses groups that are clinically meaningful and not duplicated in the masters.

---

## s18 Duplicate/Blank Rows

| Option | Description | Selected |
|--------|-------------|----------|
| Log and drop — continue import | Log IDs to SAS log, exclude from pdd.src_s18 | ✓ (with QC) |
| Keep with flag | Import all rows; add _dup_flag = 1 | |
| Halt and review | ERROR if dup/blank key found | |

**User's choice:** Log them, keep in QC dataset (pdd.qc_s18_dup already exists from Phase 2),
exclude from join/import until reviewed. Not silently dropped.

---

## INFORMAT/LENGTH Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Derive from pdd.header_inventory (programmatic) | Macro generates spec; CALL EXECUTE produces DATA steps | |
| Hand-code from Phase 2 output as reference | Explicit LENGTH/INFORMAT statements coded by planner | |
| Spec table approach (docs\import_spec.csv) | Generate spec CSV; Gerard can override; 03_import.sas reads it | ✓ |

**User's choice:** Programmatic derivation from pdd.header_inventory → `docs\import_spec.csv`
(overridable). IDs and codes forced to character. Lengths from observed maximum + 4 headroom.
03_import.sas reads the spec and generates DATA steps at runtime.

---

## Claude's Discretion

- Exact column-group heuristic for s06 profiling (prefix length, delimiter, fallback)
- Whether spec generation is a standalone macro or inline in 03_import.sas Section 1
- QC row-count reconciliation format (consistent with Phase 2 style)

## Deferred Ideas

- Which s06 column groups enter PCNR_: deferred until profiling output is reviewed
- s04/s05 use in Phase 5 linkage: Phase 5 planning decision
- PDD-D-15, PDD-D-16: Phase 5 only
