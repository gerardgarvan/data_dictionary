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
   NOTE: Sections 13, 14, 15 are appended by Plan 02 (ODS/verify).
         Section 16 (%restore_log) is added by Plan 03 final task.
   ============================================================ */
%put NOTE: [02_source_guard] === Plan 01 sections complete ===;


/* ============================================================
   SECTION 6 -- Import loop: all 20 files, header inventory,
                enriched counts.
   CSV via PROC IMPORT (options nosyntaxcheck noerrorabend MUST
   precede each call); XLSX via XLSX engine (not PROC IMPORT).
   All conditional logic inside named macros (no open-code %IF).
   ============================================================ */

/* Evaluate the step that just ran.  Must be called immediately
   after the import/read step; reads &syserr directly.
   Sets fstatus, freason; resets %let syscc=0.               */
%macro eval_import(target=);
  %if &syserr le 4 and %sysfunc(exist(&target)) %then %do;
    %let fstatus = profiled;
    %if &syserr > 0 %then %let freason = %superq(syswarningtext);
  %end;
  %else %do;
    %let fstatus = read-failed;
    %let freason = import error syserr=&syserr;
  %end;
  %let syscc = 0;
%mend eval_import;

/* Accumulator: one row per file x sheet x column */
data work.hdr_all;
  length s_code $4 sheet_name $200 col_name $32 col_type $4
         col_label $256 col_len 8;
  stop;
run;

/* Accumulator: one row per file x sheet (counts + status) */
data work.counts_all;
  length s_code $4 sheet_name $200 row_count 8 col_count 8
         sheet_list $2000 original_header $32767
         import_status $30 import_reason $500
         nonblank_row_count 8;
  stop;
run;

/* Sheet map: s_code + sheet_name -> work dataset name for XLSX sheets */
data work.sheet_map;
  length s_code $4 sheet_name $200 sheet_ds $40;
  stop;
run;

