/*==========================================================================
  Program : 03a_build_spec.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 3 Plan 01 -- One-time spec generation.
            (1) Raw $32767 character pre-pass over all 16 CSV files to find
                true max observed lengths -> pdd.raw_char_lengths.
            (2) Build import_spec for all 20 files from pdd.header_inventory
                + pdd.raw_char_lengths with forced-char rules, dup handling,
                numeric informat probing -> docs\import_spec_generated.csv
                and pdd.import_spec (persisted).
            Run once, commit docs\import_spec_generated.csv, then run
            03_import.sas for the repeatable pipeline step.

  Reads   : pdd.header_inventory  (Phase 2 output, READ ONLY)
            pdd.source_inventory  (Phase 2 output, READ ONLY)
            &raw_master (read-only -- 16 CSV source files, pre-pass only)

  Writes  : pdd.raw_char_lengths
            pdd.import_spec
            C:\data_dictionary\docs\import_spec_generated.csv

  Sections:
    0  Header, %include, %pdd_lib
    1  Utility macros (fail_out, _note_written_ds, route_log, restore_log)
    2  Precondition guards + encoding check
    3  Build work.file_list (20 rows)
    4  Raw char-length pre-pass (CSV files only, 16 files)
    5  Spec build (all 20 files, CSV + XLSX)
    6  Write docs\import_spec_generated.csv
    7  Restore log

  PCM compliance:
    - No open-code %IF outside a %macro block
    - %abort cancel only inside %fail_out
    - No apostrophes or embedded semicolons in %put text
    - No PROC SQL UPDATE
    - No in-place dataset rewrite (data X; set X;)

  Author  : GSD Phase 03 Plan 01
==========================================================================*/


/* ============================================================
   SECTION 0 -- Header, %include, %pdd_lib
   ============================================================ */

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;


/* ============================================================
   SECTION 1 -- Utility macros
   All conditional logic inside named macros (no open-code %IF).
   Labels retargeted to [03a_build_spec].
   ============================================================ */

/* Route the log to a per-program file when running standalone */
%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\03a_build_spec.log" new; run;
  %end;
%mend route_log;

/* Restore the log to the default destination */
%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* Abort with a loud ERROR message. %abort cancel is ONLY called here. */
%macro fail_out(msg=);
  %put ERROR: [03a_build_spec] &msg;
  %abort cancel;
%mend fail_out;

/* Print a NOTE that a pdd dataset was written, confirmed with rowcount > 0. */
%macro _note_written_ds(ds=, label=);
  %local _nw;
  %let _nw = 0;
  %if %sysfunc(exist(&ds)) %then %do;
    proc sql noprint;
      select count(*) into :_nw trimmed from &ds;
    quit;
    %if &_nw > 0 %then
      %put NOTE: [03a_build_spec] &label written (&_nw rows);
    %else
      %put WARNING: [03a_build_spec] &label written but has 0 rows;
  %end;
  %else
    %put WARNING: [03a_build_spec] &label was NOT written;
%mend _note_written_ds;


/* ============================================================
   SECTION 2 -- Preconditions
   ============================================================ */

/* check_encoding and check_pdd_lib need %fail_out defined above */
%check_encoding;
%check_pdd_lib;

/* Precondition: pdd.header_inventory must exist (Phase 2 output) */
%macro _check_prereqs;
  %if not %sysfunc(exist(pdd.header_inventory)) %then %do;
    %fail_out(msg=%str(pdd.header_inventory missing -- run 02_source_guard.sas first));
  %end;
  %if not %sysfunc(exist(pdd.source_inventory)) %then %do;
    %fail_out(msg=%str(pdd.source_inventory missing -- run 02_source_guard.sas first));
  %end;
  %put NOTE: [03a_build_spec] Preconditions OK -- pdd.header_inventory and pdd.source_inventory exist;
%mend _check_prereqs;
%_check_prereqs;

/* Begin log redirect */
%route_log;

%put NOTE: [03a_build_spec] === Phase 3 Plan 01 starting ===;
%put NOTE: [03a_build_spec] sas_path   = &sas_path;
%put NOTE: [03a_build_spec] raw_master = &raw_master;
%put NOTE: [03a_build_spec] out_root   = &out_root;


/* ============================================================
   SECTION 3 -- Build work.file_list (20 rows)
   Exact copy from 02_source_guard.sas Section 3.
   ============================================================ */

data work.file_list;
  length s_code $4 filename $200 ftype $5 full_path $500;
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

%put NOTE: [03a_build_spec] work.file_list built;


/* ============================================================
   SECTION 4 -- Raw char-length pre-pass (CSV files only)
   Pitfall 3: skip XLSX files (engine handles types).
   Pitfall 3: batch if any CSV > 500 columns (batches of 200).
   ============================================================ */

/* --- 4a. Initialize accumulators for pre-pass and header-line parse ---
   Max CSV column count is determined from the header-line parse in _run_prepass.
   pdd.header_inventory has NO col_order column -- do NOT query it for col counts. */

/* Pre-pass accumulator: max observed char length per (s_code, col_order) */
data work._prepass_all;
  length s_code $4 col_order 8 max_len 8;
  stop;
run;

/* Header-line parse accumulator: physical col_order + orig column name per CSV */
data work._csv_cols;
  length s_code $4 col_order 8 orig_col_name $256;
  stop;
run;

/* --- 4b. Pre-pass macro (handles one CSV file) --- */
%macro _csv_prepass(scode=, full_path=, ncols=);
  %local _nbatches _b _col_start _col_end _batch_ncols _b_ncols;

  /* Determine batch count (batch size 200 for all widths) */
  %let _nbatches = %sysfunc(ceil(%sysevalf(&ncols / 200)));

  %put NOTE: [03a_build_spec] Pre-pass &scode: ncols=&ncols nbatches=&_nbatches;

  %do _b = 1 %to &_nbatches;
    %let _col_start = %eval((&_b - 1) * 200 + 1);
    %let _col_end   = %sysfunc(min(&ncols, %eval(&_b * 200)));
    %let _b_ncols   = %eval(&_col_end - &_col_start + 1);

    /* Read all columns as $32767 char; track max length per column in batch.
       Output only at EOF so _ml arrays hold the true per-column maxima. */
    data work._pp_long;
      length _s_code $4 s_code $4;
      retain _ml1-_ml&_b_ncols 0;
      array _c {&_b_ncols} $32767 _c1-_c&_b_ncols;
      array _m {&_b_ncols} _ml1-_ml&_b_ncols;
      _s_code = "&scode";
      infile "&full_path" encoding='utf-8' dlm=',' dsd missover
             firstobs=2 lrecl=32767 end=_eof;

      /* Skip the first (_col_start - 1) columns before reading our batch */
      %if &_col_start > 1 %then %do;
        %local _nskip;
        %let _nskip = %eval(&_col_start - 1);
        length _skip1-_skip&_nskip $1;
        input (_skip1-_skip&_nskip) (:$1.) (_c1-_c&_b_ncols) (:$32767.);
        drop _skip1-_skip&_nskip;
      %end;
      %else %do;
        input (_c1-_c&_b_ncols) (:$32767.);
      %end;

      do _j = 1 to &_b_ncols;
        if lengthn(_c{_j}) > _m{_j} then _m{_j} = lengthn(_c{_j});
      end;

      /* Only output the final accumulated row (true maxima) */
      if _eof then do;
        /* Log sample max_lens for first 3 columns of batch 1 */
        %if &_b = 1 %then %do;
          %local _nsamp;
          %let _nsamp = %sysfunc(min(3, &_b_ncols));
          %do _js = 1 %to &_nsamp;
            put "NOTE: [03a_build_spec] &scode prepass col=%eval(&_col_start + &_js - 1) max_len=" _ml&_js;
          %end;
        %end;
        do _j = 1 to &_b_ncols;
          s_code    = _s_code;
          col_order = &_col_start + _j - 1;
          max_len   = _m{_j};
          output;
        end;
      end;
      keep s_code col_order max_len;
    run;

    proc append base=work._prepass_all data=work._pp_long; run;

    proc datasets lib=work nolist nowarn;
      delete _pp_long;
    quit;
  %end;

  %put NOTE: [03a_build_spec] Pre-pass &scode complete;
