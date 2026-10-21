/*==========================================================================
  Program : 04_name_map.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 4 -- Map every source header to a PCNR_ name or status.
            Loads pdd.import_spec (4795 rows), assigns statuses (D-04),
            cleans and shortens PCNR names (D-02/D-03), applies decision
            overrides, forms variable groups (D-01a), two-stage collision
            resolution (D-05), near-match detection (D-06).

  Reads   : pdd.import_spec (orig_col_name = original_header text),
            pdd.header_inventory (row counts per s_code only),
            pdd.key_analysis (key_var_name, key_column_type)
            docs\s06_column_class.csv, docs\name_map_decisions.csv,
            docs\name_abbrev.csv

  Writes  : pdd.name_map, pdd.name_map_vars, pdd.qc_name_map_collisions
            exchange CSVs: name_map.csv, name_map_vars.csv,
              name_map_collisions.csv, name_map_nearmatches.csv,
              name_abbrev_applied.csv

  PCM compliance:
    C1  No ?? in PROC SQL
    C2  No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH AS)
    C3  No open-code %if/%else outside %macro
    C9  LIBNAME engine before path
    C11 No macro keyword in quoted PUT string
    C13 All macro definitions in Section 0 before first call
    C14 No bare data;/set;

  Author  : GSD Phase 04 Plan 02
==========================================================================*/


/* ============================================================
   SECTION 0 -- %include, %pdd_lib, ALL macro definitions
   All macros defined here before any call (PCM C13).
   ============================================================ */

%include "&sas_path.\00_config.sas";
%pdd_lib;

/* Hard stop with loud ERROR */
%macro fail_out(msg=);
  %put ERROR: [04_name_map] &msg;
  %abort cancel;
%mend fail_out;

/* Check pdd library after fail_out is compiled */
%check_pdd_lib;

/* Route log to per-program file when running standalone */
%macro route_log;
  %if &in_pipeline = 0 %then %do;
    proc printto log="&logs_path.\04_name_map.log" new; run;
  %end;
%mend route_log;

%macro restore_log;
  %if &in_pipeline = 0 %then %do;
    proc printto; run;
  %end;
%mend restore_log;

/* Apply D-02 name cleaning steps 1-4 to a character expression.
   Parameters:
     raw=   source variable name (original_header)
     out=   target variable name (must be declared $200 or wider)
   Steps:
     1. strip whitespace
     2. replace non-alphanumeric runs with single _
     3. strip leading and trailing _
     4. prefix N_ if starts with digit
   Does NOT apply abbreviations or PCNR_ prefix (handled in Section 4). */
%macro clean_name(raw=, out=);
  &out = strip(&raw);
  &out = prxchange('s/[^A-Za-z0-9]+/_/', -1, strip(&out));
  &out = prxchange('s/^_+//', 1, strip(&out));
  &out = prxchange('s/_+$//', 1, strip(&out));
  if prxmatch('/^\d/', strip(&out)) then &out = cats('N_', strip(&out));
%mend clean_name;

/* Validate abbreviation CSV: every long/short non-blank and [A-Za-z0-9_] only */
%macro check_abbrev_csv;
  %local _nbad_ab;
  proc sql noprint;
    select count(*) into :_nbad_ab trimmed
    from work._abbrev_raw
    where strip(long) = ''
       or short = ''
       or strip(long) = strip(short)
       or prxmatch('/[^A-Za-z0-9_]/', strip(long))  > 0
       or prxmatch('/[^A-Za-z0-9_]/', strip(short)) > 0;
  quit;
  %if &_nbad_ab > 0 %then %do;
    data _null_;
      set work._abbrev_raw (where=(strip(long) = ''
              or short = ''
              or strip(long) = strip(short)
              or prxmatch('/[^A-Za-z0-9_]/', strip(long))  > 0
              or prxmatch('/[^A-Za-z0-9_]/', strip(short)) > 0));
      put 'ERROR: [04_name_map] ABBREV_BAD: ' long= short=;
    run;
    %fail_out(msg=%str(name_abbrev.csv &_nbad_ab rows: blank long/short, long=short, or non-word chars));
  %end;
  %put NOTE: [04_name_map] name_abbrev.csv validated OK;
%mend check_abbrev_csv;

/* Post-clean guard: fail if any cleaned_pre_short has leading or trailing _ */
%macro check_cleaned_anchors;
  %local _nba;
  proc sql noprint;
    select count(*) into :_nba trimmed
    from work.name_map_cleaned
    where status = 'PCNR'
      and (prxmatch('/^_/', strip(cleaned_pre_short)) > 0
           or prxmatch('/_$/', strip(cleaned_pre_short)) > 0);
  quit;
  %if &_nba > 0 %then %do;
    data _null_;
      set work.name_map_cleaned (where=(status = 'PCNR'
              and (prxmatch('/^_/', strip(cleaned_pre_short)) > 0
                   or prxmatch('/_$/', strip(cleaned_pre_short)) > 0)));
      put 'ERROR: [04_name_map] ANCHOR_BAD: ' s_code= col_order= cleaned_pre_short=;
    run;
    %fail_out(msg=%str(D-02 &_nba cleaned_pre_short values have leading/trailing underscore after strip));
  %end;
%mend check_cleaned_anchors;

/* Apply D-03 middle-elide so name fits within 27 chars.
   Keeps first _elide_first chars and last _elide_last chars joined by __.
   Never drops COM or COPY prefix (requires at least 4 chars before __).
   Parameter: nm= variable name to shorten (in-place, $200). */
%macro elide_middle(nm=);
  if length(&nm) > 27 then do;
    _elide_first = max(4, ceil((27 - 2) / 2));
    _elide_last  = 27 - 2 - _elide_first;
    if _elide_last < 1 then do;
      _elide_first = 24;
      _elide_last  = 1;
    end;
    _elide_head = prxchange('s/_+$//', 1, strip(substr(&nm, 1, _elide_first)));
    _elide_tail = prxchange('s/^_+//', 1, strip(substr(&nm, length(&nm) - _elide_last + 1)));
    &nm = cats(_elide_head, '__', _elide_tail);
  end;
%mend elide_middle;

/* Assert exact row count; %fail_out if wrong.
   Parameters: ds= dataset, expected= count, label= description */
%macro assert_rowcount(ds=, expected=, label=);
  %local _arc_n;
  proc sql noprint;
    select count(*) into :_arc_n trimmed
    from &ds;
  quit;
  %if &_arc_n ne &expected %then %do;
    %fail_out(msg=%str(&label row count=&_arc_n expected=&expected));
  %end;
%mend assert_rowcount;

/* D-08 check: verify duplicate PSID columns in s15/s17 are value-identical.
   Called from Section 3 after _psid_dup_cols is built.
   Primary column is the key_var_name from pdd.key_analysis.
   %fail_out if pdd.src_s15 or pdd.src_s17 is missing when duplicates exist. */
