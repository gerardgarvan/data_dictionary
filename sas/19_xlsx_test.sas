/*==========================================================================
  Program : 19_xlsx_test.sas
  Phase   : 19 (master data workbook), Wave 1, plan 19-02 (decision-free part)
  Purpose : Standalone synthetic tests for sas/19_xlsx_macros.sas.
            WORK data only (the pdd libref points at a folder inside WORK,
            out_root is a WORK folder). Reads nothing from P: and nothing from
            g. Includes no 00_config.sas. Fake MRNs are built with cats() so
            the log never echoes them.
            T0  session is UTF-8, state restored at the end
            T1  path guard: inside out_root passes; shared Master Data folder,
                an unrelated folder, a sibling with the same prefix and a
                parent reference fail
            T2  decision gate: empty stops (stop=1) or is recorded (stop=0),
                valid value any case passes, bad value fails, no list accepts
                any non-empty value, an undefined variable counts as empty
            T3  probes P19-1..P19-5, P19-8 against hand-counted values: text
                starting = # + - @, leading zero, control character, over 255
                characters, non-ASCII, newline, replacement character, special
                missing .A and ._, 1e15, 15 digit round trip, date-like ranges
            T4  limits gate (XLS-02): clean passes, boundaries pass, each limit
                breach fails, free disk -1 is recorded and not failed
            T5  control character gate: the probe count feeds the limits gate
                (fails on the control character fixture, passes on a clean one)
            T6  allow-list gate: key and mapped names pass, ENCRYPTED_MRN and an
                unmapped PCNR_ name fail
            T7  P19-6 keys: crosstab, rows per era, NORM_PSID differences,
                masked and top-coded in the CSV
            T8  mask and top-code rule
            T9  probe report: masked summary CSV, no NONBLANK row, MAXLEN exact
            T10 free space parse (dir output text) and the missing-line case
            T11 SAS benchmark: file written then deleted, timing and estimate
            T12 closed-file MRN scan: clean 0 hits, seeded 1 hit and FAIL
            T13 QC staging: 25 qadd calls give one write and 25 rows
            T14 QC dump CSV: n of 5 is masked as <11
            T15 no WARNING and no ERROR lines in this log, no fake MRN in the
                log or the CSV files
  Run     : sas 19_xlsx_test.sas  (no pipeline setup required, UTF-8 session:
            -config ...\nls\u8\sasv9.cfg -encoding utf8)
            Bring back the log and look for the TESTRESULT SUMMARY line.
  Session : own SAS session. Close any table viewer on pdd first. This test
            repoints pdd at a WORK folder and uses FLAG mode. It restores them
            at the end, but never run it in the same session as 19a.
  Status  : PENDING SAS RUN (Gerard, synthetic data only).
==========================================================================*/

%let _test_log_path = %sysfunc(pathname(work))\19_xlsx_test.log;
proc printto log="&_test_log_path" new; run;

/* session state saved here, restored by %_restore_state at the very end */
%let _saved_pdd_path = %sysfunc(pathname(pdd));

options validvarname=v7 dlcreatedir;
libname pdd "%sysfunc(pathname(work))\tpdd";
%let backup_path = %sysfunc(pathname(work))\tbak;
%let out_root = %sysfunc(pathname(work));
options nodlcreatedir;

/* %fail_out is only reached in ABORT mode, which this test never uses */
%macro fail_out(msg=);
  %put ERROR: [19_xlsx_test] unexpected abort - &msg;
  %abort cancel;
%mend fail_out;

%include "C:\data_dictionary\sas\19_xlsx_macros.sas";

%let _saved_p19_mode = &p19_fail_mode;
%let _saved_p18_mode = &p18_fail_mode;
%let _saved_p17_mode = &p17_fail_mode;
%let p19_fail_mode = FLAG;
%let p18_fail_mode = FLAG;
%let p17_fail_mode = FLAG;
%macro _globals_t;
  %global PDD_XLS_T _v _c;
%mend _globals_t;
%_globals_t;
%let PDD_XLS_T = ;

%macro _restore_state;
  %let p19_fail_mode = &_saved_p19_mode;
  %let p18_fail_mode = &_saved_p18_mode;
  %let p17_fail_mode = &_saved_p17_mode;
  %let _p19_failed = 0;
  %let _p18_failed = 0;
  %if %length(&_saved_pdd_path) > 0 %then %do;
    libname pdd base "&_saved_pdd_path";
  %end;
  %else %if %sysfunc(libref(pdd)) = 0 %then %do;
    libname pdd clear;
  %end;
  %put NOTE: [19_xlsx_test] session state restored - fail modes reset and pdd libref reset;
  %put NOTE: [19_xlsx_test] run production programs each in a fresh SAS session;
%mend _restore_state;

