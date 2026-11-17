/*==========================================================================
  Program : 18a_comb_preflight.sas
  Phase   : 18 (combined dataset and dictionary 2018-2025), plan 18-03
  Purpose : Preflight and probe for the combined dataset. Read-only on every
            pdd table. Measures what no probe file contains: the columns and
            types of pdd.pcnr and pdd.nsrc_s21..s23, the type delta against the
            decided combined types (PDD-D-31), conversion failures (counts only),
            the ASA_Anesth_Record and CPT1_Class numeric check (PDD-D-31 item 2,
            conditional), case counts and overlaps, the pdd.pcnr 1298-vs-1297
            column question, and the read-only baseline of the three
            pecan_id tables.
  Reads   : pdd.pcnr, pdd.name_map_vars_ext, pdd.name_map_ext,
            pdd.name_map_coverage, pdd.name_map_vars_coverage,
            pdd.nsrc_s21..s23, pdd.pecan_id_case_map, pdd.pecan_id_registry,
            pdd.pecan_id_dup_link, docs\combined_type_decisions.csv,
            docs\new_overlap_decisions.csv
  Writes  : pdd.qc_comb_pre (once, WORK staging flush), qc\comb_pre.csv,
            qc\comb_pre_inventory.csv (names and types only),
            exchange\comb_type_delta.csv, the log. Never pdd.pcnr_2018_2025.
  Stops   : PENDING DECISION in the ERROR line (QC written first) on a
            PENDING_DECISION map row, a decisions key matching no variable, a
            pdd.pcnr column that is neither NORM_PSID nor a mapped name, a mapped
            name with no source column anywhere, a char to num value that cannot
            be converted (this includes ASA_Anesth_Record and CPT1_Class), a
            case overlap different from the decided one.
  Never   : puts a value or an MRN in the log or QC.
  Session : fresh SAS session, never the one that ran the synthetic test.
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance: C1 no ?? in PROC SQL, C3 no open-code %if, C9 engine before
  path, C11 no macro keyword in quoted PUT text, C13 macros defined before use,
  C30 no semicolon in %put or fail_out text, C36 the include target exists.
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from a test session. */
%let p18_fail_mode = ABORT;
%let _p18_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\18a_comb_preflight.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\18_combine_macros.sas";

%macro p18a_dump;
  %p18_dump_qc(tables=pre asacpt, file=&qc_path.\comb_pre.csv);
  %p18_flush_qc;
%mend p18a_dump;

