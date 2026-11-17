/*==========================================================================
  Program : 18b_comb_build.sas
  Phase   : 18 (combined dataset and dictionary 2018-2025), plan 18-04
  Purpose : Build pdd.pcnr_2018_2025: one row per surgery 2018-2025, PECAN_ID
            and PRECEDE_STUDY_ID first, every PCNR_ variable of the name map in
            its decided type (DD-01, DD-02).
            Old era rows come from the frozen pdd.pcnr (D18-1), new era rows from
            pdd.nsrc_s21..s23 through pdd.name_map_ext (D18-2). PDD-D-30: s22 wins,
            s23 fills missing values only, field by field, conflicts counted per
            column. PDD-D-33 (decided 2026-11-17): K2 PRECEDE_STUDY_ID is the
            normalized Precede form, PDD_K2_PSID_MODE defaults to NORM.
  Reads   : as 18a. pdd.pecan_id_registry, pdd.pecan_id_dup_link and
            pdd.pecan_id_case_map are read-only (row counts checked at start and
            end).
  Writes  : pdd.pcnr_2018_2025 (replaced on rerun, previous copy backed up first
            as pcnrcmb_YYYYMMDD_HHMMSS), pdd.qc_comb_build, pdd.qc_comb_d30,
            pdd.qc_comb_typeconv (each written once), qc\comb_build.csv,
            exchange\comb_d30_conflicts.csv, the log.
  Order   : gates run on WORK tables BEFORE the final dataset is written. A
            failed gate flushes QC and aborts with nothing written.
  Never   : puts a value or an MRN in the log or QC, writes a column named
            ENCRYPTED_*, touches pdd.pcnr or the v1.0 outputs.
  Session : fresh SAS session, after 18a PASS. Close table viewers on pdd.
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance: C1, C3, C9, C11, C13, C30, C36 as in 18a. No POINT= step (C31).
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from a test session. */
%let p18_fail_mode = ABORT;
%let p17_fail_mode = ABORT;
%let _p18_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\18b_comb_build.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\18_combine_macros.sas";

%macro p18b_dump;
  %p18_dump_qc(tables=build, file=&qc_path.\comb_build.csv);
  %p18_flush_qc;
%mend p18b_dump;

%macro fail_out(msg=);
  %put ERROR: [18b_comb_build] &msg;
  %p18b_dump;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [18b_comb_build] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

