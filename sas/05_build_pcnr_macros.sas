/*==========================================================================
  Program : 05_build_pcnr_macros.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Macro library for Phase 5 -- Build PCNR_ on the spine.
            Section 0 defines all macros; subsequent sections call them.
            Plans 03, 04, 05 append macros to this file in order.

  Macros (Plan 03):
    %fail_out            -- hard stop with ERROR
    %_p5_ok              -- section guard (obs=0 / syserr > 4)
    %assert_rowcount     -- exact row count assertion
    %route_log           -- redirect log when running standalone
    %restore_log         -- restore log after standalone run
    %p5_preflight        -- D-18 assertion, spine key quality, SHA-256,
                            priority/override file validation
    %p5_spine_coverage   -- D-19 extended spine coverage QC
    %p5_resolve_types    -- D-02 type-conflict resolution

  Author  :
  Notes   : PCM compliance: C1 C2 C3 C9 C11 C13 C14.
            %include "sas/00_config.sas" must be called before this file.
==========================================================================*/

/* ============================================================
   SECTION 0 -- %include, %pdd_lib, ALL macro definitions
   All macros defined here before any call (PCM C13).
   ============================================================ */

%include "&sas_path.\00_config.sas";
%pdd_lib;

/* Hard stop with loud ERROR */
%macro fail_out(msg=);
  %put ERROR: [05_build_pcnr] &msg;
  %abort cancel;
%mend fail_out;

/* Fail-fast at start of each section: catches obs=0/syserr from the prior section */
%macro _p5_ok(section=);
  %if %sysfunc(getoption(obs)) = 0 %then %do;
    %fail_out(msg=%str(SAS in obs=0/syntax-check mode entering Section &section -- prior section had an error));
  %end;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(syserr=&syserr entering Section &section -- prior section had an error));
  %end;
%mend _p5_ok;

/* Check pdd library after fail_out is compiled */
%check_pdd_lib;

/* Route log to per-program file when running standalone */
%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\05_build_pcnr.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* Assert exact row count; %fail_out if wrong.
   Parameters: ds= dataset, expected= count, label= description */
%macro assert_rowcount(ds=, expected=, label=);
  %local _arc_n;
  proc sql noprint;
    select count(*) into :_arc_n trimmed
    from &ds;
  quit;
  %if &_arc_n ne &expected %then %do;
    %fail_out(msg=%str(&label row count=&_arc_n expected=&expected));
  %end;
  %put NOTE: [05_build_pcnr] assert_rowcount OK: &label rows=&_arc_n;
%mend assert_rowcount;

