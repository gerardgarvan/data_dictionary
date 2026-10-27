/*==========================================================================
  Program : 06_profile_macros.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 6 -- %pdd_profile distribution engine macro library.
            Section 0 defines all macros; subsequent sections call them.

  Macros (Plan 01):
    %_p6_init_globals   -- declare and reset Phase 6 control globals
    %p6_fail_out        -- hard stop with ERROR (test-mode: sets p6_fail)
    %_p6_ok             -- section guard (obs=0 / syserr > 4 / p6_fail=1)
    %p6_assert_rowcount -- exact row count assertion
    %p6_route_log       -- redirect log when running standalone
    %p6_restore_log     -- restore log after standalone run
    %p6_preflight       -- dataset/name_map existence + row-count guard
    %p6_classify_vars   -- build work._p6_vars with four-tier var_class

  PCM compliance: C1 C2 C3 C9 C11 C13 C14 C23 C24 C26
  Notes:
    - All Phase 6 utility macros use p6_* / _p6_* namespace.
    - Do NOT redefine fail_out, assert_rowcount, route_log, restore_log
      from Phase 5.  Loading this file in the same session as Phase 5 is
      safe.
    - C26: no literal "pdd." inside any macro body -- always use &lib param.
    - Caller must set &sas_path, &logs_path before calling these macros
      (typically via 00_config.sas + %pdd_lib).
    - For test harness usage: set p6_test_mode=1 before any call.
==========================================================================*/

/* ============================================================
   SECTION 0 -- ALL macro definitions
   All macros defined here before any call (PCM C13).
   ============================================================ */

/* Declare and initialise all Phase 6 control globals.
   Called immediately after definition so every &p6_fail guard is safe.
   Does NOT overwrite values already set by the caller (test harness or
   smoke test may pre-set p6_test_mode=1 before %include). */
%macro _p6_init_globals;
  %global p6_fail p6_fail_msg p6_test_mode _p6_total;
  /* Always reset error state at the start of an orchestrator run */
  %let p6_fail     = 0;
  %let p6_fail_msg = ;
  /* Set mode flag only when the caller has not already provided a value */
  %if %bquote(&p6_test_mode) = %bquote() %then %let p6_test_mode = 0;
%mend _p6_init_globals;
%_p6_init_globals;

/* Hard stop with loud ERROR.
   If p6_test_mode=1: set p6_fail/p6_fail_msg and %return instead of aborting.
   NOTE: %return only exits %p6_fail_out itself -- callers MUST check
   %if &p6_fail=1 %then %return; after every call that can fail. */
%macro p6_fail_out(msg=);
  %put ERROR: [06_profile] &msg;
  %if &p6_test_mode = 1 %then %do;
    %let p6_fail = 1;
    %let p6_fail_msg = %superq(msg);
    %return;
  %end;
  %abort cancel;
%mend p6_fail_out;

/* Fail-fast at start of each section.
   Triggers on: p6_fail=1, obs=0 (syntax-check mode), or syserr > 4. */
%macro _p6_ok(section=);
  %if &p6_fail = 1 %then %do;
    %p6_fail_out(msg=%str(p6_fail set before Section &section -- aborting));
    %return;
  %end;
  %if %sysfunc(getoption(obs)) = 0 %then %do;
    %p6_fail_out(msg=%str(SAS in obs=0/syntax-check mode entering Section &section -- prior section had an error));
    %return;
  %end;
  %if &syserr > 4 %then %do;
    %p6_fail_out(msg=%str(syserr=&syserr entering Section &section -- prior section had an error));
    %return;
  %end;
%mend _p6_ok;

/* Assert exact row count; %p6_fail_out if wrong.
   Parameters: ds= dataset, expected= count, label= description */
%macro p6_assert_rowcount(ds=, expected=, label=);
  %local _p6_arc;
  proc sql noprint;
    select count(*) into :_p6_arc trimmed
    from &ds;
  quit;
  %if &_p6_arc ne &expected %then %do;
    %p6_fail_out(msg=%str(&label row count=&_p6_arc expected=&expected));
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] p6_assert_rowcount OK: &label rows=&_p6_arc;
%mend p6_assert_rowcount;

/* Redirect log to 06_profile_run.log when running standalone (in_pipeline=0).
   When in_pipeline is not set or equals 1, log routing is skipped. */
%macro p6_route_log;
  %if %symexist(in_pipeline) %then %do;
    %if &in_pipeline = 0 %then %do;
      proc printto log="&logs_path.\06_profile_run.log" new;
      run;
    %end;
  %end;
%mend p6_route_log;

/* Restore log after standalone run. */
%macro p6_restore_log;
  %if %symexist(in_pipeline) %then %do;
    %if &in_pipeline = 0 %then %do;
      proc printto;
      run;
    %end;
  %end;
%mend p6_restore_log;

/* ============================================================
   %p6_preflight
   Verify dataset exists, has rows, and (when require_name_map=1)
   that &lib..name_map exists with the required columns.
   DEFINE ONLY -- called from orchestrator after %include.
   ============================================================ */
%macro p6_preflight(lib=, ds=, require_name_map=1);

  /* 1. Dataset must exist */
  %if %sysfunc(exist(&lib..&ds)) = 0 %then %do;
    %p6_fail_out(msg=%str(Dataset &lib..&ds does not exist));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;

  /* 2. Row count must be > 0 */
  %global _p6_total;
  %let _p6_total = ;
  proc sql noprint;
    select count(*) into :_p6_total trimmed
    from &lib..&ds;
  quit;
  %if %bquote(&_p6_total) = %bquote() or &_p6_total = 0 %then %do;
    %p6_fail_out(msg=%str(&lib..&ds has 0 rows -- nothing to profile));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] &ds has &_p6_total rows;

  /* 3. Verify name_map existence and required columns */
  %if &require_name_map = 1 %then %do;

    %if %sysfunc(exist(&lib..name_map)) = 0 %then %do;
      %p6_fail_out(msg=%str(&lib..name_map does not exist -- required for LINKAGE_ONLY exclusion (D-05)));
      %return;
    %end;
    %if &p6_fail = 1 %then %return;

    /* Verify columns: pcnr_name and status must exist in &lib..name_map */
    %local _p6_col_pcnr_name _p6_col_status;
    proc sql noprint;
      select count(*) into :_p6_col_pcnr_name trimmed
      from dictionary.columns
      where libname = upcase("&lib")
        and memname = upcase('name_map')
        and upcase(name) = 'PCNR_NAME';
    quit;
    %if &_p6_col_pcnr_name = 0 %then %do;
      %p6_fail_out(msg=%str(&lib..name_map is missing required column PCNR_NAME));
      %return;
    %end;
    %if &p6_fail = 1 %then %return;

    proc sql noprint;
      select count(*) into :_p6_col_status trimmed
      from dictionary.columns
      where libname = upcase("&lib")
        and memname = upcase('name_map')
        and upcase(name) = 'STATUS';
    quit;
    %if &_p6_col_status = 0 %then %do;
      %p6_fail_out(msg=%str(&lib..name_map is missing required column STATUS));
      %return;
    %end;
    %if &p6_fail = 1 %then %return;

    %put NOTE: [06_profile] name_map schema check passed (pcnr_name + status present);

  %end; /* require_name_map=1 */

%mend p6_preflight;

/* ============================================================
   %p6_classify_vars
   Builds work._p6_vars: one row per profiled variable with columns:
     name, type, length, format, n_distinct, var_class,
     date_kind, display_format
   Steps:
     1. Build exclusion list (NORM_PSID + LINKAGE_ONLY from name_map)
     2. Query DICTIONARY.COLUMNS for variables matching prefix
     3. Batched PROC FREQ NLEVELS for distinct non-missing counts
     4. Assign var_class (DATE first, then LOW_CARD/CONT_NUM/HIGH_CARD)
     5. Set _p6_nv global to row count of work._p6_vars
   Parameters:
     lib=             SAS libref of target dataset
     ds=              Dataset name (no libref)
     prefix=          Variable name prefix to profile (e.g. PCNR_)
     family=          Family label (e.g. PCNR) -- used in generated file name
     require_name_map= 1 (default) require &lib..name_map for D-05 exclusion
   ============================================================ */
