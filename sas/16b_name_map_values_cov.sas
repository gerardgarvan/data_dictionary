/*==========================================================================
  Program : 16b_name_map_values_cov.sas
  Phase   : 16 (name map extension), plan 16-04
  Purpose : MAP-02 evidence: value distributions of the new and the old
            column of every candidate pair, side by side (levels up to 30
            with counts, else summary rows). MAP-04: first and last
            surgical year, years present and contributing sources for every
            PCNR variable and every pending column (key PENDING:<name_key>).
            Old sources take the year from the spine (pdd.src_s09 YEAR by
            norm_psid); new files use their own YEAR column. Rows without a
            year are counted in NO_YEAR and never dropped. Years are read
            from the data at run time.
            Non-missing follows Phase 5: not missing, and NULL (any case)
            counts as missing for char columns of type-conflict variables.
            Placeholders count as data. No value is printed to the log.
  Inputs  : pdd.name_map_ext, pdd.name_map_vars_ext,
            pdd.qc_map_ext_candidates (16a), pdd.src_s01..s20,
            pdd.nsrc_s21..s23 (15c)
  Outputs : pdd.qc_map_ext_values, pdd.name_map_coverage,
            pdd.name_map_vars_coverage
            &exchange_path\name_map_ext_values.csv, name_map_coverage.csv,
            name_map_vars_coverage.csv
  Status  : PENDING SAS RUN; needs 16a outputs and pdd.nsrc_s21..s23
==========================================================================*/

/* ============================================================
   SECTION 0 -- %include, %pdd_lib
   ============================================================ */

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;
options validvarname=any nomprint nosymbolgen;


/* ============================================================
   SECTION 1 -- Utility macros
   ============================================================ */

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\16b_name_map_values_cov.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* ERROR line first, while the log is still routed to the program log file,
   then restore the log and echo it once more to the SAS Log window. */
%macro fail_out(msg=);
  %put ERROR: [16b_name_map_values_cov] &msg;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [16b_name_map_values_cov] &msg;
  %abort cancel;
%mend fail_out;

%macro _note_written_ds(ds=, label=);
  %local _nw;
  %let _nw = 0;
  %if %sysfunc(exist(&ds)) %then %do;
    proc sql noprint;
      select count(*) into :_nw trimmed from &ds;
    quit;
    %if &_nw > 0 %then
      %put NOTE: [16b_name_map_values_cov] &label written (&_nw rows);
    %else
      %put WARNING: [16b_name_map_values_cov] &label written but has 0 rows;
  %end;
  %else
    %put WARNING: [16b_name_map_values_cov] &label was NOT written;
%mend _note_written_ds;

%check_encoding;
%check_pdd_lib;


/* ============================================================
   SECTION 2 -- Preconditions
   ============================================================ */

/* Assert that every column in the space separated list exists in lib.mem */
%macro p16b_need_cols(lib=, mem=, cols=);
  %local _i _c _n;
  %let _i = 1;
  %let _c = %scan(&cols, &_i, %str( ));
  %do %while(%length(&_c) > 0);
    %let _n = 0;
    proc sql noprint;
      select count(*) into :_n trimmed
      from dictionary.columns
      where libname = upcase("&lib") and memname = upcase("&mem")
        and upcase(name) = upcase("&_c");
    quit;
    %if &_n ne 1 %then
      %fail_out(msg=%str(p16b_preconditions: column &_c missing in &lib..&mem));
    %let _i = %eval(&_i + 1);
    %let _c = %scan(&cols, &_i, %str( ));
  %end;
%mend p16b_need_cols;

