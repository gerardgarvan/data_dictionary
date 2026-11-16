/*==========================================================================
  Program : 15c_new_import.sas
  Phase   : 15 (new-source intake), plan 15-03
  Purpose : NEW-03 import half, NEW-03a type changes, NEW-04 1:1 gate,
            NEW-05 overlap and pairwise gate (PDD-D-29 item 3).
            Imports the three new files s21 s22 s23 from the 15b spec with
            explicit lengths and informats, each in its own encoding (utf-8
            for s21, wlatin1 for s22 and s23, PDD-D-23). No PROC IMPORT.
            norm_psid comes from %pdd_norm_psid unchanged (PDD-D-19, applied
            to 2023-2025 by PDD-D-29 item 1).
            Dataset names are nsrc_s21..s23, not src_s21..s23: the Phase 3
            norm_psid loop sweeps every pdd member like SRC_S__ (A11).
  Inputs  : docs/import_spec_new_generated.csv (15b output, committed)
            docs/new_source_files.csv (file list and expected counts)
            docs/source_guard_baseline_new.csv (15a approved)
            pdd.raw_char_lengths_new (15b), pdd.src_s01..s20 (v1.0)
            &raw_master\<new files> (read only)
  Outputs : pdd.nsrc_s21, pdd.nsrc_s22, pdd.nsrc_s23,
            pdd.qc_import_rowcounts_new, pdd.qc_new_nonascii,
            pdd.qc_new_type_changes, pdd.qc_new_one_to_one,
            pdd.qc_new_overlap
            &exchange_path\new_rowcounts.csv, new_nonascii.csv,
            new_type_changes.csv, new_one_to_one.csv, new_overlap.csv
  Gates   : A gate writes its QC first, then stops with PENDING DECISION.
            Nothing is deduplicated, stacked or given a precedence here.
  Run     : standalone, after 15b has run and import_spec_new_generated.csv
            is committed. Status: PENDING SAS RUN.
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
    proc printto log="&logs_path.\15c_new_import.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%macro fail_out(msg=);
  %put ERROR: [15c_new_import] &msg;
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
      %put NOTE: [15c_new_import] &label written (&_nw rows);
    %else
      %put WARNING: [15c_new_import] &label written but has 0 rows;
  %end;
  %else
    %put WARNING: [15c_new_import] &label was NOT written;
%mend _note_written_ds;

%check_encoding;
%check_pdd_lib;

/* Encoding of the committed spec CSV (written by 15b as utf-8) */
%let p15c_spec_enc = utf-8;


/* ============================================================
   SECTION 2 -- Preconditions
   ============================================================ */

%macro p15c_preconditions;
  %local _n_old;
  %let _n_old = -1;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\import_spec_new_generated.csv)) %then
    %fail_out(msg=%str(p15c_preconditions: docs/import_spec_new_generated.csv not found -- run 15b and commit it));
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\new_source_files.csv)) %then
    %fail_out(msg=%str(p15c_preconditions: docs/new_source_files.csv not found));
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\source_guard_baseline_new.csv)) %then
    %fail_out(msg=%str(PENDING DECISION -- new baseline not approved (NEW-01); run 15a first));
  %if not %sysfunc(exist(pdd.raw_char_lengths_new)) %then
    %fail_out(msg=%str(p15c_preconditions: pdd.raw_char_lengths_new missing -- run 15b));
  %if not %sysfunc(exist(pdd.src_s09)) %then
    %fail_out(msg=%str(p15c_preconditions: pdd.src_s09 (spine) missing));
  proc sql noprint;
    select count(*) into :_n_old trimmed
    from dictionary.tables
    where libname = 'PDD' and memname like 'SRC_S__';
  quit;
  %if &_n_old ne 20 %then
    %fail_out(msg=%str(p15c_preconditions: &_n_old old source datasets like SRC_S__ in pdd -- expected 20));
  %route_log;
  %put NOTE: [15c_new_import] === Phase 15 plan 03 starting ===;
  %put NOTE: [15c_new_import] raw_master = &raw_master;

  proc datasets lib=pdd nolist nowarn;
    delete nsrc_s21 nsrc_s22 nsrc_s23 qc_import_rowcounts_new
           qc_new_nonascii qc_new_type_changes qc_new_one_to_one
           qc_new_overlap;
  quit;
%mend p15c_preconditions;


/* ============================================================
   SECTION 3 -- Load the file list and the spec
   ============================================================ */

