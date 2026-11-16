/*==========================================================================
  Program : 20_pecan_id.sas
  Purpose : Build the pecan_ID patient linkage key from ENCRYPTED_MRN.
            Verifies md3 source checksum (PID-01), audits MRN cardinality
            (PID-02, PID-03), builds the append-only crosswalk g.pecan_id_xwalk
            with a dated backup (PID-04), tests linkage reach of every raw file
            carrying ENCRYPTED_MRN including r7/r8/r9 (PID-07), and notes
            PCM-D-17/PCM-D-18 completion (PID-08).

  Reads   : qc/19_raw_files.csv, qc/19_raw_key_columns.csv,
            qc/19_raw_sheets.csv, qc/19_raw_variables_md3.csv  (Phase 19 handoffs)
            raw\master\2018_2022_X_MASTER_DATASET_20240402.csv (md3 source, read-only)
            g.master_data_merged                                (read-only)
            g.pecan_id_xwalk                                    (append-only)
            Every raw file Phase 19 tagged ENCRYPTED_MRN        (read-only)

  Writes  : g.pecan_id_xwalk           (new or appended)
            [xwalk_backup_path]/pecan_id_xwalk_<stamp>.sas7bdat (dated backup)
            qc/20_linkage_reach.txt     (PID-07 output)
            logs/20_pecan_id.log        (when in_pipeline=0)

  PCM compliance:
    - No bare open-code %IF/%THEN; all conditional logic inside named macros
    - No apostrophes or embedded semicolons in %PUT text
    - Every %abort cancel inside %fail_out only
    - No automatic-macro row counts; explicit SELECT COUNT(*) INTO :macvar TRIMMED
    - ASCII only (session encoding is not UTF-8)
    - No in-place dataset rewrite (data g.X; set g.X;) -- PCM-T-02
    - No PROC SQL UPDATE
    - options nosyntaxcheck noerrorabend set before PROC IMPORT calls
    - Raw file paths never pass through macro parameters; they reach
      filerefs/librefs through FILENAME()/LIBNAME() inside DATA steps

  Requirements: PID-01, PID-02, PID-03, PID-04, PID-07, PID-08
  Created     : 2026-09-23 (Phase 20, plan 01)
  Revised     : 2026-09-23 (review fixes -- CALL EXECUTE timing, report layout,
                D-14 orphan/mismatch logic, r7/r8/r9 list, open-code %IF removal,
                ranking guard, MRN type guard, backup-on-change only)
                2026-09-29 (%unquote on digit-prefix sheet name literal in
                reach_one -- same macro-quoting fix as program 19 R5-01)
==========================================================================*/


/* ============================================================
   SECTION 0 -- Config, options, libnames, utility macros
   ============================================================ */

%include "C:\Master_Renamed_same_format_accross\sas\00_config.sas";

options validvarname=v7 nofmterr msglevel=i;
options nosyntaxcheck noerrorabend;

libname g "&g_path.";

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\20_pecan_id.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* The only macro that may call abort */
%macro fail_out(msg=);
  %put ERROR: &msg;
  %restore_log;
  %abort cancel;
%mend fail_out;

%macro check_dir(path=, label=);
  %if %sysfunc(fileexist(&path.)) = 0 %then %do;
    %fail_out(msg=&label. directory not found: &path.);
  %end;
%mend check_dir;

%check_dir(path=&logs_path., label=logs);
%check_dir(path=&qc_path.,   label=qc);
%check_dir(path=&g_path.,    label=g_path);

%route_log;

/* md3 source identity used throughout */
%let _md3_file = 2018_2022_X_MASTER_DATASET_20240402.csv;


/* ============================================================
   SECTION 1 -- Preconditions (PCM-T-12: enumerated individually)
   ============================================================ */

%macro check_phase19_csvs;
  %if %sysfunc(fileexist(&qc_path.\19_raw_files.csv)) = 0 %then %do;
    %fail_out(msg=PRECONDITION FAILED -- qc/19_raw_files.csv not found -- re-run program 19 first);
  %end;
  %if %sysfunc(fileexist(&qc_path.\19_raw_key_columns.csv)) = 0 %then %do;
    %fail_out(msg=PRECONDITION FAILED -- qc/19_raw_key_columns.csv not found -- re-run program 19 first);
  %end;
  %if %sysfunc(fileexist(&qc_path.\19_raw_sheets.csv)) = 0 %then %do;
    %fail_out(msg=PRECONDITION FAILED -- qc/19_raw_sheets.csv not found -- re-run program 19 first);
  %end;
  %if %sysfunc(fileexist(&qc_path.\19_raw_variables_md3.csv)) = 0 %then %do;
    %fail_out(msg=PRECONDITION FAILED -- qc/19_raw_variables_md3.csv not found -- re-run program 19 first);
  %end;
  %if %sysfunc(fileexist(&raw_path.\master\&_md3_file.)) = 0 %then %do;
    %fail_out(msg=PRECONDITION FAILED -- md3 source CSV not found in raw\master);
  %end;
  %put NOTE: [20] SECTION 1 preconditions passed -- all four Phase 19 CSVs and md3 source present;
