/**============================================================================
  probe_inputs.sas  -  privacy-safe schema probe of the PeCAN Master Data folder
  Project : PeCAN Data Dictionary (PDD), repo C:\data_dictionary
  Purpose : Give the Claude Code machine (no P:, no SAS) the facts it needs about
            the source files without moving any data off P:.
  Output  : <repo>\.planning\schemas\probe_master_data_<yyyymmdd>.md

  What is written (and what is not)
    - Per file / sheet: rows, all-blank rows, columns, encoding guess (CSV byte
      scan: lines with non-ASCII bytes, and how many are not valid UTF-8).
    - Per column: SAS name, original header, type, length, format, non-missing
      count, number of distinct levels, count of candidate placeholder values
      (?, Unknown, NULL, -999 ...), first-last year for date-formatted columns.
    - Per ID-like column (name matches &id_regex): non-missing rows, distinct
      values, whether it is 1 row per value, overlap with the current spine's
      case IDs and encrypted MRNs (from &spine_file), and value SHAPES only
      (9 = digit, A = letter; long tokens as length + character class).
    - Counts from 1 to 10 are shown as <11. No data values are ever written.

  Reads the source folder read-only. Writes only to work and to the repo's
  .planning\schemas folder. Run on the SAS machine, then commit the .md file:
      git add .planning/schemas/probe_master_data_<yyyymmdd>.md
      git commit -m "probe: Master Data folder schema"
      git push
============================================================================*/

options validvarname=any nofmterr mprint;

/*---------------------------------------------------------------------------
  0. Parameters
---------------------------------------------------------------------------*/
%let src_dir   = P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data;
%let repo_dir  = C:\data_dictionary;

/* Regex on file names to probe. "." = every .csv/.xlsx/.xls in the folder.  */
/* Example to probe only the new deliveries: 2023|2024|2025                   */
%let file_regex = .;

/* Spine for linkage overlap: a CSV in the same folder (blank = skip).        */
/* The 2018-2022 spine is the reference for 2023-2025 overlap.                */
/* Spine columns are found by regex on the imported column names.             */
%let spine_file    = 2018_2022_X_MASTER_DATASET_20240402.csv;
%let spine_case_rx = ^PRECEDE.?STUDY.?ID$;
%let spine_mrn_rx  = ENCRYPTED.?MRN;

%let min_cell = 11;
%let id_regex = PRECEDE|MRN|ENCOUNTER|STUDY_?ID|PCNR_ID|PECAN|(^|_| )ID$;
%let ph_char  = '?','UNKNOWN','UNK','NULL','N/A','NA','NONE','MISSING','-999','-99','-9','.','#N/A','NAN';
%let ph_num   = -9999, -999, -99, -9, 999, 9999;

%let run_date = %sysfunc(today(), yymmddn8.);
%let out_md   = &repo_dir.\.planning\schemas\probe_master_data_&run_date..md;

%macro init_globals();
  %global unit enc n_lines n_hi n_bad cur_sheet cur_path nblank have_spine nfiles spine_case spine_mrn;
  %let unit = 0;
  %let nblank = 0;
  %let have_spine = 0;
  %let nfiles = 0;
  %let spine_case = ;
  %let spine_mrn = ;
%mend init_globals;
%init_globals()

/* Text-only header strings and timestamps (kept out of DATA step / PUT text) */
%let gen_ts    = %sysfunc(today(), yymmdd10.) %sysfunc(time(), time5.);
%let max_small = %eval(&min_cell - 1);
%let id_hdr    = ID-like columns;
%let top_lbl   = top;
%let shp_hdr   = ID value shapes (&top_lbl 5 per column);
%let b64_lbl   = base64-like;

/*---------------------------------------------------------------------------
  1. Guard: output must go to the repo, never to P:
---------------------------------------------------------------------------*/
%macro guard();
  %if %upcase(%substr(%superq(repo_dir), 1, 2)) = %str(P:) %then %do;
    %put ERROR: [probe] repo_dir is on P: - the probe writes only to the git repo.;
    %abort cancel;
  %end;
  %if not %sysfunc(fileexist(%superq(repo_dir)\.planning)) %then %do;
    %put ERROR: [probe] &repo_dir.\.planning not found - check repo_dir.;
    %abort cancel;
  %end;