%let _all_pass = 1;
%macro _record(case=, result=, detail=);
  %if %upcase(&result) = PASS %then
    %put NOTE: [PASS] &case;
  %else %do;
    %put NOTE: [FAIL] &case -- &detail;
    %let _all_pass = 0;
  %end;
%mend _record;

/* the check is FAIL unless cond evaluates true (C34: %unquote).
   num=1: cond holds a decimal comparison, evaluated with %sysevalf(..., boolean)
   into a variable first, so an evaluation problem records FAIL. */
%macro _chk(case=, cond=, detail=, num=0);
  %local _res _r;
  %let _res = FAIL;
  %if &num = 1 %then %do;
    %let _r = 0;
    %let _r = %sysevalf(%unquote(&cond), boolean);
    %if "&_r" = "1" %then %let _res = PASS;
  %end;
  %else %do;
    %if %unquote(&cond) %then %let _res = PASS;
  %end;
  %if &_res = PASS %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(&detail - or the check could not be evaluated));
%mend _chk;

%macro _expect_fail(case=);
  %if &_p19_failed = 1 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(gate did not fail));
  %let _p19_failed = 0;
%mend _expect_fail;

%macro _expect_ok(case=);
  %if &_p19_failed = 0 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(unexpected failure));
  %let _p19_failed = 0;
%mend _expect_ok;

%macro _val(ds=, var=, where=1, mv=_v);
  %let &mv = ;
  proc sql noprint;
    select &var into :&mv trimmed from &ds where %unquote(&where);
  quit;
%mend _val;

%macro _cnt(ds=, where=1, mv=_c);
  %let &mv = 0;
  proc sql noprint;
    select count(*) into :&mv trimmed from &ds where %unquote(&where);
  quit;
%mend _cnt;

/* probe count of one variable and one check, 0 when absent */
%macro _pcell(var=, chk=, ds=work.p19_pr, mv=_c);
  %let &mv = 0;
  proc sql noprint;
    select coalesce(sum(n), 0) into :&mv trimmed from &ds
    where upcase(variable) = "%upcase(&var)" and chk = "&chk";
  quit;
%mend _pcell;

%macro _drop(ds=);
  %if %sysfunc(exist(&ds)) %then %do;
    proc delete data=&ds;
    run;
  %end;
%mend _drop;

