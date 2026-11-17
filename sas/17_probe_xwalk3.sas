/*============================================================================
  17_probe_xwalk3.sas  -  Phase 17 PROBE REQUEST PR-3 (counts and names only)
  Supports PDD-D-32: K1 PECAN_ID is taken row by row from
  g.MASTER_DATA_HARMONIZED through a surgery-level key. Which key joins
  pdd.src_s09 to it one-to-one, and how many patients carry two pecan_IDs?
  Questions:
   (1) Candidate surgery keys present in BOTH pdd.src_s09 and
       g.MASTER_DATA_HARMONIZED. Candidates are columns found through
       dictionary.columns whose name has PSID, STUDY, SURG, CASE, PRECEDE,
       ENCOUNTER or an ID suffix, kept when the name exists on both sides.
       Each is tried as delivered (raw) and, for character columns, after
       the PDD-D-19 rule (%pdd_norm_psid, norm_psid). Row order (row number
       on each side) is tried last as a last resort. Per key: distinct count
       on each side, matched rows, spine rows matching 0 or more than 1,
       harmonized rows matched by more than 1 spine row. The key giving a
       one-to-one match of all spine rows is named. Keys with fewer distinct
       values than half of their non-missing rows are not joined (listed as
       skipped) so that a low-cardinality column cannot blow up the join.
   (2) With the best key: spine distinct MRN -> number of distinct pecan_IDs
       (histogram 1, 2, 3+); pecan_IDs with more than one spine MRN; total
       implied dup pairs (one pair per two pecan_IDs sharing a spine MRN).
   (3) For the dup pairs: counts by spine YEAR on each side of the pair.
       Side A = the ID that sorts first as text, side B = the other.
   (4) Spine YEAR distribution of the spine MRNs that have no exact match
       in g.pecan_id_xwalk (re-check of PR-2 section 3), and how many of
       them are in a dup pair.
  Also reported on its own line: spine rows with a blank or NULL MRN.
  Reads    : pdd.src_s09 (spine), g.master_data_harmonized, g.pecan_id_xwalk
             (libname g READ-ONLY)
  Writes   : C:\data_dictionary\.planning\schemas\probe_xwalk3_<yyyymmdd>.md
             Names, types, lengths and counts only. No MRN, case ID or
             pecan_ID values and no data rows. Counts 1-10 are shown as <11.
             Lengths are not counts and are not suppressed. Only counts and
             names reach the log.
  Run      : standalone on the SAS machine, then commit the .md file.
  Notes    : g_path comes from 00_config.sas when 17-01 has added it,
             otherwise the planned value is used.
             Report labels are built without putn or other functions inside
             %str, so the PR-2 label error cannot recur.
============================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;

options mprint nosyntaxcheck noerrorabend validvarname=v7;

%let p17z_min = 11;
%let p17z_sec = 1;
%let p17z_out = C:\data_dictionary\.planning\schemas\probe_xwalk3_%sysfunc(today(), yymmddn8.).md;
%let p17z_gdef = P:\PeCAN Master Data\Gerard\Master_Renamed_same_format_accross\merge;
%let p17z_bcol = ;
%let p17z_bmode = ;
%let p17z_bhc = ;
%let p17z_bst = ;
%let p17z_bht = ;
%let p17z_bfull = 0;
%let p17z_cn = ;
%let p17z_ct = ;
%let p17z_s2ok = 0;

/* Suppressed display of a numeric: missing -> -, 1-10 -> <11, else comma */
%macro p17z_sup(x);
  ifc(missing(&x), '-', ifc(0 < &x < &p17z_min, "<&p17z_min", strip(put(&x, comma15.))))
%mend p17z_sup;

/* Append one result row to work.p17z_res. Label has no commas or quotes.
   raw=1 writes the number unsuppressed (lengths, not counts). */
%macro p17z_add(item=, num=, raw=0);
  data work.p17z_one;
    length item $200 value $20;
    sec = &p17z_sec;
    item = "&item";
    n = &num;
    if &raw = 1 then value = strip(put(n, comma15.));
    else value = %p17z_sup(n);
    keep sec item value;
  run;
  proc append base=work.p17z_res data=work.p17z_one force;
  run;
