/*==========================================================================
  File    : sas/17_pecan_id_link_macros.sas
  Phase   : 17 (PECAN_ID), plan 17-04 (PID-06). Macros only.
  Purpose : Cross-era link of K2 MRNs to K1 patients through a crosswalk
            (K2 MRN to K1 MRN, or both eras re-encrypted under one key).
            DRYRUN (default) writes QC only. APPLY needs
            PDD_APPROVE_NEW_BASELINE=1 and a registry equal to its latest
            backup (checked with approval switched off), fills
            LINKED_TO_PECAN_ID and LINK_SOURCE, sets matched K2 rows to
            SUPERSEDED, never changes a PECAN_ID value, never deletes. The new
            registry is built in a NEW dataset, verified, backed up, then
            replaced. Linked cases in the case map carry the K1 PECAN_ID and
            PECAN_ID_KEY_ERA = K1.
  Needs   : sas/17_pecan_id_macros.sas included first, and %fail_out.
  Status  : written and tested (17_pecan_id_link_test.sas), NOT RUN.
==========================================================================*/

/* Crosswalk CSV: header row, columns K2_MRN and K1_MRN. utf-8 by default,
   a probe must say otherwise (then pass encoding through the program). */
%macro p17l_load(csv=, out=);
  data &out;
    length k2_mrn $64 k1_mrn $64;
    infile "&csv" dsd dlm=',' truncover firstobs=2 lrecl=32767 encoding='utf-8';
    input k2_mrn $ k1_mrn $;
    k2_mrn = strip(k2_mrn);
    k1_mrn = strip(k1_mrn);
  run;
%mend p17l_load;

/* Refusals, each counted in pdd.qc_pecan_id_link. Global p17l_n_bad. */
%macro p17l_validate(xw=, reg=pdd.pecan_id_registry);
  %global p17l_n_bad p17l_n_xw;
  %local _c0 _c1 _c2 _c3 _c4 _c5;
  %let _c0=0; %let _c1=0; %let _c2=0; %let _c3=0; %let _c4=0; %let _c5=0;
  proc sql noprint;
    select count(*) into :p17l_n_xw trimmed from &xw;
    select count(*) into :_c0 trimmed from &xw
      where strip(k2_mrn) = '' or strip(k1_mrn) = '';
    select count(*) into :_c1 trimmed from
      (select k2_mrn from &xw group by k2_mrn having count(distinct k1_mrn) > 1);
    select count(*) into :_c2 trimmed from &xw x
      where not exists (select 1 from &reg r
                        where r.KEY_ERA = 'K1' and r.ENCRYPTED_MRN = x.k1_mrn);
    select count(*) into :_c3 trimmed from &xw x
      where not exists (select 1 from &reg r
                        where r.KEY_ERA = 'K2' and r.ENCRYPTED_MRN = x.k2_mrn);
    select count(*) into :_c4 trimmed from
      (select ENCRYPTED_MRN from &reg
       where KEY_ERA = 'K1' and ENCRYPTED_MRN in (select k1_mrn from &xw)
       group by ENCRYPTED_MRN having count(*) > 1);
    select count(*) into :_c5 trimmed from &reg r, &reg k, &xw x
      where r.KEY_ERA = 'K2' and r.ENCRYPTED_MRN = x.k2_mrn
        and k.KEY_ERA = 'K1' and k.ENCRYPTED_MRN = x.k1_mrn
        and not missing(r.LINKED_TO_PECAN_ID)
        and r.LINKED_TO_PECAN_ID ne k.PECAN_ID;
  quit;
  %p17_qinit(ds=pdd.qc_pecan_id_link);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=CROSSWALK_ROWS, n=&p17l_n_xw);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=REFUSE_BLANK_MRN, n=&_c0, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=REFUSE_K2_MRN_TO_TWO_K1_MRNS, n=&_c1, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=REFUSE_K1_MRN_NOT_IN_K1_REGISTRY, n=&_c2, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=REFUSE_K2_MRN_NOT_IN_K2_REGISTRY, n=&_c3, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=REFUSE_K1_MRN_WITH_MORE_THAN_ONE_ID, n=&_c4, fail=1);
  %p17_qadd(ds=pdd.qc_pecan_id_link, item=REFUSE_K2_ALREADY_LINKED_TO_OTHER_K1, n=&_c5, fail=1);
  %let p17l_n_bad = %eval(&_c0 + &_c1 + &_c2 + &_c3 + &_c4 + &_c5);
  %if &p17l_n_bad > 0 %then
    %p17_fail(msg=%str(crosswalk refused - blank MRN &_c0., K2 MRN to two K1 MRNs &_c1., K1 MRN not in registry &_c2., K2 MRN not in registry &_c3., K1 MRN with several IDs &_c4., already linked elsewhere &_c5.));
%mend p17l_validate;

/* mode = DRYRUN or APPLY. Leaves work.p17l_chg (old K2 ID, new K1 ID, cases)
   for the caller to export to qc. Global p17l_n_changed. */