%mend _csv_prepass;

/* --- 4c. Loop over CSV files in file_list ---
   Header-line parse derives ncols and orig_col_name from the actual CSV.
   pdd.header_inventory has NO col_order; never query it for column counts. */
%macro _run_prepass;
  %local _n_csv _i _scode _fpath _ncols;

  /* Load all CSV file codes and paths into macro arrays in one PROC SQL.
     No OFFSET/FETCH: SAS PROC SQL does not support that Oracle/ANSI syntax. */
  proc sql noprint;
    select count(*) into :_n_csv trimmed
    from work.file_list
    where ftype = 'csv';
    select s_code, full_path
    into :_csv_sc1-:_csv_sc999, :_csv_fp1-:_csv_fp999
    from work.file_list
    where ftype = 'csv';
  quit;

  %put NOTE: [03a_build_spec] Running pre-pass over &_n_csv CSV files;

  %do _i = 1 %to &_n_csv;
    %let _scode = &&_csv_sc&_i;
    %let _fpath = &&_csv_fp&_i;

    /* Parse the first line of the CSV: derive orig_col_name and physical col count.
       Handles quoted fields containing commas.
       Builds work._hdr_parse_ (s_code, col_order, orig_col_name). */
    data work._hdr_parse_;
      length s_code $4 orig_col_name $256 _line $32767 _f $256;
      infile "&_fpath" encoding='utf-8' lrecl=32767 obs=1;
      input;
      _line  = _infile_;
      s_code = "&_scode";
      _in_q  = 0;
      _start = 1;
      _cpos  = 0;
      do _k = 1 to lengthn(_line) + 1;
        /* sentinel: treat end-of-line as a final comma to flush last field */
        if _k > lengthn(_line) then _ch = ',';
        else _ch = char(_line, _k);
        /* toggle in-quote state on double-quote characters */
        if _ch = '"' then _in_q = ^_in_q;
        else if _ch = ',' and ^_in_q then do;
          _cpos + 1;
          _f = substr(_line, _start, _k - _start);
          _f = strip(_f);
          /* Strip surrounding double-quotes if present */
          if length(_f) >= 2 and char(_f, 1) = '"'
             and char(_f, length(_f)) = '"' then
            _f = substr(_f, 2, length(_f) - 2);
          orig_col_name = strip(_f);
          output;
          _start = _k + 1;
        end;
      end;
      keep s_code _cpos orig_col_name;
      rename _cpos = col_order;
    run;

    /* ncols from header parse (not from header_inventory) */
    proc sql noprint;
      select count(*) into :_ncols trimmed from work._hdr_parse_;
    quit;

    %if &_ncols = 0 %then %do;
      %put WARNING: [03a_build_spec] &_scode header parse returned 0 columns -- skipping;
    %end;
    %else %do;
      %put NOTE: [03a_build_spec] &_scode: &_ncols columns from header-line parse;
      proc append base=work._csv_cols data=work._hdr_parse_; run;
      %_csv_prepass(scode=&_scode, full_path=&_fpath, ncols=&_ncols);
    %end;

    proc datasets lib=work nolist nowarn; delete _hdr_parse_; quit;
  %end;

  %put NOTE: [03a_build_spec] All CSV pre-pass runs complete;
%mend _run_prepass;
%_run_prepass;

/* Fail fast if CSV header parse produced no rows */
%macro _assert_csv_cols;
  %local _ncc;
  %let _ncc = -1;
  proc sql noprint;
    select count(*) into :_ncc trimmed from work._csv_cols;
  quit;
  %if %length(&_ncc) = 0 or &_ncc = -1 %then
    %fail_out(msg=%str(_assert_csv_cols -- count not populated -- proc sql may have failed));
  %if &_ncc = 0 %then
    %fail_out(msg=%str(work._csv_cols has 0 rows -- CSV header parse failed -- check source paths));
  %put NOTE: [03a_build_spec] work._csv_cols has &_ncc rows across &_n_csv CSV files;
%mend _assert_csv_cols;
%_assert_csv_cols;

/* --- 4d. Verify col_order is gapless and 1-based per s_code --- */
%macro _assert_prepass_col_order;
  %local _ngaps;
  %let _ngaps = -1;
  proc sql noprint;
    /* A gap exists if any col_order is <= 0 */
    select count(*) into :_ngaps trimmed
    from work._prepass_all
    where col_order < 1;
  quit;
  %if %length(&_ngaps) = 0 or &_ngaps = -1 %then
    %fail_out(msg=%str(_assert_prepass_col_order -- count not populated));
  %if &_ngaps > 0 %then %do;
    %fail_out(msg=%str(raw pre-pass col_order has &_ngaps rows with col_order < 1 -- check pre-pass logic));
  %end;
  %put NOTE: [03a_build_spec] Pre-pass col_order assert passed (all col_order >= 1);
%mend _assert_prepass_col_order;
%_assert_prepass_col_order;

/* --- 4e. Persist pdd.raw_char_lengths --- */
data pdd.raw_char_lengths;
  set work._prepass_all;
  length s_code $4 col_order 8 max_len 8;
  keep s_code col_order max_len;
run;

%_note_written_ds(ds=pdd.raw_char_lengths, label=pdd.raw_char_lengths);

/* Fail fast if pre-pass produced no rows */
%macro _assert_raw_char_lengths;
  %local _nrcl;
  %let _nrcl = -1;
  proc sql noprint;
    select count(*) into :_nrcl trimmed from pdd.raw_char_lengths;
  quit;
  %if %length(&_nrcl) = 0 or &_nrcl = -1 %then
    %fail_out(msg=%str(_assert_raw_char_lengths -- count not populated));
  %if &_nrcl = 0 %then
    %fail_out(msg=%str(pdd.raw_char_lengths has 0 rows -- pre-pass failed -- check CSV paths));
  %put NOTE: [03a_build_spec] pdd.raw_char_lengths has &_nrcl rows -- OK;
%mend _assert_raw_char_lengths;
%_assert_raw_char_lengths;


/* ============================================================
   SECTION 5 -- Spec build (all 20 files)
   ============================================================ */

/* --- 5a. Build work.spec_src: source rows for all 20 files ---
   For CSV: use work._prepass_all col_order (authoritative physical order).
            orig_col_name from pdd.header_inventory original_header.
            src_name = orig_col_name (column header seen in file).
   For XLSX: use pdd.header_inventory col_name (engine var name) as src_name;
             orig_col_name = original_header (display label).
             col_order from header_inventory (varnum-based order is acceptable).
   Sheet names for XLSX from dictionary.members (XLSX libref). */

/* --- 5a. Build work.spec_src: source rows for all 20 files ---
   CSV: col_order + orig_col_name from work._csv_cols (header-line parse).
        pdd.header_inventory has NO col_order -- never join on it for order.
        inferred_type from row-position-numbered header_inventory.
   XLSX: col_order from row-position in header_inventory (varnum order
         captured by Phase 2 LIBNAME XLSX reads). */

/* Position-number header_inventory rows for CSV files.
   Row sequence in the stored dataset mirrors Phase 2's physical column reads. */
proc sql noprint;
  create table work._hdr_csv_raw as
  select h.s_code, h.col_type
  from pdd.header_inventory h
  inner join work.file_list f on h.s_code = f.s_code
  where f.ftype = 'csv';
quit;

data work._hdr_csv_typed;
  length _prev_s $4;
  retain _prev_s '' _cpos 0;
  set work._hdr_csv_raw;
  if strip(s_code) ne strip(_prev_s) then do;
    _cpos  = 1;
    _prev_s = s_code;
  end;
  else _cpos + 1;
  col_order = _cpos;
  keep s_code col_order col_type;
run;

/* CSV source rows: col_order and orig_col_name from header-line parse */
proc sql noprint;
  create table work.spec_src_csv as
  select
    c.s_code               as file_code,
    c.col_order,
    strip(c.orig_col_name) as src_name,
    strip(c.orig_col_name) as orig_col_name,
    coalesce(h.col_type, 'char') as inferred_type
  from work._csv_cols c
  left join work._hdr_csv_typed h
    on c.s_code = h.s_code and c.col_order = h.col_order
  order by file_code, col_order;
quit;

