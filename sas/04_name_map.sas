/*==========================================================================
  Program : 04_name_map.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 4 -- Map every source header to a PCNR_ name or status.
            Loads pdd.import_spec (4795 rows), assigns statuses (D-04),
            cleans and shortens PCNR names (D-02/D-03), applies decision
            overrides, forms variable groups (D-01a), two-stage collision
            resolution (D-05), near-match detection (D-06).

  Reads   : pdd.import_spec, pdd.header_inventory, pdd.key_analysis
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
     raw=   source variable name
     out=   target variable name (must be declared $200 or wider)
   Steps:
     1. strip whitespace
     2. replace non-alphanumeric runs with single _
     3. strip leading and trailing _
     4. prefix N_ if starts with digit
   Does NOT apply abbreviations or PCNR_ prefix (handled in Section 4). */
%macro clean_name(raw=, out=);
  &out = strip(&raw);
  &out = prxchange('s/[^A-Za-z0-9]+/_/', -1, &out);
  &out = prxchange('s/^_+//', 1, &out);
  &out = prxchange('s/_+$//', 1, &out);
  if prxmatch('/^\d/', &out) then &out = cats('N_', &out);
%mend clean_name;

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
    &nm = cats(substr(&nm, 1, _elide_first), '__',
               substr(&nm, length(&nm) - _elide_last + 1));
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
   Called from Section 3 after _psid_dup_cols is built. */
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
      %if &_sc = s15 and &_src_exists15 %then %let _src_ok = 1;
      %if &_sc = s17 and &_src_exists17 %then %let _src_ok = 1;

      %if &_src_ok %then %do;
        /* Replicate %pdd_norm_psid logic inline -- cannot call the macro
           with in= out= parameters in a DATA step context here. */
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
          proc print data=work._d08_compare (where=(_disagree=1) obs=20); run;
          %fail_out(msg=%str(D-08 &_sc &_ndis rows disagree between &_pc and &_dc after norm_psid));
        %end;
        %put NOTE: [04_name_map] D-08 &_sc &_nagr rows confirmed identical (0 disagreements);
      %end;
      %else %do;
        %put NOTE: [04_name_map] D-08 &_sc src not yet available -- dup PSID flagged for status only;
      %end;
    %end;
  %end;
  %else %do;
    %put NOTE: [04_name_map] D-08 no duplicate Study ID columns found in s15/s17;
  %end;
%mend d08_check;

/* Status assignment and assertions (called from Section 3 body). */
%macro build_status;
  /* Determine if key_analysis has a col_name column */
  %local _ka_has_col;
  %let _ka_has_col = 0;
  proc sql noprint;
    select count(*) into :_ka_has_col trimmed
    from dictionary.columns
    where libname = 'WORK'
      and memname = '_KA_COLS'
      and lowcase(name) = 'col_name';
  quit;

  %if &_ka_has_col > 0 %then %do;
    proc sql noprint;
      create table work._headers_aug as
      select a.s_code,
             a.col_order,
             a.col_name,
             a.sas_type,
             a.length,
             a.orig_col_name,
             a.original_header_trunc,
             b.key_column_type,
             c.class as col_class,
             case when d.col_name is not null then 1 else 0 end
               as duplicate_study_id
      from work.headers as a
      left join (select s_code, col_name, key_column_type
                 from pdd.key_analysis
                 where key_column_type = 'PRECEDE_STUDY_ID') as b
        on a.s_code = b.s_code and a.col_name = b.col_name
      left join work.s06class as c
        on a.col_name = c.sas_name
      left join work._psid_dup_cols as d
        on a.s_code = d.s_code and a.col_name = d.col_name;
    quit;
  %end;
  %else %do;
    proc sql noprint;
      create table work._headers_aug as
      select a.s_code,
             a.col_order,
             a.col_name,
             a.sas_type,
             a.length,
             a.orig_col_name,
             a.original_header_trunc,
             b.key_column_type,
             c.class as col_class,
             case when d.col_name is not null then 1 else 0 end
               as duplicate_study_id
      from work.headers as a
      left join (select s_code, key_column_type
                 from pdd.key_analysis
                 where key_column_type = 'PRECEDE_STUDY_ID') as b
        on a.s_code = b.s_code
       and prxmatch('/PRECEDE.Study.ID/i', a.orig_col_name) > 0
      left join work.s06class as c
        on a.col_name = c.sas_name
      left join work._psid_dup_cols as d
        on a.s_code = d.s_code and a.col_name = d.col_name;
    quit;
  %end;

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

  /* Assert: exactly one KEY row per file with PRECEDE_STUDY_ID */
  proc sql noprint;
    create table work._key_check as
    select s_code, count(*) as n_key
    from work.name_map_status
    where status = 'KEY'
    group by s_code
    having count(*) ne 1;
  quit;

  %local _nkwrong;
  proc sql noprint;
    select count(*) into :_nkwrong trimmed from work._key_check;
  quit;
  %if &_nkwrong > 0 %then %do;
    proc print data=work._key_check; run;
    %fail_out(msg=%str(&_nkwrong files have != 1 KEY row -- see above));
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
      %clean_name(raw=original_header_trunc, out=cleaned_pre_short);
      if cleaned_pre_short = '' then do;
        put 'ERROR: [04_name_map] D-02 empty clean for: ' original_header_trunc;
        call symputx('_n_empty_clean',
          cats(input(symget('_n_empty_clean'), best.) + 1));
      end;
    end;
  run;

  %if &_n_empty_clean > 0 %then %do;
    %fail_out(msg=%str(D-02 &_n_empty_clean headers cleaned to empty string));
  %end;
  %put NOTE: [04_name_map] 0 empty-clean headers;
  %put NOTE: [04_name_map] Section 4 cleaning complete;
