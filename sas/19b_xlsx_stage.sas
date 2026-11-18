/*==========================================================================
  Program : 19b_xlsx_stage.sas
  Phase   : 19 (master data workbook), Wave 2, plan 19-04
  Purpose : Write the stage files the Python writer turns into
            PCNR_Master_Data_Nov_2026.xlsx. Production, fresh SAS session.
              stage\xlsx_data.csv      header + one record per row (UTF-8, CRLF)
              stage\xlsx_schema.csv    col_index, name, sas_type, excel_kind
              stage\xlsx_expected.csv  exact counts and a seeded sample row list
            The stage files hold row-level data (identifiable fields, approved
            PeCAN team use only). They stay under out_root\stage and are deleted
            by the verifier on PASS. Nothing goes to the shared Master Data
            folder. The log, QC and exchange files hold names and counts only.
  Gates   : every PDD_XLS_* choice must be a decided value (empty stops with
            PENDING DECISION), PDD_XLS_APPROVE must be 1 (set at run time with
            options set=PDD_XLS_APPROVE 1, never in config), path guard on every
            target, allow-list gate, export column gate (K3 keys first, NORM_PSID
            and PECAN_ID_KEY_ERA never staged), XLS-02 limits gate against the
            real dataset, CSV records = dataset rows + 1, registry, dup link and
            case map row counts unchanged.
  Reads   : pdd.pcnr_2018_2025, pdd.name_map_vars_ext, registry, dup link, case
            map (counts only).
  Writes  : stage\ files above, pdd.qc_xlsx_stage (one flush), qc\xlsx_master_stage.csv
            (masked), the log. Writes no pdd table other than the QC table.
  Stdout  : PASS - stage written, row count equal (or ERROR with the reason).
  Session : fresh SAS session, UTF-8. Close table viewers on pdd first.
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
    proc printto log="&logs_path.\19b_xlsx_stage.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%include "&sas_path.\19_xlsx_macros.sas";

%macro p19b_dump;
  %p19_dump_qc(tables=stage, file=&qc_path.\xlsx_master_stage.csv);
  %p19_flush_qc;
%mend p19b_dump;

%macro fail_out(msg=);
  %put ERROR: [19b_xlsx_stage] &msg;
  %p19b_dump;
  %restore_log;
  %put ERROR: [19b_xlsx_stage] &msg;
  %abort cancel;
%mend fail_out;

%check_encoding;
%check_pdd_lib;

/* every decision must be set to a value this program implements */
%macro p19b_decisions;
  %p19_need_decision(var=PDD_XLS_ROUTE, allowed=STAGE_CSV);
  %p19_need_decision(var=PDD_XLS_NODATA, allowed=INCLUDE);
  %p19_need_decision(var=PDD_XLS_ORDER, allowed=DICT);
  %p19_need_decision(var=PDD_XLS_DATES, allowed=SERIAL);
  %p19_need_decision(var=PDD_XLS_NUMTEXT, allowed=TEXT);
  %p19_need_decision(var=PDD_XLS_SPECIAL, allowed=BLANK);
  %p19_need_decision(var=PDD_XLS_SHEETS, allowed=ONE);
  %p19_need_decision(var=PDD_XLS_COMPANION, allowed=NONE);
  %p19_need_decision(var=PDD_XLS_KEYS, allowed=K3 K4);
  %p19_need_decision(var=PDD_XLS_APPROVE, allowed=1);
  %p19_need_decision(var=PDD_XLS_DICT, allowed=NO);
%mend p19b_decisions;