%macro p17l_run(xw=, mode=DRYRUN, reg=pdd.pecan_id_registry, map=pdd.pecan_id_case_map);
  %global p17l_n_changed;
  %local _md _ap _n_reg _n_nxt _d1 _d2;
  %let p17l_n_changed = 0;
  %let _md = %upcase(&mode);
  %if &_md ne DRYRUN and &_md ne APPLY %then %do;
    %p17_fail(msg=%str(PDD_LINK_MODE must be DRYRUN or APPLY));
  %end;
  %else %do;
    %p17l_validate(xw=&xw, reg=&reg);
    %if &p17l_n_bad = 0 %then %do;
      proc sql noprint;
        create table work.p17l_map as
          select distinct x.k2_mrn, r.PECAN_ID as k1_id
          from &xw x, &reg r
          where r.KEY_ERA = 'K1' and r.ENCRYPTED_MRN = x.k1_mrn;
      quit;
      data work.p17l_r0;
        set &reg;
        _ord = _n_;
      run;
      proc sql noprint;
        create table work.p17l_r1 as
          select r.*, m.k1_id
          from work.p17l_r0 r
          left join work.p17l_map m
            on r.KEY_ERA = 'K2' and r.ENCRYPTED_MRN = m.k2_mrn
          order by r._ord;
      quit;
      data work.p17l_next;
        %p17_reg_attrs;
        length _chg 8;
        set work.p17l_r1(rename=(LINKED_TO_PECAN_ID=_old_lk LINK_SOURCE=_old_ls STATUS=_old_st));
        LINKED_TO_PECAN_ID = _old_lk;
        LINK_SOURCE = _old_ls;
        STATUS = _old_st;
        _chg = 0;
        if not missing(k1_id) then do;
          if missing(_old_lk) or _old_lk ne k1_id or _old_st ne 'SUPERSEDED' then _chg = 1;
          LINKED_TO_PECAN_ID = k1_id;
          LINK_SOURCE = 'xwalk_csv';
          STATUS = 'SUPERSEDED';
        end;
        drop _old_lk _old_ls _old_st k1_id _ord;
      run;
      proc sql noprint;
        select coalesce(sum(_chg), 0) into :p17l_n_changed trimmed from work.p17l_next;
        create table work.p17l_chg as
          select n.PECAN_ID as old_k2_id, n.LINKED_TO_PECAN_ID as new_k1_id,
                 (select count(*) from &map m
                  where m.KEY_ERA = 'K2' and m.ENCRYPTED_MRN = n.ENCRYPTED_MRN) as n_cases
          from work.p17l_next n where n._chg = 1;
      quit;
      %p17_qadd(ds=pdd.qc_pecan_id_link, item=K2_ROWS_TO_LINK, n=&p17l_n_changed);
      %put NOTE: [p17] link &_md - K2 registry rows to link or relink &p17l_n_changed;

      %if &_md = APPLY %then %do;
        %if "&PDD_APPROVE_NEW_BASELINE" ne "1" %then %do;
          %p17_fail(msg=%str(APPLY needs PDD_APPROVE_NEW_BASELINE=1 - nothing changed));
        %end;
        %else %if &p17l_n_changed = 0 %then %do;
          %put NOTE: [p17] link APPLY - nothing to change, registry and case map untouched;
        %end;
        %else %do;
          /* backup-current check with approval switched off */
          %let _ap = &PDD_APPROVE_NEW_BASELINE;
          %let PDD_APPROVE_NEW_BASELINE = 0;
          %p17_assert_backup_current;
          %let PDD_APPROVE_NEW_BASELINE = &_ap;
          %if &_p17_failed = 0 %then %do;
            /* verify the new registry before it replaces the old one */
            data pdd.pecan_id_registry_next;
              set work.p17l_next;
              drop _chg;
            run;
            %let _d1 = 0; %let _d2 = 0;
            %p17_nobs(ds=&reg, mv=_n_reg);
            %p17_nobs(ds=pdd.pecan_id_registry_next, mv=_n_nxt);
            proc sql noprint;
              select count(*) into :_d1 trimmed from
                (select PECAN_ID, ENCRYPTED_MRN, KEY_ERA from &reg
                 except select PECAN_ID, ENCRYPTED_MRN, KEY_ERA from pdd.pecan_id_registry_next);
              select count(*) into :_d2 trimmed from
                (select PECAN_ID, ENCRYPTED_MRN, KEY_ERA from pdd.pecan_id_registry_next
                 except select PECAN_ID, ENCRYPTED_MRN, KEY_ERA from &reg);
            quit;
            %if &_n_reg ne &_n_nxt or %eval(&_d1 + &_d2) > 0 %then %do;
              %p17_fail(msg=%str(new registry failed verification - rows &_n_reg. vs &_n_nxt., changed keys &_d1. and &_d2.. Registry untouched));
            %end;
            %else %do;
              %p17_backup_table(ds=&reg, stem=pidreg_prelink);
              data &reg;
                set pdd.pecan_id_registry_next;
              run;
              %p17_gate_registry(reg=&reg);
              %p17_backup;
              /* case map: back up, then rebuild from its own K1 and K2 rows */
              %p17_backup_table(ds=&map, stem=pidmap);
              data work.p17l_k1;
                set &map(where=(KEY_ERA = 'K1'));
              run;
              data work.p17l_k2;
                set &map(where=(KEY_ERA = 'K2')
                         keep=norm_psid ENCRYPTED_MRN SRC_UNIT MRN_STATUS KEY_ERA);
                mrn_usable = (MRN_STATUS = 'OK');
              run;
              %p17_casemap(k1=work.p17l_k1, k2=work.p17l_k2, reg=&reg, out=work.p17l_newmap);
              data &map;
                set work.p17l_newmap;
              run;
              %p17_gate_casemap(map=&map, reg=&reg);
            %end;
          %end;
        %end;
      %end;
    %end;
  %end;
%mend p17l_run;
