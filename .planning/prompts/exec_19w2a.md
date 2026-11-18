# exec_19w2a - Phase 19 Wave 2, part A: SAS stage export (task 19-04)

Status: Wave 1 SAS runs on real data PASSED (19_xlsx_test: ALL TESTS PASSED;
19a_xlsx_preflight: PASS after fix_19a). Decisions DECIDED (decide_19).
Read 19-PLAN.md, 19-CONTEXT.md, docs/xlsx_stage_contract.md, DECISIONS.md.

Do (SAS side only; Python writer/verifier are part B - do not start them):
1. sas/19b_xlsx_stage.sas per task 19-04: fresh session, ABORT mode,
   %p19_need_decision for every PDD_XLS_* choice incl. PDD_XLS_APPROVE=1;
   path guard; limits gate; %p19_columns with the K3 key set (PECAN_ID,
   PRECEDE_STUDY_ID, KEY_ERA; PECAN_ID_KEY_ERA and norm_psid never staged);
   %p19_stage -> stage\xlsx_data.csv + stage\xlsx_schema.csv; %p19_expected ->
   stage\xlsx_expected.csv; CSV line count == dataset rows + 1; registry /
   dup link / case map unchanged gate; QC qc\xlsx_master_stage.csv (masked
   export); PASS/FAIL line. PCNR_Death_Days_After_Surgery is staged as
   delivered text (conversion happens in the Python writer per the contract).
2. Extend sas/19_xlsx_test.sas: %p19_keyset (K3 yields exactly the three keys;
   an unknown K-code stops), and a synthetic end-to-end %p19_stage +
   %p19_expected check if not already covered. Keep FLAG mode + restore.
3. 19-SAS-RUN.md: Wave 2 run order (19_xlsx_test, then 19b with
   options set=PDD_XLS_APPROVE '1' before and '0' after), expected PASS lines,
   PowerShell checks (counts only), time estimate.
4. Lint zero errors; pytest green.
5. Write each file as soon as it is done; keep each Write moderate in size.

Constraints unchanged (see exec_19w1.md). Stage files only under
P:\PeCAN Master Data\Gerard\data_dictionary\stage. No run against real data.
Commit on pdd-2018-2025-api; no push.