%macro fail_out(msg=);
  %put ERROR: [18a_comb_preflight] &msg;
  %p18a_dump;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [18a_comb_preflight] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p18a_main;
  %local _t _n_pcnr _n_s21 _n_s22 _n_s23 _d_pcnr _d_s21 _d_s22 _d_s23
         _n_unexp _n_nosrc _n_conv _n_dec _nn _nc;
  %route_log;
  %p18_qinit(ds=pdd.qc_comb_pre);
  %p18_qinit(ds=pdd.qc_comb_asacpt);

  /* 1 tables must exist */
  %p18_require(tables=pdd.pcnr pdd.name_map_vars_ext pdd.name_map_ext
               pdd.name_map_coverage pdd.name_map_vars_coverage pdd.nsrc_s21
               pdd.nsrc_s22 pdd.nsrc_s23 pdd.pecan_id_case_map
               pdd.pecan_id_registry pdd.pecan_id_dup_link);

  /* 6 read-only baseline of the three pecan_id tables */
  %p18_ro_start;
  %p18_qadd(ds=pdd.qc_comb_pre, item=registry_rows_at_start, n=&_p18_ro_reg);
  %p18_qadd(ds=pdd.qc_comb_pre, item=dup_link_rows_at_start, n=&_p18_ro_dup);
  %p18_qadd(ds=pdd.qc_comb_pre, item=case_map_rows_at_start, n=&_p18_ro_map);

  /* PDD-D-33 mode (decided, default NORM) reported, not a stop */
  %p18_psid_mode;
  %p18_qadd(ds=pdd.qc_comb_pre, item=k2_psid_mode_&PDD_K2_PSID_MODE, n=1);

  /* 2 decided types and the PENDING_DECISION stop */
  %p18_load_types(decisions=C:\data_dictionary\docs\combined_type_decisions.csv);
  %p18_qadd(ds=pdd.qc_comb_pre, item=mapped_pcnr_variables, n=&_p18_nvars);
  proc sql noprint;
    select count(*) into :_n_dec trimmed from work.p18_vars
      where decided_type ne ext_type and strip(decision_ref) = '';
  quit;
  %p18_qadd(ds=pdd.qc_comb_pre, item=type_differs_from_ext_without_decision, n=&_n_dec,
            fail=%eval(&_n_dec > 0));
  %if &_n_dec > 0 %then
    %fail_out(msg=%str(PENDING DECISION - decided type differs from the name map type and has no decision row));

  /* 3 column inventory (names and types only) and the pdd.pcnr column check */
  proc sql noprint;
    create table work.p18a_inv as
      select 'pcnr' as src length=8, name length=64, type length=4, length as clen,
             case when upcase(name) = 'NORM_PSID' then 'KEY'
                  when upcase(name) = 'PCNR_PRECEDE_STUDY_ID' then 'KEY'
                  when upcase(name) in (select upcase(pcnr_name) from work.p18_vars) then 'MAPPED'
                  else 'UNEXPLAINED' end as status length=12
      from dictionary.columns where libname = 'PDD' and memname = 'PCNR'
      outer union corresponding
      select 's21' as src length=8, name length=64, type length=4, length as clen,
             'SOURCE' as status length=12
      from dictionary.columns where libname = 'PDD' and memname = 'NSRC_S21'
      outer union corresponding
      select 's22' as src length=8, name length=64, type length=4, length as clen,
             'SOURCE' as status length=12
      from dictionary.columns where libname = 'PDD' and memname = 'NSRC_S22'
      outer union corresponding
      select 's23' as src length=8, name length=64, type length=4, length as clen,
             'SOURCE' as status length=12
      from dictionary.columns where libname = 'PDD' and memname = 'NSRC_S23';
    select count(*) into :_n_unexp trimmed from work.p18a_inv where status = 'UNEXPLAINED';
  quit;
  data work.p18a_inv;
    set work.p18a_inv;
    rename clen = length;
  run;
  %p18_export(ds=work.p18a_inv, file=&qc_path.\comb_pre_inventory.csv,
              cols=src name type length status, numcols=);
  %p18_qadd(ds=pdd.qc_comb_pre, item=pcnr_columns_not_mapped_and_not_key, n=&_n_unexp,
            fail=%eval(&_n_unexp > 0));
  %if &_n_unexp > 0 %then
    %fail_out(msg=%str(PENDING DECISION - &_n_unexp pdd.pcnr column(s) are neither NORM_PSID nor a mapped PCNR_ name. Names are in qc comb_pre_inventory with status UNEXPLAINED));

  /* source maps and lengths */
  %p18_srcmap(src=pdd.pcnr, kind=OLD, tag=old);
  %p18_srcmap(src=pdd.nsrc_s21, kind=NEW, scode=s21, tag=s21);
  %p18_srcmap(src=pdd.nsrc_s22, kind=NEW, scode=s22, tag=s22);
  %p18_srcmap(src=pdd.nsrc_s23, kind=NEW, scode=s23, tag=s23);
  %p18_set_lengths(tags=old s21 s22 s23);
  proc sql noprint;
    select count(*) into :_n_nosrc trimmed
    from work.p18_vars v
    where v.idx not in (select idx from work.p18_sm_old where srcname ne '')
      and v.idx not in (select idx from work.p18_sm_s21 where srcname ne '')
      and v.idx not in (select idx from work.p18_sm_s22 where srcname ne '')
      and v.idx not in (select idx from work.p18_sm_s23 where srcname ne '');
  quit;
  %p18_qadd(ds=pdd.qc_comb_pre, item=mapped_variables_without_any_source_column, n=&_n_nosrc,
            fail=%eval(&_n_nosrc > 0));
  %if &_n_nosrc > 0 %then
    %fail_out(msg=%str(PENDING DECISION - &_n_nosrc mapped variable(s) have no source column in pdd.pcnr or the three new sources));

  /* 4 dry conversion of every source in WORK: counts only */
  %p18_typeconv_reset;
  %p18_build_source(src=pdd.pcnr, out=work.p18a_b_old, tag=old);
  %p18_typeconv_add(tag=old);
  %p18_build_source(src=pdd.nsrc_s21, out=work.p18a_b_s21, tag=s21);
  %p18_typeconv_add(tag=s21);
  %p18_build_source(src=pdd.nsrc_s22, out=work.p18a_b_s22, tag=s22);
  %p18_typeconv_add(tag=s22);
  %p18_build_source(src=pdd.nsrc_s23, out=work.p18a_b_s23, tag=s23);
  %p18_typeconv_add(tag=s23);
  proc datasets lib=work nolist;
    delete p18a_b_: ;
  quit;

  /* type delta report (names and counts, masked in the export) */
  proc sql noprint;
    create table work.p18a_pt as
      select upcase(name) as ukey length=64, case when upcase(type) = 'CHAR' then 'C' else 'N' end as ptype length=1
      from dictionary.columns where libname = 'PDD' and memname = 'PCNR';
    create table work.p18a_nt as
      select idx, catx('/', max(case when srctype = 'C' then 'C' end),
                       max(case when srctype = 'N' then 'N' end)) as new_types length=8
      from (select idx, srctype from work.p18_sm_s21 where srcname ne ''
            outer union corresponding select idx, srctype from work.p18_sm_s22 where srcname ne ''
            outer union corresponding select idx, srctype from work.p18_sm_s23 where srcname ne '')
      group by idx;
    create table work.p18a_tcs as
      select upcase(pcnr_name) as ukey length=64,
             sum(n_null_as_missing) as n_null_as_missing, sum(n_char_to_num_fail) as n_conv_fail
      from work.qc_comb_typeconv group by upcase(pcnr_name);
    create table work.p18a_delta as
      select v.pcnr_name as pcnr_name length=64, v.ext_type as ext_type length=1,
             v.decided_type as decided_type length=1, coalesce(p.ptype, '') as pcnr_type length=1,
             coalesce(n.new_types, '') as new_types length=8,
             coalesce(t.n_null_as_missing, 0) as n_null_as_missing,
             coalesce(t.n_conv_fail, 0) as n_conv_fail,
             v.decision_ref as decision_ref length=40
      from work.p18_vars v
      left join work.p18a_pt p on upcase(v.pcnr_name) = p.ukey
      left join work.p18a_nt n on v.idx = n.idx
      left join work.p18a_tcs t on upcase(v.pcnr_name) = t.ukey
      order by v.idx;
    select count(*) into :_n_conv trimmed from work.p18a_delta
      where pcnr_type ne '' and pcnr_type ne decided_type;
  quit;
  %p18_export(ds=work.p18a_delta, file=&exchange_path.\comb_type_delta.csv,
              cols=pcnr_name ext_type decided_type pcnr_type new_types n_null_as_missing n_conv_fail decision_ref,
              numcols=n_null_as_missing n_conv_fail);
  proc sql noprint;
    select count(*) into :_nn trimmed from work.p18_vars where decided_type = 'N';
    select count(*) into :_nc trimmed from work.p18_vars where decided_type = 'C';
  quit;
  %p18_qadd(ds=pdd.qc_comb_pre, item=variables_decided_numeric, n=&_nn);
  %p18_qadd(ds=pdd.qc_comb_pre, item=variables_decided_text, n=&_nc);
  %p18_qadd(ds=pdd.qc_comb_pre, item=variables_pcnr_type_differs_will_convert, n=&_n_conv);

  /* ASA_Anesth_Record and CPT1_Class (PDD-D-31 item 2, conditional): measured
     answer per side. Failure counts above 0 stop the run at PENDING DECISION. */
  data work.qc_comb_asacpt;
    length item $80 n 8 isfail 8;
    set work.qc_comb_typeconv;
    where index(upcase(pcnr_name), 'ASA_ANESTH_RECORD') > 0
       or index(upcase(pcnr_name), 'CPT1_CLASS') > 0;
    item = catx('_', 'non_numeric_values', strip(pcnr_name), strip(s_code));
    n = n_char_to_num_fail;
    isfail = (n_char_to_num_fail > 0);
    keep item n isfail;
  run;
  %p18_gate_conv(qc=work.qc_comb_pre);

  /* 5 case counts and overlaps from the data */
  %p18_nobs(ds=pdd.pcnr, mv=_n_pcnr);
  %p18_nobs(ds=pdd.nsrc_s21, mv=_n_s21);
  %p18_nobs(ds=pdd.nsrc_s22, mv=_n_s22);
  %p18_nobs(ds=pdd.nsrc_s23, mv=_n_s23);
  proc sql noprint;
    select count(distinct norm_psid) into :_d_pcnr trimmed from pdd.pcnr where norm_psid ne '';
    select count(distinct norm_psid) into :_d_s21 trimmed from pdd.nsrc_s21 where norm_psid ne '';
    select count(distinct norm_psid) into :_d_s22 trimmed from pdd.nsrc_s22 where norm_psid ne '';
    select count(distinct norm_psid) into :_d_s23 trimmed from pdd.nsrc_s23 where norm_psid ne '';
  quit;
  %p18_qadd(ds=pdd.qc_comb_pre, item=n_pcnr, n=&_n_pcnr);
  %p18_qadd(ds=pdd.qc_comb_pre, item=n_s21, n=&_n_s21);
  %p18_qadd(ds=pdd.qc_comb_pre, item=n_s22, n=&_n_s22);
  %p18_qadd(ds=pdd.qc_comb_pre, item=n_s23, n=&_n_s23);
  %p18_qadd(ds=pdd.qc_comb_pre, item=distinct_norm_psid_pcnr, n=&_d_pcnr, fail=%eval(&_d_pcnr ne &_n_pcnr));
  %p18_qadd(ds=pdd.qc_comb_pre, item=distinct_norm_psid_s21, n=&_d_s21, fail=%eval(&_d_s21 ne &_n_s21));
  %p18_qadd(ds=pdd.qc_comb_pre, item=distinct_norm_psid_s22, n=&_d_s22, fail=%eval(&_d_s22 ne &_n_s22));
  %p18_qadd(ds=pdd.qc_comb_pre, item=distinct_norm_psid_s23, n=&_d_s23, fail=%eval(&_d_s23 ne &_n_s23));
  %if &_d_pcnr ne &_n_pcnr or &_d_s21 ne &_n_s21 or &_d_s22 ne &_n_s22 or &_d_s23 ne &_n_s23 %then
    %fail_out(msg=%str(a source has repeated or blank norm_psid values - see qc comb_pre));
  %p18_read_expected(file=C:\data_dictionary\docs\new_overlap_decisions.csv);
  %p18_gate_overlap(old=pdd.pcnr, s21=pdd.nsrc_s21, s22=pdd.nsrc_s22, s23=pdd.nsrc_s23,
                    exp=&_p18_exp_shared, qc=work.qc_comb_pre);

  /* the three pecan_id tables are unchanged by this program */
  %p18_ro_end(qc=work.qc_comb_pre);

  %p18a_dump;
  %put NOTE: [18a_comb_preflight] PASS - preflight complete, nothing written to the combined dataset;
  %restore_log;
%mend p18a_main;

%p18a_main;
