/*==========================================================================
  Program : 18c_comb_profile_qc.sas
  Phase   : 18 (combined dataset and dictionary 2018-2025), plan 18-05
  Purpose : Profile pdd.pcnr_2018_2025 (DD-03) and produce the reconciliation
            and KEY facts the dictionary workbook needs (DD-04).
            - %pdd_profile with prefix PCNR_ and family PCNR_2018_2025: writes
              pdd.prf_PCNR_2018_2025 and exchange\profile_PCNR_2018_2025.csv.
              PECAN_ID, PRECEDE_STUDY_ID, PECAN_ID_KEY_ERA, KEY_ERA and NORM_PSID
              carry no PCNR_ prefix and are therefore never profiled (no ID
              value is ever a level); the workbook describes them as KEY rows.
            - reconciliation: per variable non-missing counts on the K1 slice
              against pdd.pcnr (exact except NULL cells read as missing) and
              distinct-value counts on the K1 slice against the v1.0 profile
              pdd.prf_pcnr. Level-by-level frequencies are NOT re-profiled on
              the K1 slice (stated on the KEY sheet).
            - NO_DATA flags reconciled with pdd.name_map_vars_coverage.
            - KEY facts. Counts only, 1-10 exported as <11.
  Reads   : pdd.pcnr_2018_2025, pdd.pcnr, pdd.prf_pcnr (v1.0, read only),
            pdd.qc_comb_typeconv, pdd.qc_comb_build, name map tables, case map,
            dup link, registry (row counts only).
  Writes  : pdd.prf_PCNR_2018_2025, pdd.qc_comb_profile (once, WORK flush),
            exchange\profile_PCNR_2018_2025.csv and _manifest.csv,
            exchange\comb_recon.csv, comb_nodata.csv, comb_key_facts.csv,
            qc\comb_profile.csv, the log. Never the v1.0 outputs profile_PCNR.csv,
            pdd.prf_pcnr, pdd_v1_0.xlsx.
  Never   : scans its own log (18d scans the closed logs), writes to the
            registry, dup link or case map.
  Session : fresh SAS session, after 18b PASS.
  Status  : PENDING SAS RUN (Gerard).

  Assumption A3: Phase 6 macros are unchanged. %pdd_profile reads pdd.name_map
  (frozen) only for LINKAGE_ONLY exclusion; the combined dataset holds PCNR
  status variables only, so no staging library is needed.
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from a test session. */
%let p18_fail_mode = ABORT;
%let p17_fail_mode = ABORT;
%let _p18_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\18c_comb_profile_qc.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\18_combine_macros.sas";

/* Phase 6 macros: test mode makes a profile failure set p6_fail instead of
   aborting, so QC is written before the stop. */
%let p6_test_mode = 1;
%include "&sas_path.\06_profile_macros.sas";

%macro p18c_dump;
  %p18_dump_qc(tables=profile, file=&qc_path.\comb_profile.csv);
  %p18_flush_qc;
%mend p18c_dump;