/* Position-number header_inventory rows for XLSX files */
proc sql noprint;
  create table work._hdr_xlsx_raw as
  select h.s_code, h.col_name, h.col_type,
         coalesce(strip(h.original_header), strip(h.col_name)) as orig_col_name length=256
  from pdd.header_inventory h
  inner join work.file_list f on h.s_code = f.s_code
  where f.ftype = 'xlsx';
quit;

data work._hdr_xlsx_typed;
  length _prev_s $4;
  retain _prev_s '' _cpos 0;
  set work._hdr_xlsx_raw;
  if strip(s_code) ne strip(_prev_s) then do;
    _cpos  = 1;
    _prev_s = s_code;
  end;
  else _cpos + 1;
  col_order = _cpos;
  keep s_code col_order col_name col_type orig_col_name;
run;

/* XLSX source rows: col_order from row-position; src_name = engine var name */
proc sql noprint;
  create table work.spec_src_xlsx as
  select
    h.s_code               as file_code,
    h.col_order,
    strip(h.col_name)      as src_name,
    strip(h.orig_col_name) as orig_col_name,
    h.col_type             as inferred_type
  from work._hdr_xlsx_typed h
  order by file_code, col_order;
quit;

/* Union */
data work.spec_src;
  set work.spec_src_csv work.spec_src_xlsx;
  length file_code $4 src_name $256 orig_col_name $256 inferred_type $4;
run;

proc sort data=work.spec_src; by file_code col_order; run;


/* --- 5b. SAS_NAME derivation (case-insensitive dup detection within file) ---
   Use a DATA step with a hash object for UPCASE collision detection. */

data work.spec_with_names;
  set work.spec_src;
  by file_code;

  length sas_name $32 sas_name_raw $32 _base $27 _upbase $32;

  /* Step 1: sanitise to V7 name */
  sas_name_raw = prxchange('s/[^A-Za-z0-9_]/_/', -1, strip(orig_col_name));
  /* Truncate to 32 chars */
  sas_name_raw = substr(sas_name_raw, 1, 32);
  /* Prepend _ if starts with digit */
  if prxmatch('/^\d/', sas_name_raw) then
    sas_name_raw = cats('_', substr(sas_name_raw, 1, 31));

  sas_name = sas_name_raw;

  keep file_code col_order src_name orig_col_name inferred_type sas_name;
run;

/* The DATA step above doesn't do proper dup detection because a hash object
   can't persist across BY groups via a SET statement without more complex code.
   Use a self-join approach via PROC SQL to assign dup suffixes. */

/* Self-join to find which rows are duplicates (by UPCASE comparison within file) */
proc sql noprint;
  create table work.spec_ranked as
  select
    a.file_code,
    a.col_order,
    a.src_name,
    a.orig_col_name,
    a.inferred_type,
    a.sas_name,
    /* Count how many prior rows (lower col_order) in same file have same upcase name */
    count(b.col_order) as dup_rank
  from work.spec_with_names a
  left join work.spec_with_names b
    on  a.file_code       = b.file_code
    and upcase(a.sas_name) = upcase(b.sas_name)
    and b.col_order       < a.col_order
  group by a.file_code, a.col_order, a.src_name, a.orig_col_name,
           a.inferred_type, a.sas_name
  order by a.file_code, a.col_order;
quit;

/* Apply dup suffix based on rank, with special rule for PRECEDE_STUDY_ID */
data work.spec_named;
  set work.spec_ranked;
  length sas_name_final $32 _base27 $27;

  if dup_rank = 0 then sas_name_final = sas_name;
  else do;
    /* Special rule: exact 'PRECEDE_STUDY_ID' (case-insensitive) always keeps base
       name at first occurrence; subsequent get _dup2 etc.
       dup_rank > 0 means this is the 2nd or later occurrence. */
    _base27 = substr(sas_name, 1, 27);
    sas_name_final = cats(_base27, '_dup', put(dup_rank + 1, 8.));
    sas_name_final = substr(sas_name_final, 1, 32);
  end;

  rename sas_name_final = sas_name;
  drop sas_name _base27;
run;

proc datasets lib=work nolist nowarn;
  delete spec_ranked spec_with_names;
quit;

/* --- P1-3: Assert V7-valid names and no within-file upcase dups.
   Fix collisions by incrementing suffix against the full final name set. */
%macro _assert_and_fix_names;
  %local _n_inv _n_dup;
  %let _n_inv = -1;
  %let _n_dup = -1;

  /* Check V7 validity */
  proc sql noprint;
    select count(*) into :_n_inv trimmed
    from work.spec_named
    where not prxmatch('/^[A-Za-z_][A-Za-z0-9_]{0,31}$/', strip(sas_name));
  quit;
  %if %length(&_n_inv) = 0 or &_n_inv = -1 %then
    %fail_out(msg=%str(V7 name check -- count not populated));
  %if &_n_inv > 0 %then
    %fail_out(msg=%str(&_n_inv spec_named rows have invalid V7 sas_name -- check name derivation));
  %put NOTE: [03a_build_spec] V7 name validation passed (&_n_inv invalid names);

  /* Check within-file upcase dups -- log each colliding group before resolving */
  proc sql noprint;
    select count(*) into :_n_dup trimmed
    from (
      select file_code, upcase(sas_name) as uname, count(*) as n
      from work.spec_named
      group by file_code, upcase(sas_name)
      having count(*) > 1
    );
  quit;
  %if %length(&_n_dup) = 0 or &_n_dup = -1 %then
    %fail_out(msg=%str(upcase-dup check -- count not populated));

  %if &_n_dup > 0 %then %do;
    /* Log each colliding group (file_code, orig_col_name, sas_name) */
    proc sql;
      select a.file_code, a.orig_col_name, a.sas_name
      from work.spec_named a
      inner join (
        select file_code, upcase(sas_name) as uname
        from work.spec_named
        group by file_code, upcase(sas_name)
        having count(*) > 1
      ) d on a.file_code = d.file_code and upcase(a.sas_name) = d.uname
      order by a.file_code, a.sas_name;
    quit;

    %put WARNING: [03a_build_spec] &_n_dup upcase-dup groups remain after suffix assignment -- resolving;

    /* Write to a NEW dataset (never data X; set X;) */
    data work.spec_named_fixed;
      set work.spec_named;
      by file_code;
      length _uname $32 _candidate $32 _sfx_str $10;
      length _prev_file $4;
      retain _prev_file '';
      if _N_ = 1 then do;
        declare hash _seen(multidata:'n');
        _seen.defineKey('_uname');
        _seen.defineDone();
      end;
      if first.file_code then _seen.clear();
      _uname = upcase(strip(sas_name));
      if _seen.check() = 0 then do;
        /* Collision -- suffix base trimmed to fit exactly 32 chars */
        _sfx = 2;
        do while(_seen.check() = 0);
          _sfx_str   = cats('_dup', strip(put(_sfx, best32.)));
          _candidate = cats(substr(sas_name, 1, 32 - lengthn(_sfx_str)), _sfx_str);
          _candidate = substr(_candidate, 1, 32);
          _uname     = upcase(_candidate);
          _sfx + 1;
        end;
        put "NOTE: [03a_build_spec] dup resolved: file=" file_code
            " orig_col=" orig_col_name " old_sas=" sas_name " new_sas=" _candidate;
        sas_name = _candidate;
        _uname   = upcase(sas_name);
      end;
      _seen.add();
      drop _uname _candidate _sfx _sfx_str _prev_file;
    run;

    proc datasets lib=work nolist nowarn; delete spec_named; quit;
    data work.spec_named; set work.spec_named_fixed; run;
    proc datasets lib=work nolist nowarn; delete spec_named_fixed; quit;

    /* Re-run V7 check after fix */
    %let _n_inv = -1;
    proc sql noprint;
      select count(*) into :_n_inv trimmed
      from work.spec_named
      where not prxmatch('/^[A-Za-z_][A-Za-z0-9_]{0,31}$/', strip(sas_name));
    quit;
    %if %length(&_n_inv) = 0 or &_n_inv = -1 %then
      %fail_out(msg=%str(post-fix V7 name check -- count not populated));
    %if &_n_inv > 0 %then
      %fail_out(msg=%str(&_n_inv rows have invalid V7 sas_name after dup resolution -- check suffix logic));

    /* Re-run uniqueness check after fix */
    %let _n_dup = -1;
    proc sql noprint;
      select count(*) into :_n_dup trimmed
      from (
        select file_code, upcase(sas_name) as uname, count(*) as n
        from work.spec_named
        group by file_code, upcase(sas_name)
        having count(*) > 1
      );
    quit;
    %if %length(&_n_dup) = 0 or &_n_dup = -1 %then
      %fail_out(msg=%str(post-fix dup check -- count not populated));
    %if &_n_dup > 0 %then
      %fail_out(msg=%str(&_n_dup upcase-dup groups remain after dup resolution -- check suffix logic));

    %put NOTE: [03a_build_spec] Dup collision resolution complete -- all names unique;
  %end;
  %else
    %put NOTE: [03a_build_spec] No within-file upcase dup names -- OK;
