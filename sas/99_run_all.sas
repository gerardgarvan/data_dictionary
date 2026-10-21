/*==========================================================================
  Program  : 99_run_all.sas
  Project  : PeCAN Data Dictionary (PDD)
  Purpose  : Full pipeline runner. %includes all phase programs in order.
             Any %abort cancel in an included program stops execution
             immediately; the log shows which phase failed.

  Pipeline :
    Phase 2  02_source_guard.sas    -- SHA-256 source guard + header inventory
    Phase 3  03_import.sas          -- direct import of 20 raw sources
    Phase 4  04_name_map.sas        -- original header to PCNR_ name map
    Phase 5  05_build_pcnr.sas      -- assemble PCNR_ on the spine
    Phase 6  06_profile.sas         -- %pdd_profile distribution engine
    Phase 7  07_dictionary_xlsx.sas -- workbook writer

  Usage (batch -- canonical):
    run_pipeline.cmd  (at repo root)

  Usage (standalone):
    sas -sysin "C:\data_dictionary\sas\99_run_all.sas"
        -log   "P:\PeCAN Master Data\Gerard\data_dictionary\logs\99_run_all.log"

  Note: Code on C: (git). Logs and data on P: (outside git).
==========================================================================*/

options mprint nofmterr nodate nonumber ps=max ls=200;

/* ---- Single path config; all macros (&sas_path etc.) resolve from here ---- */
%include "C:\data_dictionary\sas\00_config.sas";

/* This runner owns the master log. Setting in_pipeline=1 prevents individual
   programs from redirecting the log to their own per-program file.           */
%let in_pipeline = 1;

%put NOTE: ============================================================;
%put NOTE: 99_run_all.sas -- PeCAN Data Dictionary pipeline start;
%put NOTE: sas_path    = &sas_path;
%put NOTE: raw_master  = &raw_master;
%put NOTE: out_root    = &out_root;
%put NOTE: logs_path   = &logs_path;
%put NOTE: ============================================================;


/* Assign pdd libref once, before any phase runs (including the hash guard
   that checks pdd.source_inventory when Phase 2 is skipped).              */
%pdd_lib;
%check_encoding;
%check_pdd_lib;

/* =========================================================================
   PHASE SELECTOR -- read PDD_PHASES from -set (run_pipeline.cmd) or default
   ========================================================================= */

/* _phase_in(n) -- 1 if n is in space-delimited &pdd_phases_run, else 0.
   Uses indexw to avoid substring false-match (e.g. "2" in "20"). */
%macro _phase_in(n);
  %if %sysfunc(indexw(&pdd_phases_run, &n)) > 0 %then 1;
  %else 0;
%mend _phase_in;

/* Prerequisite check when Phase 2 is skipped.
   Recomputes all 20 source SHA-256 values via certutil and compares them to
   docs/source_guard_baseline.csv -- same logic as 02_source_guard run_hash_guard.
   Aborts on any hash drift or missing baseline.                              */