/* ============================================================
   %p5_preflight
   D-18 s04/s05 assertion, spine key quality, SHA-256 hash
   logging of name_map.csv, priority/override file validation.
   DEFINE ONLY -- called from Section 1 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_preflight;

  /* ---- A. name_map assertions ---- */

  /* A1. Exact row count of name_map_vars */
  %assert_rowcount(ds=pdd.name_map_vars, expected=1299, label=name_map_vars);

  /* A2. D-18: s04/s05 must contribute 0 PCNR rows to name_map.
         pdd.name_map (not name_map_vars) carries s_code. */
  %local _n_linkage_pcnr;
  proc sql noprint;
    select count(*) into :_n_linkage_pcnr trimmed
    from pdd.name_map
    where s_code in ('s04', 's05')
      and status = 'PCNR';
  quit;
  %if &_n_linkage_pcnr > 0 %then %do;
    %fail_out(msg=%str(D-18 violated: &_n_linkage_pcnr rows in pdd.name_map have s_code in (s04 s05) and status=PCNR));
  %end;
  %put NOTE: [05_build_pcnr] D-18 s04/s05 contribute 0 PCNR rows (passed);

  /* ---- B. SHA-256 + row counts ---- */

  /* B1. SHA-256 of exchange\name_map.csv via certutil */
  filename _nmhash pipe "certutil -hashfile ""&exchange_path.\name_map.csv"" SHA256";
  data _null_;
    infile _nmhash;
    input;
    put "NOTE: [05_build_pcnr] name_map.csv SHA256= " _infile_;
  run;
  filename _nmhash clear;

  /* B2. Row counts for traceability */
  %local _n_nm _n_nmv;
  proc sql noprint;
    select count(*) into :_n_nm trimmed from pdd.name_map;
  quit;
  proc sql noprint;
    select count(*) into :_n_nmv trimmed from pdd.name_map_vars;
  quit;
  %put NOTE: [05_build_pcnr] pdd.name_map rows=&_n_nm pdd.name_map_vars rows=&_n_nmv;

  /* ---- C. Source file checks ---- */

  /* C1. Spine row count and key quality */
  %assert_rowcount(ds=pdd.src_s09, expected=41150, label=spine pdd.src_s09);

  %local _n_blank_spine;
  proc sql noprint;
    select count(*) into :_n_blank_spine trimmed
    from pdd.src_s09
    where norm_psid = '';
  quit;
  %if &_n_blank_spine > 0 %then %do;
    %fail_out(msg=%str(spine has &_n_blank_spine blank norm_psid values));
  %end;
  %put NOTE: [05_build_pcnr] spine blank norm_psid check passed (0 blank);

  %local _n_all_spine _n_dis_spine;
  proc sql noprint;
    select count(*) into :_n_all_spine trimmed from pdd.src_s09;
    select count(distinct norm_psid) into :_n_dis_spine trimmed from pdd.src_s09;
  quit;
  %if &_n_all_spine ne &_n_dis_spine %then %do;
    %fail_out(msg=%str(spine has duplicate norm_psid: total=&_n_all_spine distinct=&_n_dis_spine));
  %end;
  %put NOTE: [05_build_pcnr] spine duplicate norm_psid check passed (&_n_dis_spine unique keys);

  /* C2. Per-source key quality for all 20 sources.
         Check each pdd.src_s* that has contributing PCNR rows:
         report n_blank_keys; fail if duplicate non-blank norm_psid. */
  %local _sc _i _src_exist _n_pcnr_src _n_nonblank _n_dis_nonblank
         _n_blank_keys;
  %do _i = 1 %to 20;
    /* Build zero-padded s_code: s01..s20 */
    %if &_i < 10 %then %let _sc = s0&_i;
    %else %let _sc = s&_i;

    /* Skip spine -- already checked above */
    %if &_sc = s09 %then %goto next_source;

    /* Check dataset exists */
    %let _src_exist = %sysfunc(exist(pdd.src_&_sc));
    %if &_src_exist = 0 %then %do;
      %put NOTE: [05_build_pcnr] pdd.src_&_sc not found -- skipping key quality check;
      %goto next_source;
    %end;

    /* Check whether this source contributes any PCNR rows */
    %let _n_pcnr_src = 0;
    proc sql noprint;
      select count(*) into :_n_pcnr_src trimmed
      from pdd.name_map
      where s_code = "&_sc"
        and status = 'PCNR';
    quit;
    %if &_n_pcnr_src = 0 %then %do;
      %put NOTE: [05_build_pcnr] &_sc contributes 0 PCNR rows -- key quality check skipped;
      %goto next_source;
    %end;

    /* Report n_blank_keys */
    %let _n_blank_keys = 0;
    proc sql noprint;
      select count(*) into :_n_blank_keys trimmed
      from pdd.src_&_sc
      where norm_psid = '';
    quit;
    %put NOTE: [05_build_pcnr] SOURCE &_sc n_blank_keys=&_n_blank_keys;

    /* Assert 0 duplicate non-blank norm_psid */
    %let _n_nonblank = 0;
    %let _n_dis_nonblank = 0;
    proc sql noprint;
      select count(*) into :_n_nonblank trimmed
      from pdd.src_&_sc
      where norm_psid ne '';
      select count(distinct norm_psid) into :_n_dis_nonblank trimmed
      from pdd.src_&_sc
      where norm_psid ne '';
    quit;
    %if &_n_nonblank ne &_n_dis_nonblank %then %do;
      %fail_out(msg=%str(source &_sc has duplicate non-blank norm_psid: n_nonblank=&_n_nonblank n_distinct=&_n_dis_nonblank));
    %end;

    %next_source:
  %end;
  %put NOTE: [05_build_pcnr] per-source key quality checks complete;

  /* ---- D. Docs file validation -- priority and override CSVs ---- */

  /* D1. Priority file */
  %local _prio_path;
  %let _prio_path = &sas_path.\..\docs\pcnr_source_priority.csv;
  %if not %sysfunc(fileexist(&_prio_path)) %then %do;
    %fail_out(msg=%str(priority CSV missing: &_prio_path));
  %end;

  data work._priority;
    length s_code $4 rank 8 note $40;
    infile "&sas_path.\..\docs\pcnr_source_priority.csv"
           encoding='utf-8' dsd dlm=',' missover firstobs=2;
    input s_code $ rank note $;
    s_code = strip(s_code);
    note   = strip(note);
    if s_code = '' then delete;
  run;

  %assert_rowcount(ds=work._priority, expected=20, label=priority);

  /* Assert ranks form a permutation of 1..20 */
  %local _n_valid_ranks _n_dis_ranks;
  proc sql noprint;
    select count(*) into :_n_valid_ranks trimmed
    from work._priority
    where rank between 1 and 20;
    select count(distinct rank) into :_n_dis_ranks trimmed
    from work._priority;
  quit;
  %if &_n_valid_ranks ne 20 %then %do;
    %fail_out(msg=%str(priority ranks not a permutation of 1..20: &_n_valid_ranks rows have rank in [1,20]));
  %end;
  %if &_n_dis_ranks ne 20 %then %do;
    %fail_out(msg=%str(priority ranks not a permutation of 1..20: only &_n_dis_ranks distinct ranks));
  %end;
  %put NOTE: [05_build_pcnr] priority ranks are a valid permutation of 1..20;

  /* Assert s09 note = 'spine' */
  %local _s09note;
  proc sql noprint;
    select note into :_s09note trimmed
    from work._priority
    where s_code = 's09';
  quit;
  %if "%strip(&_s09note)" ne "spine" %then %do;
    %fail_out(msg=%str(priority s09 note is not spine -- found: &_s09note));
  %end;
  %put NOTE: [05_build_pcnr] priority s09 note=spine confirmed;

  /* Sort priority by rank for use in coverage/build loops */
  proc sort data=work._priority out=work._priority;
    by rank;
  run;

  /* D2. Override file */
  %local _override_path;
  %let _override_path = &sas_path.\..\docs\pcnr_source_override.csv;
  %if not %sysfunc(fileexist(&_override_path)) %then %do;
    %fail_out(msg=%str(override CSV missing: &_override_path));
  %end;

  data work._override;
    length pcnr_name $200 s_code $4;
    infile "&sas_path.\..\docs\pcnr_source_override.csv"
           encoding='utf-8' dsd dlm=',' missover firstobs=2;
    input pcnr_name $ s_code $;
    pcnr_name = strip(pcnr_name);
    s_code    = strip(s_code);
    if pcnr_name = '' then delete;
  run;

  /* Assert 0 duplicate pcnr_name in override */
  %local _n_ov _n_ov_dis;
  proc sql noprint;
    select count(*) into :_n_ov trimmed from work._override;
    select count(distinct pcnr_name) into :_n_ov_dis trimmed from work._override;
  quit;
  %if &_n_ov ne &_n_ov_dis %then %do;
    %fail_out(msg=%str(override has duplicate pcnr_name: n=&_n_ov distinct=&_n_ov_dis));
  %end;
  %put NOTE: [05_build_pcnr] override pcnr_name uniqueness OK (rows=&_n_ov);

  /* Assert no override pins to spine (s09 not allowed as override source) */
  %local _n_pin_spine;
  proc sql noprint;
    select count(*) into :_n_pin_spine trimmed
    from work._override
    where s_code = 's09';
  quit;
  %if &_n_pin_spine > 0 %then %do;
    %fail_out(msg=%str(override pins to spine (s_code=s09) -- not allowed; &_n_pin_spine rows));
  %end;
  %put NOTE: [05_build_pcnr] override s09 guard passed;

  /* Assert each override (pcnr_name, s_code) pair exists in pdd.name_map with status='PCNR'.
     Only run check when override file is non-empty. */
  %if &_n_ov > 0 %then %do;
    %local _n_bad_pin;
    proc sql noprint;
      select count(*) into :_n_bad_pin trimmed
      from work._override as ov
      where not exists (
        select 1 from pdd.name_map as nm
        where nm.pcnr_name = ov.pcnr_name
          and nm.s_code    = ov.s_code
          and nm.status    = 'PCNR'
      );
    quit;
    %if &_n_bad_pin > 0 %then %do;
      %fail_out(msg=%str(override references s_code not contributing to that pcnr_name: &_n_bad_pin bad rows));
    %end;
    %put NOTE: [05_build_pcnr] override foreign-key check passed;
  %end;
  %else %do;
    %put NOTE: [05_build_pcnr] override file is empty (header-only) -- no override pins active;
  %end;

  /* ---- E. Load work._nmv ---- */
  data work._nmv;
    set pdd.name_map_vars;
  run;

  %put NOTE: [05_build_pcnr] %p5_preflight complete;

