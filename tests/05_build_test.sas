/*==========================================================================
  Program : tests/05_build_test.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 5 synthetic test suite. Standalone -- no P: paths.
            Calls real macros in 05_build_pcnr_macros.sas using WORK libs.
            Output: TESTRESULT: TC-N desc [label] PASS|FAIL + SUMMARY line.

  PCM compliance:
    C3  No open-code %if/%do outside %macro/%mend
    C13 All macro definitions before first call
    C14 No bare data;/set;
    C22 No datalines inside %macro...%mend
==========================================================================*/

options nosyntaxcheck nomlogic nomprint nosymbolgen;

/*==========================================================================
  SECTION 0 -- Test harness macros (all defined before first call, C13)
==========================================================================*/

%macro _tc_start(n=, desc=);
  %global _tc_pass _tc_fail _tc_n _tc_desc p5_fail p5_fail_msg;
  %let _tc_n    = &n;
  %let _tc_desc = &desc;
  %let p5_fail = 0;
  %let p5_fail_msg = ;
%mend _tc_start;

%macro _assert(cond=, label=);
  %global _tc_pass _tc_fail;
  %if &cond %then %do;
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label] PASS;
    %let _tc_pass = %eval(&_tc_pass + 1);
  %end;
  %else %do;
    %put TESTRESULT: TC-&_tc_n &_tc_desc [&label] FAIL;
    %let _tc_fail = %eval(&_tc_fail + 1);
  %end;
%mend _assert;

%macro _assert_fail(label=);
  %_assert(cond=(%bquote(&p5_fail)=1), label=&label expected-fail);
%mend _assert_fail;

%macro _assert_pass(label=);
  %_assert(cond=(%bquote(&p5_fail)=0), label=&label expected-pass);
%mend _assert_pass;

%macro _tc_summary;
  %put TESTRESULT: SUMMARY passed=&_tc_pass failed=&_tc_fail;
%mend _tc_summary;

/* Write 20-row priority CSV to a given path (no datalines -- C22) */
%macro _write_priority_csv(path=);
  data _null_;
    file "&path" encoding='utf-8';
    put 's_code,rank,note';
    put 's01,1,'; put 's02,2,'; put 's03,3,'; put 's04,4,'; put 's05,5,';
    put 's06,6,'; put 's07,7,'; put 's08,8,'; put 's09,9,spine';
    put 's10,10,'; put 's11,11,'; put 's12,12,'; put 's13,13,'; put 's14,14,';
    put 's15,15,'; put 's16,16,'; put 's17,17,'; put 's18,18,'; put 's19,19,';
    put 's20,20,';
  run;
%mend _write_priority_csv;

%macro _write_override_csv(path=);
  data _null_;
    file "&path" encoding='utf-8';
    put 'pcnr_name,s_code';
  run;
%mend _write_override_csv;

%macro _write_s06class_csv(path=);
  data _null_;
    file "&path" encoding='utf-8';
    put 'col_name,class';
  run;
%mend _write_s06class_csv;

/* Set p5_test_mode before %include so _p5_init_globals (inside macros file)
   sees the value and does not overwrite it with the default 0. */
%let p5_test_mode = 1;

/* Load macro library -- C13: all macros defined before calls below */
%include "C:\data_dictionary\sas\05_build_pcnr_macros.sas";

/* Initialize counters -- %let is open-code safe (C3); avoid %global at open code */
%let _tc_pass = 0;
%let _tc_fail = 0;
/* p5_fail / p5_fail_msg already declared and reset by _p5_init_globals above */

/*==========================================================================
  SECTION 1 -- TC-01: type-conflict var resolved N8 when all chars parse numeric
==========================================================================*/

/* Data setup in open code (C22: no datalines inside macros) */
data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s02'; sas_name='age_c'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age Char'; col_order=1; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='Y'; s_codes_contributing='s01 s02'; n_sources=2; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=30; output;
  norm_psid='P002'; age=40; output;
  norm_psid='P003'; age=50; output;
run;
data work.src_s02;
  length norm_psid $64 age_c $4;
  norm_psid='P001'; age_c='30'; output;
  norm_psid='P002'; age_c='40'; output;
  norm_psid='P003'; age_c='50'; output;
run;

