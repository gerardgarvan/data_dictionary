/*============================================================================
  17_probe_xwalk2.sas  -  Phase 17 PROBE REQUEST PR-2 (counts and metadata only)
  Follow-up to 17_probe_xwalk.sas: 11,149 spine MRNs had no exact match in
  g.pecan_id_xwalk. Why?
  Questions:
   (1) Spine MRN length profile and whitespace counts (same items as PR-1,
       run on the spine pdd.src_s09 and, for comparison, on the xwalk), plus
       a length histogram of both.
   (2) Spine-to-xwalk match counts under looser rules: exact strip(), then
       upcase(strip()), compress() of all whitespace, and both together.
   (3) By spine YEAR: spine rows and distinct MRNs matched and not matched
       (exact rule and the upcase+compress rule), and rows with blank MRN.
   (4) For every pdd.src_s01..s20 column whose SAS name contains MRN
       (found through sashelp.vcolumn): distinct MRNs and overlap with the
       xwalk and with the spine.
   (5) Every dataset in libname g (the master-merge folder of
       docs/reference/20_pecan_id.sas, libname g "&g_path.") with a column
       named like pecan_ID or PCNR_ID: rows, distinct IDs, and overlap of its
       MRN column(s) with the spine MRNs.
  Reads    : pdd.src_s01..s20, pdd.src_s09 (spine), g.* (libname g READ-ONLY)
  Writes   : C:\data_dictionary\.planning\schemas\probe_xwalk2_<yyyymmdd>.md
             Names, types, lengths and counts only. No MRN or ID values and
             no data rows. Counts 1-10 are shown as <11. Lengths are not
             suppressed. Only counts and names reach the log.
  Run      : standalone on the SAS machine, then commit the .md file.
  Notes    : g_path comes from 00_config.sas when 17-01 has added it,
             otherwise the planned value is used. The master-merge folder is
             g itself. To scan a second folder set p17y_g2 below (libname g2,
             read-only).
             Trailing blanks cannot be detected in a fixed-width SAS character
             variable. Trailing tab, CR and LF can, and are counted.
             Looser keys: k_up = upcase(strip(x)), k_ws = compress(x,,'s')
             (removes space, tab, VT, LF, CR), k_both = upcase of k_ws.
============================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;

options mprint nosyntaxcheck noerrorabend;

%let p17y_min = 11;
%let p17y_sec = 1;
%let p17y_out = C:\data_dictionary\.planning\schemas\probe_xwalk2_%sysfunc(today(), yymmddn8.).md;
%let p17y_gdef = P:\PeCAN Master Data\Gerard\Master_Renamed_same_format_accross\merge;
%let p17y_g2 =;

/* Suppressed display of a numeric: missing -> -, 1-10 -> <11, else comma */
%macro p17y_sup(x);
  ifc(missing(&x), '-', ifc(0 < &x < &p17y_min, "<&p17y_min", strip(put(&x, comma15.))))
%mend p17y_sup;

/* Append one result row to work.p17y_res. Label must not contain commas or quotes.
   raw=1 writes the number unsuppressed (lengths, not counts). */
%macro p17y_add(item=, num=, raw=0);
  data work.p17y_one;
    length item $160 value $20;
    sec = &p17y_sec;
    item = "&item";
    n = &num;
    if &raw = 1 then value = strip(put(n, comma15.));
    else value = %p17y_sup(n);
    keep sec item value;
  run;
  proc append base=work.p17y_res data=work.p17y_one force;
  run;
%mend p17y_add;

/* Number of columns named &var in &lib..&mem (0 = absent) in &p17y_hc */
%macro p17y_hascol(lib=, mem=, var=);
  %global p17y_hc;
  %let p17y_hc = 0;
  proc sql noprint;
    select count(*) into :p17y_hc trimmed
      from dictionary.columns
      where libname = upcase("&lib") and memname = upcase("&mem")
        and upcase(name) = upcase("&var");
  quit;
