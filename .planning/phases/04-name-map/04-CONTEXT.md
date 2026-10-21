# Phase 4: Name map — Context

**Gathered:** 2026-10-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `04_name_map.sas`: map every source header to a PCNR_ name (or a non-PCNR_ status) and
write the authoritative NAME_MAP. Input: all 4,795 rows from `pdd.header_inventory` plus
`docs/s06_column_class.csv`. Output: `pdd.name_map`, `pdd.name_map_vars`, collision and
near-match QC datasets, and `qc\name_map_review.xlsx`.

Done when: all 4,795 rows have a status and a valid PCNR_ name or blank; zero duplicate/invalid
PCNR_ names; zero undecided NEAR_MATCHES; Gerard has reviewed `qc\name_map_review.xlsx`; naming
conventions flagged for Price.

</domain>

<decisions>
## Implementation Decisions

### D-01 — NAME_MAP grain
Primary table `pdd.name_map`: **one row per (source file × original header)** = 4,795 rows total.
**Primary key: (s_code, col_order).** `original_header` is an attribute, not part of the key.
Assert at the start of Phase 4: exactly 4,795 rows from `pdd.header_inventory`, unique on (s_code, col_order).

Every row carries a `status` (PCNR | KEY | EXCLUDED_CLK | LINKAGE_ONLY | DUPLICATE_DROPPED).
CLOCK-class rows have no PCNR_ name; their record is already `docs/s06_column_class.csv`.

Derived view `pdd.name_map_vars`: one row per unique PCNR_ variable, listing all source files that
contribute to it. This is what the workbook NAME_MAP sheet and Phase 5 consume.

### D-01a — Same-variable rule
Rows from **different** files whose cleaned names (D-02 steps 1–5) are equal case-insensitively
are the same variable and share one PCNR_ name.

Identical headers across files are **overlaps** (spine wins, gap-fill per PDD-D-05), never collisions.

Two columns in the **same** file whose cleaned names collide (case-insensitive) are separate
variables: the later col_order gets `_2` via Stage 1 suffixing, and the pair is listed on
NAME_MAP_COLLISIONS with `reason=SAME_FILE_CLEANED_DUPLICATE` for Gerard review. Cross-file
grouping uses only the first such group (lowest col_order); the remaining same-file variants are
separate groups. The only exception to same-file separation is the duplicate Study ID handled by D-08.

SAME decisions in `docs/name_map_decisions.csv` also group variables across files.
Variable groups formed by D-01a + SAME decisions are what the collision check (D-05) operates on.

### D-01b — Processing order
Execute steps in this fixed sequence:

1. Assign statuses (D-04) — precedence: DUPLICATE_DROPPED > KEY > LINKAGE_ONLY > EXCLUDED_CLK > PCNR.
2. Clean and shorten names (D-02, D-03).
3. Apply `docs/name_map_decisions.csv` overrides (SAME / DIFFERENT / RENAME).
4. Form variable groups: D-01a case-insensitive matches + SAME decisions.
5. Resolve collisions **between groups** with `_2`, `_3`, … (order: s01→s20, then col_order within file).
6. Stage 2 validation: case-insensitive duplicates, > 32 chars, invalid V7 names → `%fail_out`.

A SAME decision is never undone by suffixing; collision suffixes only apply between groups.

### D-02 — Name cleaning rule (implements PDD-D-07)
Applied in this fixed order before prefixing PCNR_:
1. Trim leading/trailing whitespace from the original header.
2. Replace every run of characters that are not ASCII letters or digits with a single `_`
   (non-ASCII characters are treated as non-keeping and folded into the run).
3. Strip leading and trailing `_`.
   A header that cleans to empty after steps 1–3 causes `%fail_out` listing it.
4. If the result starts with a digit, prefix `N_`.
5. Keep original letter case.
6. Apply abbreviation table (D-03) only if the result would exceed 27 chars after PCNR_
   (applies to all files, not just s06).
7. Prefix `PCNR_`.

The cleaning rule is documented in the KEY sheet of `qc\name_map_review.xlsx`.

### D-03 — Name shortening (all files, names > 27 chars after PCNR_)
The distinguishing token in s06 names is typically at the end (…Raw, …Norm_ZScore, …TrialIII),
so blind left-truncation causes mass collisions.

