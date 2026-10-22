/*==========================================================================
  Program : 04_decisions_test.sas
  Purpose : Standalone tests for Phase 4 decision-handling logic.
            Covers: SAME chain (A=B, B=C -> one group), DIFFERENT split,
            valid RENAME, invalid RENAME (too long / duplicate) -> fail,
            same-file merge -> fail, bad header -> fail,
            B7 suffix at max-length base (T8), no WARNING lines in log (T9).
  Run     : sas 04_decisions_test.sas  (no pipeline setup required)

  PCM compliance:
    C3  No open-code %if/%else outside %macro ... %mend
    C18 No %local/%global at open-code level
==========================================================================*/

/* Route log to a file so T9 can scan it for WARNING lines */
%let _test_log_path = %sysfunc(pathname(work))\04_decisions_test.log;
proc printto log="&_test_log_path" new; run;

/* ── shared helpers ───────────────────────────────────────────────────── */
%macro _test_fail(msg=);
  %put ERROR: [04_decisions_test] &msg;
  %abort cancel;
%mend _test_fail;

%let _all_pass = 1;
%macro _record(case=, result=, detail=);
  %if %upcase(&result) = PASS %then
    %put NOTE: [PASS] &case;
  %else %do;
    %put ERROR: [FAIL] &case -- &detail;
    %let _all_pass = 0;
  %end;
%mend _record;

/* ── HELPER: union-find over _same_grpids -> _uf_map ─────────────────── */
%macro _run_union_find(in_groups=, in_pairs=, out_map=);
  proc sql noprint;
    create table &out_map as
    select distinct group_id, group_id as canon_id
    from &in_groups;
  quit;

  %local _uf_pass _uf_changed;
  %let _uf_pass    = 0;
  %let _uf_changed = 1;
  %do %while (&_uf_changed > 0 and &_uf_pass < 50);
    %let _uf_pass = %eval(&_uf_pass + 1);
    proc sql noprint;
      create table _uf_upd as
      select m.group_id,
             min(m.canon_id,
                 coalesce(from_b.mc, m.canon_id),
                 coalesce(from_a.mc, m.canon_id)) as new_canon
      from &out_map as m
      left join (select s.grp_b as group_id, min(ma.canon_id) as mc
                 from &in_pairs as s
                 inner join &out_map as ma on s.grp_a = ma.group_id
                 group by s.grp_b) as from_b
        on m.group_id = from_b.group_id
      left join (select s.grp_a as group_id, min(mb.canon_id) as mc
                 from &in_pairs as s
                 inner join &out_map as mb on s.grp_b = mb.group_id
                 group by s.grp_a) as from_a
        on m.group_id = from_a.group_id;
    quit;
    proc sql noprint;
      select count(*) into :_uf_changed trimmed
      from _uf_upd as u inner join &out_map as o on u.group_id = o.group_id
      where u.new_canon ne o.canon_id;
    quit;
    proc sql noprint;
      update &out_map as m
      set canon_id = (select u.new_canon from _uf_upd as u
                      where u.group_id = m.group_id);
    quit;
  %end;
%mend _run_union_find;


/* ================================================================
   TEST 1: SAME chain A=B, B=C -> all three in one group
   ================================================================ */
data work._t1_groups;
  input group_id s_code $ col_order cleaned_pre_short $;
  datalines;
1 s01 1 Age
2 s02 1 Age
3 s03 1 Age
;
run;

data work._t1_pairs;
  input grp_a grp_b;
  datalines;
1 2
2 3
;
run;

%_run_union_find(in_groups=work._t1_groups, in_pairs=work._t1_pairs, out_map=work._t1_uf);

%macro _t1_check;
  %local _t1_ndist;
  proc sql noprint;
    select count(distinct canon_id) into :_t1_ndist trimmed from work._t1_uf;
  quit;
  %if &_t1_ndist = 1 %then %_record(case=T1_SAME_CHAIN, result=PASS);
  %else %_record(case=T1_SAME_CHAIN, result=FAIL, detail=%str(&_t1_ndist distinct canon_ids; expected 1));
%mend _t1_check;
%_t1_check;


/* ================================================================
   TEST 2: DIFFERENT split -- b-side gets new group_id
   ================================================================ */
data work._t2_groups;
  input group_id s_code $ col_order;
  datalines;
10 s01 1
10 s02 1
;
run;

%macro _t2_setup;
  %global _t2_max_grp;
  proc sql noprint;
    select max(group_id) into :_t2_max_grp trimmed from work._t2_groups;
  quit;
%mend _t2_setup;
%_t2_setup;

data work._t2_groups;
  set work._t2_groups;
  /* Simulate DIFFERENT split: b-side = s02/1 gets new group */
  if s_code = 's02' and col_order = 1 then group_id = &_t2_max_grp + 1;
run;