%mend p17y_hascol;

/* ---- Q1: MRN profile of &lib..&mem (column ENCRYPTED_MRN) ---- */
%macro p17y_prof(lib=, mem=, key=, tag=);
  %local vl n_rows n_d n_bl n_null n_minl n_maxl n_lead n_trail n_tcl n_ws
         n_embed n_low n_40 n_vl;
  %let vl = 0;
  %let n_rows = 0;
  %let n_d = 0;
  %let n_bl = 0;
  %let n_null = 0;
  %let n_minl = .;
  %let n_maxl = .;
  %let n_lead = 0;
  %let n_trail = 0;
  %let n_tcl = 0;
  %let n_ws = 0;
  %let n_embed = 0;
  %let n_low = 0;
  %let n_40 = 0;
  %let n_vl = 0;

  data work.p17y_lh_&key;
    length len n 8;
    stop;
  run;

  proc sql noprint;
    select length into :vl trimmed
      from dictionary.columns
      where libname = upcase("&lib") and memname = upcase("&mem")
        and upcase(name) = 'ENCRYPTED_MRN' and type = 'char';
  quit;
  %if &vl = 0 %then %do;
    %p17y_add(item=%str(&tag ENCRYPTED_MRN missing or not character - string probes skipped), num=.);
    %return;
  %end;

  proc sql noprint;
    select count(*) into :n_rows trimmed from &lib..&mem;
    select count(distinct strip(ENCRYPTED_MRN)) into :n_d trimmed
      from &lib..&mem
      where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    select min(lengthn(strip(ENCRYPTED_MRN))), max(lengthn(strip(ENCRYPTED_MRN)))
      into :n_minl trimmed, :n_maxl trimmed
      from &lib..&mem
      where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    create table work.p17y_lh_&key as
      select lengthn(strip(ENCRYPTED_MRN)) as len, count(*) as n
        from &lib..&mem
        where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne ''
        group by 1;
  quit;

  data _null_;
    set &lib..&mem end=_eof;
    if missing(ENCRYPTED_MRN) or strip(ENCRYPTED_MRN) = '' then c_bl + 1;
    else do;
      _len = lengthn(ENCRYPTED_MRN);
      if upcase(strip(ENCRYPTED_MRN)) = 'NULL' then c_null + 1;
      if notspace(ENCRYPTED_MRN) > 1 then c_lead + 1;
      if substr(ENCRYPTED_MRN, _len, 1) in ('09'x, '0D'x, '0A'x) then c_trail + 1;
      if findc(ENCRYPTED_MRN, '090D0A'x) > 0 then c_tcl + 1;
      if prxmatch('/\s/', strip(ENCRYPTED_MRN)) then c_ws + 1;
      if prxmatch('/\S\s+\S/', strip(ENCRYPTED_MRN)) then c_embed + 1;
      if prxmatch('/[a-z]/', ENCRYPTED_MRN) then c_low + 1;
      if lengthn(strip(ENCRYPTED_MRN)) = 40 then c_40 + 1;
      if lengthn(strip(ENCRYPTED_MRN)) = &vl then c_vl + 1;
    end;
    if _eof then do;
      call symputx('n_bl', c_bl);
      call symputx('n_null', c_null);
      call symputx('n_lead', c_lead);
      call symputx('n_trail', c_trail);
      call symputx('n_tcl', c_tcl);
      call symputx('n_ws', c_ws);
      call symputx('n_embed', c_embed);
      call symputx('n_low', c_low);
      call symputx('n_40', c_40);
      call symputx('n_vl', c_vl);
    end;
  run;

  %let p17y_sec = 1;
  %p17y_add(item=%str(&tag row count), num=&n_rows);
  %p17y_add(item=%str(&tag distinct strip(ENCRYPTED_MRN) non-blank), num=&n_d);
  %p17y_add(item=%str(&tag blank or missing ENCRYPTED_MRN), num=&n_bl);
  %p17y_add(item=%str(&tag ENCRYPTED_MRN equal to NULL text), num=&n_null);
  %p17y_add(item=%str(&tag declared variable length - not a count), num=&vl, raw=1);
  %p17y_add(item=%str(&tag min lengthn of strip(ENCRYPTED_MRN) - not a count), num=&n_minl, raw=1);
  %p17y_add(item=%str(&tag max lengthn of strip(ENCRYPTED_MRN) - not a count), num=&n_maxl, raw=1);
  %p17y_add(item=%str(&tag leading whitespace), num=&n_lead);
  %p17y_add(item=%str(&tag trailing tab or CR or LF - plain trailing blanks undetectable), num=&n_trail);
  %p17y_add(item=%str(&tag tab or CR or LF anywhere), num=&n_tcl);
  %p17y_add(item=%str(&tag any whitespace character after strip), num=&n_ws);
  %p17y_add(item=%str(&tag embedded whitespace between non-blank characters), num=&n_embed);
  %p17y_add(item=%str(&tag contains lowercase letter a-z), num=&n_low);
  %p17y_add(item=%str(&tag lengthn = 40 - possible truncation), num=&n_40);
  %p17y_add(item=%str(&tag lengthn = declared variable length &vl), num=&n_vl);
