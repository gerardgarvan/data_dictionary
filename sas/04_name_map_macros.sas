/*==========================================================================
  File    : sas/04_name_map_macros.sas
  Purpose : Macro definitions for B1-B5 decision logic.
            Included by sas/04_name_map.sas (Section 0) and
            tests/04_decisions_test.sas.
            Contains NO executable open-code statements.
==========================================================================*/

/* D-03 middle-elide: fit name within target chars.
   Parameters: nm= variable (in-place, $200+), target= max length (default 27). */
%macro elide_middle(nm=, target=27);
  if length(&nm) > &target then do;
    _elide_first = max(4, ceil((&target - 2) / 2));
    _elide_last  = &target - 2 - _elide_first;
    if _elide_last < 1 then do;
      _elide_first = &target - 3;
      _elide_last  = 1;
    end;
    _elide_head = prxchange('s/_+$//', 1, strip(substr(&nm, 1, _elide_first)));
    _elide_tail = prxchange('s/^_+//', 1, strip(substr(&nm, length(&nm) - _elide_last + 1)));
    &nm = cats(_elide_head, '__', _elide_tail);
  end;
%mend elide_middle;

/* B4: RENAME target validation.
   Reads work._rename_dec (s_code, orig_header, col_order_dec, rename_target).
   Sets %global _rc (0=pass, 1=fail) and _fail_msg. */
%macro _check_rename_targets;
  %global _rc _fail_msg;
  %let _rc = 0;
  %let _fail_msg = ;

  %local _n_rename_long;
  proc sql noprint;
    select count(*) into :_n_rename_long trimmed
    from work._rename_dec
    where length(strip(rename_target)) > 27;
  quit;
  %if &_n_rename_long > 0 %then %do;
    data _null_;
      set work._rename_dec (where=(length(strip(rename_target)) > 27));
      put 'ERROR: [04_name_map] RENAME_TOO_LONG: ' s_code= rename_target=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B4: &_n_rename_long RENAME targets exceed 27 chars after stripping PCNR_);
    %goto _crt_done;
  %end;

  %local _n_rename_invalid_v7;
  proc sql noprint;
    select count(*) into :_n_rename_invalid_v7 trimmed
    from work._rename_dec
    where not nvalid(cats('PCNR_', strip(rename_target)), 'v7');
  quit;
  %if &_n_rename_invalid_v7 > 0 %then %do;
    data _null_;
      set work._rename_dec (where=(not nvalid(cats('PCNR_', strip(rename_target)), 'v7')));
      put 'ERROR: [04_name_map] RENAME_INVALID_V7: ' s_code= rename_target=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B4: &_n_rename_invalid_v7 RENAME targets not valid SAS V7 with PCNR_ prefix);
    %goto _crt_done;
  %end;

  %local _n_rename_dup_targets;
  proc sql noprint;
    select count(*) into :_n_rename_dup_targets trimmed
    from (select upcase(strip(rename_target)) as rt, count(*) as n
          from work._rename_dec
          group by upcase(strip(rename_target))
          having count(*) > 1);
  quit;
  %if &_n_rename_dup_targets > 0 %then %do;
    data _null_;
      set work._rename_dec;
      by rename_target;
      if not (first.rename_target and last.rename_target) then
        put 'ERROR: [04_name_map] RENAME_DUP_TARGET: ' s_code= rename_target=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B4: &_n_rename_dup_targets RENAME targets duplicated case-insensitively);
    %goto _crt_done;
  %end;

  %_crt_done:
%mend _check_rename_targets;

/* B1+B3-SAME: existence check, header check, same-s_code pre-check, union-find.
   Reads work._same_dec (s_code_a, header_a, col_order_a, s_code_b, header_b, col_order_b)
   and work._group_assign (s_code, col_order, original_header, group_id).
   Creates/overwrites work._group_final with updated group_ids.
   Sets %global _rc (0=pass, 1=fail) and _fail_msg. */