Apply in this fixed order:
1. **Abbreviation table first**: apply `docs/name_abbrev.csv` (pre-populated: Delayed→Dly,
   Recall→Rcl, Recognition→Recog, Number→N, Norm_ZScore→Z, AgeScaled→AgeSc, Percent→Pct).
   Additional abbreviations can be added before rerun.
2. **Elide middle if still too long**: keep the first N chars and the last M chars, separated by
   `__` (double underscore), so the result fits in 27 chars. Start and end lengths chosen to
   preserve COM/COPY prefix and the distinguishing suffix.
3. **Never drop COM/COPY prefix**: COM and COPY versions of the same test must remain
   distinguishable.
4. Full original name always goes to the SAS variable LABEL and to NAME_MAP (PDD-D-07).

Naming conventions require Price approval. Phase 4 output is a proposal for review.

The ABBREVIATIONS sheet in `qc\name_map_review.xlsx` lists every substitution applied.

### D-04 — Column status taxonomy

Precedence (highest first): DUPLICATE_DROPPED > KEY > LINKAGE_ONLY > EXCLUDED_CLK > PCNR.
A row gets the first status in this list whose condition is met.

| Status | Meaning |
|--------|---------|
| `DUPLICATE_DROPPED` | Duplicate header confirmed identical in values (see D-08); no PCNR_ name |
| `KEY` | Exactly the rows in `pdd.key_analysis` where `key_column_type = 'PRECEDE_STUDY_ID'` (one per file; same source the Phase 3 norm_psid loop used); PCNR_ name is blank in Phase 4; Phase 5 builds PCNR_PRECEDE_STUDY_ID from norm_psid. No name-pattern guessing — other ID-like columns (e.g. PRECEDE_ID_NUM in s01) stay PCNR. Assert: exactly one KEY row per file that has a PRECEDE_STUDY_ID row in `pdd.key_analysis`. |
| `LINKAGE_ONLY` | s04/s05 columns (PDD-D-18); no PCNR_ name |
| `EXCLUDED_CLK` | class=CLOCK in `docs/s06_column_class.csv`; no PCNR_ name; Phase 9 handles |
| `PCNR` | PCNR_ candidate; has a PCNR_ name |

Note: `DERIVED` (norm_psid, enc_for_linkage) is removed — those columns are not in
`pdd.header_inventory`; Phase 5 handles them.

s06 assertion: after status assignment, count of EXCLUDED_CLK rows for s06 must equal 2,747.
Assert against `docs/s06_column_class.csv`; `%fail_out` on mismatch.

### D-05 — Collision resolution (two-stage)
Collisions are checked **between variable groups** (formed in D-01b step 4), not across all 4,795
rows. Two rows in the same group share one PCNR_ name; that is an overlap, not a collision.
A SAME decision is never undone by suffixing.

**Stage 1 — Auto-suffix:** when two distinct variable groups produce the same PCNR_ base name,
suffix the later group's name `_2`, `_3`, … (order: s01→s20 file order, then col_order within
file for the group's representative row), staying within 27 chars. All suffixed pairs are written
to `pdd.qc_name_map_collisions` and the NAME_MAP_COLLISIONS sheet for Gerard review. Run continues.

Override paths before rerun:
- `docs/name_map_decisions.csv`: add `decision=RENAME` with the desired PCNR_ name.
- `docs/name_abbrev.csv`: add an abbreviation that shortens one name enough to avoid the clash.

**Stage 2 — Hard stop (D-01b step 6):** after Stage 1, `%fail_out` if any final PCNR_ name is:
- A case-insensitive duplicate of another final PCNR_ name, OR
- Longer than 32 characters, OR
- Not a valid SAS V7 name.

Stage 2 failure means an override file must be corrected before Phase 4 can complete.

### D-06 — Near-match detection and resolution
Near-matches are pairs from **different files** whose cleaned names (D-02 steps 1–5) are not
identical yet differ only by:
- A trailing suffix (`_1`, `_2`, `_dupN`, or a single trailing digit), OR
- Edit distance ≤ 2 (case-insensitive Levenshtein).

