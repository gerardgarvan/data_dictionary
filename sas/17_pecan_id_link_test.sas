/*==========================================================================
  Program : 17_pecan_id_link_test.sas
  Purpose : Standalone synthetic tests for sas/17_pecan_id_link_macros.sas
            (the future cross-era link, PID-06). WORK data only (pdd points at
            a folder inside WORK). Reads nothing from P: or g. FLAG fail mode.
            T1 DRYRUN writes nothing to the registry or the case map
            T2 APPLY without approval fails and changes nothing
            T3 APPLY with approval: matched K2 rows SUPERSEDED and linked, no
               PECAN_ID value changed, same row count, case map relinked
            T4 re-APPLY is idempotent (0 rows to link)
            T5 refusals: K2 MRN to two K1 MRNs, K1 MRN not in K1 registry,
               K2 MRN not in K2 registry, K1 MRN with two IDs
            T6 APPLY refuses a registry that differs from its backup
            T7 no WARNING lines in this log
  Run     : sas 17_pecan_id_link_test.sas  (no pipeline setup required)
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%let _test_log_path = %sysfunc(pathname(work))\17_pecan_id_link_test.log;
proc printto log="&_test_log_path" new; run;

options validvarname=v7 dlcreatedir;
libname pdd "%sysfunc(pathname(work))\tpdd";
%let backup_path = %sysfunc(pathname(work))\tbak;
options nodlcreatedir;

%macro fail_out(msg=);
  %put ERROR: [17_pecan_id_link_test] unexpected abort - &msg;
  %abort cancel;
%mend fail_out;

%include "C:\data_dictionary\sas\17_pecan_id_macros.sas";
%include "C:\data_dictionary\sas\17_pecan_id_link_macros.sas";

%let p17_fail_mode = FLAG;

%let _all_pass = 1;
%macro _record(case=, result=, detail=);
  %if %upcase(&result) = PASS %then
    %put NOTE: [PASS] &case;
  %else %do;
    %put NOTE: [FAIL] &case -- &detail;
    %let _all_pass = 0;
  %end;
%mend _record;

%macro _chk(case=, cond=, detail=);
  %if &cond %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(&detail));
%mend _chk;

%macro _expect_fail(case=);
  %if &_p17_failed = 1 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(did not fail));
  %let _p17_failed = 0;
%mend _expect_fail;

%macro _expect_ok(case=);
  %if &_p17_failed = 0 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(unexpected failure));
  %let _p17_failed = 0;
%mend _expect_ok;

%macro _init_q;
  %global _q;
  %let _q = -1;
%mend _init_q;
%_init_q;

/* registry and case map fixtures, rebuilt by %_fixture */
%macro _fixture;
  data pdd.pecan_id_registry;
    %p17_reg_attrs;
    PECAN_ID = 101; ENCRYPTED_MRN = 'MRN_A'; KEY_ERA = 'K1'; ASSIGNED_RUN = today(); SOURCE = 'k1_harmonized_join'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 102; ENCRYPTED_MRN = 'MRN_B'; KEY_ERA = 'K1'; ASSIGNED_RUN = today(); SOURCE = 'k1_harmonized_join'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 103; ENCRYPTED_MRN = 'MRN_C'; KEY_ERA = 'K1'; ASSIGNED_RUN = today(); SOURCE = 'k1_harmonized_join'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 104; ENCRYPTED_MRN = 'MRN_C'; KEY_ERA = 'K1'; ASSIGNED_RUN = today(); SOURCE = 'k1_harmonized_join'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 1000001; ENCRYPTED_MRN = 'K2_A'; KEY_ERA = 'K2'; ASSIGNED_RUN = today(); SOURCE = 'pdd_17b_k2'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 1000002; ENCRYPTED_MRN = 'K2_B'; KEY_ERA = 'K2'; ASSIGNED_RUN = today(); SOURCE = 'pdd_17b_k2'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 1000003; ENCRYPTED_MRN = 'K2_C'; KEY_ERA = 'K2'; ASSIGNED_RUN = today(); SOURCE = 'pdd_17b_k2'; STATUS = 'ACTIVE'; output;
  run;
  data work.fx_k1;
    length norm_psid $64 PRECEDE_STUDY_ID $64 ENCRYPTED_MRN $64 PECAN_ID 8 MRN_STATUS $8;
    norm_psid = 'Precede00001'; PRECEDE_STUDY_ID = '1'; ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 101; MRN_STATUS = 'OK'; output;
    norm_psid = 'Precede00002'; PRECEDE_STUDY_ID = '2'; ENCRYPTED_MRN = 'MRN_B'; PECAN_ID = 102; MRN_STATUS = 'OK'; output;
  run;
  data work.fx_k2;
    length norm_psid $64 ENCRYPTED_MRN $64 mrn_usable 8 SRC_UNIT $4;
    norm_psid = 'Precede00020'; ENCRYPTED_MRN = 'K2_A'; mrn_usable = 1; SRC_UNIT = 's22'; output;
    norm_psid = 'Precede00021'; ENCRYPTED_MRN = 'K2_A'; mrn_usable = 1; SRC_UNIT = 's22'; output;
    norm_psid = 'Precede00030'; ENCRYPTED_MRN = 'K2_B'; mrn_usable = 1; SRC_UNIT = 's23'; output;
    norm_psid = 'Precede00040'; ENCRYPTED_MRN = 'K2_C'; mrn_usable = 1; SRC_UNIT = 's23'; output;
  run;
  %p17_casemap(k1=work.fx_k1, k2=work.fx_k2, reg=pdd.pecan_id_registry, out=pdd.pecan_id_case_map);
  %p17_backup;