%mend p17y_prof;

/* ---- Q2: one match rule. flag is a column of work.p17y_sp2 ---- */
%macro p17y_rule(flag=, lab=);
  %local n_dm n_du n_rm n_ru n_gain;
  proc sql noprint;
    select count(distinct mrn) into :n_dm trimmed
      from work.p17y_sp2 where blank = 0 and &flag = 1;
    select count(distinct mrn) into :n_du trimmed
      from work.p17y_sp2 where blank = 0 and &flag = 0;
    select count(*) into :n_rm trimmed
      from work.p17y_sp2 where blank = 0 and &flag = 1;
    select count(*) into :n_ru trimmed
      from work.p17y_sp2 where blank = 0 and &flag = 0;
    select count(distinct mrn) into :n_gain trimmed
      from work.p17y_sp2 where blank = 0 and &flag = 1 and m_ex = 0;
  quit;
  %p17y_add(item=%str(&lab: spine distinct MRN matched), num=&n_dm);
  %p17y_add(item=%str(&lab: spine distinct MRN not matched), num=&n_du);
  %p17y_add(item=%str(&lab: spine rows matched), num=&n_rm);
  %p17y_add(item=%str(&lab: spine rows not matched), num=&n_ru);
  %p17y_add(item=%str(&lab: distinct MRN gained over exact match), num=&n_gain);
%mend p17y_rule;

/* ---- Q4: one MRN-like column of one pdd.src_sNN ---- */
%macro p17y_src(mem=, col=, typ=, len=);
  %local n_obs n_nb n_d n_x n_xl n_s n_sl;
  %let n_obs = .;
  %let n_nb = .;
  %let n_d = .;
  %let n_x = .;
  %let n_xl = .;
  %let n_s = .;
  %let n_sl = .;
  %if %upcase(&typ) = CHAR %then %do;
    proc sql noprint;
      select count(*) into :n_obs trimmed from pdd.&mem;
      select count(*) into :n_nb trimmed
        from pdd.&mem
        where not missing("&col"n) and strip("&col"n) ne '';
      create table work.p17y_d as
        select distinct strip("&col"n) as mrn length=200,
               upcase(compress("&col"n,,'s')) as kb length=200
          from pdd.&mem
          where not missing("&col"n) and strip("&col"n) ne '';
      select count(*) into :n_d trimmed from work.p17y_d;
      select count(*) into :n_x trimmed
        from work.p17y_d as a
        where a.mrn in (select mrn from work.p17y_xw);
      select count(*) into :n_xl trimmed
        from work.p17y_d as a
        where a.kb in (select k_both from work.p17y_xw);
      select count(*) into :n_s trimmed
        from work.p17y_d as a
        where a.mrn in (select mrn from work.p17y_sd);
      select count(*) into :n_sl trimmed
        from work.p17y_d as a
        where a.kb in (select k_both from work.p17y_sd);
    quit;
  %end;
  data work.p17y_one4;
    length mem $32 col $128 typ $4;
    mem = "&mem";
    col = "&col";
    typ = "&typ";
    len = &len;
    n_obs = &n_obs;
    n_nb = &n_nb;
    n_d = &n_d;
    n_x = &n_x;
    n_xl = &n_xl;
    n_s = &n_s;
    n_sl = &n_sl;
  run;
  proc append base=work.p17y_t4 data=work.p17y_one4 force;
  run;
