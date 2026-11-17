/*==========================================================================
  Program : 18d_comb_scan.sas
  Phase   : 18 (combined dataset and dictionary 2018-2025), plan 18-05
  Purpose : Scan the CLOSED logs and the QC and exchange CSVs of this phase for
            any ENCRYPTED_MRN value of the registry (read only). The only output
            is a hit count per file. Fails on any hit.
            Runs last, in its own fresh session, so the logs of 18a, 18b and 18c
            are closed. Standalone only: when run under 99_run_all.sas the logs
            are the open master log, so only the CSVs are scanned here and the
            pipeline scan step (run_pipeline.cmd) covers the logs, including this
            program's own log (which no SAS program can scan while it writes it).
            Not scanned: profile_PCNR_2018_2025.csv (the distributions are the
            dictionary by design, no MRN column exists in the dataset).
  Reads   : pdd.pecan_id_registry (ENCRYPTED_MRN, read only).
  Writes  : pdd.qc_comb_scan (once, WORK flush), qc\comb_scan.csv, the log.
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from a test session. */
%let p18_fail_mode = ABORT;
%let _p18_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\18d_comb_scan.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\18_combine_macros.sas";

/* stage the per-file hit counts (file name without path) once */
%macro p18d_stage;
  %if %sysfunc(exist(work.p18d_scan)) %then %do;
    data work.qc_comb_scan;
      length item $80 n 8 isfail 8;
      set work.p18d_scan;
      item = scan(fname, -1, '\');
      n = hits;
      isfail = (hits > 0);
      keep item n isfail;
    run;
  %end;
%mend p18d_stage;

%macro p18d_dump;
  %p18d_stage;
  %p18_dump_qc(tables=scan, file=&qc_path.\comb_scan.csv);
  %p18_flush_qc;
%mend p18d_dump;

%macro fail_out(msg=);
  %put ERROR: [18d_comb_scan] &msg;
  %p18d_dump;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [18d_comb_scan] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p18d_main;
  %global p18_scan_files;
  %let p18_scan_files = ;
  %route_log;
  %p18_require(tables=pdd.pecan_id_registry);
  %if &in_pipeline = 0 %then %do;
    %let p18_scan_files = &logs_path.\18a_comb_preflight.log|&logs_path.\18b_comb_build.log|&logs_path.\18c_comb_profile_qc.log|;
  %end;
  %let p18_scan_files = &p18_scan_files.&qc_path.\comb_pre.csv|&qc_path.\comb_pre_inventory.csv|&qc_path.\comb_build.csv|&qc_path.\comb_profile.csv|&exchange_path.\comb_type_delta.csv|&exchange_path.\comb_d30_conflicts.csv|&exchange_path.\comb_recon.csv|&exchange_path.\comb_nodata.csv|&exchange_path.\comb_key_facts.csv|&exchange_path.\profile_PCNR_2018_2025_manifest.csv;
  %p18_scan_no_mrn(filesmv=p18_scan_files, registry=pdd.pecan_id_registry, out=work.p18d_scan);
  %p18d_dump;
  %put NOTE: [18d_comb_scan] PASS - hit count &_p18_scan_hits in the scanned files;
  %restore_log;
%mend p18d_main;

%p18d_main;