%mend p5_preflight;

/* ============================================================
   %p5_spine_coverage  (Plan 03 Task 2 -- appended below)
   ============================================================ */

%macro p5_spine_coverage;

  /* Loop over work._priority rows in rank order, skipping spine (s09).
     For each non-spine source compute:
       n_keys              = count(distinct norm_psid) where norm_psid ne ''
       n_keys_not_in_spine = count where norm_psid ne '' and not in spine
       n_blank_keys        = count where norm_psid = ''
       n_dup_keys          = total non-blank - distinct non-blank
     Accumulate into work._spine_coverage; emit NOTE per source.
  */

  %local _n_prio _i _sc _nk _nnis _nb _nd;

  /* Get number of priority rows */
  proc sql noprint;
    select count(*) into :_n_prio trimmed from work._priority;
  quit;

  /* Create empty accumulator */
  data work._spine_coverage;
    length s_code $4 n_keys 8 n_keys_not_in_spine 8 n_blank_keys 8 n_dup_keys 8;
    stop;
  run;

  %do _i = 1 %to &_n_prio;

    /* Read s_code for this rank position */
    %let _sc = ;
    proc sql noprint;
      select s_code into :_sc trimmed
      from work._priority (firstobs=&_i obs=&_i);
    quit;

    /* Skip spine */
    %if &_sc = s09 %then %goto next_cov;

    /* Check dataset exists */
    %if %sysfunc(exist(pdd.src_&_sc)) = 0 %then %do;
      %put NOTE: [05_build_pcnr] SOURCE &_sc: dataset pdd.src_&_sc not found -- skipped in coverage;
      %goto next_cov;
    %end;

    /* Compute coverage metrics */
    %let _nk   = 0;
    %let _nnis = 0;
    %let _nb   = 0;
    %let _nd   = 0;

    proc sql noprint;
      select count(distinct norm_psid) into :_nk trimmed
      from pdd.src_&_sc
      where norm_psid ne '';

      select count(*) into :_nnis trimmed
      from pdd.src_&_sc
      where norm_psid ne ''
        and norm_psid not in (
          select norm_psid from pdd.src_s09 where norm_psid ne ''
        );

      select count(*) into :_nb trimmed
      from pdd.src_&_sc
      where norm_psid = '';

      select (count(norm_psid) - count(distinct norm_psid)) into :_nd trimmed
      from pdd.src_&_sc
      where norm_psid ne '';
    quit;

    %put NOTE: [05_build_pcnr] SOURCE &_sc: &_nnis of &_nk keys not in spine; n_blank=&_nb; n_dup=&_nd;

    /* Append to accumulator */
    data work._cov_row;
      length s_code $4 n_keys 8 n_keys_not_in_spine 8 n_blank_keys 8 n_dup_keys 8;
      s_code              = "&_sc";
      n_keys              = &_nk;
      n_keys_not_in_spine = &_nnis;
      n_blank_keys        = &_nb;
      n_dup_keys          = &_nd;
    run;

    proc append base=work._spine_coverage data=work._cov_row force; run;

    %next_cov:
  %end;

  /* Export coverage CSV to exchange */
  proc export data=work._spine_coverage
    outfile="&exchange_path.\pcnr_spine_coverage.csv"
    dbms=csv replace;
  run;

  %put NOTE: [05_build_pcnr] pcnr_spine_coverage.csv written to exchange;

%mend p5_spine_coverage;

/* ============================================================
   %p5_resolve_types
   D-02 type-conflict resolution before the build loop.
   Outputs: work._type_resolution (key-unique on pcnr_name),
            work._typecheck_sources (key-unique on pcnr_name+s_code),
            pdd.qc_pcnr_typefail (pcnr_name, s_code, raw_value, n),
            exchange\pcnr_typecheck.csv.
   DEFINE ONLY -- called from Section 1 of 05_build_pcnr.sas.
   ============================================================ */