%macro p16b_preconditions;
  %local _i _m _t _nr _nd _nmap _dsl;
  %let _nr = -1; %let _nd = -2; %let _nmap = -1;
  %let _dsl = src_s09 nsrc_s21 nsrc_s22 nsrc_s23;
  %if not %sysfunc(exist(pdd.name_map_ext)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.name_map_ext missing -- run 16a));
  %if not %sysfunc(exist(pdd.name_map_vars_ext)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.name_map_vars_ext missing -- run 16a));
  %if not %sysfunc(exist(pdd.qc_map_ext_candidates)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.qc_map_ext_candidates missing -- run 16a));
  %if not %sysfunc(exist(pdd.src_s09)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.src_s09 (spine) missing));
  %if not %sysfunc(exist(pdd.nsrc_s21)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.nsrc_s21 missing -- run 15c));
  %if not %sysfunc(exist(pdd.nsrc_s22)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.nsrc_s22 missing -- run 15c));
  %if not %sysfunc(exist(pdd.nsrc_s23)) %then
    %fail_out(msg=%str(p16b_preconditions: pdd.nsrc_s23 missing -- run 15c));

  %p16b_need_cols(lib=pdd, mem=name_map_ext,
    cols=s_code col_order sas_name status pcnr_name name_key);
  %p16b_need_cols(lib=pdd, mem=name_map_vars_ext,
    cols=pcnr_name type_conflict s_codes_contributing);
  %p16b_need_cols(lib=pdd, mem=qc_map_ext_candidates,
    cols=pair_id s_code_new col_order_new pcnr_name_old);

  proc sql noprint;
    select count(*) into :_nmap trimmed from pdd.name_map_ext;
  quit;
  %if &_nmap ne 5077 %then
    %fail_out(msg=%str(p16b_preconditions: pdd.name_map_ext has &_nmap rows -- expected 5077));

  /* YEAR must be numeric where it is used; no silent parse */
  %do _i = 1 %to 4;
    %let _m = %scan(&_dsl, &_i, %str( ));
    %let _t = ;
    proc sql noprint;
      select type into :_t trimmed
      from dictionary.columns
      where libname = 'PDD' and memname = upcase("&_m")
        and upcase(name) = 'YEAR';
    quit;
    %if "&_t" ne "num" %then
      %fail_out(msg=%str(p16b_preconditions: YEAR in pdd.&_m is not numeric (type=&_t)));
  %end;

  /* Spine norm_psid must be unique (PDD-D-17) */
  proc sql noprint;
    select count(*), count(distinct norm_psid)
      into :_nr trimmed, :_nd trimmed
    from pdd.src_s09;
  quit;
  %if &_nr ne &_nd %then
    %fail_out(msg=%str(p16b_preconditions: spine norm_psid not unique or blank (rows=&_nr distinct=&_nd)));

  %route_log;
  %put NOTE: [16b_name_map_values_cov] === Phase 16 plan 04 starting ===;
  %put NOTE: [16b_name_map_values_cov] name_map_ext rows=&_nmap spine rows=&_nr;

  proc datasets lib=pdd nolist nowarn;
    delete qc_map_ext_values name_map_coverage name_map_vars_coverage;
  quit;
%mend p16b_preconditions;


/* ============================================================
   SECTION 3 -- Value distributions per candidate pair
   ============================================================ */

/* One column of one side of one pair. Reads the driving row, runs PROC FREQ
   and appends LEVEL rows (levels <= 30) or summary rows to work.p16b_values.
   Nothing but counts is written to the log. */
