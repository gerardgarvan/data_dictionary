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
           qc_new_overlap qc_new_overlap_conflicts;
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
   SECTION 8 -- 1:1 gate (NEW-04)
   Each new file must be 1:1 per normalized case ID with 0 blank IDs
   (PDD-D-17 extension). Nothing is deduplicated. The QC CSV is exported
   before the gate stops the run.
   ============================================================ */

data work.p15c_o2o;
  length s_code $4 n_rows 8 n_distinct_psid 8 n_blank_psid 8
         n_distinct_mrn 8 n_distinct_enc 8 n_enc_multi_case 8 status $4;
  stop;
run;

%macro p15c_one_to_one;
  %local _i _sc _mrn _enc _exp _nr _nd _nb _nm _ne _nmc _st _bad;
  %let _bad = ;

  %do _i = 21 %to 23;
    %let _sc = s&_i;
    %let _mrn = ; %let _enc = ; %let _exp = -1;
    %let _nr = -1; %let _nd = -1; %let _nb = -1;
    %let _nm = -1; %let _ne = -1; %let _nmc = -1;

    proc sql noprint;
      select strip(sas_name) into :_mrn trimmed from work.p15c_spec
        where file_code = "&_sc"
          and upcase(compress(orig_col_name, ' _')) = 'ENCRYPTEDMRN';
      select strip(sas_name) into :_enc trimmed from work.p15c_spec
        where file_code = "&_sc"
          and upcase(compress(orig_col_name, ' _')) = 'ENCRYPTEDENCOUNTER';
      select expected_distinct_psid into :_exp trimmed from work.p15c_files
        where s_code = "&_sc";
    quit;
    %if %length(&_mrn) = 0 or %length(&_enc) = 0 %then
      %fail_out(msg=%str(p15c_one_to_one: ENCRYPTED_MRN or ENCRYPTED_ENCOUNTER not in the spec for &_sc));

    proc sql noprint;
      select count(*), count(distinct norm_psid), sum(norm_psid = ''),
             count(distinct &_mrn), count(distinct &_enc)
        into :_nr trimmed, :_nd trimmed, :_nb trimmed,
             :_nm trimmed, :_ne trimmed
        from pdd.nsrc_&_sc;
      select count(*) into :_nmc trimmed
        from (select &_enc from pdd.nsrc_&_sc
              where &_enc ne '' and norm_psid ne ''
              group by &_enc
              having count(distinct norm_psid) > 1);
    quit;
    %if &_nr = -1 or &_nd = -1 or &_nb = -1 or &_nm = -1 or &_ne = -1 or &_nmc = -1 %then
      %fail_out(msg=%str(p15c_one_to_one: count query did not populate for &_sc));

    %let _st = FAIL;
    %if &_nr = &_nd and &_nb = 0 and &_nd = &_exp %then %let _st = PASS;
    %if &_st = FAIL %then %let _bad = &_bad &_sc;

    proc sql noprint;
      insert into work.p15c_o2o
        (s_code, n_rows, n_distinct_psid, n_blank_psid, n_distinct_mrn,
         n_distinct_enc, n_enc_multi_case, status)
      values ("&_sc", &_nr, &_nd, &_nb, &_nm, &_ne, &_nmc, "&_st");
    quit;
    %put NOTE: [15c_new_import] &_sc 1:1 check &_st (multi-case patients make distinct MRN below row count; that is expected);
  %end;

  data pdd.qc_new_one_to_one;
    set work.p15c_o2o;
  run;

  proc export data=pdd.qc_new_one_to_one
              outfile="&exchange_path.\new_one_to_one.csv"
              dbms=csv replace;
  run;

  %if %length(&_bad) > 0 %then
    %fail_out(msg=%str(PENDING DECISION -- file(s) &_bad not 1:1 per case (PDD-D-17 extension, NEW-04). No row was dropped or chosen.));
  %put NOTE: [15c_new_import] 1:1 gate passed for s21 s22 s23;
%mend p15c_one_to_one;


/* ============================================================
   SECTION 9 -- Overlap and pairwise gate (NEW-05)
   PAIRWISE_NEW, SPINE, OLD20_UNION, SHARED_COL_CONFLICT rows are written
   and exported first; then the gates stop the run if any count is above
   0. Counts go to the P: log and exchange files only, not to git.
   MRN overlap is not computed across eras (K1 and K2 keys differ,
   PDD-D-26).
   ============================================================ */

data work.p15c_ov;
  length check_type $20 file_a $8 file_b $8 n_shared 8 status $14;
  stop;
run;

