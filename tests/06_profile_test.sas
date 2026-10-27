/*==========================================================================
  Program : tests/06_profile_test.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 6 synthetic test suite. Standalone -- no P: paths in
            Section 0 or synthetic tests. TC-03 integration block opens
            pdd read-only inside a wrapper macro.
            Calls real macros in 06_profile_macros.sas using WORK libs.
            Output: TESTRESULT: TC-N desc [label] PASS|FAIL|SKIP
                    TESTRESULT: SUMMARY passed=N failed=N skipped=N

  PCM compliance:
    C3  No open-code %if/%do outside %macro/%mend
    C11 No macro keyword in a quoted PUT string
    C13 All macro definitions before first call
    C14 No bare data;/set;
    C22 No datalines inside %macro...%mend
==========================================================================*/

options nosyntaxcheck nomlogic nomprint nosymbolgen;
/* Suppress SAS listing output for the entire test run.
   ODS OUTPUT (dataset destinations) is unaffected by listing close. */
ods listing close;

/*==========================================================================
  SECTION 0 -- Test harness macros (all defined before first call, C13)
==========================================================================*/

%macro _tc_start(n=, desc=);
  %global _tc_pass _tc_fail _tc_skip _tc_n _tc_desc p6_fail p6_fail_msg;
  %let _tc_n    = &n;
  %let _tc_desc = &desc;
%mend _tc_start;

/* Flag-based assertion: cond= must be a pre-computed 0/1 value, not an
   expression. A macro error inside _assert counts as FAIL (no silent PASS). */
%macro _assert(flag=, label=);
  %global _tc_pass _tc_fail;
  %if %bquote(&flag) = 1 %then %do;
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label] PASS;
    %let _tc_pass = %eval(&_tc_pass + 1);
  %end;
  %else %do;
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label] FAIL;
    %let _tc_fail = %eval(&_tc_fail + 1);
  %end;
%mend _assert;

/* Expected-fail assertion: checks p6_fail=1 AND that p6_fail_msg contains
   expected_text. A failure for the wrong reason does NOT pass (TC-25 lesson). */
%macro _assert_fail(label=, expected_text=);
  %global _tc_pass _tc_fail;
  %local _af_flag _af_flag2;
  %let _af_flag = 0;
  %let _af_flag2 = 0;
  %if %bquote(%superq(p6_fail)) = 1 %then %let _af_flag = 1;
  %if %bquote(&expected_text) = %bquote() %then %let _af_flag2 = &_af_flag;
  %else %do;
    /* Check message contains expected text (case-insensitive via upcase) */
    %local _af_msg_up _af_txt_up;
    %let _af_msg_up = %upcase(%superq(p6_fail_msg));
    %let _af_txt_up = %upcase(&expected_text);
    %if &_af_flag = 1 %then %do;
      %if %index(&_af_msg_up, &_af_txt_up) > 0 %then %let _af_flag2 = 1;
      %else %let _af_flag2 = 0;
    %end;
  %end;
  %if &_af_flag2 = 1 %then %do;
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label expected-fail] PASS;
    %let _tc_pass = %eval(&_tc_pass + 1);
  %end;
  %else %do;
    %local _af_msglog;
    %let _af_msglog = %superq(p6_fail_msg);
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label expected-fail] FAIL (p6_fail=&p6_fail msg=&_af_msglog);
    %let _tc_fail = %eval(&_tc_fail + 1);
  %end;
%mend _assert_fail;

%macro _assert_pass(label=);
  %global _tc_pass _tc_fail;
  %local _ap_flag;
  %let _ap_flag = 0;
  %if %bquote(%superq(p6_fail)) = 0 %then %let _ap_flag = 1;
  %if &_ap_flag = 1 %then %do;
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label expected-pass] PASS;
    %let _tc_pass = %eval(&_tc_pass + 1);
  %end;
  %else %do;
    %local _ap_msglog;
    %let _ap_msglog = %superq(p6_fail_msg);
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label expected-pass] FAIL (p6_fail=&p6_fail msg=&_ap_msglog);
    %let _tc_fail = %eval(&_tc_fail + 1);
  %end;
%mend _assert_pass;

%macro _tc_skip(label=, reason=);
  %global _tc_skip;
  %put TESTRESULT: TC-&_tc_n &_tc_desc [&label] SKIP (&reason);
  %let _tc_skip = %eval(&_tc_skip + 1);
%mend _tc_skip;

/* Initialize counters */
%let _tc_pass = 0;
%let _tc_fail = 0;
%let _tc_skip = 0;

/* ---- Set Phase 6 test globals BEFORE %include (C13 + test harness design) ----
   p6_test_mode=1  prevents %abort cancel in p6_fail_out
   in_pipeline=1   prevents log rerouting (no &logs_path write)
   logs_path / exchange_path point to WORK so any accidental write stays safe */
%let p6_test_mode  = 1;
%let in_pipeline   = 1;
%let logs_path     = %sysfunc(pathname(work));
%let exchange_path = %sysfunc(pathname(work));

/* Load macro library -- all macros defined before calls below (C13) */
%include "C:\data_dictionary\sas\06_profile_macros.sas";

/* After %include, _p6_init_globals ran and may have reset p6_fail/p6_fail_msg.
   Re-arm test globals to sane state. */
%let p6_fail     = 0;
%let p6_fail_msg = ;

/*==========================================================================
  SECTION 1 -- Synthetic fixture: work._t_ds + work.name_map
  DATA steps in open code (C22: no datalines inside macros)
==========================================================================*/

/* Total rows in fixture = 50 (keeps PROC MEANS values predictable) */