%macro fail_out(msg=);
  %put ERROR: [18c_comb_profile_qc] &msg;
  %p18c_dump;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [18c_comb_profile_qc] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p18c_main;
  %local _n_rows _n_cols _n_k1 _n_k2 _d_k1 _d_k2 _n_dup _n_blank _n_nd _n_pcnrvars
         _n_prfvars _modate _nobs _dttm _shared _qcn;
  %route_log;
  %p18_qinit(ds=pdd.qc_comb_profile);
  %p18_require(tables=pdd.&comb_ds pdd.pcnr pdd.prf_pcnr pdd.name_map pdd.name_map_ext
               pdd.name_map_vars_ext pdd.name_map_vars_coverage pdd.qc_comb_typeconv
               pdd.qc_comb_build pdd.pecan_id_case_map pdd.pecan_id_registry
               pdd.pecan_id_dup_link);
  %p18_ro_start;
  %p18_load_types(decisions=C:\data_dictionary\docs\combined_type_decisions.csv);

  /* the stored dataset is gated again: variables, types, order, no ENCRYPTED_ */
  %p18_gate_vars(ds=pdd.&comb_ds, order=1, qc=pdd.qc_comb_profile);

  /* profile (DD-03) */
  %pdd_profile(lib=pdd, ds=&comb_ds, prefix=PCNR_, family=PCNR_2018_2025,
               suppress_file="C:\data_dictionary\docs\profile_suppress.csv",
               categorical_file="C:\data_dictionary\docs\profile_categorical.csv");
  %if &p6_fail = 1 %then
    %fail_out(msg=%str(pdd_profile failed for the combined dataset - see the Phase 6 ERROR line above));
  proc sql noprint;
    select count(*) into :_n_pcnrvars trimmed from dictionary.columns
      where libname = 'PDD' and upcase(memname) = upcase("&comb_ds") and upcase(name) like 'PCNR!_%' escape '!';
    select count(distinct variable) into :_n_prfvars trimmed from pdd.prf_PCNR_2018_2025;
  quit;
  %p18_qadd(ds=pdd.qc_comb_profile, item=pcnr_columns_in_dataset, n=&_n_pcnrvars);
  %p18_qadd(ds=pdd.qc_comb_profile, item=variables_in_profile, n=&_n_prfvars,
            fail=%eval(&_n_prfvars ne &_n_pcnrvars));
  %if &_n_prfvars ne &_n_pcnrvars %then
    %fail_out(msg=%str(profile variable count differs from the PCNR_ columns of the dataset));
  %p18_qadd(ds=pdd.qc_comb_profile, item=dataset_columns_eq_5_keys_plus_pcnr_vars,
            n=%eval(&_n_pcnrvars + 5));
  proc sql noprint;
    select modate, nobs into :_modate trimmed, :_nobs trimmed from dictionary.tables
      where libname = 'PDD' and upcase(memname) = upcase("&comb_ds");
  quit;
  %let _dttm = %sysfunc(datetime(), datetime20.);
  data _null_;
    file "&exchange_path.\profile_PCNR_2018_2025_manifest.csv" dsd lrecl=500;
    put "pcnr_modate,pcnr_nobs,run_dttm";
    put "&_modate.,&_nobs.,&_dttm.";
  run;

  /* PDD-D-34: no pct on a masked, blank or small-n row (pct x total gives the
     count back). Scrub a WORK copy of the profile and rewrite the exchange CSV
     with the same PROC EXPORT call Phase 6 uses. pdd.prf_ stays as published. */
  %p18_pct_scrub(in=pdd.prf_PCNR_2018_2025, out=work.p18c_prf_scrub, total=&_nobs,
                 qc=pdd.qc_comb_profile);
  filename p18cprf "&exchange_path.\profile_PCNR_2018_2025.csv" encoding='utf-8';
  proc export data=work.p18c_prf_scrub outfile=p18cprf dbms=csv replace;
  run;
  filename p18cprf clear;
  %if &syserr > 4 %then
    %fail_out(msg=%str(PROC EXPORT of the scrubbed profile CSV failed));

  /* reconciliation (DD-04) */
  %p18_recon(comb=pdd.&comb_ds, old=pdd.pcnr, prf=pdd.prf_pcnr, tc=pdd.qc_comb_typeconv,
             out=work.p18c_recon, qc=pdd.qc_comb_profile);
  %p18_export(ds=work.p18c_recon, file=&exchange_path.\comb_recon.csv,
              cols=pcnr_name n_nonmiss_pcnr_old n_nonmiss_comb_k1 n_nonmiss_comb_k2 n_nonmiss_comb_all n_special_comb_all delta_k1 n_distinct_k1 n_distinct_prf_v1 explained,
              numcols=n_nonmiss_pcnr_old n_nonmiss_comb_k1 n_nonmiss_comb_k2 n_nonmiss_comb_all n_special_comb_all delta_k1 n_distinct_k1 n_distinct_prf_v1);

  /* NO_DATA flags (coverage reconciliation) */
  %p18_nodata_flags(ds=pdd.&comb_ds, cov=pdd.name_map_vars_coverage, out=work.p18c_nodata,
                    qc=pdd.qc_comb_profile);
  %p18_export(ds=work.p18c_nodata, file=&exchange_path.\comb_nodata.csv,
              cols=pcnr_name n_nonmiss coverage_status reconciled, numcols=n_nonmiss);
  proc sql noprint;
    select count(*) into :_n_nd trimmed from work.p18c_nodata where n_nonmiss = 0;
  quit;

  /* KEY facts: counts only */
  proc sql noprint;
    select count(*), sum(KEY_ERA = 'K1'), sum(KEY_ERA = 'K2'),
           count(distinct case when KEY_ERA = 'K1' then PECAN_ID end),
           count(distinct case when KEY_ERA = 'K2' then PECAN_ID end)
      into :_n_rows trimmed, :_n_k1 trimmed, :_n_k2 trimmed, :_d_k1 trimmed, :_d_k2 trimmed
      from pdd.&comb_ds;
    select count(*) into :_n_cols trimmed from dictionary.columns
      where libname = 'PDD' and upcase(memname) = upcase("&comb_ds");
    select count(*) into :_n_dup trimmed from pdd.pecan_id_dup_link;
    select count(*) into :_n_blank trimmed from pdd.pecan_id_case_map
      where KEY_ERA = 'K1' and MRN_STATUS ne 'OK';
    select coalesce(max(n), 0) into :_shared trimmed from pdd.qc_comb_build
      where item = 'shared_s22_s23';
  quit;
  data work.p18c_kf;
    length item $40 value $200;
    item = 'ROWS'; value = "%p18_mask(&_n_rows)"; output;
    item = 'COLUMNS'; value = "%p18_mask(&_n_cols)"; output;
    item = 'K1_ROWS'; value = "%p18_mask(&_n_k1)"; output;
    item = 'K2_ROWS'; value = "%p18_mask(&_n_k2)"; output;
    item = 'DISTINCT_PECAN_ID_K1'; value = "%p18_mask(&_d_k1)"; output;
    item = 'DISTINCT_PECAN_ID_K2'; value = "%p18_mask(&_d_k2)"; output;
    item = 'SHARED_SURGERIES'; value = "%p18_mask(&_shared)"; output;
    item = 'DUP_PAIRS'; value = "%p18_mask(&_n_dup)"; output;
    item = 'K1_BLANK_MRN_ROWS'; value = "%p18_mask(&_n_blank)"; output;
    item = 'PCNR_VARIABLES'; value = "%p18_mask(&_n_pcnrvars)"; output;
    item = 'NODATA_VARIABLES'; value = "%p18_mask(&_n_nd)"; output;
    item = 'PDD_K2_PSID_MODE'; value = "&PDD_K2_PSID_MODE"; output;
    item = 'DATE'; value = put(today(), yymmdd10.); output;
    item = 'SOURCE_DATASETS'; value = 'pdd.pcnr (2018-2022); pdd.nsrc_s21, nsrc_s22, nsrc_s23 (2023-2025)'; output;
  run;
  %p18_export(ds=work.p18c_kf, file=&exchange_path.\comb_key_facts.csv, cols=item value, numcols=);

  /* read-only guard, one QC flush */
  %p18_ro_end(qc=pdd.qc_comb_profile);
  %p18c_dump;
  %put NOTE: [18c_comb_profile_qc] PASS - profile, reconciliation, NO_DATA flags and KEY facts written;
  %restore_log;
%mend p18c_main;

%p18c_main;
