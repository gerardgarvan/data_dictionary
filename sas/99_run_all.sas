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


/* =========================================================================
   PHASE SELECTOR -- read PDD_PHASES from -set (run_pipeline.cmd) or default
   ========================================================================= */

/* _phase_in(n) -- 1 if n is in space-delimited &pdd_phases_run, else 0.
   Uses indexw to avoid substring false-match (e.g. "2" in "20"). */
%macro _phase_in(n);
  %if %sysfunc(indexw(&pdd_phases_run, &n)) > 0 %then 1;
  %else 0;
%mend _phase_in;

/* Prerequisite check when phase 2 is skipped. */
%macro run_hash_guard;
  %local _hg_fail _hg_ds _hg_i;
  %let _hg_fail = 0;
  %let _hg_ds = source_inventory header_inventory key_analysis id_overlap qc_s18_dup;
  %do _hg_i = 1 %to 5;
    %local _hg_name;
    %let _hg_name = %scan(&_hg_ds, &_hg_i, %str( ));
    %if not %sysfunc(exist(pdd.&_hg_name)) %then %do;
      %put ERROR: [99_run_all] hash guard: pdd.&_hg_name not found -- run full pipeline first;
      %let _hg_fail = %eval(&_hg_fail + 1);
    %end;
    %else %put NOTE: [99_run_all] hash guard: pdd.&_hg_name exists -- OK;
  %end;
  %if &_hg_fail > 0 %then %do;
    %put ERROR: [99_run_all] hash guard FAILED -- &_hg_fail prerequisite dataset(s) missing;
    %abort cancel;
  %end;
  %put NOTE: [99_run_all] hash guard passed -- all Phase 2 prerequisite datasets present;
%mend run_hash_guard;

/* Read PDD_PHASES from sas -set option; default "2 3" if not supplied.
   Normalise commas to spaces so the value is safe to pass as a macro argument. */
%macro _init_phases;
  %global pdd_phases_run;
  %local _raw;
  %let _raw = %sysfunc(translate(%sysget(PDD_PHASES), %str( ), %str(,)));
  %let _raw = %sysfunc(compbl(%superq(_raw)));
  %if %length(%superq(_raw)) = 0 %then %let pdd_phases_run = 2 3;
  %else %let pdd_phases_run = &_raw;
  %put NOTE: [99_run_all] PDD_PHASES resolved to: &pdd_phases_run;
%mend _init_phases;
%_init_phases;

/* Run phases in order; timing surrounds each. */
%macro _run_phases;

  /* =========================================================================
     PHASE 2 -- Source Guard and Header Inventory
     ========================================================================= */
  %put NOTE: [timing] phase 2 start %sysfunc(datetime(), datetime20.);
  %if %_phase_in(2) %then %do;
    %put NOTE: ---- Phase 2: Source guard and header inventory -------------;
    %include "&sas_path.\02_source_guard.sas";
    %put NOTE: ---- Phase 2 complete --------------------------------------;
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
  %put NOTE: ============================================================;
  %if &syscc <= 4 %then %do;
    %put NOTE: 99_run_all.sas -- PIPELINE COMPLETE (phases run: &pdd_phases_run);
  %end;
  %else %do;
    %put NOTE: 99_run_all.sas -- PIPELINE FAILED (syscc=&syscc phases run: &pdd_phases_run);
  %end;
  %put NOTE: Logs are in: &logs_path;
  %put NOTE: Output is in: &out_root;
  %put NOTE: ============================================================;
%mend _pipeline_status;
%_pipeline_status;
