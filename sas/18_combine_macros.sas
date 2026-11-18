%include "C:\data_dictionary\sas\17_pecan_id_macros.sas";
/*==========================================================================
  File    : sas/18_combine_macros.sas
  Phase   : 18 (combined dataset and dictionary 2018-2025), plan 18-02
  Purpose : Shared macros for 18a (preflight), 18b (build), 18c (profile and
            reconciliation) and 18d (MRN scan). Macros only; the single
            open-code call at the end (%p18_init) declares globals, no %if.
  Needs   : the calling program defines %fail_out(msg=) BEFORE calling any
            macro that can fail. The first statement above includes the
            Phase 17 macros (%p17_stamp, %p17_backup_table, ...), C36.
  Globals : p18_fail_mode (ABORT or FLAG, FLAG only in the synthetic test),
            _p18_failed, PDD_K2_PSID_MODE (PDD-D-33: NORM default).
  Never   : writes to the registry, dup link or case map; puts a value or an
            MRN in a log or QC table (names and counts only).
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance:
    C3  No open-code %if/%else outside %macro ... %mend
    C11 No macro keyword in a quoted PUT string
    C30 No semicolons in %put or %fail_out message text
    C31 POINT= steps carry stop; (none are used here)
    C32 No reserved words as PROC SQL column names
==========================================================================*/

/* ---- globals (defaults never overwrite a value already set) ----------- */
%macro p18_init;
  %if not %symexist(p18_fail_mode) %then %do;
    %global p18_fail_mode;
    %let p18_fail_mode = ABORT;
  %end;
  %if not %symexist(_p18_failed) %then %do;
    %global _p18_failed;
    %let _p18_failed = 0;
  %end;
  %global _p18_ov_21_22 _p18_ov_21_23 _p18_ov_22_23 _p18_ov_old_new _p18_exp_shared;
  %if not %symexist(PDD_K2_PSID_MODE) %then %do;
    %global PDD_K2_PSID_MODE;
    %let PDD_K2_PSID_MODE = NORM;
  %end;
%mend p18_init;

/* ---- failure helper: ABORT calls %fail_out, FLAG only records --------- */
%macro p18_fail(msg=);
  %if %upcase(&p18_fail_mode) = FLAG %then %do;
    %let _p18_failed = 1;
    %put NOTE: [p18] expected failure recorded - &msg;
  %end;
  %else %do;
    %fail_out(msg=%str(&msg));
  %end;
%mend p18_fail;

/* ---- QC staging: rows are kept in WORK (work.qc_comb_<name>) and written
   to pdd once by %p18_flush_qc (network share locks, Phase 17 lesson) ----- */
%macro p18_qinit(ds=);
  data work.%scan(&ds, -1, .);
    length item $80 n 8 isfail 8;
    stop;
  run;
%mend p18_qinit;

%macro p18_qadd(ds=, item=, n=, fail=0);
  data work._p18_q1;
    length item $80 n 8 isfail 8;
    item = "&item";
    n = &n;
    isfail = &fail;
  run;
  proc append base=work.%scan(&ds, -1, .) data=work._p18_q1 force;
  run;
%mend p18_qadd;

/* Writes every staged work.qc_comb_* table to pdd, one data step each. */
%macro p18_flush_qc;
  %local _fl_list _fl_i _fl_t _fl_n;
  %global _p18_flush_writes;
  %let _p18_flush_writes = 0;
  %let _fl_list = ;
  %if %sysfunc(libref(pdd)) ne 0 %then %do;
    %put NOTE: [p18] flush skipped - pdd not assigned;
    %return;
  %end;
  proc sql noprint;
    select memname into :_fl_list separated by ' '
    from dictionary.tables
    where libname = 'WORK' and memtype = 'DATA'
      and memname like 'QC_COMB_%';
  quit;
  %let _fl_n = %sysfunc(countw(&_fl_list, %str( )));
  %do _fl_i = 1 %to &_fl_n;
    %let _fl_t = %scan(&_fl_list, &_fl_i, %str( ));
    data pdd.&_fl_t;
      set work.&_fl_t;
    run;
    %let _p18_flush_writes = %eval(&_p18_flush_writes + 1);
  %end;
  %put NOTE: [p18] QC flush - &_fl_n table(s) written to pdd;
%mend p18_flush_qc;

%macro p18_nobs(ds=, mv=);
  %let &mv = 0;
  proc sql noprint;
    select count(*) into :&mv trimmed from &ds;
  quit;
%mend p18_nobs;

/* Mask for exports: 1-10 becomes <11. Function-style, returns text. */
%macro p18_mask(n);
  %if &n >= 1 and &n <= 10 %then %str(<11);
  %else &n;
%mend p18_mask;

/* Copy of a small WORK table to a CSV with the listed numeric columns masked
   (1-10 -> <11). cols= all columns in order, numcols= the count columns.
   Header and values only, counts and names. */
%macro p18_export(ds=, file=, cols=, numcols=);
  %local _i _c _hdr;
  %if %length(&numcols) = 0 %then %do;
    data work._p18_exp;
      set &ds;
    run;
  %end;
  %else %do;
    data work._p18_exp;
      set &ds(rename=(
        %do _i = 1 %to %sysfunc(countw(&numcols, %str( )));
          %scan(&numcols, &_i, %str( ))=_m_%scan(&numcols, &_i, %str( ))
        %end;
      ));
      length
        %do _i = 1 %to %sysfunc(countw(&numcols, %str( )));
          %scan(&numcols, &_i, %str( )) $12
        %end;
      ;
      %do _i = 1 %to %sysfunc(countw(&numcols, %str( )));
        %let _c = %scan(&numcols, &_i, %str( ));
        if missing(_m_&_c) then &_c = '';
        else if _m_&_c >= 1 and _m_&_c <= 10 then &_c = '<11';
        else &_c = strip(put(_m_&_c, best12.));
        drop _m_&_c;
      %end;
    run;
  %end;
  %let _hdr = %sysfunc(translate(%sysfunc(compbl(&cols)), %str(,), %str( )));
  data _null_;
    file "&file" lrecl=32767;
    put "&_hdr";
  run;
  data _null_;
    set work._p18_exp;
    file "&file" dsd lrecl=32767 mod;
    put
    %do _i = 1 %to %sysfunc(countw(&cols, %str( )));
      %scan(&cols, &_i, %str( ))
    %end;
    ;
  run;
%mend p18_export;

/* ---- PDD-D-33: validate the K2 PRECEDE_STUDY_ID mode. Empty means the
   decided default NORM; only NORM, DELIVERED, BLANK are valid. ---------- */
%macro p18_psid_mode;
  %if %length(%superq(PDD_K2_PSID_MODE)) = 0 %then %let PDD_K2_PSID_MODE = NORM;
  %let PDD_K2_PSID_MODE = %upcase(&PDD_K2_PSID_MODE);
  %if &PDD_K2_PSID_MODE = NORM or &PDD_K2_PSID_MODE = DELIVERED
      or &PDD_K2_PSID_MODE = BLANK %then
    %put NOTE: [p18] PDD_K2_PSID_MODE = &PDD_K2_PSID_MODE (PDD-D-33 default NORM);
  %else
    %p18_fail(msg=%str(invalid PDD_K2_PSID_MODE - valid values are NORM or DELIVERED or BLANK and the PDD-D-33 default is NORM));