%mend apply_cleaning;

/* Apply decision RENAME overrides (Section 5 body). */
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
       and (d.header_a = m.original_header_trunc
            or (d.col_order_a is not null and d.col_order_a = m.col_order))
      where m.s_code is null and d.s_code_a is not null;
    quit;

    %local _n_unmatched;
    proc sql noprint;
      select count(*) into :_n_unmatched trimmed from work._dec_unmatched;
    quit;
    %if &_n_unmatched > 0 %then %do;
      proc print data=work._dec_unmatched; run;
      %fail_out(msg=%str(&_n_unmatched decision rows do not match any name_map row));
    %end;

    /* Extract RENAME decisions */
    proc sql noprint;
      create table work._rename_dec as
      select s_code_a as s_code length=4,
             header_a as orig_header length=200,
             col_order_a as col_order_dec,
             /* note field holds the target name */
             strip(note) as rename_target length=200
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
       and m.original_header_trunc = r.orig_header;
    quit;
  %end;
%mend apply_decisions_rename;

/* Form variable groups and apply D-03 shortening (Section 6 body). */
%macro form_groups_and_shorten;

  /* 6a. Assign group_id: same lowcase(cleaned_pre_short) across files = same group.
         Same file = separate group. */
  proc sort data=work.name_map_overrides (where=(status='PCNR' and cleaned_pre_short ne ''))
    out=work._pcnr_only;
    by s_code col_order;
  run;

  data work._pcnr_lc;
    set work._pcnr_only;
    _lc_clean = lowcase(cleaned_pre_short);
  run;

  proc sort data=work._pcnr_lc; by _lc_clean s_code col_order; run;

  /* Assign group_id: new group when lc_clean changes OR same file seen again in current lc_clean */
  data work._group_assign;
    set work._pcnr_lc;
    by _lc_clean;
    length _seen_file $500;
    retain _grp_id 0 _seen_file;
    if first._lc_clean then do;
      _grp_id    = _grp_id + 1;
      _seen_file = '';
    end;
    /* Same-file collision: same lc_clean, same s_code as a previous row in this group */
    if not first._lc_clean and index(cats('|', _seen_file, '|'), cats('|', s_code, '|')) > 0 then do;
      _grp_id = _grp_id + 1;
      _same_file_collision = 1;
    end;
    else _same_file_collision = 0;
    if index(cats('|', _seen_file, '|'), cats('|', s_code, '|')) = 0 then
      _seen_file = catx('|', _seen_file, s_code);
    group_id = _grp_id;
    drop _seen_file;
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

  /* Map SAME pairs to group_ids */
  data work._group_final;
    set work._group_assign;
  run;

  %if &_nsg > 0 %then %do;
    proc sql noprint;
      create table work._same_grpids as
      select a.group_id as grp_a, b.group_id as grp_b
      from work._same_dec as d
      inner join work._group_assign as a
        on d.s_code_a = a.s_code
       and lowcase(d.header_a) = lowcase(a.cleaned_pre_short)
      inner join work._group_assign as b
        on d.s_code_b = b.s_code
       and lowcase(d.header_b) = lowcase(b.cleaned_pre_short)
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
      proc print data=work._same_sc_bad; run;
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

  /* 6d. Apply abbreviation table then elide to shorten to <= 27 chars */
  /* First load abbreviation table to a work dataset sorted desc by long length */
  data work._abbrev_applied_raw;
    length group_id 8
           long $200 short $200
           cleaned_before $200 cleaned_after $200;
    stop;
  run;

  /* Process each group representative */
  %local _ngrep _gi;
  proc sql noprint;
    select count(*) into :_ngrep trimmed from work._grp_rep;
  quit;

  /* Process abbreviations via explicit DO loop inside a DATA step.
     Load abbrev as a fixed dataset; iterate with SET ... POINT. */
  data work._grp_names (keep=group_id pcnr_name_base)
       work._abbrev_hits (keep=group_id long short cleaned_before cleaned_after);
    length group_id 8
           pcnr_name_base $200
           _nm $200 _cbe $200 _pat $400
           long $200 short $200
           cleaned_before $200 cleaned_after $200
           _elide_first 8 _elide_last 8;
    if _N_ = 1 then _nab = 0;
    /* Count abbrev rows once */
    if _N_ = 1 then do;
      _nab = 0;
      do while (1);
        _nab = _nab + 1;
        set work.abbrev point=_nab nobs=_nab_tot;
        if _nab >= _nab_tot then leave;
      end;
      _nab = _nab_tot;
    end;
    retain _nab;
    set work._grp_rep;

    _nm = cleaned_pre_short;
    if pcnr_name_override ne '' then _nm = pcnr_name_override;
    else do;
      /* Apply abbreviations, longest-first (work.abbrev already sorted desc by _longlen) */
      do _ai = 1 to _nab;
        set work.abbrev (keep=long short _longlen) point=_ai;
        _cbe = _nm;
        /* Whole-token match: bounded by start, end, or underscore */
        _pat = cats('s/(^|_)', prxchange('s/([.+*?()\[\]{}|\\^$])/\\$1/', -1, long),
                    '($|_)/$1', short, '$2/');
        _nm  = prxchange(_pat, -1, _nm);
        if _nm ne _cbe then do;
          cleaned_before = _cbe;
          cleaned_after  = _nm;
          output work._abbrev_hits;
        end;
      end;
      /* Elide if still > 27 chars */
      %elide_middle(nm=_nm);
    end;
    pcnr_name_base = _nm;
    output work._grp_names;
  run;

  /* Copy abbrev hits with correct name */
  data work._abbrev_applied_raw;
    set work._abbrev_hits;
  run;

  /* Join pcnr_name_base back to all rows in name_map_overrides */
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

