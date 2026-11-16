/*==========================================================================
  Program : 15b_new_inventory_spec.sas
  Phase   : 15 (new-source intake), plan 15-02
  Purpose : NEW-02 header inventory and file x header matrix for the three
            new files (s21 s22 s23), and NEW-03 spec half: raw length
            pre-pass, numeric parse probe, name cleaning, import spec.
            Each file is read in its own encoding (utf-8 for s21, wlatin1
            for s22 and s23, PDD-D-23) taken from docs/new_source_files.csv.
            The old inventory and the old spec are never written.
  Inputs  : docs/new_source_files.csv
            docs/source_guard_baseline_new.csv (must exist: 15a approved)
            &raw_master\<new files> (read only)
  Outputs : pdd.source_inventory_new, pdd.header_inventory_new,
            pdd.header_matrix_new, pdd.raw_char_lengths_new,
            pdd.import_spec_new,
            docs/import_spec_new_generated.csv (commit it, names/types only)
            &exchange_path\header_inventory_new.csv
            &exchange_path\header_matrix_new.csv
  Run     : standalone, after 15a has been approved (NEW-01).
==========================================================================*/

/* ============================================================
   SECTION 0 -- %include, %pdd_lib
   ============================================================ */

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;


/* ============================================================
   SECTION 1 -- Utility macros
   ============================================================ */

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\15b_new_inventory_spec.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%macro fail_out(msg=);
  %put ERROR: [15b_new_inventory_spec] &msg;
  %abort cancel;
%mend fail_out;

%macro _note_written_ds(ds=, label=);
  %local _nw;
  %let _nw = 0;
  %if %sysfunc(exist(&ds)) %then %do;
    proc sql noprint;
      select count(*) into :_nw trimmed from &ds;
    quit;
    %if &_nw > 0 %then
      %put NOTE: [15b_new_inventory_spec] &label written (&_nw rows);
    %else
      %put WARNING: [15b_new_inventory_spec] &label written but has 0 rows;
  %end;
  %else
    %put WARNING: [15b_new_inventory_spec] &label was NOT written;
%mend _note_written_ds;


/* ============================================================
   SECTION 2 -- Preconditions
   ============================================================ */

%check_encoding;
%check_pdd_lib;

%macro p15b_preconditions;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\new_source_files.csv)) %then
    %fail_out(msg=%str(p15b_preconditions: docs/new_source_files.csv not found));
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\source_guard_baseline_new.csv)) %then
    %fail_out(msg=%str(PENDING DECISION -- run 15a and approve the new baseline before 15b (NEW-01)));
  %route_log;
  %put NOTE: [15b_new_inventory_spec] === Phase 15 plan 02 starting ===;
  %put NOTE: [15b_new_inventory_spec] raw_master = &raw_master;

  proc datasets lib=pdd nolist nowarn;
    delete source_inventory_new header_inventory_new header_matrix_new
           raw_char_lengths_new import_spec_new;
  quit;
%mend p15b_preconditions;
%p15b_preconditions;


/* ============================================================
   SECTION 3 -- Load the three-file list
   ============================================================ */

