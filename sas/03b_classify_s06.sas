/*==========================================================================
  Program : 03b_classify_s06.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : D-21 (2026-10-20 LOCKED) -- classify every source column in
            pdd.src_s06 (3,987 columns from pdd.header_inventory s_code='s06')
            into one of four classes and write the classification artifacts
            that Phase 4 (name map) and Phase 5 (PCNR_ build) will consume.

              CLOCK        -- clock-drawing features; excluded from PCNR_
              DIGITAL_OTHER -- other digital cognitive battery tests; PCNR_
              PCNR         -- all other columns; always PCNR_
              UNSURE       -- COM/COPY prefix, token unrecognized (must = 0)

            NOT added to 99_run_all.sas.  Run standalone before Phase 4.

  Classification rules (D-21, reviewed Gerard 2026-10-20):
    0. Only classify 3,987 source columns in pdd.header_inventory (s_code='s06').
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

  Reads   : pdd.src_s06, pdd.header_inventory (Phase 2/3 outputs)
            dictionary.columns (SAS metadata)

  Writes  : C:\data_dictionary\docs\s06_column_class.csv  (committed)
            &qc_path.\s06_clock_classification.xlsx  (P: only)
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
   SECTION 2 -- Preconditions: pdd.src_s06 and pdd.header_inventory
   ============================================================ */

%macro _check_preconditions;
  %local _n_s06 _n_hi;
  proc sql noprint;
    select count(*) into :_n_s06 trimmed
    from dictionary.members
    where upcase(libname) = 'PDD'
      and upcase(memname) = 'SRC_S06'
      and upcase(memtype) = 'DATA';
    select count(*) into :_n_hi trimmed
    from dictionary.members
    where upcase(libname) = 'PDD'
      and upcase(memname) = 'HEADER_INVENTORY'
      and upcase(memtype) = 'DATA';
  quit;
  %if &_n_s06 = 0 %then
    %fail_out(msg=%str(pdd.src_s06 not found -- run Phase 3 first));
  %if &_n_hi = 0 %then
    %fail_out(msg=%str(pdd.header_inventory not found -- run Phase 2 first));
  %put NOTE: [03b_classify_s06] pdd.src_s06 and pdd.header_inventory confirmed;
%mend _check_preconditions;
%_check_preconditions;


/* ============================================================
   SECTION 3 -- Read column metadata; intersect with header_inventory
   Only the 3,987 source columns (s_code='s06') are classified.
   norm_psid and other Phase-3-derived columns are excluded.
   ============================================================ */

proc sql noprint;
  create table work.s06_cols as
  select d.name  as sas_name       length=64,
         d.label as orig_col_name  length=256,
         d.type,
         d.varnum
  from dictionary.columns as d
  inner join pdd.header_inventory as h
    on upcase(d.name) = upcase(h.col_name)
   and upcase(h.s_code) = 'S06'
  where upcase(d.libname) = 'PDD'
    and upcase(d.memname) = 'SRC_S06'
  order by d.varnum;
quit;

proc sql noprint;
  select count(*) into :_ncols trimmed from work.s06_cols;
quit;
%put NOTE: [03b_classify_s06] source column count = &_ncols (expected 3987);


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
       If any count differs, list differing rows to log before failing.
   ============================================================ */

%macro _assert_class;
  %local _ntotal _nmiss_class
         _n_clock _n_do _n_pcnr _n_unsure _fail;

  proc sql noprint;
    select count(*)           into :_ntotal      trimmed from work.s06_class;
    select count(*)           into :_nmiss_class trimmed
      from work.s06_class where missing(class) or strip(class) = '';
    select count(*)           into :_n_clock      trimmed
      from work.s06_class where class = 'CLOCK';
    select count(*)           into :_n_do         trimmed
      from work.s06_class where class = 'DIGITAL_OTHER';
    select count(*)           into :_n_pcnr        trimmed
      from work.s06_class where class = 'PCNR';
    select count(*)           into :_n_unsure      trimmed
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
    /* List all columns with unexpected classification */
    data _null_;
      set work.s06_class;
      if class = 'UNSURE' or class not in ('CLOCK' 'DIGITAL_OTHER' 'PCNR' 'UNSURE')
      then put 'NOTE: [03b] DIFF col=' sas_name ' class=' class ' rule=' rule;
    run;
    %fail_out(msg=%str(ASSERT FAILED -- counts: CLOCK=&_n_clock DO=&_n_do PCNR=&_n_pcnr UNSURE=&_n_unsure));
  %end;

  %put NOTE: [03b_classify_s06] assert passed -- &_ntotal rows CLOCK=&_n_clock DO=&_n_do PCNR=&_n_pcnr UNSURE=&_n_unsure;
