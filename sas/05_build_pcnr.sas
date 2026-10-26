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

  Smoke-test switch:
    Set %let p5_smoke = 1 and supply:
      %let p5_smoke_srclib  = work;
      %let p5_smoke_outlib  = work;
      %let p5_smoke_spine_n = <n>;
      %let p5_smoke_nvars   = <n>;
      %let p5_smoke_gen_dir = <path>;
      %let p5_smoke_exp_dir = <path>;
      %let p5_smoke_pri_csv = <priority CSV path>;
      %let p5_smoke_ov_csv  = <override CSV path>;
      %let p5_smoke_cls_csv = <s06class CSV path>;
    Then %include this file.  When p5_smoke=1 the config include and
    %pdd_lib call are skipped; all macros use the supplied WORK libs and
    synthetic counts.  Real pdd.pcnr and P: paths are never touched.

  PCM compliance:
    C1  No ?? in PROC SQL
    C2  No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH AS)
    C3  No open-code %if/%else outside %macro
    C9  LIBNAME engine before path
    C11 No macro keyword in quoted PUT string
    C13 All macro definitions in Section 0 before first call
    C14 No bare data;/set;

  Author  : GSD Phase 05 Plan 05
==========================================================================*/


/* ============================================================
   SECTION 0 -- %include config, %pdd_lib, macro library

   When p5_smoke=1: skip config / %pdd_lib so the caller's LIBNAME
   assignments (work libs) and path macros stay in effect.

   Macros defined here (before first call, PCM C13):
     %_p5_set_smoke_default -- initialise p5_smoke=0 if unset
     %_p5_init_paths        -- resolve all _p5_* globals from smoke or config
     %_p5_assert_vars       -- fail before any data step if any required
                               global is missing or empty
     %route_log             -- redirect log when running standalone
     %restore_log           -- restore log after standalone run
   All other macros brought in by 05_build_pcnr_macros.sas.
   ============================================================ */

/* Initialise p5_smoke default if caller did not set it */
%macro _p5_set_smoke_default;
  %global p5_smoke;
  %if %symexist(p5_smoke) = 0 %then %let p5_smoke = 0;
  %if %bquote(&p5_smoke) = %bquote() %then %let p5_smoke = 0;
%mend _p5_set_smoke_default;
%_p5_set_smoke_default;

%macro _p5_init_paths;
  %global _p5_srclib _p5_nmlib _p5_outlib _p5_spine_n _p5_nvars
          _p5_gen_dir _p5_exp_dir
          _p5_priority_csv _p5_override_csv _p5_s06class_csv;
  %if &p5_smoke = 1 %then %do;
    /* Smoke mode: use caller-supplied WORK libs and synthetic counts */
    %let _p5_srclib       = &p5_smoke_srclib;
    %let _p5_nmlib        = &p5_smoke_srclib;   /* name_map tables in same lib */
    %let _p5_outlib       = &p5_smoke_outlib;
    %let _p5_spine_n      = &p5_smoke_spine_n;
    %let _p5_nvars        = &p5_smoke_nvars;
    %let _p5_gen_dir      = &p5_smoke_gen_dir;
    %let _p5_exp_dir      = &p5_smoke_exp_dir;
    %let _p5_priority_csv = &p5_smoke_pri_csv;
    %let _p5_override_csv = &p5_smoke_ov_csv;
    %let _p5_s06class_csv = &p5_smoke_cls_csv;
  %end;
  %else %do;
    /* Normal pipeline mode: real pdd lib and production counts */
    %include "&sas_path.\00_config.sas";
    %pdd_lib;
    %let _p5_srclib       = pdd;
    %let _p5_nmlib        = pdd;
    %let _p5_outlib       = pdd;
    %let _p5_spine_n      = 41150;
    %let _p5_nvars        = 1297; /* D-24: removed ENCRYPTED_MRN, ENCRYPTED_ENCOUNTER */
    %let _p5_gen_dir      = &exchange_path;
    %let _p5_exp_dir      = &exchange_path;
    %let _p5_priority_csv = &sas_path.\..\docs\pcnr_source_priority.csv;
    %let _p5_override_csv = &sas_path.\..\docs\pcnr_source_override.csv;
    %let _p5_s06class_csv = &sas_path.\..\docs\s06_column_class.csv;
  %end;
%mend _p5_init_paths;
%_p5_init_paths;

/* Assert all required globals are set and non-empty.
   Calls %fail_out (defined in macros file) with a descriptive message.
   This macro is called AFTER %include of the macros file (below),
   so %fail_out is defined before the assertion runs.              */
%macro _p5_assert_vars;
  %local _missing _v;
  %let _missing = ;
  %macro _chk(v);
    %if %symexist(&v) = 0 %then %let _missing = &_missing &v;
    %else %if %bquote(%superq(&v)) = %bquote() %then %let _missing = &_missing &v;
  %mend _chk;
  %_chk(sas_path)
  %_chk(in_pipeline)
  %_chk(_p5_srclib)
  %_chk(_p5_nmlib)
  %_chk(_p5_outlib)
  %_chk(_p5_spine_n)
  %_chk(_p5_nvars)
  %_chk(_p5_gen_dir)
  %_chk(_p5_exp_dir)
  %_chk(_p5_priority_csv)
  %_chk(_p5_override_csv)
  %_chk(_p5_s06class_csv)
  %if %bquote(&_missing) ne %bquote() %then %do;
    %fail_out(msg=05_build_pcnr: required macro variables missing or empty: &_missing);
  %end;
%mend _p5_assert_vars;

/* Route log to per-program file when running standalone (in_pipeline=0).
   Mirrors the pattern used in 04_name_map.sas. */
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

