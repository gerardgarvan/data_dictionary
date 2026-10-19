/*==========================================================================
  Program : 02_source_guard.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 2 Plan 01 -- Source guard and file-level audit foundation.
            Computes SHA-256 checksums for all 20 shared-folder source files,
            seeds or guards a hash baseline at docs/source_guard_baseline.csv,
            collects per-file metadata (size, modified date), performs an
            older-copy hash comparison, and assembles pdd.source_inventory
            (one row per source file) as the metadata backbone for Plan 02.

  Reads   : &raw_master (read-only -- 20 source files)
            &raw_master_old  (older-copy root 1: Gerard\raw\master)
            &raw_master_old2 (older-copy root 2: Gerard\raw)
            C:\data_dictionary\docs\source_guard_baseline.csv  (seeded on first run)

  Writes  : C:\data_dictionary\docs\source_guard_baseline.csv (first run only)
            pdd.source_inventory  (20 rows)
            &logs_path.\02_source_guard.log  (standalone run only)

  Sections covered by this plan (02-01):
    0  Header, %include, %pdd_lib, older-copy roots
    1  Utility macros
    2  Preconditions
    3  Build work.file_list (20-row DATALINES)
    4  File metadata (FOPEN/FINFO)
    5  SHA-256 loop (certutil PIPE FILEVAR=)
    7  Older-copy hash comparison
   11  Hash baseline guard (seed-or-compare)
   12  Assemble pdd.source_inventory

  Sections added by later plans:
    6  Import loop (Plan 02)
    8  Candidate key detection (Plan 02)
    9  Grain test (Plan 02)
   10  ID overlap (Plan 02)
   13  Header matrix (Plan 02)
   14  ODS Excel outputs (Plan 02)
   15  Output verification (Plan 03)
   16  %restore_log (Plan 03 -- last task only)

  PCM compliance:
    - No open-code %IF outside a %macro block
    - %abort cancel only inside %fail_out
    - No apostrophes or embedded semicolons in %put text
    - No PROC SQL UPDATE
    - No in-place dataset rewrite (data X; set X;)
    - dictionary.columns.type: 'char' / 'num' (not 1/2)

  Author  : GSD Phase 02 Plan 01
==========================================================================*/


/* ============================================================
   SECTION 0 -- Header, %include, %pdd_lib, older-copy roots
   ============================================================ */

/* config MUST be the first executable statement (hardcoded path;
   &sas_path is not yet defined until config runs) */
%include "C:\data_dictionary\sas\00_config.sas";

/* Assign the pdd output library */
%pdd_lib;

/* Older-copy roots (local to this program only -- NOT added to 00_config.sas
   per project constraint; both searched non-recursively in SECTION 7) */
%let raw_master_old  = P:\PeCAN Master Data\Gerard\raw\master;
%let raw_master_old2 = P:\PeCAN Master Data\Gerard\raw;

%put NOTE: [02_source_guard] raw_master_old  = &raw_master_old;
%put NOTE: [02_source_guard] raw_master_old2 = &raw_master_old2;


/* ============================================================
   SECTION 1 -- Utility macros
   All conditional logic inside named macros (no open-code %IF).
   ============================================================ */

/* Route the log to a per-program file when running standalone */
%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\02_source_guard.log" new; run;
  %end;
%mend route_log;

/* Restore the log to the default destination */
%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* Abort with a loud ERROR message. %abort cancel is ONLY called here. */
%macro fail_out(msg=);
  %put ERROR: [02_source_guard] &msg;
  %abort cancel;
%mend fail_out;

/* Assert that a directory path exists; abort if not */
%macro check_dir(path=, label=);
  %if %sysfunc(fileexist(&path)) = 0 %then %do;
    %fail_out(msg=&label directory not found: &path);
  %end;
%mend check_dir;

/* Begin log redirect immediately after macro definitions */
%route_log;

%put NOTE: [02_source_guard] === Phase 2 Plan 01 starting ===;
%put NOTE: [02_source_guard] raw_master  = &raw_master;
%put NOTE: [02_source_guard] out_root    = &out_root;
%put NOTE: [02_source_guard] qc_path     = &qc_path;
%put NOTE: [02_source_guard] logs_path   = &logs_path;
%put NOTE: [02_source_guard] in_pipeline = &in_pipeline;


