# exec_19w1 - Phase 19 Wave 1: probes, synthetic test, preflight

Execute Wave 1 of .planning/phases/19-master-data-workbook/19-PLAN.md only
(tasks in Wave 1; stop before any task that needs a PDD-D-35..44 or PDD-D-27
decision).
- Write the probe program(s) covering P19-1..P19-8 so one SAS session answers
  all of them. Output: a privacy-safe report under .planning/schemas/ style
  (counts masked <11, top-coded where back-calculation is possible; no data
  values, no IDs, no encrypted MRN), plus the log under P: logs.
- Write sas/19_xlsx_test.sas (synthetic, FLAG mode, state restored) and
  sas/19a_xlsx_preflight.sas (read-only, fail-loud ABORT).
- Run lint (all C-rules incl. C31-C38) and any Python tests.
- Add 19-SAS-RUN.md with the exact Wave 1 run order, expected PASS lines, and
  the PowerShell commands to extract the probe report counts.
- Do not decide any PENDING DECISION; where code depends on one, leave it out
  of Wave 1.

Constraints (unchanged): no PHI or data values in git; counts 1-10 as <11.
Never write to the shared Master Data folder; outputs only under
P:\PeCAN Master Data\Gerard\data_dictionary. Read-only on pdd.pcnr_2018_2025,
registry, dup link, case map. No push, no branch switch, no history rewrite.
Commit on pdd-2018-2025-api.
