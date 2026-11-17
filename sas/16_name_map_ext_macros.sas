/*==========================================================================
  File    : sas/16_name_map_ext_macros.sas
  Purpose : Phase 16 (M3) naming macros for the extend-only name map.
            Same rules as Phase 4 (04_name_map.sas), copied into side-effect
            free macros: clean, abbreviate, elide, PCNR_ prefix, and the
            suffix rule seeded with every existing final name.
            Contains NO executable open-code statements.
  Callers : include sas/04_name_map_macros.sas first (it supplies the
            elide_middle macro used here; it is not copied).
  Never   : writes pdd.name_map or pdd.name_map_vars (frozen).
==========================================================================*/

/* MAP-01 cleaning key. Body is identical to Phase 4 clean_name.
   DATA-step fragment: raw= and out= are variables ($200 or wider). */
%macro p16_clean_name(raw=, out=);
  &out = strip(&raw);
  &out = prxchange('s/[^A-Za-z0-9]+/_/', -1, strip(&out));
  &out = prxchange('s/^_+//', 1, strip(&out));
  &out = prxchange('s/_+$//', 1, strip(&out));
  if prxmatch('/^\d/', strip(&out)) then &out = cats('N_', strip(&out));
%mend p16_clean_name;

/* Load and validate an abbreviation CSV (long, short, mode; header row).
   Writes &out sorted by descending long length (columns long short mode
   _longlen _is_lower). Sets globals p16_abbrev_bad (rows failing the Phase 4
   checks; the caller must fail when above 0) and p16_abbrev_lower. */
%macro p16_load_abbrev(csv=, out=, lower=1);
  %global p16_abbrev_bad p16_abbrev_lower;
  %let p16_abbrev_bad = 0;
  %let p16_abbrev_lower = &lower;

  data work._p16_ab_raw;
    length long $200 short $200 mode $10;
    infile "&csv" encoding='utf-8' dsd dlm=',' missover firstobs=2 lrecl=32767;
    input long $ short $ mode $;
    long  = strip(long);
    short = strip(short);
    mode  = strip(mode);
    if long = '' then delete;
  run;

  proc sql noprint;
    select count(*) into :p16_abbrev_bad trimmed
    from work._p16_ab_raw
    where short = ''
       or strip(long) = strip(short)
       or prxmatch('/[^A-Za-z0-9_]/', strip(long))  > 0
       or prxmatch('/[^A-Za-z0-9_]/', strip(short)) > 0
       or prxmatch('/^[^A-Za-z]/', strip(long)) > 0
       or upcase(strip(mode)) not in ('ALWAYS', 'AS_NEEDED');
  quit;

  data &out;
    set work._p16_ab_raw;
    _longlen  = length(long);
    _is_lower = (prxmatch('/^[a-z]/', strip(long)) > 0);
  run;

  proc sort data=&out;
    by descending _longlen;
  run;
%mend p16_load_abbrev;

/* Apply abbreviations then middle-elide to 27 (Phase 4 lines 777-831).
   DATA-step fragment. nm= is the variable to shorten.
   Caller must declare: _ai _nab_tot _longlen _is_lower _p16_longer 8,
   _cbe $200, _pat $400, long short $200, mode $10, and the elide helpers
   (_elide_first _elide_last 8, _elide_head _elide_tail $200), and must
   run  if 0 then set <abbrev> nobs=_nab_tot;  retain _nab_tot;  first.
   Sets _p16_longer = 1 when an abbreviation lengthened a name. */
%macro p16_shorten(nm=, abbrev=);
  /* Pass 1: ALWAYS rows, unconditionally */
  do _ai = 1 to _nab_tot;
    set &abbrev (keep=long short _longlen _is_lower mode) point=_ai;
    if upcase(strip(mode)) ne 'ALWAYS' then continue;
    if not (_is_lower and not &p16_abbrev_lower) then do;
      _cbe = &nm;
      if _is_lower then
        _pat = cats('s/(?i)(?:^|(?<=_))', strip(long), '(?=_|$)/', strip(short), '/');
      else
        _pat = cats('s/', strip(long), '(?=[A-Z0-9_]|$)/', strip(short), '/');
      &nm = prxchange(_pat, -1, strip(&nm));
      if length(strip(&nm)) > length(strip(_cbe)) then _p16_longer = 1;
    end;
  end;
  /* Pass 2: AS_NEEDED rows, longest first, stop once length is 27 or less */
  if length(strip(&nm)) > 27 then do _ai = 1 to _nab_tot;
    set &abbrev (keep=long short _longlen _is_lower mode) point=_ai;
    if length(strip(&nm)) <= 27 then leave;
    if upcase(strip(mode)) ne 'AS_NEEDED' then continue;
    if not (_is_lower and not &p16_abbrev_lower) then do;
      _cbe = &nm;
      if _is_lower then
        _pat = cats('s/(?i)(?:^|(?<=_))', strip(long), '(?=_|$)/', strip(short), '/');
      else
        _pat = cats('s/', strip(long), '(?=[A-Z0-9_]|$)/', strip(short), '/');
      &nm = prxchange(_pat, -1, strip(&nm));
      if length(strip(&nm)) > length(strip(_cbe)) then _p16_longer = 1;
    end;
  end;
  %elide_middle(nm=&nm);
