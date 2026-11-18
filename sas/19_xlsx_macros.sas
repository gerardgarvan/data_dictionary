%include "C:\data_dictionary\sas\18_combine_macros.sas";
/*==========================================================================
  File    : sas/19_xlsx_macros.sas
  Phase   : 19 (master data workbook PCNR_Master_Data_Nov_2026.xlsx), Wave 1
  Purpose : Shared macros for the Phase 19 probe and preflight (19a) and the
            synthetic test (19_xlsx_test). Wave 1 holds only what needs no
            decision: path guard, decision gate, QC staging, dataset probes
            P19-1..P19-8 (counts only), limits gate (XLS-02), free disk,
            allow-list gate, closed-file MRN scan, SAS-side speed benchmark.
            Wave 2 (decided PDD-D-35..44): %p19_keyset, %p19_columns (K3 keys
            first, then dataset order), %p19_stage (stage CSV and schema CSV),
            %p19_csv_records (quote-aware record count), %p19_expected (exact
            counts and a seeded sample row list). Only the decided values
            (DATES=SERIAL, SPECIAL=BLANK, ORDER=DICT, NODATA=INCLUDE) are
            implemented; the 19b program stops on any other value.
  Needs   : the calling program defines %fail_out(msg=) BEFORE calling any
            macro that can fail. The first statement above includes the
            Phase 18 macros (which include the Phase 17 macros): this file
            reuses %p18_export, %p18_nobs, %p18_ro_start, %p18_ro_end,
            %p18_scan_no_mrn.
  Globals : p19_fail_mode (ABORT or FLAG, FLAG only in the synthetic test),
            _p19_failed, _p19_guard_ok, _p19_dec_status, _p19_free_gb,
            _p19_nrows, _p19_ncols, _p19_nchar, _p19_nnum, _p19_enc,
            _p19_maxlen, _p19_nctrl, _p19_bench_secs, _p19_bench_est_min,
            _p19_flush_writes.
  Never   : writes to pdd except through %p19_flush_qc; writes the registry,
            dup link or case map; puts a cell value, an ID or an MRN in a log,
            QC table or CSV (names and counts only).
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance:
    C3  No open-code %if/%else outside %macro ... %mend
    C11 No macro keyword in a quoted PUT string
    C13 Macros defined before use
    C30 No semicolons in %put or %fail_out message text
    C31 No POINT= steps
    C32 No PROC SQL reserved words as column names (chk, not check)
    C33 No long member names
    C34 %unquote on cond parameters used in %if (none are used here)
    C35 GROUP BY only with a summary function
==========================================================================*/

/* ---- globals (defaults never overwrite a value already set) ----------- */
%macro p19_init;
  %if not %symexist(p19_fail_mode) %then %do;
    %global p19_fail_mode;
    %let p19_fail_mode = ABORT;
  %end;
  %if not %symexist(_p19_failed) %then %do;
    %global _p19_failed;
    %let _p19_failed = 0;
  %end;
  %global _p19_guard_ok _p19_dec_status _p19_free_gb _p19_nrows _p19_ncols
          _p19_nchar _p19_nnum _p19_enc _p19_maxlen _p19_nctrl
          _p19_bench_secs _p19_bench_est_min _p19_flush_writes
          _p19_keycols _p19_nexp _p19_csv_recs _p19_csv_lines;
%mend p19_init;

/* ---- failure helper: ABORT calls %fail_out, FLAG only records --------- */
%macro p19_fail(msg=);
  %if %upcase(&p19_fail_mode) = FLAG %then %do;
    %let _p19_failed = 1;
    %put NOTE: [p19] expected failure recorded - &msg;
  %end;
  %else %do;
    %fail_out(msg=%str(&msg));
  %end;
%mend p19_fail;

/* ---- QC staging: rows are kept in WORK (work.qc_xlsx_<name>) and written
   to pdd once by %p19_flush_qc (network share locks, Phase 17 lesson) ----- */
%macro p19_qinit(ds=);
  data work.%scan(&ds, -1, .);
    length item $80 n 8 isfail 8;
    stop;
  run;
%mend p19_qinit;

%macro p19_qadd(ds=, item=, n=, fail=0);
  data work._p19_q1;
    length item $80 n 8 isfail 8;
    item = "&item";
    n = &n;
    isfail = &fail;
  run;
  proc append base=work.%scan(&ds, -1, .) data=work._p19_q1 force;
  run;
%mend p19_qadd;

/* Writes every staged work.qc_xlsx_* table to pdd, one data step each. */
%macro p19_flush_qc;
  %local _fl_list _fl_i _fl_t _fl_n;
  %let _p19_flush_writes = 0;
  %let _fl_list = ;
  %if %sysfunc(libref(pdd)) ne 0 %then %do;
    %put NOTE: [p19] flush skipped - pdd not assigned;
    %return;
  %end;
  proc sql noprint;
    select memname into :_fl_list separated by ' '
    from dictionary.tables
    where libname = 'WORK' and memtype = 'DATA'
      and memname like 'QC_XLSX_%';
  quit;
  %let _fl_n = %sysfunc(countw(&_fl_list, %str( )));
  %do _fl_i = 1 %to &_fl_n;
    %let _fl_t = %scan(&_fl_list, &_fl_i, %str( ));
    data pdd.&_fl_t;
      set work.&_fl_t;
    run;
    %let _p19_flush_writes = %eval(&_p19_flush_writes + 1);
  %end;
  %put NOTE: [p19] QC flush - &_fl_n table(s) written to pdd;
%mend p19_flush_qc;

