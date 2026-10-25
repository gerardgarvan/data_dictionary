/*==========================================================================
  Program : 05_build_pcnr_macros.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Macro library for Phase 5 -- Build PCNR_ on the spine.
            Section 0 defines all macros; subsequent sections call them.
            Plans 03, 04, 05 append macros to this file in order.

  Macros (Plan 03):
    %fail_out            -- hard stop with ERROR (test-mode: sets p5_fail)
    %_p5_ok              -- section guard (obs=0 / syserr > 4)
    %assert_rowcount     -- exact row count assertion
    %p5_preflight        -- D-18 assertion, spine key quality, SHA-256,
                            priority/override file validation
    %p5_spine_coverage   -- D-19 extended spine coverage QC
    %p5_resolve_types    -- D-02 type-conflict resolution

  Author  :
  Notes   : PCM compliance: C1 C2 C3 C9 C11 C13 C14.
            Caller must set &sas_path, &exchange_path, &logs_path before
            calling these macros (typically via 00_config.sas + %pdd_lib).
            For test harness usage: set p5_test_mode=1 before any call.
==========================================================================*/

/* ============================================================
   SECTION 0 -- ALL macro definitions
   All macros defined here before any call (PCM C13).
   ============================================================ */

/* Declare and initialise all Phase 5 control globals.
   Called immediately after definition so every &p5_fail guard is safe.
   Does NOT overwrite values already set by the caller (test harness or
   smoke test may pre-set p5_test_mode=1 or p5_smoke=1 before %include). */
%macro _p5_init_globals;
  %global p5_fail p5_fail_msg p5_test_mode p5_smoke;
  /* Always reset error state at the start of an orchestrator run */
  %let p5_fail     = 0;
  %let p5_fail_msg = ;
  /* Set mode flags only when the caller has not already provided a value */
  %if %bquote(&p5_test_mode) = %bquote() %then %let p5_test_mode = 0;
  %if %bquote(&p5_smoke)     = %bquote() %then %let p5_smoke     = 0;
%mend _p5_init_globals;
%_p5_init_globals;

/* Hard stop with loud ERROR.
   If p5_test_mode=1: set p5_fail/p5_fail_msg and %return instead of aborting. */
%macro fail_out(msg=);
  %put ERROR: [05_build_pcnr] &msg;
  /* p5_fail/p5_fail_msg always global (declared by _p5_init_globals above) */
  %if &p5_test_mode = 1 %then %do;
    %let p5_fail = 1;
    %let p5_fail_msg = &msg;
    %return;
  %end;
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
%macro p5_preflight(
  srclib=pdd,
  nmlib=pdd,
  outlib=pdd,
  spine_n=41150,
  nvars=1299,
  priority_csv=,
  override_csv=,
  s06class_csv=,
  gen_dir=,
  export_dir=
);

  /* ---- A. name_map assertions ---- */

  /* A1. Exact row count of name_map_vars */
  %assert_rowcount(ds=&nmlib..name_map_vars, expected=&nvars, label=name_map_vars);

  /* A2. D-18: s04/s05 must contribute 0 PCNR rows to name_map.
         &nmlib..name_map (not name_map_vars) carries s_code. */
  %local _n_linkage_pcnr;
  proc sql noprint;
    select count(*) into :_n_linkage_pcnr trimmed
    from &nmlib..name_map
    where s_code in ('s04', 's05')
      and status = 'PCNR';
  quit;
  %if &_n_linkage_pcnr > 0 %then %do;
    %fail_out(msg=%str(D-18 violated: &_n_linkage_pcnr rows in &nmlib..name_map have s_code in (s04 s05) and status=PCNR));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] D-18 s04/s05 contribute 0 PCNR rows (passed);

  /* ---- B. SHA-256 + row counts ---- */

  /* B1. SHA-256 of export_dir\name_map.csv via certutil */
  filename _nmhash pipe "certutil -hashfile ""&export_dir.\name_map.csv"" SHA256";
  data _null_;
    infile _nmhash;
    input;
    put "NOTE: [05_build_pcnr] name_map.csv SHA256= " _infile_;
  run;
  filename _nmhash clear;

  /* B2. Row counts for traceability */
  %local _n_nm _n_nmv;
  proc sql noprint;
    select count(*) into :_n_nm trimmed from &nmlib..name_map;
  quit;
  proc sql noprint;
    select count(*) into :_n_nmv trimmed from &nmlib..name_map_vars;
  quit;
  %put NOTE: [05_build_pcnr] &nmlib..name_map rows=&_n_nm &nmlib..name_map_vars rows=&_n_nmv;

  /* ---- C. Source file checks ---- */

  /* C1. Spine row count and key quality */
  %assert_rowcount(ds=&srclib..src_s09, expected=&spine_n, label=spine &srclib..src_s09);
  %if &p5_fail = 1 %then %return;

  %local _n_blank_spine;
  proc sql noprint;
    select count(*) into :_n_blank_spine trimmed
    from &srclib..src_s09
    where norm_psid = '';
  quit;
  %if &_n_blank_spine > 0 %then %do;
    %fail_out(msg=%str(spine has &_n_blank_spine blank norm_psid values));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] spine blank norm_psid check passed (0 blank);

  %local _n_all_spine _n_dis_spine;
  proc sql noprint;
    select count(*) into :_n_all_spine trimmed from &srclib..src_s09;
    select count(distinct norm_psid) into :_n_dis_spine trimmed from &srclib..src_s09;
  quit;
  %if &_n_all_spine ne &_n_dis_spine %then %do;
    %fail_out(msg=%str(spine has duplicate norm_psid: total=&_n_all_spine distinct=&_n_dis_spine));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] spine duplicate norm_psid check passed (&_n_dis_spine unique keys);

  /* C2. Per-source key quality for all 20 sources.
         Check each &srclib..src_s* that has contributing PCNR rows:
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
    %let _src_exist = %sysfunc(exist(&srclib..src_&_sc));
    %if &_src_exist = 0 %then %do;
      %put NOTE: [05_build_pcnr] &srclib..src_&_sc not found -- skipping key quality check;
      %goto next_source;
    %end;

    /* Check whether this source contributes any PCNR rows */
    %let _n_pcnr_src = 0;
    proc sql noprint;
      select count(*) into :_n_pcnr_src trimmed
      from &nmlib..name_map
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
      from &srclib..src_&_sc
      where norm_psid = '';
    quit;
    %put NOTE: [05_build_pcnr] SOURCE &_sc n_blank_keys=&_n_blank_keys;

    /* Assert 0 duplicate non-blank norm_psid */
    %let _n_nonblank = 0;
    %let _n_dis_nonblank = 0;
    proc sql noprint;
      select count(*) into :_n_nonblank trimmed
      from &srclib..src_&_sc
      where norm_psid ne '';
      select count(distinct norm_psid) into :_n_dis_nonblank trimmed
      from &srclib..src_&_sc
      where norm_psid ne '';
    quit;
    %if &_n_nonblank ne &_n_dis_nonblank %then %do;
      %fail_out(msg=%str(source &_sc has duplicate non-blank norm_psid: n_nonblank=&_n_nonblank n_distinct=&_n_dis_nonblank));
    %end;
    %if &p5_fail = 1 %then %return;

    %next_source:
  %end;
  %put NOTE: [05_build_pcnr] per-source key quality checks complete;

  /* ---- D. Docs file validation -- priority and override CSVs ---- */

  /* D1. Priority file */
  %local _prio_path;
  %if %bquote(&priority_csv) ne %bquote() %then %let _prio_path = &priority_csv;
  %else %let _prio_path = &sas_path.\..\docs\pcnr_source_priority.csv;

  %if not %sysfunc(fileexist(&_prio_path)) %then %do;
    %fail_out(msg=%str(priority CSV missing: &_prio_path));
  %end;

  data work._priority;
    length s_code $4 rank 8 note $40;
    infile "&_prio_path"
           encoding='utf-8' dsd dlm=',' missover firstobs=2;
    input s_code $ rank note $;
    s_code = strip(s_code);
    note   = strip(note);
    if s_code = '' then delete;
  run;

  %assert_rowcount(ds=work._priority, expected=20, label=priority);
  %if &p5_fail = 1 %then %return;

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
  %if &p5_fail = 1 %then %return;
  %if &_n_dis_ranks ne 20 %then %do;
    %fail_out(msg=%str(priority ranks not a permutation of 1..20: only &_n_dis_ranks distinct ranks));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] priority ranks are a valid permutation of 1..20;

  /* Assert s09 note = 'spine' */
  %local _s09note;
  proc sql noprint;
    select note into :_s09note trimmed
    from work._priority
    where s_code = 's09';
  quit;
  %if %bquote(&_s09note) ne %bquote(spine) %then %do;
    %fail_out(msg=%str(priority s09 note is not spine -- found: &_s09note));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] priority s09 note=spine confirmed;

  /* Assert s_codes are exactly s01..s20, distinct */
  %local _n_valid_sc _n_dis_sc;
  proc sql noprint;
    select count(*) into :_n_valid_sc trimmed
    from work._priority
    where s_code in ('s01','s02','s03','s04','s05','s06','s07','s08','s09','s10',
                     's11','s12','s13','s14','s15','s16','s17','s18','s19','s20');
    select count(distinct s_code) into :_n_dis_sc trimmed
    from work._priority;
  quit;
  %if &_n_valid_sc ne 20 %then %do;
    %fail_out(msg=%str(priority s_codes not exactly s01..s20: &_n_valid_sc valid rows of 20));
  %end;
  %if &p5_fail = 1 %then %return;
  %if &_n_dis_sc ne 20 %then %do;
    %fail_out(msg=%str(priority has duplicate s_code: only &_n_dis_sc distinct of 20));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] priority s_codes confirmed as exactly s01..s20 distinct;

  /* Sort priority by rank for use in coverage/build loops */
  proc sort data=work._priority out=work._priority;
    by rank;
  run;

  /* D2. Override file */
  %local _override_path;
  %if %bquote(&override_csv) ne %bquote() %then %let _override_path = &override_csv;
  %else %let _override_path = &sas_path.\..\docs\pcnr_source_override.csv;

  %if not %sysfunc(fileexist(&_override_path)) %then %do;
    %fail_out(msg=%str(override CSV missing: &_override_path));
  %end;

  data work._override;
    length pcnr_name $200 s_code $4;
    infile "&_override_path"
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
  %if &p5_fail = 1 %then %return;
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
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] override s09 guard passed;

  /* Assert each override (pcnr_name, s_code) pair exists in &nmlib..name_map with status='PCNR'.
     Only run check when override file is non-empty. */
  %if &_n_ov > 0 %then %do;
    %local _n_bad_pin;
    proc sql noprint;
      select count(*) into :_n_bad_pin trimmed
      from work._override as ov
      where not exists (
        select 1 from &nmlib..name_map as nm
        where nm.pcnr_name = ov.pcnr_name
          and nm.s_code    = ov.s_code
          and nm.status    = 'PCNR'
      );
    quit;
    %if &_n_bad_pin > 0 %then %do;
      %fail_out(msg=%str(override references s_code not contributing to that pcnr_name: &_n_bad_pin bad rows));
    %end;
    %if &p5_fail = 1 %then %return;
    %put NOTE: [05_build_pcnr] override foreign-key check passed;
  %end;
  %else %do;
    %put NOTE: [05_build_pcnr] override file is empty (header-only) -- no override pins active;
  %end;

  /* ---- E. Load work._nmv with sequential var_idx ---- */
  data work._nmv;
    set &nmlib..name_map_vars;
    var_idx + 1;
  run;

  %put NOTE: [05_build_pcnr] p5_preflight complete;

