# Phase 7: Dictionary Workbook Writer — Context

**Gathered:** 2026-10-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Python reads exchange CSVs produced by SAS (Phases 5–6) and writes `out/pdd_v1_0.xlsx` — the v1.0
deliverable workbook. A small SAS orchestrator (`sas/07_build_profile.sas`) runs first to export
any exchange CSVs not already written and to assert freshness/schema of all inputs.

**D-22 LOCKED:** Python owns all xlsx output. SAS does not write xlsx.

Out of scope: recoding or cleaning values (Phase 13+), profiling non-PCNR families (Phases 8–12),
cohort restriction, any changes to `pdd.pcnr` or `pdd.prf_pcnr`.

</domain>

<decisions>
## Implementation Decisions

### Sheet Order (LOCKED — PDD-D-09)

KEY | VARIABLES | DISTRIBUTIONS | NAME_MAP | SOURCES | QC | PCNC_ (pending) | PCND_ (pending)
| CLK_ (pending) | LAB_ (pending) | MED_ (pending) | INTRA_ (pending)

- KEY is leftmost.
- Placeholder sheets for PCNC_, PCND_, CLK_, LAB_, MED_, INTRA_ each show "(source pending)".
- QC sheet: summary counts (n variables by var_class, n flagged small-cell, n SUPPRESSED, n all-missing).

### VARIABLES Sheet (Area A — hybrid layout)

One row per variable (1,297 rows). Columns:

| Column | Source | Notes |
|--------|--------|-------|
| pcnr_name | profile_PCNR.csv | Primary key |
| original_headers | name_map.csv | Pipe-separated list of original source headers |
| source_s_codes | name_map.csv | Space-delimited source file codes |
| storage_type | name_map.csv | N8 or C (resolved_type) |
| var_class | profile_PCNR.csv | LOW_CARD / CONT_NUM / HIGH_CARD / DATE / NUM_TEXT / SUPPRESSED |
| n_nonmiss | profile_PCNR.csv | From N stat row |
| pct_missing | profile_PCNR.csv | Derived: (total_rows - n_nonmiss) / total_rows * 100 |
| n_distinct | profile_PCNR.csv | From N_DISTINCT stat row |
| all_missing | derived | Y if every row missing (n_nonmiss = 0), N otherwise |
| summary | generated | Rule-generated text (see display rules below) |

`pcnr_name` is a hyperlink to the first row of that variable on the DISTRIBUTIONS sheet.

### DISTRIBUTIONS Sheet (Area A — long format)

One row per (variable, stat/level) from `exchange/profile_PCNR.csv`. All 5,642+ rows.
Sorted by pcnr_name then sort_order.
Counts and statistics in separate columns (n vs. value), never mixed.
Columns mirror profile_PCNR.csv schema (13 columns from 06-CONTEXT.md):
variable, var_class, stat, level, sort_order, n, pct_total, pct_nonmiss,
n_nonmiss, n_distinct, small_cell_flag, display_format, date_kind.

### Display Rules (configurable, not hard-coded)

Rules are loaded from a config dict (defaults below; overridable at runtime or by Price).

**Small-cell suppression (Area B):**
- Default: `small_cell_mode = "suppress"` — replace n with `"<11"`, pct_total and pct_nonmiss blank.
- Applies to any LEVEL/OTHER/MISSING row where `small_cell_flag = 'Y'` (1 ≤ n ≤ 10).
- Complementary suppression: if a variable would have exactly one suppressed cell after applying
  the above, also suppress the next-smallest non-zero cell of that variable (prevents derivation
  via total - suppressed).
- NUM_TEXT unparsed LEVEL rows with n ≤ 10: replace level text with `"other text entry"`.
- Config options: `suppress` (default) | `asterisk` (show n* + footnote on KEY) | `raw` (show n).
- Pending Price confirmation.

**Age top-coding (Area C):**
- Default: `age_topcode = True`.
- Variable list: `docs/age_variables.csv` (columns: variable, reason). See file for the 6 listed vars.
- For listed variables: LEVEL values > 89 displayed as `"90+"` (counts combined).
  STAT rows MIN/MAX/MEDIAN/Q1/Q3 > 89 displayed as `"90+"`. MEAN and SD unchanged.
