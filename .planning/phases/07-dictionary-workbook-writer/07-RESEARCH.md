# Phase 7: Dictionary Workbook Writer — Research

**Researched:** 2026-10-27
**Domain:** Python / openpyxl workbook generation from SAS exchange CSVs
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-22 LOCKED:** Python owns all xlsx output. SAS does not write xlsx.
- **D-09 LOCKED:** Sheet order: KEY | VARIABLES | DISTRIBUTIONS | NAME_MAP | SOURCES | QC | PCNC_ | PCND_ | CLK_ | LAB_ | MED_ | INTRA_
- Placeholder sheets (PCNC_ … INTRA_) show "(source pending)".
- `pcnr_name` column in VARIABLES is a hyperlink to the variable's first row on DISTRIBUTIONS.
- DISTRIBUTIONS: long format, all 5,642+ rows from profile_PCNR.csv, n and value in separate columns.
- Small-cell default: `small_cell_mode = "suppress"` — replace n with `"<11"`, blank pct_total / pct_nonmiss.
- Complementary suppression: if exactly one suppressed cell per variable, also suppress next-smallest non-zero n row.
- Age topcode default: `age_topcode = True`; variable list from `docs/age_variables.csv`; LEVEL values and STAT rows (MIN/MAX/MEDIAN/Q1/Q3) > 89 shown as `"90+"`; MEAN/SD unchanged.
- NAME_MAP: all 4,795 rows from exchange/name_map.csv; read columns from sas/04_name_map.sas.
- SOURCES: from pdd.source_inventory exported to exchange/source_inventory.csv; left-join docs/source_notes.csv.
- Python module: `python/pdd/dictionary_workbook.py` + entry point `python/scripts/write_dictionary.py`.
- SAS orchestrator: `sas/07_build_profile.sas` runs before Python.
- Display rules loaded from a config dict (not hard-coded); overridable at runtime.
- QC sheet: summary counts (n variables by var_class, n flagged small-cell, n SUPPRESSED, n all-missing).
- KEY sheet documents every sheet's purpose, every column, every display rule applied.
- UF blue `#0021A5` / orange `#FA4616` via existing `xlsx_style.py` constants.

### Claude's Discretion

- Summary text format for LOW_CARD variables: "top levels with %" — exact format (top N, separator, etc.) not locked.
- Complementary suppression tie-break when two rows share the same smallest non-suppressed n: policy not specified; Claude to decide and document in KEY.
- QC sheet layout: column choices and ordering not specified beyond "summary counts."
- Wave/task breakdown structure within the phase.

### Deferred Ideas (OUT OF SCOPE)

- Non-PCNR family sheets (Phases 8–13): placeholder sheets only in v1.0.
- PCND_ recoding/cleaning of placeholder values (Phase 13+).
- Per-cell provenance in workbook.
- Price confirmation on small_cell_mode and age_topcode defaults (build as configurable; ship with defaults).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDD-07-A | `07_build_profile.sas` exports source_inventory.csv; asserts freshness of profile_PCNR.csv and name_map.csv vs SAS dataset modate; asserts schema of all input CSVs | SAS DICTIONARY.TABLES modate pattern documented below |
| PDD-07-B | `python/pdd/dictionary_workbook.py` reads three exchange CSVs and writes `out/pdd_v1_0.xlsx` | Module pattern from pcnr_qc_workbook.py; openpyxl 3.1.5 confirmed |
| PDD-07-C | Sheet order, column specs, display rules per CONTEXT.md decisions | All locked decisions recorded above |
| PDD-07-D | Extend `docs/exchange_schema.csv` with Phase 7 input entries | Current schema columns confirmed; new entries documented below |
| PDD-07-E | `run_pipeline.cmd` integration: phase 7 SAS then Python when `7` in PDD_PHASES | Follows existing pattern |
</phase_requirements>

---

## Summary

Phase 7 has two distinct deliverables: a SAS orchestrator (`07_build_profile.sas`) that exports and validates exchange CSVs, and a Python module (`dictionary_workbook.py`) that writes the v1.0 xlsx workbook. The Python side is the dominant work. The existing `pcnr_qc_workbook.py` / `write_pcnr_qc.py` pair is the canonical pattern to follow; the new module is structurally identical but larger (more sheets, more complex display logic).

