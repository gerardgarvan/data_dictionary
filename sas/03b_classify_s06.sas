/*==========================================================================
  Program : 03b_classify_s06.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : D-21 (2026-10-20 LOCKED) -- classify every column in pdd.src_s06
            into one of four classes and write the classification artifacts
            that Phase 4 (name map) and Phase 5 (PCNR_ build) will consume.

              CLOCK        -- clock-drawing features; excluded from PCNR_
              DIGITAL_OTHER -- other digital cognitive battery tests; PCNR_
              UNSURE       -- COM/COPY/LINUS prefix, token unrecognized
              PCNR         -- all other columns; always PCNR_

            NOT added to 99_run_all.sas.  Run standalone before Phase 4.
            Phase 4 cannot start until Gerard reviews the UNSURE sheet.

  Clock token rules (D-21):
    Tokens recognized after COM or COPY prefix (case-sensitive):
      ClockFace  -- clock face circle features
      HH         -- hour hand features
      MH         -- minute hand features
      HandPair   -- combined hand pair features
      Digit      -- clock numeral features
      Hooklet    -- small hook at end of hands
      PCF        -- pen contact fraction (clock face contact measure)
      Intersect  -- hand-intersection geometry; a standard dCDT feature
                    unique to clock-drawing instruments; not present in any
                    other digital cognitive test in this dataset
    DIGITAL_OTHER tokens after COM or COPY prefix:
      MOCA, MoCA, Stroop, COWAT, DKEFS, PvLT, VerbFl, Libon
    LINUS prefix: DIGITAL_OTHER unconditionally (Libon mental control/
      digit span)
    COMP prefix followed by digit: PCNR (complication code columns such as
      COMP10_PULM_COMPL; P followed by digit is the complication token)
    All other columns: PCNR (no COM/COPY/LINUS prefix)

  Reads   : pdd.src_s06 (Phase 3 output -- must exist before this runs)
            dictionary.columns (SAS metadata)

  Writes  : C:\data_dictionary\docs\s06_column_class.csv  (committed)
            &qc_path.\s06_clock_classification.xlsx  (P: only)
            &logs_path.\03b_classify_s06.log  (standalone; not committed)
            &logs_path.\03b_unsure_nmiss.sas  (generated; not committed)

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
   SECTION 2 -- Precondition: pdd.src_s06 must exist
   ============================================================ */

%macro _check_src_s06;
  %local _n;
  proc sql noprint;
    select count(*) into :_n trimmed
    from dictionary.members
    where upcase(libname) = 'PDD'
      and upcase(memname) = 'SRC_S06'
      and upcase(memtype) = 'DATA';
  quit;
  %if &_n = 0 %then
    %fail_out(msg=%str(pdd.src_s06 not found -- run Phase 3 first));
  %put NOTE: [03b_classify_s06] pdd.src_s06 confirmed in pdd library;
%mend _check_src_s06;
%_check_src_s06;


/* ============================================================
   SECTION 3 -- Read column metadata from dictionary.columns
   label stores the original column header set by the import DATA step
   ============================================================ */

proc sql noprint;
  create table work.s06_cols as
  select name  as sas_name       length=64,
         label as orig_col_name  length=256,
         type,
         varnum
  from dictionary.columns
  where upcase(libname) = 'PDD'
    and upcase(memname) = 'SRC_S06'
  order by varnum;
quit;

proc sql noprint;
  select count(*) into :_ncols trimmed from work.s06_cols;
quit;
%put NOTE: [03b_classify_s06] column count = &_ncols (expected 3987);


/* ============================================================
   SECTION 4 -- Classification
   Token patterns applied in priority order; first match wins.

   Naming convention: COMtoken_feature (no separator between COM/COPY
   and the token -- options validvarname=v7 preserves underscores in the
   rest of the name but the immediate character after the prefix is the
   first letter of the token).

   regex flags: no /i  -- matches are case-sensitive per D-21 spec.
   ============================================================ */