%macro _tc01_run;
  %_tc_start(n=01, desc=type-conflict-N8-resolve);
  %p5_resolve_types(srclib=work, nmlib=work, outlib=work,
                    export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _rt;
    proc sql noprint;
      select strip(resolved_type) into :_rt trimmed
      from work._type_resolution where pcnr_name='PCNR_AGE';
    quit;
    %_assert(cond=(%bquote(&_rt)=%bquote(N8)), label=resolved-type-N8);
  %end;
%mend _tc01_run;
%_tc01_run;

/*==========================================================================
  SECTION 2 -- TC-02: C-resolved var correct length
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s01'; sas_name='code_n'; pcnr_name='PCNR_CODE'; status='PCNR';
  original_header='Code'; col_order=2; output;
  s_code='s02'; sas_name='code_c'; pcnr_name='PCNR_CODE'; status='PCNR';
  original_header='Code Char'; col_order=2; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_CODE'; var_idx=1; result_type='C'; max_length=8;
  type_conflict='Y'; s_codes_contributing='s01 s02'; n_sources=2; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work.src_s01;
  length norm_psid $64 code_n 8;
  norm_psid='P001'; code_n=42; output;
run;
data work.src_s02;
  length norm_psid $64 code_c $8;
  norm_psid='P001'; code_c='XYZ'; output;
run;

%macro _tc02_run;
  %_tc_start(n=02, desc=type-conflict-C-length);
  %p5_resolve_types(srclib=work, nmlib=work, outlib=work,
                    export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _rt _ol;
    proc sql noprint;
      select strip(resolved_type), out_length
      into :_rt trimmed, :_ol trimmed
      from work._type_resolution where pcnr_name='PCNR_CODE';
    quit;
    %_assert(cond=(%bquote(&_rt)=%bquote(C)), label=resolved-type-C);
    %_assert(cond=(%eval(&_ol >= 8)), label=out-length-ge-8);
  %end;
%mend _tc02_run;
%_tc02_run;

/*==========================================================================
  SECTION 3 -- TC-03: spine wins; SPINE_VS_SOURCE row fully populated
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s09'; sas_name='PCNR_AGE'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01'; n_sources=2; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work.src_s09;
  length norm_psid $64 PCNR_AGE 8;
  norm_psid='P001'; PCNR_AGE=99; output;
  norm_psid='P002'; PCNR_AGE=.; output;
  norm_psid='P003'; PCNR_AGE=.; output;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=55; output;
  norm_psid='P002'; age=40; output;
  norm_psid='P003'; age=50; output;
run;
proc sort data=work.src_s09 out=work._src_s09; by norm_psid; run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  set work._src_s09;
  if not missing(PCNR_AGE) then _F0001='s09';
  else _F0001='';
run;

%macro _tc03_run;
  %_tc_start(n=03, desc=spine-wins-conflict-row);
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=3, gen_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nc _ctype _wsc _wv _csc _cv _vt;
    proc sql noprint;
      select count(*) into :_nc trimmed from work._conflicts_s01;
      select strip(conflict_type), strip(winning_s_code), strip(winning_value),
             strip(candidate_s_code), strip(candidate_value), strip(value_type)
      into :_ctype trimmed, :_wsc trimmed, :_wv trimmed,
           :_csc trimmed, :_cv trimmed, :_vt trimmed
      from work._conflicts_s01 (obs=1);
    quit;
    %_assert(cond=(%eval(&_nc >= 1)), label=conflict-row-exists);
    %_assert(cond=(%bquote(&_ctype)=%bquote(SPINE_VS_SOURCE)), label=conflict-type);
    %_assert(cond=(%bquote(&_wsc)=%bquote(s09)), label=winning-s-code);
    %_assert(cond=(%bquote(&_wv) ne %bquote()), label=winning-value-nonempty);
    %_assert(cond=(%bquote(&_csc) ne %bquote()), label=candidate-s-code-nonempty);
    %_assert(cond=(%bquote(&_cv) ne %bquote()), label=candidate-value-nonempty);
    %_assert(cond=(%bquote(&_vt) ne %bquote()), label=value-type-nonempty);
  %end;
%mend _tc03_run;
%_tc03_run;

/*==========================================================================
  SECTION 4 -- TC-04: rank order s01 beats s02; SOURCE_VS_SOURCE row populated
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s09'; sas_name='PCNR_AGE'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s02'; sas_name='age2'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01 s02'; n_sources=3; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work.src_s09;
  length norm_psid $64 PCNR_AGE 8;
  norm_psid='P001'; PCNR_AGE=.; output;
  norm_psid='P002'; PCNR_AGE=.; output;
  norm_psid='P003'; PCNR_AGE=.; output;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=30; output;
  norm_psid='P002'; age=40; output;
  norm_psid='P003'; age=50; output;
run;
data work.src_s02;
  length norm_psid $64 age2 8;
  norm_psid='P001'; age2=55; output;
  norm_psid='P002'; age2=40; output;
  norm_psid='P003'; age2=50; output;
run;
proc sort data=work.src_s09 out=work._src_s09; by norm_psid; run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  set work._src_s09;
  _F0001='';
run;

%macro _tc04_run;
  %_tc_start(n=04, desc=rank-order-source-vs-source);
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=3, gen_dir=%sysfunc(getoption(work)));
  %p5_gapfill_source(s_code=s02, rank=2, srclib=work, nmlib=work,
                     spine_n=3, gen_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nc _ctype _wsc _csc;
    proc sql noprint;
      select count(*) into :_nc trimmed from work._conflicts_s02;
      select strip(conflict_type), strip(winning_s_code), strip(candidate_s_code)
      into :_ctype trimmed, :_wsc trimmed, :_csc trimmed
      from work._conflicts_s02 (obs=1);
    quit;
    %_assert(cond=(%eval(&_nc >= 1)), label=sos-conflict-exists);
    %_assert(cond=(%bquote(&_ctype)=%bquote(SOURCE_VS_SOURCE)), label=sos-type);
    %_assert(cond=(%bquote(&_wsc)=%bquote(s01)), label=winning-s01);
    %_assert(cond=(%bquote(&_csc) ne %bquote()), label=candidate-s-code-nonempty);
  %end;
%mend _tc04_run;
%_tc04_run;

/*==========================================================================
  SECTION 5 -- TC-05: agreement -- no conflict row
==========================================================================*/

data work.src_s09;
  length norm_psid $64 PCNR_AGE 8;
  norm_psid='P001'; PCNR_AGE=.; output;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=30; output;
run;
data work.src_s02;
  length norm_psid $64 age2 8;
  norm_psid='P001'; age2=30; output;
run;
proc sort data=work.src_s09 out=work._src_s09; by norm_psid; run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  set work._src_s09;
  _F0001='';
run;

%macro _tc05_run;
  %_tc_start(n=05, desc=agreement-no-conflict);
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=1, gen_dir=%sysfunc(getoption(work)));
  %p5_gapfill_source(s_code=s02, rank=2, srclib=work, nmlib=work,
                     spine_n=1, gen_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nc1 _nc2;
    proc sql noprint;
      select count(*) into :_nc1 trimmed from work._conflicts_s01;
      select count(*) into :_nc2 trimmed from work._conflicts_s02;
    quit;
    %_assert(cond=(%eval(&_nc1 = 0)), label=s01-no-conflict);
    %_assert(cond=(%eval(&_nc2 = 0)), label=s02-no-conflict);
  %end;
%mend _tc05_run;
%_tc05_run;

/*==========================================================================
  SECTION 6 -- TC-06: P002 absent from s02 -- no s02 conflict for P002
==========================================================================*/

data work.src_s09;
  length norm_psid $64 PCNR_AGE 8;
  norm_psid='P001'; PCNR_AGE=99; output;
  norm_psid='P002'; PCNR_AGE=99; output;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=55; output;
  norm_psid='P002'; age=44; output;
run;
data work.src_s02;
  length norm_psid $64 age2 8;
  norm_psid='P001'; age2=77; output;
run;
proc sort data=work.src_s09 out=work._src_s09; by norm_psid; run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  set work._src_s09;
  if not missing(PCNR_AGE) then _F0001='s09';
  else _F0001='';
run;

%macro _tc06_run;
  %_tc_start(n=06, desc=stale-value-absent-row);
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=2, gen_dir=%sysfunc(getoption(work)));
  %p5_gapfill_source(s_code=s02, rank=2, srclib=work, nmlib=work,
                     spine_n=2, gen_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nc_p002;
    proc sql noprint;
      select count(*) into :_nc_p002 trimmed
      from work._conflicts_s02 where norm_psid='P002';
    quit;
    %_assert(cond=(%eval(&_nc_p002 = 0)), label=s02-no-conflict-for-P002);
  %end;
%mend _tc06_run;
%_tc06_run;

/*==========================================================================
  SECTION 7 -- TC-07: consolidation -- >= 2 conflicts in outlib.qc_pcnr_conflicts
==========================================================================*/

data work._conflicts_s01;
  length norm_psid $64 pcnr_name $200 conflict_type $20
         winning_s_code $4 winning_value $200
         candidate_s_code $4 candidate_value $200 value_type $1;
  norm_psid='P001'; pcnr_name='PCNR_AGE'; conflict_type='SPINE_VS_SOURCE';
  winning_s_code='s09'; winning_value='99';
  candidate_s_code='s01'; candidate_value='55'; value_type='N'; output;
run;
data work._conflicts_s02;
  length norm_psid $64 pcnr_name $200 conflict_type $20
         winning_s_code $4 winning_value $200
         candidate_s_code $4 candidate_value $200 value_type $1;
  norm_psid='P001'; pcnr_name='PCNR_AGE'; conflict_type='SPINE_VS_SOURCE';
  winning_s_code='s09'; winning_value='99';
  candidate_s_code='s02'; candidate_value='77'; value_type='N'; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01 s02'; n_sources=3; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  norm_psid='P001'; PCNR_AGE=99; _F0001='s09'; output;
run;

%macro _tc07_run;
  %_tc_start(n=07, desc=conflict-consolidation);
  %p5_write_qc(outlib=work, spine_n=1,
               export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nc;
    proc sql noprint;
      select count(*) into :_nc trimmed from work.qc_pcnr_conflicts;
    quit;
    %_assert(cond=(%eval(&_nc >= 2)), label=conflicts-ge-2-rows);
  %end;
%mend _tc07_run;
%_tc07_run;

/*==========================================================================
  SECTION 8 -- TC-08: provenance -- PCNR_AGE present, PCNR_CODE absent
==========================================================================*/

data work._prov_s01;
  length norm_psid $64 pcnr_name $200 src_s_code $4;
  norm_psid='P001'; pcnr_name='PCNR_AGE'; src_s_code='s01'; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01'; n_sources=2; output;
  pcnr_name='PCNR_CODE'; var_idx=2; result_type='C'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09'; n_sources=1; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._pcnr_accum;
  attrib norm_psid length=$64
         PCNR_AGE  length=8  _F0001 length=$4
         PCNR_CODE length=$8 _F0002 length=$4;
  norm_psid='P001'; PCNR_AGE=30; _F0001='s01'; PCNR_CODE='X'; _F0002='s09'; output;
run;

%macro _tc08_run;
  %_tc_start(n=08, desc=provenance-2plus-source-only);
  %p5_write_qc(outlib=work, spine_n=1,
               export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nage _ncode;
    proc sql noprint;
      select count(*) into :_nage trimmed
      from work.qc_pcnr_provenance
      where pcnr_name='PCNR_AGE' and src_s_code ne '';
      select count(*) into :_ncode trimmed
      from work.qc_pcnr_provenance where pcnr_name='PCNR_CODE';
    quit;
    %_assert(cond=(%eval(&_nage >= 1)), label=prov-age-present);
    %_assert(cond=(%eval(&_ncode = 0)), label=prov-code-absent);
  %end;
%mend _tc08_run;
%_tc08_run;

/*==========================================================================
  SECTION 9 -- TC-09: pinned var -- override source wins for that var only
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s09'; sas_name='PCNR_AGE'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s02'; sas_name='age2'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='code'; pcnr_name='PCNR_CODE'; status='PCNR';
  original_header='Code'; col_order=2; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01 s02'; n_sources=3; output;
  pcnr_name='PCNR_CODE'; var_idx=2; result_type='C'; max_length=8;
  type_conflict='N'; s_codes_contributing='s01'; n_sources=1; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work._override;
  length pcnr_name $200 s_code $4;
  pcnr_name='PCNR_AGE'; s_code='s02'; output;
run;
data work.src_s09;
  length norm_psid $64 PCNR_AGE 8 PCNR_CODE $8;
  norm_psid='P001'; PCNR_AGE=.; PCNR_CODE=''; output;
  norm_psid='P002'; PCNR_AGE=.; PCNR_CODE=''; output;
run;
data work.src_s01;
  length norm_psid $64 age 8 code $8;
  norm_psid='P001'; age=30; code='ABC'; output;
  norm_psid='P002'; age=40; code='DEF'; output;
run;
data work.src_s02;
  length norm_psid $64 age2 8;
  norm_psid='P001'; age2=99; output;
run;
proc sort data=work.src_s09 out=work._src_s09; by norm_psid; run;
data work._pcnr_accum;
  attrib norm_psid length=$64
         PCNR_AGE  length=8  _F0001 length=$4
         PCNR_CODE length=$8 _F0002 length=$4;
  set work._src_s09;
  _F0001=''; _F0002='';
run;

%macro _tc09_run;
  %_tc_start(n=09, desc=pinned-var-override);
  /* Pass 2: pinned s02 for PCNR_AGE */
  %p5_gapfill_source(s_code=s02, rank=0,
                     pcnr_filter=PCNR_AGE,
                     srclib=work, nmlib=work, spine_n=2,
                     gen_dir=%sysfunc(getoption(work)));
  /* Pass 3: s01 for PCNR_CODE */
  %p5_gapfill_source(s_code=s01, rank=1,
                     pcnr_filter=PCNR_CODE,
                     srclib=work, nmlib=work, spine_n=2,
                     gen_dir=%sysfunc(getoption(work)));
  /* s01 for PCNR_AGE (P002 was not filled by s02 -- s02 lacks P002) */
  %p5_gapfill_source(s_code=s01, rank=1,
                     pcnr_filter=PCNR_AGE,
                     srclib=work, nmlib=work, spine_n=2,
                     gen_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _f1_p001 _f1_p002 _f2_p001;
    proc sql noprint;
      select strip(_F0001) into :_f1_p001 trimmed
      from work._pcnr_accum where norm_psid='P001';
      select strip(_F0001) into :_f1_p002 trimmed
      from work._pcnr_accum where norm_psid='P002';
      select strip(_F0002) into :_f2_p001 trimmed
      from work._pcnr_accum where norm_psid='P001';
    quit;
    %_assert(cond=(%bquote(&_f1_p001)=%bquote(s02)), label=P001-age-pinned-s02);
    %_assert(cond=(%bquote(&_f1_p002)=%bquote(s01)), label=P002-age-fallback-s01);
    %_assert(cond=(%bquote(&_f2_p001)=%bquote(s01)), label=P001-code-s01-unaffected);
  %end;
%mend _tc09_run;
%_tc09_run;

/*==========================================================================
  SECTION 10 -- TC-10: GAPFILL identity -- n_spine + n_gapfilled + n_missing = total
==========================================================================*/

data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01'; n_sources=2; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  norm_psid='P001'; PCNR_AGE=30; _F0001='s09'; output;
  norm_psid='P002'; PCNR_AGE=40; _F0001='s09'; output;
  norm_psid='P003'; PCNR_AGE=50; _F0001='s01'; output;
  norm_psid='P004'; PCNR_AGE=60; _F0001='s01'; output;
  norm_psid='P005'; PCNR_AGE=.;  _F0001=''; output;
run;

%macro _tc10_run;
  %_tc_start(n=10, desc=gapfill-identity);
  %p5_write_qc(outlib=work, spine_n=5,
               export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _ns _ng _nm _tot;
    proc sql noprint;
      select n_spine, n_gapfilled, n_missing
      into :_ns trimmed, :_ng trimmed, :_nm trimmed
      from work._gapfill_counts where var_idx=1;
    quit;
    %let _tot = %eval(&_ns + &_ng + &_nm);
    /* Check >= 1 gap-filled cell exists */
    %_assert(cond=(%eval(&_ng >= 1)), label=gapfill-ge-1-cell);
    %_assert(cond=(%eval(&_tot = 5)), label=identity-holds);
  %end;
%mend _tc10_run;
%_tc10_run;

/*==========================================================================
  SECTION 11 -- TC-11: final schema -- no helper columns
==========================================================================*/

/* TC-11 calls %p5_finalize_pcnr (not inline DROP) so the dynamic drop list
   from dictionary.columns is exercised -- proves 0 "never been referenced" WARNINGs. */
data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s09'; sas_name='PCNR_AGE';  pcnr_name='PCNR_AGE';  status='PCNR';
  original_header='Age';  col_order=1; output;
  s_code='s09'; sas_name='PCNR_CODE'; pcnr_name='PCNR_CODE'; status='PCNR';
  original_header='Code'; col_order=2; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE';  var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09'; n_sources=1; output;
  pcnr_name='PCNR_CODE'; var_idx=2; result_type='C'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09'; n_sources=1; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
/* Accumulator: spine-only, _F cols present -- finalize will drop them */
data work._pcnr_accum;
  attrib norm_psid length=$64
         PCNR_AGE  length=8  _F0001 length=$4
         PCNR_CODE length=$8 _F0002 length=$4;
  norm_psid='P001'; PCNR_AGE=30; PCNR_CODE='X'; _F0001='s09'; _F0002='s09'; output;
run;
/* src_s09 needed for reconciliation inner join */
data work.src_s09;
  length norm_psid $64 PCNR_AGE 8 PCNR_CODE $8;
  norm_psid='P001'; PCNR_AGE=30; PCNR_CODE='X'; output;
run;

%macro _tc11_run;
  %_tc_start(n=11, desc=final-schema-clean);
  %local _wdir;
  %let _wdir = %sysfunc(getoption(work));
  %_write_s06class_csv(path=&_wdir.\cls_tc11.csv);
  %p5_finalize_pcnr(outlib=work, nmlib=work, srclib=work,
                    spine_n=1, nvars=2, s06class_csv=&_wdir.\cls_tc11.csv);
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    proc contents data=work.pcnr out=work._pcnr_cols noprint; run;
    %local _nextra _has_helper;
    proc sql noprint;
      select count(*) into :_nextra trimmed
      from work._pcnr_cols
      where upcase(name) not in ('NORM_PSID','PCNR_AGE','PCNR_CODE');
      select count(*) into :_has_helper trimmed
      from work._pcnr_cols
      where upcase(name) in ('PCNR_NAME','CONFLICT_TYPE','_F0001','_S0001','SRC_S_CODE');
    quit;
    %_assert(cond=(%eval(&_nextra = 0)), label=no-extra-cols);
    %_assert(cond=(%eval(&_has_helper = 0)), label=no-helper-cols);
  %end;
%mend _tc11_run;
%_tc11_run;

/*==========================================================================
  SECTION 12 -- TC-12: rerun idempotence -- identical conflict/provenance counts
==========================================================================*/

data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01'; n_sources=2; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  norm_psid='P001'; PCNR_AGE=30; _F0001='s09'; output;
  norm_psid='P002'; PCNR_AGE=40; _F0001='s01'; output;
  norm_psid='P003'; PCNR_AGE=.;  _F0001=''; output;
run;
data work._prov_s01;
  length norm_psid $64 pcnr_name $200 src_s_code $4;
  norm_psid='P002'; pcnr_name='PCNR_AGE'; src_s_code='s01'; output;
run;

%macro _tc12_run;
  %_tc_start(n=12, desc=rerun-idempotence);
  %p5_write_qc(outlib=work, spine_n=3,
               export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail-run1);
  %if &p5_fail = 0 %then %do;
    %local _nc1 _np1;
    proc sql noprint;
      select count(*) into :_nc1 trimmed from work.qc_pcnr_conflicts;
      select count(*) into :_np1 trimmed from work.qc_pcnr_provenance;
    quit;
    /* Rebuild prov for second run */
    data work._prov_s01;
      length norm_psid $64 pcnr_name $200 src_s_code $4;
      norm_psid='P002'; pcnr_name='PCNR_AGE'; src_s_code='s01'; output;
    run;
    %let p5_fail = 0;
    %p5_write_qc(outlib=work, spine_n=3,
                 export_dir=%sysfunc(getoption(work)));
    %_assert_pass(label=no-macro-fail-run2);
    %if &p5_fail = 0 %then %do;
      %local _nc2 _np2;
      proc sql noprint;
        select count(*) into :_nc2 trimmed from work.qc_pcnr_conflicts;
        select count(*) into :_np2 trimmed from work.qc_pcnr_provenance;
      quit;
      %_assert(cond=(%eval(&_nc1 = &_nc2)), label=conflict-count-match);
      %_assert(cond=(%eval(&_np1 = &_np2)), label=prov-count-match);
    %end;
  %end;
%mend _tc12_run;
%_tc12_run;

/*==========================================================================
  SECTION 13 -- TC-13: 32-char pcnr_name works
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s01'; sas_name='longcol'; pcnr_name='PCNR_ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  status='PCNR'; original_header='Long'; col_order=1; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_ABCDEFGHIJKLMNOPQRSTUVWXYZ'; var_idx=1;
  result_type='N'; max_length=8; type_conflict='N';
  s_codes_contributing='s01'; n_sources=1; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work.src_s01;
  length norm_psid $64 longcol 8;
  norm_psid='P001'; longcol=42; output;
run;
data work._pcnr_accum;
  attrib norm_psid length=$64
         PCNR_ABCDEFGHIJKLMNOPQRSTUVWXYZ length=8
         _F0001 length=$4;
  norm_psid='P001';
  PCNR_ABCDEFGHIJKLMNOPQRSTUVWXYZ=.;
  _F0001='';
  output;
run;

%macro _tc13_run;
  %_tc_start(n=13, desc=32char-pcnr-name);
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=1, gen_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    proc contents data=work._pcnr_accum out=work._tc13_cols noprint; run;
    %local _found;
    proc sql noprint;
      select count(*) into :_found trimmed
      from work._tc13_cols
      where upcase(name)=upcase('PCNR_ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    quit;
    %_assert(cond=(%eval(&_found = 1)), label=32char-col-exists);
  %end;
%mend _tc13_run;
%_tc13_run;

/*==========================================================================
  SECTION 14 -- TC-14: empty-conflict run -- 0 data rows and CSV exists
==========================================================================*/

data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09'; n_sources=1; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  norm_psid='P001'; PCNR_AGE=30; _F0001='s09'; output;
run;

proc datasets library=work nolist;
  delete _conflicts_s01 _conflicts_s02 _conflicts_s03 _conflicts_s04 _conflicts_s05
         _conflicts_s06 _conflicts_s07 _conflicts_s08 _conflicts_s10 _conflicts_s11
         _conflicts_s12 _conflicts_s13 _conflicts_s14 _conflicts_s15 _conflicts_s16
         _conflicts_s17 _conflicts_s18 _conflicts_s19 _conflicts_s20
         _prov_s01 _prov_s02 _prov_s03 _prov_s04 _prov_s05
         _prov_s06 _prov_s07 _prov_s08 _prov_s10 _prov_s11
         _prov_s12 _prov_s13 _prov_s14 _prov_s15 _prov_s16
         _prov_s17 _prov_s18 _prov_s19 _prov_s20;
quit;

%macro _tc14_run;
  %_tc_start(n=14, desc=empty-conflict-run);
  %p5_write_qc(outlib=work, spine_n=1,
               export_dir=%sysfunc(getoption(work)));
  %_assert_pass(label=no-macro-fail);
  %if &p5_fail = 0 %then %do;
    %local _nc _fex;
    proc sql noprint;
      select count(*) into :_nc trimmed from work.qc_pcnr_conflicts;
    quit;
    %let _fex = %sysfunc(fileexist(%sysfunc(getoption(work))\pcnr_conflicts_detail.csv));
    %_assert(cond=(%eval(&_nc = 0)), label=zero-conflict-rows);
    %_assert(cond=(%eval(&_fex = 1)), label=csv-file-exists);
  %end;
%mend _tc14_run;
%_tc14_run;

/*==========================================================================
  SECTION 15 -- TC-15: preflight fails on three sub-cases
==========================================================================*/

/* Shared name_map and name_map_vars for TC-15 */
data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='code'; pcnr_name='PCNR_CODE'; status='PCNR';
  original_header='Code'; col_order=2; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s01'; n_sources=1; output;
  pcnr_name='PCNR_CODE'; var_idx=2; result_type='C'; max_length=8;
  type_conflict='N'; s_codes_contributing='s01'; n_sources=1; output;
run;
data work.src_s09;
  length norm_psid $64 PCNR_AGE 8 PCNR_CODE $8;
  norm_psid='P001'; PCNR_AGE=30; PCNR_CODE='X'; output;
  norm_psid='P002'; PCNR_AGE=40; PCNR_CODE='Y'; output;
run;

%macro _tc15_run;
  %_tc_start(n=15, desc=preflight-fail-subcases);
  %local _wdir;
  %let _wdir = %sysfunc(getoption(work));

  /* 15a: s01 has duplicate non-blank norm_psid */
  %let p5_fail = 0;
  data work.src_s01;
    length norm_psid $64 age 8 code $8;
    norm_psid='P001'; age=30; code='X'; output;
    norm_psid='P001'; age=55; code='Z'; output;
    norm_psid='P002'; age=40; code='Y'; output;
  run;
  %_write_priority_csv(path=&_wdir.\prio_15a.csv);
  %_write_override_csv(path=&_wdir.\ov_15a.csv);
  %_write_s06class_csv(path=&_wdir.\cls_15a.csv);
  %p5_preflight(srclib=work, nmlib=work, outlib=work,
                spine_n=2, nvars=2,
                priority_csv=&_wdir.\prio_15a.csv,
                override_csv=&_wdir.\ov_15a.csv,
                s06class_csv=&_wdir.\cls_15a.csv,
                gen_dir=&_wdir, export_dir=&_wdir);
  %_assert_fail(label=15a-dup-key-detected);

  /* 15b: priority CSV has duplicate rank */
  %let p5_fail = 0;
  data work.src_s01;
    length norm_psid $64 age 8 code $8;
    norm_psid='P001'; age=30; code='X'; output;
    norm_psid='P002'; age=40; code='Y'; output;
  run;
  data _null_;
    file "&_wdir.\prio_15b.csv" encoding='utf-8';
    put 's_code,rank,note';
    put 's01,1,'; put 's02,1,'; /* duplicate rank=1 */
    put 's03,3,'; put 's04,4,'; put 's05,5,'; put 's06,6,'; put 's07,7,';
    put 's08,8,'; put 's09,9,spine'; put 's10,10,'; put 's11,11,'; put 's12,12,';
    put 's13,13,'; put 's14,14,'; put 's15,15,'; put 's16,16,'; put 's17,17,';
    put 's18,18,'; put 's19,19,'; put 's20,20,';
  run;
  %p5_preflight(srclib=work, nmlib=work, outlib=work,
                spine_n=2, nvars=2,
                priority_csv=&_wdir.\prio_15b.csv,
                override_csv=&_wdir.\ov_15a.csv,
                s06class_csv=&_wdir.\cls_15a.csv,
                gen_dir=&_wdir, export_dir=&_wdir);
  %_assert_fail(label=15b-dup-rank-detected);

  /* 15c: override pins PCNR_AGE to s03, but s03 not in name_map for PCNR_AGE */
  %let p5_fail = 0;
  data _null_;
    file "&_wdir.\ov_15c.csv" encoding='utf-8';
    put 'pcnr_name,s_code';
    put 'PCNR_AGE,s03';
  run;
  %p5_preflight(srclib=work, nmlib=work, outlib=work,
                spine_n=2, nvars=2,
                priority_csv=&_wdir.\prio_15a.csv,
                override_csv=&_wdir.\ov_15c.csv,
                s06class_csv=&_wdir.\cls_15a.csv,
                gen_dir=&_wdir, export_dir=&_wdir);
  %_assert_fail(label=15c-bad-pin-detected);
%mend _tc15_run;
%_tc15_run;

/*==========================================================================
  SECTION 16 -- TC-16: reconciliation detects corrupted cell; passes when clean
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s09'; sas_name='PCNR_AGE'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
run;
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01'; n_sources=2; output;
run;
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work.src_s09;
  length norm_psid $64 PCNR_AGE 8;
  norm_psid='P001'; PCNR_AGE=.; output;
  norm_psid='P002'; PCNR_AGE=.; output;
  norm_psid='P003'; PCNR_AGE=.; output;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=30; output;
  norm_psid='P002'; age=40; output;
  norm_psid='P003'; age=50; output;
run;
proc sort data=work.src_s09 out=work._src_s09; by norm_psid; run;
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  set work._src_s09;
  _F0001='';
run;

%macro _tc16_run;
  %_tc_start(n=16, desc=reconciliation-mismatch-detection);
  %local _wdir;
  %let _wdir = %sysfunc(getoption(work));
  %_write_s06class_csv(path=&_wdir.\cls_tc16.csv);
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=3, gen_dir=&_wdir);
  %_assert_pass(label=gapfill-preflight-ok);
  %if &p5_fail = 0 %then %do;
    /* Corrupt P001 PCNR_AGE: 30 -> 999 without changing _F0001 */
    data work._pcnr_accum;
      set work._pcnr_accum;
      if norm_psid='P001' then PCNR_AGE=999;
    run;
    data work.pcnr;
      set work._pcnr_accum;
      drop _F:;
    run;
    %let p5_fail = 0;
    %p5_finalize_pcnr(outlib=work, nmlib=work, srclib=work,
                      spine_n=3, nvars=1, s06class_csv=&_wdir.\cls_tc16.csv);
    %_assert_fail(label=corrupted-cell-detected);
    /* Restore correct value */
    %let p5_fail = 0;
    data work._pcnr_accum;
      set work._pcnr_accum;
      if norm_psid='P001' then PCNR_AGE=30;
    run;
    data work.pcnr;
      set work._pcnr_accum;
      drop _F:;
    run;
    %p5_finalize_pcnr(outlib=work, nmlib=work, srclib=work,
                      spine_n=3, nvars=1, s06class_csv=&_wdir.\cls_tc16.csv);
    %_assert_pass(label=clean-run-passes);
  %end;
%mend _tc16_run;
%_tc16_run;

/*==========================================================================
  SECTION 17 -- TC-17: full chain build_accumulator -> run_gapfill ->
  finalize_pcnr -> write_qc on synthetic WORK data (no hand-built accum)
==========================================================================*/

/* Fresh name_map: s09 spine col + s01 non-spine col, 1 var, no type conflict */
data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s09'; sas_name='PCNR_SCORE'; pcnr_name='PCNR_SCORE'; status='PCNR';
  original_header='Score'; col_order=1; output;
  s_code='s01'; sas_name='score'; pcnr_name='PCNR_SCORE'; status='PCNR';
  original_header='Score'; col_order=1; output;
run;
/* name_map_vars WITHOUT var_idx -- %p5_build_accumulator owns var_idx now */
data work.name_map_vars;
  length pcnr_name $200 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_SCORE'; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s09 s01'; n_sources=2; output;
run;
/* _nmv carries var_idx from name_map_vars (set directly, no re-increment) */
data work._nmv;
  set work.name_map_vars;
run;
data work._type_resolution;
  length pcnr_name $200 resolved_type $8 out_length 8;
  stop;
run;
data work._override;
  length pcnr_name $200 s_code $4;
  stop;
run;
data work._priority;
  length s_code $4 rank 8 note $40;
  s_code='s01'; rank=1; note=''; output;
  s_code='s09'; rank=9; note='spine'; output;
run;
proc sort data=work._priority; by rank; run;
data work.src_s09;
  length norm_psid $64 PCNR_SCORE 8;
  norm_psid='P001'; PCNR_SCORE=10; output;
  norm_psid='P002'; PCNR_SCORE=.; output;
  norm_psid='P003'; PCNR_SCORE=.; output;
run;
data work.src_s01;
  length norm_psid $64 score 8;
  norm_psid='P001'; score=99; output;
  norm_psid='P002'; score=20; output;
  norm_psid='P003'; score=30; output;
run;

%macro _tc17_run;
  %_tc_start(n=17, desc=full-chain-build-to-writeqc);
  %local _wdir;
  %let _wdir = %sysfunc(getoption(work));
  %_write_s06class_csv(path=&_wdir.\cls_tc17.csv);

  /* Step 1: build_accumulator */
  %p5_build_accumulator(srclib=work, nmlib=work, spine_n=3,
                        gen_dir=&_wdir, export_dir=&_wdir);
  %_assert_pass(label=build-accum-ok);
  %if &p5_fail = 0 %then %do;

    /* Step 2: run_gapfill */
    %p5_run_gapfill(srclib=work, nmlib=work, spine_n=3, gen_dir=&_wdir);
    %_assert_pass(label=run-gapfill-ok);
  %end;
  %if &p5_fail = 0 %then %do;

    /* Step 3: finalize_pcnr */
    %p5_finalize_pcnr(outlib=work, nmlib=work, srclib=work,
                      spine_n=3, nvars=1, s06class_csv=&_wdir.\cls_tc17.csv);
    %_assert_pass(label=finalize-ok);
  %end;
  %if &p5_fail = 0 %then %do;

    /* Step 4: write_qc */
    %p5_write_qc(outlib=work, spine_n=3, export_dir=&_wdir);
    %_assert_pass(label=write-qc-ok);
  %end;
  %if &p5_fail = 0 %then %do;
    /* Verify: P001 stays spine (s09 filled), P002/P003 gap-filled from s01 */
    %local _nrow _f_p001 _f_p002 _score_p001 _score_p002;
    proc sql noprint;
      select count(*) into :_nrow trimmed from work.pcnr;
      select strip(_F0001) into :_f_p001 trimmed
      from work._pcnr_accum where norm_psid='P001';
      select strip(_F0001) into :_f_p002 trimmed
      from work._pcnr_accum where norm_psid='P002';
      select PCNR_SCORE into :_score_p001 trimmed
      from work.pcnr where norm_psid='P001';
      select PCNR_SCORE into :_score_p002 trimmed
      from work.pcnr where norm_psid='P002';
    quit;
    %_assert(cond=(%eval(&_nrow = 3)), label=pcnr-3-rows);
    %_assert(cond=(%bquote(&_f_p001)=%bquote(s09)), label=P001-spine-origin);
    %_assert(cond=(%bquote(&_f_p002)=%bquote(s01)), label=P002-gapfilled-s01);
    %_assert(cond=(%eval(&_score_p001 = 10)), label=P001-score-10);
    %_assert(cond=(%eval(&_score_p002 = 20)), label=P002-score-20);
    /* SPINE_VS_SOURCE conflict: P001 spine=10, s01=99 -> conflict row */
    %local _nconflict;
    proc sql noprint;
      select count(*) into :_nconflict trimmed
      from work.qc_pcnr_conflicts
      where norm_psid='P001' and pcnr_name='PCNR_SCORE';
    quit;
    %_assert(cond=(%eval(&_nconflict >= 1)), label=P001-conflict-recorded);
  %end;
%mend _tc17_run;
%_tc17_run;

/*==========================================================================
  SECTION 18 -- TC-18: var_idx mismatch -- reconciliation guard fires
==========================================================================*/

data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s01'; sas_name='age'; pcnr_name='PCNR_AGE'; status='PCNR';
  original_header='Age'; col_order=1; output;
run;
data work.name_map_vars;
  length pcnr_name $200 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; result_type='N'; max_length=8;
  type_conflict='N'; s_codes_contributing='s01'; n_sources=1; output;
run;
/* var_idx=99 will not match any _F0099 in the accumulator */
data work._nmv;
  set work.name_map_vars;
  var_idx = 99;
run;
data work.src_s01;
  length norm_psid $64 age 8;
  norm_psid='P001'; age=30; output;
run;
/* Accumulator uses _F0001 (var_idx=1) but _nmv says var_idx=99 */
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  norm_psid='P001'; PCNR_AGE=30; _F0001='s01'; output;
run;
data work.pcnr;
  set work._pcnr_accum;
  drop _F:;
run;

%macro _tc18_run;
  %_tc_start(n=18, desc=varidx-mismatch-guard);
  %local _wdir;
  %let _wdir = %sysfunc(getoption(work));
  %_write_s06class_csv(path=&_wdir.\cls_tc18.csv);
  %p5_finalize_pcnr(outlib=work, nmlib=work, srclib=work,
                    spine_n=1, nvars=1, s06class_csv=&_wdir.\cls_tc18.csv);
  /* Reconciliation should fire p5_fail=1 because _F0099 missing from _rs_merged */
  %_assert_fail(label=varidx-mismatch-detected);
%mend _tc18_run;
%_tc18_run;

/*==========================================================================
  SECTION 19 -- TC-19: SQL error inside p5_gapfill_source -> p5_fail=1
  Force error by passing nmlib= pointing to a libname that has no name_map.
==========================================================================*/

/* Minimal setup -- _nmv and _pcnr_accum already exist from TC-18 */
data work._pcnr_accum;
  attrib norm_psid length=$64 PCNR_AGE length=8 _F0001 length=$4;
  norm_psid='P001'; PCNR_AGE=.; _F0001=''; output;
run;

%macro _tc19_run;
  %_tc_start(n=19, desc=sql-error-gapfill-propagates);
  /* nmlib=work is fine but work.name_map exists with PCNR_AGE/s01 from TC-18 setup.
     Override: delete work.name_map so the inner join finds 0 rows -> _gf_cols empty
     -> %return (not a SQL error). Instead, force sqlrc>4 by referencing nonexistent
     libname. Assign a libname that points to a non-existent path to induce SQL error. */
  %local _wdir;
  %let _wdir = %sysfunc(getoption(work));
  libname _fake_ "&_wdir.\nonexistent_does_not_exist_path";
  /* _fake_ assignment will succeed (SAS lazy-binds), but querying it will error.
     Instead, simply delete work._nmv so the inner join produces ERROR "table not found". */
  proc datasets library=work nolist; delete _nmv; quit;
  %p5_gapfill_source(s_code=s01, rank=1, srclib=work, nmlib=work,
                     spine_n=1, gen_dir=&_wdir);
  %_assert_fail(label=sql-error-detected-p5-fail-1);
%mend _tc19_run;
%_tc19_run;

/*==========================================================================
  SECTION 20 -- Summary
==========================================================================*/
%_tc_summary;