/* QC dump: stack work.qc_xlsx_<name> tables into one masked CSV. Counts only. */
%macro p19_dump_qc(tables=, file=);
  %local _i _t;
  data work._p19_dump;
    length tbl $32 item $80 n 8 isfail 8;
    stop;
  run;
  %do _i = 1 %to %sysfunc(countw(&tables, %str( )));
    %let _t = %scan(&tables, &_i, %str( ));
    %if %sysfunc(exist(work.qc_xlsx_&_t)) %then %do;
      data work._p19_d1;
        length tbl $32;
        set work.qc_xlsx_&_t;
        tbl = "&_t";
      run;
      proc append base=work._p19_dump data=work._p19_d1 force;
      run;
    %end;
  %end;
  %p18_export(ds=work._p19_dump, file=&file, cols=tbl item n isfail, numcols=n);
%mend p19_dump_qc;

/* ---- path guard: the path must start with &out_root (then end or a
   backslash), must not hold the shared data folder, must not hold .. ------- */
%macro p19_path_guard(path=);
  %let _p19_guard_ok = 0;
  data _null_;
    length p r $1024;
    p = lowcase(translate(strip("&path"), '\', '/'));
    r = lowcase(strip("&out_root"));
    ok = 1;
    if lengthn(r) = 0 or lengthn(p) < lengthn(r) then ok = 0;
    else if substr(p, 1, lengthn(r)) ne r then ok = 0;
    else if lengthn(p) > lengthn(r) then do;
      if char(p, lengthn(r) + 1) ne '\' then ok = 0;
    end;
    if index(p, '00 shared data') > 0 then ok = 0;
    if index(p, '..') > 0 then ok = 0;
    call symputx('_p19_guard_ok', ok, 'G');
  run;
  %if &_p19_guard_ok ne 1 %then
    %p19_fail(msg=%str(path guard - a target path is outside out_root or inside the shared Master Data folder or holds a parent reference));
%mend p19_path_guard;

/* ---- decision gate: var = name of a config macro variable. allowed = blank
   separated valid values (empty list: any non-empty value is accepted). An
   empty value gives status EMPTY and, with stop=1, PENDING DECISION. A value
   outside the list always fails (status INVALID). ------------------------- */
%macro p19_need_decision(var=, allowed=, stop=1);
  %local _v _i _a _hit;
  %let _p19_dec_status = EMPTY;
  %let _v = ;
  %if %symexist(&var) %then %let _v = %qupcase(%qtrim(%qleft(%superq(&var))));
  %if %length(&_v) = 0 %then %do;
    %put NOTE: [p19] PENDING DECISION: &var is empty;
    %if &stop = 1 %then %p19_fail(msg=%str(PENDING DECISION: &var is empty));
    %return;
  %end;
  %if %length(%superq(allowed)) = 0 %then %do;
    %let _p19_dec_status = SET;
    %return;
  %end;
  %let _hit = 0;
  %do _i = 1 %to %sysfunc(countw(&allowed, %str( )));
    %let _a = %upcase(%scan(&allowed, &_i, %str( )));
    %if "&_v" = "&_a" %then %let _hit = 1;
  %end;
  %if &_hit = 1 %then %let _p19_dec_status = SET;
  %else %do;
    %let _p19_dec_status = INVALID;
    %p19_fail(msg=%str(&var has a value outside the allowed list: &allowed));
  %end;
%mend p19_need_decision;

/* ---- PDD-D-43 key set: code -> blank separated column list in mv (caller declares it).
   K3 = PECAN_ID PRECEDE_STUDY_ID KEY_ERA. K4 adds PECAN_ID_KEY_ERA. Any
   other code fails. NORM_PSID is never exported. ------------------------- */
%macro p19_keyset(code=, mv=_p19_keycols);
  %local _c;
  %let _c = %upcase(%sysfunc(strip(&code)));
  %let &mv = ;
  %if "&_c" = "K3" %then %let &mv = PECAN_ID PRECEDE_STUDY_ID KEY_ERA;
  %else %if "&_c" = "K4" %then %let &mv = PECAN_ID PRECEDE_STUDY_ID PECAN_ID_KEY_ERA KEY_ERA;
  %else %p19_fail(msg=%str(unknown PDD_XLS_KEYS value: &code));
%mend p19_keyset;

/* ---- mask for exports: 1-10 becomes <11. A count within 10 of its total
   (total - n between 1 and 10) is top-coded as >(total-11), because the
   complement would otherwise give the small count back. MAXLEN is a length,
   not a count of cells, and stays exact. in needs chk, n, tot. ----------- */
%macro p19_mask_ds(in=, out=);
  data &out;
    length n_masked $12;
    set &in;
    if chk = 'MAXLEN' then n_masked = strip(put(n, best12.));
    else if n >= 1 and n <= 10 then n_masked = '<11';
    else if tot - n >= 1 and tot - n <= 10 then n_masked = '>' || strip(put(max(tot - 11, 0), best12.));
    else n_masked = strip(put(n, best12.));
  run;
%mend p19_mask_ds;

/* ---- dataset facts: logical rows, columns, encoding, char and num counts --- */
%macro p19_dataset_facts(ds=);
  %local _lib _mem;
  %let _lib = %upcase(%scan(&ds, 1, .));
  %let _mem = %upcase(%scan(&ds, 2, .));
  %let _p19_nrows = 0;
  %let _p19_ncols = 0;
  %let _p19_nchar = 0;
  %let _p19_nnum = 0;
  %let _p19_enc = unknown;
  proc sql noprint;
    select nlobs, nvar, strip(encoding)
      into :_p19_nrows trimmed, :_p19_ncols trimmed, :_p19_enc trimmed
    from dictionary.tables
    where libname = "&_lib" and memname = "&_mem" and memtype = 'DATA';
    select coalesce(sum(upcase(type) = 'CHAR'), 0), coalesce(sum(upcase(type) = 'NUM'), 0)
      into :_p19_nchar trimmed, :_p19_nnum trimmed
    from dictionary.columns
    where libname = "&_lib" and memname = "&_mem";
  quit;
%mend p19_dataset_facts;

/* ---- P19-1 to P19-5 and P19-8 probes: one pass, counts only ---------------
   Character variables (per variable): MAXLEN (max trimmed length in
   characters), CTRL (cells with an Excel-illegal control character 00-08,
   0B, 0C, 0E-1F), LEAD_EQ / LEAD_HASH / LEAD_PLUS / LEAD_MINUS / LEAD_AT
   (first character), GT255, LEAD_ZERO (digits only, first digit 0, longer than
   1), NONASCII (character count differs from byte count), NEWLINE (LF or CR
   inside), NONBLANK, REPLCHAR (the Unicode replacement character, a sign of
   lossy transcoding).
   Numeric variables: NONMISS, GE_1E15, NO_15SIG_ROUNDTRIP (a non-integer
   whose 15 significant digit text does not read back to the same double),
   INT_IN_DATE_RANGE (integer 1 to 80000), INT_IN_DTTM_RANGE (integer 1e9 to
   5e9), SPECIAL_A .. SPECIAL_Z and SPECIAL__ (special missing .A-.Z, ._).
   Only counts above 0 are written. out: variable, chk, n, vtype (CHAR/NUM),
   tot (dataset rows). The step reads the dataset once. ------------------- */
%macro p19_probe(ds=, out=work.p19_pr);
  %local _nc _nn;
  %p19_dataset_facts(ds=&ds);
  %let _nc = &_p19_nchar;
  %let _nn = &_p19_nnum;
  %if &_p19_nrows = 0 %then %do;
    %p19_fail(msg=%str(probe input has no rows));
    %return;
  %end;
  data work._p19_pc(keep=_pvar _pchk _pn) work._p19_pn(keep=_pvar _pchk _pn);
    set &ds;
    %if &_nc > 0 %then %do;
      array _c{*} _character_;
      array cc{&_nc, 13} _temporary_ (%eval(&_nc * 13) * 0);
    %end;
    %if &_nn > 0 %then %do;
      array _nm{*} _numeric_;
      array nn{&_nn, 32} _temporary_ (%eval(&_nn * 32) * 0);
      array sp{27} _temporary_ (.A .B .C .D .E .F .G .H .I .J .K .L .M .N .O .P .Q .R .S .T .U .V .W .X .Y .Z ._);
    %end;
    length _pvar $64 _pchk $40 _ps $40 _pc1 $1;
    %if &_nc > 0 %then %do;
      do _pi = 1 to dim(_c);
        if _c{_pi} ne '' then do;
          cc{_pi, 12} = cc{_pi, 12} + 1;
          _pl = klength(trimn(_c{_pi}));
          if _pl > cc{_pi, 1} then cc{_pi, 1} = _pl;
          if findc(_c{_pi}, '01020304050607080B0C0E0F101112131415161718191A1B1C1D1E1F'x) > 0
             or index(_c{_pi}, '00'x) > 0 then cc{_pi, 2} = cc{_pi, 2} + 1;
          _pc1 = char(_c{_pi}, 1);
          _pk = index('=#+-@', _pc1);
          if _pk > 0 and _pc1 ne ' ' then cc{_pi, 2 + _pk} = cc{_pi, 2 + _pk} + 1;
          if _pl > 255 then cc{_pi, 8} = cc{_pi, 8} + 1;
          if _pc1 = '0' and _pl > 1 then do;
            if notdigit(trimn(_c{_pi})) = 0 then cc{_pi, 9} = cc{_pi, 9} + 1;
          end;
          if length(_c{_pi}) ne _pl then cc{_pi, 10} = cc{_pi, 10} + 1;
          if findc(_c{_pi}, '0A0D'x) > 0 then cc{_pi, 11} = cc{_pi, 11} + 1;
          if index(_c{_pi}, 'EFBFBD'x) > 0 then cc{_pi, 13} = cc{_pi, 13} + 1;
        end;
      end;
    %end;
    %if &_nn > 0 %then %do;
      do _pi = 1 to dim(_nm);
        _pv = _nm{_pi};
        if missing(_pv) then do;
          if _pv ne . then do;
            do _pk = 1 to 27;
              if _pv = sp{_pk} then do;
                nn{_pi, 5 + _pk} = nn{_pi, 5 + _pk} + 1;
                leave;
              end;
            end;
          end;
        end;
        else do;
          nn{_pi, 1} = nn{_pi, 1} + 1;
          if abs(_pv) >= 1e15 then nn{_pi, 2} = nn{_pi, 2} + 1;
          if _pv = int(_pv) then do;
            if _pv >= 1 and _pv <= 80000 then nn{_pi, 4} = nn{_pi, 4} + 1;
            if _pv >= 1e9 and _pv <= 5e9 then nn{_pi, 5} = nn{_pi, 5} + 1;
          end;
          else if abs(_pv) < 1e15 then do;
            _ps = put(_pv, e22.14);
            if input(_ps, best32.) ne _pv then nn{_pi, 3} = nn{_pi, 3} + 1;
          end;
        end;
      end;
    %end;
    if _n_ = &_p19_nrows then do;
      %if &_nc > 0 %then %do;
        do _pi = 1 to dim(_c);
          _pvar = vname(_c{_pi});
          do _pj = 1 to 13;
            if cc{_pi, _pj} > 0 then do;
              _pchk = scan('MAXLEN CTRL LEAD_EQ LEAD_HASH LEAD_PLUS LEAD_MINUS LEAD_AT GT255 LEAD_ZERO NONASCII NEWLINE NONBLANK REPLCHAR', _pj, ' ');
              _pn = cc{_pi, _pj};
              output work._p19_pc;
            end;
          end;
        end;
      %end;
      %if &_nn > 0 %then %do;
        do _pi = 1 to dim(_nm);
          _pvar = vname(_nm{_pi});
          do _pj = 1 to 32;
            if nn{_pi, _pj} > 0 then do;
              if _pj <= 5 then _pchk = scan('NONMISS GE_1E15 NO_15SIG_ROUNDTRIP INT_IN_DATE_RANGE INT_IN_DTTM_RANGE', _pj, ' ');
              else _pchk = cats('SPECIAL_', substr('ABCDEFGHIJKLMNOPQRSTUVWXYZ_', _pj - 5, 1));
              _pn = nn{_pi, _pj};
              output work._p19_pn;
            end;
          end;
        end;
      %end;
    end;
  run;
  data &out;
    length variable $64 chk $40 n 8 vtype $4 tot 8;
    set work._p19_pc(in=_inc rename=(_pvar=variable _pchk=chk _pn=n))
        work._p19_pn(rename=(_pvar=variable _pchk=chk _pn=n));
    if _inc then vtype = 'CHAR';
    else vtype = 'NUM';
    tot = &_p19_nrows;
  run;
%mend p19_probe;

/* ---- P19-6 key columns: KEY_ERA x PECAN_ID_KEY_ERA and NORM_PSID versus
   PRECEDE_STUDY_ID. Counts only. tot is the row count of the KEY_ERA group, so
   the top-code rule closes the complement inside a group. out: variable, chk,
   n, vtype (KEY), tot. -------------------------------------------------- */
%macro p19_keys(ds=, out=work.p19_pr_k);
  proc sql noprint;
    create table work._p19_kx as
      select KEY_ERA as era length=8, PECAN_ID_KEY_ERA as pera length=8, count(*) as n
      from &ds
      group by KEY_ERA, PECAN_ID_KEY_ERA;
    create table work._p19_kt as
      select KEY_ERA as era length=8, count(*) as tot,
             sum(strip(NORM_PSID) ne strip(PRECEDE_STUDY_ID)) as ndiff
      from &ds
      group by KEY_ERA;
    create table work._p19_kj as
      select x.era, x.pera, x.n, t.tot, t.ndiff
      from work._p19_kx x inner join work._p19_kt t on x.era = t.era
      order by x.era, x.pera;
  quit;
  data &out;
    length variable $64 chk $40 n 8 vtype $4 tot 8;
    set work._p19_kj;
    variable = 'KEYS';
    vtype = 'KEY';
    chk = cats('XTAB_', compress(era, , 'kad'), '_', compress(pera, , 'kad'));
    keep variable chk n vtype tot;
  run;
  data work._p19_kd;
    length variable $64 chk $40 n 8 vtype $4 tot 8;
    set work._p19_kt;
    variable = 'KEYS';
    vtype = 'KEY';
    chk = cats('ERA_ROWS_', compress(era, , 'kad'));
    n = tot;
    output;
    chk = cats('PSID_DIFFERS_', compress(era, , 'kad'));
    n = ndiff;
    output;
    keep variable chk n vtype tot;
  run;
  proc append base=&out data=work._p19_kd force;
  run;
%mend p19_keys;

/* ---- probe report: masked detail CSV (variable, chk, vtype, n_masked) and
   masked summary CSV per check (chk, vtype, n_variables, max_n). The summary
   has no sums, so a masked cell cannot be recovered from detail and summary
   together. NONBLANK and NONMISS rows stay in the detail only. ----------- */
%macro p19_probe_report(in=, detail=, summary=);
  %p19_mask_ds(in=&in, out=work._p19_pm);
  %p18_export(ds=work._p19_pm, file=&detail, cols=variable chk vtype n_masked, numcols=);
  proc sql noprint;
    create table work._p19_sm as
      select chk, vtype, count(distinct variable) as nv, max(n) as mx, max(tot) as tot
      from &in
      where chk not in ('NONBLANK', 'NONMISS') and vtype in ('CHAR', 'NUM')
      group by chk, vtype
      order by vtype, chk;
  quit;
  data work._p19_sm2;
    length n_variables $12 max_n $12;
    set work._p19_sm;
    if nv >= 1 and nv <= 10 then n_variables = '<11';
    else n_variables = strip(put(nv, best12.));
    if chk = 'MAXLEN' then max_n = strip(put(mx, best12.));
    else if mx >= 1 and mx <= 10 then max_n = '<11';
    else if tot - mx >= 1 and tot - mx <= 10 then max_n = '>' || strip(put(max(tot - 11, 0), best12.));
    else max_n = strip(put(mx, best12.));
  run;
  %p18_export(ds=work._p19_sm2, file=&summary, cols=chk vtype n_variables max_n, numcols=);
%mend p19_probe_report;

/* ---- values the limits gate needs, from the probe table ------------------ */
%macro p19_probe_gate_inputs(in=work.p19_pr);
  %let _p19_maxlen = 0;
  %let _p19_nctrl = 0;
  proc sql noprint;
    select coalesce(max(n), 0) into :_p19_maxlen trimmed from &in where chk = 'MAXLEN';
    select coalesce(sum(n), 0) into :_p19_nctrl trimmed from &in where chk = 'CTRL';
  quit;
%mend p19_probe_gate_inputs;

/* ---- XLS-02 limits gate. rows, cols, maxlen, nctrl, freegb are numbers
   (freegb = -1: not measurable, recorded and not failed, check by hand). One
   QC row per limit, then one failure at the end if any limit is broken. ---- */
%macro p19_limits(rows=, cols=, maxlen=, nctrl=, freegb=, mingb=, qc=,
                  rowlim=1048575, collim=16384, lenlim=32767);
  %global _p19_lf1 _p19_lf2 _p19_lf3 _p19_lf4 _p19_lf5 _p19_free_int;
  data _null_;
    f1 = (&rows + 1 >= &rowlim);
    f2 = (&cols >= &collim);
    f3 = (&maxlen > &lenlim);
    f4 = (&nctrl > 0);
    f5 = (&freegb >= 0 and &freegb < &mingb);
    call symputx('_p19_lf1', f1, 'G');
    call symputx('_p19_lf2', f2, 'G');
    call symputx('_p19_lf3', f3, 'G');
    call symputx('_p19_lf4', f4, 'G');
    call symputx('_p19_lf5', f5, 'G');
    call symputx('_p19_free_int', floor(&freegb), 'G');
  run;
  %p19_qadd(ds=&qc, item=limit_rows_plus_header, n=%eval(&rows + 1), fail=&_p19_lf1);
  %p19_qadd(ds=&qc, item=limit_columns, n=&cols, fail=&_p19_lf2);
  %p19_qadd(ds=&qc, item=limit_max_trimmed_text_length, n=&maxlen, fail=&_p19_lf3);
  %p19_qadd(ds=&qc, item=limit_cells_with_illegal_control_char, n=&nctrl, fail=&_p19_lf4);
  %p19_qadd(ds=&qc, item=limit_free_disk_gb_min, n=&_p19_free_int, fail=&_p19_lf5);
  %if &freegb < 0 %then %do;
    %p19_qadd(ds=&qc, item=free_disk_not_measurable_check_by_hand, n=1);
    %put NOTE: [p19] free disk not measurable in this session - check free space by hand;
  %end;
  %if &_p19_lf1 + &_p19_lf2 + &_p19_lf3 + &_p19_lf4 + &_p19_lf5 > 0 %then
    %p19_fail(msg=%str(limits gate failed - see the limit rows in the qc table. A control character or over-long text is a PENDING DECISION: strip or abort));
%mend p19_limits;

/* ---- free space: parse the last line of "dir /-c" output ('bytes free') ----
   fileref = a fileref holding the dir output. mv = global macro variable that
   receives whole GB, -1 when the line is absent. ----------------------- */
%macro p19_freegb_parse(fileref=, mv=);
  %let &mv = -1;
  data _null_;
    length _l _t _w $1000;
    infile &fileref truncover lrecl=1000;
    input _l $char1000.;
    _p = index(lowcase(_l), 'bytes free');
    if _p > 1 then do;
      _t = strip(substr(_l, 1, _p - 1));
      _w = compress(scan(_t, -1, ' '), , 'kd');
      _b = input(_w, ?? best32.);
      if not missing(_b) then call symputx("&mv", strip(put(floor(_b / 1024 / 1024 / 1024), best12.)), 'G');
    end;
  run;
%mend p19_freegb_parse;

/* ---- free space of the drive that holds path (needs XCMD, else -1) ------ */
%macro p19_freegb(path=, mv=_p19_free_gb);
  %local _drv;
  %let &mv = -1;
  %let _drv = %substr(&path, 1, 2);
  %if %sysfunc(getoption(xcmd)) = XCMD and "%substr(&_drv, 2, 1)" = ":" %then %do;
    filename p19dir pipe "cmd /c dir /-c ""&_drv.\""";
    %p19_freegb_parse(fileref=p19dir, mv=&mv);
    filename p19dir clear;
  %end;
  %else %put NOTE: [p19] free space not measured - XCMD is off or the path has no drive letter;
%mend p19_freegb;

/* ---- allow-list gate: every column is a key column, a mapped PCNR_ variable
   (pcnr_name of vars=) or it is listed in the flagged table. Any name with MRN,
   ENCRYPT or ENCOUNTER in it also fails the gate unless it is listed in the
   exceptions file (exc=, columns colname, reason, reviewed_by, reviewed_date)
   AND its role is MAPPED. KEY and UNLISTED columns can never be excepted. A
   missing exceptions file, or a listed name that is not a flagged MAPPED column
   of the dataset (stale or not allowed), fails loudly. Excepted names are
   logged (names only). NORM_PSID is a key column here; dropping it is a
   Wave 2 decision (PDD-D-43). out = work table of unexcepted flagged names
   (colname, colrole). ----------------------------------------------------- */
%macro p19_allowlist(ds=, vars=pdd.name_map_vars_ext, qc=, out=work.p19_cols_flagged,
                     exc=&docs_path.\xlsx_name_exceptions.csv);
  %local _lib _mem _nunl _nhost _nexc _nbad _nstale;
  %let _lib = %upcase(%scan(&ds, 1, .));
  %let _mem = %upcase(%scan(&ds, 2, .));
  %let _nexc = 0;
  %let _nbad = 0;
  %if not %sysfunc(fileexist(&exc)) %then %do;
    %p19_fail(msg=%str(name exceptions file is missing: &exc));
    %return;
  %end;
  data work._p19_exc;
    length colname $64 reason $200 reviewed_by $40 reviewed_date $10;
    infile "&exc" dsd truncover firstobs=2 encoding='wlatin1';
    input colname reason reviewed_by reviewed_date;
    colname = upcase(strip(colname));
    if not missing(colname);
  run;
  proc sql noprint;
    create table work._p19_al as
      select strip(name) as colname length=64,
             case when upcase(name) in ('PECAN_ID', 'PRECEDE_STUDY_ID', 'PECAN_ID_KEY_ERA', 'KEY_ERA', 'NORM_PSID') then 'KEY'
                  when upcase(name) in (select upcase(strip(pcnr_name)) from &vars) then 'MAPPED'
                  else 'UNLISTED' end as colrole length=10,
             (index(upcase(name), 'MRN') > 0 or index(upcase(name), 'ENCRYPT') > 0
              or index(upcase(name), 'ENCOUNTER') > 0) as ishost,
             (upcase(name) in (select colname from work._p19_exc)) as isexc
      from dictionary.columns
      where libname = "&_lib" and memname = "&_mem";
    /* excepted: flagged by name, listed, and MAPPED */
    create table work._p19_excok as
      select colname, colrole from work._p19_al
      where ishost = 1 and isexc = 1 and colrole = 'MAPPED';
    create table &out as
      select colname, colrole from work._p19_al
      where colrole = 'UNLISTED' or (ishost = 1 and not (isexc = 1 and colrole = 'MAPPED'))
      order by colname;
    /* exception rows that are not allowed: not in the dataset, not name-flagged, or not MAPPED */
    create table work._p19_excbad as
      select colname from work._p19_exc
      where colname not in (select upcase(colname) from work._p19_excok);
    select count(*) into :_nstale trimmed from work._p19_excbad;
    select count(*) into :_nunl trimmed from work._p19_al where colrole = 'UNLISTED';
    select count(*) into :_nexc trimmed from work._p19_excok;
    select count(*) into :_nhost trimmed from work._p19_al
      where ishost = 1 and not (isexc = 1 and colrole = 'MAPPED');
  quit;
  data _null_;
    set &out;
    put 'NOTE: [p19] flagged column name ' colname ' role ' colrole;
  run;
  data _null_;
    set work._p19_excok;
    put 'NOTE: [p19] excepted column name ' colname ' role ' colrole;
  run;
  data _null_;
    set work._p19_excbad;
    put 'NOTE: [p19] invalid exception name ' colname;
  run;
  %p19_qadd(ds=&qc, item=columns_not_key_and_not_mapped, n=&_nunl, fail=%eval(&_nunl > 0));
  %p19_qadd(ds=&qc, item=columns_name_flag_excepted, n=&_nexc);
  %p19_qadd(ds=&qc, item=columns_name_flag_unexcepted, n=&_nhost, fail=%eval(&_nhost > 0));
  %p19_qadd(ds=&qc, item=name_exceptions_invalid, n=&_nstale, fail=%eval(&_nstale > 0));
  %if &_nunl > 0 or &_nhost > 0 or &_nstale > 0 %then
    %p19_fail(msg=%str(allow-list gate failed - a column is not a key column or a mapped PCNR_ variable or its name suggests an MRN or encounter field and is not excepted or the exceptions file lists a column that is not allowed. Names are in the flagged table and the log));
%mend p19_allowlist;

/* ---- closed-file MRN scan (reuses the Phase 18 scan, hit count only) ----- */
%macro p19_scan_closed(filesmv=, out=work.p19_scan_out);
  %p18_scan_no_mrn(filesmv=&filesmv, out=&out);
%mend p19_scan_closed;

/* ---- SAS side speed benchmark (P19-7): write the first rows of ds as a
   throwaway UTF-8 CSV with every column, time it, delete it. Sets
   _p19_bench_secs and _p19_bench_est_min (full dataset). The file holds row
   level data: it is deleted at once and the delete is checked. -------------- */
%macro p19_bench_sas(ds=, file=, rows=1000);
  %local _lib _mem _t0 _t1 _del;
  %let _lib = %upcase(%scan(&ds, 1, .));
  %let _mem = %upcase(%scan(&ds, 2, .));
  %p19_dataset_facts(ds=&ds);
  proc sql noprint;
    create table work._p19_bn as
      select name, varnum from dictionary.columns
      where libname = "&_lib" and memname = "&_mem"
      order by varnum;
  quit;
  filename p19bg temp;
  data _null_;
    set work._p19_bn end=_e;
    file p19bg lrecl=400;
    if _n_ = 1 then do;
      put "data _null_;";
      put "set &ds(obs=&rows);";
      put "file '&file' dsd lrecl=1048576 encoding='utf-8';";
      put "put";
    end;
    put name;
    if _e then do;
      put ";";
      put "run;";
    end;
  run;
  options nomprint nosymbolgen nomlogic;
  %let _t0 = %sysfunc(datetime());
  %include p19bg;
  %let _t1 = %sysfunc(datetime());
  options mprint;
  filename p19bg clear;
  %let _p19_bench_secs = %sysevalf(&_t1 - &_t0);
  %let _p19_bench_est_min = %sysevalf(&_p19_bench_secs * &_p19_nrows / &rows / 60);
  data _null_;
    rc = filename('p19del', "&file");
    rc2 = fdelete('p19del');
    rc3 = filename('p19del');
    call symputx('_del', (rc2 = 0), 'L');
  run;
  %if &_del ne 1 %then
    %p19_fail(msg=%str(the benchmark CSV could not be deleted - delete it by hand, it holds row level data));
%mend p19_bench_sas;

/* ---- export column list (Wave 2). Keys of PDD_XLS_KEYS first (in key set
   order), then every mapped PCNR_ variable in dataset order (PDD-D-37 DICT,
   NO_DATA variables kept, PDD-D-36 INCLUDE). NORM_PSID and any other key role
   column outside the key set are never exported. A column that is neither a key
   of the set, an excluded key-role name nor a mapped variable (vars=) fails the
   gate (for example ENCRYPTED_MRN). A key of the set missing from ds fails.
   out: colname, idx (position in the export, 1-based), sas_type (N or C),
   excel_kind (N, C, DATE, DATETIME, TIME), fmt. Sets _p19_nexp. ------------ */
%macro p19_columns(ds=, out=, keys=K3, vars=pdd.name_map_vars_ext, qc=);
  %local _lib _mem _nunl _nmiss _nx;
  %let _lib = %upcase(%scan(&ds, 1, .));
  %let _mem = %upcase(%scan(&ds, 2, .));
  %let _p19_nexp = 0;
  %p19_keyset(code=&keys, mv=_p19_keycols);
  %if %length(&_p19_keycols) = 0 %then %return;
  data work._p19_keys;
    length colname $64 kord 8;
    do _i = 1 to countw("&_p19_keycols", ' ');
      colname = upcase(scan("&_p19_keycols", _i, ' '));
      kord = _i;
      output;
    end;
    drop _i;
  run;
  proc sql noprint;
    create table work._p19_dc as
      select strip(name) as colname length=64, varnum, upcase(type) as ctype length=4,
             strip(format) as fmt length=32,
             case when upcase(name) in (select colname from work._p19_keys) then 'K'
                  when upcase(name) in ('NORM_PSID', 'PECAN_ID_KEY_ERA', 'PECAN_ID', 'PRECEDE_STUDY_ID', 'KEY_ERA') then 'X'
                  when upcase(name) in (select upcase(strip(pcnr_name)) from &vars) then 'M'
                  else 'U' end as role length=1
      from dictionary.columns
      where libname = "&_lib" and memname = "&_mem";
    select count(*) into :_nunl trimmed from work._p19_dc where role = 'U';
    select count(*) into :_nx trimmed from work._p19_dc where role = 'X';
    select count(*) into :_nmiss trimmed from work._p19_keys
      where colname not in (select upcase(colname) from work._p19_dc where role = 'K');
    create table work._p19_dc2 as
      select d.colname, d.varnum, d.ctype, d.fmt,
             case when d.role = 'K' then 0 else 1 end as grp,
             coalesce(k.kord, 0) as kord
      from work._p19_dc d left join work._p19_keys k on upcase(d.colname) = k.colname
      where d.role in ('K', 'M')
      order by grp, kord, d.varnum;
  quit;
  data &out;
    length colname $64 idx 8 sas_type $1 excel_kind $8 fmt $32 _f $32;
    set work._p19_dc2;
    idx = _n_;
    if ctype = 'CHAR' then do;
      sas_type = 'C';
      excel_kind = 'C';
    end;
    else do;
      sas_type = 'N';
      excel_kind = 'N';
      _f = upcase(prxchange('s/\d*\.?\d*$//', 1, strip(fmt)));
      if prxmatch('/^(DATETIME|DTDATE|DTMONYY|DTWKDATX|DTYEAR|DTYYQC|MDYAMPM)$/', strip(_f)) then excel_kind = 'DATETIME';
      else if prxmatch('/^(TIME|TIMEAMPM|HHMM|HOUR|MMSS|TOD)$/', strip(_f)) then excel_kind = 'TIME';
      else if prxmatch('/^(DATE|DDMMYY|MMDDYY|YYMMDD|MONYY|YYMON|YYMM|MMYY|YYQ|WEEKDATE|WORDDATE|WORDDATX|EURDFDE|JULIAN|E8601DA|B8601DA)$/', strip(_f)) then excel_kind = 'DATE';
    end;
    keep colname idx sas_type excel_kind fmt;
  run;
  proc sql noprint;
    select count(*) into :_p19_nexp trimmed from &out;
  quit;
  %p19_qadd(ds=&qc, item=export_columns, n=&_p19_nexp);
  %p19_qadd(ds=&qc, item=export_columns_excluded_key_role, n=&_nx);
  %p19_qadd(ds=&qc, item=export_columns_not_key_and_not_mapped, n=&_nunl, fail=%eval(&_nunl > 0));
  %p19_qadd(ds=&qc, item=export_key_columns_missing, n=&_nmiss, fail=%eval(&_nmiss > 0));
  %if &_nunl > 0 or &_nmiss > 0 %then
    %p19_fail(msg=%str(export column gate failed - a column is not in the key set and not a mapped PCNR_ variable or a key column of the set is missing));
%mend p19_columns;

/* ---- stage writer. cols = table from %p19_columns. Writes the data CSV (header
   line, then one record per row, UTF-8, CRLF) and the schema CSV (col_index,
   name, sas_type, excel_kind; no values). Cells: character values keep their
   text, only SAS trailing padding is cut, and a value with a comma, quote, CR
   or LF is quoted (quote doubled). Numerics use BEST32., missing and special
   missing are empty (PDD-D-40 BLANK). Numeric dates and datetimes become Excel
   serials (PDD-D-38 SERIAL): date + 21916, datetime / 86400 + 21916, time /
   86400. Column statements are generated into a temp file and included inside
   one DATA step, so the dataset is read once. ----------------------------- */
%macro p19_stage(ds=, cols=, out=, schema=);
  %local _nc;
  proc sql noprint;
    select count(*) into :_nc trimmed from &cols;
  quit;
  filename p19cg temp;
  data _null_;
    set &cols end=_e;
    file p19cg lrecl=2000;
    if _n_ = 1 then put 'if _n_ = 1 then do;';
    put "put '" colname +(-1) "' @;";
    if _e then do;
      put 'put;';
      put 'end;';
    end;
    else put "put ',' @;";
  run;
  data _null_;
    set &cols;
    file p19cg lrecl=2000 mod;
    length _nm $80;
    _nm = "'" || strip(colname) || "'n";
    if idx > 1 then put "put ',' @;";
    if excel_kind = 'C' then do;
      put "_pv = trimn(" _nm +(-1) ");";
      put "_pl = lengthn(_pv);";
      put "if _pl > 0 then do;";
      put "  if findc(_pv, '222C0A0D'x) > 0 then _pv = '22'x || trimn(tranwrd(_pv, '22'x, '2222'x)) || '22'x;";
      put "  put _pv +(-1) @;";
      put "end;";
    end;
    else do;
      put "if not missing(" _nm +(-1) ") then do;";
      if excel_kind = 'DATE' then put "  _pn = " _nm +(-1) " + 21916;";
      else if excel_kind = 'DATETIME' then put "  _pn = " _nm +(-1) " / 86400 + 21916;";
      else if excel_kind = 'TIME' then put "  _pn = " _nm +(-1) " / 86400;";
      else put "  _pn = " _nm +(-1) ";";
      put "  _ps = strip(put(_pn, best32.));";
      put "  put _ps +(-1) @;";
      put "end;";
    end;
  run;
  data _null_;
    set &ds;
    length _pv $65540 _ps $64 _pl 8 _pn 8;
    file "&out" encoding='utf-8' lrecl=1048576 termstr=crlf;
    %include p19cg;
    put;
  run;
  filename p19cg clear;
  data _null_;
    set &cols;
    file "&schema" encoding='utf-8' lrecl=1000 termstr=crlf;
    if _n_ = 1 then put 'col_index,name,sas_type,excel_kind';
    length _l $200;
    _l = strip(put(idx, best12.)) || ',' || strip(colname) || ',' || strip(sas_type) || ',' || strip(excel_kind);
    put _l;
  run;
%mend p19_stage;

/* ---- records in a closed CSV, quote aware: a record ends at a line end after
   which the running count of double quotes is even. Sets _p19_csv_recs and
   _p19_csv_lines (physical lines, CRLF split). ----------------------------- */
%macro p19_csv_records(file=);
  %let _p19_csv_recs = 0;
  %let _p19_csv_lines = 0;
  data _null_;
    infile "&file" encoding='utf-8' lrecl=1048576 termstr=crlf truncover end=_e;
    input;
    _lines + 1;
    _q + countc(_infile_, '22'x);
    if mod(_q, 2) = 0 then _recs + 1;
    if _e then do;
      call symputx('_p19_csv_recs', _recs, 'G');
      call symputx('_p19_csv_lines', _lines, 'G');
    end;
  run;
%mend p19_csv_records;

/* ---- expected counts and sample list (exact, stay on P: under stage). One
   pass over ds. File layout, header kind,variable,n_rows,n_nonblank,n_special:
   ROWS (n_rows = dataset rows), COL (per exported column in export order:
   non-blank text cells or non-missing numbers, special missing numbers),
   SAMPLE (n_rows = a 1-based data row number; min(rows, 2000) distinct rows,
   seeded). Counts only, no cell values. ------------------------------------ */
%macro p19_expected(ds=, cols=, out=, sample=2000, seed=19);
  %local _nc;
  proc sql noprint;
    select count(*) into :_nc trimmed from &cols;
  quit;
  filename p19cx1 temp;
  filename p19cx2 temp;
  data _null_;
    set &cols;
    file p19cx1 lrecl=2000;
    length _nm $80 _ix $12;
    _nm = "'" || strip(colname) || "'n";
    _ix = strip(put(idx, best12.));
    if excel_kind = 'C' then put "if " _nm +(-1) " ne '' then _nb{" _ix +(-1) "} = _nb{" _ix +(-1) "} + 1;";
    else do;
      put "if missing(" _nm +(-1) ") then do;";
      put "  if " _nm +(-1) " ne . then _ns{" _ix +(-1) "} = _ns{" _ix +(-1) "} + 1;";
      put "end;";
      put "else _nb{" _ix +(-1) "} = _nb{" _ix +(-1) "} + 1;";
    end;
    file p19cx2 lrecl=2000;
    put "p19_kind = 'COL';";
    put "p19_var = '" colname +(-1) "';";
    put "p19_nonblank = _nb{" _ix +(-1) "};";
    put "p19_special = _ns{" _ix +(-1) "};";
    put "output;";
  run;
  data work._p19_ex;
    length p19_kind $8 p19_var $64 p19_nrows 8 p19_nonblank 8 p19_special 8;
    set &ds end=_e;
    array _nb{&_nc} _temporary_ (&_nc * 0);
    array _ns{&_nc} _temporary_ (&_nc * 0);
    %include p19cx1;
    if _e then do;
      p19_nrows = _n_;
      p19_kind = 'ROWS';
      p19_var = '';
      p19_nonblank = .;
      p19_special = .;
      output;
      %include p19cx2;
    end;
    keep p19_kind p19_var p19_nrows p19_nonblank p19_special;
  run;
  filename p19cx1 clear;
  filename p19cx2 clear;
  proc sql noprint;
    select max(p19_nrows) into :_p19_nrows trimmed from work._p19_ex;
  quit;
  data work._p19_smp;
    length p19_kind $8 p19_var $64 p19_nrows 8 p19_nonblank 8 p19_special 8;
    call streaminit(&seed);
    _need = min(&_p19_nrows, &sample);
    do _i = 1 to &_p19_nrows;
      if _need <= 0 then leave;
      if rand('uniform') * (&_p19_nrows - _i + 1) < _need then do;
        p19_kind = 'SAMPLE';
        p19_nrows = _i;
        output;
        _need = _need - 1;
      end;
    end;
    keep p19_kind p19_var p19_nrows p19_nonblank p19_special;
  run;
  data _null_;
    set work._p19_ex work._p19_smp;
    file "&out" encoding='utf-8' lrecl=32767 termstr=crlf;
    length _l $400;
    if _n_ = 1 then put 'kind,variable,n_rows,n_nonblank,n_special';
    _l = strip(p19_kind) || ',' || strip(p19_var) || ','
         || ifc(missing(p19_nrows), '', strip(put(p19_nrows, best12.))) || ','
         || ifc(missing(p19_nonblank), '', strip(put(p19_nonblank, best12.))) || ','
         || ifc(missing(p19_special), '', strip(put(p19_special, best12.)));
    put _l;
  run;
%mend p19_expected;

%p19_init;
