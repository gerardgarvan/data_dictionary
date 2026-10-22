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
