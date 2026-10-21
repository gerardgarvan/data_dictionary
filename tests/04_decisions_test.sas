/*==========================================================================
  Program : tests/04_decisions_test.sas
  Purpose : Synthetic unit test for grouping/suffix/elide macros in
            04_name_map.sas.  Exercises:
              - SAME chain (A=B, B=C -> one group)
              - DIFFERENT split (D and E auto-grouped, then split)
              - Conflicting RENAME (two different rename targets in one group)
              - Suffix re-elision across an internal _ (name > 27 chars + suffix)
            Does NOT use real data.  Run standalone; %abort if any check fails.
==========================================================================*/

/* ── Macros needed (copied verbatim from 04_name_map.sas Section 0) ──── */
%macro fail_out(msg=);
  %put ERROR: [04_decisions_test] &msg;
  %abort cancel;
%mend fail_out;

/* target= may be a SAS variable name or integer literal */
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

/* ── Synthetic name table (10 rows) ─────────────────────────────────── */
data work._t_names;
  length s_code $4 col_order 8 original_header $40 cleaned $40 group_id 8;
  /* Rows 1-3: SAME chain A=B, B=C (different files) */
  s_code='s01'; col_order=1; original_header='Apples'; cleaned='Apples'; group_id=1; output;
  s_code='s02'; col_order=1; original_header='Apples'; cleaned='Apples'; group_id=2; output;
  s_code='s03'; col_order=1; original_header='Apples'; cleaned='Apples'; group_id=3; output;
  /* Rows 4-5: DIFFERENT pair (D-01a auto-groups them, then DIFFERENT splits) */
  s_code='s04'; col_order=1; original_header='Weight'; cleaned='Weight'; group_id=4; output;
  s_code='s05'; col_order=1; original_header='Weight'; cleaned='Weight'; group_id=4; output;
  /* Row 6-7: conflicting RENAME inside one group */
  s_code='s06'; col_order=1; original_header='Score';  cleaned='Score';  group_id=5; output;
  s_code='s07'; col_order=1; original_header='Score';  cleaned='Score';  group_id=5; output;
  /* Row 8: name that needs re-elision when suffix is added */
  s_code='s08'; col_order=1;
    original_header='VeryLongName_WithUnder_AndMore'; cleaned='VeryLongName_WithUnder_AndMore';
    group_id=6; output;
  /* Row 9-10: second group sharing same upcase base (triggers suffix) */
  s_code='s09'; col_order=1;
    original_header='VeryLongName_WithUnder_AndMore'; cleaned='VeryLongName_WithUnder_AndMore';
    group_id=7; output;
  s_code='s10'; col_order=2;
    original_header='DifferentHeader'; cleaned='DifferentHeader'; group_id=8; output;
run;

/* ── Test 1: SAME chain ──────────────────────────────────────────────── */
/* Groups 1,2,3 should all collapse to group 1 after: SAME(s01c1, s02c1) and SAME(s02c1, s03c1) */
data work._t_same_dec;
  length s_code_a $4 col_order_a 8 s_code_b $4 col_order_b 8;
  s_code_a='s01'; col_order_a=1; s_code_b='s02'; col_order_b=1; output; /* A=B */
  s_code_a='s02'; col_order_a=1; s_code_b='s03'; col_order_b=1; output; /* B=C */
run;

/* Build initial _same_grpids from the synthetic table */
proc sql noprint;
  create table work._same_grpids as
  select a.group_id as grp_a, b.group_id as grp_b
  from work._t_same_dec as d
  inner join work._t_names as a
    on d.s_code_a = a.s_code and d.col_order_a = a.col_order
  inner join work._t_names as b
    on d.s_code_b = b.s_code and d.col_order_b = b.col_order
  where a.group_id ne b.group_id;
quit;

/* Copy names to a working table and run the union-find logic */
data work._t_final;
  set work._t_names;
run;

proc sql noprint;
  create table work._uf_map as
  select distinct group_id, group_id as canon_id
  from work._t_final;
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

%if &_uf_changed > 0 %then %fail_out(msg=%str(TEST1: SAME union-find did not converge));

proc sql noprint;
  update work._t_final as g
  set group_id = (select m.canon_id from work._uf_map as m
                  where m.group_id = g.group_id);
quit;

/* Assert: s01,s02,s03 all share one group_id = 1 */
%local _t1_ok;
proc sql noprint;
  select count(distinct group_id) into :_t1_ok trimmed
  from work._t_final
  where s_code in ('s01','s02','s03');
quit;
%if &_t1_ok ne 1 %then
  %fail_out(msg=%str(TEST1 FAIL: SAME chain A=B,B=C did not collapse to one group (n_groups=&_t1_ok)));
%put NOTE: [04_decisions_test] TEST1 PASS: SAME chain collapsed groups 1-2-3 to one group_id;

/* ── Test 2: DIFFERENT split ─────────────────────────────────────────── */
/* After SAME merge, s04 and s05 are both in group 4.
   DIFFERENT(s04c1, s05c1) should split s05 to a new group. */
data work._t_diff_dec;
  length s_code_a $4 col_order_a 8 s_code_b $4 col_order_b 8;
  s_code_a='s04'; col_order_a=1; s_code_b='s05'; col_order_b=1; output;
