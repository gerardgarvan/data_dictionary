/*==========================================================================
  Program : 03b_classify_s06.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : D-21 (2026-10-20 LOCKED) -- classify every source column in
            pdd.src_s06 (3,987 columns from pdd.import_spec file_code='s06')
            into one of four classes and write the classification artifacts
            that Phase 4 (name map) and Phase 5 (PCNR_ build) will consume.

              CLOCK        -- clock-drawing features; excluded from PCNR_
              DIGITAL_OTHER -- other digital cognitive battery tests; PCNR_
              PCNR         -- all other columns; always PCNR_
              UNSURE       -- COM/COPY prefix, token unrecognized (must = 0)

            NOT added to 99_run_all.sas.  Run standalone before Phase 4.

  Classification rules (D-21, reviewed Gerard 2026-10-20):
    0. Only classify 3,987 source columns in pdd.import_spec (file_code='s06').
       norm_psid and other derived columns are excluded.
    1. ^LINUS (case-insensitive) -> CLOCK.
       Linus Health DCTclock summary columns (DCTScore, DCTClassification,
       COM/COP latency, ink, clockface metrics).  NOT Libon tests.
    2. ^COMP\d -> PCNR (complication codes such as COMP10_PULM_COMPL).
    3. ^(COPY|COM)(?=[A-Z]) -> token logic (case-sensitive prefix, uppercase
       letter immediately after; underscore after prefix does NOT match so
       COM_mini_cog_clock_only and COPY_mini_cog_clock_only remain PCNR).
       3a. token ^(Digits|Digit|Hooklet|Clock|HH|MH|Hand|PCF|Intersect|
                   Anchor|CFBF|CFNonCF|CenterDot|DigAvgNormSize|DigNormSize|
                   Dwg|InkLenTime|InkTimeByLen|InterDigit|Inter_TestLatency|
                   NoiseHisto|Over12|PersevDigits|PostCenterDot|PreCenterDot|
                   PreFirstHand|PreSecondHand|Spokes|TenEleven|TextStroke|
                   TickMark|TotInk) -> CLOCK
       3b. token ^(VerbFl|Libon|Pv|MOCA|Moca|DKEFSDESIGN|BNT|Beck|CVLTII|
                   EDSS|Grip|HOOPER|IADL|LPegs|MFIS|NineItemList|RBANS|
                   ReitanTrails|STROOP|SpatialWMS|TOMM|Tap|TrailsD_KEF|
                   Vigil|WAISIII|WAISIV|WASI|WISCONSIN|WMS|WRAT)
                -> DIGITAL_OTHER (stays PCNR_)
       3c. otherwise -> UNSURE
    4. Everything else -> PCNR.  Includes clock admin and Mini-Cog columns:
       pecan_clock_flag, Clock_Data, DigitalClockData, DigitalClockDataExpected,
       DigitalClockDataInfo, precede_aim1_2_clock_*, repeated_clock_instructions,
       Edu_Clock_notes, COM_mini_cog_clock_only, COPY_mini_cog_clock_only.

  Expected counts (Gerard 2026-10-20):
    CLOCK = 2747,  DIGITAL_OTHER = 809,  PCNR = 431,  UNSURE = 0

  Reads   : pdd.src_s06, pdd.import_spec (Phase 2/3 outputs)
            dictionary.columns (SAS metadata)

  Writes  : C:\data_dictionary\docs\s06_column_class.csv  (committed)
            &exchange_path.\s06_class_nn.csv  (P: exchange -- Python input; D-22)
            &logs_path.\03b_classify_s06.log  (standalone; not committed)

  PCM compliance:
    C3  -- no open-code %if/%else; all conditionals inside %macro blocks
    C9  -- LIBNAME engine before path (Base engine; no keyword required)
    C11 -- no macro keyword in quoted PUT strings
    C13 -- every macro defined before its first call
    C14 -- no bare data/set statements

  Author  : GSD (D-21, 2026-10-20)
==========================================================================*/


/* ============================================================
   SECTION 0 -- Config, libname, options
   ============================================================ */

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;


/* ============================================================
   SECTION 1 -- Utility macros
   All macros defined before any call (PCM C13).
   ============================================================ */

/* Route standalone log to a per-program file */
%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\03b_classify_s06.log" new; run;
  %end;
%mend route_log;