%mend p5_preflight;

/* ============================================================
   %p5_spine_coverage  (Plan 03 Task 2 -- appended below)
   ============================================================ */

%macro p5_spine_coverage(
  srclib=pdd,
  spine_n=41150,
  export_dir=
);

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
    %if %sysfunc(exist(&srclib..src_&_sc)) = 0 %then %do;
      %put NOTE: [05_build_pcnr] SOURCE &_sc: dataset &srclib..src_&_sc not found -- skipped in coverage;
      %goto next_cov;
    %end;

    /* Compute coverage metrics */
    %let _nk   = 0;
    %let _nnis = 0;
    %let _nb   = 0;
    %let _nd   = 0;

    proc sql noprint;
      select count(distinct norm_psid) into :_nk trimmed
      from &srclib..src_&_sc
      where norm_psid ne '';

      select count(*) into :_nnis trimmed
      from &srclib..src_&_sc
      where norm_psid ne ''
        and norm_psid not in (
          select norm_psid from &srclib..src_s09 where norm_psid ne ''
        );

      select count(*) into :_nb trimmed
      from &srclib..src_&_sc
      where norm_psid = '';

      select (count(norm_psid) - count(distinct norm_psid)) into :_nd trimmed
      from &srclib..src_&_sc
      where norm_psid ne '';
    quit;

    %put NOTE: [05_build_pcnr] SOURCE &_sc: &_nnis of &_nk keys not in spine, n_blank=&_nb, n_dup=&_nd;

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

  /* Export coverage CSV */
  proc export data=work._spine_coverage
    outfile="&export_dir.\pcnr_spine_coverage.csv"
    dbms=csv replace;
  run;

  %put NOTE: [05_build_pcnr] pcnr_spine_coverage.csv written to export_dir;

%mend p5_spine_coverage;

/* ============================================================
   %p5_resolve_types
   D-02 type-conflict resolution before the build loop.
   Outputs: work._type_resolution (key-unique on pcnr_name),
            work._typecheck_sources (key-unique on pcnr_name+s_code),
            &outlib..qc_pcnr_typefail (pcnr_name, s_code, raw_value, n),
            &export_dir.\pcnr_typecheck.csv.
   DEFINE ONLY -- called from Section 1 of 05_build_pcnr.sas.
   ============================================================ */

%macro p5_resolve_types(
  srclib=pdd,
  nmlib=pdd,
  outlib=pdd,
  export_dir=
);

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

  data &outlib..qc_pcnr_typefail;
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

    /* Step 2. Find contributing (s_code, col_name) pairs from &nmlib..name_map */
    data work._tc_sources_&_tc_i;
      length pcnr_name $200 s_code $4 col_name $200;
      stop;
    run;

    proc sql noprint;
      insert into work._tc_sources_&_tc_i (pcnr_name, s_code, col_name)
      select pcnr_name, s_code, col_name
      from &nmlib..name_map
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
      %if %sysfunc(exist(&srclib..src_&_sc_j)) = 0 %then %do;
        %put NOTE: [05_build_pcnr] &srclib..src_&_sc_j not found -- skipped for type check of &_tc_name;
        %goto next_tc_src;
      %end;

      /* Determine storage type of this column in &srclib..src_&_sc_j */
      %let _src_type = ;
      proc sql noprint;
        select type into :_src_type trimmed
        from dictionary.columns
        where libname = upcase("&srclib")
          and memname = upcase("SRC_&_sc_j")
          and name    = upcase("&_col_j");
      quit;

      /* If column is numeric: track max length of put(x, best32.) for C-resolve fallback */
      %if &_src_type = num %then %do;
        %local _numlen_this;
        %let _numlen_this = 0;
        proc sql noprint;
          select max(length(strip(put(&_col_j, best32.)))) into :_numlen_this trimmed
          from &srclib..src_&_sc_j
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
        set &srclib..src_&_sc_j (keep=&_col_j);
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
        from work._tc_scan (obs=1)
        where _fail = 1;
      quit;

      %let _n_char_src_total = %eval(&_n_char_src_total + 1);
      %let _n_fail_total     = %eval(&_n_fail_total + &_n_fail);

      /* Accumulate per-source row into typecheck_sources.
         n_char_sources = 1 (this source has the column as char); per-row indicator. */
      data work._tcs_row;
        length pcnr_name $200 s_code $4 n_char_sources 8 n_parse_failures 8
               example_failing_value $200;
        pcnr_name             = "&_tc_name";
        s_code                = "&_sc_j";
        n_char_sources        = 1;
        n_parse_failures      = &_n_fail;
        example_failing_value = symget('_ex_fail');
      run;
      proc append base=work._typecheck_sources data=work._tcs_row force; run;

      /* If failures exist, accumulate into &outlib..qc_pcnr_typefail (distinct values) */
      %if &_n_fail > 0 %then %do;
        proc sql noprint;
          insert into &outlib..qc_pcnr_typefail (pcnr_name, s_code, raw_value, n)
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
      %put NOTE: [05_build_pcnr] &_tc_name resolved to C (length=&_out_length, &_n_fail_total parse failures);
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
  %if &p5_fail = 1 %then %return;
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
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] work._typecheck_sources key uniqueness OK (rows=&_n_tcs);

  /* Step 8. Export &outlib..qc_pcnr_typefail */
  proc export data=&outlib..qc_pcnr_typefail
    outfile="&export_dir.\pcnr_typecheck.csv"
    dbms=csv replace;
  run;

  /* Step 9. Summary note */
  %local _n_n8 _n_c;
  proc sql noprint;
    select count(*) into :_n_n8 trimmed from work._type_resolution where resolved_type = 'N8';
    select count(*) into :_n_c  trimmed from work._type_resolution where resolved_type = 'C';
  quit;
  %put NOTE: [05_build_pcnr] type resolution complete: N8=&_n_n8 C=&_n_c (of &_n_tr conflict vars);
  %put NOTE: [05_build_pcnr] pcnr_typecheck.csv written to export_dir;