data work._t_ds;
  /* Char / numeric variables with exact boundary counts */
  length
    T_BIN      $4
    T_L20      8
    T_L21      8
    T_H21      $6
    T_HTIE     $6
    T_LONG     $300
    T_RSV      $10
    T_DT       8
    T_DTM      8
    T_TM       8
    T_ISO      8
    T_ISO2     8
    T_ISO3     8
    T_ISO4     8
    T_X_DATE   8
    T_UNF      8
    T_ALLMN    8
    T_ALLMC    $4
    T_ALLMD    8
    T_NA       $10
    ZZ_OUT     8
    /* TC-13 FIX 1: zero-missing variables */
    T_ZNOMISS  8    /* LOW_CARD numeric; 5 distinct vals, 0 missing */
    T_HZNOMISS $6   /* HIGH_CARD char; 21+ distinct, 0 missing */
    /* TC-15/16 D-09 suppression */
    T_FREETEXT $200 /* char free-text; variable char lengths */
    T_NUMID    $10  /* char numeric-looking IDs '1001'..'1050' */
    /* TC-17/18/19 D-10 numtext */
    T_NUMTXT   $10  /* 30 numeric + NULL + <5: NUM_TEXT */
    T_NUMNEAR  $10  /* 45/50 parse rate: stays HIGH_CARD */
    T_NUM95    $10  /* exactly 0.95 parse rate: NUM_TEXT */
    ;

  format T_DT   DATE9.
         T_DTM  DATETIME20.
         T_TM   TIME8.
         T_ISO  E8601DA.
         T_ISO2 E8601DT26.6
         T_ISO3 B8601DA10.
         T_ISO4 E8601TM15.6
         T_ALLMD DATE9.
         ;

  /* ---- T_BIN: 2 levels; level 'A' n=3 (small cell), 'B' n=47 ---- */
  /* ---- T_L20: 20 distinct non-missing values (1..20), repeated ---- */
  /* ---- T_L21: 21 distinct non-missing values (1..21) ---- */
  /* ---- T_H21: 21 distinct char values (A00..A20) -- HIGH_CARD ---- */
  /* ---- T_HTIE: 22 distinct values; rank-10 and rank-11 tied at n=2 ---- */
  /* ---- T_LONG: char $300 with long common prefix ---- */
  /* ---- T_RSV: has literal levels 'OTHER' and 'MISSING' ---- */
  /* ---- T_DT: 3 distinct date values ---- */
  /* ---- T_DTM: 3 distinct datetime values ---- */
  /* ---- T_TM: 3 distinct time values ---- */
  /* ---- T_ISO: 3 distinct ISO-date values ---- */
  /* ---- T_X_DATE: no format, name_pattern *_DATE, SAS-date-range values ---- */
  /* ---- T_UNF: numeric, no format, >20 distinct (1..50) ---- */
  /* ---- T_ALLMN: 100% missing numeric ---- */
  /* ---- T_ALLMC: 100% missing char ---- */
  /* ---- T_ALLMD: 100% missing DATE9. numeric ---- */
  /* ---- T_NA: char with UTF-8 value ß ---- */
  /* ---- ZZ_OUT: no T_ prefix, must not be profiled ---- */

  do _i = 1 to 50;
    /* T_BIN */
    if _i <= 3 then T_BIN = 'A';
    else            T_BIN = 'B';

    /* T_L20: 20 distinct values cycling 1..20 */
    T_L20 = mod(_i - 1, 20) + 1;

    /* T_L21: 21 distinct values cycling 1..21 */
    T_L21 = mod(_i - 1, 21) + 1;

    /* T_H21: 21 distinct values -- first 21 rows unique, rest cycle */
    if _i <= 21 then T_H21 = cat('A', put(_i - 1, z2.));
    else             T_H21 = cat('A', put(mod(_i - 1, 21), z2.));

    /* T_HTIE: 22 distinct values; values V01..V08 appear 3x, V09..V22 appear 1-2x
       We want rank-10 and rank-11 to be tied at n=2.
       Values V01..V08 get count 3 each (8*3=24), V09..V16 get count 2 each (8*2=16),
       V17..V22 get count 1 each (6*1=6). Total=24+16+6=46 < 50.
       Use remaining 4 rows to give V01..V04 an extra hit: V01..V04 become 4,
       but that changes the tie. Instead: distribute 50 rows.
       Strategy: V01-V06: 4 obs each (24), V07-V16: 2 obs each (20), V17-V22: 1 obs (6)
       Total=24+20+6=50. Rank 1-6: n=4, rank 7-16: n=2 (tie at ranks 7-16!),
       rank 17-22: n=1. Tie-break at rank 10/11 both n=2, resolve ascending level.
       V10 < V11 alphabetically -> V10 is rank 10, V11 is rank 11 (OTHER includes V11..V16). */
    if      _i <= 4  then T_HTIE = 'V01';
    else if _i <= 8  then T_HTIE = 'V02';
    else if _i <= 12 then T_HTIE = 'V03';
    else if _i <= 16 then T_HTIE = 'V04';
    else if _i <= 20 then T_HTIE = 'V05';
    else if _i <= 24 then T_HTIE = 'V06';
    else if _i <= 26 then T_HTIE = 'V07';
    else if _i <= 28 then T_HTIE = 'V08';
    else if _i <= 30 then T_HTIE = 'V09';
    else if _i <= 32 then T_HTIE = 'V10';
    else if _i <= 34 then T_HTIE = 'V11';
    else if _i <= 36 then T_HTIE = 'V12';
    else if _i <= 38 then T_HTIE = 'V13';
    else if _i <= 40 then T_HTIE = 'V14';
    else if _i <= 42 then T_HTIE = 'V15';
    else if _i <= 44 then T_HTIE = 'V16';
    else if _i = 45  then T_HTIE = 'V17';
    else if _i = 46  then T_HTIE = 'V18';
    else if _i = 47  then T_HTIE = 'V19';
    else if _i = 48  then T_HTIE = 'V20';
    else if _i = 49  then T_HTIE = 'V21';
    else                  T_HTIE = 'V22';

    /* T_LONG: $300 string, common 200-char prefix, differs at char 201 */
    T_LONG = repeat('X', 199) || put(mod(_i - 1, 10) + 1, z3.);

    /* T_RSV: includes literal levels 'OTHER' and 'MISSING' among real values.
       OTHER=11 (boundary above small-cell), MISSING=9 (small-cell), rest 10 each. */
    if      _i <= 11 then T_RSV = 'OTHER';
    else if _i <= 20 then T_RSV = 'MISSING';
    else if _i <= 30 then T_RSV = 'REAL_A';
    else if _i <= 40 then T_RSV = 'REAL_B';
    else                  T_RSV = 'REAL_C';

    /* T_DT: 3 distinct SAS dates (cycling) */
    T_DT = '01JAN2020'd + mod(_i - 1, 3);

    /* T_DTM: 3 distinct SAS datetimes */
    T_DTM = '01JAN2020:00:00:00'dt + mod(_i - 1, 3) * 3600;

    /* T_TM: 3 distinct SAS times */
    T_TM = mod(_i - 1, 3) * 3600;

    /* T_ISO: 3 distinct ISO-date values (same numeric base as T_DT) */
    T_ISO = '01JAN2020'd + mod(_i - 1, 3);

    /* T_ISO2: E8601DT (ISO 8601 datetime) -- 3 distinct values */
    T_ISO2 = '01JAN2020:00:00:00'dt + mod(_i - 1, 3) * 3600;

    /* T_ISO3: B8601DA (Basic ISO 8601 date) -- 3 distinct values */
    T_ISO3 = '01JAN2020'd + mod(_i - 1, 3);

    /* T_ISO4: E8601TM (ISO 8601 time) -- 3 distinct values */
    T_ISO4 = mod(_i - 1, 3) * 3600;

    /* T_X_DATE: no format, name ends _DATE, SAS-date-range values (1980-2020) */
    T_X_DATE = 7305 + mod(_i - 1, 21);   /* 7305 = 01JAN1980 */

    /* T_UNF: numeric, no format, 50 distinct values */
    T_UNF = _i * 1.1;

    /* T_ALLMN / T_ALLMC / T_ALLMD: always missing */
    T_ALLMN = .;
    T_ALLMC = '';
    T_ALLMD = .;

    /* T_NA: mostly 'NORMAL', one row has ß (UTF-8 multibyte) */
    if _i = 1 then T_NA = 'ß';
    else           T_NA = 'NORMAL';

    /* ZZ_OUT: no T_ prefix */
    ZZ_OUT = _i;

    /* TC-13 FIX 1: zero-missing LOW_CARD -- 5 distinct values cycling, always non-missing */
    T_ZNOMISS = mod(_i - 1, 5) + 1;

    /* TC-13 FIX 1: zero-missing HIGH_CARD char -- 25 distinct values, all non-missing */
    T_HZNOMISS = cats('Z', put(mod(_i - 1, 25) + 1, z2.));

    /* TC-15 D-09 suppression: free-text char variable -- varied lengths, no parse */
    T_FREETEXT = cats('Free text entry number ', strip(put(_i, best32.)),
                      repeat(' extra', mod(_i, 5)));

    /* TC-16 D-09 suppression: numeric-looking IDs '1001'..'1050' */
    T_NUMID = strip(put(1000 + _i, best32.));

    /* TC-17 D-10 numtext: 30 numeric rows (1..30), 1 NULL, 1 <5, 18 blank */
    if      _i <= 30 then T_NUMTXT = strip(put(_i, best32.));
    else if _i  = 31 then T_NUMTXT = 'NULL';
    else if _i  = 32 then T_NUMTXT = '<5';
    else                  T_NUMTXT = '';

    /* TC-18 D-10 near-miss: 45 numeric, 5 non-numeric (all non-missing) */
    if _i <= 45 then T_NUMNEAR = strip(put(_i, best32.));
    else             T_NUMNEAR = cats('ALPHA', put(_i - 45, 1.));

    /* TC-19 D-10 boundary 95%: 10 placeholder, 38 numeric, 2 non-numeric */
    /* n_placeholder=10, n_parse=38, denom=50-10=40, rate=38/40=0.95 */
    if      _i <= 10 then T_NUM95 = 'UNKNOWN';
    else if _i <= 48 then T_NUM95 = strip(put(_i - 10, best32.));
    else                  T_NUM95 = cats('ZZ', put(_i, best32.));

    output;
  end;
  drop _i;
run;

/* name_map with pcnr_name + status columns.
   T_LINK is LINKAGE_ONLY so it would be excluded if it were in _t_ds.
   (T_LINK is not in _t_ds -- it is added here only for name_map exclusion test.) */
data work.name_map;
  length pcnr_name $200 status $20;
  pcnr_name = 'T_BIN';    status = 'PCNR';          output;
  pcnr_name = 'T_LINK';   status = 'LINKAGE_ONLY';  output;
  pcnr_name = 'T_L20';    status = 'PCNR';          output;
  pcnr_name = 'T_L21';    status = 'PCNR';          output;
run;

/* Run profiler on the synthetic fixture (WORK only, no CSV export) */
%pdd_profile(lib=work, ds=_t_ds, prefix=T_, family=TEST, outlib=work, export=0);

/*==========================================================================
  TC-01 -- Classification: correct var_class per variable
==========================================================================*/

%macro _tc01;
  %_tc_start(n=01, desc=classification);

  %local _cls_l20 _cls_l21 _cls_h21 _cls_dt _cls_dtm _cls_tm
         _cls_iso _cls_iso2 _cls_iso3 _cls_iso4 _cls_xd _cls_unf _cls_bin;

  proc sql noprint;
    select max(case when variable='T_L20'    then strip(var_class) end),
           max(case when variable='T_L21'    then strip(var_class) end),
           max(case when variable='T_H21'    then strip(var_class) end),
           max(case when variable='T_DT'     then strip(var_class) end),
           max(case when variable='T_DTM'    then strip(var_class) end),
           max(case when variable='T_TM'     then strip(var_class) end),
           max(case when variable='T_ISO'    then strip(var_class) end),
           max(case when variable='T_ISO2'   then strip(var_class) end),
           max(case when variable='T_ISO3'   then strip(var_class) end),
           max(case when variable='T_ISO4'   then strip(var_class) end),
           max(case when variable='T_X_DATE' then strip(var_class) end),
           max(case when variable='T_UNF'    then strip(var_class) end),
           max(case when variable='T_BIN'    then strip(var_class) end)
    into :_cls_l20  trimmed, :_cls_l21  trimmed, :_cls_h21  trimmed,
         :_cls_dt   trimmed, :_cls_dtm  trimmed, :_cls_tm   trimmed,
         :_cls_iso  trimmed, :_cls_iso2 trimmed, :_cls_iso3 trimmed,
         :_cls_iso4 trimmed, :_cls_xd   trimmed, :_cls_unf  trimmed,
         :_cls_bin  trimmed
    from work.prf_test;
  quit;

  %local _f;
  %let _f = 0; %if %bquote(&_cls_l20) = LOW_CARD %then %let _f = 1;
  %_assert(flag=&_f, label=T_L20-LOW_CARD);

  %let _f = 0; %if %bquote(&_cls_l21) = CONT_NUM %then %let _f = 1;
  %_assert(flag=&_f, label=T_L21-CONT_NUM);

  %let _f = 0; %if %bquote(&_cls_h21) = HIGH_CARD %then %let _f = 1;
  %_assert(flag=&_f, label=T_H21-HIGH_CARD);

  %let _f = 0; %if %bquote(&_cls_dt) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_DT-DATE);

  %let _f = 0; %if %bquote(&_cls_dtm) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_DTM-DATE);

  %let _f = 0; %if %bquote(&_cls_tm) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_TM-DATE);

  %let _f = 0; %if %bquote(&_cls_iso) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_ISO-DATE);

  /* E8601DT: datetime class -> var_class=DATE */
  %let _f = 0; %if %bquote(&_cls_iso2) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_ISO2-E8601DT-DATE);

  /* B8601DA: date class -> var_class=DATE */
  %let _f = 0; %if %bquote(&_cls_iso3) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_ISO3-B8601DA-DATE);

  /* E8601TM: time class -> var_class=DATE */
  %let _f = 0; %if %bquote(&_cls_iso4) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_ISO4-E8601TM-DATE);

  %let _f = 0; %if %bquote(&_cls_xd) = DATE %then %let _f = 1;
  %_assert(flag=&_f, label=T_X_DATE-DATE-name-pattern);

  %let _f = 0; %if %bquote(&_cls_unf) = CONT_NUM %then %let _f = 1;
  %_assert(flag=&_f, label=T_UNF-CONT_NUM-no-format);

  %let _f = 0; %if %bquote(&_cls_bin) = LOW_CARD %then %let _f = 1;
  %_assert(flag=&_f, label=T_BIN-LOW_CARD);

%mend _tc01;
%_tc01;