/* Restore log to default */
%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* Abort with loud ERROR.  %abort cancel ONLY called here. */
%macro fail_out(msg=);
  %put ERROR: [03b_classify_s06] &msg;
  %abort cancel;
%mend fail_out;

/* check_encoding and check_pdd_lib from 00_config.sas call %fail_out */
%check_encoding;
%check_pdd_lib;
%route_log;


/* ============================================================
   SECTION 2 -- Preconditions
   pdd.src_s06 must exist and have rows; pdd.import_spec must exist.
   ============================================================ */

%macro _check_preconditions;
  %local _n_s06 _n_is _nrows_s06;
  proc sql noprint;
    select count(*) into :_n_s06 trimmed
      from dictionary.members
      where upcase(libname) = 'PDD'
        and upcase(memname) = 'SRC_S06'
        and upcase(memtype) = 'DATA';
    select count(*) into :_n_is trimmed
      from dictionary.members
      where upcase(libname) = 'PDD'
        and upcase(memname) = 'IMPORT_SPEC'
        and upcase(memtype) = 'DATA';
  quit;
  %if &_n_s06 = 0 %then
    %fail_out(msg=%str(pdd.src_s06 not found -- run Phase 3 first));
  %if &_n_is = 0 %then
    %fail_out(msg=%str(pdd.import_spec not found -- run 03a_build_spec.sas first));

  proc sql noprint;
    select count(*) into :_nrows_s06 trimmed from pdd.src_s06;
  quit;
  %if &_nrows_s06 = 0 %then
    %fail_out(msg=%str(pdd.src_s06 has 0 rows -- Phase 3 may have failed));

  %put NOTE: [03b_classify_s06] pdd.src_s06 (&_nrows_s06 rows) and pdd.import_spec confirmed;
%mend _check_preconditions;
%_check_preconditions;


/* ============================================================
   SECTION 3 -- Build work.s06_cols from pdd.import_spec
   Source: pdd.import_spec where file_code='s06' (sas_name, orig_col_name,
   col_order) joined to dictionary.columns for type/varnum.
   Assertions: count=3987, no duplicate sas_name, all present in src_s06.
   ============================================================ */

%macro _build_s06_cols;
  %local _n_spec _n_dups _n_miss_dc;

  /* Step A: count spec rows for s06 */
  proc sql noprint;
    select count(*) into :_n_spec trimmed
      from pdd.import_spec
      where upcase(file_code) = 'S06';
  quit;
  %if &_n_spec ne 3987 %then
    %fail_out(msg=%str(pdd.import_spec s06 rows=&_n_spec expected 3987));

  /* Step B: check for duplicate sas_names in spec */
  proc sql noprint;
    select count(*) into :_n_dups trimmed
      from (select upcase(sas_name) as uname
              from pdd.import_spec
              where upcase(file_code) = 'S06'
              group by uname
              having count(*) > 1);
  quit;
  %if &_n_dups ne 0 %then
    %fail_out(msg=%str(pdd.import_spec s06 has &_n_dups sas_names appearing more than once));

  /* Step C: check that every spec sas_name exists in dictionary.columns for src_s06 */
  proc sql noprint;
    create table work._s06_miss_dc as
      select i.sas_name
        from pdd.import_spec as i
        left join dictionary.columns as d
          on upcase(i.sas_name) = upcase(d.name)
         and upcase(d.libname) = 'PDD'
         and upcase(d.memname) = 'SRC_S06'
        where upcase(i.file_code) = 'S06'
          and d.name is null;
    select count(*) into :_n_miss_dc trimmed from work._s06_miss_dc;
  quit;
  %if &_n_miss_dc ne 0 %then %do;
    data _null_;
      set work._s06_miss_dc;
      put 'ERROR: [03b_classify_s06] sas_name in import_spec but not in src_s06: ' sas_name;
    run;
    %fail_out(msg=%str(&_n_miss_dc import_spec sas_names missing from dictionary.columns for pdd.src_s06));
  %end;

  /* Step D: build the column list, ordered by import_spec col_order */
  proc sql noprint;
    create table work.s06_cols as
      select i.sas_name     length=64,
             i.orig_col_name length=256,
             i.col_order,
             d.type,
             d.varnum
        from pdd.import_spec as i
        inner join dictionary.columns as d
          on upcase(i.sas_name) = upcase(d.name)
         and upcase(d.libname) = 'PDD'
         and upcase(d.memname) = 'SRC_S06'
        where upcase(i.file_code) = 'S06'
        order by i.col_order;
  quit;

  proc datasets lib=work nolist; delete _s06_miss_dc; quit;

  %put NOTE: [03b_classify_s06] work.s06_cols built -- &_n_spec source columns (s06);
