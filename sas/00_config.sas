/*==========================================================================
  Program : 00_config.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Single source of truth for all path macro variables.
            Every pipeline program starts with:
              %include "C:\data_dictionary\sas\00_config.sas";
            and then references &sas_path, &raw_master, &out_root,
            &qc_path, &logs_path, &out_path -- never hardcoding them again.
  Paths   : Code on C: (git). Data, QC, logs on P: (PHI -- outside git).
  Author  :
  Notes   : Mirror pattern from _reference_old/sas/00_config.sas.
            Do NOT copy data paths or the g/source library references.
==========================================================================*/

/* ===== 1. SAS SESSION OPTIONS ===========================================
   Set before macros so options are active for the whole session.
   ===================================================================== */
options validvarname=v7;
options mprint nofmterr nodate nonumber ps=max ls=200;

/* ===== 2. PATH MACRO VARIABLES ==========================================
   Locked values -- do not change without updating all downstream programs.
   ===================================================================== */

/* ---- Code path (C: -- in git) ---- */
%let sas_path   = C:\data_dictionary\sas;

/* ---- Data paths (P: -- NOT in git, PHI lives here) ---- */
%let raw_master = P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data;
%let out_root   = P:\PeCAN Master Data\Gerard\data_dictionary;
%let qc_path    = &out_root.\qc;
%let logs_path  = &out_root.\logs;
%let out_path   = &out_root.\out;

/* ===== 3. OUTPUT FOLDER AUTO-CREATION ===================================
   options dlcreatedir causes each libname assignment to create the target
   folder if it does not already exist. Temporary librefs _pdd* are used
   for this purpose only; they are NOT the pdd libref used by programs.
   ===================================================================== */
options dlcreatedir;
libname _pddout  "&out_root.";
libname _pddqc   "&qc_path.";
libname _pddlogs "&logs_path.";
libname _pddout2 "&out_path.";
options nodlcreatedir;

/* ===== 4. %PDD_LIB MACRO ================================================
   Called by every downstream program at its top to assign libname pdd.
   Usage: %pdd_lib;
   ===================================================================== */
%macro pdd_lib;
  options dlcreatedir;
  libname pdd "&out_root.";
  options nodlcreatedir;
%mend pdd_lib;

/* ===== 5. EARLY GUARD MACROS ============================================
   %check_encoding -- aborts if SAS session is not UTF-8.
     Call immediately after %include "00_config.sas" in each program.
     UTF-8 is required for Base_Procedure_1 (esophagectomy rows).
     Set via -config "...nls\u8\sasv9.cfg" on the sas.exe command line;
     the run_pipeline.cmd driver does this automatically.
   %check_pdd_lib  -- aborts if %pdd_lib failed to assign the pdd libref.
     Call immediately after %pdd_lib; in each program so a bad P: path
     stops the run with a clear message instead of cascading OBS=0 errors.
   Both macros call %fail_out, so they MUST be called after %fail_out is
   defined in the calling program (i.e. after Section 1 macros are compiled).
   They are defined here so they are available to all programs via %include.
   ===================================================================== */
%macro check_encoding;
  /* %put before the %if so the actual value is always visible in the log */
  %put NOTE: [00_config] sysencoding = &sysencoding;
  /* Quote both sides: unquoted utf-8 causes %EVAL to parse - as subtraction */
  %if "%lowcase(&sysencoding)" ne "utf-8" %then %do;
    %fail_out(msg=%str(SESSION ENCODING ERROR -- sysencoding=&sysencoding expected utf-8. Add -config ".../nls/u8/sasv9.cfg" to the sas.exe call; run_pipeline.cmd does this automatically));
  %end;
  %put NOTE: [00_config] sysencoding check passed (UTF-8 confirmed);
%mend check_encoding;

%macro check_pdd_lib;
  %if %sysfunc(libref(pdd)) ne 0 %then %do;
    %fail_out(msg=%str(FATAL -- pdd library not assigned. Check out_root path and P: drive mapping. out_root=&out_root));
  %end;
  %put NOTE: [00_config] pdd library assigned OK (&out_root);
%mend check_pdd_lib;

/* ===== 6. IN_PIPELINE GUARD =============================================
   0 = running standalone; the program redirects the log to its own file.
   1 = running under 99_run_all.sas, which owns the master log.

   The %SYMEXIST guard is essential. 99_run_all.sas sets in_pipeline=1
   after its own include, but every phase program then re-includes THIS
   file. An unconditional %let would reset the flag to 0 on every phase,
   so each program would redirect the log to its own file and the master
   log would have a hole exactly where a failure needs investigating.

   Wrapped in a macro on purpose. In OPEN CODE, %IF/%THEN requires a %DO
   block -- a bare statement after %THEN makes SAS report "Expected %DO
   not found" and then skip forward hunting for a %END, swallowing the
   rest of the file. Inside a macro definition the bare form is fine. This
   bit once: an open-code version here made 99_run_all.sas execute nothing
   at all.

   envlen returns -1 silently when absent -- safer than %sysget which logs
   a WARNING.
   ===================================================================== */
%macro _set_pipeline_default;
  /* If in_pipeline was already set (e.g. by an older %include chain), do not overwrite. */
  %if not %symexist(in_pipeline) %then %do;
    %global in_pipeline;
    %let in_pipeline = 0;
  %end;
  /* Detect batch driver: -set RUN_ALL 1 sets an OS env var readable by envlen/sysget. */
  %if %sysfunc(envlen(RUN_ALL)) > 0 %then %do;
    %if %sysget(RUN_ALL) = 1 %then %let in_pipeline = 1;
  %end;
%mend _set_pipeline_default;
%_set_pipeline_default;

/* ===== 7. LOG ECHO BLOCK ================================================
   Echo every macro variable for log traceability.
   ===================================================================== */
%put NOTE: [00_config] sas_path    = &sas_path;
%put NOTE: [00_config] raw_master  = &raw_master;
%put NOTE: [00_config] out_root    = &out_root;
%put NOTE: [00_config] qc_path     = &qc_path;
%put NOTE: [00_config] logs_path   = &logs_path;
%put NOTE: [00_config] out_path    = &out_path;
%put NOTE: [00_config] in_pipeline = &in_pipeline;