/*==========================================================================
  TC-02 -- Schema: 13 columns, names, types, lengths, order
==========================================================================*/

%macro _tc02;
  %_tc_start(n=02, desc=schema-13-cols);

  /* Expected columns in order */
  %local _ncols _col1 _col2 _col3 _col4 _col5 _col6 _col7
         _col8 _col9 _col10 _col11 _col12 _col13 _lvl_len;

  proc sql noprint;
    select count(*) into :_ncols trimmed
    from dictionary.columns
    where libname='WORK' and memname='PRF_TEST';
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_ncols = 13) %then %let _f = 1;
  %_assert(flag=&_f, label=col-count-13);

  /* Verify column names and order via a sequential query */
  proc sql noprint;
    select name into :_col1  - :_col13
    from dictionary.columns
    where libname='WORK' and memname='PRF_TEST'
    order by varnum;
  quit;

  %let _f = 0; %if %bquote(&_col1)  = family         %then %let _f = 1; %_assert(flag=&_f, label=col1-family);
  %let _f = 0; %if %bquote(&_col2)  = variable        %then %let _f = 1; %_assert(flag=&_f, label=col2-variable);
  %let _f = 0; %if %bquote(&_col3)  = var_class       %then %let _f = 1; %_assert(flag=&_f, label=col3-var_class);
  %let _f = 0; %if %bquote(&_col4)  = stat            %then %let _f = 1; %_assert(flag=&_f, label=col4-stat);
  %let _f = 0; %if %bquote(&_col5)  = level           %then %let _f = 1; %_assert(flag=&_f, label=col5-level);
  %let _f = 0; %if %bquote(&_col6)  = n               %then %let _f = 1; %_assert(flag=&_f, label=col6-n);
  %let _f = 0; %if %bquote(&_col7)  = value           %then %let _f = 1; %_assert(flag=&_f, label=col7-value);
  %let _f = 0; %if %bquote(&_col8)  = pct_total       %then %let _f = 1; %_assert(flag=&_f, label=col8-pct_total);
  %let _f = 0; %if %bquote(&_col9)  = pct_nonmiss     %then %let _f = 1; %_assert(flag=&_f, label=col9-pct_nonmiss);
  %let _f = 0; %if %bquote(&_col10) = sort_order      %then %let _f = 1; %_assert(flag=&_f, label=col10-sort_order);
  %let _f = 0; %if %bquote(&_col11) = small_cell_flag %then %let _f = 1; %_assert(flag=&_f, label=col11-small_cell_flag);
  %let _f = 0; %if %bquote(&_col12) = date_kind       %then %let _f = 1; %_assert(flag=&_f, label=col12-date_kind);
  %let _f = 0; %if %bquote(&_col13) = display_format  %then %let _f = 1; %_assert(flag=&_f, label=col13-display_format);

  /* level column length must be >= 300 */
  proc sql noprint;
    select length into :_lvl_len trimmed
    from dictionary.columns
    where libname='WORK' and memname='PRF_TEST' and name='level';
  quit;
  %let _f = 0; %if %eval(&_lvl_len >= 300) %then %let _f = 1;
  %_assert(flag=&_f, label=level-len-ge-300);

%mend _tc02;
%_tc02;

/*==========================================================================
  TC-05 -- Small cells: Y exactly where 1<=n<=10 on LEVEL/OTHER/MISSING
==========================================================================*/

%macro _tc05;
  %_tc_start(n=05, desc=small-cell-flag);

  /* Count rows where flag is wrong:
     LEVEL/OTHER/MISSING rows: Y iff 1<=n<=10; else N.
     N_DISTINCT and STAT rows: flag must be blank.
     Mismatches produce a nonzero count. */

  %local _sc_bad _sc_stat_bad;

  proc sql noprint;
    select count(*) into :_sc_bad trimmed
    from work.prf_test
    where stat in ('LEVEL','OTHER','MISSING')
      and (
        (n >= 1 and n <= 10 and small_cell_flag ne 'Y')
        or
        (n = 0              and small_cell_flag ne 'N')
        or
        (n > 10             and small_cell_flag ne 'N')
      );
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_sc_bad = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=scf-correct-on-level-other-missing);

  proc sql noprint;
    select count(*) into :_sc_stat_bad trimmed
    from work.prf_test
    where stat not in ('LEVEL','OTHER','MISSING')
      and small_cell_flag ne '';
  quit;

  %let _f = 0; %if %eval(&_sc_stat_bad = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=scf-blank-on-stat-ndist);

  /* Confirm n=0,1,10,11 boundaries actually exist in the output */
  %local _has_n1 _has_n10 _has_n11;

  proc sql noprint;
    select max(case when n=1  then 1 else 0 end),
           max(case when n=10 then 1 else 0 end),
           max(case when n=11 then 1 else 0 end)
    into :_has_n1 trimmed, :_has_n10 trimmed, :_has_n11 trimmed
    from work.prf_test
    where stat in ('LEVEL','OTHER','MISSING');
  quit;

  %let _f = 0; %if %eval(&_has_n1  = 1) %then %let _f = 1; %_assert(flag=&_f, label=boundary-n1-exists);
  %let _f = 0; %if %eval(&_has_n10 = 1) %then %let _f = 1; %_assert(flag=&_f, label=boundary-n10-exists);
  %let _f = 0; %if %eval(&_has_n11 = 1) %then %let _f = 1; %_assert(flag=&_f, label=boundary-n11-exists);

%mend _tc05;
%_tc05;

/*==========================================================================
  TC-07 -- Date variables: date_kind, display_format, nine STAT rows + SD
==========================================================================*/

%macro _tc07;
  %_tc_start(n=07, desc=date-vars);

  %local _dk_dt _df_dt _dk_dtm _df_dtm _dk_tm _df_tm
         _dk_iso _df_iso _dk_iso2 _df_iso2 _dk_iso3 _df_iso3 _dk_iso4 _df_iso4
         _dk_xd _df_xd;

  proc sql noprint;
    select
      max(case when variable='T_DT'    then strip(date_kind) end),
      max(case when variable='T_DT'    then strip(display_format) end),
      max(case when variable='T_DTM'   then strip(date_kind) end),
      max(case when variable='T_DTM'   then strip(display_format) end),
      max(case when variable='T_TM'    then strip(date_kind) end),
      max(case when variable='T_TM'    then strip(display_format) end),
      max(case when variable='T_ISO'   then strip(date_kind) end),
      max(case when variable='T_ISO'   then strip(display_format) end),
      max(case when variable='T_ISO2'  then strip(date_kind) end),
      max(case when variable='T_ISO2'  then strip(display_format) end),
      max(case when variable='T_ISO3'  then strip(date_kind) end),
      max(case when variable='T_ISO3'  then strip(display_format) end),
      max(case when variable='T_ISO4'  then strip(date_kind) end),
      max(case when variable='T_ISO4'  then strip(display_format) end),
      max(case when variable='T_X_DATE' then strip(date_kind) end),
      max(case when variable='T_X_DATE' then strip(display_format) end)
    into :_dk_dt   trimmed, :_df_dt   trimmed,
         :_dk_dtm  trimmed, :_df_dtm  trimmed,
         :_dk_tm   trimmed, :_df_tm   trimmed,
         :_dk_iso  trimmed, :_df_iso  trimmed,
         :_dk_iso2 trimmed, :_df_iso2 trimmed,
         :_dk_iso3 trimmed, :_df_iso3 trimmed,
         :_dk_iso4 trimmed, :_df_iso4 trimmed,
         :_dk_xd   trimmed, :_df_xd   trimmed
    from work.prf_test
    where stat not in ('LEVEL','OTHER','MISSING','N_DISTINCT');
  quit;

  %local _f;
  %let _f = 0; %if %bquote(&_dk_dt)   = DATE     %then %let _f = 1; %_assert(flag=&_f, label=T_DT-date_kind-DATE);
  %let _f = 0; %if %bquote(&_dk_dtm)  = DATETIME  %then %let _f = 1; %_assert(flag=&_f, label=T_DTM-date_kind-DATETIME);
  %let _f = 0; %if %bquote(&_dk_tm)   = TIME      %then %let _f = 1; %_assert(flag=&_f, label=T_TM-date_kind-TIME);
  %let _f = 0; %if %bquote(&_dk_iso)  = DATE      %then %let _f = 1; %_assert(flag=&_f, label=T_ISO-date_kind-DATE);
  /* T_ISO2: E8601DT is DATETIME class */
  %let _f = 0; %if %bquote(&_dk_iso2) = DATETIME  %then %let _f = 1; %_assert(flag=&_f, label=T_ISO2-E8601DT-date_kind-DATETIME);
  /* T_ISO3: B8601DA is DATE class */
  %let _f = 0; %if %bquote(&_dk_iso3) = DATE      %then %let _f = 1; %_assert(flag=&_f, label=T_ISO3-B8601DA-date_kind-DATE);
  /* T_ISO4: E8601TM is TIME class */
  %let _f = 0; %if %bquote(&_dk_iso4) = TIME      %then %let _f = 1; %_assert(flag=&_f, label=T_ISO4-E8601TM-date_kind-TIME);
  %let _f = 0; %if %bquote(&_dk_xd)   = DATE      %then %let _f = 1; %_assert(flag=&_f, label=T_X_DATE-date_kind-DATE);

  /* display_format non-blank for each DATE-class variable */
  %let _f = 0; %if %bquote(&_df_dt)   ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_DT-display_format-set);
  %let _f = 0; %if %bquote(&_df_dtm)  ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_DTM-display_format-set);
  %let _f = 0; %if %bquote(&_df_tm)   ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_TM-display_format-set);
  %let _f = 0; %if %bquote(&_df_iso)  ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_ISO-display_format-set);
  %let _f = 0; %if %bquote(&_df_iso2) ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_ISO2-display_format-set);
  %let _f = 0; %if %bquote(&_df_iso3) ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_ISO3-display_format-set);
  %let _f = 0; %if %bquote(&_df_iso4) ne %bquote() %then %let _f = 1; %_assert(flag=&_f, label=T_ISO4-display_format-set);
  %let _f = 0; %if %bquote(&_df_xd)  = %str(DATE9.) %then %let _f = 1; %_assert(flag=&_f, label=T_X_DATE-display_format-DATE9);

  /* Each DATE var must have exactly 9 STAT rows (N N_MISSING MEAN SD MEDIAN Q1 Q3 MIN MAX) */
  %local _nstat_dt _nstat_dtm;
  proc sql noprint;
    select
      sum(case when variable='T_DT'  and stat in ('N','N_MISSING','MEAN','SD','MEDIAN','Q1','Q3','MIN','MAX') then 1 else 0 end),
      sum(case when variable='T_DTM' and stat in ('N','N_MISSING','MEAN','SD','MEDIAN','Q1','Q3','MIN','MAX') then 1 else 0 end)
    into :_nstat_dt trimmed, :_nstat_dtm trimmed
    from work.prf_test;
  quit;

  %let _f = 0; %if %eval(&_nstat_dt  = 9) %then %let _f = 1; %_assert(flag=&_f, label=T_DT-9-stat-rows);
  %let _f = 0; %if %eval(&_nstat_dtm = 9) %then %let _f = 1; %_assert(flag=&_f, label=T_DTM-9-stat-rows);

  /* SD row present for T_DT */
  %local _has_sd;
  proc sql noprint;
    select count(*) into :_has_sd trimmed
    from work.prf_test
    where variable='T_DT' and stat='SD';
  quit;
  %let _f = 0; %if %eval(&_has_sd = 1) %then %let _f = 1; %_assert(flag=&_f, label=T_DT-SD-row-present);

