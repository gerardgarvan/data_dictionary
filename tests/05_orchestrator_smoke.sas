/*==========================================================================
  Program : tests/05_orchestrator_smoke.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Smoke test -- run sas/05_build_pcnr.sas end-to-end against
            synthetic WORK data.  Validates orchestrator wiring
            (%route_log, %p5_preflight, ... %restore_log) without P: paths.

  Safety guarantee (p5_smoke=1 switch):
    - 00_config.sas and %pdd_lib are NOT called: LIBNAME pdd stays pointed
      at WORK; real pdd.pcnr and P: exchange/log paths are never touched.
    - All macros receive srclib/nmlib/outlib=work and the synthetic
      spine_n/nvars counts (3/2) rather than the production defaults
      (41150/1299).  Assertions on row counts use those same synthetic values.

  NOTE: NOT YET RUN -- awaiting live SAS execution.

  PCM compliance:
    C3  No open-code %if/%do outside %macro/%mend
    C13 All macro definitions before first call
    C14 No bare data;/set;
==========================================================================*/

options nosyntaxcheck nomlogic nomprint nosymbolgen;

/*==========================================================================
  SECTION 0 -- Smoke switch and path globals
  Set these BEFORE %include of 05_build_pcnr.sas so Section 0 of that
  program reads them and skips config / %pdd_lib.
==========================================================================*/

%let p5_smoke         = 1;
%let p5_smoke_srclib  = work;
%let p5_smoke_outlib  = work;
%let p5_smoke_spine_n = 3;        /* 3 synthetic subjects */
%let p5_smoke_nvars   = 2;        /* PCNR_AGE + PCNR_SEX */
%let p5_smoke_gen_dir = %sysfunc(getoption(work));
%let p5_smoke_exp_dir = %sysfunc(getoption(work));
/* CSV paths resolved after _work is set below -- overwritten at Section 1 */
%let p5_smoke_pri_csv = ;
%let p5_smoke_ov_csv  = ;
%let p5_smoke_cls_csv = ;

/* in_pipeline=1: skip proc printto log routing inside %route_log */
%let in_pipeline = 1;

/* Point pdd libref to WORK so any residual reference resolves to WORK */
%let _work = %sysfunc(getoption(work));
libname pdd "&_work";

/* sas_path needed by the %include statement inside 05_build_pcnr.sas */
%let sas_path = C:\data_dictionary\sas;

/*==========================================================================
  SECTION 1 -- Helper macros (C13: defined before %include, which calls them)
==========================================================================*/

/* Write 20-row priority CSV */
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

/* Write CSVs to WORK dir; set globals for orchestrator */
%_write_priority_csv(path=&_work.\pcnr_source_priority.csv);
%_write_override_csv(path=&_work.\pcnr_source_override.csv);
%_write_s06class_csv(path=&_work.\s06class.csv);

/* Tell the orchestrator's _p5_init_paths where the synthetic CSVs live */
%let p5_smoke_pri_csv = &_work.\pcnr_source_priority.csv;
%let p5_smoke_ov_csv  = &_work.\pcnr_source_override.csv;
%let p5_smoke_cls_csv = &_work.\s06class.csv;

/* Dummy macro _mk_empty -- used in data setup below */
%macro _mk_empty(n=);
  data work.src_s&n;
    length norm_psid $64;
    stop;
  run;
%mend _mk_empty;

/*==========================================================================
  SECTION 2 -- Synthetic source data
  Two PCNR_ variables: PCNR_AGE (numeric, var_idx=1) and PCNR_SEX (char, var_idx=2).
  Two sources: s01 (has both), s09 (spine, has PCNR_SEX only).
  All other src_sNN tables created empty so loop in %p5_build_accumulator
  does not error on missing members.
==========================================================================*/