%macro p6_classify_vars(lib=, ds=, prefix=, family=, require_name_map=1);

  /* ---- Step 1: Build exclusion list ---- */

  /* Always start with an empty exclusion table */
  proc sql noprint;
    create table work._p6_excl
      (excl_name char(200));
    insert into work._p6_excl values('NORM_PSID');
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 1 excl init);
  %if &p6_fail = 1 %then %return;

  /* Add LINKAGE_ONLY variables from name_map (D-05) */
  %if &require_name_map = 1 %then %do;
    %if %sysfunc(exist(&lib..name_map)) %then %do;
      proc sql noprint;
        insert into work._p6_excl
          select upcase(strip(pcnr_name))
          from &lib..name_map
          where upcase(strip(status)) = 'LINKAGE_ONLY'
            and pcnr_name ne '';
      quit;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_classify_vars step 1 linkage_only insert);
      %if &p6_fail = 1 %then %return;
      %put NOTE: [06_profile] LINKAGE_ONLY exclusion list loaded from &lib..name_map;
    %end;
    %else %do;
      %p6_fail_out(msg=%str(&lib..name_map not found -- required when require_name_map=1));
      %return;
    %end;
  %end;
  %else %do;
    /* require_name_map=0: tests only -- skip name_map query */
    %if %sysfunc(exist(&lib..name_map)) %then %do;
      proc sql noprint;
        insert into work._p6_excl
          select upcase(strip(pcnr_name))
          from &lib..name_map
          where upcase(strip(status)) = 'LINKAGE_ONLY'
            and pcnr_name ne '';
      quit;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_classify_vars step 1 linkage_only optional insert);
      %if &p6_fail = 1 %then %return;
      %put NOTE: [06_profile] LINKAGE_ONLY exclusion list loaded from &lib..name_map (optional);
    %end;
    %else %do;
      %put NOTE: [06_profile] &lib..name_map not found -- only NORM_PSID excluded (test mode or non-PCNR family);
    %end;
  %end;

  /* ---- Step 2: Candidate variable roster from DICTIONARY.COLUMNS ---- */

  proc sql noprint;
    create table work._p6_meta as
      select name,
             type,
             length,
             format
      from dictionary.columns
      where libname  = upcase("&lib")
        and memname  = upcase("&ds")
        and upcase(name) like upcase("&prefix.%")
        and upcase(name) ne 'NORM_PSID'
        and upcase(name) not in (select upcase(strip(excl_name)) from work._p6_excl)
      order by name;
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 2 meta query);
  %if &p6_fail = 1 %then %return;

  %local _p6_meta_n;
  proc sql noprint;
    select count(*) into :_p6_meta_n trimmed
    from work._p6_meta;
  quit;
  %if &_p6_meta_n = 0 %then %do;
    %p6_fail_out(msg=%str(No variables found in &lib..&ds matching prefix &prefix -- check prefix= parameter));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] &_p6_meta_n variables found matching prefix &prefix in &lib..&ds;

  /* ---- Step 3: Batched PROC FREQ NLEVELS for distinct non-missing counts ---- */
  /* Generate a .sas file with one PROC FREQ NLEVELS per batch of ~100 variables,
     %include it, then stack the NLevels ODS outputs.
     NNonMissLevels column gives distinct non-missing count directly.
     FILE (not MOD) so reruns never append (Phase 5 lesson). */

  %local _p6_batch_size _p6_batch_n _p6_batch_b _p6_varlist _p6_vname
         _p6_gen_file _p6_nl_accum;
  %let _p6_batch_size = 100;
  %let _p6_gen_file   = &logs_path.\06_generated_nlevels_&family..sas;

  /* Count variables for batch calculation */
  %local _p6_total_vars;
  %let _p6_total_vars = &_p6_meta_n;

  /* Generate the batched PROC FREQ NLEVELS calls */
  data _null_;
    /* Load variable names into macro array via call symputx */
    set work._p6_meta;
    call symputx(cats('_p6_vn_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx('_p6_total_vars', strip(put(_n_, best32.)), 'L');
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 varname load);
  %if &p6_fail = 1 %then %return;

  /* Write generated file -- FILE (not MOD) */
  data _null_;
    file "&_p6_gen_file" lrecl=32767;
    /* Header comment */
    put "* Generated by p6_classify_vars -- do not edit *;";
    put "* Family: &family  Dataset: &lib..&ds  Prefix: &prefix *;";
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 gen file header);
  %if &p6_fail = 1 %then %return;

  /* Append batch PROC FREQ statements */
  %let _p6_batch_b = 1;
  %do %while (&_p6_batch_b <= &_p6_total_vars);

    /* Build variable list for this batch */
    %local _p6_batch_varlist;
    %let _p6_batch_varlist = ;
    %local _p6_bi;
    %let _p6_bi = &_p6_batch_b;
    %do %while (&_p6_bi <= &_p6_total_vars and &_p6_bi < %eval(&_p6_batch_b + &_p6_batch_size));
      %let _p6_batch_varlist = &_p6_batch_varlist &&_p6_vn_&_p6_bi;
      %let _p6_bi = %eval(&_p6_bi + 1);
    %end;

    /* Batch number for ODS output naming */
    %local _p6_bnum;
    %let _p6_bnum = %eval((&_p6_batch_b - 1) / &_p6_batch_size + 1);

    /* Append this batch's PROC FREQ call to the generated file */
    data _null_;
      file "&_p6_gen_file" lrecl=32767 mod;
      put "proc freq data=&lib..&ds nlevels;";
      put "  tables &_p6_batch_varlist / noprint;";
      put "  ods output nlevels=work._p6_nl_b&_p6_bnum;";
      put "run;";
    run;
    %if &p6_fail = 1 %then %return;

    %let _p6_batch_b = %eval(&_p6_batch_b + &_p6_batch_size);
  %end;

  /* Include the generated file -- suppress listing output while keeping ODS datasets */
  ods listing close;
  %include "&_p6_gen_file";
  ods listing;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 nlevels include);
  %if &p6_fail = 1 %then %return;

  /* Stack all _p6_nl_b* outputs into work._p6_nl_all */
  /* Number of batches */
  %local _p6_nbatches;
  %let _p6_nbatches = %eval((&_p6_total_vars + &_p6_batch_size - 1) / &_p6_batch_size);

  /* Keep only the three columns needed; excludes TableVarLabel (which varies in     */
  /* declared length across batches and causes "Multiple lengths" WARNING).           */
  data work._p6_nl_all;
    length TableVar $32 NLevels 8 NNonMissLevels 8;
    %local _p6_sb;
    %let _p6_sb = 1;
    set
    %do %while (&_p6_sb <= &_p6_nbatches);
      work._p6_nl_b&_p6_sb (keep=TableVar NLevels NNonMissLevels)
      %let _p6_sb = %eval(&_p6_sb + 1);
    %end;
    ;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 nlevels stack);
  %if &p6_fail = 1 %then %return;

  /* Rename TableVar -> name; compute n_distinct as NNonMissLevels when present,
     else NLevels (coalesce handles SAS versions that omit NNonMissLevels).      */
  data work._p6_nl_all;
    length name $32 name_upper $32 n_distinct 8;
    set work._p6_nl_all (rename=(TableVar=name));
    /* NNonMissLevels is the non-missing distinct count; NLevels includes the
       missing level.  Use NNonMissLevels when non-missing, else NLevels.       */
    if nmiss(NNonMissLevels) then
      n_distinct = NLevels;
    else
      n_distinct = NNonMissLevels;
    name_upper = upcase(strip(name));
    keep name name_upper n_distinct;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 nlevels rename);
  %if &p6_fail = 1 %then %return;

  /* Assert every meta variable got exactly one n_distinct row */
  %local _p6_nl_n;
  proc sql noprint;
    select count(*) into :_p6_nl_n trimmed
    from work._p6_nl_all;
  quit;
  %if &_p6_nl_n ne &_p6_total_vars %then %do;
    %p6_fail_out(msg=%str(NLEVELS output has &_p6_nl_n rows but expected &_p6_total_vars -- mismatch in distinct count step));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] NLEVELS distinct count pass complete: &_p6_nl_n rows OK;

  /* ---- Step 4: Assign var_class ---- */
  /* DATE tier check runs FIRST (D-06 precedence).
     Name-pattern fallback for blank format requires one PROC MEANS pass
     over all candidate numeric _DATE/_DTTM vars together.
     Character *_date variables are never DATE; log a NOTE listing them.
     DATE format set (exact, after stripping width/decimals via compress):
       dates:     DATE DAY DDMMYY DDMMYYB DDMMYYC DDMMYYD DDMMYYN DDMMYYP DDMMYYS
                  MMDDYY MMDDYYB MMDDYYC MMDDYYD MMDDYYN MMDDYYP MMDDYYS
                  YYMMDD YYMMDDB YYMMDDC YYMMDDD YYMMDDN YYMMDDP YYMMDDS
                  MONYY MONNAME YEAR YYMON YYMM YYQ JULIAN WEEKDATE WEEKDATX
                  WORDDATE WORDDATX DOWNAME NLDATE E8601DA B8601DA MMYY
       datetimes: DATETIME DTDATE DTMONYY DTYEAR DTWKDATX DTYYQC E8601DT B8601DT NLDATM
       times:     TIME TOD HHMM HOUR MMSS E8601TM B8601TM NLTIME
  */

  /* Join meta + n_distinct */
  proc sql noprint;
    create table work._p6_joined as
      select m.name,
             m.type,
             m.length,
             m.format,
             n.n_distinct
      from work._p6_meta as m
      inner join work._p6_nl_all as n
        on upcase(strip(m.name)) = n.name_upper
      order by m.name;
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 4 meta+nlevels join);
  %if &p6_fail = 1 %then %return;

  /* Identify numeric blank-format _DATE/_DTTM candidates for name-pattern fallback.
     Run ONE PROC MEANS min/max across all such candidates.
     SAS date plausible range: -3653 (1950-01-01) to 36525 (2060-01-09). */

  /* Split into two queries: count first, then list (avoids empty-row issue) */
  %local _p6_np_count;
  %let _p6_np_count = 0;
  proc sql noprint;
    select count(*) into :_p6_np_count trimmed
    from work._p6_joined
    where type = 'num'
      and prxchange('s/\d*\.\d*$//', 1, strip(format)) = ''
      and (upcase(reverse(strip(name))) like upcase(reverse('_DATE') || '%')
           or upcase(reverse(strip(name))) like upcase(reverse('_DTTM') || '%'));
  quit;
  %if &p6_fail = 1 %then %return;

  %local _p6_np_varlist;
  %let _p6_np_varlist = ;
  %if &_p6_np_count > 0 %then %do;
    proc sql noprint;
      select strip(name) into :_p6_np_varlist separated by ' '
      from work._p6_joined
      where type = 'num'
        and prxchange('s/\d*\.\d*$//', 1, strip(format)) = ''
        and (upcase(reverse(strip(name))) like upcase(reverse('_DATE') || '%')
             or upcase(reverse(strip(name))) like upcase(reverse('_DTTM') || '%'));
    quit;
    %if &p6_fail = 1 %then %return;

    /* Plausibility: ONE PROC MEANS min/max across all candidates */
    ods listing close;
    ods output summary=work._p6_np_stats;
    proc means data=&lib..&ds stackodsoutput min max;
      var &_p6_np_varlist;
    run;
    ods output close;
    ods listing;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_classify_vars step 4 name-pattern PROC MEANS);
    %if &p6_fail = 1 %then %return;
  %end;

  /* Build list of name-pattern variables that pass plausibility (min>=-3653, max<=36525) */
  %local _p6_np_inrange_list;
  %let _p6_np_inrange_list = ;
  %if &_p6_np_count > 0 %then %do;
    proc sql noprint;
      select strip(Variable) into :_p6_np_inrange_list separated by ' '
      from work._p6_np_stats
      where Min >= -3653 and Max <= 36525;
    quit;
    %if &p6_fail = 1 %then %return;
    /* Log out-of-range name-pattern candidates */
    data _null_;
      set work._p6_np_stats;
      where not (Min >= -3653 and Max <= 36525);
      put "NOTE: [06_profile] name-pattern date variable out of plausible range -- classifying by cardinality: " Variable;
    run;
  %end;

  /* Log character *_date / *_dttm variables (they fall to LOW_CARD/HIGH_CARD) */
  %local _p6_char_date_n;
  proc sql noprint;
    select count(*) into :_p6_char_date_n trimmed
    from work._p6_joined
    where type = 'char'
      and (upcase(reverse(strip(name))) like upcase(reverse('_DATE') || '%')
           or upcase(reverse(strip(name))) like upcase(reverse('_DTTM') || '%'));
  quit;
  %if &p6_fail = 1 %then %return;
  %if &_p6_char_date_n > 0 %then %do;
    data _null_;
      set work._p6_joined;
      where type = 'char'
        and (upcase(reverse(strip(name))) like upcase(reverse('_DATE') || '%')
             or upcase(reverse(strip(name))) like upcase(reverse('_DTTM') || '%'));
      put "NOTE: [06_profile] char *_date / *_dttm variable (not DATE tier): " name;
    run;
    %put NOTE: [06_profile] &_p6_char_date_n character *_date / *_dttm variable(s) found -- classified by cardinality (see above NOTEs);
  %end;

  /* Build work._p6_vars with var_class assignment via DATA-step logic (C3: no open-code %if) */
  data work._p6_vars;
    length name $200 type $8 format $49 var_class $12 date_kind $12 display_format $32
           _uname $200 _is_np 8;

    /* Define the exact date/datetime/time format sets (stripped of width/decimals) */
    length _fmt_stripped $49 _date_kind $12;
    retain _dummy 0; /* suppress uninitialized note */

    set work._p6_joined;

    /* Normalize format: strip trailing width/decimals only (e.g. E8601DA10. -> E8601DA) */
    _fmt_stripped = upcase(prxchange('s/\d*\.\d*$//', 1, strip(format)));

    /* Initialize classification outputs */
    var_class      = '';
    date_kind      = '';
    display_format = '';

    /* ---- DATE tier check (D-06 precedence) ---- */
    _is_date = 0;
    _date_kind = '';

    if type = 'num' then do;

      /* Check format against exact set */
      if _fmt_stripped in (
        /* dates */
        'DATE','DAY','DDMMYY','DDMMYYB','DDMMYYC','DDMMYYD','DDMMYYN','DDMMYYP','DDMMYYS',
        'MMDDYY','MMDDYYB','MMDDYYC','MMDDYYD','MMDDYYN','MMDDYYP','MMDDYYS',
        'YYMMDD','YYMMDDB','YYMMDDC','YYMMDDD','YYMMDDN','YYMMDDP','YYMMDDS',
        'MONYY','MONNAME','YEAR','YYMON','YYMM','YYQ','JULIAN',
        'WEEKDATE','WEEKDATX','WORDDATE','WORDDATX','DOWNAME',
        'NLDATE','E8601DA','B8601DA','MMYY'
      ) then do;
        _is_date  = 1;
        _date_kind = 'DATE';
      end;
      else if _fmt_stripped in (
        /* datetimes */
        'DATETIME','DTDATE','DTMONYY','DTYEAR','DTWKDATX','DTYYQC',
        'E8601DT','B8601DT','NLDATM'
      ) then do;
        _is_date  = 1;
        _date_kind = 'DATETIME';
      end;
      else if _fmt_stripped in (
        /* times */
        'TIME','TOD','HHMM','HOUR','MMSS','E8601TM','B8601TM','NLTIME'
      ) then do;
        _is_date  = 1;
        _date_kind = 'TIME';
      end;
      /* Name-pattern fallback: blank format AND name ends _DATE or _DTTM */
      else if _fmt_stripped = '' then do;
        _uname = upcase(strip(name));
        _is_np = (length(_uname) >= 5 and
                  substr(_uname, length(_uname)-4) in ('_DATE','_DTTM'));
        if _is_np then do;
          /* Only assign DATE when the variable passed the plausibility check
             (min>=-3653 and max<=36525).  Out-of-range vars are logged above
             and fall through to the LOW_CARD/CONT_NUM cardinality branches.  */
          if indexw(upcase("&_p6_np_inrange_list"), _uname) > 0 then do;
            _is_date   = 1;
            _date_kind = 'DATE';
          end;
          /* else: _is_date stays 0; classify by cardinality below */
        end;
      end;

    end; /* type=num */

    /* Assign var_class */
    if _is_date then do;
      var_class      = 'DATE';
      date_kind      = _date_kind;
      display_format = strip(format);
      /* Name-pattern dates with blank format get DATE9. as display_format */
      if display_format = '' then display_format = 'DATE9.';
    end;
    else if n_distinct <= 20 then do;
      /* Covers 0 non-missing (100% missing) per D-07 */
      var_class = 'LOW_CARD';
    end;
    else if type = 'num' then do;
      /* n_distinct >= 21 */
      var_class = 'CONT_NUM';
    end;
    else do;
      /* type='char', n_distinct >= 21 */
      var_class = 'HIGH_CARD';
    end;

    /* Drop working variables */
    drop _fmt_stripped _is_date _date_kind _dummy;

    /* Keep output columns */
    keep name type length format n_distinct var_class date_kind display_format;

  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 4 var_class assignment);
  %if &p6_fail = 1 %then %return;

  /* ---- Step 5: Set _p6_nv global and log class counts ---- */
  %global _p6_nv;
  proc sql noprint;
    select count(*) into :_p6_nv trimmed
    from work._p6_vars;
  quit;
  %if &p6_fail = 1 %then %return;

  %put NOTE: [06_profile] work._p6_vars complete: &_p6_nv variables classified;

  /* Log counts per var_class */
  %local _p6_n_date _p6_n_lc _p6_n_cn _p6_n_hc;
  proc sql noprint;
    select
      sum(var_class='DATE'),
      sum(var_class='LOW_CARD'),
      sum(var_class='CONT_NUM'),
      sum(var_class='HIGH_CARD')
    into
      :_p6_n_date   trimmed,
      :_p6_n_lc     trimmed,
      :_p6_n_cn     trimmed,
      :_p6_n_hc     trimmed
    from work._p6_vars;
  quit;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] var_class summary: DATE=&_p6_n_date LOW_CARD=&_p6_n_lc CONT_NUM=&_p6_n_cn HIGH_CARD=&_p6_n_hc;

%mend p6_classify_vars;

/* ============================================================
   %_p6_attrib
   Emits the ATTRIB statement for the 13 locked schema columns.
   Uses &_p6_lvl_len (global, set in %pdd_profile before any
   computation macro is called).
   C26: no literal "pdd." -- always use &lib / &outlib params.
   ============================================================ */
%macro _p6_attrib;
  attrib
    family         length=$32      label='Family'
    variable       length=$32      label='Variable name'
    var_class      length=$12      label='Variable class'
    stat           length=$12      label='Row type identifier'
    level          length=$&_p6_lvl_len label='Category text (LEVEL rows only)'
    n              length=8        label='Count'
    value          length=8        label='Statistic value'
    pct_total      length=8        label='n / total_rows * 100'
    pct_nonmiss    length=8        label='n / n_nonmiss * 100'
    sort_order     length=8        label='Display sort order within variable'
    small_cell_flag length=$1      label='Y if 1<=n<=10'
    date_kind      length=$8       label='DATE / DATETIME / TIME or blank'
    display_format length=$32      label='SAS format for DATE tier'
  ;
%mend _p6_attrib;

/* ============================================================
   %p6_freq_lowcard
   Compute LOW_CARD distributions.
   - D-07 (100% missing) variables: emit single MISSING row directly.
   - Others: batched PROC FREQ OUT= with MISSING option; reshape
     to LEVEL rows + one MISSING row per variable.
   - Appends normalised rows into work._p6_rows (no FORCE).
   ============================================================ */