- NOT matched by variable name pattern (would hit mood_agency, *STAGE*, *PERCENTAGE*, etc.).
- Pending Price confirmation.

**Placeholder/mixed codes (Area D):**
- Display-only; no recoding. Show N_UNPARSED / n_placeholder counts as computed by Phase 6.
- Unparsed text rows with n ≤ 10 fall under Area B small-cell rule above.
- No sign-off needed (values unchanged; only counts shown).

**All-missing variables (Area E):**
- 56 all-missing vars (mostly LOW_CARD with n_distinct = 0).
- VARIABLES sheet carries `all_missing = Y` flag column.
- Summary text: `"No values (100% missing)"`.
- Variables remain in sheet; inclusion pending Price (issues doc item 7).

### NAME_MAP Sheet (Area F)

All 4,795 name_map rows (every source column and its fate).
Source: `exchange/name_map.csv` (already exists; Phase 5 hashes it — no new SAS export needed).
Columns to read from sas/04_name_map.sas schema: s_code, original_header, pcnr_name, status, note/reason.
Sorted by s_code then original_header. Autofilter on.
Do NOT assume columns — read actual schema from sas/04_name_map.sas before using.

### SOURCES Sheet (Area F2)

Generated from `pdd.source_inventory` exported to `exchange/source_inventory.csv`.
Columns: s_code, file_name (NO P: path), row_count, column_count, sha256_short (first 12 chars),
received_date (derived from file name if possible).
Left-join `docs/source_notes.csv` (s_code, description) for plain-English descriptions.
`docs/source_notes.csv` is optional; sheet renders without it if absent.

### SAS Orchestrator: 07_build_profile.sas (Area G)

Runs before Python. Three responsibilities:

1. **Export source_inventory.csv** if not already exported to exchange/.
2. **Freshness check** (hard FAIL):
   - `exchange/profile_PCNR.csv` must not be older than `pdd.pcnr` last-modified time.
   - `exchange/name_map.csv` must not be older than `pdd.name_map` last-modified time.
3. **Schema assertion**: assert every input CSV exists and has expected columns.
   Extend `docs/exchange_schema.csv` with Phase 7 input entries.

### Python Entry Point