%macro d08_check;
  %local _nd08;
  proc sql noprint;
    select count(*) into :_nd08 trimmed
    from work._psid_dup_cols;
  quit;

  %if &_nd08 > 0 %then %do;
    %put NOTE: D-08 [04_name_map] found &_nd08 duplicate Study ID columns -- verifying value identity;
    %local _src_exists15 _src_exists17;
    %let _src_exists15 = %sysfunc(exist(pdd.src_s15));
    %let _src_exists17 = %sysfunc(exist(pdd.src_s17));

    %local _ndp _i _sc _pc _dc _ndis _nagr;
    proc sql noprint;
      select count(*) into :_ndp trimmed
      from work._d08_primary;
    quit;

    %do _i = 1 %to &_ndp;
      proc sql noprint;
        select s_code, primary_col, dup_col
        into :_sc trimmed, :_pc trimmed, :_dc trimmed
        from work._d08_primary (firstobs=&_i obs=&_i);
      quit;

      %local _src_ok;
      %let _src_ok = 0;
      %if "&_sc" = "s15" %then %do;
        %if not &_src_exists15 %then
          %fail_out(msg=%str(D-08 pdd.src_s15 missing -- cannot verify duplicate PSID));
        %let _src_ok = 1;
      %end;
      %if "&_sc" = "s17" %then %do;
        %if not &_src_exists17 %then
          %fail_out(msg=%str(D-08 pdd.src_s17 missing -- cannot verify duplicate PSID));
        %let _src_ok = 1;
      %end;

      %if &_src_ok %then %do;
        data work._d08_compare;
          set pdd.src_&_sc (keep=&_pc &_dc);
          length _norm_p $64 _norm_d $64;
          if missing(&_pc) or strip(&_pc) = '' then _norm_p = '';
          else if prxmatch('/^\d+$/', strip(&_pc)) then
            _norm_p = cats('Precede', put(input(strip(&_pc), 8.), z5.));
          else if length(strip(&_pc)) >= 7
               and lowcase(substr(strip(&_pc), 1, 7)) = 'precede'
          then _norm_p = cats('Precede', substr(strip(&_pc), 8));
          else _norm_p = strip(&_pc);

          if missing(&_dc) or strip(&_dc) = '' then _norm_d = '';
          else if prxmatch('/^\d+$/', strip(&_dc)) then
            _norm_d = cats('Precede', put(input(strip(&_dc), 8.), z5.));
          else if length(strip(&_dc)) >= 7
               and lowcase(substr(strip(&_dc), 1, 7)) = 'precede'
          then _norm_d = cats('Precede', substr(strip(&_dc), 8));
          else _norm_d = strip(&_dc);

          _both_missing = (strip(_norm_p) = '' and strip(_norm_d) = '');
          _disagree     = (not _both_missing) and (_norm_p ne _norm_d);
        run;

        proc sql noprint;
          select count(*) into :_ndis trimmed
          from work._d08_compare where _disagree = 1;
          select count(*) into :_nagr trimmed
          from work._d08_compare where not _both_missing;
        quit;

        %if &_ndis > 0 %then %do;
          data _null_;
            set work._d08_compare (where=(_disagree=1));
            put 'ERROR: [04_name_map] D08_DISAGREE: ' _norm_p= _norm_d=;
          run;
          %fail_out(msg=%str(D-08 &_sc &_ndis rows disagree between &_pc and &_dc after norm_psid));
        %end;
        %put NOTE: [04_name_map] D-08 &_sc &_nagr rows confirmed identical (0 disagreements);
      %end;
    %end;
  %end;
  %else %do;
    %put NOTE: [04_name_map] D-08 no duplicate Study ID columns found in s15/s17;
  %end;
%mend d08_check;

/* Status assignment and assertions (called from Section 3 body). */
%macro build_status;
  /* Join headers to key_analysis on upcase(key_var_name) = upcase(col_name)
     within s_code. key_column_type = 'PRECEDE_STUDY_ID' marks the KEY column. */
  proc sql noprint;
    create table work._headers_aug as
    select a.s_code,
           a.col_order,
           a.col_name,
           a.sas_type,
           a.length,
           a.original_header,
           a.trunc_flag,
           case when k.ukvn is not null then 'PRECEDE_STUDY_ID' else '' end
             as key_column_type length=20,
           c.class as col_class,
           case when d.col_name is not null then 1 else 0 end
             as duplicate_study_id
    from work.headers as a
    left join (select s_code, upcase(strip(key_var_name)) as ukvn
               from pdd.key_analysis
               where key_column_type = 'PRECEDE_STUDY_ID') as k
      on a.s_code = k.s_code
     and upcase(a.col_name) = k.ukvn
    left join work.s06class as c
      on a.col_name = c.sas_name
    left join work._psid_dup_cols as d
      on a.s_code = d.s_code and a.col_name = d.col_name;
  quit;

  /* D-04 status: DATA step IF/ELSE (not open-code %if) */
  data work.name_map_status;
    set work._headers_aug;
    length status $20;
    if duplicate_study_id = 1 then status = 'DUPLICATE_DROPPED';
    else if key_column_type = 'PRECEDE_STUDY_ID' then status = 'KEY';
    else if s_code in ('s04','s05') then status = 'LINKAGE_ONLY';
    else if col_class = 'CLOCK' then status = 'EXCLUDED_CLK';
    else status = 'PCNR';
  run;

  /* Assert: every s_code that has a PRECEDE_STUDY_ID row in key_analysis
     must have exactly 1 KEY row. Zero is also a failure. */
  proc sql noprint;
    create table work._key_expected as
    select distinct s_code
    from pdd.key_analysis
    where key_column_type = 'PRECEDE_STUDY_ID';
  quit;

  proc sql noprint;
    create table work._key_check as
    select e.s_code,
           coalesce(k.n_key, 0) as n_key
    from work._key_expected as e
    left join (select s_code, count(*) as n_key
               from work.name_map_status
               where status = 'KEY'
               group by s_code) as k
      on e.s_code = k.s_code
    where coalesce(k.n_key, 0) ne 1;
  quit;

  %local _nkwrong;
  proc sql noprint;
    select count(*) into :_nkwrong trimmed from work._key_check;
  quit;
  %if &_nkwrong > 0 %then %do;
    data _null_;
      set work._key_check;
      put 'ERROR: [04_name_map] KEY_COUNT_WRONG: ' s_code= n_key=;
    run;
    %fail_out(msg=%str(&_nkwrong files have != 1 KEY row (0 is a failure too) -- see above));
  %end;

  /* Assert EXCLUDED_CLK count for s06 = 2747 */
  %local _n_clk;
  proc sql noprint;
    select count(*) into :_n_clk trimmed
    from work.name_map_status
    where s_code = 's06' and status = 'EXCLUDED_CLK';
  quit;
  %if &_n_clk ne 2747 %then %do;
    %fail_out(msg=%str(s06 EXCLUDED_CLK=&_n_clk not 2747));
  %end;
  %put NOTE: [04_name_map] EXCLUDED_CLK=2747;
  %put NOTE: [04_name_map] Status assignment complete;
%mend build_status;

/* Apply cleaning (Section 4 body). */
%macro apply_cleaning;
  %local _n_empty_clean;
  %let _n_empty_clean = 0;

  data work.name_map_cleaned;
    set work.name_map_status;
    length cleaned_pre_short $200;
    cleaned_pre_short = '';
    if status = 'PCNR' then do;
      %clean_name(raw=original_header, out=cleaned_pre_short);
      if cleaned_pre_short = '' then do;
        put 'ERROR: [04_name_map] D-02 empty clean for: ' original_header;
        call symputx('_n_empty_clean',
          cats(input(symget('_n_empty_clean'), best.) + 1));
      end;
    end;
  run;

  %if &_n_empty_clean > 0 %then %do;
    %fail_out(msg=%str(D-02 &_n_empty_clean headers cleaned to empty string));
  %end;
  %put NOTE: [04_name_map] 0 empty-clean headers;
  %check_cleaned_anchors;
  %put NOTE: [04_name_map] Section 4 cleaning complete;
%mend apply_cleaning;

/* Apply decision RENAME overrides (Section 5 body).
   Decisions file schema: s_code_a, header_a, col_order_a, s_code_b, header_b,
     col_order_b, decision, note, new_name, decided_by, date
   Match on (s_code, col_order) when col_order_a is non-missing, else on
   original_header (case-insensitive).
   new_name takes priority over note; strip leading PCNR_ from new_name. */
%macro apply_decisions_rename;
  %local _n_decisions;
  proc sql noprint;
    select count(*) into :_n_decisions trimmed from work.decisions;
  quit;

  %if &_n_decisions = 0 %then %do;
    %put NOTE: [04_name_map] name_map_decisions.csv is empty -- no overrides to apply;
    data work.name_map_overrides;
      set work.name_map_cleaned;
      length pcnr_name_override $200;
      pcnr_name_override = '';
    run;
  %end;
  %else %do;
    /* Verify every decision row matches an existing (s_code, header/col_order) */
    proc sql noprint;
      create table work._dec_unmatched as
      select d.*
      from work.decisions as d
      left join work.name_map_cleaned as m
        on d.s_code_a = m.s_code
       and (d.col_order_a is not missing
            and d.col_order_a = m.col_order
            or d.col_order_a is missing
            and lowcase(d.header_a) = lowcase(m.original_header))
      where m.s_code is null and d.s_code_a is not null;
    quit;

    %local _n_unmatched;
    proc sql noprint;
      select count(*) into :_n_unmatched trimmed from work._dec_unmatched;
    quit;
    %if &_n_unmatched > 0 %then %do;
      data _null_;
        set work._dec_unmatched;
        put 'ERROR: [04_name_map] DEC_UNMATCHED: ' s_code_a= header_a= col_order_a=;
      run;
      %fail_out(msg=%str(&_n_unmatched decision rows do not match any name_map row));
    %end;

    /* Extract RENAME decisions; new_name wins over note; strip leading PCNR_ */
    proc sql noprint;
      create table work._rename_dec as
      select s_code_a as s_code length=4,
             header_a as orig_header length=256,
             col_order_a as col_order_dec,
             prxchange('s/^PCNR_//', 1,
               strip(case when strip(new_name) ne '' then new_name else note end))
               as rename_target length=200
      from work.decisions
      where upcase(strip(decision)) = 'RENAME' and s_code_a is not null;
    quit;

    proc sql noprint;
      create table work.name_map_overrides as
      select m.*,
             coalesce(r.rename_target, '') as pcnr_name_override length=200
      from work.name_map_cleaned as m
      left join work._rename_dec as r
        on m.s_code = r.s_code
       and (r.col_order_dec is not missing
            and m.col_order = r.col_order_dec
            or r.col_order_dec is missing
            and lowcase(m.original_header) = lowcase(r.orig_header));
    quit;
  %end;
