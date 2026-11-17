/*==========================================================================
  Program : 17b_pecan_id_k2.sas
  Phase   : 17 (PECAN_ID), plan 17-03
  Purpose : (1) PDD-D-30 dedupe of s21 s22 s23 BEFORE any ID assignment
            (s22 wins, s23 fills a blank s22 MRN, each normalized case once),
            (2) K2 assignment: PECAN_ID = 1000000 + rank for new MRNs
            (later additions max(K2 PECAN_ID) + n), known (MRN,K2) pairs
            keep their ID, (3) the surgery-level key table
            pdd.pecan_id_case_map (K1 cases from pdd.pecan_id_k1_cases,
            K2 cases by (MRN,K2) lookup), (4) gates.
  Reads   : docs/new_overlap_decisions.csv, pdd.nsrc_s21, pdd.nsrc_s22, pdd.nsrc_s23, pdd.pecan_id_k1_cases,
            pdd.pecan_id_registry (made by 17a)
  Writes  : pdd.pecan_id_registry (append only, backup after the append so
            the next run finds the backup current), pdd.pecan_id_case_map,
            pdd.qc_pecan_id_*, qc\pecan_id_k2_summary.csv, qc\pecan_id_gate.csv
  Gates   : QC first, then abort: s21 overlap, repeated case, shared s22 x s23
            count not equal to expected_n_shared in docs/new_overlap_decisions.csv
            row s22_s23 (read into PDD_EXPECT_SHARED, no default, row missing = fail),
            duplicate PECAN_ID, duplicate (MRN,K2), K2 ID below 1000001,
            K1 ID at or above 1000000, K2 case with usable MRN and no PECAN_ID,
            K1 case whose ID is not in the K1 registry.
  Never   : deletes or rewrites the registry, reads g, or logs MRNs or IDs.
            A second run appends 0 rows.
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from an earlier session
   (the synthetic tests use FLAG). Run each program in a fresh SAS session. */
%let p17_fail_mode = ABORT;
%let _p17_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\17b_pecan_id_k2.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\17_pecan_id_macros.sas";

%macro p17b_dump;
  %p17_dump_qc(tables=d30 gate casemap_gate, file=&qc_path.\pecan_id_gate.csv);
  %p17_dump_qc(tables=k2, file=&qc_path.\pecan_id_k2_summary.csv);
%mend p17b_dump;

%macro fail_out(msg=);
  %put ERROR: [17b_pecan_id_k2] &msg;
  %p17b_dump;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [17b_pecan_id_k2] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p17b_defaults;
  %global PDD_EXPECT_SHARED PDD_K2_BASE;
  %if %length(&PDD_K2_BASE) = 0 %then %let PDD_K2_BASE = 1000000;
%mend p17b_defaults;

/* Expected shared s22 x s23 case count: row s22_s23, column expected_n_shared
   of docs/new_overlap_decisions.csv (PDD-D-30). No default. Row missing, file
   missing or value not a whole number is a failure. */
%macro p17b_read_expected;
  %local _f;
  %let _f = C:\data_dictionary\docs\new_overlap_decisions.csv;
  %let PDD_EXPECT_SHARED = ;
  %if not %sysfunc(fileexist(&_f)) %then
    %fail_out(msg=%str(docs/new_overlap_decisions.csv not found. Expected shared count unknown));
  data _null_;
    infile "&_f" dsd dlm=',' firstobs=2 truncover lrecl=500;
    length pair $40 expected $40;
    input pair $ expected $;
    if strip(pair) = 's22_s23' and prxmatch('/^\d+$/', strip(expected)) then
      call symputx('PDD_EXPECT_SHARED', strip(expected), 'G');
  run;
  %if %length(&PDD_EXPECT_SHARED) = 0 %then
    %fail_out(msg=%str(row s22_s23 with a numeric expected_n_shared missing in docs/new_overlap_decisions.csv));
  %put NOTE: [17b_pecan_id_k2] expected shared s22 x s23 cases &PDD_EXPECT_SHARED read from docs/new_overlap_decisions.csv;
%mend p17b_read_expected;