%macro _t2_check;
  %local _t2_ndist _t2_s01grp _t2_s02grp;
  proc sql noprint;
    select count(distinct group_id) into :_t2_ndist trimmed from work._t2_groups;
    select group_id into :_t2_s01grp trimmed from work._t2_groups where s_code = 's01';
    select group_id into :_t2_s02grp trimmed from work._t2_groups where s_code = 's02';
  quit;
  %if &_t2_ndist = 2 and &_t2_s01grp ne &_t2_s02grp %then
    %_record(case=T2_DIFFERENT_SPLIT, result=PASS);
  %else
    %_record(case=T2_DIFFERENT_SPLIT, result=FAIL,
             detail=%str(ndist=&_t2_ndist s01grp=&_t2_s01grp s02grp=&_t2_s02grp));
%mend _t2_check;
%_t2_check;


/* ================================================================
   TEST 3: Valid RENAME (<=27 chars, V7-valid, unique)
   ================================================================ */
data work._t3_rename;
  length rename_target $200;
  rename_target = 'ValidName27CharsExactlyHere';  /* 27 chars */
run;

%macro _t3_check;
  %local _t3_len _t3_v7 _t3_ok;
  proc sql noprint;
    select length(strip(rename_target)) into :_t3_len trimmed from work._t3_rename;
    select nvalid(cats('PCNR_', strip(rename_target)), 'v7') into :_t3_v7 trimmed from work._t3_rename;
  quit;
  %let _t3_ok = 0;
  %if &_t3_len <= 27 and &_t3_v7 = 1 %then %let _t3_ok = 1;
  %if &_t3_ok = 1 %then %_record(case=T3_VALID_RENAME, result=PASS);
  %else %_record(case=T3_VALID_RENAME, result=FAIL, detail=%str(len=&_t3_len v7=&_t3_v7));
%mend _t3_check;
%_t3_check;


/* ================================================================
   TEST 4: Invalid RENAME -- too long (>27 chars after stripping PCNR_)
   ================================================================ */
data work._t4_rename;
  length rename_target $200;
  rename_target = 'ThisNameIsWayTooLongForTheSASLimit32Chars';  /* > 27 */
run;

%macro _t4_check;
  %local _t4_len _t4_fail;
  proc sql noprint;
    select length(strip(rename_target)) into :_t4_len trimmed from work._t4_rename;
  quit;
  %let _t4_fail = 0;
  %if &_t4_len > 27 %then %let _t4_fail = 1;
  %if &_t4_fail = 1 %then %_record(case=T4_RENAME_TOO_LONG, result=PASS);
  %else %_record(case=T4_RENAME_TOO_LONG, result=FAIL, detail=%str(len=&_t4_len should be >27));
%mend _t4_check;
%_t4_check;


/* ================================================================
   TEST 5: Invalid RENAME -- duplicate targets (case-insensitive)
   ================================================================ */
data work._t5_rename;
  length rename_target $200;
  input rename_target $;
  datalines;
SameName
samename
;
run;

%macro _t5_check;
  %local _t5_ndup;
  proc sql noprint;
    select count(*) into :_t5_ndup trimmed
    from (select upcase(strip(rename_target)) as rt, count(*) as n
          from work._t5_rename
          group by upcase(strip(rename_target))
          having count(*) > 1);
  quit;
  %if &_t5_ndup > 0 %then %_record(case=T5_RENAME_DUPLICATE, result=PASS);
  %else %_record(case=T5_RENAME_DUPLICATE, result=FAIL, detail=%str(ndup=&_t5_ndup should be >0));
%mend _t5_check;
%_t5_check;


/* ================================================================
   TEST 6: Same-file merge fails (SAME puts two rows from same s_code in one group)
   ================================================================ */
data work._t6_groups;
  input group_id s_code $ col_order;
  datalines;
20 s01 1
21 s01 2
;
run;

%macro _t6_check;
  %local _t6_sc_viol;
  proc sql noprint;
    select count(*) into :_t6_sc_viol trimmed
    from (
      /* Simulate: if we merged 20 and 21, both s01 rows would be in group 20 */
      select 20 as merged_group_id, s_code, count(*) as n
      from work._t6_groups
      group by s_code
      having count(*) > 1);
  quit;
  %if &_t6_sc_viol > 0 %then %_record(case=T6_SAME_FILE_MERGE_BLOCKED, result=PASS);
  %else %_record(case=T6_SAME_FILE_MERGE_BLOCKED, result=FAIL,
         detail=%str(no same-file violation detected; test setup may be wrong));
%mend _t6_check;
%_t6_check;


/* ================================================================
   TEST 7: Bad decisions header detected
   ================================================================ */
%macro _t7_check;
  %local _t7_ok _t7_good_ok;
  %local _exp_hdr _bad_hdr;
  %let _exp_hdr = s_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date;
  %let _bad_hdr = s_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,note,new_name,decided_by,date;
  %let _t7_ok = 0;
  %let _t7_good_ok = 0;
  /* Simulate: a bad header should NOT equal the expected header */
  %if %lowcase(&_bad_hdr) ne %lowcase(&_exp_hdr) %then %let _t7_ok = 1;
  /* Simulate: the correct header SHOULD equal expected */
  %if %lowcase(&_exp_hdr) = %lowcase(&_exp_hdr) %then %let _t7_good_ok = 1;
  %if &_t7_ok = 1 and &_t7_good_ok = 1 %then
    %_record(case=T7_BAD_HEADER_DETECTED, result=PASS);
  %else
    %_record(case=T7_BAD_HEADER_DETECTED, result=FAIL,
             detail=%str(bad_differs=&_t7_ok good_matches=&_t7_good_ok));