%mend apply_decisions_rename;

/* Form variable groups (D-01a) and apply D-03 shortening (Section 6 body).

   Group rules:
     - First occurrence of lowcase(cleaned): assign base group_id G; retain G.
     - Same file seen again for same lowcase(cleaned): new group_id G',
       record as SAME_FILE_CLEANED_DUPLICATE.
     - Different file, same lowcase(cleaned): join base group_id G.

   Abbreviation rules:
     - Apply only when length(cleaned) > 27.
     - Apply longest-first; stop as soon as length <= 27.
     - Token boundary: start of string, end of string, _, digit, or
       lower-to-upper case transition.
     - Log each applied substitution with group_id. */
%macro form_groups_and_shorten;

  /* 6a. Assign group_id: same lowcase(cleaned_pre_short) across files = base group.
         Same file repeat = new group (SAME_FILE_CLEANED_DUPLICATE). */
  proc sort data=work.name_map_overrides (where=(status='PCNR' and cleaned_pre_short ne ''))
    out=work._pcnr_only;
    by s_code col_order;
  run;

  data work._pcnr_lc;
    set work._pcnr_only;
    _lc_clean = lowcase(cleaned_pre_short);
  run;

  proc sort data=work._pcnr_lc; by _lc_clean s_code col_order; run;

  data work._group_assign;
    set work._pcnr_lc;
    by _lc_clean;
    length _seen_file $500;
    retain _grp_id 0 _base_grp_id 0 _seen_file '';
    if first._lc_clean then do;
      _grp_id      = _grp_id + 1;
      _base_grp_id = _grp_id;
      _seen_file   = s_code;
      group_id     = _grp_id;
      _same_file_collision = 0;
    end;
    else if index(cats('|', _seen_file, '|'), cats('|', s_code, '|')) > 0 then do;
      /* Same file already in this lc_clean group -- new group */
      _grp_id = _grp_id + 1;
      _same_file_collision = 1;
      group_id = _grp_id;
    end;
    else do;
      /* Different file -- joins base group */
      _same_file_collision = 0;
      _seen_file = catx('|', _seen_file, s_code);
      group_id   = _base_grp_id;
    end;
    drop _seen_file _base_grp_id;
  run;

  /* 6b. Apply SAME decisions: find pairs that need group merging */
  proc sql noprint;
    create table work._same_dec as
    select s_code_a, header_a, col_order_a,
           s_code_b, header_b, col_order_b
    from work.decisions
    where upcase(strip(decision)) = 'SAME' and s_code_a is not null;
  quit;

  %local _nsg;
  proc sql noprint;
    select count(*) into :_nsg trimmed from work._same_dec;
  quit;

  data work._group_final;
    set work._group_assign;
  run;

  %if &_nsg > 0 %then %do;
    /* Map SAME pairs to group_ids; match on (s_code, col_order) or original_header */
    proc sql noprint;
      create table work._same_grpids as
      select a.group_id as grp_a, b.group_id as grp_b
      from work._same_dec as d
      inner join work._group_assign as a
        on d.s_code_a = a.s_code
       and (d.col_order_a is not missing and d.col_order_a = a.col_order
            or d.col_order_a is missing
               and lowcase(d.header_a) = lowcase(a.original_header))
      inner join work._group_assign as b
        on d.s_code_b = b.s_code
       and (d.col_order_b is not missing and d.col_order_b = b.col_order
            or d.col_order_b is missing
               and lowcase(d.header_b) = lowcase(b.original_header))
      where a.group_id ne b.group_id;
    quit;

    /* Validate: SAME must not place two same-s_code rows in one group */
    proc sql noprint;
      create table work._same_sc_bad as
      select a.s_code, s.grp_a, s.grp_b
      from work._same_grpids as s
      inner join work._group_assign as a on s.grp_a = a.group_id
      inner join work._group_assign as b on s.grp_b = b.group_id
      where a.s_code = b.s_code;
    quit;

    %local _nsc_bad;
    proc sql noprint;
      select count(*) into :_nsc_bad trimmed from work._same_sc_bad;
    quit;
    %if &_nsc_bad > 0 %then %do;
      data _null_;
        set work._same_sc_bad;
        put 'ERROR: [04_name_map] SAME_SC_BAD: ' s_code= grp_a= grp_b=;
      run;
      %fail_out(msg=%str(SAME decision places two columns from same file in one group));
    %end;

    /* Remap grp_b to grp_a */
    proc sql noprint;
      update work._group_final as g
      set group_id = (select min(s.grp_a)
                      from work._same_grpids as s
                      where s.grp_b = g.group_id)
      where group_id in (select grp_b from work._same_grpids);
    quit;
  %end;

  /* 6c. One representative name per group (lowest s_code file num, then col_order) */
  data work._grp_order;
    set work._group_final;
    _file_num = input(substr(s_code, 2), best.);
  run;

  proc sort data=work._grp_order; by group_id _file_num col_order; run;

  data work._grp_rep;
    set work._grp_order;
    by group_id;
    if first.group_id;
    keep group_id cleaned_pre_short pcnr_name_override;
  run;

  /* 6d. Apply abbreviation table then elide.
         Abbreviation: only when length > 27; longest-first; stop as soon as <= 27.
         Token boundary: start, end, _, digit, or lower-to-upper transition. */
  %local _ngrep;
  proc sql noprint;
    select count(*) into :_ngrep trimmed from work._grp_rep;
  quit;

  %local _abbrev_longer;
  %let _abbrev_longer = 0;

  data work._grp_names (keep=group_id pcnr_name_base _elided)
       work._abbrev_hits (keep=group_id long short cleaned_before cleaned_after);
    length group_id 8
           pcnr_name_base $200
           _nm $200 _cbe $200 _pat $400 _pre_elide $200
           long $200 short $200
           cleaned_before $200 cleaned_after $200
           _elide_first 8 _elide_last 8 _nab_tot 8 _elided 8
           _elide_head $200 _elide_tail $200;

    /* Load total abbreviation count once without reading row 0 */
    if 0 then set work.abbrev (keep=long short _longlen) nobs=_nab_tot;
    retain _nab_tot;

    set work._grp_rep;

    _nm     = cleaned_pre_short;
    _elided = 0;
    if pcnr_name_override ne '' then _nm = pcnr_name_override;
    else do;
      /* Apply abbreviations longest-first; only when length > 27; stop early.
         long/short validated [A-Za-z0-9_] only -- no regex escaping needed. */
      if length(strip(_nm)) > 27 then do _ai = 1 to _nab_tot;
        set work.abbrev (keep=long short _longlen) point=_ai;
        if length(strip(_nm)) <= 27 then leave;
        _cbe = _nm;
        /* Token boundary: start | after _ or digit | after lowercase (camelCase) */
        _pat = cats('s/(?:^|(?<=[_0-9a-z]))', strip(long), '(?=[A-Z0-9_]|$)/', strip(short), '/');
        _nm  = prxchange(_pat, -1, strip(_nm));
        if strip(_nm) ne strip(_cbe) then do;
          if length(strip(_nm)) > length(strip(_cbe)) then do;
            put 'ERROR: [04_name_map] abbreviation made name longer: '
                long= short= _cbe= _nm=;
            call symputx('_abbrev_longer', '1', 'L');
          end;
          cleaned_before = _cbe;
          cleaned_after  = _nm;
          output work._abbrev_hits;
        end;
      end;
      /* Elide if still > 27 chars after abbreviation */
      _pre_elide = _nm;
      %elide_middle(nm=_nm);
      _elided = (strip(_nm) ne strip(_pre_elide));
    end;
    pcnr_name_base = strip(_nm);
    output work._grp_names;
  run;

  %if &_abbrev_longer = 1 %then
    %fail_out(msg=%str(abbreviation made one or more names longer -- see ERROR above));

  /* Guard: pcnr_name_base must contain only [A-Za-z0-9_] and no triple underscores */
  %local _n_badbase;
  proc sql noprint;
    select count(*) into :_n_badbase trimmed
    from work._grp_names
    where prxmatch('/[^A-Za-z0-9_]/', strip(pcnr_name_base)) > 0
       or prxmatch('/___/',            strip(pcnr_name_base)) > 0;
  quit;
  %if &_n_badbase > 0 %then %do;
    data _null_;
      set work._grp_names (where=(prxmatch('/[^A-Za-z0-9_]/', strip(pcnr_name_base)) > 0
              or prxmatch('/___/', strip(pcnr_name_base)) > 0));
      put 'ERROR: [04_name_map] BADBASE: ' group_id= pcnr_name_base=;
    run;
    %fail_out(msg=%str(&_n_badbase pcnr_name_base values have invalid chars or triple underscores));
  %end;

  /* Join pcnr_name_base back to all rows */
  proc sql noprint;
    create table work._gid_map as
    select g.group_id, gn.pcnr_name_base, g.s_code, g.col_name
    from work._group_final as g
    inner join work._grp_names as gn
      on g.group_id = gn.group_id;
  quit;

  proc sql noprint;
    create table work.name_map_grouped as
    select m.*,
           coalesce(gm.group_id, .) as group_id,
           coalesce(gm.pcnr_name_base, '') as pcnr_name_base length=200,
           coalesce(sc._same_file_collision, 0) as same_file_collision
    from work.name_map_overrides as m
    left join work._gid_map as gm
      on m.s_code = gm.s_code and m.col_name = gm.col_name
    left join (select s_code, col_name, _same_file_collision
               from work._group_final) as sc
      on m.s_code = sc.s_code and m.col_name = sc.col_name;
  quit;

  %put NOTE: [04_name_map] Section 6 groups and shortening complete;
