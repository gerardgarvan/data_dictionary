/*==========================================================================
  Program : 16_name_map_ext_test.sas
  Purpose : Standalone synthetic tests for the Phase 16 naming macros
            (sas/16_name_map_ext_macros.sas). Uses only work datasets and a
            synthetic abbreviation table. Reads nothing from the shared or
            output libraries.
            T1 clean_name, T2 shorten with an always row, T3 short name
            unchanged, T4 existing name skipped (Foo, Foo_2 used -> Foo_3),
            T5 two new groups with one base, T6 27-char base re-elided,
            T7 stage 2 checks, T8 no WARNING lines in this log.
  Run     : sas 16_name_map_ext_test.sas  (no pipeline setup required)
            Bring back the log and look for the TESTRESULT SUMMARY line.
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance:
    C3  No open-code %if/%else outside %macro ... %mend
==========================================================================*/

%let _test_log_path = %sysfunc(pathname(work))\16_name_map_ext_test.log;
proc printto log="&_test_log_path" new; run;

%include "C:\data_dictionary\sas\04_name_map_macros.sas";
%include "C:\data_dictionary\sas\16_name_map_ext_macros.sas";

%let _all_pass = 1;
%macro _record(case=, result=, detail=);
  %if %upcase(&result) = PASS %then
    %put NOTE: [PASS] &case;
  %else %do;
    %put ERROR: [FAIL] &case -- &detail;
    %let _all_pass = 0;
  %end;
%mend _record;

/* ---- synthetic abbreviation csv -------------------------------------- */
%let _abbrev_csv = %sysfunc(pathname(work))\t_abbrev.csv;

data _null_;
  file "&_abbrev_csv" encoding='utf-8';
  put 'long,short,mode';
  put 'Perception,Perc,always';
  put 'Mobility,Mob,as_needed';
  put 'Activity,Act,as_needed';
run;

%p16_load_abbrev(csv=&_abbrev_csv, out=work.t_abbrev, lower=1);