%macro import_all_files;
  %local n_files i j _scode _full _ftype _dsname
         fstatus freason nsheets _rawhdrs _s09rows
         _dups _nb;

  %let n_files = 20;

  %do i = 1 %to &n_files;

    /* ---- Read this file row into macro vars ---- */
    data _null_;
      set work.file_list(where=(file_id = &i));
      call symputx('_scode',   s_code,   'G');
      call symputx('_full',    full_path,'G');
      call symputx('_ftype',   ftype,    'G');
    run;
    %let _dsname = src_&_scode;
    %let fstatus = ;
    %let freason = ;
    %let _rawhdrs = ;

    %put NOTE: [02_source_guard] === importing file_id=&i s_code=&_scode ===;

    /* ============ CSV branch ============ */
    %if &_ftype = csv %then %do;

      options nosyntaxcheck noerrorabend;
      proc import datafile="&_full"
          out=work.&_dsname dbms=csv replace;
        guessingrows=max;
      run;
      %eval_import(target=work.&_dsname);

      /* Capture raw first-line header (Pitfall 6 check) */
      data _null_;
        infile "&_full" obs=1 dsd dlm=',' truncover
               lrecl=32767 encoding='utf-8';
        input;
        _line = _infile_;
        call symputx('_rawhdrs', _line, 'G');
        stop;
      run;

      /* Check original header for duplicate PRECEDE Study ID token */
      %macro _check_dup_hdr;
        %local _cnt;
        %let _cnt = 0;
        data _null_;
          _line = "&_rawhdrs";
          /* count occurrences of the exact token PRECEDE Study ID */
          _cnt = 0;
          _pos = 1;
          do while (_pos le length(_line));
            _pos2 = index(substr(_line, _pos), 'PRECEDE Study ID');
            if _pos2 > 0 then do;
              _cnt + 1;
              _pos = _pos + _pos2 + 15;
            end;
            else _pos = length(_line) + 1;
          end;
          call symputx('_cnt', _cnt, 'G');
        run;
        %if &_cnt > 1 %then %do;
          %put WARNING: [02_source_guard] duplicate original header PRECEDE Study ID in &_scode;
        %end;
      %mend _check_dup_hdr;
      %_check_dup_hdr;

      /* Accumulate header rows from dictionary.columns */
      proc sql noprint;
        insert into work.hdr_all
          (s_code, sheet_name, col_name, col_type, col_label, col_len)
        select "&_scode", '', name, type, label, length
        from dictionary.columns
        where libname='WORK' and memname=upcase("&_dsname");
      quit;

      /* Accumulate row/col counts from dictionary.tables */
      proc sql noprint;
        insert into work.counts_all
          (s_code, sheet_name, row_count, col_count, original_header,
           import_status, import_reason)
        select "&_scode", '', nobs, nvar, "&_rawhdrs",
               "&fstatus", "&freason"
        from dictionary.tables
        where libname='WORK' and memname=upcase("&_dsname");
      quit;

      /* s15 / s17 check for STUDYID trailing digit (Pitfall 6 col_name) */
      %if &_scode = s15 or &_scode = s17 %then %do;
        %macro _check_studyid_digit;
          %local _nd;
          %let _nd = 0;
          proc sql noprint;
            select count(*) into :_nd trimmed
            from dictionary.columns
            where libname='WORK' and memname=upcase("&_dsname")
              and prxmatch('/STUDYID\d+/i', strip(name)) > 0;
          quit;
          %if &_nd > 0 %then %do;
            %put WARNING: [02_source_guard] duplicate PRECEDE_STUDY_ID header in &_scode;
          %end;
        %mend _check_studyid_digit;
        %_check_studyid_digit;
      %end;

      /* s09 row count check */
      %if &_scode = s09 %then %do;
        %macro _check_s09rows;
          %let _s09rows = 0;
          proc sql noprint;
            select nobs into :_s09rows trimmed
            from dictionary.tables
            where libname='WORK' and memname='SRC_S09';
          quit;
          %put NOTE: [02_source_guard] s09 row count = &_s09rows. (expect ~41150);
          %if %eval(&_s09rows < 41000 or &_s09rows > 42000) %then %do;
            %put WARNING: [02_source_guard] s09 row count = &_s09rows. -- outside expected 41000-42000 range;
          %end;
        %mend _check_s09rows;
        %_check_s09rows;
      %end;

    %end;  /* end CSV branch */

    /* ============ XLSX branch ============ */
    %else %if &_ftype = xlsx %then %do;

      data _null_;
        _rc = libname('_xlw', "&_full", 'xlsx');
        call symputx('_xlrc', _rc, 'G');
      run;

      %if %sysfunc(libref(_xlw)) ne 0 %then %do;
        %let fstatus = read-failed;
        %let freason = xlsx libname could not be assigned;
        %let syscc = 0;

        proc sql noprint;
          insert into work.counts_all
            (s_code, sheet_name, row_count, col_count,
             import_status, import_reason)
          values ("&_scode", '', ., ., "&fstatus", "&freason");
        quit;

      %end;
      %else %do;

        /* Get sheet list */
        %let nsheets = 0;
        proc sql noprint;
          create table work._sheetlist as
          select memname as sheet_name length=200
          from dictionary.members
          where libname='_XLW' and memtype='DATA';
          select count(*) into :nsheets trimmed from work._sheetlist;
        quit;

        %if &nsheets = 0 %then %do;
          %let fstatus = read-failed;
          %let freason = xlsx opened but no sheets found;
          proc sql noprint;
            insert into work.counts_all
              (s_code, sheet_name, row_count, col_count,
               import_status, import_reason)
            values ("&_scode", '', ., ., "&fstatus", "&freason");
          quit;
        %end;
        %else %do;

          /* Store sheet names in macro vars for the loop */
          data work._sheetlist;
            set work._sheetlist;
            sheet_seq = _n_;
            call symputx(cats('_sh', _n_), sheet_name, 'G');
          run;

          /* Build sheet_list string */
          data _null_;
            retain _slist '';
            set work._sheetlist end=_eof;
            if _n_ = 1 then _slist = strip(sheet_name);
            else _slist = catx(', ', _slist, strip(sheet_name));
            if _eof then call symputx('_slist_str', _slist, 'G');
          run;

          %do j = 1 %to &nsheets;
            %let _sh_ds = &_dsname._s&j;

            /* Use letter-start unquoted vs digit-start name literal (Pitfall 1) */
            %if %sysfunc(prxmatch(%str(/^[A-Za-z_]\w*$/), %superq(_sh&j))) %then %do;
              data work.&_sh_ds;
                set _xlw.&&_sh&j;
              run;
            %end;
            %else %do;
              %let _dsid_chk = %sysfunc(open(_xlw.%superq(_sh&j)));
              %if &_dsid_chk > 0 %then %do;
                %let _rc_chk = %sysfunc(close(&_dsid_chk));
                data work.&_sh_ds;
                  set _xlw."%unquote(%superq(_sh&j))"n;
                run;
              %end;
              %else %do;
                %put NOTE: [02_source_guard] digit-prefix sheet &&_sh&j in &_scode -- inaccessible;
              %end;
            %end;
            %let syscc = 0;

            /* Record sheet_name -> dataset mapping for grain/overlap lookups */
            %if %sysfunc(exist(work.&_sh_ds)) %then %do;
              proc sql noprint;
                insert into work.sheet_map (s_code, sheet_name, sheet_ds)
                values ("&_scode", "&&_sh&j", "work.&_sh_ds");
              quit;
            %end;

            /* Accumulate header rows */
            %if %sysfunc(exist(work.&_sh_ds)) %then %do;
              proc sql noprint;
                insert into work.hdr_all
                  (s_code, sheet_name, col_name, col_type, col_label, col_len)
                select "&_scode", "&&_sh&j", name, type, label, length
                from dictionary.columns
                where libname='WORK' and memname=upcase("&_sh_ds");
              quit;

              /* Compute nonblank_row_count for s19 BEFORE insert (no PROC SQL UPDATE) */
              %let _nb_count = .;
              %if &_scode = s19 %then %do;
                %macro _s19_nonblank_pre;
                  %local _nb;
                  %let _nb = 0;
                  data _null_;
                    set work.&_sh_ds end=_eof;
                    retain _nb 0;
                    _any = 0;
                    array _c {*} _character_;
                    array _n {*} _numeric_;
                    do _k = 1 to dim(_c);
                      if strip(_c{_k}) ne '' then _any = 1;
                    end;
                    do _k = 1 to dim(_n);
                      if not missing(_n{_k}) then _any = 1;
                    end;
                    if _any then _nb + 1;
                    if _eof then call symputx('_nb_count', _nb, 'G');
                    drop _any _k;
                  run;
                %mend _s19_nonblank_pre;
                %_s19_nonblank_pre;
              %end;

              /* Accumulate counts (nonblank_row_count included here -- no UPDATE needed) */
              proc sql noprint;
                insert into work.counts_all
                  (s_code, sheet_name, row_count, col_count, sheet_list,
                   import_status, import_reason, nonblank_row_count)
                select "&_scode", "&&_sh&j", nobs, nvar, "&_slist_str",
                       'profiled', '', &_nb_count
                from dictionary.tables
                where libname='WORK' and memname=upcase("&_sh_ds");
              quit;

            %end;
          %end;  /* end sheet loop */

        %end;  /* end nsheets > 0 */

        libname _xlw clear;
        /* sheet_list already populated in each INSERT row above; no UPDATE needed */

        proc datasets lib=work nolist nowarn;
          delete _sheetlist;
        quit;

      %end;  /* end libref ok */

    %end;  /* end XLSX branch */

  %end;  /* end file loop */

%mend import_all_files;
%import_all_files;


/* ---- Write pdd.header_inventory ---- */
data pdd.header_inventory;
  set work.hdr_all;
run;

%put NOTE: [02_source_guard] pdd.header_inventory written;