%mend form_groups_and_shorten;

/* Stage 1 collision suffix between groups (Section 7 body).
   If base + suffix > 27, re-apply middle-elide to the base (not cut end).
   Choose next suffix not already used by any final name in this run. */
%macro stage1_suffix;
  /* Representative row per group for ordering */
  proc sort data=work.name_map_grouped (where=(status='PCNR' and group_id>.))
    out=work._pcnr_grp;
    by group_id s_code col_order;
  run;

  data work._grp_order2;
    set work._pcnr_grp;
    by group_id;
    if first.group_id;
    _file_num = input(substr(s_code, 2), best.);
    _base_uc  = upcase(pcnr_name_base);
    keep group_id pcnr_name_base _base_uc _file_num col_order;
  run;

  proc sort data=work._grp_order2; by _base_uc _file_num col_order; run;

  data work._suffix_assign;
    set work._grp_order2;
    by _base_uc;
    retain _suffix_counter 1;
    if first._base_uc then _suffix_counter = 1;
    _suffix_n = _suffix_counter;
    _suffix_counter = _suffix_counter + 1;
  run;

  /* Build Stage 1 collision records */
  proc sql noprint;
    create table work._coll_stage1 as
    select a.group_id,
           a.pcnr_name_base as base_name length=200,
           '' as pcnr_name_final length=200,
           a._suffix_n as suffix_n,
           'BETWEEN_GROUP_SUFFIX' as reason length=30
    from work._suffix_assign as a
    where a._suffix_n > 1;
  quit;

  /* Same-file collision records from Section 6 */
  proc sql noprint;
    create table work._coll_samefile as
    select coalesce(group_id, .) as group_id,
           pcnr_name_base as base_name length=200,
           '' as pcnr_name_final length=200,
           2  as suffix_n,
           'SAME_FILE_CLEANED_DUPLICATE' as reason length=30
    from work.name_map_grouped
    where same_file_collision = 1 and status = 'PCNR';
  quit;

  /* Build final pcnr_name with suffix.
     If base + suffix > 27: re-apply middle-elide to base (not cut end).
     Use a hash to track all final names and pick next unused suffix. */
  data work._suffix_final;
    if _N_ = 1 then do;
      /* Pre-populate hash with all unsuffixed (suffix_n=1) names */
      declare hash _used();
      _used.defineKey('_k');
      _used.defineDone();
      do until (_eof1);
        set work._suffix_assign (where=(_suffix_n=1)) end=_eof1;
        _k = lowcase(pcnr_name_base);
        _used.replace();
      end;
    end;
    set work._suffix_assign;
    length pcnr_name_final $200 _sfx $10 _base_trim $200 _candidate $200 _k $200;
    _elide_first = 0;
    _elide_last  = 0;
    if _suffix_n = 1 then pcnr_name_final = pcnr_name_base;
    else do;
      _try = _suffix_n;
      do while (_try < 1000);
        _sfx     = cats('_', put(_try, best.));
        _allowed = 27 - length(_sfx);
        _base_trim = pcnr_name_base;
        /* Re-apply middle-elide to base if needed */
        if length(_base_trim) > _allowed then do;
          _elide_first = max(4, ceil((_allowed - 2) / 2));
          _elide_last  = _allowed - 2 - _elide_first;
          if _elide_last < 1 then do;
            _elide_first = _allowed - 3;
            _elide_last  = 1;
          end;
          _base_trim = cats(substr(_base_trim, 1, _elide_first), '__',
                            substr(_base_trim, length(_base_trim) - _elide_last + 1));
        end;
        _candidate = cats(_base_trim, _sfx);
        _k = lowcase(_candidate);
        if _used.check() ne 0 then do;
          pcnr_name_final = _candidate;
          _used.replace();
          leave;
        end;
        _try = _try + 1;
      end;
      if _try >= 1000 then
        put 'ERROR: [04_name_map] stage1_suffix exhausted 1000 suffix tries for: ' pcnr_name_base;
    end;
    keep group_id pcnr_name_base pcnr_name_final _suffix_n;
  run;

  /* Update collision table with final names */
  proc sql noprint;
    update work._coll_stage1 as c
    set pcnr_name_final = (select sf.pcnr_name_final
                           from work._suffix_final as sf
                           where sf.group_id = c.group_id)
    where c.suffix_n > 1;
  quit;

  data pdd.qc_name_map_collisions;
    set work._coll_stage1 work._coll_samefile;
  run;

  /* Join final pcnr_name to all rows */
  proc sql noprint;
    create table work.name_map_suffixed as
    select m.*,
           case
             when m.status = 'PCNR' and m.group_id > .
             then cats('PCNR_', sf.pcnr_name_final)
             else ''
           end as pcnr_name length=200
    from work.name_map_grouped as m
    left join work._suffix_final as sf
      on m.group_id = sf.group_id;
  quit;

  %local _ncoll;
  proc sql noprint;
    select count(*) into :_ncoll trimmed from pdd.qc_name_map_collisions;
  quit;
  %put NOTE: [04_name_map] Stage 1 complete -- &_ncoll collision rows in qc_name_map_collisions;

  /* Stage 1 summary */
  %local _s1_groups _s1_abbrev _s1_elided _s1_btwn _s1_sf;
  proc sql noprint;
    select count(distinct group_id) into :_s1_groups trimmed
      from work.name_map_grouped where status = 'PCNR' and group_id > .;
    select count(distinct group_id) into :_s1_abbrev trimmed
      from work._abbrev_hits;
    select count(*) into :_s1_elided trimmed
      from work._grp_names where _elided = 1;
    select count(*) into :_s1_btwn trimmed from work._coll_stage1;
    select count(*) into :_s1_sf   trimmed from work._coll_samefile;
  quit;
  %put NOTE: [04_name_map] PHASE 4 STAGE 1 SUMMARY:;
  %put NOTE: [04_name_map]   PCNR groups               = &_s1_groups;
  %put NOTE: [04_name_map]   groups shortened (abbrev)  = &_s1_abbrev;
  %put NOTE: [04_name_map]   groups elided              = &_s1_elided;
  %put NOTE: [04_name_map]   between-group suffixes     = &_s1_btwn;
  %put NOTE: [04_name_map]   same-file suffixes         = &_s1_sf;

  /* Self-check: Stage 1 must not leave two groups sharing the same case-folded final name */
  proc sql noprint;
    create table work._s1_missed as
    select upcase(strip(pcnr_name_final)) as name_uc length=200,
           count(distinct group_id) as n_grps
    from work._suffix_final
    where strip(pcnr_name_final) ne ''
    group by upcase(strip(pcnr_name_final))
    having count(distinct group_id) > 1;
  quit;

  %local _n_s1_missed;
  proc sql noprint;
    select count(*) into :_n_s1_missed trimmed from work._s1_missed;
  quit;
  %if &_n_s1_missed > 0 %then %do;
    proc sql noprint;
      create table work._s1_missed_detail as
      select sf.group_id, sf.pcnr_name_base, sf.pcnr_name_final,
             m.s_code, m.col_order, m.original_header
      from work._suffix_final as sf
      inner join work._s1_missed as ms
        on upcase(strip(sf.pcnr_name_final)) = ms.name_uc
      left join work.name_map_grouped as m
        on sf.group_id = m.group_id and m.status = 'PCNR'
      order by sf.pcnr_name_final, sf.group_id, m.s_code, m.col_order;
    quit;
    data _null_;
      set work._s1_missed_detail;
      put 'ERROR: [04_name_map] S1_MISSED: ' pcnr_name_final= group_id= pcnr_name_base= s_code= col_order= original_header=;
    run;
    %fail_out(msg=%str(Stage 1 missed &_n_s1_missed case-insensitive collisions -- see ERROR above));
  %end;
  %put NOTE: [04_name_map] Stage 1 self-check passed (&_n_s1_missed missed collisions);