/* Stage 1 collision suffix between groups (Section 7 body). */
%macro stage1_suffix;
  /* Representative row per group for ordering: s01->s20 then col_order */
  proc sort data=work.name_map_grouped (where=(status='PCNR' and group_id>.))
    out=work._pcnr_grp;
    by group_id s_code col_order;
  run;

  data work._grp_order2;
    set work._pcnr_grp;
    by group_id;
    if first.group_id;
    _file_num = input(substr(s_code, 2), best.);
    keep group_id pcnr_name_base _file_num col_order;
  run;

  proc sort data=work._grp_order2; by pcnr_name_base _file_num col_order; run;

  data work._suffix_assign;
    set work._grp_order2;
    by pcnr_name_base;
    retain _suffix_counter 1;
    if first.pcnr_name_base then _suffix_counter = 1;
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

  /* Build final pcnr_name with suffix (ensured <= 27 chars) */
  data work._suffix_final;
    set work._suffix_assign;
    length pcnr_name_final $200
           _sfx $10 _base_trim $200;
    _elide_first = 0;
    _elide_last  = 0;
    if _suffix_n = 1 then pcnr_name_final = pcnr_name_base;
    else do;
      _sfx     = cats('_', put(_suffix_n, best.));
      _allowed = 27 - length(_sfx);
      if length(pcnr_name_base) > _allowed then
        _base_trim = substr(pcnr_name_base, 1, _allowed);
      else _base_trim = pcnr_name_base;
      pcnr_name_final = cats(_base_trim, _sfx);
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
%mend stage1_suffix;

