/*==========================================================================
  Program : 17c_pecan_id_summary.sas
  Phase   : 17 (PECAN_ID), plan 17-05 (PID-05, PID-07)
  Purpose : Cases per PECAN_ID from pdd.pecan_id_case_map only, per era (K1,
            K2) and combined (ALL), plus the K1 dup pair count from
            pdd.pecan_id_dup_link. Combined rows carry the caveat that
            patients in both eras have two PECAN_IDs and K1 patients with two
            IDs are listed in the dup link, so ALL overestimates patients
            until they are linked.
  Reads   : pdd.pecan_id_case_map, pdd.pecan_id_dup_link
  Writes  : qc\pecan_id_cases_per_patient.csv (counts only, no IDs or MRNs)
  Gate    : the summary reconciles to the case map (cases with an ID plus
            cases without an ID = case map rows, per scope and in total).
  Never   : changes any dataset in pdd. Counts 1-10 must be shown as <11 if
            copied into .planning/ (A5); the qc file itself holds real counts.
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\17c_pecan_id_summary.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%macro fail_out(msg=);
  %put ERROR: [17c_pecan_id_summary] &msg;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [17c_pecan_id_summary] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p17c_main;
  %local _n_map _n_id _n_noid _n_k1 _n_k2 _n_k1id _n_k2id _n_pairs _n_dupids _bad;
  %let _n_pairs = 0; %let _n_dupids = 0;
  %route_log;
  %if not %sysfunc(exist(pdd.pecan_id_case_map)) %then
    %fail_out(msg=%str(pdd.pecan_id_case_map missing - run 17b first));

  proc sql noprint;
    create table work.p17c_pc as
      select KEY_ERA, PECAN_ID, count(*) as n_cases
      from pdd.pecan_id_case_map
      where not missing(PECAN_ID)
      group by KEY_ERA, PECAN_ID;
    select count(*) into :_n_map trimmed from pdd.pecan_id_case_map;
    select count(*) into :_n_noid trimmed from pdd.pecan_id_case_map where missing(PECAN_ID);
    select count(*) into :_n_k1 trimmed from pdd.pecan_id_case_map where KEY_ERA = 'K1';
    select count(*) into :_n_k2 trimmed from pdd.pecan_id_case_map where KEY_ERA = 'K2';
  quit;

  data work.p17c_pc2;
    set work.p17c_pc;
    length bucket $4;
    if n_cases >= 10 then bucket = '10+';
    else bucket = strip(put(n_cases, 2.));
    bn = min(n_cases, 10);
  run;

  proc sql noprint;
    create table work.p17c_dist as
      select KEY_ERA as scope length=8, bn, bucket, count(*) as n_ids,
             sum(n_cases) as n_cases
      from work.p17c_pc2 group by KEY_ERA, bn, bucket
      union all
      select 'ALL' as scope length=8, bn, bucket, count(*) as n_ids,
             sum(n_cases) as n_cases
      from work.p17c_pc2 group by bn, bucket
      order by scope, bn;
    select coalesce(sum(n_cases), 0) into :_n_id trimmed from work.p17c_pc2;
    select count(*) into :_n_k1id trimmed from work.p17c_pc2 where KEY_ERA = 'K1';
    select count(*) into :_n_k2id trimmed from work.p17c_pc2 where KEY_ERA = 'K2';
  quit;

  %if %sysfunc(exist(pdd.pecan_id_dup_link)) %then %do;
    proc sql noprint;
      select count(*) into :_n_pairs trimmed from pdd.pecan_id_dup_link;
      select count(*) into :_n_dupids trimmed from
        (select pecan_id_a as pid from pdd.pecan_id_dup_link
         union
         select pecan_id_b as pid from pdd.pecan_id_dup_link);
    quit;
  %end;

  /* reconcile: cases with an ID plus cases without = case map rows */
  %let _bad = 0;
  %if %eval(&_n_id + &_n_noid) ne &_n_map %then %let _bad = 1;
  %if %eval(&_n_k1 + &_n_k2) ne &_n_map %then %let _bad = 1;

  data work.p17c_out;
    length scope $8 metric $40 bucket $4 n_ids 8 n_cases 8 note $200;
    set work.p17c_dist;
    metric = 'CASES_PER_PECAN_ID';
    if scope = 'ALL' then
      note = 'Patients in both eras have two PECAN_IDs and K1 patients with two IDs are in pecan_id_dup_link, so counts overestimate patients until linked';
    else note = '';
    keep scope metric bucket n_ids n_cases note;
  run;

  data work.p17c_tot;
    length scope $8 metric $40 bucket $4 n_ids 8 n_cases 8 note $200;
    scope = 'K1'; metric = 'TOTALS'; bucket = ''; n_ids = &_n_k1id; n_cases = &_n_k1; note = 'n_ids = distinct K1 PECAN_IDs, n_cases = K1 case map rows'; output;
    scope = 'K2'; metric = 'TOTALS'; bucket = ''; n_ids = &_n_k2id; n_cases = &_n_k2; note = 'n_ids = distinct K2 PECAN_IDs, n_cases = K2 case map rows'; output;
    scope = 'ALL'; metric = 'TOTALS'; bucket = ''; n_ids = %eval(&_n_k1id + &_n_k2id); n_cases = &_n_map; note = 'Overestimates patients until linked'; output;
    scope = 'ALL'; metric = 'CASES_WITHOUT_PECAN_ID'; bucket = ''; n_ids = .; n_cases = &_n_noid; note = 'K2 cases with blank or NULL MRN'; output;
    scope = 'K1'; metric = 'DUP_LINK_PAIRS'; bucket = ''; n_ids = &_n_dupids; n_cases = &_n_pairs; note = 'n_ids = PECAN_IDs in a pair, n_cases = pairs (K1 patients with two IDs)'; output;
  run;

  data work.p17c_all;
    set work.p17c_out work.p17c_tot;
  run;

  %if &_bad = 1 %then
    %fail_out(msg=%str(summary does not reconcile to the case map - with ID &_n_id., without ID &_n_noid., K1 &_n_k1., K2 &_n_k2., rows &_n_map.));

  proc export data=work.p17c_all
              outfile="&qc_path.\pecan_id_cases_per_patient.csv"
              dbms=csv replace;
  run;
  %put NOTE: [17c_pecan_id_summary] reconciled - case map rows &_n_map, distinct K1 IDs &_n_k1id, distinct K2 IDs &_n_k2id, dup pairs &_n_pairs;
  %restore_log;
%mend p17c_main;

%p17c_main;