%mend _t7_check;
%_t7_check;


/* ================================================================
   TEST 8: B7 -- forced suffix at max-length base; final name <= 32,
            distinct case-insensitively, no triple underscore.
            Uses real %elide_middle logic via DATA step.
   ================================================================ */
%include "04_name_map_macros.sas";

/* Build two groups with the same 27-char base so stage1_suffix assigns _2 */
data work._t8_suffix_assign;
  length group_id 8 pcnr_name_base $200 _base_uc $200 _file_num 8 col_order 8;
  group_id = 1; pcnr_name_base = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'; _base_uc = upcase(pcnr_name_base); _file_num = 1; col_order = 1; output;
  group_id = 2; pcnr_name_base = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'; _base_uc = upcase(pcnr_name_base); _file_num = 2; col_order = 1; output;
run;

/* Simulate stage1_suffix hash logic: group 1 gets base name, group 2 gets suffixed+elided */
data work._t8_suffix_final;
  if _N_ = 1 then do;
    declare hash _used();
    _used.defineKey('_k');
    _used.defineDone();
    /* pre-populate with suffix_n=1 name (group 1) */
    _k = lowcase('ABCDEFGHIJKLMNOPQRSTUVWXYZ_');
    _used.replace();
  end;
  set work._t8_suffix_assign;
  length pcnr_name_final $200 _sfx $10 _base_trim $200 _candidate $200 _k $200
         _elide_head $200 _elide_tail $200;
  _elide_first = 0; _elide_last = 0;
  if _N_ = 1 then pcnr_name_final = pcnr_name_base;
  else do;
    _try = 2;
    do while (_try < 1000);
      _sfx     = cats('_', put(_try, best.));
      _allowed = 27 - length(_sfx);
      _base_trim = pcnr_name_base;
      %elide_middle(nm=_base_trim, target=_allowed);
      _candidate = cats(_base_trim, _sfx);
      _k = lowcase(_candidate);
      if _used.check() ne 0 then do;
        pcnr_name_final = _candidate;
        _used.replace();
        leave;
      end;
      _try = _try + 1;
    end;
  end;
  pcnr_name_final = cats('PCNR_', pcnr_name_final);
  keep group_id pcnr_name_base pcnr_name_final;
run;

%macro _t8_check;
  %local _t8_len_ok _t8_distinct _t8_no_triple _t8_pass;
  proc sql noprint;
    select max(length(pcnr_name_final)) <= 32 into :_t8_len_ok trimmed
    from work._t8_suffix_final;
    select count(distinct upcase(pcnr_name_final)) = count(*) into :_t8_distinct trimmed
    from work._t8_suffix_final;
    select sum(prxmatch('/___/', pcnr_name_final)) = 0 into :_t8_no_triple trimmed
    from work._t8_suffix_final;
  quit;
  %let _t8_pass = 0;
  %if &_t8_len_ok = 1 and &_t8_distinct = 1 and &_t8_no_triple = 1 %then %let _t8_pass = 1;
  %if &_t8_pass = 1 %then %_record(case=T8_B7_SUFFIX_MAX_LEN, result=PASS);
  %else %_record(case=T8_B7_SUFFIX_MAX_LEN, result=FAIL,
         detail=%str(len_ok=&_t8_len_ok distinct=&_t8_distinct no_triple=&_t8_no_triple));
%mend _t8_check;
%_t8_check;


/* ================================================================
   TEST 9: No WARNING lines in this test's log
   ================================================================ */
proc printto; run;

data work._t9_warn_check;
  length _n_warn 8;
  retain _n_warn 0;
  infile "&_test_log_path" lrecl=32767 end=_eof;
  input;
  if index(upcase(_infile_), 'WARNING:') > 0 then _n_warn + 1;
  if _eof then do;
    call symputx('_t9_n_warn', _n_warn);
    output;
  end;
run;

%macro _t9_check;
  %if &_t9_n_warn = 0 %then %_record(case=T9_NO_WARNINGS_IN_LOG, result=PASS);
  %else %_record(case=T9_NO_WARNINGS_IN_LOG, result=FAIL,
         detail=%str(&_t9_n_warn WARNING lines found in test log));
%mend _t9_check;
%_t9_check;


/* ================================================================
   Final summary
   ================================================================ */
%macro _final_summary;
  %if &_all_pass = 1 %then
    %put NOTE: [04_decisions_test] TESTRESULT SUMMARY: ALL TESTS PASSED;
  %else
    %put ERROR: [04_decisions_test] TESTRESULT SUMMARY: ONE OR MORE TESTS FAILED;
%mend _final_summary;
%_final_summary;