%mend _assert_class;
%_assert_class;


/* ============================================================
   SECTION 6 -- Summary tables for SUMMARY sheet
   (a) class counts
   (b) rule x class counts
   ============================================================ */

proc sql noprint;
  create table work.class_summary as
  select class,
         count(*) as n_cols label='Column count'
  from work.s06_class
  group by class
  order by class;

  create table work.rule_class_summary as
  select rule,
         class,
         count(*) as n_cols label='Column count'
  from work.s06_class
  group by rule, class
  order by rule, class;
quit;

data _null_;
  set work.class_summary;
  put NOTE: "[03b_classify_s06] class=" class +(-1) "  n=" n_cols;
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
  order by c.varnum;
quit;

/* Class-level subsets for individual xlsx sheets */
data work.s06_clock        (keep=sas_name orig_col_name token rule pct_nonnull)
     work.s06_digital_other(keep=sas_name orig_col_name token rule pct_nonnull)
     work.s06_pcnr          (keep=sas_name orig_col_name token rule pct_nonnull);
  set work.s06_class_nn;
  if      class = 'CLOCK'         then output work.s06_clock;
  else if class = 'DIGITAL_OTHER' then output work.s06_digital_other;
  else if class = 'PCNR'          then output work.s06_pcnr;
run;


/* ============================================================
   SECTION 9 -- ODS style (UF colors: #0021A5 header / white text)
   ============================================================ */

proc template;
  define style pdd_uf / parent=styles.minimal;
    style fonts from fonts /
      'defaultFont' = ('Calibri', 10pt);
    style header from header /
      background  = '#0021A5'
      color       = '#FFFFFF'
      font_weight = bold
      font_size   = 10pt;
    style column from column /
      background = '#FFFFFF';
    style data from data /
      font_size = 10pt;
  end;
run;


/* ============================================================
   SECTION 10 -- Write qc\s06_clock_classification.xlsx
   Sheet order: KEY | SUMMARY | CLOCK | DIGITAL_OTHER | PCNR
   No UNSURE sheet when UNSURE=0 (asserted above).
   ============================================================ */

ods excel file="&qc_path.\s06_clock_classification.xlsx"
  style=pdd_uf
  options(sheet_name='KEY'
          sheet_interval='none'
          frozen_headers='yes'
          autofilter='all');

  title "s06 Column Classification -- D-21 (2026-10-20, LOCKED)";
  title2 "CLOCK=2747 excluded from PCNR_.  DIGITAL_OTHER=809 PCNR=431.  UNSURE=0.";

  proc report data=work.s06_class_nn nowd;
    columns sas_name orig_col_name token class rule pct_nonnull;
    define sas_name      / display 'SAS Name';
    define orig_col_name / display 'Original Column';
    define token         / display 'Token';
    define class         / display 'Class';
    define rule          / display 'Rule';
    define pct_nonnull   / display '% Non-null' format=6.1;
  run;

ods excel options(sheet_name='SUMMARY' sheet_interval='now');

  title  "Class Counts (D-21 reviewed 2026-10-20)";
  title2 "CLOCK excluded from PCNR_; DIGITAL_OTHER stays PCNR_";

  proc report data=work.class_summary nowd;
    columns class n_cols;
    define class   / display 'Class';
    define n_cols  / display 'Column count';
  run;

  title  "Rule x Class Counts";
  title2 "(all 3,987 source columns)";

  proc report data=work.rule_class_summary nowd;
    columns rule class n_cols;
    define rule   / display 'Rule';
    define class  / display 'Class';
    define n_cols / display 'Column count';
  run;