%macro p6_freq_lowcard(lib=, ds=);
  %_p6_ok(section=p6_freq_lowcard entry);
  %if &p6_fail = 1 %then %return;

  /* Identify LOW_CARD variables */
  %local _p6_lc_n;
  proc sql noprint;
    select count(*) into :_p6_lc_n trimmed
    from work._p6_vars
    where var_class = 'LOW_CARD';
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_lc_n = 0 %then %do;
    %put NOTE: [06_profile] p6_freq_lowcard: no LOW_CARD variables -- skipping;
    %return;
  %end;

  %put NOTE: [06_profile] p6_freq_lowcard: processing &_p6_lc_n LOW_CARD variable(s);

  /* Load LOW_CARD variable names into macro array */
  %local _p6_lc_total;
  %let _p6_lc_total = &_p6_lc_n;
  data _null_;
    set work._p6_vars (where=(var_class='LOW_CARD'));
    call symputx(cats('_p6_lcv_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx(cats('_p6_lct_', strip(put(_n_, best32.))), strip(type), 'L');
    call symputx(cats('_p6_lcd_', strip(put(_n_, best32.))), strip(put(n_distinct, best32.)), 'L');
    call symputx(cats('_p6_lck_', strip(put(_n_, best32.))), strip(date_kind), 'L');
    call symputx(cats('_p6_lcf_', strip(put(_n_, best32.))), strip(display_format), 'L');
    call symputx(cats('_p6_lcc_', strip(put(_n_, best32.))), strip(var_class), 'L');
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_freq_lowcard varname load);
  %if &p6_fail = 1 %then %return;

  /* ---- D-07: 100%-missing LOW_CARD variables ---- */
  /* Emit single MISSING row for each; no PROC FREQ needed */
  %local _p6_lci;
  %let _p6_lci = 1;
  %do %while (&_p6_lci <= &_p6_lc_total);
    %if &&_p6_lcd_&_p6_lci = 0 %then %do;
      /* 100% missing: single MISSING row */
      data work._p6_lc_d07;
        %_p6_attrib;
        family         = upcase("&family");
        variable       = "&&_p6_lcv_&_p6_lci";
        var_class      = "&&_p6_lcc_&_p6_lci";
        stat           = 'MISSING';
        level          = '';
        n              = &_p6_total;
        value          = .;
        pct_total      = 100;
        pct_nonmiss    = .;
        sort_order     = 99;
        /* small_cell_flag D-04: 1<=n<=10 */
        if &_p6_total >= 1 and &_p6_total <= 10
          then small_cell_flag = 'Y';
          else small_cell_flag = 'N';
        date_kind      = "&&_p6_lck_&_p6_lci";
        display_format = "&&_p6_lcf_&_p6_lci";
        output;
        stop;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard d07 row &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;
      proc append base=work._p6_rows data=work._p6_lc_d07;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard d07 append &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;
    %end;
    %let _p6_lci = %eval(&_p6_lci + 1);
  %end;

  /* ---- Batch PROC FREQ for non-D07 LOW_CARD variables ---- */
  /* Write generated include file -- FILE (not MOD) so reruns are safe */
  %local _p6_lc_gen;
  %let _p6_lc_gen = &logs_path.\06_generated_lowcard_&family..sas;

  /* Count non-D07 LOW_CARD vars */
  %local _p6_lc_nd07;
  %let _p6_lc_nd07 = 0;
  %let _p6_lci = 1;
  %do %while (&_p6_lci <= &_p6_lc_total);
    %if &&_p6_lcd_&_p6_lci > 0 %then
      %let _p6_lc_nd07 = %eval(&_p6_lc_nd07 + 1);
    %let _p6_lci = %eval(&_p6_lci + 1);
  %end;

  %if &_p6_lc_nd07 = 0 %then %do;
    %put NOTE: [06_profile] p6_freq_lowcard: all LOW_CARD vars were 100%% missing -- no PROC FREQ needed;
    %goto lc_done;
  %end;

  /* Write header */
  data _null_;
    file "&_p6_lc_gen" lrecl=32767;
    put "* Generated by p6_freq_lowcard -- do not edit *;";
    put "* Family: &family  Dataset: &lib..&ds *;";
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_freq_lowcard gen header);
  %if &p6_fail = 1 %then %return;

  /* Write one PROC FREQ per non-D07 LOW_CARD variable (each needs its own OUT=) */
  /* Batch into groups of 100 TABLES statements */
  %local _p6_lc_batch_size _p6_lc_bstart _p6_lc_bnum;
  %let _p6_lc_batch_size = 100;
  %let _p6_lc_bstart = 0; /* will increment to find non-D07 */
  %let _p6_lc_bnum   = 0;
  %local _p6_lc_bi_in_batch _p6_lc_batch_open;
  %let _p6_lc_bi_in_batch = 0;
  %let _p6_lc_batch_open  = 0;
  %let _p6_lc_bnum        = 0;

  %let _p6_lci = 1;
  %do %while (&_p6_lci <= &_p6_lc_total);
    %if &&_p6_lcd_&_p6_lci > 0 %then %do;
      /* This var needs PROC FREQ */
      %let _p6_lc_bi_in_batch = %eval(&_p6_lc_bi_in_batch + 1);

      /* Open a new batch if needed */
      %if &_p6_lc_batch_open = 0 %then %do;
        %let _p6_lc_bnum = %eval(&_p6_lc_bnum + 1);
        %let _p6_lc_batch_open = 1;
        data _null_;
          file "&_p6_lc_gen" lrecl=32767 mod;
          put "proc freq data=&lib..&ds noprint;";
        run;
        %if &p6_fail = 1 %then %return;
      %end;

      /* Append this variable's TABLES statement to current batch */
      data _null_;
        file "&_p6_lc_gen" lrecl=32767 mod;
        put "  tables &&_p6_lcv_&_p6_lci / out=work._p6_lc_f&_p6_lci(keep=&&_p6_lcv_&_p6_lci COUNT) missing noprint;";
      run;
      %if &p6_fail = 1 %then %return;

      /* Close batch if full */
      %if &_p6_lc_bi_in_batch >= &_p6_lc_batch_size %then %do;
        data _null_;
          file "&_p6_lc_gen" lrecl=32767 mod;
          put "run;";
        run;
        %if &p6_fail = 1 %then %return;
        %let _p6_lc_batch_open  = 0;
        %let _p6_lc_bi_in_batch = 0;
      %end;
    %end;
    %let _p6_lci = %eval(&_p6_lci + 1);
  %end;

  /* Close last open batch if any */
  %if &_p6_lc_batch_open = 1 %then %do;
    data _null_;
      file "&_p6_lc_gen" lrecl=32767 mod;
      put "run;";
    run;
    %if &p6_fail = 1 %then %return;
    %let _p6_lc_batch_open = 0;
  %end;

  /* Include the generated file */
  %include "&_p6_lc_gen";
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_freq_lowcard gen include);
  %if &p6_fail = 1 %then %return;

  /* ---- Reshape each PROC FREQ output into schema rows ---- */
  %let _p6_lci = 1;
  %do %while (&_p6_lci <= &_p6_lc_total);
    %if &&_p6_lcd_&_p6_lci > 0 %then %do;

      /* Compute n_nonmiss for this variable from the PROC FREQ output */
      /* (rows where the variable value is not missing) */
      /* coalesce(sum,0) ensures 0 (not blank) when no non-missing rows exist */
      %local _p6_lc_nn;
      proc sql noprint;
        select coalesce(sum(COUNT), 0) into :_p6_lc_nn trimmed
        from work._p6_lc_f&_p6_lci
        where &&_p6_lcv_&_p6_lci is not missing;
      quit;
      %if &p6_fail = 1 %then %return;

      /* Build LEVEL rows + MISSING row from PROC FREQ output */
      /* Sort: n desc, level asc for sort_order assignment */
      proc sort data=work._p6_lc_f&_p6_lci
                out =work._p6_lc_sorted;
        where &&_p6_lcv_&_p6_lci is not missing;
        by descending COUNT &&_p6_lcv_&_p6_lci;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard sort &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;

      data work._p6_lc_piece;
        %_p6_attrib;
        call missing(of _all_);
        set work._p6_lc_sorted end=_eof;
        family         = upcase("&family");
        variable       = "&&_p6_lcv_&_p6_lci";
        var_class      = "&&_p6_lcc_&_p6_lci";
        stat           = 'LEVEL';
        /* Level text: char = strip value; num = strip(put(v,best32.)) */
        %if &&_p6_lct_&_p6_lci = char %then %do;
          level = strip(vvalue(&&_p6_lcv_&_p6_lci));
        %end;
        %else %do;
          level = strip(put(&&_p6_lcv_&_p6_lci, best32.));
        %end;
        n              = COUNT;
        value          = .;
        pct_total      = n / &_p6_total * 100;
        if &_p6_lc_nn > 0
          then pct_nonmiss = n / &_p6_lc_nn * 100;
          else pct_nonmiss = .;
        sort_order     = _n_;
        if n >= 1 and n <= 10
          then small_cell_flag = 'Y';
          else small_cell_flag = 'N';
        date_kind      = "&&_p6_lck_&_p6_lci";
        display_format = "&&_p6_lcf_&_p6_lci";
        drop COUNT &&_p6_lcv_&_p6_lci;
        output;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard level rows &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;

      /* Add MISSING row (n from PROC FREQ OUT= missing row or 0 if none) */
      /* coalesce(sum,0) ensures 0 (not blank) when no missing values exist */
      %local _p6_lc_nmiss;
      proc sql noprint;
        select coalesce(sum(COUNT), 0) into :_p6_lc_nmiss trimmed
        from work._p6_lc_f&_p6_lci
        where &&_p6_lcv_&_p6_lci is missing;
      quit;
      %if &p6_fail = 1 %then %return;

      data work._p6_lc_miss;
        %_p6_attrib;
        family         = upcase("&family");
        variable       = "&&_p6_lcv_&_p6_lci";
        var_class      = "&&_p6_lcc_&_p6_lci";
        stat           = 'MISSING';
        level          = '';
        n              = &_p6_lc_nmiss;
        value          = .;
        pct_total      = n / &_p6_total * 100;
        pct_nonmiss    = .;
        sort_order     = 99;
        if n >= 1 and n <= 10
          then small_cell_flag = 'Y';
          else small_cell_flag = 'N';
        date_kind      = "&&_p6_lck_&_p6_lci";
        display_format = "&&_p6_lcf_&_p6_lci";
        output;
        stop;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard missing row &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;

      proc append base=work._p6_rows data=work._p6_lc_piece;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard append piece &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;

      proc append base=work._p6_rows data=work._p6_lc_miss;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard append miss &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;

    %end;
    %let _p6_lci = %eval(&_p6_lci + 1);
  %end;

  %lc_done:
  %put NOTE: [06_profile] p6_freq_lowcard complete;

%mend p6_freq_lowcard;

/* ============================================================
   %p6_stats_contnum
   Compute CONT_NUM and DATE distributions.
   - D-07 (100% missing) variables: emit single MISSING row directly,
     BEFORE PROC MEANS (all-missing numerics must not reach PROC MEANS).
   - Others: ONE PROC MEANS pass with all vars in one VAR statement;
     reshape to nine rows per variable.
   - Appends normalised rows into work._p6_rows (no FORCE).
   ============================================================ */
