# Phase 6: Distribution Engine — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-26
**Phase:** 06-distribution-engine
**Areas discussed:** Output table name, Missing % denominator, HIGH_CARD sort order, additional locks

---

## Output Table Name

| Option | Description | Selected |
|--------|-------------|----------|
| `pdd.prf_&family` | Short; matches src_*/qc_* abbreviation style | ✓ |
| `pdd.profile_&family` | More readable; slightly longer | |

**User's choice:** `pdd.prf_pcnr` / `pdd.prf_&family`
**Notes:** Generalizes cleanly across all seven families.

---

## Missing % Denominator

| Option | Description | Selected |
|--------|-------------|----------|
| Total rows (41,150) only | All levels + MISSING sum to 100% | |
| Both columns | `pct_total` (total-rows denominator) + `pct_nonmiss` (non-missing denominator) | ✓ |
| Non-missing N only | PROC FREQ default | |

**User's choice:** Two columns — `pct_total` and `pct_nonmiss`. `pct_nonmiss` is blank on the MISSING row. Exchange CSV carries both.
**Notes:** Levels + OTHER + MISSING sum to 100% via `pct_total`.

---

## HIGH_CARD Sort Order

| Option | Description | Selected |
|--------|-------------|----------|
| Top-10 first, N_DISTINCT last | Reviewer scans top values first | |
| N_DISTINCT first, then top-10, OTHER, MISSING | Summary up front; counts reconcile | ✓ |

**User's choice:** sort_order 0 = N_DISTINCT, 1–10 = top-10 by frequency desc, 11 = OTHER, 99 = MISSING.
**Notes:** OTHER row added (not initially proposed) so counts reconcile to total rows.

---

## Additional Locks (raised by user)

| Decision | Value |
|----------|-------|
| `small_cell_flag` | 'Y' if n < 11 on every level row; no suppression in Phase 6 |
| Exclusions | NORM_PSID + LINKAGE_ONLY variables (from pdd.name_map status column) |
| Date/datetime/time tier | Fourth `var_class = 'DATE'`; stats same as CONT_NUM but `display_format` column added; name-pattern fallback for blank format |
| 100% missing variables | Still profiled; single MISSING row, pct_total = 100 |
| Reconciliation assertion | `sum(n where stat != 'N_DISTINCT') = total_rows` per variable; hard stop on failure |

---

## Claude's Discretion

- Internal macro section structure and guard naming (`%_p6_ok` etc.)
- Generated include file location and batch size for PROC FREQ TABLE statements
- Whether distinct-count pass uses one PROC SQL per variable or a batch DATA _NULL_ loop
- Acceptance test variable name lookup (runtime query vs hardcoded name)

## Deferred Ideas

None.