/* Stage 2 hard-stop (Section 8 body). */
%macro stage2_validate;
  /* Check 1: case-insensitive duplicate pcnr_name */
  proc sql noprint;
    create table work._s2_dups as
    select pcnr_name, count(*) as n_rows
    from work.name_map_suffixed
    where status = 'PCNR' and pcnr_name ne ''
    group by upcase(pcnr_name)
    having count(*) > 1;
  quit;

  %local _n_s2_dups;
  proc sql noprint;
    select count(*) into :_n_s2_dups trimmed from work._s2_dups;
  quit;
  %if &_n_s2_dups > 0 %then %do;
    proc print data=work._s2_dups; run;
    %fail_out(msg=%str(Stage 2 -- &_n_s2_dups PCNR_ names are case-insensitive duplicates));
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
    proc print data=work._s2_toolong; run;
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
    proc print data=work._s2_invalid; run;
    %fail_out(msg=%str(Stage 2 -- &_n_s2_inv PCNR_ names are not valid SAS V7 names));
  %end;

  %put NOTE: [04_name_map] Stage 2 passed;

  /* Persist work.name_map_core for downstream plans */
  data work.name_map_core;
    set work.name_map_suffixed;
    /* Log truncated labels (D-10 criterion 6) */
    if length(original_header_trunc) >= 256 then
      put 'NOTE: [04_name_map] LABEL TRUNCATED: ' s_code= col_order= col_name=;
  run;

  %put NOTE: [04_name_map] work.name_map_core ready;
%mend stage2_validate;


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

/* Per-s_code count comparison */
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
    proc print data=work._sc_check; run;
    %fail_out(msg=%str(import_spec and header_inventory row counts differ for &_nmis s_code values));
  %end;
  %put NOTE: [04_name_map] per-s_code row counts match header_inventory;
%mend check_per_scode;
%check_per_scode;

%put NOTE: [04_name_map] 4795 rows;


/* ============================================================
   SECTION 2 -- Load inputs
   ============================================================ */

/* 2a. Base spec */
data work.importspec;
  set pdd.import_spec;
run;

/* 2b. Headers: join import_spec to header_inventory for original_header_trunc */
proc sql noprint;
  create table work.headers as
  select a.file_code  as s_code,
         a.col_order,
         a.sas_name   as col_name,
         a.sas_type,
         a.length,
         b.orig_col_name,
         b.original_header_trunc
  from pdd.import_spec as a
  left join pdd.header_inventory as b
    on a.file_code = b.s_code
   and a.sas_name  = b.sas_name;
quit;

%macro check_header_join;
  %local _nmis_hdr;
  proc sql noprint;
    select count(*) into :_nmis_hdr trimmed
    from work.headers
    where original_header_trunc is null;
  quit;
  %if &_nmis_hdr > 0 %then %do;
    %fail_out(msg=%str(&_nmis_hdr import_spec rows failed to join to header_inventory));
  %end;
  %put NOTE: [04_name_map] All import_spec rows joined to header_inventory;
%mend check_header_join;
%check_header_join;

/* 2c. Key analysis */
data work.keyanalysis;
  set pdd.key_analysis (keep=s_code key_column_type);
run;

/* 2d. S06 column class */
proc import datafile="&sas_path.\..\docs\s06_column_class.csv"
  out=work.s06class dbms=csv replace;
  guessingrows=max;
run;

data work.s06class;
  set work.s06class (keep=sas_name class);
  sas_name = strip(sas_name);
  class    = strip(class);
run;

/* 2e. Decision overrides (may be empty) */
proc import datafile="&sas_path.\..\docs\name_map_decisions.csv"
  out=work.decisions dbms=csv replace;
  guessingrows=max;
run;

/* 2f. Abbreviation table -- already sorted desc by _longlen from PROC IMPORT.
        Add length variable then sort. */
proc import datafile="&sas_path.\..\docs\name_abbrev.csv"
  out=work._abbrev_raw dbms=csv replace;
  guessingrows=max;
run;

data work.abbrev;
  set work._abbrev_raw;
  long     = strip(long);
  short    = strip(short);
  _longlen = length(long);
run;

proc sort data=work.abbrev; by descending _longlen; run;


/* ============================================================
   SECTION 3 -- D-08 duplicate Study ID (s15, s17) THEN status
   ============================================================ */

/* 3a. Identify PSID-like headers in s15/s17 */
proc sql noprint;
  create table work._psid_headers as
  select s_code, col_name, col_order, orig_col_name
  from work.headers
  where s_code in ('s15','s17')
    and prxmatch('/PRECEDE.Study.ID/i', orig_col_name) > 0
  order by s_code, col_order;