%macro p17b_preconditions;
  %local _m;
  %if not %sysfunc(exist(pdd.pecan_id_registry)) %then
    %fail_out(msg=%str(pdd.pecan_id_registry missing - run 17a first));
  %if not %sysfunc(exist(pdd.pecan_id_k1_cases)) %then
    %fail_out(msg=%str(pdd.pecan_id_k1_cases missing - run 17a first));
  %do _m = 21 %to 23;
    %if not %sysfunc(exist(pdd.nsrc_s&_m)) %then
      %fail_out(msg=%str(pdd.nsrc_s&_m missing - run Phase 15 first));
  %end;
  %p17b_defaults;
  %p17b_read_expected;
%mend p17b_preconditions;

%macro p17b_main;
  %local _n21 _n22 _n23 _n_nomrn _n_map _n_k1 _n_k2 _n_expected;
  %let _n_expected = 36348;
  %route_log;
  %p17b_preconditions;
  %p17_qinit(ds=pdd.qc_pecan_id_gate);
  %p17_qinit(ds=pdd.qc_pecan_id_casemap_gate);
  %p17_qinit(ds=pdd.qc_pecan_id_k2);

  /* PDD-D-30 before any ID is assigned */
  %p17_pdd_d30_cases(s21=pdd.nsrc_s21, s22=pdd.nsrc_s22, s23=pdd.nsrc_s23, out=work.p17b_cases);
  %if &p17_n_shared ne &PDD_EXPECT_SHARED %then
    %fail_out(msg=%str(PENDING DECISION - shared s22 x s23 cases &p17_n_shared. but &PDD_EXPECT_SHARED. expected. Nothing assigned));

  %p17_nobs(ds=pdd.nsrc_s21, mv=_n21);
  %p17_nobs(ds=pdd.nsrc_s22, mv=_n22);
  %p17_nobs(ds=pdd.nsrc_s23, mv=_n23);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=S21_ROWS, n=&_n21);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=S22_ROWS, n=&_n22);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=S23_ROWS, n=&_n23);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=SHARED_S22_S23_CASES, n=&p17_n_shared);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=S21_OVERLAP_CASES, n=&p17_n_s21ov);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=MRN_FILLED_FROM_S23, n=&p17_n_filled);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=S22_S23_MRN_CONFLICTS, n=&p17_n_conflict);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=CASES_AFTER_DEDUPE, n=&p17_n_cases);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=CASES_EXPECTED_ORIENTATION_ONLY, n=&_n_expected);

  /* K2 assignment (append only) */
  %p17_k2_append(cases=work.p17b_cases, base=&PDD_K2_BASE);
  %p17_gate_registry(reg=pdd.pecan_id_registry);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=K2_DISTINCT_USABLE_MRNS, n=&p17_n_k2_distinct);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=K2_MRNS_KNOWN, n=&p17_n_k2_known);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=K2_MRNS_NEW, n=&p17_n_k2_new);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=ROWS_APPENDED, n=&p17_n_k2_appended);

  /* case map for both eras */
  %p17_casemap(k1=pdd.pecan_id_k1_cases, k2=work.p17b_cases,
               reg=pdd.pecan_id_registry, out=pdd.pecan_id_case_map);
  proc sql noprint;
    select count(*) into :_n_nomrn trimmed from pdd.pecan_id_case_map
      where KEY_ERA = 'K2' and MRN_STATUS = 'NO_MRN';
    select count(*) into :_n_map trimmed from pdd.pecan_id_case_map;
    select count(*) into :_n_k1 trimmed from pdd.pecan_id_case_map where KEY_ERA = 'K1';
    select count(*) into :_n_k2 trimmed from pdd.pecan_id_case_map where KEY_ERA = 'K2';
  quit;
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=K2_NO_MRN_CASES, n=&_n_nomrn);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=CASE_MAP_ROWS, n=&_n_map);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=CASE_MAP_K1_ROWS, n=&_n_k1);
  %p17_qadd(ds=pdd.qc_pecan_id_k2, item=CASE_MAP_K2_ROWS, n=&_n_k2);
  %p17_gate_casemap(map=pdd.pecan_id_case_map, reg=pdd.pecan_id_registry);

  %p17b_dump;
  %put NOTE: [17b_pecan_id_k2] done - shared &p17_n_shared, K2 new &p17_n_k2_new, rows appended &p17_n_k2_appended, K2 cases without MRN &_n_nomrn, case map rows &_n_map;
  %restore_log;
%mend p17b_main;

%p17b_main;
