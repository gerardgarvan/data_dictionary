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
   SECTION 7 -- Run
   ============================================================ */

%p16b_preconditions;
%p16b_values_all;

%put NOTE: [16b_name_map_values_cov] === Phase 16 plan 04 values done ===;
%restore_log;