quit;

/* 3b. Duplicate columns = all beyond the first (min col_order) per file */
proc sql noprint;
  create table work._psid_dup_cols as
  select a.s_code, a.col_name, a.col_order
  from work._psid_headers as a
  inner join (select s_code, min(col_order) as min_order
              from work._psid_headers
              group by s_code) as b
    on a.s_code = b.s_code
   and a.col_order > b.min_order;
quit;

/* 3c. Build _d08_primary: primary vs dup col pairs */
proc sql noprint;
  create table work._d08_primary as
  select p.s_code,
         p.col_name as primary_col,
         d.col_name as dup_col
  from (select s_code, col_name
        from work._psid_headers as h
        inner join (select s_code, min(col_order) as min_order
                    from work._psid_headers group by s_code) as m
          on h.s_code = m.s_code and h.col_order = m.min_order) as p
  inner join work._psid_dup_cols as d
    on p.s_code = d.s_code;
quit;

/* 3d. D-08 value comparison */
%d08_check;

/* 3e. Determine key_analysis column structure */
proc contents data=pdd.key_analysis noprint
  out=work._ka_cols (keep=name varnum); run;

/* 3f. Status assignment */
%build_status;


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

%restore_log;


/* ============================================================
   SECTION 9 -- Near-match detection (D-06)
   ============================================================ */

%macro section9_nearmatches;
  /* Distinct (s_code, cleaned_pre_short, group_id) from PCNR rows */
  proc sql noprint;
    create table work._nm_distinct as
    select distinct s_code,
                    cleaned_pre_short,
                    group_id,
                    monotonic() as key
    from work.name_map_core
    where status = 'PCNR' and cleaned_pre_short ne '';
  quit;

  /* Cross-join: different s_code, each pair once (a.key < b.key),
     length difference <= 2, edit distance <= 2, not identical,
     not already in same group_id */
  proc sql noprint;
    create table work._nm_pairs_edit as
    select a.s_code      as s_code_a,
           a.cleaned_pre_short as name_a,
           a.group_id    as group_id_a,
           b.s_code      as s_code_b,
           b.cleaned_pre_short as name_b,
           b.group_id    as group_id_b,
           complev(lowcase(a.cleaned_pre_short),
                   lowcase(b.cleaned_pre_short)) as edit_dist,
           'EDIT_DISTANCE' as match_type length=20
    from work._nm_distinct as a,
         work._nm_distinct as b
    where a.s_code ne b.s_code
      and a.key < b.key
      and a.group_id ne b.group_id
      and abs(length(a.cleaned_pre_short) - length(b.cleaned_pre_short)) <= 2
      and complev(lowcase(a.cleaned_pre_short),
                  lowcase(b.cleaned_pre_short)) <= 2
      and lowcase(a.cleaned_pre_short) ne lowcase(b.cleaned_pre_short);
  quit;

  /* Trailing-suffix rule: one name has _N or _dupN suffix;
     stripped version equals the other name */
  proc sql noprint;
    create table work._nm_pairs_suffix as
    select a.s_code      as s_code_a,
           a.cleaned_pre_short as name_a,
           a.group_id    as group_id_a,
           b.s_code      as s_code_b,
           b.cleaned_pre_short as name_b,
           b.group_id    as group_id_b,
           . as edit_dist,
           'TRAILING_SUFFIX' as match_type length=20
    from work._nm_distinct as a,
         work._nm_distinct as b
    where a.s_code ne b.s_code
      and a.key < b.key
      and a.group_id ne b.group_id
      and prxmatch('/(_\d+|_dup\d*)$/i', strip(a.cleaned_pre_short)) > 0
      and lowcase(prxchange('s/(_\d+|_dup\d*)$//i', 1,
                  strip(a.cleaned_pre_short))) =
          lowcase(strip(b.cleaned_pre_short));
  quit;

  /* Union both sets, deduplicate */
  proc sql noprint;
    create table pdd.name_map_nearmatches as
    select distinct s_code_a, name_a, group_id_a,
                    s_code_b, name_b, group_id_b,
                    edit_dist, match_type
    from (select * from work._nm_pairs_edit
          union all
          select * from work._nm_pairs_suffix);
  quit;

  %local _n_nm;
  proc sql noprint;
    select count(*) into :_n_nm trimmed
    from pdd.name_map_nearmatches;
  quit;
  %put NOTE: near-match pair count=&_n_nm;

  %if &_n_nm > 200 %then %do;
    /* Report top patterns before failing */
    proc freq data=pdd.name_map_nearmatches order=freq noprint;
      tables match_type / out=work._nm_top;
    run;
    proc print data=work._nm_top; run;
    proc print data=pdd.name_map_nearmatches (obs=20); run;
    %fail_out(msg=%str(D-06 near-match pair count=&_n_nm exceeds 200 -- resolve before continuing));
  %end;

  /* Count undecided pairs (no SAME or DIFFERENT decision) */
  %local _n_undecided;
  proc sql noprint;
    select count(*) into :_n_undecided trimmed
    from pdd.name_map_nearmatches as nm
    where not exists (
      select 1 from work.decisions as d
      where upcase(strip(d.decision)) in ('SAME','DIFFERENT')
        and ((d.s_code_a = nm.s_code_a
              and lowcase(d.header_a) = lowcase(nm.name_a)
              and d.s_code_b = nm.s_code_b
              and lowcase(d.header_b) = lowcase(nm.name_b))
          or (d.s_code_a = nm.s_code_b
              and lowcase(d.header_a) = lowcase(nm.name_b)
              and d.s_code_b = nm.s_code_a
              and lowcase(d.header_b) = lowcase(nm.name_a))));
  quit;
  %put NOTE: [04_name_map] undecided near-match pairs=&_n_undecided;
  %if &_n_undecided > 0 %then
    %put NOTE: [04_name_map] undecided>0 means phase not complete -- resolve via docs/name_map_decisions.csv;
  %put NOTE: [04_name_map] Section 9 near-match detection complete;