%mend _assert_and_fix_names;
%_assert_and_fix_names;


/* --- 5c. SAS_TYPE determination (forced-char rules) ---
   Priority order: first match wins. */

data work.spec_typed;
  set work.spec_named;
  length sas_type $1 _oc $256 _forced_char_reason $80;

  _oc = upcase(strip(orig_col_name));

  /* Rule 1: starts with ENCRYPTED_ */
  if substr(_oc, 1, 10) = 'ENCRYPTED_' then do;
    sas_type = 'C';
    _forced_char_reason = 'forced to char -- ENCRYPTED col';
  end;
  /* Rule 2: ends with _ID or _CODE */
  else if prxmatch('/(_ID|_CODE)$/i', strip(orig_col_name)) then do;
    sas_type = 'C';
    _forced_char_reason = 'forced to char -- ID column';
  end;
  /* Rule 3: starts with CPT or ICD */
  else if prxmatch('/^(CPT|ICD)/i', strip(orig_col_name)) then do;
    sas_type = 'C';
    _forced_char_reason = 'forced to char -- CPT col';
  end;
  /* Rule 4: compress to PRECEDESTUDYID */
  else if upcase(compress(orig_col_name, ' _')) = 'PRECEDESTUDYID' then do;
    sas_type = 'C';
    _forced_char_reason = 'forced to char -- ID column';
  end;
  /* Rule 5: exact known names */
  else if _oc in ('BASE PROCEDURE CODE 1', 'PRECEDE STUDY ID') then do;
    sas_type = 'C';
    _forced_char_reason = 'forced to char -- ID column';
  end;
  /* Otherwise inherit from header_inventory */
  else do;
    if inferred_type = 'char' then sas_type = 'C';
    else sas_type = 'N';
    _forced_char_reason = '';
  end;

  drop _oc;
run;


/* ============================================================
   SECTION 5c.5 -- XLSX char-length measurement (s06/s08/s11/s19)
   Runs AFTER spec_typed so forced-char rules are known.
   Persists pdd.xlsx_char_lengths (file_code, sheet_name, src_name, max_len).
   ============================================================ */

/* Accumulator for all 4 XLSX files */
data work._xlsx_char_lens_all;
  length file_code $4 sheet_name $256 src_name $256 max_len 8;
  stop;
run;

/* Measure max char lengths for one XLSX file.
   Assigns LIBNAME XLSX first; %fail_out if libref fails.
   Discovers data sheets via dictionary.members; measures every sheet.
   Pass A: engine-character columns via _character_ array (retain _ml1-_ml5000).
   Pass B: engine-numeric columns that spec forces to C (lengthn(cats(x))). */
%macro _measure_xlsx_char_lens(fc=, fpath=);
  %local _librc _n_sheets _is _sheet _n_numforce _jnf;

  libname _xlmsr xlsx "&fpath";
  %let _librc = %sysfunc(libref(_xlmsr));
  %if &_librc ne 0 %then
    %fail_out(msg=%str(_measure_xlsx_char_lens -- LIBNAME XLSX failed for &fc -- &fpath));

  /* Discover all data sheets in this XLSX */
  proc sql noprint;
    select count(*) into :_n_sheets trimmed
    from dictionary.members
    where upcase(libname) = '_XLMSR' and upcase(memtype) = 'DATA';
    select memname
    into :_xlsh1-:_xlsh999
    from dictionary.members
    where upcase(libname) = '_XLMSR' and upcase(memtype) = 'DATA'
    order by memname;
  quit;

  %if &_n_sheets = 0 %then %do;
    libname _xlmsr clear;
    %fail_out(msg=%str(_measure_xlsx_char_lens -- no data sheets found for &fc -- &fpath));
  %end;

  %put NOTE: [03a_build_spec] &fc has &_n_sheets XLSX sheet(s);

  %do _is = 1 %to &_n_sheets;
    %let _sheet = &&_xlsh&_is;

    /* Pass A: engine-character columns.
       5000-element retain array covers s06 (up to ~3987 char cols). */
    data work._xlcl_a (keep=file_code sheet_name src_name max_len);
      length file_code $4 sheet_name $256 src_name $256 max_len 8;
      retain _ml1-_ml5000 0;
      array _c {*} _character_;
      array _m {5000} _ml1-_ml5000;
      set _xlmsr."&_sheet"n end=_eof;
      do _j = 1 to dim(_c);
        if lengthn(_c{_j}) > _m{_j} then _m{_j} = lengthn(_c{_j});
      end;
      if _eof then do;
        file_code  = "&fc";
        sheet_name = "&_sheet";
        do _j = 1 to dim(_c);
          src_name = vname(_c{_j});
          max_len  = _m{_j};
          output;
        end;
      end;
    run;

    /* Pass B: engine-numeric columns forced to C in spec_typed.
       Identify via dictionary.columns while _xlmsr is still assigned. */
    %let _n_numforce = 0;
    proc sql noprint;
      select count(*) into :_n_numforce trimmed
      from work.spec_typed s
      inner join dictionary.columns d
        on  upcase(d.libname)        = '_XLMSR'
        and upcase(d.memname)        = upcase("&_sheet")
        and upcase(strip(d.name))    = upcase(strip(s.src_name))
      where s.file_code = "&fc"
        and s.sas_type  = 'C'
        and d.type      = 'num';

      select strip(s.src_name)
      into :_nf_col1-:_nf_col999
      from work.spec_typed s
      inner join dictionary.columns d
        on  upcase(d.libname)        = '_XLMSR'
        and upcase(d.memname)        = upcase("&_sheet")
        and upcase(strip(d.name))    = upcase(strip(s.src_name))
      where s.file_code = "&fc"
        and s.sas_type  = 'C'
        and d.type      = 'num'
      order by s.col_order;
    quit;

    %put NOTE: [03a_build_spec] &fc sheet &_sheet engine-numeric forced-C cols: &_n_numforce;

    %if &_n_numforce > 0 %then %do;
      data work._xlcl_b (keep=file_code sheet_name src_name max_len);
        length file_code $4 sheet_name $256 src_name $256 max_len 8;
        retain _mnf1-_mnf&_n_numforce 0;
        array _mnf {&_n_numforce} _mnf1-_mnf&_n_numforce;
        set _xlmsr."&_sheet"n end=_eof;
        %do _jnf = 1 %to &_n_numforce;
          if lengthn(cats(&&_nf_col&_jnf)) > _mnf{&_jnf}
            then _mnf{&_jnf} = lengthn(cats(&&_nf_col&_jnf));
        %end;
        if _eof then do;
          file_code  = "&fc";
          sheet_name = "&_sheet";
          %do _jnf = 1 %to &_n_numforce;
            src_name = "&&_nf_col&_jnf";
            max_len  = _mnf{&_jnf};
            output;
          %end;
        end;
      run;

      proc append base=work._xlcl_a data=work._xlcl_b; run;
      proc datasets lib=work nolist nowarn; delete _xlcl_b; quit;
    %end;

    proc append base=work._xlsx_char_lens_all data=work._xlcl_a; run;
    proc datasets lib=work nolist nowarn; delete _xlcl_a; quit;
    %put NOTE: [03a_build_spec] &fc sheet &_sheet measurement complete;
  %end;

  libname _xlmsr clear;
  %put NOTE: [03a_build_spec] &fc XLSX char-length measurement complete;
