/*============================================================================
  17_probe_xwalk.sas  -  Phase 17 PROBE REQUEST PR-1 (metadata and counts only)
  Question : what does g.pecan_id_xwalk look like (names, types, lengths,
             formats, row count, distinct keys, blanks, MRN length profile,
             possible truncation) and how does its ENCRYPTED_MRN overlap the
             K1 spine (pdd.src_s09) and the K2 files (pdd.nsrc_s21..s23)?
  Reads    : g.pecan_id_xwalk (libname g opened READ-ONLY, never written)
             pdd.src_s09, pdd.nsrc_s21, pdd.nsrc_s22, pdd.nsrc_s23 (read-only)
  Writes   : C:\data_dictionary\.planning\schemas\probe_xwalk_<yyyymmdd>.md
             Variable names, types, lengths, formats and counts only.
             No MRN values, no ID values, no data rows. Counts 1-10 are
             shown as <11. Nothing is printed to the log except counts
             and the dataset and variable names.
  Run      : standalone on the SAS machine, then commit the .md file.
  Notes    : g_path comes from 00_config.sas when 17-01 has added it,
             otherwise the value planned in 17-01 is used.
             Trailing spaces cannot be detected in a fixed-width SAS
             character variable (they are padding). Trailing tab, CR and
             LF characters can, and are counted.
============================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;

options mprint nosyntaxcheck noerrorabend;

%let p17x_min = 11;
%let p17x_out = C:\data_dictionary\.planning\schemas\probe_xwalk_%sysfunc(today(), yymmddn8.).md;
%let p17x_gdef = P:\PeCAN Master Data\Gerard\Master_Renamed_same_format_accross\merge;

/* Suppressed display of a numeric: missing -> -, 1-10 -> <11, else comma */
%macro p17x_sup(x);
  ifc(missing(&x), '-', ifc(0 < &x < &p17x_min, "<&p17x_min", strip(put(&x, comma15.))))
%mend p17x_sup;

/* Append one result row. Label text must not contain commas or quotes. */
%macro p17x_add(item=, num=);
  data work.p17x_one;
    length item $120 value $20;
    item = "&item";
    n = &num;
    value = %p17x_sup(n);
    keep item value;
  run;
  proc append base=work.p17x_res data=work.p17x_one force;
  run;
%mend p17x_add;

/* Number of columns named &var in &lib..&mem (0 = absent) */
%macro p17x_hascol(lib=, mem=, var=);
  %global p17x_hc;
  %let p17x_hc = 0;
  proc sql noprint;
    select count(*) into :p17x_hc trimmed
      from dictionary.columns
      where libname = upcase("&lib") and memname = upcase("&mem")
        and upcase(name) = upcase("&var");
  quit;
%mend p17x_hascol;

/* Overlap of xwalk MRN with one dataset. &mem is the member name in pdd. */
%macro p17x_overlap(mem=);
  %local n_d n_both n_only_d n_only_x n_pre;
  %p17x_hascol(lib=pdd, mem=&mem, var=ENCRYPTED_MRN);
  %if &p17x_hc = 0 %then %do;
    %p17x_add(item=%str(overlap pdd.&mem: ENCRYPTED_MRN column absent or dataset missing), num=.);
    %return;
  %end;

  proc sql noprint;
    create table work.p17x_d as
      select distinct strip(ENCRYPTED_MRN) as mrn length=200
      from pdd.&mem
      where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    select count(*) into :n_d trimmed from work.p17x_d;
    select count(*) into :n_both trimmed
      from work.p17x_d as a, work.p17x_x as b
      where a.mrn = b.mrn;
    /* truncation indicator: first 40 chars agree but full strings differ */
    select count(distinct a.mrn) into :n_pre trimmed
      from work.p17x_d as a, work.p17x_x as b
      where substr(a.mrn, 1, 40) = substr(b.mrn, 1, 40)
        and a.mrn ne b.mrn;
  quit;
  %let n_only_d = %eval(&n_d - &n_both);

  %p17x_add(item=%str(pdd.&mem distinct non-blank MRN), num=&n_d);
  %p17x_add(item=%str(pdd.&mem MRN also in xwalk - exact strip match), num=&n_both);
  %p17x_add(item=%str(pdd.&mem MRN not in xwalk), num=&n_only_d);
  %p17x_add(item=%str(pdd.&mem MRN not matched exactly but first 40 chars equal an xwalk MRN), num=&n_pre);
%mend p17x_overlap;

