%include "C:\data_dictionary\sas\00_config.sas";
%pdd_lib;
data work._c;
  set pdd.qc_pcnr_conflicts;
  where pcnr_name in ('PCNR_ICD10_Principal_Diagnosis','PCNR_SEV_Exp_IntraOp_MAC_Average',
                      'PCNR_ISO_Exp_IntraOp_MAC_Average','PCNR_Frailty_Score',
                      'PCNR_Age_at_Encounter','PCNR_Death_Date_Y_N','PCNR_Sex','PCNR_YEAR');
  length pair $90 kind $16;
  w = strip(winning_value); c = strip(candidate_value);
  wn = input(w, ?? best32.); cn = input(c, ?? best32.);
  if upcase(compress(w,'. -')) = upcase(compress(c,'. -')) then kind = 'FORMAT_ONLY';
  else if nmiss(wn,cn)=0 and abs(wn-cn) <= 0.01*max(abs(wn),1) then kind = 'NUM_WITHIN_1PCT';
  else kind = 'OTHER';
  pair = catx(' | ', substr(w,1,40), substr(c,1,40));
run;
proc freq data=work._c noprint;
  tables pcnr_name*kind*winning_s_code*candidate_s_code / out=work._k;
run;
data _null_; set work._k; put 'CONFKIND: ' pcnr_name kind winning_s_code candidate_s_code count; run;
proc freq data=work._c(where=(kind='OTHER')) noprint; tables pcnr_name*pair / out=work._p; run;
proc sort data=work._p; by pcnr_name descending count; run;
data _null_; set work._p; by pcnr_name; if first.pcnr_name then n=0; n+1;
  if n <= 8 then put 'CONFPAIR: ' pcnr_name count pair; run;
