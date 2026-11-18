/*==========================================================================
  Program : 18_combine_test.sas
  Purpose : Standalone synthetic tests for sas/18_combine_macros.sas.
            WORK data only (the pdd libref points at a folder inside WORK).
            Reads nothing from P: and nothing from g. Includes no 00_config.sas
            (norm_psid values are given in the fixtures). Fake MRNs and text
            canaries are built with cats() so the log never echoes them.
            T1  char to num: NULL null blank to missing, 1.5 to 1.5, abc counted
                as a failure (FLAG), no value in QC
            T2  num to char: 7, 12345678901, 0.5 and no E in any result
            T3  PDD-D-30 merge: s22 wins, s23 fills blank and NULL, conflicts
                counted per column, YEAR stays s22, s23-only case passes through
            T4  stack counts, gate FAILs: repeated case, old with new, s21 with s22
            T5  id attach: PECAN_ID and PECAN_ID_KEY_ERA from the case map, FAIL on
                no entry, duplicate key, missing PECAN_ID, K2 PRECEDE_STUDY_ID by
                NORM, DELIVERED and BLANK, K1 keeps the delivered value
            T6  variable gate: missing variable, extra PCNR_ column, wrong type,
                ENCRYPTED_ column
            T7  decisions loader: prefix and case-insensitive key, unknown key
                FAILs, PENDING_DECISION row FAILs, CONDITIONAL row accepted
            T8  column order and order gate
            T9  NO_DATA flag and coverage reconciliation
            T10 reconciliation: K1 counts, NULL-to-missing explained, unexplained
                FAILs, distinct counts against a fake v1.0 profile
            T11 backup of the replaced combined table (stem pcnrcmb, member name at
                most 32 bytes, second build adds a second backup, copy equals table)
            T12 read-only guard on registry, dup link and case map
            T13 mask: 0 1 10 11 give 0 <11 <11 11
            T14 QC staging: 40 qadd calls give one write and 40 rows
            T15 canary and MRN scan: clean file 0 hits, seeded file 1 hit and FAIL
            T16 PDD-D-33: empty gives the NORM default, X FAILs with nothing written,
                NORM DELIVERED BLANK pass
            T17 no WARNING and no ERROR lines in this log and no canary in log or CSV
            T0  session state restored
  Run     : sas 18_combine_test.sas  (no pipeline setup required)
            Bring back the log and look for the TESTRESULT SUMMARY line.
  Session : own SAS session. Close any table viewer on pdd first. This test repoints
            pdd and the backup folder at WORK folders and uses FLAG mode. It restores
            them at the end, but never run it in the same session as 18a 18b 18c 18d.
  Status  : PENDING SAS RUN (Gerard, synthetic data only).
==========================================================================*/

%let _test_log_path = %sysfunc(pathname(work))\18_combine_test.log;
proc printto log="&_test_log_path" new; run;

/* session state saved here, restored by %_restore_state at the very end */
%let _saved_pdd_path = %sysfunc(pathname(pdd));
%let _saved_k2mode = ;
%macro _save_mode;
  %if %symexist(PDD_K2_PSID_MODE) %then %let _saved_k2mode = &PDD_K2_PSID_MODE;
%mend _save_mode;
%_save_mode;

options validvarname=v7 dlcreatedir;
libname pdd "%sysfunc(pathname(work))\tpdd";
%let backup_path = %sysfunc(pathname(work))\tbak;
%let out_root = %sysfunc(pathname(work));
%let comb_backup_stem = pcnrcmb;
options nodlcreatedir;

/* %fail_out is only reached in ABORT mode, which this test never uses */
%macro fail_out(msg=);
  %put ERROR: [18_combine_test] unexpected abort - &msg;
  %abort cancel;
%mend fail_out;

%include "C:\data_dictionary\sas\18_combine_macros.sas";

%let _saved_fail_mode = &p18_fail_mode;
%let _saved_p17_mode = &p17_fail_mode;
%let p18_fail_mode = FLAG;
%let p17_fail_mode = FLAG;

%macro _restore_state;
  %let p18_fail_mode = &_saved_fail_mode;
  %let p17_fail_mode = &_saved_p17_mode;
  %let _p18_failed = 0;
  %let PDD_K2_PSID_MODE = &_saved_k2mode;
  %if %sysfunc(libref(p17bak)) = 0 %then %do;
    libname p17bak clear;
  %end;
  %if %length(&_saved_pdd_path) > 0 %then %do;
    libname pdd base "&_saved_pdd_path";
  %end;
  %else %if %sysfunc(libref(pdd)) = 0 %then %do;
    libname pdd clear;
  %end;
  %put NOTE: [18_combine_test] session state restored - fail mode &p18_fail_mode, pdd and p17bak librefs reset;
  %put NOTE: [18_combine_test] run production programs 18a 18b 18c 18d each in a fresh SAS session;
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

/* the check is FAIL unless cond evaluates true (C34: %unquote) */
/* num=1: cond holds a decimal comparison, evaluated with %sysevalf(..., boolean)
   into a variable first, so an evaluation problem leaves _r blank (FAIL is recorded)
   instead of stopping the macro inside %if. Use num=1 for every decimal literal. */
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
  %if &_p18_failed = 1 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(gate did not fail));
  %let _p18_failed = 0;
%mend _expect_fail;

%macro _expect_ok(case=);
  %if &_p18_failed = 0 %then %_record(case=&case, result=PASS);
  %else %_record(case=&case, result=FAIL, detail=%str(unexpected failure));
  %let _p18_failed = 0;
%mend _expect_ok;