%macro p6_stats_contnum(lib=, ds=);
  %_p6_ok(section=p6_stats_contnum entry);
  %if &p6_fail = 1 %then %return;

  %local _p6_cn_n;
  proc sql noprint;
    select count(*) into :_p6_cn_n trimmed
    from work._p6_vars
    where var_class in ('CONT_NUM','DATE');
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_cn_n = 0 %then %do;
    %put NOTE: [06_profile] p6_stats_contnum: no CONT_NUM/DATE variables -- skipping;
    %return;
  %end;

  %put NOTE: [06_profile] p6_stats_contnum: processing &_p6_cn_n CONT_NUM/DATE variable(s);

  /* Load variable info into macro arrays */
  data _null_;
    set work._p6_vars (where=(var_class in ('CONT_NUM','DATE')));
    call symputx(cats('_p6_cnv_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx(cats('_p6_cnd_', strip(put(_n_, best32.))), strip(put(n_distinct, best32.)), 'L');
    call symputx(cats('_p6_cnk_', strip(put(_n_, best32.))), strip(date_kind), 'L');
    call symputx(cats('_p6_cnf_', strip(put(_n_, best32.))), strip(display_format), 'L');
    call symputx(cats('_p6_cnc_', strip(put(_n_, best32.))), strip(var_class), 'L');
    call symputx('_p6_cn_total', strip(put(_n_, best32.)), 'L');
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_stats_contnum varname load);
  %if &p6_fail = 1 %then %return;

  /* ---- D-07: 100%-missing CONT_NUM/DATE variables (branch BEFORE PROC MEANS) ---- */
  %local _p6_cni;
  %let _p6_cni = 1;
  %do %while (&_p6_cni <= &_p6_cn_total);
    %if &&_p6_cnd_&_p6_cni = 0 %then %do;
      data work._p6_cn_d07;
        %_p6_attrib;
        family         = upcase("&family");
        variable       = "&&_p6_cnv_&_p6_cni";
        var_class      = "&&_p6_cnc_&_p6_cni";
        stat           = 'MISSING';
        level          = '';
        n              = &_p6_total;
        value          = .;
        pct_total      = 100;
        pct_nonmiss    = .;
        sort_order     = 99;
        if &_p6_total >= 1 and &_p6_total <= 10
          then small_cell_flag = 'Y';
          else small_cell_flag = 'N';
        date_kind      = "&&_p6_cnk_&_p6_cni";
        display_format = "&&_p6_cnf_&_p6_cni";
        output;
        stop;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_stats_contnum d07 row &&_p6_cnv_&_p6_cni);
      %if &p6_fail = 1 %then %return;
      proc append base=work._p6_rows data=work._p6_cn_d07;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_stats_contnum d07 append &&_p6_cnv_&_p6_cni);
      %if &p6_fail = 1 %then %return;
    %end;
    %let _p6_cni = %eval(&_p6_cni + 1);
  %end;

  /* ---- Build VAR list for PROC MEANS (non-D07 only) ---- */
  %local _p6_cn_varlist _p6_cn_nd07;
  %let _p6_cn_varlist = ;
  %let _p6_cn_nd07    = 0;
  %let _p6_cni = 1;
  %do %while (&_p6_cni <= &_p6_cn_total);
    %if &&_p6_cnd_&_p6_cni > 0 %then %do;
      %let _p6_cn_varlist = &_p6_cn_varlist &&_p6_cnv_&_p6_cni;
      %let _p6_cn_nd07    = %eval(&_p6_cn_nd07 + 1);
    %end;
    %let _p6_cni = %eval(&_p6_cni + 1);
  %end;

  %if &_p6_cn_nd07 = 0 %then %do;
    %put NOTE: [06_profile] p6_stats_contnum: all CONT_NUM/DATE vars were 100%% missing -- no PROC MEANS needed;
    %goto cn_done;
  %end;

  /* ONE PROC MEANS with stackodsoutput — avoids autoname truncation on long varnames */
  ods listing close;
  ods output summary=work._p6_cn_stats;
  proc means data=&lib..&ds stackodsoutput n nmiss mean std median q1 q3 min max;
    var &_p6_cn_varlist;
  run;
  ods output close;
  ods listing;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_stats_contnum proc means);
  %if &p6_fail = 1 %then %return;

  /* Reshape: work._p6_cn_stats has one row per variable (stackodsoutput).
     Columns: Variable N NMiss Mean StdDev Median Q1 Q3 Min Max             */
  %let _p6_cni = 1;
  %do %while (&_p6_cni <= &_p6_cn_total);
    %if &&_p6_cnd_&_p6_cni > 0 %then %do;
      %local _p6_cn_vname;
      %let _p6_cn_vname = &&_p6_cnv_&_p6_cni;

      data work._p6_cn_piece;
        %_p6_attrib;
        call missing(of _all_);
        set work._p6_cn_stats (where=(upcase(strip(Variable)) = upcase("&_p6_cn_vname")));

        /* Common fields */
        family         = upcase("&family");
        variable       = "&_p6_cn_vname";
        var_class      = "&&_p6_cnc_&_p6_cni";
        level          = '';
        small_cell_flag = '';  /* blank on STAT rows per D-04 */
        date_kind      = "&&_p6_cnk_&_p6_cni";
        display_format = "&&_p6_cnf_&_p6_cni";

        /* N row (sort_order=1) */
        stat       = 'N';
        n          = N;
        value      = .;
        pct_total  = n / &_p6_total * 100;
        pct_nonmiss = .;
        sort_order = 1;
        output;

        /* N_MISSING row (sort_order=2) */
        stat       = 'N_MISSING';
        n          = NMiss;
        value      = .;
        pct_total  = n / &_p6_total * 100;
        pct_nonmiss = .;
        sort_order = 2;
        output;

        /* MEAN row (sort_order=3) */
        stat       = 'MEAN';
        n          = .;
        value      = Mean;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 3;
        output;

        /* SD row (sort_order=4) */
        stat       = 'SD';
        n          = .;
        value      = StdDev;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 4;
        output;

        /* MEDIAN row (sort_order=5) */
        stat       = 'MEDIAN';
        n          = .;
        value      = Median;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 5;
        output;

        /* Q1 row (sort_order=6) */
        stat       = 'Q1';
        n          = .;
        value      = Q1;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 6;
        output;

        /* Q3 row (sort_order=7) */
        stat       = 'Q3';
        n          = .;
        value      = Q3;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 7;
        output;

        /* MIN row (sort_order=8) */
        stat       = 'MIN';
        n          = .;
        value      = Min;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 8;
        output;

        /* MAX row (sort_order=9) */
        stat       = 'MAX';
        n          = .;
        value      = Max;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 9;
        output;

        keep family variable var_class stat level n value pct_total pct_nonmiss
             sort_order small_cell_flag date_kind display_format;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_stats_contnum reshape &_p6_cn_vname);
      %if &p6_fail = 1 %then %return;

      proc append base=work._p6_rows data=work._p6_cn_piece;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_stats_contnum append &_p6_cn_vname);
      %if &p6_fail = 1 %then %return;

    %end;
    %let _p6_cni = %eval(&_p6_cni + 1);
  %end;

  %cn_done:
  %put NOTE: [06_profile] p6_stats_contnum complete;

%mend p6_stats_contnum;

/* ============================================================
   %p6_freq_highcard
   Compute HIGH_CARD distributions.
   - Batched PROC FREQ OUT= with MISSING option per variable.
   - Ranks non-missing levels by COUNT desc, level asc.
   - Emits N_DISTINCT (sort_order=0), top-10 LEVEL (1..10),
     OTHER (11), MISSING (99) per D-03.
   - D-07 HIGH_CARD: not possible (HIGH_CARD requires n_distinct>=21),
     but code still guards via the n_distinct>0 check in _p6_vars.
   - Appends normalised rows into work._p6_rows (no FORCE).
   ============================================================ */
%macro p6_freq_highcard(lib=, ds=);
  %_p6_ok(section=p6_freq_highcard entry);
  %if &p6_fail = 1 %then %return;

  %local _p6_hc_n;
  proc sql noprint;
    select count(*) into :_p6_hc_n trimmed
    from work._p6_vars
    where var_class = 'HIGH_CARD';
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_hc_n = 0 %then %do;
    %put NOTE: [06_profile] p6_freq_highcard: no HIGH_CARD variables -- skipping;
    %return;
  %end;

  %put NOTE: [06_profile] p6_freq_highcard: processing &_p6_hc_n HIGH_CARD variable(s);

  /* Load HIGH_CARD variable names into macro arrays */
  data _null_;
    set work._p6_vars (where=(var_class='HIGH_CARD'));
    call symputx(cats('_p6_hcv_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx(cats('_p6_hcd_', strip(put(_n_, best32.))), strip(put(n_distinct, best32.)), 'L');
    call symputx(cats('_p6_hct_', strip(put(_n_, best32.))), strip(type), 'L');
    call symputx(cats('_p6_hck_', strip(put(_n_, best32.))), strip(date_kind), 'L');
    call symputx(cats('_p6_hcf_', strip(put(_n_, best32.))), strip(display_format), 'L');
    call symputx('_p6_hc_total', strip(put(_n_, best32.)), 'L');
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_freq_highcard varname load);
  %if &p6_fail = 1 %then %return;

  /* Write generated include file -- FILE (not MOD) */
  %local _p6_hc_gen;
  %let _p6_hc_gen = &logs_path.\06_generated_highcard_&family..sas;

  data _null_;
    file "&_p6_hc_gen" lrecl=32767;
    put "* Generated by p6_freq_highcard -- do not edit *;";
    put "* Family: &family  Dataset: &lib..&ds *;";
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_freq_highcard gen header);
  %if &p6_fail = 1 %then %return;

  /* Batch PROC FREQ (100 TABLES per PROC) */
  %local _p6_hc_batch_size _p6_hc_bi_in_batch _p6_hc_batch_open _p6_hci;
  %let _p6_hc_batch_size   = 100;
  %let _p6_hc_bi_in_batch  = 0;
  %let _p6_hc_batch_open   = 0;
  %let _p6_hci = 1;
  %do %while (&_p6_hci <= &_p6_hc_total);
    %let _p6_hc_bi_in_batch = %eval(&_p6_hc_bi_in_batch + 1);

    %if &_p6_hc_batch_open = 0 %then %do;
      %let _p6_hc_batch_open = 1;
      data _null_;
        file "&_p6_hc_gen" lrecl=32767 mod;
        put "proc freq data=&lib..&ds noprint;";
      run;
      %if &p6_fail = 1 %then %return;
    %end;

    data _null_;
      file "&_p6_hc_gen" lrecl=32767 mod;
      put "  tables &&_p6_hcv_&_p6_hci / out=work._p6_hc_f&_p6_hci(keep=&&_p6_hcv_&_p6_hci COUNT) missing noprint;";
    run;
    %if &p6_fail = 1 %then %return;

    %if &_p6_hc_bi_in_batch >= &_p6_hc_batch_size %then %do;
      data _null_;
        file "&_p6_hc_gen" lrecl=32767 mod;
        put "run;";
      run;
      %if &p6_fail = 1 %then %return;
      %let _p6_hc_batch_open  = 0;
      %let _p6_hc_bi_in_batch = 0;
    %end;

    %let _p6_hci = %eval(&_p6_hci + 1);
  %end;

  %if &_p6_hc_batch_open = 1 %then %do;
    data _null_;
      file "&_p6_hc_gen" lrecl=32767 mod;
      put "run;";
    run;
    %if &p6_fail = 1 %then %return;
    %let _p6_hc_batch_open = 0;
  %end;

  %include "&_p6_hc_gen";
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_freq_highcard gen include);
  %if &p6_fail = 1 %then %return;

  /* ---- Reshape each variable's PROC FREQ output into schema rows ---- */
  %let _p6_hci = 1;
  %do %while (&_p6_hci <= &_p6_hc_total);
    %local _p6_hc_vname _p6_hc_nmiss _p6_hc_nndist;
    %let _p6_hc_vname = &&_p6_hcv_&_p6_hci;

    /* Compute n_missing from PROC FREQ output */
    /* coalesce(sum,0) ensures 0 (not blank) when no missing values exist */
    proc sql noprint;
      select coalesce(sum(COUNT), 0) into :_p6_hc_nmiss trimmed
      from work._p6_hc_f&_p6_hci
      where &_p6_hc_vname is missing;
    quit;
    %if &p6_fail = 1 %then %return;

    /* n_distinct from classifier (used on N_DISTINCT row) */
    %let _p6_hc_nndist = &&_p6_hcd_&_p6_hci;

    /* Sort non-missing rows: COUNT desc, level asc (D-03 deterministic tie-break) */
    proc sort data=work._p6_hc_f&_p6_hci (where=(&_p6_hc_vname is not missing))
              out =work._p6_hc_sorted;
      by descending COUNT &_p6_hc_vname;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard sort &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    /* Compute n_other = sum of non-missing levels ranked > 10 */
    /* coalesce(sum,0) ensures 0 (not blank) when fewer than 11 levels exist */
    %local _p6_hc_nother;
    proc sql noprint;
      select coalesce(sum(COUNT), 0) into :_p6_hc_nother trimmed
      from (select COUNT, monotonic() as rn
            from work._p6_hc_sorted)
      where rn > 10;
    quit;
    %if &p6_fail = 1 %then %return;

    /* Build all rows for this variable */
    data work._p6_hc_piece;
      %_p6_attrib;
      call missing(of _all_);
      set work._p6_hc_sorted end=_eof;

      /* Keep only top-10 non-missing levels */
      if _n_ > 10 then stop;

      family         = upcase("&family");
      variable       = "&_p6_hc_vname";
      var_class      = 'HIGH_CARD';
      stat           = 'LEVEL';
      %if &&_p6_hct_&_p6_hci = char %then %do;
        level = strip(vvalue(&_p6_hc_vname));
      %end;
      %else %do;
        level = strip(put(&_p6_hc_vname, best32.));
      %end;
      n              = COUNT;
      value          = .;
      pct_total      = n / &_p6_total * 100;
      pct_nonmiss    = n / (&_p6_total - &_p6_hc_nmiss) * 100;
      sort_order     = _n_;
      if n >= 1 and n <= 10
        then small_cell_flag = 'Y';
        else small_cell_flag = 'N';
      date_kind      = '';
      display_format = '';
      drop COUNT &_p6_hc_vname;
      output;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard level rows &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    /* N_DISTINCT row (sort_order=0) */
    data work._p6_hc_ndist;
      %_p6_attrib;
      family         = upcase("&family");
      variable       = "&_p6_hc_vname";
      var_class      = 'HIGH_CARD';
      stat           = 'N_DISTINCT';
      level          = '';
      n              = &_p6_hc_nndist;
      value          = .;
      pct_total      = .;
      pct_nonmiss    = .;
      sort_order     = 0;
      small_cell_flag = '';
      date_kind      = '';
      display_format = '';
      output;
      stop;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard ndist row &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    /* OTHER row (sort_order=11) */
    data work._p6_hc_other;
      %_p6_attrib;
      family         = upcase("&family");
      variable       = "&_p6_hc_vname";
      var_class      = 'HIGH_CARD';
      stat           = 'OTHER';
      level          = '';
      n              = &_p6_hc_nother;
      value          = .;
      pct_total      = n / &_p6_total * 100;
      pct_nonmiss    = n / (&_p6_total - &_p6_hc_nmiss) * 100;
      sort_order     = 11;
      if n >= 1 and n <= 10
        then small_cell_flag = 'Y';
        else small_cell_flag = 'N';
      date_kind      = '';
      display_format = '';
      output;
      stop;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard other row &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    /* MISSING row (sort_order=99) */
    data work._p6_hc_miss;
      %_p6_attrib;
      family         = upcase("&family");
      variable       = "&_p6_hc_vname";
      var_class      = 'HIGH_CARD';
      stat           = 'MISSING';
      level          = '';
      n              = &_p6_hc_nmiss;
      value          = .;
      pct_total      = n / &_p6_total * 100;
      pct_nonmiss    = .;
      sort_order     = 99;
      if n >= 1 and n <= 10
        then small_cell_flag = 'Y';
        else small_cell_flag = 'N';
      date_kind      = '';
      display_format = '';
      output;
      stop;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard missing row &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    /* Append all four pieces (order doesn't matter; final sort in %p6_write_output) */
    proc append base=work._p6_rows data=work._p6_hc_ndist;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard append ndist &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    proc append base=work._p6_rows data=work._p6_hc_piece;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard append levels &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    proc append base=work._p6_rows data=work._p6_hc_other;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard append other &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    proc append base=work._p6_rows data=work._p6_hc_miss;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_freq_highcard append miss &_p6_hc_vname);
    %if &p6_fail = 1 %then %return;

    %let _p6_hci = %eval(&_p6_hci + 1);
  %end;

  %put NOTE: [06_profile] p6_freq_highcard complete;

