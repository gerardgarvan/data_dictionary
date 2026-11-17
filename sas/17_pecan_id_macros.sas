/*==========================================================================
  File    : sas/17_pecan_id_macros.sas
  Phase   : 17 (PECAN_ID), plan 17-01
  Purpose : Shared macros for 17a (K1 join, PDD-D-32), 17b (K2, PDD-D-30)
            and the reserved link program. Macros only; the single open-code
            call at the end (%p17_init) declares globals and has no %if.
  Needs   : the calling program defines %fail_out(msg=) BEFORE calling any
            macro here, and (for the K1 join) %pdd_norm_psid from 00_config.sas.
  Globals : PDD_APPROVE_NEW_BASELINE (0 or 1), p17_fail_mode (ABORT or FLAG),
            _p17_failed, PDD_K1_SPINE_KEY, PDD_K1_HARM_KEY, PDD_K1_KEY_MODE.
  Never   : writes to libname g, deletes or rewrites pdd.pecan_id_registry or
            pdd.pecan_id_dup_link. Logs and QC carry counts only, never MRNs
            or IDs.
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance:
    C3  No open-code %if/%else outside %macro ... %mend
    C11 No macro keyword in a quoted PUT string
    C30 No semicolons in %put or %fail_out message text
    C31 No POINT= step; C32 no reserved words as PROC SQL column names
==========================================================================*/

/* ---- globals (defaults never overwrite a value already set) ----------- */
%macro p17_init;
  %if not %symexist(PDD_APPROVE_NEW_BASELINE) %then %do;
    %global PDD_APPROVE_NEW_BASELINE;
    %let PDD_APPROVE_NEW_BASELINE = 0;
  %end;
  %if not %symexist(p17_fail_mode) %then %do;
    %global p17_fail_mode;
    %let p17_fail_mode = ABORT;
  %end;
  %if not %symexist(_p17_failed) %then %do;
    %global _p17_failed;
    %let _p17_failed = 0;
  %end;
  %if not %symexist(PDD_K1_SPINE_KEY) %then %do;
    %global PDD_K1_SPINE_KEY;
    %let PDD_K1_SPINE_KEY = ;
  %end;
  %if not %symexist(PDD_K1_HARM_KEY) %then %do;
    %global PDD_K1_HARM_KEY;
    %let PDD_K1_HARM_KEY = ;
  %end;
  %if not %symexist(PDD_K1_KEY_MODE) %then %do;
    %global PDD_K1_KEY_MODE;
    %let PDD_K1_KEY_MODE = ;
  %end;
%mend p17_init;

/* ---- failure helper: ABORT calls %fail_out, FLAG only records --------- */
%macro p17_fail(msg=);
  %if %upcase(&p17_fail_mode) = FLAG %then %do;
    %let _p17_failed = 1;
    %put NOTE: [p17] expected failure recorded - &msg;
  %end;
  %else %do;
    %fail_out(msg=%str(&msg));
  %end;
%mend p17_fail;

/* ---- tiny QC table helpers: columns item, n, isfail ------------------- */
%macro p17_qinit(ds=);
  data &ds;
    length item $80 n 8 isfail 8;
    stop;
  run;
%mend p17_qinit;

%macro p17_qadd(ds=, item=, n=, fail=0);
  data work._p17_q1;
    length item $80 n 8 isfail 8;
    item = "&item";
    n = &n;
    isfail = &fail;
  run;
  proc append base=&ds data=work._p17_q1 force;
  run;
%mend p17_qadd;

/* Number of rows of a dataset into the global named by mv= */
%macro p17_nobs(ds=, mv=);
  %let &mv = 0;
  proc sql noprint;
    select count(*) into :&mv trimmed from &ds;
  quit;
%mend p17_nobs;

/* ---- QC dump: stack pdd.qc_pecan_id_<name> tables into one CSV --------
   tables= blank separated names without the pdd.qc_pecan_id_ prefix, file=
   full CSV path. Missing tables are skipped. Counts only, no MRNs or IDs.
   Called before an abort so the QC file always exists (QC first). */
%macro p17_dump_qc(tables=, file=);
  %local _i _t _n;
  data work._p17_dump;
    length source $24 item $80 n 8 isfail 8;
    stop;
  run;
  %let _n = %sysfunc(countw(&tables));
  %do _i = 1 %to &_n;
    %let _t = %scan(&tables, &_i);
    %if %sysfunc(exist(pdd.qc_pecan_id_&_t)) %then %do;
      data work._p17_dump1;
        length source $24;
        set pdd.qc_pecan_id_&_t;
        source = "&_t";
      run;
      proc append base=work._p17_dump data=work._p17_dump1 force;
      run;
    %end;
  %end;
  proc export data=work._p17_dump outfile="&file" dbms=csv replace;
  run;
%mend p17_dump_qc;

/* ---- usable MRN flag -------------------------------------------------- */
%macro p17_usable_mrn(in=, out=);
  data &out;
    set &in;
    mrn_usable = (strip(ENCRYPTED_MRN) ne '' and upcase(strip(ENCRYPTED_MRN)) ne 'NULL');
  run;
%mend p17_usable_mrn;