%macro run_hash_guard;
  %local _baseline_path _n_base_rows;
  %let _baseline_path = C:\data_dictionary\docs\source_guard_baseline.csv;
  %let _n_base_rows = 0;

  /* ---- Build work.file_list (20 source files) ---- */
  data work.file_list;
    length s_code $4 filename $200 ftype $5 full_path $500;
    infile datalines dsd dlm='|' truncover;
    input s_code $ filename $ ftype $;
    full_path = cats("&raw_master.\", filename);
    file_id + 1;
    datalines;
s01|2018-2022_PACU_STAY_20260813.csv|csv
s02|2018_2019_2020_Induction_Emergent20231121.csv|csv
s03|2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv|csv
s04|2018_2019_ENCOUNTER_Crypto_Data_20260814.csv|csv
s05|2018_2019_MRN_Crypto_Data20260814.csv|csv
s06|2018_2019_Precede_Database.xlsx|xlsx
s07|2018_2019_X_MASTER_DATASET_20200801.csv|csv
s08|2018_2022_COLONOSCOPY_20240118.xlsx|xlsx
s09|2018_2022_X_MASTER_DATASET_20240402.csv|csv
s10|2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv|csv
s11|2020_Precede_Database_Edu.xlsx|xlsx
s12|2020_X_MASTER_DATASET_20210519.csv|csv
s13|2021_Education_20240124.csv|csv
s14|2021_Frailty_20240123.csv|csv
s15|2021_X_MASTER_DATASET_20230512.csv|csv
s16|2022_Education_20240124.csv|csv
s17|2022_MASTER_DATASET_20231024.csv|csv
s18|2022_RES_20230927.csv|csv
s19|ALL_AIM2_MASTER_DATASET_20210917.xlsx|xlsx
s20|All_YEARS_LAT_LONG_20231127.csv|csv
;
  %put NOTE: [99_run_all] run_hash_guard: work.file_list built;

  /* ---- Compute SHA-256 for all 20 files via certutil PIPE FILEVAR ---- */
  data work.sha_results;
    set work.file_list(keep=file_id s_code filename full_path);
    length _cmd $1000 line $400 compressed $400 sha256 $64;
    _cmd   = 'certutil -hashfile "' || strip(full_path) || '" SHA256';
    sha256 = 'FAILED';
    infile ckpipe pipe filevar=_cmd end=_done truncover lrecl=400;
    do while (not _done);
      input line $400.;
      compressed = compress(line, ' ');
      if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
        sha256 = lowcase(compressed);
    end;
    if sha256 = 'FAILED' then
      put 'WARNING: [99_run_all] SHA-256 FAILED for ' full_path=;
    keep file_id s_code filename sha256;
  run;
  %put NOTE: [99_run_all] run_hash_guard: work.sha_results built;

  /* ---- Count baseline rows ---- */
  %if %sysfunc(fileexist(&_baseline_path)) %then %do;
    data _null_;
      retain _cnt 0;
      infile "&_baseline_path" dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
      input;
      _cnt + 1;
      if _eof then call symputx('_n_base_rows', _cnt, 'L');
    run;
  %end;

  %if &_n_base_rows = 0 %then %do;
    %put ERROR: [99_run_all] run_hash_guard: baseline not found or empty (&_baseline_path);
    %put ERROR: [99_run_all] run_hash_guard: run full pipeline (Phase 2) first to seed the baseline;
    %abort cancel;
  %end;

  /* ---- Compare current hashes against baseline ---- */
  data work._hg_baseline;
    length s_code $4 filename $200 sha256_base $64;
    infile "&_baseline_path" dsd dlm=',' firstobs=2 truncover lrecl=500;
    input s_code $ filename $ sha256_base $;
  run;

  %local _n_base _n_curr _n_dup_base _n_dup_curr
         _n_only_base _n_only_curr _n_fname _n_sha;
  %let _n_base = -1; %let _n_curr = -1;
  %let _n_dup_base = -1; %let _n_dup_curr = -1;
  %let _n_only_base = -1; %let _n_only_curr = -1;
  %let _n_fname = -1; %let _n_sha = -1;

  proc sql noprint;
    select count(*) into :_n_base     trimmed from work._hg_baseline;
    select count(*) into :_n_curr     trimmed from work.sha_results;
    select count(*) into :_n_dup_base trimmed
      from (select s_code from work._hg_baseline
            group by s_code having count(*) > 1);
    select count(*) into :_n_dup_curr trimmed
      from (select s_code from work.sha_results
            group by s_code having count(*) > 1);
    select count(*) into :_n_only_base trimmed
      from work._hg_baseline b
      where not exists (select 1 from work.sha_results r
                        where upcase(strip(r.s_code)) = upcase(strip(b.s_code)));
    select count(*) into :_n_only_curr trimmed
      from work.sha_results r
      where not exists (select 1 from work._hg_baseline b
                        where upcase(strip(b.s_code)) = upcase(strip(r.s_code)));
    select count(*) into :_n_fname trimmed
      from work._hg_baseline b
      inner join work.sha_results r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.filename)) ne lowcase(strip(r.filename));
    select count(*) into :_n_sha trimmed
      from work._hg_baseline b
      inner join work.sha_results r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.sha256_base)) ne lowcase(strip(r.sha256));
  quit;

  %put NOTE: [99_run_all] run_hash_guard: n_baseline=&_n_base n_current=&_n_curr n_dup_base=&_n_dup_base n_dup_curr=&_n_dup_curr n_only_base=&_n_only_base n_only_curr=&_n_only_curr n_fname_mismatch=&_n_fname n_sha_mismatch=&_n_sha;

  %if &_n_base      = -1 %then %fail_out(msg=%str(run_hash_guard: baseline count query failed));
  %if &_n_curr      = -1 %then %fail_out(msg=%str(run_hash_guard: current-scan count query failed));
  %if &_n_dup_base  = -1 %then %fail_out(msg=%str(run_hash_guard: dup_base query failed));
  %if &_n_dup_curr  = -1 %then %fail_out(msg=%str(run_hash_guard: dup_curr query failed));
  %if &_n_only_base = -1 %then %fail_out(msg=%str(run_hash_guard: only_base query failed));
  %if &_n_only_curr = -1 %then %fail_out(msg=%str(run_hash_guard: only_curr query failed));
  %if &_n_fname     = -1 %then %fail_out(msg=%str(run_hash_guard: fname query failed));
  %if &_n_sha       = -1 %then %fail_out(msg=%str(run_hash_guard: sha query failed));

  %if &_n_base ne 20 %then
    %fail_out(msg=%str(run_hash_guard: baseline has &_n_base rows -- expected 20));
  %if &_n_curr ne 20 %then
    %fail_out(msg=%str(run_hash_guard: current scan has &_n_curr rows -- expected 20));
  %if &_n_dup_base > 0 %then
    %fail_out(msg=%str(run_hash_guard: &_n_dup_base duplicate s_code(s) in baseline));
  %if &_n_dup_curr > 0 %then
    %fail_out(msg=%str(run_hash_guard: &_n_dup_curr duplicate s_code(s) in current scan));
  %if &_n_only_base > 0 %then
    %fail_out(msg=%str(run_hash_guard: &_n_only_base s_code(s) in baseline not found in current scan));
  %if &_n_only_curr > 0 %then
    %fail_out(msg=%str(run_hash_guard: &_n_only_curr s_code(s) in current scan not found in baseline));
  %if &_n_fname > 0 %then
    %fail_out(msg=%str(run_hash_guard: &_n_fname filename(s) changed since baseline));
  %if &_n_sha > 0 %then
    %fail_out(msg=%str(SOURCE GUARD FAILED -- &_n_sha file(s) changed since baseline. Delete docs/source_guard_baseline.csv to reseed.));
  %put NOTE: [02_source_guard] PASS -- all 20 SHA-256 values and filenames match baseline;

  proc datasets lib=work nolist nowarn;
    delete _hg_baseline file_list sha_results;
  quit;