%macro p19b_main;
  %local _sd _expected_recs;
  %route_log;
  %p19_qinit(ds=pdd.qc_xlsx_stage);

  /* 1 decisions, path guards, required tables */
  %p19b_decisions;
  %p19_path_guard(path=&xls_stage_path.\xlsx_data.csv);
  %p19_path_guard(path=&xls_stage_path.\xlsx_schema.csv);
  %p19_path_guard(path=&xls_stage_path.\xlsx_expected.csv);
  %p19_path_guard(path=&qc_path.\xlsx_master_stage.csv);
  %p19_path_guard(path=&xls_bak_path.);
  %p18_require(tables=pdd.pcnr_2018_2025 pdd.name_map_vars_ext pdd.pecan_id_registry
               pdd.pecan_id_dup_link pdd.pecan_id_case_map);

  /* 2 read-only baseline of the three pecan_id tables */
  %p18_ro_start;
  %p19_qadd(ds=work.qc_xlsx_stage, item=registry_rows_at_start, n=&_p18_ro_reg);
  %p19_qadd(ds=work.qc_xlsx_stage, item=dup_link_rows_at_start, n=&_p18_ro_dup);
  %p19_qadd(ds=work.qc_xlsx_stage, item=case_map_rows_at_start, n=&_p18_ro_map);

  /* 3 dataset facts, allow list, export column list */
  %p19_dataset_facts(ds=pdd.pcnr_2018_2025);
  %p19_qadd(ds=work.qc_xlsx_stage, item=dataset_rows, n=&_p19_nrows);
  %p19_qadd(ds=work.qc_xlsx_stage, item=dataset_columns, n=&_p19_ncols);
  %p19_allowlist(ds=pdd.pcnr_2018_2025, vars=pdd.name_map_vars_ext, qc=work.qc_xlsx_stage,
                 out=work.p19b_cols_flagged);
  %p19_columns(ds=pdd.pcnr_2018_2025, out=work.p19b_cols, keys=&PDD_XLS_KEYS,
               vars=pdd.name_map_vars_ext, qc=work.qc_xlsx_stage);

  /* 4 XLS-02 limits gate against the real dataset (exported column count) */
  %p19_probe(ds=pdd.pcnr_2018_2025, out=work.p19_pr);
  %p19_probe_gate_inputs(in=work.p19_pr);
  %p19_freegb(path=&out_root, mv=_p19_free_gb);
  %p19_limits(rows=&_p19_nrows, cols=&_p19_nexp, maxlen=&_p19_maxlen, nctrl=&_p19_nctrl,
              freegb=&_p19_free_gb, mingb=&PDD_XLS_MIN_FREE_GB, qc=work.qc_xlsx_stage);

  /* 5 stage files (stage folder created if absent) */
  %let _sd = %sysfunc(dcreate(stage, &out_root));
  %p19_stage(ds=pdd.pcnr_2018_2025, cols=work.p19b_cols, out=&xls_stage_path.\xlsx_data.csv,
             schema=&xls_stage_path.\xlsx_schema.csv);
  %p19_csv_records(file=&xls_stage_path.\xlsx_data.csv);
  %let _expected_recs = %eval(&_p19_nrows + 1);
  %p19_qadd(ds=work.qc_xlsx_stage, item=stage_csv_records_incl_header, n=&_p19_csv_recs,
            fail=%eval(&_p19_csv_recs ne &_expected_recs));
  %p19_qadd(ds=work.qc_xlsx_stage, item=stage_csv_physical_lines, n=&_p19_csv_lines);
  %if &_p19_csv_recs ne &_expected_recs %then
    %p19_fail(msg=%str(stage CSV record count differs from dataset rows plus one));

  /* 6 expected counts and sample list */
  %p19_expected(ds=pdd.pcnr_2018_2025, cols=work.p19b_cols, out=&xls_stage_path.\xlsx_expected.csv);

  /* 7 the three pecan_id tables are unchanged by this program */
  %p18_ro_end(qc=work.qc_xlsx_stage);

  %p19b_dump;
  %put NOTE: [19b_xlsx_stage] PASS - stage written, row count equal, stage files are row-level data under stage only;
  %restore_log;
%mend p19b_main;

%p19b_main;