Pairs within the same file are never near-matches. Near-matches are never automatically merged;
a SAME decision is required.

Workflow:
1. SAS computes all qualifying pairs and writes `pdd.name_map_nearmatches`. **Print pair count.**
   If pair count exceeds 200: `%fail_out` and report the top patterns (most-common suffix or
   edit-1/edit-2 clusters) to Gerard before writing any sheet.
2. If pair count ≤ 200: export to `exchange\name_map_nearmatches.csv`.
3. Python writes the NEAR_MATCHES sheet in `qc\name_map_review.xlsx`.
4. Gerard resolves via `docs/name_map_decisions.csv`:
   - `decision=SAME`: pair maps to one PCNR_ variable (adds them to the same group).
   - `decision=DIFFERENT`: pair stays separate; no merge.
5. Unresolved (undecided) pair count is printed to the SAS log.
   **Phase 4 is not complete while any undecided pairs remain.**

`docs/name_map_decisions.csv` schema:
`s_code_a, header_a, col_order_a, s_code_b, header_b, col_order_b, decision, note, decided_by, date`
`col_order_a` and `col_order_b` are optional; populate only when a header repeats within a file
and the decision must target an exact column. No data values; committed to git.

### D-07 — Type tracking and conflict flagging
`pdd.name_map` records `sas_type` and `length` for each (file × header) row from `pdd.import_spec`
(the merged spec Phase 3 produced).

`pdd.name_map_vars` records:
- `result_type`: C if any contributing source has `sas_type=C`, else N.
- `max_length`: maximum length across all contributing rows.

When the same PCNR_ variable has `sas_type=C` in some sources and `sas_type=N` in others:
- `result_type` = C (Phase 5 enforces this, PDD-D-02).
- `pdd.name_map_vars` shows a `type_conflict=Y` flag for that variable.
- Phase 4 lists all type-conflict variables in the SAS log for Gerard review.

Conversion details (date formats, number formatting, leading zeros) are Phase 5 scope.

### D-08 — Duplicate "PRECEDE Study ID" header (s15, s17)
Before marking `status=DUPLICATE_DROPPED`, compare duplicate vs primary Study ID after
normalisation: strip whitespace; if the value is numeric, convert via `put(x, best32. -l)`.

Log:
- Rows compared (non-missing in both columns).
- Count of disagreements.
- Count of missing/missing pairs (both blank; not counted as a disagreement).

`%fail_out` on any disagreement, listing up to 20 offending rows.
If all values agree: mark DUPLICATE_DROPPED and log NOTE with row count confirmed.

### D-09 — Output files

**SAS datasets (all in `pdd` library):**
- `pdd.name_map` — primary table (4,795 rows, one per source × header)
- `pdd.name_map_vars` — VARIABLES view (one row per PCNR_ variable)
- `pdd.qc_name_map_collisions` — Stage 1 suffix pairs