%macro _run_tests;

  /* ---- T1 clean_name -------------------------------------------------- */
  data work.t1;
    length raw $200 got $200 want $200;
    raw = 'BRADEN_2024_OUT_Braden Sensory Perception';
    want = 'BRADEN_2024_OUT_Braden_Sensory_Perception';
    %p16_clean_name(raw=raw, out=got)
    ok = (strip(got) = strip(want)); output;
    raw = 'ASA (Anesth Record)';
    want = 'ASA_Anesth_Record';
    %p16_clean_name(raw=raw, out=got)
    ok = (strip(got) = strip(want)); output;
    raw = '2nd value';
    want = 'N_2nd_value';
    %p16_clean_name(raw=raw, out=got)
    ok = (strip(got) = strip(want)); output;
  run;
  %local _t1_bad;
  %let _t1_bad = 1;
  proc sql noprint;
    select count(*) into :_t1_bad trimmed from work.t1 where ok = 0;
  quit;
  %if &_t1_bad = 0 %then %_record(case=T1_CLEAN_NAME, result=PASS);
  %else %_record(case=T1_CLEAN_NAME, result=FAIL, detail=%str(&_t1_bad cleaned names differ));

  /* ---- T2 and T3 shorten ---------------------------------------------- */
  data work.t23;
    length nm $200 _cbe $200 _pat $400 long short $200 mode $10
           _ai _nab_tot _longlen _is_lower _p16_longer 8
           _elide_first 8 _elide_last 8 _elide_head $200 _elide_tail $200
           case $4;
    if 0 then set work.t_abbrev (keep=long short _longlen _is_lower mode) nobs=_nab_tot;
    retain _nab_tot;
    _p16_longer = 0;
    case = 'T2';
    nm = 'BRADEN_2024_OUT_Braden_Sensory_Perception';
    %p16_shorten(nm=nm, abbrev=work.t_abbrev)
    output;
    case = 'T3';
    nm = 'Foo_Score';
    %p16_shorten(nm=nm, abbrev=work.t_abbrev)
    output;
    keep case nm _p16_longer;
  run;
  %local _t2_ok _t3_ok;
  %let _t2_ok = 0;
  %let _t3_ok = 0;
  proc sql noprint;
    select count(*) into :_t2_ok trimmed from work.t23
    where case = 'T2' and length(strip(nm)) <= 27 and index(nm, 'Perc') > 0;
    select count(*) into :_t3_ok trimmed from work.t23
    where case = 'T3' and strip(nm) = 'Foo_Score';
  quit;
  %if &_t2_ok = 1 %then %_record(case=T2_SHORTEN_ALWAYS_ROW, result=PASS);
  %else %_record(case=T2_SHORTEN_ALWAYS_ROW, result=FAIL, detail=%str(not within 27 or Perc missing));
  %if &_t3_ok = 1 %then %_record(case=T3_SHORT_UNCHANGED, result=PASS);
  %else %_record(case=T3_SHORT_UNCHANGED, result=FAIL, detail=%str(short name changed));

  /* ---- T4 existing names skipped -------------------------------------- */
  data work.t4_used;
    length name_nop $200;
    name_nop = 'Foo';   output;
    name_nop = 'Foo_2'; output;
  run;
  data work.t4_in;
    length s_code $4 pcnr_name_base $200;
    group_id = 1; s_code = 's21'; col_order = 1; pcnr_name_base = 'Foo';
  run;
  %p16_assign_names(in=work.t4_in, used=work.t4_used, out=work.t4_out)
  %local _t4_ok;
  %let _t4_ok = 0;
  proc sql noprint;
    select count(*) into :_t4_ok trimmed from work.t4_out
    where pcnr_name_final = 'PCNR_Foo_3' and reason = 'EXISTING_NAME' and suffix_n = 3;
  quit;
  %if &_t4_ok = 1 %then %_record(case=T4_EXISTING_SKIPPED, result=PASS);
  %else %_record(case=T4_EXISTING_SKIPPED, result=FAIL, detail=%str(expected PCNR_Foo_3 EXISTING_NAME 3));

  /* ---- T5 two new groups, one base ------------------------------------ */
  data work.t5_used;
    length name_nop $200;
    name_nop = 'Other'; output;
  run;
  data work.t5_in;
    length s_code $4 pcnr_name_base $200;
    group_id = 1; s_code = 's21'; col_order = 1; pcnr_name_base = 'Bar'; output;
    group_id = 2; s_code = 's22'; col_order = 1; pcnr_name_base = 'Bar'; output;
  run;
  %p16_assign_names(in=work.t5_in, used=work.t5_used, out=work.t5_out)
  %local _t5_ok;
  %let _t5_ok = 0;
  proc sql noprint;
    select count(*) into :_t5_ok trimmed from work.t5_out
    where (group_id = 1 and pcnr_name_final = 'PCNR_Bar' and reason = 'NONE')
       or (group_id = 2 and pcnr_name_final = 'PCNR_Bar_2' and reason = 'NEW_NAME_EARLIER');
  quit;
  %if &_t5_ok = 2 %then %_record(case=T5_NEW_NAME_EARLIER, result=PASS);
  %else %_record(case=T5_NEW_NAME_EARLIER, result=FAIL, detail=%str(expected Bar and Bar_2));

  /* ---- T6 27-char base re-elided -------------------------------------- */
  data work.t6_used;
    length name_nop $200;
    name_nop = 'ABCDEFGHIJKLM_NOPQRSTUVWXYZ'; output;
  run;
  data work.t6_in;
    length s_code $4 pcnr_name_base $200;
    group_id = 1; s_code = 's21'; col_order = 1;
    pcnr_name_base = 'ABCDEFGHIJKLM_NOPQRSTUVWXYZ';
  run;
  %p16_assign_names(in=work.t6_in, used=work.t6_used, out=work.t6_out)
  %local _t6_ok;
  %let _t6_ok = 0;
  proc sql noprint;
    select count(*) into :_t6_ok trimmed from work.t6_out
    where length(pcnr_name_final) <= 32
      and suffix_n = 2
      and substr(pcnr_name_final, length(pcnr_name_final) - 1) = '_2'
      and length(pcnr_name_final) - 5 - 2 = 25;
  quit;
  %if &_t6_ok = 1 %then %_record(case=T6_RE_ELIDED_BASE, result=PASS);
  %else %_record(case=T6_RE_ELIDED_BASE, result=FAIL, detail=%str(base not re-elided to 25 chars plus _2));

  /* ---- T7 stage 2 ------------------------------------------------------ */
  data work.t7_bad;
    length status $8 pcnr_name $40;
    status = 'PCNR'; group_id = 1; pcnr_name = 'PCNR_Dup'; output;
    status = 'PCNR'; group_id = 2; pcnr_name = 'PCNR_dup'; output;
  run;
  %p16_stage2(ds=work.t7_bad, label=T7, quiet=1)
  %local _t7_bad_fail;
  %let _t7_bad_fail = &p16_stage2_fail;
  data work.t7_ok;
    length status $8 pcnr_name $40;
    status = 'PCNR'; group_id = 1; pcnr_name = 'PCNR_One'; output;
    status = 'PCNR'; group_id = 2; pcnr_name = 'PCNR_Two'; output;
  run;
  %p16_stage2(ds=work.t7_ok, label=T7, quiet=1)
  %if &_t7_bad_fail >= 1 and &p16_stage2_fail = 0 %then %_record(case=T7_STAGE2, result=PASS);
  %else %_record(case=T7_STAGE2, result=FAIL,
         detail=%str(dup fail=&_t7_bad_fail clean fail=&p16_stage2_fail));

%mend _run_tests;
%_run_tests;

/* ---- T8 no WARNING lines in this log ----------------------------------- */
proc printto; run;

data work._t8_warn_check;
  length _n_warn 8;
  retain _n_warn 0;
  infile "&_test_log_path" lrecl=32767 end=_eof;
  input;
  if index(upcase(_infile_), 'WARNING:') > 0 then _n_warn + 1;
  if _eof then do;
    call symputx('_t8_n_warn', _n_warn);
    output;
  end;
run;

%macro _t8_check;
  %if &_t8_n_warn = 0 %then %_record(case=T8_NO_WARNINGS_IN_LOG, result=PASS);
  %else %_record(case=T8_NO_WARNINGS_IN_LOG, result=FAIL,
         detail=%str(&_t8_n_warn WARNING lines found in test log));
%mend _t8_check;
%_t8_check;

%macro _final_summary;
  %if &_all_pass = 1 %then
    %put NOTE: [16_name_map_ext_test] TESTRESULT SUMMARY: ALL TESTS PASSED;
  %else
    %put ERROR: [16_name_map_ext_test] TESTRESULT SUMMARY: ONE OR MORE TESTS FAILED;
%mend _final_summary;
%_final_summary;
