/*==========================================================================
  Program : 16a_name_map_ext.sas
  Phase   : 16 (name map extension), plan 16-03
  Purpose : MAP-01 exact reuse, MAP-02 near-match candidates and human gate,
            MAP-03 naming of genuinely new columns. Extends the frozen Phase 4
            map to the 282 new (file x header) rows of s21 s22 s23.
            pdd.name_map and pdd.name_map_vars are read-only (A1). They are
            never a DATA, OUT or CREATE target here.
  Inputs  : pdd.name_map (4795 rows), pdd.name_map_vars (1297 rows)
            docs/import_spec_new_generated.csv (282 rows)
            docs/name_abbrev.csv, docs/new_source_header_variants.csv
            docs/name_map_decisions_new.csv (Gerard, may be header-only)
            docs/s06_column_class.csv
  Outputs : pdd.name_map_ext, pdd.name_map_vars_ext,
            pdd.qc_map_ext_candidates, pdd.qc_map_ext_collisions,
            pdd.qc_map_ext_summary
            &exchange_path\name_map_ext_new.csv, name_map_vars_ext.csv,
            name_map_ext_candidates.csv, name_map_ext_collisions.csv,
            name_map_ext_summary.csv
  Rules   : An exact cleaned-header match reuses the stored name (lookup,
            never regenerated). A near-match is merged only when
            name_map_decisions_new.csv has a SAME row. An undecided candidate
            gets status PENDING_DECISION and a blank pcnr_name. Nothing is
            merged automatically.
  Run     : standalone or via run_pipeline.cmd 16. Needs only the frozen map
            and the committed spec (A13).
  Status  : PENDING SAS RUN (Gerard).
==========================================================================*/

/* ============================================================
   SECTION 0 -- %include, %pdd_lib
   ============================================================ */

%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;
%include "&sas_path.\04_name_map_macros.sas";
%include "&sas_path.\16_name_map_ext_macros.sas";


/* ============================================================
   SECTION 1 -- Utility macros
   ============================================================ */

%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\16a_name_map_ext.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* ERROR line first, while the log is still routed to the program log file,
   then restore the log and echo it once more to the SAS Log window. */
%macro fail_out(msg=);
  %put ERROR: [16a_name_map_ext] &msg;
  %restore_log;
  %if &in_pipeline = 0 %then %put ERROR: [16a_name_map_ext] &msg;
  %abort cancel;
%mend fail_out;

/* Fails when a count is above zero. row= names the decision row number. */
%macro p16a_failif(n=, row=, msg=);
  %if &n > 0 %then
    %fail_out(msg=%str(decision row &row: &msg (&n rows)));
%mend p16a_failif;

%check_encoding;
%check_pdd_lib;


/* ============================================================
   SECTION 2 -- Preconditions and frozen asserts (A1)
   ============================================================ */

%macro p16a_preconditions;
  %local _n_rows _n_uniq _n_names _n_vars _f;
  %let _n_rows = -1; %let _n_uniq = -1; %let _n_names = -1; %let _n_vars = -1;

  %let _f = import_spec_new_generated.csv;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\&_f)) %then
    %fail_out(msg=%str(docs/&_f not found));
  %let _f = name_abbrev.csv;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\&_f)) %then
    %fail_out(msg=%str(docs/&_f not found));
  %let _f = name_map_decisions_new.csv;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\&_f)) %then
    %fail_out(msg=%str(docs/&_f not found));
  %let _f = new_source_header_variants.csv;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\&_f)) %then
    %fail_out(msg=%str(docs/&_f not found));
  %let _f = s06_column_class.csv;
  %if not %sysfunc(fileexist(C:\data_dictionary\docs\&_f)) %then
    %fail_out(msg=%str(docs/&_f not found));
  %if not %sysfunc(exist(pdd.name_map)) %then
    %fail_out(msg=%str(pdd.name_map missing -- run Phase 4 first));
  %if not %sysfunc(exist(pdd.name_map_vars)) %then
    %fail_out(msg=%str(pdd.name_map_vars missing -- run Phase 4 first));

  proc sql noprint;
    select count(*) into :_n_rows trimmed from pdd.name_map;
    select count(*) into :_n_uniq trimmed
      from (select distinct s_code, col_order from pdd.name_map);
    select count(distinct pcnr_name) into :_n_names trimmed
      from pdd.name_map where status = 'PCNR' and pcnr_name ne '';
    select count(*) into :_n_vars trimmed from pdd.name_map_vars;
  quit;

  %if &_n_rows ne 4795 %then
    %fail_out(msg=%str(frozen pdd.name_map rows expected=4795 got=&_n_rows));
  %if &_n_uniq ne 4795 %then
    %fail_out(msg=%str(frozen pdd.name_map distinct keys expected=4795 got=&_n_uniq));
  %if &_n_names ne 1297 %then
    %fail_out(msg=%str(frozen PCNR names expected=1297 got=&_n_names));
  %if &_n_vars ne 1297 %then
    %fail_out(msg=%str(frozen pdd.name_map_vars rows expected=1297 got=&_n_vars));

  proc sort data=pdd.name_map out=work.p16_frozen;
    by s_code col_order;
  run;

  /* One row per frozen final name without the PCNR_ prefix (extend-only set) */
  proc sql noprint;
    create table work.p16_used as
    select distinct substr(pcnr_name, 6) as name_nop length=32
    from work.p16_frozen
    where status = 'PCNR' and pcnr_name ne '';
  quit;

  %route_log;
  %put NOTE: [16a_name_map_ext] === Phase 16 plan 03 starting ===;
  %put NOTE: [16a_name_map_ext] frozen map asserted: 4795 rows and 1297 names and 1297 vars;

  proc datasets lib=pdd nolist nowarn;
    delete name_map_ext name_map_vars_ext qc_map_ext_candidates
           qc_map_ext_collisions qc_map_ext_summary;
  quit;
%mend p16a_preconditions;


/* ============================================================
   SECTION 3 -- Load the new rows, abbreviations and variants
   ============================================================ */