%mend _measure_xlsx_char_lens;

/* Run measurement for all 4 XLSX files */
%macro _run_xlsx_measurement;
  %local _n_xlsx _ix _xsc _xfp;

  proc sql noprint;
    select count(*) into :_n_xlsx trimmed
    from work.file_list
    where ftype = 'xlsx';
    select s_code, full_path
    into :_xlsx_sc1-:_xlsx_sc999, :_xlsx_fp1-:_xlsx_fp999
    from work.file_list
    where ftype = 'xlsx';
  quit;

  %do _ix = 1 %to &_n_xlsx;
    %let _xsc = &&_xlsx_sc&_ix;
    %let _xfp = &&_xlsx_fp&_ix;
    %_measure_xlsx_char_lens(fc=&_xsc, fpath=&_xfp);
  %end;
%mend _run_xlsx_measurement;
%_run_xlsx_measurement;

/* Persist pdd.xlsx_char_lengths */
data pdd.xlsx_char_lengths;
  length file_code $4 sheet_name $256 src_name $256 max_len 8;
  set work._xlsx_char_lens_all;
run;
%_note_written_ds(ds=pdd.xlsx_char_lengths, label=pdd.xlsx_char_lengths);
proc datasets lib=work nolist nowarn; delete _xlsx_char_lens_all; quit;

/* Validate: log per-XLSX-file counts; fail if matched < in-spec */
%macro _validate_xlsx_char_lens;
  %local _n_xlsx_fc _ix _xfc _n_inspec _n_measured _n_matched;

  proc sql noprint;
    select count(*) into :_n_xlsx_fc trimmed
    from work.file_list
    where ftype = 'xlsx';
    select s_code
    into :_xlv_sc1-:_xlv_sc999
    from work.file_list
    where ftype = 'xlsx';
  quit;

  %do _ix = 1 %to &_n_xlsx_fc;
    %let _xfc      = &&_xlv_sc&_ix;
    %let _n_inspec   = 0;
    %let _n_measured = 0;
    %let _n_matched  = 0;

    proc sql noprint;
      select count(*) into :_n_inspec trimmed
      from work.spec_typed
      where file_code = "&_xfc" and sas_type = 'C';

      select count(*) into :_n_measured trimmed
      from pdd.xlsx_char_lengths
      where upcase(strip(file_code)) = upcase(strip("&_xfc"));

      select count(*) into :_n_matched trimmed
      from work.spec_typed s
      inner join pdd.xlsx_char_lengths x
        on  upcase(strip(x.file_code)) = upcase(strip(s.file_code))
        and upcase(strip(x.src_name))  = upcase(strip(s.src_name))
      where s.file_code = "&_xfc" and s.sas_type = 'C';
    quit;

    %put NOTE: [03a_build_spec] &_xfc XLSX char cols -- in-spec=&_n_inspec measured=&_n_measured matched=&_n_matched;

    %if &_n_matched < &_n_inspec %then
      %fail_out(msg=%str(&_xfc XLSX char cols matched=&_n_matched < in-spec=&_n_inspec -- check src_name join between spec_typed and xlsx_char_lengths));
  %end;
%mend _validate_xlsx_char_lens;
%_validate_xlsx_char_lens;


/* --- 5d. Numeric informat probing (CSV only; N-type cols after forced-char rules) ---
   For XLSX: trust engine; assign informat='best32.' and format=''.
   For CSV N columns: probe the source file for parse failures.
   We read the raw pre-pass data but only have max_len, not actual values.
   The probe must re-read the source file for N columns.
   Strategy: for each CSV file with N-type columns, generate a probe DATA step
   via CALL EXECUTE. Record parse_fail counts per column. */

/* First: join pdd.raw_char_lengths into spec for CSV C columns (for length derivation) */
proc sql noprint;
  create table work.spec_with_lens as
  select
    s.file_code,
    s.col_order,
    s.src_name,
    s.orig_col_name,
    s.sas_name,
    s.inferred_type,
    s.sas_type,
    s._forced_char_reason,
    coalesce(r.max_len, 0) as raw_max_len,
    coalesce(x.max_len, 0) as xlsx_max_len
  from work.spec_typed s
  left join pdd.raw_char_lengths r
    on  s.file_code = r.s_code
    and s.col_order = r.col_order
  left join pdd.xlsx_char_lengths x
    on  upcase(strip(x.file_code)) = upcase(strip(s.file_code))
    and upcase(strip(x.src_name))  = upcase(strip(s.src_name));
quit;

/* Determine if any CSV files have N-type columns requiring probing */
proc sql noprint;
  select count(*) into :_n_probe_cols trimmed
  from work.spec_with_lens s
  inner join work.file_list f on s.file_code = f.s_code
  where f.ftype = 'csv' and s.sas_type = 'N';
quit;

%put NOTE: [03a_build_spec] N-type CSV columns requiring numeric probe: &_n_probe_cols;

/* Set datestyle to MDY before any numeric probing */
options datestyle=mdy;

/* Initialize probe results table */
data work._probe_results;
  length file_code $4 col_order 8 sas_name $32
         parse_fail_best32 8 best_informat $20 best_format $20 probe_note $200;
  stop;
run;