%mend p5_resolve_types;

/* ============================================================
   %p5_build_accumulator  (Plan 04 Task 1)
   Add var_idx to work._nmv; build representative-label lookup;
   generate ATTRIB code to gen_dir\05_generated_attrib.sas via
   DATA _NULL_ FILE= (no CALL EXECUTE); load spine into
   work._pcnr_accum with fill-origin _F* ($4) and source-alias
   _S* columns; assert &spine_n rows.
   DEFINE ONLY -- called from Section 2 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_build_accumulator(
  srclib=pdd,
  nmlib=pdd,
  spine_n=41150,
  gen_dir=,
  export_dir=
);

  /* Step 0. Delete stale intermediate tables from any prior run to prevent leakage (TC-14). */
  proc datasets library=work nolist;
    delete _conflicts_s01 _conflicts_s02 _conflicts_s03 _conflicts_s04 _conflicts_s05
           _conflicts_s06 _conflicts_s07 _conflicts_s08 _conflicts_s10 _conflicts_s11
           _conflicts_s12 _conflicts_s13 _conflicts_s14 _conflicts_s15 _conflicts_s16
           _conflicts_s17 _conflicts_s18 _conflicts_s19 _conflicts_s20
           _prov_s01 _prov_s02 _prov_s03 _prov_s04 _prov_s05
           _prov_s06 _prov_s07 _prov_s08 _prov_s10 _prov_s11
           _prov_s12 _prov_s13 _prov_s14 _prov_s15 _prov_s16
           _prov_s17 _prov_s18 _prov_s19 _prov_s20
           _gf_cols_s01 _gf_cols_s02 _gf_cols_s03 _gf_cols_s04 _gf_cols_s05
           _gf_cols_s06 _gf_cols_s07 _gf_cols_s08 _gf_cols_s10 _gf_cols_s11
           _gf_cols_s12 _gf_cols_s13 _gf_cols_s14 _gf_cols_s15 _gf_cols_s16
           _gf_cols_s17 _gf_cols_s18 _gf_cols_s19 _gf_cols_s20;
  quit;
  /* Also delete previously generated gapfill SAS files */
  %local _delsc _deli;
  %do _deli = 1 %to 20;
    %if &_deli < 10 %then %let _delsc = s0&_deli;
    %else %let _delsc = s&_deli;
    %if %sysfunc(fileexist("&gen_dir.\05_generated_gapfill_&_delsc..sas")) %then %do;
      data _null_;
        rc = fdelete(filename('_del', "&gen_dir.\05_generated_gapfill_&_delsc..sas"));
      run;
    %end;
  %end;

  /* Step 1. Assign var_idx if not already present in work._nmv.
     %p5_preflight assigns it; if called without preflight (e.g. test harness),
     assign it here as a sequential counter. Single-source: only add when missing. */
  %local _nmv_has_varidx;
  %let _nmv_has_varidx = 0;
  proc sql noprint;
    select count(*) into :_nmv_has_varidx trimmed
    from dictionary.columns
    where libname = 'WORK' and memname = '_NMV'
      and upcase(name) = 'VAR_IDX';
  quit;
  %if &_nmv_has_varidx = 0 %then %do;
    data work._nmv;
      set work._nmv;
      var_idx + 1;
    run;
  %end;

  /* Step 2. Build representative-label lookup (work._pcnr_labels).
     For each pcnr_name select the original_header from the row with
     the numerically lowest s_code (cast via input(substr(s_code,2),best32.))
     then lowest col_order. Join &nmlib..name_map (status='PCNR') to itself. */
  proc sql noprint;
    create table work._pcnr_labels as
    select a.pcnr_name,
           substr(a.original_header, 1, 256) as label length=256
    from &nmlib..name_map as a
    inner join (
      select pcnr_name,
             min(input(substr(s_code, 2), best32.)) as min_sc_num
      from &nmlib..name_map
      where status = 'PCNR' and pcnr_name ne ''
      group by pcnr_name
    ) as b
      on a.pcnr_name = b.pcnr_name
         and input(substr(a.s_code, 2), best32.) = b.min_sc_num
    inner join (
      select pcnr_name,
             input(substr(s_code, 2), best32.) as sc_num,
             min(col_order) as min_col_order
      from &nmlib..name_map
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
    file "&gen_dir.\05_generated_attrib.sas" encoding='utf-8';
    put 'ATTRIB norm_psid LENGTH=$64;';
    stop;
  run;

  /* Step 3b. Append ATTRIB for each PCNR_ variable and its _F alias.
     Accumulator schema: norm_psid + PCNR_#### + _F#### ($4) ONLY.
     _S#### aliases are NOT declared here -- they are generated in per-source code.
     Generated code shape per variable (example var_idx=1):
       ATTRIB PCNR_AGE LENGTH=8 LABEL='Age';
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
           _typecode $40 _line $400 _f_alias $10;
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
    _f_alias = cats('_F', put(var_idx, z4.));
    file "&gen_dir.\05_generated_attrib.sas" encoding='utf-8' mod;
    _line = cat('ATTRIB ', strip(pcnr_name),
                ' LENGTH=', strip(_typecode),
                ' LABEL=', quote(trim(label)), ';');
    put _line;
    _line = cat('ATTRIB ', strip(_f_alias), ' LENGTH=$4;');
    put _line;
    drop resolved_type out_length label _typecode _line _f_alias;
  run;

  %put NOTE: [05_build_pcnr] 05_generated_attrib.sas written;

  /* Step 4. Collect s09-contributed columns from &nmlib..name_map */
  proc sql noprint;
    create table work._s09_cols as
    select nm.col_name,
           nm.pcnr_name,
           nv.var_idx,
           nv.result_type,
           nv.max_length,
           nv.type_conflict
    from &nmlib..name_map as nm
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
    file "&gen_dir.\05_generated_spine_fill.sas" encoding='utf-8';
    /* type_conflict='Y' and resolved to N8: spine col is char in &srclib..src_s09;
       ATTRIB declares it N8; SAS coerces on read, but explicitly INPUT for clarity */
    if type_conflict = 'Y' and resolved_type = 'N8' then do;
      _line = cat('/* type-conflict N8: ', strip(pcnr_name), ' */');
      put _line;
      _line = cat('if not missing(', strip(pcnr_name), ') then do;');
      put _line;
      _line = cat('  ', strip(pcnr_name),
                  ' = input(strip(put(', strip(pcnr_name),
                  ', best32.)), ?? best32.);');
      put _line;
      _line = cat('  ', strip(_f_alias), " = 's09';");
      put _line;
      put 'end;';
    end;
    else do;
      _line = cat('if not missing(', strip(pcnr_name),
                  ') then ', strip(_f_alias), " = 's09';"
                 );
      put _line;
    end;
    drop resolved_type out_length _f_alias _line;
  run;

  /* Sort spine to work (item 2 -- never sort &srclib..src_* in place) */
  proc sort data=&srclib..src_s09 out=work._src_s09;
    by norm_psid;
  run;

  /* Step 6. DATA work._pcnr_accum: set spine; apply ATTRIBs and fill-origin */
  data work._pcnr_accum;
    %include "&gen_dir.\05_generated_attrib.sas";
    set work._src_s09 (keep=&_s09_keep
                       rename=(&_s09_rename));
    %include "&gen_dir.\05_generated_spine_fill.sas";
  run;

  /* Assert spine_n rows */
  %assert_rowcount(ds=work._pcnr_accum, expected=&spine_n,
                   label=spine-loaded accumulator);
  %if &p5_fail = 1 %then %return;

  %put NOTE: [05_build_pcnr] p5_build_accumulator complete;

%mend p5_build_accumulator;

/* ============================================================
   %p5_gapfill_source(s_code=, rank=)  (Plan 04 Task 2)
   Gap-fill accumulator from one non-spine source via
   write-next-verify-replace pattern; generate per-variable
   IF blocks to gen_dir\05_generated_gapfill_<s>.sas (no CALL
   EXECUTE); detect SPINE_VS_SOURCE and SOURCE_VS_SOURCE
   conflicts; record provenance for 2+-source vars; assert
   &spine_n rows on work._pcnr_next before replacing accumulator.
   DEFINE ONLY -- called from %p5_run_gapfill.
   ============================================================ */
/* pcnr_filter=: space-separated list of quoted pcnr_name values to include,
   e.g. %str('PCNR_AGE' 'PCNR_CODE'). Leave blank for all vars (rank-order pass). */
%macro p5_gapfill_source(s_code=, rank=, pcnr_filter=, srclib=pdd, nmlib=pdd, spine_n=41150, gen_dir=);

  /* Step 1. Collect (col_name, pcnr_name, var_idx, n_sources) for this source.
     If pcnr_filter is specified (pinned pass), restrict to those pcnr_names. */
  %local _n_src_vars;
  %local _pf_clause;
  %let _pf_clause = ;
  %if %bquote(&pcnr_filter) ne %bquote() %then %do;
    /* Build quoted in-list from space-separated pcnr_filter values */
    %local _pf_i _pf_word _pf_list;
    %let _pf_list = ;
    %let _pf_i = 1;
    %let _pf_word = %scan(&pcnr_filter, &_pf_i, %str( ));
    %do %while(%bquote(&_pf_word) ne %bquote());
      %if %bquote(&_pf_list) ne %bquote() %then %let _pf_list = &_pf_list,;
      %let _pf_list = &_pf_list "&_pf_word";
      %let _pf_i = %eval(&_pf_i + 1);
      %let _pf_word = %scan(&pcnr_filter, &_pf_i, %str( ));
    %end;
    %let _pf_clause = and nm.pcnr_name in (&_pf_list);
  %end;

  proc sql noprint;
    create table work._gf_cols_&s_code as
    select nm.col_name,
           nm.pcnr_name,
           nv.var_idx,
           nv.result_type,
           nv.max_length,
           nv.type_conflict,
           nv.n_sources
    from &nmlib..name_map as nm
    inner join work._nmv as nv
      on nm.pcnr_name = nv.pcnr_name
    where nm.s_code = "&s_code"
      and nm.status = 'PCNR'
      &_pf_clause
    order by nv.var_idx;

    select count(*) into :_n_src_vars trimmed
    from work._gf_cols_&s_code;
  quit;
  %if &sqlrc > 4 %then %do;
    %fail_out(msg=%str(p5_gapfill_source SQL failed building _gf_cols_&s_code (sqlrc=&sqlrc)));
    %if &p5_fail = 1 %then %return;
  %end;

  /* Skip sources contributing 0 PCNR_ variables */
  %if &_n_src_vars = 0 %then %do;
    %put NOTE: [05_build_pcnr] source &s_code contributes 0 PCNR_ variables -- skipped;
    %return;
  %end;
  %put NOTE: [05_build_pcnr] source &s_code contributes &_n_src_vars PCNR_ variables (rank=&rank);

  /* Step 2. Sort source to work (item 2 -- never sort &srclib..src_* in place) */
  %local _gf_keep _gf_rename _i _gf_rn_n;
  %let _gf_keep   = norm_psid;
  %let _gf_rename = ;
  %let _gf_rn_n   = 0;
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

  proc sort data=&srclib..src_&s_code
    out=work._src_&s_code (keep=&_gf_keep rename=(&_gf_rename_str));
    by norm_psid;
  run;

  /* Step 3. Collect source column types from dictionary.columns for _S#### ATTRIB.
     Stores: col_name, src_type ($4: 'num'/'char'), src_length (8) */
  proc sql noprint;
    create table work._gf_dict_&s_code as
    select upcase(d.name) as col_name_uc length=200,
           d.type         as src_type    length=4,
           d.length       as src_length
    from dictionary.columns as d
    where d.libname = upcase("&srclib")
      and d.memname = upcase("SRC_&s_code");
  quit;

  /* Step 3b. Generate per-variable ATTRIB (_S####) and gap-fill/conflict IF blocks
     to gen_dir\05_generated_gapfill_&s_code..sas via DATA _NULL_ FILE=.
     No CALL EXECUTE.
     Generated code shape for one variable (type C, example):
       ATTRIB _S0042 LENGTH=$20;
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
    length col_name_uc $200 src_type $4 src_length 8
           resolved_type $8 out_length 8
           _f_alias $10 _s_alias $10 _line $500;
    if _n_ = 1 then do;
      declare hash htr(dataset: 'work._type_resolution');
      htr.definekey('pcnr_name');
      htr.definedata('resolved_type', 'out_length');
      htr.definedone();
      declare hash hdict(dataset: "work._gf_dict_&s_code");
      hdict.definekey('col_name_uc');
      hdict.definedata('src_type', 'src_length');
      hdict.definedone();
    end;
    set work._gf_cols_&s_code end=_eof;
    resolved_type = '';
    out_length    = max_length;
    if htr.find() ne 0 then do;
      if result_type = 'N' then resolved_type = 'N8';
      else                       resolved_type = 'C';
    end;
    _f_alias = cats('_F', put(var_idx, z4.));
    _s_alias = cats('_S', put(var_idx, z4.));
    /* Look up actual source column type/length */
    src_type   = 'char';
    src_length = max_length;
    col_name_uc = upcase(strip(col_name));
    if hdict.find() = 0 then do;
      /* found */
    end;
    file "&gen_dir.\05_generated_gapfill_&s_code..sas" encoding='utf-8';
    /* Write ATTRIB for _S#### with actual source type/length (Blocker 1) */
    if src_type = 'num' then do;
      _line = cat('ATTRIB ', strip(_s_alias), ' LENGTH=8;');
    end;
    else do;
      _line = cat('ATTRIB ', strip(_s_alias),
                  ' LENGTH=$', strip(put(src_length, best32.)), ';');
    end;
    put _line;
    /* Gap-fill block */
    _line = cat('/* gap-fill for ', strip(pcnr_name), ' from &s_code */');
    put _line;
    _line = cat('if missing(', strip(pcnr_name),
                ') and not missing(', strip(_s_alias), ') then do;');
    put _line;
    if resolved_type = 'N8' and type_conflict = 'Y' then do;
      /* Source _S alias is char (type-conflict); convert to numeric */
      _line = cat('  ', strip(pcnr_name),
                  ' = input(strip(', strip(_s_alias), '), ?? best32.);');
      put _line;
    end;
    else if resolved_type = 'C' and result_type = 'N' then do;
      /* Source is numeric; resolved to C: convert via PUT */
      _line = cat('  ', strip(pcnr_name),
                  ' = strip(put(', strip(_s_alias), ', best32.));');
      put _line;
    end;
    else do;
      _line = cat('  ', strip(pcnr_name), ' = ', strip(_s_alias), ';');
      put _line;
    end;
    _line = cat('  ', strip(_f_alias), ' = "&s_code";');
    put _line;
    /* Provenance output: ONLY for vars with 2+ contributing sources (W5).
       NOTE: work._prov_&s_code contains ONLY 2+-source rows
       by construction of this n_sources guard -- no additional filter needed. */
    if n_sources > 1 then do;
      _line = "  output work._prov_&s_code;";
      put _line;
    end;
    put 'end;';
    /* Conflict block -- all output columns set BEFORE output statement (Blocker 2) */
    _line = cat('else if not missing(', strip(pcnr_name),
                ') and not missing(', strip(_s_alias), ') then do;');
    put _line;
    /* D-20 equality: char uses strip(); numeric uses exact */
    if resolved_type = 'N8' then do;
      _line = cat('  if ', strip(pcnr_name), ' ne ', strip(_s_alias), ' then do;');
    end;
    else do;
      _line = cat('  if strip(', strip(pcnr_name),
                  ') ne strip(', strip(_s_alias), ') then do;');
    end;
    put _line;
    /* conflict_type: SPINE_VS_SOURCE if _F alias = 's09', else SOURCE_VS_SOURCE */
    _line = cat('    _conflict_type = ifc(strip(', strip(_f_alias),
                ") = 's09', 'SPINE_VS_SOURCE', 'SOURCE_VS_SOURCE');");
    put _line;
    _line = cat('    _winning_sc = strip(', strip(_f_alias), ');');
    put _line;
    /* winning_value: convert to $200 */
    if resolved_type = 'N8' then do;
      _line = cat('    _winning_val = strip(put(', strip(pcnr_name), ', best32.));');
      put _line;
      _line = cat('    _candidate_val = strip(put(', strip(_s_alias), ', best32.));');
      put _line;
    end;
    else do;
      _line = cat('    _winning_val = strip(', strip(pcnr_name), ');');
      put _line;
      _line = cat('    _candidate_val = strip(', strip(_s_alias), ');');
      put _line;
    end;
    _line = cat('    _candidate_sc = "', "&s_code", '";');
    put _line;
    _line = cat('    _pcnr_name_c  = "', strip(pcnr_name), '";');
    put _line;
    /* value_type: 'N' or 'C' -- set before output */
    if resolved_type = 'N8' then put "    _value_type = 'N';";
    else                          put "    _value_type = 'C';";
    /* Map internal helper vars to output column names before OUTPUT (Blocker 2) */
    put '    conflict_type    = _conflict_type;';
    put '    winning_s_code   = _winning_sc;';
    put '    winning_value    = _winning_val;';
    put '    candidate_s_code = _candidate_sc;';
    put '    candidate_value  = _candidate_val;';
    put '    value_type       = _value_type;';
    put '    pcnr_name        = _pcnr_name_c;';
    _line = "    src_s_code = '&s_code';";
    put _line;
    _line = "    output work._conflicts_&s_code;";
    put _line;
    put '  end;';
    put 'end;';
    /* After last variable, write drop _S: to remove all _S#### aliases (Blocker 1) */
    if _eof then put 'drop _S:;';
    drop col_name_uc resolved_type out_length _f_alias _s_alias _line src_type src_length;
  run;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(gapfill generator DATA step failed for source &s_code (syserr=&syserr)));
    %if &p5_fail = 1 %then %return;
  %end;
  %if not %sysfunc(fileexist("&gen_dir.\05_generated_gapfill_&s_code..sas")) %then %do;
    %fail_out(msg=%str(generated gapfill file not found after generator step: &gen_dir.\05_generated_gapfill_&s_code..sas));
    %if &p5_fail = 1 %then %return;
  %end;

  /* Clean up dictionary lookup */
  proc datasets library=work nolist;
    delete _gf_dict_&s_code;
  quit;

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
    if _a; /* keep all spine rows */
    /* Reset side-output vars */
    _conflict_type = ''; _winning_sc = ''; _winning_val = '';
    _candidate_sc  = ''; _candidate_val = ''; _value_type = '';
    _pcnr_name_c   = '';
    %include "&gen_dir.\05_generated_gapfill_&s_code..sas";
    /* Generated code sets conflict_type, winning_s_code, winning_value,
       candidate_s_code, candidate_value, value_type, pcnr_name, src_s_code
       and calls OUTPUT work._conflicts_&s_code before this point (Blocker 2).
       Helper columns are dropped in generated DROP statement below. */
    output work._pcnr_next;
    drop _conflict_type _winning_sc _winning_val _candidate_sc
         _candidate_val _value_type _pcnr_name_c _S:;
  run;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(merge/gapfill DATA step failed for source &s_code (syserr=&syserr)));
    %if &p5_fail = 1 %then %return;
  %end;

  /* Step 5. Assert spine_n rows on work._pcnr_next */
  %assert_rowcount(ds=work._pcnr_next, expected=&spine_n,
                   label=pcnr_next after &s_code);
  %if &p5_fail = 1 %then %return;

  /* Step 6. Replace accumulator (write-next-verify-replace) via PROC DATASETS rename.
     No DATA step copy -- atomic rename avoids a full pass (Performance 9). */
  proc datasets library=work nolist;
    delete _pcnr_accum;
    change _pcnr_next = _pcnr_accum;
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

  %put NOTE: [05_build_pcnr] p5_gapfill_source(&s_code) complete;