%macro p16a_load_new;
  %local _n_spec _n_bad94 _n_codes;
  %let _n_spec = -1; %let _n_bad94 = -1; %let _n_codes = -1;

  data work.p16_new (rename=(spec_len=length));
    length file_code $4 col_order 8 src_name $256 orig_col_name $256
           sas_name $32 sas_type $1 spec_len 8 informat $34 fmt $34
           notes $200 src_encoding $10 s_code $4 original_header $256;
    infile "C:\data_dictionary\docs\import_spec_new_generated.csv"
           dsd dlm=',' firstobs=2 truncover lrecl=5000 encoding='utf-8';
    input file_code $ col_order src_name $ orig_col_name $ sas_name $
          sas_type $ spec_len informat $ fmt $ notes $ src_encoding $;
    s_code          = strip(file_code);
    original_header = strip(orig_col_name);
    sas_name        = strip(sas_name);
    sas_type        = upcase(strip(sas_type));
    keep s_code col_order sas_name original_header sas_type spec_len;
  run;

  proc sql noprint;
    select count(*) into :_n_spec trimmed from work.p16_new;
    select count(distinct s_code) into :_n_codes trimmed from work.p16_new
      where s_code in ('s21', 's22', 's23');
    select count(*) into :_n_bad94 trimmed
      from (select s_code, count(*) as n from work.p16_new
            group by s_code) where n ne 94;
  quit;
  %if &_n_spec ne 282 %then
    %fail_out(msg=%str(spec rows expected=282 got=&_n_spec));
  %if &_n_codes ne 3 %then
    %fail_out(msg=%str(spec must hold exactly s21 s22 s23 (found &_n_codes codes)));
  %if &_n_bad94 ne 0 %then
    %fail_out(msg=%str(&_n_bad94 file codes without exactly 94 spec rows));

  %p16_load_abbrev(csv=C:\data_dictionary\docs\name_abbrev.csv, out=work.p16_abbrev)
  %if &p16_abbrev_bad > 0 %then
    %fail_out(msg=%str(name_abbrev.csv has &p16_abbrev_bad invalid rows));

  data work.p16_variants_raw;
    length file_codes $40 new_header $256 new_type $10 older_header $256
           older_source_codes $60 older_type $10 variant_kind $30
           note $400 vstatus $40;
    infile "C:\data_dictionary\docs\new_source_header_variants.csv"
           dsd dlm=',' firstobs=2 truncover lrecl=32767 encoding='utf-8';
    input file_codes $ new_header $ new_type $ older_header $
          older_source_codes $ older_type $ variant_kind $ note $ vstatus $;
    if strip(new_header) = '' then delete;
  run;

  data work.p16_variants;
    set work.p16_variants_raw;
    length s_code $4 nk_new $200 ok_old $200 _i 8;
    %p16_clean_name(raw=new_header, out=nk_new)
    nk_new = lowcase(nk_new);
    %p16_clean_name(raw=older_header, out=ok_old)
    ok_old = lowcase(ok_old);
    variant_kind = lowcase(strip(variant_kind));
    do _i = 1 to countw(file_codes, ';');
      s_code = strip(scan(file_codes, _i, ';'));
      output;
    end;
    keep s_code nk_new ok_old variant_kind;
  run;

  %put NOTE: [16a_name_map_ext] loaded 282 spec rows and abbreviations and variants;
%mend p16a_load_new;


/* ============================================================
   SECTION 4 -- Status (A7) and guards
   ============================================================ */

%macro p16a_status;
  %local _n_key _n_link _n_clock _n_dup;
  %let _n_key = -1; %let _n_link = -1; %let _n_clock = -1; %let _n_dup = -1;

  data work.p16_new;
    set work.p16_new;
    length name_key $200 clean_case $200 status $20 map_class $20
           pcnr_name $32 matched_pcnr_name $32 decision_ref $40;
    %p16_clean_name(raw=original_header, out=clean_case)
    name_key = lowcase(clean_case);
    if name_key = 'precede_study_id' then status = 'KEY';
    else if name_key in ('encrypted_mrn', 'encrypted_encounter') then status = 'LINKAGE_ONLY';
    else status = 'PCNR';
    trunc_flag = (length(strip(original_header)) >= 256);
    group_id = .;
  run;

  proc sql noprint;
    select count(*) into :_n_key trimmed from work.p16_new where status = 'KEY';
    select count(*) into :_n_link trimmed from work.p16_new where status = 'LINKAGE_ONLY';
  quit;
  %if &_n_key ne 3 %then
    %fail_out(msg=%str(KEY rows expected=3 got=&_n_key));
  %if &_n_link ne 6 %then
    %fail_out(msg=%str(LINKAGE_ONLY rows expected=6 got=&_n_link));

  data work.p16_clock;
    length sas_name $32 orig_col_name $256 token $40 class $20 rule $400;
    infile "C:\data_dictionary\docs\s06_column_class.csv"
           dsd dlm=',' firstobs=2 truncover lrecl=32767 encoding='utf-8';
    input sas_name $ orig_col_name $ token $ class $ rule $;
    if upcase(strip(class)) = 'CLOCK';
    sas_name = lowcase(strip(sas_name));
    keep sas_name;
  run;

  proc sql noprint;
    select count(*) into :_n_clock trimmed
    from work.p16_new as n inner join work.p16_clock as c
      on lowcase(n.sas_name) = c.sas_name;
    select count(*) into :_n_dup trimmed
    from (select s_code, name_key, count(*) as n from work.p16_new
          group by s_code, name_key having count(*) > 1);
  quit;
  %if &_n_clock > 0 %then
    %fail_out(msg=%str(&_n_clock new sas_names equal a CLOCK-class s06 name));
  %if &_n_dup > 0 %then %do;
    proc sql noprint;
      create table work.p16_dupkeys as
      select s_code, name_key, min(col_order) as col_order, count(*) as n
      from work.p16_new group by s_code, name_key having count(*) > 1;
    quit;
    data _null_;
      set work.p16_dupkeys;
      put "ERROR: [16a_name_map_ext] D-01a same-file duplicate: " s_code= col_order=;
    run;
    %fail_out(msg=%str(D-01a: &_n_dup same-file duplicate cleaned headers in the new files));
  %end;
  %put NOTE: [16a_name_map_ext] status set: 3 KEY and 6 LINKAGE_ONLY and 0 clock clashes;
%mend p16a_status;


/* ============================================================
   SECTION 5 -- MAP-01 exact lookup and candidate union
   ============================================================ */