/* Probe macro: test a set of N-type cols in one CSV file */
%macro _probe_numeric_cols(scode=, fpath=);
  %local _n_ncols;

  /* Get N-type column count for this CSV file */
  proc sql noprint;
    select count(*) into :_n_ncols trimmed
    from work.spec_with_lens s
    inner join work.file_list f on s.file_code = f.s_code
    where f.s_code = "&scode" and f.ftype = 'csv' and s.sas_type = 'N';
  quit;

  %if &_n_ncols = 0 %then %do;
    %put NOTE: [03a_build_spec] &scode has no N-type CSV columns to probe;
    %return;
  %end;

  %put NOTE: [03a_build_spec] Probing &_n_ncols N-type columns in &scode;

  /* Build macro vars for column names and their col_order for the probe */
  proc sql noprint;
    select sas_name, col_order
    into :_pname1-:_pname999, :_pord1-:_pord999
    from work.spec_with_lens s
    inner join work.file_list f on s.file_code = f.s_code
    where f.s_code = "&scode" and f.ftype = 'csv' and s.sas_type = 'N'
    order by col_order;
  quit;

  /* Total column count of this file (for reading all cols, then picking N ones) */
  %local _tot_cols;
  proc sql noprint;
    select count(*) into :_tot_cols trimmed
    from work.spec_with_lens
    where file_code = "&scode";
  quit;

  /* Build macro array of per-column max_len values from pre-pass (P1-6) */
  %local _k;
  %do _k = 1 %to &_n_ncols;
    %local _pmaxlen&_k;
    %let _pmaxlen&_k = 64;
    proc sql noprint;
      select max(coalesce(raw_max_len, 64), 1)
      into :_pmaxlen&_k trimmed
      from work.spec_with_lens
      where file_code = "&scode" and col_order = &&_pord&_k;
    quit;
  %end;

  /* Read all columns using pre-pass max_len widths; keep only N-type ones.
     Each N-type column gets its own pre-pass-derived length (P1-6). */
  data work._probe_vals_&scode;
    length _f_code $4;
    retain _f_code "&scode";
    array _allc {&_tot_cols} $32767 _allc1-_allc&_tot_cols;
    infile "&fpath" encoding='utf-8' dlm=',' dsd missover firstobs=2 lrecl=32767;
    input (_allc1-_allc&_tot_cols) (:$32767.);

    /* Keep only N-type columns at their pre-pass max length */
    %do _k = 1 %to &_n_ncols;
      %local _pmlen;
      %let _pmlen = &&_pmaxlen&_k;
      length &&_pname&_k $&_pmlen;
      &&_pname&_k = substr(_allc{&&_pord&_k}, 1, &_pmlen);
    %end;
    keep _f_code
    %do _k = 1 %to &_n_ncols;
      &&_pname&_k
    %end;
    ;
  run;

  /* Count parse failures per N-type column using DATA steps.
     ?? is valid in DATA step INPUT but invalid in PROC SQL.
     One DATA step per column computes all counts at once. */
  %local _k;
  %do _k = 1 %to &_n_ncols;
    %local _colname _fail_best32 _n_leadzero _best_inf _best_fmt
           _fail_mmddyy _fail_yymmdd _fail_anydtdtm _fail_ddmmyy _n_ambig;
    %let _colname       = &&_pname&_k;
    %let _fail_best32   = ;
    %let _n_leadzero    = ;
    %let _fail_mmddyy   = ;
    %let _fail_yymmdd   = ;
    %let _fail_anydtdtm = ;
    %let _fail_ddmmyy   = ;
    %let _n_ambig       = ;
    %let _best_inf      = ;
    %let _best_fmt      = ;

    /* Single DATA step: all parse counts for &&_pname&_k in one pass */
    data work._probe_cnt;
      retain _fail_best32 0 _n_leadzero 0
             _fail_mmddyy 0 _fail_yymmdd 0 _fail_anydtdtm 0
             _fail_ddmmyy 0 _n_ambig 0;
      set work._probe_vals_&scode end=_eof;
      length _v $32767;
      _v = strip(&&_pname&_k);
      if _v not in ('', 'NULL', '.') then do;
        /* P1-5: leading zero followed by a digit (007 -> char; not 0.5 or bare 0) */
        if prxmatch('/^0\d/', _v)             then _n_leadzero    + 1;
        if input(_v, ?? best32.)     = .      then _fail_best32   + 1;
        if input(_v, ?? mmddyy10.)   = .      then _fail_mmddyy   + 1;
        if input(_v, ?? yymmdd10.)   = .      then _fail_yymmdd   + 1;
        if input(_v, ?? anydtdtm21.) = .      then _fail_anydtdtm + 1;
        if input(_v, ?? ddmmyy10.)   = .      then _fail_ddmmyy   + 1;
        /* P1-4 ambiguous date: mmddyy and ddmmyy both parse but give different values */
        if input(_v, ?? mmddyy10.) ne . and input(_v, ?? ddmmyy10.) ne .
           and input(_v, ?? mmddyy10.) ne input(_v, ?? ddmmyy10.)
          then _n_ambig + 1;
      end;
      if _eof then output;
      keep _fail_best32 _n_leadzero _fail_mmddyy _fail_yymmdd
           _fail_anydtdtm _fail_ddmmyy _n_ambig;
    run;

    proc sql noprint;
      select _fail_best32, _n_leadzero, _fail_mmddyy, _fail_yymmdd,
             _fail_anydtdtm, _fail_ddmmyy, _n_ambig
      into :_fail_best32   trimmed, :_n_leadzero    trimmed,
           :_fail_mmddyy   trimmed, :_fail_yymmdd   trimmed,
           :_fail_anydtdtm trimmed, :_fail_ddmmyy   trimmed,
           :_n_ambig       trimmed
      from work._probe_cnt;
    quit;
    proc datasets lib=work nolist nowarn; delete _probe_cnt; quit;

    /* Guard: blank count means DATA step produced 0 rows -- never silently fallback */
    %if %length(&_fail_best32) = 0 %then
      %fail_out(msg=%str(&scode probe DATA step for &&_pname&_k returned 0 rows -- check source file));

    /* P1-5: a zero followed by a digit forces char */
    %if &_n_leadzero > 0 %then %do;
      %put NOTE: [03a_build_spec] &scode..&_colname: &_n_leadzero values match ^0\d -- forcing to char (P1-5);
      %let _best_inf = FORCE_CHAR;
      %let _best_fmt = ;
    %end;
    %else %do;
      /* Informat selection: fixed order best32 > mmddyy > yymmdd > anydtdtm (P1-4) */
      %if &_fail_best32 = 0 %then %do;
        %let _best_inf = best32.;
        %let _best_fmt = ;
      %end;
      %else %if &_fail_mmddyy = 0 %then %do;
        %let _best_inf = mmddyy10.;
        %let _best_fmt = DATE9.;
        /* P1-4 ambiguous-date warning */
        %if &_fail_ddmmyy = 0 and &_n_ambig > 0 %then
          %put WARNING: [03a_build_spec] &scode..&_colname: &_n_ambig values parse differently as mmddyy vs ddmmyy -- verify date format (P1-4);
      %end;
      %else %if &_fail_yymmdd = 0 %then %do;
        %let _best_inf = yymmdd10.;
        %let _best_fmt = DATE9.;
      %end;
      %else %if &_fail_anydtdtm = 0 %then %do;
        %let _best_inf = anydtdtm21.;
        %let _best_fmt = DATETIME21.;
      %end;
      %else %do;
        /* No informat parsed 100%: must fail, not silently fall back */
        %fail_out(msg=%str(&scode..&_colname: no numeric informat parsed all non-blank values -- add to import_spec_overrides.csv with sas_type=C));
      %end;
    %end;

    /* Record probe result */
    data work._probe_one;
      length file_code $4 col_order 8 sas_name $32
             parse_fail_best32 8 best_informat $20 best_format $20 probe_note $200;
      file_code         = "&scode";
      col_order         = &&_pord&_k;
      sas_name          = "&_colname";
      parse_fail_best32 = &_fail_best32;
      best_informat     = "&_best_inf";
      best_format       = "&_best_fmt";
      probe_note        = cats('parse_fail_best32=', put(&_fail_best32, 8.),
                               ' chosen_informat=', "&_best_inf");
    run;
    proc append base=work._probe_results data=work._probe_one; run;
    proc datasets lib=work nolist nowarn; delete _probe_one; quit;
  %end;

  proc datasets lib=work nolist nowarn; delete _probe_vals_&scode; quit;
  %put NOTE: [03a_build_spec] Probe complete for &scode;
%mend _probe_numeric_cols;

/* Run probe for each CSV file */
%macro _run_probes;
  %local _n_csv _i _scode _fpath;

  /* Load all CSV file codes and paths into macro arrays (no OFFSET/FETCH) */
  proc sql noprint;
    select count(*) into :_n_csv trimmed
    from work.file_list
    where ftype = 'csv';
    select s_code, full_path
    into :_prb_sc1-:_prb_sc999, :_prb_fp1-:_prb_fp999
    from work.file_list
    where ftype = 'csv';
  quit;

  %do _i = 1 %to &_n_csv;
    %let _scode = &&_prb_sc&_i;
    %let _fpath = &&_prb_fp&_i;
    %_probe_numeric_cols(scode=&_scode, fpath=&_fpath);
  %end;

  %put NOTE: [03a_build_spec] All numeric probes complete;
%mend _run_probes;
%_run_probes;


/* --- 5e. Apply probe results to spec ---
   For CSV N cols: update sas_type, informat, format, notes from probe.
   For XLSX N cols: informat=best32., format=''.
   For all C cols: informat from length, format=''. */

proc sql noprint;
  create table work.spec_final_base as
  select
    s.file_code,
    s.col_order,
    s.src_name,
    s.orig_col_name,
    s.sas_name,
    s.inferred_type,
    /* Apply forced-char from probe (FORCE_CHAR) if it applies */
    case
      when s.sas_type = 'N'
           and f.ftype = 'csv'
           and p.best_informat = 'FORCE_CHAR' then 'C'
      else s.sas_type
    end as sas_type,
    s._forced_char_reason,
    s.raw_max_len,
    s.xlsx_max_len,
    f.ftype,
    coalesce(p.parse_fail_best32, .) as parse_fail_best32,
    coalesce(p.best_informat, '') as best_informat,
    coalesce(p.best_format,   '') as best_format,
    coalesce(p.probe_note,    '') as probe_note
  from work.spec_with_lens s
  inner join work.file_list f on s.file_code = f.s_code
  left join work._probe_results p
    on  s.file_code = p.file_code
    and s.col_order = p.col_order
  order by s.file_code, s.col_order;
quit;