%macro _init_g;
  %global _v _c _dec _dec2;
%mend _init_g;
%_init_g;
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

%macro _drop(ds=);
  %if %sysfunc(exist(&ds)) %then %do;
    proc delete data=&ds;
    run;
  %end;
%mend _drop;

/* one fixture row of a new-era source (all text) */
%macro _nrow(id=, age=, year=, frail=, code=, asa=, note=);
  norm_psid = "&id"; nm_age = "&age"; nm_year = "&year"; nm_frail = "&frail";
  nm_code = "&code"; nm_asa = "&asa"; nm_note = "&note";
  output;
%mend _nrow;

%macro _mk_new(ds=);
  data &ds;
    length norm_psid $64 nm_age $20 nm_year $20 nm_frail $8 nm_code $20 nm_asa $8 nm_note $40;
%mend _mk_new;

%macro _mrow(id=, psid=, n=, era=, pid=, pera=);
  norm_psid = "&id"; PRECEDE_STUDY_ID = "&psid"; ENCRYPTED_MRN = cats('MRN', 'CANARY', "&n");
  KEY_ERA = "&era"; PECAN_ID = &pid; PECAN_ID_KEY_ERA = "&pera";
  SRC_UNIT = 's09'; MRN_STATUS = 'OK';
  output;
%mend _mrow;

/* ---- fixtures ------------------------------------------------------------ */
%macro _fixtures;
  data pdd.name_map_ext;
    length s_code $8 sas_name $64 status $16 pcnr_name $64;
    do s_code = 's21', 's22', 's23';
      sas_name = 'nm_age'; pcnr_name = 'PCNR_AGE'; status = 'PCNR'; output;
      sas_name = 'nm_year'; pcnr_name = 'PCNR_YEAR'; output;
      sas_name = 'nm_frail'; pcnr_name = 'PCNR_FRAIL'; output;
      sas_name = 'nm_code'; pcnr_name = 'PCNR_CODE'; output;
      sas_name = 'nm_asa'; pcnr_name = 'PCNR_ASA'; output;
      sas_name = 'nm_note'; pcnr_name = 'PCNR_NOTE'; output;
      sas_name = 'nm_link'; pcnr_name = ''; status = 'LINKAGE_ONLY'; output;
      status = 'PCNR';
    end;
  run;
  data pdd.name_map_vars_ext;
    length pcnr_name $64 result_type $1 max_length 8;
    result_type = 'C'; max_length = 20;
    pcnr_name = 'PCNR_AGE'; output;
    pcnr_name = 'PCNR_YEAR'; output;
    pcnr_name = 'PCNR_FRAIL'; output;
    pcnr_name = 'PCNR_CODE'; output;
    pcnr_name = 'PCNR_ASA'; output;
    pcnr_name = 'PCNR_NOTE'; max_length = 40; output;
  run;
  %let _dec = %sysfunc(pathname(work))\t_dec.csv;
  data _null_;
    file "&_dec";
    put 'pcnr_name,combined_type,note_kind,note_text,decision_ref';
    put 'Age,N,TYPE,numeric,PDD-D-31(1)';
    put 'PCNR_YEAR,C,TYPE,text,PDD-D-31(2)';
    put 'pcnr_code,C,TYPE,text code,PDD-D-31(2)';
    put 'ASA,N,CONDITIONAL,numeric if both sides numeric,PDD-D-31(2) conditional';
    put 'frail,,NOTE,era coding,PDD-D-31(3)';
  run;
  %let _dec2 = %sysfunc(pathname(work))\t_dec2.csv;
  data _null_;
    file "&_dec2";
    put 'pcnr_name,combined_type,note_kind,note_text,decision_ref';
    put 'ZZZ_NOT_A_VARIABLE,N,TYPE,x,PDD-D-31';
  run;
  /* old era (frozen pcnr stand-in): names are the PCNR_ names */
  data work.t_old;
    length norm_psid $64 PCNR_AGE $20 PCNR_YEAR $20 PCNR_FRAIL $8 PCNR_CODE 8
           PCNR_ASA $8 PCNR_NOTE $40;
    norm_psid = 'Precede00001'; PCNR_AGE = '50'; PCNR_YEAR = '2018_2019'; PCNR_FRAIL = 'Y';
    PCNR_CODE = 7; PCNR_ASA = '2'; PCNR_NOTE = cats('CAN', 'ARY_OLD'); output;
    norm_psid = 'Precede00002'; PCNR_AGE = 'NULL'; PCNR_YEAR = '2019'; PCNR_FRAIL = 'N';
    PCNR_CODE = 12345678901; PCNR_ASA = 'null'; PCNR_NOTE = ''; output;
    norm_psid = 'Precede00003'; PCNR_AGE = ''; PCNR_YEAR = '2020'; PCNR_FRAIL = 'Y';
    PCNR_CODE = 0.5; PCNR_ASA = '3'; PCNR_NOTE = 'x'; output;
  run;
  %_mk_new(ds=work.t_s21);
    %_nrow(id=Precede10001, age=60, year=2023, frail=1, code=ABC1, asa=1, note=n21);
  run;
  %_mk_new(ds=work.t_s22);
    %_nrow(id=Precede20001, age=70, year=2024, frail=0, code=C1, asa=, note=NULL);
    %_nrow(id=Precede20002, age=NULL, year=2024, frail=1, code=C2, asa=NULL, note=only22);
    %_nrow(id=Precede20003, age=71, year=2024, frail=, code=, asa=4, note=keep22);
  run;
  %_mk_new(ds=work.t_s23);
    %_nrow(id=Precede20001, age=75, year=2025, frail=1, code=C9, asa=5, note=filled23);
    %_nrow(id=Precede20003, age=, year=2025, frail=1, code=C3, asa=4, note=other);
    %_nrow(id=Precede30001, age=80, year=2025, frail=0, code=C4, asa=2, note=only23);
  run;
  data pdd.pecan_id_case_map;
    length norm_psid $64 PRECEDE_STUDY_ID $64 ENCRYPTED_MRN $64 KEY_ERA $2 PECAN_ID 8
           PECAN_ID_KEY_ERA $2 SRC_UNIT $8 MRN_STATUS $8;
    %_mrow(id=Precede00001, psid=D0001, n=0001, era=K1, pid=1, pera=K1);
    %_mrow(id=Precede00002, psid=D0002, n=0002, era=K1, pid=2, pera=K1);
    %_mrow(id=Precede00003, psid=D0003, n=0003, era=K1, pid=3, pera=K1);
    %_mrow(id=Precede10001, psid=, n=0004, era=K2, pid=1000001, pera=K2);
    %_mrow(id=Precede20001, psid=, n=0005, era=K2, pid=1000002, pera=K2);
    %_mrow(id=Precede20002, psid=, n=0006, era=K2, pid=1000003, pera=K2);
    %_mrow(id=Precede20003, psid=, n=0007, era=K2, pid=1000004, pera=K2);
    %_mrow(id=Precede30001, psid=, n=0008, era=K2, pid=1000005, pera=K2);
  run;
  data pdd.pecan_id_registry;
    set pdd.pecan_id_case_map(keep=ENCRYPTED_MRN KEY_ERA PECAN_ID);
  run;
  data pdd.pecan_id_dup_link;
    pecan_id_a = 1; pecan_id_b = 2; output;
  run;