**Exchange exports (UTF-8 CSV, no index, to `&exchange_path.\`):**
- `name_map.csv`
- `name_map_vars.csv`
- `name_map_collisions.csv`
- `name_map_nearmatches.csv`
- `name_abbrev_applied.csv` (abbreviations applied, for ABBREVIATIONS sheet)

**Python output (D-22):**
- `qc\name_map_review.xlsx` — sheets: KEY | NAME_MAP | VARIABLES | NAME_MAP_COLLISIONS | NEAR_MATCHES | ABBREVIATIONS; UF colors via `python\pdd\xlsx_style.py`

**Committed decision files (no PHI, header names only):**
- `docs/name_map_decisions.csv` — SAME/DIFFERENT/RENAME decisions; may be empty initially
- `docs/name_abbrev.csv` — abbreviation table; pre-populated with standard tokens

### D-10 — Done criteria
1. All 4,795 `pdd.header_inventory` rows have exactly one `pdd.name_map` row and a status.
2. No duplicate or invalid PCNR_ names (Stage 2 check passes).
3. Zero undecided NEAR_MATCHES.
4. Every row in `docs/name_map_decisions.csv` refers to an existing (s_code, header) pair in `pdd.name_map`.
5. SAS dataset row counts equal Python workbook sheet row counts for all exported tables.
6. Variable labels equal the full original header. Any label longer than 256 chars was truncated
   (Phase 2 logged 16 truncation warnings) — list truncated variables in the SAS log.
7. Gerard has reviewed `qc\name_map_review.xlsx` and review is recorded as complete.
8. Price approval of naming conventions recorded as complete.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 4 scope and requirements
- `.planning/ROADMAP.md` §Phase 4 — phase goal, done criteria, gate note
- `.planning/REQUIREMENTS.md` §PDD-04 — acceptance criteria table

### Locked decisions that govern this phase
- PDD-D-07 (naming, truncation, label rule) — captured in PROJECT.md and REQUIREMENTS.md
- PDD-D-21 (CLOCK exclusion, s06 class split) — `docs/s06_column_class.csv` is the record
- PDD-D-18 (s04/s05 are LINKAGE_ONLY) — STATE.md open-decisions table
- PDD-D-22 (SAS/Python split) — STATE.md D-22 section; Python owns xlsx output

### Source data contracts
- `docs/s06_column_class.csv` — s06 column class (PCNR | CLOCK | DIGITAL_OTHER | …) for all 3,987 columns; authoritative for Phase 4 filtering
- `pdd.import_spec` — per-(file × column) sas_name, sas_type, length; source of type/length for pdd.name_map rows (the merged spec Phase 3 produced)

### Override / decision files (may be empty at Phase 4 start; committed to git)
- `docs/name_map_decisions.csv` — SAME/DIFFERENT/RENAME decisions for near-match and collision resolution
- `docs/name_abbrev.csv` — abbreviation table applied before truncation

### PCM compliance
- `CLAUDE.md` — SAS lint rules (C1–C14); must run `python tools\sas_lint.py sas\04_name_map.sas` and `sasjs lint` with zero errors before commit

No external ADRs or specs. Requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sas/00_config.sas` — `%pdd_lib`, `&exchange_path.`, `%check_encoding`, `%check_pdd_lib`, `%pdd_norm_psid`; all available via `%include`
- `sas/03_import.sas` — pattern for DATA step accumulation and `%fail_out` macro; reuse same pattern
- `sas/03a_build_spec.sas` — precedent for spec-driven approach; shows how to read CSV spec files into SAS

### Established Patterns
- `%fail_out(msg=...)` macro: used in Phases 2–3 for hard stops; replicate in Phase 4 for Stage 2 collision check and D-08 duplicate check
- Exchange CSV export: `&exchange_path.\` established in D-22 and 03b_classify_s06.sas
- Python xlsx writer: `python\scripts\write_s06_clock_classification.py` is the pilot; `write_name_map_review.py` follows same structure
- `options validvarname=v7` is already set in `00_config.sas`; Phase 4 benefits from this for PCNR_ name validation

### Integration Points
- Reads `pdd.header_inventory` (Phase 2 output) — must exist before Phase 4 runs
- Reads `docs/s06_column_class.csv`, `pdd.import_spec`, `docs/name_map_decisions.csv`, `docs/name_abbrev.csv`
- Writes `pdd.name_map` and `pdd.name_map_vars` — consumed by Phase 5 (`05_build_pcnr.sas`)
- Writes exchange CSVs — consumed by `python\scripts\write_name_map_review.py`
- Must be wired into `sas/99_run_all.sas` after Phase 3 and before Phase 5

</code_context>

<specifics>
## Specific Ideas

- s06 PCNR_-class column count is ~1,240 (809 DIGITAL_OTHER + 431 PCNR from D-21); expect heavy use of abbreviation table for these.
- Standard abbreviations to seed `docs/name_abbrev.csv`: Delayed→Dly, Recall→Rcl, Recognition→Recog, Number→N, Norm_ZScore→Z, AgeScaled→AgeSc, Percent→Pct.
- CLOCK columns (2,747) stay in `pdd.name_map` with `status=EXCLUDED_CLK` and blank PCNR_ name — no separate CLK_ dataset needed; `docs/s06_column_class.csv` is already the record.
- 4,795 = total header_inventory rows expected; verify this row count at start of Phase 4.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 4 scope.

</deferred>

---

*Phase: 04-name-map*
*Context gathered: 2026-10-21*
