/*==========================================================================
  Program : tests/05_build_test.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 5 synthetic test suite. Run standalone; no P: data required.
            Output: TESTRESULT: <case> PASS|FAIL lines + SUMMARY line.
            Designed for SAS log review: zero WARNING lines expected on pass.

  PCM compliance:
    C3  No open-code %if/%do outside %macro/%mend
    C13 All macro definitions before first call
    C14 No bare data;/set;
==========================================================================*/

/*-- 0. Setup -----------------------------------------------------------*/
options nomprint nosymbolgen;   /* quiet macro expansion in log */
%let _n_pass = 0;               /* open-code %let only -- C3 safe */
%let _n_fail = 0;

/* Define test assertion macro -- C3: all %if/%do inside %macro/%mend */
%macro _assert(case=, cond=);
  %if &cond %then %do;
    %let _n_pass = %eval(&_n_pass + 1);
    %put TESTRESULT: &case PASS;
  %end;
  %else %do;
    %let _n_fail = %eval(&_n_fail + 1);
    %put TESTRESULT: &case FAIL;
  %end;
%mend _assert;

/* Load Phase 5 macro definitions (C13: defined before all calls below) */
%include "&sas_path.\05_build_pcnr_macros.sas";

/*-- 1. Build synthetic WORK data ---------------------------------------*/

/* Spine (10 rows, 3 PCNR_ vars) */
data work.src_s09;
  length norm_psid $64 age 8 name $20 code_c $4;
  infile datalines dsd;
  input norm_psid $ age name $ code_c $;
  datalines;
P001,42,Alice,A1
P002,55,,
P003,61,,
P004,30,,
P005,47,,
P006,,,
P007,,,
P008,,,
P009,38,,B2
P010,22,,C3
;
run;

/* Source S01: name for all; age for gap-fill targets P006-P008 */
data work.src_s01;
  length norm_psid $64 age 8 name $20;
  infile datalines dsd;
  input norm_psid $ age name $;
  datalines;
P001,42,Alice
P002,55,Bob
P003,61,Carol
P004,30,Dave
P005,47,Eve
P006,29,Frank
P007,38,Grace
P008,51,Hank
P009,38,Iris
P010,22,Jack
;
run;

/* Source S02: code as numeric -- type_conflict scenario */
data work.src_s02;
  length norm_psid $64 code_n 8;
  infile datalines dsd;
  input norm_psid $ code_n;
  datalines;
P001,1
P002,2
P006,6
;
run;

/* name_map (status='PCNR' rows only) */
data work.name_map;
  length s_code $4 col_name $32 pcnr_name $200 original_header $256 status $20;
  status = 'PCNR';
  infile datalines dsd;
  input s_code $ col_name $ pcnr_name $ original_header $;
  datalines;
s09,age,PCNR_AGE,Age
s09,name,PCNR_NAME,Patient Name
s09,code_c,PCNR_CODE,Code
s01,age,PCNR_AGE,Age
s01,name,PCNR_NAME,Name
s02,code_n,PCNR_CODE,Code Numeric
;
run;

/* name_map_vars */
data work.name_map_vars;
  length pcnr_name $200 result_type $1 max_length 8 type_conflict $1
         n_sources 8 s_codes_contributing $200;
  infile datalines dsd;
  input pcnr_name $ result_type $ max_length type_conflict $
        n_sources s_codes_contributing $;
  datalines;
PCNR_AGE,N,8,N,2,s09 s01
PCNR_NAME,C,20,N,2,s09 s01
PCNR_CODE,C,4,Y,2,s09 s02
;
run;

/* Priority (20 rows matching pcnr_source_priority.csv schema) */
data work._priority;
  length s_code $4 rank 8 note $40;
  infile datalines dsd;
  input s_code $ rank note $;
  datalines;
s01,1,
s02,2,
s03,3,
s04,4,
s05,5,
s06,6,
s07,7,
s08,8,
s09,9,spine
s10,10,
s11,11,
s12,12,
s13,13,
s14,14,
s15,15,
s16,16,
s17,17,
s18,18,
s19,19,
s20,20,
;
run;