data work.s06_class;
  set work.s06_cols;
  length token $64 class $20 rule $120;

  /* ---- COM prefix immediately followed by an uppercase letter ---- */
  if prxmatch('/^COM[A-Z]/', sas_name) then do;
    token = substr(sas_name, 4);   /* strip "COM"; remainder starts with token */

    /* CLOCK: remainder starts with a recognized clock-drawing token */
    if prxmatch('/^(ClockFace|HH|MH|HandPair|Digit|Hooklet|PCF|Intersect)/', token)
    then do;
      class = 'CLOCK';
      rule  = 'COM + clock token (D-21)';
    end;

    /* PCNR: complication codes -- P followed by a digit (e.g. P10, P20) */
    else if prxmatch('/^P\d/', token) then do;
      class = 'PCNR';
      rule  = 'COMP## complication code -- always PCNR';
      token = '';
    end;

    /* DIGITAL_OTHER: other digital cognitive battery tests */
    else if prxmatch('/^(MOCA|MoCA|Stroop|COWAT|DKEFS|PvLT|VerbFl|Libon)/', token)
    then do;
      class = 'DIGITAL_OTHER';
      rule  = 'COM + digital test token (non-clock; stays PCNR_)';
    end;

    /* UNSURE: COM prefix but token not in either known list */
    else do;
      class = 'UNSURE';
      rule  = 'COM prefix -- token not in CLOCK or DIGITAL_OTHER list';
    end;
  end;

  /* ---- COPY prefix immediately followed by an uppercase letter ---- */
  else if prxmatch('/^COPY[A-Z]/', sas_name) then do;
    token = substr(sas_name, 5);   /* strip "COPY" */

    if prxmatch('/^(ClockFace|HH|MH|HandPair|Digit|Hooklet|PCF|Intersect)/', token)
    then do;
      class = 'CLOCK';
      rule  = 'COPY + clock token (D-21)';
    end;
    else if prxmatch('/^(MOCA|MoCA|Stroop|COWAT|DKEFS|PvLT|VerbFl|Libon)/', token)
    then do;
      class = 'DIGITAL_OTHER';
      rule  = 'COPY + digital test token (non-clock; stays PCNR_)';
    end;
    else do;
      class = 'UNSURE';
      rule  = 'COPY prefix -- token not in CLOCK or DIGITAL_OTHER list';
    end;
  end;

  /* ---- LINUS prefix -- Libon mental control / digit span ---- */
  else if prxmatch('/^LINUS/', sas_name) then do;
    token = 'LINUS';
    class = 'DIGITAL_OTHER';
    rule  = 'LINUS prefix (Libon mental control / digit span)';
  end;

  /* ---- All other columns ---- */
  else do;
    token = '';
    class = 'PCNR';
    rule  = 'No COM/COPY/LINUS prefix -- always PCNR';
  end;

run;


/* ============================================================
   SECTION 5 -- Assertions
   (a) total rows = &_ncols (expected 3987)
   (b) every row has a non-missing class
   ============================================================ */

%macro _assert_class;
  %local _ntotal _nmiss_class;
  proc sql noprint;
    select count(*) into :_ntotal      trimmed from work.s06_class;
    select count(*) into :_nmiss_class trimmed
      from work.s06_class
      where missing(class) or strip(class) = '';
  quit;
  %if &_ntotal ne &_ncols %then
    %fail_out(msg=%str(ASSERT FAILED -- s06_class row count=&_ntotal expected &_ncols));
  %if &_nmiss_class ne 0 %then
    %fail_out(msg=%str(ASSERT FAILED -- &_nmiss_class rows have missing class));
  %put NOTE: [03b_classify_s06] assert passed -- &_ntotal rows, 0 missing class;
%mend _assert_class;
%_assert_class;


/* ============================================================
   SECTION 6 -- Class count summary
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
  put NOTE: "[03b_classify_s06] class=" class +(-1) "  n=" n_cols;
run;

/* Token x class counts (for SUMMARY sheet) */
proc sql noprint;
  create table work.token_class_summary as
  select token,
         class,
         count(*) as n_cols label='Column count'
  from work.s06_class
  where strip(token) ne ''
  group by token, class
  order by token, class;
quit;


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
   SECTION 8 -- Compute % non-null for UNSURE columns
   Generates a PROC SQL UNION ALL file then %includes it.
   ============================================================ */

proc sql noprint;
  select count(*) into :_n_unsure trimmed
  from work.s06_class where class = 'UNSURE';
quit;
%put NOTE: [03b_classify_s06] UNSURE column count = &_n_unsure;

