/*==========================================================================
  Program : tests/05_orchestrator_smoke.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Smoke test -- run sas/05_build_pcnr.sas end-to-end against
            synthetic WORK data.  Validates the orchestrator wiring
            (%route_log, %p5_preflight, ... %restore_log) without P: paths.

  Strategy:
    1. Build minimal WORK tables that satisfy all phase macros.
    2. Assign LIBNAME pdd pointing to WORK temp dir (same physical dir).
    3. Set macro variables (sas_path, logs_path, exchange_path, pdd_path,
       in_pipeline) so 05_build_pcnr.sas runs fully standalone.
    4. %include sas/05_build_pcnr.sas -- exercises every section.
    5. Verify pdd.pcnr exists and has the expected row count.

  PCM compliance:
    C3  No open-code %if/%do outside %macro/%mend
    C13 All macro definitions before first call
    C14 No bare data;/set;
==========================================================================*/

options nosyntaxcheck nomlogic nomprint nosymbolgen;

/*==========================================================================
  SECTION 0 -- Paths and LIBNAME
==========================================================================*/

/* Resolve WORK directory and point all pipeline paths there */
%let _work = %sysfunc(getoption(work));
%let sas_path      = C:\data_dictionary\sas;
%let logs_path     = &_work;
%let exchange_path = &_work;
%let pdd_path      = &_work;
%let in_pipeline   = 1;   /* skip proc printto log routing */

libname pdd "&_work";

/*==========================================================================
  SECTION 1 -- Helper macros (defined before %include, C13)
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

/* Write CSVs to WORK dir so phase macros can read them */
%_write_priority_csv(path=&_work.\pcnr_source_priority.csv);
%_write_override_csv(path=&_work.\pcnr_source_override.csv);
%_write_s06class_csv(path=&_work.\s06class.csv);

/*==========================================================================
  SECTION 2 -- Synthetic source data
  Two PCNR_ variables: PCNR_AGE (numeric) and PCNR_SEX (char).
  Two sources: s01 (has both), s09 (spine, has PCNR_SEX only).
  All other src_sNN tables created empty so %p5_build_accumulator
  loop does not error on missing members.
==========================================================================*/

/* name_map: one row per (source, pcnr_name) pairing */
data pdd.name_map;
  length pcnr_name $200 s_code $4 col_name $200 status $20
         original_header $200 col_order 8 n_sources 8
         type_conflict $1 result_type $1 max_length 8;
  s_code='s01'; col_name='age';    pcnr_name='PCNR_AGE'; status='PCNR';
    original_header='Age'; col_order=1; n_sources=1;
    type_conflict='N'; result_type='N'; max_length=8; output;
  s_code='s01'; col_name='sex';    pcnr_name='PCNR_SEX'; status='PCNR';
    original_header='Sex'; col_order=2; n_sources=2;
    type_conflict='N'; result_type='C'; max_length=20; output;
  s_code='s09'; col_name='sex';    pcnr_name='PCNR_SEX'; status='PCNR';
    original_header='Sex'; col_order=2; n_sources=2;
    type_conflict='N'; result_type='C'; max_length=20; output;
run;

/* name_map_vars: one row per PCNR_ variable */
data pdd.name_map_vars;
  length pcnr_name $200 var_idx 8 result_type $1 max_length 8
         type_conflict $1 s_codes_contributing $200 n_sources 8;
  pcnr_name='PCNR_AGE'; var_idx=1; result_type='N'; max_length=8;
    type_conflict='N'; s_codes_contributing='s01'; n_sources=1; output;
  pcnr_name='PCNR_SEX'; var_idx=2; result_type='C'; max_length=20;
    type_conflict='N'; s_codes_contributing='s01 s09'; n_sources=2; output;
run;

/* Spine: src_s09 -- 3 subjects */
data pdd.src_s09;
  length norm_psid $64 sex $20;
  norm_psid='P001'; sex='M'; output;
  norm_psid='P002'; sex='F'; output;
  norm_psid='P003'; sex='M'; output;
run;

/* s01: has age and sex for P001/P002; P003 age missing (gap-fill test) */
data pdd.src_s01;
  length norm_psid $64 age 8 sex $20;
  norm_psid='P001'; age=30; sex='M'; output;
  norm_psid='P002'; age=45; sex='F'; output;
run;

/* Empty tables for s02..s08, s10..s20 */
%macro _mk_empty(n=);
  data pdd.src_s&n;
    length norm_psid $64;
    stop;
  run;
%mend _mk_empty;

%_mk_empty(n=02) %_mk_empty(n=03) %_mk_empty(n=04) %_mk_empty(n=05)
%_mk_empty(n=06) %_mk_empty(n=07) %_mk_empty(n=08) %_mk_empty(n=10)
%_mk_empty(n=11) %_mk_empty(n=12) %_mk_empty(n=13) %_mk_empty(n=14)
%_mk_empty(n=15) %_mk_empty(n=16) %_mk_empty(n=17) %_mk_empty(n=18)
%_mk_empty(n=19) %_mk_empty(n=20)

/*==========================================================================
  SECTION 3 -- Override macro globals so 05_build_pcnr.sas uses WORK paths
  The orchestrator macros default to srclib=pdd, nmlib=pdd, outlib=pdd.
  Since we assigned LIBNAME pdd to WORK above, all I/O lands in WORK.
  CSV paths used by macros are resolved via &exchange_path (set above).
==========================================================================*/

%let priority_csv = &_work.\pcnr_source_priority.csv;
%let override_csv = &_work.\pcnr_source_override.csv;
%let s06class_csv = &_work.\s06class.csv;

/*==========================================================================
  SECTION 4 -- Run the orchestrator end-to-end
==========================================================================*/

%include "C:\data_dictionary\sas\05_build_pcnr.sas";

/*==========================================================================
  SECTION 5 -- Assertions
==========================================================================*/

%macro _smoke_assert(label=, cond=);
  %if &cond %then
    %put SMOKE-PASS: &label;
  %else
    %put SMOKE-FAIL: &label;
%mend _smoke_assert;

/* pdd.pcnr must exist and have 3 rows (one per spine subject) */
%let _pcnr_n = 0;
proc sql noprint;
  select count(*) into :_pcnr_n trimmed from pdd.pcnr;
quit;

%_smoke_assert(label=pdd.pcnr exists with 3 rows,
               cond=(%bquote(&_pcnr_n) = 3));

/* PCNR_AGE should be populated for P001 and P002 (P003 remains missing) */
%let _age_n = 0;
proc sql noprint;
  select count(*) into :_age_n trimmed
  from pdd.pcnr
  where PCNR_AGE is not missing;
quit;

%_smoke_assert(label=PCNR_AGE populated for 2 subjects,
               cond=(%bquote(&_age_n) = 2));

/* PCNR_SEX should be populated for all 3 spine rows (gap-filled from s09) */
%let _sex_n = 0;
proc sql noprint;
  select count(*) into :_sex_n trimmed
  from pdd.pcnr
  where PCNR_SEX ne '';
quit;

%_smoke_assert(label=PCNR_SEX populated for all 3 subjects,
               cond=(%bquote(&_sex_n) = 3));

%put NOTE: [05_orchestrator_smoke] Smoke test complete.;