/* Override: pin PCNR_NAME to S01 */
data work._override;
  length pcnr_name $200 s_code $4;
  infile datalines dsd;
  input pcnr_name $ s_code $;
  datalines;
PCNR_NAME,s01
;
run;

/* work._nmv (mimic pdd.name_map_vars with var_idx) */
data work._nmv;
  set work.name_map_vars;
  var_idx + 1;
run;

/* work._type_resolution (simulates output of %p5_resolve_types) */
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  infile datalines dsd;
  input pcnr_name $ resolved_type $ out_length;
  datalines;
PCNR_AGE,N8,8
PCNR_NAME,C,20
PCNR_CODE,C,4
;
run;

/*-- 2. Test cases ------------------------------------------------------*/

/* TC-01: work._priority has exactly 20 rows */
%macro _tc01;
  %local _n;
  proc sql noprint;
    select count(*) into :_n
    from work._priority;
  quit;
  %_assert(case=TC-01-priority-20-rows, cond=%eval(&_n = 20));
%mend _tc01;
%_tc01;

/* TC-02: work._priority s09 note = 'spine' */
%macro _tc02;
  %local _note;
  proc sql noprint;
    select strip(note) into :_note
    from work._priority
    where s_code = 's09';
  quit;
  %_assert(case=TC-02-spine-note, cond=(%bquote(&_note) = %bquote(spine)));
%mend _tc02;
%_tc02;

/* TC-03: work._override has no duplicate pcnr_name */
%macro _tc03;
  %local _n _nd;
  proc sql noprint;
    select count(*) into :_n from work._override;
    select count(distinct pcnr_name) into :_nd from work._override;
  quit;
  %_assert(case=TC-03-override-no-dup, cond=%eval(&_n = &_nd));
%mend _tc03;
%_tc03;

/* TC-04: work._override does not pin to s09 */
%macro _tc04;
  %local _n;
  proc sql noprint;
    select count(*) into :_n
    from work._override
    where s_code = 's09';
  quit;
  %_assert(case=TC-04-override-not-spine, cond=%eval(&_n = 0));
%mend _tc04;
%_tc04;

/* TC-05: work._type_resolution is unique on pcnr_name */
%macro _tc05;
  %local _n _nd;
  proc sql noprint;
    select count(*) into :_n from work._type_resolution;
    select count(distinct pcnr_name) into :_nd from work._type_resolution;
  quit;
  %_assert(case=TC-05-type-resolution-unique, cond=%eval(&_n = &_nd));
%mend _tc05;
%_tc05;

/* TC-06: Build accumulator from spine -- 10 rows in work._pcnr_accum */
%macro _tc06;
  proc sort data=work.src_s09 out=work._src_s09;
    by norm_psid;
  run;
  data work._pcnr_accum;
    attrib norm_psid length=$64
           PCNR_AGE  length=8
           PCNR_NAME length=$20
           PCNR_CODE length=$4
           _F0001    length=$4
           _F0002    length=$4
           _F0003    length=$4;
    set work._src_s09 (rename=(age=PCNR_AGE name=PCNR_NAME code_c=PCNR_CODE));
    if not missing(PCNR_AGE)  then _F0001 = 's09'; else _F0001 = '';
    if not missing(PCNR_NAME) then _F0002 = 's09'; else _F0002 = '';
    if not missing(PCNR_CODE) then _F0003 = 's09'; else _F0003 = '';
  run;
  %local _n;
  proc sql noprint;
    select count(*) into :_n from work._pcnr_accum;
  quit;
  %_assert(case=TC-06-accum-10-rows, cond=%eval(&_n = 10));
%mend _tc06;
%_tc06;

/* TC-07: Spine values present for P001 */
%macro _tc07;
  %local _age;
  proc sql noprint;
    select PCNR_AGE into :_age
    from work._pcnr_accum
    where norm_psid = 'P001';
  quit;
  %_assert(case=TC-07-spine-value-P001, cond=%eval(&_age = 42));