%mend p5_gapfill_source;

/* ============================================================
   %p5_run_gapfill  (Plan 04 Task 2)
   Three-pass precedence: spine pass (done in %p5_build_accumulator),
   pinned-source pass (work._override), rank-order loop (work._priority
   excluding s09 and already-pinned sources).
   DEFINE ONLY -- called from Section 2 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_run_gapfill(
  srclib=pdd,
  nmlib=pdd,
  spine_n=41150,
  gen_dir=
);

  /* Build work._pinned_pairs: (pcnr_name, s_code) pairs already handled in Pass 2.
     Used in Pass 3 to skip pinned (source, var) pairs (Blocker 6). */
  data work._pinned_pairs;
    length pcnr_name $200 s_code $4;
    stop;
  run;

  /* Pass 2 -- pinned sources from work._override.
     Only generate code for the specific pcnr_name pinned to each source (Blocker 6). */
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
    /* Call gapfill restricted to the pinned pcnr_name only (Blocker 6).
       rank=0 indicates this is a pinned override call. */
    %p5_gapfill_source(s_code=&_ov_sc, rank=0,
                       pcnr_filter=&_ov_pn,
                       srclib=&srclib, nmlib=&nmlib,
                       spine_n=&spine_n, gen_dir=&gen_dir);
    /* Record pinned pair so Pass 3 can skip it */
    data work._pinned_pairs;
      set work._pinned_pairs;
      output;
      pcnr_name = "&_ov_pn";
      s_code    = "&_ov_sc";
      output;
    run;
  %end;

  /* Sort pinned pairs for efficient lookup in Pass 3 */
  proc sort data=work._pinned_pairs nodupkey out=work._pinned_pairs;
    by pcnr_name s_code;
  run;

  /* Pass 3 -- rank-order loop; skip spine (s09); skip pinned (source, var) pairs (Blocker 6).
     For each source, build a list of pcnr_names NOT already pinned from that source,
     then call gapfill restricted to those vars. */
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
      /* Build pcnr_filter excluding any pcnr_name pinned from this source */
      %local _p3_filter _n_p3_vars;
      %let _p3_filter = ;
      proc sql noprint;
        select count(*) into :_n_p3_vars trimmed
        from &nmlib..name_map
        where s_code = "&_sc"
          and status = 'PCNR'
          and pcnr_name not in (
            select pcnr_name from work._pinned_pairs where s_code = "&_sc"
          );
      quit;
      %if &_n_p3_vars > 0 %then %do;
        /* Pass pcnr_filter as the non-pinned pcnr_name list */
        proc sql noprint;
          select distinct strip(pcnr_name)
          into :_p3_filter separated by ' '
          from &nmlib..name_map
          where s_code = "&_sc"
            and status = 'PCNR'
            and pcnr_name not in (
              select pcnr_name from work._pinned_pairs where s_code = "&_sc"
            );
        quit;
        %p5_gapfill_source(s_code=&_sc, rank=&_rk,
                           pcnr_filter=&_p3_filter,
                           srclib=&srclib, nmlib=&nmlib,
                           spine_n=&spine_n, gen_dir=&gen_dir);
      %end;
      %else %do;
        %put NOTE: [05_build_pcnr] Pass 3: source &_sc all vars pinned -- skipped;
      %end;
    %end;
  %end;

  %put NOTE: [05_build_pcnr] gap-fill loop complete across all non-spine sources;