All key technical questions are now answered with HIGH confidence from code inspection and live openpyxl testing. The most critical verified finding: openpyxl internal hyperlinks (VARIABLES pcnr_name → DISTRIBUTIONS row) MUST use `Hyperlink(ref=cell_ref, location='DISTRIBUTIONS!AX')` — the string shortcut `'#DISTRIBUTIONS!AX'` creates an external relationship entry, not an internal location attribute, and will produce broken links in Excel.

**Primary recommendation:** Implement in four waves: (0) scaffold + tests, (1) SAS orchestrator, (2) Python core sheets (VARIABLES + DISTRIBUTIONS with suppression logic), (3) remaining sheets (NAME_MAP, SOURCES, QC, KEY, placeholders) + pipeline wiring.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| openpyxl | 3.1.5 (confirmed installed) | xlsx read/write | Project-standard; used in all existing Python workbook code |
| pandas | (project-installed) | CSV loading, merge, groupby for suppression | Already used in project; suitable for profile data |

No new libraries needed. All dependencies already present.

**Installation:** None required.

---

## Architecture Patterns

### Module layout (mirrors existing pattern exactly)

```
python/
├── pdd/
│   ├── dictionary_workbook.py    # core logic (new — mirrors pcnr_qc_workbook.py)
│   └── xlsx_style.py             # reuse unchanged
├── scripts/
│   └── write_dictionary.py       # entry point (new — mirrors write_pcnr_qc.py)
└── tests/
    └── test_dictionary_workbook.py  # new

sas/
└── 07_build_profile.sas          # new SAS orchestrator

docs/
└── source_notes.csv              # new optional lookup (s_code, description)
```

### Pattern: entry-point script (`write_dictionary.py`)

Mirrors `write_pcnr_qc.py` exactly:
- `argparse` with `--exchange`, `--out`, `--logs` (defaults from `config.py`)
- `setup_logging()` same implementation
- Read CSVs → validate → call `write_workbook()` → call `verify_workbook()` → exit 0/1
- PermissionError caught separately with "close the file in Excel and rerun" message

### Pattern: core module (`dictionary_workbook.py`)

```python
SHEET_ORDER = [
    "KEY", "VARIABLES", "DISTRIBUTIONS", "NAME_MAP",
    "SOURCES", "QC",
    "PCNC_", "PCND_", "CLK_", "LAB_", "MED_", "INTRA_",
]

def read_csv(path): ...          # same as pcnr_qc_workbook.py
def assert_input(sheet, hdrs, rows): ...   # column validation
def apply_suppression(df, config): ...     # small-cell + complementary
def apply_age_topcode(df, age_vars): ...   # topcode LEVEL + STAT rows
def build_variables_sheet(profile_df, namemap_df): ...
def build_distributions_sheet(profile_df): ...
def build_name_map_sheet(namemap_df): ...
def build_sources_sheet(inventory_df, notes_df): ...
def build_qc_sheet(profile_df): ...
def build_key_rows(): ...
def write_workbook(sheets, out_path): ...
def verify_workbook(path, expected): ...
```

### Pattern: openpyxl internal hyperlinks (VERIFIED)

**CRITICAL — tested against openpyxl 3.1.5:**

```python
from openpyxl.worksheet.hyperlink import Hyperlink

# Build DISTRIBUTIONS row index first (variable -> first row number, 1-based, header=row 1)
dist_row: dict[str, int] = {}   # pcnr_name -> row number in DISTRIBUTIONS sheet
for i, var in enumerate(dist_df['variable'].unique(), start=2):  # row 2 = first data row
    dist_row[var] = i  # mark only the FIRST occurrence

# Then when writing VARIABLES sheet:
cell = ws.cell(row=row_num, column=pcnr_name_col_idx, value=pcnr_name)
target_row = dist_row.get(pcnr_name)
if target_row:
    cell.hyperlink = Hyperlink(
        ref=cell.coordinate,
        location=f"DISTRIBUTIONS!A{target_row}",
    )
    cell.style = "Hyperlink"
```

**Do NOT use** `cell.hyperlink = '#DISTRIBUTIONS!A5'` — this creates an `r:id` relationship
(external URL type) in the XML and produces broken links. The `location=` attribute is the
correct internal-reference mechanism. Verified by inspecting saved xlsx XML.