%macro p16a_exact;
  %local _n_cand _n_ed _n_sfx _n_var _n_amb _n_np _n_novar;
  %let _n_cand = 0; %let _n_ed = 0; %let _n_sfx = 0; %let _n_var = 0;
  %let _n_amb = 0; %let _n_np = 0; %let _n_novar = 0;

  /* Old keys: the same cleaning key as the new rows (never regenerated names) */
  data work.p16_old_keys;
    set pdd.name_map (where=(strip(pcnr_name) ne '' or status ne 'PCNR'));
    length name_key $200;
    %p16_clean_name(raw=original_header, out=name_key)
    name_key = lowcase(name_key);
    keep s_code col_order status pcnr_name group_id sas_type name_key original_header;
  run;

  proc sql noprint;
    create table work.p16_old_pcnr_keys as
    select name_key, min(pcnr_name) as pcnr_name length=32,
           count(distinct pcnr_name) as n_names, min(group_id) as group_id
    from work.p16_old_keys where status = 'PCNR'
    group by name_key;
    create table work.p16_old_nonpcnr_keys as
    select distinct name_key from work.p16_old_keys where status ne 'PCNR';
    create table work.p16_old_types as
    select distinct pcnr_name, sas_type from work.p16_old_keys where status = 'PCNR';
    create table work.p16_newj as
    select n.*, o.pcnr_name as o_name length=32, o.n_names as o_n,
           o.group_id as o_gid,
           (select count(*) from work.p16_old_nonpcnr_keys as x
             where x.name_key = n.name_key) as o_nonp
    from work.p16_new as n
    left join work.p16_old_pcnr_keys as o
      on n.name_key = o.name_key and n.status = 'PCNR'
    order by n.s_code, n.col_order;
  quit;

  data work.p16_new;
    set work.p16_newj;
    length open_reason $20;
    open_reason = '';
    if status = 'PCNR' then do;
      if o_n = 1 then do;
        map_class = 'EXACT_REUSE';
        pcnr_name = o_name;
        matched_pcnr_name = o_name;
        group_id = o_gid;
      end;
      else if o_n > 1 then open_reason = 'AMBIGUOUS';
      else if o_nonp > 0 then open_reason = 'NONPCNR_EXACT';
    end;
    else map_class = status;
    drop o_name o_n o_gid o_nonp;
  run;

  /* Open groups: one group per distinct name_key across s21-s23 */
  proc sort data=work.p16_new (where=(status = 'PCNR' and map_class = ''))
            out=work.p16_openrows;
    by name_key s_code col_order;
  run;

  data work.p16_grp (keep=grp_no name_key rep_s_code rep_col_order rep_header
                          rep_clean open_reason s_codes_new)
       work.p16_openmap (keep=grp_no s_code col_order name_key);
    set work.p16_openrows;
    by name_key;
    length s_codes_new $60 rep_s_code $4 rep_header $256 rep_clean $200
           rep_col_order 8;
    retain grp_no 0 s_codes_new rep_s_code rep_col_order rep_header rep_clean;
    if first.name_key then do;
      grp_no + 1;
      s_codes_new = '';
      rep_s_code = s_code;
      rep_col_order = col_order;
      rep_header = original_header;
      rep_clean = clean_case;
    end;
    s_codes_new = catx(' ', s_codes_new, s_code);
    output work.p16_openmap;
    if last.name_key then output work.p16_grp;
  run;

  /* One representative key per frozen PCNR name */
  proc sort data=work.p16_old_keys (where=(status = 'PCNR' and pcnr_name ne ''))
            out=work.p16_oldsort;
    by pcnr_name s_code col_order;
  run;

  data work.p16_old_rep (keep=pcnr_name name_key header_old s_codes_old);
    set work.p16_oldsort;
    by pcnr_name;
    length s_codes_old $100 header_old $256 rep_key $200;
    retain s_codes_old header_old rep_key;
    if first.pcnr_name then do;
      s_codes_old = '';
      header_old = original_header;
      rep_key = name_key;
    end;
    s_codes_old = catx(' ', s_codes_old, s_code);
    if last.pcnr_name then do;
      name_key = rep_key;
      output;
    end;
  run;

  /* (a) EDIT_DISTANCE: complev at most 2 (D-06 detector) */
  proc sql noprint;
    create table work.p16_c_ed as
    select g.grp_no, o.pcnr_name as pcnr_name_old length=32,
           'EDIT_DISTANCE' as match_type length=20,
           complev(strip(g.name_key), strip(o.name_key)) as edit_dist
    from work.p16_grp as g, work.p16_old_rep as o
    where g.name_key ne o.name_key
      and abs(length(strip(g.name_key)) - length(strip(o.name_key))) <= 2
      and complev(strip(g.name_key), strip(o.name_key)) <= 2;

    /* (b) TRAILING_SUFFIX: _N or _dup suffix, both directions */
    create table work.p16_c_sfx as
    select g.grp_no, o.pcnr_name as pcnr_name_old length=32,
           'TRAILING_SUFFIX' as match_type length=20,
           . as edit_dist
    from work.p16_grp as g, work.p16_old_rep as o
    where g.name_key ne o.name_key
      and (
        (prxmatch('/(_\d+|_dup\d*)$/i', strip(g.name_key)) > 0
         and prxchange('s/(_\d+|_dup\d*)$//i', 1, strip(g.name_key))
             = strip(o.name_key))
        or
        (prxmatch('/(_\d+|_dup\d*)$/i', strip(o.name_key)) > 0
         and prxchange('s/(_\d+|_dup\d*)$//i', 1, strip(o.name_key))
             = strip(g.name_key))
      );

    /* (c) VARIANTS_FILE: pairs listed in new_source_header_variants.csv */
    create table work.p16_c_var as
    select distinct m.grp_no,
           coalesce(o.pcnr_name, '') as pcnr_name_old length=32,
           'VARIANTS_FILE' as match_type length=20,
           . as edit_dist
    from work.p16_openmap as m
    inner join work.p16_variants as v
      on v.s_code = m.s_code and v.nk_new = m.name_key
    left join work.p16_old_pcnr_keys as o
      on o.name_key = v.ok_old;

    /* AMBIGUOUS: the key maps to more than one frozen name */
    create table work.p16_c_amb as
    select distinct g.grp_no, k.pcnr_name as pcnr_name_old length=32,
           'AMBIGUOUS' as match_type length=20, . as edit_dist
    from work.p16_grp as g
    inner join work.p16_old_keys as k
      on k.name_key = g.name_key and k.status = 'PCNR' and k.pcnr_name ne ''
    where g.open_reason = 'AMBIGUOUS';

    /* NONPCNR_EXACT: the key exists only on non-PCNR frozen rows */
    create table work.p16_c_nonp as
    select g.grp_no, '' as pcnr_name_old length=32,
           'NONPCNR_EXACT' as match_type length=20, . as edit_dist
    from work.p16_grp as g
    where g.open_reason = 'NONPCNR_EXACT';
  quit;

  data work.p16_cand0;
    set work.p16_c_ed work.p16_c_sfx work.p16_c_var work.p16_c_amb work.p16_c_nonp;
  run;

  proc sql noprint;
    create table work.p16_cand_real as
    select c.grp_no, g.rep_s_code as s_code_new length=4,
           g.rep_col_order as col_order_new,
           g.rep_header as header_new length=256,
           g.s_codes_new length=60,
           c.pcnr_name_old,
           coalesce(r.s_codes_old, '') as s_codes_old length=100,
           coalesce(r.header_old, '') as header_old length=256,
           c.match_type, c.edit_dist
    from work.p16_cand0 as c
    inner join work.p16_grp as g on c.grp_no = g.grp_no
    left join work.p16_old_rep as r on c.pcnr_name_old = r.pcnr_name;
    select count(*) into :_n_cand trimmed from work.p16_cand_real;
    select count(*) into :_n_ed trimmed from work.p16_cand_real where match_type = 'EDIT_DISTANCE';
    select count(*) into :_n_sfx trimmed from work.p16_cand_real where match_type = 'TRAILING_SUFFIX';
    select count(*) into :_n_var trimmed from work.p16_cand_real where match_type = 'VARIANTS_FILE';
    select count(*) into :_n_amb trimmed from work.p16_cand_real where match_type = 'AMBIGUOUS';
    select count(*) into :_n_np trimmed from work.p16_cand_real where match_type = 'NONPCNR_EXACT';
    select count(*) into :_n_novar trimmed from work.p16_cand_real
      where match_type = 'VARIANTS_FILE' and pcnr_name_old = '';
  quit;

  %put NOTE: [16a_name_map_ext] candidates EDIT_DISTANCE=&_n_ed TRAILING_SUFFIX=&_n_sfx VARIANTS_FILE=&_n_var AMBIGUOUS=&_n_amb NONPCNR_EXACT=&_n_np;
  %if &_n_novar > 0 %then
    %put NOTE: [16a_name_map_ext] &_n_novar VARIANTS_FILE candidates have no frozen name (blank pcnr_name_old);
  %if &_n_cand > 200 %then
    %fail_out(msg=%str(sanity stop: &_n_cand candidate pairs (more than 200) -- review the detector));

  /* TYPE_CONFLICT_EXACT: exact reuse where the type changed (A6), info only */
  proc sql noprint;
    create table work.p16_tc_rows as
    select n.s_code, n.col_order, n.original_header, n.name_key, n.pcnr_name
    from work.p16_new as n
    where n.map_class = 'EXACT_REUSE'
      and (exists (select 1 from work.p16_old_types as o
                    where o.pcnr_name = n.pcnr_name and o.sas_type ne n.sas_type)
        or exists (select 1 from work.p16_variants as v
                    where v.s_code = n.s_code and v.nk_new = n.name_key
                      and v.variant_kind in ('type_change', 'suffix_and_type')))
    order by n.name_key, n.s_code, n.col_order;
  quit;

  data work.p16_tc (keep=s_code_new col_order_new header_new s_codes_new pcnr_name_old);
    set work.p16_tc_rows;
    by name_key;
    length s_code_new $4 header_new $256 s_codes_new $60 pcnr_name_old $32
           col_order_new 8;
    retain s_code_new col_order_new header_new s_codes_new;
    if first.name_key then do;
      s_code_new = s_code;
      col_order_new = col_order;
      header_new = original_header;
      s_codes_new = '';
    end;
    s_codes_new = catx(' ', s_codes_new, s_code);
    pcnr_name_old = pcnr_name;
    if last.name_key then output;
  run;

  proc sql noprint;
    create table work.p16_cand1 as
    select . as grp_no, t.s_code_new, t.col_order_new, t.header_new, t.s_codes_new,
           t.pcnr_name_old,
           coalesce(r.s_codes_old, '') as s_codes_old length=100,
           coalesce(r.header_old, '') as header_old length=256,
           'TYPE_CONFLICT_EXACT' as match_type length=20, . as edit_dist
    from work.p16_tc as t
    left join work.p16_old_rep as r on t.pcnr_name_old = r.pcnr_name;
  quit;

  data work.p16_cand2;
    set work.p16_cand_real work.p16_cand1;
  run;

  proc sort data=work.p16_cand2;
    by s_code_new col_order_new match_type pcnr_name_old;
  run;

  data work.p16_cand;
    set work.p16_cand2;
    pair_id + 1;
  run;
