# Phase 2: Source Guard and Header Inventory — Research

**Researched:** 2026-10-19
**Domain:** SAS 9.4 file I/O, SHA-256 hashing, XLSX engine, metadata collection, candidate key analysis
**Confidence:** HIGH (all core findings drawn from the reference project's working code)

---

## Summary

Phase 2 produces a read-only audit of all 20 shared-folder source files: SHA-256 checksums,
per-file metadata, per-column inventory, candidate key grain analysis, ID overlap counts
against the s09 spine candidate, and a hash comparison against older copies in the `raw\master`
staging folder. Every technique needed is already demonstrated in the reference project's
`19_raw_dir_inventory.sas`, `15_id_overlap.sas`, and the seed programs.

The new program differs from the reference in three important ways:
1. It operates on all 20 sources directly (not on renamed SAS datasets).
2. SHA-256 must work on binary files (CSV and XLSX) — `certutil` through an INFILE PIPE
   FILEVAR= loop is the established pattern and handles both types identically.
3. No `g` library exists; outputs go straight to `pdd` library and `qc\`.

The reference project's compliance rules (PCM) apply here: no open-code `%IF`, all
conditional logic in named macros, `%abort cancel` only inside `%fail_out`, no apostrophes
in `%put` text, no PROC SQL UPDATE, and `dictionary.columns.type` returns `'char'`/`'num'`
(not 1/2).

**Primary recommendation:** Adapt `19_raw_dir_inventory.sas` directly. The import loop,
SHA-256 pattern, XLSX engine sheet enumeration, metadata collection via FINFO, and key-column
detection are all proven in that file. Build Phase 2 as a single `02_source_guard.sas` using
a macro loop over the 20 files rather than 20 separate DATA steps.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDD-02-R1 | SHA-256 of all 20 files; abort if any changes from baseline | certutil PIPE FILEVAR= pattern (Section 5 of 19_raw_dir_inventory.sas) |
| PDD-02-R2 | Per-file metadata: SHA-256, file size, modified date, row count, column count; sheet list for xlsx | FINFO pattern + XLSX libname + dictionary.tables/columns |
| PDD-02-R3 | Candidate key analysis per file: ID columns present, grain (unique vs. multi-row) | dictionary.columns name/label scan + PROC SQL COUNT DISTINCT |
| PDD-02-R4 | ID overlap: match counts against s09 spine per candidate key | PROC SQL left join from imported s09 PRECEDE_STUDY_IDs to each file |
| PDD-02-R5 | Hash comparison against older copies in raw\master | Second certutil pass on the older path; three-way status: identical/different/no older copy |
| PDD-02-R6 | Header x file matrix across all 20 files | dictionary.columns in the import loop, written as long-format pdd.header_matrix |
| PDD-02-R7 | Re-check prior expectations (~701 headers, ~168 unique vars, ~41,150-row spine) | Count rows/columns in the import loop output; compare in assertions |
| PDD-02-R8 | Outputs written to pdd library and qc\ | pdd.source_inventory, pdd.header_matrix, qc\source_inventory.xlsx, qc\header_matrix.xlsx |
</phase_requirements>

---

## Standard Stack

### Core (SAS 9.4 built-ins only — no external packages)

| Facility | Purpose | Notes |
|----------|---------|-------|
| `certutil -hashfile "path" SHA256` via `INFILE PIPE FILEVAR=` | SHA-256 of any file, binary or text | Windows-native; no SAS HASHING function needed; handles CSV and XLSX identically |
| `FILENAME('ref', path)` + `FOPEN`/`FINFO`/`FCLOSE` | File size and last-modified date | `FINFO(_fid, 'File Size (bytes)')` and `FINFO(_fid, 'Last Modified')` |
| `LIBNAME('_xlw', path, 'xlsx')` + `dictionary.members` | Sheet list for XLSX files | `WHERE memtype='DATA'` gives sheet names as SAS memnames |
| `PROC IMPORT dbms=csv` from a fileref | CSV row/column counts | Faster than reading with INFILE; `GUESSINGROWS=MAX`; `options nosyntaxcheck noerrorabend` MUST precede |
| `dictionary.tables` + `dictionary.columns` | Row counts, column counts, types, labels post-import | The authoritative metadata source after any import |
| `PROC SQL COUNT DISTINCT` | Grain test (unique vs. multi-row per key) | Compare `COUNT(*)` to `COUNT(DISTINCT key_col)` |
| `ODS EXCEL` with `style=styles.uf_inventory` | Output workbooks with UF colors | Custom PROC TEMPLATE block required; pattern in reference Section 15 |

### No External Dependencies

This phase requires no additional `npm install`, Python packages, or third-party SAS macros.
All capabilities are base SAS 9.4 on Windows.

---

## Architecture Patterns

### Recommended Program Structure for `02_source_guard.sas`

```
SECTION 0   Header, %include "C:\data_dictionary\sas\00_config.sas", options
SECTION 1   Utility macros: %route_log, %restore_log, %fail_out, %check_dir
SECTION 2   Preconditions: verify raw_master and qc\ directories exist
SECTION 3   Build work.file_list — 20 rows, one per source (filename, s_code, path)
SECTION 4   File metadata loop — FOPEN/FINFO for size and modified date
SECTION 5   SHA-256 loop — certutil PIPE FILEVAR= over full paths
SECTION 6   Import loop — CSV via PROC IMPORT, XLSX via XLSX libname; collect
              row counts, col counts, sheet lists
SECTION 7   Older-copy hash comparison — certutil on raw\master copies
SECTION 8   Candidate key detection — dictionary.columns name/label scan per
              imported table; key_column_type assignment
SECTION 9   Grain test — COUNT(*) vs COUNT(DISTINCT key) per file/key
SECTION 10  ID overlap — read s09 spine PRECEDE_STUDY_IDs; left-join each file
SECTION 11  Hash baseline: first-run seed vs. re-run guard
SECTION 12  Assemble pdd.source_inventory (one row per file)
SECTION 13  Assemble pdd.header_matrix (one row per file x column)
SECTION 14  Write qc\source_inventory.xlsx and qc\header_matrix.xlsx via ODS EXCEL
SECTION 15  Output verification: assert all pdd datasets and xlsx files exist
SECTION 16  Log restore
```

### Pattern 1: certutil SHA-256 via INFILE PIPE FILEVAR=

The reference project's Section 5 is the authoritative implementation. Key points:
- `_cmd = 'certutil -hashfile "' || strip(full_path) || '" SHA256';`
- Loop reads all lines; the hash line is the one where `compress(line,' ')` is exactly 64
  hex characters (`notxdigit(strip(compressed)) = 0`).
- `sha256 = 'FAILED'` is set before the loop; if the 64-char line is never found, the
  sentinel stays.
- FILEVAR= drives a new pipe per file; no shell escaping of paths needed as long as paths
  are quoted with double-quotes in the command string.
- Works identically for CSV and XLSX — certutil reads the raw bytes.

```sas
/* Source: _reference_old/sas/19_raw_dir_inventory.sas, Section 5 */
data work.sha_results;
  set work.file_list(keep=file_id full_path);
  length _cmd $1000 line $400 compressed $400 sha256 $64;
  _cmd   = 'certutil -hashfile "' || strip(full_path) || '" SHA256';
  sha256 = 'FAILED';
  infile ckpipe pipe filevar=_cmd end=_done truncover lrecl=400;
  do while (not _done);
    input line $400.;
    compressed = compress(line, ' ');
    if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
      sha256 = lowcase(compressed);
  end;
  if sha256 = 'FAILED' then put 'WARNING: SHA-256 FAILED for ' full_path=;
  keep file_id sha256;
run;
```

### Pattern 2: XLSX Sheet Enumeration via XLSX Libname

```sas
/* Source: _reference_old/sas/19_raw_dir_inventory.sas, Section 6 */
data _null_;
  set work.file_list(where=(file_id = &i));
  _rc = libname('_xlw', full_path, 'xlsx');
run;
%if %sysfunc(libref(_xlw)) ne 0 %then %do;
  /* locked or corrupt */
%end;
%else %do;
  proc sql noprint;
    create table work._sheetlist as
    select memname as sheet_name length=200
    from dictionary.members
    where libname = '_XLW' and memtype = 'DATA';
    select count(*) into :nsheets trimmed from work._sheetlist;
  quit;
%end;
```

**Critical detail — case sensitivity of sheet names with the XLSX engine:**
Dictionary.members returns UPPERCASE memnames. Sheet names that start with a
letter/underscore should be referenced as unquoted SAS names (case-insensitive resolution,
no engine case-sensitivity issue). Sheet names that start with a digit require a name
literal with `%unquote(%superq(...))` to strip macro-quoting bytes before the literal is
built. See reference Section 6, lines 341–385 for the full if/else pattern. For Phase 2,
`2018_2019_Precede_Database.xlsx` is the only file with multiple sheets and the sheet names
are expected to start with letters, so the unquoted form should work. Still implement the
same two-branch guard as the reference for safety.

### Pattern 3: File Metadata via FOPEN/FINFO

```sas
/* Source: _reference_old/sas/19_raw_dir_inventory.sas, Section 3 */
data work.files_meta;
  set work.file_list;
  length fsize 8 fdate $30;
  _rc = filename('_fr_', full_path);
  _fid = fopen('_fr_');
  if _fid > 0 then do;
    fsize = input(finfo(_fid, 'File Size (bytes)'), best32.);
    fdate = finfo(_fid, 'Last Modified');
    _rc   = fclose(_fid);
  end;
  else do;
    fsize = .;
    fdate = 'UNKNOWN';
  end;
  _rc = filename('_fr_');   /* clear the fileref */
  drop _rc _fid;
run;
```

### Pattern 4: Hash Baseline — Seed vs. Guard Split

The reference project uses TWO programs: one that seeds the baseline (`19b`) and one that
guards against drift (`19` Section 13). For Phase 2, both functions live in the same
`02_source_guard.sas`:

- **First run (no baseline file):** compute hashes, write `docs/source_guard_baseline.csv`,
  log `NOTE: baseline seeded`. Do NOT abort on first run.
- **Subsequent runs:** read baseline, compare. If any hash differs, `%fail_out`.
- The guard on "do not overwrite a valid baseline" is: count data rows in the CSV; if
  rows > 0, skip the write and proceed to the comparison instead.

This two-branch logic must be inside a macro (no open-code `%IF`).

Baseline file location: `C:\data_dictionary\docs\source_guard_baseline.csv` (C: drive,
version-controlled, no PHI — contains only filenames and hex strings).

### Pattern 5: Key-Column Detection

Adapted from reference Section 8. For Phase 2 the relevant key types are:

| key_column_type | Match criteria |
|-----------------|----------------|
| PRECEDE_STUDY_ID | `compress(upcase(name),' _-')` in ('PRECEDESTUDYID','STUDYID') OR same on label |
| ENCRYPTED_MRN | `compress(upcase(name),' _-') = 'ENCRYPTEDMRN'` OR contains 'ENCRYPTED' and 'MRN' |
| ENCRYPTED_ENCOUNTER | Contains 'ENCRYPTED' and 'ENCOUNTER' |
| UNENC_MRN | bare MRN |
| UNENC_ENCOUNTER | bare ENCOUNTER or ENCOUNTERID |

The reference uses a `match_basis` flag (name / loose / label) to distinguish exact name
matches from label-derived matches — carry this over as it is useful for deciding PDD-D-18.

### Pattern 6: Grain Test

```sas
/* For each file x candidate key, produce one row */
proc sql noprint;
  select count(*) into :n_rows trimmed from work.&dsname;
  select count(distinct &keyvar) into :n_dist trimmed
    from work.&dsname
    where &keyvar is not missing;
quit;
/* grain = 'unique' if n_rows = n_dist; 'multi-row' otherwise */
```

### Pattern 7: ID Overlap Against s09 Spine

The spine (s09, `2018_2022_X_MASTER_DATASET_20240402.csv`) must be imported first. Then
for each file x candidate key:

```sas
proc sql noprint;
  select count(distinct f.&keyvar) into :n_match trimmed
  from work.spine_ids s
  inner join work.&dsname f
    on strip(upcase(s.PRECEDE_STUDY_ID)) = strip(upcase(f.&keyvar))
  where f.&keyvar is not missing;
quit;
```

Store: n_in_file (non-missing key values), n_in_spine (n_match), pct_overlap.

### Anti-Patterns to Avoid

- **Open-code `%IF/%THEN`:** Every conditional must be inside a named macro. Bare `%IF` in
  open code requires a `%DO` block; missing it causes SAS to skip the rest of the file
  silently. (Reference header comments confirm this burned the old project.)
- **Apostrophes or semicolons in `%put` text:** Use `%str(,)` for commas and rephrase
  possessives to avoid apostrophes.
- **`dictionary.columns.type` comparison with 1/2:** The type column returns `'char'` and
  `'num'` (strings), not integers. `where type = 'char'` is correct; `where type = 1` is
  not.
- **PROC SQL UPDATE:** Not a PCM-compliant operation. Use `data work.new; set work.old;`
  with conditional logic instead.
- **In-place dataset rewrite (`data X; set X; run;`):** Always write to a new name, then
  rename or replace.
- **`options nosyntaxcheck noerrorabend` omitted before PROC IMPORT:** A failed PROC IMPORT
  without these options sets a non-zero `&syscc` that can cascade and abort the rest of the
  program. Set both before any PROC IMPORT call; reset `&syscc = 0` after.
- **Quoting inside `%sysfunc(fileexist(...))`:** Do not put literal quotes inside the
  parentheses. Use a macro variable: `%let _p = &qc_path.\file.xlsx; %sysfunc(fileexist(&_p))`.
- **Embedding PROC inside DATA step:** Not valid. Use `call symputx` in the DATA step to
  capture values, then run the PROC after.
- **Relying on `&sqlobs` for counts:** Use explicit `SELECT COUNT(*) INTO :macvar TRIMMED`
  instead.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SHA-256 of binary files | HASHING function + FOPEN/FREAD chunk loop | `certutil` via PIPE FILEVAR= | certutil handles binary files (CSV and XLSX) identically; the HASHING function in a DATA step requires careful chunk sizing and encoding mode to avoid truncating binary content — the reference project uses certutil for exactly this reason |
| Sheet list for XLSX | Trying to parse the XLSX zip structure | XLSX libname + `dictionary.members where memtype='DATA'` | Handles multi-sheet files of any size; proven on the 200 MB 2018_2019_Precede_Database.xlsx in the reference project |
| Row/column counts | Counting in a DATA step after import | `dictionary.tables` (nobs, nvar) post-import | One SQL query; no extra pass through the data |
| ODS Excel with UF colors | Custom CSV + post-processing | ODS EXCEL + PROC TEMPLATE with `backgroundcolor=cx0021A5` | The reference's Section 15 already has the exact PROC TEMPLATE block needed |

---

## Common Pitfalls

### Pitfall 1: XLSX Engine Case-Sensitivity on Sheet Names
**What goes wrong:** `dictionary.members` returns sheet names in UPPERCASE. Using them as
name literals (`"SHEET1"n`) passes the uppercase string to the XLSX engine, which then
fails to find the tab because the actual tab name is mixed case (e.g., "Sheet1").
**Why it happens:** The XLSX engine is case-sensitive for name literal references but
case-insensitive for unquoted SAS identifiers.
**How to avoid:** For sheet names that start with a letter/underscore (the common case), use
the unquoted form: `set _xlw.&&_sh&j;` — SAS resolves it case-insensitively. For
digit-prefix names, use `%unquote(%superq(...))` to strip macro-quoting bytes, then build
the name literal. See reference Section 6 lines 341–385.
**Warning signs:** `ERROR: File _XLW.SHEET1.DATA does not exist.` in the log when the
workbook opens fine.

### Pitfall 2: `options nosyntaxcheck noerrorabend` Omitted Before PROC IMPORT
**What goes wrong:** A PROC IMPORT failure on a large file (e.g., ALL_AIM2 with ~1M rows)
sets `&syscc` to a non-zero value. Subsequent SAS steps then abort silently.
**Why it happens:** SAS treats a non-zero `&syscc` as a prior failure and skips subsequent
steps.
**How to avoid:** Always place `options nosyntaxcheck noerrorabend;` before any PROC IMPORT
call. After the import, call `%eval_import(target=work.&dsname)` — the reference's macro
that reads `&syserr` — then set `%let syscc = 0;`.
**Warning signs:** Steps after the PROC IMPORT produce no output and no ERROR in the log;
only a NOTE about `syscc`.

### Pitfall 3: certutil Pipe Fails Silently on Locked Files
**What goes wrong:** If a file is open in another application (Excel lock file `~$name.xlsx`),
certutil cannot read it and the pipe produces only error text — no 64-char hex line.
**Why it happens:** The PIPE DATA step loops until `end=_done`, reads whatever certutil
writes (which is an error message, not a hash), and leaves `sha256 = 'FAILED'`.
**How to avoid:** After the SHA-256 DATA step, assert that no `sha256 = 'FAILED'` rows exist
for the 20 required files. Emit a `WARNING:` for lock files (which are identified by the
`~$` prefix) but treat them as non-data. The reference uses the `ftype = 'lockfile'`
classification in Section 3 to skip them before hashing.
**Warning signs:** `WARNING: SHA-256 FAILED for [path]` in the log.

### Pitfall 4: PROC IMPORT on ALL_AIM2.xlsx (~1M Rows, ~1 GB)
**What goes wrong:** PROC IMPORT with `GUESSINGROWS=MAX` on a ~1M-row XLSX file can be
extremely slow (tens of minutes) or run out of memory, producing a partially imported
dataset or an ERROR.
**Why it happens:** `GUESSINGROWS=MAX` reads every row to determine column types. On a
200+ MB XLSX this is prohibitively expensive.
**How to avoid:** For XLSX files, use the XLSX libname engine directly (not PROC IMPORT):
`libname _xlw path 'xlsx'; data work.ds; set _xlw.Sheet1; run;`. This streams the data
without a type-guessing pass. For ALL_AIM2, the known issue is that PRECEDE_STUDY_ID may
import as numeric — detect this via `dictionary.columns type` and document it.
**Warning signs:** SAS log shows `NOTE: 1,048,575 records were read from ...` or the
program appears to hang.

### Pitfall 5: Baseline File on the Network Drive
**What goes wrong:** Placing `source_guard_baseline.csv` on P: means it is outside git,
and a change to the shared-folder files cannot be detected across machines or after a disk
restore.
**Why it happens:** Convenience — writing everything to P: is the default pattern.
**How to avoid:** The baseline lives at `C:\data_dictionary\docs\source_guard_baseline.csv`
(C: drive, version-controlled). This is identical to the reference project's
`docs/raw_hash_baseline.csv` placement. No PHI: the file contains only filenames and
64-character hex strings.
**Warning signs:** `%sysfunc(fileexist(&docs_path.\...))` checks would pass but the file is
absent from git and cannot prove baseline integrity.

### Pitfall 6: Duplicate PRECEDE_STUDY_ID Header in s15 and s17
**What goes wrong:** Earlier copies of `2021_X_MASTER_DATASET_20230512.csv` (s15) and
`2022_MASTER_DATASET_20231024.csv` (s17) had two columns named `PRECEDE Study ID` and
`PRECEDE_STUDY_ID`. PROC IMPORT renamed the duplicate to `PRECEDE_STUDY_ID1`, silently
dropping the original column name from one of them.
**Why it happens:** The source query that generated these files included the ID column
twice. The shared-folder originals may or may not have the same issue.
**How to avoid:** After importing s15 and s17, check `dictionary.columns` for any column
whose name or label contains 'STUDYID' with a numeric suffix. Log a WARNING if found;
document it in `pdd.source_inventory`.
**Warning signs:** A column named `PRECEDE_STUDY_ID1` or `PRECEDE_STUDY_ID2` in the
imported dataset.

### Pitfall 7: FINFO String for 'Last Modified' Is Locale-Dependent
**What goes wrong:** The exact string returned by `FINFO(_fid, 'Last Modified')` varies by
Windows locale and SAS configuration. On some systems it returns the Windows file timestamp
directly; on others it returns a SAS-formatted string.
**Why it happens:** FINFO is a thin wrapper around the OS file handle, and the string name
for the metadata field is not standardized across SAS platforms.
**How to avoid:** Store `fdate` as a raw character value (`$30`) without attempting to
parse it into a SAS date value. The reference project does exactly this. Document the raw
string in `pdd.source_inventory`.
**Warning signs:** `FINFO returned blank for 'Last Modified'` — try `'Last Modified'` with
different capitalization or try `'Date/Time Modified'` (Windows SAS 9.4 typically uses
`'Last Modified'`).

---

## Code Examples

### Building the 20-File List Inline (no DIR command needed)

Because the 20 file paths are known at design time, build `work.file_list` from a DATALINES
block rather than a pipe. This avoids any dependency on DIR being available and makes the
program self-contained.

```sas
/* Source: adapted from reference Section 4 / PROJECT.md file list */
data work.file_list;
  length s_code $4 filename $200 full_path $500 ftype $5;
  infile datalines dsd dlm='|' truncover;
  input s_code $ filename $ ftype $;
  full_path = cats("&raw_master.\", filename);
  file_id + 1;
  datalines;
s01|2018-2022_PACU_STAY_20260813.csv|csv
s02|2018_2019_2020_Induction_Emergent20231121.csv|csv
s03|2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv|csv
s04|2018_2019_ENCOUNTER_Crypto_Data_20260814.csv|csv
s05|2018_2019_MRN_Crypto_Data20260814.csv|csv
s06|2018_2019_Precede_Database.xlsx|xlsx
s07|2018_2019_X_MASTER_DATASET_20200801.csv|csv
s08|2018_2022_COLONOSCOPY_20240118.xlsx|xlsx
s09|2018_2022_X_MASTER_DATASET_20240402.csv|csv
s10|2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv|csv
s11|2020_Precede_Database_Edu.xlsx|xlsx
s12|2020_X_MASTER_DATASET_20210519.csv|csv
s13|2021_Education_20240124.csv|csv
s14|2021_Frailty_20240123.csv|csv
s15|2021_X_MASTER_DATASET_20230512.csv|csv
s16|2022_Education_20240124.csv|csv
s17|2022_MASTER_DATASET_20231024.csv|csv
s18|2022_RES_20230927.csv|csv
s19|ALL_AIM2_MASTER_DATASET_20210917.xlsx|xlsx
s20|All_YEARS_LAT_LONG_20231127.csv|csv
;
```

### %eval_import Macro (required before every PROC IMPORT)

```sas
/* Source: _reference_old/sas/19_raw_dir_inventory.sas, Section 6 */
%macro eval_import(target=);
  %if &syserr le 4 and %sysfunc(exist(&target)) %then %do;
    %let fstatus = profiled;
    %if &syserr > 0 %then %let fwarn = %superq(syswarningtext);
  %end;
  %else %do;
    %let fstatus = read-failed;
    %let freason = import error syserr=&syserr;
  %end;
  %let syscc = 0;
%mend eval_import;
```

### Hash Baseline Two-Branch Logic (seed vs. guard)

```sas
%macro run_hash_guard;
  %local n_base_rows n_drift;
  %let n_base_rows = 0;
  %let n_drift     = 0;

  /* Count existing baseline rows */
  %if %sysfunc(fileexist(&sas_path.\..\docs\source_guard_baseline.csv)) %then %do;
    data _null_;
      retain _cnt 0;
      infile "&sas_path.\..\docs\source_guard_baseline.csv"
             dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
      input;
      _cnt + 1;
      if _eof then call symputx('n_base_rows', _cnt, 'L');
    run;
  %end;

  %if &n_base_rows = 0 %then %do;
    /* FIRST RUN: seed the baseline */
    /* ... write docs/source_guard_baseline.csv from work.sha_results ... */
    %put NOTE: [02] source guard baseline seeded. Commit docs/source_guard_baseline.csv.;
  %end;
  %else %do;
    /* SUBSEQUENT RUNS: compare and abort on drift */
    /* ... read baseline, join to work.sha_results, count mismatches ... */
    %if &n_drift > 0 %then %do;
      %fail_out(msg=SOURCE GUARD FAILED -- &n_drift files changed since baseline. Delete docs/source_guard_baseline.csv to reseed.);
    %end;
    %put NOTE: [02] source guard passed -- all 20 SHA-256 values match baseline.;
  %end;
%mend run_hash_guard;
```

### ODS EXCEL with UF Colors

```sas
/* Source: _reference_old/sas/19_raw_dir_inventory.sas, Section 15 */
ods path(prepend) work.templat(update);
proc template;
  define style styles.uf_inventory;
    parent = styles.pearl;
    class header /
      backgroundcolor = cx0021A5
      color           = white
      fontweight      = bold;
  end;
run;

ods listing close;
ods excel file="&qc_path.\source_inventory.xlsx"
    style=styles.uf_inventory
    options(sheet_interval='proc' frozen_headers='on' autofilter='all');
/* KEY sheet must come first (PDD-D-09) */
ods excel options(sheet_name='KEY');
proc print data=work.key_legend noobs; run;
/* ... other sheets ... */
ods excel close;
ods listing;
```

---

## State of the Art

| Old Approach (reference project) | New Approach (Phase 2) | Reason for Change |
|----------------------------------|------------------------|-------------------|
| Inventoried 8 renamed SAS datasets in `g` library | Inventory 20 original files directly in shared folder | PDD-D-03: removes the XLSX conversion layer and the g library |
| Hash guard on `master_data_1..8.sas7bdat` | Hash guard on the 20 original CSV/XLSX files | No renamed intermediate copies exist in the new project |
| Separate seed program (`19b`) and guard program (`19`) | Single `02_source_guard.sas` with two-branch logic | Simpler pipeline for 20 known files |
| `raw_path` config variable | `raw_master` config variable already defined in `00_config.sas` | Rename only; logic is identical |
| `g.id_membership`, `g.id_overlap_pairs` | `pdd.source_inventory`, `pdd.header_matrix` | No g library; pdd library is the output target |

---

## Open Questions

1. **Does `2018_2019_Precede_Database.xlsx` (s06, ~200 MB) actually have multiple sheets
   and what are their names?**
   - What we know: PROJECT.md says "all sheets must be inventoried."
   - What's unclear: How many sheets, whether any start with digits, whether all are data.
   - Recommendation: The import loop handles this generically via `dictionary.members`.
     Log the sheet count and names to `pdd.source_inventory` in the sheet_list column.

2. **Will PROC IMPORT succeed on ALL_AIM2 (s19, ~1M rows)?**
   - What we know: Project.md notes this file is large and PROC IMPORT may be unreliable.
   - What's unclear: Whether the XLSX engine DATA step (no PROC IMPORT) avoids the memory
     issue.
   - Recommendation: For s19 use `libname _xlw path 'xlsx'; data work.ds; set _xlw.Sheet1;
     run;` rather than PROC IMPORT. After the DATA step read `dictionary.tables` for nobs.
     If the DATA step also fails, record `status = 'read-failed'` and proceed — the
     hash and metadata are still collected before the import step.

3. **Older copies in `raw\master` — which of the 20 filenames will match?**
   - What we know: PROJECT.md states some files were modified 2026-08-17 there; the
     reference project's `required_files` list shows 8 CSVs that were in the old pipeline.
   - What's unclear: Whether all 20 new files have a same-filename copy there.
   - Recommendation: The three-way status (`identical`/`different`/`no older copy`) handles
     the missing case gracefully. Do not abort if a file has no older copy; just record the
     status.

4. **`raw_master` path in `00_config.sas` points to the shared folder, not `raw\master`.**
   - What we know: `00_config.sas` defines:
     `%let raw_master = P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data;`
     The older-copy folder is `P:\PeCAN Master Data\Gerard\raw\master`.
   - What's unclear: Whether a second macro variable is needed for the older-copy path.
   - Recommendation: Add `%let raw_master_old = P:\PeCAN Master Data\Gerard\raw\master;`
     to `00_config.sas`, or define it locally at the top of `02_source_guard.sas`. A local
     definition is safer to avoid polluting the global config.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| SAS 9.4 on Windows | All of Phase 2 | Assumed (project constraint) | 9.4 | None — SAS-only project |
| `certutil` (Windows built-in) | SHA-256 hashing | Available on all Windows 7+ systems | Windows built-in | None — certutil is the established approach; HASHING function alternative is complex for binary files |
| `P:\PeCAN Master Data\00 Shared Data\...` (shared folder) | Source files | Assumed accessible | — | Phase cannot run without read access |
| `P:\PeCAN Master Data\Gerard\raw\master` (older copies) | Hash comparison (PDD-02-R5) | Likely accessible; some files confirmed 2026-08-17 | — | If path missing, record all 20 as 'no older copy' |
| `C:\data_dictionary\docs\` | Baseline CSV storage | Must be created if absent | — | `options dlcreatedir; libname _doc 'C:\data_dictionary\docs\';` |

---

## Validation Architecture

No automated test framework (pytest, jest, vitest) applies here — this is a SAS pipeline.
Validation is SAS-internal: assertions written as named macros that call `%fail_out` on
failure.

### Phase Requirements to Assertion Map

| Req | Behavior | Assertion Type | Location in Program |
|-----|----------|---------------|---------------------|
| PDD-02-R1 | All 20 SHA-256 computed; none = 'FAILED' | `%macro assert_hashes_ok` — count sha256='FAILED' rows; fail if > 0 | Section 5 |
| PDD-02-R1 | Baseline match on re-run | `%macro run_hash_guard` — n_drift > 0 triggers %fail_out | Section 11 |
| PDD-02-R2 | All 20 files have metadata (fsize, fdate) | Check fsize > 0 for all 20 rows in work.files_meta | Section 4 |
| PDD-02-R8 | pdd.source_inventory exists with 20 rows | `proc sql; select count(*) into :n ...` after write; fail if ne 20 | Section 15 |
| PDD-02-R8 | pdd.header_matrix exists with > 0 rows | `proc sql; select count(*) into :n ...` after write; fail if = 0 | Section 15 |
| PDD-02-R8 | qc\source_inventory.xlsx exists | `%sysfunc(fileexist(&qc_path.\source_inventory.xlsx))` | Section 15 |
| PDD-02-R8 | qc\header_matrix.xlsx exists | `%sysfunc(fileexist(&qc_path.\header_matrix.xlsx))` | Section 15 |
| PDD-02-R7 | Spine (s09) has approximately 41,150 rows | Log count; emit WARNING if outside 41,000–42,000 range | Section 6 |

### Sampling on Re-run

Every run of `02_source_guard.sas` is self-validating: the hash guard either passes with
`NOTE:` or aborts with `ERROR:`. The log is the test output.

---

## Sources

### Primary (HIGH confidence — working SAS code in the reference project)
- `_reference_old/sas/19_raw_dir_inventory.sas` — certutil SHA-256 pattern, XLSX engine
  sheet enumeration, FINFO metadata, CSV import loop, ODS EXCEL with UF colors, key-column
  detection SQL
- `_reference_old/sas/19b_seed_hash_baseline.sas` — baseline seed two-branch logic,
  DATA step infile CSV read, positional column order constraint
- `_reference_old/sas/19c_seed_source_hash_baseline.sas` — alternative seed pattern for
  SAS datasets (adapted for files here)
- `_reference_old/sas/15_id_overlap.sas` — ID overlap pattern, grain test
  (COUNT DISTINCT vs COUNT), membership build from stacked ID-only extracts
- `C:\data_dictionary\sas\00_config.sas` — confirmed macro variable names and path values

### Secondary (MEDIUM confidence — project design documents)
- `.planning/PROJECT.md` — file list, known hazards, locked decisions
- `.planning/REQUIREMENTS.md` — PDD-02 acceptance criteria
- `.planning/ROADMAP.md` — Phase 2 scope and done-when criteria

---

## Metadata

**Confidence breakdown:**
- SHA-256 pattern: HIGH — copied from working production code
- XLSX engine sheet enumeration: HIGH — copied from working production code; the
  200 MB file is explicitly mentioned as handled
- File metadata via FINFO: HIGH — direct copy of working reference pattern
- Grain test / ID overlap: HIGH — adapted from 15_id_overlap.sas patterns
- Hash baseline two-branch logic: HIGH — synthesized from 19b and 19c patterns
- Key-column detection SQL: HIGH — direct copy from Section 8 of reference
- Header x file matrix structure: MEDIUM — pattern exists in reference `work.variables`
  dataset; minor adaptation needed for the 20-file scope
- Older-copy hash comparison: MEDIUM — the certutil pattern is proven; which files will
  match the older copies is unknown until runtime

**Research date:** 2026-10-19
**Valid until:** Stable. The reference code is frozen; SAS 9.4 APIs are stable.
Revisit only if the shared-folder file list changes before Phase 2 executes.
