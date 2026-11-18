/*==========================================================================
  Program : 19a_xlsx_preflight.sas
  Phase   : 19 (master data workbook), Wave 1, plan 19-03
  Purpose : Preflight and probe for PCNR_Master_Data_Nov_2026.xlsx. One SAS
            session answers probes P19-1..P19-8 (counts only) and checks the
            Excel limits (XLS-02) against the real dataset. Read-only on every
            pdd table: it writes no pdd.pcnr_2018_2025, no registry, no dup link,
            no case map.
  Probes  : P19-1 numeric date-like variables (integer ranges, counts)
            P19-2 text length, cells over 255 characters, control characters,
                  newlines, non-ASCII and replacement characters
            P19-3 text cells starting with = # + - @ (formula risk) and digit
                  text with a leading zero
            P19-4 numeric cells at or above 1e15, 15 digit round trip failures
            P19-5 special missing codes .A-.Z and ._ per variable
            P19-6 KEY_ERA x PECAN_ID_KEY_ERA and NORM_PSID vs PRECEDE_STUDY_ID
            P19-7 SAS side CSV write speed of the first rows (throwaway file in
                  out_root\stage, deleted at once) and free disk of the drive
            P19-8 dataset facts: rows, columns, character and numeric counts,
                  encoding
  Reads   : pdd.pcnr_2018_2025, pdd.name_map_vars_ext, pdd.pecan_id_registry,
            pdd.pecan_id_dup_link, pdd.pecan_id_case_map (counts only)
  Writes  : pdd.qc_xlsx_pre (one flush at the end), qc\xlsx_master_pre.csv,
            qc\xlsx_master_probe.csv (masked), exchange\xlsx_master_probe_summary.csv
            (masked), the log. Row-level data: none kept (the speed test CSV is
            deleted and the delete is checked).
  Stops   : ABORT with PENDING DECISION or a limits message, QC written first.
            Empty PDD_XLS_* decisions are only listed as PENDING DECISION lines
            (this is a probe run: its job is to supply the facts for them).
  Never   : puts a cell value, an ID or an MRN in the log or a CSV.
  Session : fresh SAS session, UTF-8, never the one that ran 19_xlsx_test.
            Close table viewers on pdd first.
  Status  : PENDING SAS RUN (Gerard).

  PCM compliance: C1 no ?? in PROC SQL, C3 no open-code %if, C9 engine before
  path, C11 no macro keyword in quoted PUT text, C13 macros defined before use,
  C30 no semicolon in %put or fail_out text, C31 no POINT= step.
==========================================================================*/

%include "C:\data_dictionary\sas\00_config.sas";

/* Production run: always ABORT. Never inherit FLAG from a test session. */
%let p19_fail_mode = ABORT;
%let p18_fail_mode = ABORT;
%let _p19_failed = 0;
%let _p18_failed = 0;

%pdd_lib;

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\19a_xlsx_preflight.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* The Phase 18 and 17 macros load through the first line of the 19 macros */
%include "&sas_path.\19_xlsx_macros.sas";

%macro p19a_dump;
  %p19_dump_qc(tables=pre, file=&qc_path.\xlsx_master_pre.csv);
  %p19_flush_qc;
%mend p19a_dump;

%macro fail_out(msg=);
  %put ERROR: [19a_xlsx_preflight] &msg;
  %p19a_dump;
  %restore_log;
  %put ERROR: [19a_xlsx_preflight] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

/* PENDING DECISION lines for every empty PDD_XLS_* choice (no stop) */
%macro p19a_decisions;
  %local _i _v _n;
  %let _n = 0;
  %do _i = 1 %to 11;
    %let _v = %scan(ROUTE NODATA ORDER DATES NUMTEXT SPECIAL SHEETS COMPANION KEYS APPROVE DICT, &_i, %str( ));
    %p19_need_decision(var=PDD_XLS_&_v, allowed=, stop=0);
    %if &_p19_dec_status = EMPTY %then %let _n = %eval(&_n + 1);
  %end;
  %p19_qadd(ds=work.qc_xlsx_pre, item=decisions_still_empty_pending, n=&_n);
  %put NOTE: [19a_xlsx_preflight] &_n of 11 PDD_XLS decisions are PENDING DECISION (expected in a probe run);
%mend p19a_decisions;