/* ---- K2 rank: in has ENCRYPTED_MRN and min_num, one row per MRN ------- */
%macro p17_rank_k2(in=, out=, base=1000000);
  data work._p17_rk0;
    set &in;
    _mn = coalesce(min_num, 1e15);
  run;
  proc sort data=work._p17_rk0;
    by _mn ENCRYPTED_MRN;
  run;
  data &out;
    set work._p17_rk0;
    length PECAN_ID 8;
    PECAN_ID = &base + _n_;
    drop _mn;
  run;
%mend p17_rank_k2;

/* ---- backup helpers ---------------------------------------------------- */
%macro p17_bak_lib;
  %if %sysfunc(libref(p17bak)) ne 0 %then %do;
    options dlcreatedir;
    libname p17bak base "&backup_path.";
    options nodlcreatedir;
  %end;
%mend p17_bak_lib;

%macro p17_stamp;
  %global _p17_stamp;
  data _null_;
    length s $20;
    s = tranwrd(put(datetime(), b8601dt15.), 'T', '_');
    call symputx('_p17_stamp', s, 'G');
  run;
%mend p17_stamp;

/* dated copy of any pdd table: &stem._yyyymmdd_hhmmss in the backup folder.
   Sets global _p17_last_backup (member name only). */
%macro p17_backup_table(ds=, stem=);
  %global _p17_last_backup;
  %p17_bak_lib;
  %p17_stamp;
  %let _p17_last_backup = &stem._&_p17_stamp;
  data p17bak.&_p17_last_backup;
    set &ds;
  run;
  %put NOTE: [p17] backup written - &_p17_last_backup;
%mend p17_backup_table;

%macro p17_backup;
  %p17_backup_table(ds=pdd.pecan_id_registry, stem=pecan_id_registry);
%mend p17_backup;

%macro p17_backup_link;
  %p17_backup_table(ds=pdd.pecan_id_dup_link, stem=pecan_id_dup_link);
%mend p17_backup_link;

/* latest backup member of a stem into global _p17_latest (blank when none) */
%macro p17_latest_backup(stem=);
  %global _p17_latest;
  %let _p17_latest = ;
  %p17_bak_lib;
  proc sql noprint;
    select max(memname) into :_p17_latest trimmed
    from dictionary.tables
    where libname = 'P17BAK' and memtype = 'DATA'
      and prxmatch(cats('/^', upcase("&stem"), '_\d{8}_\d{6}$/'), strip(memname)) > 0;
  quit;
%mend p17_latest_backup;

/* ---- registry must equal its latest backup before any append ---------- */
%macro p17_assert_backup_current;
  %local _n_reg _n_bak _n_d1 _n_d2 _n_diff;
  %let _n_bak = 0; %let _n_d1 = 0; %let _n_d2 = 0;
  %p17_latest_backup(stem=pecan_id_registry);
  %p17_nobs(ds=pdd.pecan_id_registry, mv=_n_reg);
  %if %length(&_p17_latest) = 0 %then %do;
    %if "&PDD_APPROVE_NEW_BASELINE" = "1" %then %do;
      %put NOTE: [p17] APPROVED NEW BASELINE - no backup existed, taking one;
      %p17_backup;
    %end;
    %else %do;
      %p17_fail(msg=%str(registry exists but no backup found, registry rows &_n_reg. Approve with PDD_APPROVE_NEW_BASELINE=1 to take a first backup));
    %end;
  %end;
  %else %do;
    %p17_nobs(ds=p17bak.&_p17_latest, mv=_n_bak);
    proc sql noprint;
      select count(*) into :_n_d1 trimmed from
        (select * from pdd.pecan_id_registry except select * from p17bak.&_p17_latest);
      select count(*) into :_n_d2 trimmed from
        (select * from p17bak.&_p17_latest except select * from pdd.pecan_id_registry);
    quit;
    %let _n_diff = %eval(&_n_d1 + &_n_d2);
    %if &_n_diff > 0 or &_n_reg ne &_n_bak %then %do;
      %if "&PDD_APPROVE_NEW_BASELINE" = "1" %then %do;
        %put NOTE: [p17] APPROVED NEW BASELINE - registry rows &_n_reg, backup rows &_n_bak, differing rows &_n_diff;
        %p17_backup;
      %end;
      %else %do;
        %p17_fail(msg=%str(registry differs from its latest backup - registry rows &_n_reg., backup rows &_n_bak., differing rows &_n_diff.. Nothing appended. Approve with PDD_APPROVE_NEW_BASELINE=1 only if you accept the registry as the new baseline));
      %end;
    %end;
    %else %put NOTE: [p17] registry equals its latest backup (&_n_reg rows);
  %end;
%mend p17_assert_backup_current;