/* name_map: one row per (source, pcnr_name) pairing -- real schema */
data work.name_map;
  length s_code $4 col_order 8 sas_name $200 original_header $200
         status $20 pcnr_name $200;
  s_code='s01'; sas_name='age';  pcnr_name='PCNR_AGE'; status='PCNR';
    original_header='Age'; col_order=1; output;
  s_code='s01'; sas_name='sex';  pcnr_name='PCNR_SEX'; status='PCNR';
    original_header='Sex'; col_order=2; output;
  s_code='s09'; sas_name='sex';  pcnr_name='PCNR_SEX'; status='PCNR';
    original_header='Sex'; col_order=2; output;
run;

/* name_map_vars: one row per PCNR_ variable (var_idx pre-assigned) */
data work.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
    type_conflict='N'; s_codes_contributing='s01'; n_sources=1; output;
  pcnr_name='PCNR_SEX'; var_idx=2; result_type='C'; max_length=20;
    type_conflict='N'; s_codes_contributing='s01 s09'; n_sources=2; output;
run;

/* Spine: src_s09 -- 3 subjects */
data work.src_s09;
  length norm_psid $64 sex $20;
  norm_psid='P001'; sex='M'; output;
  norm_psid='P002'; sex='F'; output;
  norm_psid='P003'; sex='M'; output;
run;

/* s01: age and sex for P001/P002; P003 age missing to test gap-fill */
data work.src_s01;
  length norm_psid $64 age 8 sex $20;
  norm_psid='P001'; age=30; sex='M'; output;
  norm_psid='P002'; age=45; sex='F'; output;
run;

/* Empty tables for s02..s08, s10..s20 */
%_mk_empty(n=02) %_mk_empty(n=03) %_mk_empty(n=04) %_mk_empty(n=05)
%_mk_empty(n=06) %_mk_empty(n=07) %_mk_empty(n=08) %_mk_empty(n=10)
%_mk_empty(n=11) %_mk_empty(n=12) %_mk_empty(n=13) %_mk_empty(n=14)
%_mk_empty(n=15) %_mk_empty(n=16) %_mk_empty(n=17) %_mk_empty(n=18)
%_mk_empty(n=19) %_mk_empty(n=20)

/*==========================================================================
  SECTION 3 -- Run the orchestrator end-to-end
  p5_smoke=1 causes 05_build_pcnr.sas to:
    - skip %include 00_config.sas and %pdd_lib (P: paths never touched)
    - pass srclib=work nmlib=work outlib=work to every macro call
    - pass spine_n=3 nvars=2 to every macro call
==========================================================================*/

%include "C:\data_dictionary\sas\05_build_pcnr.sas";

/*==========================================================================
  SECTION 4 -- Assertions
  NOTE: NOT YET RUN -- awaiting live SAS execution.
==========================================================================*/

%macro _smoke_assert(label=, cond=);
  %if &cond %then
    %put SMOKE-PASS: &label;
  %else
    %put SMOKE-FAIL: &label;
%mend _smoke_assert;

/* work.pcnr must exist and have 3 rows (one per spine subject) */
%let _pcnr_n = 0;
proc sql noprint;
  select count(*) into :_pcnr_n trimmed from work.pcnr;
quit;

%_smoke_assert(label=work.pcnr exists with 3 rows,
               cond=(%bquote(&_pcnr_n) = 3));

/* PCNR_AGE populated for P001 and P002; P003 has no age source */
%let _age_n = 0;
proc sql noprint;
  select count(*) into :_age_n trimmed
  from work.pcnr
  where PCNR_AGE is not missing;
quit;

%_smoke_assert(label=PCNR_AGE populated for 2 subjects,
               cond=(%bquote(&_age_n) = 2));

/* PCNR_SEX populated for all 3 spine rows (s09 spine source covers P003) */
%let _sex_n = 0;
proc sql noprint;
  select count(*) into :_sex_n trimmed
  from work.pcnr
  where PCNR_SEX ne '';
quit;

%_smoke_assert(label=PCNR_SEX populated for all 3 subjects,
               cond=(%bquote(&_sex_n) = 3));

%put NOTE: [05_orchestrator_smoke] Smoke test complete. NOT YET RUN -- awaiting live SAS execution.;