%mend _build_s06_cols;
%_build_s06_cols;

proc sql noprint;
  select count(*) into :_ncols trimmed from work.s06_cols;
quit;


/* ============================================================
   SECTION 4 -- Classification
   Rules applied in priority order; first match wins.
   Token patterns use prxmatch (DATA-step PCRE); no macro text handling.
   ============================================================ */

data work.s06_class;
  set work.s06_cols;
  length token $64 class $20 rule $160;

  /* ----------------------------------------------------------------
     Rule 1: LINUS prefix (case-insensitive) -> CLOCK
     Linus Health DCTclock summary; NOT Libon tests.
  ---------------------------------------------------------------- */
  if prxmatch('/^LINUS/i', sas_name) then do;
    token = 'LINUS';
    class = 'CLOCK';
    rule  = 'LINUS prefix (Linus Health DCTclock summary; D-21)';
  end;

  /* ----------------------------------------------------------------
     Rule 2: ^COMP\d -> PCNR  (complication codes)
     Must precede Rule 3 because COMP starts with COM.
  ---------------------------------------------------------------- */
  else if prxmatch('/^COMP\d/', sas_name) then do;
    token = '';
    class = 'PCNR';
    rule  = 'COMP## complication code -- always PCNR';
  end;

  /* ----------------------------------------------------------------
     Rule 3: COM immediately followed by uppercase letter
  ---------------------------------------------------------------- */
  else if prxmatch('/^COM(?=[A-Z])/', sas_name) then do;
    token = substr(sas_name, 4);   /* strip "COM"; remainder starts at token */

    /* 3a -- clock-drawing tokens */
    if prxmatch(
      '/^(Digits|Digit|Hooklet|Clock|HH|MH|Hand|PCF|Intersect|Anchor|' ||
      'CFBF|CFNonCF|CenterDot|DigAvgNormSize|DigNormSize|Dwg|InkLenTime|' ||
      'InkTimeByLen|InterDigit|Inter_TestLatency|NoiseHisto|Over12|' ||
      'PersevDigits|PostCenterDot|PreCenterDot|PreFirstHand|PreSecondHand|' ||
      'Spokes|TenEleven|TextStroke|TickMark|TotInk)/',
      token) then do;
      class = 'CLOCK';
      rule  = 'COM + clock token (D-21)';
    end;

    /* 3b -- other digital cognitive battery tests */
    else if prxmatch(
      '/^(VerbFl|Libon|Pv|MOCA|Moca|DKEFSDESIGN|BNT|Beck|CVLTII|EDSS|' ||
      'Grip|HOOPER|IADL|LPegs|MFIS|NineItemList|RBANS|ReitanTrails|' ||
      'STROOP|SpatialWMS|TOMM|Tap|TrailsD_KEF|Vigil|WAISIII|WAISIV|' ||
      'WASI|WISCONSIN|WMS|WRAT)/',
      token) then do;
      class = 'DIGITAL_OTHER';
      rule  = 'COM + digital test token (non-clock; stays PCNR_)';
    end;

    /* 3c -- unrecognized token */
    else do;
      class = 'UNSURE';
      rule  = 'COM prefix -- token not in CLOCK or DIGITAL_OTHER list';
    end;
  end;

  /* ----------------------------------------------------------------
     Rule 3 (COPY): COPY immediately followed by uppercase letter
  ---------------------------------------------------------------- */
  else if prxmatch('/^COPY(?=[A-Z])/', sas_name) then do;
    token = substr(sas_name, 5);   /* strip "COPY" */

    /* 3a -- clock-drawing tokens */
    if prxmatch(
      '/^(Digits|Digit|Hooklet|Clock|HH|MH|Hand|PCF|Intersect|Anchor|' ||
      'CFBF|CFNonCF|CenterDot|DigAvgNormSize|DigNormSize|Dwg|InkLenTime|' ||
      'InkTimeByLen|InterDigit|Inter_TestLatency|NoiseHisto|Over12|' ||
      'PersevDigits|PostCenterDot|PreCenterDot|PreFirstHand|PreSecondHand|' ||
      'Spokes|TenEleven|TextStroke|TickMark|TotInk)/',
      token) then do;
      class = 'CLOCK';
      rule  = 'COPY + clock token (D-21)';
    end;

    /* 3b -- other digital cognitive battery tests */
    else if prxmatch(
      '/^(VerbFl|Libon|Pv|MOCA|Moca|DKEFSDESIGN|BNT|Beck|CVLTII|EDSS|' ||
      'Grip|HOOPER|IADL|LPegs|MFIS|NineItemList|RBANS|ReitanTrails|' ||
      'STROOP|SpatialWMS|TOMM|Tap|TrailsD_KEF|Vigil|WAISIII|WAISIV|' ||
      'WASI|WISCONSIN|WMS|WRAT)/',
      token) then do;
      class = 'DIGITAL_OTHER';
      rule  = 'COPY + digital test token (non-clock; stays PCNR_)';
    end;

    /* 3c -- unrecognized token */
    else do;
      class = 'UNSURE';
      rule  = 'COPY prefix -- token not in CLOCK or DIGITAL_OTHER list';
    end;
  end;

  /* ----------------------------------------------------------------
     Rule 4: all other columns -> PCNR
     Includes clock admin, Mini-Cog, pecan_clock_flag, etc.
  ---------------------------------------------------------------- */
  else do;
    token = '';
    class = 'PCNR';
    rule  = 'No COM/COPY/LINUS/COMP prefix -- always PCNR';
  end;