/* ---- registry gate ------------------------------------------------------ */
%macro p17_gate_registry(reg=pdd.pecan_id_registry);
  %local _c1 _c2 _c3 _c4 _c5 _c6 _c7 _nbad;
  %let _c1=0; %let _c2=0; %let _c3=0; %let _c4=0; %let _c5=0; %let _c6=0; %let _c7=0;
  proc sql noprint;
    select count(*) into :_c1 trimmed from
      (select PECAN_ID from &reg group by PECAN_ID having count(*) > 1);
    select count(*) into :_c2 trimmed from
      (select ENCRYPTED_MRN from &reg where KEY_ERA = 'K2'
       group by ENCRYPTED_MRN having count(*) > 1);
    select count(*) into :_c3 trimmed from &reg
      where KEY_ERA = 'K1' and PECAN_ID >= 1000000;
    select count(*) into :_c4 trimmed from &reg
      where KEY_ERA = 'K2' and PECAN_ID < 1000001;
    select count(*) into :_c5 trimmed from &reg
      where strip(ENCRYPTED_MRN) = '' or upcase(strip(ENCRYPTED_MRN)) = 'NULL';
    select count(*) into :_c6 trimmed from &reg
      where KEY_ERA not in ('K1', 'K2') or missing(KEY_ERA);
    select count(*) into :_c7 trimmed from &reg
      where STATUS not in ('ACTIVE', 'SUPERSEDED') or missing(STATUS);
  quit;
  %p17_qinit(ds=pdd.qc_pecan_id_gate);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry duplicate PECAN_ID, n=&_c1, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry duplicate MRN within K2, n=&_c2, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry K1 ID at or above 1000000, n=&_c3, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry K2 ID below 1000001, n=&_c4, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry blank or NULL MRN stored, n=&_c5, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry KEY_ERA not K1 or K2, n=&_c6, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_gate, item=registry STATUS not ACTIVE or SUPERSEDED, n=&_c7, fail=1);
  %let _nbad = %eval(&_c1 + &_c2 + &_c3 + &_c4 + &_c5 + &_c6 + &_c7);
  %if &_nbad > 0 %then
    %p17_fail(msg=%str(registry gate FAILED - dup ID &_c1., dup K2 MRN &_c2., K1 ID too high &_c3., K2 ID too low &_c4., blank MRN &_c5., bad era &_c6., bad status &_c7.));
  %else %put NOTE: [p17] registry gate PASS;
%mend p17_gate_registry;

/* ---- case map gate ------------------------------------------------------ */
%macro p17_gate_casemap(map=pdd.pecan_id_case_map, reg=pdd.pecan_id_registry);
  %local _c1 _c2 _c3 _c4 _c5 _c6 _nbad;
  %let _c1=0; %let _c2=0; %let _c3=0; %let _c4=0; %let _c5=0; %let _c6=0;
  proc sql noprint;
    select count(*) into :_c1 trimmed from
      (select norm_psid from &map group by norm_psid having count(*) > 1);
    select count(*) into :_c2 trimmed from &map
      where KEY_ERA = 'K2' and MRN_STATUS = 'OK' and missing(PECAN_ID);
    select count(*) into :_c3 trimmed from &map
      where KEY_ERA = 'K1' and missing(PECAN_ID);
    select count(*) into :_c4 trimmed from &map m
      where KEY_ERA = 'K1' and not missing(PECAN_ID)
        and not exists (select 1 from &reg r
                        where r.PECAN_ID = m.PECAN_ID and r.KEY_ERA = 'K1');
    select count(*) into :_c5 trimmed from &map m
      where KEY_ERA = 'K2' and not missing(PECAN_ID)
        and not exists (select 1 from &reg r
                        where r.KEY_ERA = 'K2' and r.ENCRYPTED_MRN = m.ENCRYPTED_MRN
                          and (r.PECAN_ID = m.PECAN_ID
                               or r.LINKED_TO_PECAN_ID = m.PECAN_ID));
    select count(*) into :_c6 trimmed from &map
      where not missing(PECAN_ID) and missing(PECAN_ID_KEY_ERA);
  quit;
  %p17_qinit(ds=pdd.qc_pecan_id_casemap_gate);
  %p17_qadd(ds=pdd.qc_pecan_id_casemap_gate, item=case map repeated norm_psid, n=&_c1, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_casemap_gate, item=K2 case with usable MRN and no PECAN_ID, n=&_c2, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_casemap_gate, item=K1 case with no PECAN_ID, n=&_c3, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_casemap_gate, item=K1 PECAN_ID not in K1 registry, n=&_c4, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_casemap_gate, item=K2 MRN and PECAN_ID pair not in registry, n=&_c5, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_casemap_gate, item=PECAN_ID without PECAN_ID_KEY_ERA, n=&_c6, fail=1);
  %let _nbad = %eval(&_c1 + &_c2 + &_c3 + &_c4 + &_c5 + &_c6);
  %if &_nbad > 0 %then
    %p17_fail(msg=%str(case map gate FAILED - repeated case &_c1., unmapped K2 &_c2., K1 no ID &_c3., K1 not in registry &_c4., K2 pair not in registry &_c5., no era &_c6.));
  %else %put NOTE: [p17] case map gate PASS;
%mend p17_gate_casemap;

/* ---- PDD-D-30 dedupe over s21 s22 s23 (before any ID assignment) -------
   in : datasets with norm_psid and ENCRYPTED_MRN
   out: one row per normalized case (norm_psid, ENCRYPTED_MRN, SRC_UNIT,
        mrn_usable). s22 wins, s23 fills a blank or NULL s22 MRN.
   Globals: p17_n_shared p17_n_s21ov p17_n_within p17_n_blankid p17_n_filled
            p17_n_conflict p17_n_cases. QC rows in pdd.qc_pecan_id_d30
   Aborts (QC first) on s21 overlap, a case repeated within one file, or a
   blank norm_psid. The expected shared count is checked by the caller. */