%macro p16b_values_one(seq=);
  %local _pid _side _sc _co _sas _ds _mem _vn _vt _nlev _nmiss _nn _mn _mx;
  %let _pid = ; %let _side = ; %let _sc = ; %let _co = ;
  %let _sas = ; %let _ds = ; %let _vt = ;
  %let _nlev = 0; %let _nmiss = 0; %let _nn = 0; %let _mn = ; %let _mx = ;
  proc sql noprint;
    select pair_id, side, s_code, col_order, strip(sas_name), ds
      into :_pid trimmed, :_side trimmed, :_sc trimmed, :_co trimmed,
           :_sas trimmed, :_ds trimmed
    from work.p16b_sides
    where seq = &seq;
  quit;
  %let _mem = %scan(&_ds, 2, .);
  proc sql noprint;
    select type into :_vt trimmed
    from dictionary.columns
    where libname = 'PDD' and memname = upcase("&_mem")
      and upcase(name) = upcase("&_sas");
  quit;
  %if %length(&_vt) = 0 %then
    %fail_out(msg=%str(p16b_values_one: column &_sas not found in &_ds));
  %let _vn = %sysfunc(nliteral(&_sas));

  proc freq data=&_ds noprint;
    tables &_vn / missing out=work.p16b_f(rename=(&_vn=_lv));
  run;

  proc sql noprint;
    select count(*) into :_nlev trimmed
      from work.p16b_f as f where not missing(f._lv);
    select coalesce(sum(f.count), 0) into :_nmiss trimmed
      from work.p16b_f as f where missing(f._lv);
    select coalesce(sum(f.count), 0) into :_nn trimmed
      from work.p16b_f as f where not missing(f._lv);
  %if "&_vt" = "num" %then %do;
    select put(min(f._lv), best32.), put(max(f._lv), best32.)
      into :_mn trimmed, :_mx trimmed
      from work.p16b_f as f where not missing(f._lv);
  %end;
  %else %do;
    select put(min(lengthn(strip(f._lv))), best32.),
           put(max(lengthn(strip(f._lv))), best32.)
      into :_mn trimmed, :_mx trimmed
      from work.p16b_f as f where not missing(f._lv);
  %end;
  quit;

  /* Summary rows: always DISTINCT, N_MISSING and N; range rows by type */
  data work.p16b_x;
    length row_type $10 level $200 n 8;
    row_type = 'DISTINCT';  level = ''; n = &_nlev;  output;
    row_type = 'N_MISSING'; level = ''; n = &_nmiss; output;
    row_type = 'N';         level = ''; n = &_nn;    output;
  %if "&_vt" = "num" %then %do;
    row_type = 'MIN';       level = "&_mn"; n = .;   output;
    row_type = 'MAX';       level = "&_mx"; n = .;   output;
  %end;
  %else %do;
    row_type = 'MINLEN';    level = "&_mn"; n = .;   output;
    row_type = 'MAXLEN';    level = "&_mx"; n = .;   output;
  %end;
  run;

  /* LEVEL rows only when 30 or fewer distinct non-missing levels */
  %if &_nlev <= 30 %then %do;
    data work.p16b_l;
      set work.p16b_f;
      length row_type $10 level $200 n 8;
      row_type = 'LEVEL';
      if missing(_lv) then level = '(missing)';
      else level = strip(vvalue(_lv));
      n = count;
      keep row_type level n;
    run;
  %end;

  data work.p16b_o;
    length pair_id 8 side $3 s_code $8 col_order 8 sas_name $32
           row_type $10 level $200 n 8;
    set work.p16b_x
  %if &_nlev <= 30 %then %do;
        work.p16b_l
  %end;
        ;
    pair_id = &_pid;
    side = "&_side";
    s_code = "&_sc";
    col_order = &_co;
    sas_name = "&_sas";
  run;

  proc append base=work.p16b_values data=work.p16b_o;
  run;

  %put NOTE: [16b_name_map_values_cov] pair=&_pid side=&_side s_code=&_sc levels=&_nlev;
%mend p16b_values_one;