%mend stage1_suffix;

/* Stage 2 hard-stop (Section 8 body).
   Duplicate = count(distinct group_id) > 1 per upcase(pcnr_name). */
%macro stage2_validate;
  /* Check 1: case-insensitive duplicate pcnr_name -- different group_ids with same name */
  proc sql noprint;
    create table work._s2_dups as
    select pcnr_name, count(distinct group_id) as n_groups
    from work.name_map_suffixed
    where status = 'PCNR' and pcnr_name ne ''
    group by upcase(pcnr_name)
    having count(distinct group_id) > 1;
  quit;

  %local _n_s2_dups;
  proc sql noprint;
    select count(*) into :_n_s2_dups trimmed from work._s2_dups;
  quit;
  %if &_n_s2_dups > 0 %then %do;
    proc sql noprint;
      create table work._s2_dups_detail as
      select m.pcnr_name, m.group_id, m.s_code, m.col_order, m.original_header
      from work.name_map_suffixed as m
      inner join work._s2_dups as d
        on upcase(m.pcnr_name) = upcase(d.pcnr_name)
      where m.status = 'PCNR' and m.pcnr_name ne ''
      order by m.pcnr_name, m.group_id, m.s_code, m.col_order;
    quit;
    data _null_;
      set work._s2_dups_detail;
      put 'ERROR: [04_name_map] S2_DUP: ' pcnr_name= group_id= s_code= col_order= original_header=;
    run;
    %fail_out(msg=%str(Stage 2 -- &_n_s2_dups PCNR_ names assigned to multiple groups));
  %end;

  /* Check 2: length > 32 */
  proc sql noprint;
    create table work._s2_toolong as
    select pcnr_name, length(pcnr_name) as name_len
    from work.name_map_suffixed
    where status = 'PCNR' and length(pcnr_name) > 32;
  quit;

  %local _n_s2_long;
  proc sql noprint;
    select count(*) into :_n_s2_long trimmed from work._s2_toolong;
  quit;
  %if &_n_s2_long > 0 %then %do;
    data _null_;
      set work._s2_toolong;
      put 'ERROR: [04_name_map] S2_TOOLONG: ' pcnr_name= name_len=;
    run;
    %fail_out(msg=%str(Stage 2 -- &_n_s2_long PCNR_ names exceed 32 characters));
  %end;

  /* Check 3: invalid SAS V7 name */
  proc sql noprint;
    create table work._s2_invalid as
    select pcnr_name
    from work.name_map_suffixed
    where status = 'PCNR'
      and pcnr_name ne ''
      and not nvalid(pcnr_name, 'v7');
  quit;

  %local _n_s2_inv;
  proc sql noprint;
    select count(*) into :_n_s2_inv trimmed from work._s2_invalid;
  quit;
  %if &_n_s2_inv > 0 %then %do;
    data _null_;
      set work._s2_invalid;
      put 'ERROR: [04_name_map] S2_INVALID: ' pcnr_name=;
    run;
    %fail_out(msg=%str(Stage 2 -- &_n_s2_inv PCNR_ names are not valid SAS V7 names));
  %end;

  %put NOTE: [04_name_map] Stage 2 passed;

  data work.name_map_core;
    set work.name_map_suffixed;
    if length(original_header) >= 256 then
      put 'NOTE: [04_name_map] LABEL TRUNCATED: ' s_code= col_order= col_name=;
  run;

  %put NOTE: [04_name_map] work.name_map_core ready;
%mend stage2_validate;

/* DRY-RUN gate: when env var PDD_DRYRUN=1, stop after Section 3 and
   print diagnostics (rows loaded, status counts, KEY rows, D-08 result). */
%macro pdd_dryrun_gate;
  %local _dryrun_flag;
  %if %sysfunc(sysexist(PDD_DRYRUN)) %then
    %let _dryrun_flag = %sysget(PDD_DRYRUN);
  %else %let _dryrun_flag = 0;

  %if "&_dryrun_flag" = "1" %then %do;
    %put NOTE: [04_name_map] PDD_DRYRUN=1 -- stopping after Section 3;

    %local _n_spec;
    proc sql noprint;
      select count(*) into :_n_spec trimmed from work.headers;
    quit;
    %put NOTE: [04_name_map] DRYRUN rows loaded from import_spec: &_n_spec;

    %put NOTE: [04_name_map] DRYRUN status counts by s_code:;
    proc sql;
      select s_code, status, count(*) as n
      from work.name_map_status
      group by s_code, status
      order by s_code, status;
    quit;

    %put NOTE: [04_name_map] DRYRUN KEY rows per file:;
    proc sql;
      select s_code, count(*) as n_key
      from work.name_map_status
      where status = 'KEY'
      group by s_code;
    quit;

    %local _nd08_dr;
    proc sql noprint;
      select count(*) into :_nd08_dr trimmed from work._psid_dup_cols;
    quit;
    %put NOTE: [04_name_map] DRYRUN D-08 duplicate PSID columns: &_nd08_dr;

    %restore_log;
    %abort cancel;
  %end;
%mend pdd_dryrun_gate;


/* Delete Phase 4 exchange CSVs so a failed run cannot leave stale files
   for the Python step. Called after Section 1 preconditions pass. */
%macro delete_stale_csvs;
  %local _fi _fname _rc;
  %local _f1 _f2 _f3 _f4 _f5 _f6;
  %let _f1 = name_map.csv;
  %let _f2 = name_map_vars.csv;
  %let _f3 = name_map_collisions.csv;
  %let _f4 = name_map_nearmatches.csv;
  %let _f5 = name_abbrev_applied.csv;
  %let _f6 = name_map_decisions_template.csv;
  %do _fi = 1 %to 6;
    %let _fname = &&_f&_fi;
    filename _dlcsvf "&exchange_path.\&_fname";
    %let _rc = %sysfunc(fdelete(_dlcsvf));
    %if &_rc = 0 %then
      %put NOTE: [04_name_map] deleted stale exchange CSV: &_fname;
    %else
      %put NOTE: [04_name_map] exchange CSV not present (no delete needed): &_fname;
    filename _dlcsvf clear;
  %end;
%mend delete_stale_csvs;


/* ============================================================
   SECTION 1 -- Assertions: 4795 rows, unique on (file_code, col_order)
   ============================================================ */

%route_log;

%macro check_import_spec_counts;
  %local _n_total _n_distinct;
  proc sql noprint;
    select count(*)
      into :_n_total trimmed
    from pdd.import_spec;

    select count(distinct catx('|', file_code, put(col_order, best.)))
      into :_n_distinct trimmed
    from pdd.import_spec;
  quit;
  %if &_n_total ne 4795 %then %do;
    %fail_out(msg=%str(import_spec row count=&_n_total expected=4795));
  %end;
  %if &_n_distinct ne 4795 %then %do;
    %fail_out(msg=%str(import_spec distinct file_code+col_order=&_n_distinct -- duplicates present));
  %end;
  %put NOTE: [04_name_map] 4795 rows confirmed in pdd.import_spec;
%mend check_import_spec_counts;
%check_import_spec_counts;

/* Per-s_code count comparison with header_inventory (count only) */
proc sql noprint;
  create table work._sc_check as
  select a.file_code as s_code,
         a.n_spec,
         b.n_inv
  from (select file_code, count(*) as n_spec
        from pdd.import_spec
        group by file_code) as a
  left join
       (select s_code, count(*) as n_inv
        from pdd.header_inventory
        group by s_code) as b
    on a.file_code = b.s_code
  having a.n_spec ne b.n_inv;
quit;

%macro check_per_scode;
  %local _nmis;
  proc sql noprint;
    select count(*) into :_nmis trimmed from work._sc_check;
  quit;
  %if &_nmis > 0 %then %do;
    data _null_;
      set work._sc_check;
      put 'ERROR: [04_name_map] SC_COUNT_MISMATCH: ' s_code= n_spec= n_inv=;
    run;
    %fail_out(msg=%str(import_spec and header_inventory row counts differ for &_nmis s_code values));
  %end;
  %put NOTE: [04_name_map] per-s_code row counts match header_inventory;