%mend p17y_src;

%macro p17y_q4;
  %local i n4 nm ncols;
  data work.p17y_c4;
    set sashelp.vcolumn(keep=libname memname memtype name type length
                        where=(libname = 'PDD' and memtype = 'DATA'));
    if prxmatch('/^SRC_S(0[1-9]|1[0-9]|20)$/', strip(memname))
       and prxmatch('/MRN/i', name);
  run;
  proc sort data=work.p17y_c4;
    by memname name;
  run;

  data work.p17y_t4;
    length mem $32 col $128 typ $4 len n_obs n_nb n_d n_x n_xl n_s n_sl 8;
    stop;
  run;

  /* member presence and number of MRN-like columns per member */
  %let p17y_sec = 4;
  %do i = 1 %to 20;
    %let nm = src_s%sysfunc(putn(&i, z2.));
    %if %sysfunc(exist(pdd.&nm)) = 0 %then %do;
      %p17y_add(item=%str(pdd.&nm dataset absent), num=.);
    %end;
    %else %do;
      proc sql noprint;
        select count(*) into :ncols trimmed
          from work.p17y_c4 where upcase(memname) = upcase("src_s%sysfunc(putn(&i, z2.))");
      quit;
      %p17y_add(item=%str(pdd.src_s%sysfunc(putn(&i, z2.)) MRN-like columns - count), num=&ncols);
    %end;
  %end;

  proc sql noprint;
    select count(*) into :n4 trimmed from work.p17y_c4;
  quit;
  %if &n4 > 0 %then %do;
    data _null_;
      set work.p17y_c4;
      call symputx(cats('m', _n_), memname);
      call symputx(cats('c', _n_), name);
      call symputx(cats('t', _n_), type);
      call symputx(cats('l', _n_), length);
    run;
    %do i = 1 %to &n4;
      %p17y_src(mem=&&m&i, col=&&c&i, typ=&&t&i, len=&&l&i);
    %end;
  %end;
%mend p17y_q4;

/* ---- Q5: one (dataset, ID column, MRN column) ---- */
%macro p17y_g5one(lib=, mem=, idc=, idt=, mrc=);
  %local n_rows n_did n_imiss n_md n_ms n_msl;
  %let n_rows = .;
  %let n_did = .;
  %let n_imiss = .;
  %let n_md = .;
  %let n_ms = .;
  %let n_msl = .;
  proc sql noprint;
    select count(*) into :n_rows trimmed from &lib..&mem;
    select count(distinct "&idc"n) into :n_did trimmed from &lib..&mem;
    select sum(missing("&idc"n)) into :n_imiss trimmed from &lib..&mem;
  quit;
  %if %length(&mrc) > 0 %then %do;
    proc sql noprint;
      create table work.p17y_d5 as
        select distinct strip("&mrc"n) as mrn length=200,
               upcase(compress("&mrc"n,,'s')) as kb length=200
          from &lib..&mem
          where not missing("&mrc"n) and strip("&mrc"n) ne '';
      select count(*) into :n_md trimmed from work.p17y_d5;
      select count(*) into :n_ms trimmed
        from work.p17y_d5 as a
        where a.mrn in (select mrn from work.p17y_sd);
      select count(*) into :n_msl trimmed
        from work.p17y_d5 as a
        where a.kb in (select k_both from work.p17y_sd);
    quit;
  %end;
  data work.p17y_one5;
    length lib $8 mem $32 idc $128 idt $4 mrc $128;
    lib = "&lib";
    mem = "&mem";
    idc = "&idc";
    idt = "&idt";
    mrc = "&mrc";
    n_rows = &n_rows;
    n_did = &n_did;
    n_imiss = &n_imiss;
    n_md = &n_md;
    n_ms = &n_ms;
    n_msl = &n_msl;
  run;
  proc append base=work.p17y_t5 data=work.p17y_one5 force;
  run;