%macro p18b_main;
  %local _n_old _n_s21 _n_s22 _n_s23 _n_out _n_fin;
  %route_log;
  %p18_qinit(ds=pdd.qc_comb_build);

  /* 1 preconditions as in 18a */
  %p18_require(tables=pdd.pcnr pdd.name_map_vars_ext pdd.name_map_ext
               pdd.nsrc_s21 pdd.nsrc_s22 pdd.nsrc_s23 pdd.pecan_id_case_map
               pdd.pecan_id_registry pdd.pecan_id_dup_link);
  %p18_ro_start;
  %p18_psid_mode;
  %p18_qadd(ds=pdd.qc_comb_build, item=k2_psid_mode_&PDD_K2_PSID_MODE, n=1);
  %p18_load_types(decisions=C:\data_dictionary\docs\combined_type_decisions.csv);
  %p18_qadd(ds=pdd.qc_comb_build, item=mapped_pcnr_variables, n=&_p18_nvars);
  %p18_read_expected(file=C:\data_dictionary\docs\new_overlap_decisions.csv);

  /* 2 and 3 source maps, then every source converted to the decided types */
  %p18_srcmap(src=pdd.pcnr, kind=OLD, tag=old);
  %p18_srcmap(src=pdd.nsrc_s21, kind=NEW, scode=s21, tag=s21);
  %p18_srcmap(src=pdd.nsrc_s22, kind=NEW, scode=s22, tag=s22);
  %p18_srcmap(src=pdd.nsrc_s23, kind=NEW, scode=s23, tag=s23);
  %p18_set_lengths(tags=old s21 s22 s23);
  %p18_typeconv_reset;
  %p18_build_source(src=pdd.pcnr, out=work.b_old, tag=old);
  %p18_typeconv_add(tag=old);
  %p18_build_source(src=pdd.nsrc_s21, out=work.b_s21, tag=s21);
  %p18_typeconv_add(tag=s21);
  %p18_build_source(src=pdd.nsrc_s22, out=work.b_s22, tag=s22);
  %p18_typeconv_add(tag=s22);
  %p18_build_source(src=pdd.nsrc_s23, out=work.b_s23, tag=s23);
  %p18_typeconv_add(tag=s23);
  %p18_gate_conv(qc=pdd.qc_comb_build);

  /* case overlaps: s21 shares 0 with s22 and s23, old shares 0 with new,
     s22 x s23 equals the decided count read from the CSV */
  %p18_gate_overlap(old=work.b_old, s21=work.b_s21, s22=work.b_s22, s23=work.b_s23,
                    exp=&_p18_exp_shared, qc=pdd.qc_comb_build);

  /* 4 PDD-D-30 merge of s22 and s23 */
  %p18_d30_merge(a=work.b_s22, b=work.b_s23, out=work.b_m);

  /* 5 stack old, s21 and the merged s22+s23 */
  %p18_nobs(ds=work.b_old, mv=_n_old);
  %p18_nobs(ds=work.b_s21, mv=_n_s21);
  %p18_nobs(ds=work.b_s22, mv=_n_s22);
  %p18_nobs(ds=work.b_s23, mv=_n_s23);
  %p18_stack(old=work.b_old, s21=work.b_s21, merged=work.b_m, out=work.b_stk);
  proc datasets lib=work nolist;
    delete b_old b_s21 b_s22 b_s23 b_m;
  quit;

  /* 6 attach PECAN_ID, PECAN_ID_KEY_ERA, KEY_ERA, PRECEDE_STUDY_ID (PDD-D-33) */
  %p18_gate_rows(ds=work.b_stk, n_old=&_n_old, n_s21=&_n_s21, n_s22=&_n_s22,
                 n_s23=&_n_s23, shared=&_p18_ov_22_23, qc=pdd.qc_comb_build);
  %p18_attach_ids(in=work.b_stk, map=pdd.pecan_id_case_map, out=work.b_att,
                  qc=pdd.qc_comb_build);
  %p18_order_cols(in=work.b_att, out=work.b_final);
  proc datasets lib=work nolist;
    delete b_stk b_att;
  quit;

  /* 7 final gates on the WORK table: variables, types, order, no ENCRYPTED_ column */
  %p18_gate_vars(ds=work.b_final, order=1, qc=pdd.qc_comb_build);
  %p18_gate_rows(ds=work.b_final, n_old=&_n_old, n_s21=&_n_s21, n_s22=&_n_s22,
                 n_s23=&_n_s23, shared=&_p18_ov_22_23, qc=pdd.qc_comb_build);

  /* 8 backup of an existing copy, then the one write of the dataset */
  %p18_backup_comb(ds=pdd.&comb_ds, stem=&comb_backup_stem);
  %p18_qadd(ds=pdd.qc_comb_build, item=previous_copy_backed_up, n=&_p18_bak_done);
  data pdd.&comb_ds;
    set work.b_final;
  run;
  %p18_nobs(ds=work.b_final, mv=_n_fin);
  %p18_nobs(ds=pdd.&comb_ds, mv=_n_out);
  %p18_qadd(ds=pdd.qc_comb_build, item=rows_written, n=&_n_out, fail=%eval(&_n_out ne &_n_fin));
  %if &_n_out ne &_n_fin %then
    %fail_out(msg=%str(rows written to the combined dataset differ from the WORK table));

  /* 10 read-only guard, 9 one QC flush and the exports */
  %p18_ro_end(qc=pdd.qc_comb_build);
  %p18_export(ds=work.qc_comb_d30, file=&exchange_path.\comb_d30_conflicts.csv,
              cols=pcnr_name n_shared n_s22_missing_filled n_conflict_kept_s22,
              numcols=n_shared n_s22_missing_filled n_conflict_kept_s22);
  %p18b_dump;
  %put NOTE: [18b_comb_build] PASS - pdd.&comb_ds written with &_n_out rows;
  %restore_log;
%mend p18b_main;

%p18b_main;