%macro p17_pdd_d30_cases(s21=, s22=, s23=, out=);
  %global p17_n_shared p17_n_s21ov p17_n_within p17_n_blankid p17_n_filled
          p17_n_conflict p17_n_cases;
  %let p17_n_shared=0; %let p17_n_s21ov=0; %let p17_n_within=0;
  %let p17_n_blankid=0; %let p17_n_filled=0; %let p17_n_conflict=0;
  %let p17_n_cases=0;
  data work._p17_all;
    length SRC_UNIT $4 ENCRYPTED_MRN $64;
    set &s21(in=_a keep=norm_psid ENCRYPTED_MRN)
        &s22(in=_b keep=norm_psid ENCRYPTED_MRN)
        &s23(in=_c keep=norm_psid ENCRYPTED_MRN);
    if _a then SRC_UNIT = 's21';
    else if _b then SRC_UNIT = 's22';
    else SRC_UNIT = 's23';
  run;
  proc sql noprint;
    select count(*) into :p17_n_blankid trimmed from work._p17_all
      where strip(norm_psid) = '';
    create table work._p17_pc as
      select norm_psid, sum(SRC_UNIT = 's21') as n21, sum(SRC_UNIT = 's22') as n22,
             sum(SRC_UNIT = 's23') as n23
      from work._p17_all where strip(norm_psid) ne '' group by norm_psid;
    select count(*) into :p17_n_within trimmed from work._p17_pc
      where n21 > 1 or n22 > 1 or n23 > 1;
    select count(*) into :p17_n_s21ov trimmed from work._p17_pc
      where n21 > 0 and (n22 + n23) > 0;
    select count(*) into :p17_n_shared trimmed from work._p17_pc
      where n22 > 0 and n23 > 0 and n21 = 0;
  quit;
  %p17_qinit(ds=pdd.qc_pecan_id_d30);
  %p17_qadd(ds=pdd.qc_pecan_id_d30, item=blank norm_psid rows, n=&p17_n_blankid, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_d30, item=case repeated within one file, n=&p17_n_within, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_d30, item=s21 cases also in s22 or s23, n=&p17_n_s21ov, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_d30, item=shared s22 and s23 cases, n=&p17_n_shared, fail=0);
  %if %eval(&p17_n_blankid + &p17_n_within + &p17_n_s21ov) > 0 %then %do;
    %p17_fail(msg=%str(PDD-D-30 dedupe stopped - blank case IDs &p17_n_blankid., repeated within a file &p17_n_within., s21 overlap &p17_n_s21ov.. No ID assigned));
  %end;
  %else %do;
    proc sql noprint;
      create table work._p17_base as
        select norm_psid, SRC_UNIT, ENCRYPTED_MRN from work._p17_all
        where strip(norm_psid) ne '' and SRC_UNIT in ('s21', 's22')
        union all
        select a.norm_psid, a.SRC_UNIT, a.ENCRYPTED_MRN from work._p17_all a
        where a.SRC_UNIT = 's23' and a.norm_psid not in
          (select norm_psid from work._p17_all where SRC_UNIT = 's22');
      create table work._p17_b2 as
        select x.norm_psid, x.SRC_UNIT, x.ENCRYPTED_MRN as mrn_x, y.ENCRYPTED_MRN as mrn_y
        from work._p17_base x
        left join (select norm_psid, ENCRYPTED_MRN from work._p17_all where SRC_UNIT = 's23') y
          on x.norm_psid = y.norm_psid and x.SRC_UNIT = 's22';
    quit;
    data &out(keep=norm_psid ENCRYPTED_MRN SRC_UNIT mrn_usable) work._p17_d30flag(keep=_filled _conf);
      set work._p17_b2;
      length ENCRYPTED_MRN $64;
      _ux = (strip(mrn_x) ne '' and upcase(strip(mrn_x)) ne 'NULL');
      _uy = (strip(mrn_y) ne '' and upcase(strip(mrn_y)) ne 'NULL');
      _filled = 0;
      _conf = 0;
      ENCRYPTED_MRN = mrn_x;
      if SRC_UNIT = 's22' and not _ux and _uy then do;
        ENCRYPTED_MRN = mrn_y;
        _filled = 1;
      end;
      if _ux and _uy and strip(mrn_x) ne strip(mrn_y) then _conf = 1;
      mrn_usable = (strip(ENCRYPTED_MRN) ne '' and upcase(strip(ENCRYPTED_MRN)) ne 'NULL');
      output &out;
      output work._p17_d30flag;
    run;
    proc sql noprint;
      select sum(_filled), sum(_conf) into :p17_n_filled trimmed, :p17_n_conflict trimmed
        from work._p17_d30flag;
      select count(*) into :p17_n_cases trimmed from &out;
    quit;
    %p17_qadd(ds=pdd.qc_pecan_id_d30, item=blank s22 MRN filled from s23, n=&p17_n_filled, fail=0);
    %p17_qadd(ds=pdd.qc_pecan_id_d30, item=s22 and s23 MRN conflicts, n=&p17_n_conflict, fail=0);
    %p17_qadd(ds=pdd.qc_pecan_id_d30, item=cases after dedupe, n=&p17_n_cases, fail=0);
  %end;
%mend p17_pdd_d30_cases;

/* ======================== PDD-D-32 K1 join macros ===================== */