%mend p17y_g5one;

%macro p17y_q5;
  %local i n5;
  data work.p17y_i5;
    set sashelp.vcolumn(keep=libname memname memtype name type
                        where=(libname in ('G', 'G2') and memtype = 'DATA'));
    if prxmatch('/(PECAN|PCNR)_?ID/i', strip(name));
    rename name = idcol type = idtype;
  run;
  data work.p17y_m5;
    set sashelp.vcolumn(keep=libname memname memtype name type
                        where=(libname in ('G', 'G2') and memtype = 'DATA' and type = 'char'));
    if prxmatch('/MRN/i', name);
    rename name = mrncol;
  run;
  proc sql noprint;
    create table work.p17y_g5 as
      select a.libname, a.memname, a.idcol, a.idtype, b.mrncol
        from work.p17y_i5 as a left join work.p17y_m5 as b
          on a.libname = b.libname and a.memname = b.memname
        order by a.libname, a.memname, a.idcol, b.mrncol;
    select count(*) into :n5 trimmed from work.p17y_g5;
  quit;

  data work.p17y_t5;
    length lib $8 mem $32 idc $128 idt $4 mrc $128
           n_rows n_did n_imiss n_md n_ms n_msl 8;
    stop;
  run;

  %if &n5 > 0 %then %do;
    data _null_;
      set work.p17y_g5;
      call symputx(cats('gl', _n_), libname);
      call symputx(cats('gm', _n_), memname);
      call symputx(cats('gi', _n_), idcol);
      call symputx(cats('gt', _n_), idtype);
      call symputx(cats('gr', _n_), mrncol);
    run;
    %do i = 1 %to &n5;
      %p17y_g5one(lib=&&gl&i, mem=&&gm&i, idc=&&gi&i, idt=&&gt&i, mrc=&&gr&i);
    %end;
  %end;
%mend p17y_q5;

/* ---- report writers ---- */
%macro p17y_wsec(sec=, title=);
  data _null_;
    file "&p17y_out." encoding='utf-8' mod;
    put ' ';
    put "## &title";
    put ' ';
    put '|item|value|';
    put '|---|---|';
  run;
  data _null_;
    set work.p17y_res(where=(sec = &sec));
    file "&p17y_out." encoding='utf-8' mod;
    length line $400;
    line = cats('|', item, '|', value, '|');
    put line;
  run;
%mend p17y_wsec;