%include "&sas_path.\05_build_pcnr_macros.sas";

/* Run preflight variable assertion now that %fail_out is defined */
%_p5_assert_vars;


/* ============================================================
   SECTION 1 -- Preflight (D-18 assertion, spine QC, hashes)
   ============================================================ */
%route_log;

%_p5_ok(section=1);
%p5_preflight(srclib=&_p5_srclib, nmlib=&_p5_nmlib, outlib=&_p5_outlib,
              spine_n=&_p5_spine_n, nvars=&_p5_nvars,
              priority_csv=&_p5_priority_csv,
              override_csv=&_p5_override_csv,
              s06class_csv=&_p5_s06class_csv,
              gen_dir=&_p5_gen_dir, export_dir=&_p5_exp_dir);


/* ============================================================
   SECTION 2 -- Spine coverage QC (D-19 extended)
   ============================================================ */
%_p5_ok(section=2);
%p5_spine_coverage(srclib=&_p5_srclib, spine_n=&_p5_spine_n,
                   export_dir=&_p5_exp_dir);


/* ============================================================
   SECTION 3 -- Type-conflict resolution (D-02)
   ============================================================ */
%_p5_ok(section=3);
%p5_resolve_types(srclib=&_p5_srclib, nmlib=&_p5_nmlib, outlib=&_p5_outlib,
                  export_dir=&_p5_exp_dir);


/* ============================================================
   SECTION 4 -- Build accumulator (left-join all sources)
   ============================================================ */
%_p5_ok(section=4);
%p5_build_accumulator(srclib=&_p5_srclib, nmlib=&_p5_nmlib,
                      spine_n=&_p5_spine_n,
                      gen_dir=&_p5_gen_dir, export_dir=&_p5_exp_dir);


/* ============================================================
   SECTION 5 -- Gap-fill (D-15 priority order)
   ============================================================ */
%_p5_ok(section=5);
%p5_run_gapfill(srclib=&_p5_srclib, nmlib=&_p5_nmlib,
                spine_n=&_p5_spine_n, gen_dir=&_p5_gen_dir);


/* ============================================================
   SECTION 6 -- Finalize pdd.pcnr
   ============================================================ */
%_p5_ok(section=6);
%p5_finalize_pcnr(outlib=&_p5_outlib, nmlib=&_p5_nmlib, srclib=&_p5_srclib,
                  spine_n=&_p5_spine_n, nvars=&_p5_nvars,
                  s06class_csv=&_p5_s06class_csv);


/* ============================================================
   SECTION 7 -- Write QC datasets / exchange CSV
   ============================================================ */
%_p5_ok(section=7);
%p5_write_qc(outlib=&_p5_outlib, spine_n=&_p5_spine_n,
             export_dir=&_p5_exp_dir);


/* ============================================================
   SECTION 8 -- Python QC command (informational -- no shell-out)
   run_pipeline.cmd invokes write_pcnr_qc.py automatically.
   This %put is for operators running 05_build_pcnr.sas standalone.
   ============================================================ */
%put NOTE: [05_build_pcnr] Phase 5 SAS complete. Run Python QC step via run_pipeline.cmd:;
%put NOTE: [05_build_pcnr]   python python\scripts\write_pcnr_qc.py;
%put NOTE: [05_build_pcnr]   Console output: logs\write_pcnr_qc_console.txt;

/* ============================================================
   SECTION 9 -- Log integrity scan (standalone mode only).
   Scan Phase 5 log for "Invalid numeric data" or "Invalid argument"
   which indicate type-unsafe code emitted by the code generators.
   These should be impossible by construction (D-02b NULL guard + ??
   suppressor in input()); treat any occurrence as a hard stop.
   Wrapped in a macro to comply with C3 (no open-code %if/%mend).
   ============================================================ */
%macro _p5_log_scan;
  %local _p5_logfile _p5_bad_lines;
  %let _p5_logfile  = &logs_path.\05_build_pcnr.log;
  %let _p5_bad_lines = 0;
  %if %sysfunc(fileexist(&_p5_logfile)) %then %do;
    data _null_;
      infile "&_p5_logfile" encoding='utf-8' lrecl=500 end=_eof;
      input _line $500.;
      if index(upcase(_line), 'INVALID NUMERIC DATA') > 0
      or index(upcase(_line), 'INVALID ARGUMENT') > 0
      or index(_line, 'Variable') > 0 and index(_line, 'is uninitialized') > 0
      or index(_line, 'Numeric values have been converted to character') > 0
      then do;
        call symputx('_p5_bad_lines',
                     strip(put(input(symget('_p5_bad_lines'), best32.) + 1, best32.)), 'G');
        put 'ERROR: [05_build_pcnr] log-scan hit: ' _line;
      end;
    run;
    %if &_p5_bad_lines > 0 %then %do;
      %fail_out(msg=%str(log-scan: &_p5_bad_lines occurrence(s) of Invalid numeric data / Invalid argument / uninitialized variable / Numeric-to-char conversion in 05_build_pcnr.log));
    %end;
    %else %do;
      %put NOTE: [05_build_pcnr] log-scan: 0 Invalid-numeric-data / Invalid-argument lines found;
    %end;
  %end;
  %else %do;
    %put NOTE: [05_build_pcnr] log-scan skipped: log file not found (&_p5_logfile);
  %end;
%mend _p5_log_scan;

%macro _p5_log_scan_dispatch;
  %if &in_pipeline = 0 %then %_p5_log_scan;
%mend _p5_log_scan_dispatch;
%restore_log;
%_p5_log_scan_dispatch;