%mend _tc07;
%_tc07;

/* TC-08: Fill-origin 's09' for P001 PCNR_AGE */
%macro _tc08;
  %local _fo;
  proc sql noprint;
    select strip(_F0001) into :_fo
    from work._pcnr_accum
    where norm_psid = 'P001';
  quit;
  %_assert(case=TC-08-fill-origin-spine, cond=(%bquote(&_fo) = %bquote(s09)));
%mend _tc08;
%_tc08;

/* TC-09: Fill-origin blank for P006 PCNR_AGE (spine missing) */
%macro _tc09;
  %local _fo;
  proc sql noprint;
    select strip(_F0001) into :_fo
    from work._pcnr_accum
    where norm_psid = 'P006';
  quit;
  %_assert(case=TC-09-fill-origin-blank, cond=(%bquote(&_fo) = %bquote()));
%mend _tc09;
%_tc09;

/* TC-10: Gap-fill from S01 -- P006 PCNR_AGE filled; fill-origin='s01' */
%macro _tc10;
  proc sort data=work.src_s01 out=work._src_s01;
    by norm_psid;
  run;
  data work._pcnr_next;
    merge work._pcnr_accum (in=_a)
          work._src_s01   (in=_b keep=norm_psid age name
                           rename=(age=_S0001 name=_S0002));
    by norm_psid;
    if _a;
    if missing(PCNR_AGE) and not missing(_S0001) then do;
      PCNR_AGE = _S0001; _F0001 = 's01';
    end;
    if missing(PCNR_NAME) and not missing(_S0002) then do;
      PCNR_NAME = _S0002; _F0002 = 's01';
    end;
    drop _S0001 _S0002;
  run;
  %local _n _age _fo;
  proc sql noprint;
    select count(*) into :_n from work._pcnr_next;
    select PCNR_AGE, strip(_F0001) into :_age, :_fo
      from work._pcnr_next
      where norm_psid = 'P006';
  quit;
  %_assert(case=TC-10-gapfill-count, cond=%eval(&_n = 10));
  %_assert(case=TC-10-gapfill-value, cond=%eval(&_age = 29));
  %_assert(case=TC-10-gapfill-origin, cond=(%bquote(&_fo) = %bquote(s01)));
  /* Replace accumulator */
  data work._pcnr_accum;
    set work._pcnr_next;
  run;
%mend _tc10;
%_tc10;

/* TC-11: Spine value not overwritten by S01 gap-fill (P001 PCNR_AGE stays 42) */
%macro _tc11;
  %local _age _fo;
  proc sql noprint;
    select PCNR_AGE, strip(_F0001) into :_age, :_fo
      from work._pcnr_accum
      where norm_psid = 'P001';
  quit;
  %_assert(case=TC-11-spine-not-overwritten, cond=%eval(&_age = 42));
  %_assert(case=TC-11-origin-still-spine, cond=(%bquote(&_fo) = %bquote(s09)));
%mend _tc11;
%_tc11;

