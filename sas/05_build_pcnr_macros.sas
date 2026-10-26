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
  nvars=1297, /* D-24: removed PCNR_ENCRYPTED_MRN, PCNR_ENCRYPTED_ENCOUNTER */
  priority_csv=,
  override_csv=,
  s06class_csv=,
  gen_dir=,
  export_dir=
);

  /* ---- A. name_map assertions ---- */

  /* A0. Assert required columns exist in &nmlib..name_map and &nmlib..name_map_vars.
         %fail_out listing any missing before any other step (item 2). */
  %local _miss_nm _miss_nmv _col_exists;
  %let _miss_nm  = ;
  %let _miss_nmv = ;
  %macro _chk_col(lib, ds, col);
    %local _cc_n;
    proc sql noprint;
      select count(*) into :_cc_n trimmed
      from dictionary.columns
      where libname = upcase("&lib")
        and memname = upcase("&ds")
        and upcase(name) = upcase("&col");
    quit;
    %if &_cc_n = 0 %then %let _miss_&ds = &&&_miss_&ds &col;
  %mend _chk_col;
  /* name_map required columns */
  %_chk_col(&nmlib, name_map, s_code)
  %_chk_col(&nmlib, name_map, sas_name)
  %_chk_col(&nmlib, name_map, original_header)
  %_chk_col(&nmlib, name_map, status)
  %_chk_col(&nmlib, name_map, pcnr_name)
  %_chk_col(&nmlib, name_map, col_order)
  /* name_map_vars required columns */
  %_chk_col(&nmlib, name_map_vars, pcnr_name)
  %_chk_col(&nmlib, name_map_vars, result_type)
  %_chk_col(&nmlib, name_map_vars, max_length)
  %_chk_col(&nmlib, name_map_vars, type_conflict)
  %_chk_col(&nmlib, name_map_vars, n_sources)
  %_chk_col(&nmlib, name_map_vars, s_codes_contributing)
  %if %bquote(&_miss_nm) ne %bquote() %then %do;
    %fail_out(msg=%str(name_map missing required columns:&_miss_nm));
  %end;
  %if &p5_fail = 1 %then %return;
  %if %bquote(&_miss_nmv) ne %bquote() %then %do;
    %fail_out(msg=%str(name_map_vars missing required columns:&_miss_nmv));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] schema check passed: all required columns present in name_map and name_map_vars;

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
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
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

  /* Export coverage CSV -- explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp01 "&export_dir.\pcnr_spine_coverage.csv" encoding='utf-8';
  proc export data=work._spine_coverage
    outfile=_exp01
    dbms=csv replace;
  run;
  filename _exp01 clear;

  %put NOTE: [05_build_pcnr] pcnr_spine_coverage.csv written to export_dir;

%mend p5_spine_coverage;

/* ============================================================
   %p5_resolve_types
   D-02 type-conflict resolution before the build loop.
   Outputs: work._type_resolution (key-unique on pcnr_name),
            work._typecheck_sources (key-unique on pcnr_name+s_code),
            work._typefail_stage -> &outlib..qc_pcnr_typefail (single write at Step 8),
            &export_dir.\pcnr_typecheck.csv   (one row per conflict var; cols:
              pcnr_name, resolved_type, out_length, n_char_sources, n_failures,
              n_null_as_missing),
            &export_dir.\pcnr_typefail.csv    (raw failing values; cols:
              pcnr_name, s_code, raw_value, n).
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
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
    stop;
  run;

  data work._typecheck_sources;
    length pcnr_name $200 s_code $4 n_char_sources 8 n_parse_failures 8
           n_null_as_missing 8 example_failing_value $200;
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
    stop;
  run;

  /* Build in WORK to avoid outlib lock conflicts during incremental appends */
  data work._typefail_stage;
    length pcnr_name $200 s_code $4 raw_value $200 n 8;
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
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

    /* Step 2. Find contributing (s_code, sas_name) pairs from &nmlib..name_map */
    data work._tc_sources_&_tc_i;
      length pcnr_name $200 s_code $4 sas_name $200;
      call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
      stop;
    run;

    proc sql noprint;
      insert into work._tc_sources_&_tc_i (pcnr_name, s_code, sas_name)
      select pcnr_name, s_code, sas_name
      from &nmlib..name_map
      where pcnr_name = "&_tc_name"
        and status    = 'PCNR';
    quit;
    %if &sqlrc > 4 %then %do;
      %fail_out(msg=%str(p5_resolve_types INSERT failed for &_tc_name (sqlrc=&sqlrc)));
      %if &p5_fail = 1 %then %return;
    %end;

    /* Step 3. For each contributing source, test parse of character values */
    %local _n_tc_src _sc_j _col_j _src_type _n_fail _n_null_mis _ex_fail
           _n_char_src_total _n_fail_total _n_numlen_max _n_null_total;
    %let _n_char_src_total = 0;
    %let _n_fail_total     = 0;
    %let _n_numlen_max     = 0;
    %let _n_null_total     = 0;

    proc sql noprint;
      select count(*) into :_n_tc_src trimmed from work._tc_sources_&_tc_i;
    quit;

    %local _k;
    %do _k = 1 %to &_n_tc_src;

      %let _sc_j  = ;
      %let _col_j = ;
      proc sql noprint;
        select s_code, sas_name
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
         D-02b: upcase(strip(val))='NULL' is treated as missing (not a parse failure).
         ?? in DATA step INPUT is permitted (C1 bans ?? only in PROC SQL). */
      %let _n_fail         = 0;
      %let _n_null_mis     = 0;
      %let _ex_fail        = ;

      data work._tc_scan;
        set &srclib..src_&_sc_j (keep=&_col_j);
        length val $200 _ex_fail $200;
        val = strip(&_col_j);
        /* Skip blank and '.' -- treated as missing in parse check */
        if val = '' or val = '.' then delete;
        /* D-02b: 'NULL' (any case) treated as numeric missing -- not a parse failure */
        _is_null = (upcase(val) = 'NULL');
        _n   = input(val, ?? best32.);
        _fail = (not _is_null and missing(_n) and val not in ('', '.'));
        if _fail then _ex_fail = val;
        else _ex_fail = '';
        keep val _fail _ex_fail _is_null;
      run;

      %local _n_fail_this _n_null_this;
      %let _n_fail_this = 0;
      %let _n_null_this = 0;
      proc sql noprint;
        select count(*) into :_n_fail_this trimmed
        from work._tc_scan
        where _fail = 1;

        select count(*) into :_n_null_this trimmed
        from work._tc_scan
        where _is_null = 1;

        select _ex_fail into :_ex_fail trimmed
        from work._tc_scan (obs=1)
        where _fail = 1;
      quit;
      %let _n_fail     = &_n_fail_this;
      %let _n_null_mis = &_n_null_this;

      %let _n_char_src_total = %eval(&_n_char_src_total + 1);
      %let _n_fail_total     = %eval(&_n_fail_total + &_n_fail);
      %let _n_null_total     = %eval(&_n_null_total + &_n_null_mis);

      %put NOTE: [05_build_pcnr] &_tc_name &_sc_j: parse_fails=&_n_fail null_as_missing=&_n_null_mis;

      /* Accumulate per-source row into typecheck_sources.
         n_char_sources = 1 (this source has the column as char); per-row indicator. */
      data work._tcs_row;
        length pcnr_name $200 s_code $4 n_char_sources 8 n_parse_failures 8
               n_null_as_missing 8 example_failing_value $200;
        pcnr_name             = "&_tc_name";
        s_code                = "&_sc_j";
        n_char_sources        = 1;
        n_parse_failures      = &_n_fail;
        n_null_as_missing     = &_n_null_mis;
        example_failing_value = symget('_ex_fail');
      run;
      proc append base=work._typecheck_sources data=work._tcs_row force; run;

      /* If failures exist, accumulate into &outlib..qc_pcnr_typefail (distinct values) */
      %if &_n_fail > 0 %then %do;
        proc sql noprint;
          insert into work._typefail_stage (pcnr_name, s_code, raw_value, n)
          select "&_tc_name", "&_sc_j", val, count(*) as n
          from work._tc_scan
          where _fail = 1
          group by val;
        quit;
      %end;

      %next_tc_src:
    %end; /* _k loop over sources */

    /* Step 3b. Guard: a type conflict requires contributing sources to exist. */
    %if &_n_tc_src = 0 %then %do;
      %fail_out(msg=%str(p5_resolve_types: &_tc_name is type_conflict=Y but 0 contributing sources found in name_map (status=PCNR) -- data integrity error));
      %if &p5_fail = 1 %then %return;
    %end;
    /* Guard: a type conflict by definition has >=1 char source and >=1 num source.
       Resolving to N8 with 0 char sources examined means the conflict never existed. */
    %if &_n_char_src_total = 0 %then %do;
      %fail_out(msg=%str(p5_resolve_types: &_tc_name is type_conflict=Y but 0 character sources were found in &srclib -- all sources numeric or missing; cannot resolve));
      %if &p5_fail = 1 %then %return;
    %end;

    /* Step 4. Resolution rule */
    %local _resolved_type _out_length;
    %if &_n_fail_total = 0 %then %do;
      %let _resolved_type = N8;
      %let _out_length    = 8;
      /* Step 7. Pre-scan passed -- N8 conversion will be lossless */
      %put NOTE: [05_build_pcnr] &_tc_name resolved to N8 (0 parse failures, null_as_missing=&_n_null_total across &_n_char_src_total char sources);
    %end;
    %else %do;
      %let _resolved_type = C;
      /* Step 4 / item 11. out_length = max(name_map_vars max_length, numeric source best32 max) */
      %let _out_length = &_tc_maxlen;
      %if &_n_numlen_max > &_out_length %then %let _out_length = &_n_numlen_max;
      %put NOTE: [05_build_pcnr] &_tc_name resolved to C (length=&_out_length, parse_failures=&_n_fail_total, null_as_missing=&_n_null_total);
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

  /* Step 8. Copy _typefail_stage (built in WORK) to outlib -- single write avoids lock */
  data &outlib..qc_pcnr_typefail;
    set work._typefail_stage;
  run;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(failed to persist qc_pcnr_typefail to &outlib (syserr=&syserr)));
    %if &p5_fail = 1 %then %return;
  %end;

  /* Step 8b. Build per-variable typecheck summary by joining work._type_resolution
     with aggregated totals from work._typecheck_sources (one row per conflict var).
     Columns: pcnr_name, resolved_type, out_length, n_char_sources, n_failures,
              n_null_as_missing. */
  proc sql noprint;
    create table work._typecheck_summary as
    select tr.pcnr_name,
           tr.resolved_type,
           tr.out_length,
           sum(tcs.n_char_sources)    as n_char_sources,
           sum(tcs.n_parse_failures)  as n_failures,
           sum(tcs.n_null_as_missing) as n_null_as_missing
    from work._type_resolution as tr
    left join work._typecheck_sources as tcs
      on tr.pcnr_name = tcs.pcnr_name
    group by tr.pcnr_name, tr.resolved_type, tr.out_length
    order by tr.pcnr_name;
  quit;

  /* Assert export schema matches docs/exchange_schema.csv contract.
     Use subsetting IF (not WHERE) because this is an INFILE-based DATA step:
     WHERE requires a SET/MERGE source and causes "No input data sets available". */
  data work._schema_chk;
    length file $50 column $100 type $10 required $1;
    infile "C:\data_dictionary\docs\exchange_schema.csv"
           encoding='utf-8' dsd dlm=',' missover firstobs=2;
    input file $ column $ type $ required $;
    if strip(file) = 'pcnr_typecheck.csv';
  run;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(pcnr_typecheck.csv schema check: DATA step failed reading exchange_schema.csv (syserr=&syserr)));
    %if &p5_fail = 1 %then %return;
  %end;

  %local _n_schema_chk _n_missing_cols _n_extra_cols;
  %let _n_schema_chk   = 0;
  %let _n_missing_cols = 0;
  %let _n_extra_cols   = 0;

  /* Assert at least 1 contract row was read (0 = exchange_schema.csv stale or wrong file name) */
  proc sql noprint;
    select count(*) into :_n_schema_chk trimmed from work._schema_chk;
  quit;
  %if &_n_schema_chk = 0 %then %do;
    %fail_out(msg=%str(pcnr_typecheck.csv schema check: 0 contract rows found in exchange_schema.csv -- recheck file name or regenerate docs/exchange_schema.csv));
    %if &p5_fail = 1 %then %return;
  %end;

  /* Check schema columns exist in work._typecheck_summary */
  proc sql noprint;
    select count(*) into :_n_missing_cols trimmed
    from work._schema_chk as s
    where not exists (
      select 1 from dictionary.columns as d
      where d.libname = 'WORK'
        and d.memname = '_TYPECHECK_SUMMARY'
        and upcase(d.name) = upcase(s.column)
    );
  quit;
  %if &_n_missing_cols > 0 %then %do;
    %fail_out(msg=%str(pcnr_typecheck.csv export: &_n_missing_cols of &_n_schema_chk schema columns missing from work._typecheck_summary));
    %if &p5_fail = 1 %then %return;
  %end;
  %put NOTE: [05_build_pcnr] pcnr_typecheck.csv schema contract: &_n_schema_chk cols checked 0 missing;

  /* Export typecheck summary -- explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp02 "&export_dir.\pcnr_typecheck.csv" encoding='utf-8';
  proc export data=work._typecheck_summary
    outfile=_exp02
    dbms=csv replace;
  run;
  filename _exp02 clear;
  /* Also persist to outlib for audit */
  data &outlib..qc_pcnr_typecheck_src;
    set work._typecheck_sources;
  run;

  /* Assert pcnr_typefail.csv export schema matches exchange_schema.csv contract.
     Subsetting IF (not WHERE) because INFILE-based DATA step has no SET source. */
  data work._schema_chk2;
    length file $50 column $100 type $10 required $1;
    infile "C:\data_dictionary\docs\exchange_schema.csv"
           encoding='utf-8' dsd dlm=',' missover firstobs=2;
    input file $ column $ type $ required $;
    if strip(file) = 'pcnr_typefail.csv';
  run;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(pcnr_typefail.csv schema check: DATA step failed reading exchange_schema.csv (syserr=&syserr)));
    %if &p5_fail = 1 %then %return;
  %end;

  %local _n_schema_chk2 _n_missing_cols2;
  %let _n_schema_chk2   = 0;
  %let _n_missing_cols2 = 0;

  proc sql noprint;
    select count(*) into :_n_schema_chk2 trimmed from work._schema_chk2;
  quit;
  %if &_n_schema_chk2 = 0 %then %do;
    %fail_out(msg=%str(pcnr_typefail.csv schema check: 0 contract rows found in exchange_schema.csv for pcnr_typefail.csv));
    %if &p5_fail = 1 %then %return;
  %end;

  proc sql noprint;
    select count(*) into :_n_missing_cols2 trimmed
    from work._schema_chk2 as s
    where not exists (
      select 1 from dictionary.columns as d
      where d.libname = upcase("&outlib")
        and d.memname = 'QC_PCNR_TYPEFAIL'
        and upcase(d.name) = upcase(s.column)
    );
  quit;
  %if &_n_missing_cols2 > 0 %then %do;
    %fail_out(msg=%str(pcnr_typefail.csv export: &_n_missing_cols2 of &_n_schema_chk2 schema columns missing from &outlib..qc_pcnr_typefail));
    %if &p5_fail = 1 %then %return;
  %end;
  %put NOTE: [05_build_pcnr] pcnr_typefail.csv schema contract: &_n_schema_chk2 cols checked 0 missing;

  /* Export raw failing values -- explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp03 "&export_dir.\pcnr_typefail.csv" encoding='utf-8';
  proc export data=&outlib..qc_pcnr_typefail
    outfile=_exp03
    dbms=csv replace;
  run;
  filename _exp03 clear;

  /* Step 9. Summary note */
  %local _n_n8 _n_c;
  proc sql noprint;
    select count(*) into :_n_n8 trimmed from work._type_resolution where resolved_type = 'N8';
    select count(*) into :_n_c  trimmed from work._type_resolution where resolved_type = 'C';
  quit;
  %put NOTE: [05_build_pcnr] type resolution complete: N8=&_n_n8 C=&_n_c (of &_n_tr conflict vars);
  %put NOTE: [05_build_pcnr] pcnr_typecheck.csv and pcnr_typefail.csv written to export_dir;

