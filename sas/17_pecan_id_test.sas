/*==========================================================================
  Program : 17_pecan_id_test.sas
  Purpose : Standalone synthetic tests for sas/17_pecan_id_macros.sas.
            WORK data only (the pdd libref points at a folder inside WORK).
            Reads nothing from P: and nothing from g. Includes no 00_config.sas,
            so it carries an identical copy of %pdd_norm_psid (a python static
            test checks that the two bodies are the same).
            T1  K2 rank = 1000000 + rank, MRN tie-break, missing last
            T2  usable-MRN flag (blank, NULL, null, real)
            T3  PDD-D-30 dedupe: s22 wins, s23 fills blank s22 MRN, shared counted once
            T4  PDD-D-30 negative: s21 overlap, repeated case (FLAG mode)
            T5  K1 join 1:1, blank-MRN spine row counted and keeps its pecan_ID
            T6  K1 join negatives: matches 0, matches 2, missing pecan_ID
            T7  dup pair from one spine MRN with two pecan_IDs, n_surgeries right
            T8  dup link append idempotence, existing rows unchanged, backup taken
            T9  K2 append: first run IDs 1000001.., known keep ID, new MRN gets max+1,
                second run appends 0
            T10 registry gate PASS and FAIL cases
            T11 case map and case map gate PASS and FAIL cases
            T12 backup-current assertion: no backup, approval, differing registry
            T14 registry baseline guard: no approval / value 2 = proposal + masked
                summary, no registry; approval 1 = registry + current backup
            T13 no WARNING or ERROR lines in this log (runs last)
  Run     : sas 17_pecan_id_test.sas  (no pipeline setup required)
            Bring back the log and look for the TESTRESULT SUMMARY line.
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%let _test_log_path = %sysfunc(pathname(work))\17_pecan_id_test.log;
proc printto log="&_test_log_path" new; run;

options validvarname=v7 dlcreatedir;
libname pdd "%sysfunc(pathname(work))\tpdd";
%let backup_path = %sysfunc(pathname(work))\tbak;
%let out_root = %sysfunc(pathname(work));
options nodlcreatedir;

/* identical copy of 00_config.sas section 8 (PDD-D-19) */
%macro pdd_norm_psid(in=, out=, idvar=PRECEDE_STUDY_ID);
  data &out;
    set &in;
    length norm_psid $64;
    if missing(&idvar) or strip(&idvar) = '' then norm_psid = '';
    else if prxmatch('/^\d+$/', strip(&idvar)) then
      norm_psid = cats('Precede', put(input(strip(&idvar), ?? 8.), z5.));
    else if length(strip(&idvar)) >= 7
         and lowcase(substr(strip(&idvar), 1, 7)) = 'precede' then
      norm_psid = cats('Precede', substr(strip(&idvar), 8));
    else norm_psid = strip(&idvar);
  run;
%mend pdd_norm_psid;

/* %fail_out is only reached in ABORT mode, which this test never uses */
%macro fail_out(msg=);
  %put ERROR: [17_pecan_id_test] unexpected abort - &msg;
  %abort cancel;
%mend fail_out;

%include "C:\data_dictionary\sas\17_pecan_id_macros.sas";

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

/* expression must be true; cond is evaluated with %eval */
%macro _chk(case=, cond=, detail=);
  %local _res;
  %let _res = FAIL;
  %if %unquote(&cond) %then %let _res = PASS;
  %if &_res = PASS %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(&detail - or the check could not be evaluated));
%mend _chk;

%macro _expect_fail(case=);
  %if &_p17_failed = 1 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(gate did not fail));
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