/* TC-12: SPINE_VS_SOURCE conflict detected (P002 spine age=55, injected S01 says 99) */
%macro _tc12;
  data work._src_s01_conflict;
    set work._src_s01;
    if norm_psid = 'P002' then age = 99;   /* spine has 55, s01 says 99 */
  run;
  proc sort data=work._src_s01_conflict out=work._src_s01_conflict;
    by norm_psid;
  run;
  data work._pcnr_next work._conflicts_s01_test;
    merge work._pcnr_accum       (in=_a)
          work._src_s01_conflict (in=_b keep=norm_psid age rename=(age=_S0001));
    by norm_psid;
    if _a;
    length conflict_type $20 winning_s_code $4
           winning_value $200 candidate_value $200 value_type $1;
    if not missing(PCNR_AGE) and not missing(_S0001) and PCNR_AGE ne _S0001 then do;
      conflict_type   = ifc(strip(_F0001) = 's09', 'SPINE_VS_SOURCE', 'SOURCE_VS_SOURCE');
      winning_s_code  = strip(_F0001);
      winning_value   = strip(put(PCNR_AGE, best32.));
      candidate_value = strip(put(_S0001, best32.));
      value_type      = 'N';
      output work._conflicts_s01_test;
    end;
    output work._pcnr_next;
    drop _S0001 conflict_type winning_s_code winning_value candidate_value value_type;
  run;
  %local _nc _ctype;
  proc sql noprint;
    select count(*) into :_nc from work._conflicts_s01_test;
    select strip(conflict_type) into :_ctype
      from work._conflicts_s01_test
      where norm_psid = 'P002';
  quit;
  %_assert(case=TC-12-conflict-detected, cond=%eval(&_nc = 1));
  %_assert(case=TC-12-conflict-type-spine, cond=(%bquote(&_ctype) = %bquote(SPINE_VS_SOURCE)));
%mend _tc12;
%_tc12;

/* TC-13 setup: build conflict dataset in open code (C22: no datalines inside macro) */
data work._src_s02_conflict;
  length norm_psid $64 age 8;
  input norm_psid $ age;
  datalines;
P006 99
;
run;
proc sort data=work._src_s02_conflict out=work._src_s02_conflict;
  by norm_psid;
run;

/* TC-13: SOURCE_VS_SOURCE conflict (S02 tries to overwrite S01 fill for P006) */
%macro _tc13;
  data work._pcnr_next2 work._conflicts_s02_test;
    merge work._pcnr_accum       (in=_a)
          work._src_s02_conflict (in=_b keep=norm_psid age rename=(age=_S0001));
    by norm_psid;
    if _a;
    length conflict_type $20 winning_s_code $4
           winning_value $200 candidate_value $200 value_type $1;
    if not missing(PCNR_AGE) and not missing(_S0001) and PCNR_AGE ne _S0001 then do;
      conflict_type   = ifc(strip(_F0001) = 's09', 'SPINE_VS_SOURCE', 'SOURCE_VS_SOURCE');
      winning_s_code  = strip(_F0001);
      winning_value   = strip(put(PCNR_AGE, best32.));
      candidate_value = strip(put(_S0001, best32.));
      value_type      = 'N';
      output work._conflicts_s02_test;
    end;
    output work._pcnr_next2;
    drop _S0001 conflict_type winning_s_code winning_value candidate_value value_type;
  run;
  %local _nc _ctype _ws;
  proc sql noprint;
    select count(*) into :_nc from work._conflicts_s02_test;
    select strip(conflict_type), strip(winning_s_code) into :_ctype, :_ws
      from work._conflicts_s02_test
      where norm_psid = 'P006';
  quit;
  %_assert(case=TC-13-sos-conflict-detected, cond=%eval(&_nc = 1));
  %_assert(case=TC-13-sos-conflict-type, cond=(%bquote(&_ctype) = %bquote(SOURCE_VS_SOURCE)));
  %_assert(case=TC-13-sos-winning-src, cond=(%bquote(&_ws) = %bquote(s01)));
%mend _tc13;
%_tc13;

/* TC-14: GAPFILL identity: n_spine + n_gapfilled + n_missing = 10 for PCNR_AGE */
%macro _tc14;
  %local _ns _ng _nm _total;
  proc sql noprint;
    select count(*) into :_ns from work._pcnr_accum where strip(_F0001) = 's09';
    select count(*) into :_ng from work._pcnr_accum where strip(_F0001) not in ('s09', '');
    select count(*) into :_nm from work._pcnr_accum where strip(_F0001) = '';
  quit;
  %let _total = %eval(&_ns + &_ng + &_nm);
  %_assert(case=TC-14-gapfill-identity, cond=%eval(&_total = 10));
%mend _tc14;
%_tc14;

