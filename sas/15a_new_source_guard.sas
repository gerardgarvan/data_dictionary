/*==========================================================================
  Program : 15a_new_source_guard.sas
  Phase   : 15 (new-source intake), plan 15-01
  Purpose : NEW-01. (a) Re-check the 20 existing source files against the
            unchanged docs/source_guard_baseline.csv (read only).
            (b) Hash the three new 2023-2025 files (s21 s22 s23) against a
            separate baseline docs/source_guard_baseline_new.csv, which is
            created ONLY when the OS env var PDD_APPROVE_NEW_BASELINE=1 is
            set and the file is absent. Without approval the program writes
            a proposal and stops with PENDING DECISION.
  Inputs  : docs/source_guard_baseline.csv (read only)
            docs/new_source_files.csv
            &raw_master\<new files> (read only, certutil SHA-256)
  Outputs : docs/source_guard_baseline_new.csv (approved run only)
            &qc_path\new_source_hashes_proposed.csv (unapproved first run)
            &exchange_path\new_source_guard.csv (every branch)
  Run     : standalone first. Never seeds without approval.
            Approve with: sas.exe ... -set PDD_APPROVE_NEW_BASELINE 1
==========================================================================*/

/* ============================================================
   SECTION 0 -- %include, %pdd_lib
   ============================================================ */

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;


/* ============================================================
   SECTION 1 -- Utility macros
   ============================================================ */

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\15a_new_source_guard.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

%macro fail_out(msg=);
  %put ERROR: [15a_new_source_guard] &msg;
  %abort cancel;
%mend fail_out;

%macro _note_written_ds(ds=, label=);
  %local _nw;
  %let _nw = 0;
  %if %sysfunc(exist(&ds)) %then %do;
    proc sql noprint;
      select count(*) into :_nw trimmed from &ds;
    quit;
    %if &_nw > 0 %then
      %put NOTE: [15a_new_source_guard] &label written (&_nw rows);
    %else
      %put WARNING: [15a_new_source_guard] &label written but has 0 rows;
  %end;
  %else
    %put WARNING: [15a_new_source_guard] &label was NOT written;
%mend _note_written_ds;


/* ============================================================
   SECTION 2 -- Preconditions
   ============================================================ */

%check_encoding;
%check_pdd_lib;
%route_log;

%put NOTE: [15a_new_source_guard] === Phase 15 plan 01 starting ===;
%put NOTE: [15a_new_source_guard] raw_master = &raw_master;
%put NOTE: [15a_new_source_guard] out_root   = &out_root;


/* ============================================================
   SECTION 3 -- 20-file check, unchanged baseline (read only)
   ============================================================ */

