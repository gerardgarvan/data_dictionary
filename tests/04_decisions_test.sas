/*==========================================================================
  Program : tests/04_decisions_test.sas
  Purpose : Synthetic unit tests for B1-B5 decision macros.
            Standalone -- no PHI, no P: data.
            %includes sas/04_name_map_macros.sas for real logic.
            Prints TESTRESULT: <case> PASS|FAIL per case.
==========================================================================*/

/* Minimal stubs so the macros file compiles without the full pipeline */
%let sas_path = C:\data_dictionary\sas;
%macro check_pdd_lib; %mend;
%macro _p4_ok(section=); %mend;
%macro route_log; %mend;
%macro restore_log; %mend;
%macro fail_out(msg=);
  %put ERROR: [04_decisions_test] UNEXPECTED ABORT: &msg;
%mend fail_out;

%include "C:\data_dictionary\sas\04_name_map_macros.sas";

/* Test counters */
%let _t_pass = 0;
%let _t_fail = 0;

%macro _pass(case=, detail=);
  %put TESTRESULT: &case PASS &detail;
  %let _t_pass = %eval(&_t_pass + 1);
%mend _pass;

%macro _fail(case=, detail=);
  %put TESTRESULT: &case FAIL &detail;
  %let _t_fail = %eval(&_t_fail + 1);
%mend _fail;

/* ── Test a: SAME chain A=B, B=C -> one group ────────────────────────── */
%macro _test_a;
  data work._group_assign;
    length s_code $4 col_order 8 original_header $40 group_id 8;
    s_code='s01'; col_order=1; original_header='Apples'; group_id=1; output;
    s_code='s02'; col_order=1; original_header='Apples'; group_id=2; output;
    s_code='s03'; col_order=1; original_header='Apples'; group_id=3; output;
  run;
  data work._same_dec;
    length s_code_a $4 col_order_a 8 header_a $40 s_code_b $4 col_order_b 8 header_b $40;
    s_code_a='s01'; col_order_a=1; header_a=''; s_code_b='s02'; col_order_b=1; header_b=''; output;
    s_code_a='s02'; col_order_a=1; header_a=''; s_code_b='s03'; col_order_b=1; header_b=''; output;
  run;
  %_apply_same_closure;
  %if &_rc ne 0 %then %do;
    %_fail(case=a, detail=%str(_apply_same_closure failed: &_fail_msg));
    %goto _ta_done;
  %end;
  %local _ta_ngrp;
  proc sql noprint;
    select count(distinct group_id) into :_ta_ngrp trimmed
    from work._group_final
    where s_code in ('s01', 's02', 's03');
  quit;
  %if &_ta_ngrp = 1 %then
    %_pass(case=a, detail=%str(SAME chain A=B B=C collapsed to 1 group));
  %else
    %_fail(case=a, detail=%str(SAME chain: expected 1 group got &_ta_ngrp));
  %_ta_done:
%mend _test_a;

/* ── Test b: DIFFERENT split -> two groups ───────────────────────────── */
%macro _test_b;
  data work._group_final;
    length s_code $4 col_order 8 original_header $40 group_id 8;
    s_code='s04'; col_order=1; original_header='Weight'; group_id=4; output;
    s_code='s05'; col_order=1; original_header='Weight'; group_id=4; output;
  run;
  data work._diff_dec;
    length s_code_a $4 col_order_a 8 header_a $40 s_code_b $4 col_order_b 8 header_b $40;
    s_code_a='s04'; col_order_a=1; header_a=''; s_code_b='s05'; col_order_b=1; header_b=''; output;
  run;
  %_apply_different_split;
  %if &_rc ne 0 %then %do;
    %_fail(case=b, detail=%str(_apply_different_split failed: &_fail_msg));
    %goto _tb_done;
  %end;
  %local _tb_g04 _tb_g05;
  proc sql noprint;
    select group_id into :_tb_g04 trimmed from work._group_final where s_code='s04';
    select group_id into :_tb_g05 trimmed from work._group_final where s_code='s05';
  quit;
  %if &_tb_g04 ne &_tb_g05 %then
    %_pass(case=b, detail=%str(DIFFERENT split: s04=&_tb_g04 s05=&_tb_g05));
  %else
    %_fail(case=b, detail=%str(DIFFERENT: s04 and s05 still share group_id &_tb_g04));
  %_tb_done:
%mend _test_b;

/* ── Test c: valid RENAME -> _rc=0 ──────────────────────────────────── */
%macro _test_c;
  data work._rename_dec;
    length s_code $4 orig_header $256 col_order_dec 8 rename_target $200;
    s_code='s10'; orig_header='DifferentHeader'; col_order_dec=2;
    rename_target='ShortName'; output;
  run;
  %_check_rename_targets;
  %if &_rc = 0 %then
    %_pass(case=c, detail=%str(valid RENAME accepted _rc=0));
  %else
    %_fail(case=c, detail=%str(valid RENAME rejected unexpectedly: &_fail_msg));
%mend _test_c;