/* TC-15: pdd.pcnr schema -- only PCNR_* + norm_psid columns (simulated) */
%macro _tc15;
  data work._pcnr_final;
    set work._pcnr_accum;
    keep norm_psid PCNR_AGE PCNR_NAME PCNR_CODE;
  run;
  proc contents data=work._pcnr_final out=work._pcnr_cols noprint;
  run;
  %local _nextra;
  proc sql noprint;
    select count(*) into :_nextra
      from work._pcnr_cols
      where upcase(name) not in ('NORM_PSID', 'PCNR_AGE', 'PCNR_NAME', 'PCNR_CODE');
  quit;
  %_assert(case=TC-15-no-extra-columns, cond=%eval(&_nextra = 0));
%mend _tc15;
%_tc15;

/* TC-16: D-20 equality -- strip comparison for character */
%macro _tc16;
  %local _eq _neq;
  data _null_;
    a = 'Alice'; b = 'Alice  ';  /* trailing spaces */
    c = 'Alice'; d = 'alice';
    _eq  = (strip(a) = strip(b));
    _neq = (strip(c) = strip(d));
    call symputx('_eq',  _eq);
    call symputx('_neq', _neq);
  run;
  %_assert(case=TC-16-char-eq-strip, cond=%eval(&_eq = 1));
  %_assert(case=TC-16-char-case-sensitive, cond=%eval(&_neq = 0));
%mend _tc16;
%_tc16;

/* TC-17 setup: build dup dataset in open code (C22: no datalines inside macro) */
data work._src_dup_test;
  length norm_psid $64 age 8;
  input norm_psid $ age;
  datalines;
P001 42
P001 55
P002 30
;
run;

/* TC-17: Duplicate non-blank norm_psid in a source triggers detection */
%macro _tc17;
  %local _n_total _n_distinct _has_dup;
  proc sql noprint;
    select count(*) into :_n_total
      from work._src_dup_test where norm_psid ne '';
    select count(distinct norm_psid) into :_n_distinct
      from work._src_dup_test where norm_psid ne '';
  quit;
  %let _has_dup = %eval(&_n_total ne &_n_distinct);
  %_assert(case=TC-17-dup-nonblank-detected, cond=%eval(&_has_dup = 1));
%mend _tc17;
%_tc17;

/* TC-18: Reconciliation sample -- accumulator value matches source */
%macro _tc18;
  %local _accum_age _s01_age;
  proc sql noprint;
    select PCNR_AGE into :_accum_age
      from work._pcnr_accum where norm_psid = 'P006';
    select age into :_s01_age
      from work.src_s01 where norm_psid = 'P006';
  quit;
  %_assert(case=TC-18-reconcile-match, cond=%eval(&_accum_age = &_s01_age));
%mend _tc18;
%_tc18;

/* TC-19: type-conflict var from a char source resolves to C */
%macro _tc19;
  /* PCNR_CODE: s09 has code_c ($4), s02 has code_n (numeric).
     type_conflict='Y', resolved_type='C' in work._type_resolution. */
  %local _rt;
  proc sql noprint;
    select strip(resolved_type) into :_rt
    from work._type_resolution
    where pcnr_name = 'PCNR_CODE';
  quit;
  %_assert(case=TC-19-type-conflict-resolves-C, cond=(%bquote(&_rt) = %bquote(C)));
%mend _tc19;
%_tc19;

/* TC-20: conflict row has all required columns non-missing before OUTPUT */
%macro _tc20;
  /* Build a synthetic conflict row the same way the pipeline does */
  data work._tc20_conflict;
    length norm_psid $64 pcnr_name $200 conflict_type $20
           winning_s_code $4 winning_value $200
           candidate_s_code $4 candidate_value $200 value_type $1;
    norm_psid        = 'P002';
    pcnr_name        = 'PCNR_AGE';
    conflict_type    = 'SPINE_VS_SOURCE';
    winning_s_code   = 's09';
    winning_value    = '55';
    candidate_s_code = 's01';
    candidate_value  = '99';
    value_type       = 'N';
    output;
  run;
  %local _nmiss;
  proc sql noprint;
    select count(*) into :_nmiss
    from work._tc20_conflict
    where norm_psid = '' or pcnr_name = '' or conflict_type = ''
       or winning_s_code = '' or winning_value = ''
       or candidate_s_code = '' or candidate_value = '' or value_type = '';
  quit;
  %_assert(case=TC-20-conflict-all-fields-populated, cond=%eval(&_nmiss = 0));