%mend p18_psid_mode;

/* ---- decided types: work.p18_vars ---------------------------------------
   One row per mapped PCNR_ variable (status PCNR, non-blank pcnr_name).
   decided_type = decisions CSV row when present (N or C) else result_type of
   name_map_vars_ext. Keys of the CSV match with or without PCNR_ prefix and
   in any case. A CSV key that matches no variable fails. Any PENDING_DECISION
   row in the name map fails. A PCNR_PRECEDE_STUDY_ID map row (if any) is not
   a PCNR_ column of the dataset: the key column PRECEDE_STUDY_ID replaces it. */
%macro p18_load_types(decisions=, vars_ext=pdd.name_map_vars_ext,
                      map_ext=pdd.name_map_ext, out=work.p18_vars);
  %local _npend _nunk _nv;
  %if not %sysfunc(fileexist(&decisions)) %then %do;
    %p18_fail(msg=%str(PENDING DECISION - type decisions CSV not found: &decisions));
    %return;
  %end;
  data work._p18_dec;
    infile "&decisions" dsd truncover firstobs=2 lrecl=4000;
    length pcnr_name $64 combined_type $1 note_kind $16 note_text $1000
           decision_ref $40 dkey $64;
    input pcnr_name combined_type note_kind note_text decision_ref;
    dkey = upcase(prxchange('s/^PCNR_//i', 1, strip(pcnr_name)));
  run;
  proc sql noprint;
    select count(*) into :_npend trimmed
    from &map_ext where upcase(strip(status)) = 'PENDING_DECISION';
  quit;
  %if &_npend > 0 %then
    %p18_fail(msg=%str(PENDING DECISION - &_npend name map rows still carry PENDING_DECISION));
  proc sql noprint;
    create table work._p18_vb as
      select distinct strip(m.pcnr_name) as pcnr_name length=64,
             upcase(prxchange('s/^PCNR_//i', 1, strip(m.pcnr_name))) as vkey length=64,
             upcase(strip(v.result_type)) as ext_type length=1,
             v.max_length as max_length
      from &map_ext m inner join &vars_ext v
        on upcase(strip(m.pcnr_name)) = upcase(strip(v.pcnr_name))
      where upcase(strip(m.status)) = 'PCNR' and strip(m.pcnr_name) ne ''
        and calculated vkey ne 'PRECEDE_STUDY_ID';
  quit;
  proc sql noprint;
    create table &out as
      select v.pcnr_name, v.vkey, v.ext_type, v.max_length,
             case when d.combined_type in ('N', 'C') then d.combined_type
                  else v.ext_type end as decided_type length=1,
             d.decision_ref as decision_ref length=40,
             d.note_kind as note_kind length=16,
             d.note_text as note_text length=1000
      from work._p18_vb v left join work._p18_dec d on v.vkey = d.dkey
      order by upcase(v.pcnr_name);
  quit;
  data &out;
    set &out;
    idx = _n_;
  run;
  proc sql noprint;
    select count(*) into :_nunk trimmed
    from work._p18_dec d
    where d.dkey not in (select vkey from &out);
    select count(*) into :_nv trimmed from &out;
  quit;
  %global _p18_nvars;
  %let _p18_nvars = &_nv;
  %if &_nunk > 0 %then
    %p18_fail(msg=%str(PENDING DECISION - &_nunk decisions CSV key(s) match no mapped variable));
  %put NOTE: [p18] &_nv mapped PCNR_ variables loaded with decided types;
%mend p18_load_types;

/* ---- source map for one source dataset --------------------------------
   kind=OLD: columns of src carry the PCNR_ names (frozen pdd.pcnr).
   kind=NEW: map_ext rows (status PCNR, s_code=scode) give the source column
   sas_name. out = work.p18_sm_<tag>: idx, srcname (blank when the source has
   no column), srctype C or N, srclen. Counts of mapped-but-absent source
   columns and repeated source columns go to globals and fail. */
%macro p18_srcmap(src=, kind=, scode=, tag=, map_ext=pdd.name_map_ext,
                  vars=work.p18_vars);
  %local _lib _mem _nabs _ndup;
  %let _lib = %upcase(%scan(&src, 1, .));
  %let _mem = %upcase(%scan(&src, 2, .));
  proc sql noprint;
    create table work._p18_cols as
      select upcase(strip(name)) as upname length=64,
             strip(name) as colname length=64,
             case when upcase(type) = 'CHAR' then 'C' else 'N' end as ctype length=1,
             length as clen
      from dictionary.columns
      where libname = "&_lib" and memname = "&_mem";
  quit;
  %if %upcase(&kind) = OLD %then %do;
    proc sql noprint;
      create table work._p18_sm0 as
        select v.idx, v.pcnr_name, c.colname as srcname length=64,
               c.ctype as srctype length=1, c.clen as srclen
        from &vars v left join work._p18_cols c
          on upcase(strip(v.pcnr_name)) = c.upname;
    quit;
  %end;
  %else %do;
    proc sql noprint;
      create table work._p18_sm0 as
        select v.idx, v.pcnr_name, c.colname as srcname length=64,
               c.ctype as srctype length=1, c.clen as srclen,
               m.sas_name as mapname length=64
        from &vars v
        inner join (select distinct pcnr_name, sas_name from &map_ext
                    where upcase(strip(status)) = 'PCNR' and strip(pcnr_name) ne ''
                      and lowcase(strip(s_code)) = lowcase("&scode")) m
          on upcase(strip(v.pcnr_name)) = upcase(strip(m.pcnr_name))
        left join work._p18_cols c on upcase(strip(m.sas_name)) = c.upname;
    quit;
    proc sql noprint;
      select count(*) into :_nabs trimmed from work._p18_sm0 where srcname = '';
      select count(*) - count(distinct idx) into :_ndup trimmed from work._p18_sm0;
    quit;
    %if &_nabs > 0 %then
      %p18_fail(msg=%str(&tag - &_nabs mapped source column(s) missing from &src));
    %if &_ndup > 0 %then
      %p18_fail(msg=%str(&tag - &_ndup variable(s) map to more than one source column));
  %end;
  data work.p18_sm_&tag;
    set work._p18_sm0;
    keep idx pcnr_name srcname srctype srclen;
  run;
%mend p18_srcmap;

/* dstlen per variable: 8 for N, else max of ext max_length, longest C source
   and 32 when any numeric source feeds a text variable. All sources of one
   variable then share one length (no multiple-length WARNING on stacking). */