%mend _fixtures;

/* prepare: types, source maps, lengths, converted sources, conversion counts */
%macro _prep;
  %p18_load_types(decisions=&_dec);
  %p18_srcmap(src=work.t_old, kind=OLD, tag=old);
  %p18_srcmap(src=work.t_s21, kind=NEW, scode=s21, tag=s21);
  %p18_srcmap(src=work.t_s22, kind=NEW, scode=s22, tag=s22);
  %p18_srcmap(src=work.t_s23, kind=NEW, scode=s23, tag=s23);
  %p18_set_lengths(tags=old s21 s22 s23);
  %p18_build_source(src=work.t_old, out=work.b_old, tag=old);
  %p18_build_source(src=work.t_s21, out=work.b_s21, tag=s21);
  %p18_build_source(src=work.t_s22, out=work.b_s22, tag=s22);
  %p18_build_source(src=work.t_s23, out=work.b_s23, tag=s23);
%mend _prep;

%macro _typeconv_all;
  %p18_typeconv_reset;
  %p18_typeconv_add(tag=old);
  %p18_typeconv_add(tag=s21);
  %p18_typeconv_add(tag=s22);
  %p18_typeconv_add(tag=s23);
%mend _typeconv_all;

%macro _run_tests;
  %local _i _cmp;
  %_fixtures;
  %p18_qinit(ds=work.qc_comb_build);

  /* ---- T7 decisions loader ---------------------------------------------- */
  %p18_load_types(decisions=&_dec);
  %_expect_ok(case=T7_LOAD_TYPES_OK);
  %_chk(case=T7_SIX_MAPPED_VARIABLES, cond=%str(&_p18_nvars = 6), detail=%str(variable count));
  %_val(ds=work.p18_vars, var=decided_type, where=%str(pcnr_name = %'PCNR_AGE%'));
  %_chk(case=T7_UNPREFIXED_KEY_MATCHES_NUMERIC, cond=%str(&_v = N), detail=%str(AGE type));
  %_val(ds=work.p18_vars, var=decided_type, where=%str(pcnr_name = %'PCNR_CODE%'));
  %_chk(case=T7_LOWERCASE_PREFIXED_KEY_MATCHES_TEXT, cond=%str(&_v = C), detail=%str(CODE type));
  %_val(ds=work.p18_vars, var=decided_type, where=%str(pcnr_name = %'PCNR_ASA%'));
  %_chk(case=T7_CONDITIONAL_ROW_ACCEPTED_AS_NUMERIC, cond=%str(&_v = N), detail=%str(ASA type));
  %_val(ds=work.p18_vars, var=decided_type, where=%str(pcnr_name = %'PCNR_FRAIL%'));
  %_chk(case=T7_NOTE_ONLY_ROW_KEEPS_EXT_TYPE, cond=%str(&_v = C), detail=%str(FRAIL type));
  %p18_load_types(decisions=&_dec2);
  %_expect_fail(case=T7_UNKNOWN_DECISION_KEY_FAILS);
  data work.t_mapp;
    set pdd.name_map_ext end=_e;
    output;
    if _e then do;
      status = 'PENDING_DECISION';
      output;
    end;
  run;
  %p18_load_types(decisions=&_dec, map_ext=work.t_mapp);
  %_expect_fail(case=T7_PENDING_DECISION_ROW_FAILS);

  %_prep;
  %_expect_ok(case=T0_PREP_OK);

  /* ---- T1 char to num ---------------------------------------------------- */
  %_typeconv_all;
  %_cnt(ds=work.b_old, where=%str(missing(PCNR_AGE)));
  %_chk(case=T1_NULL_AND_BLANK_TO_MISSING, cond=%str(&_c = 2), detail=%str(missing count));
  %_val(ds=work.qc_comb_typeconv, var=n_null_as_missing,
        where=%str(pcnr_name = %'PCNR_AGE%' and s_code = %'old%'));
  %_chk(case=T1_NULL_CELLS_COUNTED, cond=%str(&_v = 1), detail=%str(null count));
  %_val(ds=work.qc_comb_typeconv, var=n_null_as_missing,
        where=%str(pcnr_name = %'PCNR_ASA%' and s_code = %'old%'));
  %_chk(case=T1_LOWERCASE_NULL_COUNTED, cond=%str(&_v = 1), detail=%str(null lowercase count));
  %p18_gate_conv;
  %_expect_ok(case=T1_CLEAN_CONVERSION_GATE_PASSES);
  data work.t1_old;
    set work.t_old;
    if norm_psid = 'Precede00001' then PCNR_AGE = '1.5';
    if norm_psid = 'Precede00003' then PCNR_AGE = 'abc';
  run;
  %p18_srcmap(src=work.t1_old, kind=OLD, tag=t1);
  %p18_build_source(src=work.t1_old, out=work.b_t1, tag=t1);
  %p18_typeconv_reset;
  %p18_typeconv_add(tag=t1);
  %_val(ds=work.b_t1, var=PCNR_AGE, where=%str(norm_psid = %'Precede00001%'));
  %_chk(case=T1_DECIMAL_PARSED, cond=%str(&_v = 1.5), num=1, detail=%str(1.5 not parsed));
  %_val(ds=work.qc_comb_typeconv, var=n_char_to_num_fail, where=%str(pcnr_name = %'PCNR_AGE%'));
  %_chk(case=T1_UNPARSEABLE_COUNTED, cond=%str(&_v = 1), detail=%str(failure count));
  %_cnt(ds=dictionary.columns,
        where=%str(libname = %'WORK%' and memname = %'QC_COMB_TYPECONV%' and index(upcase(name), %'RAW%') > 0));
  %_chk(case=T1_NO_VALUE_COLUMN_IN_QC, cond=%str(&_c = 0), detail=%str(raw column present));
  %p18_gate_conv;
  %_expect_fail(case=T1_UNPARSEABLE_VALUE_FAILS_GATE);
  %_typeconv_all;

  /* ---- T2 num to char ---------------------------------------------------- */
  %_cnt(ds=work.b_old, where=%str(PCNR_CODE = %'7%'));
  %_chk(case=T2_SEVEN_TO_TEXT, cond=%str(&_c = 1), detail=%str(7));
  %_cnt(ds=work.b_old, where=%str(PCNR_CODE = %'12345678901%'));
  %_chk(case=T2_LARGE_INTEGER_NO_EXPONENT, cond=%str(&_c = 1), detail=%str(12345678901));
  %_cnt(ds=work.b_old, where=%str(PCNR_CODE = %'0.5%'));
  %_chk(case=T2_FRACTION_KEPT, cond=%str(&_c = 1), detail=%str(0.5));
  %_cnt(ds=work.b_old, where=%str(index(upcase(PCNR_CODE), %'E%') > 0));
  %_chk(case=T2_NO_E_IN_ANY_RESULT, cond=%str(&_c = 0), detail=%str(exponent found));

  /* ---- T3 PDD-D-30 merge ------------------------------------------------- */
  %p18_d30_merge(a=work.b_s22, b=work.b_s23, out=work.m1);
  %_cnt(ds=work.m1);
  %_chk(case=T3_SHARED_CASE_ONCE_AND_ONE_SIDED_PASS_THROUGH, cond=%str(&_c = 4), detail=%str(merged rows));
  %_val(ds=work.m1, var=PCNR_YEAR, where=%str(norm_psid = %'Precede20001%'));
  %_chk(case=T3_YEAR_STAYS_S22, cond=%str(&_v = 2024), detail=%str(year changed));
  %_val(ds=work.m1, var=PCNR_AGE, where=%str(norm_psid = %'Precede20001%'));
  %_chk(case=T3_S22_KEPT_WHEN_BOTH_PRESENT, cond=%str(&_v = 70), detail=%str(age));
  %_val(ds=work.m1, var=PCNR_ASA, where=%str(norm_psid = %'Precede20001%'));
  %_chk(case=T3_BLANK_S22_FILLED_FROM_S23, cond=%str(&_v = 5), detail=%str(asa fill));
  %_val(ds=work.m1, var=PCNR_NOTE, where=%str(norm_psid = %'Precede20001%'));
  %_chk(case=T3_NULL_TEXT_S22_FILLED, cond=%str(&_v = filled23), detail=%str(note fill));
  %_cnt(ds=work.m1, where=%str(norm_psid = %'Precede30001%' and PCNR_NOTE = %'only23%'));
  %_chk(case=T3_S23_ONLY_CASE_PASSES_THROUGH, cond=%str(&_c = 1), detail=%str(s23 only));
  %_val(ds=work.qc_comb_d30, var=n_shared, where=%str(pcnr_name = %'PCNR_AGE%'));
  %_chk(case=T3_SHARED_COUNT_PER_COLUMN, cond=%str(&_v = 2), detail=%str(shared));
  %_val(ds=work.qc_comb_d30, var=n_conflict_kept_s22, where=%str(pcnr_name = %'PCNR_YEAR%'));
  %_chk(case=T3_YEAR_CONFLICTS_COUNTED, cond=%str(&_v = 2), detail=%str(year conflicts));
  %_val(ds=work.qc_comb_d30, var=n_conflict_kept_s22, where=%str(pcnr_name = %'PCNR_AGE%'));
  %_chk(case=T3_AGE_CONFLICT_COUNTED, cond=%str(&_v = 1), detail=%str(age conflicts));
  %_val(ds=work.qc_comb_d30, var=n_s22_missing_filled, where=%str(pcnr_name = %'PCNR_FRAIL%'));
  %_chk(case=T3_FRAIL_FILL_COUNTED, cond=%str(&_v = 1), detail=%str(frail fills));
  %_val(ds=work.qc_comb_d30, var=n_s22_missing_filled, where=%str(pcnr_name = %'PCNR_NOTE%'));
  %_chk(case=T3_NULL_FILL_COUNTED, cond=%str(&_v = 1), detail=%str(note fills));
  %_val(ds=work.qc_comb_d30, var=n_conflict_kept_s22, where=%str(pcnr_name = %'PCNR_ASA%'));
  %_chk(case=T3_EQUAL_VALUES_NOT_CONFLICT, cond=%str(&_v = 0), detail=%str(asa conflicts));

  /* ---- T4 stack and counts ----------------------------------------------- */
  %p18_stack(old=work.b_old, s21=work.b_s21, merged=work.m1, out=work.stk);
  %_cnt(ds=work.stk);
  %_chk(case=T4_STACK_COUNT_OLD_PLUS_NEW_MINUS_SHARED, cond=%str(&_c = 8), detail=%str(stack rows));
  %let _ovf = %sysfunc(pathname(work))\t_ov.csv;
  data _null_;
    file "&_ovf";
    put 'pair,expected_n_shared,id_min,id_max,rule,decision';
    put 's22_s23,2,1,2,EARLIER_WINS_GAPFILL,PDD-D-30';
  run;
  %p18_read_expected(file=&_ovf);
  %_expect_ok(case=T4_EXPECTED_SHARED_READ_FROM_CSV);
  %_chk(case=T4_EXPECTED_SHARED_VALUE, cond=%str(&_p18_exp_shared = 2), detail=%str(expected shared));
  %p18_read_expected(file=%sysfunc(pathname(work))\t_nofile.csv);
  %_expect_fail(case=T4_MISSING_OVERLAP_FILE_FAILS);
  data _null_;
    file "%sysfunc(pathname(work))\t_ov2.csv";
    put 'pair,expected_n_shared,id_min,id_max,rule,decision';
    put 's22_s23,abc,1,2,EARLIER_WINS_GAPFILL,PDD-D-30';
  run;
  %p18_read_expected(file=%sysfunc(pathname(work))\t_ov2.csv);
  %_expect_fail(case=T4_NON_NUMERIC_EXPECTED_FAILS);
  %p18_read_expected(file=&_ovf);
  %p18_gate_overlap(old=work.b_old, s21=work.b_s21, s22=work.b_s22, s23=work.b_s23, exp=&_p18_exp_shared);
  %_expect_ok(case=T4_OVERLAP_GATE_PASSES);
  %p18_gate_rows(ds=work.stk, n_old=3, n_s21=1, n_s22=3, n_s23=3, shared=2);
  %_expect_ok(case=T4_ROW_GATE_PASSES);
  data work.stk_dup;
    set work.stk work.stk(obs=1);
  run;
  %p18_gate_rows(ds=work.stk_dup, n_old=3, n_s21=1, n_s22=3, n_s23=3, shared=2);
  %_expect_fail(case=T4_REPEATED_CASE_FAILS);
  data work.s22_bad;
    set work.b_s22 end=_e;
    output;
    if _e then do;
      norm_psid = 'Precede10001';
      output;
    end;
  run;
  %p18_gate_overlap(old=work.b_old, s21=work.b_s21, s22=work.s22_bad, s23=work.b_s23, exp=&_p18_exp_shared);
  %_expect_fail(case=T4_S21_SHARING_WITH_S22_FAILS);
  data work.s21_bad;
    set work.b_s21;
    norm_psid = 'Precede00001';
  run;
  %p18_gate_overlap(old=work.b_old, s21=work.s21_bad, s22=work.b_s22, s23=work.b_s23, exp=&_p18_exp_shared);
  %_expect_fail(case=T4_OLD_SHARING_WITH_NEW_FAILS);

  /* ---- T5 id attach and T16 PDD-D-33 -------------------------------------- */
  %let PDD_K2_PSID_MODE = NORM;
  %p18_attach_ids(in=work.stk, map=pdd.pecan_id_case_map, out=work.att);
  %_expect_ok(case=T5_ATTACH_OK);
  %_val(ds=work.att, var=PECAN_ID, where=%str(norm_psid = %'Precede10001%'));
  %_chk(case=T5_PECAN_ID_FROM_CASE_MAP, cond=%str(&_v = 1000001), detail=%str(pecan id));
  %_val(ds=work.att, var=PECAN_ID_KEY_ERA, where=%str(norm_psid = %'Precede00002%'));
  %_chk(case=T5_KEY_ERA_FROM_CASE_MAP, cond=%str(&_v = K1), detail=%str(key era));
  %_cnt(ds=work.att, where=%str(KEY_ERA = %'K2%' and PRECEDE_STUDY_ID = norm_psid));
  %_chk(case=T5_K2_NORM_MODE_IS_NORMALIZED_FORM, cond=%str(&_c = 5), detail=%str(norm mode));
  %_cnt(ds=work.att, where=%str(KEY_ERA = %'K1%' and substr(PRECEDE_STUDY_ID, 1, 4) = %'D000%'));
  %_chk(case=T5_K1_KEEPS_DELIVERED_VALUE, cond=%str(&_c = 3), detail=%str(k1 psid));
  %let PDD_K2_PSID_MODE = DELIVERED;
  %p18_attach_ids(in=work.stk, map=pdd.pecan_id_case_map, out=work.att_d);
  %_expect_ok(case=T16_DELIVERED_PASSES);
  %_val(ds=work.att_d, var=PRECEDE_STUDY_ID, where=%str(norm_psid = %'Precede20001%'));
  %_chk(case=T5_K2_DELIVERED_MODE_IS_FIVE_DIGITS, cond=%str(&_v = 20001), detail=%str(delivered mode));
  %let PDD_K2_PSID_MODE = BLANK;
  %p18_attach_ids(in=work.stk, map=pdd.pecan_id_case_map, out=work.att_b);
  %_expect_ok(case=T16_BLANK_PASSES);
  %_cnt(ds=work.att_b, where=%str(KEY_ERA = %'K2%' and missing(PRECEDE_STUDY_ID)));
  %_chk(case=T5_K2_BLANK_MODE_IS_BLANK, cond=%str(&_c = 5), detail=%str(blank mode));
  %let PDD_K2_PSID_MODE = ;
  %p18_psid_mode;
  %_expect_ok(case=T16_EMPTY_USES_DECIDED_DEFAULT);
  %_chk(case=T16_EMPTY_BECOMES_NORM, cond=%str(&PDD_K2_PSID_MODE = NORM), detail=%str(default));
  %let PDD_K2_PSID_MODE = X;
  %p18_attach_ids(in=work.stk, map=pdd.pecan_id_case_map, out=work.att_x);
  %_expect_fail(case=T16_INVALID_MODE_STOPS);
  %_chk(case=T16_NOTHING_WRITTEN_ON_INVALID_MODE, cond=%str(%sysfunc(exist(work.att_x)) = 0), detail=%str(table written));
  %let PDD_K2_PSID_MODE = NORM;
  data work.map_short;
    set pdd.pecan_id_case_map;
    if norm_psid ne 'Precede30001';
  run;
  %p18_attach_ids(in=work.stk, map=work.map_short, out=work.att_n);
  %_expect_fail(case=T5_ROW_WITHOUT_CASE_MAP_ENTRY_FAILS);
  data work.map_dup;
    set pdd.pecan_id_case_map work.map_short(obs=1);
  run;
  %p18_attach_ids(in=work.stk, map=work.map_dup, out=work.att_u);
  %_expect_fail(case=T5_DUPLICATE_MAP_KEY_FAILS);
  data work.map_nopid;
    set pdd.pecan_id_case_map;
    if norm_psid = 'Precede30001' then PECAN_ID = .;
  run;
  %p18_attach_ids(in=work.stk, map=work.map_nopid, out=work.att_m);
  %_expect_fail(case=T5_MISSING_PECAN_ID_FAILS);

  /* ---- T8 order and T6 variable gate ---------------------------------------- */
  %p18_order_cols(in=work.att, out=work.final);
  %p18_gate_vars(ds=work.final, order=1);
  %_expect_ok(case=T8_ORDER_AND_VARIABLE_GATE_PASS);
  data work.f_ord;
    length PRECEDE_STUDY_ID $64 PECAN_ID 8;
    set work.final;
  run;
  %p18_gate_vars(ds=work.f_ord, order=1);
  %_expect_fail(case=T8_WRONG_COLUMN_ORDER_FAILS);
  data work.f_miss;
    set work.final(drop=PCNR_NOTE);
  run;
  %p18_gate_vars(ds=work.f_miss);
  %_expect_fail(case=T6_MISSING_VARIABLE_FAILS);
  data work.f_extra;
    set work.final;
    PCNR_EXTRA = 1;
  run;
  %p18_gate_vars(ds=work.f_extra);
  %_expect_fail(case=T6_EXTRA_PCNR_COLUMN_FAILS);
  data work.f_type;
    set work.final(rename=(PCNR_AGE=_a));
    PCNR_AGE = put(_a, 8.);
    drop _a;
  run;
  %p18_gate_vars(ds=work.f_type);
  %_expect_fail(case=T6_WRONG_TYPE_FAILS);
  data work.f_enc;
    set work.final;
    ENCRYPTED_MRN = 'x';
  run;
  %p18_gate_vars(ds=work.f_enc);
  %_expect_fail(case=T6_ENCRYPTED_COLUMN_FAILS);

  /* ---- T9 NO_DATA ------------------------------------------------------------- */
  data pdd.name_map_vars_coverage;
    length pcnr_name $64 status $16;
    set pdd.name_map_vars_ext(keep=pcnr_name);
    status = ifc(pcnr_name = 'PCNR_FRAIL', 'NO_DATA', 'DATA');
  run;
  data work.nd1;
    set work.final;
    PCNR_FRAIL = '';
  run;
  %p18_nodata_flags(ds=work.nd1);
  %_expect_ok(case=T9_NODATA_RECONCILES_WITH_COVERAGE);
  %_val(ds=work.p18_nodata, var=reconciled, where=%str(pcnr_name = %'PCNR_FRAIL%'));
  %_chk(case=T9_ALL_MISSING_VARIABLE_FLAGGED, cond=%str(&_v = OK), detail=%str(flag));
  %_cnt(ds=work.p18_nodata, where=%str(pcnr_name = %'PCNR_NOTE%'));
  %_chk(case=T9_VARIABLE_WITH_VALUES_NOT_FLAGGED, cond=%str(&_c = 0), detail=%str(note flagged));
  data work.cov2;
    set pdd.name_map_vars_coverage;
    if pcnr_name = 'PCNR_YEAR' then status = 'NO_DATA';
  run;
  %p18_nodata_flags(ds=work.nd1, cov=work.cov2);
  %_expect_fail(case=T9_COVERAGE_NODATA_WITH_DATA_FAILS);

  /* ---- T10 reconciliation --------------------------------------------------- */
  %p18_stats(ds=work.t_old, out=work._t_oldst, distinct=1);
  data work.t_prf;
    length variable $64 stat $16 n 8 var_class $16;
    set work._t_oldst;
    variable = pcnr_name;
    stat = 'N_DISTINCT';
    n = n_distinct;
    var_class = 'HIGH_CARD';
    keep variable stat n var_class;
  run;
  %p18_recon(comb=work.final, old=work.t_old, prf=work.t_prf, tag_old=old);
  %_expect_ok(case=T10_RECON_EXPLAINS_NULL_TO_MISSING);
  %_val(ds=work.p18_recon, var=delta_k1, where=%str(pcnr_name = %'PCNR_AGE%'));
  %_chk(case=T10_NULL_TO_MISSING_DELTA_SHOWN, cond=%str(&_v = -1), detail=%str(age delta));
  %_val(ds=work.p18_recon, var=delta_k1, where=%str(pcnr_name = %'PCNR_NOTE%'));
  %_chk(case=T10_K1_COUNTS_EQUAL_OLD, cond=%str(&_v = 0), detail=%str(note delta));
  %_val(ds=work.p18_recon, var=n_distinct_k1, where=%str(pcnr_name = %'PCNR_YEAR%'));
  %_chk(case=T10_DISTINCT_ON_K1_SLICE, cond=%str(&_v = 3), detail=%str(year distinct));
  data work.final_bad;
    set work.final;
    if norm_psid = 'Precede00001' then PCNR_NOTE = '';
  run;
  %p18_recon(comb=work.final_bad, old=work.t_old, prf=work.t_prf, tag_old=old);
  %_expect_fail(case=T10_UNEXPLAINED_DELTA_FAILS);

  /* ---- T12 read-only guard ---------------------------------------------------- */
  %p18_ro_start;
  %p18_ro_end;
  %_expect_ok(case=T12_UNCHANGED_COUNTS_PASS);
  data work.reg1;
    length ENCRYPTED_MRN $64 KEY_ERA $2 PECAN_ID 8;
    ENCRYPTED_MRN = cats('MRN', 'CANARY', '0009'); KEY_ERA = 'K2'; PECAN_ID = 99;
  run;
  proc append base=pdd.pecan_id_registry data=work.reg1 force;
  run;
  %p18_ro_end;
  %_expect_fail(case=T12_CHANGED_REGISTRY_COUNT_FAILS);

  /* ---- T11 backup ----------------------------------------------------------- */
  %_drop(ds=pdd.comb_none);
  %p18_backup_comb(ds=pdd.comb_none);
  %_chk(case=T11_NO_BACKUP_WHEN_NOTHING_TO_REPLACE, cond=%str(&_p18_bak_done = 0), detail=%str(backup taken));
  data pdd.comb_t;
    set work.final;
  run;
  %p18_backup_comb(ds=pdd.comb_t);
  %_chk(case=T11_BACKUP_TAKEN, cond=%str(&_p18_bak_done = 1), detail=%str(no backup));
  %_chk(case=T11_MEMBER_NAME_AT_MOST_32_BYTES, cond=%str(%length(&_p17_last_backup) <= 32), detail=%str(too long));
  proc compare base=pdd.comb_t compare=p17bak.&_p17_last_backup;
  run;
  %let _cmp = &sysinfo;
  %_chk(case=T11_BACKUP_EQUALS_REPLACED_TABLE, cond=%str(&_cmp = 0), detail=%str(copy differs));
  %let _x = %sysfunc(sleep(2));
  %p18_backup_comb(ds=pdd.comb_t);
  %_cnt(ds=dictionary.tables,
        where=%str(libname = %'P17BAK%' and index(memname, %'PCNRCMB_%') = 1));
  %_chk(case=T11_SECOND_BUILD_ADDS_SECOND_BACKUP, cond=%str(&_c = 2), detail=%str(backup count));

  /* ---- T13 mask ------------------------------------------------------------------ */
  %let _t13file = %sysfunc(pathname(work))\t13.csv;
  data work.t13;
    length pcnr_name $20 n 8;
    pcnr_name = 'a'; n = 0; output;
    n = 1; output;
    n = 10; output;
    n = 11; output;
  run;
  %p18_export(ds=work.t13, file=&_t13file, cols=pcnr_name n, numcols=n);
  data work.t13r;
    infile "&_t13file" dsd firstobs=2 truncover;
    length a $20 b $12;
    input a $ b $;
  run;
  %_cnt(ds=work.t13r, where=%str(b = %'<11%'));
  %_chk(case=T13_ONE_AND_TEN_MASKED, cond=%str(&_c = 2), detail=%str(masked rows));
  %_cnt(ds=work.t13r, where=%str(b = %'0%'));
  %_chk(case=T13_ZERO_NOT_MASKED, cond=%str(&_c = 1), detail=%str(zero));
  %_cnt(ds=work.t13r, where=%str(b = %'11%'));
  %_chk(case=T13_ELEVEN_NOT_MASKED, cond=%str(&_c = 1), detail=%str(eleven));
  %let _m5 = %p18_mask(5);
  %_chk(case=T13_MASK_MACRO_SMALL_COUNT, cond=%str(%length(&_m5) = 3), detail=%str(mask macro));

  /* ---- T14 QC staging ------------------------------------------------------------ */
  proc datasets lib=work nolist;
    delete qc_comb_: ;
  quit;
  %p18_qinit(ds=pdd.qc_comb_t14);
  %do _i = 1 %to 40;
    %p18_qadd(ds=pdd.qc_comb_t14, item=row&_i, n=&_i);
  %end;
  %p18_flush_qc;
  %_chk(case=T14_ONE_WRITE_FOR_FORTY_ROWS, cond=%str(&_p18_flush_writes = 1), detail=%str(writes));
  %_cnt(ds=pdd.qc_comb_t14);
  %_chk(case=T14_FORTY_ROWS_WRITTEN, cond=%str(&_c = 40), detail=%str(rows));

  /* ---- T15 canary and MRN scan ------------------------------------------------------- */
  %let _f_clean = %sysfunc(pathname(work))\t15_clean.txt;
  %let _f_seed = %sysfunc(pathname(work))\t15_seed.txt;
  data _null_;
    file "&_f_clean";
    put 'NOTE: nothing here, counts 40 and tokens only';
  run;
  data _null_;
    length _s $13;
    file "&_f_seed";
    _s = cats('MRN', 'CANARY', '0001');
    put 'seeded line ' _s $13. ' end';
  run;
  %global _scan_files;
  %let _scan_files = &_f_clean;
  %p18_scan_no_mrn(filesmv=_scan_files, out=work.sc1);
  %_expect_ok(case=T15_CLEAN_FILE_HAS_NO_HITS);
  %_chk(case=T15_CLEAN_HIT_COUNT_ZERO, cond=%str(&_p18_scan_hits = 0), detail=%str(hits));
  %let _scan_files = &_f_clean|&_f_seed;
  %p18_scan_no_mrn(filesmv=_scan_files, out=work.sc1);
  %_expect_fail(case=T15_SEEDED_FILE_FAILS);
  %_chk(case=T15_SEEDED_HIT_COUNT_ONE, cond=%str(&_p18_scan_hits = 1), detail=%str(hits));
