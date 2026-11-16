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

/* SECTION 5+ (pre-pass, probe, names, spec) -- appended in Task 2 */

%_note_written_ds(ds=pdd.source_inventory_new, label=pdd.source_inventory_new);
%_note_written_ds(ds=pdd.header_inventory_new, label=pdd.header_inventory_new);
%_note_written_ds(ds=pdd.header_matrix_new,    label=pdd.header_matrix_new);

%restore_log;