%mend _fixture;

%macro _run_tests;
  %_fixture;
  %p17_gate_casemap(map=pdd.pecan_id_case_map, reg=pdd.pecan_id_registry);
  %_expect_ok(case=T0_FIXTURE_GATES_PASS);

  data work.xw_ok;
    length k2_mrn $64 k1_mrn $64;
    k2_mrn = 'K2_A'; k1_mrn = 'MRN_A'; output;
    k2_mrn = 'K2_B'; k1_mrn = 'MRN_B'; output;
  run;

  /* ---- T1 DRYRUN ---------------------------------------------------------- */
  %p17l_run(xw=work.xw_ok, mode=DRYRUN);
  %_expect_ok(case=T1_DRYRUN_NO_FAILURE);
  %_chk(case=T1_DRYRUN_COUNTS_2, cond=%str(&p17l_n_changed = 2), detail=%str(would link &p17l_n_changed));
  %p17_latest_backup(stem=pecan_id_registry);
  proc sql noprint;
    select count(*) into :_q trimmed from
      (select * from pdd.pecan_id_registry except select * from p17bak.&_p17_latest);
  quit;
  %_chk(case=T1_DRYRUN_REGISTRY_UNCHANGED, cond=%str(&_q = 0), detail=%str(registry differs from backup));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry where STATUS = 'SUPERSEDED';
  quit;
  %_chk(case=T1_DRYRUN_NO_SUPERSEDED, cond=%str(&_q = 0), detail=%str(rows superseded in DRYRUN));
  %_chk(case=T1_CHANGE_REPORT_ROWS, cond=%str(%sysfunc(exist(work.p17l_chg)) = 1), detail=%str(no change report));

  /* ---- T2 APPLY without approval ---------------------------------------------- */
  %let PDD_APPROVE_NEW_BASELINE = 0;
  %p17l_run(xw=work.xw_ok, mode=APPLY);
  %_expect_fail(case=T2_APPLY_WITHOUT_APPROVAL_FAILS);
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry where STATUS = 'SUPERSEDED';
  quit;
  %_chk(case=T2_NOTHING_CHANGED, cond=%str(&_q = 0), detail=%str(registry changed without approval));

  /* ---- T3 APPLY with approval -------------------------------------------------- */
  %let PDD_APPROVE_NEW_BASELINE = 1;
  %p17l_run(xw=work.xw_ok, mode=APPLY);
  %_expect_ok(case=T3_APPLY_NO_FAILURE);
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry
      where (ENCRYPTED_MRN = 'K2_A' and STATUS = 'SUPERSEDED' and LINKED_TO_PECAN_ID = 101 and LINK_SOURCE = 'xwalk_csv' and PECAN_ID = 1000001)
         or (ENCRYPTED_MRN = 'K2_B' and STATUS = 'SUPERSEDED' and LINKED_TO_PECAN_ID = 102 and LINK_SOURCE = 'xwalk_csv' and PECAN_ID = 1000002);
  quit;
  %_chk(case=T3_MATCHED_K2_ROWS_SUPERSEDED, cond=%str(&_q = 2), detail=%str(linked rows &_q expected 2));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry
      where ENCRYPTED_MRN = 'K2_C' and STATUS = 'ACTIVE' and missing(LINKED_TO_PECAN_ID);
  quit;
  %_chk(case=T3_UNLINKED_K2_ROW_ACTIVE, cond=%str(&_q = 1), detail=%str(K2_C row changed));
  proc sql noprint;
    select count(*), count(distinct PECAN_ID) into :_q trimmed, :_q2 trimmed from pdd.pecan_id_registry;
  quit;
  %_chk(case=T3_SAME_ROWS_AND_IDS, cond=%str(&_q = 7 and &_q2 = 7), detail=%str(rows &_q ids &_q2));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_case_map
      where ENCRYPTED_MRN = 'K2_A' and PECAN_ID = 101 and PECAN_ID_KEY_ERA = 'K1';
  quit;
  %_chk(case=T3_LINKED_CASES_CARRY_K1_ID, cond=%str(&_q = 2), detail=%str(linked K2_A cases &_q expected 2));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_case_map
      where ENCRYPTED_MRN = 'K2_C' and PECAN_ID = 1000003 and PECAN_ID_KEY_ERA = 'K2';
  quit;
  %_chk(case=T3_UNLINKED_CASE_KEEPS_K2_ID, cond=%str(&_q = 1), detail=%str(K2_C case changed));
  %p17_gate_casemap(map=pdd.pecan_id_case_map, reg=pdd.pecan_id_registry);
  %_expect_ok(case=T3_CASEMAP_GATE_PASSES_AFTER_LINK);
  %_chk(case=T3_CHANGE_REPORT_COUNTS_CASES, cond=%str(&p17l_n_changed = 2), detail=%str(changed &p17l_n_changed));

  /* ---- T4 re-APPLY is idempotent --------------------------------------------- */
  %p17l_run(xw=work.xw_ok, mode=APPLY);
  %_expect_ok(case=T4_REAPPLY_NO_FAILURE);
  %_chk(case=T4_REAPPLY_LINKS_0, cond=%str(&p17l_n_changed = 0), detail=%str(relinked &p17l_n_changed));
  %let PDD_APPROVE_NEW_BASELINE = 0;

  /* ---- T5 refusals (fresh fixture) -------------------------------------------- */
  %_fixture;
  data work.xw_r1;
    length k2_mrn $64 k1_mrn $64;
    k2_mrn = 'K2_A'; k1_mrn = 'MRN_A'; output;
    k2_mrn = 'K2_A'; k1_mrn = 'MRN_B'; output;
  run;
  %p17l_run(xw=work.xw_r1, mode=DRYRUN);
  %_expect_fail(case=T5_K2_MRN_TO_TWO_K1_MRNS_REFUSED);
  data work.xw_r2;
    length k2_mrn $64 k1_mrn $64;
    k2_mrn = 'K2_A'; k1_mrn = 'MRN_NOT_THERE'; output;
  run;
  %p17l_run(xw=work.xw_r2, mode=DRYRUN);
  %_expect_fail(case=T5_K1_MRN_NOT_IN_K1_REGISTRY_REFUSED);
  data work.xw_r3;
    length k2_mrn $64 k1_mrn $64;
    k2_mrn = 'K2_NOT_THERE'; k1_mrn = 'MRN_A'; output;
  run;
  %p17l_run(xw=work.xw_r3, mode=DRYRUN);
  %_expect_fail(case=T5_K2_MRN_NOT_IN_K2_REGISTRY_REFUSED);
  data work.xw_r4;
    length k2_mrn $64 k1_mrn $64;
    k2_mrn = 'K2_C'; k1_mrn = 'MRN_C'; output;
  run;
  %p17l_run(xw=work.xw_r4, mode=DRYRUN);
  %_expect_fail(case=T5_K1_MRN_WITH_TWO_IDS_REFUSED);
  %p17l_run(xw=work.xw_ok, mode=LINK);
  %_expect_fail(case=T5_BAD_MODE_REFUSED);

  /* ---- T6 APPLY refuses a registry that differs from its backup -------------- */
  data work.t6_extra;
    %p17_reg_attrs;
    PECAN_ID = 1000777; ENCRYPTED_MRN = 'K2_X'; KEY_ERA = 'K2'; ASSIGNED_RUN = today();
    SOURCE = 'test'; STATUS = 'ACTIVE';
  run;
  proc append base=pdd.pecan_id_registry data=work.t6_extra;
  run;
  %let PDD_APPROVE_NEW_BASELINE = 1;
  %p17l_run(xw=work.xw_ok, mode=APPLY);
  %_expect_fail(case=T6_APPLY_REFUSES_REGISTRY_DIFFERING_FROM_BACKUP);
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry where STATUS = 'SUPERSEDED';
  quit;
  %_chk(case=T6_NOTHING_LINKED_AFTER_REFUSAL, cond=%str(&_q = 0), detail=%str(rows linked despite stale backup));
  %let PDD_APPROVE_NEW_BASELINE = 0;