%mend p17z_add;

/* Name (as stored) and type of column &var in &lib..&mem -> p17z_cn p17z_ct
   (both blank when the column is absent) */
%macro p17z_col(lib=, mem=, var=);
  %let p17z_cn = ;
  %let p17z_ct = ;
  proc sql noprint;
    select name, type into :p17z_cn trimmed, :p17z_ct trimmed
      from dictionary.columns
      where libname = upcase("&lib") and upcase(memname) = upcase("&mem")
        and upcase(name) = upcase("&var");
  quit;
%mend p17z_col;

/* One side of a key test: out has p17rid (row number) and p17k (char key).
   mode = raw (as delivered), norm (PDD-D-19 rule, char only), rid (row number) */
%macro p17z_side(lib=, mem=, col=, typ=, mode=, out=);
  %local nobs;
  %if &mode = rid %then %do;
    %let nobs = 0;
    proc sql noprint;
      select count(*) into :nobs trimmed from &lib..&mem;
    quit;
    data &out;
      length p17rid 8 p17k $200;
      do p17rid = 1 to &nobs;
        p17k = strip(put(p17rid, best12.));
        output;
      end;
    run;
  %end;
  %else %do;
    data work.p17z_t0;
      set &lib..&mem(keep=&col);
      p17rid = _n_;
    run;
    %if &mode = norm %then %do;
      %pdd_norm_psid(in=work.p17z_t0, out=work.p17z_t1, idvar=&col);
      data &out(keep=p17rid p17k);
        set work.p17z_t1;
        length p17k $200;
        p17k = norm_psid;
      run;
    %end;
    %else %do;
      data &out(keep=p17rid p17k);
        set work.p17z_t0;
        length p17k $200;
        %if %upcase(&typ) = CHAR %then %do;
          p17k = strip(&col);
        %end;
        %else %do;
          if missing(&col) then p17k = '';
          else p17k = strip(put(&col, best32.));
        %end;
      run;
    %end;
  %end;
%mend p17z_side;

/* ---- Q1: test one key. Appends one row to work.p17z_kt ---- */
%macro p17z_try(sc=, hc=, st=, ht=, mode=);
  %local nrs nrh nns nnh nds ndh r0 r1 rg h0 hg skip;
  %let nrs = .;
  %let nrh = .;
  %let nns = .;
  %let nnh = .;
  %let nds = .;
  %let ndh = .;
  %let r0 = .;
  %let r1 = .;
  %let rg = .;
  %let h0 = .;
  %let hg = .;
  %let skip = 0;
  %p17z_side(lib=pdd, mem=src_s09, col=&sc, typ=&st, mode=&mode, out=work.p17z_a);
  %p17z_side(lib=g, mem=master_data_harmonized, col=&hc, typ=&ht, mode=&mode, out=work.p17z_b);
  proc sql noprint;
    select count(*) into :nrs trimmed from work.p17z_a;
    select count(*) into :nrh trimmed from work.p17z_b;
    select count(*), count(distinct p17k) into :nns trimmed, :nds trimmed
      from work.p17z_a where p17k ne '';
    select count(*), count(distinct p17k) into :nnh trimmed, :ndh trimmed
      from work.p17z_b where p17k ne '';
  quit;
  %if &nns = 0 or &nnh = 0 %then %let skip = 1;
  %else %if %sysevalf(&nds < 0.5 * &nns) or %sysevalf(&ndh < 0.5 * &nnh) %then %let skip = 2;
  %if &skip = 0 %then %do;
    proc sql noprint;
      create table work.p17z_ma as
        select a.p17rid, count(b.p17rid) as nm
          from work.p17z_a as a left join work.p17z_b as b
            on a.p17k = b.p17k and a.p17k ne ''
          group by a.p17rid;
      create table work.p17z_mb as
        select b.p17rid, count(a.p17rid) as nm
          from work.p17z_b as b left join work.p17z_a as a
            on a.p17k = b.p17k and b.p17k ne ''
          group by b.p17rid;
      select sum(nm = 0), sum(nm = 1), sum(nm > 1)
        into :r0 trimmed, :r1 trimmed, :rg trimmed
        from work.p17z_ma;
      select sum(nm = 0), sum(nm > 1)
        into :h0 trimmed, :hg trimmed
        from work.p17z_mb;
    quit;
  %end;
  data work.p17z_kone;
    length scol $128 hcol $128 mode $4 styp $4 htyp $4;
    scol = "&sc";
    hcol = "&hc";
    mode = "&mode";
    styp = "&st";
    htyp = "&ht";
    nrs = &nrs;
    nrh = &nrh;
    nds = &nds;
    ndh = &ndh;
    skip = &skip;
    r0 = &r0;
    r1 = &r1;
    rg = &rg;
    h0 = &h0;
    hg = &hg;
    full = 0;
    if skip = 0 and nrs > 0 and r1 = nrs and hg = 0 and nrs = nrh then full = 1;
  run;
  proc append base=work.p17z_kt data=work.p17z_kone force;
  run;