run;

proc sql noprint;
  create table work._t_diff_splits as
  select b.s_code, b.col_order, b.group_id as old_group_id
  from work._t_diff_dec as d
  inner join work._t_final as a
    on d.s_code_a = a.s_code and d.col_order_a = a.col_order
  inner join work._t_final as b
    on d.s_code_b = b.s_code and d.col_order_b = b.col_order
  where a.group_id = b.group_id;
quit;

%local _t2_n_splits;
proc sql noprint;
  select count(*) into :_t2_n_splits trimmed from work._t_diff_splits;
quit;
%if &_t2_n_splits = 0 %then
  %fail_out(msg=%str(TEST2 FAIL: no splits detected for DIFFERENT pair in same group));

%local _t2_max_grp;
proc sql noprint;
  select max(group_id) into :_t2_max_grp trimmed from work._t_final;
quit;
data work._t_diff_splits;
  set work._t_diff_splits;
  new_group_id = &_t2_max_grp + _N_;
run;
proc sql noprint;
  update work._t_final as g
  set group_id = (select ds.new_group_id from work._t_diff_splits as ds
                  where ds.s_code = g.s_code and ds.col_order = g.col_order)
  where exists (select 1 from work._t_diff_splits as ds
                where ds.s_code = g.s_code and ds.col_order = g.col_order);
quit;

/* Assert: s04 and s05 are now in different groups */
%local _t2_grp_s04 _t2_grp_s05;
proc sql noprint;
  select group_id into :_t2_grp_s04 trimmed from work._t_final where s_code='s04';
  select group_id into :_t2_grp_s05 trimmed from work._t_final where s_code='s05';
quit;
%if &_t2_grp_s04 = &_t2_grp_s05 %then
  %fail_out(msg=%str(TEST2 FAIL: s04 and s05 still share group_id &_t2_grp_s04 after DIFFERENT split));
%put NOTE: [04_decisions_test] TEST2 PASS: DIFFERENT split -- s04 group=&_t2_grp_s04 s05 group=&_t2_grp_s05;

/* ── Test 3: Conflicting RENAME ──────────────────────────────────────── */
/* s06 and s07 are in group 5; they have two different rename_target values. */
data work._t_rename_dec;
  length s_code $4 col_order_dec 8 rename_target $200;
  s_code='s06'; col_order_dec=1; rename_target='ScoreA'; output;
  s_code='s07'; col_order_dec=1; rename_target='ScoreB'; output; /* conflicts */
run;

proc sql noprint;
  create table work._t_rename_grp_check as
  select gf.group_id, count(distinct strip(r.rename_target)) as n_targets
  from work._t_final as gf
  inner join work._t_rename_dec as r
    on gf.s_code = r.s_code and gf.col_order = r.col_order_dec
  group by gf.group_id
  having count(distinct strip(r.rename_target)) > 1;
quit;

%local _t3_n_conflict;
proc sql noprint;
  select count(*) into :_t3_n_conflict trimmed from work._t_rename_grp_check;
quit;
%if &_t3_n_conflict = 0 %then
  %fail_out(msg=%str(TEST3 FAIL: conflicting RENAME not detected));
%put NOTE: [04_decisions_test] TEST3 PASS: conflicting RENAME detected (&_t3_n_conflict group(s) flagged);

/* ── Test 4: Suffix re-elision via %elide_middle(target=_allowed) ────── */
/* pcnr_name_base = 'VeryLongName_WithUnder_AndMore' (30 chars).
   suffix '_2' -> _allowed = 25.  After %elide_middle the base must fit in 25. */
data work._t_elide_test;
  length _base_trim $200 _elide_head $200 _elide_tail $200;
  length _sfx $10 _candidate $200;
  _elide_first = 0;
  _elide_last  = 0;
  _base    = 'VeryLongName_WithUnder_AndMore'; /* 30 chars */
  _sfx     = '_2';
  _allowed = 27 - length(_sfx);               /* 25 */
  _base_trim = _base;
  %elide_middle(nm=_base_trim, target=_allowed);
  _candidate = cats(_base_trim, _sfx);
  /* Assert final name <= 27 chars and no triple underscore */
  _ok_len  = (length(_candidate) <= 27);
  _ok_notr = (index(_candidate, '___') = 0);
  _ok_char = (prxmatch('/[^A-Za-z0-9_]/', strip(_candidate)) = 0);
  put 'NOTE: [04_decisions_test] TEST4 candidate=' _candidate
      ' len=' _ok_len ' no_triple=' _ok_notr ' char_ok=' _ok_char;
  if not (_ok_len and _ok_notr and _ok_char) then do;
    put 'ERROR: [04_decisions_test] TEST4 FAIL: ' _candidate=;
    call symputx('_t4_fail', '1', 'G');
  end;
run;
%if %symexist(_t4_fail) %then
  %fail_out(msg=%str(TEST4 FAIL: suffix re-elision produced invalid name -- see ERROR above));
%put NOTE: [04_decisions_test] TEST4 PASS: suffix re-elision via %elide_middle fits within 27 chars;

%put NOTE: [04_decisions_test] ALL TESTS PASSED;