%mend p5_run_gapfill;

/* ============================================================
   %p5_finalize_pcnr  (Plan 04 Task 3)
   Write &outlib..pcnr from accumulator; assert exact schema
   (nvars PCNR_ + NORM_PSID); &spine_n rows; 0 dup/blank norm_psid;
   0 CLOCK columns via &nmlib..name_map status='EXCLUDED_CLK';
   reconciliation sample 1,000 rows.
   DEFINE ONLY -- called from Section 3 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_finalize_pcnr(
  outlib=pdd,
  nmlib=pdd,
  srclib=pdd,
  spine_n=41150,
  nvars=1299,
  s06class_csv=
);

  /* Step 1. Write &outlib..pcnr -- drop all temp columns (Blocker 4).
     Explicit DROP instead of KEEP PCNR_: to avoid accidentally keeping _F:/_S: aliases. */

  /* Build drop list from dictionary.columns to avoid "never been referenced"
     warnings for columns absent in test runs (named helpers + _F:/_S: wildcards). */
  %local _helper_drop _hi _hword _hexists _hnames _has_f _has_s;
  %let _helper_drop = ;
  %let _hnames = pcnr_name conflict_type winning_s_code winning_value
                 candidate_s_code candidate_value value_type src_s_code;
  %let _hi = 1;
  %let _hword = %scan(&_hnames, &_hi, %str( ));
  %do %while(%bquote(&_hword) ne %bquote());
    %let _hexists = 0;
    proc sql noprint;
      select count(*) into :_hexists trimmed
      from dictionary.columns
      where libname = 'WORK'
        and memname = '_PCNR_ACCUM'
        and upcase(name) = upcase("&_hword");
    quit;
    %if &_hexists > 0 %then %let _helper_drop = &_helper_drop &_hword;
    %let _hi = %eval(&_hi + 1);
    %let _hword = %scan(&_hnames, &_hi, %str( ));
  %end;
  /* Enumerate actual _F* and _S* column names to avoid wildcard "never been referenced"
     warnings when no such columns exist (e.g. in test harnesses). */
  %local _fs_names;
  %let _fs_names = ;
  proc sql noprint;
    select name into :_fs_names separated by ' '
    from dictionary.columns
    where libname = 'WORK' and memname = '_PCNR_ACCUM'
      and (upcase(substr(name, 1, 2)) = '_F'
        or upcase(substr(name, 1, 2)) = '_S');
  quit;
  %if %bquote(&_fs_names) ne %bquote() %then
    %let _helper_drop = &_helper_drop &_fs_names;

  data &outlib..pcnr;
    set work._pcnr_accum;
    %if %bquote(&_helper_drop) ne %bquote() %then %do;
    drop &_helper_drop;
    %end;
  run;

  /* Step 2. Assert spine_n rows */
  %assert_rowcount(ds=&outlib..pcnr, expected=&spine_n, label=&outlib..pcnr);
  %if &p5_fail = 1 %then %return;

  /* Step 3. Assert 0 blank norm_psid */
  %local _n_blank_final;
  proc sql noprint;
    select count(*) into :_n_blank_final trimmed
    from &outlib..pcnr
    where norm_psid = '';
  quit;
  %if &_n_blank_final > 0 %then %do;
    %fail_out(msg=%str(&outlib..pcnr has &_n_blank_final blank norm_psid values));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] &outlib..pcnr blank norm_psid check passed (0 blank);

  /* Step 4. Assert 0 duplicate norm_psid */
  %local _n_all_f _n_dis_f;
  proc sql noprint;
    select count(*) into :_n_all_f trimmed from &outlib..pcnr;
    select count(distinct norm_psid) into :_n_dis_f trimmed from &outlib..pcnr;
  quit;
  %if &_n_all_f ne &_n_dis_f %then %do;
    %fail_out(msg=%str(&outlib..pcnr has duplicate norm_psid: total=&_n_all_f distinct=&_n_dis_f));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] &outlib..pcnr duplicate norm_psid check passed;

  /* Step 5. Exact column schema assertion (item 16).
     Extra columns = in &outlib..pcnr but not in &nmlib..name_map_vars (excluding norm_psid).
     Missing columns = in &nmlib..name_map_vars but not in &outlib..pcnr. */
  proc contents data=&outlib..pcnr out=work._pcnr_cols noprint; run;

  %local _n_extra _n_missing;
  proc sql noprint;
    /* Extra: columns in &outlib..pcnr (not norm_psid) absent from &nmlib..name_map_vars */
    select count(*) into :_n_extra trimmed
    from work._pcnr_cols as c
    where upcase(c.name) ne 'NORM_PSID'
      and upcase(c.name) not in (
        select upcase(pcnr_name) from &nmlib..name_map_vars
      );

    /* Missing: pcnr_names in &nmlib..name_map_vars absent from &outlib..pcnr columns */
    select count(*) into :_n_missing trimmed
    from &nmlib..name_map_vars as v
    where upcase(v.pcnr_name) not in (
        select upcase(c.name) from work._pcnr_cols as c
      );
  quit;
  %if &_n_extra > 0 %then %do;
    %fail_out(msg=%str(&outlib..pcnr has &_n_extra extra columns not in &nmlib..name_map_vars));
  %end;
  %if &p5_fail = 1 %then %return;
  %if &_n_missing > 0 %then %do;
    %fail_out(msg=%str(&outlib..pcnr is missing &_n_missing columns from &nmlib..name_map_vars));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] &outlib..pcnr schema confirmed: exactly &nvars PCNR_ + NORM_PSID;

  /* Step 6. CLOCK check via s06_column_class.csv (item 11).
     Read CSV; for every row where class=CLOCK, assert status=EXCLUDED_CLK
     in &nmlib..name_map for s_code='s06'. */
  %local _clk_csv;
  %if %bquote(&s06class_csv) ne %bquote() %then %let _clk_csv = &s06class_csv;
  %else %let _clk_csv = &sas_path.\..\docs\s06_column_class.csv;

  %if not %sysfunc(fileexist(&_clk_csv)) %then %do;
    %fail_out(msg=%str(CLOCK CSV missing: &_clk_csv));
  %end;
  %if &p5_fail = 1 %then %return;

  data work._s06_classes;
    length col_name $200 class $40;
    infile "&_clk_csv"
           encoding='utf-8' dsd dlm=',' missover firstobs=2;
    input col_name $ class $;
    col_name = strip(col_name);
    class    = strip(class);
    if col_name = '' then delete;
  run;

  /* For each CLOCK col_name, check status=EXCLUDED_CLK in name_map where s_code='s06' */
  %local _n_clk_not_excluded;
  proc sql noprint;
    select count(*) into :_n_clk_not_excluded trimmed
    from work._s06_classes as c
    where upcase(c.class) = 'CLOCK'
      and not exists (
        select 1 from &nmlib..name_map as nm
        where upcase(nm.col_name) = upcase(c.col_name)
          and nm.s_code  = 's06'
          and nm.status  = 'EXCLUDED_CLK'
      );
  quit;
  %if &_n_clk_not_excluded > 0 %then %do;
    %fail_out(msg=%str(CLOCK check: &_n_clk_not_excluded CLOCK variables in s06_column_class.csv are NOT excluded (status ne EXCLUDED_CLK) in &nmlib..name_map));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] CLOCK check passed (all CLOCK vars have EXCLUDED_CLK in name_map);

  /* Step 7. Reconciliation sample 1,000 rows (Blocker 7).
     For each (norm_psid, var_idx) in the sample where _F* is non-blank and ne 's09':
     look up the raw source value from &srclib..src_<s_code> for the contributing source;
     compare to the accumulated PCNR_ value using D-20 equality;
     %fail_out if any mismatch. */
  %local _n_recon_nmv;
  proc sql noprint;
    select count(*) into :_n_recon_nmv trimmed from work._nmv;
  quit;

  /* 1. Draw sample of norm_psid from &outlib..pcnr (up to 1000 rows) */
  %local _recon_n;
  %if %eval(&spine_n < 1000) %then %let _recon_n = &spine_n;
  %else %let _recon_n = 1000;

  proc surveyselect data=&outlib..pcnr method=srs n=&_recon_n out=work._recon_sample noprint seed=12345;
  run;

  %local _recon_sample_n;
  proc sql noprint;
    select count(*) into :_recon_sample_n trimmed from work._recon_sample;
  quit;

  %if &_recon_sample_n > 0 %then %do;

  /* 2. Join sample keys to accumulator to get PCNR_ values AND _F* fill-origins */
  proc sort data=work._recon_sample out=work._recon_sample_s;
    by norm_psid;
  run;
  proc sort data=work._pcnr_accum out=work._accum_sorted;
    by norm_psid;
  run;

  data work._recon_with_flags;
    merge work._recon_sample_s (in=_a keep=norm_psid)
          work._accum_sorted   (in=_b);
    by norm_psid;
    if _a;
  run;

  /* 3. For each non-spine source s, merge sample PCNR_+_F values with &srclib..src_s.
     For every variable where _F=s_code, compare converted source value to PCNR_ value.
     Write mismatches to work._recon_mismatches. */
  data work._recon_mismatches;
    length norm_psid $64 pcnr_name $200 s_code $4
           accum_value $200 source_value $200 var_idx 8 n_mismatches 8;
    stop;
  run;

  %local _rs_i _rs_sc;
  %do _rs_i = 1 %to 20;
    %if &_rs_i < 10 %then %let _rs_sc = s0&_rs_i;
    %else %let _rs_sc = s&_rs_i;

    /* Skip spine */
    %if &_rs_sc = s09 %then %goto next_recon_src;

    /* Skip sources not contributing any PCNR rows */
    %local _rs_n_pcnr;
    %let _rs_n_pcnr = 0;
    proc sql noprint;
      select count(*) into :_rs_n_pcnr trimmed
      from &nmlib..name_map
      where s_code = "&_rs_sc"
        and status = 'PCNR';
    quit;
    %if &_rs_n_pcnr = 0 %then %goto next_recon_src;

    /* Skip sources not in sample fill-origins */
    %local _rs_in_sample;
    %let _rs_in_sample = 0;
    proc sql noprint;
      select count(*) into :_rs_in_sample trimmed
      from work._recon_with_flags
      where 's09' ne '' /* dummy; real check requires dynamic column scan */
      having 0 = 0; /* always check -- simpler than dynamic column scan */
    quit;

    /* For each variable contributed by this source, check sample rows */
    proc sql noprint;
      create table work._rs_vars as
      select nm.col_name,
             nm.pcnr_name,
             nv.var_idx,
             nv.result_type,
             nv.type_conflict
      from &nmlib..name_map as nm
      inner join work._nmv as nv
        on nm.pcnr_name = nv.pcnr_name
      where nm.s_code = "&_rs_sc"
        and nm.status = 'PCNR';
    quit;

    %local _rs_nv;
    proc sql noprint;
      select count(*) into :_rs_nv trimmed from work._rs_vars;
    quit;

    %if &_rs_nv = 0 %then %goto next_recon_src;
    %if %sysfunc(exist(&srclib..src_&_rs_sc)) = 0 %then %goto next_recon_src;

    /* Sort source to work and merge with sample */
    proc sort data=&srclib..src_&_rs_sc out=work._rs_src;
      by norm_psid;
    run;

    data work._rs_merged;
      merge work._recon_with_flags (in=_a) /* keep all PCNR_ and _F columns */
            work._rs_src (in=_b);
      by norm_psid;
      if _a and _b; /* inner join: only sample rows also in this source */
    run;

    /* For each variable, count mismatches where fill-origin = this source */
    %local _rs_vi_i _rs_pn _rs_vi _rs_fa _rs_cn _rs_rt _rs_tc _rs_mm;
    %do _rs_vi_i = 1 %to &_rs_nv;
      %let _rs_pn = ;
      %let _rs_vi = ;
      %let _rs_cn = ;
      %let _rs_rt = ;
      %let _rs_tc = ;
      proc sql noprint;
        select pcnr_name, var_idx, col_name, result_type, type_conflict
        into :_rs_pn trimmed, :_rs_vi trimmed, :_rs_cn trimmed,
             :_rs_rt trimmed, :_rs_tc trimmed
        from work._rs_vars (firstobs=&_rs_vi_i obs=&_rs_vi_i);
      quit;

      %let _rs_fa = _F%sysfunc(putn(&_rs_vi, z4.));
      %let _rs_mm = 0;

      /* Guard: verify _F#### and PCNR_ column both exist in work._rs_merged */
      %local _rs_fa_exists _rs_pn_exists;
      %let _rs_fa_exists = 0;
      %let _rs_pn_exists = 0;
      proc sql noprint;
        select count(*) into :_rs_fa_exists trimmed
        from dictionary.columns
        where libname = 'WORK' and memname = '_RS_MERGED'
          and upcase(name) = upcase("&_rs_fa");
        select count(*) into :_rs_pn_exists trimmed
        from dictionary.columns
        where libname = 'WORK' and memname = '_RS_MERGED'
          and upcase(name) = upcase("&_rs_pn");
      quit;
      %if &_rs_fa_exists = 0 or &_rs_pn_exists = 0 %then %do;
        %fail_out(msg=%str(reconciliation: column &_rs_fa or &_rs_pn missing from work._rs_merged -- var_idx mismatch or merge error));
        %if &p5_fail = 1 %then %goto recon_next_var;
      %end;

      /* Count mismatches: rows where fill-origin=this source AND values differ */
      %if &_rs_rt = N and &_rs_tc ne Y %then %do;
        /* Numeric var: exact equality */
        proc sql noprint;
          select count(*) into :_rs_mm trimmed
          from work._rs_merged
          where strip(&_rs_fa) = "&_rs_sc"
            and &_rs_pn ne &_rs_cn;
        quit;
      %end;
      %else %if &_rs_tc = Y %then %do;
        /* Type-conflict: compare via string after conversion */
        proc sql noprint;
          select count(*) into :_rs_mm trimmed
          from work._rs_merged
          where strip(&_rs_fa) = "&_rs_sc"
            and strip(put(&_rs_pn, best32.)) ne strip(&_rs_cn);
        quit;
      %end;
      %else %do;
        /* Character var: strip comparison */
        proc sql noprint;
          select count(*) into :_rs_mm trimmed
          from work._rs_merged
          where strip(&_rs_fa) = "&_rs_sc"
            and strip(&_rs_pn) ne strip(&_rs_cn);
        quit;
      %end;

      %if &_rs_mm > 0 %then %do;
        data work._rs_mis_row;
          length norm_psid $64 pcnr_name $200 s_code $4
                 accum_value $200 source_value $200 var_idx 8;
          norm_psid    = 'RECON_FAIL';
          pcnr_name    = "&_rs_pn";
          s_code       = "&_rs_sc";
          accum_value  = 'MISMATCH';
          source_value = 'MISMATCH';
          var_idx      = &_rs_vi;
          n_mismatches = &_rs_mm;
        run;
        proc append base=work._recon_mismatches data=work._rs_mis_row force; run;
      %end;
      %recon_next_var:
    %end; /* _rs_vi_i */

    proc datasets library=work nolist;
      delete _rs_vars _rs_src _rs_merged;
    quit;

    %next_recon_src:
  %end; /* _rs_i */

  /* 4. Assert 0 mismatches */
  %local _n_recon_mm;
  proc sql noprint;
    select count(*) into :_n_recon_mm trimmed from work._recon_mismatches;
  quit;
  %if &_n_recon_mm > 0 %then %do;
    %fail_out(msg=%str(reconciliation sample found &_n_recon_mm mismatch(es) between &outlib..pcnr and source data -- check work._recon_mismatches));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] Reconciliation sample (&_recon_n rows) verified 0 mismatches;

  /* Clean up recon work datasets */
  proc datasets library=work nolist;
    delete _recon_sample _recon_sample_s _accum_sorted _recon_with_flags
           _recon_mismatches;
  quit;

  %end; /* _recon_sample_n > 0 */
  %else %do;
    %put NOTE: [05_build_pcnr] Reconciliation sample is empty -- skipping comparison;
  %end;

  %put NOTE: [05_build_pcnr] p5_finalize_pcnr complete;