/* Compute length, informat, format, and notes */
data work.spec_final;
  set work.spec_final_base;
  length length_ 8 informat $30 format $30 notes $500;
  length _is_id_col 8;

  /* Is this a "ID/code/ENCRYPTED" style forced-char column? */
  _is_id_col = (index(upcase(_forced_char_reason), 'ID') > 0
             or index(upcase(_forced_char_reason), 'ENCRYPTED') > 0
             or index(upcase(_forced_char_reason), 'CPT') > 0);

  /* LENGTH derivation */
  if sas_type = 'C' then do;
    if ftype = 'csv' then do;
      if _is_id_col then length_ = max(raw_max_len + 4, 8);
      else               length_ = max(raw_max_len, 8);
    end;
    else do; /* XLSX: measured max from pdd.xlsx_char_lengths */
      if _is_id_col then length_ = max(xlsx_max_len + 4, 8);
      else               length_ = max(xlsx_max_len, 8);
    end;
    informat = cats('$', strip(put(length_, best32.)), '.');
    format   = '';
  end;
  else do; /* N */
    length_ = 8;
    if ftype = 'xlsx' then do;
      informat = 'best32.';
      format   = '';
    end;
    else do;
      /* CSV N col: use probe results */
      if best_informat = '' then do;
        informat = 'best32.';
        format   = '';
      end;
      else if best_informat = 'FORCE_CHAR' then do;
        /* Should have been reclassified to C already; fallback */
        sas_type = 'C';
        length_  = max(raw_max_len, 8);
        informat = cats('$', put(length_, 8.), '.');
        format   = '';
      end;
      else do;
        informat = best_informat;
        format   = best_format;
      end;
    end;
  end;

  /* Rebuild sas_type for any remaining FORCE_CHAR reclassified rows */
  if best_informat = 'FORCE_CHAR' and ftype = 'csv' then sas_type = 'C';

  /* NOTES field */
  notes = '';
  if _forced_char_reason ne '' then notes = _forced_char_reason;
  /* Dup detection from sas_name pattern */
  if prxmatch('/_dup\d+$/', strip(sas_name)) and index(notes, 'dup header') = 0 then do;
    if notes ne '' then notes = cats(notes, '; dup header');
    else notes = 'dup header';
  end;
  /* Probe note for N cols */
  if probe_note ne '' then do;
    if notes ne '' then notes = cats(notes, '; ', probe_note);
    else notes = probe_note;
  end;
  /* Force-char because no informat parsed */
  if best_informat = 'FORCE_CHAR' and ftype = 'csv' then do;
    if notes ne '' then notes = cats(notes, '; forced to char -- no numeric informat parsed 100%');
    else notes = 'forced to char -- no numeric informat parsed 100%';
  end;

  /* Rename length_ to length for the output dataset */
  rename length_ = length;

  keep file_code col_order src_name orig_col_name sas_name sas_type length
       informat format notes xlsx_max_len;
run;

proc datasets lib=work nolist nowarn;
  delete spec_final_base spec_with_lens spec_typed spec_named spec_src
         spec_src_csv spec_src_xlsx
         _hdr_csv_raw _hdr_csv_typed _hdr_xlsx_raw _hdr_xlsx_typed;
quit;


/* --- 5f. Column-order assert: gapless 1..N per CSV file_code ---
   (Pitfall 8 from 03-CONTEXT.md) */

%macro _assert_col_order;
  %local _ngaps;
  %let _ngaps = -1;
  /* Check that min(col_order) = 1 and count = max(col_order) for each CSV file */
  proc sql noprint;
    select count(*) into :_ngaps trimmed
    from (
      select file_code,
             min(col_order)  as min_ord,
             max(col_order)  as max_ord,
             count(col_order) as n_cols
      from work.spec_final
      inner join work.file_list on file_code = s_code
      where ftype = 'csv'
      group by file_code
    )
    where min_ord ne 1 or n_cols ne max_ord;
  quit;
  %if %length(&_ngaps) = 0 or &_ngaps = -1 %then
    %fail_out(msg=%str(_assert_col_order -- count not populated));
  %if &_ngaps > 0 %then %do;
    %fail_out(msg=%str(import_spec col_order has gaps for &_ngaps CSV files -- check spec build logic));
  %end;
  %put NOTE: [03a_build_spec] col_order assert passed -- gapless 1..N for all CSV files;
%mend _assert_col_order;
%_assert_col_order;


/* --- 5f.2. Hard asserts on spec_final before CSV write --- */

%macro _assert_spec_final;
  %local _n1 _n2 _n3 _n4;

  /* Assert 1: no missing or < 1 length */
  %let _n1 = -1;
  proc sql noprint;
    select count(*) into :_n1 trimmed
    from work.spec_final
    where missing(length) or length < 1;
  quit;
  %if %length(&_n1) = 0 or &_n1 = -1 %then
    %fail_out(msg=%str(_assert_spec_final assert1 -- count not populated));
  %if &_n1 > 0 %then %do;
    proc sql;
      select file_code, count(*) as n
      from work.spec_final
      where missing(length) or length < 1
      group by file_code;
    quit;
    %fail_out(msg=%str(&_n1 spec_final rows have missing or < 1 length -- counts by file_code shown above));
  %end;
  %put NOTE: [03a_build_spec] Assert 1 passed -- no missing or < 1 length;

  /* Assert 2: no missing informat */
  %let _n2 = -1;
  proc sql noprint;
    select count(*) into :_n2 trimmed
    from work.spec_final
    where missing(informat) or strip(informat) = '';
  quit;
  %if %length(&_n2) = 0 or &_n2 = -1 %then
    %fail_out(msg=%str(_assert_spec_final assert2 -- count not populated));
  %if &_n2 > 0 %then %do;
    proc sql;
      select file_code, count(*) as n
      from work.spec_final
      where missing(informat) or strip(informat) = ''
      group by file_code;
    quit;
    %fail_out(msg=%str(&_n2 spec_final rows have missing informat -- counts by file_code shown above));
  %end;
  %put NOTE: [03a_build_spec] Assert 2 passed -- no missing informat;

  /* Assert 3: every C row -- informat length extracted from $<n>. equals length */
  %let _n3 = -1;
  proc sql noprint;
    select count(*) into :_n3 trimmed
    from work.spec_final
    where sas_type = 'C'
      and input(compress(strip(informat), '$.'), best32.) ne length;
  quit;
  %if %length(&_n3) = 0 or &_n3 = -1 %then
    %fail_out(msg=%str(_assert_spec_final assert3 -- count not populated));
  %if &_n3 > 0 %then %do;
    proc sql;
      select file_code, sas_name, length, informat
      from work.spec_final
      where sas_type = 'C'
        and input(compress(strip(informat), '$.'), best32.) ne length;
    quit;
    %fail_out(msg=%str(&_n3 C rows whose informat length does not equal length -- rows shown above));
  %end;
  %put NOTE: [03a_build_spec] Assert 3 passed -- all C row informat lengths match length;

  /* Assert 4: XLSX C rows -- spec length >= measured xlsx_max_len */
  %let _n4 = -1;
  proc sql noprint;
    select count(*) into :_n4 trimmed
    from work.spec_final s
    inner join work.file_list f on s.file_code = f.s_code
    where f.ftype = 'xlsx'
      and s.sas_type = 'C'
      and s.length < s.xlsx_max_len;
  quit;
  %if %length(&_n4) = 0 or &_n4 = -1 %then
    %fail_out(msg=%str(_assert_spec_final assert4 -- count not populated));
  %if &_n4 > 0 %then %do;
    proc sql;
      select s.file_code, s.sas_name, s.xlsx_max_len, s.length, s.informat
      from work.spec_final s
      inner join work.file_list f on s.file_code = f.s_code
      where f.ftype = 'xlsx' and s.sas_type = 'C' and s.length < s.xlsx_max_len;
    quit;
    %fail_out(msg=%str(&_n4 XLSX C columns whose spec length is below measured xlsx_max_len -- rows shown above));
  %end;
  %put NOTE: [03a_build_spec] Assert 4 passed -- all XLSX C lengths >= measured xlsx_max_len;

%mend _assert_spec_final;
%_assert_spec_final;


/* --- 5f.3. 10-row sample of XLSX char columns --- */
%put NOTE: [03a_build_spec] 10-row sample XLSX char cols (file_code sas_name xlsx_max_len length informat):;
proc sql outobs=10;
  select s.file_code, s.sas_name, s.xlsx_max_len, s.length, s.informat
  from work.spec_final s
  inner join work.file_list f on s.file_code = f.s_code
  where f.ftype = 'xlsx' and s.sas_type = 'C'
  order by s.file_code, s.col_order;
quit;


