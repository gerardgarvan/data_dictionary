/*============================================================================
  15d_overlap_diag.sas  -  one-off diagnostic for the PDD-D-29 item 3 gate
  Question : the 2024 (s22) and 2025 (s23) files share normalized case IDs.
             Are these the same surgeries delivered twice, or different
             surgeries that collide on the same 5-digit number?
  Reads    : pdd.nsrc_s21, pdd.nsrc_s22, pdd.nsrc_s23 (from 15c), read-only
  Writes   : C:\data_dictionary\.planning\schemas\overlap_s22_s23_<yyyymmdd>.md
             (column names, counts and case-ID number ranges only; counts
             1-10 shown as <11; no data values, no MRNs, no individual IDs)
  Run      : standalone after 15c. Commit the .md file.
============================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;

options mprint;

%let p15d_out = C:\data_dictionary\.planning\schemas\overlap_s22_s23_%sysfunc(today(), yymmddn8.).md;
%let p15d_min = 11;

%macro p15d_sup(x);
  ifc(missing(&x), '-', ifc(0 < &x < &p15d_min, "<&p15d_min", strip(put(&x, comma15.))))
%mend p15d_sup;

%macro p15d_run();
  %local nv i n_shared n_typediff n_only22 n_only23;
  %let n_shared = 0;
  %let n_typediff = 0;

  /* 1. Shared normalized case IDs */
  proc sql noprint;
    create table work.p15d_ids as
      select distinct a.norm_psid
      from pdd.nsrc_s22 as a
           inner join pdd.nsrc_s23 as b
           on a.norm_psid = b.norm_psid
      where a.norm_psid ne '';
    select count(*) into :n_shared trimmed from work.p15d_ids;
  quit;
  %put NOTE: [15d] shared case IDs s22 x s23 = &n_shared;
  %if &n_shared = 0 %then %do;
    %put NOTE: [15d] nothing to compare - stopping.;
    %return;
  %end;

  /* 2. Columns present in both files with the same name and type */
  proc sql noprint;
    select a.name into :v1-
      from dictionary.columns as a
           inner join dictionary.columns as b
           on upcase(a.name) = upcase(b.name) and a.type = b.type
      where a.libname = 'PDD' and a.memname = 'NSRC_S22'
        and b.libname = 'PDD' and b.memname = 'NSRC_S23'
        and upcase(a.name) ne 'NORM_PSID'
      order by a.varnum;
  quit;
  %let nv = &sqlobs;

  proc sql noprint;
    select count(*) into :n_typediff trimmed
      from dictionary.columns as a
           inner join dictionary.columns as b
           on upcase(a.name) = upcase(b.name) and a.type ne b.type
      where a.libname = 'PDD' and a.memname = 'NSRC_S22'
        and b.libname = 'PDD' and b.memname = 'NSRC_S23';
    select count(*) into :n_only22 trimmed
      from dictionary.columns
      where libname = 'PDD' and memname = 'NSRC_S22'
        and upcase(name) not in (select upcase(name) from dictionary.columns
                                 where libname = 'PDD' and memname = 'NSRC_S23');
    select count(*) into :n_only23 trimmed
      from dictionary.columns
      where libname = 'PDD' and memname = 'NSRC_S23'
        and upcase(name) not in (select upcase(name) from dictionary.columns
                                 where libname = 'PDD' and memname = 'NSRC_S22');
  quit;
  %put NOTE: [15d] columns compared = &nv, same name but different type = &n_typediff;

  /* 3. The shared rows from each file */
  proc sql;
    create table work.p15d_a as
      select * from pdd.nsrc_s22
      where norm_psid in (select norm_psid from work.p15d_ids)
      order by norm_psid;
    create table work.p15d_b as
      select * from pdd.nsrc_s23
      where norm_psid in (select norm_psid from work.p15d_ids)
      order by norm_psid;
  quit;

  /* 4. Cell-by-cell comparison per shared case */
  data work.p15d_cmp(keep=norm_psid __ndiff __d1-__d&nv);
    merge work.p15d_a(in=__ina keep=norm_psid %do i = 1 %to &nv; &&v&i %end;)
          work.p15d_b(in=__inb keep=norm_psid %do i = 1 %to &nv; &&v&i %end;
                      rename=(%do i = 1 %to &nv; &&v&i=__b&i %end;));
    by norm_psid;
    if __ina and __inb;
    array __d{&nv} __d1-__d&nv;
    %do i = 1 %to &nv;
      __d{&i} = (&&v&i ne __b&i);
    %end;
    __ndiff = sum(of __d1-__d&nv);
  run;

  /* 5. Per-column count of shared cases whose values differ */
  proc means data=work.p15d_cmp noprint;
    var __d1-__d&nv;
    output out=work.p15d_vsum(drop=_type_ _freq_) sum=;
  run;
  data work.p15d_vars(keep=col_order varname n_diff);
    set work.p15d_vsum;
    length varname $32;
    %do i = 1 %to &nv;
      col_order = &i;
      varname = "&&v&i";
      n_diff = __d&i;
      output;
    %end;
  run;
  proc sort data=work.p15d_vars;
    by descending n_diff col_order;
  run;

  /* 6. How many columns differ per shared case */
  proc sql;
    create table work.p15d_dist as
      select case when __ndiff = 0 then 'identical in every compared column'
                  when __ndiff = 1 then '1 column differs'
                  when __ndiff <= 5 then '2-5 columns differ'
                  when __ndiff <= 20 then '6-20 columns differ'
                  else 'more than 20 columns differ' end as bucket length=40,
             min(__ndiff) as sortkey,
             count(*) as n_cases
      from work.p15d_cmp
      group by calculated bucket
      order by sortkey;
  quit;

  /* 7. Case-ID number ranges per file and for the shared set */
  proc sql;
    create table work.p15d_rng as
      select 's21 (2023)' as grp length=24,
             min(input(substr(norm_psid, 8), 8.)) as id_min,
             max(input(substr(norm_psid, 8), 8.)) as id_max,
             count(*) as n_ids
        from pdd.nsrc_s21 where norm_psid ne ''
      union all
      select 's22 (2024)', min(input(substr(norm_psid, 8), 8.)),
             max(input(substr(norm_psid, 8), 8.)), count(*)
        from pdd.nsrc_s22 where norm_psid ne ''
      union all
      select 's23 (2025)', min(input(substr(norm_psid, 8), 8.)),
             max(input(substr(norm_psid, 8), 8.)), count(*)
        from pdd.nsrc_s23 where norm_psid ne ''
      union all
      select 'shared s22 x s23', min(input(substr(norm_psid, 8), 8.)),
             max(input(substr(norm_psid, 8), 8.)), count(*)
        from work.p15d_ids;
  quit;

  /* 8. Markdown report */
  data _null_;
    file "&p15d_out" encoding='utf-8' lrecl=2000;
    put "# Overlap diagnostic: 2024 (s22) x 2025 (s23)";
    put;
    put "- Generated by sas/15d_overlap_diag.sas from pdd.nsrc_s21..s23 (15c output).";
    put "- Privacy: column names, counts and case-ID number ranges only. Counts 1-10 shown as <&p15d_min..";
    put "- Shared normalized case IDs: &n_shared";
    put "- Columns compared (same name and type in both files): &nv";
    put "- Same name, different type (not compared): &n_typediff";
    put "- Columns only in s22: &n_only22 ; only in s23: &n_only23 (the year-prefixed Braden columns)";
  run;

  data _null_;
    set work.p15d_rng;
    file "&p15d_out" mod encoding='utf-8' lrecl=2000;
    length __line $500;
    if _n_ = 1 then do;
      put;
      put "## Case-ID number ranges (digits after Precede)";
      put;
      put "|group|lowest|highest|IDs|";
      put "|---|---|---|---|";
    end;
    __line = cats('|', grp, '|', id_min, '|', id_max, '|', %p15d_sup(n_ids), '|');
    put __line;
  run;

  data _null_;
    set work.p15d_dist;
    file "&p15d_out" mod encoding='utf-8' lrecl=2000;
    length __line $500;
    if _n_ = 1 then do;
      put;
      put "## How many columns differ per shared case";
      put;
      put "|columns differing|shared cases|";
      put "|---|---|";
    end;
    __line = cats('|', bucket, '|', %p15d_sup(n_cases), '|');
    put __line;
  run;

  data _null_;
    set work.p15d_vars end=__eof;
    file "&p15d_out" mod encoding='utf-8' lrecl=2000;
    length __line $500;
    retain __n0 0;
    if _n_ = 1 then do;
      put;
      put "## Columns with differing values (shared cases where s22 and s23 disagree)";
      put;
      put "|column|shared cases with a different value|";
      put "|---|---|";
    end;
    if n_diff > 0 then do;
      __line = cats('|', varname, '|', %p15d_sup(n_diff), '|');
      put __line;
    end;
    else __n0 + 1;
    if __eof then do;
      put;
      put "Columns identical for every shared case: " __n0;
      put;
      put "Key columns: ENCRYPTED_MRN and ENCRYPTED_ENCOUNTER differing on most shared cases means a numbering collision (different surgeries);";
      put "matching MRN and encounter with few other differences means the same surgery delivered in both files.";
    end;
  run;

  %put NOTE: [15d] report written to &p15d_out;

  proc datasets lib=work nolist nowarn;
    delete p15d_ids p15d_a p15d_b p15d_cmp p15d_vsum p15d_vars p15d_dist p15d_rng;
  quit;
%mend p15d_run;

%p15d_run()