%mend p16a_exact;


/* ============================================================
   SECTION 6 -- MAP-02 decisions (SAME DIFFERENT RENAME)
   ============================================================ */

%macro p16a_check_dec_header;
  %local _ok;
  %let _ok = 0;
  data _null_;
    length _raw $1000 _exp $500;
    infile "C:\data_dictionary\docs\name_map_decisions_new.csv"
           encoding='utf-8' firstobs=1 obs=1 lrecl=32767;
    input;
    _raw = strip(_infile_);
    if length(_raw) > 0 and substr(_raw, length(_raw), 1) = '0D'x then
      _raw = strip(substr(_raw, 1, length(_raw) - 1));
    _exp = 's_code_a,header_a,col_order_a,s_code_b,header_b,col_order_b,decision,new_name,note,decided_by,date';
    if length(_raw) >= length(_exp) and length(_raw) - length(_exp) <= 3
       and lowcase(substr(_raw, length(_raw) - length(_exp) + 1)) = _exp
      then call symputx('_ok', '1');
  run;
  %if &_ok ne 1 %then
    %fail_out(msg=%str(name_map_decisions_new.csv header does not match the Phase 4 header));
%mend p16a_check_dec_header;

%macro p16a_decisions;
  %local _n _r _n_dec;
  %let _n = 0; %let _r = 0; %let _n_dec = 0;

  %p16a_check_dec_header

  data work.p16_dec;
    length s_code_a $4 header_a $256 col_order_a 8
           s_code_b $4 header_b $256 col_order_b 8
           decision $20 new_name $200 note $200 decided_by $50 date $10
           key_a $200 key_b $200 new_base $200 rown 8;
    infile "C:\data_dictionary\docs\name_map_decisions_new.csv"
           encoding='utf-8' dsd dlm=',' missover firstobs=2 lrecl=32767;
    input s_code_a $ header_a $ col_order_a s_code_b $ header_b $ col_order_b
          decision $ new_name $ note $ decided_by $ date $;
    rown = _n_;
    s_code_a = strip(s_code_a);
    header_a = strip(header_a);
    s_code_b = strip(s_code_b);
    header_b = strip(header_b);
    decision = upcase(strip(decision));
    new_name = strip(new_name);
    if decision = '' and s_code_a = '' and header_a = '' then delete;
    %p16_clean_name(raw=header_a, out=key_a)
    key_a = lowcase(key_a);
    %p16_clean_name(raw=header_b, out=key_b)
    key_b = lowcase(key_b);
    new_base = prxchange('s/^PCNR_//i', 1, strip(new_name));
  run;

  proc sql noprint;
    select count(*) into :_n_dec trimmed from work.p16_dec;
  quit;
  %put NOTE: [16a_name_map_ext] decision rows read: &_n_dec;

  proc sql noprint;
    /* decision value */
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec where decision not in ('SAME', 'DIFFERENT', 'RENAME');
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(decision must be SAME or DIFFERENT or RENAME))

  proc sql noprint;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec
      where s_code_a ne '' and s_code_a not in ('s21', 's22', 's23');
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(s_code_a must be blank or s21 or s22 or s23))

  /* Side a: new PCNR-status rows matched by cleaned lowercase header */
  proc sql noprint;
    create table work.p16_dec_hit as
    select d.rown, d.decision, n.s_code, n.col_order, n.name_key, n.map_class
    from work.p16_dec as d
    inner join work.p16_new as n
      on n.status = 'PCNR' and n.name_key = d.key_a
     and (d.s_code_a = '' or n.s_code = d.s_code_a)
     and (d.col_order_a is missing or n.col_order = d.col_order_a);

    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec
      where rown not in (select rown from work.p16_dec_hit);
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(side a matches no new PCNR row))

  proc sql noprint;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec
      where rown in (select rown from work.p16_dec_hit)
        and rown not in (select rown from work.p16_dec_hit where map_class = '');
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(side a is already settled by an exact match))

  /* Side b for SAME: exactly one frozen PCNR name */
  proc sql noprint;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec
      where decision = 'SAME' and s_code_b ne ''
        and prxmatch('/^s(0[1-9]|1[0-9]|20)$/', strip(s_code_b)) = 0;
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(s_code_b must be in s01 to s20))

  proc sql noprint;
    create table work.p16_dec_b as
    select d.rown, count(distinct o.pcnr_name) as n_b,
           min(o.pcnr_name) as pcnr_b length=32,
           min(o.group_id) as group_b
    from work.p16_dec as d
    left join work.p16_old_keys as o
      on o.status = 'PCNR' and o.pcnr_name ne ''
     and ( (d.s_code_b ne '' and d.col_order_b is not missing
            and o.s_code = d.s_code_b and o.col_order = d.col_order_b)
        or (not (d.s_code_b ne '' and d.col_order_b is not missing)
            and (d.s_code_b = '' or o.s_code = d.s_code_b)
            and o.name_key = d.key_b) )
    where d.decision = 'SAME'
    group by d.rown;

    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec_b where n_b ne 1;
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(side b must resolve to exactly one frozen PCNR name))

  /* RENAME target checks (B4 analogue) */
  proc sql noprint;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec
      where decision = 'RENAME'
        and (new_base = '' or length(strip(new_base)) > 27
             or not nvalid(cats('PCNR_', strip(new_base)), 'v7'));
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(RENAME new_name is blank or over 27 characters or not a valid name))

  proc sql noprint;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_dec
      where decision = 'RENAME'
        and lowcase(new_base) in (select lowcase(name_nop) from work.p16_used);
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(RENAME new_name collides with a frozen name))

  /* Group level: all rows of a cleaned header share one outcome */
  proc sql noprint;
    create table work.p16_grp_dec0 as
    select distinct h.name_key, d.rown, d.decision,
           case when d.decision = 'RENAME' then d.new_base else '' end as new_base length=200,
           coalesce(b.pcnr_b, '') as pcnr_b length=32, b.group_b,
           catx('|', d.decision, b.pcnr_b,
                case when d.decision = 'RENAME' then d.new_base else '' end)
             as outcome length=300
    from work.p16_dec_hit as h
    inner join work.p16_dec as d on h.rown = d.rown
    left join work.p16_dec_b as b on d.rown = b.rown
    where h.map_class = '';

    create table work.p16_grp_conf as
    select name_key, min(rown) as rown from work.p16_grp_dec0
    group by name_key having count(distinct outcome) > 1;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from work.p16_grp_conf;
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(a cleaned header has two different decision outcomes))

  proc sql noprint;
    select count(*), coalesce(min(rown), 0) into :_n trimmed, :_r trimmed
      from (select lowcase(new_base) as nb, min(rown) as rown
            from work.p16_grp_dec0 where decision = 'RENAME'
            group by lowcase(new_base)
            having count(distinct name_key) > 1);
  quit;
  %p16a_failif(n=&_n, row=&_r, msg=%str(RENAME new_name used for two different headers))

  proc sql noprint;
    create table work.p16_grp_dec as
    select name_key, min(rown) as rown, min(decision) as decision length=20,
           min(new_base) as new_base length=200,
           min(pcnr_b) as pcnr_b length=32, min(group_b) as group_b
    from work.p16_grp_dec0
    group by name_key;

    create table work.p16_newd as
    select n.*, g.decision as g_dec length=20, g.pcnr_b as g_pcnr length=32,
           g.group_b as g_gid, g.rown as g_rown
    from work.p16_new as n
    left join work.p16_grp_dec as g
      on n.name_key = g.name_key and n.status = 'PCNR' and n.map_class = ''
    order by n.s_code, n.col_order;
  quit;

  /* Apply SAME: reuse the frozen name and group */
  data work.p16_new;
    set work.p16_newd;
    if g_dec = 'SAME' then do;
      map_class = 'SAME_DECIDED';
      pcnr_name = g_pcnr;
      matched_pcnr_name = g_pcnr;
      group_id = g_gid;
      decision_ref = catx(' ', 'name_map_decisions_new.csv row', g_rown);
    end;
    drop g_dec g_pcnr g_gid g_rown;
  run;

  /* B5 analogue: no new file may carry two columns on one name */
  proc sql noprint;
    create table work.p16_b5 as
    select s_code, pcnr_name, count(*) as n
    from work.p16_new
    where map_class in ('EXACT_REUSE', 'SAME_DECIDED')
    group by s_code, pcnr_name having count(*) > 1;
    select count(*) into :_n trimmed from work.p16_b5;
  quit;
  %if &_n > 0 %then %do;
    data _null_;
      set work.p16_b5;
      put "ERROR: [16a_name_map_ext] B5 two columns on one name: " s_code= pcnr_name=;
    run;
    %fail_out(msg=%str(B5: &_n new files have two columns mapped to the same name));
  %end;

  /* Group table with decision state and candidate flag */
  proc sql noprint;
    create table work.p16_grp2 as
    select g.*, coalesce(d.decision, '') as dec length=20,
           coalesce(d.new_base, '') as new_base length=200,
           d.rown as dec_rown,
           case when g.open_reason ne ''
                  or g.grp_no in (select grp_no from work.p16_cand where grp_no is not missing)
                then 1 else 0 end as has_cand
    from work.p16_grp as g
    left join work.p16_grp_dec as d on g.name_key = d.name_key;
  quit;