/* ---- Benchmark NOTEs for header_inventory ---- */
proc sql noprint;
  select count(*) into :_nrows7 trimmed
    from pdd.header_inventory
    where s_code in ('s03','s07','s09','s10','s12','s15','s17')
      and sheet_name='';
  select count(distinct col_name) into :_ndist7 trimmed
    from pdd.header_inventory
    where s_code in ('s03','s07','s09','s10','s12','s15','s17')
      and sheet_name='';
  select count(*) into :_nrows_all trimmed from pdd.header_inventory;
  select count(distinct col_name) into :_ndist_all trimmed from pdd.header_inventory;
quit;
%put NOTE: [02_source_guard] header_inventory 7-CSV rows = &_nrows7. (expect ~701);
%put NOTE: [02_source_guard] 7-CSV distinct col_name = &_ndist7. (expect ~168);
%put NOTE: [02_source_guard] header_inventory all-20 total rows = &_nrows_all.;
%put NOTE: [02_source_guard] all-20 distinct col_name = &_ndist_all.;


/* ---- Re-assemble pdd.source_inventory with import columns ---- */
/* Sort component datasets */
proc sort data=work.file_list     out=work._fl2_s;  by s_code; run;

/* Aggregate counts_all to one row per s_code (summing multi-sheet) */
proc sql noprint;
  create table work._counts_agg as
  select s_code,
         sum(row_count)          as row_count,
         sum(col_count)          as col_count,
         max(sheet_list)         as sheet_list    length=2000,
         max(import_status)      as import_status length=30,
         max(import_reason)      as import_reason length=500,
         max(nonblank_row_count) as nonblank_row_count
  from work.counts_all
  group by s_code;
quit;

proc sort data=work._counts_agg out=work._cnt2_s;  by s_code; run;
proc sort data=pdd.source_inventory out=work._si_s; by s_code; run;

data pdd.source_inventory;
  merge work._si_s (in=_in_si)
        work._cnt2_s (keep=s_code row_count col_count sheet_list
                          import_status import_reason nonblank_row_count);
  by s_code;
  if _in_si;
  label
    row_count          = 'Imported row count from import loop'
    col_count          = 'Imported column count from import loop'
    sheet_list         = 'Comma-separated list of XLSX sheet names (blank for CSV)'
    import_status      = 'profiled or read-failed'
    import_reason      = 'Failure or warning reason from import step'
    nonblank_row_count = 'Rows with at least one non-blank/non-missing value (s19 only)';
run;

/* Clean up */
proc datasets lib=work nolist nowarn;
  delete _fl2_s _counts_agg _cnt2_s _si_s;
quit;

%put NOTE: [02_source_guard] pdd.source_inventory re-assembled with import columns;

/* Re-assert 20 rows */
%assert_inventory_rows;


/* ============================================================
   SECTION 8 -- Candidate key detection (pdd.key_analysis prep)
   Scan pdd.header_inventory column names and labels.
   key_column_type assignment per RESEARCH Pattern 5 table.
   NONE_DETECTED sentinel for files with no matching key.
   ============================================================ */
proc sql noprint;
  create table work.file_keys_raw as
  select s_code, sheet_name, col_name, col_type, col_label,
    case
      /* PRECEDE_STUDY_ID -- name-based exact or STUDYID loose */
      when compress(upcase(col_name),' _-') in
           ('PRECEDESTUDYID','STUDYID','PRECEDEID')              then 'PRECEDE_STUDY_ID'
      /* ENCRYPTED_MRN -- exact or contains ENCRYPTED + MRN */
      when compress(upcase(col_name),' _-') = 'ENCRYPTEDMRN'
           or (index(upcase(col_name),'ENCRYPTED') > 0
               and index(upcase(col_name),'MRN') > 0)            then 'ENCRYPTED_MRN'
      /* ENCRYPTED_ENCOUNTER */
      when index(upcase(col_name),'ENCRYPTED') > 0
           and index(upcase(col_name),'ENCOUNTER') > 0           then 'ENCRYPTED_ENCOUNTER'
      /* bare MRN */
      when compress(upcase(col_name),' _-') = 'MRN'             then 'UNENC_MRN'
      /* bare ENCOUNTER / ENCOUNTERID */
      when compress(upcase(col_name),' _-') in
           ('ENCOUNTER','ENCOUNTERID')                           then 'UNENC_ENCOUNTER'
      /* RECORD_ID -- exact */
      when compress(upcase(col_name),' _-') = 'RECORDID'        then 'RECORD_ID'
      /* Label-based fallbacks */
      when compress(upcase(col_label),' _-') in
           ('PRECEDESTUDYID','STUDYID','PRECEDEID')              then 'PRECEDE_STUDY_ID'
      when compress(upcase(col_label),' _-') = 'ENCRYPTEDMRN'
           or (index(upcase(col_label),'ENCRYPTED') > 0
               and index(upcase(col_label),'MRN') > 0)           then 'ENCRYPTED_MRN'
      when index(upcase(col_label),'ENCRYPTED') > 0
           and index(upcase(col_label),'ENCOUNTER') > 0          then 'ENCRYPTED_ENCOUNTER'
      when compress(upcase(col_label),' _-') = 'MRN'            then 'UNENC_MRN'
      when compress(upcase(col_label),' _-') in
           ('ENCOUNTER','ENCOUNTERID')                           then 'UNENC_ENCOUNTER'
      when compress(upcase(col_label),' _-') = 'RECORDID'       then 'RECORD_ID'
      else ''
    end as key_column_type length=30,
    case
      when compress(upcase(col_name),' _-') in
           ('PRECEDESTUDYID','PRECEDEID') then 'name'
      when compress(upcase(col_name),' _-') = 'STUDYID'         then 'loose'
      when compress(upcase(col_name),' _-') = 'ENCRYPTEDMRN'
           or compress(upcase(col_name),' _-') = 'MRN'
           or compress(upcase(col_name),' _-') in ('ENCOUNTER','ENCOUNTERID')
           or compress(upcase(col_name),' _-') = 'RECORDID'     then 'name'
      when index(upcase(col_name),'ENCRYPTED') > 0
           and (index(upcase(col_name),'MRN') > 0
             or index(upcase(col_name),'ENCOUNTER') > 0)         then 'name'
      else 'label'
    end as match_basis length=20
  from pdd.header_inventory
  where calculated key_column_type ne ''
  order by s_code, sheet_name, col_name;