%macro _run_tests;

  /* ---- T1 K2 rank ------------------------------------------------------ */
  data work.t1_in;
    length ENCRYPTED_MRN $64 min_num 8;
    ENCRYPTED_MRN = 'MRN_A'; min_num = 5; output;
    ENCRYPTED_MRN = 'MRN_C'; min_num = 2; output;
    ENCRYPTED_MRN = 'MRN_B'; min_num = 2; output;
    ENCRYPTED_MRN = 'MRN_D'; min_num = .; output;
  run;
  %p17_rank_k2(in=work.t1_in, out=work.t1_out, base=1000000);
  proc sql noprint;
    select sum(PECAN_ID = 1000001 and ENCRYPTED_MRN = 'MRN_B') +
                      sum(PECAN_ID = 1000002 and ENCRYPTED_MRN = 'MRN_C') +
                      sum(PECAN_ID = 1000003 and ENCRYPTED_MRN = 'MRN_A') +
                      sum(PECAN_ID = 1000004 and ENCRYPTED_MRN = 'MRN_D')
               into :_q trimmed from work.t1_out;
  quit;
  %_chk(case=T1_K2_RANK_AND_TIEBREAK, cond=%str(&_q = 4), detail=%str(rank mapping wrong, matched &_q of 4));

  /* ---- T2 usable MRN flag ---------------------------------------------- */
  data work.t2_in;
    length ENCRYPTED_MRN $64;
    ENCRYPTED_MRN = ''; output;
    ENCRYPTED_MRN = 'NULL'; output;
    ENCRYPTED_MRN = 'null'; output;
    ENCRYPTED_MRN = ' abc '; output;
  run;
  %p17_usable_mrn(in=work.t2_in, out=work.t2_out);
  proc sql noprint;
    select sum(mrn_usable) into :_q trimmed from work.t2_out;
  quit;
  %_chk(case=T2_USABLE_MRN_FLAG, cond=%str(&_q = 1), detail=%str(usable count &_q expected 1));

  /* ---- T3 PDD-D-30 dedupe ----------------------------------------------- */
  data work.t3_s21;
    length norm_psid $64 ENCRYPTED_MRN $64;
    norm_psid = 'Precede00001'; ENCRYPTED_MRN = 'MRN_A'; output;
  run;
  data work.t3_s22;
    length norm_psid $64 ENCRYPTED_MRN $64;
    norm_psid = 'Precede00010'; ENCRYPTED_MRN = 'MRN_1'; output;
    norm_psid = 'Precede00011'; ENCRYPTED_MRN = ''; output;
    norm_psid = 'Precede00012'; ENCRYPTED_MRN = 'MRN_3'; output;
    norm_psid = 'Precede00013'; ENCRYPTED_MRN = 'NULL'; output;
  run;
  data work.t3_s23;
    length norm_psid $64 ENCRYPTED_MRN $64;
    norm_psid = 'Precede00011'; ENCRYPTED_MRN = 'MRN_2'; output;
    norm_psid = 'Precede00012'; ENCRYPTED_MRN = 'MRN_3'; output;
    norm_psid = 'Precede00014'; ENCRYPTED_MRN = 'MRN_5'; output;
    norm_psid = 'Precede00013'; ENCRYPTED_MRN = ''; output;
  run;
  %p17_pdd_d30_cases(s21=work.t3_s21, s22=work.t3_s22, s23=work.t3_s23, out=work.t3_cases);
  %_expect_ok(case=T3_D30_NO_FAILURE);
  %_chk(case=T3_SHARED_COUNT, cond=%str(&p17_n_shared = 3), detail=%str(shared &p17_n_shared expected 3));
  %_chk(case=T3_CASE_COUNT, cond=%str(&p17_n_cases = 6), detail=%str(cases &p17_n_cases expected 6));
  %_chk(case=T3_MRN_FILLED, cond=%str(&p17_n_filled = 1), detail=%str(filled &p17_n_filled expected 1));
  %_chk(case=T3_NO_CONFLICT, cond=%str(&p17_n_conflict = 0), detail=%str(conflicts &p17_n_conflict expected 0));
  proc sql noprint;
    select count(*) into :_q trimmed from work.t3_cases
               where norm_psid = 'Precede00011' and ENCRYPTED_MRN = 'MRN_2' and mrn_usable = 1;
  quit;
  %_chk(case=T3_S23_FILLS_BLANK_S22, cond=%str(&_q = 1), detail=%str(filled row not found));
  proc sql noprint;
    select count(*) into :_q trimmed from work.t3_cases
               where norm_psid = 'Precede00013' and mrn_usable = 0;
  quit;
  %_chk(case=T3_NULL_STAYS_UNUSABLE, cond=%str(&_q = 1), detail=%str(NULL case row wrong));
  proc sql noprint;
    select count(*) into :_q trimmed from (select norm_psid from work.t3_cases
               group by norm_psid having count(*) > 1);
  quit;
  %_chk(case=T3_EACH_CASE_ONCE, cond=%str(&_q = 0), detail=%str(&_q repeated cases));

  /* ---- T4 PDD-D-30 negatives ---------------------------------------------- */
  data work.t4_s21;
    length norm_psid $64 ENCRYPTED_MRN $64;
    norm_psid = 'Precede00010'; ENCRYPTED_MRN = 'MRN_X'; output;
  run;
  %p17_pdd_d30_cases(s21=work.t4_s21, s22=work.t3_s22, s23=work.t3_s23, out=work.t4_cases);
  %_expect_fail(case=T4_S21_OVERLAP_FAILS);
  data work.t4_s22;
    length norm_psid $64 ENCRYPTED_MRN $64;
    norm_psid = 'Precede00010'; ENCRYPTED_MRN = 'MRN_1'; output;
    norm_psid = 'Precede00010'; ENCRYPTED_MRN = 'MRN_1'; output;
  run;
  %p17_pdd_d30_cases(s21=work.t3_s21, s22=work.t4_s22, s23=work.t3_s23, out=work.t4_cases2);
  %_expect_fail(case=T4_REPEAT_WITHIN_FILE_FAILS);

  /* ---- T5 K1 join 1:1 ---------------------------------------------------- */
  %let PDD_K1_SPINE_KEY = PRECEDE_Study_ID;
  %let PDD_K1_HARM_KEY = PRECEDE_STUDY_ID;
  %let PDD_K1_KEY_MODE = norm;
  data work.t5_spine;
    length PRECEDE_Study_ID $12 ENCRYPTED_MRN $41 YEAR 8;
    PRECEDE_Study_ID = '1'; ENCRYPTED_MRN = 'MRN_A'; YEAR = 2018; output;
    PRECEDE_Study_ID = '2'; ENCRYPTED_MRN = 'MRN_B'; YEAR = 2019; output;
    PRECEDE_Study_ID = '3'; ENCRYPTED_MRN = ''; YEAR = 2020; output;
  run;
  data work.t5_harm;
    length PRECEDE_STUDY_ID $12 pecan_ID 8;
    PRECEDE_STUDY_ID = 'Precede00003'; pecan_ID = 103; output;
    PRECEDE_STUDY_ID = '2'; pecan_ID = 102; output;
    PRECEDE_STUDY_ID = 'Precede00001'; pecan_ID = 101; output;
  run;
  %p17_k1_join(spine=work.t5_spine, harm=work.t5_harm, out=work.t5_out);
  %p17_gate_k1;
  %_expect_ok(case=T5_K1_GATE_PASSES);
  %_chk(case=T5_COUNTS, cond=%str(&p17_n_spine = 3 and &p17_n_harm = 3 and &p17_n_m1 = 3),
        detail=%str(spine &p17_n_spine harm &p17_n_harm exactly one &p17_n_m1));
  %_chk(case=T5_BLANK_MRN_LINE, cond=%str(&p17_blank_mrn = 1), detail=%str(blank MRN rows &p17_blank_mrn));
  proc sql noprint;
    select count(*) into :_q trimmed from work.t5_out
               where norm_psid = 'Precede00003' and PECAN_ID = 103 and MRN_STATUS = 'NO_MRN';
  quit;
  %_chk(case=T5_BLANK_MRN_ROW_KEEPS_ID, cond=%str(&_q = 1), detail=%str(blank MRN row lost its ID));
  proc sql noprint;
    select count(*) into :_q trimmed from work.t5_out
               where (norm_psid = 'Precede00001' and PECAN_ID = 101)
                  or (norm_psid = 'Precede00002' and PECAN_ID = 102);
  quit;
  %_chk(case=T5_IDS_COPIED_THROUGH_KEY, cond=%str(&_q = 2), detail=%str(IDs not copied by key));

  /* ---- T6 K1 join negatives ---------------------------------------------- */
  data work.t6a_harm;
    length PRECEDE_STUDY_ID $12 pecan_ID 8;
    PRECEDE_STUDY_ID = 'Precede00001'; pecan_ID = 101; output;
    PRECEDE_STUDY_ID = 'Precede00002'; pecan_ID = 102; output;
    PRECEDE_STUDY_ID = 'Precede00099'; pecan_ID = 109; output;
  run;
  %p17_k1_join(spine=work.t5_spine, harm=work.t6a_harm, out=work.t6a_out);
  %p17_gate_k1;
  %_expect_fail(case=T6_SPINE_ROW_MATCHING_NONE_FAILS);
  data work.t6b_harm;
    length PRECEDE_STUDY_ID $12 pecan_ID 8;
    PRECEDE_STUDY_ID = 'Precede00001'; pecan_ID = 101; output;
    PRECEDE_STUDY_ID = 'Precede00001'; pecan_ID = 111; output;
    PRECEDE_STUDY_ID = 'Precede00002'; pecan_ID = 102; output;
    PRECEDE_STUDY_ID = 'Precede00003'; pecan_ID = 103; output;
  run;
  %p17_k1_join(spine=work.t5_spine, harm=work.t6b_harm, out=work.t6b_out);
  %p17_gate_k1;
  %_expect_fail(case=T6_SPINE_ROW_MATCHING_TWO_FAILS);
  data work.t6c_harm;
    length PRECEDE_STUDY_ID $12 pecan_ID 8;
    PRECEDE_STUDY_ID = 'Precede00001'; pecan_ID = 101; output;
    PRECEDE_STUDY_ID = 'Precede00002'; pecan_ID = .; output;
    PRECEDE_STUDY_ID = 'Precede00003'; pecan_ID = 103; output;
  run;
  %p17_k1_join(spine=work.t5_spine, harm=work.t6c_harm, out=work.t6c_out);
  %p17_gate_k1;
  %_expect_fail(case=T6_MISSING_PECAN_ID_FAILS);
  %let PDD_K1_KEY_MODE = ;
  %p17_k1_join(spine=work.t5_spine, harm=work.t5_harm, out=work.t6d_out);
  %_expect_fail(case=T6_KEY_NOT_SET_FAILS);
  %let PDD_K1_KEY_MODE = norm;

  /* ---- T7 dup pair ---------------------------------------------------------- */
  data work.t7_k1;
    length ENCRYPTED_MRN $64 PECAN_ID 8 mrn_usable 8;
    ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 101; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 102; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_B'; PECAN_ID = 101; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_C'; PECAN_ID = 103; mrn_usable = 1; output;
    ENCRYPTED_MRN = ''; PECAN_ID = 104; mrn_usable = 0; output;
  run;
  %p17_dup_pairs(in=work.t7_k1, out=work.t7_pairs);
  %_chk(case=T7_ONE_DUP_PAIR, cond=%str(&p17_n_pairs = 1), detail=%str(pairs &p17_n_pairs expected 1));
  proc sql noprint;
    select count(*) into :_q trimmed from work.t7_pairs
               where pecan_id_a = 101 and pecan_id_b = 102 and n_surgeries_a = 2
                 and n_surgeries_b = 1 and link_basis = 'SPINE_MRN_MULTI_ID'
                 and not missing(decided_on);
  quit;
  %_chk(case=T7_PAIR_VALUES, cond=%str(&_q = 1), detail=%str(pair values wrong));

  /* ---- T8 dup link append ---------------------------------------------------- */
  %p17_append_dup_link(pairs=work.t7_pairs);
  %_chk(case=T8_FIRST_APPEND_ADDS_1, cond=%str(&p17_n_link_new = 1), detail=%str(appended &p17_n_link_new));
  %p17_append_dup_link(pairs=work.t7_pairs);
  %_chk(case=T8_SECOND_APPEND_ADDS_0, cond=%str(&p17_n_link_new = 0), detail=%str(appended &p17_n_link_new));
  data work.t8_k1b;
    length ENCRYPTED_MRN $64 PECAN_ID 8 mrn_usable 8;
    ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 101; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 102; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_B'; PECAN_ID = 101; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_C'; PECAN_ID = 103; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_C'; PECAN_ID = 105; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_C'; PECAN_ID = 105; mrn_usable = 1; output;
  run;
  %p17_dup_pairs(in=work.t8_k1b, out=work.t8_pairs);
  %p17_append_dup_link(pairs=work.t8_pairs);
  %_chk(case=T8_NEW_PAIR_ONLY_APPENDED, cond=%str(&p17_n_link_new = 1), detail=%str(appended &p17_n_link_new));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_dup_link;
  quit;
  %_chk(case=T8_LINK_HAS_2_ROWS, cond=%str(&_q = 2), detail=%str(rows &_q));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_dup_link
               where pecan_id_a = 101 and pecan_id_b = 102 and n_surgeries_a = 2 and n_surgeries_b = 1;
  quit;
  %_chk(case=T8_EXISTING_ROW_UNCHANGED, cond=%str(&_q = 1), detail=%str(existing pair changed));
  %p17_latest_backup(stem=piddup);
  %_chk(case=T8_LINK_BACKUP_TAKEN, cond=%str(%length(&_p17_latest) > 0), detail=%str(no link backup));

  /* ---- T9 registry creation and K2 append ---------------------------------- */
  data work.t9_k1cases;
    length ENCRYPTED_MRN $64 PECAN_ID 8 mrn_usable 8;
    ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 101; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 101; mrn_usable = 1; output;
    ENCRYPTED_MRN = 'MRN_B'; PECAN_ID = 102; mrn_usable = 1; output;
    ENCRYPTED_MRN = ''; PECAN_ID = 103; mrn_usable = 0; output;
  run;
  %p17_k1_reg_rows(in=work.t9_k1cases, out=work.t9_regk1);
  %_chk(case=T9_K1_ID_ONLY_ON_BLANK_MRN_REPORTED, cond=%str(&p17_n_only_blank = 1), detail=%str(only blank &p17_n_only_blank));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.qc_pecan_id_k1
               where item like 'PENDING_DECISION%' and n > 0;
  quit;
  %_chk(case=T9_PENDING_DECISION_IN_QC, cond=%str(&_q >= 1), detail=%str(QC missing pending row));
  data work.t9_k1cases;
    set work.t9_k1cases(where=(mrn_usable = 1));
  run;
  %p17_k1_reg_rows(in=work.t9_k1cases, out=work.t9_regk1);
  proc sql noprint;
    select count(*) into :_q trimmed from work.t9_regk1
               where KEY_ERA = 'K1' and STATUS = 'ACTIVE' and SOURCE = 'k1_harmonized_join';
  quit;
  %_chk(case=T9_K1_REGISTRY_ROWS_ONE_PER_ID, cond=%str(&_q = 2), detail=%str(K1 registry rows &_q));
  data pdd.pecan_id_registry;
    set work.t9_regk1;
  run;
  %p17_backup;
  %p17_gate_registry(reg=pdd.pecan_id_registry);
  %_expect_ok(case=T9_REGISTRY_GATE_AFTER_K1);

  data work.t9_k2;
    length norm_psid $64 ENCRYPTED_MRN $64 mrn_usable 8 SRC_UNIT $4;
    norm_psid = 'Precede00040'; ENCRYPTED_MRN = 'K2_M3'; mrn_usable = 1; SRC_UNIT = 's22'; output;
    norm_psid = 'Precede00020'; ENCRYPTED_MRN = 'K2_M1'; mrn_usable = 1; SRC_UNIT = 's22'; output;
    norm_psid = 'Precede00021'; ENCRYPTED_MRN = 'K2_M1'; mrn_usable = 1; SRC_UNIT = 's22'; output;
    norm_psid = 'Precede00030'; ENCRYPTED_MRN = 'K2_M2'; mrn_usable = 1; SRC_UNIT = 's23'; output;
    norm_psid = 'Precede00050'; ENCRYPTED_MRN = ''; mrn_usable = 0; SRC_UNIT = 's23'; output;
  run;
  %p17_k2_append(cases=work.t9_k2);
  %_expect_ok(case=T9_FIRST_K2_RUN_NO_FAILURE);
  %_chk(case=T9_FIRST_RUN_APPENDS_3, cond=%str(&p17_n_k2_appended = 3), detail=%str(appended &p17_n_k2_appended));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry
               where (ENCRYPTED_MRN = 'K2_M1' and PECAN_ID = 1000001)
                  or (ENCRYPTED_MRN = 'K2_M2' and PECAN_ID = 1000002)
                  or (ENCRYPTED_MRN = 'K2_M3' and PECAN_ID = 1000003);
  quit;
  %_chk(case=T9_K2_IDS_1000000_PLUS_RANK, cond=%str(&_q = 3), detail=%str(K2 IDs wrong));
  %p17_k2_append(cases=work.t9_k2);
  %_expect_ok(case=T9_SECOND_RUN_NO_FAILURE);
  %_chk(case=T9_SECOND_RUN_APPENDS_0, cond=%str(&p17_n_k2_appended = 0), detail=%str(appended &p17_n_k2_appended));
  %_chk(case=T9_SECOND_RUN_ALL_KNOWN, cond=%str(&p17_n_k2_known = 3), detail=%str(known &p17_n_k2_known));
  data work.t9_k2b;
    set work.t9_k2 work.t9_k2(in=_x where=(norm_psid = 'Precede00040'));
    if _x then do;
      norm_psid = 'Precede00010';
      ENCRYPTED_MRN = 'K2_M4';
    end;
  run;
  %p17_k2_append(cases=work.t9_k2b);
  %_chk(case=T9_NEW_MRN_APPENDS_1, cond=%str(&p17_n_k2_appended = 1), detail=%str(appended &p17_n_k2_appended));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry
               where ENCRYPTED_MRN = 'K2_M4' and PECAN_ID = 1000004;
  quit;
  %_chk(case=T9_NEW_MRN_GETS_MAX_PLUS_1, cond=%str(&_q = 1), detail=%str(new MRN ID wrong));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_registry
               where (ENCRYPTED_MRN = 'K2_M1' and PECAN_ID = 1000001)
                  or (ENCRYPTED_MRN = 'K2_M2' and PECAN_ID = 1000002)
                  or (ENCRYPTED_MRN = 'K2_M3' and PECAN_ID = 1000003);
  quit;
  %_chk(case=T9_EXISTING_IDS_NOT_RENUMBERED, cond=%str(&_q = 3), detail=%str(existing IDs changed));

  /* ---- T10 registry gate negatives -------------------------------------------- */
  %p17_gate_registry(reg=pdd.pecan_id_registry);
  %_expect_ok(case=T10_REGISTRY_GATE_PASSES);
  /* self-contained valid base registry so each negative differs by exactly one row */
  data work.t10_base;
    %p17_reg_attrs;
    PECAN_ID = 101; ENCRYPTED_MRN = 'MRN_A'; KEY_ERA = 'K1'; ASSIGNED_RUN = today(); SOURCE = 'test'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 1000001; ENCRYPTED_MRN = 'K2_M1'; KEY_ERA = 'K2'; ASSIGNED_RUN = today(); SOURCE = 'test'; STATUS = 'ACTIVE'; output;
    PECAN_ID = 1000002; ENCRYPTED_MRN = 'K2_M2'; KEY_ERA = 'K2'; ASSIGNED_RUN = today(); SOURCE = 'test'; STATUS = 'ACTIVE'; output;
  run;
  %p17_gate_registry(reg=work.t10_base);
  %_expect_ok(case=T10_BASE_REGISTRY_PASSES);
  data work.t10a;
    set work.t10_base end=_e;
    output;
    if _e then do; PECAN_ID = 101; ENCRYPTED_MRN = 'ZZ'; KEY_ERA = 'K1'; output; end;
  run;
  %p17_gate_registry(reg=work.t10a);
  %_expect_fail(case=T10_DUPLICATE_PECAN_ID_FAILS);
  /* same ENCRYPTED_MRN on a second K2 row under a new, valid K2 ID */
  data work.t10b;
    set work.t10_base end=_e;
    output;
    if _e then do; PECAN_ID = 1009999; ENCRYPTED_MRN = 'K2_M1'; KEY_ERA = 'K2'; output; end;
  run;
  %p17_gate_registry(reg=work.t10b);
  %_expect_fail(case=T10_DUPLICATE_MRN_K2_FAILS);
  data work.t10c;
    set work.t10_base end=_e;
    output;
    if _e then do; PECAN_ID = 1000000; ENCRYPTED_MRN = 'ZZ'; KEY_ERA = 'K2'; output; end;
  run;
  %p17_gate_registry(reg=work.t10c);
  %_expect_fail(case=T10_K2_ID_BELOW_1000001_FAILS);
  data work.t10d;
    set work.t10_base end=_e;
    output;
    if _e then do; PECAN_ID = 1000500; ENCRYPTED_MRN = 'ZZ'; KEY_ERA = 'K1'; output; end;
  run;
  %p17_gate_registry(reg=work.t10d);
  %_expect_fail(case=T10_K1_ID_AT_OR_ABOVE_1000000_FAILS);

  /* ---- T11 case map ------------------------------------------------------------ */
  data work.t11_k1;
    length norm_psid $64 PRECEDE_STUDY_ID $64 ENCRYPTED_MRN $64 PECAN_ID 8 MRN_STATUS $8;
    norm_psid = 'Precede00001'; PRECEDE_STUDY_ID = '1'; ENCRYPTED_MRN = 'MRN_A'; PECAN_ID = 101; MRN_STATUS = 'OK'; output;
    norm_psid = 'Precede00002'; PRECEDE_STUDY_ID = '2'; ENCRYPTED_MRN = 'MRN_B'; PECAN_ID = 102; MRN_STATUS = 'OK'; output;
  run;
  data work.t11_k2;
    set work.t9_k2b;
  run;
  %p17_casemap(k1=work.t11_k1, k2=work.t11_k2, reg=pdd.pecan_id_registry, out=pdd.pecan_id_case_map);
  %p17_gate_casemap(map=pdd.pecan_id_case_map, reg=pdd.pecan_id_registry);
  %_expect_ok(case=T11_CASEMAP_GATE_PASSES);
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_case_map
               where KEY_ERA = 'K2' and MRN_STATUS = 'NO_MRN' and missing(PECAN_ID)
                 and missing(PECAN_ID_KEY_ERA);
  quit;
  %_chk(case=T11_K2_NO_MRN_KEEPS_MISSING_ID, cond=%str(&_q = 1), detail=%str(NO_MRN row wrong));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_case_map
               where KEY_ERA = 'K1' and PECAN_ID_KEY_ERA = 'K1' and not missing(PECAN_ID);
  quit;
  %_chk(case=T11_K1_ERA_FILLED, cond=%str(&_q = 2), detail=%str(K1 era rows &_q));
  proc sql noprint;
    select count(*) into :_q trimmed from pdd.pecan_id_case_map;
  quit;
  %_chk(case=T11_ROWS_ARE_K1_PLUS_K2_CASES, cond=%str(&_q = 8), detail=%str(case map rows &_q expected 8));
  data work.t11_bad1;
    set pdd.pecan_id_case_map end=_e;
    if KEY_ERA = 'K2' and MRN_STATUS = 'OK' and not _done then do;
      PECAN_ID = .; PECAN_ID_KEY_ERA = ''; _done = 1;
    end;
    retain _done 0;
    drop _done;
  run;
  %p17_gate_casemap(map=work.t11_bad1, reg=pdd.pecan_id_registry);
  %_expect_fail(case=T11_UNMAPPED_USABLE_MRN_CASE_FAILS);
  data work.t11_bad2;
    set pdd.pecan_id_case_map;
    if KEY_ERA = 'K1' and norm_psid = 'Precede00001' then PECAN_ID = 999;
  run;
  %p17_gate_casemap(map=work.t11_bad2, reg=pdd.pecan_id_registry);
  %_expect_fail(case=T11_K1_ID_NOT_IN_REGISTRY_FAILS);
  data work.t11_bad3;
    set pdd.pecan_id_case_map;
    if KEY_ERA = 'K1' and norm_psid = 'Precede00001' then PECAN_ID = .;
  run;
  %p17_gate_casemap(map=work.t11_bad3, reg=pdd.pecan_id_registry);
  %_expect_fail(case=T11_K1_MISSING_ID_FAILS);
  data work.t11_bad4;
    set pdd.pecan_id_case_map pdd.pecan_id_case_map(obs=1);
  run;
  %p17_gate_casemap(map=work.t11_bad4, reg=pdd.pecan_id_registry);
  %_expect_fail(case=T11_REPEATED_CASE_FAILS);

  /* ---- T12 backup-current assertion ------------------------------------------------ */
  %let PDD_APPROVE_NEW_BASELINE = 0;
  %p17_assert_backup_current;
  %_expect_ok(case=T12_REGISTRY_EQUALS_BACKUP);
  data work.t12_extra;
    %p17_reg_attrs;
    PECAN_ID = 1000777; ENCRYPTED_MRN = 'K2_X'; KEY_ERA = 'K2'; ASSIGNED_RUN = today();
    SOURCE = 'test'; STATUS = 'ACTIVE';
  run;
  proc append base=pdd.pecan_id_registry data=work.t12_extra;
  run;
  %p17_assert_backup_current;
  %_expect_fail(case=T12_DIFFERING_REGISTRY_FAILS_WITHOUT_APPROVAL);
  %let PDD_APPROVE_NEW_BASELINE = 2;
  %p17_assert_backup_current;
  %_expect_fail(case=T12_APPROVAL_VALUE_OTHER_THAN_1_FAILS);
  %let PDD_APPROVE_NEW_BASELINE = 1;
  %p17_assert_backup_current;
  %_expect_ok(case=T12_APPROVAL_1_TAKES_NEW_BASELINE);
  %let PDD_APPROVE_NEW_BASELINE = 0;
  %p17_assert_backup_current;
  %_expect_ok(case=T12_REGISTRY_EQUALS_NEW_BACKUP);

  /* ---- T14 registry baseline guard (17a rule, same pattern as 15a) -------------- */
  /* test-only: WORK registry removed so the absent-registry path can run */
  proc delete data=pdd.pecan_id_registry;
  run;
  %let _t14_prop = %sysfunc(pathname(work))\t14_proposed.csv;
  %let _t14_sum = %sysfunc(pathname(work))\t14_summary.csv;
  %let PDD_APPROVE_NEW_BASELINE = 0;
  %p17_registry_baseline(in=work.t9_regk1, propfile=&_t14_prop, sumfile=&_t14_sum);
  %_expect_fail(case=T14_NO_APPROVAL_FAILS);
  %_chk(case=T14_NO_APPROVAL_REGISTRY_NOT_CREATED, cond=%str(%sysfunc(exist(pdd.pecan_id_registry)) = 0),
        detail=%str(registry was created without approval));
  %_chk(case=T14_NO_APPROVAL_PROPOSAL_WRITTEN, cond=%str(%sysfunc(fileexist(&_t14_prop)) = 1),
        detail=%str(proposal csv missing));
  %_chk(case=T14_NO_APPROVAL_SUMMARY_WRITTEN, cond=%str(%sysfunc(fileexist(&_t14_sum)) = 1),
        detail=%str(summary csv missing));
  %let PDD_APPROVE_NEW_BASELINE = 2;
  %p17_registry_baseline(in=work.t9_regk1, propfile=&_t14_prop, sumfile=&_t14_sum);
  %_expect_fail(case=T14_APPROVAL_VALUE_OTHER_THAN_1_FAILS);
  %_chk(case=T14_VALUE_2_REGISTRY_NOT_CREATED, cond=%str(%sysfunc(exist(pdd.pecan_id_registry)) = 0),
        detail=%str(registry created with approval value 2));
  %let PDD_APPROVE_NEW_BASELINE = 1;
  %p17_registry_baseline(in=work.t9_regk1, propfile=&_t14_prop, sumfile=&_t14_sum);
  %_expect_ok(case=T14_APPROVAL_1_NO_FAILURE);
  %p17_nobs(ds=pdd.pecan_id_registry, mv=_q);
  %_chk(case=T14_APPROVED_REGISTRY_CREATED, cond=%str(&_q = 2), detail=%str(registry rows &_q expected 2));
  %let PDD_APPROVE_NEW_BASELINE = 0;
  %p17_assert_backup_current;
  %_expect_ok(case=T14_APPROVED_REGISTRY_HAS_CURRENT_BACKUP);