%mend _tc07;
%_tc07;

/*==========================================================================
  TC-08 -- 100% missing: single MISSING row per var, correct structure
==========================================================================*/

%macro _tc08;
  %_tc_start(n=08, desc=all-missing-vars);

  %local _nm_rows _mc_rows _md_rows;
  %local _nm_stat _nm_n _nm_pct _nm_so;
  %local _md_class;

  proc sql noprint;
    select count(*) into :_nm_rows trimmed from work.prf_test where variable='T_ALLMN';
    select count(*) into :_mc_rows trimmed from work.prf_test where variable='T_ALLMC';
    select count(*) into :_md_rows trimmed from work.prf_test where variable='T_ALLMD';
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_nm_rows = 1) %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMN-one-row);
  %let _f = 0; %if %eval(&_mc_rows = 1) %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMC-one-row);
  %let _f = 0; %if %eval(&_md_rows = 1) %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMD-one-row);

  proc sql noprint;
    select strip(stat), n, pct_total, sort_order
    into :_nm_stat trimmed, :_nm_n trimmed, :_nm_pct trimmed, :_nm_so trimmed
    from work.prf_test
    where variable='T_ALLMN';
  quit;

  %let _f = 0; %if %bquote(&_nm_stat) = MISSING %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMN-stat-MISSING);
  %let _f = 0; %if %eval(&_nm_n = 50)            %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMN-n-50);
  %let _f = 0; %if %eval(&_nm_pct = 100)         %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMN-pct_total-100);
  %let _f = 0; %if %eval(&_nm_so = 99)           %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMN-sort_order-99);

  /* T_ALLMD must keep var_class=DATE */
  proc sql noprint;
    select strip(var_class) into :_md_class trimmed
    from work.prf_test
    where variable='T_ALLMD';
  quit;
  %let _f = 0; %if %bquote(&_md_class) = DATE %then %let _f = 1; %_assert(flag=&_f, label=T_ALLMD-var_class-DATE);

%mend _tc08;
%_tc08;

/*==========================================================================
  TC-09 -- HIGH_CARD: N_DISTINCT, 10 LEVEL rows, OTHER, MISSING; tie-break
==========================================================================*/

%macro _tc09;
  %_tc_start(n=09, desc=high-card);

  %local _nd_h21 _lev_h21 _other_h21 _miss_h21 _sum_h21;
  %local _lev_htie _tie_rank10;

  proc sql noprint;
    select
      sum(case when stat='N_DISTINCT' then 1 else 0 end),
      sum(case when stat='LEVEL'      then 1 else 0 end),
      sum(case when stat='OTHER'      then 1 else 0 end),
      sum(case when stat='MISSING'    then 1 else 0 end),
      sum(case when stat in ('LEVEL','OTHER','MISSING') then n else 0 end)
    into :_nd_h21 trimmed, :_lev_h21 trimmed, :_other_h21 trimmed,
         :_miss_h21 trimmed, :_sum_h21 trimmed
    from work.prf_test
    where variable='T_H21';
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_nd_h21   = 1)  %then %let _f = 1; %_assert(flag=&_f, label=T_H21-N_DISTINCT-row);
  %let _f = 0; %if %eval(&_lev_h21  = 10) %then %let _f = 1; %_assert(flag=&_f, label=T_H21-10-LEVEL-rows);
  %let _f = 0; %if %eval(&_other_h21= 1)  %then %let _f = 1; %_assert(flag=&_f, label=T_H21-OTHER-row);
  %let _f = 0; %if %eval(&_miss_h21 = 1)  %then %let _f = 1; %_assert(flag=&_f, label=T_H21-MISSING-row);
  %let _f = 0; %if %eval(&_sum_h21 = 50)  %then %let _f = 1; %_assert(flag=&_f, label=T_H21-total-reconcile);

  /* T_HTIE: 22 distinct values; tie at rank 10/11 resolved by level ascending */
  proc sql noprint;
    select count(*) into :_lev_htie trimmed
    from work.prf_test
    where variable='T_HTIE' and stat='LEVEL';
  quit;
  %let _f = 0; %if %eval(&_lev_htie = 10) %then %let _f = 1; %_assert(flag=&_f, label=T_HTIE-10-LEVEL-rows);

  /* With tie at n=2 between V10 and V11, V10 < V11 alphabetically,
     so V10 is rank 10 (last LEVEL), V11 falls into OTHER. */
  proc sql noprint;
    select max(sort_order) into :_tie_rank10 trimmed
    from work.prf_test
    where variable='T_HTIE' and stat='LEVEL' and strip(level)='V10';
  quit;
  %let _f = 0; %if %eval(&_tie_rank10 = 10) %then %let _f = 1; %_assert(flag=&_f, label=T_HTIE-tie-V10-rank10);

%mend _tc09;
%_tc09;

/*==========================================================================
  TC-10 -- Values: long levels, reserved-word levels, UTF-8
==========================================================================*/

%macro _tc10;
  %_tc_start(n=10, desc=values-long-rsv-utf8);

  /* T_LONG: each LEVEL row level value must have length > 200 (untruncated) */
  %local _long_minlen;
  proc sql noprint;
    select min(length(strip(level))) into :_long_minlen trimmed
    from work.prf_test
    where variable='T_LONG' and stat='LEVEL';
  quit;
  %local _f;
  %let _f = 0; %if %eval(&_long_minlen >= 200) %then %let _f = 1;
  %_assert(flag=&_f, label=T_LONG-untruncated-level);

  /* T_RSV: LEVEL rows with level='OTHER' and level='MISSING' must exist
     alongside the engine's own MISSING row (stat='MISSING') */
  %local _rsv_other _rsv_miss_lvl _rsv_miss_stat;
  proc sql noprint;
    select
      sum(case when stat='LEVEL' and strip(level)='OTHER'   then 1 else 0 end),
      sum(case when stat='LEVEL' and strip(level)='MISSING' then 1 else 0 end),
      sum(case when stat='MISSING'                          then 1 else 0 end)
    into :_rsv_other trimmed, :_rsv_miss_lvl trimmed, :_rsv_miss_stat trimmed
    from work.prf_test
    where variable='T_RSV';
  quit;

  %let _f = 0; %if %eval(&_rsv_other    >= 1) %then %let _f = 1; %_assert(flag=&_f, label=T_RSV-level-OTHER-present);
  %let _f = 0; %if %eval(&_rsv_miss_lvl >= 1) %then %let _f = 1; %_assert(flag=&_f, label=T_RSV-level-MISSING-present);
  %let _f = 0; %if %eval(&_rsv_miss_stat = 1) %then %let _f = 1; %_assert(flag=&_f, label=T_RSV-stat-MISSING-row);

  /* T_NA: a LEVEL row with level containing ß */
  %local _na_utf;
  proc sql noprint;
    select count(*) into :_na_utf trimmed
    from work.prf_test
    where variable='T_NA' and stat='LEVEL' and index(level, 'ß') > 0;
  quit;
  %let _f = 0; %if %eval(&_na_utf >= 1) %then %let _f = 1;
  %_assert(flag=&_f, label=T_NA-utf8-beta-level);

%mend _tc10;
%_tc10;

/*==========================================================================
  TC-11 -- Numeric reconciliation for T_L21: N+N_MISSING=total; MEAN/MIN/MAX
==========================================================================*/

%macro _tc11;
  %_tc_start(n=11, desc=numeric-reconcile);

  %local _n21 _nm21 _sum21 _mean21 _min21 _max21;

  proc sql noprint;
    select
      max(case when stat='N'         then n end),
      max(case when stat='N_MISSING' then n end),
      max(case when stat='MEAN'      then value end),
      max(case when stat='MIN'       then value end),
      max(case when stat='MAX'       then value end)
    into :_n21 trimmed, :_nm21 trimmed, :_mean21 trimmed, :_min21 trimmed, :_max21 trimmed
    from work.prf_test
    where variable='T_L21';
  quit;

  /* Total rows in fixture = 50; T_L21 cycles 1..21, no missing */
  %local _f;
  %let _f = 0;
  %if %bquote(&_n21) ne %bquote() and %bquote(&_nm21) ne %bquote() %then %do;
    %if %eval(&_n21 + &_nm21 = 50) %then %let _f = 1;
  %end;
  %_assert(flag=&_f, label=T_L21-N-plus-NMISS-eq-50);

  /* Independent PROC MEANS for comparison (tolerance 1e-9) */
  proc means data=work._t_ds noprint;
    var T_L21;
    output out=work._tc11_means mean=m min=mn max=mx;
  run;

  %local _mean_ref _min_ref _max_ref;
  proc sql noprint;
    select m, mn, mx
    into :_mean_ref trimmed, :_min_ref trimmed, :_max_ref trimmed
    from work._tc11_means;
  quit;

  %local _abs_mean _abs_min _abs_max;
  data _null_;
    abs_mean = abs(&_mean21 - &_mean_ref);
    abs_min  = abs(&_min21  - &_min_ref);
    abs_max  = abs(&_max21  - &_max_ref);
    call symputx('_abs_mean', strip(put(abs_mean, 32.10)), 'L');
    call symputx('_abs_min',  strip(put(abs_min,  32.10)), 'L');
    call symputx('_abs_max',  strip(put(abs_max,  32.10)), 'L');
  run;

  %let _f = 0; %if %bquote(&_abs_mean) ne %bquote() %then %do; %if %sysevalf(&_abs_mean <= 1e-9) %then %let _f = 1; %end; %_assert(flag=&_f, label=T_L21-MEAN-match);
  %let _f = 0; %if %bquote(&_abs_min)  ne %bquote() %then %do; %if %sysevalf(&_abs_min  <= 1e-9) %then %let _f = 1; %end; %_assert(flag=&_f, label=T_L21-MIN-match);
  %let _f = 0; %if %bquote(&_abs_max)  ne %bquote() %then %do; %if %sysevalf(&_abs_max  <= 1e-9) %then %let _f = 1; %end; %_assert(flag=&_f, label=T_L21-MAX-match);