%mend p6_freq_highcard;

/* ============================================================
   %p6_suppressed
   D-09: Value suppression. Processes all SUPPRESSED variables
   (var_class already set to 'SUPPRESSED' in work._p6_vars before
   this macro is called).
   Rows emitted per variable (level always blank):
     N_DISTINCT  sort_order=0
     RANGE_MIN   sort_order=1   value = numeric min  OR char-length min
     RANGE_MAX   sort_order=2   value = numeric max  OR char-length max
     N           sort_order=3   n = non-missing count
     MISSING     sort_order=99  n = missing count
   If >=95% of non-missing values parse as numeric: numeric min/max.
   Otherwise: min/max length in characters; display_format='LENGTH'.
   Appends to work._p6_rows.
   Parameters:
     lib=  source library
     ds=   source dataset
   ============================================================ */
%macro p6_suppressed(lib=, ds=);
  %_p6_ok(section=p6_suppressed entry);
  %if &p6_fail = 1 %then %return;

  /* Count SUPPRESSED variables */
  %local _p6_sup_n;
  proc sql noprint;
    select count(*) into :_p6_sup_n trimmed
    from work._p6_vars
    where var_class = 'SUPPRESSED';
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_sup_n = 0 %then %do;
    %put NOTE: [06_profile] p6_suppressed: no SUPPRESSED variables -- skipping;
    %return;
  %end;

  %put NOTE: [06_profile] p6_suppressed: processing &_p6_sup_n SUPPRESSED variable(s);

  /* Load SUPPRESSED variable names and metadata into macro arrays */
  %local _p6_sup_total;
  %let _p6_sup_total = 0;
  data _null_;
    set work._p6_vars (where=(var_class='SUPPRESSED'));
    call symputx(cats('_p6_supv_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx(cats('_p6_supt_', strip(put(_n_, best32.))), strip(type), 'L');
    call symputx(cats('_p6_supk_', strip(put(_n_, best32.))), strip(date_kind), 'L');
    call symputx(cats('_p6_supf_', strip(put(_n_, best32.))), strip(display_format), 'L');
    call symputx(cats('_p6_supd_', strip(put(_n_, best32.))), strip(put(n_distinct, best32.)), 'L');
    call symputx('_p6_sup_total', strip(put(_n_, best32.)), 'L');
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_suppressed varname load);
  %if &p6_fail = 1 %then %return;

  /* ONE DATA step over &lib..&ds for all SUPPRESSED variables.                      */
  /* Generates per-variable IF blocks; no loop over &lib..&ds.                       */
  /* W9-exempt: single consolidated pass; no &lib..&ds read inside variable loop.    */
  data work._p6_sup_stats;
    length _vname $32
      %local _p6_supi;
      %let _p6_supi = 1;
      %do %while (&_p6_supi <= &_p6_sup_total);
        _nm_&_p6_supi 8 _nmiss_&_p6_supi 8 _np_&_p6_supi 8
        _nmin_&_p6_supi 8 _nmax_&_p6_supi 8
        _lmin_&_p6_supi 8 _lmax_&_p6_supi 8
        %let _p6_supi = %eval(&_p6_supi + 1);
      %end;
      ;
    retain
      %let _p6_supi = 1;
      %do %while (&_p6_supi <= &_p6_sup_total);
        _nm_&_p6_supi 0 _nmiss_&_p6_supi 0 _np_&_p6_supi 0
        _nmin_&_p6_supi . _nmax_&_p6_supi .
        _lmin_&_p6_supi . _lmax_&_p6_supi .
        %let _p6_supi = %eval(&_p6_supi + 1);
      %end;
      ;
    set &lib..&ds (keep=
      %let _p6_supi = 1;
      %do %while (&_p6_supi <= &_p6_sup_total);
        &&_p6_supv_&_p6_supi
        %let _p6_supi = %eval(&_p6_supi + 1);
      %end;
      ) end=_eof;

    /* Per-variable unrolled accumulators */
    %let _p6_supi = 1;
    %do %while (&_p6_supi <= &_p6_sup_total);
      %if &&_p6_supt_&_p6_supi = char %then %do;
        if strip(&&_p6_supv_&_p6_supi) = '' then _nmiss_&_p6_supi = _nmiss_&_p6_supi + 1;
        else do;
          _nm_&_p6_supi = _nm_&_p6_supi + 1;
          if input(strip(&&_p6_supv_&_p6_supi), ?? best32.) ne . then do;
            _np_&_p6_supi = _np_&_p6_supi + 1;
            if _nmin_&_p6_supi = . or input(strip(&&_p6_supv_&_p6_supi), ?? best32.) < _nmin_&_p6_supi
              then _nmin_&_p6_supi = input(strip(&&_p6_supv_&_p6_supi), ?? best32.);
            if _nmax_&_p6_supi = . or input(strip(&&_p6_supv_&_p6_supi), ?? best32.) > _nmax_&_p6_supi
              then _nmax_&_p6_supi = input(strip(&&_p6_supv_&_p6_supi), ?? best32.);
          end;
          if _lmin_&_p6_supi = . or length(strip(&&_p6_supv_&_p6_supi)) < _lmin_&_p6_supi
            then _lmin_&_p6_supi = length(strip(&&_p6_supv_&_p6_supi));
          if _lmax_&_p6_supi = . or length(strip(&&_p6_supv_&_p6_supi)) > _lmax_&_p6_supi
            then _lmax_&_p6_supi = length(strip(&&_p6_supv_&_p6_supi));
        end;
      %end;
      %else %do;
        if &&_p6_supv_&_p6_supi = . then _nmiss_&_p6_supi = _nmiss_&_p6_supi + 1;
        else do;
          _nm_&_p6_supi = _nm_&_p6_supi + 1;
          _np_&_p6_supi = _nm_&_p6_supi; /* numeric always parseable */
          if _nmin_&_p6_supi = . or &&_p6_supv_&_p6_supi < _nmin_&_p6_supi
            then _nmin_&_p6_supi = &&_p6_supv_&_p6_supi;
          if _nmax_&_p6_supi = . or &&_p6_supv_&_p6_supi > _nmax_&_p6_supi
            then _nmax_&_p6_supi = &&_p6_supv_&_p6_supi;
        end;
      %end;
      %let _p6_supi = %eval(&_p6_supi + 1);
    %end;

    if _eof then do;
      %let _p6_supi = 1;
      %do %while (&_p6_supi <= &_p6_sup_total);
        _vname = "&&_p6_supv_&_p6_supi";
        output;
        %let _p6_supi = %eval(&_p6_supi + 1);
      %end;
    end;
    keep _vname
      %let _p6_supi = 1;
      %do %while (&_p6_supi <= &_p6_sup_total);
        _nm_&_p6_supi _nmiss_&_p6_supi _np_&_p6_supi
        _nmin_&_p6_supi _nmax_&_p6_supi _lmin_&_p6_supi _lmax_&_p6_supi
        %let _p6_supi = %eval(&_p6_supi + 1);
      %end;
      ;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_suppressed one-pass stats);
  %if &p6_fail = 1 %then %return;

  /* Extract stats for each SUPPRESSED variable and emit rows */
  %let _p6_supi = 1;
  %do %while (&_p6_supi <= &_p6_sup_total);
    %local _p6_sup_vname _p6_sup_vtype _p6_sup_dk _p6_sup_df _p6_sup_nd;
    %let _p6_sup_vname = &&_p6_supv_&_p6_supi;
    %let _p6_sup_vtype = &&_p6_supt_&_p6_supi;
    %let _p6_sup_dk    = &&_p6_supk_&_p6_supi;
    %let _p6_sup_df    = &&_p6_supf_&_p6_supi;
    %let _p6_sup_nd    = &&_p6_supd_&_p6_supi;

    %local _p6_sup_nnonmiss _p6_sup_nmiss _p6_sup_nparse
           _p6_sup_nummin _p6_sup_nummax _p6_sup_lenmin _p6_sup_lenmax;
    proc sql noprint;
      select _nm_&_p6_supi, _nmiss_&_p6_supi, _np_&_p6_supi,
             _nmin_&_p6_supi, _nmax_&_p6_supi,
             _lmin_&_p6_supi, _lmax_&_p6_supi
      into :_p6_sup_nnonmiss trimmed, :_p6_sup_nmiss trimmed, :_p6_sup_nparse trimmed,
           :_p6_sup_nummin trimmed, :_p6_sup_nummax trimmed,
           :_p6_sup_lenmin trimmed, :_p6_sup_lenmax trimmed
      from work._p6_sup_stats
      where _vname = "&_p6_sup_vname";
    quit;
    %if &p6_fail = 1 %then %return;
    %if %bquote(&_p6_sup_nnonmiss) = %bquote() %then %let _p6_sup_nnonmiss = 0;
    %if %bquote(&_p6_sup_nmiss)    = %bquote() %then %let _p6_sup_nmiss    = 0;
    %if %bquote(&_p6_sup_nparse)   = %bquote() %then %let _p6_sup_nparse   = 0;

    /* Determine if numeric mode: >=95% parse rate among non-missing */
    %local _p6_sup_use_num;
    %let _p6_sup_use_num = 0;
    %if &_p6_sup_vtype = num %then %let _p6_sup_use_num = 1;
    %else %if &_p6_sup_nnonmiss > 0 %then %do;
      %if %sysevalf(&_p6_sup_nparse / &_p6_sup_nnonmiss >= 0.95) %then
        %let _p6_sup_use_num = 1;
    %end;

    /* Set range values and display_format flag */
    %local _p6_sup_rmin _p6_sup_rmax _p6_sup_dflag;
    %let _p6_sup_dflag = &_p6_sup_df;
    %if &_p6_sup_use_num = 1 %then %do;
      %let _p6_sup_rmin = &_p6_sup_nummin;
      %let _p6_sup_rmax = &_p6_sup_nummax;
      %if %bquote(&_p6_sup_rmin) = %bquote() %then %let _p6_sup_rmin = .;
      %if %bquote(&_p6_sup_rmax) = %bquote() %then %let _p6_sup_rmax = .;
    %end;
    %else %do;
      %let _p6_sup_rmin = &_p6_sup_lenmin;
      %let _p6_sup_rmax = &_p6_sup_lenmax;
      %if %bquote(&_p6_sup_rmin) = %bquote() %then %let _p6_sup_rmin = .;
      %if %bquote(&_p6_sup_rmax) = %bquote() %then %let _p6_sup_rmax = .;
      %let _p6_sup_dflag = LENGTH;
    %end;

    /* Emit 5 stat rows for this SUPPRESSED variable */
    data work._p6_sup_rows;
      %_p6_attrib;
      family         = upcase("&family");
      variable       = "&_p6_sup_vname";
      var_class      = 'SUPPRESSED';
      level          = '';
      value          = .;
      pct_total      = .;
      pct_nonmiss    = .;
      small_cell_flag = '';
      date_kind      = "&_p6_sup_dk";
      display_format = "&_p6_sup_dflag";

      /* N_DISTINCT row */
      stat       = 'N_DISTINCT';
      n          = &_p6_sup_nd;
      sort_order = 0;
      output;

      /* RANGE_MIN row */
      stat       = 'RANGE_MIN';
      n          = .;
      value      = &_p6_sup_rmin;
      sort_order = 1;
      output;

      /* RANGE_MAX row */
      stat       = 'RANGE_MAX';
      n          = .;
      value      = &_p6_sup_rmax;
      sort_order = 2;
      output;

      /* N row (non-missing count) */
      stat       = 'N';
      n          = &_p6_sup_nnonmiss;
      value      = .;
      sort_order = 3;
      output;

      /* MISSING row */
      stat       = 'MISSING';
      n          = &_p6_sup_nmiss;
      value      = .;
      sort_order = 99;
      if n >= 1 and n <= 10
        then small_cell_flag = 'Y';
        else small_cell_flag = 'N';
      output;

      stop;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_suppressed rows &_p6_sup_vname);
    %if &p6_fail = 1 %then %return;

    proc append base=work._p6_rows data=work._p6_sup_rows;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_suppressed append &_p6_sup_vname);
    %if &p6_fail = 1 %then %return;

    %let _p6_supi = %eval(&_p6_supi + 1);
  %end;

  %put NOTE: [06_profile] p6_suppressed complete: &_p6_sup_total SUPPRESSED variable(s) processed;

%mend p6_suppressed;

/* ============================================================
   %p6_numtext
   D-10: Numeric text detection for HIGH_CARD char variables.
   In one DATA step pass (arrays), per variable counts:
     n_nonmiss   strip(v) ne ''
     n_placeholder  upcase(strip(v)) in ('NULL','N/A','NA','?','UNKNOWN','.', '-')
     n_parse        input(strip(v), ?? best32.) not missing
     n_unparsed  = n_nonmiss - n_parse
   If n_parse / (n_nonmiss - n_placeholder) >= &num_text_threshold:
     var_class -> 'NUM_TEXT' in work._p6_vars.
   NUM_TEXT rows: N, N_MISSING, N_UNPARSED, MEAN SD MEDIAN Q1 Q3 MIN MAX
     (via PROC MEANS stackodsoutput on a WORK dataset of parsed numeric copies),
     plus up to 5 LEVEL rows (sort_order 20-24) for most frequent unparsed values.
   Called BEFORE %p6_freq_highcard so NUM_TEXT vars never get HIGH_CARD rows.
   Appends NUM_TEXT rows directly to work._p6_rows.
   Parameters:
     lib=  source library
     ds=   source dataset
     num_text_threshold=  parse rate threshold (default 0.95)
   ============================================================ */