No named ranges required. No `defined_names` needed. Direct `SheetName!CellRef` works.

### Pattern: complementary suppression algorithm

Given a variable's rows from profile_PCNR.csv (LEVEL/OTHER/MISSING stat types):

```python
def apply_complementary_suppression(var_rows: pd.DataFrame) -> pd.DataFrame:
    """
    After primary suppression (small_cell_flag='Y'), if exactly one row
    is suppressed, suppress the next-smallest non-zero n row too.

    Edge cases:
    - 0 suppressed: no complementary action.
    - 2+ suppressed: no complementary action (already safe).
    - All non-suppressed rows have n=0 (e.g. all-missing var): no complementary action.
    - Tie for smallest non-suppressed n: suppress ALL tied rows (conservative).
      Document this choice in KEY sheet.
    """
    suppressed_mask = var_rows['_primary_suppressed']
    n_suppressed = suppressed_mask.sum()
    if n_suppressed != 1:
        return var_rows
    candidates = var_rows[~suppressed_mask & (var_rows['n'] > 0)]
    if candidates.empty:
        return var_rows
    min_n = candidates['n'].min()
    # suppress ALL rows tied at min_n (conservative)
    var_rows.loc[candidates[candidates['n'] == min_n].index, '_comp_suppressed'] = True
    return var_rows
```

Rows eligible for suppression (primary or complementary): `stat` in `{LEVEL, OTHER, MISSING}`.
STAT rows (N, MEAN, SD, etc.) are never suppressed for count reasons.

### Pattern: age topcode

The `n` column in profile_PCNR.csv holds the **statistic value** for STAT rows, not a count.
For STAT rows where stat in `{MIN, MAX, MEDIAN, Q1, Q3}` and the variable is in the age list:

```python
AGE_STAT_ROWS = {'MIN', 'MAX', 'MEDIAN', 'Q1', 'Q3'}

def apply_age_topcode(df: pd.DataFrame, age_vars: set[str]) -> pd.DataFrame:
    mask_var = df['variable'].isin(age_vars)
    # LEVEL rows: level column holds the display value (string)
    mask_level = mask_var & (df['stat'] == 'LEVEL')
    df.loc[mask_level, 'level'] = df.loc[mask_level, 'level'].apply(
        lambda v: '90+' if _numeric_gt89(v) else v
    )
    # STAT rows: n column holds the numeric statistic value
    mask_stat = mask_var & df['stat'].isin(AGE_STAT_ROWS)
    df.loc[mask_stat, 'n'] = df.loc[mask_stat, 'n'].apply(
        lambda v: '90+' if _numeric_gt89(v) else v
    )
    return df

def _numeric_gt89(val) -> bool:
    try:
        return float(val) > 89
    except (TypeError, ValueError):
        return False
```

MEAN and SD rows: unchanged (stat not in AGE_STAT_ROWS). N, N_MISSING rows: unchanged.
LEVEL rows with value `> 89`: the topcode combines them into a single `"90+"` row.
If multiple LEVEL rows all map to `"90+"`, they must be aggregated (sum n, recalculate pcts).

### Pattern: summary text for LOW_CARD variables