%macro p18_set_lengths(tags=, vars=work.p18_vars);
  %local _i _t;
  data work._p18_small;
    set
    %do _i = 1 %to %sysfunc(countw(&tags, %str( )));
      work.p18_sm_%scan(&tags, &_i, %str( ))
    %end;
    ;
  run;
  proc sql noprint;
    create table work._p18_len as
      select idx, max(case when srctype = 'C' then srclen else 0 end) as cmax,
             max(case when srctype = 'N' then 1 else 0 end) as anynum
      from work._p18_small group by idx;
    /* new table first: a CREATE TABLE that reads its own target warns */
    create table work._p18_vnew as
      select v.*, case when v.decided_type = 'N' then 8
             else max(1, coalesce(v.max_length, 1), coalesce(l.cmax, 0),
                      32 * coalesce(l.anynum, 0)) end as dstlen
      from &vars v left join work._p18_len l on v.idx = l.idx
      order by v.idx;
  quit;
  data &vars;
    set work._p18_vnew;
  run;
  proc delete data=work._p18_vnew;
  run;
%mend p18_set_lengths;



/* ---- a table must exist ------------------------------------------------ */
%macro p18_require(tables=);
  %local _i _t _miss;
  %let _miss = 0;
  %do _i = 1 %to %sysfunc(countw(&tables, %str( )));
    %let _t = %scan(&tables, &_i, %str( ));
    %if %sysfunc(exist(&_t)) = 0 %then %do;
      %let _miss = %eval(&_miss + 1);
      %put NOTE: [p18] required table missing - &_t;
    %end;
  %end;
  %if &_miss > 0 %then %p18_fail(msg=%str(&_miss required table(s) missing - see NOTE lines above));
%mend p18_require;

/* ---- build one source: rename, convert, count, keep ----------------------
   Generated code goes to a temp file and is included. No column name is typed
   here. Counters per variable: _cf = conversion failures (counts only), _cn =
   NULL cells read as missing (char to num). out has norm_psid and every PCNR_
   variable in its decided type. Counts go to work.p18_cnt_<tag>. */
%macro p18_build_source(src=, out=, tag=, vars=work.p18_vars);
  %local _nv;
  proc sql noprint;
    create table work.p18_g_&tag as
      select v.idx, v.pcnr_name, v.decided_type as dsttype, v.dstlen,
             m.srcname, m.srctype
      from &vars v left join work.p18_sm_&tag m on v.idx = m.idx
      order by v.idx;
    select count(*) into :_nv trimmed from work.p18_g_&tag;
  quit;
  data work.p18_code_&tag;
    length sect 8 line $2000 _s $40 _d $64 _cf $40 _cn $40 _ix $12;
    set work.p18_g_&tag end=_e;
    if _n_ = 1 then do;
      sect = 10; line = "data &out(keep=norm_psid"; output;
    end;
    sect = 11; line = strip(pcnr_name); output;
    if _n_ = 1 then do;
      sect = 12; line = ") work.p18_cnt_&tag(keep=idx nfail nnull);"; output;
    end;
    _ix = strip(put(idx, best12.));
    _s = cats('_s', _ix);
    _d = strip(pcnr_name);
    _cf = cats('_cf', _ix);
    _cn = cats('_cn', _ix);
    sect = 20;
    if dsttype = 'N' then line = catx(' ', 'length', _d, '8;');
    else line = catx(' ', 'length', _d, cats('$', strip(put(dstlen, best12.)), ';'));
    output;
    if _n_ = 1 then do;
      sect = 30; line = "set &src(keep=norm_psid"; output;
    end;
    if srcname ne '' then do;
      sect = 31; line = strip(srcname); output;
    end;
    if _e then do;
      sect = 32; line = 'rename=('; output;
    end;
    if srcname ne '' then do;
      sect = 33; line = catx('=', strip(srcname), _s); output;
    end;
    if _e then do;
      sect = 34; line = ')) end=_last;'; output;
      sect = 39; line = "retain _cf1-_cf&_nv 0 _cn1-_cn&_nv 0;"; output;
      sect = 40; line = "array _cfa{&_nv} _cf1-_cf&_nv; array _cna{&_nv} _cn1-_cn&_nv;"; output;
      sect = 60; line = "output &out;"; output;
      sect = 61;
      line = catx(' ', "if _last then do; do idx = 1 to &_nv;",
                  "nfail = _cfa{idx}; nnull = _cna{idx}; output work.p18_cnt_&tag; end; end;");
      output;
      sect = 62; line = 'run;'; output;
    end;
    sect = 50;
    if srcname = '' then do;
      if dsttype = 'N' then line = catx(' ', _d, '= .;');
      else line = catx(' ', _d, "= '';");
    end;
    else if srctype = 'C' and dsttype = 'N' then
      line = catx(' ', 'if missing(', _s, ') then', _d, '= .;',
                  'else if upcase(strip(', _s, "))= 'NULL' then do;", _d, '= .;', _cn, '=', _cn, '+ 1; end;',
                  'else do;', _d, '= input(strip(', _s, '), ?? best32.);',
                  'if missing(', _d, ') then', _cf, '=', _cf, '+ 1; end;');
    else if srctype = 'N' and dsttype = 'C' then
      line = catx(' ', 'if missing(', _s, ') then', _d, "= '';",
                  'else do; if', _s, '= int(', _s, ') and abs(', _s, ') < 1e15 then', _d,
                  '= strip(put(', _s, ', 32.)); else', _d, '= strip(put(', _s, ', best32.));',
                  "if indexc(", _d, ", 'Ee') > 0 then", _cf, '=', _cf, '+ 1; end;');
    else line = catx(' ', _d, '=', _s, ';');
    output;
    keep sect idx line;
  run;
  proc sort data=work.p18_code_&tag;
    by sect idx;
  run;
  filename p18gen temp;
  data _null_;
    set work.p18_code_&tag;
    file p18gen lrecl=2000;
    put line;
  run;
  options nomprint nosymbolgen nomlogic;
  %include p18gen;
  options mprint;
  filename p18gen clear;
%mend p18_build_source;

/* ---- conversion counts of one built source into work.qc_comb_typeconv ---- */
%macro p18_typeconv_add(tag=);
  proc sql noprint;
    create table work._p18_tc as
      select g.pcnr_name as pcnr_name length=64, "&tag" as s_code length=8,
             c.nfail as n_char_to_num_fail, c.nnull as n_null_as_missing
      from work.p18_g_&tag g inner join work.p18_cnt_&tag c on g.idx = c.idx
      where g.srcname ne '' and g.srctype ne g.dsttype;
  quit;
  proc append base=work.qc_comb_typeconv data=work._p18_tc force;
  run;
%mend p18_typeconv_add;

%macro p18_typeconv_reset;
  data work.qc_comb_typeconv;
    length pcnr_name $64 s_code $8 n_char_to_num_fail 8 n_null_as_missing 8;
    stop;
  run;
%mend p18_typeconv_reset;

/* conversion failures must be 0 (counts only, no value) */
%macro p18_gate_conv(qc=work.qc_comb_build);
  %local _nf;
  proc sql noprint;
    select coalesce(sum(n_char_to_num_fail), 0) into :_nf trimmed from work.qc_comb_typeconv;
  quit;
  %p18_qadd(ds=&qc, item=type_conversion_failures, n=&_nf, fail=%eval(&_nf > 0));
  %if &_nf > 0 %then
    %p18_fail(msg=%str(PENDING DECISION - &_nf value(s) cannot be converted to the decided type, see qc_comb_typeconv));