/* Joins the spine to the harmonized dataset on the surgery key named by
   PDD_K1_SPINE_KEY, PDD_K1_HARM_KEY, PDD_K1_KEY_MODE (norm or raw).
   out: one row per spine row (plus extra rows when a spine row matches more
   than one harmonized row, which the gate rejects): norm_psid,
   PRECEDE_STUDY_ID (as delivered), ENCRYPTED_MRN, YEAR, PECAN_ID,
   mrn_usable, MRN_STATUS, _p17_nmatch.
   Writes the join counts to pdd.qc_pecan_id_k1 and sets globals
   p17_n_spine p17_n_harm p17_n_m1 p17_n_m0 p17_n_m2 p17_n_missid
   p17_blank_mrn. The pecan_ID value is copied, never recomputed. */
%macro p17_k1_join(spine=, harm=, out=);
  %global p17_n_spine p17_n_harm p17_n_m1 p17_n_m0 p17_n_m2 p17_n_missid
          p17_blank_mrn;
  %local _mode;
  %let _mode = %upcase(&PDD_K1_KEY_MODE);
  %if %length(&PDD_K1_SPINE_KEY) = 0 or %length(&PDD_K1_HARM_KEY) = 0
      or %length(&_mode) = 0 %then %do;
    %p17_fail(msg=%str(K1 join key not set - set PDD_K1_SPINE_KEY, PDD_K1_HARM_KEY and PDD_K1_KEY_MODE from probe_xwalk3 section 1c));
  %end;
  %else %do;
  /* spine side */
  data work._p17_sp0;
    set &spine(keep=&PDD_K1_SPINE_KEY ENCRYPTED_MRN YEAR);
    _p17_sid = _n_;
  run;
  %pdd_norm_psid(in=work._p17_sp0, out=work._p17_sp1, idvar=&PDD_K1_SPINE_KEY);
  data work._p17_sp;
    set work._p17_sp1(rename=(&PDD_K1_SPINE_KEY=_p17_raw));
    length PRECEDE_STUDY_ID $64 _p17_k $200;
    PRECEDE_STUDY_ID = strip(vvaluex('_p17_raw'));
    %if &_mode = NORM %then %do;
      _p17_k = norm_psid;
    %end;
    %else %do;
      _p17_k = PRECEDE_STUDY_ID;
    %end;
    keep _p17_sid _p17_k norm_psid PRECEDE_STUDY_ID ENCRYPTED_MRN YEAR;
  run;
  /* harmonized side, read once */
  data work._p17_hm0;
    set &harm(keep=&PDD_K1_HARM_KEY pecan_ID);
    _p17_hid = _n_;
  run;
  %if &_mode = NORM %then %do;
    %pdd_norm_psid(in=work._p17_hm0, out=work._p17_hm1, idvar=&PDD_K1_HARM_KEY);
    data work._p17_hm;
      set work._p17_hm1;
      length _p17_k $200;
      _p17_k = norm_psid;
      keep _p17_hid _p17_k pecan_ID;
    run;
  %end;
  %else %do;
    data work._p17_hm;
      set work._p17_hm0;
      length _p17_k $200;
      _p17_k = strip(vvaluex("&PDD_K1_HARM_KEY"));
      keep _p17_hid _p17_k pecan_ID;
    run;
  %end;
  proc sql noprint;
    create table work._p17_cnt as
      select _p17_k, count(*) as nh from work._p17_hm
      where strip(_p17_k) ne '' group by _p17_k;
    create table work._p17_jn as
      select s.*, h.pecan_ID, coalesce(c.nh, 0) as _p17_nmatch
      from work._p17_sp s
      left join work._p17_hm h on s._p17_k = h._p17_k and strip(s._p17_k) ne ''
      left join work._p17_cnt c on s._p17_k = c._p17_k
      order by s._p17_sid;
  quit;
  %p17_usable_mrn(in=work._p17_jn, out=work._p17_jn2);
  data &out;
    set work._p17_jn2;
    length MRN_STATUS $8;
    MRN_STATUS = ifc(mrn_usable, 'OK', 'NO_MRN');
    drop _p17_k _p17_sid;
  run;
  %p17_nobs(ds=work._p17_sp, mv=p17_n_spine);
  %p17_nobs(ds=work._p17_hm0, mv=p17_n_harm);
  proc sql noprint;
    select count(*) into :p17_n_m1 trimmed from &out where _p17_nmatch = 1;
    select count(*) into :p17_n_m0 trimmed from &out where _p17_nmatch = 0;
    select count(*) into :p17_n_m2 trimmed from &out where _p17_nmatch > 1;
    select count(*) into :p17_n_missid trimmed from &out
      where _p17_nmatch >= 1 and missing(PECAN_ID);
    select count(*) into :p17_blank_mrn trimmed from &out where mrn_usable = 0;
  quit;
  %p17_qinit(ds=pdd.qc_pecan_id_k1);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=SPINE_ROWS, n=&p17_n_spine);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=HARMONIZED_ROWS, n=&p17_n_harm);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=SPINE_ROWS_MATCHING_EXACTLY_ONE, n=&p17_n_m1);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=SPINE_ROWS_MATCHING_NONE, n=&p17_n_m0);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=JOIN_ROWS_MATCHING_MORE_THAN_ONE, n=&p17_n_m2);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=MISSING_PECAN_ID, n=&p17_n_missid);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=BLANK_SPINE_MRN_ROWS, n=&p17_blank_mrn);
  %put NOTE: [p17] K1 join - spine &p17_n_spine, harmonized &p17_n_harm, exactly one &p17_n_m1, none &p17_n_m0, more than one &p17_n_m2, missing ID &p17_n_missid;
  %put NOTE: [p17] BLANK_SPINE_MRN_ROWS=&p17_blank_mrn;
  %end;