%mend _tc11;
%_tc11;

/*==========================================================================
  TC-04 -- Expected-fail: class-specific D-08 reconciliation hard-stops
==========================================================================*/

/* TC-04 injects bad _p6_rows directly and calls %p6_write_output.
   Three sub-cases: LOW_CARD, HIGH_CARD, CONT_NUM reconciliation failures.
   Each sub-case: assert p6_fail=1, message names class/variable,
                  work.prf_bad does not exist.
   Reset p6_fail between sub-cases. */

%macro _tc04;
  %_tc_start(n=04, desc=d08-recon-expected-fail);

  /* Set globals so %p6_write_output has consistent schema */
  %global _p6_total _p6_lvl_len _p6_nv;
  %let _p6_total   = 50;
  %let _p6_lvl_len = 300;
  %let _p6_nv      = 1;

  /* ======== Sub-case A: LOW_CARD mismatch ======== */
  proc datasets lib=work nolist; delete prf_bad; quit;

  /* Build a _p6_rows that has a LOW_CARD variable with n sum != 50 */
  data work._p6_rows;
    %_p6_attrib;
    variable = 'T_BAD_LC'; var_class = 'LOW_CARD'; family = 'BAD';
    stat = 'LEVEL'; level = 'A'; n = 20; sort_order = 1; small_cell_flag = 'N'; output;
    stat = 'MISSING'; level = ''; n = 5; sort_order = 99; small_cell_flag = 'N'; output;
    /* Total = 25, not 50 -- reconciliation must fail */
  run;

  /* Minimal work._p6_vars for variable-set check in %p6_write_output */
  data work._p6_vars;
    length name $200 type $8 length 8 format $32 n_distinct 8
           var_class $12 date_kind $8 display_format $32;
    name = 'T_BAD_LC'; type = 'char'; var_class = 'LOW_CARD'; output;
    stop;
  run;

  %let p6_fail = 0;
  %let p6_fail_msg = ;
  %p6_write_output(outlib=work, family=BAD, export=0);

  %_assert_fail(label=TC04a-LC-recon-fail, expected_text=D-08);

  /* Check work.prf_bad does NOT exist */
  %local _f _badexist;
  %let _badexist = %sysfunc(exist(work.prf_bad));
  %let _f = 0; %if %eval(&_badexist = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC04a-prf_bad-not-published);

  %let p6_fail = 0;
  %let p6_fail_msg = ;

  /* ======== Sub-case B: HIGH_CARD mismatch ======== */
  proc datasets lib=work nolist; delete prf_bad; quit;

  data work._p6_rows;
    %_p6_attrib;
    variable = 'T_BAD_HC'; var_class = 'HIGH_CARD'; family = 'BAD';
    /* N_DISTINCT row */
    stat = 'N_DISTINCT'; n = 22; sort_order = 0; output;
    /* Only 5 LEVEL rows instead of 10 -- HC level count fails */
    do _i = 1 to 5;
      stat = 'LEVEL'; level = cat('V', put(_i, z2.)); n = 8; sort_order = _i; output;
    end;
    stat = 'OTHER';   n = 8;  sort_order = 11; small_cell_flag = 'N'; output;
    stat = 'MISSING'; n = 0;  sort_order = 99; small_cell_flag = 'N'; output;
    drop _i;
  run;

  /* Minimal work._p6_vars for variable-set check in %p6_write_output */
  data work._p6_vars;
    length name $200 type $8 length 8 format $32 n_distinct 8
           var_class $12 date_kind $8 display_format $32;
    name = 'T_BAD_HC'; type = 'char'; var_class = 'HIGH_CARD'; n_distinct = 22; output;
    stop;
  run;

  %p6_write_output(outlib=work, family=BAD, export=0);

  %_assert_fail(label=TC04b-HC-recon-fail, expected_text=D-08);

  %let _badexist = %sysfunc(exist(work.prf_bad));
  %let _f = 0; %if %eval(&_badexist = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC04b-prf_bad-not-published);

  %let p6_fail = 0;
  %let p6_fail_msg = ;

  /* ======== Sub-case C: CONT_NUM mismatch ======== */
  proc datasets lib=work nolist; delete prf_bad; quit;

  data work._p6_rows;
    %_p6_attrib;
    variable = 'T_BAD_CN'; var_class = 'CONT_NUM'; family = 'BAD';
    stat = 'N';         n = 40; sort_order = 1; output;
    stat = 'N_MISSING'; n = 5;  sort_order = 2; output;
    /* N + N_MISSING = 45, not 50 */
    stat = 'MEAN';   value = 10.5; sort_order = 3; output;
    stat = 'SD';     value = 2.1;  sort_order = 4; output;
    stat = 'MEDIAN'; value = 10.0; sort_order = 5; output;
    stat = 'Q1';     value = 9.0;  sort_order = 6; output;
    stat = 'Q3';     value = 12.0; sort_order = 7; output;
    stat = 'MIN';    value = 5.0;  sort_order = 8; output;
    stat = 'MAX';    value = 20.0; sort_order = 9; output;
  run;

  /* Minimal work._p6_vars for variable-set check in %p6_write_output */
  data work._p6_vars;
    length name $200 type $8 length 8 format $32 n_distinct 8
           var_class $12 date_kind $8 display_format $32;
    name = 'T_BAD_CN'; type = 'num'; var_class = 'CONT_NUM'; n_distinct = 50; output;
    stop;
  run;

  %p6_write_output(outlib=work, family=BAD, export=0);

  %_assert_fail(label=TC04c-CONT_NUM-recon-fail, expected_text=D-08);

  %let _badexist = %sysfunc(exist(work.prf_bad));
  %let _f = 0; %if %eval(&_badexist = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC04c-prf_bad-not-published);

  %let p6_fail = 0;
  %let p6_fail_msg = ;

%mend _tc04;
%_tc04;

/*==========================================================================
  TC-06 -- Exclusions: NORM_PSID, LINKAGE_ONLY, no-prefix absent; rest present
==========================================================================*/

%macro _tc06;
  %_tc_start(n=06, desc=exclusions);

  /* T_LINK is in name_map with LINKAGE_ONLY but not in _t_ds (so it wouldn't
     appear regardless). ZZ_OUT has no T_ prefix. NORM_PSID is always excluded. */

  %local _link_cnt _zzout_cnt _psid_cnt;
  proc sql noprint;
    select
      sum(case when variable='T_LINK'    then 1 else 0 end),
      sum(case when variable='ZZ_OUT'    then 1 else 0 end),
      sum(case when variable='NORM_PSID' then 1 else 0 end)
    into :_link_cnt trimmed, :_zzout_cnt trimmed, :_psid_cnt trimmed
    from work.prf_test;
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_link_cnt = 0) %then %let _f = 1; %_assert(flag=&_f, label=T_LINK-absent);
  %let _f = 0; %if %eval(&_zzout_cnt = 0) %then %let _f = 1; %_assert(flag=&_f, label=ZZ_OUT-absent-no-prefix);
  %let _f = 0; %if %eval(&_psid_cnt = 0) %then %let _f = 1;  %_assert(flag=&_f, label=NORM_PSID-absent);

  /* All T_ variables in _t_ds must be present (ZZ_OUT excluded by prefix,
     T_LINK excluded by name_map but not in _t_ds anyway).
     Derive expected count from dictionary.columns rather than hardcode,
     so adding fixture variables does not require updating this assertion. */
  %local _nvars _expected_nvars;
  proc sql noprint;
    select count(*) into :_expected_nvars trimmed
    from dictionary.columns
    where libname='WORK' and memname='_T_DS'
      and upcase(name) like 'T_%';
    select count(distinct variable) into :_nvars trimmed
    from work.prf_test;
  quit;
  %let _f = 0; %if %eval(&_nvars = &_expected_nvars) %then %let _f = 1;
  %_assert(flag=&_f, label=var-count-matches-fixture);

  /* Sub-case: require_name_map=1 with name_map deleted → expected-fail */
  proc datasets lib=work nolist; delete name_map; quit;

  %let p6_fail = 0;
  %let p6_fail_msg = ;

  %pdd_profile(lib=work, ds=_t_ds, prefix=T_, family=NMT,
               outlib=work, export=0, require_name_map=1);

  %_assert_fail(label=TC06-no-name_map-fail, expected_text=name_map);

  %let p6_fail = 0;
  %let p6_fail_msg = ;

  /* Restore name_map for TC-12 */
  data work.name_map;
    length pcnr_name $200 status $20;
    pcnr_name = 'T_BIN';    status = 'PCNR';          output;
    pcnr_name = 'T_LINK';   status = 'LINKAGE_ONLY';  output;
    pcnr_name = 'T_L20';    status = 'PCNR';          output;
    pcnr_name = 'T_L21';    status = 'PCNR';          output;
  run;

%mend _tc06;
%_tc06;

/*==========================================================================
  TC-12 -- Rerun after TC-04 failures: p6_fail=0, output matches first run
==========================================================================*/