%macro p15c_load;
  %local _n_files _n_spec _n_bad94 _n_enc _n_pid;
  %let _n_files = -1; %let _n_spec = -1; %let _n_bad94 = -1;
  %let _n_enc = -1; %let _n_pid = -1;

  data work.p15c_files;
    length s_code $4 filename $200 ftype $5 src_encoding $10
           expected_rows 8 expected_cols 8 expected_distinct_psid 8
           full_path $500;
    infile "C:\data_dictionary\docs\new_source_files.csv" dsd dlm=','
           firstobs=2 truncover lrecl=500;
    input s_code $ filename $ ftype $ src_encoding $
          expected_rows expected_cols expected_distinct_psid;
    s_code       = strip(s_code);
    filename     = strip(filename);
    src_encoding = strip(src_encoding);
    full_path    = cats("&raw_master.\", strip(filename));
  run;

  data work.p15c_spec;
    length file_code $4 col_order 8 src_name $256 orig_col_name $256
           sas_name $32 sas_type $1 spec_len 8 informat $34 fmt $34
           notes $200 src_encoding $10;
    infile "C:\data_dictionary\docs\import_spec_new_generated.csv"
           dsd dlm=',' firstobs=2 truncover lrecl=5000
           encoding="&p15c_spec_enc";
    input file_code $ col_order src_name $ orig_col_name $ sas_name $
          sas_type $ spec_len informat $ fmt $ notes $ src_encoding $;
    file_code     = strip(file_code);
    src_name      = strip(src_name);
    orig_col_name = strip(orig_col_name);
    sas_name      = strip(sas_name);
    sas_type      = strip(sas_type);
    informat      = strip(informat);
    fmt           = strip(fmt);
    src_encoding  = strip(src_encoding);
  run;

  proc sql noprint;
    select count(*) into :_n_files trimmed from work.p15c_files
      where s_code in ('s21', 's22', 's23');
    select count(*) into :_n_spec trimmed from work.p15c_spec;
    select count(*) into :_n_bad94 trimmed
      from (select file_code, count(*) as n from work.p15c_spec
            group by file_code) where n ne 94;
    select count(*) into :_n_enc trimmed
      from work.p15c_spec
      where (file_code = 's21' and src_encoding eq 'utf-8')
         or (file_code in ('s22', 's23') and src_encoding eq 'wlatin1');
    select count(*) into :_n_pid trimmed
      from (select file_code from work.p15c_spec
            where upcase(compress(orig_col_name, ' _')) = 'PRECEDESTUDYID'
              and sas_type = 'C'
            group by file_code having count(*) = 1);
  quit;

  %if &_n_files ne 3 %then
    %fail_out(msg=%str(p15c_load: file list must hold exactly s21 s22 s23 (found &_n_files)));
  %if &_n_spec ne 282 %then
    %fail_out(msg=%str(p15c_load: spec has &_n_spec rows -- expected 282 (3 x 94)));
  %if &_n_bad94 ne 0 %then
    %fail_out(msg=%str(p15c_load: &_n_bad94 file code(s) without exactly 94 spec rows));
  %if &_n_enc ne 282 %then
    %fail_out(msg=%str(p15c_load: spec encodings are not s21 utf-8 / s22 wlatin1 / s23 wlatin1));
  %if &_n_pid ne 3 %then
    %fail_out(msg=%str(p15c_load: PRECEDE Study ID is not exactly one char column per file (found &_n_pid)));
  %put NOTE: [15c_new_import] file list and spec loaded and checked;
%mend p15c_load;


/* ============================================================
   SECTION 4 -- One-file import from the spec (generated DATA step)
   ============================================================ */

data work.p15c_rowcounts;
  length s_code $4 filename $200 src_encoding $10 expected_rows 8
         raw_data_lines 8 n_imported 8 status $12;
  stop;
run;

%macro p15c_import_one(sc=);
  %local _full _enc _fn _exp _idvar _nimp _nraw _st _gen_rc _n_malformed;
  %let _full = ; %let _enc = ; %let _fn = ; %let _exp = ;
  %let _idvar = ; %let _nimp = -1; %let _nraw = -1; %let _n_malformed = -1;

  data _null_;
    set work.p15c_files(where=(s_code = "&sc"));
    call symputx('_full', full_path,     'L');
    call symputx('_enc',  src_encoding,  'L');
    call symputx('_fn',   filename,      'L');
    call symputx('_exp',  expected_rows, 'L');
  run;

  %if %length(&_full) = 0 or %length(&_enc) = 0 %then
    %fail_out(msg=%str(p15c_import_one: no file list row for &sc));
  %if not %sysfunc(fileexist(&_full)) %then
    %fail_out(msg=%str(p15c_import_one: file not found for &sc));

  proc sql noprint;
    select strip(sas_name) into :_idvar trimmed
    from work.p15c_spec
    where file_code = "&sc"
      and upcase(compress(orig_col_name, ' _')) = 'PRECEDESTUDYID';
  quit;
  %if %length(&_idvar) = 0 %then
    %fail_out(msg=%str(p15c_import_one: no PRECEDE Study ID row in spec for &sc));

  %put NOTE: [15c_new_import] === import &sc encoding=&_enc idvar=&_idvar ===;

  proc sort data=work.p15c_spec(where=(file_code = "&sc")) out=work.p15c_spec_one;
    by col_order;
  run;

  /* Generated import code: temporary file in WORK, not in git */
  filename _p15cg "%sysfunc(pathname(work))\p15c_gen_&sc..sas"
           encoding="&p15c_spec_enc";

  data _null_;
    set work.p15c_spec_one end=_eof;
    file _p15cg lrecl=32767;
    length _line $2000;
    if _n_ = 1 then do;
      put "data work.p15c_raw_&sc;";
      _line = catx(' ', "infile", "'&_full'", "encoding='&_enc'",
                   "dsd dlm=',' firstobs=2 truncover lrecl=32767;");
      put _line;
      put '  length';
    end;
    _line = '    ' || catx(' ', strip(sas_name),
              ifc(sas_type = 'C', cats('$', strip(put(spec_len, best12.))),
                  '8'));
    put _line;
    if _eof then put '  ;';
  run;

  data _null_;
    set work.p15c_spec_one end=_eof;
    file _p15cg lrecl=32767 mod;
    length _line _inf $2000;
    if _n_ = 1 then put '  input';
    if sas_type = 'C' then
      _inf = ifc(lengthn(informat) > 0, informat,
                 cats('$', strip(put(spec_len, best12.)), '.'));
    else
      _inf = ifc(lengthn(informat) > 0, informat, 'best32.');
    _line = '    ' || catx(' ', strip(sas_name), cats(':', _inf));
    put _line;
    if _eof then do;
      put '  ;';
      put 'run;';
    end;
  run;

  /* Syntax check of the generated LENGTH lines (no values, names only) */
  data _null_;
    infile _p15cg lrecl=32767 end=_eof;
    input;
    retain _bad 0 _in_len 0;
    if strip(_infile_) = 'length' then _in_len = 1;
    else if strip(_infile_) = ';' then _in_len = 0;
    else if _in_len and not prxmatch('/^\S+ \$?\d+$/', strip(_infile_)) then _bad + 1;
    if _eof then call symputx('_n_malformed', _bad, 'L');
  run;
  %if &_n_malformed ne 0 %then
    %fail_out(msg=%str(p15c_import_one: &sc generator emitted &_n_malformed malformed LENGTH line(s)));

  %include _p15cg;
  %let _gen_rc = &syserr;
  filename _p15cg clear;
  %if &_gen_rc > 4 or not %sysfunc(exist(work.p15c_raw_&sc)) %then
    %fail_out(msg=%str(p15c_import_one: generated import step failed for &sc syserr=&_gen_rc));

  %pdd_norm_psid(in=work.p15c_raw_&sc, out=pdd.nsrc_&sc, idvar=&_idvar);

  proc sql noprint;
    select count(*) into :_nimp trimmed from pdd.nsrc_&sc;
  quit;

  data _null_;
    infile "&_full" encoding="&_enc" firstobs=2 lrecl=32767 end=_e truncover;
    input;
    _n + 1;
    if _e then call symputx('_nraw', _n, 'L');
  run;

  %let _st = MISMATCH;
  %if &_nimp = &_exp and &_nimp = &_nraw %then %let _st = MATCH;
  %else %if &_nimp = &_exp %then %do;
    %let _st = MATCH_RAWDIFF;
    %put NOTE: [15c_new_import] &sc raw line count (&_nraw) differs from imported rows (&_nimp); likely embedded line breaks;
  %end;

  proc sql noprint;
    insert into work.p15c_rowcounts
      (s_code, filename, src_encoding, expected_rows, raw_data_lines,
       n_imported, status)
    values ("&sc", "&_fn", "&_enc", &_exp, &_nraw, &_nimp, "&_st");
  quit;

  proc datasets lib=work nolist nowarn;
    delete p15c_spec_one;
  quit;
%mend p15c_import_one;


/* ============================================================
   SECTION 5 -- Import all three, reconcile row counts
   ============================================================ */

%macro p15c_import_all;
  %local _bad _n_np;
  %let _bad = ; %let _n_np = -1;

  %p15c_import_one(sc=s21);
  %p15c_import_one(sc=s22);
  %p15c_import_one(sc=s23);

  data pdd.qc_import_rowcounts_new;
    set work.p15c_rowcounts;
  run;

  proc export data=pdd.qc_import_rowcounts_new
              outfile="&exchange_path.\new_rowcounts.csv"
              dbms=csv replace;
  run;

  proc sql noprint;
    select strip(s_code) into :_bad separated by ' '
    from work.p15c_rowcounts where status = 'MISMATCH';
    select count(*) into :_n_np trimmed
    from (select memname from dictionary.columns
          where libname = 'PDD'
            and memname in ('NSRC_S21', 'NSRC_S22', 'NSRC_S23')
            and upcase(name) = 'NORM_PSID'
          group by memname having count(*) = 1);
  quit;

  %if %length(&_bad) > 0 %then
    %fail_out(msg=%str(row count does not match probe for &_bad (NEW-03)));
  %if &_n_np ne 3 %then
    %fail_out(msg=%str(p15c_import_all: each nsrc dataset must have exactly one norm_psid column (found &_n_np of 3)));
  %put NOTE: [15c_new_import] row counts reconciled; norm_psid present once in each nsrc dataset;
%mend p15c_import_all;


/* ============================================================
   SECTION 6 -- Truncation check and non-ASCII report (A5)
   One pass per file: post-import max length and non-ASCII cell count
   for every character variable. Names and counts only, no values.
   ============================================================ */

data work.p15c_charscan;
  length s_code $4 sas_name $32 post_max 8 n_nonascii_cells 8;
  stop;
run;

%macro p15c_char_scan;
  %local _i _sc _n_trunc _trunc_list _na;
  %let _n_trunc = -1; %let _trunc_list = ; %let _na = -1;

  %do _i = 21 %to 23;
    %let _sc = s&_i;
    data work.p15c_cs_one;
      set pdd.nsrc_&_sc end=_eof;
      array _c {*} _character_;
      length s_code $4 sas_name $32 post_max 8 n_nonascii_cells 8;
      array _m {500} _temporary_;
      array _a {500} _temporary_;
      if _n_ = 1 then do;
        if dim(_c) > 500 then do;
          put "ERROR: [15c_new_import] more than 500 character variables in &_sc";
          abort cancel;
        end;
        do _j = 1 to dim(_c);
          _m{_j} = 0;
          _a{_j} = 0;
        end;
      end;
      do _j = 1 to dim(_c);
        _m{_j} = max(_m{_j}, lengthn(_c{_j}));
        if verify(_c{_j}, collate(0, 127)) > 0 then _a{_j} = _a{_j} + 1;
      end;
      if _eof then do _j = 1 to dim(_c);
        s_code = "&_sc";
        sas_name = vname(_c{_j});
        post_max = _m{_j};
        n_nonascii_cells = _a{_j};
        output;
      end;
      keep s_code sas_name post_max n_nonascii_cells;
    run;
    proc append base=work.p15c_charscan data=work.p15c_cs_one; run;
    proc datasets lib=work nolist nowarn; delete p15c_cs_one; quit;
  %end;

  /* Truncation: post-import max must not be below the pre-pass maximum */
  proc sql noprint;
    select count(*) into :_n_trunc trimmed
    from work.p15c_charscan c
    inner join work.p15c_spec s
      on c.s_code = s.file_code and upcase(c.sas_name) = upcase(s.sas_name)
    inner join pdd.raw_char_lengths_new l
      on s.file_code = l.s_code and s.col_order = l.col_order
    where s.sas_type = 'C' and c.post_max < l.max_len;

    select strip(c.s_code) || ':' || strip(c.sas_name)
           into :_trunc_list separated by ' '
    from work.p15c_charscan c
    inner join work.p15c_spec s
      on c.s_code = s.file_code and upcase(c.sas_name) = upcase(s.sas_name)
    inner join pdd.raw_char_lengths_new l
      on s.file_code = l.s_code and s.col_order = l.col_order
    where s.sas_type = 'C' and c.post_max < l.max_len;
  quit;
  %if &_n_trunc ne 0 %then
    %fail_out(msg=%str(possible truncation after import in &_n_trunc column(s): &_trunc_list));
  %put NOTE: [15c_new_import] truncation check passed (no column shorter than the pre-pass maximum);

  /* Non-ASCII report: informational, not a guard (A5) */
  data pdd.qc_new_nonascii;
    set work.p15c_charscan(where=(upcase(sas_name) ne 'NORM_PSID'));
    keep s_code sas_name n_nonascii_cells;
  run;

  proc export data=pdd.qc_new_nonascii
              outfile="&exchange_path.\new_nonascii.csv"
              dbms=csv replace;
  run;

  %do _i = 21 %to 23;
    proc sql noprint;
      select coalesce(sum(n_nonascii_cells), 0) into :_na trimmed
      from pdd.qc_new_nonascii where s_code = "s&_i";
    quit;
    %put NOTE: [15c_new_import] s&_i non-ASCII cells after transcoding: &_na (informational);
  %end;
%mend p15c_char_scan;


/* ============================================================
   SECTION 7 -- Type changes against the 20 old sources (NEW-03a)
   Report only. Nothing is renamed or retyped at source; Phase 16 map
   review decides. Match key: upcase name without blanks/underscores.
   ============================================================ */

%macro p15c_type_changes;
  %local _n_tc _n_dd _n_fr;
  %let _n_tc = -1; %let _n_dd = -1; %let _n_fr = -1;

  proc sql noprint;
    create table pdd.qc_new_type_changes as
    select n.norm_key length=64,
           lowcase(substr(n.memname, 6)) as new_s_code length=4,
           n.name as new_sas_name length=32,
           n.type as new_type length=4,
           n.length as new_length,
           lowcase(substr(o.memname, 5)) as old_s_code length=4,
           o.name as old_sas_name length=32,
           o.type as old_type length=4,
           o.length as old_length
    from (select memname, name, type, length,
                 compress(upcase(name), ' _') as norm_key
          from dictionary.columns
          where libname = 'PDD'
            and memname in ('NSRC_S21', 'NSRC_S22', 'NSRC_S23')
            and upcase(name) ne 'NORM_PSID') n
    inner join
         (select memname, name, type, length,
                 compress(upcase(name), ' _') as norm_key
          from dictionary.columns
          where libname = 'PDD'
            and memname like 'SRC_S__'
            and upcase(name) ne 'NORM_PSID') o
      on n.norm_key = o.norm_key
    where n.type ne o.type
    order by n.norm_key, new_s_code, old_s_code;

    select count(*) into :_n_tc trimmed from pdd.qc_new_type_changes;
    select count(*) into :_n_dd trimmed from pdd.qc_new_type_changes
      where norm_key = 'DEATHDAYSAFTERSURGERY';
    select count(distinct norm_key) into :_n_fr trimmed
      from pdd.qc_new_type_changes
      where norm_key in ('FEELSEXAUSTED', 'LOWPHYSICALACTIVITY',
                         'SLOWWALKINGSPEED', 'UNINTENDEDWEIGHTLOSS',
                         'WEEKGRIPSTRENGTH');
  quit;

  proc export data=pdd.qc_new_type_changes
              outfile="&exchange_path.\new_type_changes.csv"
              dbms=csv replace;
  run;

  %put NOTE: [15c_new_import] type changes vs old sources: &_n_tc row(s) -- for Phase 16 map review;
  %put NOTE: [15c_new_import] DEATHDAYSAFTERSURGERY type-change rows: &_n_dd;
  %put NOTE: [15c_new_import] frailty component keys (5 checked) with a type change: &_n_fr;
  %put NOTE: [15c_new_import] Fraility_ and _Value spelling variants: see docs/new_source_header_variants.csv;
%mend p15c_type_changes;


/* ============================================================
   SECTION 8 -- Run (Sections 2-7); 1:1 and overlap gates follow
   ============================================================ */

%p15c_preconditions;
%p15c_load;
%p15c_import_all;
%p15c_char_scan;
%p15c_type_changes;

%_note_written_ds(ds=pdd.nsrc_s21, label=pdd.nsrc_s21);
%_note_written_ds(ds=pdd.nsrc_s22, label=pdd.nsrc_s22);
%_note_written_ds(ds=pdd.nsrc_s23, label=pdd.nsrc_s23);
%_note_written_ds(ds=pdd.qc_import_rowcounts_new, label=pdd.qc_import_rowcounts_new);
%_note_written_ds(ds=pdd.qc_new_nonascii, label=pdd.qc_new_nonascii);

proc datasets lib=work nolist nowarn;
  delete p15c_:;
quit;

%restore_log;