%mend p17z_try;

%macro p17z_q1;
  %local i nb;
  data work.p17z_cs(rename=(name=sname type=styp length=slen));
    set sashelp.vcolumn(keep=libname memname memtype name type length
                        where=(libname = 'PDD' and memtype = 'DATA'));
    if upcase(memname) = 'SRC_S09';
    if prxmatch('/PSID|STUDY|SURG|CASE|PRECEDE|ENCOUNTER|(^|_)ID$|^ID/i', strip(name));
    ckey = upcase(strip(name));
  run;
  data work.p17z_ch(rename=(name=hname type=htyp length=hlen));
    set sashelp.vcolumn(keep=libname memname memtype name type length
                        where=(libname = 'G' and memtype = 'DATA'));
    if upcase(memname) = 'MASTER_DATA_HARMONIZED';
    if prxmatch('/PSID|STUDY|SURG|CASE|PRECEDE|ENCOUNTER|(^|_)ID$|^ID/i', strip(name));
    ckey = upcase(strip(name));
  run;
  proc sql noprint;
    create table work.p17z_cand as
      select coalesce(a.ckey, b.ckey) as ckey, a.sname, a.styp, a.slen,
             b.hname, b.htyp, b.hlen
        from work.p17z_cs as a full join work.p17z_ch as b
          on a.ckey = b.ckey
        order by 1;
  quit;

  data work.p17z_kt;
    length scol $128 hcol $128 mode $4 styp $4 htyp $4
           nrs nrh nds ndh skip r0 r1 rg h0 hg full 8;
    stop;
  run;

  data work.p17z_both;
    set work.p17z_cand;
    if not missing(sname) and not missing(hname);
  run;
  proc sql noprint;
    select count(*) into :nb trimmed from work.p17z_both;
  quit;
  %if &nb > 0 %then %do;
    data _null_;
      set work.p17z_both;
      call symputx(cats('sc', _n_), sname);
      call symputx(cats('hc', _n_), hname);
      call symputx(cats('st', _n_), styp);
      call symputx(cats('ht', _n_), htyp);
    run;
    %do i = 1 %to &nb;
      %p17z_try(sc=&&sc&i, hc=&&hc&i, st=&&st&i, ht=&&ht&i, mode=raw);
      %if %upcase(&&st&i) = CHAR and %upcase(&&ht&i) = CHAR
          and %upcase(&&sc&i) ne NORM_PSID and %upcase(&&hc&i) ne NORM_PSID %then %do;
        %p17z_try(sc=&&sc&i, hc=&&hc&i, st=&&st&i, ht=&&ht&i, mode=norm);
      %end;
    %end;
  %end;
  /* last resort: row order */
  %p17z_try(sc=%str(row order), hc=%str(row order), st=num, ht=num, mode=rid);

  proc sql noprint;
    create table work.p17z_kts as
      select *, (mode = 'rid') as isrow, (mode = 'norm') as isnorm
        from work.p17z_kt
        where skip = 0
        order by full desc, isrow, r1 desc, isnorm desc;
  quit;
  data _null_;
    set work.p17z_kts(obs=1);
    call symputx('p17z_bcol', scol);
    call symputx('p17z_bhc', hcol);
    call symputx('p17z_bmode', mode);
    call symputx('p17z_bst', styp);
    call symputx('p17z_bht', htyp);
    call symputx('p17z_bfull', full);
  run;