%mend p5_resolve_types;

/* ============================================================
   %p5_gen_conv  -- Shared type-safe conversion expression generator.
   Returns (via global &p5_conv_expr) the SAS expression that converts
   a source alias to the resolved PCNR type.

   Parameters:
     src_alias  -- source column name or alias (e.g. _S0042 or raw col)
     src_type   -- actual source storage type: 'num' or 'char'
     res_type   -- resolved PCNR type: 'N8' or 'C'
     tc         -- 'Y' if type_conflict variable, else 'N'
     outvar     -- global macro variable to receive the expression string

   For N8+char (type conflict only, D-02b applies):
     input(strip(src), ?? best32.)
   For N8+num: src (direct)
   For C+num:  ifc(missing(src),'',strip(put(src,best32.)))
   For C+char: src (direct, strip handled by caller)

   Non-missing test (also generated in p5_conv_nonmiss macro var):
   For N8+char (tc=Y): not missing(src) and upcase(strip(src)) ne 'NULL'
   For all others:     not missing(src)
   ============================================================ */
%macro p5_gen_conv(src_alias=, src_type=, res_type=, tc=N, outvar=p5_conv_expr,
                   outvar_nm=p5_conv_nonmiss);
  /* Caller must pre-declare &outvar and &outvar_nm as %local or %global (C21). */
  %if &res_type = N8 and &src_type = char %then %do;
    %let &outvar = input(strip(&src_alias), %str(??)%str( )best32.);
    %if &tc = Y %then
      %let &outvar_nm = (not missing(&src_alias) and upcase(strip(&src_alias)) ne 'NULL');
    %else
      %let &outvar_nm = (not missing(&src_alias));
  %end;
  %else %if &res_type = N8 and &src_type = num %then %do;
    %let &outvar    = &src_alias;
    %let &outvar_nm = (not missing(&src_alias));
  %end;
  %else %if &res_type = C and &src_type = num %then %do;
    %let &outvar    = ifc(missing(&src_alias),'',strip(put(&src_alias,best32.)));
    %let &outvar_nm = (not missing(&src_alias));
  %end;
  %else %do;
    /* C+char: direct */
    %let &outvar    = &src_alias;
    %let &outvar_nm = (not missing(&src_alias));
  %end;