%mend p16a_decisions;


/* ============================================================
   SECTION 7 -- MAP-03 naming (A1-A4, extend-only)
   ============================================================ */

/* Base names with the Phase 4 abbreviation rules. in= has grp_no rep_s_code
   rep_col_order rep_clean forced new_base. out= feeds p16_assign_names. */
%macro p16a_basename(in=, out=);
  data &out;
    length pcnr_name_base $200 nm $200 _cbe $200 _pat $400 long short $200
           mode $10 _ai _nab_tot _longlen _is_lower _p16_longer 8
           _elide_first 8 _elide_last 8 _elide_head $200 _elide_tail $200;
    if 0 then set work.p16_abbrev (keep=long short _longlen _is_lower mode) nobs=_nab_tot;
    retain _nab_tot;
    set &in;
    _p16_longer = 0;
    nm = rep_clean;
    if forced = 1 then pcnr_name_base = new_base;
    else do;
      %p16_shorten(nm=nm, abbrev=work.p16_abbrev)
      pcnr_name_base = nm;
    end;
    group_id = grp_no;
    s_code = rep_s_code;
    col_order = rep_col_order;
    keep group_id s_code col_order pcnr_name_base _p16_longer;
  run;
%mend p16a_basename;

%macro p16a_naming;
  %local _max_gid _n_toname _n_longer;
  %let _max_gid = 0; %let _n_toname = 0; %let _n_longer = 0;

  proc sql noprint;
    select max(group_id) into :_max_gid trimmed from work.p16_frozen;
    create table work.p16_name_in as
    select grp_no, rep_s_code, rep_col_order, rep_clean,
           (dec = 'RENAME') as forced, new_base
    from work.p16_grp2
    where dec in ('DIFFERENT', 'RENAME') or (dec = '' and has_cand = 0)
    order by calculated forced desc, rep_s_code, rep_col_order;
    create table work.p16_prop_in as
    select grp_no, rep_s_code, rep_col_order, rep_clean,
           0 as forced, '' as new_base length=200
    from work.p16_grp2
    where dec = '' and has_cand = 1
    order by rep_s_code, rep_col_order;
    select count(*) into :_n_toname trimmed from work.p16_name_in;
  quit;
  %put NOTE: [16a_name_map_ext] groups to name: &_n_toname (max frozen group_id &_max_gid);

  %p16a_basename(in=work.p16_name_in, out=work.p16_to_name)
  %p16a_basename(in=work.p16_prop_in, out=work.p16_to_prop)

  proc sql noprint;
    select count(*) into :_n_longer trimmed from
      (select 1 from work.p16_to_name where _p16_longer = 1
       union all
       select 1 from work.p16_to_prop where _p16_longer = 1);
  quit;
  %if &_n_longer > 0 %then
    %fail_out(msg=%str(A3: an abbreviation lengthened &_n_longer names));

  %p16_assign_names(in=work.p16_to_name, used=work.p16_used, out=work.p16_named)

  data work.p16_named2;
    set work.p16_named;
    new_gid = &_max_gid + _n_;
  run;

  /* Collisions (suffix above 1) */
  proc sql noprint;
    create table pdd.qc_map_ext_collisions as
    select s_code, col_order, pcnr_name_base, pcnr_name_final, suffix_n, reason
    from work.p16_named2
    where suffix_n > 1
    order by s_code, col_order;
  quit;

  /* Proposals for undecided groups (never written to the map) */
  data work.p16_used2 (keep=name_nop);
    set work.p16_used work.p16_named (in=b keep=pcnr_name_final);
    if b then name_nop = substr(pcnr_name_final, 6);
  run;

  %p16_assign_names(in=work.p16_to_prop, used=work.p16_used2, out=work.p16_proposed)

  proc sql noprint;
    create table work.p16_namemap as
    select g.name_key, g.dec, g.dec_rown, n.pcnr_name_final, n.new_gid
    from work.p16_grp2 as g
    inner join work.p16_named2 as n on g.grp_no = n.group_id;
    create table work.p16_pendkeys as
    select name_key from work.p16_grp2 where dec = '' and has_cand = 1;
    create table work.p16_newn as
    select r.*, m.pcnr_name_final as nm_final length=32, m.new_gid as nm_gid,
           m.dec as nm_dec length=20, m.dec_rown as nm_rown,
           case when r.name_key in (select name_key from work.p16_pendkeys)
                then 1 else 0 end as is_pend
    from work.p16_new as r
    left join work.p16_namemap as m
      on r.name_key = m.name_key and r.status = 'PCNR' and r.map_class = ''
    order by r.s_code, r.col_order;
  quit;

  data work.p16_new;
    set work.p16_newn;
    if status = 'PCNR' and map_class = '' then do;
      if nm_final ne '' then do;
        map_class = 'NEW_NAMED';
        pcnr_name = nm_final;
        group_id = nm_gid;
        if nm_dec in ('DIFFERENT', 'RENAME') then
          decision_ref = catx(' ', 'name_map_decisions_new.csv row', nm_rown);
      end;
      else if is_pend = 1 then do;
        map_class = 'PENDING_DECISION';
        status = 'PENDING_DECISION';
        pcnr_name = '';
        group_id = .;
      end;
    end;
    drop nm_final nm_gid nm_dec nm_rown is_pend;
  run;

  proc sql noprint;
    select count(*) into :_n_toname trimmed from work.p16_new where map_class = '';
  quit;
  %if &_n_toname > 0 %then
    %fail_out(msg=%str(&_n_toname new rows were not classified));