quit;

/* Build the distinct list of file x sheet combinations */
proc sql noprint;
  create table work._file_sheets as
  select distinct s_code, sheet_name
  from pdd.header_inventory
  order by s_code, sheet_name;
quit;

/* Left join: all file x sheets get at least one row;
   files with no key get NONE_DETECTED sentinel */
proc sql noprint;
  create table work.file_keys_joined as
  select fs.s_code, fs.sheet_name,
         coalesce(k.col_name, '')         as key_var_name    length=32,
         coalesce(k.col_type, '')         as key_col_type_raw length=4,
         coalesce(k.key_column_type, 'NONE_DETECTED') as key_column_type length=30,
         coalesce(k.match_basis, 'none')  as match_basis      length=20
  from work._file_sheets fs
  left join work.file_keys_raw k
    on fs.s_code = k.s_code and fs.sheet_name = k.sheet_name
  order by fs.s_code, fs.sheet_name, key_column_type;
quit;

/* Emit WARNING for NONE_DETECTED (inside macro, per PCM compliance) */
%macro _warn_none_detected;
  data _null_;
    set work.file_keys_joined;
    if key_column_type = 'NONE_DETECTED' then
      put 'WARNING: [02_source_guard] no candidate key detected in ' s_code= sheet_name=;
  run;
%mend _warn_none_detected;
%_warn_none_detected;

data work.file_keys;
  set work.file_keys_joined;
  rename key_var_name = key_var_name;
run;

proc datasets lib=work nolist nowarn;
  delete file_keys_raw _file_sheets file_keys_joined;
quit;

%put NOTE: [02_source_guard] work.file_keys built;


/* ============================================================
   SECTION 9 -- Grain test (COUNT(*) vs COUNT(DISTINCT key))
   Runs ONLY for rows where key_column_type ne NONE_DETECTED.
   NONE_DETECTED rows pass through with n_rows/n_distinct/grain
   set to missing.
   ============================================================ */
data work.key_grain_base;
  set work.file_keys;
  length n_rows 8 n_distinct 8 grain $10;
  n_rows    = .;
  n_distinct = .;
  grain     = '';
run;

%macro grain_test;
  %local n_keys ik _scode2 _sheet2 _ktype2 _kvar2 _dsref
         _n_rows _n_dist;

  %let n_keys = 0;
  proc sql noprint;
    select count(*) into :n_keys trimmed
    from work.file_keys
    where key_column_type ne 'NONE_DETECTED';
  quit;

  data _null_;
    set work.file_keys(where=(key_column_type ne 'NONE_DETECTED'));
    call symputx(cats('_gsc',  _n_), s_code,          'G');
    call symputx(cats('_gsh',  _n_), sheet_name,      'G');
    call symputx(cats('_gkt',  _n_), key_column_type, 'G');
    call symputx(cats('_gkv',  _n_), key_var_name,    'G');
  run;

  %do ik = 1 %to &n_keys;
    %let _scode2 = &&_gsc&ik;
    %let _sheet2 = &&_gsh&ik;
    %let _ktype2 = &&_gkt&ik;
    %let _kvar2  = &&_gkv&ik;

    /* Determine dataset reference */
    %if %length(&_sheet2) = 0 %then %let _dsref = work.src_&_scode2;
    %else %do;
      /* Look up the work dataset name from sheet_map */
      %local _dsref_tmp;
      %let _dsref_tmp = ;
      data _null_;
        set work.sheet_map;
        if s_code = "&_scode2" and sheet_name = "&_sheet2" then
          call symputx('_dsref_tmp', strip(sheet_ds), 'G');
      run;
      %if %length(&_dsref_tmp) > 0 %then %let _dsref = &_dsref_tmp;
      %else %let _dsref = work.src_&_scode2._s1;  /* fallback */
    %end;

    /* Check if dataset exists before querying */
    %if %sysfunc(exist(&_dsref)) and %length(&_kvar2) > 0 %then %do;
      %let _n_rows = 0;
      %let _n_dist = 0;
      proc sql noprint;
        select count(*) into :_n_rows trimmed from &_dsref;
        select count(distinct &_kvar2) into :_n_dist trimmed
          from &_dsref
          where &_kvar2 is not missing;
      quit;

      data work._grain_upd;
        set work.key_grain_base;
        if s_code = "&_scode2"
           and sheet_name = "&_sheet2"
           and key_column_type = "&_ktype2"
           and key_var_name = "&_kvar2"
        then do;
          n_rows    = &_n_rows;
          n_distinct = &_n_dist;
          if &_n_rows = &_n_dist then grain = 'unique';
          else grain = 'multi-row';
        end;
      run;
      /* Replace base with updated */
      data work.key_grain_base;
        set work._grain_upd;
      run;
      proc datasets lib=work nolist nowarn; delete _grain_upd; quit;
    %end;

  %end;  /* end grain loop */

%mend grain_test;
%grain_test;

/* Log s01 and s08 grain as informational NOTEs */
%macro _log_grain_notes;
  data _null_;
    set work.key_grain_base;
    if s_code in ('s01','s08') and key_column_type ne 'NONE_DETECTED' then
      put 'NOTE: [02_source_guard] grain info: ' s_code= key_column_type= grain= n_rows= n_distinct=;
  run;
%mend _log_grain_notes;
%_log_grain_notes;

/* Write pdd.key_analysis */
data pdd.key_analysis;
  set work.key_grain_base;
  label
    s_code         = 'Source code (s01-s20)'
    sheet_name     = 'Sheet name (blank for CSV)'
    key_column_type = 'Key type: PRECEDE_STUDY_ID / ENCRYPTED_MRN / ENCRYPTED_ENCOUNTER / UNENC_MRN / UNENC_ENCOUNTER / RECORD_ID / NONE_DETECTED'
    key_var_name   = 'SAS variable name of the candidate key column'
    match_basis    = 'How the key was matched: name / loose / label / none'
    n_rows         = 'Total row count of imported table'
    n_distinct     = 'Count of distinct non-missing key values'
    grain          = 'unique or multi-row (blank for NONE_DETECTED)';