%macro _run_tests;
  %local _i _wk _f1 _f2 _f3 _f4 _t13file;
  %let _wk = %sysfunc(pathname(work));

  /* ---- T0 session ---------------------------------------------------------------- */
  %_chk(case=T0_SESSION_IS_UTF8, cond=%str(%"%lowcase(&sysencoding)%" = %"utf-8%"), detail=%str(run with the UTF-8 configuration));

  /* ---- T1 path guard ------------------------------------------------------------- */
  %p19_path_guard(path=&out_root\stage\x.csv);
  %_expect_ok(case=T1_PATH_INSIDE_OUT_ROOT_PASSES);
  %p19_path_guard(path=&out_root);
  %_expect_ok(case=T1_OUT_ROOT_ITSELF_PASSES);
  %p19_path_guard(path=%str(P:\PeCAN Master Data\00 Shared Data\DSS Received Data\x.csv));
  %_expect_fail(case=T1_SHARED_FOLDER_FAILS);
  %p19_path_guard(path=%str(C:\other\x.csv));
  %_expect_fail(case=T1_UNRELATED_FOLDER_FAILS);
  %p19_path_guard(path=&out_root.X\x.csv);
  %_expect_fail(case=T1_SIBLING_WITH_SAME_PREFIX_FAILS);
  %p19_path_guard(path=&out_root\..\x.csv);
  %_expect_fail(case=T1_PARENT_REFERENCE_FAILS);
  %p19_path_guard(path=&out_root\00 Shared Data\x.csv);
  %_expect_fail(case=T1_SHARED_NAME_UNDER_OUT_ROOT_FAILS);

  /* ---- T2 decision gate ---------------------------------------------------------- */
  %let PDD_XLS_T = ;
  %p19_need_decision(var=PDD_XLS_T, allowed=%str(STAGE_CSV PROC_EXPORT), stop=1);
  %_expect_fail(case=T2_EMPTY_STOPS);
  %_chk(case=T2_EMPTY_STATUS, cond=%str(&_p19_dec_status = EMPTY), detail=%str(status));
  %p19_need_decision(var=PDD_XLS_T, allowed=%str(STAGE_CSV PROC_EXPORT), stop=0);
  %_expect_ok(case=T2_EMPTY_RECORDED_WHEN_STOP_OFF);
  %_chk(case=T2_EMPTY_STATUS_STOP_OFF, cond=%str(&_p19_dec_status = EMPTY), detail=%str(status));
  %let PDD_XLS_T = stage_csv;
  %p19_need_decision(var=PDD_XLS_T, allowed=%str(STAGE_CSV PROC_EXPORT), stop=1);
  %_expect_ok(case=T2_VALID_VALUE_ANY_CASE_PASSES);
  %_chk(case=T2_VALID_STATUS_SET, cond=%str(&_p19_dec_status = SET), detail=%str(status));
  %let PDD_XLS_T = BAD;
  %p19_need_decision(var=PDD_XLS_T, allowed=%str(STAGE_CSV PROC_EXPORT), stop=0);
  %_expect_fail(case=T2_BAD_VALUE_FAILS_EVEN_WITH_STOP_OFF);
  %_chk(case=T2_BAD_STATUS_INVALID, cond=%str(&_p19_dec_status = INVALID), detail=%str(status));
  %let PDD_XLS_T = ANYTHING;
  %p19_need_decision(var=PDD_XLS_T, allowed=, stop=1);
  %_expect_ok(case=T2_NO_LIST_ACCEPTS_NON_EMPTY);
  %p19_need_decision(var=PDD_XLS_NOT_DEFINED_ANYWHERE, allowed=, stop=1);
  %_expect_fail(case=T2_UNDEFINED_VARIABLE_COUNTS_AS_EMPTY);
  %let PDD_XLS_T = ;

  /* ---- T3 probes ----------------------------------------------------------------- */
  data work.t3;
    length c1 $400 c2 $20 x 8 y 8 z 8;
    c1 = '=SUM(1)'; c2 = '007'; x = .A; y = 1e15; z = .; output;
    c1 = '#N/A'; c2 = '-5'; x = ._; y = 1/3; z = 45000; output;
    c1 = cats('a', '01'x, 'b'); c2 = '+x'; x = .A; y = 0.5; z = 1.5e9; output;
    c1 = repeat('x', 298); c2 = '@h'; x = 1; y = 2; z = .; output;
    c1 = cats('caf', 'C3A9'x); c2 = ''; x = 2; y = .; z = .; output;
    c1 = cats('a', '0A'x, 'b'); c2 = '0'; x = .; y = .; z = .; output;
    c1 = ''; c2 = 'NULL'; x = .; y = .; z = .; output;
    c1 = cats('r', 'EFBFBD'x); c2 = 'abc'; x = .; y = .; z = .; output;
  run;
  %p19_probe(ds=work.t3, out=work.p19_pr);
  %_chk(case=T3_FACTS_ROWS, cond=%str(&_p19_nrows = 8), detail=%str(rows));
  %_chk(case=T3_FACTS_CHAR_AND_NUM_COUNTS, cond=%str(&_p19_nchar = 2 and &_p19_nnum = 3), detail=%str(counts));
  %_pcell(var=c1, chk=NONBLANK);
  %_chk(case=T3_C1_NONBLANK_7, cond=%str(&_c = 7), detail=%str(nonblank));
  %_pcell(var=c1, chk=LEAD_EQ);
  %_chk(case=T3_C1_LEADING_EQUALS_1, cond=%str(&_c = 1), detail=%str(equals));
  %_pcell(var=c1, chk=LEAD_HASH);
  %_chk(case=T3_C1_LEADING_HASH_1, cond=%str(&_c = 1), detail=%str(hash));
  %_pcell(var=c1, chk=CTRL);
  %_chk(case=T3_C1_CONTROL_CHAR_1, cond=%str(&_c = 1), detail=%str(control));
  %_pcell(var=c1, chk=GT255);
  %_chk(case=T3_C1_OVER_255_1, cond=%str(&_c = 1), detail=%str(over 255));
  %_pcell(var=c1, chk=MAXLEN);
  %_chk(case=T3_C1_MAX_LENGTH_299, cond=%str(&_c = 299), detail=%str(maxlen));
  %_pcell(var=c1, chk=NONASCII);
  %_chk(case=T3_C1_NON_ASCII_2, cond=%str(&_c = 2), detail=%str(non-ascii));
  %_pcell(var=c1, chk=REPLCHAR);
  %_chk(case=T3_C1_REPLACEMENT_CHAR_1, cond=%str(&_c = 1), detail=%str(replacement));
  %_pcell(var=c1, chk=NEWLINE);
  %_chk(case=T3_C1_NEWLINE_1, cond=%str(&_c = 1), detail=%str(newline));
  %_pcell(var=c2, chk=NONBLANK);
  %_chk(case=T3_C2_NONBLANK_7, cond=%str(&_c = 7), detail=%str(nonblank));
  %_pcell(var=c2, chk=LEAD_ZERO);
  %_chk(case=T3_C2_LEADING_ZERO_1_NOT_SINGLE_ZERO, cond=%str(&_c = 1), detail=%str(leading zero));
  %_pcell(var=c2, chk=LEAD_MINUS);
  %_chk(case=T3_C2_LEADING_MINUS_1, cond=%str(&_c = 1), detail=%str(minus));
  %_pcell(var=c2, chk=LEAD_PLUS);
  %_chk(case=T3_C2_LEADING_PLUS_1, cond=%str(&_c = 1), detail=%str(plus));
  %_pcell(var=c2, chk=LEAD_AT);
  %_chk(case=T3_C2_LEADING_AT_1, cond=%str(&_c = 1), detail=%str(at));
  %_pcell(var=c2, chk=CTRL);
  %_chk(case=T3_C2_NO_CONTROL_CHAR, cond=%str(&_c = 0), detail=%str(control));
  %_pcell(var=x, chk=SPECIAL_A);
  %_chk(case=T3_X_SPECIAL_A_2, cond=%str(&_c = 2), detail=%str(special A));
  %_pcell(var=x, chk=SPECIAL__);
  %_chk(case=T3_X_SPECIAL_UNDERSCORE_1, cond=%str(&_c = 1), detail=%str(special underscore));
  %_pcell(var=x, chk=NONMISS);
  %_chk(case=T3_X_NONMISS_2_SPECIALS_NOT_COUNTED, cond=%str(&_c = 2), detail=%str(nonmiss));
  %_pcell(var=y, chk=GE_1E15);
  %_chk(case=T3_Y_AT_OR_ABOVE_1E15_1, cond=%str(&_c = 1), detail=%str(1e15));
  %_pcell(var=y, chk=NO_15SIG_ROUNDTRIP);
  %_chk(case=T3_Y_NO_15_DIGIT_ROUNDTRIP_1, cond=%str(&_c = 1), detail=%str(round trip));
  %_pcell(var=y, chk=NONMISS);
  %_chk(case=T3_Y_NONMISS_4, cond=%str(&_c = 4), detail=%str(nonmiss));
  %_pcell(var=z, chk=INT_IN_DATE_RANGE);
  %_chk(case=T3_Z_DATE_RANGE_1, cond=%str(&_c = 1), detail=%str(date range));
  %_pcell(var=z, chk=INT_IN_DTTM_RANGE);
  %_chk(case=T3_Z_DATETIME_RANGE_1, cond=%str(&_c = 1), detail=%str(datetime range));
  %_cnt(ds=work.p19_pr, where=%str(vtype = %"CHAR%"));
  %_chk(case=T3_VTYPE_CHAR_ROWS_PRESENT, cond=%str(&_c > 0), detail=%str(char rows));
  %_cnt(ds=work.p19_pr, where=%str(tot ne 8));
  %_chk(case=T3_TOT_IS_ROW_COUNT, cond=%str(&_c = 0), detail=%str(tot));
  %p19_probe_gate_inputs(in=work.p19_pr);
  %_chk(case=T3_GATE_INPUT_MAXLEN_299, cond=%str(&_p19_maxlen = 299), detail=%str(maxlen));
  %_chk(case=T3_GATE_INPUT_CONTROL_1, cond=%str(&_p19_nctrl = 1), detail=%str(control));

  /* ---- T4 limits gate ------------------------------------------------------------ */
  %p19_qinit(ds=work.qc_xlsx_t4);
  %p19_limits(rows=77498, cols=1302, maxlen=500, nctrl=0, freegb=100, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_ok(case=T4_CLEAN_PASSES);
  %p19_limits(rows=1048573, cols=16383, maxlen=32767, nctrl=0, freegb=15, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_ok(case=T4_BOUNDARIES_PASS);
  %p19_limits(rows=1048574, cols=1302, maxlen=500, nctrl=0, freegb=100, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_fail(case=T4_ROWS_OVER_LIMIT_FAILS);
  %p19_limits(rows=77498, cols=16384, maxlen=500, nctrl=0, freegb=100, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_fail(case=T4_COLUMNS_OVER_LIMIT_FAILS);
  %p19_limits(rows=77498, cols=1302, maxlen=32768, nctrl=0, freegb=100, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_fail(case=T4_TEXT_OVER_LIMIT_FAILS);
  %p19_limits(rows=77498, cols=1302, maxlen=500, nctrl=1, freegb=100, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_fail(case=T4_CONTROL_CHAR_FAILS);
  %p19_limits(rows=77498, cols=1302, maxlen=500, nctrl=0, freegb=14, mingb=15, qc=work.qc_xlsx_t4);
  %_expect_fail(case=T4_LOW_DISK_FAILS);
  %p19_qinit(ds=work.qc_xlsx_t4b);
  %p19_limits(rows=77498, cols=1302, maxlen=500, nctrl=0, freegb=-1, mingb=15, qc=work.qc_xlsx_t4b);
  %_expect_ok(case=T4_UNMEASURED_DISK_RECORDED_NOT_FAILED);
  %_cnt(ds=work.qc_xlsx_t4b, where=%str(item = %"free_disk_not_measurable_check_by_hand%"));
  %_chk(case=T4_UNMEASURED_DISK_ROW_PRESENT, cond=%str(&_c = 1), detail=%str(row));

  /* ---- T5 control character gate fed by the probe -------------------------------- */
  %p19_qinit(ds=work.qc_xlsx_t5);
  %p19_limits(rows=&_p19_nrows, cols=&_p19_ncols, maxlen=&_p19_maxlen, nctrl=&_p19_nctrl,
              freegb=100, mingb=15, qc=work.qc_xlsx_t5);
  %_expect_fail(case=T5_PROBE_CONTROL_CHAR_FAILS_GATE);
  data work.t5;
    length c1 $20 x 8;
    c1 = 'plain'; x = 1; output;
    c1 = cats('tab', '09'x, 'ok'); x = .; output;
    c1 = cats('cr', '0D'x, 'ok'); x = 2; output;
  run;
  %p19_probe(ds=work.t5, out=work.p19_pr5);
  %p19_probe_gate_inputs(in=work.p19_pr5);
  %_chk(case=T5_TAB_AND_CR_ARE_NOT_ILLEGAL, cond=%str(&_p19_nctrl = 0), detail=%str(control count));
  %p19_limits(rows=&_p19_nrows, cols=&_p19_ncols, maxlen=&_p19_maxlen, nctrl=&_p19_nctrl,
              freegb=100, mingb=15, qc=work.qc_xlsx_t5);
  %_expect_ok(case=T5_CLEAN_FIXTURE_PASSES_GATE);

  /* ---- T6 allow-list gate -------------------------------------------------------- */
  data work.t6v;
    length pcnr_name $64;
    pcnr_name = 'PCNR_A'; output;
    pcnr_name = 'pcnr_b'; output;
  run;
  data work.t6;
    length PECAN_ID 8 PRECEDE_STUDY_ID $20 KEY_ERA $2 PCNR_A $5 PCNR_B 8;
    stop;
  run;
  %p19_qinit(ds=work.qc_xlsx_t6);
  %p19_allowlist(ds=work.t6, vars=work.t6v, qc=work.qc_xlsx_t6, out=work.t6f);
  %_expect_ok(case=T6_KEY_AND_MAPPED_NAMES_PASS);
  %_cnt(ds=work.t6f);
  %_chk(case=T6_NO_FLAGGED_NAMES, cond=%str(&_c = 0), detail=%str(flagged));
  data work.t6b;
    length PECAN_ID 8 KEY_ERA $2 PCNR_A $5 ENCRYPTED_MRN $64;
    stop;
  run;
  %p19_allowlist(ds=work.t6b, vars=work.t6v, qc=work.qc_xlsx_t6, out=work.t6f);
  %_expect_fail(case=T6_ENCRYPTED_MRN_COLUMN_FAILS);
  %_cnt(ds=work.t6f, where=%str(upcase(colname) = %"ENCRYPTED_MRN%"));
  %_chk(case=T6_ENCRYPTED_MRN_NAME_IS_FLAGGED, cond=%str(&_c = 1), detail=%str(flagged name));
  data work.t6c;
    length PECAN_ID 8 KEY_ERA $2 PCNR_A $5 PCNR_ZZ $5;
    stop;
  run;
  %p19_allowlist(ds=work.t6c, vars=work.t6v, qc=work.qc_xlsx_t6, out=work.t6f);
  %_expect_fail(case=T6_UNMAPPED_PCNR_NAME_FAILS);

  /* ---- T7 P19-6 key columns ------------------------------------------------------ */
  data work.t7;
    length KEY_ERA $2 PECAN_ID_KEY_ERA $2 NORM_PSID $64 PRECEDE_STUDY_ID $64;
    do _i = 1 to 30;
      KEY_ERA = 'K1'; PECAN_ID_KEY_ERA = 'K1';
      NORM_PSID = cats('Precede', put(_i, z5.));
      if _i <= 3 then PRECEDE_STUDY_ID = strip(put(_i, best12.));
      else PRECEDE_STUDY_ID = NORM_PSID;
      output;
    end;
    do _i = 1 to 20;
      KEY_ERA = 'K2';
      if _i = 1 then PECAN_ID_KEY_ERA = 'K1'; else PECAN_ID_KEY_ERA = 'K2';
      NORM_PSID = cats('Precede', put(100 + _i, z5.));
      PRECEDE_STUDY_ID = NORM_PSID;
      output;
    end;
    drop _i;
  run;
  %p19_keys(ds=work.t7, out=work.p19_pr_k);
  %_pcell(var=KEYS, chk=XTAB_K1_K1, ds=work.p19_pr_k);
  %_chk(case=T7_K1_K1_30, cond=%str(&_c = 30), detail=%str(K1xK1));
  %_pcell(var=KEYS, chk=XTAB_K2_K2, ds=work.p19_pr_k);
  %_chk(case=T7_K2_K2_19, cond=%str(&_c = 19), detail=%str(K2xK2));
  %_pcell(var=KEYS, chk=XTAB_K2_K1, ds=work.p19_pr_k);
  %_chk(case=T7_K2_K1_1_MISMATCH_COUNTED, cond=%str(&_c = 1), detail=%str(K2xK1));
  %_pcell(var=KEYS, chk=PSID_DIFFERS_K1, ds=work.p19_pr_k);
  %_chk(case=T7_PSID_DIFFERS_K1_3, cond=%str(&_c = 3), detail=%str(psid differs K1));
  %_pcell(var=KEYS, chk=PSID_DIFFERS_K2, ds=work.p19_pr_k);
  %_chk(case=T7_PSID_DIFFERS_K2_0, cond=%str(&_c = 0), detail=%str(psid differs K2));
  %_pcell(var=KEYS, chk=ERA_ROWS_K2, ds=work.p19_pr_k);
  %_chk(case=T7_ERA_ROWS_K2_20, cond=%str(&_c = 20), detail=%str(era rows));
  %let _f1 = &_wk\t7_detail.csv;
  %let _f2 = &_wk\t7_summary.csv;
  %p19_probe_report(in=work.p19_pr_k, detail=&_f1, summary=&_f2);
  data work.t7r;
    infile "&_f1" dsd firstobs=2 truncover;
    length variable $64 chk $40 vtype $4 nm $12;
    input variable $ chk $ vtype $ nm $;
  run;
  %_val(ds=work.t7r, var=nm, where=%str(chk = %"XTAB_K2_K1%"));
  %_chk(case=T7_SMALL_CELL_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(mask of 1));
  %_val(ds=work.t7r, var=nm, where=%str(chk = %"XTAB_K2_K2%"));
  %_chk(case=T7_COMPLEMENT_OF_SMALL_CELL_TOP_CODED, cond=%str(%"&_v%" = %">9%"), detail=%str(top code of 19 in 20));
  %_val(ds=work.t7r, var=nm, where=%str(chk = %"PSID_DIFFERS_K1%"));
  %_chk(case=T7_PSID_DIFF_3_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(mask of 3));
  %_val(ds=work.t7r, var=nm, where=%str(chk = %"XTAB_K1_K1%"));
  %_chk(case=T7_FULL_CELL_EXACT, cond=%str(%"&_v%" = %"30%"), detail=%str(exact 30));

  /* ---- T8 mask and top-code ------------------------------------------------------ */
  data work.t8;
    length chk $40 n 8 tot 8;
    tot = 1000;
    chk = 'A'; n = 0; output;
    n = 1; output;
    n = 10; output;
    n = 11; output;
    n = 989; output;
    n = 990; output;
    n = 999; output;
    n = 1000; output;
    chk = 'MAXLEN'; n = 5; output;
  run;
  %p19_mask_ds(in=work.t8, out=work.t8m);
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 0));
  %_chk(case=T8_ZERO_EXACT, cond=%str(%"&_v%" = %"0%"), detail=%str(zero));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 1));
  %_chk(case=T8_ONE_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(one));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 10));
  %_chk(case=T8_TEN_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(ten));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 11));
  %_chk(case=T8_ELEVEN_EXACT, cond=%str(%"&_v%" = %"11%"), detail=%str(eleven));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 989));
  %_chk(case=T8_ELEVEN_FROM_TOTAL_EXACT, cond=%str(%"&_v%" = %"989%"), detail=%str(989));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 990));
  %_chk(case=T8_TEN_FROM_TOTAL_TOP_CODED, cond=%str(%"&_v%" = %">989%"), detail=%str(990));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 999));
  %_chk(case=T8_ONE_FROM_TOTAL_TOP_CODED, cond=%str(%"&_v%" = %">989%"), detail=%str(999));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"A%" and n = 1000));
  %_chk(case=T8_ALL_ROWS_EXACT, cond=%str(%"&_v%" = %"1000%"), detail=%str(1000));
  %_val(ds=work.t8m, var=n_masked, where=%str(chk = %"MAXLEN%"));
  %_chk(case=T8_MAXLEN_IS_NOT_MASKED, cond=%str(%"&_v%" = %"5%"), detail=%str(maxlen));

  /* ---- T9 probe report ----------------------------------------------------------- */
  %let _f3 = &_wk\t9_detail.csv;
  %let _f4 = &_wk\t9_summary.csv;
  %p19_probe_report(in=work.p19_pr, detail=&_f3, summary=&_f4);
  data work.t9s;
    infile "&_f4" dsd firstobs=2 truncover;
    length chk $40 vtype $4 nv $12 mx $12;
    input chk $ vtype $ nv $ mx $;
  run;
  %_cnt(ds=work.t9s, where=%str(chk in (%"NONBLANK%", %"NONMISS%")));
  %_chk(case=T9_SUMMARY_HAS_NO_NONBLANK_OR_NONMISS_ROW, cond=%str(&_c = 0), detail=%str(rows));
  %_val(ds=work.t9s, var=mx, where=%str(chk = %"MAXLEN%" and vtype = %"CHAR%"));
  %_chk(case=T9_SUMMARY_MAXLEN_EXACT_299, cond=%str(%"&_v%" = %"299%"), detail=%str(maxlen));
  %_val(ds=work.t9s, var=nv, where=%str(chk = %"CTRL%" and vtype = %"CHAR%"));
  %_chk(case=T9_SUMMARY_ONE_VARIABLE_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(one variable));
  %_val(ds=work.t9s, var=mx, where=%str(chk = %"CTRL%" and vtype = %"CHAR%"));
  %_chk(case=T9_SUMMARY_MAX_COUNT_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(max count));
  data work.t9d;
    infile "&_f3" dsd firstobs=2 truncover;
    length variable $64 chk $40 vtype $4 nm $12;
    input variable $ chk $ vtype $ nm $;
  run;
  %_val(ds=work.t9d, var=nm, where=%str(upcase(variable) = %"C1%" and chk = %"NONBLANK%"));
  %_chk(case=T9_DETAIL_SEVEN_CELLS_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(7 cells));

  /* ---- T10 free space parse ------------------------------------------------------ */
  %global _t10_free;
  %let _f1 = &_wk\t10_dir.txt;
  data _null_;
    file "&_f1";
    put ' Volume in drive P is Data';
    put ' Directory of P:\';
    put '12/01/2025  10:00 AM    <DIR>          x';
    put '               2 File(s)       123456 bytes';
    put '               5 Dir(s)  107374182400 bytes free';
  run;
  filename p19t10 "&_f1";
  %p19_freegb_parse(fileref=p19t10, mv=_t10_free);
  filename p19t10 clear;
  %_chk(case=T10_FREE_SPACE_100_GB, cond=%str(&_t10_free = 100), detail=%str(free gb));
  %let _f2 = &_wk\t10_dir2.txt;
  data _null_;
    file "&_f2";
    put ' Volume in drive P is Data';
    put '               2 File(s)       123456 bytes';
  run;
  filename p19t10 "&_f2";
  %p19_freegb_parse(fileref=p19t10, mv=_t10_free);
  filename p19t10 clear;
  %_chk(case=T10_NO_BYTES_FREE_LINE_GIVES_MINUS_ONE, cond=%str(&_t10_free = -1), detail=%str(missing line));

  /* ---- T11 SAS benchmark --------------------------------------------------------- */
  %let _f3 = &_wk\t11_bench.csv;
  %p19_bench_sas(ds=work.t3, file=&_f3, rows=1000);
  %_expect_ok(case=T11_BENCH_RUNS_AND_DELETES_ITS_FILE);
  %_chk(case=T11_BENCH_FILE_IS_GONE, cond=%str(%sysfunc(fileexist(&_f3)) = 0), detail=%str(file left behind));
  %_chk(case=T11_BENCH_SECONDS_NUMERIC, cond=%str(&_p19_bench_secs >= 0), detail=%str(seconds), num=1);
  %_chk(case=T11_BENCH_ESTIMATE_NUMERIC, cond=%str(&_p19_bench_est_min >= 0), detail=%str(estimate), num=1);

  /* ---- T12 closed-file MRN scan -------------------------------------------------- */
  data pdd.pecan_id_registry;
    length ENCRYPTED_MRN $64;
    ENCRYPTED_MRN = cats('MRN', 'CANARY', '0001');
    output;
  run;
  %let _f1 = &_wk\t12_clean.txt;
  %let _f2 = &_wk\t12_seed.txt;
  data _null_;
    file "&_f1";
    put 'NOTE: nothing here, counts 40 and tokens only';
  run;
  data _null_;
    length _s $13;
    file "&_f2";
    _s = cats('MRN', 'CANARY', '0001');
    put 'seeded line ' _s $13. ' end';
  run;
  %global _scan_files;
  %let _scan_files = &_f1;
  %p19_scan_closed(filesmv=_scan_files, out=work.sc1);
  %_expect_ok(case=T12_CLEAN_FILE_HAS_NO_HITS);
  %_chk(case=T12_CLEAN_HIT_COUNT_ZERO, cond=%str(&_p18_scan_hits = 0), detail=%str(hits));
  %let _scan_files = &_f1|&_f2;
  %let _p18_failed = 0;
  %p19_scan_closed(filesmv=_scan_files, out=work.sc1);
  %_chk(case=T12_SEEDED_FILE_FAILS, cond=%str(&_p18_failed = 1), detail=%str(scan did not fail));
  %let _p18_failed = 0;
  %_chk(case=T12_SEEDED_HIT_COUNT_ONE, cond=%str(&_p18_scan_hits = 1), detail=%str(hits));

  /* ---- T13 QC staging ------------------------------------------------------------ */
  proc datasets lib=work nolist;
    delete qc_xlsx_: ;
  quit;
  %p19_qinit(ds=pdd.qc_xlsx_t13);
  %do _i = 1 %to 25;
    %p19_qadd(ds=pdd.qc_xlsx_t13, item=row&_i, n=&_i);
  %end;
  %p19_flush_qc;
  %_chk(case=T13_ONE_WRITE_FOR_TWENTY_FIVE_ROWS, cond=%str(&_p19_flush_writes = 1), detail=%str(writes));
  %_cnt(ds=pdd.qc_xlsx_t13);
  %_chk(case=T13_TWENTY_FIVE_ROWS_WRITTEN, cond=%str(&_c = 25), detail=%str(rows));

  /* ---- T14 QC dump CSV ----------------------------------------------------------- */
  %p19_qinit(ds=work.qc_xlsx_t14);
  %p19_qadd(ds=work.qc_xlsx_t14, item=small_count, n=5);
  %p19_qadd(ds=work.qc_xlsx_t14, item=large_count, n=500);
  %let _t13file = &_wk\t14.csv;
  %p19_dump_qc(tables=t14, file=&_t13file);
  data work.t14r;
    infile "&_t13file" dsd firstobs=2 truncover;
    length a $32 b $80 c $12 d $4;
    input a $ b $ c $ d $;
  run;
  %_val(ds=work.t14r, var=c, where=%str(b = %"small_count%"));
  %_chk(case=T14_SMALL_COUNT_MASKED, cond=%str(%"&_v%" = %"<11%"), detail=%str(mask));
  %_val(ds=work.t14r, var=c, where=%str(b = %"large_count%"));
  %_chk(case=T14_LARGE_COUNT_EXACT, cond=%str(%"&_v%" = %"500%"), detail=%str(exact));