%macro p6_numtext(lib=, ds=, num_text_threshold=0.95);
  %_p6_ok(section=p6_numtext entry);
  %if &p6_fail = 1 %then %return;

  /* Count HIGH_CARD char variables eligible for numtext check */
  %local _p6_nt_n;
  proc sql noprint;
    select count(*) into :_p6_nt_n trimmed
    from work._p6_vars
    where var_class = 'HIGH_CARD' and type = 'char';
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_nt_n = 0 %then %do;
    %put NOTE: [06_profile] p6_numtext: no HIGH_CARD char variables -- skipping;
    %return;
  %end;

  %put NOTE: [06_profile] p6_numtext: checking &_p6_nt_n HIGH_CARD char variable(s) for numeric text;

  /* Load HIGH_CARD char variable names and declared lengths into macro arrays */
  /* _p6_ntl_K = declared char length (used to set explicit array element length) */
  %local _p6_nt_total _p6_nt_maxlen;
  %let _p6_nt_total  = 0;
  %let _p6_nt_maxlen = 1;
  data _null_;
    set work._p6_vars (where=(var_class='HIGH_CARD' and type='char'));
    call symputx(cats('_p6_ntv_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx(cats('_p6_ntl_', strip(put(_n_, best32.))), strip(put(length, best32.)), 'L');
    call symputx('_p6_nt_total',  strip(put(_n_, best32.)), 'L');
    /* running max -- resolved after data step completes */
  run;
  %if &p6_fail = 1 %then %return;

  /* Compute max declared length across all candidates for array element size */
  %local _p6_ntj;
  %let _p6_ntj = 1;
  %do %while (&_p6_ntj <= &_p6_nt_total);
    %if &&_p6_ntl_&_p6_ntj > &_p6_nt_maxlen %then
      %let _p6_nt_maxlen = &&_p6_ntl_&_p6_ntj;
    %let _p6_ntj = %eval(&_p6_ntj + 1);
  %end;

  /* ONE DATA step over &lib..&ds to count parse rates for all HIGH_CARD char vars */
  /* Array declared with explicit $&_p6_nt_maxlen to avoid length-mismatch warnings */
  /* Accumulators held in _temporary_ arrays; one output row per candidate.         */
  /* W9-exempt: this is the single consolidated pass; no loop over &lib..&ds.       */
  data work._p6_nt_counts;
    length varname $32 n_nonmiss 8 n_placeholder 8 n_parse 8;
    array _ntv  {&_p6_nt_total} $ &_p6_nt_maxlen
      %let _p6_ntj = 1;
      %do %while (&_p6_ntj <= &_p6_nt_total);
        &&_p6_ntv_&_p6_ntj
        %let _p6_ntj = %eval(&_p6_ntj + 1);
      %end;
      ;
    array _nm   {&_p6_nt_total} _temporary_;  /* n_nonmiss */
    array _nph  {&_p6_nt_total} _temporary_;  /* n_placeholder */
    array _np   {&_p6_nt_total} _temporary_;  /* n_parse */

    if _n_ = 1 then do _j = 1 to &_p6_nt_total;
      _nm(_j) = 0; _nph(_j) = 0; _np(_j) = 0;
    end;

    set &lib..&ds (keep=
      %let _p6_ntj = 1;
      %do %while (&_p6_ntj <= &_p6_nt_total);
        &&_p6_ntv_&_p6_ntj
        %let _p6_ntj = %eval(&_p6_ntj + 1);
      %end;
      ) end=_eof;

    do _j = 1 to &_p6_nt_total;
      if strip(_ntv(_j)) ne '' then do;
        _nm(_j) = _nm(_j) + 1;
        if upcase(strip(_ntv(_j))) in ('NULL','N/A','NA','?','UNKNOWN','.','-')
          then _nph(_j) = _nph(_j) + 1;
        if input(strip(_ntv(_j)), ?? best32.) ne .
          then _np(_j) = _np(_j) + 1;
      end;
    end;

    if _eof then do _j = 1 to &_p6_nt_total;
      /* Set varname via macro-generated IF chain -- avoids vname() with loop counter */
      %let _p6_ntj = 1;
      %do %while (&_p6_ntj <= &_p6_nt_total);
        if _j = &_p6_ntj then varname = "&&_p6_ntv_&_p6_ntj";
        %let _p6_ntj = %eval(&_p6_ntj + 1);
      %end;
      n_nonmiss    = _nm(_j);
      n_placeholder = _nph(_j);
      n_parse      = _np(_j);
      output;
    end;
    keep varname n_nonmiss n_placeholder n_parse;
    drop _j;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_numtext one-pass count);
  %if &p6_fail = 1 %then %return;

  /* Log near-misses (parse rate 80-95%) and reclassify NUM_TEXT vars */
  %local _p6_nt_reclassified _p6_nt_reclassified_n;
  %let _p6_nt_reclassified   = ;
  %let _p6_nt_reclassified_n = 0;

  data _null_;
    set work._p6_nt_counts;
    length _rate 8;
    _denom = n_nonmiss - n_placeholder;
    if _denom > 0 then _rate = n_parse / _denom;
    else _rate = 0;
    if _rate >= &num_text_threshold then
      put "NOTE: [06_profile] NUM_TEXT candidate: " varname= _rate=;
    else if _rate >= 0.80 then
      put "NOTE: [06_profile] NUM_TEXT near-miss (80-95pct): " varname= _rate=;
  run;
  %if &p6_fail = 1 %then %return;

  /* Reclassify in work._p6_vars */
  proc sql noprint;
    update work._p6_vars
    set var_class = 'NUM_TEXT'
    where type = 'char'
      and var_class = 'HIGH_CARD'
      and upcase(name) in
        (select upcase(varname)
         from work._p6_nt_counts
         where (n_nonmiss - n_placeholder) > 0
           and (n_parse / (n_nonmiss - n_placeholder)) >= &num_text_threshold);
  quit;
  %if &p6_fail = 1 %then %return;

  proc sql noprint;
    select count(*) into :_p6_nt_reclassified_n trimmed
    from work._p6_vars
    where var_class = 'NUM_TEXT';
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_nt_reclassified_n = 0 %then %do;
    %put NOTE: [06_profile] p6_numtext: no variables met NUM_TEXT threshold;
    %return;
  %end;

  %put NOTE: [06_profile] p6_numtext: &_p6_nt_reclassified_n variable(s) reclassified as NUM_TEXT;
  /* No rows to delete: %p6_numtext runs before %p6_freq_highcard, so no HIGH_CARD */
  /* rows exist yet for these variables.                                              */

  /* Load NUM_TEXT variable names and counts into macro arrays */
  /* Also load count data from work._p6_nt_counts for each reclassified var. */
  %local _p6_ntr_total;
  %let _p6_ntr_total = 0;
  data _null_;
    set work._p6_vars (where=(var_class='NUM_TEXT'));
    call symputx(cats('_p6_ntrv_', strip(put(_n_, best32.))), strip(name), 'L');
    call symputx(cats('_p6_ntrd_', strip(put(_n_, best32.))), strip(put(n_distinct, best32.)), 'L');
    call symputx(cats('_p6_ntrl_', strip(put(_n_, best32.))), strip(put(length, best32.)), 'L');
    call symputx('_p6_ntr_total', strip(put(_n_, best32.)), 'L');
  run;
  %if &p6_fail = 1 %then %return;

  /* Pull per-var counts into macro arrays from work._p6_nt_counts */
  %local _p6_ntri;
  %let _p6_ntri = 1;
  %do %while (&_p6_ntri <= &_p6_ntr_total);
    %local _p6_ntr_nm_&_p6_ntri _p6_ntr_np_&_p6_ntri _p6_ntr_nph_&_p6_ntri;
    proc sql noprint;
      select n_nonmiss, n_parse, n_placeholder
      into :_p6_ntr_nm_&_p6_ntri trimmed,
           :_p6_ntr_np_&_p6_ntri trimmed,
           :_p6_ntr_nph_&_p6_ntri trimmed
      from work._p6_nt_counts
      where upcase(varname) = upcase("&&_p6_ntrv_&_p6_ntri");
    quit;
    %if &p6_fail = 1 %then %return;
    %if %bquote(&&_p6_ntr_nm_&_p6_ntri)  = %bquote() %then %let _p6_ntr_nm_&_p6_ntri  = 0;
    %if %bquote(&&_p6_ntr_np_&_p6_ntri)  = %bquote() %then %let _p6_ntr_np_&_p6_ntri  = 0;
    %if %bquote(&&_p6_ntr_nph_&_p6_ntri) = %bquote() %then %let _p6_ntr_nph_&_p6_ntri = 0;
    %let _p6_ntri = %eval(&_p6_ntri + 1);
  %end;

  /* Compute max declared length for array element size */
  %local _p6_ntr_maxlen;
  %let _p6_ntr_maxlen = 1;
  %let _p6_ntri = 1;
  %do %while (&_p6_ntri <= &_p6_ntr_total);
    %if &&_p6_ntrl_&_p6_ntri > &_p6_ntr_maxlen %then
      %let _p6_ntr_maxlen = &&_p6_ntrl_&_p6_ntri;
    %let _p6_ntri = %eval(&_p6_ntri + 1);
  %end;

  /* ONE DATA step: build parsed-numeric copy + collect unparsed values.         */
  /* _prs = wide table: _nt1.._ntK numeric (. when unparseable) for PROC MEANS. */
  /* _upraw = long table: varname + uval for unparsed LEVEL rows.               */
  /* W9-exempt: single consolidated pass; no &lib..&ds read inside variable loop.*/
  /* varname set via macro-generated IF chain (avoids vname() with loop counter).*/
  /* varname='' and uval='' initialised before set so columns always exist even  */
  /* when 0 rows are output to _upraw (0-unparsed case).                        */
  /* keep= per-dataset in data statement controls column scope.                  */
  data work._p6_nt_prs (keep=
        %let _p6_ntri = 1;
        %do %while (&_p6_ntri <= &_p6_ntr_total);
          _nt&_p6_ntri
          %let _p6_ntri = %eval(&_p6_ntri + 1);
        %end;
        )
       work._p6_nt_upraw (keep=varname uval);
    length varname $32 uval $&_p6_lvl_len;
    varname = ''; uval = ''; /* initialise so columns always exist in _upraw */
    array _src {&_p6_ntr_total} $ &_p6_ntr_maxlen
      %let _p6_ntri = 1;
      %do %while (&_p6_ntri <= &_p6_ntr_total);
        &&_p6_ntrv_&_p6_ntri
        %let _p6_ntri = %eval(&_p6_ntri + 1);
      %end;
      ;
    array _num {&_p6_ntr_total}
      %let _p6_ntri = 1;
      %do %while (&_p6_ntri <= &_p6_ntr_total);
        _nt&_p6_ntri
        %let _p6_ntri = %eval(&_p6_ntri + 1);
      %end;
      ;
    set &lib..&ds (keep=
      %let _p6_ntri = 1;
      %do %while (&_p6_ntri <= &_p6_ntr_total);
        &&_p6_ntrv_&_p6_ntri
        %let _p6_ntri = %eval(&_p6_ntri + 1);
      %end;
      );
    do _j = 1 to &_p6_ntr_total;
      if strip(_src(_j)) ne '' then do;
        _num(_j) = input(strip(_src(_j)), ?? best32.);
        /* Collect unparsed non-blank values for LEVEL rows */
        if _num(_j) = . then do;
          /* Set varname via macro-generated IF chain -- avoids vname() with loop counter */
          %let _p6_ntri = 1;
          %do %while (&_p6_ntri <= &_p6_ntr_total);
            if _j = &_p6_ntri then varname = "&&_p6_ntrv_&_p6_ntri";
            %let _p6_ntri = %eval(&_p6_ntri + 1);
          %end;
          uval = strip(_src(_j)); /* direct assign; SAS truncates to $&_p6_lvl_len via length stmt */
          output work._p6_nt_upraw;
        end;
      end;
      else _num(_j) = .;
    end;
    output work._p6_nt_prs;
    drop _j;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_numtext parsed-copy + unparsed collect);
  %if &p6_fail = 1 %then %return;

  /* ONE PROC MEANS across all _nt1.._ntK columns */
  /* ODS column names (stackodsoutput): Variable Mean StdDev Median Q1 Q3 Min Max */
  ods listing close;
  ods output summary=work._p6_nt_means;
  proc means data=work._p6_nt_prs stackodsoutput mean std median q1 q3 min max;
    var
      %let _p6_ntri = 1;
      %do %while (&_p6_ntri <= &_p6_ntr_total);
        _nt&_p6_ntri
        %let _p6_ntri = %eval(&_p6_ntri + 1);
      %end;
      ;
  run;
  ods output close;
  ods listing;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_numtext proc means all vars);
  %if &p6_fail = 1 %then %return;

  /* Build top-5 unparsed frequency per variable from collected unparsed table */
  proc sql noprint;
    create table work._p6_nt_upfreq as
      select varname, uval, count(*) as ucnt
      from work._p6_nt_upraw
      group by varname, uval
      order by varname, ucnt desc, uval;
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_numtext unparsed freq);
  %if &p6_fail = 1 %then %return;

  /* Emit stat rows per NUM_TEXT variable using macro arrays + PROC MEANS ODS table */
  /* _p6_nt_means has one row per _ntI with Variable='_ntI', and stat columns.      */
  %let _p6_ntri = 1;
  %do %while (&_p6_ntri <= &_p6_ntr_total);
    %local _p6_ntr_vname _p6_ntr_nd _p6_ntr_nnonmiss _p6_ntr_nparse
           _p6_ntr_nph _p6_ntr_nmiss _p6_ntr_nunparsed;
    %let _p6_ntr_vname    = &&_p6_ntrv_&_p6_ntri;
    %let _p6_ntr_nd       = &&_p6_ntrd_&_p6_ntri;
    %let _p6_ntr_nnonmiss = &&_p6_ntr_nm_&_p6_ntri;
    %let _p6_ntr_nparse   = &&_p6_ntr_np_&_p6_ntri;
    %let _p6_ntr_nph      = &&_p6_ntr_nph_&_p6_ntri;
    %let _p6_ntr_nmiss    = %eval(&_p6_total - &_p6_ntr_nnonmiss);
    %let _p6_ntr_nunparsed = %eval(&_p6_ntr_nnonmiss - &_p6_ntr_nparse);

    /* Extract stats for this variable from the single PROC MEANS ODS table */
    /* Variable column in stackodsoutput = '_nt&_p6_ntri' (the array element name) */
    %local _p6_nt_mean _p6_nt_std _p6_nt_med _p6_nt_q1 _p6_nt_q3 _p6_nt_min _p6_nt_max;
    proc sql noprint;
      select Mean, StdDev, Median, Q1, Q3, Min, Max
      into :_p6_nt_mean trimmed, :_p6_nt_std trimmed, :_p6_nt_med trimmed,
           :_p6_nt_q1 trimmed, :_p6_nt_q3 trimmed,
           :_p6_nt_min trimmed, :_p6_nt_max trimmed
      from work._p6_nt_means
      where upcase(Variable) = upcase("_nt&_p6_ntri");
    quit;
    %if &p6_fail = 1 %then %return;
    %if %bquote(&_p6_nt_mean) = %bquote() %then %let _p6_nt_mean = .;
    %if %bquote(&_p6_nt_std)  = %bquote() %then %let _p6_nt_std  = .;
    %if %bquote(&_p6_nt_med)  = %bquote() %then %let _p6_nt_med  = .;
    %if %bquote(&_p6_nt_q1)   = %bquote() %then %let _p6_nt_q1   = .;
    %if %bquote(&_p6_nt_q3)   = %bquote() %then %let _p6_nt_q3   = .;
    %if %bquote(&_p6_nt_min)  = %bquote() %then %let _p6_nt_min  = .;
    %if %bquote(&_p6_nt_max)  = %bquote() %then %let _p6_nt_max  = .;

    /* Emit stat rows for this NUM_TEXT variable */
    data work._p6_nt_rows;
      %_p6_attrib;
      family         = upcase("&family");
      variable       = "&_p6_ntr_vname";
      var_class      = 'NUM_TEXT';
      level          = '';
      pct_total      = .;
      pct_nonmiss    = .;
      small_cell_flag = '';
      date_kind      = '';
      display_format = '';

      /* N_DISTINCT row */
      stat       = 'N_DISTINCT';
      n          = &_p6_ntr_nd;
      value      = .;
      sort_order = 0;
      output;

      /* N (parsed count) */
      stat       = 'N';
      n          = &_p6_ntr_nparse;
      value      = .;
      sort_order = 3;
      pct_total  = n / &_p6_total * 100;
      output;

      /* N_MISSING */
      stat       = 'N_MISSING';
      n          = &_p6_ntr_nmiss;
      value      = .;
      sort_order = 4;
      pct_total  = n / &_p6_total * 100;
      output;

      /* N_UNPARSED (includes placeholders) */
      stat       = 'N_UNPARSED';
      n          = &_p6_ntr_nunparsed;
      value      = .;
      sort_order = 5;
      pct_total  = n / &_p6_total * 100;
      output;

      /* MEAN */
      stat       = 'MEAN';   n = .; value = &_p6_nt_mean; sort_order = 6;  output;
      /* SD */
      stat       = 'SD';     n = .; value = &_p6_nt_std;  sort_order = 7;  output;
      /* MEDIAN */
      stat       = 'MEDIAN'; n = .; value = &_p6_nt_med;  sort_order = 8;  output;
      /* Q1 */
      stat       = 'Q1';     n = .; value = &_p6_nt_q1;   sort_order = 9;  output;
      /* Q3 */
      stat       = 'Q3';     n = .; value = &_p6_nt_q3;   sort_order = 10; output;
      /* MIN */
      stat       = 'MIN';    n = .; value = &_p6_nt_min;  sort_order = 11; output;
      /* MAX */
      stat       = 'MAX';    n = .; value = &_p6_nt_max;  sort_order = 12; output;

      stop;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_numtext stat rows &_p6_ntr_vname);
    %if &p6_fail = 1 %then %return;

    proc append base=work._p6_rows data=work._p6_nt_rows;
    run;
    %if &p6_fail = 1 %then %return;

    /* Top-5 LEVEL rows for unparsed values for this variable */
    data work._p6_nt_lev_rows;
      %_p6_attrib;
      length _so 8;
      retain _so 19;
      set work._p6_nt_upfreq (where=(upcase(varname)=upcase("&_p6_ntr_vname")) obs=5);
      family          = upcase("&family");
      variable        = "&_p6_ntr_vname";
      var_class       = 'NUM_TEXT';
      stat            = 'LEVEL';
      level           = uval;
      n               = ucnt;
      value           = .;
      pct_total       = n / &_p6_total * 100;
      pct_nonmiss     = .;
      _so             = _so + 1;
      sort_order      = _so;
      if n >= 1 and n <= 10
        then small_cell_flag = 'Y';
        else small_cell_flag = 'N';
      date_kind       = '';
      display_format  = '';
      keep family variable var_class stat level n value pct_total pct_nonmiss
           sort_order small_cell_flag date_kind display_format;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_numtext level rows &_p6_ntr_vname);
    %if &p6_fail = 1 %then %return;

    proc append base=work._p6_rows data=work._p6_nt_lev_rows;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_numtext append &_p6_ntr_vname);
    %if &p6_fail = 1 %then %return;

    %let _p6_ntri = %eval(&_p6_ntri + 1);
  %end;

  %put NOTE: [06_profile] p6_numtext complete: &_p6_ntr_total NUM_TEXT variable(s) processed;

