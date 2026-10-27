/* =============================================================================
   07_build_profile.sas  --  Phase 7 SAS orchestrator
   Exports exchange CSVs; asserts manifest freshness; aborts on any failure.
   ============================================================================= */

/* Section 0 -- standalone guard + setup */
%macro _p7_standalone_init;
  %global in_pipeline;
  %if %symexist(in_pipeline) = 0 %then %let in_pipeline = 0;
  %if %bquote(&in_pipeline) = %bquote() %then %let in_pipeline = 0;
  %if &in_pipeline = 0 %then %do;
    %include "C:\data_dictionary\sas\00_config.sas";
    %pdd_lib;
  %end;
%mend _p7_standalone_init;
%_p7_standalone_init;
options mprint;
%let _p7_fail = 0;

/* Section 1 -- Confirm docs/age_variables.csv exists */
%macro p7_check_age_file;
  %if %sysfunc(fileexist(C:\data_dictionary\docs\age_variables.csv)) = 0 %then %do;
    %put ERROR: P7: docs/age_variables.csv not found -- create it with 6 age variable rows.;
    %let _p7_fail = 1;
  %end;
  %else %do;
    %put NOTE: P7: docs/age_variables.csv found.;
  %end;
%mend p7_check_age_file;
%p7_check_age_file;

/* Section 2 -- Always export source_inventory.csv and name_map_dict.csv */
%macro p7_export_tables;
  proc export data=pdd.source_inventory
    outfile="&exchange_path.\source_inventory.csv"
    dbms=csv replace;
  run;
  %put NOTE: P7: source_inventory.csv exported.;
  proc export data=pdd.name_map
    outfile="&exchange_path.\name_map_dict.csv"
    dbms=csv replace;
  run;
  %put NOTE: P7: name_map_dict.csv exported.;
%mend p7_export_tables;
%p7_export_tables;

/* Section 3 -- Manifest freshness check */
%macro p7_check_manifest;
  %local _p7m_modate _p7m_nobs _p7m_cur_modate _p7m_cur_nobs _p7m_file;
  %let _p7m_file = &exchange_path.\profile_PCNR_manifest.csv;

  %if %sysfunc(fileexist(&_p7m_file)) = 0 %then %do;
    %put ERROR: P7-MANIFEST: profile_PCNR_manifest.csv not found -- rerun Phase 6 first.;
    %let _p7_fail = 1;
    %return;
  %end;

  /* Read manifest: pcnr_modate is a 16-char string written by put(modate,16.) in Phase 6.
     Store as string -- no numeric input() round-trip. */
  data _null_;
    infile "&_p7m_file" dsd firstobs=2 truncover;
    length pcnr_modate_str $16;
    input pcnr_modate_str $ pcnr_nobs :best32. run_dttm $20.;
    call symputx('_p7m_modate', strip(pcnr_modate_str), 'L');
    call symputx('_p7m_nobs',   pcnr_nobs, 'L');
  run;

  /* Get current pdd.pcnr modate formatted the same way: put(modate,16.) trimmed string */
  proc sql noprint;
    select put(modate, 16.) trimmed, nobs
    into :_p7m_cur_modate trimmed, :_p7m_cur_nobs trimmed
    from dictionary.tables
    where libname='PDD' and memname='PCNR';
  quit;

  %if &_p7m_cur_modate = %then %do;
    %put ERROR: P7-MANIFEST: pdd.pcnr not found in dictionary.tables.;
    %let _p7_fail = 1;
    %return;
  %end;

  /* Compare both sides as put(modate,16.) trimmed strings -- no numeric round-trip */
  %if &_p7m_modate ne &_p7m_cur_modate %then %do;
    %put ERROR: P7-MANIFEST: manifest pcnr_modate (&_p7m_modate) differs from current (&_p7m_cur_modate). Rerun Phase 6.;
    %let _p7_fail = 1;
  %end;
  %if &_p7m_nobs ne &_p7m_cur_nobs %then %do;
    %put ERROR: P7-MANIFEST: manifest pcnr_nobs (&_p7m_nobs) differs from current (&_p7m_cur_nobs). Rerun Phase 6.;
    %let _p7_fail = 1;
  %end;
%mend p7_check_manifest;
%p7_check_manifest;

/* Section 4 -- Abort if any check failed */
%macro p7_abort_if_fail;
  %if &_p7_fail = 1 %then %do;
    %put ERROR: P7: One or more pre-flight checks failed -- aborting.;
    %abort cancel;
  %end;
  %put NOTE: P7: 07_build_profile.sas complete -- all checks passed.;
%mend p7_abort_if_fail;
%p7_abort_if_fail;