%mend check_phase19_csvs;
%check_phase19_csvs;


/* ============================================================
   SECTION 2 -- PID-01: checksum the md3 source CSV and compare
   to the Phase 19 record in qc/19_raw_files.csv
   ============================================================ */

%let _computed_sha = FAILED;
data work._sha_md3;
  length _cmd $1000 line $400 compressed $400 sha256 $64;
  _cmd = 'certutil -hashfile "' || "&raw_path.\master\&_md3_file." || '" SHA256';
  sha256 = 'FAILED';
  infile ckpipe20 pipe filevar=_cmd end=_done truncover lrecl=400;
  do while (not _done);
    input line $400.;
    compressed = compress(line, ' ');
    if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
      sha256 = lowcase(compressed);
  end;
  if sha256 = 'FAILED' then put 'WARNING: SHA-256 FAILED for md3 source CSV';
  /* One pass only: without OUTPUT/STOP the step iterates again after the pipe
     is exhausted, resets sha256 to FAILED, prints a false WARNING and writes
     a second FAILED row to work._sha_md3. */
  output;
  stop;
  keep sha256;
run;

proc sql noprint;
  select sha256 into :_computed_sha trimmed from work._sha_md3;
quit;
%put NOTE: [20] Computed SHA-256 of md3 source CSV: &_computed_sha;

proc import datafile="&qc_path.\19_raw_files.csv"
    out=work.files19 dbms=csv replace;
  guessingrows=max;
run;