%mend p18_gate_conv;


/* ---- PDD-D-30 merge of s22 and s23, field by field ----------------------
   Both inputs are already converted to the decided types. s22 wins; s23 fills
   a value that is missing in s22 (blank, or NULL in any case for text). A case
   in only one input passes through. Per variable counters: shared cases,
   values filled from s23, conflicts (both non-missing and different, s22 kept)
   go to qc (counts only). */
%macro p18_d30_merge(a=, b=, out=, vars=work.p18_vars, qc=work.qc_comb_d30);
  %local _nv;
  proc sort data=&a out=work._p18_ma;
    by norm_psid;
  run;
  proc sort data=&b out=work._p18_mb;
    by norm_psid;
  run;
  proc sql noprint;
    select count(*) into :_nv trimmed from &vars;
  quit;
  data work.p18_code_d30;
    length sect 8 line $2000 _d $64 _b $40 _ix $12 _mA $400 _mB $400;
    set &vars end=_e;
    if _n_ = 1 then do;
      sect = 10; line = "data &out work.p18_d30cnt(keep=idx nshared nfill nconf);"; output;
      sect = 20; line = "merge work._p18_ma(in=_ina) work._p18_mb(in=_inb rename=("; output;
    end;
    _ix = strip(put(idx, best12.));
    _d = strip(pcnr_name);
    _b = cats('_b', _ix);
    sect = 21; line = catx('=', _d, _b); output;
    if _e then do;
      sect = 22; line = ")) end=_last; by norm_psid;"; output;
      sect = 25; line = "retain _sh1-_sh&_nv 0 _fi1-_fi&_nv 0 _co1-_co&_nv 0;"; output;
      sect = 30; line = "array _sha{&_nv} _sh1-_sh&_nv; array _fia{&_nv} _fi1-_fi&_nv; array _coa{&_nv} _co1-_co&_nv;"; output;
      sect = 90; line = "output &out;"; output;
      sect = 91; line = catx(' ', "if _last then do; do idx = 1 to &_nv;",
                  "nshared = _sha{idx}; nfill = _fia{idx}; nconf = _coa{idx}; output work.p18_d30cnt; end; end;");
      output;
      sect = 92; line = "drop _b1-_b&_nv _sh1-_sh&_nv _fi1-_fi&_nv _co1-_co&_nv;"; output;
      sect = 93; line = "run;"; output;
    end;
    sect = 50;
    if decided_type = 'C' then do;
      _mA = catx(' ', '(missing(', _d, ') or upcase(strip(', _d, "))= 'NULL')");
      _mB = catx(' ', '(missing(', _b, ') or upcase(strip(', _b, "))= 'NULL')");
    end;
    else do;
      _mA = catx(' ', 'missing(', _d, ')');
      _mB = catx(' ', 'missing(', _b, ')');
    end;
    line = catx(' ', 'if _inb and not _ina then', _d, '=', _b, ';',
                'else if _ina and _inb then do;', cats('_sh', _ix), '=', cats('_sh', _ix), '+ 1;',
                'if', _mA, 'then do; if not', _mB, 'then do;', _d, '=', _b, ';',
                cats('_fi', _ix), '=', cats('_fi', _ix), '+ 1; end; end;',
                'else if not', _mB, 'then do; if', _d, 'ne', _b, 'then',
                cats('_co', _ix), '=', cats('_co', _ix), '+ 1; end; end;');
    output;
    keep sect idx line;
  run;
  proc sort data=work.p18_code_d30;
    by sect idx;
  run;
  filename p18gen temp;
  data _null_;
    set work.p18_code_d30;
    file p18gen lrecl=2000;
    put line;
  run;
  options nomprint nosymbolgen nomlogic;
  %include p18gen;
  options mprint;
  filename p18gen clear;
  proc sql noprint;
    create table &qc as
      select v.pcnr_name as pcnr_name length=64, c.nshared as n_shared,
             c.nfill as n_s22_missing_filled, c.nconf as n_conflict_kept_s22
      from work.p18_d30cnt c inner join &vars v on c.idx = v.idx
      order by v.idx;
  quit;
%mend p18_d30_merge;

%macro p18_stack(old=, s21=, merged=, out=);
  data &out;
    set &old &s21 &merged;
  run;
%mend p18_stack;

/* ---- count of normalized case IDs shared by two tables ---------------- */
%macro p18_overlap(a=, b=, mv=);
  %let &mv = 0;
  proc sql noprint;
    select count(*) into :&mv trimmed
    from (select distinct norm_psid from &a where norm_psid ne '') x
    inner join (select distinct norm_psid from &b where norm_psid ne '') y
      on x.norm_psid = y.norm_psid;
  quit;
%mend p18_overlap;

/* expected shared count of s22 x s23 from docs/new_overlap_decisions.csv.
   No default: a missing file, row or non-numeric value fails. */
%macro p18_read_expected(file=, pair=s22_s23, mv=_p18_exp_shared);
  %let &mv = ;
  %if %sysfunc(fileexist(&file)) = 0 %then %do;
    %p18_fail(msg=%str(overlap decisions file not found));
    %return;
  %end;
  data work._p18_exp;
    infile "&file" dsd truncover firstobs=2 lrecl=2000;
    length pair $40 expected $40;
    input pair expected;
    if strip(pair) = "&pair";
    nexp = input(strip(expected), ?? 12.);
  run;
  proc sql noprint;
    select nexp into :&mv trimmed from work._p18_exp where nexp is not null;
  quit;
  %if %length(&&&mv) = 0 %then
    %p18_fail(msg=%str(expected shared count for pair &pair missing or not numeric in the overlap decisions file));
%mend p18_read_expected;

/* ---- case overlap gates: s21 with s22 and s23 share 0, old with new 0,
   s22 with s23 equal the CSV value ---------------------------------------- */
%macro p18_gate_overlap(old=, s21=, s22=, s23=, exp=, qc=work.qc_comb_build);
  %local _bad;
  %let _bad = 0;
  data work._p18_newall;
    set &s21(keep=norm_psid) &s22(keep=norm_psid) &s23(keep=norm_psid);
  run;
  %p18_overlap(a=&s21, b=&s22, mv=_p18_ov_21_22);
  %p18_overlap(a=&s21, b=&s23, mv=_p18_ov_21_23);
  %p18_overlap(a=&s22, b=&s23, mv=_p18_ov_22_23);
  %p18_overlap(a=&old, b=work._p18_newall, mv=_p18_ov_old_new);
  %p18_qadd(ds=&qc, item=shared_s21_s22, n=&_p18_ov_21_22, fail=%eval(&_p18_ov_21_22 > 0));
  %p18_qadd(ds=&qc, item=shared_s21_s23, n=&_p18_ov_21_23, fail=%eval(&_p18_ov_21_23 > 0));
  %p18_qadd(ds=&qc, item=shared_old_new, n=&_p18_ov_old_new, fail=%eval(&_p18_ov_old_new > 0));
  %p18_qadd(ds=&qc, item=shared_s22_s23, n=&_p18_ov_22_23,
            fail=%eval(&_p18_ov_22_23 ne &exp));
  %if &_p18_ov_21_22 > 0 or &_p18_ov_21_23 > 0 or &_p18_ov_old_new > 0 %then
    %let _bad = 1;
  %if &_p18_ov_22_23 ne &exp %then %let _bad = 1;
  %if &_bad = 1 %then
    %p18_fail(msg=%str(case overlap gate failed - see qc_comb_build rows shared_*));
