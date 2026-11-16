Resolve PDD-D-29 non-interactively. Do not ask questions.

## Evidence (probe `.planning/schemas/probe_master_data_20261116.md`, strip-fix rerun, 2026-11-16)

The first two probe runs reported 0 case-ID overlap for the 2022 files because of a probe bug
(padded value tested against `^\d{1,5}$`). After the fix, normalizing 5-digit IDs with the
PDD-D-19 rule `cats('Precede', put(input(strip(id), ?? 8.), z5.))` gives, against the spine
`2018_2022_X_MASTER_DATASET_20240402.csv`:

| unit | file | distinct case IDs | in spine | not in spine |
|---|---|---|---|---|
| 16 | 2022_Education_20240124.csv | 9,215 | 9,215 | 0 |
| 17 | 2022_MASTER_DATASET_20231024.csv | 9,215 | 9,215 | 0 |
| 18 | 2022_RES_20230927.csv | 9,484 | 9,215 | 269 |
| 19 | 2023_X_MASTER_DATASET_20261016.csv | 10,772 | 0 | 10,772 |
| 20 | 2024_X_MASTER_DATASET_20261016.csv | 13,029 | 0 | 13,029 |
| 21 | 2025_X_MASTER_DATASET_20261016.csv | 12,689 | 0 | 12,689 |
| 23 | All_YEARS_LAT_LONG_20231127.csv | 41,150 | 41,150 | 0 |

Units 16-18 reproduce PDD-D-19 exactly. All three 2023-2025 files use 5-digit IDs (shape 99999 on
every row) and are one row per case ID.

## Decision text for PDD-D-29 (status DECIDED, Gerard 2026-11-16)

1. The 2023-2025 case IDs are normalized with the PDD-D-19 rule unchanged.
2. No 2023-2025 normalized ID appears in the 2018-2022 spine (probe above), so no cross-era case
   collision exists and decision PDD-D-25 (precedence for cases in both eras) has nothing to
   act on. PDD-D-25 stays recorded with that evidence and status CLOSED - NOT NEEDED.
3. Gate in Phase 15 (NEW-04/NEW-05): the probe compares each file only to the spine, not the three
   new files to each other. Phase 15 must count normalized case IDs shared between any two of the
   2023, 2024 and 2025 files. If any are shared, stop at a decision gate (do not stack) and list
   the counts per pair.

## Edits

1. `docs/DECISIONS.md`: PDD-D-29 DECIDED with the text above and the evidence table; PDD-D-25
   CLOSED - NOT NEEDED, citing PDD-D-29 item 2. Remove the earlier "Conflict" note in PDD-D-29
   (it came from the probe bug).
2. `.planning/REQUIREMENTS.md` and `.planning/MILESTONE_BRIEF_2018_2025.md`: NEW-03 states the
   D-19 rule applies to 2023-2025; NEW-05 adds the within-new-files overlap gate from item 3.
3. `.planning/STATE.md` and `.planning/ROADMAP.md`: record that the Phase 14 probe is committed
   (`.planning/schemas/probe_master_data_20261116.md`, strip-fix rerun) and mark Phase 14 complete
   if its other requirements (PRB-03 CLAUDE.md rules, RUN-01 runner) are already satisfied;
   otherwise list what remains. Phase 15 is unblocked.
4. Commit: `decision: PDD-D-29 D-19 rule applies to 2023-2025; PDD-D-25 not needed; Phase 14 probe in`.

Report the edits and any remaining blockers for planning Phase 15.