%mend p17_k1_join;

/* K1 gate: every spine row matches exactly one harmonized row and no
   pecan_ID is missing. QC rows first, then the verdict. */
%macro p17_gate_k1;
  %local _bad;
  %let _bad = 0;
  %if %length(&p17_n_spine) = 0 %then %let _bad = 1;
  %else %let _bad = %eval(
      (&p17_n_spine ne &p17_n_harm) + (&p17_n_spine ne &p17_n_m1)
      + (&p17_n_m0 > 0) + (&p17_n_m2 > 0) + (&p17_n_missid > 0));
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=K1_GATE_FAILED_CHECKS, n=&_bad, fail=1);
  %if &_bad > 0 %then
    %p17_fail(msg=%str(K1 join gate FAILED - spine &p17_n_spine., harmonized &p17_n_harm., exactly one &p17_n_m1., none &p17_n_m0., more than one &p17_n_m2., missing ID &p17_n_missid.. Nothing was written));
  %else %put NOTE: [p17] K1 join gate PASS (&p17_n_m1 rows one-to-one);
%mend p17_gate_k1;

/* Dup pairs: a spine MRN with more than one distinct K1 pecan_ID gives one
   pair per two IDs (pecan_id_a < pecan_id_b). in has ENCRYPTED_MRN,
   PECAN_ID, mrn_usable. Sets global p17_n_pairs. Counts only in the log. */
%macro p17_dup_pairs(in=, out=);
  %global p17_n_pairs;
  %let p17_n_pairs = 0;
  proc sql noprint;
    create table work._p17_mi as
      select ENCRYPTED_MRN as mrn, PECAN_ID as pid from &in
      where mrn_usable = 1 and not missing(PECAN_ID)
      group by ENCRYPTED_MRN, PECAN_ID;
    create table work._p17_pn as
      select PECAN_ID as pid, count(*) as n_surg from &in
      where not missing(PECAN_ID) group by PECAN_ID;
    create table work._p17_pp as
      select distinct x.pid as pecan_id_a, y.pid as pecan_id_b
      from work._p17_mi x, work._p17_mi y
      where x.mrn = y.mrn and x.pid < y.pid;
    create table &out as
      select p.pecan_id_a, p.pecan_id_b,
             'SPINE_MRN_MULTI_ID' as link_basis length=24,
             na.n_surg as n_surgeries_a, nb.n_surg as n_surgeries_b,
             today() as decided_on format=yymmdd10.
      from work._p17_pp p
      left join work._p17_pn na on p.pecan_id_a = na.pid
      left join work._p17_pn nb on p.pecan_id_b = nb.pid
      order by p.pecan_id_a, p.pecan_id_b;
    select count(*) into :p17_n_pairs trimmed from &out;
  quit;
  %put NOTE: [p17] dup pairs found - &p17_n_pairs;
%mend p17_dup_pairs;

/* Append-only: only pairs not yet in pdd.pecan_id_dup_link are appended,
   after a dated backup. Existing rows are never changed or deleted.
   Sets global p17_n_link_new (rows appended). */
%macro p17_append_dup_link(pairs=);
  %global p17_n_link_new;
  %let p17_n_link_new = 0;
  %if %sysfunc(exist(pdd.pecan_id_dup_link)) %then %do;
    proc sql noprint;
      create table work._p17_newpairs as
        select p.* from &pairs p
        where not exists (select 1 from pdd.pecan_id_dup_link l
                          where l.pecan_id_a = p.pecan_id_a
                            and l.pecan_id_b = p.pecan_id_b);
    quit;
  %end;
  %else %do;
    data work._p17_newpairs;
      set &pairs;
    run;
  %end;
  %p17_nobs(ds=work._p17_newpairs, mv=p17_n_link_new);
  %if &p17_n_link_new > 0 %then %do;
    %if %sysfunc(exist(pdd.pecan_id_dup_link)) %then %do;
      %p17_backup_link;
    %end;
    proc append base=pdd.pecan_id_dup_link data=work._p17_newpairs;
    run;
  %end;
  %put NOTE: [p17] dup link rows appended - &p17_n_link_new;
%mend p17_append_dup_link;

/* ---- registry column attributes (one definition, used by 17a and K2) -- */
%macro p17_reg_attrs;
  length PECAN_ID 8 ENCRYPTED_MRN $64 KEY_ERA $2 ASSIGNED_RUN 8 SOURCE $32
         LINKED_TO_PECAN_ID 8 LINK_SOURCE $64 STATUS $10;
  format ASSIGNED_RUN yymmdd10.;
%mend p17_reg_attrs;

/* K1 registry rows: one per distinct K1 pecan_ID, MRN = the usable spine MRN
   of its surgeries. PENDING DECISION counts (A13): IDs with more than one
   distinct usable MRN, IDs seen only on blank MRN rows. Globals
   p17_n_multi_mrn p17_n_only_blank. out is written only when both are 0. */