%mend p16a_naming;


/* ============================================================
   SECTION 8 -- Final datasets, Stage 2, frozen compare
   ============================================================ */

%macro p16a_final;
  %local _n_ext _n_uniq _n_chg _n_clash _n_vrows _n_vnames _n_vdiff _n_tcnew
         _n_frozen_names _n_new _n_key _n_link _n_exact _n_same _n_named
         _n_pend _n_pgrp _n_cand _n_candp _n_tc _n_coll _n_extnames _n_s2;
  %let _n_ext = 0; %let _n_uniq = 0; %let _n_chg = -1; %let _n_clash = 0;
  %let _n_vrows = 0; %let _n_vnames = 0; %let _n_vdiff = 0; %let _n_tcnew = 0;

  data pdd.name_map_ext;
    if 0 then set pdd.name_map;
    length map_class $20 matched_pcnr_name $32 decision_ref $40 name_key $200;
    set pdd.name_map (in=a)
        work.p16_new (keep=s_code col_order sas_name original_header trunc_flag
                           status group_id pcnr_name sas_type length map_class
                           matched_pcnr_name decision_ref name_key);
    if a then map_class = 'FROZEN';
  run;

  /* Expected rows: 4795 + 282 = 5077 */
  proc sql noprint;
    select count(*) into :_n_ext trimmed from pdd.name_map_ext;
    select count(*) into :_n_uniq trimmed
      from (select distinct s_code, col_order from pdd.name_map_ext);
  quit;
  %if &_n_ext ne 5077 %then
    %fail_out(msg=%str(name_map_ext rows expected=5077 got=&_n_ext));
  %if &_n_uniq ne 5077 %then
    %fail_out(msg=%str(name_map_ext distinct keys expected=5077 got=&_n_uniq));

  /* Frozen compare: no frozen row may change */
  proc sql noprint;
    select count(*) into :_n_chg trimmed
    from work.p16_frozen as f
    where not exists
      (select 1 from pdd.name_map_ext as e
        where e.map_class = 'FROZEN' and e.s_code = f.s_code
          and e.col_order = f.col_order and e.sas_name = f.sas_name
          and e.status = f.status and e.group_id = f.group_id
          and e.pcnr_name = f.pcnr_name and e.sas_type = f.sas_type
          and e.length = f.length);
  quit;
  %if &_n_chg ne 0 %then
    %fail_out(msg=%str(frozen map rows changed in name_map_ext (n_frozen_names_changed=&_n_chg)));

  /* New names must not equal a frozen name unless they reuse it */
  proc sql noprint;
    select count(*) into :_n_clash trimmed
    from pdd.name_map_ext
    where map_class = 'NEW_NAMED'
      and lowcase(pcnr_name) in
          (select lowcase(pcnr_name) from work.p16_frozen where pcnr_name ne '');
  quit;
  %if &_n_clash > 0 %then
    %fail_out(msg=%str(&_n_clash new names equal a frozen name -- names must keep their meaning));

  %p16_stage2(ds=pdd.name_map_ext, label=16a_name_map_ext)
  %let _n_s2 = &p16_stage2_fail;
  %if &p16_stage2_fail > 0 %then
    %fail_out(msg=%str(Stage 2 failed with &p16_stage2_fail problems on name_map_ext));

  /* pdd.name_map_vars_ext: Phase 4 type rollup over all PCNR rows */
  proc sql noprint;
    create table work.p16_vt as
    select pcnr_name, min(group_id) as group_id,
           case when max(case when upcase(sas_type) = 'C' then 1 else 0 end) = 1
                then 'C' else 'N' end as result_type length=1,
           max(e.length) as max_length,
           case when max(case when upcase(sas_type) = 'C' then 1 else 0 end) = 1
                 and max(case when upcase(sas_type) = 'N' then 1 else 0 end) = 1
                then 'Y' else 'N' end as type_conflict length=1
    from pdd.name_map_ext as e
    where status = 'PCNR' and pcnr_name ne ''
    group by pcnr_name;
  quit;

  proc sort data=pdd.name_map_ext (where=(status = 'PCNR' and pcnr_name ne ''))
            out=work.p16_vsort;
    by pcnr_name s_code;
  run;

  data work.p16_vsc;
    set work.p16_vsort;
    by pcnr_name s_code;
    length s_codes_contributing $200;
    retain s_codes_contributing n_sources;
    if first.pcnr_name then do;
      s_codes_contributing = '';
      n_sources = 0;
    end;
    if first.s_code then do;
      s_codes_contributing = catx(' ', s_codes_contributing, s_code);
      n_sources = n_sources + 1;
    end;
    if last.pcnr_name then output;
    keep pcnr_name n_sources s_codes_contributing;
  run;

  proc sql noprint;
    create table work.p16_fnames as
    select distinct pcnr_name from work.p16_frozen
    where status = 'PCNR' and pcnr_name ne '';
    create table work.p16_xnames as
    select distinct pcnr_name from pdd.name_map_ext
    where status = 'PCNR' and map_class ne 'FROZEN' and pcnr_name ne '';
    create table pdd.name_map_vars_ext as
    select v.pcnr_name, t.group_id, t.result_type, t.max_length, t.type_conflict,
           v.n_sources, v.s_codes_contributing,
           case when f.pcnr_name is null then 'NEW'
                when x.pcnr_name is not null then 'EXTENDED'
                else 'FROZEN' end as var_origin length=10
    from work.p16_vsc as v
    inner join work.p16_vt as t on v.pcnr_name = t.pcnr_name
    left join work.p16_fnames as f on v.pcnr_name = f.pcnr_name
    left join work.p16_xnames as x on v.pcnr_name = x.pcnr_name
    order by v.pcnr_name;

    select count(*) into :_n_vrows trimmed from pdd.name_map_vars_ext;
    select count(distinct pcnr_name) into :_n_vnames trimmed
      from pdd.name_map_ext where status = 'PCNR' and pcnr_name ne '';
    select count(*) into :_n_vdiff trimmed
      from pdd.name_map_vars_ext as e
      where e.var_origin = 'FROZEN'
        and not exists
          (select 1 from pdd.name_map_vars as o
            where o.pcnr_name = e.pcnr_name and o.result_type = e.result_type
              and o.max_length = e.max_length and o.type_conflict = e.type_conflict
              and o.n_sources = e.n_sources
              and o.s_codes_contributing = e.s_codes_contributing);
    select count(*) into :_n_tcnew trimmed
      from pdd.name_map_vars_ext as e
      inner join pdd.name_map_vars as o on o.pcnr_name = e.pcnr_name
      where e.var_origin = 'EXTENDED' and o.type_conflict = 'N'
        and e.type_conflict = 'Y';
  quit;
  %if &_n_vrows ne &_n_vnames %then
    %fail_out(msg=%str(name_map_vars_ext rows=&_n_vrows but distinct PCNR names=&_n_vnames));
  %if &_n_vdiff > 0 %then
    %fail_out(msg=%str(&_n_vdiff frozen variables changed in name_map_vars_ext));
  %put NOTE: [16a_name_map_ext] EXTENDED variables with type_conflict N to Y: &_n_tcnew;

  /* Candidates with decision state and proposed names */
  proc sql noprint;
    create table pdd.qc_map_ext_candidates as
    select c.pair_id, c.s_code_new, c.col_order_new, c.header_new, c.s_codes_new,
           c.pcnr_name_old, c.s_codes_old, c.header_old, c.match_type, c.edit_dist,
           coalesce(p.pcnr_name_final, '') as proposed_name_if_different length=32,
           case when c.match_type = 'TYPE_CONFLICT_EXACT' then ''
                else coalesce(g.dec, '') end as decision length=20,
           case when c.match_type = 'TYPE_CONFLICT_EXACT' then 'INFO_REUSED'
                when g.dec = 'SAME' then 'DECIDED_SAME'
                when g.dec = 'DIFFERENT' then 'DECIDED_DIFFERENT'
                when g.dec = 'RENAME' then 'DECIDED_RENAME'
                else 'PENDING_DECISION' end as status length=20
    from work.p16_cand as c
    left join work.p16_grp2 as g on c.grp_no = g.grp_no
    left join work.p16_proposed as p on c.grp_no = p.group_id
    order by c.pair_id;
  quit;

  /* Summary: the 17 metrics of the 16-01 contract */
  proc sql noprint;
    select count(*) into :_n_frozen_names trimmed from work.p16_fnames;
    select count(*) into :_n_new trimmed from pdd.name_map_ext where map_class ne 'FROZEN';
    select count(*) into :_n_key trimmed from pdd.name_map_ext where map_class = 'KEY';
    select count(*) into :_n_link trimmed from pdd.name_map_ext where map_class = 'LINKAGE_ONLY';
    select count(*) into :_n_exact trimmed from pdd.name_map_ext where map_class = 'EXACT_REUSE';
    select count(*) into :_n_same trimmed from pdd.name_map_ext where map_class = 'SAME_DECIDED';
    select count(*) into :_n_named trimmed from pdd.name_map_ext where map_class = 'NEW_NAMED';
    select count(*) into :_n_pend trimmed from pdd.name_map_ext where map_class = 'PENDING_DECISION';
    select count(distinct name_key) into :_n_pgrp trimmed
      from pdd.name_map_ext where map_class = 'PENDING_DECISION';
    select count(*) into :_n_cand trimmed from pdd.qc_map_ext_candidates
      where match_type ne 'TYPE_CONFLICT_EXACT';
    select count(*) into :_n_candp trimmed from pdd.qc_map_ext_candidates
      where status = 'PENDING_DECISION';
    select count(*) into :_n_tc trimmed from pdd.qc_map_ext_candidates
      where match_type = 'TYPE_CONFLICT_EXACT';
    select count(*) into :_n_coll trimmed from pdd.qc_map_ext_collisions;
    select count(distinct pcnr_name) into :_n_extnames trimmed
      from pdd.name_map_ext where status = 'PCNR' and pcnr_name ne '';
  quit;

  %global p16a_npend p16a_npgrp;
  %let p16a_npend = &_n_pend;
  %let p16a_npgrp = &_n_pgrp;

  data pdd.qc_map_ext_summary;
    length metric $40 value 8;
    metric = 'n_ext_rows'; value = &_n_ext; output;
    metric = 'n_frozen_rows'; value = 4795; output;
    metric = 'n_frozen_pcnr_names'; value = &_n_frozen_names; output;
    metric = 'n_frozen_names_changed'; value = &_n_chg; output;
    metric = 'n_new_rows'; value = &_n_new; output;
    metric = 'n_new_key'; value = &_n_key; output;
    metric = 'n_new_linkage_only'; value = &_n_link; output;
    metric = 'n_new_exact_reuse'; value = &_n_exact; output;
    metric = 'n_new_same_decided'; value = &_n_same; output;
    metric = 'n_new_named'; value = &_n_named; output;
    metric = 'n_new_pending_decision'; value = &_n_pend; output;
    metric = 'n_candidates'; value = &_n_cand; output;
    metric = 'n_candidates_pending'; value = &_n_candp; output;
    metric = 'n_type_conflict_exact'; value = &_n_tc; output;
    metric = 'n_collisions_suffixed'; value = &_n_coll; output;
    metric = 'n_ext_pcnr_names'; value = &_n_extnames; output;
    metric = 'n_stage2_fail'; value = &_n_s2; output;
  run;