%mend p6_numtext;

/* ============================================================
   %p6_write_output
   1. Build work._p6_final from work._p6_rows (sorted).
   2. Validate in WORK (D-08 class-specific reconciliation,
      variable set check, schema check, integrity checks).
   3. Publish to &outlib..prf_&family only after all checks pass.
   4. Export UTF-8 CSV when export=1.
   Parameters:
     outlib= SAS libref to publish to (default blank -- set by %pdd_profile)
     family= Family label (e.g. PCNR)
     export= 1 to write exchange CSV; 0 to skip (test isolation)
   C26: no literal "pdd." -- use &outlib.
   ============================================================ */
%macro p6_write_output(outlib=, family=, export=1);
  %_p6_ok(section=p6_write_output entry);
  %if &p6_fail = 1 %then %return;

  /* ---- Step 1: Build work._p6_final sorted by variable, sort_order ---- */
  proc sort data=work._p6_rows out=work._p6_final;
    by variable sort_order;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output sort);
  %if &p6_fail = 1 %then %return;

  /* Apply schema attrib in a DATA step to lock column order/types/lengths */
  data work._p6_final;
    %_p6_attrib;
    set work._p6_final;
    family = upcase("&family");
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output schema attrib);
  %if &p6_fail = 1 %then %return;

  /* ---- Step 2: Validation ---- */

  /* --- D-08: class-specific reconciliation per variable --- */
  /* LOW_CARD:    sum(n where stat in ('LEVEL','MISSING')) = &_p6_total */
  /* HIGH_CARD:   sum(n where stat in ('LEVEL','OTHER','MISSING')) = &_p6_total */
  /*              count(LEVEL rows) = 10 */
  /*              N_DISTINCT n = n_distinct from classifier */
  /* CONT_NUM/DATE: n(N) + n(N_MISSING) = &_p6_total */
  /* SUPPRESSED:  n(N) + n(MISSING) = &_p6_total */
  /* NUM_TEXT:    n(N) + n(N_MISSING) + n(N_UNPARSED) = &_p6_total */
  /* D-07: single MISSING row, n = &_p6_total */

  /* Step 1: compute per-variable per-class sums */
  proc sql noprint;
    create table work._p6_recon_sums as
      select variable,
             var_class,
             sum(case when stat in ('LEVEL','MISSING')              then n else 0 end) as lc_sum,
             sum(case when stat in ('LEVEL','OTHER','MISSING')       then n else 0 end) as hc_sum,
             sum(case when stat='N'                                  then n else 0 end) as cn_n,
             sum(case when stat='N_MISSING'                          then n else 0 end) as cn_nmiss,
             sum(case when stat='N_UNPARSED'                         then n else 0 end) as nt_nunparsed,
             sum(case when stat='MISSING'                            then n else 0 end) as sup_miss,
             count(*)                                                                   as row_cnt,
             max(case when stat='MISSING' then n else 0 end)                            as miss_n
      from work._p6_final
      group by variable, var_class;
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output d08 recon sums);
  %if &p6_fail = 1 %then %return;

  /* Step 2: select failures using WHERE (aliases now safe to reference) */
  proc sql noprint;
    create table work._p6_recon_fail as
      select variable, var_class
      from work._p6_recon_sums
      where
        (var_class='LOW_CARD'
          and lc_sum ne &_p6_total
          and not (row_cnt=1 and miss_n=&_p6_total))
        or
        (var_class='HIGH_CARD'
          and hc_sum ne &_p6_total
          and not (row_cnt=1 and miss_n=&_p6_total))
        or
        (var_class in ('CONT_NUM','DATE')
          and (cn_n + cn_nmiss) ne &_p6_total
          and not (row_cnt=1 and miss_n=&_p6_total))
        or
        (var_class='SUPPRESSED'
          and (cn_n + sup_miss) ne &_p6_total)
        or
        (var_class='NUM_TEXT'
          and (cn_n + cn_nmiss + nt_nunparsed) ne &_p6_total);
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output d08 recon query);
  %if &p6_fail = 1 %then %return;

  %local _p6_recon_n;
  proc sql noprint;
    select count(*) into :_p6_recon_n trimmed
    from work._p6_recon_fail;
  quit;
  %if &_p6_recon_n > 0 %then %do;
    %local _p6_recon_vars;
    proc sql noprint;
      select variable into :_p6_recon_vars separated by ', '
      from work._p6_recon_fail(obs=5);
    quit;
    %p6_fail_out(msg=%str(D-08 reconciliation failed for &_p6_recon_n variable(s): &_p6_recon_vars [first 5 shown]));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] D-08 reconciliation passed for all variables;

  /* HIGH_CARD: count(LEVEL rows) = 10 per variable (unless D-07) */
  proc sql noprint;
    create table work._p6_hc_lev_fail as
      select variable
      from work._p6_final
      where var_class='HIGH_CARD'
      group by variable
      having count(case when stat='LEVEL' then 1 end) ne 10
         and max(case when stat='MISSING' then n else 0 end) ne &_p6_total;
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output hc level count check);
  %if &p6_fail = 1 %then %return;

  %local _p6_hclev_n;
  proc sql noprint;
    select count(*) into :_p6_hclev_n trimmed
    from work._p6_hc_lev_fail;
  quit;
  %if &_p6_hclev_n > 0 %then %do;
    %local _p6_hclev_vars;
    proc sql noprint;
      select variable into :_p6_hclev_vars separated by ', '
      from work._p6_hc_lev_fail(obs=5);
    quit;
    %p6_fail_out(msg=%str(HIGH_CARD LEVEL count not 10 for: &_p6_hclev_vars [first 5 shown]));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;

  /* HIGH_CARD: N_DISTINCT n = classifier n_distinct */
  proc sql noprint;
    create table work._p6_hc_nd_fail as
      select f.variable
      from (select variable, max(case when stat='N_DISTINCT' then n end) as nd_n
            from work._p6_final
            where var_class='HIGH_CARD'
            group by variable) as f
      inner join work._p6_vars as v on upcase(f.variable) = upcase(v.name)
      where f.nd_n ne v.n_distinct;
  quit;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output hc ndist vs classifier check);
  %if &p6_fail = 1 %then %return;

  %local _p6_hcnd_n;
  proc sql noprint;
    select count(*) into :_p6_hcnd_n trimmed
    from work._p6_hc_nd_fail;
  quit;
  %if &_p6_hcnd_n > 0 %then %do;
    %local _p6_hcnd_vars;
    proc sql noprint;
      select variable into :_p6_hcnd_vars separated by ', '
      from work._p6_hc_nd_fail(obs=5);
    quit;
    %p6_fail_out(msg=%str(HIGH_CARD N_DISTINCT mismatch vs classifier for: &_p6_hcnd_vars [first 5 shown]));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] HIGH_CARD level count and N_DISTINCT checks passed;

  /* --- Variable set check: distinct vars in output = work._p6_vars exactly --- */
  %local _p6_vset_n;
  proc sql noprint;
    select count(*) into :_p6_vset_n trimmed
    from work._p6_final;
  quit;
  %if &p6_fail = 1 %then %return;

  /* Count distinct output variables */
  %local _p6_out_nv;
  proc sql noprint;
    select count(distinct variable) into :_p6_out_nv trimmed
    from work._p6_final;
  quit;
  %if &p6_fail = 1 %then %return;

  %if &_p6_out_nv ne &_p6_nv %then %do;
    %p6_fail_out(msg=%str(Variable set check: output has &_p6_out_nv distinct variables but expected &_p6_nv));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;

  /* Check for extras (output vars not in _p6_vars) */
  %local _p6_extra_n;
  proc sql noprint;
    select count(*) into :_p6_extra_n trimmed
    from (select distinct variable from work._p6_final) as f
    where upcase(f.variable) not in (select upcase(name) from work._p6_vars);
  quit;
  %if &_p6_extra_n > 0 %then %do;
    %p6_fail_out(msg=%str(Variable set check: &_p6_extra_n output variable(s) not in work._p6_vars));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] Variable set check passed: &_p6_out_nv distinct variables;

  /* --- Schema check: 13 columns by name, type, length and varnum order --- */
  /* Locked schema (varnum order 1..13):
     1  family         char  32
     2  variable       char  (= &_p6_lvl_len, at least 32)
     3  var_class      char  12
     4  stat           char  12
     5  level          char  (= &_p6_lvl_len)
     6  n              num   8
     7  value          num   8
     8  pct_total      num   8
     9  pct_nonmiss    num   8
     10 sort_order     num   8
     11 small_cell_flag char  1
     12 date_kind      char  8
     13 display_format char  32                                           */

  data work._p6_schema_exp;
    length varnum 8 col_name $32 col_type $4;
    varnum=1;  col_name='family';           col_type='char'; output;
    varnum=2;  col_name='variable';         col_type='char'; output;
    varnum=3;  col_name='var_class';        col_type='char'; output;
    varnum=4;  col_name='stat';             col_type='char'; output;
    varnum=5;  col_name='level';            col_type='char'; output;
    varnum=6;  col_name='n';               col_type='num';  output;
    varnum=7;  col_name='value';            col_type='num';  output;
    varnum=8;  col_name='pct_total';        col_type='num';  output;
    varnum=9;  col_name='pct_nonmiss';      col_type='num';  output;
    varnum=10; col_name='sort_order';       col_type='num';  output;
    varnum=11; col_name='small_cell_flag';  col_type='char'; output;
    varnum=12; col_name='date_kind';        col_type='char'; output;
    varnum=13; col_name='display_format';   col_type='char'; output;
    stop;
  run;

  proc sql noprint;
    create table work._p6_schema_actual as
      select varnum, lowcase(strip(name)) as col_name, lowcase(strip(type)) as col_type
      from dictionary.columns
      where libname='WORK' and memname='_P6_FINAL'
      order by varnum;
  quit;

  %local _p6_schema_bad;
  proc sql noprint;
    select count(*) into :_p6_schema_bad trimmed
    from work._p6_schema_exp as e
    full join work._p6_schema_actual as a
      on e.varnum = a.varnum
    where e.col_name ne a.col_name
       or e.col_type ne a.col_type
       or (e.varnum is missing or a.varnum is missing);
  quit;
  %if &p6_fail = 1 %then %return;
  %if %bquote(&_p6_schema_bad) ne 0 and %bquote(&_p6_schema_bad) ne %bquote() %then %do;
    %p6_fail_out(msg=%str(Schema check: &_p6_schema_bad column(s) have wrong name/type/order in work._p6_final));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] Schema check passed: 13 columns with correct names/types/order;

  /* --- Integrity: no LEVEL row with blank variable --- */
  %local _p6_blank_var_n;
  proc sql noprint;
    select count(*) into :_p6_blank_var_n trimmed
    from work._p6_final
    where stat='LEVEL' and (variable='' or variable is missing);
  quit;
  %if &_p6_blank_var_n > 0 %then %do;
    %p6_fail_out(msg=%str(Integrity: &_p6_blank_var_n LEVEL row(s) with blank variable));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;

  /* --- Integrity: no duplicate (variable, sort_order) --- */
  %local _p6_dup_n;
  proc sql noprint;
    select count(*) into :_p6_dup_n trimmed
    from (select variable, sort_order, count(*) as cnt
          from work._p6_final
          group by variable, sort_order
          having cnt > 1);
  quit;
  %if &_p6_dup_n > 0 %then %do;
    %p6_fail_out(msg=%str(Integrity: &_p6_dup_n duplicate (variable, sort_order) combination(s)));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;

  /* --- Integrity: each variable carries exactly one var_class --- */
  %local _p6_mixvc_n;
  proc sql noprint;
    select count(*) into :_p6_mixvc_n trimmed
    from (select variable, count(distinct var_class) as nvc
          from work._p6_final
          group by variable
          having nvc > 1);
  quit;
  %if &_p6_mixvc_n > 0 %then %do;
    %p6_fail_out(msg=%str(Integrity: &_p6_mixvc_n variable(s) have mixed var_class values));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;

  %put NOTE: [06_profile] All integrity checks passed;

  /* ---- Step 3: Publish (only reached if all validations passed) ---- */
  data &outlib..prf_&family;
    set work._p6_final;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_write_output publish);
  %if &p6_fail = 1 %then %return;
  %put NOTE: [06_profile] Published &outlib..prf_&family (&_p6_vset_n rows, &_p6_out_nv variables);

  /* ---- Step 4: Export CSV (only when export=1) ---- */
  %if &export = 1 %then %do;
    filename _p6out "&exchange_path.\profile_&family..csv" encoding='utf-8';
    proc export data=work._p6_final
                outfile=_p6out
                dbms=csv
                replace;
    run;
    %if &syserr > 4 %then %do;
      %p6_fail_out(msg=%str(PROC EXPORT failed for profile_&family..csv syserr=&syserr));
      filename _p6out clear;
      %return;
    %end;
    %if %sysfunc(fexist(_p6out)) = 0 %then %do;
      %p6_fail_out(msg=%str(CSV not found after PROC EXPORT: &exchange_path.\profile_&family..csv));
      filename _p6out clear;
      %return;
    %end;
    filename _p6out clear;
    %put NOTE: [06_profile] Exported &exchange_path.\profile_&family..csv (UTF-8);
  %end;
  %else %do;
    %put NOTE: [06_profile] export=0 -- CSV export skipped;
  %end;

