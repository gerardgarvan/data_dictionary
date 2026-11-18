# close_19 - close Phase 19 (PCNR_Master_Data_Nov_2026.xlsx)

Verified on real data (Gerard, 2026-11-18; counts masked where small):
- 19_xlsx_test ALL TESTS PASSED (after fix_19w2a, a2, a3).
- 19a preflight PASS (after fix_19a name exception).
- 19b stage PASS: 1,300 export columns (K3 keys + 1,297 vars; PECAN_ID_KEY_ERA
  and norm_psid excluded), 77,499 records = 77,499 physical lines, limits
  clean (maxlen 199, 0 control chars), Phase 17 tables unchanged.
- Writer bench 403 rows/s; full write PASS in ~2 min after fix_19w2b1 (UTF-8
  BOM); out\PCNR_Master_Data_Nov_2026.xlsx 75.7 MB.
- Verifier PASS: 2,687 items, 0 failed (nonblank vs stage 1,300; vs recon
  1,297; NO_DATA 56; sample values/types; 0 formula/error cells; 0 registry
  token hits; KEY facts/notice/Price pending). Stage files deleted.

Do:
1. 19-SUMMARY.md: deliverable, decisions (PDD-D-27, 35-44, audience PeCAN
   team only, content kept as is), the fix chain with one-line root causes
   (allow-list false positive; $65540 length; _INFILE_ LRECL; ifc padding;
   BOM), lint rules added (C39-C41), lessons.
2. STATE.md / ROADMAP.md: Phase 19 complete. Backlog (add, keep existing):
   - triage pre-Phase-19 lint errors (sas_lint 43 errors across older files;
     sasjs "10 errors") - were all phases really lint-clean?
   - masking applies to non-person counts (flags, timings, check counts):
     mask only person/cell counts
   - INT_IN_DATE_RANGE probe range (1-80000) uninformative
   - 06_profile_macros pct carry-over (+ check published pdd_v1_0.xlsx)
   - W1 &sqlrc warnings in 19_xlsx_macros
   - revisit sensitive fields (lat/long, free text, staff names, ages 90+)
     before any sharing beyond the PeCAN team
   Carry forward: Price naming sign-off, DSS #Error deaths question,
   cleanup items 1/2/3/5, future cross-era link.
3. Update 19-SAS-RUN.md status to complete.

Docs/planning only. No PHI or data values; counts 1-10 as <11. Commit on
pdd-2018-2025-api; no push.
