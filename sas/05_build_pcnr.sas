/*==========================================================================
  Program : 05_build_pcnr.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 5 -- Build PCNR_ on the spine.
            Starts from pdd.src_s09 (spine, 41,150 rows), left-joins all
            other 1:1 PRECEDE_STUDY_ID sources using Phase 4 name map,
            applies gap-fill and type resolution, writes pdd.pcnr.

  Reads   : pdd.src_s01..pdd.src_s20 (all sources)
            pdd.name_map_vars (PCNR_ variable roster from Phase 4)
            docs\pcnr_source_priority.csv (D-15 gap-fill rank order)
            docs\pcnr_source_override.csv (D-05b per-variable source pin)

  Writes  : pdd.pcnr (41,150 rows x 1,299 PCNR_ + NORM_PSID)
            pdd.qc_pcnr_conflicts
            exchange\pcnr_gapfill.csv

  PCM compliance:
    C1  No ?? in PROC SQL
    C2  No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH AS)
    C3  No open-code %if/%else outside %macro
    C9  LIBNAME engine before path
    C11 No macro keyword in quoted PUT string
    C13 All macro definitions in Section 0 before first call
    C14 No bare data;/set;

  Author  : GSD Phase 05 Plan 01
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

%route_log;

%put NOTE: [05_build_pcnr] stub -- Wave 2 fills the macros and sections;

%restore_log;