run;

%put NOTE: [02_source_guard] pdd.key_analysis written;

/* Assert pdd.key_analysis has at least one row */
%macro assert_key_analysis;
  %local _nka;
  %let _nka = 0;
  proc sql noprint;
    select count(*) into :_nka trimmed from pdd.key_analysis;
  quit;
  %if &_nka = 0 %then %do;
    %fail_out(msg=pdd.key_analysis has zero rows -- import loop or key detection failed);
  %end;
  %put NOTE: [02_source_guard] assert_key_analysis passed -- &_nka rows;
%mend assert_key_analysis;
%assert_key_analysis;

proc datasets lib=work nolist nowarn;
  delete key_grain_base;
quit;


/* ============================================================
   SECTION 10 -- ID overlap against the s09 spine (pdd.id_overlap)
   Three spine lookup tables from src_s09.
   Normalisation: char -> strip(x); numeric -> cats(strip(put(x,20.))).
   Never upcase() a numeric column.
   s04/s05 also compared against s16/s17/s18 spines.
   ============================================================ */

/* ---- Determine type of each s09 key column ---- */
%macro _get_col_type(ds=, col=, outmv=);
  %local _tp;
  %let _tp = ;
  proc sql noprint;
    select type into :_tp trimmed
    from dictionary.columns
    where libname='WORK' and memname=upcase("&ds") and upcase(name)=upcase("&col");
  quit;
  %let &outmv = &_tp;
%mend _get_col_type;

/* ---- Build spine lookup tables from src_s09 ---- */
%macro _build_spine(ds=, col=, out=);
  /* Check if column exists */
  %local _coltype;
  %_get_col_type(ds=&ds, col=&col, outmv=_coltype);
  %if %length(&_coltype) = 0 %then %do;
    %put NOTE: [02_source_guard] column &col not found in &ds -- spine &out will be empty;
    data &out;
      length spine_key $64;
      stop;
    run;
  %end;
  %else %if &_coltype = char %then %do;
    proc sql noprint;
      create table &out as
      select distinct strip(&col) as spine_key length=64
      from &ds
      where &col is not missing and strip(&col) ne '';
    quit;
  %end;
  %else %do;
    proc sql noprint;
      create table &out as
      select distinct cats(strip(put(&col, 20.))) as spine_key length=64
      from &ds
      where &col is not missing;
    quit;
  %end;
%mend _build_spine;

/* Build the three primary spine tables from s09 */
%macro _build_primary_spines;
  %if %sysfunc(exist(work.src_s09)) %then %do;
    %_build_spine(ds=work.src_s09, col=PRECEDE_STUDY_ID, out=work.spine_psid);
    %_build_spine(ds=work.src_s09, col=ENCRYPTED_MRN,    out=work.spine_mrn);
    %_build_spine(ds=work.src_s09, col=ENCRYPTED_ENCOUNTER, out=work.spine_enc);
  %end;
  %else %do;
    %put WARNING: [02_source_guard] work.src_s09 not found -- spine tables will be empty;
    data work.spine_psid work.spine_mrn work.spine_enc;
      length spine_key $64; stop;
    run;
  %end;
%mend _build_primary_spines;
%_build_primary_spines;

/* Build secondary spines for s04/s05 crosswalk testing */
%macro _build_secondary_spines;
  /* s16 MRN spine */
  %if %sysfunc(exist(work.src_s16)) %then
    %_build_spine(ds=work.src_s16, col=ENCRYPTED_MRN, out=work.spine_s16_mrn);
  %else %do;
    data work.spine_s16_mrn; length spine_key $64; stop; run;
  %end;

  /* s17 study ID spine */
  %if %sysfunc(exist(work.src_s17)) %then
    %_build_spine(ds=work.src_s17, col=PRECEDE_STUDY_ID, out=work.spine_s17_psid);
  %else %do;
    data work.spine_s17_psid; length spine_key $64; stop; run;
  %end;

  /* s18 study ID spine */
  %if %sysfunc(exist(work.src_s18)) %then
    %_build_spine(ds=work.src_s18, col=PRECEDE_STUDY_ID, out=work.spine_s18_psid);
  %else %do;
    data work.spine_s18_psid; length spine_key $64; stop; run;
  %end;
%mend _build_secondary_spines;
%_build_secondary_spines;

/* Accumulator for overlap results */
data work.overlap_all;
  length s_code $4 sheet_name $200 key_column_type $30 key_var_name $32
         spine_source $8 n_in_file 8 n_matching_spine 8 pct_overlap 8;
  stop;
run;