%mend p17z_q1;

/* ---- Q2 to Q3: best key, MRN to pecan_ID, dup pairs, by YEAR ---- */
%macro p17z_s2;
  %local pidc pidt n_j n_jrow n_nopid n_pm n_np1 n_np2 n_np3 n_pp n_nm1 n_nm2
         n_nm3 n_pairs n_pidp n_pidmulti n_common;
  %p17z_col(lib=g, mem=master_data_harmonized, var=pecan_ID);
  %let pidc = &p17z_cn;
  %let pidt = &p17z_ct;
  %if %length(&pidc) = 0 %then %do;
    %p17z_add(item=%str(pecan_ID column not found on g.master_data_harmonized - sections 2 and 3 skipped), num=.);
    %return;
  %end;
  %p17z_side(lib=pdd, mem=src_s09, col=&p17z_bcol, typ=&p17z_bst, mode=&p17z_bmode, out=work.p17z_a);
  %p17z_side(lib=g, mem=master_data_harmonized, col=&p17z_bhc, typ=&p17z_bht, mode=&p17z_bmode, out=work.p17z_b);

  data work.p17z_hp(keep=p17rid pid_c);
    set g.master_data_harmonized(keep=&pidc);
    length pid_c $64;
    p17rid = _n_;
    %if %upcase(&pidt) = CHAR %then %do;
      pid_c = strip(&pidc);
    %end;
    %else %do;
      if missing(&pidc) then pid_c = '';
      else pid_c = strip(put(&pidc, best32.));
    %end;
  run;

  %let p17z_sec = 2;
  %let n_j = .;
  %let n_jrow = .;
  %let n_nopid = .;
  proc sql noprint;
    create table work.p17z_j as
      select a.p17rid as rid_s, b.p17rid as rid_h
        from work.p17z_a as a inner join work.p17z_b as b
          on a.p17k = b.p17k
        where a.p17k ne '';
    select count(*), sum(rid_s = rid_h) into :n_j trimmed, :n_jrow trimmed
      from work.p17z_j;
    create table work.p17z_sj as
      select j.rid_s, j.rid_h, s.mrn, s.blank, s.yrc, h.pid_c
        from work.p17z_j as j, work.p17z_sp as s, work.p17z_hp as h
        where j.rid_s = s.p17rid and j.rid_h = h.p17rid;
    select sum(pid_c = '') into :n_nopid trimmed from work.p17z_sj;
  quit;
  %p17z_add(item=%str(best key joined rows spine to harmonized), num=&n_j);
  %p17z_add(item=%str(best key joined rows where spine row number equals harmonized row number), num=&n_jrow);
  %p17z_add(item=%str(joined rows with missing pecan_ID), num=&n_nopid);

  proc sql noprint;
    create table work.p17z_mp as
      select distinct mrn, pid_c from work.p17z_sj
        where blank = 0 and pid_c ne '';
    create table work.p17z_pm as
      select mrn, count(*) as np from work.p17z_mp group by mrn;
    create table work.p17z_pp as
      select pid_c, count(*) as nmr from work.p17z_mp group by pid_c;
    select count(*), sum(np = 1), sum(np = 2), sum(np >= 3)
      into :n_pm trimmed, :n_np1 trimmed, :n_np2 trimmed, :n_np3 trimmed
      from work.p17z_pm;
    select count(*), sum(nmr = 1), sum(nmr = 2), sum(nmr >= 3)
      into :n_pp trimmed, :n_nm1 trimmed, :n_nm2 trimmed, :n_nm3 trimmed
      from work.p17z_pp;
    create table work.p17z_pairs as
      select distinct a.pid_c as pid_a, b.pid_c as pid_b
        from work.p17z_mp as a, work.p17z_mp as b
        where a.mrn = b.mrn and a.pid_c < b.pid_c;
    select count(*) into :n_pairs trimmed from work.p17z_pairs;
  quit;
  %p17z_add(item=%str(spine distinct non-blank MRN with a pecan_ID), num=&n_pm);
  %p17z_add(item=%str(spine MRN with 1 distinct pecan_ID), num=&n_np1);
  %p17z_add(item=%str(spine MRN with 2 distinct pecan_IDs), num=&n_np2);
  %p17z_add(item=%str(spine MRN with 3 or more distinct pecan_IDs), num=&n_np3);
  %p17z_add(item=%str(distinct pecan_ID on the joined spine rows), num=&n_pp);
  %p17z_add(item=%str(pecan_ID with 1 distinct spine MRN), num=&n_nm1);
  %p17z_add(item=%str(pecan_ID with 2 distinct spine MRN), num=&n_nm2);
  %p17z_add(item=%str(pecan_ID with 3 or more distinct spine MRN), num=&n_nm3);
  %p17z_add(item=%str(implied dup pairs - two pecan_IDs sharing a spine MRN), num=&n_pairs);

  /* ---- Q3: by spine YEAR on each side of the pair ---- */
  %let p17z_sec = 3;
  proc sql noprint;
    create table work.p17z_cnt as
      select pid_c, yrc, count(*) as n
        from work.p17z_sj where pid_c ne ''
        group by pid_c, yrc;
    create table work.p17z_da as select distinct pid_a as pid from work.p17z_pairs;
    create table work.p17z_db as select distinct pid_b as pid from work.p17z_pairs;
    create table work.p17z_ya as
      select c.yrc, count(*) as n_id_a, sum(c.n) as rows_a
        from work.p17z_cnt as c, work.p17z_da as d
        where c.pid_c = d.pid
        group by c.yrc;
    create table work.p17z_yb as
      select c.yrc, count(*) as n_id_b, sum(c.n) as rows_b
        from work.p17z_cnt as c, work.p17z_db as d
        where c.pid_c = d.pid
        group by c.yrc;
    create table work.p17z_y3 as
      select coalesce(a.yrc, b.yrc) as yrc, a.n_id_a, a.rows_a, b.n_id_b, b.rows_b
        from work.p17z_ya as a full join work.p17z_yb as b
          on a.yrc = b.yrc
        order by 1;
    create table work.p17z_pyc as
      select p.pid_a, p.pid_b, count(*) as n_common
        from work.p17z_pairs as p, work.p17z_cnt as ca, work.p17z_cnt as cb
        where p.pid_a = ca.pid_c and p.pid_b = cb.pid_c and ca.yrc = cb.yrc
        group by p.pid_a, p.pid_b;
    select count(*) into :n_common trimmed from work.p17z_pyc;
    select count(*) into :n_pidp trimmed from
      (select pid from work.p17z_da intersect select pid from work.p17z_db);
  quit;
  %p17z_add(item=%str(dup pairs with a spine surgery in the same YEAR on both sides), num=&n_common);
  %p17z_add(item=%str(pecan_ID that is side A in one pair and side B in another), num=&n_pidp);
  %let p17z_s2ok = 1;