%macro p15c_ov_row(ct=, a=, b=, n=, st=);
  %local _st;
  %if %length(&st) > 0 %then %let _st = &st;
  %else %if &n = 0 %then %let _st = ZERO;
  %else %let _st = SHARED;
  proc sql noprint;
    insert into work.p15c_ov (check_type, file_a, file_b, n_shared, status)
    values ("&ct", "&a", "&b", &n, "&_st");
  quit;
%mend p15c_ov_row;

/* PDD-D-30: per-column count of shared s22 x s23 cases whose values differ.
   Columns compared = same name and same type in both files. Counts only. */
%macro p15c_conflicts(n_shared=0);
  %global p15c_ncol;
  %local _nv _i _ncol;
  %let p15c_ncol = 0;
  %let _nv = 0;
  %let _ncol = 0;

  data work.p15c_conf;
    length pair $8 column $32 n_cases_differ 8;
    stop;
  run;

  %if &n_shared > 0 %then %do;
    proc sql noprint;
      select a.name into :_cv1-
        from dictionary.columns as a
             inner join dictionary.columns as b
             on upcase(a.name) = upcase(b.name) and a.type = b.type
        where a.libname = 'PDD' and a.memname = 'NSRC_S22'
          and b.libname = 'PDD' and b.memname = 'NSRC_S23'
          and upcase(a.name) ne 'NORM_PSID'
        order by a.varnum;
    quit;
    %let _nv = &sqlobs;

    %if &_nv > 0 %then %do;
      proc sql;
        create table work.p15c_ca as
          select * from pdd.nsrc_s22
          where norm_psid in (select norm_psid from work.p15c_shared)
          order by norm_psid;
        create table work.p15c_cb as
          select * from pdd.nsrc_s23
          where norm_psid in (select norm_psid from work.p15c_shared)
          order by norm_psid;
      quit;

      data work.p15c_cmp(keep=__d1-__d&_nv);
        merge work.p15c_ca(in=__ina keep=norm_psid %do _i = 1 %to &_nv; &&_cv&_i %end;)
              work.p15c_cb(in=__inb keep=norm_psid %do _i = 1 %to &_nv; &&_cv&_i %end;
                           rename=(%do _i = 1 %to &_nv; &&_cv&_i=__b&_i %end;));
        by norm_psid;
        if __ina and __inb;
        array __d{&_nv} __d1-__d&_nv;
        %do _i = 1 %to &_nv;
          __d{&_i} = (&&_cv&_i ne __b&_i);
        %end;
      run;

      proc means data=work.p15c_cmp noprint;
        var __d1-__d&_nv;
        output out=work.p15c_vsum(drop=_type_ _freq_) sum=;
      run;

      data work.p15c_conf(keep=pair column n_cases_differ);
        length pair $8 column $32 n_cases_differ 8;
        set work.p15c_vsum;
        pair = 's22_s23';
        %do _i = 1 %to &_nv;
          column = "&&_cv&_i";
          n_cases_differ = __d&_i;
          if n_cases_differ > 0 then output;
        %end;
      run;
    %end;
  %end;

  proc sql noprint;
    select count(*) into :_ncol trimmed from work.p15c_conf;
  quit;
  %let p15c_ncol = &_ncol;

  data pdd.qc_new_overlap_conflicts;
    set work.p15c_conf;
  run;

  proc export data=pdd.qc_new_overlap_conflicts
              outfile="&exchange_path.\new_overlap_conflicts.csv"
              dbms=csv replace;
  run;

  proc datasets lib=work nolist nowarn;
    delete p15c_ca p15c_cb p15c_cmp p15c_vsum p15c_conf;
  quit;
%mend p15c_conflicts;