run;


/* ============================================================
   SECTION 5 -- Assertions
   (a) total rows = &_ncols (expected 3987)
   (b) every row has a non-missing class
   (c) CLOCK=2747, DIGITAL_OTHER=809, PCNR=431, UNSURE=0
       On any failure: print rule_class_summary to log, then %fail_out.
   ============================================================ */

/* Build rule x class counts first (needed for failure log dump) */
proc sql noprint;
  create table work.rule_class_summary as
  select rule,
         class,
         count(*) as n_cols label='Column count'
  from work.s06_class
  group by rule, class
  order by rule, class;
quit;

%macro _assert_class;
  %local _ntotal _nmiss_class
         _n_clock _n_do _n_pcnr _n_unsure _fail;

  proc sql noprint;
    select count(*)  into :_ntotal      trimmed from work.s06_class;
    select count(*)  into :_nmiss_class trimmed
      from work.s06_class where missing(class) or strip(class) = '';
    select count(*)  into :_n_clock     trimmed
      from work.s06_class where class = 'CLOCK';
    select count(*)  into :_n_do        trimmed
      from work.s06_class where class = 'DIGITAL_OTHER';
    select count(*)  into :_n_pcnr      trimmed
      from work.s06_class where class = 'PCNR';
    select count(*)  into :_n_unsure    trimmed
      from work.s06_class where class = 'UNSURE';
  quit;

  %let _fail = 0;

  %if &_ntotal ne &_ncols %then %do;
    %put ERROR: [03b_classify_s06] ASSERT FAILED -- row count=&_ntotal expected &_ncols;
    %let _fail = 1;
  %end;

  %if &_nmiss_class ne 0 %then %do;
    %put ERROR: [03b_classify_s06] ASSERT FAILED -- &_nmiss_class rows have missing class;
    %let _fail = 1;
  %end;

  %if &_n_clock ne 2747 %then %do;
    %put ERROR: [03b_classify_s06] ASSERT FAILED -- CLOCK=&_n_clock expected 2747;
    %let _fail = 1;
  %end;

  %if &_n_do ne 809 %then %do;
    %put ERROR: [03b_classify_s06] ASSERT FAILED -- DIGITAL_OTHER=&_n_do expected 809;
    %let _fail = 1;
  %end;

  %if &_n_pcnr ne 431 %then %do;
    %put ERROR: [03b_classify_s06] ASSERT FAILED -- PCNR=&_n_pcnr expected 431;
    %let _fail = 1;
  %end;

  %if &_n_unsure ne 0 %then %do;
    %put ERROR: [03b_classify_s06] ASSERT FAILED -- UNSURE=&_n_unsure expected 0;
    %let _fail = 1;
  %end;

  %if &_fail %then %do;
    /* Dump rule x class counts to log before failing */
    data _null_;
      set work.rule_class_summary;
      put 'NOTE: [03b_classify_s06] RULE_CLASS_DUMP rule=' rule
          '  class=' class '  n=' n_cols;
    run;
    /* List UNSURE and unknown-class columns */
    data _null_;
      set work.s06_class;
      if class = 'UNSURE' or class not in ('CLOCK' 'DIGITAL_OTHER' 'PCNR' 'UNSURE')
      then put 'NOTE: [03b_classify_s06] DIFF col=' sas_name
               '  class=' class '  rule=' rule;
    run;
    %fail_out(msg=%str(ASSERT FAILED -- counts: CLOCK=&_n_clock DO=&_n_do PCNR=&_n_pcnr UNSURE=&_n_unsure));
  %end;

  %put NOTE: [03b_classify_s06] assert passed -- &_ntotal rows CLOCK=&_n_clock DO=&_n_do PCNR=&_n_pcnr UNSURE=&_n_unsure;