%macro p16b_values_all;
  %local _n _i;
  %let _n = 0;

  proc sql noprint;
    create table work.p16b_new_keys as
    select distinct c.pair_id, e.name_key
    from pdd.qc_map_ext_candidates as c
         inner join pdd.name_map_ext as e
         on lowcase(strip(e.s_code)) = lowcase(strip(c.s_code_new))
        and e.col_order = c.col_order_new;

    create table work.p16b_sides0 as
    select distinct k.pair_id, 'NEW' as side length=3,
           lowcase(strip(e.s_code)) as s_code length=8,
           e.col_order, strip(e.sas_name) as sas_name length=32
    from work.p16b_new_keys as k
         inner join pdd.name_map_ext as e
         on strip(e.name_key) = strip(k.name_key)
    where lowcase(strip(e.s_code)) in ('s21', 's22', 's23')
    union all
    select distinct c.pair_id, 'OLD' as side length=3,
           lowcase(strip(e.s_code)) as s_code length=8,
           e.col_order, strip(e.sas_name) as sas_name length=32
    from pdd.qc_map_ext_candidates as c
         inner join pdd.name_map_ext as e
         on strip(e.pcnr_name) = strip(c.pcnr_name_old)
    where strip(c.pcnr_name_old) ne ''
      and strip(e.status) = 'PCNR'
      and lowcase(strip(e.s_code)) not in ('s21', 's22', 's23');
  quit;

  proc sort data=work.p16b_sides0;
    by pair_id side s_code col_order;
  run;

  data work.p16b_sides;
    set work.p16b_sides0;
    length ds $24;
    if side = 'NEW' then ds = cats('pdd.nsrc_', s_code);
    else ds = cats('pdd.src_', s_code);
    seq = _n_;
  run;

  proc sql noprint;
    select count(*) into :_n trimmed from work.p16b_sides;
  quit;
  %put NOTE: [16b_name_map_values_cov] value passes to run: &_n;

  %do _i = 1 %to &_n;
    %p16b_values_one(seq=&_i);
  %end;

  /* Contract column order; header-only file when there are no candidates */
  %if &_n = 0 %then %do;
    data work.p16b_values;
      length pair_id 8 side $3 s_code $8 col_order 8 sas_name $32
             row_type $10 level $200 n 8;
      stop;
    run;
  %end;

  data pdd.qc_map_ext_values;
    length pair_id 8 side $3 s_code $8 col_order 8 sas_name $32
           row_type $10 level $200 n 8;
    set work.p16b_values;
  run;

  proc export data=pdd.qc_map_ext_values
              outfile="&exchange_path.\name_map_ext_values.csv"
              dbms=csv replace;
  run;

  %_note_written_ds(ds=pdd.qc_map_ext_values, label=pdd.qc_map_ext_values);
%mend p16b_values_all;


/* ============================================================
   SECTION 4 -- Year coverage per (variable, source)
   ============================================================ */

/* Counts non-missing cells per (variable, year) for one source, then rolls
   up to one row per (var_key, s_code). Generated code (FILE + %include):
   the variable list is not known until run time. Old sources take the year
   from the spine by norm_psid (hash); new files use their own YEAR column.
   Rows without a year fall into the NO_YEAR bucket (missing year key). */