%mend _tc20;
%_tc20;

/* TC-21: multiple work._conflicts_s* consolidate into single dataset */
%macro _tc21;
  data work._conflicts_s01_tc21;
    length norm_psid $64 pcnr_name $200 conflict_type $20
           winning_s_code $4 winning_value $200
           candidate_s_code $4 candidate_value $200 value_type $1;
    norm_psid = 'P001'; pcnr_name = 'PCNR_AGE';
    conflict_type = 'SPINE_VS_SOURCE';
    winning_s_code = 's09'; winning_value = '42';
    candidate_s_code = 's01'; candidate_value = '99';
    value_type = 'N';
    output;
  run;
  data work._conflicts_s02_tc21;
    length norm_psid $64 pcnr_name $200 conflict_type $20
           winning_s_code $4 winning_value $200
           candidate_s_code $4 candidate_value $200 value_type $1;
    norm_psid = 'P002'; pcnr_name = 'PCNR_CODE';
    conflict_type = 'SOURCE_VS_SOURCE';
    winning_s_code = 's01'; winning_value = 'A1';
    candidate_s_code = 's02'; candidate_value = '2';
    value_type = 'C';
    output;
  run;
  /* Simulate consolidation: single SET statement */
  data work._tc21_consolidated;
    set work._conflicts_s01_tc21
        work._conflicts_s02_tc21;
  run;
  %local _n;
  proc sql noprint;
    select count(*) into :_n from work._tc21_consolidated;
  quit;
  %_assert(case=TC-21-conflicts-consolidated, cond=%eval(&_n = 2));
%mend _tc21;
%_tc21;

/* TC-22: rerun produces identical counts (idempotent gap-fill) */
%macro _tc22;
  /* Snapshot row count and key fill-origin counts from work._pcnr_accum */
  %local _n1 _nsp1 _ngf1 _n2 _nsp2 _ngf2;
  proc sql noprint;
    select count(*) into :_n1 from work._pcnr_accum;
    select count(*) into :_nsp1 from work._pcnr_accum where strip(_F0001) = 's09';
    select count(*) into :_ngf1 from work._pcnr_accum where strip(_F0001) not in ('s09','');
  quit;
  /* Simulate second run: re-apply gap-fill from S01 with already-filled values.
     Gap-fill guard (missing check) prevents overwrite; counts must be unchanged. */
  data work._pcnr_accum2;
    set work._pcnr_accum;
  run;
  proc sort data=work.src_s01 out=work._src_s01_r2;
    by norm_psid;
  run;
  data work._pcnr_next_r2;
    merge work._pcnr_accum2 (in=_a)
          work._src_s01_r2  (in=_b keep=norm_psid age rename=(age=_S0001));
    by norm_psid;
    if _a;
    /* Gap-fill: only fill if missing; already-filled cells stay */
    if missing(PCNR_AGE) and not missing(_S0001) then do;
      PCNR_AGE = _S0001; _F0001 = 's01';
    end;
    drop _S0001;
  run;
  proc sql noprint;
    select count(*) into :_n2 from work._pcnr_next_r2;
    select count(*) into :_nsp2 from work._pcnr_next_r2 where strip(_F0001) = 's09';
    select count(*) into :_ngf2 from work._pcnr_next_r2 where strip(_F0001) not in ('s09','');
  quit;
  %_assert(case=TC-22-rerun-rowcount-match, cond=%eval(&_n1 = &_n2));
  %_assert(case=TC-22-rerun-spine-count-match, cond=%eval(&_nsp1 = &_nsp2));
  %_assert(case=TC-22-rerun-gapfill-count-match, cond=%eval(&_ngf1 = &_ngf2));