%macro p5_resolve_types;

  /* Step 1. Select type-conflict variables from work._nmv.
             Do NOT hard-code the 9 names -- read from dataset. */
  %local _n_tc;

  data work._tc_vars;
    set work._nmv (where=(type_conflict = 'Y'));
    keep pcnr_name max_length s_codes_contributing;
  run;

  proc sql noprint;
    select count(*) into :_n_tc trimmed from work._tc_vars;
  quit;
  %put NOTE: [05_build_pcnr] type_conflict variables found: &_n_tc;

  /* Create empty output datasets */
  data work._type_resolution;
    length pcnr_name $200 resolved_type $8 out_length 8;
    stop;
  run;

  data work._typecheck_sources;
    length pcnr_name $200 s_code $4 n_char_sources 8 n_parse_failures 8
           example_failing_value $200;
    stop;
  run;

  data pdd.qc_pcnr_typefail;
    length pcnr_name $200 s_code $4 raw_value $200 n 8;
    stop;
  run;

  /* Step 2-8. Loop over each type-conflict variable */
  %local _tc_i _tc_name _tc_maxlen _tc_sc_list;
  %local _n_tc_rows;

  proc sql noprint;
    select count(*) into :_n_tc_rows trimmed from work._tc_vars;
  quit;

  %do _tc_i = 1 %to &_n_tc_rows;

    /* Read pcnr_name and max_length for this conflict variable */
    %let _tc_name   = ;
    %let _tc_maxlen = 0;
    proc sql noprint;
      select pcnr_name, max_length
      into :_tc_name trimmed, :_tc_maxlen trimmed
      from work._tc_vars (firstobs=&_tc_i obs=&_tc_i);
    quit;

    /* Step 2. Find contributing (s_code, col_name) pairs from pdd.name_map */
    data work._tc_sources_&_tc_i;
      length pcnr_name $200 s_code $4 col_name $200;
      stop;
    run;

    proc sql noprint;
      insert into work._tc_sources_&_tc_i (pcnr_name, s_code, col_name)
      select pcnr_name, s_code, col_name
      from pdd.name_map
      where pcnr_name = "&_tc_name"
        and status    = 'PCNR';
    quit;

    /* Step 3. For each contributing source, test parse of character values */
    %local _n_tc_src _sc_j _col_j _src_type _n_fail _ex_fail _n_char_src_total
           _n_fail_total _n_numlen_max;
    %let _n_char_src_total = 0;
    %let _n_fail_total     = 0;
    %let _n_numlen_max     = 0;

    proc sql noprint;
      select count(*) into :_n_tc_src trimmed from work._tc_sources_&_tc_i;
    quit;

    %local _k;
    %do _k = 1 %to &_n_tc_src;

      %let _sc_j  = ;
      %let _col_j = ;
      proc sql noprint;
        select s_code, col_name
        into :_sc_j trimmed, :_col_j trimmed
        from work._tc_sources_&_tc_i (firstobs=&_k obs=&_k);
      quit;

      /* Check source dataset exists */
      %if %sysfunc(exist(pdd.src_&_sc_j)) = 0 %then %do;
        %put NOTE: [05_build_pcnr] pdd.src_&_sc_j not found -- skipped for type check of &_tc_name;
        %goto next_tc_src;
      %end;

      /* Determine storage type of this column in pdd.src_&_sc_j */
      %let _src_type = ;
      proc sql noprint;
        select type into :_src_type trimmed
        from dictionary.columns
        where libname = 'PDD'
          and memname = upcase("SRC_&_sc_j")
          and name    = upcase("&_col_j");
      quit;

      /* If column is numeric: track max length of put(x, best32.) for C-resolve fallback */
      %if &_src_type = num %then %do;
        %local _numlen_this;
        %let _numlen_this = 0;
        proc sql noprint;
          select max(length(strip(put(&_col_j, best32.)))) into :_numlen_this trimmed
          from pdd.src_&_sc_j
          where &_col_j is not missing;
        quit;
        %if &_numlen_this > &_n_numlen_max %then %let _n_numlen_max = &_numlen_this;
        %goto next_tc_src;
      %end;

      /* Column is character: run parse test.
         ?? in DATA step INPUT is permitted (C1 bans ?? only in PROC SQL). */
      %let _n_fail    = 0;
      %let _ex_fail   = ;

      data work._tc_scan;
        set pdd.src_&_sc_j (keep=&_col_j);
        length val $200 _ex_fail $200;
        val = strip(&_col_j);
        /* Skip blank and '.' -- treated as missing in parse check */
        if val = '' or val = '.' then delete;
        _n   = input(val, ?? best32.);
        _fail = (missing(_n) and val not in ('', '.'));
        if _fail then _ex_fail = val;
        else _ex_fail = '';
        keep val _fail _ex_fail;
      run;

      proc sql noprint;
        select count(*) into :_n_fail trimmed
        from work._tc_scan
        where _fail = 1;

        select _ex_fail into :_ex_fail trimmed
        from work._tc_scan
        where _fail = 1
        having monotonic() = 1;
      quit;

      %let _n_char_src_total = %eval(&_n_char_src_total + 1);
      %let _n_fail_total     = %eval(&_n_fail_total + &_n_fail);

      /* Accumulate per-source row into typecheck_sources */
      data work._tcs_row;
        length pcnr_name $200 s_code $4 n_char_sources 8 n_parse_failures 8
               example_failing_value $200;
        pcnr_name             = "&_tc_name";
        s_code                = "&_sc_j";
        n_char_sources        = &_n_char_src_total;
        n_parse_failures      = &_n_fail;
        example_failing_value = "&_ex_fail";
      run;
      proc append base=work._typecheck_sources data=work._tcs_row force; run;

      /* If failures exist, accumulate into pdd.qc_pcnr_typefail (distinct values) */
      %if &_n_fail > 0 %then %do;
        proc sql noprint;
          insert into pdd.qc_pcnr_typefail (pcnr_name, s_code, raw_value, n)
          select "&_tc_name", "&_sc_j", val, count(*) as n
          from work._tc_scan
          where _fail = 1
          group by val;
        quit;
      %end;

      %next_tc_src:
    %end; /* _k loop over sources */

    /* Step 4. Resolution rule */
    %local _resolved_type _out_length;
    %if &_n_fail_total = 0 %then %do;
      %let _resolved_type = N8;
      %let _out_length    = 8;
      /* Step 7. Pre-scan passed -- N8 conversion will be lossless */
      %put NOTE: [05_build_pcnr] &_tc_name resolved to N8 (0 parse failures across &_n_char_src_total char sources);
    %end;
    %else %do;
      %let _resolved_type = C;
      /* Step 4 / item 11. out_length = max(name_map_vars max_length, numeric source best32 max) */
      %let _out_length = &_tc_maxlen;
      %if &_n_numlen_max > &_out_length %then %let _out_length = &_n_numlen_max;
      %put NOTE: [05_build_pcnr] &_tc_name resolved to C (length=&_out_length; &_n_fail_total parse failures);
    %end;

    /* Step 5. Append to work._type_resolution */
    data work._tr_row;
      length pcnr_name $200 resolved_type $8 out_length 8;
      pcnr_name     = "&_tc_name";
      resolved_type = "&_resolved_type";
      out_length    = &_out_length;
    run;
    proc append base=work._type_resolution data=work._tr_row force; run;

    /* Clean up per-variable source list */
    proc datasets library=work nolist;
      delete _tc_sources_&_tc_i _tc_scan _tcs_row _tr_row;
    quit;

  %end; /* _tc_i loop */

  /* Step 5. Assert key uniqueness on work._type_resolution */
  %local _n_tr _n_tr_k;
  proc sql noprint;
    select count(*) into :_n_tr trimmed from work._type_resolution;
    select count(distinct pcnr_name) into :_n_tr_k trimmed from work._type_resolution;
  quit;
  %if &_n_tr ne &_n_tr_k %then %do;
    %fail_out(msg=%str(work._type_resolution not unique on pcnr_name: n=&_n_tr distinct=&_n_tr_k));
  %end;
  %put NOTE: [05_build_pcnr] work._type_resolution key uniqueness OK (rows=&_n_tr);

  /* Step 6. Assert key uniqueness on work._typecheck_sources (pcnr_name + s_code) */
  %local _n_tcs _n_tcs_k;
  proc sql noprint;
    select count(*) into :_n_tcs trimmed from work._typecheck_sources;
    select count(*) into :_n_tcs_k trimmed
    from (
      select pcnr_name, s_code from work._typecheck_sources
      group by pcnr_name, s_code
    );
  quit;
  /* _n_tcs_k = number of distinct (pcnr_name,s_code) combinations */
  %if &_n_tcs ne &_n_tcs_k %then %do;
    %fail_out(msg=%str(work._typecheck_sources not unique on (pcnr_name,s_code): n=&_n_tcs distinct_pairs=&_n_tcs_k));
  %end;
  %put NOTE: [05_build_pcnr] work._typecheck_sources key uniqueness OK (rows=&_n_tcs);

  /* Step 8. Export pdd.qc_pcnr_typefail to exchange */
  proc export data=pdd.qc_pcnr_typefail
    outfile="&exchange_path.\pcnr_typecheck.csv"
    dbms=csv replace;
  run;

  /* Step 9. Summary note */
  %local _n_n8 _n_c;
  proc sql noprint;
    select count(*) into :_n_n8 trimmed from work._type_resolution where resolved_type = 'N8';
    select count(*) into :_n_c  trimmed from work._type_resolution where resolved_type = 'C';
  quit;
  %put NOTE: [05_build_pcnr] type resolution complete: N8=&_n_n8 C=&_n_c (of &_n_tr conflict vars);
  %put NOTE: [05_build_pcnr] pcnr_typecheck.csv written to exchange;