/* --- 5g. Persist pdd.import_spec --- */
data pdd.import_spec;
  set work.spec_final (drop=xlsx_max_len);
run;

%_note_written_ds(ds=pdd.import_spec, label=pdd.import_spec);

/* Fail fast: must have EXACTLY 20 distinct file_codes matching work.file_list s_code set */
%macro _assert_spec_complete;
  %local _nfc _nspec _nmiss;
  %let _nfc   = -1;
  %let _nspec = -1;
  %let _nmiss = -1;
  proc sql noprint;
    select count(distinct file_code) into :_nfc   trimmed from pdd.import_spec;
    select count(*)                  into :_nspec  trimmed from pdd.import_spec;
    /* file_codes in file_list but missing from import_spec */
    select count(*) into :_nmiss trimmed
    from work.file_list f
    where f.s_code not in (select distinct file_code from pdd.import_spec);
  quit;
  %if %length(&_nfc)   = 0 or &_nfc   = -1 %then %fail_out(msg=%str(_assert_spec_complete nfc not populated));
  %if %length(&_nspec) = 0 or &_nspec = -1 %then %fail_out(msg=%str(_assert_spec_complete nspec not populated));
  %if %length(&_nmiss) = 0 or &_nmiss = -1 %then %fail_out(msg=%str(_assert_spec_complete nmiss not populated));
  %if &_nspec = 0 %then
    %fail_out(msg=%str(pdd.import_spec has 0 rows -- spec build failed));
  %if &_nfc ne 20 %then
    %fail_out(msg=%str(pdd.import_spec has &_nfc distinct file_codes -- expected exactly 20));
  %if &_nmiss > 0 %then
    %fail_out(msg=%str(&_nmiss file_codes from work.file_list missing in pdd.import_spec));
  %put NOTE: [03a_build_spec] pdd.import_spec: &_nfc distinct file_codes &_nspec total rows -- OK;
%mend _assert_spec_complete;
%_assert_spec_complete;


/* ============================================================
   SECTION 6 -- Write docs\import_spec_generated.csv
   ============================================================ */

data _null_;
  file "C:\data_dictionary\docs\import_spec_generated.csv"
       lrecl=5000 encoding='utf-8';
  /* Header line */
  put 'file_code,col_order,src_name,orig_col_name,sas_name,sas_type,length,informat,format,notes';
run;

data _null_;
  set pdd.import_spec;
  file "C:\data_dictionary\docs\import_spec_generated.csv"
       lrecl=5000 encoding='utf-8' mod;

  /* Quote a field: surround with " and double any internal " */
  length _q_fc $10 _q_co $12 _q_sn $300 _q_oc $300 _q_nm $40 _q_st $4
         _q_le $12 _q_inf $34 _q_fmt $34 _q_no $600;

  /* All fields stripped before quoting -- no padded values in output */
  _q_fc  = strip(file_code);
  _q_co  = strip(put(col_order, best32.));
  _q_sn  = '"' || tranwrd(strip(src_name),      '"', '""') || '"';
  _q_oc  = '"' || tranwrd(strip(orig_col_name),  '"', '""') || '"';
  _q_nm  = '"' || tranwrd(strip(sas_name),        '"', '""') || '"';
  _q_st  = strip(sas_type);
  _q_le  = strip(put(length, best32.));
  _q_inf = '"' || tranwrd(strip(informat),        '"', '""') || '"';
  _q_fmt = '"' || tranwrd(strip(format),          '"', '""') || '"';
  _q_no  = '"' || tranwrd(strip(notes),           '"', '""') || '"';

  put _q_fc ',' _q_co ',' _q_sn ',' _q_oc ',' _q_nm ',' _q_st ','
      _q_le ',' _q_inf ',' _q_fmt ',' _q_no;
run;

%put NOTE: [03a_build_spec] docs\import_spec_generated.csv written;
%put NOTE: [03a_build_spec] Gerard -- create docs\import_spec_overrides.csv (same 10-column header) with only override rows -- 03_import.sas will merge at runtime (override row wins);

/* P2: Read back the CSV and assert its data row count = pdd.import_spec row count */
%macro _assert_csv_rowcount;
  %local _nspec _ncsv_rows;
  %let _nspec    = -1;
  %let _ncsv_rows = -1;

  proc sql noprint;
    select count(*) into :_nspec trimmed from pdd.import_spec;
  quit;
  %if %length(&_nspec) = 0 or &_nspec = -1 %then
    %fail_out(msg=%str(_assert_csv_rowcount -- pdd.import_spec count not populated));

  /* Count data rows in the generated CSV (skip header; end= fires at true EOF) */
  data work._csv_rc_check;
    infile "C:\data_dictionary\docs\import_spec_generated.csv"
           lrecl=5000 encoding='utf-8' firstobs=2 end=_eof;
    input; _row + 1;
    if _eof then output;
    keep _row;
  run;

  proc sql noprint;
    select _row into :_ncsv_rows trimmed from work._csv_rc_check;
  quit;

  proc datasets lib=work nolist nowarn; delete _csv_rc_check; quit;

  %if %length(&_ncsv_rows) = 0 or &_ncsv_rows = -1 %then
    %fail_out(msg=%str(_assert_csv_rowcount -- CSV row count not populated -- end= may not have fired));
  %if &_ncsv_rows ne &_nspec %then
    %fail_out(msg=%str(import_spec_generated.csv has &_ncsv_rows data rows but pdd.import_spec has &_nspec -- write mismatch));
  %put NOTE: [03a_build_spec] CSV row-count assert passed (&_ncsv_rows rows match pdd.import_spec);
%mend _assert_csv_rowcount;
%_assert_csv_rowcount;


/* ============================================================
   SECTION 7 -- Final verification notes
   ============================================================ */

proc sql noprint;
  select count(distinct file_code) into :_n_fc trimmed from pdd.import_spec;
  select count(*) into :_n_rows trimmed from pdd.import_spec;
quit;

%put NOTE: [03a_build_spec] pdd.import_spec: &_n_fc distinct file_code values, &_n_rows total rows;

%macro _check_forced_char;
  %local _n_psid_num _n_id_num _n_enc_num;
  %let _n_psid_num = -1;
  %let _n_id_num   = -1;
  %let _n_enc_num  = -1;

  proc sql noprint;
    select count(*) into :_n_psid_num trimmed
    from pdd.import_spec
    where upcase(compress(orig_col_name,' _'))='PRECEDESTUDYID' and sas_type ne 'C';

    select count(*) into :_n_id_num trimmed
    from pdd.import_spec
    where prxmatch('/(_ID|_CODE)$/i', strip(orig_col_name)) and sas_type ne 'C';

    select count(*) into :_n_enc_num trimmed
    from pdd.import_spec
    where prxmatch('/^ENCRYPTED_/i', strip(orig_col_name)) and sas_type ne 'C';
  quit;

  %if &_n_psid_num > 0 %then
    %fail_out(msg=%str(&_n_psid_num PRECEDE_STUDY_ID-like columns not forced to char -- fix forced-char rules));
  %if &_n_id_num > 0 %then
    %fail_out(msg=%str(&_n_id_num _ID/_CODE columns not forced to char -- fix forced-char rules));
  %if &_n_enc_num > 0 %then
    %fail_out(msg=%str(&_n_enc_num ENCRYPTED_ columns not forced to char -- fix forced-char rules));

  %if %length(&_n_psid_num) = 0 or &_n_psid_num = -1 %then %fail_out(msg=%str(_check_forced_char psid count not populated));
  %if %length(&_n_id_num)   = 0 or &_n_id_num   = -1 %then %fail_out(msg=%str(_check_forced_char id count not populated));
  %if %length(&_n_enc_num)  = 0 or &_n_enc_num  = -1 %then %fail_out(msg=%str(_check_forced_char enc count not populated));
  %if &_n_psid_num = 0 and &_n_id_num = 0 and &_n_enc_num = 0 %then
    %put NOTE: [03a_build_spec] Forced-char verification passed -- all ID/code/ENCRYPTED cols are type C;
%mend _check_forced_char;
%_check_forced_char;


/* ============================================================
   SECTION 7 -- Restore log
   ============================================================ */

%put NOTE: [03a_build_spec] === Phase 3 Plan 01 complete ===;
%restore_log;