/* Macro to compute one overlap row */
%macro _compute_overlap(scode=, sheet=, ktype=, kvar=, kvar_type=,
                         filedsn=, spinedsn=, spine_src=);

  %if not %sysfunc(exist(&filedsn)) %then %do;
    %put NOTE: [02_source_guard] &filedsn does not exist -- skipping overlap for &scode &sheet &ktype;
  %end;
  %else %do;
    %local _nin _nmatch _pct;
    %let _nin   = 0;
    %let _nmatch = 0;

    /* n_in_file: distinct non-missing key values in the file */
    %if &kvar_type = char %then %do;
      proc sql noprint;
        select count(distinct strip(&kvar)) into :_nin trimmed
        from &filedsn
        where &kvar is not missing and strip(&kvar) ne '';
      quit;
    %end;
    %else %do;
      proc sql noprint;
        select count(distinct cats(strip(put(&kvar, 20.)))) into :_nin trimmed
        from &filedsn
        where &kvar is not missing;
      quit;
    %end;

    /* n_matching_spine: count matching the spine */
    %if &kvar_type = char %then %do;
      proc sql noprint;
        select count(distinct strip(f.&kvar)) into :_nmatch trimmed
        from &filedsn f
        inner join &spinedsn s
          on strip(f.&kvar) = s.spine_key
        where f.&kvar is not missing and strip(f.&kvar) ne '';
      quit;
    %end;
    %else %do;
      proc sql noprint;
        select count(distinct cats(strip(put(f.&kvar, 20.)))) into :_nmatch trimmed
        from &filedsn f
        inner join &spinedsn s
          on cats(strip(put(f.&kvar, 20.))) = s.spine_key
        where f.&kvar is not missing;
      quit;
    %end;

    /* pct_overlap with divide-by-zero guard */
    data work._ov_row_;
      length s_code $4 sheet_name $200 key_column_type $30 key_var_name $32
             spine_source $8 n_in_file 8 n_matching_spine 8 pct_overlap 8;
      s_code           = "&scode";
      sheet_name       = "&sheet";
      key_column_type  = "&ktype";
      key_var_name     = "&kvar";
      spine_source     = "&spine_src";
      n_in_file        = &_nin;
      n_matching_spine = &_nmatch;
      if &_nin > 0 then
        pct_overlap = round(100 * &_nmatch / &_nin, 0.1);
      else
        pct_overlap = .;
    run;
    proc append base=work.overlap_all data=work._ov_row_ force; run;
    proc datasets lib=work nolist nowarn; delete _ov_row_; quit;

    %put NOTE: [02_source_guard] overlap &scode &sheet &ktype spine=&spine_src n_in_file=&_nin n_matching=&_nmatch;
  %end;

%mend _compute_overlap;

/* Main overlap loop over pdd.key_analysis where key ne NONE_DETECTED */
%macro overlap_loop;
  %local n_ov io _ov_sc _ov_sh _ov_kt _ov_kv _ov_kvt
         _ov_ds _spine_ds;

  %let n_ov = 0;
  proc sql noprint;
    select count(*) into :n_ov trimmed
    from pdd.key_analysis
    where key_column_type ne 'NONE_DETECTED' and key_var_name ne '';
  quit;

  data _null_;
    set pdd.key_analysis(where=(key_column_type ne 'NONE_DETECTED'
                                and key_var_name ne ''));
    call symputx(cats('_ovsc', _n_), s_code,          'G');
    call symputx(cats('_ovsh', _n_), sheet_name,      'G');
    call symputx(cats('_ovkt', _n_), key_column_type, 'G');
    call symputx(cats('_ovkv', _n_), key_var_name,    'G');
  run;

  %do io = 1 %to &n_ov;
    %let _ov_sc  = &&_ovsc&io;
    %let _ov_sh  = &&_ovsh&io;
    %let _ov_kt  = &&_ovkt&io;
    %let _ov_kv  = &&_ovkv&io;

    /* Determine file dataset reference */
    %if %length(&_ov_sh) = 0 %then %let _ov_ds = work.src_&_ov_sc;
    %else %do;
      /* Look up the work dataset name from sheet_map */
      %local _ov_ds_tmp;
      %let _ov_ds_tmp = ;
      data _null_;
        set work.sheet_map;
        if s_code = "&_ov_sc" and sheet_name = "&_ov_sh" then
          call symputx('_ov_ds_tmp', strip(sheet_ds), 'G');
      run;
      %if %length(&_ov_ds_tmp) > 0 %then %let _ov_ds = &_ov_ds_tmp;
      %else %let _ov_ds = work.src_&_ov_sc._s1;  /* fallback */
    %end;

    /* Get col type for normalisation */
    %_get_col_type(ds=&_ov_ds, col=&_ov_kv, outmv=_ov_kvt);

    /* Select spine table based on key_column_type */
    %if &_ov_kt = PRECEDE_STUDY_ID %then %let _spine_ds = work.spine_psid;
    %else %if &_ov_kt = ENCRYPTED_MRN %then %let _spine_ds = work.spine_mrn;
    %else %if &_ov_kt = ENCRYPTED_ENCOUNTER %then %let _spine_ds = work.spine_enc;
    %else %do;
      %put NOTE: [02_source_guard] no same-type spine for &_ov_kt in &_ov_sc -- using PSID spine (overlap expected low);
      %let _spine_ds = work.spine_psid;
    %end;

    %_compute_overlap(scode=&_ov_sc, sheet=&_ov_sh, ktype=&_ov_kt,
                      kvar=&_ov_kv, kvar_type=&_ov_kvt,
                      filedsn=&_ov_ds, spinedsn=&_spine_ds,
                      spine_src=s09);

    /* s04/s05: additional spine comparisons */
    %if &_ov_sc = s04 or &_ov_sc = s05 %then %do;
      %_compute_overlap(scode=&_ov_sc, sheet=&_ov_sh, ktype=&_ov_kt,
                        kvar=&_ov_kv, kvar_type=&_ov_kvt,
                        filedsn=&_ov_ds, spinedsn=work.spine_s16_mrn,
                        spine_src=s16);
      %_compute_overlap(scode=&_ov_sc, sheet=&_ov_sh, ktype=&_ov_kt,
                        kvar=&_ov_kv, kvar_type=&_ov_kvt,
                        filedsn=&_ov_ds, spinedsn=work.spine_s17_psid,
                        spine_src=s17);
      %_compute_overlap(scode=&_ov_sc, sheet=&_ov_sh, ktype=&_ov_kt,
                        kvar=&_ov_kv, kvar_type=&_ov_kvt,
                        filedsn=&_ov_ds, spinedsn=work.spine_s18_psid,
                        spine_src=s18);
    %end;

  %end;  /* end overlap loop */

%mend overlap_loop;
%overlap_loop;

/* Write pdd.id_overlap */
data pdd.id_overlap;
  set work.overlap_all;
  label
    s_code           = 'Source code (s01-s20)'
    sheet_name       = 'Sheet name (blank for CSV)'
    key_column_type  = 'Key type'
    key_var_name     = 'SAS variable name of the key column'
    spine_source     = 'Spine dataset used (s09 / s16 / s17 / s18)'
    n_in_file        = 'Distinct non-missing key values in this file'
    n_matching_spine = 'Distinct file keys that appear in the spine'
    pct_overlap      = 'n_matching_spine / n_in_file * 100 (rounded to 0.1)';