%macro p17x_run();
  %local gp n_rows n_dmrn n_did n_mblank n_mnull n_iblank n_minl n_maxl
         n_lead n_trail n_embed n_len40 n_atvl n_mtype mrn_vlen;

  /* ---- 1. Open g read-only ---- */
  %if %symexist(g_path) %then %let gp = &g_path;
  %else %let gp = &p17x_gdef;
  libname g base "&gp." access=readonly;
  %if %sysfunc(libref(g)) ne 0 %then %do;
    %put ERROR: [17_probe_xwalk] libname g could not be assigned - nothing probed;
    %return;
  %end;
  %if %sysfunc(exist(g.pecan_id_xwalk)) = 0 %then %do;
    %put ERROR: [17_probe_xwalk] g.pecan_id_xwalk does not exist - nothing probed;
    %return;
  %end;

  /* ---- 2. Structure (PROC CONTENTS to WORK, no data) ---- */
  proc contents data=g.pecan_id_xwalk noprint
                out=work.p17x_c(keep=name type length varnum format formatl formatd
                                     informat informl informd);
  run;
  proc sort data=work.p17x_c;
    by varnum;
  run;

  %p17x_hascol(lib=g, mem=pecan_id_xwalk, var=ENCRYPTED_MRN);
  %let n_mtype = &p17x_hc;
  %if &n_mtype = 0 %then %do;
    %put ERROR: [17_probe_xwalk] ENCRYPTED_MRN not on g.pecan_id_xwalk;
  %end;
  %p17x_hascol(lib=g, mem=pecan_id_xwalk, var=pecan_ID);
  %if &p17x_hc = 0 %then %do;
    %put ERROR: [17_probe_xwalk] pecan_ID not on g.pecan_id_xwalk;
  %end;

  /* MRN must be character for the string probes */
  %let mrn_vlen = 0;
  proc sql noprint;
    select length into :mrn_vlen trimmed
      from work.p17x_c
      where upcase(name) = 'ENCRYPTED_MRN' and type = 2;
  quit;

  proc sql noprint;
    select count(*) into :n_rows trimmed from g.pecan_id_xwalk;
  quit;

  proc datasets library=work nolist;
    delete p17x_res;
  quit;

  %p17x_add(item=%str(row count g.pecan_id_xwalk), num=&n_rows);

  /* ---- 3. pecan_ID counts ---- */
  %p17x_hascol(lib=g, mem=pecan_id_xwalk, var=pecan_ID);
  %if &p17x_hc > 0 %then %do;
    proc sql noprint;
      select count(distinct pecan_ID) into :n_did trimmed
        from g.pecan_id_xwalk where not missing(pecan_ID);
      select sum(missing(pecan_ID)) into :n_iblank trimmed
        from g.pecan_id_xwalk;
    quit;
    %p17x_add(item=%str(distinct non-missing pecan_ID), num=&n_did);
    %p17x_add(item=%str(blank or missing pecan_ID), num=&n_iblank);
  %end;

  /* ---- 4. ENCRYPTED_MRN counts and length profile ---- */
  %if &mrn_vlen = 0 %then %do;
    %put ERROR: [17_probe_xwalk] ENCRYPTED_MRN missing or not character - string probes skipped;
    %p17x_add(item=%str(ENCRYPTED_MRN missing or not character - string probes skipped), num=.);
  %end;
  %else %do;
    proc sql noprint;
      select count(distinct strip(ENCRYPTED_MRN)) into :n_dmrn trimmed
        from g.pecan_id_xwalk
        where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
      select sum(missing(ENCRYPTED_MRN) or strip(ENCRYPTED_MRN) = '') into :n_mblank trimmed
        from g.pecan_id_xwalk;
      select sum(upcase(strip(ENCRYPTED_MRN)) = 'NULL') into :n_mnull trimmed
        from g.pecan_id_xwalk;
      select min(lengthn(strip(ENCRYPTED_MRN))), max(lengthn(strip(ENCRYPTED_MRN)))
        into :n_minl trimmed, :n_maxl trimmed
        from g.pecan_id_xwalk
        where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    quit;

    /* leading blank or whitespace, trailing tab/CR/LF, embedded whitespace,
       length 40, length equal to declared variable length */
    data _null_;
      set g.pecan_id_xwalk end=_eof;
      retain c_lead c_trail c_embed c_40 c_vl 0;
      if not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '' then do;
        if anyspace(ENCRYPTED_MRN) = 1 then c_lead + 1;
        if substr(ENCRYPTED_MRN, lengthn(ENCRYPTED_MRN), 1) in ('09'x, '0D'x, '0A'x) then c_trail + 1;
        if prxmatch('/\S\s+\S/', strip(ENCRYPTED_MRN)) then c_embed + 1;
        if lengthn(strip(ENCRYPTED_MRN)) = 40 then c_40 + 1;
        if lengthn(strip(ENCRYPTED_MRN)) = &mrn_vlen then c_vl + 1;
      end;
      if _eof then do;
        call symputx('n_lead', c_lead);
        call symputx('n_trail', c_trail);
        call symputx('n_embed', c_embed);
        call symputx('n_len40', c_40);
        call symputx('n_atvl', c_vl);
      end;
    run;

    %p17x_add(item=%str(distinct strip(ENCRYPTED_MRN) non-blank), num=&n_dmrn);
    %p17x_add(item=%str(blank or missing ENCRYPTED_MRN), num=&n_mblank);
    %p17x_add(item=%str(ENCRYPTED_MRN equal to NULL text), num=&n_mnull);
    %p17x_add(item=%str(min lengthn of strip(ENCRYPTED_MRN) - not suppressed), num=.);
    %p17x_add(item=%str(max lengthn of strip(ENCRYPTED_MRN) - not suppressed), num=.);
    %p17x_add(item=%str(leading whitespace in ENCRYPTED_MRN), num=&n_lead);
    %p17x_add(item=%str(trailing tab or CR or LF in ENCRYPTED_MRN - plain trailing blanks undetectable), num=&n_trail);
    %p17x_add(item=%str(embedded whitespace in ENCRYPTED_MRN), num=&n_embed);
    %p17x_add(item=%str(lengthn = 40 - possible truncation), num=&n_len40);
    %p17x_add(item=%str(lengthn = declared variable length &mrn_vlen), num=&n_atvl);

    /* min and max lengths are lengths not counts: write them unsuppressed */
    data work.p17x_res;
      set work.p17x_res;
      if index(item, 'min lengthn') = 1 then do;
        value = strip(put(&n_minl, 8.));
        item = 'min lengthn of strip(ENCRYPTED_MRN)';
      end;
      else if index(item, 'max lengthn') = 1 then do;
        value = strip(put(&n_maxl, 8.));
        item = 'max lengthn of strip(ENCRYPTED_MRN)';
      end;
    run;

    /* ---- 5. Overlap with spine and K2 ---- */
    proc sql noprint;
      create table work.p17x_x as
        select distinct strip(ENCRYPTED_MRN) as mrn length=200
        from g.pecan_id_xwalk
        where not missing(ENCRYPTED_MRN) and strip(ENCRYPTED_MRN) ne '';
    quit;
    %p17x_overlap(mem=src_s09);
    %p17x_overlap(mem=nsrc_s21);
    %p17x_overlap(mem=nsrc_s22);
    %p17x_overlap(mem=nsrc_s23);
  %end;

  /* ---- 6. Write the markdown (metadata and counts only) ---- */
  data _null_;
    file "&p17x_out." encoding='utf-8';
    _d = today();
    put '# Probe: g.pecan_id_xwalk (PR-1)';
    put ' ';
    put 'Metadata and counts only. No MRN or ID values. Counts 1-10 shown as <11.';
    put 'Written by sas/17_probe_xwalk.sas on ' _d yymmdd10. '.';
    put ' ';
    put '## Variables';
    put ' ';
    put '|varnum|name|type|length|format|informat|';
    put '|---|---|---|---|---|---|';
  run;
  data _null_;
    set work.p17x_c;
    file "&p17x_out." encoding='utf-8' mod;
    length ftxt itxt $40 ttxt $4 line $400;
    ttxt = ifc(type = 1, 'Num', 'Char');
    ftxt = '';
    if not missing(format) then
      ftxt = cats(format, ifc(formatl > 0, strip(put(formatl, 8.)), ''), '.',
                  ifc(formatd > 0, strip(put(formatd, 8.)), ''));
    itxt = '';
    if not missing(informat) then
      itxt = cats(informat, ifc(informl > 0, strip(put(informl, 8.)), ''), '.',
                  ifc(informd > 0, strip(put(informd, 8.)), ''));
    line = cats('|', varnum, '|', name, '|', ttxt, '|', length, '|', ftxt, '|', itxt, '|');
    put line;
  run;
  data _null_;
    file "&p17x_out." encoding='utf-8' mod;
    put ' ';
    put '## Counts';
    put ' ';
    put '|item|value|';
    put '|---|---|';
  run;
  data _null_;
    set work.p17x_res;
    file "&p17x_out." encoding='utf-8' mod;
    length line $400;
    line = cats('|', item, '|', value, '|');
    put line;
  run;
  %put NOTE: [17_probe_xwalk] report written to &p17x_out;
%mend p17x_run;

%p17x_run();

libname g clear;