%mend _run_tests;
%_run_tests;

/* ---- T17 no WARNING or ERROR lines, no canary in log or CSV ------------------------------ */
proc printto; run;

data work._t17_warn_check;
  length _n_warn 8 _n_err 8 _n_can 8;
  retain _n_warn 0 _n_err 0 _n_can 0;
  infile "&_test_log_path" lrecl=32767 end=_eof;
  input;
  if upcase(_infile_) =: 'WARNING' then _n_warn + 1;
  if upcase(_infile_) =: 'ERROR'
     and index(upcase(_infile_), 'TESTRESULT SUMMARY') = 0 then _n_err + 1;
  if index(upcase(_infile_), 'CANARY_OLD') > 0 then _n_can + 1;
  if index(upcase(_infile_), '[FAIL]') > 0 or index(upcase(_infile_), '[PASS]') > 0 then
    put _infile_;
  if _eof then do;
    call symputx('_t17_n_warn', _n_warn);
    call symputx('_t17_n_err', _n_err);
    call symputx('_t17_n_can', _n_can);
    output;
  end;
run;

%macro _t17_check;
  %if &_t17_n_warn = 0 and &_t17_n_err = 0 %then %_record(case=T17_NO_WARNINGS_OR_ERRORS_IN_LOG, result=PASS);
  %else %_record(case=T17_NO_WARNINGS_OR_ERRORS_IN_LOG, result=FAIL,
         detail=%str(&_t17_n_warn WARNING and &_t17_n_err ERROR lines found in test log));
  %if &_t17_n_can = 0 %then %_record(case=T17_NO_CHAR_CANARY_IN_LOG, result=PASS);
  %else %_record(case=T17_NO_CHAR_CANARY_IN_LOG, result=FAIL, detail=%str(canary text found in the log));
  %let _scan_files = &_test_log_path|&_t13file;
  %let _p18_failed = 0;
  %p18_scan_no_mrn(filesmv=_scan_files, out=work.sc2);
  %if &_p18_scan_hits = 0 %then %_record(case=T17_NO_FAKE_MRN_IN_LOG_OR_CSV, result=PASS);
  %else %_record(case=T17_NO_FAKE_MRN_IN_LOG_OR_CSV, result=FAIL, detail=%str(fake MRN found in log or CSV));