run;

%put NOTE: [02_source_guard] pdd.id_overlap written;

/* Log s04/s05 overlap NOTEs for PDD-D-18 decision */
%macro _log_overlap_notes;
  data _null_;
    set pdd.id_overlap;
    if s_code in ('s04','s05') then
      put 'NOTE: [02_source_guard] crosswalk overlap: '
          s_code= key_column_type= spine_source= n_in_file= n_matching_spine= pct_overlap=;
  run;
%mend _log_overlap_notes;
%_log_overlap_notes;

/* Assert pdd.id_overlap: has rows; s09 self-overlap >= 99.5 */
%macro assert_overlap;
  %local _nov _s09self;
  %let _nov    = 0;
  %let _s09self = 0;
  proc sql noprint;
    select count(*) into :_nov trimmed from pdd.id_overlap;
    select max(pct_overlap) into :_s09self trimmed
    from pdd.id_overlap
    where s_code = 's09' and spine_source = 's09'
      and key_column_type = 'PRECEDE_STUDY_ID';
  quit;
  %if &_nov = 0 %then %do;
    %fail_out(msg=pdd.id_overlap has zero rows -- overlap computation failed);
  %end;
  %if %sysevalf(&_s09self < 99.5) %then %do;
    %fail_out(msg=s09 self-overlap = &_s09self pct -- expected >= 99.5);
  %end;
  %put NOTE: [02_source_guard] assert_overlap passed -- &_nov rows s09 self-overlap=&_s09self.pct;
%mend assert_overlap;
%assert_overlap;

/* Clean up spine and overlap work datasets */
proc datasets lib=work nolist nowarn;
  delete spine_psid spine_mrn spine_enc
         spine_s16_mrn spine_s17_psid spine_s18_psid
         overlap_all file_keys sheet_map;
quit;

%put NOTE: [02_source_guard] === Plan 02 sections complete ===;


/* ============================================================
   SECTION 13 -- Build display datasets for QC workbooks
   work.key_legend_inv  : KEY sheet for source_inventory.xlsx
   work.key_legend_hdr  : KEY sheet for header_matrix.xlsx
   work.header_wide     : wide header matrix (PROC TRANSPOSE)
   ============================================================ */

/* KEY legend for source_inventory.xlsx */
data work.key_legend_inv;
  length sheet_name $20 column_name $50 description $200 notes $250;
  infile datalines dsd dlm='|' truncover;
  input sheet_name $ column_name $ description $ notes $;
  datalines;
SOURCES|file_id|Sequential file identifier (1-20)|
SOURCES|s_code|Source code (s01-s20)|
SOURCES|filename|Source file name|
SOURCES|ftype|File type: csv or xlsx|
SOURCES|full_path|Full path in shared source folder (read-only)|
SOURCES|file_size|File size in bytes|
SOURCES|mod_date|Last-modified date string from OS|Raw locale-dependent string; not parsed to SAS date
SOURCES|sha256|SHA-256 checksum from certutil|FAILED sentinel if certutil could not hash the file
SOURCES|sha256_old|SHA-256 of older copy or NO_OLD_COPY sentinel|
SOURCES|old_copy_folder|Older-copy root that matched: master / raw / blank|
SOURCES|old_copy_status|identical / different / no_older_copy|
SOURCES|row_count|Imported row count from import loop|
SOURCES|col_count|Imported column count from import loop|
SOURCES|sheet_list|Comma-separated XLSX sheet names (blank for CSV)|
SOURCES|import_status|profiled or read-failed|
SOURCES|import_reason|Failure or warning reason from import step|
SOURCES|nonblank_row_count|Rows with at least one non-blank/non-missing value (s19 only)|
KEY_ANALYSIS|s_code|Source code (s01-s20)|
KEY_ANALYSIS|sheet_name|Sheet name (blank for CSV)|
KEY_ANALYSIS|key_column_type|Key type detected|PRECEDE_STUDY_ID / ENCRYPTED_MRN / ENCRYPTED_ENCOUNTER / UNENC_MRN / UNENC_ENCOUNTER / RECORD_ID / NONE_DETECTED
KEY_ANALYSIS|key_var_name|SAS variable name of the candidate key column|
KEY_ANALYSIS|match_basis|How the key was matched: name / loose / label / none|
KEY_ANALYSIS|n_rows|Total row count of imported table|
KEY_ANALYSIS|n_distinct|Count of distinct non-missing key values|
KEY_ANALYSIS|grain|unique or multi-row (blank for NONE_DETECTED)|
ID_OVERLAP|s_code|Source code (s01-s20)|
ID_OVERLAP|sheet_name|Sheet name (blank for CSV)|
ID_OVERLAP|key_column_type|Key type|
ID_OVERLAP|key_var_name|SAS variable name of the key column|
ID_OVERLAP|spine_source|Spine dataset used: s09 / s16 / s17 / s18|
ID_OVERLAP|n_in_file|Distinct non-missing key values in this file|
ID_OVERLAP|n_matching_spine|Distinct file keys that appear in the spine|
ID_OVERLAP|pct_overlap|n_matching_spine / n_in_file * 100 (rounded to 0.1)|
;

/* KEY legend for header_matrix.xlsx */
data work.key_legend_hdr;
  length sheet_name $20 column_name $50 description $200 notes $250;
  infile datalines dsd dlm='|' truncover;
  input sheet_name $ column_name $ description $ notes $;
  datalines;
HEADER_LONG|s_code|Source code (s01-s20)|
HEADER_LONG|sheet_name|Sheet name (blank for CSV)|
HEADER_LONG|col_name|SAS column name as imported|
HEADER_LONG|col_type|SAS column type: char or num|
HEADER_LONG|col_label|SAS column label (original header where name was changed)|
HEADER_LONG|col_len|SAS column length in bytes|
HEADER_MATRIX|col_name|Column name (one row per distinct column across all files)|Rows sorted alphabetically by col_name
HEADER_MATRIX|(s_code columns)|Cell value = col_type (char / num) or blank if column absent|One column per source file or file-sheet combination
;