%mend p18_gate_overlap;

/* ---- row count gates --------------------------------------------------- */
%macro p18_gate_rows(ds=, n_old=, n_s21=, n_s22=, n_s23=, shared=,
                     map=pdd.pecan_id_case_map, qc=work.qc_comb_build);
  %local _n _dist _blank _expect _nmap _bad;
  %let _bad = 0;
  proc sql noprint;
    select count(*), count(distinct case when norm_psid ne '' then norm_psid end),
           sum(norm_psid = '')
      into :_n trimmed, :_dist trimmed, :_blank trimmed from &ds;
    select count(*) into :_nmap trimmed from &map;
  quit;
  %let _expect = %eval(&n_old + &n_s21 + &n_s22 + &n_s23 - &shared);
  %p18_qadd(ds=&qc, item=n_rows_combined, n=&_n);
  %p18_qadd(ds=&qc, item=n_rows_expected_from_sources, n=&_expect, fail=%eval(&_n ne &_expect));
  %p18_qadd(ds=&qc, item=n_distinct_norm_psid, n=&_dist, fail=%eval(&_n ne &_dist));
  %p18_qadd(ds=&qc, item=n_blank_norm_psid, n=&_blank, fail=%eval(&_blank > 0));
  %p18_qadd(ds=&qc, item=n_rows_case_map, n=&_nmap, fail=%eval(&_n ne &_nmap));
  %if &_n ne &_expect or &_n ne &_dist or &_blank > 0 or &_n ne &_nmap %then
    %let _bad = 1;
  %if &_bad = 1 %then
    %p18_fail(msg=%str(row count gate failed - see qc_comb_build rows n_rows_*));
%mend p18_gate_rows;

/* ---- attach PECAN_ID, PECAN_ID_KEY_ERA, KEY_ERA, PRECEDE_STUDY_ID by
   norm_psid from the case map (read only). K1 keeps the delivered value of the
   map. K2 follows PDD_K2_PSID_MODE (PDD-D-33, default NORM). No encrypted
   column is carried. ----------------------------------------------------- */
%macro p18_attach_ids(in=, map=, out=, qc=work.qc_comb_build);
  %local _dups _nomatch _noid _bad;
  %let _bad = 0;
  %p18_psid_mode;
  %if &_p18_failed = 1 and %upcase(&p18_fail_mode) = FLAG %then %return;
  proc sql noprint;
    select count(*) - count(distinct norm_psid) into :_dups trimmed from &map;
  quit;
  %p18_qadd(ds=&qc, item=case_map_duplicate_keys, n=&_dups, fail=%eval(&_dups > 0));
  %if &_dups > 0 %then %do;
    %p18_fail(msg=%str(case map has duplicate norm_psid keys));
    %return;
  %end;
  %let _nomatch = 0;
  %let _noid = 0;
  data &out;
    length norm_psid $64 _m_pid 8 _m_pera $2 _m_era $2 _m_psid $64
           PECAN_ID 8 PECAN_ID_KEY_ERA $2 KEY_ERA $2 PRECEDE_STUDY_ID $64;
    if _n_ = 1 then do;
      declare hash h(dataset: "&map(keep=norm_psid PECAN_ID PECAN_ID_KEY_ERA KEY_ERA PRECEDE_STUDY_ID rename=(PECAN_ID=_m_pid PECAN_ID_KEY_ERA=_m_pera KEY_ERA=_m_era PRECEDE_STUDY_ID=_m_psid))");
      h.defineKey('norm_psid');
      h.defineData('_m_pid', '_m_pera', '_m_era', '_m_psid');
      h.defineDone();
    end;
    retain _nomatch 0 _noid 0;
    set &in end=_last;
    _m_pid = .; _m_pera = ''; _m_era = ''; _m_psid = '';
    if h.find() ne 0 then _nomatch + 1;
    PECAN_ID = _m_pid;
    PECAN_ID_KEY_ERA = _m_pera;
    KEY_ERA = _m_era;
    PRECEDE_STUDY_ID = _m_psid;
    if missing(PECAN_ID) or PECAN_ID_KEY_ERA = '' then _noid + 1;
    if KEY_ERA = 'K2' then do;
%if &PDD_K2_PSID_MODE = NORM %then %do;
      PRECEDE_STUDY_ID = norm_psid;
%end;
%else %if &PDD_K2_PSID_MODE = DELIVERED %then %do;
      PRECEDE_STUDY_ID = substr(norm_psid, 8);
%end;
%else %do;
      PRECEDE_STUDY_ID = '';
%end;
    end;
    if _last then do;
      call symputx('_nomatch', _nomatch);
      call symputx('_noid', _noid);
    end;
    drop _m_pid _m_pera _m_era _m_psid _nomatch _noid;
  run;
  %p18_qadd(ds=&qc, item=rows_without_case_map_entry, n=&_nomatch, fail=%eval(&_nomatch > 0));
  %p18_qadd(ds=&qc, item=rows_without_pecan_id, n=&_noid, fail=%eval(&_noid > 0));
  %if &_nomatch > 0 or &_noid > 0 %then %let _bad = 1;
  %if &_bad = 1 %then
    %p18_fail(msg=%str(id attach gate failed - rows without a case map entry or without PECAN_ID));
%mend p18_attach_ids;

/* ---- fixed column order: PECAN_ID, PRECEDE_STUDY_ID, PECAN_ID_KEY_ERA,
   KEY_ERA, NORM_PSID, then PCNR_ variables alphabetically ------------------ */
%macro p18_order_cols(in=, out=, vars=work.p18_vars);
  %local _i _nv _nkeyin;
  /* the key columns must already be on the input (p18_attach_ids adds them) */
  proc sql noprint;
    select count(*) into :_nkeyin trimmed
    from dictionary.columns
    where libname = "%upcase(%scan(&in, 1, .))" and memname = "%upcase(%scan(&in, 2, .))"
      and upcase(name) in ('PECAN_ID', 'PRECEDE_STUDY_ID', 'PECAN_ID_KEY_ERA',
                           'KEY_ERA', 'NORM_PSID');
  quit;
  %if &_nkeyin ne 5 %then %do;
    %p18_fail(msg=%str(column order needs PECAN_ID PRECEDE_STUDY_ID PECAN_ID_KEY_ERA KEY_ERA NORM_PSID on the input - run the id attach first));
    %return;
  %end;
  proc sql noprint;
    select count(*) into :_nv trimmed from &vars;
    select strip(pcnr_name) into :_p18_c1 - :_p18_c&_nv
    from &vars order by upcase(pcnr_name);
  quit;
  proc sql noprint;
    create table &out as
      select PECAN_ID, PRECEDE_STUDY_ID, PECAN_ID_KEY_ERA, KEY_ERA, norm_psid
      %do _i = 1 %to &_nv;
        , &&_p18_c&_i
      %end;
      from &in;
  quit;
