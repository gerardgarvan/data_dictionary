# Milestone brief: PCNR_ 2018–2025, PECAN_ID, and PCNR_Master_Data_Nov_2026

**Project:** PeCAN Data Dictionary (PDD), repo `C:\data_dictionary`
**Drafted:** 2026-11-16
**Status:** brief for `/gsd:new-milestone`. The roadmapper assigns phase numbers and continues from the last phase in ROADMAP.md. The phases below are labeled M1–M6 in order.

## Goal

Two deliverables, both covering surgical cases from 2018 through 2025:

- **A. Data dictionary 2018–2025.** One row per variable. `PECAN_ID` is the patient-level key derived from the encrypted MRN. Every other source variable is named with the `PCNR_` prefix, listed alphabetically with distributions over all 2018–2025 cases.
- **B. `PCNR_Master_Data_Nov_2026.xlsx`.** All of the 2018–2025 PCNR_ data in one Excel workbook.

`PECAN_ID` is the existing master-merge `pecan_ID` (PDD-D-28), carried unchanged. The name carries no `PCNR_` prefix.

**Encryption key change (confirmed by Gerard, 2026-11-16).** The 2023–2025 files encrypt MRNs with a different key from 2018–2022. The 2026-11-16 probe found 0 of the 2023–2025 encrypted MRNs in the 2018–2022 spine, and every new value is 5 characters longer. PECAN_IDs for 2023–2025 are therefore assigned separately per key, and stored in a registry built so that a later crosswalk or re-encryption can merge them without renumbering anything (see PID-01..08).

New source files for 2023–2025 are in the same shared folder as the current 20 sources:
`P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`

## Working method (carried over from insurance_investigation)

- **Probe first.** The Claude Code machine has no P: drive and no SAS. Facts about files (names, headers, types, ID formats, encodings, row counts, linkage rates) come only from privacy-safe probe output in `.planning/schemas/`, written by `sas/probe_inputs.sas` on the SAS machine. If a fact isn't in a probe, the plan stops and requests a probe run. It never guesses.
- **Headless execution on API credits.** Planning and code-writing steps run through `pdd_sdk_run.py` (Claude Agent SDK, billed to the API promotional credit), on a branch, with a spend cap and a JSON cost log per step. SAS runs and human gates are marked `PENDING SAS RUN` / `PENDING DECISION` and done by Gerard on the SAS machine.

## Requirements

### Probe and headless setup (M1)
- **PRB-01** `sas/probe_inputs.sas` committed. It reads the Master Data folder read-only and writes `.planning/schemas/probe_master_data_<yyyymmdd>.md` with, for every file and sheet: rows, blank rows, columns, encoding guess (UTF-8 vs Windows-1252 byte scan), and per column the SAS name, original header, type, length, format, non-missing count, level count, candidate placeholder count and year range for date columns. For ID-like columns it also reports distinct count, rows vs distinct (1:1 check), value-shape patterns, and overlap with the current spine's case IDs and encrypted MRNs. Counts 1–10 are shown as `<11`. No data values are written.
- **PRB-02** The first probe run is committed. It lists every new 2023–2025 file. The milestone cannot plan past M1 without it.
- **PRB-03** CLAUDE.md gains the probe-first rule and the headless-run rules (see `CLAUDE_md_addition.md`).
- **RUN-01** `pdd_sdk_run.py` is in the repo root. It refuses to run on main/master or with a dirty tree, logs each step's cost to `logs/api_runs/`, and refuses new steps once the logged total reaches the cap.