/* Build work.header_wide via PROC TRANSPOSE
   id = s_code (or s_code_sheet for multi-sheet XLSX)
   For multi-sheet files the s_code alone would collapse sheets;
   build a combined s_code_sheet label for the id variable.
   The id value must be a valid SAS name (max 32 chars).
   Combine: cats(s_code, '_', compress(sheet_name,' ')) for xlsx;
   for csv (sheet_name='') just use s_code.
*/
data work.hdr_inv_prep;
  set pdd.header_inventory;
  length hdr_src $32;
  if sheet_name = '' then
    hdr_src = s_code;
  else
    hdr_src = substr(cats(s_code, '_', compress(sheet_name,' _-')), 1, 32);
  /* normalised sort key: compress upcase for duplicate detection */
  length col_name_sort $32;
  col_name_sort = compress(upcase(col_name), ' _');
run;

proc sort data=work.hdr_inv_prep out=work.hdr_inv_sorted;
  by col_name hdr_src;
run;

proc transpose data=work.hdr_inv_sorted
    out=work.header_wide (drop=_name_)
    prefix=src_;
  by col_name;
  id hdr_src;
  var col_type;
run;

%put NOTE: [02_source_guard] work.header_wide built via PROC TRANSPOSE;


/* ============================================================
   SECTION 14 -- ODS Excel QC workbooks
   Workbook 1: qc\source_inventory.xlsx
   Workbook 2: qc\header_matrix.xlsx
   KEY sheet is FIRST (leftmost) in each workbook (PDD-D-09).
   UF header style: background cx0021A5, white bold text.
   ============================================================ */

/* Register template in WORK path so it does not persist across sessions */
ods path(prepend) work.templat(update);
proc template;
  define style styles.uf_inventory;
    parent = styles.pearl;
    class header /
      backgroundcolor = cx0021A5
      color           = white
      fontweight      = bold;
  end;
run;

/* ---- Workbook 1: source_inventory.xlsx ---- */
ods listing close;
ods excel file="&qc_path.\source_inventory.xlsx"
    style=styles.uf_inventory
    options(sheet_interval='proc' frozen_headers='on' autofilter='all');

/* KEY sheet MUST be first (PDD-D-09) */
ods excel options(sheet_name='KEY');
proc print data=work.key_legend_inv noobs; run;

ods excel options(sheet_name='SOURCES');
proc print data=pdd.source_inventory noobs; run;

ods excel options(sheet_name='KEY_ANALYSIS');
proc print data=pdd.key_analysis noobs; run;

ods excel options(sheet_name='ID_OVERLAP');
proc print data=pdd.id_overlap noobs; run;

ods excel close;
ods listing;

%put NOTE: [02_source_guard] qc\source_inventory.xlsx written;

/* ---- Workbook 2: header_matrix.xlsx ---- */
ods listing close;
ods excel file="&qc_path.\header_matrix.xlsx"
    style=styles.uf_inventory
    options(sheet_interval='proc' frozen_headers='on' autofilter='all');

/* KEY sheet MUST be first (PDD-D-09) */
ods excel options(sheet_name='KEY');
proc print data=work.key_legend_hdr noobs; run;

ods excel options(sheet_name='HEADER_LONG');
proc print data=pdd.header_inventory noobs; run;

ods excel options(sheet_name='HEADER_MATRIX');
proc print data=work.header_wide noobs; run;

ods excel close;
ods listing;

%put NOTE: [02_source_guard] qc\header_matrix.xlsx written;


/* ============================================================
   SECTION 15 -- %assert_outputs: final output-existence assertions
   Verifies all four pdd datasets and both QC workbooks exist.
   No literal quotes inside %sysfunc(fileexist()) -- path via macro var.
   ============================================================ */
%macro assert_outputs;
  %local _p _n_si;

  /* ---- Four pdd datasets ---- */
  %if not %sysfunc(exist(pdd.source_inventory)) %then %do;
    %fail_out(msg=OUTPUT MISSING -- pdd.source_inventory does not exist);
  %end;
  %if not %sysfunc(exist(pdd.header_inventory)) %then %do;
    %fail_out(msg=OUTPUT MISSING -- pdd.header_inventory does not exist);
  %end;
  %if not %sysfunc(exist(pdd.key_analysis)) %then %do;
    %fail_out(msg=OUTPUT MISSING -- pdd.key_analysis does not exist);
  %end;
  %if not %sysfunc(exist(pdd.id_overlap)) %then %do;
    %fail_out(msg=OUTPUT MISSING -- pdd.id_overlap does not exist);
  %end;

  /* ---- pdd.source_inventory rowcount = 20 ---- */
  %let _n_si = 0;
  proc sql noprint;
    select count(*) into :_n_si trimmed from pdd.source_inventory;
  quit;
  %if &_n_si ne 20 %then %do;
    %fail_out(msg=pdd.source_inventory rowcount = &_n_si -- expected 20);
  %end;

  /* ---- source_inventory.xlsx ---- */
  %let _p = &qc_path.\source_inventory.xlsx;
  %if not %sysfunc(fileexist(&_p)) %then %do;
    %fail_out(msg=OUTPUT MISSING -- qc\source_inventory.xlsx was not created);
  %end;

  /* ---- header_matrix.xlsx ---- */
  %let _p = &qc_path.\header_matrix.xlsx;
  %if not %sysfunc(fileexist(&_p)) %then %do;
    %fail_out(msg=OUTPUT MISSING -- qc\header_matrix.xlsx was not created);
  %end;

  %put NOTE: [02_source_guard] PASS -- all Phase 2 outputs present;
%mend assert_outputs;
%assert_outputs;


/* ============================================================
   SECTION 16 -- %restore_log (MUST be the last executable line)
   Standalone: closes the PROC PRINTTO redirect.
   Pipeline (in_pipeline=1): no-op.
   ============================================================ */
%restore_log;