%mend p16a_final;


/* ============================================================
   SECTION 9 -- Exchange CSVs, then the gate NOTE (A11)
   ============================================================ */

%macro p16a_export_gate;
  %local _n_coll;
  %let _n_coll = 0;

  proc sql noprint;
    create table work.p16_exp_new as
    select e.s_code, e.col_order, e.sas_name, e.original_header, e.status,
           e.group_id, e.pcnr_name, e.sas_type, e.length, e.map_class,
           e.matched_pcnr_name, e.decision_ref, e.name_key
    from pdd.name_map_ext as e
    where e.map_class ne 'FROZEN'
    order by e.s_code, e.col_order;
    select count(*) into :_n_coll trimmed from pdd.qc_map_ext_collisions;
  quit;

  proc export data=work.p16_exp_new
              outfile="&exchange_path.\name_map_ext_new.csv"
              dbms=csv replace;
  run;
  proc export data=pdd.name_map_vars_ext
              outfile="&exchange_path.\name_map_vars_ext.csv"
              dbms=csv replace;
  run;
  proc export data=pdd.qc_map_ext_candidates
              outfile="&exchange_path.\name_map_ext_candidates.csv"
              dbms=csv replace;
  run;
  %if &_n_coll = 0 %then %do;
    data _null_;
      file "&exchange_path.\name_map_ext_collisions.csv" dsd lrecl=1000;
      put 's_code,col_order,pcnr_name_base,pcnr_name_final,suffix_n,reason';
    run;
  %end;
  %else %do;
    proc export data=pdd.qc_map_ext_collisions
                outfile="&exchange_path.\name_map_ext_collisions.csv"
                dbms=csv replace;
    run;
  %end;
  proc export data=pdd.qc_map_ext_summary
              outfile="&exchange_path.\name_map_ext_summary.csv"
              dbms=csv replace;
  run;

  %if &p16a_npend > 0 %then
    %put NOTE: [16a_name_map_ext] PENDING DECISION -- &p16a_npend new columns in &p16a_npgrp groups wait for Gerard. Record SAME, DIFFERENT or RENAME rows in docs/name_map_decisions_new.csv and rerun 16a. Nothing was merged.;
  %else
    %put NOTE: [16a_name_map_ext] PASS -- all candidates decided.;

  data _null_;
    set pdd.qc_map_ext_summary;
    put "NOTE: [16a_name_map_ext] " metric +(-1) "=" value;
  run;
  %put NOTE: [16a_name_map_ext] Price naming sign-off remains PENDING.;

  proc datasets lib=work nolist nowarn;
    delete p16_: _p16_: ;
  quit;
  %restore_log;
%mend p16a_export_gate;


/* ============================================================
   SECTION 10 -- Run
   ============================================================ */

%p16a_preconditions;
%p16a_load_new;
%p16a_status;
%p16a_exact;
%p16a_decisions;
%p16a_naming;
%p16a_final;
%p16a_export_gate;