ods excel options(sheet_name='CLOCK' sheet_interval='now');

  title  "CLOCK Columns (n=2,747) -- Excluded from PCNR_";
  title2 "COM/COPY clock tokens + LINUS DCTclock summary";

  proc report data=work.s06_clock nowd;
    columns sas_name orig_col_name token rule pct_nonnull;
    define sas_name      / display 'SAS Name';
    define orig_col_name / display 'Original Column';
    define token         / display 'Token';
    define rule          / display 'Rule';
    define pct_nonnull   / display '% Non-null' format=6.1;
  run;

ods excel options(sheet_name='DIGITAL_OTHER' sheet_interval='now');

  title  "DIGITAL_OTHER Columns (n=809) -- Stay in PCNR_";
  title2 "COM/COPY non-clock digital battery tokens";

  proc report data=work.s06_digital_other nowd;
    columns sas_name orig_col_name token rule pct_nonnull;
    define sas_name      / display 'SAS Name';
    define orig_col_name / display 'Original Column';
    define token         / display 'Token';
    define rule          / display 'Rule';
    define pct_nonnull   / display '% Non-null' format=6.1;
  run;

ods excel options(sheet_name='PCNR' sheet_interval='now');

  title  "PCNR Columns (n=431) -- Always PCNR_";
  title2 "No COM/COPY/LINUS/COMP prefix + clock admin/Mini-Cog flags";

  proc report data=work.s06_pcnr nowd;
    columns sas_name orig_col_name token rule pct_nonnull;
    define sas_name      / display 'SAS Name';
    define orig_col_name / display 'Original Column';
    define token         / display 'Token';
    define rule          / display 'Rule';
    define pct_nonnull   / display '% Non-null' format=6.1;
  run;

title;
ods excel close;

/* Conditional NOTE: only when syscc clean and all sheet datasets have rows */
%macro _note_xlsx_written;
  %local _nx_clock _nx_do _nx_pcnr _nx_key _nx_sum;
  proc sql noprint;
    select nobs into :_nx_key  trimmed
      from dictionary.tables
      where upcase(libname)='WORK' and upcase(memname)='S06_CLASS_NN';
    select nobs into :_nx_sum  trimmed
      from dictionary.tables
      where upcase(libname)='WORK' and upcase(memname)='CLASS_SUMMARY';
    select nobs into :_nx_clock trimmed
      from dictionary.tables
      where upcase(libname)='WORK' and upcase(memname)='S06_CLOCK';
    select nobs into :_nx_do   trimmed
      from dictionary.tables
      where upcase(libname)='WORK' and upcase(memname)='S06_DIGITAL_OTHER';
    select nobs into :_nx_pcnr trimmed
      from dictionary.tables
      where upcase(libname)='WORK' and upcase(memname)='S06_PCNR';
  quit;
  %if &syscc <= 4
    and &_nx_key  > 0
    and &_nx_sum  > 0
    and &_nx_clock > 0
    and &_nx_do   > 0
    and &_nx_pcnr > 0
  %then %put NOTE: [03b_classify_s06] &qc_path.\s06_clock_classification.xlsx written (KEY=&_nx_key CLOCK=&_nx_clock DO=&_nx_do PCNR=&_nx_pcnr);
  %else %put WARNING: [03b_classify_s06] xlsx may be incomplete -- syscc=&syscc KEY=&_nx_key CLOCK=&_nx_clock DO=&_nx_do PCNR=&_nx_pcnr;
%mend _note_xlsx_written;
%_note_xlsx_written;


/* ============================================================
   SECTION 11 -- Final log summary
   ============================================================ */

data _null_;
  set work.class_summary;
  put NOTE: "[03b_classify_s06] FINAL class=" class +(-1) "  n=" n_cols;
run;

%put NOTE: [03b_classify_s06] Artifact: docs/s06_column_class.csv (committed -- no PHI);
%put NOTE: [03b_classify_s06] Phase 4 gate: UNSURE=0 -- ready to proceed;

%restore_log;