Recommended format (Claude's discretion — document in KEY sheet):

```
"Yes 45.2%, No 52.1%, Missing 2.7%"   # top-3 non-OTHER levels + Missing, pct_total
```

Rules:
- Show top-3 levels by sort_order (sort_order 1–3), then MISSING row if present.
- If SUPPRESSED (small_cell after suppression), show `"<11"` instead of pct.
- All-missing variable: show `"No values (100% missing)"` (locked in CONTEXT.md).
- CONT_NUM: show `"N=X, Mean=Y, Median=Z, Min=A, Max=B"`.
- HIGH_CARD: show `"N distinct=X"` and top-3 levels.
- NUM_TEXT: show `"N parseable=X / N unparsed=Y"`.
- SUPPRESSED var_class: show `"Suppressed (n < threshold)"`.

---

## Name_map Sheet Columns (VERIFIED from 04_name_map.sas)

pdd.name_map columns (from Section 12, line 1835–1853):

| Column | Width | Notes |
|--------|-------|-------|
| s_code | $4 | Source file code |
| col_order | 8 | Column order within source file |
| sas_name | $32 | SAS column name in pdd.src_<s_code> |
| original_header | $256 | Raw source header text |
| trunc_flag | 8 | 1 when original header >= 256 chars |
| status | $20 | PCNR / KEY / EXCLUDED_CLK / LINKAGE_ONLY / DUPLICATE_DROPPED |
| group_id | 8 | Variable group identifier |
| pcnr_name | $32 | PCNR_ variable name (blank unless status=PCNR) |
| sas_type | $1 | N or C |
| length | 8 | SAS length |

Sort order for NAME_MAP sheet: s_code, then col_order (or original_header per CONTEXT — use col_order since it preserves source ordering). Autofilter on.

---

## Source_inventory Sheet Columns (VERIFIED from 02_source_guard.sas)

pdd.source_inventory columns (from Sections 12 + reassembly at line 1072):

| Column | Notes |
|--------|-------|
| file_id | Sequential 1–20 |
| s_code | s01–s20 |
| filename | Source file name (no path) |
| ftype | csv or xlsx |
| full_path | Full path on P: (do NOT show in SOURCES sheet per CONTEXT) |
| file_size | Bytes |
| mod_date | Last-modified string from FINFO (locale-dependent format) |
| sha256 | Full SHA-256 |
| sha256_old | SHA-256 of older copy or NO_OLD_COPY |
| old_copy_folder | master / raw / blank |
| old_copy_status | identical / different / no_older_copy |
| row_count | From import loop |
| col_count | From import loop |
| sheet_list | XLSX sheet names (blank for CSV) |
| import_status | profiled / read-failed |
| import_reason | Failure/warning reason |
| nonblank_row_count | s19 only |

SOURCES sheet: show s_code, filename, row_count, col_count, sha256[0:12], mod_date, description (from source_notes.csv join). Exclude full_path (contains P: path).

pdd.source_inventory EXISTS from Phase 2. 07_build_profile.sas only needs to EXPORT it to exchange/source_inventory.csv — no new SAS creation needed.

---

## SAS Orchestrator: 07_build_profile.sas

### Freshness check approach (VERIFIED — use DICTIONARY.TABLES)

SAS `DICTIONARY.TABLES` provides `modate` (last-modified datetime) for SAS datasets. Compare against CSV file modification time via `%sysfunc(finfo(...,'Last Modified'))`.

Problem: `finfo` returns locale-dependent string; comparison with `modate` (SAS datetime) requires parsing. Simpler and more reliable approach used in practice:

```sas
/* Get SAS dataset modate as SAS datetime */
proc sql noprint;
  select modate into :_pcnr_modate trimmed
  from dictionary.tables
  where libname='PDD' and memname='PCNR';
quit;

/* Get CSV file mtime via FINFO */
filename _csvf "&exchange_path.\profile_PCNR.csv";
%let _fid = %sysfunc(fopen(_csvf));
%let _csv_mtime_str = %sysfunc(finfo(&_fid, Last Modified));
%let _rc = %sysfunc(fclose(&_fid));
filename _csvf clear;

/* Compare: convert modate to date8 string, compare year/month/day only
   OR write CSV mtime to a work dataset and compare numerically */
```

Recommended: export modate from DICTIONARY.TABLES as a SAS datetime numeric. Parse the CSV's Last Modified string with `input(..., anydtdtm.)` (if SAS parses locale format) or just compare dates at day granularity using `datepart()`. If locale causes parse failures, fall back to: assert CSV mod date >= dataset create date (less precise but robust).

Alternative simpler approach: use `%sysfunc(finfo())` for both — store expected file list with expected dates in a macro table and check each CSV exists and is non-zero size. Strict date-based freshness is complex in SAS; the CONTEXT says "hard FAIL if CSV older than SAS dataset" — use DICTIONARY.TABLES modate (SAS datetime) vs. file FINFO mod date string parsed with `input(scan(mtime_str,...), date9.)`.

### Schema assertion approach

Reuse `docs/exchange_schema.csv` pattern: PROC IMPORT the CSV header row, compare against expected columns list. Fail with ERROR if any required column missing. This is consistent with how Phase 5/6 validate inputs.

### Export source_inventory.csv

```sas
proc export data=pdd.source_inventory
  outfile="&exchange_path.\source_inventory.csv"
  dbms=csv replace;
run;
```

Guard with `%if not %sysfunc(fileexist(...)) %then` to skip re-export if fresh.

---

## Exchange Schema Extension

Add these rows to `docs/exchange_schema.csv` (current format: file,column,type,required):

```
profile_PCNR.csv,variable,str,Y
profile_PCNR.csv,var_class,str,Y
profile_PCNR.csv,stat,str,Y
profile_PCNR.csv,level,str,Y
profile_PCNR.csv,sort_order,int,Y
profile_PCNR.csv,n,float,Y
profile_PCNR.csv,pct_total,float,N
profile_PCNR.csv,pct_nonmiss,float,N
profile_PCNR.csv,n_nonmiss,int,Y
profile_PCNR.csv,n_distinct,int,Y
profile_PCNR.csv,small_cell_flag,str,Y
profile_PCNR.csv,display_format,str,N
profile_PCNR.csv,date_kind,str,N
name_map.csv,s_code,str,Y
name_map.csv,col_order,int,Y
name_map.csv,sas_name,str,Y
name_map.csv,original_header,str,Y
name_map.csv,trunc_flag,int,N
name_map.csv,status,str,Y
name_map.csv,group_id,int,N
name_map.csv,pcnr_name,str,N
name_map.csv,sas_type,str,N
name_map.csv,length,int,N
source_inventory.csv,s_code,str,Y
source_inventory.csv,filename,str,Y
source_inventory.csv,row_count,int,N
source_inventory.csv,col_count,int,N
source_inventory.csv,sha256,str,N
source_inventory.csv,mod_date,str,N
```

Note: `n` in profile_PCNR.csv is `float` (not int) because STAT rows (MEAN, SD, MEDIAN, etc.) hold decimal values. `pct_total` and `pct_nonmiss` are `N` required because they are blank for STAT rows.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CSV reading with BOM | raw `open()` | `csv.DictReader` with `encoding='utf-8-sig'` | Matches existing `read_csv()` in pcnr_qc_workbook.py |
| Header/freeze/autofit | custom loop | `style_sheet(ws)` from xlsx_style.py | Already implemented; covers all sheets |
| Column width | manual pixel calc | `autofit_columns()` from xlsx_style.py | Already implemented |
| Int coercion | per-column try/except | `write_table(..., int_cols=...)` | Already implemented |
| Internal hyperlinks | string `#Sheet!Ref` | `Hyperlink(ref=, location=)` | String approach creates broken external rel (verified) |

---

## Common Pitfalls

### Pitfall 1: Wrong hyperlink type for internal references
**What goes wrong:** `cell.hyperlink = '#DISTRIBUTIONS!A5'` silently creates an `r:id`-based relationship that Excel treats as an external URL. Link appears blue but does not navigate within the workbook.
**Why it happens:** openpyxl accepts any string as hyperlink and stores it as an external `rId`; only the `Hyperlink(location=)` attribute produces an internal reference in the XML.
**How to avoid:** Always use `Hyperlink(ref=cell.coordinate, location='SheetName!CellRef')`.
**Warning signs:** XML contains `r:id="rId..."` on the hyperlink element instead of `location="..."`.

### Pitfall 2: n column is float for STAT rows
**What goes wrong:** Casting the entire `n` column to int breaks MEAN/SD/MEDIAN rows (e.g., 72.3 becomes 72).
**How to avoid:** Keep `n` as object/str in the DataFrame during processing; only coerce to numeric where stat is a count type (N, N_MISSING, N_DISTINCT, N_UNPARSED) when displaying. For the xlsx output, write `n` as-is (float or string depending on row type).

### Pitfall 3: Age topcode aggregation for LEVEL rows
**What goes wrong:** If multiple LEVEL rows have values > 89 (e.g., 90, 91, 92, 93), naively replacing each with "90+" creates duplicate LEVEL rows. Excel reader sees multiple "90+" rows for one variable.
**How to avoid:** After topcode substitution, group by (variable, level) and sum n; recalculate pct_total and pct_nonmiss for the merged "90+" row. Only then write to DISTRIBUTIONS.

### Pitfall 4: DISTRIBUTIONS row index built after suppression/topcode
**What goes wrong:** Hyperlink row numbers computed before display transformations shift rows (if any rows are dropped or merged, e.g., topcode aggregation). VARIABLES hyperlinks point to wrong rows.
**How to avoid:** Build the DISTRIBUTIONS DataFrame in final display order first; compute `dist_row` dict from that final DataFrame; write VARIABLES sheet using those final row numbers.

### Pitfall 5: source_notes.csv absent breaks SOURCES sheet
**What goes wrong:** `pd.read_csv('source_notes.csv')` raises FileNotFoundError and crashes the run.
**How to avoid:** Wrap in `try/except`; if absent, `notes_df = pd.DataFrame(columns=['s_code','description'])`. Left-join still works; description column just stays blank.

### Pitfall 6: pdd.name_map `col_order` column type
**What goes wrong:** PROC EXPORT writes numeric `col_order` which csv.DictReader reads as string. Sorting by col_order lexicographically ("10" < "2") gives wrong order.
**How to avoid:** `sorted(rows, key=lambda r: int(r['col_order']))` when sorting NAME_MAP rows.

### Pitfall 7: SAS `finfo` mod_date locale format
**What goes wrong:** `finfo(_fid, 'Last Modified')` returns locale-dependent string (e.g. "10/27/2026 14:30:00" on US Windows). `input(..., anydtdtm.)` may fail on some locales.
**How to avoid:** In `07_build_profile.sas`, use DICTIONARY.TABLES modate (already a SAS datetime numeric) for the SAS dataset side. For CSV freshness, compare datepart of modate vs. datepart of file mod parsed with `input(scan(mdate,1,'/'), ?? 8.)` — or simply assert CSV mtime string is later by string compare after formatting modate with `put(modate, datetime20.)`. Document any locale assumption in a NOTE.

---

## Code Examples

### Verified: internal hyperlink (openpyxl 3.1.5)
```python
# Source: live test against installed openpyxl 3.1.5
from openpyxl.worksheet.hyperlink import Hyperlink

cell = ws.cell(row=2, column=1, value="PCNR_Age_at_Encounter")
cell.hyperlink = Hyperlink(
    ref=cell.coordinate,       # e.g. "A2"
    location="DISTRIBUTIONS!A5",  # no # prefix; no quotes around sheet name needed if no spaces
)
cell.style = "Hyperlink"      # blue underline
```

### Verified: read_csv pattern (from pcnr_qc_workbook.py — reuse unchanged)
```python
def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)
        headers = list(reader.fieldnames or [])
    return headers, rows
```

### Verified: write_table call pattern
```python
from pdd.xlsx_style import write_table, style_sheet

# int_cols: 0-based column indices to coerce to int
int_col_set = frozenset(i for i, h in enumerate(headers) if h in INT_COLUMN_NAMES)
write_table(ws, headers, data_rows, int_cols=int_col_set)
style_sheet(ws)
```

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest (already installed; used in Phases 4–6) |
| Config file | none — `python -m pytest python/tests/` |
| Quick run command | `pytest python/tests/test_dictionary_workbook.py -x` |
| Full suite command | `pytest python/tests/` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PDD-07-B hyperlink | Hyperlink(location=) produces internal ref in XML | unit | `pytest python/tests/test_dictionary_workbook.py::test_hyperlink_is_internal -x` | No — Wave 0 |
| PDD-07-B suppression | Primary suppression replaces n with <11 | unit | `pytest python/tests/test_dictionary_workbook.py::test_primary_suppression -x` | No — Wave 0 |
| PDD-07-B comp suppression | Complementary fires on exactly-1-suppressed variables | unit | `pytest python/tests/test_dictionary_workbook.py::test_complementary_suppression -x` | No — Wave 0 |
| PDD-07-B topcode | LEVEL and STAT rows > 89 become "90+" for age vars | unit | `pytest python/tests/test_dictionary_workbook.py::test_age_topcode -x` | No — Wave 0 |
| PDD-07-B topcode agg | Multiple LEVEL > 89 rows merged into one "90+" row | unit | `pytest python/tests/test_dictionary_workbook.py::test_age_topcode_aggregation -x` | No — Wave 0 |
| PDD-07-B sheet order | Workbook sheets match SHEET_ORDER exactly | unit | `pytest python/tests/test_dictionary_workbook.py::test_sheet_order -x` | No — Wave 0 |
| PDD-07-B row counts | DISTRIBUTIONS rows match profile_PCNR.csv after transforms | unit | `pytest python/tests/test_dictionary_workbook.py::test_distributions_row_count -x` | No — Wave 0 |
| PDD-07-B sources | SOURCES renders without source_notes.csv present | unit | `pytest python/tests/test_dictionary_workbook.py::test_sources_no_notes -x` | No — Wave 0 |

### Wave 0 Gaps
- [ ] `python/tests/test_dictionary_workbook.py` — new file; all tests above

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| openpyxl | xlsx output | Yes | 3.1.5 | — |
| Python | all Python steps | Yes | confirmed | — |
| pdd.source_inventory | SOURCES sheet | Yes (Phase 2 output) | — | — |
| exchange/name_map.csv | NAME_MAP sheet | Yes (Phase 5 output) | — | — |
| exchange/profile_PCNR.csv | VARIABLES + DISTRIBUTIONS | Yes (Phase 6 output) | — | — |
| docs/source_notes.csv | SOURCES descriptions | No (new file to create) | — | Optional; sheet renders without it |
| docs/age_variables.csv | age topcode | Yes | — | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:**
- `docs/source_notes.csv` — does not exist yet; must be created (can be empty with headers `s_code,description`). The SOURCES sheet renders without it.

---

## Open Questions

1. **Complementary suppression tie: suppress all ties or only one?**
   - What we know: CONTEXT.md says "next-smallest non-zero cell" (singular).
   - What's unclear: if two cells tie for smallest non-suppressed n, suppress both or pick one?
   - Recommendation: suppress all tied cells (conservative); document in KEY sheet. No Price input needed since this is the safer choice.

2. **Name_map sort: col_order or original_header?**
   - CONTEXT.md says "sorted by s_code then original_header" but col_order preserves source file ordering.
   - Recommendation: sort by s_code then col_order (matches source intent); note in KEY.

3. **SUPPRESSED var_class rows in DISTRIBUTIONS: emit the 5 stat rows (N_DISTINCT, RANGE_MIN, RANGE_MAX, N, MISSING) as-is?**
   - What we know: Phase 6 emits those 5 stat rows for SUPPRESSED vars (no LEVEL rows).
   - Recommendation: yes, display as-is; no suppression logic applies (no count cells).

4. **QC sheet: one row per var_class or aggregated summary?**
   - CONTEXT.md: "summary counts (n variables by var_class, n flagged small-cell, n SUPPRESSED, n all-missing)".
   - Recommendation: two tables on QC sheet: (a) var_class counts, (b) summary scalars (n_small_cell_vars, n_suppressed_vars, n_all_missing_vars).

---

## Sources

### Primary (HIGH confidence)
- `python/pdd/pcnr_qc_workbook.py` — canonical module pattern, read_csv, write_table, verify_workbook
- `python/pdd/xlsx_style.py` — style constants and helpers
- `python/scripts/write_pcnr_qc.py` — entry-point pattern
- `python/pdd/config.py` — EXCHANGE_PATH, OUT_PATH, LOGS_PATH, QC_PATH, DOCS_PATH
- `sas/04_name_map.sas` lines 1835–1864 — pdd.name_map column definitions (verified)
- `sas/02_source_guard.sas` lines 524–553, 1072–1085 — pdd.source_inventory columns (verified)
- `docs/exchange_schema.csv` — current schema format (file, column, type, required)
- `docs/age_variables.csv` — 6 age variables subject to topcode
- Live openpyxl 3.1.5 test — hyperlink XML behavior verified

### Secondary (MEDIUM confidence)
- openpyxl docs: `Hyperlink(location=)` is the standard internal reference attribute per OOXML spec

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed installed; versions verified
- Architecture: HIGH — mirrors existing pattern directly; no new design decisions
- openpyxl hyperlink: HIGH — verified by XML inspection of saved file
- Suppression algorithm: HIGH — logic follows CONTEXT.md exactly; edge cases reasoned from spec
- Age topcode: HIGH — stat names confirmed from 06-CONTEXT.md schema table
- SAS freshness: MEDIUM — DICTIONARY.TABLES modate is standard SAS; finfo string format is locale-dependent
- name_map columns: HIGH — read directly from 04_name_map.sas Section 12
- source_inventory columns: HIGH — read directly from 02_source_guard.sas

**Research date:** 2026-10-27
**Valid until:** 2026-11-27 (stable libraries; openpyxl API unlikely to change)