%macro p17_k1_reg_rows(in=, out=);
  %global p17_n_multi_mrn p17_n_only_blank;
  %let p17_n_multi_mrn = 0;
  %let p17_n_only_blank = 0;
  proc sql noprint;
    create table work._p17_km as
      select PECAN_ID as pid, count(distinct ENCRYPTED_MRN) as n_mrn,
             min(ENCRYPTED_MRN) as mrn1
      from &in where mrn_usable = 1 and not missing(PECAN_ID)
      group by PECAN_ID;
    select count(*) into :p17_n_multi_mrn trimmed from work._p17_km where n_mrn > 1;
    select count(distinct PECAN_ID) into :p17_n_only_blank trimmed from &in
      where not missing(PECAN_ID) and PECAN_ID not in (select pid from work._p17_km);
  quit;
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=PENDING_DECISION_ID_WITH_MORE_THAN_ONE_MRN, n=&p17_n_multi_mrn, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_k1, item=PENDING_DECISION_ID_ONLY_ON_BLANK_MRN_ROWS, n=&p17_n_only_blank, fail=1);
  %if %eval(&p17_n_multi_mrn + &p17_n_only_blank) = 0 %then %do;
    data &out;
      %p17_reg_attrs;
      set work._p17_km(rename=(pid=_pid mrn1=_mrn));
      PECAN_ID = _pid;
      ENCRYPTED_MRN = _mrn;
      KEY_ERA = 'K1';
      ASSIGNED_RUN = today();
      SOURCE = 'k1_harmonized_join';
      LINKED_TO_PECAN_ID = .;
      LINK_SOURCE = '';
      STATUS = 'ACTIVE';
      keep PECAN_ID ENCRYPTED_MRN KEY_ERA ASSIGNED_RUN SOURCE LINKED_TO_PECAN_ID
           LINK_SOURCE STATUS;
    run;
  %end;
%mend p17_k1_reg_rows;

/* ---- registry baseline guard (same pattern as 15a) ---------------------
   The registry must not be created silently. Call only when
   pdd.pecan_id_registry is absent. in= is the proposed registry.
   Without PDD_APPROVE_NEW_BASELINE=1: writes the proposed registry to
   propfile= (contains encrypted MRNs, stays in qc, never in git) and a masked
   counts summary (1-10 shown as <11) to sumfile=, creates NOTHING, then fails
   (ABORT mode: %fail_out). With approval: creates the registry and its first
   backup. */
%macro p17_registry_baseline(in=, propfile=, sumfile=);
  %local _n_rows _n_k1 _n_ids _n_mrns;
  %let _n_rows = 0; %let _n_k1 = 0; %let _n_ids = 0; %let _n_mrns = 0;
  %if "&PDD_APPROVE_NEW_BASELINE" = "1" %then %do;
    data pdd.pecan_id_registry;
      set &in;
    run;
    %p17_backup;
    %put NOTE: [p17] registry created by explicit approval (PDD_APPROVE_NEW_BASELINE=1) with its first backup;
  %end;
  %else %do;
    proc sql noprint;
      select count(*), sum(KEY_ERA = 'K1'), count(distinct PECAN_ID),
             count(distinct ENCRYPTED_MRN)
        into :_n_rows trimmed, :_n_k1 trimmed, :_n_ids trimmed, :_n_mrns trimmed
        from &in;
    quit;
    proc export data=&in outfile="&propfile" dbms=csv replace;
    run;
    data work._p17_bsum;
      length item $40 n_masked $12;
      item = 'PROPOSED_REGISTRY_ROWS';  n = &_n_rows; link mask; output;
      item = 'PROPOSED_K1_ROWS';        n = &_n_k1;   link mask; output;
      item = 'PROPOSED_DISTINCT_IDS';   n = &_n_ids;  link mask; output;
      item = 'PROPOSED_DISTINCT_MRNS';  n = &_n_mrns; link mask; output;
      keep item n_masked;
      return;
      mask:
        if n >= 1 and n <= 10 then n_masked = '<11';
        else n_masked = strip(put(n, 12.));
      return;
    run;
    proc export data=work._p17_bsum outfile="&sumfile" dbms=csv replace;
    run;
    %p17_fail(msg=%str(PENDING DECISION - registry baseline not approved. Proposed registry has &_n_rows. rows. Review the proposal and masked summary in qc then rerun with PDD_APPROVE_NEW_BASELINE=1. Registry not created));
  %end;
%mend p17_registry_baseline;

/* ---- K2 assignment (append-only). cases: norm_psid ENCRYPTED_MRN mrn_usable
   one row per deduped case. Known (MRN,K2) pairs keep their ID, unseen MRNs
   get max(K2 PECAN_ID)+rank (base when no K2 row exists). Order: registry
   must equal its latest backup, then append, then gate, then a new backup
   (so the next run finds the backup current). Globals: p17_n_k2_distinct
   p17_n_k2_known p17_n_k2_new p17_n_k2_appended. */
