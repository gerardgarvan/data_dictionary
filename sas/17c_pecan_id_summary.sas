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
  Writes  : qc\pecan_id_cases_per_patient.csv (counts only, no IDs or MRNs; top-coded per scope, no row with 1-10 IDs)
  Gate    : the summary reconciles to the case map (cases with an ID plus
            cases without an ID = case map rows, per scope and in total).
  Never   : changes any dataset in pdd. Buckets are top-coded per scope (see
            %p17_topcode) so no row has 1-10 IDs; n_ids and n_cases are text columns.
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from an earlier session
   (the synthetic tests use FLAG). Run each program in a fresh SAS session. */
%let p17_fail_mode = ABORT;
%let _p17_failed = 0;

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

%include "&sas_path.\17_pecan_id_macros.sas";

%macro fail_out(msg=);
  %put ERROR: [17c_pecan_id_summary] &msg;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [17c_pecan_id_summary] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

/* record the worst &syserr seen after a step (syserr is reset by every step) */
%macro p17c_err;
  %if &syserr > 4 and &syserr > &_errmax %then %let _errmax = &syserr;
%mend p17c_err;

%macro p17c_main;
  %local _n_map _errmax _n_reg _n_allids _n_outrows _n_tcrows _n_id _n_noid _n_k1 _n_k2 _n_k1id _n_k2id _n_pairs _n_dupids _bad;
  %let _n_pairs = 0; %let _n_dupids = 0; %let _errmax = 0;
  %let _n_reg = -1; %let _n_outrows = 0; %let _n_tcrows = 0;
  %route_log;
  %if not %sysfunc(exist(pdd.pecan_id_case_map)) %then
    %fail_out(msg=%str(pdd.pecan_id_case_map missing - run 17b first));
  %if not %sysfunc(exist(pdd.pecan_id_registry)) %then
    %fail_out(msg=%str(pdd.pecan_id_registry missing - run 17a and 17b first));

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
  %p17c_err;

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
  %p17c_err;

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

  /* top-coding per scope (replaces cell masking): buckets merge from the top into
     one 'N+' bucket until every row has at least 11 IDs, so no n_cases can be
     divided back to a small n_ids and totals never hide a masked cell. */
  %p17_topcode(in=work.p17c_dist, out=work.p17c_tc, minn=11);
  %p17c_err;

  data work.p17c_out;
    length scope $8 metric $40 bucket $4 n_ids 8 n_cases 8 row_masked 8 note $200;
    set work.p17c_tc;
    metric = 'CASES_PER_PECAN_ID';
    if scope = 'ALL' then
      note = 'Patients in both eras have two PECAN_IDs and K1 patients with two IDs are in pecan_id_dup_link, so counts overestimate patients until linked';
    else note = '';
    note = catx(' ', note, ifc(index(bucket, '+') > 0 and row_masked = 0, 'N+ = top-coded: buckets merged until at least 11 IDs', ''));
    keep scope metric bucket n_ids n_cases row_masked note;
  run;

  data work.p17c_tot;
    length scope $8 metric $40 bucket $4 n_ids 8 n_cases 8 row_masked 8 note $200;
    row_masked = 0;
    scope = 'K1'; metric = 'TOTALS'; bucket = ''; n_ids = &_n_k1id; n_cases = &_n_k1; note = 'n_ids = distinct K1 PECAN_IDs, n_cases = K1 case map rows'; output;
    scope = 'K2'; metric = 'TOTALS'; bucket = ''; n_ids = &_n_k2id; n_cases = &_n_k2; note = 'n_ids = distinct K2 PECAN_IDs, n_cases = K2 case map rows'; output;
    scope = 'ALL'; metric = 'TOTALS'; bucket = ''; n_ids = %eval(&_n_k1id + &_n_k2id); n_cases = &_n_map; note = 'Overestimates patients until linked'; output;
    scope = 'ALL'; metric = 'CASES_WITHOUT_PECAN_ID'; bucket = ''; n_ids = .; n_cases = &_n_noid; note = 'K2 cases with blank or NULL MRN'; output;
    scope = 'K1'; metric = 'DUP_LINK_PAIRS'; bucket = ''; n_ids = &_n_dupids; n_cases = &_n_pairs; note = 'n_ids = PECAN_IDs in a pair, n_cases = pairs (K1 patients with two IDs)'; output;
  run;

  /* scope totals are dropped for a scope that had to be masked; when the without-ID
     count is 1-10 the K2 and ALL case totals would reveal it (total minus the visible
     bucket sums), so those two n_cases are blanked; a dup pair row with a count of
     1-10 in either column is masked in both (n_ids = 2 x pairs would reveal it) */
  proc sql noprint;
    create table work.p17c_totk as
      select t.* from work.p17c_tot t
      where not (t.metric = 'TOTALS'
                 and t.scope in (select scope from work.p17c_tc where row_masked = 1));
  quit;

  data work.p17c_all;
    length scope $8 metric $40 bucket $4 n_ids $12 n_cases $12 note $200;
    set work.p17c_out(rename=(n_ids=_ni n_cases=_nc)) work.p17c_totk(rename=(n_ids=_ni n_cases=_nc));
    if metric = 'TOTALS' and scope in ('K2' 'ALL') and 1 <= &_n_noid <= 10 then _nc = .;
    if metric = 'DUP_LINK_PAIRS' and (1 <= _ni <= 10 or 1 <= _nc <= 10) then row_masked = 1;
    if row_masked = 1 then do;
      n_ids = '<11';
      n_cases = '<11';
    end;
    else do;
      if _ni = . then n_ids = '';
      else if 1 <= _ni <= 10 then n_ids = '<11';
      else n_ids = strip(put(_ni, best12.));
      if _nc = . then n_cases = '';
      else if 1 <= _nc <= 10 then n_cases = '<11';
      else n_cases = strip(put(_nc, best12.));
    end;
    keep scope metric bucket n_ids n_cases note;
  run;


  /* loud failure: any step error, empty output, or ALL ID total off the registry */
  %if %sysfunc(exist(work.p17c_tc)) %then %do;
    proc sql noprint;
      select count(*) into :_n_tcrows trimmed from work.p17c_tc;
    quit;
  %end;
  %if %sysfunc(exist(work.p17c_all)) %then %do;
    proc sql noprint;
      select count(*) into :_n_outrows trimmed from work.p17c_all;
    quit;
  %end;
  proc sql noprint;
    select count(*) into :_n_reg trimmed from pdd.pecan_id_registry;
    select coalesce(sum(n_ids), 0) into :_n_allids trimmed from work.p17c_dist where scope = 'ALL';
  quit;
  %p17c_err;
  %if &_errmax > 4 %then
    %fail_out(msg=%str(a step ended with SYSERR &_errmax. - summary not written));
  %if &_n_tcrows = 0 or &_n_outrows = 0 %then
    %fail_out(msg=%str(summary output has 0 data rows - top-coded rows &_n_tcrows., output rows &_n_outrows.));
  %if &_n_allids ne &_n_reg %then
    %fail_out(msg=%str(ALL scope ID total &_n_allids. does not equal registry rows &_n_reg.));

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
