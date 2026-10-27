/*==========================================================================
  Program : 06_profile.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 6 -- run %pdd_profile on pdd.pcnr.
            Reads pdd.pcnr + pdd.name_map, writes pdd.prf_pcnr and
            exchange\profile_pcnr.csv.

  Reads   : pdd.pcnr      (built by Phase 5)
            pdd.name_map  (built by Phase 4)

  Writes  : pdd.prf_pcnr
            exchange\profile_pcnr.csv

  PCM compliance:
    C1  No ?? in PROC SQL
    C2  No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH AS)
    C3  No open-code %if/%else outside %macro
    C9  LIBNAME engine before path
    C11 No macro keyword in quoted PUT string
    C13 All macro definitions in Section 0 before first call
    C14 No bare data;/set;

  Author  : GSD Phase 06 Plan 03
==========================================================================*/


/* ============================================================
   SECTION 0 -- %include config, %pdd_lib, macro library

   When running standalone (in_pipeline not set or = 0):
     %include 00_config.sas and call %pdd_lib to assign pdd libref.
   When running inside 99_run_all.sas (in_pipeline=1):
     config and %pdd_lib already ran; skip them.

   Macros defined here (before first call, PCM C13):
     %_p6_standalone_init -- loads config + pdd_lib if not in pipeline
     %_p6_check_result    -- checks &p6_fail and &syscc after profiler call
   All other macros brought in by 06_profile_macros.sas.
   ============================================================ */

%macro _p6_standalone_init;
  %global in_pipeline;
  %if %symexist(in_pipeline) = 0 %then %let in_pipeline = 0;
  %if %bquote(&in_pipeline) = %bquote() %then %let in_pipeline = 0;
  %if &in_pipeline = 0 %then %do;
    %include "C:\data_dictionary\sas\00_config.sas";
    %pdd_lib;
  %end;
%mend _p6_standalone_init;
%_p6_standalone_init;

%include "&sas_path.\06_profile_macros.sas";

/* Manifest write — called only from _p6_check_result success branch */
%macro _p6_write_manifest;
  %local _p6m_modate _p6m_nobs _p6m_dttm;
  proc sql noprint;
    select put(modate, 16.), nobs
    into :_p6m_modate trimmed, :_p6m_nobs trimmed
    from dictionary.tables
    where libname='PDD' and memname='PCNR';
  quit;
  %let _p6m_dttm = %sysfunc(datetime(), datetime20.);
  data _null_;
    file "&exchange_path.\profile_PCNR_manifest.csv" dsd lrecl=500;
    put "pcnr_modate,pcnr_nobs,run_dttm";
    put "&_p6m_modate.,&_p6m_nobs.,&_p6m_dttm.";
  run;
  %put NOTE: P6-MANIFEST: profile_PCNR_manifest.csv written (modate=&_p6m_modate, nobs=&_p6m_nobs).;
%mend _p6_write_manifest;

%macro _p6_check_result;
  %global p6_fail p6_fail_msg;
  %if %symexist(p6_fail) = 0 %then %let p6_fail = 0;
  %if %bquote(&p6_fail) = %bquote() %then %let p6_fail = 0;
  %if &p6_fail ne 0 %then %do;
    %put ERROR: [06_profile] pdd_profile failed -- &p6_fail_msg;
  %end;
  %else %if &syscc > 4 %then %do;
    %put ERROR: [06_profile] pdd_profile ended with syscc=&syscc;
  %end;
  %else %do;
    %put NOTE: [06_profile] Phase 6 complete.;
    /* Write freshness manifest for Phase 7 pre-flight check */
    %_p6_write_manifest;
  %end;
%mend _p6_check_result;


/* ============================================================
   SECTION 1 -- Route log, run profiler, restore log
   ============================================================ */
%p6_route_log;

%pdd_profile(lib=pdd, ds=pcnr, prefix=PCNR_, family=PCNR,
             suppress_file="C:\data_dictionary\docs\profile_suppress.csv",
             categorical_file="C:\data_dictionary\docs\profile_categorical.csv");

%p6_restore_log;

%_p6_check_result;