%mend p5_finalize_pcnr;

/* ============================================================
   %p5_write_qc  (Plan 04 Task 3)
   Consolidate conflicts and provenance; compute GAPFILL counts
   from _F* fill-origin columns with identity assertions; write
   export CSVs: pcnr_gapfill.csv, pcnr_conflicts_summary.csv,
   pcnr_conflicts_detail.csv (capped 5,000 rows).
   DEFINE ONLY -- called from Section 3 of 05_build_pcnr.sas.
   ============================================================ */
%macro p5_write_qc(
  outlib=pdd,
  spine_n=41150,
  export_dir=
);

  /* Step 1. Build SET list for conflicts consolidation (Blocker 3).
     Only include datasets that exist to avoid DATA step errors. */
  %local _csc _ci _conflicts_setlist _psc _pi _prov_setlist;
  %let _conflicts_setlist = ;
  %do _ci = 1 %to 20;
    %if &_ci < 10 %then %let _csc = s0&_ci;
    %else %let _csc = s&_ci;
    %if %sysfunc(exist(work._conflicts_&_csc)) %then %do;
      %let _conflicts_setlist = &_conflicts_setlist work._conflicts_&_csc;
    %end;
  %end;

  %if %bquote(&_conflicts_setlist) ne %bquote() %then %do;
    data &outlib..qc_pcnr_conflicts;
      length norm_psid $64 pcnr_name $200 conflict_type $20
             winning_s_code $4 winning_value $200
             candidate_s_code $4 candidate_value $200
             value_type $1;
      set &_conflicts_setlist;
    run;
  %end;
  %else %do;
    data &outlib..qc_pcnr_conflicts;
      length norm_psid $64 pcnr_name $200 conflict_type $20
             winning_s_code $4 winning_value $200
             candidate_s_code $4 candidate_value $200
             value_type $1;
      stop;
    run;
  %end;

  /* Step 2. Consolidate provenance from work._prov_s01..s20.
     NOTE: each work._prov_&s_code contains ONLY 2+-source variable rows
     by construction of the n_sources guard in %p5_gapfill_source.
     No additional filter is needed here (W5). */
  %let _prov_setlist = ;
  %do _pi = 1 %to 20;
    %if &_pi < 10 %then %let _psc = s0&_pi;
    %else %let _psc = s&_pi;
    %if %sysfunc(exist(work._prov_&_psc)) %then %do;
      %let _prov_setlist = &_prov_setlist work._prov_&_psc;
    %end;
  %end;

  %if %bquote(&_prov_setlist) ne %bquote() %then %do;
    data &outlib..qc_pcnr_provenance;
      length norm_psid $64 pcnr_name $200 src_s_code $4;
      set &_prov_setlist;
    run;
  %end;
  %else %do;
    data &outlib..qc_pcnr_provenance;
      length norm_psid $64 pcnr_name $200 src_s_code $4;
      stop;
    run;
  %end;

  %local _n_prov;
  proc sql noprint;
    select count(*) into :_n_prov trimmed from &outlib..qc_pcnr_provenance;
  quit;
  %put NOTE: [05_build_pcnr] &outlib..qc_pcnr_provenance row count = &_n_prov;

  /* Step 3. GAPFILL counts from fill-origin _F* columns in work._pcnr_accum.
     For each PCNR_ variable (var_idx i):
       n_spine     = rows where _F<i> = 's09'
       n_gapfilled = rows where _F<i> not in ('s09','')
       n_missing   = rows where _F<i> = ''
     Identity assertion: n_spine + n_gapfilled + n_missing = &spine_n.
     Accumulate into work._gapfill_summary (pcnr_name, n_spine, n_gapfilled,
     n_missing) plus one n_filled_<s_code> per contributing non-spine source. */

  /* Build gapfill summary in one DATA step using arrays (Performance 8).
     Arrays _fill_ over _F0001-_F<nvars> (actual count from work._nmv).
     Counts per variable: n_spine (_F='s09'), n_gapfilled (_F not in ('','s09')),
     n_missing (_F='').
     Assert per variable: n_spine + n_gapfilled + n_missing = &spine_n.
     Output: work._gapfill_counts (var_idx, n_spine, n_gapfilled, n_missing). */
  %local _n_nmv2;
  proc sql noprint;
    select count(*) into :_n_nmv2 trimmed from work._nmv;
  quit;

  /* Build pcnr_name lookup in order of var_idx (for output) */
  proc sort data=work._nmv out=work._nmv_sorted;
    by var_idx;
  run;

  /* One-pass array DATA step over work._pcnr_accum */
  data work._gapfill_counts (keep=var_idx n_spine n_gapfilled n_missing);
    array _fill_ {&_n_nmv2} $ 4 _F0001-_F%sysfunc(putn(&_n_nmv2, z4.));
    array _nsp   {&_n_nmv2} 8 _nsp1-_nsp&_n_nmv2   (   &_n_nmv2 * 0 );
    array _ngf   {&_n_nmv2} 8 _ngf1-_ngf&_n_nmv2   (   &_n_nmv2 * 0 );
    array _nms   {&_n_nmv2} 8 _nms1-_nms&_n_nmv2   (   &_n_nmv2 * 0 );
    retain _nsp: _ngf: _nms: 0;
    set work._pcnr_accum end=_eof;
    do _vi = 1 to &_n_nmv2;
      if _fill_{_vi} = 's09' then _nsp{_vi} + 1;
      else if _fill_{_vi} ne '' then _ngf{_vi} + 1;
      else _nms{_vi} + 1;
    end;
    if _eof then do;
      do var_idx = 1 to &_n_nmv2;
        n_spine    = _nsp{var_idx};
        n_gapfilled = _ngf{var_idx};
        n_missing  = _nms{var_idx};
        output;
      end;
    end;
    keep var_idx n_spine n_gapfilled n_missing;
  run;

  /* Assert identity and join pcnr_name */
  data work._gapfill_summary;
    length pcnr_name $200 n_spine 8 n_gapfilled 8 n_missing 8;
    merge work._gapfill_counts (in=_a)
          work._nmv_sorted     (in=_b keep=var_idx pcnr_name);
    by var_idx;
    if _a;
    _id_check = n_spine + n_gapfilled + n_missing;
    if _id_check ne &spine_n then do;
      put "ERROR: GAPFILL identity assertion failed for " pcnr_name
          " sp=" n_spine " gf=" n_gapfilled " ms=" n_missing
          " total=" _id_check " expected=&spine_n";
      abort cancel;
    end;
    keep pcnr_name n_spine n_gapfilled n_missing;
  run;

  %put NOTE: [05_build_pcnr] GAPFILL identity assertions passed for all &_n_nmv2 variables;

  proc export data=work._gapfill_summary
    outfile="&export_dir.\pcnr_gapfill.csv"
    dbms=csv replace;
  run;
  %put NOTE: [05_build_pcnr] pcnr_gapfill.csv written to export_dir;

  /* Step 4. Conflict summary (item 15) */
  proc sql noprint;
    create table work._conflict_summary as
    select pcnr_name,
           conflict_type,
           count(*) as n_conflict_events,
           count(distinct cats(norm_psid, '|', pcnr_name)) as n_conflict_cells
    from &outlib..qc_pcnr_conflicts
    group by pcnr_name, conflict_type;
  quit;

  proc export data=work._conflict_summary
    outfile="&export_dir.\pcnr_conflicts_summary.csv"
    dbms=csv replace;
  run;
  %put NOTE: [05_build_pcnr] pcnr_conflicts_summary.csv written to export_dir;

  /* Step 5. Conflict detail -- cap at 5,000 rows */
  %local _n_total_conflicts;
  proc sql noprint;
    select count(*) into :_n_total_conflicts trimmed
    from &outlib..qc_pcnr_conflicts;
  quit;

  data work._conflicts_cap;
    set &outlib..qc_pcnr_conflicts (obs=5000);
  run;

  proc export data=work._conflicts_cap
    outfile="&export_dir.\pcnr_conflicts_detail.csv"
    dbms=csv replace;
  run;

  %if &_n_total_conflicts > 5000 %then %do;
    %put NOTE: [05_build_pcnr] conflicts detail capped at 5000 rows, full table in &outlib..qc_pcnr_conflicts (total=&_n_total_conflicts);
  %end;
  %put NOTE: [05_build_pcnr] pcnr_conflicts_detail.csv written to export_dir;

  %put NOTE: [05_build_pcnr] p5_write_qc complete;

%mend p5_write_qc;
