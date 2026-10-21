/* Quick smoke-test: run pipeline with PDD_PHASES=3 but stub out Phase 3 include.
   Verifies: pdd libref assigned, hash guard PASS, "Phase 3 would run" note.
   Run with:
     sas -sysin "C:\data_dictionary\sas\test_phase3_skip.sas" -set PDD_PHASES 3
       -log "P:\PeCAN Master Data\Gerard\data_dictionary\logs\test_phase3_skip.log"
   Expected NOTE lines in log:
     NOTE: [00_config] pdd libref assigned ...
     NOTE: [02_source_guard] PASS -- all 20 SHA-256 values and filenames match baseline
     NOTE: Phase 3 would run (stub) */
options mprint nofmterr nodate nonumber ps=max ls=200;
%include "C:\data_dictionary\sas\00_config.sas";
%let in_pipeline = 1;

%pdd_lib;
%check_encoding;
%check_pdd_lib;

%macro _phase_in(n);
  %if %sysfunc(indexw(&pdd_phases_run, &n)) > 0 %then 1;
  %else 0;
%mend _phase_in;

/* ---- full run_hash_guard from 99_run_all ---- */
%macro run_hash_guard;
  %local _baseline_path _n_base_rows;
  %let _baseline_path = C:\data_dictionary\docs\source_guard_baseline.csv;
  %let _n_base_rows = 0;
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
  %put NOTE: [99_run_all] run_hash_guard: work.file_list built;
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
      put 'WARNING: [99_run_all] SHA-256 FAILED for ' full_path=;
    keep file_id s_code filename sha256;
  run;
  %put NOTE: [99_run_all] run_hash_guard: work.sha_results built;
  %if %sysfunc(fileexist(&_baseline_path)) %then %do;
    data _null_;
      retain _cnt 0;
      infile "&_baseline_path" dsd dlm=',' firstobs=2 truncover lrecl=500 end=_eof;
      input;
      _cnt + 1;
      if _eof then call symputx('_n_base_rows', _cnt, 'L');
    run;
  %end;
  %if &_n_base_rows = 0 %then %do;
    %put ERROR: [99_run_all] run_hash_guard: baseline not found or empty;
    %abort cancel;
  %end;
  data work._hg_baseline;
    length s_code $4 filename $200 sha256_base $64;
    infile "&_baseline_path" dsd dlm=',' firstobs=2 truncover lrecl=500;
    input s_code $ filename $ sha256_base $;
  run;
  %local _n_base _n_curr _n_dup_base _n_dup_curr
         _n_only_base _n_only_curr _n_fname _n_sha;
  %let _n_base = -1; %let _n_curr = -1;
  %let _n_dup_base = -1; %let _n_dup_curr = -1;
  %let _n_only_base = -1; %let _n_only_curr = -1;
  %let _n_fname = -1; %let _n_sha = -1;
  proc sql noprint;
    select count(*) into :_n_base     trimmed from work._hg_baseline;
    select count(*) into :_n_curr     trimmed from work.sha_results;
    select count(*) into :_n_dup_base trimmed
      from (select s_code from work._hg_baseline group by s_code having count(*) > 1);
    select count(*) into :_n_dup_curr trimmed
      from (select s_code from work.sha_results  group by s_code having count(*) > 1);
    select count(*) into :_n_only_base trimmed
      from work._hg_baseline b
      where not exists (select 1 from work.sha_results r
                        where upcase(strip(r.s_code)) = upcase(strip(b.s_code)));
    select count(*) into :_n_only_curr trimmed
      from work.sha_results r
      where not exists (select 1 from work._hg_baseline b
                        where upcase(strip(b.s_code)) = upcase(strip(r.s_code)));
    select count(*) into :_n_fname trimmed
      from work._hg_baseline b inner join work.sha_results r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.filename)) ne lowcase(strip(r.filename));
    select count(*) into :_n_sha trimmed
      from work._hg_baseline b inner join work.sha_results r
        on upcase(strip(b.s_code)) = upcase(strip(r.s_code))
      where lowcase(strip(b.sha256_base)) ne lowcase(strip(r.sha256));
  quit;
  %put NOTE: [99_run_all] run_hash_guard: n_baseline=&_n_base n_current=&_n_curr n_sha_mismatch=&_n_sha;
  %if &_n_sha > 0 %then
    %fail_out(msg=%str(SOURCE GUARD FAILED -- &_n_sha file(s) changed since baseline));
  %put NOTE: [02_source_guard] PASS -- all 20 SHA-256 values and filenames match baseline;
  proc datasets lib=work nolist nowarn; delete _hg_baseline file_list sha_results; quit;
%mend run_hash_guard;

%macro _init_phases;
  %global pdd_phases_run pdd_full_run;
  %local _raw;
  %let _raw = %sysfunc(translate(%sysget(PDD_PHASES), %str( ), %str(,)));
  %let _raw = %sysfunc(compbl(%superq(_raw)));
  %if %length(%superq(_raw)) = 0 %then %do;
    %let pdd_phases_run = 2 3;
    %let pdd_full_run = 1;
  %end;
  %else %do;
    %let pdd_phases_run = &_raw;
    %let pdd_full_run = 0;
  %end;
  %put NOTE: [test] PDD_PHASES parsed=&pdd_phases_run;
%mend _init_phases;
%_init_phases;

/* Phase 2 skip path */
%if not %_phase_in(2) %then %do;
  %put NOTE: [test] Phase 2 skipped -- running hash guard;
  %run_hash_guard;
%end;

/* Phase 3 stub */
%if %_phase_in(3) %then
  %put NOTE: Phase 3 would run (stub);