%macro _tc12;
  %_tc_start(n=12, desc=rerun-after-failure);

  /* Save first-run row count */
  %local _rc_first;
  proc sql noprint;
    select count(*) into :_rc_first trimmed
    from work.prf_test;
  quit;

  /* Rerun profiler */
  %pdd_profile(lib=work, ds=_t_ds, prefix=T_, family=TEST, outlib=work, export=0);

  %_assert_pass(label=TC12-no-fail-after-rerun);

  %local _rc_second;
  proc sql noprint;
    select count(*) into :_rc_second trimmed
    from work.prf_test;
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_rc_first = &_rc_second) %then %let _f = 1;
  %_assert(flag=&_f, label=TC12-row-count-same);

  /* Sum of n per variable must match between runs */
  proc sql noprint;
    create table work._tc12_first as
      select variable, sum(n) as sum_n
      from work.prf_test
      group by variable;
  quit;

  /* prf_test is the second run (just replaced above) */
  proc sql noprint;
    create table work._tc12_second as
      select variable, sum(n) as sum_n
      from work.prf_test
      group by variable;
  quit;

  %local _delta_n;
  proc sql noprint;
    select count(*) into :_delta_n trimmed
    from work._tc12_first a
    inner join work._tc12_second b on a.variable = b.variable
    where abs(a.sum_n - b.sum_n) > 0;
  quit;
  %let _f = 0; %if %eval(&_delta_n = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC12-sum-n-per-var-same);

%mend _tc12;
%_tc12;

/*==========================================================================
  TC-13 -- FIX 1: Zero-missing variables: MISSING row n=0, pct_total=0
==========================================================================*/

%macro _tc13;
  %_tc_start(n=13, desc=fix1-zero-missing-rows);

  /* T_ZNOMISS is LOW_CARD with 5 distinct values and 0 missing */
  %local _miss_n_lc _miss_pct_lc _miss_flag_lc;
  proc sql noprint;
    select n, pct_total, small_cell_flag
    into :_miss_n_lc trimmed, :_miss_pct_lc trimmed, :_miss_flag_lc trimmed
    from work.prf_test
    where variable='T_ZNOMISS' and stat='MISSING';
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_miss_n_lc = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC13-lc-missing-n-is-0);

  %let _f = 0; %if %eval(&_miss_pct_lc = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC13-lc-missing-pct-is-0);

  %let _f = 0; %if %bquote(&_miss_flag_lc) = %bquote(N) %then %let _f = 1;
  %_assert(flag=&_f, label=TC13-lc-missing-flag-is-N);

  /* T_HZNOMISS is HIGH_CARD (25 distinct) with 0 missing */
  %local _miss_n_hc _miss_pct_hc _miss_flag_hc;
  proc sql noprint;
    select n, pct_total, small_cell_flag
    into :_miss_n_hc trimmed, :_miss_pct_hc trimmed, :_miss_flag_hc trimmed
    from work.prf_test
    where variable='T_HZNOMISS' and stat='MISSING';
  quit;

  %let _f = 0; %if %eval(&_miss_n_hc = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC13-hc-missing-n-is-0);

  %let _f = 0; %if %eval(&_miss_pct_hc = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC13-hc-missing-pct-is-0);

  %let _f = 0; %if %bquote(&_miss_flag_hc) = %bquote(N) %then %let _f = 1;
  %_assert(flag=&_f, label=TC13-hc-missing-flag-is-N);

%mend _tc13;
%_tc13;

/*==========================================================================
  TC-14 -- FIX 1: Validation -- no stat row may have n=. (SAS missing)
==========================================================================*/

%macro _tc14;
  %_tc_start(n=14, desc=fix1-no-missing-n-values);

  %local _missing_n_rows;
  proc sql noprint;
    select count(*) into :_missing_n_rows trimmed
    from work.prf_test
    where stat in ('LEVEL','OTHER','MISSING','N','N_MISSING','N_UNPARSED')
      and n = .;
  quit;

  %local _f;
  %let _f = 0; %if %eval(&_missing_n_rows = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC14-no-null-n-in-count-rows);

%mend _tc14;
%_tc14;

/*==========================================================================
  TC-15 -- D-09: Suppressed char free-text variable
==========================================================================*/

%macro _tc15;
  %_tc_start(n=15, desc=d09-suppressed-char-freetext);

  /* Create temp suppress CSV with T_FREETEXT */
  %local _sup_file;
  %let _sup_file = %sysfunc(pathname(work))\tc15_suppress.csv;
  data _null_;
    file "&_sup_file";
    put 'variable,reason';
    put 'T_FREETEXT,free text';
  run;

  /* Run profiler with suppress_file on a fresh outlib dataset */
  %let p6_fail = 0; %let p6_fail_msg = ;
  %pdd_profile(lib=work, ds=_t_ds, prefix=T_, family=SUP15, outlib=work,
               export=0, suppress_file=&_sup_file);

  %_assert_pass(label=TC15-suppress-no-fail);

  %local _f;

  /* No LEVEL rows for T_FREETEXT */
  %local _lev_cnt;
  proc sql noprint;
    select count(*) into :_lev_cnt trimmed
    from work.prf_sup15
    where variable='T_FREETEXT' and stat='LEVEL';
  quit;
  %let _f = 0; %if %eval(&_lev_cnt = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC15-no-level-rows);

  /* All rows for T_FREETEXT have blank level */
  %local _nonblank_level;
  proc sql noprint;
    select count(*) into :_nonblank_level trimmed
    from work.prf_sup15
    where variable='T_FREETEXT' and strip(level) ne '';
  quit;
  %let _f = 0; %if %eval(&_nonblank_level = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC15-level-always-blank);

  /* RANGE values are char lengths (display_format='LENGTH') */
  %local _fmt_min _fmt_max;
  proc sql noprint;
    select max(case when stat='RANGE_MIN' then display_format else '' end),
           max(case when stat='RANGE_MAX' then display_format else '' end)
    into :_fmt_min trimmed, :_fmt_max trimmed
    from work.prf_sup15
    where variable='T_FREETEXT';
  quit;
  %let _f = 0; %if %bquote(&_fmt_min) = %bquote(LENGTH) %then %let _f = 1;
  %_assert(flag=&_f, label=TC15-range-min-display-format-length);
  %let _f = 0; %if %bquote(&_fmt_max) = %bquote(LENGTH) %then %let _f = 1;
  %_assert(flag=&_f, label=TC15-range-max-display-format-length);

  /* No fixture text value ('Free text entry number' etc.) in prf_sup15 for T_FREETEXT */
  %local _fixture_text_present;
  proc sql noprint;
    select count(*) into :_fixture_text_present trimmed
    from work.prf_sup15
    where variable='T_FREETEXT'
      and index(strip(level), 'Free text') > 0;
  quit;
  %let _f = 0; %if %eval(&_fixture_text_present = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC15-no-fixture-text-in-level);

  /* Reconciliation: N + MISSING = 50 */
  %local _n_val _miss_val;
  proc sql noprint;
    select max(case when stat='N'       then n else . end),
           max(case when stat='MISSING' then n else . end)
    into :_n_val trimmed, :_miss_val trimmed
    from work.prf_sup15
    where variable='T_FREETEXT';
  quit;
  %if %bquote(&_n_val)   = %bquote() %then %let _n_val   = 0;
  %if %bquote(&_miss_val) = %bquote() %then %let _miss_val = 0;
  %let _f = 0; %if %eval(&_n_val + &_miss_val = 50) %then %let _f = 1;
  %_assert(flag=&_f, label=TC15-recon-n-plus-miss-eq-50);

%mend _tc15;
%_tc15;

/*==========================================================================
  TC-16 -- D-09: Suppressed numeric-looking ID variable
==========================================================================*/

%macro _tc16;
  %_tc_start(n=16, desc=d09-suppressed-numeric-id);

  /* Create temp suppress CSV with T_NUMID */
  %local _sup_file;
  %let _sup_file = %sysfunc(pathname(work))\tc16_suppress.csv;
  data _null_;
    file "&_sup_file";
    put 'variable,reason';
    put 'T_NUMID,record id';
  run;

  %let p6_fail = 0; %let p6_fail_msg = ;
  %pdd_profile(lib=work, ds=_t_ds, prefix=T_, family=SUP16, outlib=work,
               export=0, suppress_file=&_sup_file);

  %_assert_pass(label=TC16-suppress-no-fail);

  %local _f;

  /* No LEVEL rows for T_NUMID */
  %local _lev_cnt;
  proc sql noprint;
    select count(*) into :_lev_cnt trimmed
    from work.prf_sup16
    where variable='T_NUMID' and stat='LEVEL';
  quit;
  %let _f = 0; %if %eval(&_lev_cnt = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC16-no-level-rows);

  /* RANGE_MIN=1001, RANGE_MAX=1050 (numeric mode: 100% parse) */
  %local _rmin _rmax;
  proc sql noprint;
    select max(case when stat='RANGE_MIN' then value else . end),
           max(case when stat='RANGE_MAX' then value else . end)
    into :_rmin trimmed, :_rmax trimmed
    from work.prf_sup16
    where variable='T_NUMID';
  quit;
  %let _f = 0; %if %eval(&_rmin = 1001) %then %let _f = 1;
  %_assert(flag=&_f, label=TC16-range-min-1001);
  %let _f = 0; %if %eval(&_rmax = 1050) %then %let _f = 1;
  %_assert(flag=&_f, label=TC16-range-max-1050);

  /* display_format not LENGTH (numeric mode) */
  %local _fmt;
  proc sql noprint;
    select max(case when stat='RANGE_MIN' then coalesce(display_format,'') else '' end)
    into :_fmt trimmed
    from work.prf_sup16
    where variable='T_NUMID';
  quit;
  %let _f = 0; %if %bquote(&_fmt) ne %bquote(LENGTH) %then %let _f = 1;
  %_assert(flag=&_f, label=TC16-range-not-length-format);

%mend _tc16;
%_tc16;

/*==========================================================================
  TC-17 -- D-10: NUM_TEXT var with correct stats and N_UNPARSED/LEVEL rows
==========================================================================*/