%macro p16b_cov_one(sc=);
  %local _isnew _ds _mem _nv _nfound _nk _genf _nobs _bad
         _nvar _nnd _nny _ndy;
  %let _isnew = 0;
  %if "&sc" = "s21" or "&sc" = "s22" or "&sc" = "s23" %then %let _isnew = 1;
  %if &_isnew = 1 %then %let _ds = pdd.nsrc_&sc;
  %else %let _ds = pdd.src_&sc;
  %let _mem = %scan(&_ds, 2, .);
  %let _nv = 0; %let _nfound = -1; %let _nobs = -1; %let _bad = -1;

  /* Variable list: PCNR and pending columns, never norm_psid */
  proc sql noprint;
    create table work.p16b_vl0 as
    select strip(e.sas_name) as sas_name length=32,
           strip(e.pcnr_name) as pcnr_name length=32,
           strip(e.name_key) as name_key length=200,
           coalesce(v.type_conflict, 'N') as type_conflict length=1
    from pdd.name_map_ext as e
         left join pdd.name_map_vars_ext as v
         on strip(v.pcnr_name) = strip(e.pcnr_name)
        and strip(e.pcnr_name) ne ''
    where lowcase(strip(e.s_code)) = "&sc"
      and strip(e.status) in ('PCNR', 'PENDING_DECISION')
      and upcase(strip(e.sas_name)) ne 'NORM_PSID';
  quit;

  proc sort data=work.p16b_vl0 nodupkey;
    by sas_name;
  run;

  data work.p16b_vl;
    set work.p16b_vl0;
    length var_key $210 nlit $70;
    if missing(pcnr_name) then var_key = cats('PENDING:', name_key);
    else var_key = pcnr_name;
    nlit = nliteral(strip(sas_name));
  run;

  proc sql noprint;
    select count(*) into :_nv trimmed from work.p16b_vl;
  quit;
  %if &_nv = 0 %then %do;
    %put NOTE: [16b_name_map_values_cov] &sc has no mapped variables -- skipped;
    %return;
  %end;

  /* Every mapped column must exist in the dataset */
  proc sql noprint;
    select count(*) into :_nfound trimmed
    from work.p16b_vl as v
         inner join dictionary.columns as d
         on upcase(d.name) = upcase(v.sas_name)
    where d.libname = 'PDD' and d.memname = upcase("&_mem");
    select nobs into :_nobs trimmed
    from dictionary.tables
    where libname = 'PDD' and memname = upcase("&_mem");
  quit;
  %if &_nfound ne &_nv %then
    %fail_out(msg=%str(p16b_cov_one: &sc has &_nv mapped columns but &_nfound found in &_ds));
  %let _nk = %eval(&_nv + 5);
  %let _genf = %sysfunc(pathname(work))\p16b_gen_&sc..sas;

  /* Part A: header, SET with KEEP, arrays, length, temporary flag arrays */
  data _null_;
    file "&_genf" lrecl=4000;
    set work.p16b_vl end=_last;
    length _l $4000;
    if _n_ = 1 then do;
      put "data _null_;";
      put "  set &_ds (keep=norm_psid";
    end;
    _l = cat("    ", strip(nlit));
    put _l;
    if _last then do;
%if &_isnew = 1 %then %do;
      put "    YEAR";
%end;
      put "    ) end=_eof;";
      put "  array _an[*] _numeric_;";
      put "  array _ac[*] _character_;";
      put "  length _p16_yr 8 _yr 8 _n 8 _j 8 _rc 8 _tcv 8 _vn $32;";
      put "  array _usn[&_nk] _temporary_;";
      put "  array _usc[&_nk] _temporary_;";
      put "  array _cf[&_nk] _temporary_;";
    end;
  run;

  /* Part B: hashes and one add per mapped variable (type-conflict flag) */
  data _null_;
    file "&_genf" mod lrecl=4000;
    set work.p16b_vl;
    length _l $4000 _nm $80;
    if _n_ = 1 then do;
      put "  if _n_ = 1 then do;";
      put "    declare hash h(ordered:'a');";
      put "    h.defineKey('_vn','_yr');";
      put "    h.defineData('_vn','_yr','_n');";
      put "    h.defineDone();";
      put "    declare hash u();";
      put "    u.defineKey('_vn');";
      put "    u.defineData('_tcv');";
      put "    u.defineDone();";
%if &_isnew = 0 %then %do;
      put "    declare hash sp(dataset:'pdd.src_s09(keep=norm_psid YEAR rename=(YEAR=_p16_yr))');";
      put "    sp.defineKey('norm_psid');";
      put "    sp.defineData('_p16_yr');";
      put "    sp.defineDone();";
%end;
    end;
    _nm = tranwrd(upcase(strip(sas_name)), "'", "''");
    _l = cat("    _rc = u.add(key:'", strip(_nm), "', data:",
             ifc(type_conflict = 'Y', '1', '0'), ");");
    put _l;
  run;

  /* Part C: flag loops, per-row counting, output at end of data */
  data _null_;
    file "&_genf" mod lrecl=4000;
    put "    do _j = 1 to dim(_an);";
    put "      _vn = upcase(vname(_an[_j])); _usn[_j] = 0; _tcv = 0;";
    put "      if u.find() = 0 then _usn[_j] = 1;";
    put "    end;";
    put "    do _j = 1 to dim(_ac);";
    put "      _vn = upcase(vname(_ac[_j])); _usc[_j] = 0; _cf[_j] = 0; _tcv = 0;";
    put "      if u.find() = 0 then do; _usc[_j] = 1; _cf[_j] = _tcv; end;";
    put "    end;";
    put "  end;";