%macro p15c_overlap;
  %local _n2122 _n2123 _n2223 _s21 _s22 _s23 _o21 _o22 _o23
         _old_list _n_old _k _m _nonorm _i _exp _dmin _dmax _smin _smax
         _nmrn _d30 _st2223;
  %let _n2122 = -1; %let _n2123 = -1; %let _n2223 = -1;
  %let _s21 = -1; %let _s22 = -1; %let _s23 = -1;
  %let _o21 = -1; %let _o22 = -1; %let _o23 = -1;
  %let _old_list = ; %let _nonorm = ; %let _n_old = 0;
  %let _exp = -1; %let _dmin = -1; %let _dmax = -1;
  %let _smin = -1; %let _smax = -1; %let _nmrn = -1;
  %let _d30 = 0; %let _st2223 = ;

  /* a. pairwise between the new files, distinct non-blank normalized IDs */
  proc sql noprint;
    select count(*) into :_n2122 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s21 a
       inner join pdd.nsrc_s22 b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
    select count(*) into :_n2123 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s21 a
       inner join pdd.nsrc_s23 b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
    select count(*) into :_n2223 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s22 a
       inner join pdd.nsrc_s23 b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
  quit;

  /* b. spine overlap (pdd.src_s09) */
  proc sql noprint;
    select count(*) into :_s21 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s21 a
       inner join pdd.src_s09 b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
    select count(*) into :_s22 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s22 a
       inner join pdd.src_s09 b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
    select count(*) into :_s23 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s23 a
       inner join pdd.src_s09 b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
  quit;

  /* c. union of the old sources that carry norm_psid */
  proc sql noprint;
    select distinct memname into :_old_list separated by ' '
    from dictionary.columns
    where libname = 'PDD' and memname like 'SRC_S__'
      and upcase(name) = 'NORM_PSID';
    select lowcase(substr(memname, 5)) into :_nonorm separated by ' '
    from dictionary.tables
    where libname = 'PDD' and memname like 'SRC_S__'
      and memname not in (select memname from dictionary.columns
                          where libname = 'PDD' and upcase(name) = 'NORM_PSID');
  quit;
  %let _n_old = %sysfunc(countw(&_old_list, %str( )));
  %put NOTE: [15c_new_import] old sources with norm_psid: &_n_old, without (expected s04 s05, PDD-D-18): &_nonorm;

  proc datasets lib=work nolist nowarn;
    delete p15c_old_stack p15c_old_ids;
  quit;
  %do _k = 1 %to &_n_old;
    %let _m = %scan(&_old_list, &_k, %str( ));
    proc append base=work.p15c_old_stack
                data=pdd.&_m(keep=norm_psid where=(norm_psid ne ''));
    run;
  %end;

  proc sql noprint;
    create table work.p15c_old_ids as
      select distinct norm_psid from work.p15c_old_stack
      where norm_psid ne '';
    select count(*) into :_o21 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s21 a
       inner join work.p15c_old_ids b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
    select count(*) into :_o22 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s22 a
       inner join work.p15c_old_ids b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
    select count(*) into :_o23 trimmed from
      (select distinct a.norm_psid from pdd.nsrc_s23 a
       inner join work.p15c_old_ids b on a.norm_psid = b.norm_psid
       where a.norm_psid ne '');
  quit;

  /* d. PDD-D-30 decision for the s22 x s23 pair (docs/new_overlap_decisions.csv) */
  data work.p15c_dec;
    length pair $12 expected_n_shared 8 id_min 8 id_max 8 rule $30 decision $12;
    infile "C:\data_dictionary\docs\new_overlap_decisions.csv" dsd dlm=','
           firstobs=2 truncover lrecl=500;
    input pair $ expected_n_shared id_min id_max rule $ decision $;
    pair = strip(pair);
  run;

  proc sql noprint;
    select expected_n_shared, id_min, id_max
      into :_exp trimmed, :_dmin trimmed, :_dmax trimmed
      from work.p15c_dec where pair = 's22_s23';

    create table work.p15c_shared as
      select distinct a.norm_psid from pdd.nsrc_s22 a
      inner join pdd.nsrc_s23 b on a.norm_psid = b.norm_psid
      where a.norm_psid ne '';

    select min(input(substr(norm_psid, 8), 8.)), max(input(substr(norm_psid, 8), 8.))
      into :_smin trimmed, :_smax trimmed
      from work.p15c_shared;

    select count(*) into :_nmrn trimmed
      from pdd.nsrc_s22 a inner join pdd.nsrc_s23 b
           on a.norm_psid = b.norm_psid
      where a.norm_psid ne ''
        and (a.ENCRYPTED_MRN ne b.ENCRYPTED_MRN
             or a.ENCRYPTED_ENCOUNTER ne b.ENCRYPTED_ENCOUNTER);
  quit;

  %if &_n2223 = 0 %then %do;
    %let _smin = 0;
    %let _smax = 0;
  %end;

  %if &_n2122 < 0 or &_n2123 < 0 or &_n2223 < 0 or &_s21 < 0 or &_s22 < 0
      or &_s23 < 0 or &_o21 < 0 or &_o22 < 0 or &_o23 < 0 or &_exp < 0
      or &_nmrn < 0 %then
    %fail_out(msg=%str(p15c_overlap: an overlap count query did not populate));

  %if &_n2223 = &_exp and &_smin = &_dmin and &_smax = &_dmax and &_nmrn = 0 %then
    %let _d30 = 1;
  %if &_d30 = 1 %then %let _st2223 = DECIDED;

  %p15c_ov_row(ct=PAIRWISE_NEW, a=s21, b=s22, n=&_n2122);
  %p15c_ov_row(ct=PAIRWISE_NEW, a=s21, b=s23, n=&_n2123);
  %p15c_ov_row(ct=PAIRWISE_NEW, a=s22, b=s23, n=&_n2223, st=&_st2223);
  %p15c_ov_row(ct=SPINE, a=s21, b=s09, n=&_s21);
  %p15c_ov_row(ct=SPINE, a=s22, b=s09, n=&_s22);
  %p15c_ov_row(ct=SPINE, a=s23, b=s09, n=&_s23);
  %p15c_ov_row(ct=OLD20_UNION, a=s21, b=s01-s20, n=&_o21);
  %p15c_ov_row(ct=OLD20_UNION, a=s22, b=s01-s20, n=&_o22);
  %p15c_ov_row(ct=OLD20_UNION, a=s23, b=s01-s20, n=&_o23);

  /* e. value conflicts on the shared s22 x s23 cases (counts per column) */
  %p15c_conflicts(n_shared=&_n2223);
  %if &_n2223 = 0 %then
    %p15c_ov_row(ct=SHARED_COL_CONFLICT, a=s22, b=s23, n=0, st=NOT_APPLICABLE);
  %else
    %p15c_ov_row(ct=SHARED_COL_CONFLICT, a=s22, b=s23, n=&p15c_ncol, st=COMPARED);

  data pdd.qc_new_overlap;
    set work.p15c_ov;
  run;

  proc export data=pdd.qc_new_overlap
              outfile="&exchange_path.\new_overlap.csv"
              dbms=csv replace;
  run;

  /* Gates: QC is already written. Never stack, never pick a precedence beyond PDD-D-30. */
  %if %eval(&_n2122 + &_n2123) > 0 %then
    %fail_out(msg=%str(PENDING DECISION -- s21 shares normalized case IDs with a later new file (PDD-D-29 item 3): s21-s22=&_n2122 s21-s23=&_n2123. Do not stack, Gerard decides.));
  %if &_d30 ne 1 %then
    %fail_out(msg=%str(PENDING DECISION -- s22-s23 overlap does not match docs/new_overlap_decisions.csv (PDD-D-30): n_shared=&_n2223 expected=&_exp id_range=&_smin..&_smax expected=&_dmin..&_dmax mrn_or_encounter_mismatches=&_nmrn (must be 0). Do not stack, Gerard decides.));
  %if %eval(&_o21 + &_o22 + &_o23 + &_s21 + &_s22 + &_s23) > 0 %then
    %fail_out(msg=%str(PENDING DECISION -- new files share case IDs with 2018-2022 sources: s21=&_o21 s22=&_o22 s23=&_o23 (spine &_s21 &_s22 &_s23). Reopen PDD-D-25 (precedence).));
  %put NOTE: [15c_new_import] PASS -- s21-s22 0, s21-s23 0, s22-s23 &_n2223 per PDD-D-30 (id range &_smin..&_smax, MRN and encounter equal), columns with differing values: &p15c_ncol;
  %put NOTE: [15c_new_import] spine overlap 0/0/0, old-source overlap 0/0/0;
  proc datasets lib=work nolist nowarn;
    delete p15c_dec p15c_shared;
  quit;