%macro assert_checksum;
  %local n_rows expected;
  %let n_rows = 0;
  %let expected = ;
  proc sql noprint;
    select count(*) into :n_rows trimmed
    from work.files19
    where upcase(strip(filename)) = upcase("&_md3_file.")
      and upcase(scan(full_path, -2, '\')) = 'MASTER';
  quit;
  %if &n_rows ne 1 %then %do;
    %fail_out(msg=PID-01 ABORT -- found &n_rows rows for md3 source in 19_raw_files.csv -- expected exactly 1);
  %end;
  proc sql noprint;
    select sha256 into :expected trimmed
    from work.files19
    where upcase(strip(filename)) = upcase("&_md3_file.")
      and upcase(scan(full_path, -2, '\')) = 'MASTER';
  quit;
  %put NOTE: [20] Expected SHA-256 from Phase 19 record: &expected;
  %if %upcase(&_computed_sha) = FAILED %then %do;
    %fail_out(msg=PID-01 ABORT -- certutil could not hash the md3 source CSV);
  %end;
  %if %upcase(&_computed_sha) ne %upcase(&expected) %then %do;
    %fail_out(msg=PID-01 ABORT -- md3 source SHA-256 mismatch -- computed &_computed_sha expected &expected -- source file may have changed since program 19 ran);
  %end;
  %put NOTE: [20] PID-01 checksum match confirmed;
%mend assert_checksum;
%assert_checksum;


/* ============================================================
   SECTION 3 -- PID-01 cont. (D-11): ENCRYPTED_MRN and
   PRECEDE_STUDY_ID types from qc/19_raw_variables_md3.csv
   ============================================================ */

proc import datafile="&qc_path.\19_raw_variables_md3.csv"
    out=work.inv_vars_md3 dbms=csv replace;
  guessingrows=max;
run;

%global _mrn_type _mrn_len _pid_type _precede_is_num;
%let _mrn_type = ;
%let _mrn_len  = 0;
%let _pid_type = ;

proc sql noprint;
  select strip(var_type), strip(put(var_length, best12.))
    into :_mrn_type trimmed, :_mrn_len trimmed
  from work.inv_vars_md3
  where upcase(strip(var_name)) = 'ENCRYPTED_MRN';

  select strip(var_type) into :_pid_type trimmed
  from work.inv_vars_md3
  where upcase(strip(var_name)) = 'PRECEDE_STUDY_ID';
quit;

%macro check_md3_types;
  %if %upcase(&_mrn_type) ne CHAR %then %do;
    %fail_out(msg=D-11 ABORT -- ENCRYPTED_MRN in the md3 source imported as type [&_mrn_type] not char -- resolve before building the crosswalk);
  %end;
  %if %length(&_pid_type) = 0 %then %do;
    %fail_out(msg=D-11 ABORT -- PRECEDE_STUDY_ID not found in 19_raw_variables_md3.csv);
  %end;
  %if %upcase(&_pid_type) = NUM %then %let _precede_is_num = 1;
  %else %let _precede_is_num = 0;
  %put NOTE: [20] D-11 ENCRYPTED_MRN type=&_mrn_type length=&_mrn_len;
  %put NOTE: [20] D-11 PRECEDE_STUDY_ID type=&_pid_type precede_is_num=&_precede_is_num;
%mend check_md3_types;
%check_md3_types;


/* ============================================================
   SECTION 4 -- PID-01 cont. (D-12): import the md3 CSV and assert
   max ENCRYPTED_MRN length <= 40. GUESSINGROWS=MAX scans every row
   and sets the column length to the longest value, so the import
   itself cannot truncate.
   ============================================================ */

proc import datafile="&raw_path.\master\&_md3_file."
    out=work.md3csv dbms=csv replace;
  guessingrows=max;
run;

%macro assert_md3_import;
  %local max_len n_rows n_dist;
  %if %sysfunc(exist(work.md3csv)) = 0 %then %do;
    %fail_out(msg=D-12 ABORT -- md3 source CSV did not import);
  %end;
  %let max_len = 0;
  proc sql noprint;
    select coalesce(max(lengthn(strip(ENCRYPTED_MRN))), 0) into :max_len trimmed
    from work.md3csv;
    select count(*), count(distinct PRECEDE_STUDY_ID)
      into :n_rows trimmed, :n_dist trimmed
    from work.md3csv;
  quit;
  %put NOTE: [20] D-12 max ENCRYPTED_MRN length in md3 source CSV: &max_len;
  %if &max_len > 40 %then %do;
    %fail_out(msg=D-12 ABORT -- source holds MRN of length &max_len -- the $40 merged column would silently truncate it);
  %end;
  /* A duplicated PRECEDE in the CSV would fan out the D-14 join */
  %if &n_rows ne &n_dist %then %do;
    %fail_out(msg=D-14 ABORT -- md3 source CSV has &n_rows rows but &n_dist distinct PRECEDE_STUDY_IDs);
  %end;
  %put NOTE: [20] D-12 truncation guard passed and CSV PRECEDE_STUDY_ID is unique;
  %let syscc = 0;
%mend assert_md3_import;
%assert_md3_import;


/* ============================================================
   SECTION 5 -- D-14 cross-check: join the CSV to g.master_data_merged
   on PRECEDE_STUDY_ID after applying md3 prep normalization.
   Merged PRECEDE_STUDY_ID must convert cleanly to a number -- this is
   also required by the SECTION 8 numeric ranking (D-01).
   ============================================================ */

%macro assert_merged_pid_numeric;
  %local n_fail;
  data _null_;
    set g.master_data_merged(keep=PRECEDE_STUDY_ID) end=_eof;
    retain _nf 0;
    if not missing(PRECEDE_STUDY_ID)
       and missing(input(substr(strip(PRECEDE_STUDY_ID), 8), ?? best32.)) then _nf + 1;
    if _eof then call symputx('n_fail', _nf, 'L');
  run;
  %if %length(&n_fail) = 0 %then %let n_fail = 0;
  %if &n_fail > 0 %then %do;
    %fail_out(msg=D-01 ABORT -- &n_fail PRECEDE_STUDY_ID values in g.master_data_merged cannot be parsed after stripping the Precede prefix -- cannot order or join numerically);
  %end;
  %put NOTE: [20] Merged PRECEDE_STUDY_ID numeric conversion passed after stripping Precede prefix;
%mend assert_merged_pid_numeric;
%assert_merged_pid_numeric;

%macro d14_crosscheck;
  %local n_mismatch n_csv_orphan n_mrg_orphan;

  proc sql noprint;
    create table work._crosscheck as
    select
      case when c.PRECEDE_STUDY_ID is not missing then 1 else 0 end as _in_csv,
      case when m.PRECEDE_STUDY_ID is not missing then 1 else 0 end as _in_mrg,
      case when missing(c.ENCRYPTED_MRN) or strip(upcase(c.ENCRYPTED_MRN)) = 'NULL'
           then '' else strip(c.ENCRYPTED_MRN) end as _mrn_csv length=40,
      case when missing(m.ENCRYPTED_MRN) or strip(upcase(m.ENCRYPTED_MRN)) = 'NULL'
           then '' else strip(m.ENCRYPTED_MRN) end as _mrn_mrg length=40
    from work.md3csv as c
    full join g.master_data_merged as m
    %if &_precede_is_num = 1 %then %do;
      on  c.PRECEDE_STUDY_ID is not missing
      and c.PRECEDE_STUDY_ID = input(substr(strip(m.PRECEDE_STUDY_ID), 8), best32.)
    %end;
    %else %do;
      on  strip(c.PRECEDE_STUDY_ID) ne ''
      and strip(c.PRECEDE_STUDY_ID) = strip(m.PRECEDE_STUDY_ID)
    %end;
    ;

    /* (a) matched rows: normalized MRN must be identical, blank vs value included */
    select count(*) into :n_mismatch trimmed
    from work._crosscheck
    where _in_csv = 1 and _in_mrg = 1 and _mrn_csv ne _mrn_mrg;

    /* (b) orphans: PRECEDE present on one side only */
    select count(*) into :n_csv_orphan trimmed
    from work._crosscheck where _in_csv = 1 and _in_mrg = 0;

    select count(*) into :n_mrg_orphan trimmed
    from work._crosscheck where _in_csv = 0 and _in_mrg = 1;
  quit;

  %put NOTE: [20] D-14 matched rows with differing MRN: &n_mismatch;
  %put NOTE: [20] D-14 PRECEDEs in CSV only: &n_csv_orphan -- in merged only: &n_mrg_orphan;

  %if &n_mismatch > 0 %then %do;
    %fail_out(msg=D-14 ABORT -- &n_mismatch matched PRECEDE_STUDY_IDs have a different ENCRYPTED_MRN in the CSV and the merged file);
  %end;
  %if &n_csv_orphan > 0 or &n_mrg_orphan > 0 %then %do;
    %fail_out(msg=D-14 ABORT -- PRECEDE sets differ -- &n_csv_orphan in CSV only and &n_mrg_orphan in merged only);
  %end;
  %put NOTE: [20] D-14 cross-check passed -- same PRECEDE set and same MRN on every row;
%mend d14_crosscheck;
%d14_crosscheck;


/* ============================================================
   SECTION 6 -- PID-02: source audit on g.master_data_merged
   ============================================================ */

%let _n_blank_mrn     = 0;
%let _n_null_mrn      = 0;
%let _n_incl_mrn      = 0;
%let _n_incl_precede  = 0;
%let _max_mrn_per_pid = 0;
%let _max_pid_per_mrn = 0;

proc sql noprint;
  select count(*) into :_n_blank_mrn trimmed
  from g.master_data_merged where missing(ENCRYPTED_MRN);

  select count(*) into :_n_null_mrn trimmed
  from g.master_data_merged
  where not missing(ENCRYPTED_MRN) and strip(upcase(ENCRYPTED_MRN)) = 'NULL';

  select count(distinct ENCRYPTED_MRN) into :_n_incl_mrn trimmed
  from g.master_data_merged
  where not missing(ENCRYPTED_MRN) and strip(upcase(ENCRYPTED_MRN)) ne 'NULL';

  select count(distinct PRECEDE_STUDY_ID) into :_n_incl_precede trimmed
  from g.master_data_merged
  where not missing(ENCRYPTED_MRN) and strip(upcase(ENCRYPTED_MRN)) ne 'NULL';

  select max(n_mrn) into :_max_mrn_per_pid trimmed
  from (select PRECEDE_STUDY_ID, count(distinct ENCRYPTED_MRN) as n_mrn
        from g.master_data_merged
        where not missing(ENCRYPTED_MRN) and strip(upcase(ENCRYPTED_MRN)) ne 'NULL'
        group by PRECEDE_STUDY_ID);

  select max(n_pid) into :_max_pid_per_mrn trimmed
  from (select ENCRYPTED_MRN, count(distinct PRECEDE_STUDY_ID) as n_pid
        from g.master_data_merged
        where not missing(ENCRYPTED_MRN) and strip(upcase(ENCRYPTED_MRN)) ne 'NULL'
        group by ENCRYPTED_MRN);
quit;

%put NOTE: [20] PID-02 blank MRN rows: &_n_blank_mrn;
%put NOTE: [20] PID-02 placeholder (NULL sentinel) MRN rows: &_n_null_mrn;
%put NOTE: [20] PID-02 distinct included MRNs: &_n_incl_mrn;
%put NOTE: [20] PID-02 distinct included PRECEDEs: &_n_incl_precede;
%put NOTE: [20] PID-02 max distinct MRNs per PRECEDE: &_max_mrn_per_pid;
%put NOTE: [20] PID-02 max distinct PRECEDEs per MRN: &_max_pid_per_mrn;


/* ============================================================
   SECTION 7 -- PID-03: every PRECEDE_STUDY_ID maps to exactly one MRN
   ============================================================ */

%macro assert_pid_cardinality;
  %local n_multi;
  %let n_multi = 0;
  proc sql noprint;
    select count(*) into :n_multi trimmed
    from (select PRECEDE_STUDY_ID
          from g.master_data_merged
          where not missing(ENCRYPTED_MRN) and strip(upcase(ENCRYPTED_MRN)) ne 'NULL'
          group by PRECEDE_STUDY_ID
          having count(distinct ENCRYPTED_MRN) > 1);
  quit;
  %put NOTE: [20] PID-03 PRECEDEs mapping to more than one MRN: &n_multi;
  %if &n_multi > 0 %then %do;
    %fail_out(msg=PID-03 ABORT -- &n_multi PRECEDE_STUDY_IDs map to more than one ENCRYPTED_MRN -- crosswalk cannot be safely built);
  %end;
  %put NOTE: [20] PID-03 cardinality assertion passed;
%mend assert_pid_cardinality;
%assert_pid_cardinality;


/* ============================================================
   SECTION 8 -- PID-04: build_or_append_xwalk (D-01, D-02, D-04)
   Four cases on (crosswalk exists, backup exists):
     no  / no  -> first run: build and write the first backup
     yes / yes -> re-run: compare to latest backup, append new MRNs,
                  re-compare, write a new backup only if rows were added
     no  / yes -> abort: restore from backup, never renumber
     yes / no  -> write the first backup with a WARNING, then re-run path
   ============================================================ */

/* Rank MRNs by their smallest PRECEDE_STUDY_ID (numeric), MRN as tie-breaker.
   Writes work.&out with ENCRYPTED_MRN and _min_pid_num. */
%macro rank_mrns(out=, exclude_existing=0);
  %local n_missing;
  proc sql noprint;
    create table work.&out as
    select ENCRYPTED_MRN,
           min(input(substr(strip(PRECEDE_STUDY_ID), 8), best32.)) as _min_pid_num
    from g.master_data_merged
    where not missing(ENCRYPTED_MRN)
      and strip(upcase(ENCRYPTED_MRN)) ne 'NULL'
    %if &exclude_existing = 1 %then %do;
      and ENCRYPTED_MRN not in (select ENCRYPTED_MRN from g.pecan_id_xwalk)
    %end;
    group by ENCRYPTED_MRN
    order by _min_pid_num, ENCRYPTED_MRN;

    select count(*) into :n_missing trimmed
    from work.&out where _min_pid_num is missing;
  quit;
  %if &n_missing > 0 %then %do;
    %fail_out(msg=D-01 ABORT -- &n_missing MRNs have no usable PRECEDE_STUDY_ID for ranking);
  %end;
%mend rank_mrns;

%macro build_or_append_xwalk;
  %local xwalk_exists n_backups latest_bak bak_stamp n_xwalk_only n_bak_only
         max_pid n_new n_bak_lost n_built;

  %if %sysfunc(fileexist(&xwalk_backup_path.)) = 0 %then %do;
    %fail_out(msg=D-04 ABORT -- xwalk_backup_path does not exist -- create the folder first: &xwalk_backup_path);
  %end;
  libname bak "&xwalk_backup_path.";

  %let xwalk_exists = %sysfunc(exist(g.pecan_id_xwalk));
  %let n_backups = 0;
  %let latest_bak = ;
  proc sql noprint;
    select count(*), max(memname)
      into :n_backups trimmed, :latest_bak trimmed
    from dictionary.tables
    where libname = 'BAK' and memname like 'PECAN_ID_XWALK_%';
  quit;
  %put NOTE: [20] xwalk_exists=&xwalk_exists n_backups=&n_backups latest_bak=&latest_bak;

  /* B8601DT15. gives e.g. 20260923T140500 -- valid in a name, sorts by time */
  %let bak_stamp = %sysfunc(datetime(), B8601DT15.);

  /* Crosswalk missing but a backup exists: never rebuild */
  %if &xwalk_exists = 0 and &n_backups > 0 %then %do;
    %fail_out(msg=D-04 ABORT -- g.pecan_id_xwalk is missing but &n_backups backups exist at &xwalk_backup_path -- restore the latest backup to g before re-running);
  %end;

  /* First run */
  %if &xwalk_exists = 0 and &n_backups = 0 %then %do;
    %put NOTE: [20] First run -- building g.pecan_id_xwalk from g.master_data_merged;
    %rank_mrns(out=_mrn_rank, exclude_existing=0);

    data g.pecan_id_xwalk;
      length ENCRYPTED_MRN $40 pecan_ID 8;
      set work._mrn_rank;
      pecan_ID = _N_;
      keep ENCRYPTED_MRN pecan_ID;
    run;

    data bak.pecan_id_xwalk_&bak_stamp.;
      set g.pecan_id_xwalk;
    run;

    proc sql noprint;
      select count(*) into :n_built trimmed from g.pecan_id_xwalk;
    quit;
    %put NOTE: [20] PID-04 initial build -- &n_built distinct MRNs -- first backup pecan_id_xwalk_&bak_stamp;
    %return;
  %end;

  /* Crosswalk present but no backup: write the first one, then continue */
  %if &xwalk_exists = 1 and &n_backups = 0 %then %do;
    %put WARNING: [20] D-04 no backup found -- writing first backup now;
    data bak.pecan_id_xwalk_&bak_stamp.;
      set g.pecan_id_xwalk;
    run;
    %let latest_bak = PECAN_ID_XWALK_&bak_stamp.;
    %put NOTE: [20] PID-04 first backup written: &latest_bak;
  %end;

  /* Re-run path */
  %put NOTE: [20] Re-run -- asserting xwalk equals latest backup &latest_bak before appending;
  proc sql noprint;
    select count(*) into :n_xwalk_only trimmed
    from g.pecan_id_xwalk as x
    where not exists (select 1 from bak.&latest_bak as b
                      where b.ENCRYPTED_MRN = x.ENCRYPTED_MRN and b.pecan_ID = x.pecan_ID);
    select count(*) into :n_bak_only trimmed
    from bak.&latest_bak as b
    where not exists (select 1 from g.pecan_id_xwalk as x
                      where x.ENCRYPTED_MRN = b.ENCRYPTED_MRN and x.pecan_ID = b.pecan_ID);
  quit;
  %put NOTE: [20] Pre-append diff -- xwalk_only=&n_xwalk_only bak_only=&n_bak_only;
  %if &n_xwalk_only > 0 or &n_bak_only > 0 %then %do;
    %fail_out(msg=D-02 ABORT -- g.pecan_id_xwalk differs from latest backup &latest_bak -- xwalk_only=&n_xwalk_only bak_only=&n_bak_only -- crosswalk may have been edited outside program 20);
  %end;

  proc sql noprint;
    select max(pecan_ID) into :max_pid trimmed from g.pecan_id_xwalk;
  quit;
  %rank_mrns(out=_new_mrns_rank, exclude_existing=1);
  proc sql noprint;
    select count(*) into :n_new trimmed from work._new_mrns_rank;
  quit;
  %put NOTE: [20] Current max pecan_ID &max_pid -- new MRNs to append: &n_new;

  %if &n_new = 0 %then %do;
    %put NOTE: [20] PID-04 no new MRNs -- crosswalk unchanged -- no new backup written;
    %return;
  %end;

  data work._new_rows;
    length ENCRYPTED_MRN $40 pecan_ID 8;
    set work._new_mrns_rank;
    pecan_ID = &max_pid + _N_;
    keep ENCRYPTED_MRN pecan_ID;
  run;
  proc append base=g.pecan_id_xwalk data=work._new_rows; run;
  %put NOTE: [20] PID-04 appended &n_new new MRN rows via PROC APPEND;

  proc sql noprint;
    select count(*) into :n_bak_lost trimmed
    from bak.&latest_bak as b
    where not exists (select 1 from g.pecan_id_xwalk as x
                      where x.ENCRYPTED_MRN = b.ENCRYPTED_MRN and x.pecan_ID = b.pecan_ID);
  quit;
  %if &n_bak_lost > 0 %then %do;
    %fail_out(msg=D-02 ABORT -- &n_bak_lost backup rows missing after PROC APPEND -- existing pecan_ID assignments may have been altered);
  %end;
  %put NOTE: [20] D-02 post-append backup integrity assertion passed;

  data bak.pecan_id_xwalk_&bak_stamp.;
    set g.pecan_id_xwalk;
  run;
  %put NOTE: [20] PID-04 new backup written: pecan_id_xwalk_&bak_stamp;
%mend build_or_append_xwalk;
%build_or_append_xwalk;

%let _n_xwalk_final = 0;
proc sql noprint;
  select count(*) into :_n_xwalk_final trimmed from g.pecan_id_xwalk;
quit;
%put NOTE: [20] PID-04 g.pecan_id_xwalk final row count: &_n_xwalk_final;


/* ============================================================
   SECTION 9 -- PID-07: linkage reach report (D-20 through D-26)
   One section per file + sheet + ENCRYPTED_MRN column, each written
   by the same macro call that computes its counts. No CALL EXECUTE:
   the loop is a %DO over row numbers, so every count exists before
   it is written.
   ============================================================ */

proc import datafile="&qc_path.\19_raw_key_columns.csv"
    out=work.inv_key_cols dbms=csv replace;
  guessingrows=max;
run;

/* r7/r8/r9 = the three 2022-era supplemental files from Phase 18 (PCM-D-16).
   Filenames follow the Phase 18 r1-r9 order; confirm against 18-CONTEXT.md. */
data work.r789;
  length r_label $4 r_filename $200;
  infile datalines dlm='|' truncover;
  input r_label $ r_filename $;
  datalines;
r7|2022_Education_20240124.csv
r8|2022_RES_20230927.csv
r9|All_YEARS_LAT_LONG_20231127.csv
;

%let _rpt = &qc_path.\20_linkage_reach.txt;

/* Char ENCRYPTED_MRN targets, one row each, with md3 and r7/r8/r9 flags */
proc sql noprint;
  create table work._enc_mrn_targets as
  select k.source_file length=500,
         k.sheet_name  length=200,
         k.var_name    length=32,
         scan(k.source_file, -1, '\') as filename length=200,
         lowcase(scan(k.source_file, -1, '.')) as ext length=10,
         case when upcase(scan(k.source_file, -1, '\')) = upcase("&_md3_file.")
               and upcase(scan(k.source_file, -2, '\')) = 'MASTER'
              then 1 else 0 end as is_md3,
         r.r_label
  from work.inv_key_cols as k
  left join work.r789 as r
    on upcase(scan(k.source_file, -1, '\')) = upcase(r.r_filename)
  where upcase(strip(k.key_column_type)) = 'ENCRYPTED_MRN'
    and upcase(strip(k.var_type)) ne 'NUM'
  order by is_md3 desc, filename, sheet_name, var_name;
quit;

/* Report header */
data _null_;
  file "&_rpt." lrecl=250;
  put "==========================================================================";
  put "Phase 20 -- PID-07 Linkage Reach Report";
  put "Generated: %sysfunc(datetime(), datetime20.)";
  put "Crosswalk: g.pecan_id_xwalk (distinct MRNs: &_n_xwalk_final)";
  put "==========================================================================";
  put " ";
  put "MRN normalization applied before matching: strip() whitespace; the";
  put "literal string NULL (any case) is treated as blank; blanks are not counted.";
  put "YES on a PCM-D-16 line means at least one distinct MRN matched; no threshold.";
  put " ";
run;

/* Excluded files: UNENC_MRN only */
%macro write_exclusions;
  %local n_ex n_num;
  proc sql noprint;
    create table work._unenc_only as
    select source_file, scan(source_file, -1, '\') as filename length=200
    from work.inv_key_cols
    group by source_file
    having sum(upcase(strip(key_column_type)) = 'ENCRYPTED_MRN') = 0
       and sum(upcase(strip(key_column_type)) = 'UNENC_MRN') > 0;
    select count(*) into :n_ex trimmed from work._unenc_only;

    create table work._numeric_mrn as
    select distinct source_file, scan(source_file, -1, '\') as filename length=200,
           sheet_name, var_name
    from work.inv_key_cols
    where upcase(strip(key_column_type)) = 'ENCRYPTED_MRN'
      and upcase(strip(var_type)) = 'NUM';
    select count(*) into :n_num trimmed from work._numeric_mrn;
  quit;

  %if &n_ex > 0 %then %do;
    data _null_;
      set work._unenc_only;
      file "&_rpt." mod lrecl=250;
      if _n_ = 1 then do;
        put "--------------------------------------------------------------------------";
        put "EXCLUDED FILES (UNENC_MRN only -- no ENCRYPTED_MRN column; not compared)";
        put "--------------------------------------------------------------------------";
      end;
      put "  " filename;
    run;
  %end;

  %if &n_num > 0 %then %do;
    data _null_;
      set work._numeric_mrn;
      file "&_rpt." mod lrecl=250;
      if _n_ = 1 then do;
        put "--------------------------------------------------------------------------";
        put "TYPE MISMATCH -- NOT COMPARED (ENCRYPTED_MRN imported as numeric, D-26)";
        put "A numeric-to-char conversion can lose digits or leading zeros.";
        put "--------------------------------------------------------------------------";
      end;
      put "  " filename " sheet=[" sheet_name "] col=" var_name;
    run;
  %end;

  data _null_;
    file "&_rpt." mod lrecl=250;
    put " ";
  run;
%mend write_exclusions;
%write_exclusions;

/* One target: import, count, write its whole section */
%macro reach_one(row=);
  %local col ext is_md3 r_label n_total n_match n_dist n_dmatch ok;
  %global _rsheet;

  /* Scalar attributes into macro vars; the path itself stays in data */
  data _null_;
    set work._enc_mrn_targets(firstobs=&row obs=&row);
    call symputx('col',     var_name, 'L');
    call symputx('ext',     ext,      'L');
    call symputx('is_md3',  is_md3,   'L');
    call symputx('r_label', r_label,  'L');
    call symputx('_rsheet', sheet_name, 'G');
  run;

  /* Section header */
  data _null_;
    set work._enc_mrn_targets(firstobs=&row obs=&row);
    file "&_rpt." mod lrecl=250;
    put "--------------------------------------------------------------------------";
    if is_md3 = 1 then
      put "SOURCE: " filename " -- reference (crosswalk source; 100% by construction)";
    else if not missing(r_label) then
      put "SOURCE: " filename " (" r_label ")  sheet=[" sheet_name "]  col=" var_name;
    else
      put "SOURCE: " filename "  sheet=[" sheet_name "]  col=" var_name;
    put "--------------------------------------------------------------------------";
  run;

  proc datasets lib=work nolist nowarn; delete _reach_tmp _reach_norm; quit;
  %let ok = 1;

  %if &ext = csv %then %do;
    data _null_;
      set work._enc_mrn_targets(firstobs=&row obs=&row);
      _rc = filename('_rch', source_file);
    run;
    proc import datafile=_rch out=work._reach_tmp dbms=csv replace;
      guessingrows=max;
    run;
    %if &syserr > 4 %then %let ok = 0;
    filename _rch clear;
  %end;
  %else %if &ext = xlsx %then %do;
    /* Targeted read: one column from one sheet through the XLSX libref */
    data _null_;
      set work._enc_mrn_targets(firstobs=&row obs=&row);
      _rc = libname('_rchx', source_file, 'xlsx');
    run;
    %if %sysfunc(libref(_rchx)) ne 0 %then %let ok = 0;
    %else %do;
      /* Same sheet-name handling as program 19 (unquoted when a valid name) */
      %if %sysfunc(prxmatch(%str(/^[A-Za-z_]\w{0,31}$/), %superq(_rsheet))) %then %do;
        data work._reach_tmp;
          set _rchx.&_rsheet.(keep=&col);
        run;
      %end;
      %else %do;
        /* %superq leaves macro-quoting bytes around the value; inside a
           quoted name literal they reach the XLSX engine verbatim and no
           sheet matches. %unquote strips them first. */
        data work._reach_tmp;
          set _rchx."%unquote(%superq(_rsheet))"n(keep=&col);
        run;
      %end;
      %if &syserr > 4 %then %let ok = 0;
      libname _rchx clear;
    %end;
  %end;
  %else %let ok = 0;

  %if &ok = 1 and %sysfunc(exist(work._reach_tmp)) = 0 %then %let ok = 0;
  %let syscc = 0;

  %if &ok = 0 %then %do;
    data _null_;
      file "&_rpt." mod lrecl=250;
      put "  IMPORT FAILED or unsupported file type [&ext] -- not compared";
      %if %length(&r_label) > 0 %then %do;
        put "  Links on MRN (PCM-D-16 test): NOT TESTED (file could not be read)";
      %end;
      put " ";
    run;
    %put WARNING: [20] PID-07 row &row could not be read -- reported as not compared;
    %return;
  %end;

  proc sql noprint;
    create table work._reach_norm as
    select strip(&col.) as _mrn_norm length=64
    from work._reach_tmp
    where not missing(&col.) and strip(upcase(&col.)) ne 'NULL';

    select count(*) into :n_total trimmed from work._reach_norm;
    select count(*) into :n_match trimmed
    from work._reach_norm
    where _mrn_norm in (select ENCRYPTED_MRN from g.pecan_id_xwalk);
    select count(distinct _mrn_norm) into :n_dist trimmed from work._reach_norm;
    select count(distinct _mrn_norm) into :n_dmatch trimmed
    from work._reach_norm
    where _mrn_norm in (select ENCRYPTED_MRN from g.pecan_id_xwalk);
  quit;

  data _null_;
    file "&_rpt." mod lrecl=250;
    n_total = &n_total; n_match = &n_match; n_dist = &n_dist; n_dmatch = &n_dmatch;
    if n_total > 0 then pct_row  = n_match  / n_total * 100;
    if n_dist  > 0 then pct_dist = n_dmatch / n_dist  * 100;
    put "  Row match:          " n_match 8. " / " n_total 8. "  (" pct_row 6.1 " %)";
    put "  Distinct MRN match: " n_dmatch 8. " / " n_dist 8. "  (" pct_dist 6.1 " %)";
    %if %length(&r_label) > 0 %then %do;
      if n_dmatch > 0 then yn = 'YES'; else yn = 'NO ';
      put "  Links on MRN (PCM-D-16 test): " yn "  distinct-MRN rate: " pct_dist 6.1 " %";
    %end;
    put " ";
  run;

  %put NOTE: [20] PID-07 row &row -- rows &n_total matched &n_match -- distinct MRNs &n_dist matched &n_dmatch;
%mend reach_one;

%macro reach_all;
  %local n_targets row n_untested;
  %let n_targets = 0;
  proc sql noprint;
    select count(*) into :n_targets trimmed from work._enc_mrn_targets;
  quit;
  %put NOTE: [20] PID-07 char ENCRYPTED_MRN targets to process: &n_targets;

  %do row = 1 %to &n_targets;
    %reach_one(row=&row);
  %end;

  /* r7/r8/r9 files with no char ENCRYPTED_MRN column still get an explicit line */
  proc sql noprint;
    create table work._r789_untested as
    select r.r_label, r.r_filename
    from work.r789 as r
    where upcase(r.r_filename) not in
          (select upcase(filename) from work._enc_mrn_targets)
    order by r.r_label;
    select count(*) into :n_untested trimmed from work._r789_untested;
  quit;
  %if &n_untested > 0 %then %do;
    data _null_;
      set work._r789_untested;
      file "&_rpt." mod lrecl=250;
      if _n_ = 1 then do;
        put "--------------------------------------------------------------------------";
        put "r7/r8/r9 FILES WITHOUT A CHAR ENCRYPTED_MRN COLUMN";
        put "--------------------------------------------------------------------------";
      end;
      put "  " r_filename " (" r_label ")";
      put "  Links on MRN (PCM-D-16 test): NOT TESTED (no char ENCRYPTED_MRN column -- see exclusions or type-mismatch blocks above)";
    run;
    data _null_;
      file "&_rpt." mod lrecl=250;
      put " ";
    run;
  %end;
%mend reach_all;
%reach_all;

data _null_;
  file "&_rpt." mod lrecl=250;
  put "==========================================================================";
  put "END OF PID-07 LINKAGE REACH REPORT";
  put "==========================================================================";
run;
%put NOTE: [20] PID-07 linkage reach report written to qc/20_linkage_reach.txt;


/* ============================================================
   SECTION 10 -- PID-08: DECISIONS.md entries are a text edit
   (Plan 20-01 Task 4), not a SAS write.
   ============================================================ */

%put NOTE: [20] PID-08 -- PCM-D-17 and PCM-D-18 are recorded in docs/DECISIONS.md;
%put NOTE: [20] ==== Phase 20 program 20 complete ====;
%restore_log;