%mend _run_tests;
%_run_tests;

/* ---- T13 no WARNING or ERROR lines in this log ------------------------------------------ */
proc printto; run;

data work._t13_warn_check;
  length _n_warn 8 _n_err 8;
  retain _n_warn 0 _n_err 0;
  infile "&_test_log_path" lrecl=32767 end=_eof;
  input;
  if index(upcase(_infile_), 'WARNING:') > 0 then _n_warn + 1;
  if index(upcase(_infile_), 'ERROR:') > 0
     and index(upcase(_infile_), 'TESTRESULT SUMMARY') = 0 then _n_err + 1;
  if index(upcase(_infile_), '[FAIL]') > 0 or index(upcase(_infile_), '[PASS]') > 0 then
    put _infile_;
  if _eof then do;
    call symputx('_t13_n_warn', _n_warn);
    call symputx('_t13_n_err', _n_err);
    output;
  end;
run;

%macro _t13_check;
  %if &_t13_n_warn = 0 and &_t13_n_err = 0 %then %_record(case=T13_NO_WARNINGS_OR_ERRORS_IN_LOG, result=PASS);
  %else %_record(case=T13_NO_WARNINGS_OR_ERRORS_IN_LOG, result=FAIL,
         detail=%str(&_t13_n_warn WARNING and &_t13_n_err ERROR lines found in test log));
%mend _t13_check;
%_t13_check;

%macro _final_summary;
  %if &_all_pass = 1 %then
    %put NOTE: [17_pecan_id_test] TESTRESULT SUMMARY: ALL TESTS PASSED;
  %else
    %put ERROR: [17_pecan_id_test] TESTRESULT SUMMARY: ONE OR MORE TESTS FAILED;
%mend _final_summary;
%_final_summary;