%mend p15c_overlap;


/* ============================================================
   SECTION 10 -- Run in order (every macro is defined above its call)
   ============================================================ */

%p15c_preconditions;
%p15c_load;
%p15c_import_all;
%p15c_char_scan;
%p15c_type_changes;
%p15c_one_to_one;
%p15c_overlap;

%_note_written_ds(ds=pdd.nsrc_s21, label=pdd.nsrc_s21);
%_note_written_ds(ds=pdd.nsrc_s22, label=pdd.nsrc_s22);
%_note_written_ds(ds=pdd.nsrc_s23, label=pdd.nsrc_s23);
%_note_written_ds(ds=pdd.qc_import_rowcounts_new, label=pdd.qc_import_rowcounts_new);
%_note_written_ds(ds=pdd.qc_new_nonascii, label=pdd.qc_new_nonascii);
%_note_written_ds(ds=pdd.qc_new_type_changes, label=pdd.qc_new_type_changes);
%_note_written_ds(ds=pdd.qc_new_one_to_one, label=pdd.qc_new_one_to_one);
%_note_written_ds(ds=pdd.qc_new_overlap, label=pdd.qc_new_overlap);
%_note_written_ds(ds=pdd.qc_new_overlap_conflicts, label=pdd.qc_new_overlap_conflicts);

proc datasets lib=work nolist nowarn;
  delete p15c_:;
quit;

%restore_log;