%mend _run_tests;
%_run_tests;

/* ---- T15 no WARNING or ERROR lines, no fake MRN in log or CSV ------------------------------- */
proc printto; run;

data work._t15_log_check;
  length _n_warn 8 _n_err 8;
  retain _n_warn 0 _n_err 0;
  infile "&_test_log_path" lrecl=32767 end=_eof;
  input;
  if upcase(_infile_) =: 'WARNING' then _n_warn + 1;
  if upcase(_infile_) =: 'ERROR'
     and index(upcase(_infile_), 'TESTRESULT SUMMARY') = 0 then _n_err + 1;
  if index(upcase(_infile_), '[FAIL]') > 0 or index(upcase(_infile_), '[PASS]') > 0 then
    put _infile_;
  if _eof then do;
    call symputx('_t15_n_warn', _n_warn);
    call symputx('_t15_n_err', _n_err);
    output;
  end;
run;

%macro _t15_check;
  %if &_t15_n_warn = 0 and &_t15_n_err = 0 %then %_record(case=T15_NO_WARNINGS_OR_ERRORS_IN_LOG, result=PASS);
  %else %_record(case=T15_NO_WARNINGS_OR_ERRORS_IN_LOG, result=FAIL,
         detail=%str(&_t15_n_warn WARNING and &_t15_n_err ERROR lines found in test log));
  %let _scan_files = &_test_log_path|%sysfunc(pathname(work))\t7_detail.csv|%sysfunc(pathname(work))\t9_detail.csv|%sysfunc(pathname(work))\t14.csv;
  %let _p18_failed = 0;
  %p19_scan_closed(filesmv=_scan_files, out=work.sc2);
  %if &_p18_scan_hits = 0 %then %_record(case=T15_NO_FAKE_MRN_IN_LOG_OR_CSV, result=PASS);
  %else %_record(case=T15_NO_FAKE_MRN_IN_LOG_OR_CSV, result=FAIL, detail=%str(fake MRN found in log or CSV));
%mend _t15_check;
%_t15_check;

%macro _t0_check;
  %_restore_state;
  %if %length(&_saved_pdd_path) = 0 %then %do;
    %_chk(case=T0_PDD_LIBREF_RESTORED, cond=%str(%sysfunc(libref(pdd)) ne 0), detail=%str(pdd still assigned));
  %end;
  %else %do;
    %_chk(case=T0_PDD_LIBREF_RESTORED, cond=%str(%length(%sysfunc(pathname(pdd))) > 0), detail=%str(pdd not restored));
  %end;
  %_chk(case=T0_FAIL_MODE_RESTORED, cond=%str(&p19_fail_mode = &_saved_p19_mode), detail=%str(fail mode));
%mend _t0_check;
%_t0_check;

%macro _final_summary;
  %if &_all_pass = 1 %then
    %put NOTE: [19_xlsx_test] TESTRESULT SUMMARY: ALL TESTS PASSED;
  %else
    %put ERROR: [19_xlsx_test] TESTRESULT SUMMARY: ONE OR MORE TESTS FAILED;
%mend _final_summary;
%_final_summary;