%mend run_hash_guard;

/* Read PDD_PHASES from sas -set option; default "2 3" if not supplied.
   Normalise commas to spaces so the value is safe to pass as a macro argument. */
%macro _init_phases;
  %global pdd_phases_run pdd_full_run;
  %local _raw;
  %put NOTE: [99_run_all] PDD_PHASES raw=%sysget(PDD_PHASES);
  %let _raw = %sysfunc(translate(%sysget(PDD_PHASES), %str( ), %str(,)));
  %let _raw = %sysfunc(compbl(%superq(_raw)));
  %if %length(%superq(_raw)) = 0 %then %do;
    %let pdd_phases_run = 2 3;
    %let pdd_full_run = 1;
  %end;
  %else %do;
    %let pdd_phases_run = &_raw;
    %let pdd_full_run = 0;
  %end;
  %put NOTE: [99_run_all] PDD_PHASES parsed=&pdd_phases_run full_run=&pdd_full_run;
%mend _init_phases;
%_init_phases;

%macro _validate_phases;
  %local _valid _i _tok;
  %let _valid = 2 3 4 5 6 7;
  %if %length(%superq(pdd_phases_run)) = 0 %then %do;
    %put ERROR: [99_run_all] PDD_PHASES is empty -- cannot run pipeline;
    %abort cancel;
  %end;
  %let _i = 1;
  %do %while(%scan(&pdd_phases_run, &_i, %str( )) ne %str());
    %let _tok = %scan(&pdd_phases_run, &_i, %str( ));
    %if %sysfunc(indexw(&_valid, &_tok)) = 0 %then %do;
      %put ERROR: [99_run_all] invalid phase token "&_tok" -- allowed: &_valid;
      %abort cancel;
    %end;
    %let _i = %eval(&_i + 1);
  %end;
%mend _validate_phases;
%_validate_phases;