%if &_isnew = 1 %then %do;
    put "  _p16_yr = YEAR;";
%end;
%else %do;
    put "  _p16_yr = .;";
    put "  _rc = sp.find();";
%end;
    put "  do _j = 1 to dim(_an);";
    put "    if _usn[_j] then if not missing(_an[_j]) then do;";
    put "      _vn = upcase(vname(_an[_j])); _yr = _p16_yr; _n = 1;";
    put "      if h.find() = 0 then _n = _n + 1;";
    put "      _rc = h.replace();";
    put "    end;";
    put "  end;";
    put "  do _j = 1 to dim(_ac);";
    put "    if _usc[_j] then if not missing(_ac[_j]) then";
    put "      if not (_cf[_j] and upcase(strip(_ac[_j])) = 'NULL') then do;";
    put "      _vn = upcase(vname(_ac[_j])); _yr = _p16_yr; _n = 1;";
    put "      if h.find() = 0 then _n = _n + 1;";
    put "      _rc = h.replace();";
    put "    end;";
    put "  end;";
    put "  if _eof then _rc = h.output(dataset:'work.p16b_hcov_&sc');";
    put "run;";
  run;

  proc datasets lib=work nolist nowarn;
    delete p16b_hcov_&sc;
  quit;

  %include "&_genf";

  /* No rows read at all: write an empty hash result so the roll-up runs */
  %if not %sysfunc(exist(work.p16b_hcov_&sc)) %then %do;
    data work.p16b_hcov_&sc;
      length _vn $32 _yr 8 _n 8;
      stop;
    run;
  %end;

  /* Roll-up per (var_key, s_code) */
  proc sql noprint;
    create table work.p16b_yy as
    select v.var_key, h._yr, sum(h._n) as n
    from work.p16b_vl as v
         inner join work.p16b_hcov_&sc as h
         on upcase(strip(v.sas_name)) = h._vn
    group by v.var_key, h._yr;
  quit;

  proc sort data=work.p16b_yy;
    by var_key _yr;
  run;

  data work.p16b_ro;
    set work.p16b_yy;
    by var_key;
    length years_present $2000;
    retain n_nonmiss n_no_year n_with_year first_year last_year years_present;
    if first.var_key then do;
      n_nonmiss = 0; n_no_year = 0; n_with_year = 0;
      first_year = .; last_year = .; years_present = '';
    end;
    n_nonmiss = n_nonmiss + n;
    if missing(_yr) then n_no_year = n_no_year + n;
    else do;
      n_with_year = n_with_year + n;
      first_year = min(first_year, _yr);
      last_year = max(last_year, _yr);
      years_present = catx(' ', years_present, strip(put(_yr, best12.)));
    end;
    if last.var_key then output;
    keep var_key n_nonmiss n_no_year n_with_year first_year last_year
         years_present;
  run;

  /* Reconcile: years plus NO_YEAR equal the total, and the total cannot
     exceed rows times mapped columns of that variable */
  proc sql noprint;
    select count(*) into :_bad trimmed
    from work.p16b_ro as r
         inner join (select var_key, count(*) as nc
                     from work.p16b_vl group by var_key) as k
         on r.var_key = k.var_key
    where r.n_with_year + r.n_no_year ne r.n_nonmiss
       or r.n_nonmiss > &_nobs * k.nc;
  quit;
  %if &_bad ne 0 %then
    %fail_out(msg=%str(coverage reconcile failed for &sc (&_bad variables)));

  proc sql noprint;
    create table work.p16b_cs as
    select k.var_key, k.pcnr_name, "&sc" as s_code length=8,
           r.first_year, r.last_year, r.years_present,
           coalesce(r.n_nonmiss, 0) as n_nonmiss,
           coalesce(r.n_no_year, 0) as n_nonmiss_no_year,
           case when coalesce(r.n_nonmiss, 0) > 0 then 'DATA'
                else 'NO_DATA' end as status length=7
    from (select distinct var_key, pcnr_name from work.p16b_vl) as k
         left join work.p16b_ro as r
         on r.var_key = k.var_key;
  quit;

  proc append base=work.p16b_cov_all data=work.p16b_cs force;
  run;

  data work.p16b_yy1;
    set work.p16b_yy;
    length s_code $8;
    s_code = "&sc";
    if not missing(_yr);
    keep var_key s_code _yr;
  run;

  proc append base=work.p16b_yy_all data=work.p16b_yy1 force;
  run;

  proc sql noprint;
    select count(*), sum(status = 'NO_DATA'), coalesce(sum(n_nonmiss_no_year), 0)
      into :_nvar trimmed, :_nnd trimmed, :_nny trimmed
      from work.p16b_cs;
    select count(distinct _yr) into :_ndy trimmed
      from work.p16b_yy where not missing(_yr);
  quit;
  %put NOTE: [16b_name_map_values_cov] &sc variables=&_nvar NO_DATA=&_nnd NO_YEAR cells=&_nny distinct years=&_ndy;