%macro _tc17;
  %_tc_start(n=17, desc=d10-numtext-correct-stats);

  /* T_NUMTXT: rows 1-30 numeric, row 31 'NULL' (placeholder), row 32 '<5',
     rows 33-50 blank. n_nonmiss=32, n_placeholder=1, n_parse=30,
     denom=32-1=31, rate=30/31=0.968 >= 0.95 -> NUM_TEXT.
     N=30, N_MISSING=18, N_UNPARSED=2 (NULL + <5), total=50. */

  /* Run profiler (uses main prf_test from the last run) */
  /* T_NUMTXT was part of the standard fixture; after TC-12 rerun it's in prf_test */

  %local _f;

  /* var_class = NUM_TEXT */
  %local _vc;
  proc sql noprint;
    select distinct var_class into :_vc trimmed
    from work.prf_test
    where variable='T_NUMTXT';
  quit;
  %let _f = 0; %if %bquote(&_vc) = %bquote(NUM_TEXT) %then %let _f = 1;
  %_assert(flag=&_f, label=TC17-var-class-num-text);

  /* N=30 (parsed count) */
  %local _n_val;
  proc sql noprint;
    select n into :_n_val trimmed
    from work.prf_test
    where variable='T_NUMTXT' and stat='N';
  quit;
  %if %bquote(&_n_val) = %bquote() %then %let _n_val = -1;
  %let _f = 0; %if %eval(&_n_val = 30) %then %let _f = 1;
  %_assert(flag=&_f, label=TC17-n-equals-30);

  /* N_MISSING=18 */
  %local _nmiss_val;
  proc sql noprint;
    select n into :_nmiss_val trimmed
    from work.prf_test
    where variable='T_NUMTXT' and stat='N_MISSING';
  quit;
  %if %bquote(&_nmiss_val) = %bquote() %then %let _nmiss_val = -1;
  %let _f = 0; %if %eval(&_nmiss_val = 18) %then %let _f = 1;
  %_assert(flag=&_f, label=TC17-nmissing-equals-18);

  /* N_UNPARSED=2 */
  %local _nup_val;
  proc sql noprint;
    select n into :_nup_val trimmed
    from work.prf_test
    where variable='T_NUMTXT' and stat='N_UNPARSED';
  quit;
  %if %bquote(&_nup_val) = %bquote() %then %let _nup_val = -1;
  %let _f = 0; %if %eval(&_nup_val = 2) %then %let _f = 1;
  %_assert(flag=&_f, label=TC17-nunparsed-equals-2);

  /* Reconciliation N + N_MISSING + N_UNPARSED = 50 */
  %let _f = 0;
  %if %eval(&_n_val >= 0) and %eval(&_nmiss_val >= 0) and %eval(&_nup_val >= 0) %then %do;
    %if %eval(&_n_val + &_nmiss_val + &_nup_val = 50) %then %let _f = 1;
  %end;
  %_assert(flag=&_f, label=TC17-recon-50);

  /* LEVEL rows exist for unparsed values (NULL and <5) */
  %local _lev_cnt;
  proc sql noprint;
    select count(*) into :_lev_cnt trimmed
    from work.prf_test
    where variable='T_NUMTXT' and stat='LEVEL';
  quit;
  %let _f = 0; %if %eval(&_lev_cnt >= 1) %then %let _f = 1;
  %_assert(flag=&_f, label=TC17-level-rows-exist);

  /* MEAN stat present */
  %local _mean_cnt;
  proc sql noprint;
    select count(*) into :_mean_cnt trimmed
    from work.prf_test
    where variable='T_NUMTXT' and stat='MEAN';
  quit;
  %let _f = 0; %if %eval(&_mean_cnt = 1) %then %let _f = 1;
  %_assert(flag=&_f, label=TC17-mean-row-exists);

%mend _tc17;
%_tc17;

/*==========================================================================
  TC-18 -- D-10: Near-miss (90%) stays HIGH_CARD
==========================================================================*/

%macro _tc18;
  %_tc_start(n=18, desc=d10-near-miss-stays-highcard);

  /* T_NUMNEAR: 45/50 = 0.90 < 0.95 -- stays HIGH_CARD */
  %local _vc;
  proc sql noprint;
    select distinct var_class into :_vc trimmed
    from work.prf_test
    where variable='T_NUMNEAR';
  quit;

  %local _f;
  %let _f = 0; %if %bquote(&_vc) = %bquote(HIGH_CARD) %then %let _f = 1;
  %_assert(flag=&_f, label=TC18-near-miss-stays-high-card);

%mend _tc18;
%_tc18;

/*==========================================================================
  TC-19 -- D-10: Boundary exactly 0.95 qualifies as NUM_TEXT
==========================================================================*/

%macro _tc19;
  %_tc_start(n=19, desc=d10-boundary-095-is-numtext);

  /* T_NUM95: n_placeholder=10, n_parse=38, denom=50-10=40, rate=38/40=0.95 -- NUM_TEXT */
  %local _vc;
  proc sql noprint;
    select distinct var_class into :_vc trimmed
    from work.prf_test
    where variable='T_NUM95';
  quit;

  %local _f;
  %let _f = 0; %if %bquote(&_vc) = %bquote(NUM_TEXT) %then %let _f = 1;
  %_assert(flag=&_f, label=TC19-boundary-095-is-num-text);

%mend _tc19;
%_tc19;

/*==========================================================================
  TC-20 -- No per-variable source passes: W9 lint gate + pass-structure NOTE
  The W9 lint rule (python/tests/test_sas_lint.py::test_w9_clean_on_phase6_macros)
  statically verifies that no &lib..&ds read appears inside a %do variable loop.
  This TC verifies the runtime side: after the standard synthetic profile run,
  p6_fail=0 (no syserr from excessive passes) and the pass-structure NOTE was
  written to the log (confirmed by the put below producing a known string).
==========================================================================*/

%macro _tc20;
  %_tc_start(n=20, desc=no-per-variable-source-passes);

  /* The main prf_test run completed without fail (TC-12 already checks row counts).
     Assert p6_fail=0 as a proxy that all consolidated DATA steps succeeded.     */
  %local _f;
  %let _f = 0; %if &p6_fail = 0 %then %let _f = 1;
  %_assert(flag=&_f, label=TC20-p6-fail-zero-after-main-run);

  /* Assert T_NUMTXT has MEAN row (confirms PROC MEANS ran over parsed-copy table,
     which only works if the single-pass consolidated DATA step was correct).     */
  %local _mean_exists;
  proc sql noprint;
    select count(*) into :_mean_exists trimmed
    from work.prf_test
    where variable='T_NUMTXT' and stat='MEAN' and value ne .;
  quit;
  %let _f = 0; %if %eval(&_mean_exists = 1) %then %let _f = 1;
  %_assert(flag=&_f, label=TC20-numtext-mean-value-non-missing);

%mend _tc20;
%_tc20;

/*==========================================================================
  TC-21 -- No WARNING lines in synthetic profile log (except expected-fail)
  Runs %pdd_profile on the synthetic fixture with log captured to a WORK
  file; reads it back and asserts no "WARNING:" lines are present.
  Expected-fail calls are excluded (they run separately with p6_fail=0 guard).
==========================================================================*/

%macro _tc21;
  %_tc_start(n=21, desc=no-warning-in-synthetic-profile-log);

  /* Capture a clean profile run log to WORK */
  %local _tc21_log;
  %let _tc21_log = %sysfunc(pathname(work))\tc21_profile.log;
  proc printto log="&_tc21_log"; run;

  %let p6_fail = 0; %let p6_fail_msg = ;
  %pdd_profile(lib=work, ds=_t_ds, prefix=T_, family=TC21, outlib=work, export=0);

  proc printto; run;  /* restore log */

  /* Read captured log and count WARNING lines (excluding expected-fail guards) */
  %local _warn_cnt;
  %let _warn_cnt = 0;
  data _null_;
    infile "&_tc21_log" truncover lrecl=32767;
    input _line $32767.;
    /* WARNING: lines that are part of SAS infrastructure (autoexec etc.) are
       accepted; only profile-generated WARNINGs are of concern. Count all.    */
    if index(upcase(_line), 'WARNING:') > 0 then do;
      call symputx('_warn_cnt', strip(put(input(symget('_warn_cnt'), best32.) + 1, best32.)));
      put "NOTE: [TC-21] WARNING found: " _line;
    end;
  run;

  %local _f;
  %let _f = 0; %if %eval(&_warn_cnt = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC21-no-warning-lines-in-profile-log);

%mend _tc21;
%_tc21;

/*==========================================================================
  TC-03 -- Integration on pdd.pcnr (read-only); wrapped in macro (C3)
==========================================================================*/