`python/scripts/write_dictionary.py`
Follows pattern of `write_pcnr_qc.py`:
- `--exchange <path>` (default: EXCHANGE_PATH from config.py)
- `--out <path>` (default: OUT_PATH from config.py — `P:\PeCAN Master Data\Gerard\data_dictionary\out\`)
- `--logs <path>` (default: LOGS_PATH)
- Core logic in `python/pdd/dictionary_workbook.py`
- Uses `python/pdd/xlsx_style.py` (write_table, style_sheet, HEADER_FILL, HEADER_FONT, ACCENT_FILL)

### run_pipeline.cmd Integration

Phase 7 Python step runs only when `7` is in `PDD_PHASES`.
Order: `07_build_profile.sas` then `write_dictionary.py`.

### House Style

- UF blue `#0021A5` / orange `#FA4616` via existing `xlsx_style.py` constants.
- Measured neutral wording throughout (no clinical tone, no sensational language).
- KEY sheet documents every sheet's purpose, every column, every display rule applied.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 6 output schema (profile_PCNR.csv)
- `.planning/phases/06-distribution-engine/06-CONTEXT.md` — 13-column schema, var_class values,
  stat rows, small_cell_flag, display_format, NUM_TEXT/SUPPRESSED rows

### Existing Python patterns (reuse, do not reinvent)
- `python/pdd/xlsx_style.py` — HEADER_FILL, HEADER_FONT, ACCENT_FILL, write_table, style_sheet
- `python/pdd/pcnr_qc_workbook.py` — workbook structure, sheet order, KEY rows, assert_input,
  write_workbook, verify_workbook, read_csv patterns
- `python/scripts/write_pcnr_qc.py` — entry-point pattern: argparse, setup_logging, read CSVs,
  validate, write, verify, exit 0/1

### Name map schema
- `sas/04_name_map.sas` — actual columns in pdd.name_map / exchange/name_map.csv
  (READ this file before assuming NAME_MAP sheet columns)

### Display config files
- `docs/age_variables.csv` — 6 age variables subject to top-coding (variable, reason)
- `docs/profile_suppress.csv` — SUPPRESSED variable list
- `docs/profile_categorical.csv` — categorical override list

### Requirements
- `.planning/REQUIREMENTS.md` §PDD-07 (lines ~117–130) — formal requirements for Phase 7

### Config / paths
- `python/pdd/config.py` — EXCHANGE_PATH, QC_PATH, LOGS_PATH, OUT_PATH

</canonical_refs>

<specifics>
## Specific Requirements

### profile_PCNR.csv 13-column schema (from 06-CONTEXT.md)

| # | Column | Type | Width | Notes |
|---|--------|------|-------|-------|
| 1 | variable | $32 | 32 | PCNR_ variable name |
| 2 | var_class | $12 | 12 | LOW_CARD / CONT_NUM / HIGH_CARD / DATE / NUM_TEXT / SUPPRESSED |
| 3 | stat | $16 | 16 | LEVEL / N / N_MISSING / MEAN / SD / MEDIAN / Q1 / Q3 / MIN / MAX / N_DISTINCT / OTHER / MISSING / SUPPRESSED / N_UNPARSED |
| 4 | level | $100 | 100 | Level value for LEVEL rows; blank for STAT rows |
| 5 | sort_order | 8 | — | 0=N_DISTINCT, 1–10=top levels, 11=OTHER, 99=MISSING |
| 6 | n | 8 | — | Count or statistic value |
| 7 | pct_total | 8 | — | n / total_rows * 100; blank for STAT rows |
| 8 | pct_nonmiss | 8 | — | n / n_nonmiss * 100; blank on MISSING row |
| 9 | n_nonmiss | 8 | — | Non-missing count for this variable |
| 10 | n_distinct | 8 | — | Distinct non-missing count |
| 11 | small_cell_flag | $1 | 1 | Y / N / blank |
| 12 | display_format | $32 | 32 | SAS format name for DATE vars; blank otherwise. Do NOT apply to SD rows. |
| 13 | date_kind | $12 | 12 | DATE / DATETIME / TIME / blank |

### Workbook output path

`P:\PeCAN Master Data\Gerard\data_dictionary\out\pdd_v1_0.xlsx`

### Exchange inputs (Phase 7 reads)

| File | Written by | Notes |
|------|-----------|-------|
| `exchange/profile_PCNR.csv` | Phase 6 SAS | 13-column schema above |
| `exchange/name_map.csv` | Phase 5 SAS | ALL 4,795 rows; read columns from sas/04_name_map.sas |
| `exchange/source_inventory.csv` | Phase 7 SAS (new) | From pdd.source_inventory |

### Key counts (from Phase 6 production run)

- Total variables profiled: 1,297
- LOW_CARD: 1,097 | CONT_NUM: 123 | NUM_TEXT: 38 | HIGH_CARD: 29 | SUPPRESSED: 10
- Total prf_pcnr rows: 5,642
- All-missing vars: 56 (mostly LOW_CARD, n_distinct=0)
- Small-cell rows: 805 across 191 variables
- Vars with placeholder text: 136

</specifics>

<deferred>
## Deferred

- Non-PCNR family sheets (Phases 8–13): placeholder sheets only in v1.0.
- PCND_ recoding/cleaning of placeholder values (pending Price, Phase 13+).
- Per-cell provenance in workbook (pdd.qc_pcnr_provenance stays SAS-only).
- Price confirmation on small_cell_mode and age_topcode defaults — build as configurable settings,
  ship with defaults documented in KEY sheet pending confirmation.

</deferred>

---

*Phase: 07-dictionary-workbook-writer*
*Context gathered: 2026-10-26 via /gsd:discuss-phase 7*
