/* check_nearmatch_values.sas -- compare value sets of near-match pairs (counts only) */
%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;
options validvarname=any nomprint nosymbolgen;

%macro nm_check(tag, sc_a, co_a, sc_b, co_b);
  %local i sc co var vn n n_a n_b n_both;
  %do i = 1 %to 2;
    %if &i = 1 %then %do; %let sc=&sc_a; %let co=&co_a; %end;
    %else %do;            %let sc=&sc_b; %let co=&co_b; %end;
    %let var=;
    proc sql noprint;
      select strip(sas_name) into :var trimmed
      from pdd.name_map where s_code="&sc" and col_order=&co;
    quit;
    %if %length(&var) = 0 %then %do;
      %put ERROR: [nm_check] no name_map row for &sc col_order=&co;
      %return;
    %end;
    %let vn = %sysfunc(nliteral(&var));
    proc freq data=pdd.src_&sc noprint;
      tables &vn / missing out=work._f_&i(rename=(&vn=value));
    run;
    proc sort data=work._f_&i; by descending count; run;
    data work._v_&i;
      set work._f_&i;
      length value_c $200;
      value_c = strip(vvalue(value));
      keep value_c count;
    run;
    proc sql noprint; select count(*) into :n trimmed from work._v_&i; quit;
    %put NMCHECK: &tag &sc col=&co var=&var distinct_values=&n;
    %if &n <= 30 %then %do;
      data _null_;
        set work._v_&i;
        put "NMCHECK: &tag &sc   value=" value_c "  n=" count;
      run;
    %end;
    %else %put NMCHECK: &tag &sc more than 30 distinct values -- values not printed;
  %end;
  proc sql noprint;
    select count(*) into :n_a trimmed from work._v_1;
    select count(*) into :n_b trimmed from work._v_2;
    select count(*) into :n_both trimmed
      from work._v_1 a inner join work._v_2 b
      on upcase(a.value_c) = upcase(b.value_c);
  quit;
  %put NMCHECK: &tag SUMMARY distinct_&sc_a=&n_a distinct_&sc_b=&n_b shared_values=&n_both;
%mend nm_check;

%nm_check(ASA,     s06, 94, s03, 36);
%nm_check(HOLIDAY, s06, 84, s03, 24);