%mend check_per_scode;
%check_per_scode;

%put NOTE: [04_name_map] 4795 rows;

%delete_stale_csvs;


/* ============================================================
   SECTION 2 -- Load inputs
   ============================================================ */

/* Log column names of key inputs for diagnostics */
proc contents data=pdd.import_spec noprint
  out=work._is_cols (keep=name varnum); run;
proc contents data=pdd.key_analysis noprint
  out=work._ka_cols (keep=name varnum); run;

/* 2a. Base spec */
data work.importspec;
  set pdd.import_spec;
run;

/* 2b. Headers: build directly from pdd.import_spec.
        original_header = first 256 chars of orig_col_name.
        trunc_flag = 1 when orig_col_name length >= 256.
        col_name = sas_name (column in pdd.src_<s_code>). */
data work.headers;
  set pdd.import_spec (rename=(file_code=s_code sas_name=col_name));
  length original_header $256;
  original_header = strip(orig_col_name);
  trunc_flag      = (length(strip(orig_col_name)) >= 256);
  keep s_code col_order col_name sas_type length orig_col_name original_header trunc_flag;
run;

%macro check_orig_col_name;
  %local _n_empty_orig;
  proc sql noprint;
    select count(*) into :_n_empty_orig trimmed
    from work.headers
    where original_header = '';
  quit;
  %if &_n_empty_orig > 0 %then %do;
    %fail_out(msg=%str(&_n_empty_orig import_spec rows have blank orig_col_name));
  %end;
  %put NOTE: [04_name_map] All import_spec rows have non-empty original_header;
%mend check_orig_col_name;
%check_orig_col_name;

/* 2c. Key analysis -- keep key_var_name for join */
data work.keyanalysis;
  set pdd.key_analysis (keep=s_code key_column_type key_var_name);
run;

/* 2d. S06 column class -- DATA step INFILE (03_import pattern) */
data work.s06class;
  length sas_name $32 orig_col_name $256 token $100 class $20 rule $200;
  infile "&sas_path.\..\docs\s06_column_class.csv"
         encoding='utf-8' dsd dlm=',' missover firstobs=2 lrecl=32767;
  input sas_name $ orig_col_name $ token $ class $ rule $;
  sas_name = strip(sas_name);
  class    = strip(class);
  if sas_name = '' then delete;
  keep sas_name class;
run;

/* 2e. Decision overrides (may be header-only) -- DATA step INFILE.
        Schema: s_code_a, header_a, col_order_a, s_code_b, header_b,
                col_order_b, decision, note, new_name, decided_by, date */
data work.decisions;
  length s_code_a $4    header_a $256    col_order_a 8
         s_code_b $4    header_b $256    col_order_b 8
         decision $20   note $200        new_name $200
         decided_by $50 date $10;
  infile "&sas_path.\..\docs\name_map_decisions.csv"
         encoding='utf-8' dsd dlm=',' missover firstobs=2 lrecl=32767;
  input s_code_a $ header_a $ col_order_a
        s_code_b $ header_b $ col_order_b
        decision $ note $ new_name $ decided_by $ date $;
  s_code_a   = strip(s_code_a);
  header_a   = strip(header_a);
  s_code_b   = strip(s_code_b);
  header_b   = strip(header_b);
  decision   = strip(decision);
  note       = strip(note);
  new_name   = strip(new_name);
  decided_by = strip(decided_by);
  date       = strip(date);
  if strip(decision) = '' and strip(s_code_a) = '' then delete;
run;

/* 2f. Abbreviation table -- DATA step INFILE; sort desc by long length */
data work._abbrev_raw;
  length long $200 short $200;
  infile "&sas_path.\..\docs\name_abbrev.csv"
         encoding='utf-8' dsd dlm=',' missover firstobs=2 lrecl=32767;
  input long $ short $;
  long  = strip(long);
  short = strip(short);
  if long = '' then delete;
run;

data work.abbrev;
  set work._abbrev_raw;
  _longlen = length(long);
run;

proc sort data=work.abbrev; by descending _longlen; run;

%check_abbrev_csv;


/* ============================================================
   SECTION 3 -- D-08 duplicate Study ID (s15, s17) THEN status
   ============================================================ */

/* 3a. Identify PSID-like headers in s15/s17 via original_header */
proc sql noprint;
  create table work._psid_headers as
  select s_code, col_name, col_order, original_header
  from work.headers
  where s_code in ('s15','s17')
    and prxmatch('/PRECEDE.?Study.?ID/i', original_header) > 0
  order by s_code, col_order;
quit;

/* 3b. Duplicate columns = all beyond the primary (key_var_name) per file */
proc sql noprint;
  create table work._psid_dup_cols as
  select h.s_code, h.col_name, h.col_order
  from work._psid_headers as h
  where not exists (
    select 1 from pdd.key_analysis as k
    where k.s_code = h.s_code
      and k.key_column_type = 'PRECEDE_STUDY_ID'
      and upcase(k.key_var_name) = upcase(h.col_name));
quit;

/* 3c. Build _d08_primary: key_var_name column vs each dup column */
proc sql noprint;
  create table work._d08_primary as
  select h.s_code,
         h.col_name as primary_col,
         d.col_name as dup_col
  from work._psid_headers as h
  inner join pdd.key_analysis as k
    on h.s_code = k.s_code
   and k.key_column_type = 'PRECEDE_STUDY_ID'
   and upcase(k.key_var_name) = upcase(h.col_name)
  inner join work._psid_dup_cols as d
    on h.s_code = d.s_code;
quit;

/* 3d. D-08 value comparison */
%d08_check;

/* 3e. Status assignment */
%build_status;

/* 3f. DRY-RUN gate: PDD_DRYRUN=1 stops here */
%pdd_dryrun_gate;


/* ============================================================
   SECTION 4 -- D-02 Name cleaning (PCNR rows only)
   ============================================================ */

%apply_cleaning;


/* ============================================================
   SECTION 5 -- Decision RENAME overrides
   ============================================================ */

%apply_decisions_rename;


/* ============================================================
   SECTION 6 -- Variable groups (D-01a) and D-03 shortening
   ============================================================ */

%form_groups_and_shorten;


/* ============================================================
   SECTION 7 -- Stage 1 collision suffix between groups (D-05)
   ============================================================ */

%stage1_suffix;


/* ============================================================
   SECTION 8 -- Stage 2 hard-stop validation (D-05)
   ============================================================ */

%stage2_validate;


/* ============================================================
   SECTION 9 -- Near-match detection (D-06)
   ============================================================ */