%mend p5_resolve_types;

/* ============================================================
   %p5_build_accumulator  (Plan 04 Task 1)
   Add var_idx to work._nmv; build representative-label lookup;
   generate ATTRIB code to logs\05_generated_attrib.sas via
   DATA _NULL_ FILE= (no CALL EXECUTE); load spine into
   work._pcnr_accum with fill-origin _F* ($4) and source-alias
   _S* columns; assert 41,150 rows.
   DEFINE ONLY -- called from Section 2 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_build_accumulator;

  /* Step 1. Add sequential var_idx (1..1299) to work._nmv.
     DATA step automatic counter increments before first OUTPUT. */
  data work._nmv;
    set work._nmv;
    var_idx + 1;
  run;

  /* Step 2. Build representative-label lookup (work._pcnr_labels).
     For each pcnr_name select the original_header from the row with
     the numerically lowest s_code (cast via input(substr(s_code,2),best32.))
     then lowest col_order. Join pdd.name_map (status='PCNR') to itself. */
  proc sql noprint;
    create table work._pcnr_labels as
    select a.pcnr_name,
           substr(a.original_header, 1, 256) as label length=256
    from pdd.name_map as a
    inner join (
      select pcnr_name,
             min(input(substr(s_code, 2), best32.)) as min_sc_num
      from pdd.name_map
      where status = 'PCNR' and pcnr_name ne ''
      group by pcnr_name
    ) as b
      on a.pcnr_name = b.pcnr_name
         and input(substr(a.s_code, 2), best32.) = b.min_sc_num
    inner join (
      select pcnr_name,
             input(substr(s_code, 2), best32.) as sc_num,
             min(col_order) as min_col_order
      from pdd.name_map
      where status = 'PCNR' and pcnr_name ne ''
      group by pcnr_name, calculated sc_num
    ) as c
      on a.pcnr_name = c.pcnr_name
         and input(substr(a.s_code, 2), best32.) = c.sc_num
         and a.col_order = c.min_col_order
    where a.status = 'PCNR' and a.pcnr_name ne ''
    order by a.pcnr_name;
  quit;

  /* Step 3a. Write norm_psid ATTRIB first (fresh file, not mod) */
  data _null_;
    file "&logs_path.\05_generated_attrib.sas" encoding='utf-8';
    put 'ATTRIB norm_psid LENGTH=$64;';
    stop;
  run;

  /* Step 3b. Append ATTRIB for each PCNR_ variable and its aliases.
     Generated code shape per variable (example var_idx=1):
       ATTRIB PCNR_AGE LENGTH=8 LABEL='Age';
       ATTRIB _S0001 LENGTH=8;
       ATTRIB _F0001 LENGTH=$4;
     No CALL EXECUTE. */
  data _null_;
    /* Load type-resolution overrides into hash */
    if _n_ = 1 then do;
      declare hash htr(dataset: 'work._type_resolution');
      htr.definekey('pcnr_name');
      htr.definedata('resolved_type', 'out_length');
      htr.definedone();
      declare hash hlbl(dataset: 'work._pcnr_labels');
      hlbl.definekey('pcnr_name');
      hlbl.definedata('label');
      hlbl.definedone();
    end;
    set work._nmv;
    length resolved_type $8 out_length 8 label $256
           _typecode $40 _line $400 _s_alias $10 _f_alias $10;
    resolved_type = '';
    out_length    = max_length;
    if htr.find() ne 0 then do;
      /* No override: derive from result_type flag in _nmv */
      if result_type = 'N' then resolved_type = 'N8';
      else                       resolved_type = 'C';
    end;
    if resolved_type = 'N8' then _typecode = '8';
    else _typecode = cats('$', put(out_length, best32.));
    label = '';
    if hlbl.find() ne 0 then label = pcnr_name; /* fallback: use name */
    if length(strip(label)) > 256 then label = substr(label, 1, 256);
    _s_alias = cats('_S', put(var_idx, z4.));
    _f_alias = cats('_F', put(var_idx, z4.));
    file "&logs_path.\05_generated_attrib.sas" encoding='utf-8' mod;
    _line = cats('ATTRIB ', strip(pcnr_name),
                 ' LENGTH=', strip(_typecode),
                 ' LABEL=', quote(trim(label)), ';');
    put _line;
    _line = cats('ATTRIB ', strip(_s_alias),
                 ' LENGTH=', strip(_typecode), ';');
    put _line;
    _line = cats('ATTRIB ', strip(_f_alias), ' LENGTH=$4;');
    put _line;
    drop resolved_type out_length label _typecode _line _s_alias _f_alias;
  run;

  %put NOTE: [05_build_pcnr] 05_generated_attrib.sas written;

  /* Step 4. Collect s09-contributed columns from pdd.name_map */
  proc sql noprint;
    create table work._s09_cols as
    select nm.col_name,
           nm.pcnr_name,
           nv.var_idx,
           nv.result_type,
           nv.max_length,
           nv.type_conflict
    from pdd.name_map as nm
    inner join work._nmv as nv
      on nm.pcnr_name = nv.pcnr_name
    where nm.s_code = 's09'
      and nm.status = 'PCNR'
    order by nv.var_idx;
  quit;

  /* Build KEEP= and RENAME= macro variables for spine DATA step */
  %local _n_s09 _s09_keep _s09_rename _i;
  proc sql noprint;
    select count(*) into :_n_s09 trimmed from work._s09_cols;
  quit;
  %let _s09_keep   = norm_psid;
  %let _s09_rename = ;
  %do _i = 1 %to &_n_s09;
    %local _cn_&_i _pn_&_i;
    proc sql noprint;
      select col_name, pcnr_name
      into :_cn_&_i trimmed, :_pn_&_i trimmed
      from work._s09_cols (firstobs=&_i obs=&_i);
    quit;
    %let _s09_keep   = &_s09_keep &&_cn_&_i;
    %if "&&_cn_&_i" ne "&&_pn_&_i" %then
      %let _s09_rename = &_s09_rename &&_cn_&_i = &&_pn_&_i;
  %end;

  /* Step 5. Generate spine fill-origin assignment code.
     For each s09-contributed var: set _F<z4(i)>='s09' when non-missing.
     For type-conflict vars resolved to N8 where s09 col was character:
     the rename already maps to the pcnr_name; the PDV type is N8 from ATTRIB;
     SAS will auto-convert a character incoming value when the PDV declares N8,
     but we use explicit INPUT to be explicit and safe. */
  data _null_;
    if _n_ = 1 then do;
      declare hash htr(dataset: 'work._type_resolution');
      htr.definekey('pcnr_name');
      htr.definedata('resolved_type', 'out_length');
      htr.definedone();
    end;
    set work._s09_cols;
    length resolved_type $8 out_length 8 _f_alias $10 _line $300;
    resolved_type = '';
    out_length    = max_length;
    if htr.find() ne 0 then do;
      if result_type = 'N' then resolved_type = 'N8';
      else                       resolved_type = 'C';
    end;
    _f_alias = cats('_F', put(var_idx, z4.));
    file "&logs_path.\05_generated_spine_fill.sas" encoding='utf-8' mod;
    /* type_conflict='Y' and resolved to N8: spine col is char in pdd.src_s09;
       ATTRIB declares it N8; SAS coerces on read, but explicitly INPUT for clarity */
    if type_conflict = 'Y' and resolved_type = 'N8' then do;
      _line = cats('/* type-conflict N8: ', strip(pcnr_name), ' */');
      put _line;
      _line = cats('if not missing(', strip(pcnr_name), ') then do;');
      put _line;
      _line = cats('  ', strip(pcnr_name),
                   ' = input(strip(put(', strip(pcnr_name),
                   ', best32.)), ?? best32.);');
      put _line;
      _line = cats('  ', strip(_f_alias), " = 's09';");
      put _line;
      put 'end;';
    end;
    else do;
      _line = cats('if not missing(', strip(pcnr_name),
                   ') then ', strip(_f_alias), " = 's09';");
      put _line;
    end;
    drop resolved_type out_length _f_alias _line;
  run;

  /* Sort spine to work (item 2 -- never sort pdd.src_* in place) */
  proc sort data=pdd.src_s09 out=work._src_s09;
    by norm_psid;
  run;

  /* Step 6. DATA work._pcnr_accum: set spine; apply ATTRIBs and fill-origin */
  data work._pcnr_accum;
    %include "&logs_path.\05_generated_attrib.sas";
    set work._src_s09 (keep=&_s09_keep
                       rename=(&_s09_rename));
    %include "&logs_path.\05_generated_spine_fill.sas";
  run;

  /* Assert 41,150 rows */
  %assert_rowcount(ds=work._pcnr_accum, expected=41150,
                   label=spine-loaded accumulator);

  %put NOTE: [05_build_pcnr] %p5_build_accumulator complete;