### New-source intake (M2)
- **NEW-01** The source guard is extended: the existing 20-file SHA-256 baseline still has to match unchanged, and the new files get their own baseline entries. Adding the new baseline is an explicit, approved step, not a silent re-baseline.
- **NEW-02** The header inventory (Phase 2 output) is extended to the new files and covers the same file × header matrix.
- **NEW-03** The new files are imported with the Phase 3 conventions: explicit informats and lengths, IDs and codes read as character, `encoding='wlatin1'` for the 2024 and 2025 files (the 2026-11-16 probe flags them; 2023 is UTF-8) per PDD-D-23. All three use 5-digit case IDs, normalized with the PDD-D-19 rule unchanged (`cats('Precede', put(input(strip(id), ?? 8.), z5.))`) per PDD-D-29 (DECIDED 2026-11-16).
- **NEW-03a** Header variants found by the probe are mapped, not renamed at source: the Braden columns differ by year (`Braden Activity` in 2023, `Braden_2024_OUT_Braden Activity` and `Braden_2025_OUT_…` later), and several names differ from the older files (`Fraility_Score` in 2023–2025 vs `Frailty_Score`, `SleepApnea_YN` vs `Sleep_Apnea_YN`, `Preop_Edu_Years` vs `Education`). Type changes go to the map review: `Death_Days_After_Surgery` is character in 2023–2025, and the five frailty components are numeric where the 2022 master has character.
- **NEW-04** 1:1-per-case check on each new file (PDD-D-17 extended). Any file that is not 1:1 stops at a decision gate.
- **NEW-05** Era overlap check: count case IDs that appear in both the 2018–2022 sources and the 2023–2025 sources, and conflicting values for shared columns. The probe (strip-fix rerun, 2026-11-16) found 0 of the 2023-2025 normalized case IDs in the 2018-2022 spine, so PDD-D-25 (precedence) is CLOSED - NOT NEEDED (PDD-D-29 item 2); the check is still run and reported to QC. **Within-new-files gate (PDD-D-29 item 3):** the probe compares each file only to the spine, so Phase 15 must also count normalized case IDs shared between each pair of the 2023, 2024 and 2025 files (2023-2024, 2023-2025, 2024-2025). If any are shared, stop at a decision gate (do not stack) and list the counts per pair.

### Name map extension (M3)
- **MAP-01** New headers are mapped to the existing 1,299 PCNR_ names with the Phase 4 cleaning, abbreviation and collision rules. Exact matches reuse the existing name.
- **MAP-02** Near-matches (for example, the earlier ASA and Holiday/Holidays cases) go to a human gate with value distributions side by side, decided by Gerard.
- **MAP-03** Genuinely new columns get new PCNR_ names under the same rules. Names already in use keep their meaning.
- **MAP-04** Year coverage per variable is recorded (first and last surgical year with any non-missing value, and which source files contribute).

### PECAN_ID (M4)
- **PID-01** PECAN_ID = master-merge `pecan_ID`, carried unchanged (PDD-D-28). No value changes; the dictionary row uses the PDD-D-28 wording.
- **PID-02** Key eras: `K1` = 2018–2022 MRN encryption, `K2` = 2023–2025 MRN encryption. Every encrypted MRN is tagged with its key era. MRNs from different eras are never compared directly.
- **PID-03** Persistent registry `pdd.pecan_id_registry` (on P:, never in git), append-only: `PECAN_ID` (num 8), `ENCRYPTED_MRN $64`, `KEY_ERA $2`, `ASSIGNED_RUN` (date), `SOURCE $32`, `LINKED_TO_PECAN_ID` (blank for now), `LINK_SOURCE $64` (blank), `STATUS $10` (ACTIVE / SUPERSEDED). Seeded once from `g.pecan_id_xwalk`, every row copied unchanged with `KEY_ERA='K1'`, `SOURCE='master_merge_xwalk'`. Seed checks: row count and sum of pecan_ID match the source; pecan_ID unique; ENCRYPTED_MRN unique; seeded MRN set equals the distinct non-blank, non-NULL MRNs of the 2018-2022 spine (abort with counts on any difference). Reruns look up the registry on (ENCRYPTED_MRN, KEY_ERA) first: a known MRN keeps its ID, only unseen MRNs get a new one. No ID is ever renumbered or reused. Every registry change writes a dated backup under the PDD output root on P:; abort if the registry differs from its latest backup before an append.
- **PID-04** K2 IDs: numeric `PECAN_ID = 1000000 + rank`, rank by smallest numeric PRECEDE study number per MRN with MRN as tie-breaker (same rule as K1) over the 2023-2025 files. Append-only: re-runs keep existing IDs; new K2 MRNs get `max(K2 PECAN_ID) + n`. Deterministic for the same inputs (PDD-D-28).
- **PID-05** The combined dataset carries `PECAN_ID` and `PECAN_ID_KEY_ERA`. The dictionary and the master workbook's KEY sheet state plainly that patients with surgeries in both eras currently have two PECAN_IDs, so patient counts across 2018–2025 are overestimates until the IDs are linked.
- **PID-06** A linkage program (`sas/pecan_id_link.sas`) is written and tested but not run. Given a crosswalk (K2 encrypted MRN → K1 encrypted MRN, or both eras re-encrypted under one key), it fills `LINKED_TO_PECAN_ID` and `LINK_SOURCE`, marks matched K2 IDs as SUPERSEDED, and rebuilds the dataset so linked patients carry their K1 PECAN_ID. A QC report lists every ID that changes. Running it later is the whole "revisit".
- **PID-07** Cases-per-patient summary (PECAN_ID vs PRECEDE_STUDY_ID) for each era, plus the same summary combined with the caveat from PID-05.
- **PID-08** Phase 17 reads `g.pecan_id_xwalk` read-only through a libname defined in `sas/00_config.sas` (new macro variable for the master-merge g path); no PDD program writes to that library.