%macro section9_nearmatches;
  /* ── Step 1: Group-level representative (lowest s_code, then col_order) ── */
  proc sql noprint;
    create table work._nm_grp_rep as
    select distinct c.group_id,
           c.s_code,
           c.col_order,
           c.original_header,
           c.cleaned_pre_short
    from work.name_map_core as c
    where c.status = 'PCNR'
      and c.cleaned_pre_short ne ''
      and c.s_code = (
        select min(c2.s_code)
        from work.name_map_core as c2
        where c2.group_id = c.group_id
          and c2.status   = 'PCNR'
          and c2.cleaned_pre_short ne '')
      and c.col_order = (
        select min(c2.col_order)
        from work.name_map_core as c2
        where c2.group_id = c.group_id
          and c2.s_code   = c.s_code
          and c2.status   = 'PCNR'
          and c2.cleaned_pre_short ne '');
  quit;

  /* ── Step 2: File list (n_files, pipe-separated scodes) per group ──────── */
  proc sort data=work.name_map_core (
      where=(status='PCNR' and cleaned_pre_short ne '')
      keep=group_id s_code)
    out=work._nm_grp_detail nodupkey;
    by group_id s_code;
  run;

  data work._nm_grp_files;
    length scodes $500;
    retain scodes '' n_files 0;
    set work._nm_grp_detail;
    by group_id;
    if first.group_id then do; scodes = ''; n_files = 0; end;
    scodes  = catx('|', scodes, s_code);
    n_files + 1;
    if last.group_id then output;
    keep group_id scodes n_files;
  run;

  /* ── Step 3: Join representative to file stats ──────────────────────────── */
  proc sql noprint;
    create table work._nm_grp as
    select r.group_id, r.s_code, r.col_order, r.original_header,
           r.cleaned_pre_short, f.n_files, f.scodes
    from work._nm_grp_rep as r
    inner join work._nm_grp_files as f on r.group_id = f.group_id;
  quit;

  /* ── Step 4: Group-level near-match pairs ───────────────────────────────── */
  /* Edit-distance pairs (a.group_id < b.group_id — one row per group pair) */
  proc sql noprint;
    create table work._nm_gpairs_edit as
    select a.group_id         as group_id_a,
           a.s_code           as s_code_a,
           a.col_order        as col_order_a,
           a.original_header  as original_header_a,
           a.cleaned_pre_short as name_a,
           a.n_files          as n_files_a,
           a.scodes           as scodes_a,
           b.group_id         as group_id_b,
           b.s_code           as s_code_b,
           b.col_order        as col_order_b,
           b.original_header  as original_header_b,
           b.cleaned_pre_short as name_b,
           b.n_files          as n_files_b,
           b.scodes           as scodes_b,
           complev(lowcase(a.cleaned_pre_short),
                   lowcase(b.cleaned_pre_short)) as edit_dist,
           'EDIT_DISTANCE' as match_type length=20
    from work._nm_grp as a, work._nm_grp as b
    where a.group_id < b.group_id
      and abs(length(a.cleaned_pre_short) - length(b.cleaned_pre_short)) <= 2
      and complev(lowcase(a.cleaned_pre_short),
                  lowcase(b.cleaned_pre_short)) <= 2
      and lowcase(a.cleaned_pre_short) ne lowcase(b.cleaned_pre_short);
  quit;

  /* Trailing-suffix pairs — tested in BOTH directions */
  proc sql noprint;
    create table work._nm_gpairs_suffix as
    select a.group_id         as group_id_a,
           a.s_code           as s_code_a,
           a.col_order        as col_order_a,
           a.original_header  as original_header_a,
           a.cleaned_pre_short as name_a,
           a.n_files          as n_files_a,
           a.scodes           as scodes_a,
           b.group_id         as group_id_b,
           b.s_code           as s_code_b,
           b.col_order        as col_order_b,
           b.original_header  as original_header_b,
           b.cleaned_pre_short as name_b,
           b.n_files          as n_files_b,
           b.scodes           as scodes_b,
           . as edit_dist,
           'TRAILING_SUFFIX' as match_type length=20
    from work._nm_grp as a, work._nm_grp as b
    where a.group_id < b.group_id
      and (
        /* a has suffix, stripped a = b */
        (prxmatch('/(_\d+|_dup\d*)$/i', strip(a.cleaned_pre_short)) > 0
         and lowcase(prxchange('s/(_\d+|_dup\d*)$//i', 1, strip(a.cleaned_pre_short)))
             = lowcase(strip(b.cleaned_pre_short)))
        or
        /* b has suffix, stripped b = a */
        (prxmatch('/(_\d+|_dup\d*)$/i', strip(b.cleaned_pre_short)) > 0
         and lowcase(prxchange('s/(_\d+|_dup\d*)$//i', 1, strip(b.cleaned_pre_short)))
             = lowcase(strip(a.cleaned_pre_short)))
      );
  quit;

  /* ── Step 5: Union, stage counts, co-occurrence exclusion ──────────────── */
  proc sql noprint;
    create table work._nm_gpairs_all as
    select distinct * from (
      select * from work._nm_gpairs_edit
      union all
      select * from work._nm_gpairs_suffix);
  quit;

  %local _n_raw _n_after_cooc _n_cooc_removed _n_nm;
  proc sql noprint;
    select count(*) into :_n_raw trimmed from work._nm_gpairs_all;
  quit;
  %put NOTE: [S9] raw group-level pairs=&_n_raw;

  /* Remove pairs where both groups share at least one source file (D-01a) */
  proc sql noprint;
    create table pdd.name_map_nearmatches as
    select *
    from work._nm_gpairs_all as p
    where not exists (
      select 1
      from work._nm_grp_detail as da
      inner join work._nm_grp_detail as db
        on da.s_code = db.s_code
      where da.group_id = p.group_id_a
        and db.group_id = p.group_id_b);
  quit;

  proc sql noprint;
    select count(*) into :_n_after_cooc trimmed from pdd.name_map_nearmatches;
  quit;
  %let _n_cooc_removed = %eval(&_n_raw - &_n_after_cooc);
  %put NOTE: [S9] after co-occurrence exclusion=&_n_after_cooc (removed &_n_cooc_removed co-occurring group pairs);

  %let _n_nm = &_n_after_cooc;
  %put NOTE: near-match pair count=&_n_nm;

  %if &_n_nm > 200 %then %do;
    proc freq data=pdd.name_map_nearmatches order=freq noprint;
      tables match_type / out=work._nm_top;
    run;
    data _null_;
      set work._nm_top;
      put 'ERROR: [04_name_map] NM_TYPE: ' match_type= count=;
    run;
    data _null_;
      set pdd.name_map_nearmatches (obs=20);
      put 'ERROR: [04_name_map] NEARMATCH: ' group_id_a= name_a= scodes_a=
          group_id_b= name_b= scodes_b= edit_dist= match_type=;
    run;
    %fail_out(msg=%str(D-06 near-match pair count=&_n_nm exceeds 200 -- resolve before continuing));
  %end;

  /* Count undecided pairs; decisions match on representative (s_code, col_order) */
  %local _n_undecided;
  proc sql noprint;
    select count(*) into :_n_undecided trimmed
    from pdd.name_map_nearmatches as nm
    where not exists (
      select 1 from work.decisions as d
      where upcase(strip(d.decision)) in ('SAME','DIFFERENT')
        and ((d.s_code_a = nm.s_code_a
              and (d.col_order_a is not missing and d.col_order_a = nm.col_order_a
                   or d.col_order_a is missing
                      and lowcase(d.header_a) = lowcase(nm.original_header_a))
              and d.s_code_b = nm.s_code_b
              and (d.col_order_b is not missing and d.col_order_b = nm.col_order_b
                   or d.col_order_b is missing
                      and lowcase(d.header_b) = lowcase(nm.original_header_b)))
          or (d.s_code_a = nm.s_code_b
              and (d.col_order_a is not missing and d.col_order_a = nm.col_order_b
                   or d.col_order_a is missing
                      and lowcase(d.header_a) = lowcase(nm.original_header_b))
              and d.s_code_b = nm.s_code_a
              and (d.col_order_b is not missing and d.col_order_b = nm.col_order_a
                   or d.col_order_b is missing
                      and lowcase(d.header_b) = lowcase(nm.original_header_a)))));
  quit;
  %put NOTE: [04_name_map] undecided near-match pairs=&_n_undecided;
  %if &_n_undecided > 0 %then
    %put NOTE: [04_name_map] undecided>0 means phase not complete -- resolve via docs/name_map_decisions.csv;
  %put NOTE: [04_name_map] Section 9 near-match detection complete;
%mend section9_nearmatches;

%section9_nearmatches;


/* ============================================================
   SECTION 10 -- D-08 confirmed
   ============================================================ */

%put NOTE: Section 10 D-08 confirmed in Plan 02;
%put NOTE: [04_name_map] DUPLICATE_DROPPED rows from s15/s17 verified in Section 3;


/* ============================================================
   SECTION 11 -- Type tracking (D-07)
   ============================================================ */

%macro section11_types;
  proc sql noprint;
    create table work._nm_typed as
    select c.*,
           coalesce(s.sas_type, c.sas_type) as spec_sas_type  length=1,
           coalesce(s.length,   c.length)   as spec_length
    from work.name_map_core as c
    left join pdd.import_spec as s
      on c.s_code    = s.file_code
     and c.col_order = s.col_order;
  quit;

  proc sql noprint;
    create table work._var_types as
    select pcnr_name,
           case when max(case when upcase(spec_sas_type)='C' then 1 else 0 end) = 1
                then 'C' else 'N' end as result_type length=1,
           max(spec_length)           as max_length,
           case when max(case when upcase(spec_sas_type)='C' then 1 else 0 end) = 1
                 and max(case when upcase(spec_sas_type)='N' then 1 else 0 end) = 1
                then 'Y' else 'N' end as type_conflict length=1,
           count(distinct s_code)     as n_sources
    from work._nm_typed
    where status = 'PCNR' and pcnr_name ne ''
    group by pcnr_name;
  quit;

  %local _ntc;
  proc sql noprint;
    select count(*) into :_ntc trimmed
    from work._var_types
    where type_conflict = 'Y';
  quit;
  %put NOTE: [04_name_map] type_conflict variable count=&_ntc;

  %if &_ntc > 0 %then %do;
    data _null_;
      set work._var_types (where=(type_conflict='Y'));
      put 'NOTE: [04_name_map] TYPE_CONFLICT: ' pcnr_name=;
    run;
  %end;

  %local _ntrunc;
  proc sql noprint;
    select count(*) into :_ntrunc trimmed
    from work.name_map_core
    where trunc_flag = 1;
  quit;
  %put NOTE: [04_name_map] labels >= 256 chars (truncated in SAS LABEL): &_ntrunc;

  %if &_ntrunc > 0 %then %do;
    data _null_;
      set work.name_map_core (where=(trunc_flag=1));
      put 'NOTE: [04_name_map] LABEL TRUNCATED >= 256: ' s_code= col_order= original_header=;
    run;
  %end;

  %put NOTE: [04_name_map] Section 11 type tracking complete;