%mend p16_shorten;

/* Extend-only suffix rule.
   &in   : group_id s_code col_order pcnr_name_base (no PCNR_ prefix), in
           the order names are to be claimed.
   &used : one row per existing final name, variable name_nop (no PCNR_).
   &out  : &in columns plus pcnr_name_final, suffix_n, reason.
   Existing names are only keys in a hash and are never changed.
   A taken base gets the first free _2, _3, ... with the base re-elided so
   base plus suffix fits in 27 characters. */
%macro p16_assign_names(in=, used=, out=);
  data &out (keep=group_id s_code col_order pcnr_name_base
                  pcnr_name_final suffix_n reason);
    length pcnr_name_final $32 reason $20 suffix_n 8
           _b $200 _cand $200 _k $200 _sfx $12
           _k2 8 _tgt 8 _found 8 _i 8 _nu 8 _rc 8
           _elide_first 8 _elide_last 8 _elide_head $200 _elide_tail $200;
    if _n_ = 1 then do;
      declare hash _used();
      _used.defineKey('_k');
      _used.defineDone();
      declare hash _new();
      _new.defineKey('_k');
      _new.defineDone();
      do _i = 1 to _nu;
        set &used (keep=name_nop) point=_i nobs=_nu;
        _k = lowcase(strip(name_nop));
        _rc = _used.add();
      end;
    end;

    set &in;

    _k = lowcase(strip(pcnr_name_base));
    if _new.check() = 0 then reason = 'NEW_NAME_EARLIER';
    else if _used.check() = 0 then reason = 'EXISTING_NAME';
    else reason = 'NONE';

    if reason = 'NONE' then do;
      _cand    = strip(pcnr_name_base);
      suffix_n = 1;
    end;
    else do;
      _found = 0;
      do _k2 = 2 to 9999 until (_found);
        _sfx = cats('_', _k2);
        _b   = strip(pcnr_name_base);
        if length(strip(_b)) + length(strip(_sfx)) > 27 then do;
          _tgt = 27 - length(strip(_sfx));
          %elide_middle(nm=_b, target=_tgt);
        end;
        _cand = cats(strip(_b), strip(_sfx));
        _k = lowcase(strip(_cand));
        if _used.check() ne 0 and _new.check() ne 0 then do;
          _found   = 1;
          suffix_n = _k2;
        end;
      end;
    end;

    _k = lowcase(strip(_cand));
    _rc = _new.add();
    pcnr_name_final = cats('PCNR_', strip(_cand));
  run;
%mend p16_assign_names;

/* Stage 2 checks, reusable. &ds needs status, pcnr_name, group_id.
   Counts: (a) a name (case-insensitive) on more than one group_id,
   (b) length above 32, (c) not a valid V7 name, (d) three underscores in a row.
   Sets global p16_stage2_fail to the total (the caller fails when above 0).
   quiet=1 writes NOTE instead of ERROR (for synthetic negative tests). */
%macro p16_stage2(ds=, label=, quiet=0);
  %global p16_stage2_fail;
  %local _n_a _n_b _n_c _n_d _pfx;
  %let _n_a = 0;
  %let _n_b = 0;
  %let _n_c = 0;
  %let _n_d = 0;
  %let p16_stage2_fail = 0;
  %if &quiet = 1 %then %let _pfx = NOTE;
  %else %let _pfx = ERROR;

  proc sql noprint;
    create table work._p16_s2_dups as
    select upcase(pcnr_name) as nm length=200, count(distinct group_id) as n_groups
    from &ds
    where status = 'PCNR' and pcnr_name ne ''
    group by upcase(pcnr_name)
    having count(distinct group_id) > 1;
    select count(*) into :_n_a trimmed from work._p16_s2_dups;
    select count(*) into :_n_b trimmed
    from &ds
    where status = 'PCNR' and pcnr_name ne '' and length(pcnr_name) > 32;
    select count(*) into :_n_c trimmed
    from &ds
    where status = 'PCNR' and pcnr_name ne '' and not nvalid(pcnr_name, 'v7');
    select count(*) into :_n_d trimmed
    from &ds
    where status = 'PCNR' and pcnr_name ne '' and prxmatch('/___/', pcnr_name) > 0;
  quit;

  data _null_;
    set work._p16_s2_dups;
    put "&_pfx: [&label] S2_DUP: " nm= n_groups=;
  run;
  data _null_;
    set &ds (keep=status pcnr_name);
    if status = 'PCNR' and pcnr_name ne '' then do;
      if length(pcnr_name) > 32 then put "&_pfx: [&label] S2_TOOLONG: " pcnr_name=;
      if not nvalid(pcnr_name, 'v7') then put "&_pfx: [&label] S2_INVALID: " pcnr_name=;
      if prxmatch('/___/', pcnr_name) > 0 then put "&_pfx: [&label] S2_TRIPLE_UNDERSCORE: " pcnr_name=;
    end;
  run;

  %let p16_stage2_fail = %eval(&_n_a + &_n_b + &_n_c + &_n_d);
%mend p16_stage2;