%mend guard;
%guard()

data _null_;
  length __p $400;
  __p = dcreate('schemas', "&repo_dir.\.planning");
run;

/*---------------------------------------------------------------------------
  2. Result shells
---------------------------------------------------------------------------*/
data r_units;
  length unit 8 file $260 sheet $100 ext $8 size_bytes 8 modified $40 enc $16
         n_lines n_hi n_bad nrows nblank ncols 8 status $120;
  stop;
run;
data r_cols;
  length unit varnum 8 name $64 header $256 type $4 len 8 fmt $32
         n_nonmiss n_levels n_ph y_min y_max is_id 8;
  stop;
run;
data r_ids;
  length unit 8 name $64 n_rows n_distinct n_in_case n_in_mrn 8;
  stop;
run;
data r_pat;
  length unit 8 name $64 pattern $80 n rank 8;
  stop;
run;


/*---------------------------------------------------------------------------
  4. List files in the source folder (read-only)
---------------------------------------------------------------------------*/
filename _dir "&src_dir";

data _files(keep=file ext size_bytes modified);
  length file $260 ext $8 modified $40 __fr $8 __full $400;
  size_bytes = .;
  __did = dopen('_dir');
  if __did <= 0 then do;
    put "ERROR: [probe] cannot open folder &src_dir";
    stop;
  end;
  do __k = 1 to dnum(__did);
    file = dread(__did, __k);
    ext = lowcase(scan(file, -1, '.'));
    modified = ' ';
    size_bytes = .;
    if ext in ('csv', 'xlsx', 'xls') and substr(file, 1, 2) ne '~$'
       and prxmatch("/&file_regex/i", strip(file)) then do;
      __full = catx('\', "&src_dir", file);
      __fr = ' ';
      __rc = filename(__fr, __full);
      __fid = fopen(__fr);
      if __fid > 0 then do;
        modified = finfo(__fid, 'Last Modified');
        size_bytes = input(finfo(__fid, 'File Size (bytes)'), ?? best32.);
        __rc = fclose(__fid);
      end;
      __rc = filename(__fr);
      output;
    end;
  end;
  __rc = dclose(__did);
run;

filename _dir clear;

proc sort data=_files;
  by file;
run;

proc sql noprint;
  select file, ext into :f1-, :e1- from _files;
quit;
%let nfiles = &sqlobs;
%put NOTE: [probe] &nfiles file(s) to probe in &src_dir;

/*---------------------------------------------------------------------------
  5. Byte scan of a CSV: non-ASCII lines and lines that are not valid UTF-8
---------------------------------------------------------------------------*/
%macro scan_bytes();
  %let n_lines = 0;
  %let n_hi = 0;
  %let n_bad = 0;
  %let enc = utf-8;
  filename _raw "&cur_path" encoding='any' lrecl=32767;
  data _null_;
    infile _raw end=__eof;
    input;
    length __l __s $32767;
    retain __rx;
    if _n_ = 1 then
      __rx = prxparse('s/\xEF\xBB\xBF|[\xC2-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF]{2}|[\xF0-\xF4][\x80-\xBF]{3}//');
    __l = _infile_;
    __n + 1;
    if prxmatch('/[\x80-\xFF]/', __l) then do;
      __h + 1;
      __s = prxchange(__rx, -1, __l);
      if prxmatch('/[\x80-\xFF]/', __s) then __b + 1;
    end;
    if __eof then do;
      call symputx('n_lines', __n, 'G');
      call symputx('n_hi', __h, 'G');
      call symputx('n_bad', __b, 'G');
      call symputx('enc', ifc(__b > 0, 'wlatin1', 'utf-8'), 'G');
    end;
  run;
  filename _raw clear;
%mend scan_bytes;

/*---------------------------------------------------------------------------
  5b. Spine: distinct case IDs and encrypted MRNs from &spine_file (work only)
---------------------------------------------------------------------------*/
%macro prep_spine();
  %local sc sm;
  %let have_spine = 0;
  %let sc = ;
  %let sm = ;
  %if %length(%superq(spine_file)) = 0 %then %return;
  %let cur_path = %superq(src_dir)\%superq(spine_file);
  %if not %sysfunc(fileexist(%superq(cur_path))) %then %do;
    %put WARNING: [probe] spine file &spine_file not found - linkage skipped.;
    %return;
  %end;
  %scan_bytes
  filename _spf "&cur_path" encoding="&enc";
  proc import datafile=_spf out=work._spsrc dbms=csv replace;
    guessingrows=max;
    getnames=yes;
  run;
  filename _spf clear;
  %if not %sysfunc(exist(work._spsrc)) %then %do;
    %put WARNING: [probe] spine file did not import - linkage skipped.;
    %return;
  %end;
  proc sql noprint;
    select name into :sc trimmed from dictionary.columns
      where libname = 'WORK' and memname = '_SPSRC' and prxmatch("/&spine_case_rx/i", strip(name)) > 0;
    select name into :sm trimmed from dictionary.columns
      where libname = 'WORK' and memname = '_SPSRC' and prxmatch("/&spine_mrn_rx/i", strip(name)) > 0;
  quit;
  %if %length(%superq(sc)) = 0 or %length(%superq(sm)) = 0 %then %do;
    %put WARNING: [probe] spine case or MRN column not found (case=&sc mrn=&sm) - linkage skipped.;
    %return;
  %end;
  %let spine_case = %superq(sc);
  %let spine_mrn = %superq(sm);
  data _spc0(keep=v);
    set _spsrc(keep="&sc"n);
    length v $200 __t $200;
    __t = strip(cats("&sc"n));
    if missing(__t) then delete;
    if prxmatch('/^\d{1,5}$/', strip(__t)) then v = cats('Precede', put(input(strip(__t), 8.), z5.));
    else v = __t;
  run;
  data _spm0(keep=v);
    set _spsrc(keep="&sm"n);
    length v $200;
    v = strip(cats("&sm"n));
    if missing(v) then delete;
  run;
  proc sql;
    create table _spc as select distinct v from _spc0;
    create table _spm as select distinct v from _spm0;
  quit;
  proc datasets lib=work nolist nowarn;
    delete _spsrc _spc0 _spm0;
  quit;
  %let have_spine = 1;
  %put NOTE: [probe] spine &spine_file: case column=&sc, MRN column=&sm;
%mend prep_spine;
%prep_spine()

/*---------------------------------------------------------------------------
  6. One row per file/sheet in r_units
---------------------------------------------------------------------------*/
%macro unit_row(status);
  data _u;
    length unit 8 file $260 sheet $100 ext $8 size_bytes 8 modified $40 enc $16
           n_lines n_hi n_bad nrows nblank ncols 8 status $120;
    set _files(firstobs=&i obs=&i keep=file ext size_bytes modified);
    unit    = &unit;
    sheet   = symget('cur_sheet');
    enc     = symget('enc');
    n_lines = input(symget('n_lines'), ?? best32.);
    n_hi    = input(symget('n_hi'), ?? best32.);
    n_bad   = input(symget('n_bad'), ?? best32.);
    nblank  = input(symget('nblank'), ?? best32.);
    if exist('work._p') then do;
      __dsid = open('work._p');
      nrows  = attrn(__dsid, 'NLOBS');
      ncols  = attrn(__dsid, 'NVARS');
      __rc   = close(__dsid);
    end;
    status = "&status";
    drop __:;
  run;
  proc append base=r_units data=_u force;
  run;
%mend unit_row;

/*---------------------------------------------------------------------------
  7. Profile work._p (one file or sheet)
---------------------------------------------------------------------------*/
%macro profile(i);
  %local nc nidv asz;
  %let unit = %eval(&unit + 1);
  %let nblank = 0;

  %if not %sysfunc(exist(work._p)) %then %do;
    %unit_row(IMPORT FAILED - see SAS log)
    %return;
  %end;

  proc contents data=_p out=_ct(keep=name type length format label varnum) noprint;
  run;
  proc sql noprint;
    select count(*) into :nc trimmed from _ct;
  quit;
  %let asz = %eval(&nc + 2);

  /* Counts per column, ID values to work only, blank rows */
  data _cnt(keep=__name __nn __np __y0 __y1 __isid)
       _idv(keep=__name __v)
       _rowinfo(keep=__nrows __nblank);
    set _p end=__eof;
    length _zc $1;
    _zn = .;
    array __c{*} _character_;
    array __n{*} _numeric_;
    length __name $64 __v $200 __u $200 __f $32;
    array __kc{&asz} _temporary_;
    array __pc{&asz} _temporary_;
    array __ic{&asz} _temporary_;
    array __kn{&asz} _temporary_;
    array __pn{&asz} _temporary_;
    array __in{&asz} _temporary_;
    array __dk{&asz} _temporary_;
    array __ya{&asz} _temporary_;
    array __yb{&asz} _temporary_;

    if _n_ = 1 then do;
      do __i = 1 to dim(__c);
        __ic{__i} = (prxmatch("/&id_regex/i", strip(vname(__c{__i}))) > 0);
      end;
      do __i = 1 to dim(__n);
        __in{__i} = (prxmatch("/&id_regex/i", strip(vname(__n{__i}))) > 0);
        __f = upcase(vformat(__n{__i}));
        __dk{__i} = 0;
        if prxmatch('/^(DATETIME|E8601DT|DTDATE)/', strip(__f)) then __dk{__i} = 2;
        else if prxmatch('/^(DATE|MMDDYY|YYMMDD|DDMMYY|E8601DA|MONYY|YYMON|WEEKDATE|WORDDATE)/', strip(__f)) then __dk{__i} = 1;
      end;
    end;

    __nblank + (cmiss(of __c{*}) + nmiss(of __n{*}) = dim(__c) + dim(__n));

    do __i = 1 to dim(__c);
      if not missing(__c{__i}) then do;
        __kc{__i} = sum(__kc{__i}, 1);
        __u = upcase(strip(__c{__i}));
        if __u in (&ph_char) then __pc{__i} = sum(__pc{__i}, 1);
        if __ic{__i} = 1 then do;
          __name = vname(__c{__i});
          __v = strip(__c{__i});
          output _idv;
        end;
      end;
    end;

    do __i = 1 to dim(__n);
      if not missing(__n{__i}) then do;
        __kn{__i} = sum(__kn{__i}, 1);
        if __n{__i} in (&ph_num) then __pn{__i} = sum(__pn{__i}, 1);
        __yr = .;
        if __dk{__i} = 1 then __yr = year(__n{__i});
        else if __dk{__i} = 2 then __yr = year(datepart(__n{__i}));
        if not missing(__yr) then do;
          __ya{__i} = min(__ya{__i}, __yr);
          __yb{__i} = max(__yb{__i}, __yr);
        end;
        if __in{__i} = 1 then do;
          __name = vname(__n{__i});
          __v = strip(put(__n{__i}, best32.));
          output _idv;
        end;
      end;
    end;

    if __eof then do;
      __nrows = _n_;
      output _rowinfo;
      do __i = 1 to dim(__c);
        __name = vname(__c{__i});
        if __name ne '_zc' then do;
          __nn = sum(__kc{__i}, 0);
          __np = sum(__pc{__i}, 0);
          __y0 = .;
          __y1 = .;
          __isid = __ic{__i};
          output _cnt;
        end;
      end;
      do __i = 1 to dim(__n);
        __name = vname(__n{__i});
        if __name ne '_zn' then do;
          __nn = sum(__kn{__i}, 0);
          __np = sum(__pn{__i}, 0);
          __y0 = __ya{__i};
          __y1 = __yb{__i};
          __isid = __in{__i};
          output _cnt;
        end;
      end;
    end;
  run;

  proc sql noprint;
    select __nblank into :nblank trimmed from _rowinfo;
  quit;

  /* Distinct levels per column */
  proc freq data=_p nlevels;
    tables _all_ / noprint;
    ods output nlevels=_nl;
  run;
  %if %sysfunc(exist(work._nl)) %then %do;
    data _nl2(keep=__name NLevels);
      set _nl;
      length __name $64;
      __name = TableVar;
    run;
  %end;
  %else %do;
    data _nl2;
      length __name $64 NLevels 8;
      stop;
    run;
  %end;

  proc sql;
    create table _cols as
    select &unit as unit,
           c.varnum,
           c.name length=64,
           translate(coalescec(c.label, c.name), '/', '|') as header length=256,
           case when c.type = 1 then 'Num' else 'Char' end as type length=4,
           c.length as len,
           c.format as fmt length=32,
           k.__nn as n_nonmiss,
           l.NLevels as n_levels,
           k.__np as n_ph,
           k.__y0 as y_min,
           k.__y1 as y_max,
           k.__isid as is_id
    from _ct c
         left join _cnt k on c.name = k.__name
         left join _nl2 l on upcase(c.name) = upcase(l.__name)
    order by c.varnum;
  quit;
  proc append base=r_cols data=_cols force;
  run;

  /* ID columns: distinctness, shapes, spine overlap */
  proc sql noprint;
    select count(*) into :nidv trimmed from _idv;
  quit;
  %if &nidv > 0 %then %do;
    data _idv2;
      set _idv;
      length __vn $200 pattern $80 __t $200;
      __t = strip(__v);
      if prxmatch('/^\d{1,5}$/', strip(__t)) then __vn = cats('Precede', put(input(strip(__t), 8.), z5.));
      else __vn = __t;
      if lengthn(strip(__t)) >= 16 then
        pattern = catx(' ', 'LONG', cats('len=', lengthn(strip(__t))),
                  ifc(prxmatch('/^[0-9]+$/', strip(__t)), 'digits',
                  ifc(prxmatch('/^[0-9A-Fa-f]+$/', strip(__t)), 'hex',
                  ifc(prxmatch('/^[A-Za-z0-9+\/=]+$/', strip(__t)), "&b64_lbl", 'mixed'))));
      else do;
        pattern = prxchange('s/\d/9/', -1, __t);
        pattern = prxchange('s/[A-Za-z]/A/', -1, pattern);
      end;
      drop __t;
    run;

    proc sql;
      create table _pat0 as
      select __name as name length=64, pattern, count(*) as n
      from _idv2
      group by __name, pattern
      order by name, n desc;
    quit;
    data _pat;
      set _pat0;
      by name;
      if first.name then rank = 0;
      rank + 1;
      if rank <= 5;
      unit = &unit;
    run;
    proc append base=r_pat data=_pat force;
    run;

    proc sql;
      create table _ids as
      select &unit as unit, __name as name length=64,
             count(*) as n_rows, count(distinct __v) as n_distinct
      from _idv2
      group by __name;
    quit;

    %if &have_spine = 1 %then %do;
      proc sql;
        create table _lnk as
        select d.__name,
               count(distinct case when c.v is not null then d.__v end) as n_in_case,
               count(distinct case when m.v is not null then d.__v end) as n_in_mrn
        from (select distinct __name, __v, __vn from _idv2) d
             left join _spc c on d.__vn = c.v
             left join _spm m on d.__v = m.v
        group by d.__name;
        create table _ids2 as
        select a.*, b.n_in_case, b.n_in_mrn
        from _ids a left join _lnk b on a.name = b.__name;
      quit;
      proc append base=r_ids data=_ids2 force;
      run;
    %end;
    %else %do;
      data _ids2;
        set _ids;
        n_in_case = .;
        n_in_mrn = .;
      run;
      proc append base=r_ids data=_ids2 force;
      run;
    %end;
  %end;

  %unit_row(OK)

  proc datasets lib=work nolist nowarn;
    delete _ct _cnt _idv _idv2 _rowinfo _nl _nl2 _cols _pat0 _pat _ids _ids2 _lnk _u;
  quit;
%mend profile;

/*---------------------------------------------------------------------------
  8. Import one file (CSV, or each sheet of an XLSX) and profile it
---------------------------------------------------------------------------*/
%macro probe_file(i);
  %local ext nsh s cur_file;
  %let cur_path = %superq(src_dir)\%superq(f&i);
  %let ext = %superq(e&i);
  %let cur_file = %superq(f&i);
  %put NOTE: [probe] file &i of &nfiles: &cur_file;

  proc datasets lib=work nolist nowarn;
    delete _p;
  quit;

  %if %superq(ext) = csv %then %do;
    %let cur_sheet = ;
    %scan_bytes
    filename _src "&cur_path" encoding="&enc";
    proc import datafile=_src out=work._p dbms=csv replace;
      guessingrows=max;
      getnames=yes;
    run;
    filename _src clear;
    %profile(&i)
  %end;
  %else %if %superq(ext) = xlsx %then %do;
    %let enc = xlsx;
    %let n_lines = .;
    %let n_hi = .;
    %let n_bad = .;
    libname _xl xlsx "&cur_path";
    proc sql noprint;
      select memname into :sh1- from dictionary.tables where libname = '_XL';
    quit;
    %let nsh = &sqlobs;
    libname _xl clear;
    %if &nsh = 0 %then %do;
      %let cur_sheet = (no sheets read);
      %profile(&i)
    %end;
    %do s = 1 %to &nsh;
      %let cur_sheet = %superq(sh&s);
      proc datasets lib=work nolist nowarn;
        delete _p;
      quit;
      proc import datafile="&cur_path" out=work._p dbms=xlsx replace;
        sheet="%superq(cur_sheet)";
        getnames=yes;
      run;
      %profile(&i)
    %end;
  %end;
  %else %do;
    %let enc = xls;
    %let n_lines = .;
    %let n_hi = .;
    %let n_bad = .;
    %let cur_sheet = (first sheet);
    proc import datafile="&cur_path" out=work._p dbms=xls replace;
      getnames=yes;
    run;
    %profile(&i)
  %end;
%mend probe_file;

%macro probe_all();
  %local i;
  %do i = 1 %to &nfiles;
    %probe_file(&i)
  %end;
%mend probe_all;
%probe_all()

/*---------------------------------------------------------------------------
  9. Write the markdown (counts 1-10 shown as <11, no values)
---------------------------------------------------------------------------*/
%macro sup(x);
  ifc(missing(&x), '-', ifc(0 < &x < &min_cell, "<&min_cell", strip(put(&x, comma15.))))
%mend sup;

data _null_;
  file "&out_md" encoding='utf-8' lrecl=32767;
  length __enc $40 __sp $300;
  __enc = getoption('encoding');
  if symget('have_spine') = '1' then
    __sp = catx(' ', symget('spine_file'),
                '(case column:', symget('spine_case'), '; MRN column:', symget('spine_mrn'), ')');
  else __sp = 'none (linkage columns show -)';
  put "# Schema probe: Master Data folder";
  put;
  put "- Generated: &gen_ts by sas/probe_inputs.sas";
  put "- Folder: `&src_dir`";
  put "- File filter (regex): `&file_regex`";
  put "- SAS session encoding: " __enc;
  if upcase(__enc) = 'UTF-8' then
    put "- WARNING: session is UTF-8, so the CSV byte scan below may be unreliable.";
  put "- Spine for linkage: " __sp;
  put "- Privacy: no data values are written. Counts from 1 to &max_small are shown as <&min_cell..";
  put "  ID columns are described by value shape only (9 = digit, A = letter; LONG = length and character class).";
  put "- Candidate placeholders counted: character &ph_char; numeric &ph_num";
  put "- Encoding guess: utf-8 = every non-ASCII line is valid UTF-8 (or there are none); wlatin1 = at least one line is not valid UTF-8.";
run;

data _null_;
  set r_units;
  file "&out_md" mod encoding='utf-8' lrecl=32767;
  length __line $2000;
  if _n_ = 1 then do;
    put;
    put "## Files and sheets";
    put;
    put "|unit|file|sheet|rows|all-blank rows|columns|encoding guess|non-ASCII lines|not-UTF-8 lines|modified|status|";
    put "|---|---|---|---|---|---|---|---|---|---|---|";
  end;
  __line = cats('|', unit, '|', translate(strip(file), '/', '|'), '|', translate(strip(sheet), '/', '|'),
                '|', %sup(nrows), '|', %sup(nblank), '|', %sup(ncols), '|', enc,
                '|', %sup(n_hi), '|', %sup(n_bad), '|', modified, '|', status, '|');
  put __line;
run;

proc sort data=r_cols;
  by unit varnum;
run;

data _null_;
  merge r_cols(in=__a) r_units(keep=unit file sheet);
  by unit;
  if __a;
  file "&out_md" mod encoding='utf-8' lrecl=32767;
  length __line $2000 __yr $20;
  if first.unit then do;
    __line = catx(' ', '## Unit', cats(unit, ':'), translate(strip(file), '/', '|'),
                  ifc(missing(sheet), ' ', cats('[sheet=', translate(strip(sheet), '/', '|'), ']')));
    put;
    put __line;
    put;
    put "|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|";
    put "|---|---|---|---|---|---|---|---|---|---|---|";
  end;
  if missing(y_min) then __yr = ' ';
  else __yr = catx('-', y_min, y_max);
  __line = cats('|', varnum, '|', translate(strip(name), '/', '|'), '|', translate(strip(header), '/', '|'),
                '|', type, '|', len, '|', fmt,
                '|', %sup(n_nonmiss),
                '|', ifc(is_id = 1, %sup(n_levels), ifc(missing(n_levels), '-', strip(put(n_levels, comma15.)))),
                '|', %sup(n_ph), '|', __yr, '|', ifc(is_id = 1, 'yes', ' '), '|');
  put __line;
run;

proc sort data=r_ids;
  by unit name;
run;

data _null_;
  set r_ids;
  file "&out_md" mod encoding='utf-8' lrecl=32767;
  length __line $2000;
  if _n_ = 1 then do;
    put;
    put "## &id_hdr";
    put;
    put "Case-ID overlap uses 5-digit IDs normalized to Precede##### (PDD-D-19). MRN overlap compares raw values.";
    put;
    put "|unit|column|non-missing rows|distinct|1 row per value|in spine case IDs|not in spine case IDs|in spine MRNs|not in spine MRNs|";
    put "|---|---|---|---|---|---|---|---|---|";
  end;
  __line = cats('|', unit, '|', translate(strip(name), '/', '|'),
                '|', %sup(n_rows), '|', %sup(n_distinct), '|', ifc(n_rows = n_distinct, 'yes', 'no'),
                '|', %sup(n_in_case), '|', %sup(n_distinct - n_in_case),
                '|', %sup(n_in_mrn), '|', %sup(n_distinct - n_in_mrn), '|');
  put __line;
run;

proc sort data=r_pat;
  by unit name rank;
run;

data _null_;
  set r_pat;
  file "&out_md" mod encoding='utf-8' lrecl=32767;
  length __line $2000;
  if _n_ = 1 then do;
    put;
    put "## &shp_hdr";
    put;
    put "|unit|column|rank|shape|rows|";
    put "|---|---|---|---|---|";
  end;
  __line = cats('|', unit, '|', translate(strip(name), '/', '|'), '|', rank,
                '|', translate(strip(pattern), '/', '|'), '|', %sup(n), '|');
  put __line;
run;

data _null_;
  file "&out_md" mod encoding='utf-8' lrecl=32767;
  put;
  put "End of probe.";
run;

proc sql noprint;
  select count(*) into :n_fail trimmed from r_units where status ne 'OK';
quit;
%put NOTE: [probe] &unit unit(s) profiled, &n_fail not OK. Output: &out_md;
%put NOTE: [probe] Commit the .md file from the repo and push it for the Claude Code machine.;
