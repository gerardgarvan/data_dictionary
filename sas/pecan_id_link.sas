/*==========================================================================
  Program : pecan_id_link.sas
  Phase   : 17 (PECAN_ID), plan 17-04 (PID-06)
  Status  : written and tested, NOT RUN. Run only when a crosswalk exists
            (PDD decision needed). Not part of run_pipeline.cmd, 99_run_all
            or any phase token.
  Purpose : Link K2 MRNs to K1 patients through a crosswalk CSV so linked
            patients carry their K1 PECAN_ID (PDD-D-28 item 7). See
            sas/17_pecan_id_link_macros.sas for the rules.
  Input   : global macro variables set on the command line
              PDD_LINK_XWALK_CSV  full path, header K2_MRN,K1_MRN, utf-8
              PDD_LINK_MODE       DRYRUN (default) or APPLY
            APPLY also needs PDD_APPROVE_NEW_BASELINE=1.
  Output  : qc\pecan_id_link.csv (counts), qc\pecan_id_link_changes.csv
            (old K2 ID, new K1 ID, case count - qc only, never in git)
  Never   : deletes anything, changes a PECAN_ID value, writes to g.
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from an earlier session
   (the synthetic tests use FLAG). Run each program in a fresh SAS session. */
%let p17_fail_mode = ABORT;
%let _p17_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\pecan_id_link.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\17_pecan_id_macros.sas";
%include "&sas_path.\17_pecan_id_link_macros.sas";

%macro fail_out(msg=);
  %put ERROR: [pecan_id_link] &msg;
  %p17_dump_qc(tables=link, file=&qc_path.\pecan_id_link.csv);
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [pecan_id_link] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p17l_main;
  %global PDD_LINK_XWALK_CSV PDD_LINK_MODE;
  %route_log;
  %if %length(&PDD_LINK_MODE) = 0 %then %let PDD_LINK_MODE = DRYRUN;
  %if %length(&PDD_LINK_XWALK_CSV) = 0 %then
    %fail_out(msg=%str(PDD_LINK_XWALK_CSV not set));
  %if not %sysfunc(fileexist(&PDD_LINK_XWALK_CSV)) %then
    %fail_out(msg=%str(crosswalk file not found));
  %if not %sysfunc(exist(pdd.pecan_id_registry)) %then
    %fail_out(msg=%str(pdd.pecan_id_registry missing - run 17a first));
  %if not %sysfunc(exist(pdd.pecan_id_case_map)) %then
    %fail_out(msg=%str(pdd.pecan_id_case_map missing - run 17b first));
  %p17l_load(csv=&PDD_LINK_XWALK_CSV, out=work.p17l_xw);
  %p17l_run(xw=work.p17l_xw, mode=&PDD_LINK_MODE);
  %p17_dump_qc(tables=link, file=&qc_path.\pecan_id_link.csv);
  %if %sysfunc(exist(work.p17l_chg)) %then %do;
    proc export data=work.p17l_chg
                outfile="&qc_path.\pecan_id_link_changes.csv"
                dbms=csv replace;
    run;
  %end;
  %put NOTE: [pecan_id_link] done - mode &PDD_LINK_MODE, rows to link &p17l_n_changed;
  %restore_log;
%mend p17l_main;

%p17l_main;