%macro p15a_old_guard;
  %local _p15a_old_base _n_old_list;
  %let _p15a_old_base = C:\data_dictionary\docs\source_guard_baseline.csv;
  %let _n_old_list = 0;

  %if not %sysfunc(fileexist(&_p15a_old_base)) %then %do;
    %fail_out(msg=%str(p15a_old_guard: baseline not found (&_p15a_old_base)));
  %end;

  data work.p15a_old_list;
    length s_code $4 filename $200 full_path $500;
    infile "&_p15a_old_base" dsd dlm=',' firstobs=2 truncover lrecl=500;
    input s_code $ filename $ @;
    full_path = cats("&raw_master.\", strip(filename));
    file_id + 1;
  run;

  proc sql noprint;
    select count(*) into :_n_old_list trimmed from work.p15a_old_list;
  quit;
  %if &_n_old_list ne 20 %then
    %fail_out(msg=%str(p15a_old_guard: file list has &_n_old_list rows from baseline -- expected 20));

  data work.p15a_old_sha;
    set work.p15a_old_list(keep=file_id s_code filename full_path);
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
      put 'WARNING: [15a_new_source_guard] SHA-256 FAILED for ' s_code=;
    keep file_id s_code filename sha256;
  run;

  data work.p15a_old_base;
    length s_code $4 filename $200 sha256_base $64;
    infile "&_p15a_old_base" dsd dlm=',' firstobs=2 truncover lrecl=500;
    input s_code $ filename $ sha256_base $;
  run;

  %local _n_base _n_curr _n_dup_base _n_dup_curr
         _n_only_base _n_only_curr _n_fname _n_sha;
  %let _n_base = -1; %let _n_curr = -1;
  %let _n_dup_base = -1; %let _n_dup_curr = -1;
  %let _n_only_base = -1; %let _n_only_curr = -1;
  %let _n_fname = -1; %let _n_sha = -1;

  proc sql noprint;
    select count(*) into :_n_base trimmed from work.p15a_old_base;
    select count(*) into :_n_curr trimmed from work.p15a_old_sha;
    select count(*) into :_n_dup_base trimmed
      from (select s_code from work.p15a_old_base
            group by s_code having count(*) > 1);
    select count(*) into :_n_dup_curr trimmed
      from (select s_code from work.p15a_old_sha
            group by s_code having count(*) > 1);
    select count(*) into :_n_only_base trimmed
      from work.p15a_old_base b
      where not exists (select 1 from work.p15a_old_sha r
                        where upcase(strip(r.s_code)) = upcase(strip(b.s_code)));
    select count(*) into :_n_only_curr trimmed
      from work.p15a_old_sha r
      where not exists (select 1 from work.p15a_old_base b
                        where upcase(strip(b.s_code)) = upcase(strip(r.s_code)));
    select count(*) into :_n_fname trimmed
      from work.p15a_old_base b
      inner join work.p15a_old_sha r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.filename)) ne lowcase(strip(r.filename));
    select count(*) into :_n_sha trimmed
      from work.p15a_old_base b
      inner join work.p15a_old_sha r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.sha256_base)) ne lowcase(strip(r.sha256));
  quit;

  %put NOTE: [15a_new_source_guard] p15a_old_guard: n_baseline=&_n_base n_current=&_n_curr n_dup_base=&_n_dup_base n_dup_curr=&_n_dup_curr n_only_base=&_n_only_base n_only_curr=&_n_only_curr n_fname_mismatch=&_n_fname n_sha_mismatch=&_n_sha;

  %if &_n_base      = -1 %then %fail_out(msg=%str(p15a_old_guard: baseline count query failed));
  %if &_n_curr      = -1 %then %fail_out(msg=%str(p15a_old_guard: current-scan count query failed));
  %if &_n_dup_base  = -1 %then %fail_out(msg=%str(p15a_old_guard: dup_base query failed));
  %if &_n_dup_curr  = -1 %then %fail_out(msg=%str(p15a_old_guard: dup_curr query failed));
  %if &_n_only_base = -1 %then %fail_out(msg=%str(p15a_old_guard: only_base query failed));
  %if &_n_only_curr = -1 %then %fail_out(msg=%str(p15a_old_guard: only_curr query failed));
  %if &_n_fname     = -1 %then %fail_out(msg=%str(p15a_old_guard: fname query failed));
  %if &_n_sha       = -1 %then %fail_out(msg=%str(p15a_old_guard: sha query failed));

  %if &_n_base ne 20 %then
    %fail_out(msg=%str(p15a_old_guard: baseline has &_n_base rows -- expected 20));
  %if &_n_curr ne 20 %then
    %fail_out(msg=%str(p15a_old_guard: current scan has &_n_curr rows -- expected 20));
  %if &_n_dup_base > 0 %then
    %fail_out(msg=%str(p15a_old_guard: &_n_dup_base duplicate s_code(s) in baseline));
  %if &_n_dup_curr > 0 %then
    %fail_out(msg=%str(p15a_old_guard: &_n_dup_curr duplicate s_code(s) in current scan));
  %if &_n_only_base > 0 %then
    %fail_out(msg=%str(p15a_old_guard: &_n_only_base s_code(s) in baseline not found in current scan));
  %if &_n_only_curr > 0 %then
    %fail_out(msg=%str(p15a_old_guard: &_n_only_curr s_code(s) in current scan not found in baseline));
  %if &_n_fname > 0 %then
    %fail_out(msg=%str(p15a_old_guard: &_n_fname filename(s) changed since baseline));
  %if &_n_sha > 0 %then
    %fail_out(msg=%str(SOURCE GUARD FAILED -- &_n_sha file(s) changed since the 20-file baseline. Do not edit or delete docs/source_guard_baseline.csv (NEW-01) - investigate first.));

  %put NOTE: [15a_new_source_guard] PASS -- all 20 SHA-256 values and filenames match docs/source_guard_baseline.csv (unchanged);

  proc datasets lib=work nolist nowarn;
    delete p15a_old_list p15a_old_sha p15a_old_base;
  quit;