%mend section9_nearmatches;

%section9_nearmatches;


/* ============================================================
   SECTION 10 -- D-08 confirmed (duplicate PSID handled in Plan 02)
   ============================================================ */

%put NOTE: Section 10 D-08 confirmed in Plan 02;
%put NOTE: [04_name_map] DUPLICATE_DROPPED rows from s15/s17 verified in Section 3;


/* ============================================================
   SECTION 11 -- Type tracking (D-07)
   ============================================================ */

%macro section11_types;
  /* Join name_map_core to import_spec on (s_code=file_code, col_order=col_order)
     to get sas_type and spec_length per row */
  proc sql noprint;
    create table work._nm_typed as
    select c.*,
           coalesce(s.sas_type,  c.sas_type)  as spec_sas_type  length=1,
           coalesce(s.length,    c.length)     as spec_length
    from work.name_map_core as c
    left join pdd.import_spec as s
      on c.s_code     = s.file_code
     and c.col_order  = s.col_order;
  quit;

  /* Per PCNR_ variable: result_type, max_length, type_conflict */
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

  /* Log type-conflict variables */
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

  /* Flag original_header_trunc > 256 chars (SAS LABEL silent truncation -- Pitfall 4 / D-10 item 6) */
  %local _ntrunc;
  proc sql noprint;
    select count(*) into :_ntrunc trimmed
    from work.name_map_core
    where length(original_header_trunc) >= 256;
  quit;
  %put NOTE: [04_name_map] labels >= 256 chars (truncated in SAS LABEL): &_ntrunc;

  %if &_ntrunc > 0 %then %do;
    data _null_;
      set work.name_map_core (where=(length(original_header_trunc) >= 256));
      put 'NOTE: [04_name_map] LABEL TRUNCATED >= 256: ' s_code= col_order= original_header_trunc=;
    run;
  %end;

  %put NOTE: [04_name_map] Section 11 type tracking complete;
%mend section11_types;

%section11_types;


/* ============================================================
   SECTION 12 -- Build final datasets
   ============================================================ */