%mend _t17_check;
%_t17_check;

%macro _t0_check;
  %_restore_state;
  %if %length(&_saved_pdd_path) = 0 %then %do;
    %_chk(case=T0_PDD_LIBREF_RESTORED, cond=%str(%sysfunc(libref(pdd)) ne 0), detail=%str(pdd still assigned));
  %end;
  %else %do;
    %_chk(case=T0_PDD_LIBREF_RESTORED, cond=%str(%length(%sysfunc(pathname(pdd))) > 0), detail=%str(pdd not restored));
  %end;
  %_chk(case=T0_FAIL_MODE_RESTORED, cond=%str(&p18_fail_mode = &_saved_fail_mode), detail=%str(fail mode));
  %_chk(case=T0_K2_MODE_RESTORED, cond=%str(%length(&PDD_K2_PSID_MODE) = %length(&_saved_k2mode)), detail=%str(k2 mode));
%mend _t0_check;
%_t0_check;

%macro _final_summary;
  %if &_all_pass = 1 %then
    %put NOTE: [18_combine_test] TESTRESULT SUMMARY: ALL TESTS PASSED;
  %else
    %put ERROR: [18_combine_test] TESTRESULT SUMMARY: ONE OR MORE TESTS FAILED;
%mend _final_summary;
%_final_summary;