%macro p17y_run();
  %local gp vl_sp vl_xw yexpr n_sp_rows;

  /* ---- open g read-only (and optional g2) ---- */
  %if %symexist(g_path) %then %let gp = &g_path;
  %else %let gp = &p17y_gdef;
  libname g base "&gp." access=readonly;
  %if %sysfunc(libref(g)) ne 0 %then %do;
    %put ERROR: [17_probe_xwalk2] libname g could not be assigned - nothing probed;
    %return;
  %end;
  %if %length(&p17y_g2) > 0 %then %do;
    libname g2 base "&p17y_g2." access=readonly;
  %end;
  %if %sysfunc(exist(g.pecan_id_xwalk)) = 0 %then %do;
    %put ERROR: [17_probe_xwalk2] g.pecan_id_xwalk does not exist - nothing probed;
    %return;
  %end;
  %if %sysfunc(exist(pdd.src_s09)) = 0 %then %do;
    %put ERROR: [17_probe_xwalk2] pdd.src_s09 does not exist - nothing probed;
    %return;
  %end;

  proc datasets library=work nolist;
    delete p17y_res;
  quit;

  /* ---- Q1: profiles of spine and xwalk ---- */
  %let p17y_sec = 1;
  %p17y_prof(lib=pdd, mem=src_s09, key=spine, tag=%str(spine pdd.src_s09:));
  %p17y_prof(lib=g, mem=pecan_id_xwalk, key=xwalk, tag=%str(xwalk g.pecan_id_xwalk:));
  %p17y_hascol(lib=pdd, mem=src_s09, var=ENCRYPTED_MRN);
  %let vl_sp = &p17y_hc;
  %p17y_hascol(lib=g, mem=pecan_id_xwalk, var=ENCRYPTED_MRN);
  %let vl_xw = &p17y_hc;
  %if &vl_sp = 0 or &vl_xw = 0 %then %do;
    %put ERROR: [17_probe_xwalk2] ENCRYPTED_MRN missing on the spine or the xwalk - Q2 to Q5 skipped;
    %return;
  %end;

  proc sql noprint;
    create table work.p17y_lh as
      select coalesce(a.len, b.len) as len, a.n as n_sp, b.n as n_xw
        from work.p17y_lh_spine as a full join work.p17y_lh_xwalk as b
          on a.len = b.len
        order by 1;
  quit;

  /* ---- build keyed work tables (distinct values stay in WORK) ---- */
  %p17y_hascol(lib=pdd, mem=src_s09, var=YEAR);
  %if &p17y_hc = 0 %then %do;
    %put ERROR: [17_probe_xwalk2] YEAR not on pdd.src_s09 - year table will show missing only;
    %let yexpr = .;
  %end;
  %else %let yexpr = YEAR;

  proc sql noprint;
    create table work.p17y_sp as
      select strip(ENCRYPTED_MRN) as mrn length=200,
             upcase(strip(ENCRYPTED_MRN)) as k_up length=200,
             compress(ENCRYPTED_MRN,,'s') as k_ws length=200,
             upcase(compress(ENCRYPTED_MRN,,'s')) as k_both length=200,
             &yexpr as yr,
             (missing(ENCRYPTED_MRN) or strip(ENCRYPTED_MRN) = '') as blank
        from pdd.src_s09;
    create table work.p17y_xw as
      select distinct strip(ENCRYPTED_MRN) as mrn length=200,
             upcase(strip(ENCRYPTED_MRN)) as k_up length=200,
             compress(ENCRYPTED_MRN,,'s') as k_ws length=200,
             upcase(compress(ENCRYPTED_MRN,,'s')) as k_both length=200
        from g.pecan_id_xwalk
        where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    create table work.p17y_sd as
      select distinct mrn, k_up, k_ws, k_both
        from work.p17y_sp where blank = 0;
    create table work.p17y_sp2 as
      select a.*,
             (a.mrn in (select mrn from work.p17y_xw)) as m_ex,
             (a.k_up in (select k_up from work.p17y_xw)) as m_up,
             (a.k_ws in (select k_ws from work.p17y_xw)) as m_ws,
             (a.k_both in (select k_both from work.p17y_xw)) as m_both
        from work.p17y_sp as a;
  quit;

  /* ---- Q2: match counts under looser rules ---- */
  %let p17y_sec = 2;
  %local n_xk n_xu n_xw n_xb n_sk n_su n_sw n_sb;
  proc sql noprint;
    select count(distinct mrn), count(distinct k_up), count(distinct k_ws), count(distinct k_both)
      into :n_xk trimmed, :n_xu trimmed, :n_xw trimmed, :n_xb trimmed
      from work.p17y_xw;
    select count(distinct mrn), count(distinct k_up), count(distinct k_ws), count(distinct k_both)
      into :n_sk trimmed, :n_su trimmed, :n_sw trimmed, :n_sb trimmed
      from work.p17y_sd;
  quit;
  %p17y_add(item=%str(xwalk distinct MRN exact), num=&n_xk);
  %p17y_add(item=%str(xwalk distinct after upcase - fewer means case collisions), num=&n_xu);
  %p17y_add(item=%str(xwalk distinct after compress whitespace), num=&n_xw);
  %p17y_add(item=%str(xwalk distinct after upcase and compress), num=&n_xb);
  %p17y_add(item=%str(spine distinct MRN exact), num=&n_sk);
  %p17y_add(item=%str(spine distinct after upcase), num=&n_su);
  %p17y_add(item=%str(spine distinct after compress whitespace), num=&n_sw);
  %p17y_add(item=%str(spine distinct after upcase and compress), num=&n_sb);
  %p17y_rule(flag=m_ex, lab=%str(rule exact strip));
  %p17y_rule(flag=m_up, lab=%str(rule upcase(strip)));
  %p17y_rule(flag=m_ws, lab=%str(rule compress all whitespace));
  %p17y_rule(flag=m_both, lab=%str(rule upcase and compress));

  /* ---- Q3: by spine YEAR ---- */
  proc sql noprint;
    create table work.p17y_y1 as
      select yr, count(*) as r_all, sum(blank) as r_bl,
             sum(blank = 0 and m_ex = 1) as r_exm,
             sum(blank = 0 and m_ex = 0) as r_exu,
             sum(blank = 0 and m_both = 1) as r_bom,
             sum(blank = 0 and m_both = 0) as r_bou
        from work.p17y_sp2 group by yr;
    create table work.p17y_y2 as
      select yr, count(distinct mrn) as d_exm
        from work.p17y_sp2 where blank = 0 and m_ex = 1 group by yr;
    create table work.p17y_y3 as
      select yr, count(distinct mrn) as d_exu
        from work.p17y_sp2 where blank = 0 and m_ex = 0 group by yr;
    create table work.p17y_y4 as
      select yr, count(distinct mrn) as d_bom
        from work.p17y_sp2 where blank = 0 and m_both = 1 group by yr;
    create table work.p17y_y5 as
      select yr, count(distinct mrn) as d_bou
        from work.p17y_sp2 where blank = 0 and m_both = 0 group by yr;
    create table work.p17y_yr as
      select a.*, b.d_exm, c.d_exu, d.d_bom, e.d_bou
        from work.p17y_y1 as a
          left join work.p17y_y2 as b on a.yr = b.yr
          left join work.p17y_y3 as c on a.yr = c.yr
          left join work.p17y_y4 as d on a.yr = d.yr
          left join work.p17y_y5 as e on a.yr = e.yr
        order by a.yr;
  quit;

  /* ---- Q4 and Q5 ---- */
  %p17y_q4;
  %p17y_q5;

  /* ---- write the markdown (names and counts only) ---- */
  data _null_;
    file "&p17y_out." encoding='utf-8';
    _d = today();
    put '# Probe: xwalk vs spine, follow-up (PR-2)';
    put ' ';
    put 'Metadata and counts only. No MRN or ID values. Counts 1-10 shown as <11.';
    put 'Written by sas/17_probe_xwalk2.sas on ' _d yymmdd10. '.';
    put 'Looser keys: upcase(strip(x)), compress(x,,"s") removing all whitespace, and both.';
    put "Lengths and declared lengths are not counts and are not suppressed.";
  run;

  %p17y_wsec(sec=1, title=%str(1. MRN profile: spine and xwalk));

  data _null_;
    file "&p17y_out." encoding='utf-8' mod;
    put ' ';
    put '### 1b. Length histogram of strip(ENCRYPTED_MRN)';
    put ' ';
    put '|length|spine rows|xwalk rows|';
    put '|---|---|---|';
  run;
  data _null_;
    set work.p17y_lh;
    file "&p17y_out." encoding='utf-8' mod;
    length line $400;
    line = cats('|', len, '|', %p17y_sup(n_sp), '|', %p17y_sup(n_xw), '|');
    put line;
  run;

  %p17y_wsec(sec=2, title=%str(2. Spine to xwalk match under looser rules));

  data _null_;
    file "&p17y_out." encoding='utf-8' mod;
    put ' ';
    put '## 3. By spine YEAR (rows and distinct MRN; distinct MRN can repeat across years)';
    put ' ';
    put '|year|rows|blank MRN rows|exact matched rows|exact unmatched rows|exact matched distinct|exact unmatched distinct|upcase+compress matched rows|upcase+compress unmatched rows|upcase+compress matched distinct|upcase+compress unmatched distinct|';
    put '|---|---|---|---|---|---|---|---|---|---|---|';
  run;
  data _null_;
    set work.p17y_yr;
    file "&p17y_out." encoding='utf-8' mod;
    length line $800 ytxt $12;
    ytxt = ifc(missing(yr), 'missing', strip(put(yr, best12.)));
    line = cats('|', ytxt, '|', %p17y_sup(r_all), '|', %p17y_sup(r_bl), '|',
                %p17y_sup(r_exm), '|', %p17y_sup(r_exu), '|',
                %p17y_sup(d_exm), '|', %p17y_sup(d_exu), '|',
                %p17y_sup(r_bom), '|', %p17y_sup(r_bou), '|',
                %p17y_sup(d_bom), '|', %p17y_sup(d_bou), '|');
    put line;
  run;

  %p17y_wsec(sec=4, title=%str(4. pdd.src_s01..s20 MRN-like columns: members));

  data _null_;
    file "&p17y_out." encoding='utf-8' mod;
    put ' ';
    put '### 4b. Columns with MRN in the SAS name (distinct MRN, overlap with xwalk and spine)';
    put ' ';
    put '|member|column|type|length|rows|non-blank|distinct|in xwalk exact|in xwalk upcase+compress|in spine exact|in spine upcase+compress|';
    put '|---|---|---|---|---|---|---|---|---|---|---|';
  run;
  data _null_;
    set work.p17y_t4;
    file "&p17y_out." encoding='utf-8' mod;
    length line $800;
    line = cats('|', mem, '|', col, '|', typ, '|', len, '|', %p17y_sup(n_obs), '|',
                %p17y_sup(n_nb), '|', %p17y_sup(n_d), '|', %p17y_sup(n_x), '|',
                %p17y_sup(n_xl), '|', %p17y_sup(n_s), '|', %p17y_sup(n_sl), '|');
    put line;
  run;

  data _null_;
    file "&p17y_out." encoding='utf-8' mod;
    put ' ';
    put '## 5. Datasets in libname g (and g2 if set) with a pecan_ID or PCNR_ID named column';
    put ' ';
    put 'MRN-named = character column with MRN in its name. A blank MRN column means none found.';
    put ' ';
    put '|lib|dataset|ID column|ID type|rows|distinct IDs|missing IDs|MRN column|distinct MRN|MRN in spine exact|MRN in spine upcase+compress|';
    put '|---|---|---|---|---|---|---|---|---|---|---|';
  run;
  data _null_;
    set work.p17y_t5;
    file "&p17y_out." encoding='utf-8' mod;
    length line $800;
    line = cats('|', lib, '|', mem, '|', idc, '|', idt, '|', %p17y_sup(n_rows), '|',
                %p17y_sup(n_did), '|', %p17y_sup(n_imiss), '|', mrc, '|',
                %p17y_sup(n_md), '|', %p17y_sup(n_ms), '|', %p17y_sup(n_msl), '|');
    put line;
  run;
  %put NOTE: [17_probe_xwalk2] report written to &p17y_out;
%mend p17y_run;

%p17y_run();

libname g clear;
libname g2 clear;