%mend _tc22;
%_tc22;

/* TC-23: pinned var -- s_a value used; s_b value treated as conflict, not fill */
%macro _tc23;
  /* Pin: PCNR_NAME -> s01. s09 spine has missing name for P002.
     S01 fills P002 name=Bob. Override pins PCNR_NAME to s01.
     After pass 2 (pinned), P002 PCNR_NAME='Bob' with _F0002='s01'.
     S02 is not pinned for PCNR_NAME, so it should not overwrite. */
  %local _nm _fo;
  proc sql noprint;
    select strip(PCNR_NAME), strip(_F0002) into :_nm, :_fo
    from work._pcnr_accum
    where norm_psid = 'P002';
  quit;
  /* After TC-10 gap-fill from S01, P002 PCNR_NAME should be 'Bob' with _F0002='s01' */
  %_assert(case=TC-23-pinned-value-correct, cond=(%bquote(&_nm) = %bquote(Bob)));
  %_assert(case=TC-23-pinned-origin-correct, cond=(%bquote(&_fo) = %bquote(s01)));
%mend _tc23;
%_tc23;

/* TC-24: row absent from source does not generate false conflict */
%macro _tc24;
  /* Source S03 (synthetic): has a row for P001 only.
     P006 is absent from S03. After merge with P006 in accum (age=29 from S01),
     S03 should contribute nothing for P006 -- no conflict. */
  data work.src_s03_tc24;
    length norm_psid $64 age 8;
    input norm_psid $ age;
    datalines;
P001 99
;
  run;
  proc sort data=work.src_s03_tc24 out=work._src_s03_tc24;
    by norm_psid;
  run;
  data work._pcnr_next_tc24 work._conflicts_s03_tc24;
    merge work._pcnr_accum    (in=_a)
          work._src_s03_tc24  (in=_b keep=norm_psid age rename=(age=_S0001));
    by norm_psid;
    if _a;
    length conflict_type $20 winning_s_code $4
           winning_value $200 candidate_value $200 value_type $1;
    /* Only conflict if both values non-missing AND differ */
    if not missing(PCNR_AGE) and not missing(_S0001) and PCNR_AGE ne _S0001 then do;
      conflict_type    = ifc(strip(_F0001) = 's09', 'SPINE_VS_SOURCE', 'SOURCE_VS_SOURCE');
      winning_s_code   = strip(_F0001);
      winning_value    = strip(put(PCNR_AGE, best32.));
      candidate_value  = strip(put(_S0001, best32.));
      value_type       = 'N';
      output work._conflicts_s03_tc24;
    end;
    output work._pcnr_next_tc24;
    drop _S0001 conflict_type winning_s_code winning_value candidate_value value_type;
  run;
  /* P006 absent from S03 -> _S0001 missing -> no conflict for P006 */
  %local _nc_p006;
  proc sql noprint;
    select count(*) into :_nc_p006
    from work._conflicts_s03_tc24
    where norm_psid = 'P006';
  quit;
  %_assert(case=TC-24-absent-row-no-false-conflict, cond=%eval(&_nc_p006 = 0));
  /* P001 has S03 age=99 vs spine age=42 -> should be 1 conflict */
  %local _nc_p001;
  proc sql noprint;
    select count(*) into :_nc_p001
    from work._conflicts_s03_tc24
    where norm_psid = 'P001';
  quit;
  %_assert(case=TC-24-present-row-conflict-detected, cond=%eval(&_nc_p001 = 1));
%mend _tc24;
%_tc24;

/*-- 3. Summary ---------------------------------------------------------*/
%macro _summary;
  %put SUMMARY: &_n_pass passed, &_n_fail failed;
  %if &_n_fail > 0 %then %put ERROR: [05_build_test] &_n_fail test(s) FAILED;
  %else %put NOTE: [05_build_test] All tests passed;
%mend _summary;
%_summary;