%mend p15a_old_guard;


/* ============================================================
   SECTION 4 -- Load the three-file list
   ============================================================ */

%macro p15a_load_new_list;
  %local _n_files _n_codes _n_wl _n_utf _n_missing _miss_list;
  %let _n_files = 0; %let _n_codes = 0; %let _n_wl = 0;
  %let _n_utf = 0; %let _n_missing = 0; %let _miss_list = ;

  %if not %sysfunc(fileexist(C:\data_dictionary\docs\new_source_files.csv)) %then
    %fail_out(msg=%str(p15a_load_new_list: docs/new_source_files.csv not found));

  data work.p15a_files;
    length s_code $4 filename $200 ftype $5 src_encoding $10
           expected_rows 8 expected_cols 8 expected_distinct_psid 8
           full_path $500;
    infile "C:\data_dictionary\docs\new_source_files.csv" dsd dlm=','
           firstobs=2 truncover lrecl=500;
    input s_code $ filename $ ftype $ src_encoding $
          expected_rows expected_cols expected_distinct_psid;
    full_path = cats("&raw_master.\", strip(filename));
    file_id + 1;
    file_ok = fileexist(full_path);
  run;

  proc sql noprint;
    select count(*) into :_n_files trimmed from work.p15a_files;
    select count(*) into :_n_codes trimmed from work.p15a_files
      where s_code in ('s21', 's22', 's23');
    select count(*) into :_n_wl trimmed from work.p15a_files
      where src_encoding = 'wlatin1';
    select count(*) into :_n_utf trimmed from work.p15a_files
      where src_encoding = 'utf-8';
    select count(*) into :_n_missing trimmed from work.p15a_files
      where file_ok = 0;
  quit;

  %if &_n_files ne 3 %then
    %fail_out(msg=%str(p15a_load_new_list: new_source_files.csv has &_n_files rows -- expected 3));
  %if &_n_codes ne 3 %then
    %fail_out(msg=%str(p15a_load_new_list: s_codes are not exactly s21 s22 s23));
  %if &_n_wl ne 2 %then
    %fail_out(msg=%str(p15a_load_new_list: &_n_wl wlatin1 rows -- expected 2));
  %if &_n_utf ne 1 %then
    %fail_out(msg=%str(p15a_load_new_list: &_n_utf utf-8 rows -- expected 1));
  %if &_n_missing > 0 %then %do;
    proc sql noprint;
      select s_code into :_miss_list separated by ' ' from work.p15a_files
        where file_ok = 0;
    quit;
    %fail_out(msg=%str(p15a_load_new_list: &_n_missing new file(s) not found in raw_master: &_miss_list));
  %end;

  %put NOTE: [15a_new_source_guard] work.p15a_files built (&_n_files rows, all files present);
%mend p15a_load_new_list;


/* ============================================================
   SECTION 5 -- SHA-256 of the three new files
   ============================================================ */

%macro p15a_hash_new;
  %local _n_failed;
  %let _n_failed = 0;

  data work.p15a_new_sha;
    set work.p15a_files(keep=file_id s_code filename full_path);
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
      put 'WARNING: [15a_new_source_guard] SHA-256 FAILED for ' s_code=;
    keep s_code filename sha256;
  run;

  proc sql noprint;
    select count(*) into :_n_failed trimmed from work.p15a_new_sha
      where sha256 = 'FAILED';
  quit;
  %if &_n_failed > 0 %then
    %fail_out(msg=%str(p15a_hash_new: &_n_failed new file(s) could not be hashed));
  %put NOTE: [15a_new_source_guard] work.p15a_new_sha built;
%mend p15a_hash_new;


/* ============================================================
   SECTION 6 -- Approval-gated new-file baseline
   ============================================================ */

/* Write work.p15a_status to a CSV. withstatus=1 adds baseline_status. */
%macro p15a_write_csv(out=, withstatus=0);
  %if &withstatus = 1 %then %do;
    data _null_;
      set work.p15a_status;
      file "&out" lrecl=500;
      length _line $500;
      if _n_ = 1 then put 's_code,filename,sha256,baseline_status';
      _line = catx(',', strip(s_code), strip(filename), strip(sha256), strip(baseline_status));
      put _line;
    run;
  %end;
  %else %do;
    data _null_;
      set work.p15a_status;
      file "&out" lrecl=500;
      length _line $500;
      if _n_ = 1 then put 's_code,filename,sha256';
      _line = catx(',', strip(s_code), strip(filename), strip(sha256));
      put _line;
    run;
  %end;
%mend p15a_write_csv;

%macro p15a_new_guard;
  %local _bp _approve _n_base_rows _n_base _n_curr _n_dup_base _n_dup_curr
         _n_only_base _n_only_curr _n_fname _n_sha _n_drift _n_check;
  %let _bp = C:\data_dictionary\docs\source_guard_baseline_new.csv;
  %let _approve = 0;
  %let _n_base_rows = 0;

  %if %sysfunc(envlen(PDD_APPROVE_NEW_BASELINE)) > 0 %then %do;
    %if "%sysget(PDD_APPROVE_NEW_BASELINE)" = "1" %then %let _approve = 1;
  %end;

  %if %sysfunc(fileexist(&_bp)) %then %do;
    data _null_;
      retain _cnt 0;
      infile "&_bp" dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
      input;
      _cnt + 1;
      if _eof then call symputx('_n_base_rows', _cnt, 'L');
    run;
  %end;

  %if &_n_base_rows = 0 %then %do;
    /* ---- No baseline yet: seed only on explicit approval ---- */
    data work.p15a_status;
      set work.p15a_new_sha;
      length baseline_status $8;
      baseline_status = 'PROPOSED';
    run;

    %if &_approve = 1 %then %do;
      /* Branch A: approved seed */
      data work.p15a_status;
        set work.p15a_status;
        baseline_status = 'SEEDED';
      run;
      %p15a_write_csv(out=&_bp, withstatus=0);
      %let _n_check = 0;
      data _null_;
        retain _cnt 0;
        infile "&_bp" dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
        input;
        _cnt + 1;
        if _eof then call symputx('_n_check', _cnt, 'L');
      run;
      %if &_n_check ne 3 %then
        %fail_out(msg=%str(p15a_new_guard: seeded baseline has &_n_check rows -- expected 3));
      %p15a_write_csv(out=&exchange_path.\new_source_guard.csv, withstatus=1);
      %put NOTE: [15a_new_source_guard] new baseline seeded by explicit approval (PDD_APPROVE_NEW_BASELINE=1) -- commit docs/source_guard_baseline_new.csv;
    %end;
    %else %do;
      /* Branch B: proposal only, then stop */
      %p15a_write_csv(out=&qc_path.\new_source_hashes_proposed.csv, withstatus=0);
      %p15a_write_csv(out=&exchange_path.\new_source_guard.csv, withstatus=1);
      %fail_out(msg=%str(PENDING DECISION -- new-file baseline not approved. Review qc new_source_hashes_proposed.csv then rerun with PDD_APPROVE_NEW_BASELINE=1 (NEW-01)));
    %end;
  %end;
  %else %do;
    /* Branch C: baseline exists, compare; never overwrite */
    %if &_approve = 1 %then
      %put NOTE: [15a_new_source_guard] approval flag ignored -- baseline already exists and is never overwritten;

    data work.p15a_new_base;
      length s_code $4 filename $200 sha256_base $64;
      infile "&_bp" dsd dlm=',' firstobs=2 truncover lrecl=500;
      input s_code $ filename $ sha256_base $;
    run;

    proc sql noprint;
      create table work.p15a_status as
        select r.s_code, r.filename, r.sha256,
               case when lowcase(strip(b.sha256_base)) = lowcase(strip(r.sha256))
                     and lowcase(strip(b.filename)) = lowcase(strip(r.filename))
                    then 'MATCH' else 'DRIFT' end as baseline_status length=8
        from work.p15a_new_sha r
        left join work.p15a_new_base b
          on upcase(strip(b.s_code)) = upcase(strip(r.s_code));
    quit;

    %p15a_write_csv(out=&exchange_path.\new_source_guard.csv, withstatus=1);

    %let _n_base = -1; %let _n_curr = -1;
    %let _n_dup_base = -1; %let _n_dup_curr = -1;
    %let _n_only_base = -1; %let _n_only_curr = -1;
    %let _n_fname = -1; %let _n_sha = -1; %let _n_drift = -1;

    proc sql noprint;
      select count(*) into :_n_base trimmed from work.p15a_new_base;
      select count(*) into :_n_curr trimmed from work.p15a_new_sha;
      select count(*) into :_n_dup_base trimmed
        from (select s_code from work.p15a_new_base
              group by s_code having count(*) > 1);
      select count(*) into :_n_dup_curr trimmed
        from (select s_code from work.p15a_new_sha
              group by s_code having count(*) > 1);
      select count(*) into :_n_only_base trimmed
        from work.p15a_new_base b
        where not exists (select 1 from work.p15a_new_sha r
                          where upcase(strip(r.s_code)) = upcase(strip(b.s_code)));
      select count(*) into :_n_only_curr trimmed
        from work.p15a_new_sha r
        where not exists (select 1 from work.p15a_new_base b
                          where upcase(strip(b.s_code)) = upcase(strip(r.s_code)));
      select count(*) into :_n_fname trimmed
        from work.p15a_new_base b
        inner join work.p15a_new_sha r
          on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
        where lowcase(strip(b.filename)) ne lowcase(strip(r.filename));
      select count(*) into :_n_sha trimmed
        from work.p15a_new_base b
        inner join work.p15a_new_sha r
          on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
        where lowcase(strip(b.sha256_base)) ne lowcase(strip(r.sha256));
      select count(*) into :_n_drift trimmed from work.p15a_status
        where baseline_status = 'DRIFT';
    quit;

    %put NOTE: [15a_new_source_guard] p15a_new_guard: n_baseline=&_n_base n_current=&_n_curr n_dup_base=&_n_dup_base n_dup_curr=&_n_dup_curr n_only_base=&_n_only_base n_only_curr=&_n_only_curr n_fname_mismatch=&_n_fname n_sha_mismatch=&_n_sha n_drift=&_n_drift;

    %if &_n_base = -1 or &_n_curr = -1 or &_n_dup_base = -1 or &_n_dup_curr = -1
        or &_n_only_base = -1 or &_n_only_curr = -1 or &_n_fname = -1
        or &_n_sha = -1 or &_n_drift = -1 %then
      %fail_out(msg=%str(p15a_new_guard: a comparison query failed));
    %if &_n_base ne 3 %then
      %fail_out(msg=%str(p15a_new_guard: new baseline has &_n_base rows -- expected 3));
    %if &_n_curr ne 3 %then
      %fail_out(msg=%str(p15a_new_guard: current scan has &_n_curr rows -- expected 3));
    %if &_n_dup_base > 0 %then
      %fail_out(msg=%str(p15a_new_guard: &_n_dup_base duplicate s_code(s) in new baseline));
    %if &_n_dup_curr > 0 %then
      %fail_out(msg=%str(p15a_new_guard: &_n_dup_curr duplicate s_code(s) in current scan));
    %if &_n_only_base > 0 or &_n_only_curr > 0 %then
      %fail_out(msg=%str(p15a_new_guard: s_code sets differ between new baseline and current scan));
    %if &_n_drift > 0 %then
      %fail_out(msg=%str(NEW SOURCE GUARD FAILED -- &_n_drift new file(s) changed since the approved baseline. Do not delete docs/source_guard_baseline_new.csv - investigate - PENDING DECISION.));

    %put NOTE: [15a_new_source_guard] PASS -- all 3 new-file SHA-256 values match docs/source_guard_baseline_new.csv;
  %end;

  proc datasets lib=work nolist nowarn;
    delete p15a_new_base p15a_status;
  quit;
%mend p15a_new_guard;


/* ============================================================
   SECTION 7 -- Run
   ============================================================ */

%p15a_old_guard;
%p15a_load_new_list;
%p15a_hash_new;
%p15a_new_guard;
%restore_log;