%mend p17z_s2;

/* ---- Q4: spine YEAR of the MRNs with no exact match in the xwalk ---- */
%macro p17z_s4;
  %local n_xd n_ud n_ur n_md n_udup;
  %let n_udup = .;
  %p17z_col(lib=g, mem=pecan_id_xwalk, var=ENCRYPTED_MRN);
  %if %length(&p17z_cn) = 0 %then %do;
    %p17z_add(item=%str(g.pecan_id_xwalk ENCRYPTED_MRN not found - section 4 skipped), num=.);
    %return;
  %end;
  proc sql noprint;
    create table work.p17z_xw as
      select distinct strip(ENCRYPTED_MRN) as mrn length=200
        from g.pecan_id_xwalk
        where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    create table work.p17z_sm as
      select p17rid, mrn, yrc,
             (mrn in (select mrn from work.p17z_xw)) as inx
        from work.p17z_sp where blank = 0;
    select count(*) into :n_xd trimmed from work.p17z_xw;
    select count(distinct mrn) into :n_ud trimmed from work.p17z_sm where inx = 0;
    select count(*) into :n_ur trimmed from work.p17z_sm where inx = 0;
    select count(distinct mrn) into :n_md trimmed from work.p17z_sm where inx = 1;
    create table work.p17z_y4a as
      select yrc, count(*) as r_un, count(distinct mrn) as d_un
        from work.p17z_sm where inx = 0 group by yrc;
    create table work.p17z_y4b as
      select yrc, count(*) as r_ma, count(distinct mrn) as d_ma
        from work.p17z_sm where inx = 1 group by yrc;
    create table work.p17z_y4 as
      select coalesce(a.yrc, b.yrc) as yrc, a.r_un, a.d_un, b.r_ma, b.d_ma
        from work.p17z_y4a as a full join work.p17z_y4b as b
          on a.yrc = b.yrc
        order by 1;
  quit;
  %if &p17z_s2ok = 1 %then %do;
    proc sql noprint;
      select count(distinct mrn) into :n_udup trimmed
        from work.p17z_sm
        where inx = 0 and mrn in (select mrn from work.p17z_pm where np >= 2);
    quit;
  %end;
  %let p17z_sec = 4;
  %p17z_add(item=%str(xwalk distinct non-blank MRN), num=&n_xd);
  %p17z_add(item=%str(spine distinct MRN with no exact xwalk match), num=&n_ud);
  %p17z_add(item=%str(spine rows with no exact xwalk match), num=&n_ur);
  %p17z_add(item=%str(spine distinct MRN with an exact xwalk match), num=&n_md);
  %p17z_add(item=%str(unmatched spine MRN that carry 2 or more pecan_IDs - needs section 2), num=&n_udup);