%macro p19a_main;
  %local _sd _utf _bsec _bmin;
  %route_log;
  %p19_qinit(ds=pdd.qc_xlsx_pre);

  /* 1 path guard on every target, tables must exist */
  %p19_path_guard(path=&qc_path.\xlsx_master_pre.csv);
  %p19_path_guard(path=&exchange_path.\xlsx_master_probe_summary.csv);
  %p19_path_guard(path=&xls_stage_path.\xlsx_bench.csv);
  %p19_path_guard(path=&xls_bak_path.);
  %p18_require(tables=pdd.pcnr_2018_2025 pdd.name_map_vars_ext pdd.pecan_id_registry
               pdd.pecan_id_dup_link pdd.pecan_id_case_map);

  /* 2 read-only baseline of the three pecan_id tables */
  %p18_ro_start;
  %p19_qadd(ds=work.qc_xlsx_pre, item=registry_rows_at_start, n=&_p18_ro_reg);
  %p19_qadd(ds=work.qc_xlsx_pre, item=dup_link_rows_at_start, n=&_p18_ro_dup);
  %p19_qadd(ds=work.qc_xlsx_pre, item=case_map_rows_at_start, n=&_p18_ro_map);

  /* 3 decisions still open (listed, no stop) */
  %p19a_decisions;

  /* 4 P19-8 dataset facts */
  %p19_dataset_facts(ds=pdd.pcnr_2018_2025);
  %p19_qadd(ds=work.qc_xlsx_pre, item=dataset_rows, n=&_p19_nrows);
  %p19_qadd(ds=work.qc_xlsx_pre, item=dataset_columns, n=&_p19_ncols);
  %p19_qadd(ds=work.qc_xlsx_pre, item=dataset_character_columns, n=&_p19_nchar);
  %p19_qadd(ds=work.qc_xlsx_pre, item=dataset_numeric_columns, n=&_p19_nnum);
  %let _utf = 0;
  %if %index(%upcase(&_p19_enc), UTF) > 0 %then %let _utf = 1;
  %p19_qadd(ds=work.qc_xlsx_pre, item=dataset_encoding_is_utf8_1_else_0, n=&_utf);
  %put NOTE: [19a_xlsx_preflight] dataset encoding is &_p19_enc;

  /* 5 allow list (key and mapped names only, no MRN or encounter field) */
  %p19_allowlist(ds=pdd.pcnr_2018_2025, vars=pdd.name_map_vars_ext, qc=work.qc_xlsx_pre,
                 out=work.p19a_cols_flagged);

  /* 6 P19-1..P19-5 and P19-8 probes, P19-6 keys */
  %p19_probe(ds=pdd.pcnr_2018_2025, out=work.p19_pr);
  %p19_keys(ds=pdd.pcnr_2018_2025, out=work.p19_pr_k);
  data work.p19_pr_all;
    length variable $64 chk $40 n 8 vtype $4 tot 8;
    set work.p19_pr work.p19_pr_k;
  run;
  %p19_probe_report(in=work.p19_pr_all, detail=&qc_path.\xlsx_master_probe.csv,
                    summary=&exchange_path.\xlsx_master_probe_summary.csv);
  %p19_probe_gate_inputs(in=work.p19_pr);

  /* 7 P19-7 free disk and SAS side write speed (needs the stage folder) */
  %p19_freegb(path=&out_root, mv=_p19_free_gb);
  %let _sd = %sysfunc(dcreate(stage, &out_root));
  %p19_bench_sas(ds=pdd.pcnr_2018_2025, file=&xls_stage_path.\xlsx_bench.csv, rows=1000);
  %let _bsec = %sysfunc(ceil(%sysevalf(&_p19_bench_secs * 100)));
  %let _bmin = %sysfunc(ceil(&_p19_bench_est_min));
  %p19_qadd(ds=work.qc_xlsx_pre, item=sas_bench_seconds_1000_rows_x100, n=&_bsec);
  %p19_qadd(ds=work.qc_xlsx_pre, item=sas_bench_estimate_full_minutes, n=&_bmin);

  /* 8 XLS-02 limits gate against the real dataset */
  %p19_limits(rows=&_p19_nrows, cols=&_p19_ncols, maxlen=&_p19_maxlen, nctrl=&_p19_nctrl,
              freegb=&_p19_free_gb, mingb=&PDD_XLS_MIN_FREE_GB, qc=work.qc_xlsx_pre);

  /* 9 the three pecan_id tables are unchanged by this program */
  %p18_ro_end(qc=work.qc_xlsx_pre);

  %p19a_dump;
  %put NOTE: [19a_xlsx_preflight] PASS - preflight complete, limits gate PASS, nothing written to the combined dataset;
  %restore_log;
%mend p19a_main;

%p19a_main;