%mend p16b_cov_one;


/* ============================================================
   SECTION 5 -- All sources, stack, per-variable rollup
   ============================================================ */

%macro p16b_cov_all;
  %local _nsc _i _sc _nv_ext _nv_cov _nv_dup _nv_miss;
  %let _nsc = 0;
  %let _nv_ext = -1; %let _nv_cov = -2; %let _nv_dup = -1; %let _nv_miss = -1;

  proc sql noprint;
    select distinct lowcase(strip(s_code)) into :p16b_sc1 - :p16b_sc99
    from pdd.name_map_ext
    order by 1;
  quit;
  %let _nsc = &sqlobs;
  %if &_nsc ne 23 %then
    %fail_out(msg=%str(p16b_cov_all: &_nsc source codes in pdd.name_map_ext -- expected 23));

  %do _i = 1 %to &_nsc;
    %let _sc = &&p16b_sc&_i;
    %p16b_cov_one(sc=&_sc);
  %end;

  data pdd.name_map_coverage;
    length var_key $210 pcnr_name $32 s_code $8 first_year 8 last_year 8
           years_present $2000 n_nonmiss 8 n_nonmiss_no_year 8 status $7;
    set work.p16b_cov_all;
  run;

  proc sort data=pdd.name_map_coverage;
    by var_key s_code;
  run;

  /* Per variable: union of years, sources with data */
  proc sort data=work.p16b_yy_all out=work.p16b_yy_u nodupkey;
    by var_key _yr;
  run;

  data work.p16b_vyr;
    set work.p16b_yy_u;
    by var_key;
    length years_present $2000;
    retain first_year last_year years_present;
    if first.var_key then do;
      first_year = .; last_year = .; years_present = '';
    end;
    first_year = min(first_year, _yr);
    last_year = max(last_year, _yr);
    years_present = catx(' ', years_present, strip(put(_yr, best12.)));
    if last.var_key then output;
    keep var_key first_year last_year years_present;
  run;

  data work.p16b_vs;
    set pdd.name_map_coverage;
    by var_key;
    length s_codes_with_data $400 s_codes_all $400;
    retain n_sources_data s_codes_with_data s_codes_all;
    if first.var_key then do;
      n_sources_data = 0; s_codes_with_data = ''; s_codes_all = '';
    end;
    s_codes_all = catx(' ', s_codes_all, s_code);
    if status = 'DATA' then do;
      n_sources_data = n_sources_data + 1;
      s_codes_with_data = catx(' ', s_codes_with_data, s_code);
    end;
    if last.var_key then output;
    keep var_key pcnr_name n_sources_data s_codes_with_data s_codes_all;
  run;

  proc sql noprint;
    create table work.p16b_vc as
    select s.var_key, s.pcnr_name, y.first_year, y.last_year,
           y.years_present, s.n_sources_data, s.s_codes_with_data,
           case when strip(s.pcnr_name) ne ''
                then coalescec(strip(v.s_codes_contributing), s.s_codes_all)
                else s.s_codes_all end as s_codes_contributing length=400,
           case when s.n_sources_data > 0 then 'DATA'
                else 'NO_DATA' end as status length=7
    from work.p16b_vs as s
         left join work.p16b_vyr as y on y.var_key = s.var_key
         left join pdd.name_map_vars_ext as v
         on strip(v.pcnr_name) = strip(s.pcnr_name)
        and strip(s.pcnr_name) ne '';
  quit;

  data pdd.name_map_vars_coverage;
    length var_key $210 pcnr_name $32 first_year 8 last_year 8
           years_present $2000 n_sources_data 8 s_codes_with_data $400
           s_codes_contributing $400 status $7;
    set work.p16b_vc;
  run;

  proc sort data=pdd.name_map_vars_coverage;
    by var_key;
  run;

  /* Every PCNR variable of the extended map has exactly one row */
  proc sql noprint;
    select count(*) into :_nv_ext trimmed from pdd.name_map_vars_ext;
    select count(*) into :_nv_cov trimmed
      from pdd.name_map_vars_coverage where strip(pcnr_name) ne '';
    select count(*) into :_nv_dup trimmed
      from (select var_key from pdd.name_map_vars_coverage
            group by var_key having count(*) > 1);
    select count(*) into :_nv_miss trimmed
      from pdd.name_map_vars_ext as e
      where strip(e.pcnr_name) not in
            (select strip(pcnr_name) from pdd.name_map_vars_coverage);
  quit;
  %if &_nv_ext ne &_nv_cov or &_nv_dup ne 0 or &_nv_miss ne 0 %then
    %fail_out(msg=%str(p16b_cov_all: vars coverage mismatch (map=&_nv_ext coverage=&_nv_cov dup=&_nv_dup missing=&_nv_miss)));