%mend p17z_s4;

/* ---- report writers ---- */
%macro p17z_wsec(sec=, title=);
  data _null_;
    file "&p17z_out." encoding='utf-8' mod;
    put ' ';
    put "## &title";
    put ' ';
    put '|item|value|';
    put '|---|---|';
  run;
  data _null_;
    set work.p17z_res(where=(sec = &sec));
    file "&p17z_out." encoding='utf-8' mod;
    length line $400;
    line = cats('|', item, '|', value, '|');
    put line;
  run;
%mend p17z_wsec;

%macro p17z_run();
  %local sp_t sp_y yt n_sprows n_blank n_hrows n_hpid n_hmiss n_hd;

  %if %symexist(g_path) %then %let p17z_gp = &g_path;
  %else %let p17z_gp = &p17z_gdef;
  libname g base "&p17z_gp." access=readonly;
  %if %sysfunc(libref(g)) ne 0 %then %do;
    %put ERROR: [17_probe_xwalk3] libname g could not be assigned - nothing probed;
    %return;
  %end;
  %if %sysfunc(exist(g.master_data_harmonized)) = 0 %then %do;
    %put ERROR: [17_probe_xwalk3] g.master_data_harmonized does not exist - nothing probed;
    %return;
  %end;
  %if %sysfunc(exist(pdd.src_s09)) = 0 %then %do;
    %put ERROR: [17_probe_xwalk3] pdd.src_s09 does not exist - nothing probed;
    %return;
  %end;
  %p17z_col(lib=pdd, mem=src_s09, var=ENCRYPTED_MRN);
  %if %length(&p17z_cn) = 0 %then %do;
    %put ERROR: [17_probe_xwalk3] ENCRYPTED_MRN not on pdd.src_s09 - nothing probed;
    %return;
  %end;

  proc datasets library=work nolist;
    delete p17z_res;
  quit;

  /* ---- spine work table: row number, MRN, blank flag, YEAR as text ---- */
  %p17z_col(lib=pdd, mem=src_s09, var=YEAR);
  %let sp_y = &p17z_cn;
  %let yt = &p17z_ct;
  data work.p17z_sp(keep=p17rid mrn blank yrc);
    set pdd.src_s09(keep=ENCRYPTED_MRN %if %length(&sp_y) > 0 %then %do; &sp_y %end;);
    length mrn $200 yrc $24;
    p17rid = _n_;
    mrn = strip(ENCRYPTED_MRN);
    blank = (missing(ENCRYPTED_MRN) or strip(ENCRYPTED_MRN) = ''
             or upcase(strip(ENCRYPTED_MRN)) = 'NULL');
    %if %length(&sp_y) = 0 %then %do;
      yrc = '';
    %end;
    %else %if %upcase(&yt) = CHAR %then %do;
      yrc = strip(&sp_y);
    %end;
    %else %do;
      if missing(&sp_y) then yrc = '';
      else yrc = strip(put(&sp_y, best12.));
    %end;
    if yrc = '' then yrc = 'missing';
  run;

  %let p17z_sec = 1;
  %let n_sprows = .;
  %let n_blank = .;
  %let n_hrows = .;
  proc sql noprint;
    select count(*), sum(blank) into :n_sprows trimmed, :n_blank trimmed
      from work.p17z_sp;
    select count(*) into :n_hrows trimmed from g.master_data_harmonized;
  quit;
  %p17z_add(item=%str(spine pdd.src_s09 row count), num=&n_sprows);
  %p17z_add(item=%str(g.master_data_harmonized row count), num=&n_hrows);
  %p17z_add(item=%str(BLANK OR NULL SPINE MRN ROWS), num=&n_blank);

  /* ---- Q1 ---- */
  %p17z_q1;
  %if %length(&p17z_bcol) = 0 %then %do;
    %p17z_add(item=%str(no usable key - no candidate tested - sections 2 and 3 skipped), num=.);
  %end;
  %else %do;
    %p17z_add(item=%str(best key spine column - see section 1c for the name), num=.);
    %p17z_add(item=%str(best key gives a one-to-one match of all spine rows - 1 yes and 0 no), num=&p17z_bfull, raw=1);
    %p17z_s2;
  %end;
  %p17z_s4;

  /* ---- write the markdown (names and counts only) ---- */
  data _null_;
    file "&p17z_out." encoding='utf-8';
    _d = today();
    put '# Probe: surgery key spine vs g.MASTER_DATA_HARMONIZED, dup pairs (PR-3)';
    put ' ';
    put 'Metadata and counts only. No MRN, case ID or pecan_ID values. Counts 1-10 shown as <11.';
    put 'Written by sas/17_probe_xwalk3.sas on ' _d yymmdd10. '.';
    put 'Lengths are not counts and are not suppressed.';
    put 'Row order key: the row number on each side, valid only if neither dataset was re-sorted.';
    put 'Dup pair: two pecan_IDs that share one spine MRN. Side A = ID sorting first as text.';
  run;

  %p17z_wsec(sec=1, title=%str(1. Row counts and the best key));

  data _null_;
    file "&p17z_out." encoding='utf-8' mod;
    put ' ';
    put '### 1a. Candidate key columns (column names matching the candidate pattern on either side)';
    put ' ';
    put '|name upcased|spine column|spine type|spine length|harmonized column|harmonized type|harmonized length|on both sides|';
    put '|---|---|---|---|---|---|---|---|';
  run;
  data _null_;
    set work.p17z_cand;
    file "&p17z_out." encoding='utf-8' mod;
    length line $800 both $3;
    both = ifc(not missing(sname) and not missing(hname), 'yes', 'no');
    line = cats('|', ckey, '|', sname, '|', styp, '|', slen, '|', hname, '|', htyp, '|', hlen, '|', both, '|');
    put line;
  run;

  data _null_;
    file "&p17z_out." encoding='utf-8' mod;
    put ' ';
    put '### 1b. Key tests (spine pdd.src_s09 to g.master_data_harmonized)';
    put ' ';
    put 'mode: raw = as delivered; norm = PDD-D-19 normalized (norm_psid); rid = row number.';
    put 'skip: 0 tested; 1 no non-missing key on a side; 2 fewer distinct values than half of the non-missing rows (not joined).';
    put ' ';
    put '|spine column|harmonized column|mode|skip|spine rows|harmonized rows|spine distinct|harmonized distinct|spine rows matched 0|spine rows matched 1|spine rows matched 2+|harmonized rows matched by 2+ spine rows|one-to-one for all spine rows|';
    put '|---|---|---|---|---|---|---|---|---|---|---|---|---|';
  run;
  data _null_;
    set work.p17z_kt;
    file "&p17z_out." encoding='utf-8' mod;
    length line $900 yn $3;
    yn = ifc(full = 1, 'YES', 'no');
    line = cats('|', scol, '|', hcol, '|', mode, '|', skip, '|', %p17z_sup(nrs), '|',
                %p17z_sup(nrh), '|', %p17z_sup(nds), '|', %p17z_sup(ndh), '|',
                %p17z_sup(r0), '|', %p17z_sup(r1), '|', %p17z_sup(rg), '|',
                %p17z_sup(hg), '|', yn, '|');
    put line;
  run;

  data _null_;
    file "&p17z_out." encoding='utf-8' mod;
    put ' ';
    put '### 1c. Best key';
    put ' ';
    %if %length(&p17z_bcol) = 0 %then %do;
      put 'No usable key was found.';
    %end;
    %else %do;
      put "Spine column: &p17z_bcol ; harmonized column: &p17z_bhc ; mode: &p17z_bmode ; one-to-one for all spine rows (1 yes, 0 no): &p17z_bfull";
      put 'Order of preference: one-to-one first, then a real key before row order, then most spine rows matched once, then norm before raw.';
    %end;
  run;

  %p17z_wsec(sec=2, title=%str(2. Best key: spine MRN to pecan_ID, dup pairs));

  data _null_;
    file "&p17z_out." encoding='utf-8' mod;
    put ' ';
    put '## 3. Dup pairs by spine YEAR (surgeries on each side)';
    put ' ';
    put 'IDs = distinct pecan_IDs of that side with at least one surgery in the year; rows = spine surgeries.';
    put ' ';
    put '|year|side A IDs|side A rows|side B IDs|side B rows|';
    put '|---|---|---|---|---|';
  run;
  %if %sysfunc(exist(work.p17z_y3)) %then %do;
    data _null_;
      set work.p17z_y3;
      file "&p17z_out." encoding='utf-8' mod;
      length line $400;
      line = cats('|', yrc, '|', %p17z_sup(n_id_a), '|', %p17z_sup(rows_a), '|',
                  %p17z_sup(n_id_b), '|', %p17z_sup(rows_b), '|');
      put line;
    run;
  %end;
  %p17z_wsec(sec=3, title=%str(3b. Dup pairs: same-year overlap));

  data _null_;
    file "&p17z_out." encoding='utf-8' mod;
    put ' ';
    put '## 4. Spine MRN with no exact xwalk match, by spine YEAR';
    put ' ';
    put 'Distinct MRN can repeat across years, so the yearly distinct counts do not add up to the total.';
    put ' ';
    put '|year|unmatched rows|unmatched distinct MRN|matched rows|matched distinct MRN|';
    put '|---|---|---|---|---|';
  run;
  %if %sysfunc(exist(work.p17z_y4)) %then %do;
    data _null_;
      set work.p17z_y4;
      file "&p17z_out." encoding='utf-8' mod;
      length line $400;
      line = cats('|', yrc, '|', %p17z_sup(r_un), '|', %p17z_sup(d_un), '|',
                  %p17z_sup(r_ma), '|', %p17z_sup(d_ma), '|');
      put line;
    run;
  %end;
  %p17z_wsec(sec=4, title=%str(4b. Totals));
  %put NOTE: [17_probe_xwalk3] report written to &p17z_out;
%mend p17z_run;

%p17z_run();

libname g clear;
