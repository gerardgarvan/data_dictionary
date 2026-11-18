# decide_19 - record Gerard's Phase 19 decisions (task 19-01b) + small code for them

Gerard decided on 2026-11-18, using the 19a probe results:
- Audience: PeCAN team only, under the current IRB protocol.
- PDD-D-35 route = STAGE_CSV.  PDD-D-36 NO_DATA = INCLUDE.  PDD-D-37 order = DICT.
- PDD-D-38 dates = SERIAL (probe: no numeric variable carries a date format;
  char dates PCNR_preop_date / PCNR_test_date stay text).
- PDD-D-39 NUM_TEXT = TEXT, with ONE per-variable override:
  PCNR_Death_Days_After_Surgery -> numeric; cells whose text starts with '#'
  (probe: 34,057 such cells) and any other non-numeric text become blank;
  count of blanked cells recorded as a QC item (masked like other counts).
- PDD-D-40 special missing = BLANK (probe: 0 variables have special missings).
- PDD-D-41 sheets = ONE.  PDD-D-42 companion = NONE.
- PDD-D-43 keys = PECAN_ID, PRECEDE_STUDY_ID, KEY_ERA only. Drop
  PECAN_ID_KEY_ERA (probe: identical to KEY_ERA in every row) and norm_psid
  (probe: identical to PRECEDE_STUDY_ID). If no existing K-code matches this
  set, add K3 = exactly these three and use it.
- PDD-D-44 disclosure sign-off: run-time only (PDD_XLS_APPROVE set by Gerard
  via options set=, like PDD_APPROVE_NEW_BASELINE); never stored in config.
- PDD-D-27 dictionary sheet = NO; KEY sheet points to out\pdd_2018_2025.xlsx.
- Content: keep PCNR_Latitude/Longitude, free-text notes, staff-name fields
  and ages unaltered. KEY sheet must state plainly that the workbook contains
  identifiable fields and is for approved PeCAN team use only.

Do:
1. docs/DECISIONS.md: PDD-D-35..44 and PDD-D-27 -> DECIDED 2026-11-18 by
   Gerard, with the values above and one line of rationale each (cite probe).
2. sas/00_config.sas: set the PDD_XLS_* defaults to these values
   (PDD_XLS_APPROVE stays empty). Env-var override behaviour unchanged.
3. Implement what is not yet a parameter switch: K3 key set; the
   Death_Days numeric override (SAS stage side and/or Python writer - pick
   one place, document it in the stage contract); the KEY sheet audience /
   identifiable-fields notice. Tests for each (synthetic only).
4. Update 19-PLAN.md / 19-CONTEXT.md / 19-SAS-RUN.md: decisions resolved,
   Wave 2 unblocked; note the INT_IN_DATE_RANGE probe range was too broad to
   be informative (backlog), and that the export masks flags/timings 1-10
   (backlog: mask only person/cell counts).
5. Lint (zero errors) + ruff + pytest.

Constraints unchanged (see exec_19w1.md). No SAS/Python run against real
data. Commit on pdd-2018-2025-api; no push.
