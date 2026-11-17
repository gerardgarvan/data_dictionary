/*==========================================================================
  Program : 17a_pecan_id_k1_seed.sas
  Phase   : 17 (PECAN_ID), plan 17-02. PDD-D-32.
  Purpose : K1 PECAN_ID = pecan_ID of g.MASTER_DATA_HARMONIZED taken row by
            row through the surgery key (spine pdd.src_s09 to the harmonized
            dataset). NOT an MRN lookup in g.pecan_id_xwalk (the xwalk is not
            an input here). pecan_ID values are copied, never recomputed.
            Writes the K1 case table, creates the registry K1 rows once,
            and appends new K1 dup pairs to the append-only link table.
  Key     : global macro variables set by the run command from PR-3
            (probe_xwalk3 section 1c): PDD_K1_SPINE_KEY=PRECEDE_Study_ID,
            PDD_K1_HARM_KEY=PRECEDE_STUDY_ID, PDD_K1_KEY_MODE=norm (PDD-D-19).
            Defaults below only fill a variable that is still empty.
  Reads   : pdd.src_s09, g.master_data_harmonized (g read-only, PID-08)
  Baseline: the registry is created only when absent AND the OS/command
            option PDD_APPROVE_NEW_BASELINE=1 is set (same pattern as 15a).
            Without it: qc\pecan_id_registry_proposed.csv (encrypted MRNs, not
            for git) and qc\pecan_id_registry_proposed_summary.csv (masked
            counts), then ERROR and stop. Registry and dup link untouched.
  Writes  : pdd.pecan_id_k1_cases, pdd.pecan_id_registry (only when absent and approved),
            pdd.pecan_id_dup_link (append only), pdd.qc_pecan_id_k1,
            backups in &backup_path.,
            qc\pecan_id_k1.csv, qc\pecan_id_dup_pairs_by_year.csv
  Gate    : spine rows = harmonized rows = matched rows, 0 unmatched, 0 multi
            match, 0 missing pecan_ID. QC is written first, then the abort.
  Never   : writes to g, deletes or rewrites the registry or the link table,
            or puts MRNs or IDs in the log or QC.
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from an earlier session
   (the synthetic tests use FLAG). Run each program in a fresh SAS session. */
%let p17_fail_mode = ABORT;
%let _p17_failed = 0;

%pdd_lib;
%pdd_lib_g;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\17a_pecan_id_k1_seed.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\17_pecan_id_macros.sas";

%macro fail_out(msg=);
  %put ERROR: [17a_pecan_id_k1_seed] &msg;
  %p17_dump_qc(tables=k1, file=&qc_path.\pecan_id_k1.csv);
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [17a_pecan_id_k1_seed] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

/* Key hand-off from PR-3. Fill only variables that are still empty. */
%macro p17a_key_defaults;
  %if %length(&PDD_K1_SPINE_KEY) = 0 %then %let PDD_K1_SPINE_KEY = PRECEDE_Study_ID;
  %if %length(&PDD_K1_HARM_KEY) = 0 %then %let PDD_K1_HARM_KEY = PRECEDE_STUDY_ID;
  %if %length(&PDD_K1_KEY_MODE) = 0 %then %let PDD_K1_KEY_MODE = norm;
  %put NOTE: [17a_pecan_id_k1_seed] K1 key - spine &PDD_K1_SPINE_KEY, harmonized &PDD_K1_HARM_KEY, mode &PDD_K1_KEY_MODE;
%mend p17a_key_defaults;

%macro p17a_preconditions;
  %if %sysfunc(libref(g)) ne 0 %then
    %fail_out(msg=%str(libname g not assigned - check g_path));
  %if not %sysfunc(exist(g.master_data_harmonized)) %then
    %fail_out(msg=%str(g.master_data_harmonized not found));
  %if not %sysfunc(exist(pdd.src_s09)) %then
    %fail_out(msg=%str(pdd.src_s09 missing - run Phase 3 first));
  %p17a_key_defaults;
%mend p17a_preconditions;

%macro p17a_main;
  %route_log;
  %p17a_preconditions;

  /* K1 join, QC written, then the gate (abort with counts) */
  %p17_k1_join(spine=pdd.src_s09, harm=g.master_data_harmonized, out=work.p17a_jn);
  %p17_dump_qc(tables=k1, file=&qc_path.\pecan_id_k1.csv);
  %p17_gate_k1;

  %if &_p17_failed = 0 %then %do;
    data pdd.pecan_id_k1_cases;
      set work.p17a_jn;
      keep norm_psid PRECEDE_STUDY_ID ENCRYPTED_MRN YEAR PECAN_ID MRN_STATUS;
    run;
  %end;

  /* dup pairs (PDD-D-32 item 2) */
  %p17_dup_pairs(in=work.p17a_jn, out=work.p17a_pairs);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=DUP_PAIRS_FOUND, n=&p17_n_pairs);

  /* registry (created only when absent and approved) and dup link append.
     Nothing in there runs once the baseline guard or any gate has failed. */
  %p17_k1_registry_link(jn=work.p17a_jn, pairs=work.p17a_pairs,
       propfile=&qc_path.\pecan_id_registry_proposed.csv,
       sumfile=&qc_path.\pecan_id_registry_proposed_summary.csv);
  %if &_p17_failed ne 0 %then %fail_out(msg=%str(registry or link step failed - see the log. Nothing further was run));

  /* QC outputs, counts only */
  %p17_dump_qc(tables=k1, file=&qc_path.\pecan_id_k1.csv);
  proc sql noprint;
    create table work.p17a_by_year as
      select YEAR, count(*) as n_surgeries_with_dup_pair_id
      from work.p17a_jn
      where PECAN_ID in (select pecan_id_a from work.p17a_pairs)
         or PECAN_ID in (select pecan_id_b from work.p17a_pairs)
      group by YEAR
      order by YEAR;
  quit;
  proc export data=work.p17a_by_year
              outfile="&qc_path.\pecan_id_dup_pairs_by_year.csv"
              dbms=csv replace;
  run;
  %put NOTE: [17a_pecan_id_k1_seed] BLANK_SPINE_MRN_ROWS=&p17_blank_mrn;
  %put NOTE: [17a_pecan_id_k1_seed] done - K1 gate PASS, dup pairs &p17_n_pairs, appended to link &p17_n_link_new;
  %restore_log;
%mend p17a_main;

%p17a_main;