data work.p15b_files;
  length s_code $4 filename $200 ftype $5 src_encoding $10
         expected_rows 8 expected_cols 8 expected_distinct_psid 8
         full_path $500;
  infile "C:\data_dictionary\docs\new_source_files.csv" dsd dlm=','
         firstobs=2 truncover lrecl=500;
  input s_code $ filename $ ftype $ src_encoding $
        expected_rows expected_cols expected_distinct_psid;
  full_path = cats("&raw_master.\", strip(filename));
  file_id + 1;
run;

%macro p15b_check_list;
  %local _n_files _n_codes;
  %let _n_files = -1; %let _n_codes = -1;
  proc sql noprint;
    select count(*) into :_n_files trimmed from work.p15b_files;
    select count(*) into :_n_codes trimmed from work.p15b_files
      where s_code in ('s21', 's22', 's23');
  quit;
  %if &_n_files ne 3 %then
    %fail_out(msg=%str(p15b_check_list: file list has &_n_files rows -- expected 3));
  %if &_n_codes ne 3 %then
    %fail_out(msg=%str(p15b_check_list: file list must hold exactly s21 s22 s23));
%mend p15b_check_list;
%p15b_check_list;


/* ============================================================
   SECTION 4 -- Header inventory (NEW-02)
   Same columns as pdd.header_inventory plus col_order (varnum).
   ============================================================ */

data work.p15b_hdr_all;
  length s_code $4 sheet_name $200 col_name $32 col_type $4
         col_label $256 col_len 8 original_header $256
         original_header_trunc 8 col_order 8;
  stop;
run;

data work.p15b_counts;
  length s_code $4 filename $200 row_count 8 col_count 8 src_encoding $10;
  stop;
run;

%macro p15b_inventory;
  %local _i _sc _full _enc _fn _imp_rc _nrows _ncols;

  %do _i = 1 %to 3;
    %let _sc = ; %let _full = ; %let _enc = ; %let _fn = ;
    data _null_;
      set work.p15b_files(where=(file_id = &_i));
      call symputx('_sc',   s_code,       'L');
      call symputx('_full', full_path,    'L');
      call symputx('_enc',  src_encoding, 'L');
      call symputx('_fn',   filename,     'L');
    run;

    %if %length(&_sc) = 0 or %length(&_enc) = 0 %then
      %fail_out(msg=%str(p15b_inventory: blank s_code or encoding for file_id=&_i));
    %if not %sysfunc(fileexist(&_full)) %then
      %fail_out(msg=%str(p15b_inventory: file not found for &_sc (&_full)));

    %put NOTE: [15b_new_inventory_spec] === inventory &_sc encoding=&_enc ===;

    /* PROC IMPORT through a fileref carrying the per-file encoding */
    filename _p15bf "&_full" encoding="&_enc";
    options nosyntaxcheck noerrorabend nomprint;
    proc import datafile=_p15bf out=work.p15b_imp_&_sc dbms=csv replace;
      guessingrows=max;
    run;
    %let _imp_rc = &syserr;
    options mprint;
    filename _p15bf clear;

    %if &_imp_rc > 4 or not %sysfunc(exist(work.p15b_imp_&_sc)) %then
      %fail_out(msg=%str(p15b_inventory: PROC IMPORT failed for &_sc syserr=&_imp_rc));

    /* Raw first-line header: full original names, quote-aware split */
    data work._p15b_hdr_raw;
      length raw_col_name $256 _f $32767 _line $32767 raw_trunc 8;
      infile "&_full" encoding="&_enc" lrecl=32767 obs=1 truncover;
      input;
      _line  = _infile_;
      varnum = 0;
      _in_q  = 0;
      _start = 1;
      do _k = 1 to lengthn(_line) + 1;
        if _k > lengthn(_line) then _ch = ',';
        else _ch = char(_line, _k);
        if _ch = '"' then _in_q = ^_in_q;
        else if _ch = ',' and ^_in_q then do;
          varnum + 1;
          _f = strip(substr(_line, _start, _k - _start));
          if lengthn(_f) >= 2 and char(_f, 1) = '"'
             and char(_f, lengthn(_f)) = '"' then
            _f = substr(_f, 2, lengthn(_f) - 2);
          _f = tranwrd(_f, '""', '"');
          raw_trunc = (lengthn(_f) > 256);
          raw_col_name = strip(_f);
          output;
          _start = _k + 1;
        end;
      end;
      keep varnum raw_col_name raw_trunc;
    run;

    proc sql noprint;
      insert into work.p15b_hdr_all
        (s_code, sheet_name, col_name, col_type, col_label, col_len,
         original_header, original_header_trunc, col_order)
      select "&_sc", '', d.name, d.type, d.label, d.length,
             coalesce(r.raw_col_name, '') as original_header,
             coalesce(r.raw_trunc, 0)     as original_header_trunc,
             d.varnum
      from dictionary.columns d
      left join work._p15b_hdr_raw r on d.varnum = r.varnum
      where d.libname = 'WORK' and d.memname = upcase("p15b_imp_&_sc");

      select nobs into :_nrows trimmed
      from dictionary.tables
      where libname = 'WORK' and memname = upcase("p15b_imp_&_sc");

      select count(*) into :_ncols trimmed
      from dictionary.columns
      where libname = 'WORK' and memname = upcase("p15b_imp_&_sc");

      insert into work.p15b_counts
        (s_code, filename, row_count, col_count, src_encoding)
      values ("&_sc", "&_fn", &_nrows, &_ncols, "&_enc");
    quit;

    proc datasets lib=work nolist nowarn;
      delete _p15b_hdr_raw p15b_imp_&_sc;
    quit;
  %end;

  data pdd.header_inventory_new;
    set work.p15b_hdr_all;
  run;

  data pdd.source_inventory_new;
    set work.p15b_counts;
  run;
%mend p15b_inventory;
%p15b_inventory;

%macro p15b_assert_inventory;
  %local _n_codes _n_badcols _n_blank _n_trunc _n_rowdiff;
  %let _n_codes = -1; %let _n_badcols = -1; %let _n_blank = -1;
  %let _n_trunc = -1; %let _n_rowdiff = -1;

  proc sql noprint;
    select count(distinct s_code) into :_n_codes trimmed
      from pdd.header_inventory_new;
    select count(*) into :_n_badcols trimmed
      from (select s_code, count(*) as n from pdd.header_inventory_new
            group by s_code) a
      inner join work.p15b_files f on a.s_code = f.s_code
      where a.n ne f.expected_cols;
    select count(*) into :_n_blank trimmed
      from pdd.header_inventory_new
      where lengthn(original_header) = 0;
    select sum(original_header_trunc) into :_n_trunc trimmed
      from pdd.header_inventory_new;
    select count(*) into :_n_rowdiff trimmed
      from pdd.source_inventory_new c
      inner join work.p15b_files f on c.s_code = f.s_code
      where c.row_count ne f.expected_rows;
  quit;

  %if &_n_codes ne 3 %then
    %fail_out(msg=%str(p15b_assert_inventory: &_n_codes file codes in header_inventory_new -- expected 3));
  %if &_n_badcols ne 0 %then %do;
    proc sql;
      select a.s_code, a.n as n_cols, f.expected_cols
      from (select s_code, count(*) as n from pdd.header_inventory_new
            group by s_code) a
      inner join work.p15b_files f on a.s_code = f.s_code
      where a.n ne f.expected_cols;
    quit;
    %fail_out(msg=%str(p15b_assert_inventory: &_n_badcols file(s) with column count different from expected_cols -- see listing above));
  %end;
  %if &_n_blank ne 0 %then
    %fail_out(msg=%str(p15b_assert_inventory: &_n_blank column(s) with blank original_header));
  %if &_n_rowdiff ne 0 %then
    %put WARNING: [15b_new_inventory_spec] &_n_rowdiff file(s) have a row count different from expected_rows (check embedded line breaks);
  %put NOTE: [15b_new_inventory_spec] original_header_trunc total = &_n_trunc;

  /* Full Braden headers (names only, no data) -- answers Open Question 1 */
  data _null_;
    set pdd.header_inventory_new;
    where index(upcase(original_header), 'BRADEN') > 0;
    put 'NOTE: [15b_new_inventory_spec] Braden header ' s_code= col_order= original_header=;
  run;

  %put NOTE: [15b_new_inventory_spec] inventory assertions passed (3 files x expected_cols);
%mend p15b_assert_inventory;
%p15b_assert_inventory;


/* ============================================================
   SECTION 4b -- File x header matrix and exchange CSVs
   ============================================================ */

proc sort data=pdd.header_inventory_new
          out=work.p15b_mx_in(keep=col_name s_code col_type);
  by col_name s_code;
run;

proc transpose data=work.p15b_mx_in out=pdd.header_matrix_new(drop=_name_)
               prefix=src_;
  by col_name;
  id s_code;
  var col_type;
run;

proc export data=pdd.header_matrix_new
            outfile="&exchange_path.\header_matrix_new.csv"
            dbms=csv replace;
run;

proc sql noprint;
  create table work.p15b_inv_exp as
  select s_code, col_order, col_name, col_type, col_len,
         original_header, original_header_trunc
  from pdd.header_inventory_new
  order by s_code, col_order;
quit;

proc export data=work.p15b_inv_exp
            outfile="&exchange_path.\header_inventory_new.csv"
            dbms=csv replace;
run;

proc datasets lib=work nolist nowarn;
  delete p15b_mx_in p15b_inv_exp;
quit;

/* ============================================================
   SECTION 5 -- Raw character-length pre-pass (post-transcoding)
   Every column read as $32767 in the file's own encoding; the max
   length per column drives the spec length (not the probe).
   ============================================================ */

data work.p15b_csv_cols;
  length s_code $4 col_order 8 orig_col_name $256;
  set pdd.header_inventory_new(keep=s_code col_order original_header
                               rename=(original_header=orig_col_name));
run;

proc sort data=work.p15b_csv_cols; by s_code col_order; run;

data work.p15b_prepass_all;
  length s_code $4 col_order 8 max_len 8;
  stop;
run;

data work.p15b_probe_all;
  length s_code $4 col_order 8 parse_fail_best32 8 n_leadzero 8;
  stop;
run;

%macro p15b_csv_prepass(scode=, full_path=, ncols=, enc=);
  %local _nbatches _b _col_start _col_end _b_ncols _nskip;
  %let _nbatches = %sysfunc(ceil(%sysevalf(&ncols / 200)));
  %put NOTE: [15b_new_inventory_spec] Pre-pass &scode: ncols=&ncols nbatches=&_nbatches encoding=&enc;

  %do _b = 1 %to &_nbatches;
    %let _col_start = %eval((&_b - 1) * 200 + 1);
    %let _col_end   = %sysfunc(min(&ncols, %eval(&_b * 200)));
    %let _b_ncols   = %eval(&_col_end - &_col_start + 1);

    data work._p15b_pp_long;
      length _s_code $4 s_code $4;
      retain _ml1-_ml&_b_ncols 0;
      array _c {&_b_ncols} $32767 _c1-_c&_b_ncols;
      array _m {&_b_ncols} _ml1-_ml&_b_ncols;
      _s_code = "&scode";
      infile "&full_path" encoding="&enc" dlm=',' dsd missover
             firstobs=2 lrecl=32767 end=_eof;
      %if &_col_start > 1 %then %do;
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
      if _eof then do;
        do _j = 1 to &_b_ncols;
          s_code    = _s_code;
          col_order = &_col_start + _j - 1;
          max_len   = _m{_j};
          output;
        end;
      end;
      keep s_code col_order max_len;
    run;

    proc append base=work.p15b_prepass_all data=work._p15b_pp_long; run;
    proc datasets lib=work nolist nowarn; delete _p15b_pp_long; quit;
  %end;
  %put NOTE: [15b_new_inventory_spec] Pre-pass &scode complete;
%mend p15b_csv_prepass;


/* ============================================================
   SECTION 7 (defined here, run in the file loop) -- numeric parse probe
   One pass per file; counts best32. parse failures per column and
   values with a leading zero followed by a digit (forced to char).
   ============================================================ */

%macro p15b_probe_numeric(scode=, fpath=, enc=, ncols=);
  data work._p15b_probe_one;
    length s_code $4 _v $32767;
    array _c {&ncols} $32767 _c1-_c&ncols;
    array _f {&ncols} _f1-_f&ncols;
    array _z {&ncols} _z1-_z&ncols;
    retain _f1-_f&ncols 0 _z1-_z&ncols 0;
    infile "&fpath" encoding="&enc" dlm=',' dsd missover
           firstobs=2 lrecl=32767 end=_eof;
    input (_c1-_c&ncols) (:$32767.);
    do _j = 1 to &ncols;
      _v = strip(_c{_j});
      if _v not in ('', 'NULL', '.') then do;
        if prxmatch('/^0\d/', strip(_v)) then _z{_j} + 1;
        if input(_v, ?? best32.) = . then _f{_j} + 1;
      end;
    end;
    if _eof then do;
      s_code = "&scode";
      do _j = 1 to &ncols;
        col_order         = _j;
        parse_fail_best32 = _f{_j};
        n_leadzero        = _z{_j};
        output;
      end;
    end;
    keep s_code col_order parse_fail_best32 n_leadzero;
  run;

  proc append base=work.p15b_probe_all data=work._p15b_probe_one; run;
  proc datasets lib=work nolist nowarn; delete _p15b_probe_one; quit;
  %put NOTE: [15b_new_inventory_spec] Parse probe &scode complete;
%mend p15b_probe_numeric;

%macro p15b_run_files;
  %local _i _sc _full _enc _nc;
  %do _i = 1 %to 3;
    %let _sc = ; %let _full = ; %let _enc = ; %let _nc = 0;
    data _null_;
      set work.p15b_files(where=(file_id = &_i));
      call symputx('_sc',   s_code,       'L');
      call symputx('_full', full_path,    'L');
      call symputx('_enc',  src_encoding, 'L');
    run;
    proc sql noprint;
      select count(*) into :_nc trimmed
      from work.p15b_csv_cols where s_code = "&_sc";
    quit;
    %if &_nc = 0 %then
      %fail_out(msg=%str(p15b_run_files: header parse returned 0 columns for &_sc));
    %p15b_csv_prepass(scode=&_sc, full_path=&_full, ncols=&_nc, enc=&_enc);
    %p15b_probe_numeric(scode=&_sc, fpath=&_full, enc=&_enc, ncols=&_nc);
  %end;
%mend p15b_run_files;
%p15b_run_files;

data pdd.raw_char_lengths_new;
  set work.p15b_prepass_all;
run;

%macro p15b_assert_prepass;
  %local _n_bad;
  %let _n_bad = -1;
  proc sql noprint;
    select count(*) into :_n_bad trimmed
    from (select s_code, count(*) as n, max(col_order) as m
          from pdd.raw_char_lengths_new group by s_code) a
    inner join (select s_code, count(*) as n
                from work.p15b_csv_cols group by s_code) c
      on a.s_code = c.s_code
    where a.n ne c.n or a.m ne c.n;
  quit;
  %if &_n_bad ne 0 %then
    %fail_out(msg=%str(p15b_assert_prepass: &_n_bad file(s) where pre-pass columns differ from header columns));
  %put NOTE: [15b_new_inventory_spec] pre-pass column counts match header counts;
%mend p15b_assert_prepass;
%p15b_assert_prepass;


/* ============================================================
   SECTION 6 -- SAS names (V7, <= 32 chars, case-insensitive unique)
   Same rules as 03a: non-alphanumeric -> _, leading digit -> _ prefix,
   truncate to 32, later duplicates get _dup2 _dup3 ... (suffix kept
   inside 32 chars). orig_col_name keeps the full header.
   ============================================================ */

data work.p15b_named;
  set work.p15b_csv_cols;
  by s_code;
  length sas_name $32 _raw $256 _cand $32 _sfx_str $12 _uname $32;
  if _n_ = 1 then do;
    declare hash _seen();
    _seen.defineKey('_uname');
    _seen.defineDone();
  end;
  if first.s_code then _seen.clear();

  _raw = prxchange('s/[^A-Za-z0-9_]/_/', -1, strip(orig_col_name));
  if prxmatch('/^\d/', strip(_raw)) then _raw = cats('_', _raw);
  sas_name = substr(_raw, 1, 32);
  if lengthn(sas_name) = 0 then sas_name = cats('VAR', col_order);

  _uname = upcase(strip(sas_name));
  if _seen.check() = 0 then do;
    _sfx = 2;
    do while (_seen.check() = 0);
      _sfx_str = cats('_dup', put(_sfx, best12.));
      _cand    = cats(substr(sas_name, 1, 32 - lengthn(_sfx_str)), _sfx_str);
      _uname   = upcase(_cand);
      _sfx + 1;
    end;
    put 'NOTE: [15b_new_inventory_spec] dup resolved: ' s_code= col_order= sas_name= _cand=;
    sas_name = _cand;
    _uname   = upcase(_cand);
  end;
  _seen.add();
  drop _raw _cand _sfx _sfx_str _uname;
run;

%macro p15b_assert_names;
  %local _n_inv _n_dup;
  %let _n_inv = -1; %let _n_dup = -1;
  proc sql noprint;
    select count(*) into :_n_inv trimmed
      from work.p15b_named
      where not prxmatch('/^[A-Za-z_][A-Za-z0-9_]{0,31}$/', strip(sas_name));
    select count(*) into :_n_dup trimmed
      from (select s_code, upcase(sas_name) as u, count(*) as n
            from work.p15b_named
            group by s_code, upcase(sas_name)
            having count(*) > 1);
  quit;
  %if &_n_inv ne 0 %then
    %fail_out(msg=%str(p15b_assert_names: &_n_inv invalid V7 sas_name(s)));
  %if &_n_dup ne 0 %then
    %fail_out(msg=%str(p15b_assert_names: &_n_dup duplicate sas_name group(s) remain));
  %put NOTE: [15b_new_inventory_spec] sas_name checks passed (V7 valid, unique, <= 32 chars);
%mend p15b_assert_names;
%p15b_assert_names;


/* ============================================================
   SECTION 8 -- Spec build (11 columns)
   Forced char: PRECEDE Study ID, ENCRYPTED_*, *_ID / *_CODE.
   Numeric guess stays N / best32. only if every value parses.
   Work names len_ and fmt_ avoid the LENGTH / FORMAT keywords; they
   are renamed to length / format on pdd.import_spec_new.
   ============================================================ */

proc sql noprint;
  create table work.p15b_spec_in as
  select n.s_code as file_code length=4,
         n.col_order,
         strip(n.orig_col_name) as src_name length=256,
         strip(n.orig_col_name) as orig_col_name length=256,
         n.sas_name,
         h.col_type as imp_type length=4,
         coalesce(l.max_len, 0) as max_len,
         coalesce(p.parse_fail_best32, 0) as parse_fail_best32,
         coalesce(p.n_leadzero, 0) as n_leadzero,
         f.src_encoding length=10
  from work.p15b_named n
  inner join work.p15b_files f on n.s_code = f.s_code
  left join pdd.header_inventory_new h
    on n.s_code = h.s_code and n.col_order = h.col_order
  left join pdd.raw_char_lengths_new l
    on n.s_code = l.s_code and n.col_order = l.col_order
  left join work.p15b_probe_all p
    on n.s_code = p.s_code and n.col_order = p.col_order
  order by file_code, col_order;
quit;

data work.p15b_spec_typed;
  length file_code $4 col_order 8 src_name $256 orig_col_name $256
         sas_name $32 sas_type $1 len_ 8 informat $34 fmt_ $34
         notes $200 src_encoding $10 _oc $256;
  set work.p15b_spec_in;
  _oc  = upcase(compress(orig_col_name, ' _'));
  fmt_ = '';
  if _oc = 'PRECEDESTUDYID' then do;
    sas_type = 'C';
    len_     = 22;
    informat = '$22.';
    notes    = 'forced to char -- ID column';
  end;
  else if prxmatch('/^ENCRYPTED_/i', strip(orig_col_name)) then do;
    sas_type = 'C';
    len_     = max(1, max_len);
    informat = cats('$', put(len_, best12.), '.');
    notes    = 'forced to char -- ENCRYPTED col';
  end;
  else if prxmatch('/(_ID|_CODE)$/i', strip(orig_col_name)) then do;
    sas_type = 'C';
    len_     = max(1, max_len);
    informat = cats('$', put(len_, best12.), '.');
    notes    = 'forced to char -- ID column';
  end;
  else if imp_type = 'num' then do;
    if n_leadzero > 0 then do;
      sas_type = 'C';
      len_     = max(1, max_len);
      informat = cats('$', put(len_, best12.), '.');
      notes    = 'numeric guess had leading-zero values -- read as char';
    end;
    else if parse_fail_best32 = 0 then do;
      sas_type = 'N';
      len_     = 8;
      informat = 'best32.';
      notes    = 'parse_fail_best32=0chosen_informat=best32.';
    end;
    else do;
      sas_type = 'C';
      len_     = max(1, max_len);
      informat = cats('$', put(len_, best12.), '.');
      notes    = 'numeric guess had parse failures -- read as char';
    end;
  end;
  else do;
    sas_type = 'C';
    len_     = max(1, max_len);
    informat = cats('$', put(len_, best12.), '.');
    notes    = '';
  end;
  keep file_code col_order src_name orig_col_name sas_name sas_type len_
       informat fmt_ notes src_encoding;
run;

data pdd.import_spec_new(rename=(len_=length fmt_=format));
  set work.p15b_spec_typed;
run;


/* ============================================================
   SECTION 9 -- Assertions, then docs\import_spec_new_generated.csv
   ============================================================ */

%macro p15b_assert_spec;
  %local _n_codes _n_rows94 _n_blank_enc _n_wl _n_utf _n_pid _n_dup;
  %let _n_codes = -1; %let _n_rows94 = -1; %let _n_blank_enc = -1;
  %let _n_wl = -1; %let _n_utf = -1; %let _n_pid = -1; %let _n_dup = -1;

  proc sql noprint;
    select count(distinct file_code) into :_n_codes trimmed
      from work.p15b_spec_typed;
    select count(*) into :_n_rows94 trimmed
      from (select file_code, count(*) as n from work.p15b_spec_typed
            group by file_code) where n ne 94;
    select count(*) into :_n_blank_enc trimmed
      from work.p15b_spec_typed where lengthn(src_encoding) = 0;
    select count(distinct file_code) into :_n_wl trimmed
      from work.p15b_spec_typed where src_encoding = 'wlatin1';
    select count(distinct file_code) into :_n_utf trimmed
      from work.p15b_spec_typed
      where file_code = 's21' and src_encoding eq 'utf-8';
    select count(*) into :_n_pid trimmed
      from (select file_code from work.p15b_spec_typed
            where upcase(compress(orig_col_name, ' _')) = 'PRECEDESTUDYID'
              and sas_type = 'C'
            group by file_code having count(*) = 1);
    select count(*) into :_n_dup trimmed
      from (select file_code, upcase(sas_name) as u, count(*) as n
            from work.p15b_spec_typed
            group by file_code, upcase(sas_name) having count(*) > 1);
  quit;

  %if &_n_codes ne 3 %then
    %fail_out(msg=%str(p15b_assert_spec: &_n_codes file codes in spec -- expected 3));
  %if &_n_rows94 ne 0 %then
    %fail_out(msg=%str(p15b_assert_spec: &_n_rows94 file(s) without exactly 94 spec rows));
  %if &_n_blank_enc ne 0 %then
    %fail_out(msg=%str(p15b_assert_spec: &_n_blank_enc spec row(s) with blank src_encoding));
  %if &_n_wl ne 2 %then
    %fail_out(msg=%str(p15b_assert_spec: &_n_wl wlatin1 file code(s) -- expected 2 (s22 s23)));
  %if &_n_utf ne 1 %then
    %fail_out(msg=%str(p15b_assert_spec: s21 is not utf-8 in the spec));
  %if &_n_pid ne 3 %then
    %fail_out(msg=%str(p15b_assert_spec: PRECEDE Study ID is not exactly one char column in each of 3 files (found &_n_pid)));
  %if &_n_dup ne 0 %then
    %fail_out(msg=%str(p15b_assert_spec: &_n_dup duplicate sas_name group(s)));
  %put NOTE: [15b_new_inventory_spec] spec assertions passed;
%mend p15b_assert_spec;
%p15b_assert_spec;

%let p15b_spec_enc = utf-8;

data _null_;
  file "C:\data_dictionary\docs\import_spec_new_generated.csv"
       lrecl=5000 encoding="&p15b_spec_enc";
  put 'file_code,col_order,src_name,orig_col_name,sas_name,sas_type,length,informat,format,notes,src_encoding';
run;

data _null_;
  set work.p15b_spec_typed;
  file "C:\data_dictionary\docs\import_spec_new_generated.csv"
       lrecl=5000 encoding="&p15b_spec_enc" mod;
  length _q_sn $600 _q_oc $600 _q_nm $80 _q_inf $80 _q_fmt $80 _q_no $400
         _line $5000;
  _q_sn  = cats('"', tranwrd(strip(src_name),      '"', '""'), '"');
  _q_oc  = cats('"', tranwrd(strip(orig_col_name), '"', '""'), '"');
  _q_nm  = cats('"', tranwrd(strip(sas_name),      '"', '""'), '"');
  _q_inf = cats('"', tranwrd(strip(informat),      '"', '""'), '"');
  _q_fmt = cats('"', tranwrd(strip(fmt_),          '"', '""'), '"');
  _q_no  = cats('"', tranwrd(strip(notes),         '"', '""'), '"');
  _line  = catx(',', strip(file_code), strip(put(col_order, best12.)),
                _q_sn, _q_oc, _q_nm, strip(sas_type),
                strip(put(len_, best12.)), _q_inf, _q_fmt, _q_no,
                strip(src_encoding));
  put _line;
run;

%macro p15b_assert_csv;
  %local _nspec _ncsv;
  %let _nspec = -1; %let _ncsv = -1;
  proc sql noprint;
    select count(*) into :_nspec trimmed from pdd.import_spec_new;
  quit;
  data work._p15b_csv_rc;
    infile "C:\data_dictionary\docs\import_spec_new_generated.csv"
           lrecl=5000 encoding="&p15b_spec_enc" firstobs=2 end=_eof;
    input;
    _row + 1;
    if _eof then output;
    keep _row;
  run;
  proc sql noprint;
    select _row into :_ncsv trimmed from work._p15b_csv_rc;
  quit;
  proc datasets lib=work nolist nowarn; delete _p15b_csv_rc; quit;
  %if &_ncsv ne &_nspec %then
    %fail_out(msg=%str(import_spec_new_generated.csv has &_ncsv data rows but pdd.import_spec_new has &_nspec));
  %put NOTE: [15b_new_inventory_spec] CSV row-count assert passed (&_ncsv rows);
%mend p15b_assert_csv;
%p15b_assert_csv;

%put NOTE: [15b_new_inventory_spec] docs\import_spec_new_generated.csv written -- commit it (no PHI: names, types, lengths only);

proc datasets lib=work nolist nowarn;
  delete p15b_csv_cols p15b_prepass_all p15b_probe_all p15b_named
         p15b_spec_in p15b_spec_typed p15b_hdr_all p15b_counts;
quit;

%_note_written_ds(ds=pdd.source_inventory_new, label=pdd.source_inventory_new);
%_note_written_ds(ds=pdd.header_inventory_new, label=pdd.header_inventory_new);
%_note_written_ds(ds=pdd.header_matrix_new,    label=pdd.header_matrix_new);
%_note_written_ds(ds=pdd.raw_char_lengths_new, label=pdd.raw_char_lengths_new);
%_note_written_ds(ds=pdd.import_spec_new,      label=pdd.import_spec_new);

%restore_log;