%mend _assert_class;
%_assert_class;


/* ============================================================
   SECTION 6 -- Summary tables
   (a) class counts
   (b) rule x class counts (built in Section 5 before assert)
   ============================================================ */

proc sql noprint;
  create table work.class_summary as
  select class,
         count(*) as n_cols label='Column count'
  from work.s06_class
  group by class
  order by class;
quit;

data _null_;
  set work.class_summary;
  put 'NOTE: [03b_classify_s06] class=' class +(-1) '  n=' n_cols;
run;


/* ============================================================
   SECTION 7 -- Write docs/s06_column_class.csv (committed)
   Contains column names and classification only -- no data values (no PHI)
   ============================================================ */

proc export
  data    = work.s06_class (keep=sas_name orig_col_name token class rule)
  outfile = "C:\data_dictionary\docs\s06_column_class.csv"
  dbms    = csv
  replace;
run;

%put NOTE: [03b_classify_s06] docs/s06_column_class.csv written;


/* ============================================================
   SECTION 8 -- Compute pct_nonnull for every source column
   Single DATA step over pdd.src_s06 using _temporary_ counters.
   Replaces the former PROC SQL UNION ALL (hit 256-table limit).
   ============================================================ */

/* Get col counts and row count for _temporary_ array sizing and EOF detection.
   Avoiding end=_eof: that variable would enter the PDV before array declarations
   and inflate dim(_num) by 1, causing a subscript-out-of-range error. */
proc sql noprint;
  select count(*) into :_nobs_s06 trimmed from pdd.src_s06;
  select count(*) into :_n_num    trimmed
    from dictionary.columns
    where upcase(libname) = 'PDD'
      and upcase(memname) = 'SRC_S06'
      and type = 'num';
  select count(*) into :_n_chr    trimmed
    from dictionary.columns
    where upcase(libname) = 'PDD'
      and upcase(memname) = 'SRC_S06'
      and type = 'char';
quit;
%put NOTE: [03b_classify_s06] src_s06 rows=&_nobs_s06 numeric cols=&_n_num char cols=&_n_chr;

/* Single DATA step pass: SET first (C10), then arrays, then _temporary_ counters.
   No pre-declared variables before arrays -- keeps dim(_num)=&_n_num exactly.
   EOF detected via _n_=&_nobs_s06 to avoid end= polluting _numeric_. */
data work.colmiss;
  keep sas_name n_miss n_total;
  set pdd.src_s06;                      /* SET first: C10 compliance          */
  array _num[*]      _numeric_;         /* captures src_s06 numerics only     */
  array _chr[*]      _character_;       /* captures src_s06 chars only        */
  array _nc[&_n_num] _temporary_ (&_n_num * 0);
  array _cc[&_n_chr] _temporary_ (&_n_chr * 0);
  do _i = 1 to dim(_num); _nc[_i] + missing(_num[_i]); end;
  do _i = 1 to dim(_chr); _cc[_i] + missing(_chr[_i]); end;
  if _n_ = &_nobs_s06 then do;
    do _i = 1 to dim(_num);
      sas_name = vname(_num[_i]);
      n_miss   = _nc[_i];
      n_total  = &_nobs_s06;
      output;
    end;
    do _i = 1 to dim(_chr);
      sas_name = vname(_chr[_i]);
      n_miss   = _cc[_i];
      n_total  = &_nobs_s06;
      output;
    end;
  end;