%macro _apply_same_closure;
  %global _rc _fail_msg;
  %let _rc = 0;
  %let _fail_msg = ;

  data work._group_final;
    set work._group_assign;
  run;

  %local _nsg;
  proc sql noprint;
    select count(*) into :_nsg trimmed from work._same_dec;
  quit;
  %if &_nsg = 0 %then %goto _asc_done;

  /* B3: existence check -- both sides must exist in _group_assign */
  proc sql noprint;
    create table work._same_missing_a as
    select d.s_code_a, d.header_a, d.col_order_a
    from work._same_dec as d
    where d.s_code_a is not missing
      and not exists (
        select 1 from work._group_assign as a
        where a.s_code = d.s_code_a
          and (d.col_order_a is not missing and a.col_order = d.col_order_a
               or d.col_order_a is missing
                  and lowcase(a.original_header) = lowcase(d.header_a)));
    create table work._same_missing_b as
    select d.s_code_b, d.header_b, d.col_order_b
    from work._same_dec as d
    where d.s_code_b is not missing
      and not exists (
        select 1 from work._group_assign as a
        where a.s_code = d.s_code_b
          and (d.col_order_b is not missing and a.col_order = d.col_order_b
               or d.col_order_b is missing
                  and lowcase(a.original_header) = lowcase(d.header_b)));
  quit;
  %local _n_same_miss;
  proc sql noprint;
    select count(*) + (select count(*) from work._same_missing_b)
    into :_n_same_miss trimmed
    from work._same_missing_a;
  quit;
  %if &_n_same_miss > 0 %then %do;
    data _null_;
      set work._same_missing_a;
      put 'ERROR: [04_name_map] SAME_SIDE_MISSING_A: ' s_code_a= header_a= col_order_a=;
    run;
    data _null_;
      set work._same_missing_b;
      put 'ERROR: [04_name_map] SAME_SIDE_MISSING_B: ' s_code_b= header_b= col_order_b=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B3: &_n_same_miss SAME side(s) not found in name_map by (s_code,col_order));
    %goto _asc_done;
  %end;

  /* B3: when col_order provided and header non-blank, header_x must match original_header */
  proc sql noprint;
    create table work._same_hdr_bad_a as
    select d.s_code_a as s_code length=4,
           d.header_a as header_given length=256,
           d.col_order_a as col_order,
           a.original_header as header_actual length=256
    from work._same_dec as d
    inner join work._group_assign as a
      on d.s_code_a = a.s_code and d.col_order_a = a.col_order
    where d.col_order_a is not missing
      and strip(d.header_a) ne ''
      and lowcase(strip(d.header_a)) ne lowcase(strip(a.original_header));
    create table work._same_hdr_bad_b as
    select d.s_code_b as s_code length=4,
           d.header_b as header_given length=256,
           d.col_order_b as col_order,
           b.original_header as header_actual length=256
    from work._same_dec as d
    inner join work._group_assign as b
      on d.s_code_b = b.s_code and d.col_order_b = b.col_order
    where d.col_order_b is not missing
      and strip(d.header_b) ne ''
      and lowcase(strip(d.header_b)) ne lowcase(strip(b.original_header));
  quit;
  %local _n_same_hdr_bad;
  proc sql noprint;
    select count(*) + (select count(*) from work._same_hdr_bad_b)
    into :_n_same_hdr_bad trimmed
    from work._same_hdr_bad_a;
  quit;
  %if &_n_same_hdr_bad > 0 %then %do;
    data _null_;
      set work._same_hdr_bad_a;
      put 'ERROR: [04_name_map] SAME_HDR_MISMATCH_A: '
          s_code= col_order= header_given= header_actual=;
    run;
    data _null_;
      set work._same_hdr_bad_b;
      put 'ERROR: [04_name_map] SAME_HDR_MISMATCH_B: '
          s_code= col_order= header_given= header_actual=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B3: &_n_same_hdr_bad SAME header_x does not match original_header);
    %goto _asc_done;
  %end;

  /* Build group-id pairs for SAME edges; pre-check: no same-s_code link */
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
    %let _rc = 1;
    %let _fail_msg = %str(B5: SAME decision links two columns from the same file (s_code));
    %goto _asc_done;
  %end;

  /* B1: union-find -- iterative min-label propagation, max 50 passes */
  proc sql noprint;
    create table work._uf_map as
    select distinct group_id, group_id as canon_id
    from work._group_final;
  quit;

  %local _uf_pass _uf_changed;
  %let _uf_pass    = 0;
  %let _uf_changed = 1;

  %do %while (&_uf_changed > 0 and &_uf_pass < 50);
    %let _uf_pass = %eval(&_uf_pass + 1);
    proc sql noprint;
      create table work._uf_updates as
      select m.group_id,
             min(m.canon_id,
                 coalesce(from_b.mc, m.canon_id),
                 coalesce(from_a.mc, m.canon_id)) as new_canon
      from work._uf_map as m
      left join (select s.grp_b as group_id, min(ma.canon_id) as mc
                 from work._same_grpids as s
                 inner join work._uf_map as ma on s.grp_a = ma.group_id
                 group by s.grp_b) as from_b
        on m.group_id = from_b.group_id
      left join (select s.grp_a as group_id, min(mb.canon_id) as mc
                 from work._same_grpids as s
                 inner join work._uf_map as mb on s.grp_b = mb.group_id
                 group by s.grp_a) as from_a
        on m.group_id = from_a.group_id
      group by m.group_id;
    quit;
    proc sql noprint;
      select count(*) into :_uf_changed trimmed
      from work._uf_updates as u
      inner join work._uf_map as o on u.group_id = o.group_id
      where u.new_canon ne o.canon_id;
    quit;
    proc sql noprint;
      update work._uf_map as m
      set canon_id = (select u.new_canon from work._uf_updates as u
                      where u.group_id = m.group_id);
    quit;
  %end;

  %if &_uf_changed > 0 %then %do;
    %let _rc = 1;
    %let _fail_msg = %str(B1: SAME union-find did not converge after 50 passes);
    %goto _asc_done;
  %end;

  proc sql noprint;
    update work._group_final as g
    set group_id = (select m.canon_id from work._uf_map as m
                    where m.group_id = g.group_id);
  quit;

  %_asc_done:
%mend _apply_same_closure;

/* B2+B3-DIFF: existence check, header check, split b-side rows into new groups.
   Reads work._diff_dec (s_code_a, header_a, col_order_a, s_code_b, header_b, col_order_b)
   and work._group_final (s_code, col_order, original_header, group_id).
   Modifies work._group_final in-place.
   Sets %global _rc (0=pass, 1=fail) and _fail_msg. */
%macro _apply_different_split;
  %global _rc _fail_msg;
  %let _rc = 0;
  %let _fail_msg = ;

  %local _ndiff;
  proc sql noprint;
    select count(*) into :_ndiff trimmed from work._diff_dec;
  quit;
  %if &_ndiff = 0 %then %goto _ads_done;

  /* B3: existence check */
  proc sql noprint;
    create table work._diff_missing_a as
    select d.s_code_a, d.header_a, d.col_order_a
    from work._diff_dec as d
    where d.s_code_a is not missing
      and not exists (
        select 1 from work._group_final as a
        where a.s_code = d.s_code_a
          and (d.col_order_a is not missing and a.col_order = d.col_order_a
               or d.col_order_a is missing
                  and lowcase(a.original_header) = lowcase(d.header_a)));
    create table work._diff_missing_b as
    select d.s_code_b, d.header_b, d.col_order_b
    from work._diff_dec as d
    where d.s_code_b is not missing
      and not exists (
        select 1 from work._group_final as a
        where a.s_code = d.s_code_b
          and (d.col_order_b is not missing and a.col_order = d.col_order_b
               or d.col_order_b is missing
                  and lowcase(a.original_header) = lowcase(d.header_b)));
  quit;
  %local _n_diff_miss;
  proc sql noprint;
    select count(*) + (select count(*) from work._diff_missing_b)
    into :_n_diff_miss trimmed
    from work._diff_missing_a;
  quit;
  %if &_n_diff_miss > 0 %then %do;
    data _null_;
      set work._diff_missing_a;
      put 'ERROR: [04_name_map] DIFF_SIDE_MISSING_A: ' s_code_a= header_a= col_order_a=;
    run;
    data _null_;
      set work._diff_missing_b;
      put 'ERROR: [04_name_map] DIFF_SIDE_MISSING_B: ' s_code_b= header_b= col_order_b=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B3: &_n_diff_miss DIFFERENT side(s) not found in name_map by (s_code,col_order));
    %goto _ads_done;
  %end;

  /* B3: when col_order provided and header non-blank, header_x must match original_header */
  proc sql noprint;
    create table work._diff_hdr_bad_a as
    select d.s_code_a as s_code length=4,
           d.header_a as header_given length=256,
           d.col_order_a as col_order,
           a.original_header as header_actual length=256
    from work._diff_dec as d
    inner join work._group_final as a
      on d.s_code_a = a.s_code and d.col_order_a = a.col_order
    where d.col_order_a is not missing
      and strip(d.header_a) ne ''
      and lowcase(strip(d.header_a)) ne lowcase(strip(a.original_header));
    create table work._diff_hdr_bad_b as
    select d.s_code_b as s_code length=4,
           d.header_b as header_given length=256,
           d.col_order_b as col_order,
           b.original_header as header_actual length=256
    from work._diff_dec as d
    inner join work._group_final as b
      on d.s_code_b = b.s_code and d.col_order_b = b.col_order
    where d.col_order_b is not missing
      and strip(d.header_b) ne ''
      and lowcase(strip(d.header_b)) ne lowcase(strip(b.original_header));
  quit;
  %local _n_diff_hdr_bad;
  proc sql noprint;
    select count(*) + (select count(*) from work._diff_hdr_bad_b)
    into :_n_diff_hdr_bad trimmed
    from work._diff_hdr_bad_a;
  quit;
  %if &_n_diff_hdr_bad > 0 %then %do;
    data _null_;
      set work._diff_hdr_bad_a;
      put 'ERROR: [04_name_map] DIFF_HDR_MISMATCH_A: '
          s_code= col_order= header_given= header_actual=;
    run;
    data _null_;
      set work._diff_hdr_bad_b;
      put 'ERROR: [04_name_map] DIFF_HDR_MISMATCH_B: '
          s_code= col_order= header_given= header_actual=;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B3: &_n_diff_hdr_bad DIFFERENT header_x does not match original_header);
    %goto _ads_done;
  %end;

  /* B2: find b-side rows in the same group as their a-side partner; split them */
  proc sql noprint;
    create table work._diff_splits as
    select b.s_code, b.col_order, b.group_id as old_group_id
    from work._diff_dec as d
    inner join work._group_final as a
      on d.s_code_a = a.s_code
     and (d.col_order_a is not missing and d.col_order_a = a.col_order
          or d.col_order_a is missing
             and lowcase(d.header_a) = lowcase(a.original_header))
    inner join work._group_final as b
      on d.s_code_b = b.s_code
     and (d.col_order_b is not missing and d.col_order_b = b.col_order
          or d.col_order_b is missing
             and lowcase(d.header_b) = lowcase(b.original_header))
    where a.group_id = b.group_id;
  quit;

  %local _nsplits;
  proc sql noprint;
    select count(*) into :_nsplits trimmed from work._diff_splits;
  quit;

  %if &_nsplits > 0 %then %do;
    %local _max_grp;
    proc sql noprint;
      select max(group_id) into :_max_grp trimmed from work._group_final;
    quit;
    data work._diff_splits;
      set work._diff_splits;
      new_group_id = &_max_grp + _N_;
    run;
    %put NOTE: [04_name_map] DIFFERENT: splitting &_nsplits b-side row(s) to new group_ids;
    proc sql noprint;
      update work._group_final as g
      set group_id = (select ds.new_group_id
                      from work._diff_splits as ds
                      where ds.s_code = g.s_code and ds.col_order = g.col_order)
      where exists (select 1 from work._diff_splits as ds
                    where ds.s_code = g.s_code and ds.col_order = g.col_order);
    quit;
  %end;
  %else %do;
    %put NOTE: [04_name_map] DIFFERENT: no b-side rows share a group with a-side;
  %end;

  /* Post-split invariant: no DIFFERENT pair may share final group_id */
  proc sql noprint;
    create table work._diff_samegroup as
    select a.group_id,
           a.s_code as s_code_a, a.col_order as col_order_a,
           b.s_code as s_code_b, b.col_order as col_order_b
    from work._diff_dec as d
    inner join work._group_final as a
      on d.s_code_a = a.s_code
     and (d.col_order_a is not missing and d.col_order_a = a.col_order
          or d.col_order_a is missing
             and lowcase(d.header_a) = lowcase(a.original_header))
    inner join work._group_final as b
      on d.s_code_b = b.s_code
     and (d.col_order_b is not missing and d.col_order_b = b.col_order
          or d.col_order_b is missing
             and lowcase(d.header_b) = lowcase(b.original_header))
    where a.group_id = b.group_id;
  quit;
  %local _ndiff_bad;
  proc sql noprint;
    select count(*) into :_ndiff_bad trimmed from work._diff_samegroup;
  quit;
  %if &_ndiff_bad > 0 %then %do;
    data _null_;
      set work._diff_samegroup;
      put 'ERROR: [04_name_map] DIFF_SAMEGROUP: group_id=' group_id
          ' s_code_a=' s_code_a ' col_order_a=' col_order_a
          ' s_code_b=' s_code_b ' col_order_b=' col_order_b;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B2: &_ndiff_bad DIFFERENT pairs remain in same group after split);
    %goto _ads_done;
  %end;

  %_ads_done:
%mend _apply_different_split;

/* B5: same-file guard -- no group may contain two rows with the same s_code.
   Reads work._group_final.
   Sets %global _rc (0=pass, 1=fail) and _fail_msg. */
%macro _assert_no_same_file_dup;
  %global _rc _fail_msg;
  %let _rc = 0;
  %let _fail_msg = ;

  proc sql noprint;
    create table work._grp_scode_dup as
    select group_id, s_code, count(*) as n
    from work._group_final
    where group_id is not missing
    group by group_id, s_code
    having count(*) > 1;
  quit;

  %local _n_gsdup;
  proc sql noprint;
    select count(*) into :_n_gsdup trimmed from work._grp_scode_dup;
  quit;
  %if &_n_gsdup > 0 %then %do;
    data _null_;
      set work._grp_scode_dup;
      put 'ERROR: [04_name_map] GRP_SCODE_DUP: group_id=' group_id
          ' s_code=' s_code ' n=' n;
    run;
    %let _rc = 1;
    %let _fail_msg = %str(B5: &_n_gsdup (group_id,s_code) pairs have more than 1 row);
  %end;
%mend _assert_no_same_file_dup;