%mend p18_order_cols;

/* ---- variable gate: every mapped PCNR_ variable present once with its
   decided type, no extra PCNR_ column, no ENCRYPTED_ column, key columns
   present. order=1 also checks the fixed column order. ------------------- */
%macro p18_gate_vars(ds=, vars=work.p18_vars, order=0, qc=work.qc_comb_build);
  %local _lib _mem _nmiss _nwrong _nextra _nenc _nkey _nord _bad;
  %let _bad = 0;
  %let _lib = %upcase(%scan(&ds, 1, .));
  %let _mem = %upcase(%scan(&ds, 2, .));
  proc sql noprint;
    create table work._p18_dc as
      select upcase(strip(name)) as upname length=64, upcase(type) as dtype length=4,
             varnum
      from dictionary.columns where libname = "&_lib" and memname = "&_mem"
      order by varnum;
    select count(*) into :_nmiss trimmed
      from &vars v where upcase(strip(v.pcnr_name)) not in (select upname from work._p18_dc);
    select count(*) into :_nwrong trimmed
      from &vars v inner join work._p18_dc d on upcase(strip(v.pcnr_name)) = d.upname
      where (v.decided_type = 'N' and d.dtype ne 'NUM')
         or (v.decided_type = 'C' and d.dtype ne 'CHAR');
    select count(*) into :_nextra trimmed
      from work._p18_dc where upname like 'PCNR!_%' escape '!'
        and upname not in (select upcase(strip(pcnr_name)) from &vars);
    select count(*) into :_nenc trimmed
      from work._p18_dc where upname like '%ENCRYPTED%';
    select count(*) into :_nkey trimmed
      from work._p18_dc where upname in ('PECAN_ID', 'PRECEDE_STUDY_ID',
           'PECAN_ID_KEY_ERA', 'KEY_ERA', 'NORM_PSID');
  quit;
  %p18_qadd(ds=&qc, item=vars_missing_from_dataset, n=&_nmiss, fail=%eval(&_nmiss > 0));
  %p18_qadd(ds=&qc, item=vars_with_wrong_type, n=&_nwrong, fail=%eval(&_nwrong > 0));
  %p18_qadd(ds=&qc, item=extra_pcnr_columns, n=&_nextra, fail=%eval(&_nextra > 0));
  %p18_qadd(ds=&qc, item=encrypted_columns, n=&_nenc, fail=%eval(&_nenc > 0));
  %p18_qadd(ds=&qc, item=key_columns_present, n=&_nkey, fail=%eval(&_nkey ne 5));
  %if &_nmiss > 0 or &_nwrong > 0 or &_nextra > 0 or &_nenc > 0 or &_nkey ne 5 %then
    %let _bad = 1;
  %if &order = 1 %then %do;
    %let _nord = 0;
    data _null_;
      set work._p18_dc end=_e;
      length _prev $64;
      retain _prev '' _bad 0;
      if varnum = 1 and upname ne 'PECAN_ID' then _bad + 1;
      if varnum = 2 and upname ne 'PRECEDE_STUDY_ID' then _bad + 1;
      if varnum = 3 and upname ne 'PECAN_ID_KEY_ERA' then _bad + 1;
      if varnum = 4 and upname ne 'KEY_ERA' then _bad + 1;
      if varnum = 5 and upname ne 'NORM_PSID' then _bad + 1;
      if varnum > 6 and upname < _prev then _bad + 1;
      _prev = upname;
      if _e then call symputx('_nord', _bad);
    run;
    %p18_qadd(ds=&qc, item=column_order_violations, n=&_nord, fail=%eval(&_nord > 0));
    %if &_nord > 0 %then %let _bad = 1;
  %end;
  %if &_bad = 1 %then
    %p18_fail(msg=%str(variable gate failed - see qc_comb_build rows vars_* extra_* encrypted_* key_* column_order_*));
%mend p18_gate_vars;

/* ---- backup of the replaced combined dataset: pcnrcmb_<stamp> (23 bytes) -- */
%macro p18_backup_comb(ds=, stem=pcnrcmb);
  %global _p18_bak_done;
  %let _p18_bak_done = 0;
  %if %sysfunc(exist(&ds)) %then %do;
    %p17_backup_table(ds=&ds, stem=&stem);
    %let _p18_bak_done = 1;
  %end;
%mend p18_backup_comb;

/* ---- read-only guard for registry, dup link, case map -------------------- */
%macro p18_ro_start(reg=pdd.pecan_id_registry, dup=pdd.pecan_id_dup_link,
                    map=pdd.pecan_id_case_map);
  %global _p18_ro_reg _p18_ro_dup _p18_ro_map;
  %p18_nobs(ds=&reg, mv=_p18_ro_reg);
  %p18_nobs(ds=&dup, mv=_p18_ro_dup);
  %p18_nobs(ds=&map, mv=_p18_ro_map);
%mend p18_ro_start;

%macro p18_ro_end(reg=pdd.pecan_id_registry, dup=pdd.pecan_id_dup_link,
                  map=pdd.pecan_id_case_map, qc=work.qc_comb_build);
  %local _r _d _m _bad;
  %p18_nobs(ds=&reg, mv=_r);
  %p18_nobs(ds=&dup, mv=_d);
  %p18_nobs(ds=&map, mv=_m);
  %let _bad = 0;
  %if &_r ne &_p18_ro_reg or &_d ne &_p18_ro_dup or &_m ne &_p18_ro_map %then %let _bad = 1;
  %p18_qadd(ds=&qc, item=registry_rows_unchanged, n=&_r, fail=%eval(&_r ne &_p18_ro_reg));
  %p18_qadd(ds=&qc, item=dup_link_rows_unchanged, n=&_d, fail=%eval(&_d ne &_p18_ro_dup));
  %p18_qadd(ds=&qc, item=case_map_rows_unchanged, n=&_m, fail=%eval(&_m ne &_p18_ro_map));
  %if &_bad = 1 %then
    %p18_fail(msg=%str(read-only guard failed - registry or dup link or case map row count changed));
%mend p18_ro_end;

/* ---- per-variable non-missing and distinct counts ------------------------
   vars table needs idx and pcnr_name. where= is plain text without commas
   (for example KEY_ERA='K1'). out: pcnr_name, n_nonmiss, n_distinct. ----- */