%mend p16b_cov_all;


/* ============================================================
   SECTION 6 -- Exports
   ============================================================ */

%macro p16b_export;
  %local _nvars _nnd _npend;
  %let _nvars = 0; %let _nnd = 0; %let _npend = 0;

  proc export data=pdd.name_map_coverage
              outfile="&exchange_path.\name_map_coverage.csv"
              dbms=csv replace;
  run;

  proc export data=pdd.name_map_vars_coverage
              outfile="&exchange_path.\name_map_vars_coverage.csv"
              dbms=csv replace;
  run;

  proc sql noprint;
    select count(*), sum(status = 'NO_DATA'), sum(strip(pcnr_name) = '')
      into :_nvars trimmed, :_nnd trimmed, :_npend trimmed
      from pdd.name_map_vars_coverage;
  quit;
  %put NOTE: [16b_name_map_values_cov] MAP-04 coverage written: &_nvars variables, &_nnd NO_DATA, &_npend PENDING keys;
  %_note_written_ds(ds=pdd.name_map_coverage, label=pdd.name_map_coverage);
  %_note_written_ds(ds=pdd.name_map_vars_coverage, label=pdd.name_map_vars_coverage);

  proc datasets lib=work nolist nowarn;
    delete p16b_: ;
  quit;
%mend p16b_export;


/* ============================================================
   SECTION 7 -- Run
   ============================================================ */

%p16b_preconditions;
%p16b_values_all;
%p16b_cov_all;
%p16b_export;

%put NOTE: [16b_name_map_values_cov] === Phase 16 plan 04 complete ===;
%restore_log;