run;

data work.colmiss;
  set work.colmiss;
  pct_nonnull = (n_total - n_miss) / n_total * 100;
  format pct_nonnull 6.1;
run;

/* Merge pct_nonnull into classification table */
proc sql noprint;
  create table work.s06_class_nn as
  select c.sas_name,
         c.orig_col_name,
         c.token,
         c.class,
         c.rule,
         m.pct_nonnull
  from work.s06_class as c
  left join work.colmiss as m
    on upcase(c.sas_name) = upcase(m.sas_name)
  order by c.col_order;
quit;

/* Coverage assertions -- checked after the join */
%macro _assert_coverage;
  %local _ncm _n_total_cols _n_bad_pct;
  proc sql noprint;
    select count(*) into :_ncm          trimmed from work.colmiss;
    select count(*) into :_n_total_cols trimmed
      from dictionary.columns
      where upcase(libname) = 'PDD' and upcase(memname) = 'SRC_S06';
    select count(*) into :_n_bad_pct    trimmed
      from work.s06_class_nn
      where missing(pct_nonnull) or pct_nonnull < 0 or pct_nonnull > 100;
  quit;
  %if &_ncm ne &_n_total_cols %then
    %fail_out(msg=%str(ASSERT FAILED -- colmiss rows=&_ncm expected &_n_total_cols (one per src_s06 column)));
  %if &_n_bad_pct ne 0 %then
    %fail_out(msg=%str(ASSERT FAILED -- &_n_bad_pct of 3987 classified rows have pct_nonnull missing or out of [0 100]));
  %put NOTE: [03b_classify_s06] coverage assert passed -- colmiss=&_ncm bad_pct=0;
%mend _assert_coverage;
%_assert_coverage;

/* ============================================================
   SECTION 9 -- Write exchange CSV for Python workbook writer
   D-22 (2026-10-21): Python owns xlsx output.
   work.s06_class_nn -> &exchange_path.\s06_class_nn.csv
   Python reads this and writes qc\s06_clock_classification.xlsx
   ============================================================ */

%macro _export_exchange_csv;
  %local _exc_ok _nx_all _csv_ok;
  proc sql noprint;
    select nobs into :_nx_all trimmed
      from dictionary.tables
      where upcase(libname) = 'WORK' and upcase(memname) = 'S06_CLASS_NN';
  quit;
  %if &_nx_all <= 0 %then
    %fail_out(msg=%str(ASSERT FAILED -- work.s06_class_nn has 0 rows before export));

  proc export
    data    = work.s06_class_nn
              (keep=sas_name orig_col_name token class rule pct_nonnull)
    outfile = "&exchange_path.\s06_class_nn.csv"
    dbms    = csv
    replace;
  run;

  %let _exc_ok = %sysfunc(fileexist(&exchange_path.\s06_class_nn.csv));
  %let _csv_ok = %sysfunc(fileexist(C:\data_dictionary\docs\s06_column_class.csv));

  %if not &_exc_ok or not &_csv_ok %then
    %fail_out(msg=%str(ASSERT FAILED -- artifact check: exchange_csv=&_exc_ok docs_csv=&_csv_ok));

  %put NOTE: [03b_classify_s06] exchange CSV written -- &exchange_path.\s06_class_nn.csv (&_nx_all rows);
  %put NOTE: [03b_classify_s06] docs CSV confirmed -- docs/s06_column_class.csv;
%mend _export_exchange_csv;
%_export_exchange_csv;


/* ============================================================
   SECTION 10 -- Final log summary
   ============================================================ */

data _null_;
  set work.class_summary;
  put 'NOTE: [03b_classify_s06] FINAL class=' class +(-1) '  n=' n_cols;
run;

%put NOTE: [03b_classify_s06] Artifact: docs/s06_column_class.csv (committed -- no PHI);
%put NOTE: [03b_classify_s06] Artifact: exchange CSV at &exchange_path.\s06_class_nn.csv (Python input -- D-22);
%put NOTE: [03b_classify_s06] Phase 4 gate: UNSURE=0 -- ready to proceed;
%put NOTE: [03b_classify_s06] Next step: "%PDD_PYTHON%" python\scripts\write_s06_clock_classification.py;

%restore_log;