%macro p18_stats(ds=, out=, era=, distinct=1, special=0, vars=work.p18_vars);
  filename p18st temp;
  data _null_;
    set &vars end=_e;
    length _l $400;
    file p18st lrecl=400;
    if _n_ = 1 then put "proc sql noprint; create table work._p18_st1 as select count(*) as nrows";
    /* PDD-D-34: n_nonmiss counts only cells that are not missing. PROC SQL
       COUNT(col) counts special missings (.A-.Z, ._) as values, so use
       SUM(NOT MISSING(col)), the same meaning as PROC MEANS N. */
    _l = catx(' ', ',', 'coalesce(sum(not missing(', strip(pcnr_name), ')), 0) as n' || strip(put(idx, best12.)));
    put _l;
    if &special = 1 then do;
      if upcase(decided_type) = 'N'
        then _l = catx(' ', ',', 'coalesce(sum(missing(', strip(pcnr_name), ') and', strip(pcnr_name), 'ne .), 0) as s' || strip(put(idx, best12.)));
        else _l = catx(' ', ',', '0 as s' || strip(put(idx, best12.)));
      put _l;
    end;
    if &distinct = 1 then do;
      _l = catx(' ', ',', 'count(distinct', strip(pcnr_name), ') as d' || strip(put(idx, best12.)));
      put _l;
    end;
    if _e then do;
      if "&era" ne "" then put "from &ds where KEY_ERA = " '"' "&era" '"' "; quit;";
      else put "from &ds; quit;";
    end;
  run;
  options nomprint nosymbolgen nomlogic;
  %include p18st;
  filename p18st clear;
  filename p18st2 temp;
  data _null_;
    set &vars end=_e;
    length _l $400;
    file p18st2 lrecl=400;
    if _n_ = 1 then do;
      put "data &out; set work._p18_st1; length pcnr_name $64 n_nonmiss 8 n_distinct 8 n_special 8;";
    end;
    _l = catx(' ', 'pcnr_name =', '"' || strip(pcnr_name) || '";',
              'n_nonmiss = n' || strip(put(idx, best12.)) || ';');
    put _l;
    if &special = 1 then _l = 'n_special = s' || strip(put(idx, best12.)) || ';';
    else _l = 'n_special = .;';
    put _l;
    if &distinct = 1 then do;
      _l = 'n_distinct = d' || strip(put(idx, best12.)) || '; output;';
    end;
    else _l = 'n_distinct = .; output;';
    put _l;
    if _e then put "keep pcnr_name n_nonmiss n_distinct n_special; run;";
  run;
  %include p18st2;
  options mprint;
  filename p18st2 clear;
%mend p18_stats;

/* ---- NO_DATA flags and reconciliation with the coverage table ------------
   A variable with 0 non-missing cells over all rows is flagged. Coverage
   NO_DATA variables that have data in the combined set FAIL. out columns:
   pcnr_name, n_nonmiss, coverage_status, reconciled (OK, EXTRA, HASDATA). */
%macro p18_nodata_flags(ds=, cov=pdd.name_map_vars_coverage, out=work.p18_nodata,
                        qc=work.qc_comb_build, vars=work.p18_vars);
  %local _nnd _ncov _nhas _nextra;
  %p18_stats(ds=&ds, out=work._p18_nd0, distinct=0, vars=&vars);
  proc sql noprint;
    create table &out as
      select a.pcnr_name as pcnr_name length=64, a.n_nonmiss as n_nonmiss,
             coalesce(upcase(strip(c.status)), '') as coverage_status length=16,
             case when a.n_nonmiss = 0 and upcase(strip(c.status)) = 'NO_DATA' then 'OK'
                  when a.n_nonmiss = 0 then 'EXTRA'
                  else 'HASDATA' end as reconciled length=8
      from work._p18_nd0 a left join &cov c
        on upcase(strip(a.pcnr_name)) = upcase(strip(c.pcnr_name))
      where a.n_nonmiss = 0 or upcase(strip(c.status)) = 'NO_DATA'
      order by a.pcnr_name;
    select count(*) into :_nnd trimmed from &out where n_nonmiss = 0;
    select count(*) into :_ncov trimmed from &cov where upcase(strip(status)) = 'NO_DATA';
    select count(*) into :_nhas trimmed from &out where reconciled = 'HASDATA';
    select count(*) into :_nextra trimmed from &out where reconciled = 'EXTRA';
  quit;
  %p18_qadd(ds=&qc, item=nodata_in_combined, n=&_nnd);
  %p18_qadd(ds=&qc, item=nodata_in_coverage, n=&_ncov);
  %p18_qadd(ds=&qc, item=nodata_coverage_but_has_data, n=&_nhas, fail=%eval(&_nhas > 0));
  %p18_qadd(ds=&qc, item=nodata_extra_all_missing, n=&_nextra);
  %if &_nhas > 0 %then
    %p18_fail(msg=%str(a coverage NO_DATA variable has data in the combined dataset));
%mend p18_nodata_flags;

/* ---- reconciliation with the previous layer (DD-04) -------------------------
   K1 slice (KEY_ERA = K1) of the combined dataset against pdd.pcnr (non-missing
   counts, exact except NULL cells read as missing) and against the v1.0
   profile (distinct values). An unexplained difference fails. ------------- */
%macro p18_recon(comb=, old=, prf=, tc=work.qc_comb_typeconv, tag_old=old,
                 out=work.p18_recon, qc=work.qc_comb_build, vars=work.p18_vars);
  %local _lib _mem _nun;
  %let _lib = %upcase(%scan(&old, 1, .));
  %let _mem = %upcase(%scan(&old, 2, .));
  proc sql noprint;
    create table work._p18_vold as
      select v.* from &vars v
      where upcase(strip(v.pcnr_name)) in
        (select upcase(strip(name)) from dictionary.columns
         where libname = "&_lib" and memname = "&_mem");
  quit;
  %p18_stats(ds=&comb, out=work._p18_rk1, era=K1, distinct=1, vars=&vars);
  %p18_stats(ds=&comb, out=work._p18_rk2, era=K2, distinct=0, vars=&vars);
  %p18_stats(ds=&comb, out=work._p18_rall, distinct=0, special=1, vars=&vars);
  %p18_stats(ds=&old, out=work._p18_rold, distinct=0, vars=work._p18_vold);
  proc sql noprint;
    create table work._p18_pv as
      select upcase(strip(variable)) as ukey length=64,
             sum(stat = 'LEVEL') as nlev, sum(stat = 'OTHER') as noth,
             max(case when stat = 'N_DISTINCT' then n end) as nd,
             max(var_class) as vcl length=16
      from &prf group by upcase(strip(variable));
    create table work._p18_tcs as
      select upcase(strip(pcnr_name)) as ukey length=64,
             sum(n_null_as_missing) as nnull, 1 as conv_old
      from &tc where s_code = "&tag_old" group by upcase(strip(pcnr_name));
    create table &out as
      select k1.pcnr_name as pcnr_name length=64,
             o.n_nonmiss as n_nonmiss_pcnr_old,
             k1.n_nonmiss as n_nonmiss_comb_k1,
             k2.n_nonmiss as n_nonmiss_comb_k2,
             al.n_nonmiss as n_nonmiss_comb_all,
             al.n_special as n_special_comb_all,
             k1.n_nonmiss -coalesce(o.n_nonmiss, 0) as delta_k1,
             k1.n_distinct as n_distinct_k1,
             case when p.vcl = 'LOW_CARD' and p.noth = 0 and p.nlev > 0 then p.nlev
                  when p.nd is not null then p.nd else . end as n_distinct_prf_v1,
             coalesce(t.nnull, 0) as nnull_old,
             coalesce(t.conv_old, 0) as conv_old
      from work._p18_rk1 k1
      inner join work._p18_rk2 k2 on k1.pcnr_name = k2.pcnr_name
      inner join work._p18_rall al on k1.pcnr_name = al.pcnr_name
      left join work._p18_rold o on k1.pcnr_name = o.pcnr_name
      left join work._p18_pv p on upcase(strip(k1.pcnr_name)) = p.ukey
      left join work._p18_tcs t on upcase(strip(k1.pcnr_name)) = t.ukey
      order by k1.pcnr_name;
  quit;
  data &out;
    length explained $1;
    set &out;
    _n_ok = (delta_k1 = -nnull_old);
    _d_ok = (missing(n_distinct_prf_v1) or n_distinct_k1 = n_distinct_prf_v1 or conv_old = 1);
    explained = ifc(_n_ok and _d_ok, 'Y', 'N');
    drop _n_ok _d_ok nnull_old conv_old;
  run;
  proc sql noprint;
    select count(*) into :_nun trimmed from &out where explained = 'N';
  quit;
  %p18_qadd(ds=&qc, item=recon_unexplained_deltas, n=&_nun, fail=%eval(&_nun > 0));
  %if &_nun > 0 %then
    %p18_fail(msg=%str(reconciliation has unexplained non-missing or distinct count differences - see comb_recon));