%mend p5_build_accumulator;

/* ============================================================
   %p5_gapfill_source(s_code=, rank=)  (Plan 04 Task 2)
   Gap-fill accumulator from one non-spine source via
   write-next-verify-replace pattern; generate per-variable
   IF blocks to logs\05_generated_gapfill_<s>.sas (no CALL
   EXECUTE); detect SPINE_VS_SOURCE and SOURCE_VS_SOURCE
   conflicts; record provenance for 2+-source vars; assert
   41,150 rows on work._pcnr_next before replacing accumulator.
   DEFINE ONLY -- called from %p5_run_gapfill.
   ============================================================ */
%macro p5_gapfill_source(s_code=, rank=);

  /* Step 1. Collect (col_name, pcnr_name, var_idx, n_sources) for this source */
  %local _n_src_vars;
  proc sql noprint;
    create table work._gf_cols_&s_code as
    select nm.col_name,
           nm.pcnr_name,
           nv.var_idx,
           nv.result_type,
           nv.max_length,
           nv.type_conflict,
           nv.n_sources
    from pdd.name_map as nm
    inner join work._nmv as nv
      on nm.pcnr_name = nv.pcnr_name
    where nm.s_code = "&s_code"
      and nm.status = 'PCNR'
    order by nv.var_idx;

    select count(*) into :_n_src_vars trimmed
    from work._gf_cols_&s_code;
  quit;

  /* Skip sources contributing 0 PCNR_ variables */
  %if &_n_src_vars = 0 %then %do;
    %put NOTE: [05_build_pcnr] source &s_code contributes 0 PCNR_ variables -- skipped;
    %return;
  %end;
  %put NOTE: [05_build_pcnr] source &s_code contributes &_n_src_vars PCNR_ variables (rank=&rank);

  /* Step 2. Sort source to work (item 2 -- never sort pdd.src_* in place) */
  %local _gf_keep _gf_rename _i;
  %let _gf_keep   = norm_psid;
  %let _gf_rename = ;
  %do _i = 1 %to &_n_src_vars;
    %local _gf_cn_&_i _gf_pn_&_i;
    proc sql noprint;
      select col_name, pcnr_name
      into :_gf_cn_&_i trimmed, :_gf_pn_&_i trimmed
      from work._gf_cols_&s_code (firstobs=&_i obs=&_i);
    quit;
    %let _gf_keep = &_gf_keep &&_gf_cn_&_i;
    /* Rename col_name to _S<z4(var_idx)> alias for merge */
  %end;

  /* Build RENAME= mapping col_name -> _S<z4(var_idx)> */
  data _null_;
    set work._gf_cols_&s_code;
    length _s_alias $10 _pair $400;
    _s_alias = cats('_S', put(var_idx, z4.));
    _pair    = cats(strip(col_name), '=', strip(_s_alias));
    call symputx(cats('_gf_rn_', _n_), strip(_pair), 'L');
    call symputx('_gf_rn_n', _n_, 'L');
  run;

  /* Rebuild rename string from symputx values */
  %local _j _gf_rename_str;
  %let _gf_rename_str = ;
  %do _j = 1 %to &_gf_rn_n;
    %let _gf_rename_str = &_gf_rename_str &&_gf_rn_&_j;
  %end;

  proc sort data=pdd.src_&s_code
    out=work._src_&s_code (keep=&_gf_keep rename=(&_gf_rename_str));
    by norm_psid;
  run;

  /* Step 3. Generate per-variable gap-fill/conflict IF blocks to
     logs\05_generated_gapfill_&s_code..sas via DATA _NULL_ FILE=.
     No CALL EXECUTE.
     Generated code shape for one variable (type C, example):
       if missing(PCNR_X) and not missing(_S0042) then do;
         PCNR_X = _S0042;
         _F0042 = "&s_code";
         if 1 then output work._prov_&s_code;  (only for n_sources>1 vars)
       end;
       else if not missing(PCNR_X) and not missing(_S0042) and
               strip(PCNR_X) ne strip(_S0042) then do;
         ... conflict block ...
       end;
     NOTE: work._prov_&s_code contains ONLY 2+-source rows
     by construction of the n_sources guard (W5 confirmation). */
  data _null_;
    if _n_ = 1 then do;
      declare hash htr(dataset: 'work._type_resolution');
      htr.definekey('pcnr_name');
      htr.definedata('resolved_type', 'out_length');
      htr.definedone();
    end;
    set work._gf_cols_&s_code;
    length resolved_type $8 out_length 8
           _f_alias $10 _s_alias $10 _line $500;
    resolved_type = '';
    out_length    = max_length;
    if htr.find() ne 0 then do;
      if result_type = 'N' then resolved_type = 'N8';
      else                       resolved_type = 'C';
    end;
    _f_alias = cats('_F', put(var_idx, z4.));
    _s_alias = cats('_S', put(var_idx, z4.));
    file "&logs_path.\05_generated_gapfill_&s_code..sas" encoding='utf-8' mod;
    /* Gap-fill block */
    _line = cats('/* gap-fill for ', strip(pcnr_name), ' from &s_code */');
    put _line;
    _line = cats('if missing(', strip(pcnr_name),
                 ') and not missing(', strip(_s_alias), ') then do;');
    put _line;
    if resolved_type = 'N8' and type_conflict = 'Y' then do;
      /* Source _S alias is char (type-conflict); convert to numeric */
      _line = cats('  ', strip(pcnr_name),
                   ' = input(strip(', strip(_s_alias), '), ?? best32.);');
      put _line;
    end;
    else if resolved_type = 'C' and result_type = 'N' then do;
      /* Source is numeric; resolved to C: convert via PUT */
      _line = cats('  ', strip(pcnr_name),
                   ' = strip(put(', strip(_s_alias), ', best32.));');
      put _line;
    end;
    else do;
      _line = cats('  ', strip(pcnr_name), ' = ', strip(_s_alias), ';');
      put _line;
    end;
    _line = cats('  ', strip(_f_alias), ' = "&s_code";');
    put _line;
    /* Provenance output: ONLY for vars with 2+ contributing sources (W5).
       NOTE: work._prov_&s_code contains ONLY 2+-source rows
       by construction of this n_sources guard -- no additional filter needed. */
    if n_sources > 1 then do;
      put '  output work._prov_&s_code;';
    end;
    put 'end;';
    /* Conflict block */
    put cats('else if not missing(', strip(pcnr_name),
             ') and not missing(', strip(_s_alias), ') then do;');
    /* D-20 equality: char uses strip(); numeric uses exact */
    if resolved_type = 'N8' then do;
      _line = cats('  if ', strip(pcnr_name), ' ne ', strip(_s_alias), ' then do;');
    end;
    else do;
      _line = cats('  if strip(', strip(pcnr_name),
                   ') ne strip(', strip(_s_alias), ') then do;');
    end;
    put _line;
    /* conflict_type: SPINE_VS_SOURCE if _F alias = 's09', else SOURCE_VS_SOURCE */
    put cats('    _conflict_type = ifc(strip(', strip(_f_alias),
             ") = 's09', 'SPINE_VS_SOURCE', 'SOURCE_VS_SOURCE');");
    put cats('    _winning_sc = strip(', strip(_f_alias), ');');
    /* winning_value: convert to $200 */
    if resolved_type = 'N8' then do;
      put cats('    _winning_val = strip(put(', strip(pcnr_name), ', best32.));');
      put cats('    _candidate_val = strip(put(', strip(_s_alias), ', best32.));');
    end;
    else do;
      put cats('    _winning_val = strip(', strip(pcnr_name), ');');
      put cats('    _candidate_val = strip(', strip(_s_alias), ');');
    end;
    put cats('    _candidate_sc = "&s_code";');
    put cats('    _pcnr_name_c  = "', strip(pcnr_name), '";');
    /* value_type: 'N' or 'C' */
    if resolved_type = 'N8' then put "    _value_type = 'N';";
    else                          put "    _value_type = 'C';";
    put '    output work._conflicts_&s_code;';
    put '  end;';
    put 'end;';
    drop resolved_type out_length _f_alias _s_alias _line;
  run;

  /* Step 4. Create empty output datasets before DATA step */
  data work._prov_&s_code;
    length norm_psid $64 pcnr_name $200 src_s_code $4;
    stop;
  run;

  data work._conflicts_&s_code;
    length norm_psid $64 pcnr_name $200 conflict_type $20
           winning_s_code $4 winning_value $200
           candidate_s_code $4 candidate_value $200
           value_type $1;
    stop;
  run;

  /* Step 4b. DATA step: MERGE accumulator with source; %include generated code;
     OUTPUT to work._pcnr_next, with conditional side-outputs. */
  data work._pcnr_next
       work._conflicts_&s_code (keep=norm_psid pcnr_name conflict_type
                                     winning_s_code winning_value
                                     candidate_s_code candidate_value
                                     value_type)
       work._prov_&s_code      (keep=norm_psid pcnr_name src_s_code);
    length _conflict_type $20 _winning_sc $4 _winning_val $200
           _candidate_sc $4 _candidate_val $200 _value_type $1
           _pcnr_name_c $200 conflict_type $20 winning_s_code $4
           winning_value $200 candidate_s_code $4 candidate_value $200
           value_type $1 pcnr_name $200 src_s_code $4;
    merge work._pcnr_accum (in=_a)
          work._src_&s_code (in=_b);
    by norm_psid;
    if _a; /* keep all 41,150 spine rows */
    /* Reset side-output vars */
    _conflict_type = ''; _winning_sc = ''; _winning_val = '';
    _candidate_sc  = ''; _candidate_val = ''; _value_type = '';
    _pcnr_name_c   = '';
    %include "&logs_path.\05_generated_gapfill_&s_code..sas";
    /* Map internal vars to output column names */
    conflict_type    = _conflict_type;
    winning_s_code   = _winning_sc;
    winning_value    = _winning_val;
    candidate_s_code = _candidate_sc;
    candidate_value  = _candidate_val;
    value_type       = _value_type;
    pcnr_name        = _pcnr_name_c;
    src_s_code       = "&s_code";
    output work._pcnr_next;
    drop _conflict_type _winning_sc _winning_val _candidate_sc
         _candidate_val _value_type _pcnr_name_c;
  run;

  /* Step 5. Assert 41,150 rows on work._pcnr_next */
  %assert_rowcount(ds=work._pcnr_next, expected=41150,
                   label=pcnr_next after &s_code);

  /* Step 6. Replace accumulator (write-next-verify-replace) */
  data work._pcnr_accum;
    set work._pcnr_next;
  run;

  proc datasets lib=work nolist;
    delete _pcnr_next;
  quit;

  /* Step 7. Gap-fill counts for %p5_write_qc via work._prov_&s_code */
  %local _n_prov;
  proc sql noprint;
    select count(*) into :_n_prov trimmed from work._prov_&s_code;
  quit;
  %put NOTE: [05_build_pcnr] source &s_code: prov rows=&_n_prov;

  /* Clean up source sort */
  proc datasets lib=work nolist;
    delete _src_&s_code _gf_cols_&s_code;
  quit;

  %put NOTE: [05_build_pcnr] %p5_gapfill_source(&s_code) complete;