### Combined dataset and dictionary 2018–2025 (M5)
- **DD-01** One combined case-level PCNR_ dataset for 2018–2025 in the `pdd` library on P: (never in git), with PECAN_ID and PRECEDE_STUDY_ID first. Apply PDD-D-30: s22 wins, s23 gap-fills for the 142 shared cases (YEAR = 2024); QC the conflicts.
- **DD-02** Values are kept exactly as in source (no recoding), as in the existing PCNR_ layer.
- **DD-03** The data dictionary workbook is regenerated for 2018–2025: KEY sheet leftmost, PECAN_ID first, then PCNR_ variables alphabetically, with distributions over all 2018–2025 cases plus the year coverage and source columns from MAP-04.
- **DD-04** Reconciliation: dictionary row count equals combined dataset column count; per-variable non-missing counts match the dataset; 2018–2022 distributions match the previous dictionary except where new data adds cases.

### Master Excel export (M6)
- **XLS-01** `PCNR_Master_Data_Nov_2026.xlsx` written to `P:\PeCAN Master Data\Gerard\data_dictionary\out\` with sheets KEY (leftmost: source, date, row/column counts, ID definitions, missing-value convention) and DATA.
- **XLS-02** Pre-export limit checks stop the run if rows ≥ 1,048,575, columns ≥ 16,384 or any text cell exceeds 32,767 characters.
- **XLS-03** Round-trip QC: re-import the workbook and compare row count, column names in order, and per-column non-missing counts with the SAS dataset. Write the results to `qc/`.
- **XLS-04** Whether the dictionary is also included as a sheet in the master file is a decision gate (**PDD-D-new-3**, default: no, the dictionary stays its own workbook).

## Open decisions (numbered at the next free PDD-D numbers when the milestone is created)

| ID | Question | Default if unanswered | Who |
|---|---|---|---|
| new-1 | Precedence for cases present in both the 2018–2022 and 2023–2025 sources | Existing rule: earlier spine wins, newer sources gap-fill; conflicts listed in QC | Gerard |
| new-2 | Encrypted MRNs don't link across eras (key change confirmed 2026-11-16) | **Decided:** separate K2 PECAN_IDs through the append-only registry, with linkage deferred to `pecan_id_link.sas` when a crosswalk or common key is available | Gerard (decided) |
| new-4 | How 2022 5-digit case IDs were linked to the spine in Phase 3, and whether the same rule applies to 2023–2025 | Read the Phase 3 decision record; the probe shows 0 overlap under the plain `Precede` + 5-digit rule for the 2022 files too | Gerard |
| new-3 | Dictionary sheet inside the master xlsx | No | Gerard |
| carried | Price's sign-off on naming conventions | Still required before release | Price |

## Out of scope

- PCNC_, PCND_, CLK_, LAB_, MED_, INTRA_ families
- Recoding placeholders to missing (the PCNR_ layer keeps source values)
- Changing locked decisions PDD-D-01..23
- Any write to the shared source folder