%macro p17_k2_append(cases=, base=1000000, source=pdd_17b_k2);
  %global p17_n_k2_distinct p17_n_k2_known p17_n_k2_new p17_n_k2_appended;
  %local _mx;
  %let _mx = ;
  %let p17_n_k2_new = 0; %let p17_n_k2_distinct = 0; %let p17_n_k2_known = 0;
  %let p17_n_k2_appended = 0;
  data work._p17_k2n;
    set &cases(keep=norm_psid ENCRYPTED_MRN mrn_usable where=(mrn_usable = 1));
    min_n = input(compress(norm_psid, , 'kd'), ?? 12.);
    keep ENCRYPTED_MRN min_n;
  run;
  proc sql noprint;
    create table work._p17_k2m as
      select ENCRYPTED_MRN, min(min_n) as min_num from work._p17_k2n
      group by ENCRYPTED_MRN;
    create table work._p17_k2new as
      select m.ENCRYPTED_MRN, m.min_num from work._p17_k2m m
      where not exists (select 1 from pdd.pecan_id_registry r
                        where r.KEY_ERA = 'K2' and r.ENCRYPTED_MRN = m.ENCRYPTED_MRN);
    select max(PECAN_ID) into :_mx trimmed from pdd.pecan_id_registry
      where KEY_ERA = 'K2';
  quit;
  %if %length(&_mx) = 0 or "&_mx" = "." %then %let _mx = &base;
  %p17_nobs(ds=work._p17_k2m, mv=p17_n_k2_distinct);
  %p17_nobs(ds=work._p17_k2new, mv=p17_n_k2_new);
  %let p17_n_k2_known = %eval(&p17_n_k2_distinct - &p17_n_k2_new);
  %if &p17_n_k2_new > 0 %then %do;
    %p17_assert_backup_current;
    %if &_p17_failed = 0 %then %do;
      %p17_rank_k2(in=work._p17_k2new, out=work._p17_k2rk, base=&_mx);
      data work._p17_k2rows;
        %p17_reg_attrs;
        set work._p17_k2rk(rename=(ENCRYPTED_MRN=_mrn));
        ENCRYPTED_MRN = _mrn;
        KEY_ERA = 'K2';
        ASSIGNED_RUN = today();
        SOURCE = "&source";
        LINKED_TO_PECAN_ID = .;
        LINK_SOURCE = '';
        STATUS = 'ACTIVE';
        keep PECAN_ID ENCRYPTED_MRN KEY_ERA ASSIGNED_RUN SOURCE LINKED_TO_PECAN_ID
             LINK_SOURCE STATUS;
      run;
      proc append base=pdd.pecan_id_registry data=work._p17_k2rows;
      run;
      %let p17_n_k2_appended = &p17_n_k2_new;
      %p17_gate_registry(reg=pdd.pecan_id_registry);
      %p17_backup;
    %end;
  %end;
  %put NOTE: [p17] K2 distinct MRNs &p17_n_k2_distinct, known &p17_n_k2_known, new &p17_n_k2_new, rows appended &p17_n_k2_appended;
%mend p17_k2_append;

/* ---- case map: K2 cases by (MRN,K2) lookup, K1 cases from the K1 join --- */
%macro p17_casemap(k1=, k2=, reg=, out=);
  proc sql noprint;
    create table work._p17_cm2 as
      select c.norm_psid, c.ENCRYPTED_MRN, c.SRC_UNIT, c.mrn_usable,
             r.PECAN_ID as pid, r.LINKED_TO_PECAN_ID as lk
      from &k2 c
      left join (select PECAN_ID, ENCRYPTED_MRN, LINKED_TO_PECAN_ID from &reg
                 where KEY_ERA = 'K2') r
        on c.mrn_usable = 1 and c.ENCRYPTED_MRN = r.ENCRYPTED_MRN;
  quit;
  data work._p17_cmk2;
    length norm_psid $64 PRECEDE_STUDY_ID $64 ENCRYPTED_MRN $64 KEY_ERA $2
           PECAN_ID 8 SRC_UNIT $8 MRN_STATUS $8 _lk 8;
    set work._p17_cm2;
    PRECEDE_STUDY_ID = '';
    KEY_ERA = 'K2';
    PECAN_ID = pid;
    _lk = 0;
    /* a K2 MRN linked to a K1 patient carries the K1 ID (PID-06, link program) */
    if not missing(lk) then do;
      PECAN_ID = lk;
      _lk = 1;
    end;
    MRN_STATUS = ifc(mrn_usable = 1, 'OK', 'NO_MRN');
    keep norm_psid PRECEDE_STUDY_ID ENCRYPTED_MRN KEY_ERA PECAN_ID SRC_UNIT MRN_STATUS _lk;
  run;
  data work._p17_cmk1;
    length norm_psid $64 PRECEDE_STUDY_ID $64 ENCRYPTED_MRN $64 KEY_ERA $2
           PECAN_ID 8 SRC_UNIT $8 MRN_STATUS $8 _lk 8;
    set &k1(keep=norm_psid PRECEDE_STUDY_ID ENCRYPTED_MRN PECAN_ID MRN_STATUS);
    KEY_ERA = 'K1';
    SRC_UNIT = 's09';
    _lk = 0;
  run;
  data &out;
    length PECAN_ID_KEY_ERA $2;
    set work._p17_cmk1 work._p17_cmk2;
    PECAN_ID_KEY_ERA = ifc(missing(PECAN_ID), '', ifc(_lk = 1, 'K1', KEY_ERA));
    keep norm_psid PRECEDE_STUDY_ID ENCRYPTED_MRN KEY_ERA PECAN_ID PECAN_ID_KEY_ERA
         SRC_UNIT MRN_STATUS;
  run;
%mend p17_casemap;

%p17_init;
