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
   PHASE 2 -- Source Guard and Header Inventory
   ========================================================================= */
%put NOTE: ---- Phase 2: Source guard and header inventory -------------;
%include "&sas_path.\02_source_guard.sas";
%put NOTE: ---- Phase 2 complete --------------------------------------;



/* =========================================================================
   PHASE 3 -- Direct Import of 8 Raw Sources
   ========================================================================= */
/*
%put NOTE: ---- Phase 3: Direct import of 20 raw sources ------------;
%include "&sas_path.\03_import.sas";
%put NOTE: ---- Phase 3 complete --------------------------------------;
*/


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
   PIPELINE COMPLETE
   ========================================================================= */
%put NOTE: ============================================================;
%put NOTE: 99_run_all.sas -- PIPELINE COMPLETE;
%put NOTE: Logs are in: &logs_path;
%put NOTE: Output is in: &out_root;
%put NOTE: ============================================================;