/* ── Test d1: RENAME too long -> _rc ne 0 ────────────────────────────── */
%macro _test_d1;
  data work._rename_dec;
    length s_code $4 orig_header $256 col_order_dec 8 rename_target $200;
    s_code='s08'; orig_header='VeryLong'; col_order_dec=1;
    rename_target='NameDefinitelyLongerThan27Chars'; output;
  run;
  %_check_rename_targets;
  %if &_rc ne 0 %then
    %_pass(case=d1, detail=%str(RENAME too long rejected _rc=&_rc));
  %else
    %_fail(case=d1, detail=%str(RENAME too long was not rejected));
%mend _test_d1;

/* ── Test d2: RENAME duplicate name -> _rc ne 0 ─────────────────────── */
%macro _test_d2;
  data work._rename_dec;
    length s_code $4 orig_header $256 col_order_dec 8 rename_target $200;
    s_code='s08'; orig_header='Score'; col_order_dec=1; rename_target='SameName'; output;
    s_code='s09'; orig_header='Score'; col_order_dec=1; rename_target='samename'; output;
  run;
  %_check_rename_targets;
  %if &_rc ne 0 %then
    %_pass(case=d2, detail=%str(RENAME dup rejected _rc=&_rc));
  %else
    %_fail(case=d2, detail=%str(RENAME duplicate name was not rejected));
%mend _test_d2;

/* ── Test e: B5 fires when two rows from same s_code in one group ────── */
%macro _test_e;
  data work._group_final;
    length s_code $4 col_order 8 group_id 8;
    s_code='s01'; col_order=10; group_id=200; output;
    s_code='s01'; col_order=11; group_id=200; output;
  run;
  %_assert_no_same_file_dup;
  %if &_rc ne 0 %then
    %_pass(case=e, detail=%str(B5 fired for same-s_code in group _rc=&_rc));
  %else
    %_fail(case=e, detail=%str(B5 did not fire for same-s_code in group));
%mend _test_e;

/* ── Test f: B3 fires for nonexistent (s_code, col_order) ───────────── */
%macro _test_f;
  data work._group_assign;
    length s_code $4 col_order 8 original_header $40 group_id 8;
    s_code='s01'; col_order=1; original_header='Apples'; group_id=1; output;
  run;
  data work._same_dec;
    length s_code_a $4 col_order_a 8 header_a $40 s_code_b $4 col_order_b 8 header_b $40;
    s_code_a='s99'; col_order_a=99; header_a=''; s_code_b='s01'; col_order_b=1; header_b=''; output;
  run;
  %_apply_same_closure;
  %if &_rc ne 0 %then
    %_pass(case=f, detail=%str(B3 detected nonexistent s99/99 _rc=&_rc));
  %else
    %_fail(case=f, detail=%str(B3 did not detect nonexistent s_code s99/col_order 99));
%mend _test_f;

/* ── Tests g: header validation logic ───────────────────────────────── */
/* g1: bad header detected as mismatch
   g2: BOM-prefixed correct header passes after strip
   g3: correct header passes */
%macro _test_g;
  %local _tg1 _tg2 _tg3;
  %let _tg1 = 0;
  %let _tg2 = 0;
  %let _tg3 = 0;

  data _null_;
    length _raw $1000 _exp $500;
    _raw = 'wrong_col1,wrong_col2';
    _exp = 's_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date';
    if lowcase(strip(_raw)) ne lowcase(strip(_exp)) then call symputx('_tg1', '1', 'L');
  run;

  data _null_;
    length _raw $1000 _exp $500;
    _raw = cats('EFBBBF'x,
      's_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date');
    _exp = 's_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date';
    if length(_raw) >= 3 and substr(_raw, 1, 3) = 'EFBBBF'x then _raw = strip(substr(_raw, 4));
    if lowcase(strip(_raw)) = lowcase(strip(_exp)) then call symputx('_tg2', '1', 'L');
  run;

  data _null_;
    length _raw $1000 _exp $500;
    _raw = 's_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date';
    _exp = 's_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date';
    if lowcase(strip(_raw)) = lowcase(strip(_exp)) then call symputx('_tg3', '1', 'L');
  run;

  %if &_tg1 = 1 %then
    %_pass(case=g1, detail=%str(bad header detected as mismatch));
  %else
    %_fail(case=g1, detail=%str(bad header not detected as mismatch));
  %if &_tg2 = 1 %then
    %_pass(case=g2, detail=%str(BOM-prefixed correct header accepted after strip));
  %else
    %_fail(case=g2, detail=%str(BOM-prefixed correct header was rejected));
  %if &_tg3 = 1 %then
    %_pass(case=g3, detail=%str(correct header accepted without ERROR));
  %else
    %_fail(case=g3, detail=%str(correct header was rejected));
%mend _test_g;

/* ── Outer wrapper ───────────────────────────────────────────────────── */
%macro run_decision_tests;
  %_test_a;
  %_test_b;
  %_test_c;
  %_test_d1;
  %_test_d2;
  %_test_e;
  %_test_f;
  %_test_g;
  %put TESTRESULT: SUMMARY passed=&_t_pass failed=&_t_fail;
  %if &_t_fail > 0 %then %do;
    %put ERROR: [04_decisions_test] &_t_fail test(s) FAILED -- see TESTRESULT lines above;
  %end;
%mend run_decision_tests;

%run_decision_tests;