%mend p6_write_output;

/* ============================================================
   %pdd_profile   *** ENTRY POINT -- DEFINED LAST (C13) ***
   Chain: preflight -> classify_vars -> compute lvl_len ->
          init _p6_rows -> freq_lowcard -> stats_contnum ->
          freq_highcard -> write_output
   Parameters:
     lib=             SAS libref of source dataset
     ds=              Dataset name (no libref)
     prefix=          Variable prefix to profile (e.g. PCNR_)
     family=          Family label (e.g. PCNR)
     outlib=          Publish libref (default blank = &lib at runtime)
     export=          1 (default) = write exchange CSV; 0 = skip
     require_name_map= 1 (default) = require &lib..name_map for D-05
   Note on outlib default: cannot self-reference &lib in the default
   expression (Phase 5 recursive-default lesson).  Default is blank;
   assigned to &lib inside the macro when blank.
   C26: no literal "pdd." in macro body -- use &lib / &outlib.
   ============================================================ */
%macro pdd_profile(lib=, ds=, prefix=, family=, outlib=, export=1, require_name_map=1,
                   suppress_file=, num_text_threshold=0.95);

  /* ---- Rerun safety: delete any stale WORK._p6_* tables and reset globals ---- */
  %local _p6_stale_list;
  %let _p6_stale_list = ;
  proc sql noprint;
    select memname into :_p6_stale_list separated by ' '
    from dictionary.tables
    where libname='WORK' and memname like '_P6_%';
  quit;

  %local _p6_sname;
  %if %bquote(&_p6_stale_list) ne %bquote() %then %do;
    %let _p6_sname = 1;
    %do %while (%scan(&_p6_stale_list, &_p6_sname) ne );
      %local _p6_stale_ds;
      %let _p6_stale_ds = %scan(&_p6_stale_list, &_p6_sname);
      proc datasets lib=work nolist;
        delete &_p6_stale_ds;
      quit;
      %let _p6_sname = %eval(&_p6_sname + 1);
    %end;
  %end;

  %global p6_fail p6_fail_msg;
  %let p6_fail     = 0;
  %let p6_fail_msg = ;

  /* ---- Resolve outlib default ---- */
  %local _p6_outlib;
  %if %bquote(&outlib) = %bquote() %then
    %let _p6_outlib = &lib;
  %else
    %let _p6_outlib = &outlib;

  %put NOTE: [06_profile] pdd_profile starting: lib=&lib ds=&ds prefix=&prefix family=&family outlib=&_p6_outlib export=&export;

  /* ---- 1. Preflight ---- */
  %p6_preflight(lib=&lib, ds=&ds, require_name_map=&require_name_map);
  %if &p6_fail = 1 %then %return;

  /* ---- 2. Classify variables ---- */
  %p6_classify_vars(lib=&lib, ds=&ds, prefix=&prefix, family=&family, require_name_map=&require_name_map);
  %if &p6_fail = 1 %then %return;

  /* ---- 2b. D-09: load suppression list and override var_class=SUPPRESSED ---- */
  %if %bquote(&suppress_file) ne %bquote() %then %do;
    /* Load suppress list from CSV (must have variable,reason columns) */
    proc import datafile="&suppress_file"
                out=work._p6_suppress_raw
                dbms=csv replace;
      getnames=yes;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=pdd_profile suppress load);
    %if &p6_fail = 1 %then %return;

    /* Validate: every listed variable must exist in the dataset (prefix-matched vars) */
    %local _p6_sup_bad_n;
    proc sql noprint;
      select count(*) into :_p6_sup_bad_n trimmed
      from work._p6_suppress_raw
      where upcase(strip(variable)) not in (select upcase(name) from work._p6_vars);
    quit;
    %if &p6_fail = 1 %then %return;
    %if &_p6_sup_bad_n > 0 %then %do;
      %local _p6_sup_bad_vars;
      proc sql noprint;
        select strip(variable) into :_p6_sup_bad_vars separated by ', '
        from work._p6_suppress_raw
        where upcase(strip(variable)) not in (select upcase(name) from work._p6_vars);
      quit;
      %p6_fail_out(msg=%str(suppress_file lists &_p6_sup_bad_n variable(s) not in &lib..&ds: &_p6_sup_bad_vars));
      %return;
    %end;
    %if &p6_fail = 1 %then %return;

    /* Override var_class to SUPPRESSED for listed variables */
    proc sql noprint;
      update work._p6_vars
      set var_class = 'SUPPRESSED'
      where upcase(name) in (select upcase(strip(variable)) from work._p6_suppress_raw);
    quit;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=pdd_profile suppress reclassify);
    %if &p6_fail = 1 %then %return;

    %local _p6_sup_n_log;
    proc sql noprint;
      select count(*) into :_p6_sup_n_log trimmed
      from work._p6_vars where var_class='SUPPRESSED';
    quit;
    %put NOTE: [06_profile] D-09: &_p6_sup_n_log SUPPRESSED variable(s) loaded from suppress_file;
  %end;

  /* ---- 3. Compute &_p6_lvl_len = max(64, max char length), capped at 32767 ---- */
  %global _p6_lvl_len;
  %local _p6_max_char_len;
  proc sql noprint;
    select max(length) into :_p6_max_char_len trimmed
    from work._p6_vars
    where type='char';
  quit;
  %if &p6_fail = 1 %then %return;

  %if %bquote(&_p6_max_char_len) = %bquote() %then
    %let _p6_lvl_len = 64;
  %else %if &_p6_max_char_len > 32767 %then
    %let _p6_lvl_len = 32767;
  %else %if &_p6_max_char_len < 64 %then
    %let _p6_lvl_len = 64;
  %else
    %let _p6_lvl_len = &_p6_max_char_len;
  %put NOTE: [06_profile] _p6_lvl_len=&_p6_lvl_len (max char var length=&_p6_max_char_len, floor 64, cap 32767);

  /* ---- 4. Initialise empty work._p6_rows with the schema (DATA step with stop;) ---- */
  data work._p6_rows;
    %_p6_attrib;
    call missing(of _all_);
    stop;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=pdd_profile init _p6_rows);
  %if &p6_fail = 1 %then %return;

  /* ---- 5. LOW_CARD frequency ---- */
  %p6_freq_lowcard(lib=&lib, ds=&ds);
  %if &p6_fail = 1 %then %return;

  /* ---- 6. CONT_NUM / DATE statistics ---- */
  %p6_stats_contnum(lib=&lib, ds=&ds);
  %if &p6_fail = 1 %then %return;

  /* ---- 6b. D-10: Numeric text reclassification BEFORE HIGH_CARD rows are built ---- */
  /* %p6_numtext counts parse rates and updates var_class in work._p6_vars;           */
  /* %p6_freq_highcard then sees NUM_TEXT vars as non-HIGH_CARD and skips them.        */
  %p6_numtext(lib=&lib, ds=&ds, num_text_threshold=&num_text_threshold);
  %if &p6_fail = 1 %then %return;

  /* ---- 7. HIGH_CARD frequency ---- */
  %p6_freq_highcard(lib=&lib, ds=&ds);
  %if &p6_fail = 1 %then %return;

  /* ---- 7c. D-09: Suppressed variable stat rows ---- */
  %p6_suppressed(lib=&lib, ds=&ds);
  %if &p6_fail = 1 %then %return;

  /* ---- 8. Validate, publish, export ---- */
  %p6_write_output(outlib=&_p6_outlib, family=&family, export=&export);
  %if &p6_fail = 1 %then %return;

  /* Log pass structure for auditability (not a dynamic counter -- design time).    */
  /* Full-table passes over &lib..&ds per profile call:                            */
  /*   NLEVELS: ceil(n_vars / 100) PROC FREQ batches (~1 per 100 vars)            */
  /*   CONT_NUM/DATE: 1 PROC MEANS pass                                           */
  /*   LOW_CARD: ceil(n_lc / 100) PROC FREQ batches                              */
  /*   HIGH_CARD: ceil(n_hc / 100) PROC FREQ batches                             */
  /*   NUM_TEXT count: 1 DATA step (all candidates, keep= list, one pass)         */
  /*   NUM_TEXT parsed+unparsed: 1 DATA step (all NUM_TEXT vars, one pass)        */
  /*   SUPPRESSED: 1 DATA step (all SUPPRESSED vars, one pass)                   */
  /* Total for typical PCNR run: ~13 NLEVELS + 1 contnum + LC batches + HC batches*/
  /*   + 2 numtext + 1 suppressed.  No loop multiplies passes by variable count.  */
  %put NOTE: [06_profile] pdd_profile complete for family=&family -- pass structure: NLEVELS-batched CONTNUM-1 LC-batched HC-batched NUMTEXT-2 SUPPRESSED-1 (no per-variable source scans);

%mend pdd_profile;