%mend _run_tests;
%_run_tests;

/* ---- T7 no WARNING lines in this log ----------------------------------------- */
proc printto; run;

data work._t7_warn_check;
  length _n_warn 8;
  retain _n_warn 0;
  infile "&_test_log_path" lrecl=32767 end=_eof;
  input;
  if index(upcase(_infile_), 'WARNING:') > 0 then _n_warn + 1;
  if index(upcase(_infile_), '[FAIL]') > 0 or index(upcase(_infile_), '[PASS]') > 0 then
    put _infile_;
  if _eof then do;
    call symputx('_t7_n_warn', _n_warn);
    output;
  end;
run;

%macro _t7_check;
  %if &_t7_n_warn = 0 %then %_record(case=T7_NO_WARNINGS_IN_LOG, result=PASS);
  %else %_record(case=T7_NO_WARNINGS_IN_LOG, result=FAIL,
         detail=%str(&_t7_n_warn WARNING lines found in test log));
%mend _t7_check;
%_t7_check;

%macro _final_summary;
  %if &_all_pass = 1 %then
    %put NOTE: [17_pecan_id_link_test] TESTRESULT SUMMARY: ALL TESTS PASSED;
  %else
    %put ERROR: [17_pecan_id_link_test] TESTRESULT SUMMARY: ONE OR MORE TESTS FAILED;
%mend _final_summary;
%_final_summary;