%macro section12_final;
  /* pdd.name_map: 4795 rows, one per (s_code, col_order) */
  proc sql noprint;
    create table pdd.name_map as
    select c.s_code,
           c.col_order,
           c.original_header_trunc as original_header length=256,
           c.status,
           case when c.status = 'PCNR' then c.pcnr_name else '' end
             as pcnr_name length=32,
           coalesce(t.spec_sas_type, c.sas_type) as sas_type length=1,
           coalesce(t.spec_length,   c.length)   as length
    from work.name_map_core as c
    left join (select s_code, col_order, spec_sas_type, spec_length
               from work._nm_typed) as t
      on c.s_code    = t.s_code
     and c.col_order = t.col_order;
  quit;

  /* Apply LABEL = full original_header_trunc */
  data pdd.name_map;
    set pdd.name_map;
    label original_header = 'Original header (truncated at 256 if longer)';
    label pcnr_name       = 'PCNR_ variable name';
    label status          = 'Column status (PCNR|KEY|EXCLUDED_CLK|LINKAGE_ONLY|DUPLICATE_DROPPED)';
  run;

  %assert_rowcount(ds=pdd.name_map, expected=4795,
    label=pdd.name_map);

  /* Verify unique on (s_code, col_order) */
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

  /* pdd.name_map_vars: one row per unique PCNR_ variable */
  proc sql noprint;
    create table work._var_scodes as
    select pcnr_name,
           count(distinct s_code) as n_sources,
           /* contributing s_codes as space-delimited list */
           (select distinct cats(s_code, ' ')
            from pdd.name_map as m2
            where m2.pcnr_name = m1.pcnr_name
              and m2.status = 'PCNR') as s_codes_contributing length=200
    from pdd.name_map as m1
    where status = 'PCNR' and pcnr_name ne ''
    group by pcnr_name;
  quit;

  proc sql noprint;
    create table pdd.name_map_vars as
    select v.pcnr_name,
           t.result_type,
           t.max_length,
           t.type_conflict,
           v.n_sources,
           v.s_codes_contributing
    from work._var_scodes as v
    inner join work._var_types as t
      on v.pcnr_name = t.pcnr_name
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

  /* (b) No duplicate or invalid final pcnr_name -- Stage 2 already checked, re-assert */
  %local _n_pcnr_dup;
  proc sql noprint;
    select count(*) into :_n_pcnr_dup trimmed
    from (select upcase(pcnr_name), count(*) as n
          from pdd.name_map
          where status = 'PCNR' and pcnr_name ne ''
          group by upcase(pcnr_name)
          having count(*) > 1);
  quit;
  %if &_n_pcnr_dup > 0 %then %do;
    %fail_out(msg=%str(D-10(b): &_n_pcnr_dup case-insensitive duplicate pcnr_name values in pdd.name_map));
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
          and (lowcase(m.original_header) = lowcase(d.header_a)
               or (d.col_order_a is not null and m.col_order = d.col_order_a)));
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
              and lowcase(d.header_a) = lowcase(nm.name_a)
              and d.s_code_b = nm.s_code_b
              and lowcase(d.header_b) = lowcase(nm.name_b))
          or (d.s_code_a = nm.s_code_b
              and lowcase(d.header_a) = lowcase(nm.name_b)
              and d.s_code_b = nm.s_code_a
              and lowcase(d.header_b) = lowcase(nm.name_a))));
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

  /* name_map.csv */
  proc export data=pdd.name_map
    outfile="&exchange_path.\name_map.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.name_map;
  quit;
  %put NOTE: [04_name_map] exported name_map.csv rows=&_nrow;

  /* name_map_vars.csv */
  proc export data=pdd.name_map_vars
    outfile="&exchange_path.\name_map_vars.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.name_map_vars;
  quit;
  %put NOTE: [04_name_map] exported name_map_vars.csv rows=&_nrow;

  /* name_map_collisions.csv */
  proc export data=pdd.qc_name_map_collisions
    outfile="&exchange_path.\name_map_collisions.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.qc_name_map_collisions;
  quit;
  %put NOTE: [04_name_map] exported name_map_collisions.csv rows=&_nrow;

  /* name_map_nearmatches.csv */
  proc export data=pdd.name_map_nearmatches
    outfile="&exchange_path.\name_map_nearmatches.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from pdd.name_map_nearmatches;
  quit;
  %put NOTE: [04_name_map] exported name_map_nearmatches.csv rows=&_nrow;

  /* name_abbrev_applied.csv */
  proc export data=work._abbrev_applied_raw
    outfile="&exchange_path.\name_abbrev_applied.csv"
    dbms=csv replace;
  run;
  proc sql noprint;
    select count(*) into :_nrow trimmed from work._abbrev_applied_raw;
  quit;
  %put NOTE: [04_name_map] exported name_abbrev_applied.csv rows=&_nrow;

  %put NOTE: [04_name_map] Section 14 exchange CSV exports complete;
%mend section14_exports;

%section14_exports;