%mend p18_recon;

/* ---- MRN scan of CLOSED files --------------------------------------------
   filesmv = name of a global macro variable holding file paths separated by
   a vertical bar. registry = read-only table with ENCRYPTED_MRN. The minimum
   token length is the shortest MRN of the registry, computed here. Only the
   hit count is logged. out = work table fname, hits. Never scan a log that the
   calling program still holds open. */
%macro p18_scan_no_mrn(filesmv=, registry=pdd.pecan_id_registry, out=work.p18_scan_out);
  %local _minlen _nreg;
  %global _p18_scan_hits;
  %let _p18_scan_hits = 0;
  proc sql noprint;
    select count(*), min(length(strip(ENCRYPTED_MRN)))
      into :_nreg trimmed, :_minlen trimmed
    from &registry where strip(ENCRYPTED_MRN) ne '';
  quit;
  %if &_nreg = 0 or %length(&_minlen) = 0 %then %do;
    %p18_fail(msg=%str(MRN scan cannot run - the registry has no non-blank ENCRYPTED_MRN));
    %return;
  %end;
  data work._p18_flist;
    length fname $400;
    do _i = 1 to countw(symget("&filesmv"), '|');
      fname = strip(scan(symget("&filesmv"), _i, '|'));
      if fileexist(fname) then output;
    end;
    keep fname;
  run;
  data &out;
    length fname $400 line $32767 raw $400 tok $64 hits 8;
    if _n_ = 1 then do;
      declare hash h(dataset: "&registry(keep=ENCRYPTED_MRN rename=(ENCRYPTED_MRN=tok) where=(strip(tok) ne ''))");
      h.defineKey('tok');
      h.defineDone();
    end;
    set work._p18_flist;
    infile dummy filevar=fname end=_eof lrecl=32767 truncover;
    hits = 0;
    do while (not _eof);
      input line $char32767.;
      do _j = 1 to countw(line, ' ,;:=()[]"|<>/\' || '09'x);
        raw = scan(line, _j, ' ,;:=()[]"|<>/\' || '09'x);
        if lengthn(raw) >= &_minlen and lengthn(raw) <= 64 then do;
          tok = raw;
          if h.check() = 0 then hits + 1;
        end;
      end;
    end;
    output;
    keep fname hits;
  run;
  proc sql noprint;
    select coalesce(sum(hits), 0) into :_p18_scan_hits trimmed from &out;
  quit;
  %put NOTE: [p18] MRN scan hit count = &_p18_scan_hits;
  %if &_p18_scan_hits > 0 %then
    %p18_fail(msg=%str(MRN scan found a registry MRN in a closed log or QC file - see the scan table hit counts));
%mend p18_scan_no_mrn;

/* ---- PDD-D-34 pct scrub: close the pct back-calculation leak --------------
   A profile row whose n is blank, 1-10 or flagged small (small_cell_flag Y) must
   carry no pct_total / pct_nonmiss: pct / 100 * total_rows would give the count
   back. in = profile table, out = scrubbed copy (WORK), total = dataset row
   count. QC rows: profile_pct_scrubbed (rows changed) and
   profile_pct_implied_small (rows left whose implied count is 1-10, FAIL if >0). */
%macro p18_pct_scrub(in=, out=, total=, qc=);
  %local _nfix _nleft;
  %let _nfix = 0;
  data &out;
    set &in end=_e;
    retain _fix 0;
    if (missing(n) or (n >= 1 and n <= 10) or small_cell_flag = 'Y')
       and (not missing(pct_total) or not missing(pct_nonmiss)) then do;
      pct_total = .;
      pct_nonmiss = .;
      _fix = _fix + 1;
    end;
    if _e then call symputx('_nfix', _fix);
    drop _fix;
  run;
  proc sql noprint;
    select count(*) into :_nleft trimmed from &out
      where pct_total is not missing
        and round(pct_total / 100 * &total) >= 1 and round(pct_total / 100 * &total) <= 10;
  quit;
  %p18_qadd(ds=&qc, item=profile_pct_scrubbed, n=&_nfix);
  %p18_qadd(ds=&qc, item=profile_pct_implied_small, n=&_nleft, fail=%eval(&_nleft > 0));
  %if &_nleft > 0 %then
    %p18_fail(msg=%str(profile pct cells still imply a count of 1-10 after the pct scrub));
%mend p18_pct_scrub;

/* ---- QC dump: stack work.qc_comb_<name> tables into one masked CSV --------
   tables = blank separated names without the qc_comb_ prefix, file = full path.
   Missing tables are skipped. Counts only (n masked 1-10 as <11). */
%macro p18_dump_qc(tables=, file=);
  %local _i _t;
  data work._p18_dump;
    length tbl $32 item $80 n 8 isfail 8;
    stop;
  run;
  %do _i = 1 %to %sysfunc(countw(&tables, %str( )));
    %let _t = %scan(&tables, &_i, %str( ));
    %if %sysfunc(exist(work.qc_comb_&_t)) %then %do;
      data work._p18_d1;
        length tbl $32;
        set work.qc_comb_&_t;
        tbl = "&_t";
      run;
      proc append base=work._p18_dump data=work._p18_d1 force;
      run;
    %end;
  %end;
  %p18_export(ds=work._p18_dump, file=&file, cols=tbl item n isfail, numcols=n);
%mend p18_dump_qc;

%p18_init;
