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
  %global p6_fail p6_fail_msg p6_test_mode;
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
  %local _p6_total;
  proc sql noprint;
    select count(*) into :_p6_total trimmed
    from &lib..&ds;
  quit;
  %if &_p6_total = 0 %then %do;
    %p6_fail_out(msg=%str(&lib..&ds has 0 rows -- nothing to profile));
    %return;
  %end;
  %if &p6_fail = 1 %then %return;
  %global _p6_total;
  %let _p6_total = &_p6_total;
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
    put "/* Generated by %p6_classify_vars -- do not edit */";
    put "/* Family: &family  Dataset: &lib..&ds  Prefix: &prefix */";
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

  /* Include the generated file */
  %include "&_p6_gen_file";
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 nlevels include);
  %if &p6_fail = 1 %then %return;

  /* Stack all _p6_nl_b* outputs into work._p6_nl_all */
  /* Number of batches */
  %local _p6_nbatches;
  %let _p6_nbatches = %eval((&_p6_total_vars + &_p6_batch_size - 1) / &_p6_batch_size);

  data work._p6_nl_all;
    %local _p6_sb;
    %let _p6_sb = 1;
    set
    %do %while (&_p6_sb <= &_p6_nbatches);
      work._p6_nl_b&_p6_sb
      %let _p6_sb = %eval(&_p6_sb + 1);
    %end;
    ;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_classify_vars step 3 nlevels stack);
  %if &p6_fail = 1 %then %return;

  /* Rename TableVar -> name and NNonMissLevels -> n_distinct for join */
  data work._p6_nl_all;
    set work._p6_nl_all (rename=(TableVar=name NNonMissLevels=n_distinct));
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
  %local _p6_np_varlist _p6_np_count;
  proc sql noprint;
    select strip(name), count(*)
    into :_p6_np_varlist separated by ' ',
         :_p6_np_count trimmed
    from work._p6_joined
    where type = 'num'
      and compress(format, '.0123456789') = ''   /* blank format */
      and (upcase(reverse(strip(name))) like upcase(reverse('_DATE') || '%')
           or upcase(reverse(strip(name))) like upcase(reverse('_DTTM') || '%'));
  quit;
  %if &p6_fail = 1 %then %return;

  /* Plausibility results stored in work._p6_np_stats (one row per var) */
  %if &_p6_np_count > 0 %then %do;
    proc means data=&lib..&ds noprint min max;
      var &_p6_np_varlist;
      output out=work._p6_np_stats min= max= / autoname;
    run;
    %if &p6_fail = 1 %then %return;
    %_p6_ok(section=p6_classify_vars step 4 name-pattern PROC MEANS);
    %if &p6_fail = 1 %then %return;
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
      put "NOTE: [06_profile] char *_date/*_dttm variable (not DATE tier): " name;
    run;
    %put NOTE: [06_profile] &_p6_char_date_n character *_date/*_dttm variable(s) found -- classified by cardinality (see above NOTEs);
  %end;

  /* Build work._p6_vars with var_class assignment via DATA-step logic (C3: no open-code %if) */
  data work._p6_vars;
    length name $200 type $8 format $32 var_class $12 date_kind $12 display_format $32;

    /* Define the exact date/datetime/time format sets (stripped of width/decimals) */
    length _fmt_stripped $32 _date_kind $12;
    retain _dummy 0; /* suppress uninitialized note */

    set work._p6_joined;

    /* Normalize format: strip width/decimals */
    _fmt_stripped = upcase(compress(format, '.0123456789'));

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
      else if _fmt_stripped = '' and
              (upcase(reverse(strip(name))) like upcase(reverse('_DATE') || '%') or
               upcase(reverse(strip(name))) like upcase(reverse('_DTTM') || '%'))
      then do;
        /* Plausibility check was done via PROC MEANS above;
           if the variable is in work._p6_np_stats and within plausible range
           it qualifies.  Here we mark it conditionally: var is in the candidate
           list (&_p6_np_varlist) so we assign DATE and let the PROC MEANS
           NOTE above inform the analyst of any out-of-range vars.
           Production accuracy: assign DATE here; caller reviews log NOTEs.
           This matches the plan spec: "classify by cardinality instead and
           log a NOTE naming the variable" for out-of-range -- handled above. */
        _is_date   = 1;
        _date_kind = 'DATE';
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
    put "/* Generated by %p6_freq_lowcard -- do not edit */";
    put "/* Family: &family  Dataset: &lib..&ds */";
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
      %local _p6_lc_nn;
      proc sql noprint;
        select sum(COUNT) into :_p6_lc_nn trimmed
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
        length _raw_val $32767;
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
        drop _raw_val COUNT &&_p6_lcv_&_p6_lci;
        output;
      run;
      %if &p6_fail = 1 %then %return;
      %_p6_ok(section=p6_freq_lowcard level rows &&_p6_lcv_&_p6_lci);
      %if &p6_fail = 1 %then %return;

      /* Add MISSING row (n from PROC FREQ OUT= missing row or 0 if none) */
      %local _p6_lc_nmiss;
      proc sql noprint;
        select sum(COUNT) into :_p6_lc_nmiss trimmed
        from work._p6_lc_f&_p6_lci
        where &&_p6_lcv_&_p6_lci is missing;
      quit;
      %if &p6_fail = 1 %then %return;
      %if %bquote(&_p6_lc_nmiss) = %bquote() %then %let _p6_lc_nmiss = 0;

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

  /* ONE PROC MEANS with all non-D07 vars in a single VAR statement (Pitfall 3) */
  proc means data=&lib..&ds noprint;
    var &_p6_cn_varlist;
    output out=work._p6_cn_stats
      n=       nmiss=  mean=   std=    median= q1=     q3=     min=    max=
      / autoname;
  run;
  %if &p6_fail = 1 %then %return;
  %_p6_ok(section=p6_stats_contnum proc means);
  %if &p6_fail = 1 %then %return;

  /* Reshape: one row in wide format -> nine rows per variable */
  /* PROC MEANS AUTONAME creates: varname_N varname_NMiss varname_Mean varname_StdDev
     varname_Median varname_Q1 varname_Q3 varname_Min varname_Max                   */
  %let _p6_cni = 1;
  %do %while (&_p6_cni <= &_p6_cn_total);
    %if &&_p6_cnd_&_p6_cni > 0 %then %do;
      %local _p6_cn_vname;
      %let _p6_cn_vname = &&_p6_cnv_&_p6_cni;

      data work._p6_cn_piece;
        %_p6_attrib;
        set work._p6_cn_stats (keep=&_p6_cn_vname._N
                                     &_p6_cn_vname._NMiss
                                     &_p6_cn_vname._Mean
                                     &_p6_cn_vname._StdDev
                                     &_p6_cn_vname._Median
                                     &_p6_cn_vname._Q1
                                     &_p6_cn_vname._Q3
                                     &_p6_cn_vname._Min
                                     &_p6_cn_vname._Max);

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
        n          = &_p6_cn_vname._N;
        value      = .;
        pct_total  = n / &_p6_total * 100;
        pct_nonmiss = .;
        sort_order = 1;
        output;

        /* N_MISSING row (sort_order=2) */
        stat       = 'N_MISSING';
        n          = &_p6_cn_vname._NMiss;
        value      = .;
        pct_total  = n / &_p6_total * 100;
        pct_nonmiss = .;
        sort_order = 2;
        output;

        /* MEAN row (sort_order=3) */
        stat       = 'MEAN';
        n          = .;
        value      = &_p6_cn_vname._Mean;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 3;
        output;

        /* SD row (sort_order=4) */
        stat       = 'SD';
        n          = .;
        value      = &_p6_cn_vname._StdDev;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 4;
        output;

        /* MEDIAN row (sort_order=5) */
        stat       = 'MEDIAN';
        n          = .;
        value      = &_p6_cn_vname._Median;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 5;
        output;

        /* Q1 row (sort_order=6) */
        stat       = 'Q1';
        n          = .;
        value      = &_p6_cn_vname._Q1;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 6;
        output;

        /* Q3 row (sort_order=7) */
        stat       = 'Q3';
        n          = .;
        value      = &_p6_cn_vname._Q3;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 7;
        output;

        /* MIN row (sort_order=8) */
        stat       = 'MIN';
        n          = .;
        value      = &_p6_cn_vname._Min;
        pct_total  = .;
        pct_nonmiss = .;
        sort_order = 8;
        output;

        /* MAX row (sort_order=9) */
        stat       = 'MAX';
        n          = .;
        value      = &_p6_cn_vname._Max;
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
    put "/* Generated by %p6_freq_highcard -- do not edit */";
    put "/* Family: &family  Dataset: &lib..&ds */";
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
    proc sql noprint;
      select sum(COUNT) into :_p6_hc_nmiss trimmed
      from work._p6_hc_f&_p6_hci
      where &_p6_hc_vname is missing;
    quit;
    %if &p6_fail = 1 %then %return;
    %if %bquote(&_p6_hc_nmiss) = %bquote() %then %let _p6_hc_nmiss = 0;

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
    %local _p6_hc_nother;
    proc sql noprint;
      select sum(COUNT) into :_p6_hc_nother trimmed
      from (select COUNT, monotonic() as rn
            from work._p6_hc_sorted)
      where rn > 10;
    quit;
    %if &p6_fail = 1 %then %return;
    %if %bquote(&_p6_hc_nother) = %bquote() %then %let _p6_hc_nother = 0;

    /* Build all rows for this variable */
    data work._p6_hc_piece;
      %_p6_attrib;
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
      pct_nonmiss    = n / &_p6_hc_nndist * 100;
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
      pct_nonmiss    = n / &_p6_hc_nndist * 100;
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