%macro _gen_unsure_nmiss;
  %if &_n_unsure = 0 %then %do;
    data work.unsure_nmiss;
      length sas_name $64 n_total 8 n_miss 8 pct_nonnull 8;
      stop;
    run;
  %end;
  %else %do;
    /* Write a PROC SQL with one SELECT per UNSURE column, UNION ALL joined */
    data _null_;
      file "&logs_path.\03b_unsure_nmiss.sas";
      put "proc sql noprint;";
      put "  create table work.unsure_nmiss as";
    run;

    data _null_;
      set work.s06_class (where=(class = 'UNSURE'));
      file "&logs_path.\03b_unsure_nmiss.sas" mod;
      if _n_ > 1 then put "  union all";
      put "  select '" sas_name +(-1) "' as sas_name length=64,";
      put "         count(*) as n_total,";
      put "         sum(missing(" sas_name +(-1) ")) as n_miss";
      put "  from pdd.src_s06";
    run;

    data _null_;
      file "&logs_path.\03b_unsure_nmiss.sas" mod;
      put "  ;";
      put "quit;";
    run;

    %include "&logs_path.\03b_unsure_nmiss.sas";

    data work.unsure_nmiss;
      set work.unsure_nmiss;
      pct_nonnull = (n_total - n_miss) / n_total * 100;
      format pct_nonnull 6.1;
    run;
  %end;
%mend _gen_unsure_nmiss;
%_gen_unsure_nmiss;

/* Merge orig_col_name and token into the UNSURE nmiss table */
proc sql noprint;
  create table work.unsure_detail as
  select u.sas_name,
         c.orig_col_name,
         c.token,
         u.n_total,
         u.n_miss,
         u.pct_nonnull
  from work.unsure_nmiss as u
  left join work.s06_class as c
    on u.sas_name = c.sas_name
  order by u.pct_nonnull descending;
quit;


/* ============================================================
   SECTION 9 -- ODS style (UF colors)
   ============================================================ */

proc template;
  define style pdd_uf / parent=styles.minimal;
    style fonts from fonts /
      'defaultFont' = ('Calibri', 10pt);
    style header from header /
      background = '#0021A5'
      color      = '#FFFFFF'
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
   Sheet order: KEY (leftmost) | SUMMARY | UNSURE
   UF header: #0021A5 (blue) / white text
   ============================================================ */

ods excel file="&qc_path.\s06_clock_classification.xlsx"
  style=pdd_uf
  options(sheet_name='KEY'
          sheet_interval='none'
          frozen_headers='yes'
          autofilter='all');

  title "s06 Column Classification -- D-21 (2026-10-20)";
  title2 "CLOCK columns excluded from PCNR_. Review UNSURE sheet before Phase 4.";

  proc print data=work.s06_class noobs label;
    var sas_name orig_col_name token class rule;
    label sas_name      = 'SAS Name'
          orig_col_name = 'Original Column'
          token         = 'Token'
          class         = 'Class'
          rule          = 'Rule';
  run;

ods excel options(sheet_name='SUMMARY' sheet_interval='now');

  title  "Class Counts";
  title2 "All 3,987 s06 columns; CLOCK excluded from PCNR_";

  proc print data=work.class_summary noobs label;
    var class n_cols;
    label class  = 'Class'
          n_cols = 'Column count';
  run;

  title  "Token x Class Counts";
  title2 "(blank token = no COM/COPY/LINUS prefix)";

  proc print data=work.token_class_summary noobs label;
    var token class n_cols;
    label token  = 'Token'
          class  = 'Class'
          n_cols = 'Column count';
  run;

ods excel options(sheet_name='UNSURE' sheet_interval='now');

  title  "UNSURE Columns -- Review before Phase 4";
  title2 "COM/COPY/LINUS prefix but token not in CLOCK or DIGITAL_OTHER list";
  title3 "Sorted by pct_nonnull descending; add tokens to clock or other list after review";

  proc print data=work.unsure_detail noobs label;
    var sas_name orig_col_name token pct_nonnull;
    label sas_name      = 'SAS Name'
          orig_col_name = 'Original Column'
          token         = 'Token'
          pct_nonnull   = '% Non-null';
  run;

title;
ods excel close;

%put NOTE: [03b_classify_s06] &qc_path.\s06_clock_classification.xlsx written;


/* ============================================================
   SECTION 11 -- Final log summary
   ============================================================ */

data _null_;
  set work.class_summary;
  put NOTE: "[03b_classify_s06] FINAL class=" class +(-1) "  n=" n_cols;
run;

%put NOTE: [03b_classify_s06] Phase 4 gate: review UNSURE sheet before proceeding;
%put NOTE: [03b_classify_s06] Artifact: docs/s06_column_class.csv (committed -- no PHI);

%restore_log;