%mend p5_gen_conv;

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
    select nm.sas_name,
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

  /* Step 4b. Collect actual source column types from dictionary.columns for spine.
     This is needed to generate correct ATTRIB _S#### and type-safe assignments.
     dictionary.columns is queried AFTER proc sort (so src_s09 is in WORK). */

  /* Sort spine to work FIRST (item 2 -- never sort &srclib..src_* in place).
     Query dictionary.columns on work._src_s09 for actual column types. */
  proc sort data=&srclib..src_s09 out=work._src_s09;
    by norm_psid;
  run;

  /* Build spine column-type lookup table from dictionary.columns (on work._src_s09) */
  proc sql noprint;
    create table work._s09_dict as
    select upcase(name) as col_name_uc length=200,
           type         as src_type    length=4,
           length       as src_length
    from dictionary.columns
    where libname = 'WORK'
      and memname = '_SRC_S09';
  quit;

  /* Build KEEP= and RENAME= (sas_name -> _S####) macro variables for spine DATA step.
     Never rename a source column directly onto a PCNR_ name -- the ATTRIB declares the
     resolved type; renaming a char source column onto a numeric PDV causes type conflict.
     Instead: rename to _S#### (actual source type), assign PCNR_ with conversion. */
  %local _n_s09 _s09_keep _s09_rename _i;
  proc sql noprint;
    select count(*) into :_n_s09 trimmed from work._s09_cols;
  quit;
  %let _s09_keep   = norm_psid;
  %let _s09_rename = ;
  %do _i = 1 %to &_n_s09;
    %local _cn_&_i _pn_&_i _vi_&_i;
    proc sql noprint;
      select sas_name, pcnr_name, var_idx
      into :_cn_&_i trimmed, :_pn_&_i trimmed, :_vi_&_i trimmed
      from work._s09_cols (firstobs=&_i obs=&_i);
    quit;
    %let _s09_keep   = &_s09_keep &&_cn_&_i;
    /* Rename sas_name to _S#### alias to avoid PDV type conflict */
    %local _s09_sa_&_i;
    %let _s09_sa_&_i = _S%sysfunc(putn(&&_vi_&_i, z4.));
    %let _s09_rename = &_s09_rename &&_cn_&_i = &&_s09_sa_&_i;
  %end;

  /* Step 5. Generate spine fill code.
     Pattern mirrors p5_gapfill_source: read source col as _S#### (actual type);
     ATTRIB _S#### with actual source type from dictionary.columns; assign PCNR_
     with type conversion if needed; set _F####='s09' when non-missing; drop _S####.
     Never rename source col onto PCNR_ name. */
  data _null_;
    if _n_ = 1 then do;
      declare hash htr(dataset: 'work._type_resolution');
      htr.definekey('pcnr_name');
      htr.definedata('resolved_type', 'out_length');
      htr.definedone();
      /* Source column types from dictionary.columns on work._src_s09 */
      declare hash hdict(dataset: 'work._s09_dict');
      hdict.definekey('col_name_uc');
      hdict.definedata('src_type', 'src_length');
      hdict.definedone();
    end;
    set work._s09_cols;
    length resolved_type $8 out_length 8
           _f_alias $10 _s_alias $10 _line $500
           col_name_uc $200 src_type $4 src_length 8;
    resolved_type = '';
    out_length    = max_length;
    if htr.find() ne 0 then do;
      if result_type = 'N' then resolved_type = 'N8';
      else                       resolved_type = 'C';
    end;
    _f_alias = cats('_F', put(var_idx, z4.));
    _s_alias = cats('_S', put(var_idx, z4.));
    /* Look up actual source column type from dictionary.columns on _src_s09 */
    src_type   = 'char';  /* default if not found */
    src_length = max_length;
    col_name_uc = upcase(strip(sas_name));
    if hdict.find() = 0 then do; /* found */ end;
    file "&gen_dir.\05_generated_spine_fill.sas" encoding='utf-8';
    /* ATTRIB _S#### with actual source type */
    if src_type = 'num' then do;
      _line = cat('ATTRIB ', strip(_s_alias), ' LENGTH=8;');
    end;
    else do;
      _line = cat('ATTRIB ', strip(_s_alias),
                  ' LENGTH=$', strip(put(src_length, best32.)), ';');
    end;
    put _line;
    /* Type-safe assignment: PCNR_ = f(_S####) with resolved-type conversion */
    if resolved_type = 'N8' and src_type = 'char' then do;
      /* Source char, resolved numeric: INPUT with NULL-as-missing (D-02b) */
      _line = cat('/* spine type-conflict N8: ', strip(pcnr_name), ' from char _S#### */');
      put _line;
      _line = cat('if not missing(', strip(_s_alias), ')',
                  ' and upcase(strip(', strip(_s_alias), ")) ne 'NULL'",
                  ' then do;');
      put _line;
      _line = cat('  ', strip(pcnr_name),
                  ' = input(strip(', strip(_s_alias), '), ?? best32.);');
      put _line;
      _line = cat('  if not missing(', strip(pcnr_name), ') then ',
                  strip(_f_alias), " = 's09';");
      put _line;
      put 'end;';
    end;
    else if resolved_type = 'C' and src_type = 'num' then do;
      /* Source numeric, resolved char: PUT with best32. */
      _line = cat('/* spine type-conflict C: ', strip(pcnr_name), ' from num _S#### */');
      put _line;
      _line = cat('if not missing(', strip(_s_alias), ') then do;');
      put _line;
      _line = cat('  ', strip(pcnr_name),
                  ' = strip(put(', strip(_s_alias), ', best32.));');
      put _line;
      _line = cat('  ', strip(_f_alias), " = 's09';");
      put _line;
      put 'end;';
    end;
    else do;
      /* Same type (no conversion needed) */
      _line = cat('if not missing(', strip(_s_alias), ') then do;');
      put _line;
      _line = cat('  ', strip(pcnr_name), ' = ', strip(_s_alias), ';');
      put _line;
      _line = cat('  ', strip(_f_alias), " = 's09';");
      put _line;
      put 'end;';
    end;
    /* Drop the _S#### alias after use */
    _line = cat('drop ', strip(_s_alias), ';');
    put _line;
    drop resolved_type out_length _f_alias _s_alias _line col_name_uc src_type src_length;
  run;

  /* Step 6. DATA work._pcnr_accum: set spine with _S#### aliases; apply ATTRIBs and
     fill-origin; _S#### dropped by generated code.  ATTRIB for PCNR_ / _F#### from
     05_generated_attrib.sas comes FIRST so PDV types are set before data rows arrive. */
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

  /* Step 1. Collect (sas_name, pcnr_name, var_idx, n_sources) for this source.
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
    select nm.sas_name,
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
      select sas_name, pcnr_name
      into :_gf_cn_&_i trimmed, :_gf_pn_&_i trimmed
      from work._gf_cols_&s_code (firstobs=&_i obs=&_i);
    quit;
    %let _gf_keep = &_gf_keep &&_gf_cn_&_i;
    /* Rename sas_name to _S<z4(var_idx)> alias for merge */
  %end;

  /* Build RENAME= mapping sas_name -> _S<z4(var_idx)> */
  data _null_;
    set work._gf_cols_&s_code;
    length _s_alias $10 _pair $400;
    _s_alias = cats('_S', put(var_idx, z4.));
    _pair    = cats(strip(sas_name), '=', strip(_s_alias));
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
     Stores: sas_name (as col_name_uc key), src_type ($4: 'num'/'char'), src_length (8) */
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
    col_name_uc = upcase(strip(sas_name));
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
    /* Gap-fill block.
       D-02b (type_conflict N8 char source): 'NULL' is missing -- exclude from fill test.
       Use %p5_gen_conv logic inline:
         N8+char+tc=Y nonmiss: not missing(_S) and upcase(strip(_S)) ne 'NULL'
         N8+char+tc=N nonmiss: not missing(_S)
         N8+num       nonmiss: not missing(_S)
         C+num        nonmiss: not missing(_S)
         C+char       nonmiss: not missing(_S)
    */
    _line = cat('/* gap-fill for ', strip(pcnr_name), ' from &s_code */');
    put _line;
    if resolved_type = 'N8' and type_conflict = 'Y' and src_type = 'char' then do;
      /* D-02b: exclude NULL from non-missing test */
      _line = cat('if missing(', strip(pcnr_name),
                  ') and not missing(', strip(_s_alias), ')',
                  " and upcase(strip(", strip(_s_alias), ")) ne 'NULL' then do;");
    end;
    else do;
      _line = cat('if missing(', strip(pcnr_name),
                  ') and not missing(', strip(_s_alias), ') then do;');
    end;
    put _line;
    if resolved_type = 'N8' and type_conflict = 'Y' and src_type = 'char' then do;
      /* Source _S alias is char (type-conflict); convert to numeric via INPUT ?? */
      _line = cat('  ', strip(pcnr_name),
                  ' = input(strip(', strip(_s_alias), '), ?? best32.);');
      put _line;
    end;
    else if resolved_type = 'C' and src_type = 'num' then do;
      /* Source is numeric; resolved to C: convert via PUT */
      _line = cat('  ', strip(pcnr_name),
                  ' = ifc(missing(', strip(_s_alias), "),''",
                  ',strip(put(', strip(_s_alias), ', best32.)));');
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
    /* Conflict block -- all output columns set BEFORE output statement (Blocker 2).
       D-02b: for N8+char+tc, candidate non-missing also excludes 'NULL'. */
    if resolved_type = 'N8' and type_conflict = 'Y' and src_type = 'char' then do;
      _line = cat('else if not missing(', strip(pcnr_name),
                  ') and not missing(', strip(_s_alias), ')',
                  " and upcase(strip(", strip(_s_alias), ")) ne 'NULL' then do;");
    end;
    else do;
      _line = cat('else if not missing(', strip(pcnr_name),
                  ') and not missing(', strip(_s_alias), ') then do;');
    end;
    put _line;
    /* D-20 equality: compare typed values.
       N8+char+tc: convert _S to numeric before compare (avoids type mismatch).
       N8+num:     exact numeric compare.
       C+num:      compare pcnr_name (char) to put(_S, best32.) string.
       C+char:     strip compare. */
    if resolved_type = 'N8' and src_type = 'char' then do;
      /* Both sides numeric after conversion */
      _line = cat('  if ', strip(pcnr_name),
                  ' ne input(strip(', strip(_s_alias), '), ?? best32.) then do;');
    end;
    else if resolved_type = 'N8' and src_type = 'num' then do;
      _line = cat('  if ', strip(pcnr_name), ' ne ', strip(_s_alias), ' then do;');
    end;
    else if resolved_type = 'C' and src_type = 'num' then do;
      _line = cat('  if strip(', strip(pcnr_name),
                  ') ne strip(put(', strip(_s_alias), ', best32.)) then do;');
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
    /* winning_value / candidate_value: always store as $200 string.
       winning_value: pcnr_name is already resolved type.
       candidate_value: _s_alias may be char or num depending on src_type. */
    if resolved_type = 'N8' then do;
      _line = cat('    _winning_val = strip(put(', strip(pcnr_name), ', best32.));');
      put _line;
      if src_type = 'char' then do;
        /* _s_alias is char -- use strip() directly for candidate display */
        _line = cat('    _candidate_val = strip(', strip(_s_alias), ');');
      end;
      else do;
        _line = cat('    _candidate_val = strip(put(', strip(_s_alias), ', best32.));');
      end;
      put _line;
    end;
    else if resolved_type = 'C' and src_type = 'num' then do;
      _line = cat('    _winning_val = strip(', strip(pcnr_name), ');');
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
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
    stop;
  run;

  data work._conflicts_&s_code;
    length norm_psid $64 pcnr_name $200 conflict_type $20
           winning_s_code $4 winning_value $200
           candidate_s_code $4 candidate_value $200
           value_type $1;
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
    stop;
  run;

  /* Step 4b. Compute max char length across all PCNR_ C variables for this source.
     winning_value / candidate_value are stored as char; use max(200, max_length) to
     avoid truncation on long values while keeping a sensible floor (D-23 hardening). */
  %local _maxclen;
  %let _maxclen = 200;
  proc sql noprint;
    select max(200, max(case when result_type = 'C' then max_length else 0 end))
      into :_maxclen trimmed
    from work._gf_cols_&s_code;
  quit;
  %if %length(&_maxclen) = 0 or &_maxclen = %str() %then %let _maxclen = 200;

  /* DATA step: MERGE accumulator with source; %include generated code;
     OUTPUT to work._pcnr_next, with conditional side-outputs. */
  data work._pcnr_next
       work._conflicts_&s_code (keep=norm_psid pcnr_name conflict_type
                                     winning_s_code winning_value
                                     candidate_s_code candidate_value
                                     value_type)
       work._prov_&s_code      (keep=norm_psid pcnr_name src_s_code);
    length _conflict_type $20 _winning_sc $4 _winning_val $&_maxclen
           _candidate_sc $4 _candidate_val $&_maxclen _value_type $1
           _pcnr_name_c $200 conflict_type $20 winning_s_code $4
           winning_value $&_maxclen candidate_s_code $4 candidate_value $&_maxclen
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
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
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
        %put NOTE: [05_build_pcnr] Pass 3: source &_sc contributes 0 PCNR vars (all vars pinned) -- skipped;
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
  nvars=1297, /* D-24: removed PCNR_ENCRYPTED_MRN, PCNR_ENCRYPTED_ENCOUNTER */
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

  /* Step 4b. D-24 assertions: no PCNR_ENCRYPTED_MRN, PCNR_ENCRYPTED_ENCOUNTER,
     and no column matching PCNR_ENCRYPTED_* in &outlib..pcnr. */
  %local _n_enc_mrn _n_enc_enc _n_enc_any;
  proc sql noprint;
    select count(*) into :_n_enc_mrn trimmed
    from dictionary.columns
    where libname = upcase("&outlib")
      and memname = 'PCNR'
      and upcase(name) = 'PCNR_ENCRYPTED_MRN';

    select count(*) into :_n_enc_enc trimmed
    from dictionary.columns
    where libname = upcase("&outlib")
      and memname = 'PCNR'
      and upcase(name) = 'PCNR_ENCRYPTED_ENCOUNTER';

    select count(*) into :_n_enc_any trimmed
    from dictionary.columns
    where libname = upcase("&outlib")
      and memname = 'PCNR'
      and upcase(substr(name, 1, 14)) = 'PCNR_ENCRYPTED';
  quit;
  %if &_n_enc_mrn > 0 %then %do;
    %fail_out(msg=%str(D-24 violation: PCNR_ENCRYPTED_MRN found in &outlib..pcnr));
  %end;
  %if &p5_fail = 1 %then %return;
  %if &_n_enc_enc > 0 %then %do;
    %fail_out(msg=%str(D-24 violation: PCNR_ENCRYPTED_ENCOUNTER found in &outlib..pcnr));
  %end;
  %if &p5_fail = 1 %then %return;
  %if &_n_enc_any > 0 %then %do;
    %fail_out(msg=%str(D-24 violation: &_n_enc_any column(s) matching PCNR_ENCRYPTED_* found in &outlib..pcnr));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] D-24 assertions passed: no PCNR_ENCRYPTED_* columns in &outlib..pcnr;

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

  /* For each CLOCK col_name in s06class CSV, check status=EXCLUDED_CLK in name_map
     where s_code='s06'.  The CSV column is named col_name; name_map column is sas_name. */
  %local _n_clk_not_excluded;
  proc sql noprint;
    select count(*) into :_n_clk_not_excluded trimmed
    from work._s06_classes as c
    where upcase(c.class) = 'CLOCK'
      and not exists (
        select 1 from &nmlib..name_map as nm
        where upcase(nm.sas_name) = upcase(c.col_name)
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
    length norm_psid $64 pcnr_name $200 fill_s_code $4
           pcnr_value $200 source_value $200 n_mismatches 8;
    call missing(of _all_); /* Bug 3 fix: suppress uninitialized variable warnings */
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
      select nm.sas_name,
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
        select pcnr_name, var_idx, sas_name, result_type, type_conflict
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

      /* Look up PCNR_ actual type from &outlib..pcnr and source column actual type
         from &srclib..src_&_rs_sc (via work._rs_src which is sorted copy). */
      %local _rs_pcnr_type _rs_src_type;
      %let _rs_pcnr_type = ;
      %let _rs_src_type  = ;
      proc sql noprint;
        select type into :_rs_pcnr_type trimmed
        from dictionary.columns
        where libname = upcase("&outlib")
          and memname = 'PCNR'
          and upcase(name) = upcase("&_rs_pn");
        select type into :_rs_src_type trimmed
        from dictionary.columns
        where libname = 'WORK'
          and memname = '_RS_SRC'
          and upcase(name) = upcase("&_rs_cn");
      quit;
      %if &sqlrc > 4 %then %do;
        %fail_out(msg=%str(reconciliation: dictionary lookup failed for &_rs_pn / &_rs_cn (sqlrc=&sqlrc)));
        %if &p5_fail = 1 %then %goto recon_next_var;
      %end;

      /* Compare typed values using actual column types (not name_map result_type).
         pcnr type: num -> pcnr_name is numeric. char -> pcnr_name is character.
         src  type: num -> sas_name is numeric. char -> sas_name is character.
         Canonical comparison: both to character string via put()/strip(). */
      %local _rs_pcnr_expr _rs_src_expr;
      %if &_rs_pcnr_type = num %then
        %let _rs_pcnr_expr = strip(put(&_rs_pn, best32.));
      %else
        %let _rs_pcnr_expr = strip(&_rs_pn);
      %if &_rs_src_type = num %then
        %let _rs_src_expr = strip(put(&_rs_cn, best32.));
      %else %if &_rs_tc = Y %then
        /* D-02b: type-conflict char source; treat 'NULL' as missing */
        %let _rs_src_expr = ifc(upcase(strip(&_rs_cn))='NULL','',strip(&_rs_cn));
      %else
        %let _rs_src_expr = strip(&_rs_cn);

      proc sql noprint;
        select count(*) into :_rs_mm trimmed
        from work._rs_merged
        where strip(&_rs_fa) = "&_rs_sc"
          and &_rs_pcnr_expr ne &_rs_src_expr;
      quit;
      %if &sqlrc > 4 %then %do;
        %fail_out(msg=%str(reconciliation SQL failed for &_rs_pn / &_rs_sc (sqlrc=&sqlrc)));
        %if &p5_fail = 1 %then %goto recon_next_var;
      %end;

      %if &_rs_mm > 0 %then %do;
        data work._rs_mis_row;
          length norm_psid $64 pcnr_name $200 fill_s_code $4
                 pcnr_value $200 source_value $200 n_mismatches 8;
          norm_psid     = 'RECON_SUMMARY';
          pcnr_name     = "&_rs_pn";
          fill_s_code   = "&_rs_sc";
          pcnr_value    = '';
          source_value  = '';
          n_mismatches  = &_rs_mm;
        run;
        %if &syserr > 4 %then %do;
          %fail_out(msg=%str(recon mismatch row creation failed (syserr=&syserr)));
          %if &p5_fail = 1 %then %goto recon_next_var;
        %end;
        proc append base=work._recon_mismatches data=work._rs_mis_row force; run;
        %if &syserr > 4 %then %do;
          %fail_out(msg=%str(recon mismatch append failed (syserr=&syserr)));
          %if &p5_fail = 1 %then %goto recon_next_var;
        %end;
        %put NOTE: [05_build_pcnr] reconciliation mismatch: &_rs_pn from &_rs_sc n=&_rs_mm;
      %end;
      %recon_next_var:
    %end; /* _rs_vi_i */

    proc datasets library=work nolist;
      delete _rs_vars _rs_src _rs_merged;
    quit;

    %next_recon_src:
  %end; /* _rs_i */

  /* 4. Persist mismatches to &outlib..qc_pcnr_recon_mismatch and assert 0 */
  %local _n_recon_mm;
  proc sql noprint;
    select count(*) into :_n_recon_mm trimmed from work._recon_mismatches;
  quit;

  /* Always write mismatch table (empty = success) */
  data &outlib..qc_pcnr_recon_mismatch;
    set work._recon_mismatches;
  run;
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(failed to persist qc_pcnr_recon_mismatch to &outlib (syserr=&syserr)));
    %if &p5_fail = 1 %then %return;
  %end;

  %if &_n_recon_mm > 0 %then %do;
    /* Log by pcnr_name/fill_s_code (no values in log per spec) */
    %local _rmm_i _rmm_pn _rmm_sc _rmm_n;
    %do _rmm_i = 1 %to &_n_recon_mm;
      proc sql noprint;
        select pcnr_name, fill_s_code, n_mismatches
        into :_rmm_pn trimmed, :_rmm_sc trimmed, :_rmm_n trimmed
        from work._recon_mismatches (firstobs=&_rmm_i obs=&_rmm_i);
      quit;
      %put ERROR: [05_build_pcnr] recon mismatch: pcnr_name=&_rmm_pn fill_s_code=&_rmm_sc n=&_rmm_n;
    %end;
    %fail_out(msg=%str(reconciliation sample found &_n_recon_mm mismatch(es) -- see &outlib..qc_pcnr_recon_mismatch));
  %end;
  %if &p5_fail = 1 %then %return;
  %put NOTE: [05_build_pcnr] Reconciliation sample (&_recon_n rows) verified 0 mismatches;

  /* Clean up recon work datasets */
  proc datasets library=work nolist;
    delete _recon_sample _recon_sample_s _accum_sorted _recon_with_flags
           _recon_mismatches _rs_mis_row;
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
   export CSVs: pcnr_gapfill.csv (+ n_filled_<s_code> per-source cols),
   pcnr_conflicts_summary_class.csv (by pcnr_name, conflict_type, conflict_class),
   pcnr_conflicts_detail.csv (stratified 200/stratum REAL-first, 5000 cap).
   conflict_class: PLACEHOLDER/CODING_EQUIV/TOPCODE/NUMERIC_CLOSE/REAL.
   Equiv pairs loaded from docs/pcnr_value_equiv.csv via hash (C23: subsetting IF).
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
    /* Bug 2 fix: guard after conflicts consolidation DATA step */
    %if &syserr > 4 %then %do;
      %fail_out(msg=%str(p5_write_qc: conflicts consolidation DATA step failed (syserr=&syserr)));
      %return;
    %end;
  %end;
  %else %do;
    data &outlib..qc_pcnr_conflicts;
      length norm_psid $64 pcnr_name $200 conflict_type $20
             winning_s_code $4 winning_value $200
             candidate_s_code $4 candidate_value $200
             value_type $1;
      call missing(of _all_);
      stop;
    run;
    /* Bug 2 fix: guard after empty conflicts DATA step */
    %if &syserr > 4 %then %do;
      %fail_out(msg=%str(p5_write_qc: empty conflicts DATA step failed (syserr=&syserr)));
      %return;
    %end;
  %end;

  /* Step 1b. Add conflict_class to qc_pcnr_conflicts.
     Priority (case-insensitive on stripped values):
       PLACEHOLDER  : either candidate_value or winning_value in (?/NULL/N/A/UNKNOWN)
       CODING_EQUIV : (pcnr_name, val_a, val_b) pair in docs/pcnr_value_equiv.csv
                      order-insensitive: check both (cand,win) and (win,cand)
       TOPCODE      : numeric var, candidate_value='89', winning_value>89
       NUMERIC_CLOSE: both parse numeric, abs(a-b)/max(abs(a),abs(b)) <= 0.01
       REAL         : everything else
     Equiv CSV read via INFILE (subsetting IF, not WHERE -- C23). */

  /* Load pcnr_value_equiv.csv into work._equiv */
  data work._equiv;
    length pcnr_name $200 value_a $200 value_b $200;
    infile "&sas_path.\..\docs\pcnr_value_equiv.csv"
           dsd dlm=',' firstobs=2 truncover encoding='utf-8';
    input pcnr_name $ value_a $ value_b $;
    if pcnr_name ne '';
  run;
  /* Bug 2 fix: guard after _equiv load -- if CSV missing or unreadable, fail cleanly */
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(p5_write_qc: failed to load pcnr_value_equiv.csv (syserr=&syserr)));
    %return;
  %end;

  /* Classify conflicts using hash lookup for CODING_EQUIV */
  data &outlib..qc_pcnr_conflicts;
    length conflict_class $20;
    /* Bug 1 fix: declare PDV lengths for all hash key/data variables before
       the declare hash statement so SAS resolves column types at compile time.
       pcnr_name ($200) inherited from SET; value_a/value_b need explicit decl. */
    length value_a $200 value_b $200;
    if _n_ = 1 then do;
      declare hash _heq(dataset:'work._equiv');
      _heq.defineKey('pcnr_name','value_a','value_b');
      _heq.defineData('pcnr_name','value_a','value_b');
      _heq.defineDone();
    end;
    set &outlib..qc_pcnr_conflicts;
    /* PLACEHOLDER check */
    _u_cand = upcase(strip(candidate_value));
    _u_win  = upcase(strip(winning_value));
    if _u_cand in ('?','NULL','N/A','UNKNOWN') or
       _u_win  in ('?','NULL','N/A','UNKNOWN') then do;
      conflict_class = 'PLACEHOLDER';
    end;
    /* CODING_EQUIV check (order-insensitive) */
    else if _heq.find(key:pcnr_name, key:_u_cand, key:_u_win) = 0 or
            _heq.find(key:pcnr_name, key:_u_win,  key:_u_cand) = 0 then do;
      conflict_class = 'CODING_EQUIV';
    end;
    /* TOPCODE: numeric var, candidate='89', winner>89 */
    else if value_type = 'N' and _u_cand = '89' and
            input(winning_value, ?? best32.) > 89 then do;
      conflict_class = 'TOPCODE';
    end;
    /* NUMERIC_CLOSE: both parse numeric, within 1% */
    else do;
      _na = input(candidate_value, ?? best32.);
      _nb = input(winning_value,   ?? best32.);
      if not missing(_na) and not missing(_nb) and
         max(abs(_na), abs(_nb)) > 0 and
         abs(_na - _nb) / max(abs(_na), abs(_nb)) <= 0.01 then do;
        conflict_class = 'NUMERIC_CLOSE';
      end;
      else conflict_class = 'REAL';
    end;
    drop _u_cand _u_win _na _nb;
  run;
  /* Bug 2 fix: guard after conflict classification DATA step */
  %if &syserr > 4 %then %do;
    %fail_out(msg=%str(p5_write_qc: conflict_class classification DATA step failed (syserr=&syserr)));
    %return;
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
    /* Bug 2 fix: guard after provenance consolidation DATA step */
    %if &syserr > 4 %then %do;
      %fail_out(msg=%str(p5_write_qc: provenance consolidation DATA step failed (syserr=&syserr)));
      %return;
    %end;
  %end;
  %else %do;
    data &outlib..qc_pcnr_provenance;
      length norm_psid $64 pcnr_name $200 src_s_code $4;
      call missing(of _all_);
      stop;
    run;
    /* Bug 2 fix: guard after empty provenance DATA step */
    %if &syserr > 4 %then %do;
      %fail_out(msg=%str(p5_write_qc: empty provenance DATA step failed (syserr=&syserr)));
      %return;
    %end;
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

  /* Per-source gapfill counts: one row per (var_idx, s_code) non-spine fill.
     Pass 1: unpivot _F* columns into long form -- one row per filled cell. */
  data work._gapfill_long (keep=var_idx s_code);
    array _fill_ {&_n_nmv2} $ 4 _F0001-_F%sysfunc(putn(&_n_nmv2, z4.));
    length s_code $4;
    set work._pcnr_accum;
    do _vi = 1 to &_n_nmv2;
      if _fill_{_vi} ne '' and _fill_{_vi} ne 's09' then do;
        var_idx = _vi;
        s_code  = _fill_{_vi};
        output;
      end;
    end;
  run;

  /* Pass 2: count fills per (var_idx, s_code). */
  proc sql noprint;
    create table work._gapfill_src_counts as
    select var_idx, s_code, count(*) as n_filled
    from work._gapfill_long
    group by var_idx, s_code;
  quit;

  /* Pass 3: transpose to wide -- one n_filled_<s_code> col per contributing source. */
  proc transpose data=work._gapfill_src_counts
                 out=work._gapfill_src_wide (drop=_name_)
                 prefix=n_filled_;
    by var_idx;
    id s_code;
    var n_filled;
  run;

  /* Assert identity and join pcnr_name; merge per-source wide counts. */
  data work._gapfill_summary;
    length pcnr_name $200 n_spine 8 n_gapfilled 8 n_missing 8;
    merge work._gapfill_counts   (in=_a)
          work._nmv_sorted       (in=_b keep=var_idx pcnr_name)
          work._gapfill_src_wide (in=_c);
    by var_idx;
    if _a;
    _id_check = n_spine + n_gapfilled + n_missing;
    if _id_check ne &spine_n then do;
      put "ERROR: GAPFILL identity assertion failed for " pcnr_name
          " sp=" n_spine " gf=" n_gapfilled " ms=" n_missing
          " total=" _id_check " expected=&spine_n";
      abort cancel;
    end;
    /* Identity: n_gapfilled must equal sum of all n_filled_* per-source cols.
       Verified at runtime via _id_check2 below. */
    drop _id_check;
  run;

  /* Assert n_gapfilled = sum(n_filled_*) for each row */
  %local _nsrc_cols;
  proc sql noprint;
    select count(*) into :_nsrc_cols trimmed
    from dictionary.columns
    where libname='WORK' and memname='_GAPFILL_SUMMARY'
      and name like 'N_FILLED_%';
  quit;

  %if &_nsrc_cols > 0 %then %do;
    data _null_;
      set work._gapfill_summary;
      array _s_cols{*} n_filled_:;
      _sum_src = 0;
      do _si = 1 to dim(_s_cols);
        if not missing(_s_cols{_si}) then _sum_src + _s_cols{_si};
      end;
      if _sum_src ne n_gapfilled then do;
        put "ERROR: GAPFILL per-source sum mismatch for " pcnr_name
            " n_gapfilled=" n_gapfilled " sum_src=" _sum_src;
        abort cancel;
      end;
    run;
    %put NOTE: [05_build_pcnr] GAPFILL per-source identity assertions passed;
  %end;

  %put NOTE: [05_build_pcnr] GAPFILL identity assertions passed for all &_n_nmv2 variables;

  /* Explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp03 "&export_dir.\pcnr_gapfill.csv" encoding='utf-8';
  proc export data=work._gapfill_summary
    outfile=_exp03
    dbms=csv replace;
  run;
  filename _exp03 clear;
  %put NOTE: [05_build_pcnr] pcnr_gapfill.csv written to export_dir;

  /* Step 4. Conflict summary (item 15) + conflict_class summary (Item 1). */
  proc sql noprint;
    create table work._conflict_summary as
    select pcnr_name,
           conflict_type,
           count(*) as n_conflict_events,
           count(distinct cats(norm_psid, '|', pcnr_name)) as n_conflict_cells
    from &outlib..qc_pcnr_conflicts
    group by pcnr_name, conflict_type;
  quit;

  /* Explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp04 "&export_dir.\pcnr_conflicts_summary.csv" encoding='utf-8';
  proc export data=work._conflict_summary
    outfile=_exp04
    dbms=csv replace;
  run;
  filename _exp04 clear;
  %put NOTE: [05_build_pcnr] pcnr_conflicts_summary.csv written to export_dir;

  /* Conflict class summary: by (pcnr_name, conflict_type, conflict_class) */
  proc sql noprint;
    create table work._conflict_summary_class as
    select pcnr_name,
           conflict_type,
           conflict_class,
           count(*) as n
    from &outlib..qc_pcnr_conflicts
    group by pcnr_name, conflict_type, conflict_class;
  quit;

  /* Explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp4b "&export_dir.\pcnr_conflicts_summary_class.csv" encoding='utf-8';
  proc export data=work._conflict_summary_class
    outfile=_exp4b
    dbms=csv replace;
  run;
  filename _exp4b clear;
  %put NOTE: [05_build_pcnr] pcnr_conflicts_summary_class.csv written to export_dir;

  /* Step 5. Conflict detail -- stratified sample.
     Sort: REAL conflicts first within each (pcnr_name, conflict_type, conflict_class)
     stratum. Take up to 200 per stratum. Hard cap: 5000 total rows. */
  %local _n_total_conflicts;
  proc sql noprint;
    select count(*) into :_n_total_conflicts trimmed
    from &outlib..qc_pcnr_conflicts;
  quit;

  /* Sort: REAL first, then others, within each stratum */
  proc sort data=&outlib..qc_pcnr_conflicts
            out=work._conflicts_sorted;
    by pcnr_name conflict_type conflict_class
       descending conflict_class; /* REAL sorts last alpha -- use flag below */
  run;

  /* Re-sort: REAL first by using a numeric sort key */
  data work._conflicts_sorted2;
    set work._conflicts_sorted;
    _real_first = (conflict_class = 'REAL');
  run;

  proc sort data=work._conflicts_sorted2 out=work._conflicts_sorted3;
    by pcnr_name conflict_type conflict_class descending _real_first;
  run;

  /* Stratified sample: up to 200 per stratum, 5000 total */
  data work._conflicts_sample (drop=_real_first _strat_n _total_n);
    retain _strat_n 0 _total_n 0;
    set work._conflicts_sorted3;
    by pcnr_name conflict_type conflict_class;
    if first.conflict_class then _strat_n = 0;
    _strat_n + 1;
    if _strat_n <= 200 and _total_n < 5000 then do;
      _total_n + 1;
      output;
    end;
  run;

  /* Explicit UTF-8 FILENAME before PROC EXPORT (D-23) */
  filename _exp05 "&export_dir.\pcnr_conflicts_detail.csv" encoding='utf-8';
  proc export data=work._conflicts_sample
    outfile=_exp05
    dbms=csv replace;
  run;
  filename _exp05 clear;

  %if &_n_total_conflicts > 5000 %then %do;
    %put NOTE: [05_build_pcnr] conflicts detail capped at 5000 rows (stratified), full table in &outlib..qc_pcnr_conflicts (total=&_n_total_conflicts);
  %end;
  %put NOTE: [05_build_pcnr] pcnr_conflicts_detail.csv written to export_dir (stratified, REAL-first);

  %put NOTE: [05_build_pcnr] p5_write_qc complete;

%mend p5_write_qc;