%mend p5_gapfill_source;

/* ============================================================
   %p5_run_gapfill  (Plan 04 Task 2)
   Three-pass precedence: spine pass (done in %p5_build_accumulator),
   pinned-source pass (work._override), rank-order loop (work._priority
   excluding s09 and already-pinned sources).
   DEFINE ONLY -- called from Section 2 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_run_gapfill;

  /* Pass 2 -- pinned sources from work._override */
  %local _n_ov _oi _ov_pn _ov_sc;
  proc sql noprint;
    select count(*) into :_n_ov trimmed from work._override;
  quit;
  %if &_n_ov > 0 %then %do _oi = 1 %to &_n_ov;
    %let _ov_pn = ;
    %let _ov_sc = ;
    proc sql noprint;
      select pcnr_name, s_code
      into :_ov_pn trimmed, :_ov_sc trimmed
      from work._override (firstobs=&_oi obs=&_oi);
    quit;
    %put NOTE: [05_build_pcnr] Pass 2: pinned override pcnr_name=&_ov_pn s_code=&_ov_sc;
    /* Call gapfill for the pinned source (it handles skip-if-0 internally).
       rank=0 indicates this is a pinned override call. */
    %p5_gapfill_source(s_code=&_ov_sc, rank=0);
  %end;

  /* Pass 3 -- rank-order loop; skip spine (s09) */
  %local _n_prio _i _sc _rk;
  proc sql noprint;
    select count(*) into :_n_prio trimmed from work._priority;
  quit;
  %do _i = 1 %to &_n_prio;
    %let _sc = ;
    %let _rk = ;
    proc sql noprint;
      select s_code, rank
      into :_sc trimmed, :_rk trimmed
      from work._priority (firstobs=&_i obs=&_i);
    quit;
    %if %upcase("&_sc") ne "S09" %then %do;
      %p5_gapfill_source(s_code=&_sc, rank=&_rk);
    %end;
  %end;

  %put NOTE: [05_build_pcnr] gap-fill loop complete across all non-spine sources;

%mend p5_run_gapfill;