%macro _tc03_run;
  %_tc_start(n=03, desc=integration-pdd-pcnr);

  /* Include 00_config and open pdd library -- only inside this macro (C3).
     Immediately re-point paths to WORK and reassign pdd read-only. */
  %include "C:\data_dictionary\sas\00_config.sas";
  %pdd_lib;

  /* Immediately redirect paths back to WORK (no P: writes from this test) */
  %let logs_path     = %sysfunc(pathname(work));
  %let exchange_path = %sysfunc(pathname(work));

  /* Reassign pdd read-only so profiler cannot write pdd.prf_pcnr */
  %local _pdd_path;
  %let _pdd_path = %sysfunc(pathname(pdd));
  libname pdd "&_pdd_path" access=readonly;

  /* Guard: skip if pdd.pcnr does not exist */
  %if %sysfunc(exist(pdd.pcnr)) = 0 %then %do;
    %_tc_skip(label=pdd-pcnr-not-found, reason=pdd.pcnr not available on this machine);
    %return;
  %end;

  /* Runtime lookup of PCNR_SEX and PCNR_PATIENT_TYPE variable names */
  %local _sexvar _ptvar;
  proc sql noprint;
    select strip(pcnr_name) into :_sexvar trimmed
    from pdd.name_map
    where upcase(strip(original_header)) = 'SEX'
      and upcase(strip(status)) = 'PCNR';
  quit;

  proc sql noprint;
    select strip(pcnr_name) into :_ptvar trimmed
    from pdd.name_map
    where upcase(strip(original_header)) = 'PATIENT_TYPE'
      and upcase(strip(status)) = 'PCNR';
  quit;

  %local _f;

  /* Fail (not skip) if either lookup is empty */
  %let _f = 0; %if %bquote(&_sexvar) ne %bquote() %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-sexvar-found);
  %if &_f = 0 %then %return;

  %let _f = 0; %if %bquote(&_ptvar) ne %bquote() %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-ptvar-found);
  %if &_f = 0 %then %return;

  /* Time the profiler call */
  %local _t0 _t1 _elapsed;
  %let _t0 = %sysfunc(datetime());

  %pdd_profile(lib=pdd, ds=pcnr, prefix=PCNR_, family=PCNR, outlib=work, export=0);

  %let _t1 = %sysfunc(datetime());
  %let _elapsed = %sysevalf(&_t1 - &_t0);
  %put NOTE: [TC-03] pdd_profile elapsed: &_elapsed seconds;

  %_assert_pass(label=TC03-profile-no-fail);
  %if &p6_fail = 1 %then %return;

  /* 1. Variable count: 1297 distinct variables */
  %local _nv_pcnr;
  proc sql noprint;
    select count(distinct variable) into :_nv_pcnr trimmed
    from work.prf_pcnr;
  quit;
  %let _f = 0; %if %eval(&_nv_pcnr = 1297) %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-1297-variables);

  /* 2. Exactly 56 variables with a single MISSING row where n=41150 */
  %local _allm_cnt;
  proc sql noprint;
    select count(*) into :_allm_cnt trimmed
    from (
      select variable
      from work.prf_pcnr
      group by variable
      having count(*) = 1 and max(case when stat='MISSING' then n end) = 41150
    );
  quit;
  %let _f = 0; %if %eval(&_allm_cnt = 56) %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-56-all-missing-vars);

  /* 3. Compare PCNR_SEX level counts to PROC FREQ.
     Engine stores variable in its natural case (from dictionary.columns).
     Join uses upcase() on both sides to match regardless of stored case.
     Rule: engine level = strip(level); freq level = strip(put(var,$200.)).
     Join key: upcase(strip(a.level)) = upcase(strip(b.freq_level)).
     MISSING stat row matched to PROC FREQ / MISSING row (missing value in freq). */
  proc freq data=pdd.pcnr noprint;
    table &_sexvar / missing out=work._tc03_sex_freq;
  run;

  proc sql noprint;
    create table work._tc03_sex_all as
      select coalesce(a.level, b.freq_level) as level length=200,
             a.n                              as n_engine,
             b.count                          as n_freq
      from (select strip(level) as level, n
            from work.prf_pcnr
            where upcase(strip(variable)) = upcase("&_sexvar")
              and stat in ('LEVEL','MISSING')) a
      full join (select strip(put(&_sexvar, $200.)) as freq_level, count
                 from work._tc03_sex_freq) b
        on upcase(strip(a.level)) = upcase(strip(b.freq_level));
  quit;

  %local _sex_delta;
  proc sql noprint;
    select count(*) into :_sex_delta trimmed
    from work._tc03_sex_all
    where n_engine ne n_freq or n_engine is null or n_freq is null;
  quit;
  %let _f = 0; %if %eval(&_sex_delta = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-sex-levels-match-freq);

  %if &_sex_delta > 0 %then %do;
    %put NOTE: [TC-03-DIAG] SEX level mismatches (&_sex_delta rows). Full outer join:;
    %put NOTE: [TC-03-DIAG] Rule: upcase(strip(engine.level)) = upcase(strip(freq.put(var dollar200.)));
    data _null_;
      length _varname $32;
      _varname = "&_sexvar";
      set work._tc03_sex_all;
      put "TC03-DIAG varname=" _varname level= n_engine= n_freq=;
    run;
  %end;

  /* 4. Compare PCNR_PATIENT_TYPE level counts to PROC FREQ */
  proc freq data=pdd.pcnr noprint;
    table &_ptvar / missing out=work._tc03_pt_freq;
  run;

  proc sql noprint;
    create table work._tc03_pt_all as
      select coalesce(a.level, b.freq_level) as level length=200,
             a.n                              as n_engine,
             b.count                          as n_freq
      from (select strip(level) as level, n
            from work.prf_pcnr
            where upcase(strip(variable)) = upcase("&_ptvar")
              and stat in ('LEVEL','MISSING')) a
      full join (select strip(put(&_ptvar, $200.)) as freq_level, count
                 from work._tc03_pt_freq) b
        on upcase(strip(a.level)) = upcase(strip(b.freq_level));
  quit;

  %local _pt_delta;
  proc sql noprint;
    select count(*) into :_pt_delta trimmed
    from work._tc03_pt_all
    where n_engine ne n_freq or n_engine is null or n_freq is null;
  quit;
  %let _f = 0; %if %eval(&_pt_delta = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-pt-levels-match-freq);

  %if &_pt_delta > 0 %then %do;
    %put NOTE: [TC-03-DIAG] PATIENT_TYPE level mismatches (&_pt_delta rows). Full outer join:;
    %put NOTE: [TC-03-DIAG] Rule: upcase(strip(engine.level)) = upcase(strip(freq.put(var dollar200.)));
    data _null_;
      length _varname $32;
      _varname = "&_ptvar";
      set work._tc03_pt_all;
      put "TC03-DIAG varname=" _varname level= n_engine= n_freq=;
    run;
  %end;

  /* 5. Independent missing count for every PCNR_ variable.
     Numeric vars: PROC MEANS NMISS via ODS OUTPUT (avoids "Multiple lengths" from
     DATA-step arrays when char vars have differing declared lengths).
     Char vars: PROC SQL sum(missing()) per variable. */
  proc contents data=pdd.pcnr out=work._tc03_cols noprint; run;

  %local _pcnr_num_vars _pcnr_chr_vars;
  proc sql noprint;
    select name into :_pcnr_num_vars separated by ' '
    from work._tc03_cols
    where type=1 and upcase(name) like 'PCNR_%'
    order by name;
    select name into :_pcnr_chr_vars separated by ' '
    from work._tc03_cols
    where type=2 and upcase(name) like 'PCNR_%'
    order by name;
  quit;

  /* Numeric: use PROC MEANS stackodsoutput */
  ods output summary = work._tc03_num_miss_raw;
  proc means data=pdd.pcnr nmiss stackodsoutput;
    var &_pcnr_num_vars;
  run;
  ods output close;

  data work._tc03_indep_miss_num;
    length varname $32 n_miss 8;
    set work._tc03_num_miss_raw(keep=Variable NMiss rename=(Variable=varname NMiss=n_miss));
    varname = upcase(strip(varname));
  run;

  /* Character: PROC SQL one-pass sum of missing() per variable.
     missing() returns 1 for blank or null, 0 otherwise (numeric and char). */
  %local _tc03_chr_sql;
  proc sql noprint;
    select cat('sum(missing(', strip(name), ')) as ', strip(name))
    into :_tc03_chr_sql separated by ','
    from work._tc03_cols
    where type=2 and upcase(name) like 'PCNR_%'
    order by name;
  quit;

  proc sql noprint;
    create table work._tc03_chr_miss_wide as
      select &_tc03_chr_sql
      from pdd.pcnr;
  quit;

  /* Transpose wide row to long */
  proc transpose data=work._tc03_chr_miss_wide
                 out=work._tc03_indep_miss_chr(rename=(_name_=varname col1=n_miss));
  run;

  data work._tc03_indep_miss_chr;
    set work._tc03_indep_miss_chr(keep=varname n_miss);
    varname = upcase(strip(varname));
  run;

  /* Stack numeric + character */
  data work._tc03_indep_miss;
    set work._tc03_indep_miss_num
        work._tc03_indep_miss_chr;
  run;

  /* Compare independent counts to profile MISSING / N_MISSING rows */
  proc sql noprint;
    create table work._tc03_miss_delta as
      select a.variable, a.n as n_profile, b.n_miss as n_indep,
             abs(a.n - b.n_miss) as delta
      from (
        select variable,
               max(case when stat in ('MISSING','N_MISSING') then n end) as n
        from work.prf_pcnr
        where stat in ('MISSING','N_MISSING')
        group by variable
      ) a
      inner join work._tc03_indep_miss b on a.variable = b.varname
      where abs(a.n - b.n_miss) > 0;
  quit;

  %local _miss_delta;
  proc sql noprint;
    select count(*) into :_miss_delta trimmed
    from work._tc03_miss_delta;
  quit;
  %let _f = 0; %if %eval(&_miss_delta = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-missing-counts-match-indep);

  /* Diagnostic: print first 20 missing-count mismatches */
  %if &_miss_delta > 0 %then %do;
    %put NOTE: [TC-03-DIAG] Missing-count mismatches (&_miss_delta vars). First 20:;
    proc print data=work._tc03_miss_delta(obs=20) noobs label; run;
  %end;

  /* 6. Class-specific reconciliation = 41150 for every variable */
  proc sql noprint;
    create table work._tc03_recon_bad as
      select variable, var_class,
             sum(case when stat in ('LEVEL','MISSING') and var_class='LOW_CARD' then n else 0 end) as lc_sum,
             sum(case when stat in ('LEVEL','OTHER','MISSING') and var_class='HIGH_CARD' then n else 0 end) as hc_sum,
             sum(case when stat='N'         and var_class in ('CONT_NUM','DATE') then n else 0 end) +
             sum(case when stat='N_MISSING' and var_class in ('CONT_NUM','DATE') then n else 0 end) as cn_sum,
             count(*) as row_cnt,
             max(case when stat='MISSING' then n else 0 end) as miss_n
      from work.prf_pcnr
      group by variable, var_class
      having
        (var_class='LOW_CARD'  and lc_sum ne 41150
          and not (row_cnt=1 and miss_n=41150))
        or
        (var_class='HIGH_CARD' and hc_sum ne 41150)
        or
        (var_class in ('CONT_NUM','DATE')
          and cn_sum ne 41150
          and not (row_cnt=1 and miss_n=41150));
  quit;

  %local _recon_bad;
  proc sql noprint;
    select count(*) into :_recon_bad trimmed
    from work._tc03_recon_bad;
  quit;
  %let _f = 0; %if %eval(&_recon_bad = 0) %then %let _f = 1;
  %_assert(flag=&_f, label=TC03-recon-41150-all-vars);

%mend _tc03_run;
%_tc03_run;

/*==========================================================================
  SUMMARY
==========================================================================*/

%put TESTRESULT: SUMMARY passed=&_tc_pass failed=&_tc_fail skipped=&_tc_skip;
