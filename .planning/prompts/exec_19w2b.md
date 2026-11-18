# exec_19w2b - Phase 19 Wave 2, part B: Python writer + verifier (tasks 19-05, 19-06)

Status: decisions DECIDED (decide_19); SAS stage program written (exec_19w2a,
not yet run on real data). Read 19-PLAN.md tasks 19-05/19-06,
docs/xlsx_stage_contract.md (incl. "Stage file formats"), DECISIONS.md,
python/pdd/master_rules.py, python/pdd/xlsx_style.py.

Do:
1. python/pdd/master_workbook.py + python/scripts/write_master_workbook.py per
   19-05, applying the decisions: final file
   out\PCNR_Master_Data_Nov_2026.xlsx; sheets KEY (leftmost, UF colors
   #0021A5/#FA4616 via xlsx_style.py) then DATA only (no SPECIAL_MISSING, no
   variable list); K3 keys; Death_Days numeric override and blanked-count via
   master_rules.py; KEY notice text from master_rules.py (identifiable
   fields, approved PeCAN team use only, pointer to out\pdd_2018_2025.xlsx);
   PDD_XLS_APPROVE=1 required; streaming csv.reader; write_only workbook;
   strings starting = or # forced to text; existing final file moved to
   backup\ first; write to .tmp and rename only on success; no cell values
   ever logged. --bench-rows N writes a throwaway file under stage\ and
   prints rows/s plus extrapolated full time.
2. python/pdd/master_verify.py + python/scripts/verify_master_workbook.py per
   19-06: sheet order, header == expected, row count, per-column non-blank
   counts vs stage\xlsx_expected.csv (exact) and exchange\comb_recon.csv
   (masked-tolerant; NUM_TEXT rule; NO_DATA = 0; Death_Days = non-blank minus
   blanked), SAMPLE row equality vs stage, KEY facts, disclosure scan
   (registry ENCRYPTED_MRN tokens read in memory; hit count only). Outputs
   qc\xlsx_master_verify.csv and masked exchange\xlsx_master_verify_summary.csv.
   Exit 0 only if every item passes; on PASS delete the stage files
   (PDD-D-42 = NONE).
3. Tests per 19-05/19-06 (synthetic, tmp_path), incl. an assertion that no
   cell value appears in captured log output. ruff + pytest green. Check that
   any new dependency (e.g. pandas/pyreadstat for read_sas) is in the
   requirements file and say so in the summary.
4. 19-SAS-RUN.md: add the writer and verifier steps after 19b, with
   commands, expected output and the bench step first.
5. Write each file as soon as it is done; keep each Write moderate in size.

Constraints unchanged (see exec_19w1.md). No run against real data. Commit on
pdd-2018-2025-api; no push.