%mend section11_types;

%section11_types;


/* ============================================================
   SECTION 12 -- Build final datasets
   ============================================================ */

%macro section12_final;
  /* pdd.name_map: 4795 rows.
     Columns: s_code, col_order, sas_name (column in pdd.src_<s_code>),
              original_header, trunc_flag, status, group_id, pcnr_name,
              sas_type, length. */
  proc sql noprint;
    create table pdd.name_map as
    select c.s_code,
           c.col_order,
           c.col_name       as sas_name       length=32,
           c.original_header                  length=256,
           c.trunc_flag,
           c.status,
           c.group_id,
           case when c.status = 'PCNR' then c.pcnr_name else '' end
             as pcnr_name                     length=32,
           coalesce(t.spec_sas_type, c.sas_type) as sas_type length=1,
           coalesce(t.spec_length,   c.length)   as length
    from work.name_map_core as c
    left join (select s_code, col_order, spec_sas_type, spec_length
               from work._nm_typed) as t
      on c.s_code    = t.s_code
     and c.col_order = t.col_order;
  quit;

  data pdd.name_map;
    set pdd.name_map;
    label original_header = 'Original header (truncated at 256 if longer)';
    label pcnr_name       = 'PCNR_ variable name';
    label status          = 'Column status (PCNR|KEY|EXCLUDED_CLK|LINKAGE_ONLY|DUPLICATE_DROPPED)';
    label sas_name        = 'SAS column name in pdd.src_<s_code>';
    label trunc_flag      = '1 when original header length >= 256';
    label group_id        = 'Variable group identifier';
  run;

  %assert_rowcount(ds=pdd.name_map, expected=4795,
    label=pdd.name_map);

  %local _ndupnm;
  proc sql noprint;
    select count(*) into :_ndupnm trimmed
    from (select s_code, col_order, count(*) as n
          from pdd.name_map
          group by s_code, col_order
          having count(*) > 1);
  quit;
  %if &_ndupnm > 0 %then %do;
    %fail_out(msg=%str(pdd.name_map has &_ndupnm (s_code,col_order) duplicates -- not unique));
  %end;

  /* pdd.name_map_vars: one row per unique PCNR_ variable.
     s_codes_contributing built with DATA step (by pcnr_name, retain, catx). */
  proc sort data=pdd.name_map (where=(status='PCNR' and pcnr_name ne ''))
    out=work._nm_sorted_sc;
    by pcnr_name s_code;
  run;

  data work._var_scodes;
    set work._nm_sorted_sc;
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

  /* pdd.name_map_vars adds group_id */
  proc sql noprint;
    create table pdd.name_map_vars as
    select v.pcnr_name,
           nm.group_id,
           t.result_type,
           t.max_length,
           t.type_conflict,
           v.n_sources,
           v.s_codes_contributing
    from work._var_scodes as v
    inner join work._var_types as t
      on v.pcnr_name = t.pcnr_name
    inner join (select pcnr_name, min(group_id) as group_id
                from pdd.name_map
                where status = 'PCNR' and pcnr_name ne ''
                group by pcnr_name) as nm
      on v.pcnr_name = nm.pcnr_name
    order by v.pcnr_name;
  quit;

  %put NOTE: [04_name_map] Section 12 final datasets built;
%mend section12_final;

%section12_final;


/* ============================================================
   SECTION 13 -- D-10 integrity checks
   ============================================================ */

%macro section13_integrity;
  /* (a) All 4795 rows have a status */
  %local _n_nostatus;
  proc sql noprint;
    select count(*) into :_n_nostatus trimmed
    from pdd.name_map
    where status is null or strip(status) = '';
  quit;
  %if &_n_nostatus > 0 %then %do;
    %fail_out(msg=%str(D-10(a): &_n_nostatus rows missing status in pdd.name_map));
  %end;

  /* (b) No duplicate pcnr_name across different group_ids */
  %local _n_pcnr_dup;
  proc sql noprint;
    select count(*) into :_n_pcnr_dup trimmed
    from (select upcase(pcnr_name), count(distinct group_id) as ng
          from pdd.name_map
          where status = 'PCNR' and pcnr_name ne ''
          group by upcase(pcnr_name)
          having count(distinct group_id) > 1);
  quit;
  %if &_n_pcnr_dup > 0 %then %do;
    %fail_out(msg=%str(D-10(b): &_n_pcnr_dup pcnr_name values map to multiple group_ids in pdd.name_map));
  %end;

  /* (c) Every decisions.csv row matched an existing name_map row */
  %local _n_dec_unmatched;
  proc sql noprint;
    select count(*) into :_n_dec_unmatched trimmed
    from work.decisions as d
    where d.s_code_a is not null
      and not exists (
        select 1 from pdd.name_map as m
        where m.s_code = d.s_code_a
          and (d.col_order_a is not missing and m.col_order = d.col_order_a
               or d.col_order_a is missing
                  and lowcase(m.original_header) = lowcase(d.header_a)));
  quit;
  %if &_n_dec_unmatched > 0 %then %do;
    %fail_out(msg=%str(D-10(c): &_n_dec_unmatched decisions.csv rows do not match any pdd.name_map row));
  %end;

  /* (d) Undecided near-match count */
  %local _n_undec_d10;
  proc sql noprint;
    select count(*) into :_n_undec_d10 trimmed
    from pdd.name_map_nearmatches as nm
    where not exists (
      select 1 from work.decisions as d
      where upcase(strip(d.decision)) in ('SAME','DIFFERENT')
        and ((d.s_code_a = nm.s_code_a
              and (d.col_order_a is not missing and d.col_order_a = nm.col_order_a
                   or d.col_order_a is missing
                      and lowcase(d.header_a) = lowcase(nm.original_header_a))
              and d.s_code_b = nm.s_code_b
              and (d.col_order_b is not missing and d.col_order_b = nm.col_order_b
                   or d.col_order_b is missing
                      and lowcase(d.header_b) = lowcase(nm.original_header_b)))
          or (d.s_code_a = nm.s_code_b
              and (d.col_order_a is not missing and d.col_order_a = nm.col_order_b
                   or d.col_order_a is missing
                      and lowcase(d.header_a) = lowcase(nm.original_header_b))
              and d.s_code_b = nm.s_code_a
              and (d.col_order_b is not missing and d.col_order_b = nm.col_order_a
                   or d.col_order_b is missing
                      and lowcase(d.header_b) = lowcase(nm.original_header_a)))));
  quit;
  %put NOTE: [04_name_map] D-10(d) undecided near-match pairs=&_n_undec_d10;
  %if &_n_undec_d10 > 0 %then
    %put NOTE: [04_name_map] undecided>0 means phase not complete -- resolve via docs/name_map_decisions.csv;

  %put NOTE: D-10 integrity checks passed;
  %put NOTE: [04_name_map] Section 13 D-10 integrity checks complete;
%mend section13_integrity;

%section13_integrity;


/* ============================================================
   SECTION 14 -- Exchange CSV exports (D-09)
   ============================================================ */

%macro section14_exports;
  %local _nrow;

  proc export data=pdd.name_map
    outfile="&exchange_path.\name_map.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.name_map;
  quit;
  %put NOTE: [04_name_map] exported name_map.csv rows=&_nrow;

  proc export data=pdd.name_map_vars
    outfile="&exchange_path.\name_map_vars.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.name_map_vars;
  quit;
  %put NOTE: [04_name_map] exported name_map_vars.csv rows=&_nrow;

  proc export data=pdd.qc_name_map_collisions
    outfile="&exchange_path.\name_map_collisions.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.qc_name_map_collisions;
  quit;
  %put NOTE: [04_name_map] exported name_map_collisions.csv rows=&_nrow;

  proc export data=pdd.name_map_nearmatches
    outfile="&exchange_path.\name_map_nearmatches.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.name_map_nearmatches;
  quit;
  %put NOTE: [04_name_map] exported name_map_nearmatches.csv rows=&_nrow;

  proc export data=work._abbrev_hits
    outfile="&exchange_path.\name_abbrev_applied.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from work._abbrev_hits;
  quit;
  %put NOTE: [04_name_map] exported name_abbrev_applied.csv rows=&_nrow;

  %put NOTE: [04_name_map] Section 14 exchange CSV exports complete;
%mend section14_exports;

%section14_exports;

%restore_log;
