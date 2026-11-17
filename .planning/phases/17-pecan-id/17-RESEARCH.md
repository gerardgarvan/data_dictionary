# Phase 17 Research (inline, headless)

- Program 20 pattern to reuse: rank by min numeric study number with MRN tie-break; type guard; backup-on-change only; no in-place rewrite (PCM-T-02): build new dataset then replace via backup + `proc append`/data step to new name; no PROC SQL UPDATE.
- Append-only mechanics for registry: never `set reg; modify`. Append = `proc append base=pdd.pecan_id_registry data=work.new_rows` after backup and pre-check; supersede (link program) writes a NEW dataset `pdd.pecan_id_registry_next`, verifies, backs up, then replaces via PROC COPY/rename (only in link program, run later).
- K2 ids: `max(K2 PECAN_ID)` taken over KEY_ERA='K2' rows; first run max=1000000. New MRNs ordered by (min numeric id, MRN) get max+1.. So a re-run with no new MRN appends 0 rows (idempotence gate).
- Caveat on "rank" and append: first-run ranks are 1..n over the full K2 set; later additions are max+n, so IDs are deterministic for the same inputs and stable after additions.
- Lint: C30 (no `;` in %put / %fail_out text), C31 (STOP in any POINT= step), C32 (no reserved words as PROC SQL columns: use tcase, tera, etc.). Also C1, C3, C9, C11, C13, C14. No commas in macro call args.
- ENCRYPTED_MRN lengths: xwalk $40 (D-28), spine 41, K2 37-51: registry $64; seed asserts xwalk length >= max spine MRN length actually present, otherwise PENDING DECISION (truncated keys would break lookups).