/* ============================================================
   SECTION 2 -- Preconditions
   Verify required directories exist; create docs dir if absent.
   ============================================================ */

/* Ensure C:\data_dictionary\docs exists (git-tracked docs folder) */
options dlcreatedir;
libname _doc "C:\data_dictionary\docs";
options nodlcreatedir;
libname _doc clear;

%check_dir(path=&raw_master,  label=shared source);
%check_dir(path=&qc_path,     label=qc);
%check_dir(path=&logs_path,   label=logs);

%put NOTE: [02_source_guard] Preconditions passed;


/* ============================================================
   SECTION 3 -- Build work.file_list (20-row inline DATALINES)
   Columns: s_code, filename, ftype, full_path, file_id
   Filenames match PROJECT.md source table byte-for-byte.
   ============================================================ */
data work.file_list;
  length s_code $4 filename $200 ftype $5 full_path $500;
  infile datalines dsd dlm='|' truncover;
  input s_code $ filename $ ftype $;
  full_path = cats("&raw_master.\", filename);
  file_id + 1;
  datalines;
s01|2018-2022_PACU_STAY_20260813.csv|csv
s02|2018_2019_2020_Induction_Emergent20231121.csv|csv
s03|2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv|csv
s04|2018_2019_ENCOUNTER_Crypto_Data_20260814.csv|csv
s05|2018_2019_MRN_Crypto_Data20260814.csv|csv
s06|2018_2019_Precede_Database.xlsx|xlsx
s07|2018_2019_X_MASTER_DATASET_20200801.csv|csv
s08|2018_2022_COLONOSCOPY_20240118.xlsx|xlsx
s09|2018_2022_X_MASTER_DATASET_20240402.csv|csv
s10|2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv|csv
s11|2020_Precede_Database_Edu.xlsx|xlsx
s12|2020_X_MASTER_DATASET_20210519.csv|csv
s13|2021_Education_20240124.csv|csv
s14|2021_Frailty_20240123.csv|csv
s15|2021_X_MASTER_DATASET_20230512.csv|csv
s16|2022_Education_20240124.csv|csv
s17|2022_MASTER_DATASET_20231024.csv|csv
s18|2022_RES_20230927.csv|csv
s19|ALL_AIM2_MASTER_DATASET_20210917.xlsx|xlsx
s20|All_YEARS_LAT_LONG_20231127.csv|csv
;

%put NOTE: [02_source_guard] work.file_list built;


/* ============================================================
   SECTION 4 -- File metadata loop (FOPEN/FINFO)
   Populate file_size (numeric) and mod_date ($30 raw string).
   Per RESEARCH Pitfall 7: do NOT parse mod_date to a SAS date.
   ============================================================ */
data work.files_meta;
  set work.file_list;
  length file_size 8 mod_date $30;
  _rc  = filename('_fr_', full_path);
  _fid = fopen('_fr_');
  if _fid > 0 then do;
    file_size = input(finfo(_fid, 'File Size (bytes)'), best32.);
    mod_date  = finfo(_fid, 'Last Modified');
    _rc       = fclose(_fid);
  end;
  else do;
    file_size = .;
    mod_date  = 'UNKNOWN';
    put 'WARNING: [02_source_guard] Could not open file for metadata: ' full_path=;
  end;
  _rc = filename('_fr_');   /* clear the fileref */
  drop _rc _fid;
run;

%put NOTE: [02_source_guard] work.files_meta built (file_size and mod_date);


/* ============================================================
   SECTION 5 -- SHA-256 loop (certutil PIPE FILEVAR=)
   One pipe invocation per file; hash line identified as the
   unique 64-hex-character line in certutil output.
   ============================================================ */
data work.sha_results;
  set work.file_list(keep=file_id s_code filename full_path);
  length _cmd $1000 line $400 compressed $400 sha256 $64;
  _cmd   = 'certutil -hashfile "' || strip(full_path) || '" SHA256';
  sha256 = 'FAILED';
  infile ckpipe pipe filevar=_cmd end=_done truncover lrecl=400;
  do while (not _done);
    input line $400.;
    compressed = compress(line, ' ');
    if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
      sha256 = lowcase(compressed);
  end;
  if sha256 = 'FAILED' then
    put 'WARNING: [02_source_guard] SHA-256 FAILED for ' full_path=;
  keep file_id s_code filename sha256;
run;

%put NOTE: [02_source_guard] work.sha_results built;

/* Assert no FAILED hashes among the 20 required files */
%macro assert_hashes_ok;
  %local n_failed;
  %let n_failed = 0;
  proc sql noprint;
    select count(*) into :n_failed trimmed
    from work.sha_results
    where sha256 = 'FAILED';
  quit;
  %if &n_failed > 0 %then %do;
    %fail_out(msg=SHA-256 FAILED for &n_failed files -- check that source files are accessible and not locked);
  %end;
  %put NOTE: [02_source_guard] assert_hashes_ok passed -- all 20 SHA-256 values computed;
%mend assert_hashes_ok;
%assert_hashes_ok;


/* ============================================================
   SECTION 7 -- Older-copy hash comparison
   Search both older-copy roots, primary (raw\master) first,
   then secondary (raw). Both searches are non-recursive
   (filename-only join against each folder root).
   ============================================================ */
data work.sha_old;
  set work.file_list(keep=file_id filename);
  length _oldpath $500 _cmd $1000 line $400 compressed $400
         sha256_old $64 old_copy_folder $10;
  sha256_old     = 'NO_OLD_COPY';
  old_copy_folder = '';

  /* ---- Primary root: raw\master ---- */
  _oldpath = cats("&raw_master_old.\", filename);
  if fileexist(_oldpath) then do;
    _cmd = 'certutil -hashfile "' || strip(_oldpath) || '" SHA256';
    sha256_old = 'FAILED';
    infile ckpipe2 pipe filevar=_cmd end=_done2 truncover lrecl=400;
    do while (not _done2);
      input line $400.;
      compressed = compress(line, ' ');
      if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
        sha256_old = lowcase(compressed);
    end;
    old_copy_folder = 'master';
    if sha256_old = 'FAILED' then
      put 'WARNING: [02_source_guard] SHA-256 FAILED for older copy (raw\master): ' filename=;
  end;
  /* ---- Secondary root: raw (only if not found in primary) ---- */
  else do;
    _oldpath = cats("&raw_master_old2.\", filename);
    if fileexist(_oldpath) then do;
      _cmd = 'certutil -hashfile "' || strip(_oldpath) || '" SHA256';
      sha256_old = 'FAILED';
      infile ckpipe3 pipe filevar=_cmd end=_done3 truncover lrecl=400;
      do while (not _done3);
        input line $400.;
        compressed = compress(line, ' ');
        if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
          sha256_old = lowcase(compressed);
      end;
      old_copy_folder = 'raw';
      if sha256_old = 'FAILED' then
        put 'WARNING: [02_source_guard] SHA-256 FAILED for older copy (raw): ' filename=;
    end;
    /* else sha256_old stays 'NO_OLD_COPY', old_copy_folder stays '' */
  end;
  keep file_id sha256_old old_copy_folder;
run;

%put NOTE: [02_source_guard] work.sha_old built (older-copy hash comparison complete);


/* ============================================================
   SECTION 11 -- Hash baseline guard (seed-or-compare two-branch)
   Baseline file: C:\data_dictionary\docs\source_guard_baseline.csv
   First run (no baseline rows): write the baseline, log a NOTE.
   Subsequent runs: read baseline, compare; abort on any drift.
   ALL branching is inside the macro (no open-code %IF).
   ============================================================ */
%macro run_hash_guard;
  %local n_base_rows n_drift _baseline_path;
  %let n_base_rows   = 0;
  %let n_drift       = 0;
  %let _baseline_path = C:\data_dictionary\docs\source_guard_baseline.csv;

  /* ---- Count existing data rows (skip header line firstobs=2) ---- */
  %if %sysfunc(fileexist(&_baseline_path)) %then %do;
    data _null_;
      retain _cnt 0;
      infile "&_baseline_path" dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
      input;
      _cnt + 1;
      if _eof then call symputx('n_base_rows', _cnt, 'L');
    run;
  %end;

  /* ---- Branch 1: FIRST RUN -- seed the baseline ---- */
  %if &n_base_rows = 0 %then %do;
    /* Write header */
    data _null_;
      file "&_baseline_path" lrecl=1000;
      put 's_code,filename,sha256';
    run;
    /* Write 20 data rows (append with MOD) */
    data _null_;
      file "&_baseline_path" dsd mod lrecl=1000;
      set work.sha_results(keep=s_code filename sha256);
      put s_code filename sha256;
    run;
    %put NOTE: [02_source_guard] baseline seeded -- commit docs/source_guard_baseline.csv;
  %end;

  /* ---- Branch 2: SUBSEQUENT RUN -- compare against baseline ---- */
  %else %do;
    data work._baseline_read;
      length s_code $4 filename $200 sha256_base $64;
      infile "&_baseline_path" dsd dlm=',' firstobs=2 truncover lrecl=500;
      input s_code $ filename $ sha256_base $;
    run;

    proc sql noprint;
      select count(*) into :n_drift trimmed
      from work._baseline_read b
      inner join work.sha_results r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.sha256_base)) ne lowcase(strip(r.sha256));
    quit;

    %if &n_drift > 0 %then %do;
      %fail_out(msg=SOURCE GUARD FAILED -- &n_drift files changed since baseline. Delete docs/source_guard_baseline.csv to reseed.);
    %end;
    %put NOTE: [02_source_guard] PASS -- all 20 SHA-256 values match baseline;

    /* Clean up temporary baseline read dataset */
    proc datasets lib=work nolist nowarn;
      delete _baseline_read;
    quit;
  %end;
%mend run_hash_guard;
%run_hash_guard;


/* ============================================================
   SECTION 12 -- Assemble pdd.source_inventory (one row per file)
   Merge: work.file_list + work.files_meta + work.sha_results
          + work.sha_old on file_id.
   Derive old_copy_status via DATA-step if/else (no PROC SQL UPDATE).
   ============================================================ */

/* Sort all component datasets by file_id for DATA step merge */
proc sort data=work.file_list     out=work._fl_s;  by file_id; run;
proc sort data=work.files_meta    out=work._fm_s;  by file_id; run;
proc sort data=work.sha_results   out=work._sha_s; by file_id; run;
proc sort data=work.sha_old       out=work._old_s; by file_id; run;

data pdd.source_inventory;
  merge work._fl_s (in=_in_fl)
        work._fm_s (keep=file_id file_size mod_date)
        work._sha_s (keep=file_id sha256)
        work._old_s (keep=file_id sha256_old old_copy_folder);
  by file_id;
  if _in_fl;

  /* Derive old_copy_status from sha256 and sha256_old (DATA-step only) */
  length old_copy_status $20;
  if sha256_old = 'NO_OLD_COPY' then
    old_copy_status = 'no_older_copy';
  else if sha256_old = sha256 then
    old_copy_status = 'identical';
  else
    old_copy_status = 'different';

  label
    file_id         = 'Sequential file identifier (1-20)'
    s_code          = 'Source code (s01-s20)'
    filename        = 'Source file name'
    ftype           = 'File type (csv or xlsx)'
    full_path       = 'Full path in shared source folder'
    file_size       = 'File size in bytes (from FINFO)'
    mod_date        = 'Last modified date string (raw, locale-dependent)'
    sha256          = 'SHA-256 checksum of source file (certutil)'
    sha256_old      = 'SHA-256 of older copy, or NO_OLD_COPY'
    old_copy_folder = 'Which older-copy root matched (master / raw / blank)'
    old_copy_status = 'identical / different / no_older_copy';
run;

/* Clean up temporary sorted datasets */
proc datasets lib=work nolist nowarn;
  delete _fl_s _fm_s _sha_s _old_s;
quit;

%put NOTE: [02_source_guard] pdd.source_inventory written;

/* Assert exactly 20 rows */
%macro assert_inventory_rows;
  %local n;
  %let n = 0;
  proc sql noprint;
    select count(*) into :n trimmed
    from pdd.source_inventory;
  quit;
  %if &n ne 20 %then %do;
    %fail_out(msg=source_inventory expected 20 rows, got &n);
  %end;
  %put NOTE: [02_source_guard] assert_inventory_rows passed -- 20 rows confirmed;
%mend assert_inventory_rows;
%assert_inventory_rows;


/* ============================================================
   NOTE: Sections 6, 8, 9, 10, 13, 14, 15 are appended by Plan 02.
         Section 16 (%restore_log) is added by Plan 03 final task.
   ============================================================ */
%put NOTE: [02_source_guard] === Plan 01 sections complete ===;