/* Run phases in order; timing surrounds each. */
%macro _run_phases;
  %global pdd_phases_done;
  %let pdd_phases_done = ;

  /* =========================================================================
     PHASE 2 -- Source Guard and Header Inventory
     ========================================================================= */
  %put NOTE: [timing] phase 2 start %sysfunc(datetime(), datetime20.);
  %if %_phase_in(2) %then %do;
    %put NOTE: ---- Phase 2: Source guard and header inventory -------------;
    %include "&sas_path.\02_source_guard.sas";
    %put NOTE: ---- Phase 2 complete --------------------------------------;
    %let pdd_phases_done = &pdd_phases_done 2;
  %end;
  %else %do;
    %put NOTE: [99_run_all] Phase 2 skipped -- running hash guard;
    %run_hash_guard;
  %end;
  %put NOTE: [timing] phase 2 end %sysfunc(datetime(), datetime20.);


  /* =========================================================================
     PHASE 3 -- Direct Import of 20 Raw Sources
     ========================================================================= */
  %if %_phase_in(3) %then %do;
    %put NOTE: [timing] phase 3 start %sysfunc(datetime(), datetime20.);
    %put NOTE: ---- Phase 3: Direct import of 20 raw sources ------------;
    %include "&sas_path.\03_import.sas";
    %put NOTE: ---- Phase 3 complete --------------------------------------;
    %let pdd_phases_done = &pdd_phases_done 3;
    %put NOTE: [timing] phase 3 end %sysfunc(datetime(), datetime20.);
  %end;
  %else
    %put NOTE: [99_run_all] Phase 3 skipped (not in PDD_PHASES=&pdd_phases_run);

%mend _run_phases;
%_run_phases;



/* =========================================================================
   PHASE 4 -- Name Map (original header to PCNR_)
   ========================================================================= */
/*
%put NOTE: ---- Phase 4: Name map (original to PCNR_) -----------------;
%include "&sas_path.\04_name_map.sas";
%put NOTE: ---- Phase 4 complete --------------------------------------;
*/


/* =========================================================================
   PHASE 5 -- Build PCNR_ on the Spine
   ========================================================================= */
/*
%put NOTE: ---- Phase 5: Build PCNR_ on the spine ---------------------;
%include "&sas_path.\05_build_pcnr.sas";
%put NOTE: ---- Phase 5 complete --------------------------------------;
*/


/* =========================================================================
   PHASE 6 -- Distribution Engine (%pdd_profile)
   ========================================================================= */
/*
%put NOTE: ---- Phase 6: %pdd_profile distribution engine -------------;
%include "&sas_path.\06_profile.sas";
%put NOTE: ---- Phase 6 complete --------------------------------------;
*/


/* =========================================================================
   PHASE 7 -- Dictionary Workbook Writer
   ========================================================================= */
/*
%put NOTE: ---- Phase 7: Dictionary workbook writer -------------------;
%include "&sas_path.\07_dictionary_xlsx.sas";
%put NOTE: ---- Phase 7 complete --------------------------------------;
*/


/* =========================================================================
   PIPELINE COMPLETE / FAILED
   ========================================================================= */
%macro _pipeline_status;
  %local _i _tok _missing _done_norm;
  %let _missing = 0;
  %put NOTE: ============================================================;
  /* Full-run integrity: every phase in pdd_phases_run must have ran. */
  %if &pdd_full_run = 1 %then %do;
    %let _done_norm = %sysfunc(compbl(&pdd_phases_done));
    %let _i = 1;
    %do %while(%scan(&pdd_phases_run, &_i, %str( )) ne %str());
      %let _tok = %scan(&pdd_phases_run, &_i, %str( ));
      %if %sysfunc(indexw(&_done_norm, &_tok)) = 0 %then %do;
        %put ERROR: [99_run_all] full-run integrity: phase &_tok did not run (done:&pdd_phases_done);
        %let _missing = %eval(&_missing + 1);
      %end;
      %let _i = %eval(&_i + 1);
    %end;
  %end;
  %if &syscc <= 4 and &_missing = 0 %then %do;
    %put NOTE: 99_run_all.sas -- PIPELINE COMPLETE (phases run:&pdd_phases_done);
  %end;
  %else %do;
    %if &_missing > 0 %then
      %put ERROR: [99_run_all] full-run integrity FAILED -- &_missing phase(s) did not run;
    %put NOTE: 99_run_all.sas -- PIPELINE FAILED (syscc=&syscc phases run:&pdd_phases_done);
  %end;
  %put NOTE: Logs are in: &logs_path;
  %put NOTE: Output is in: &out_root;
  %put NOTE: ============================================================;
%mend _pipeline_status;
%_pipeline_status;
