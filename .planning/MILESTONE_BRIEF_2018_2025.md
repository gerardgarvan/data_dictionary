# Milestone brief: PCNR_ 2018–2025, PECAN_ID, and PCNR_Master_Data_Nov_2026

**Project:** PeCAN Data Dictionary (PDD), repo `C:\data_dictionary`
**Drafted:** 2026-11-16
**Status:** brief for `/gsd:new-milestone`. The roadmapper assigns phase numbers and continues from the last phase in ROADMAP.md. The phases below are labeled M1–M6 in order.

## Goal

Two deliverables, both covering surgical cases from 2018 through 2025:

- **A. Data dictionary 2018–2025.** One row per variable. `PECAN_ID` is the patient-level key derived from the encrypted MRN. Every other source variable is named with the `PCNR_` prefix, listed alphabetically with distributions over all 2018–2025 cases.
- **B. `PCNR_Master_Data_Nov_2026.xlsx`.** All of the 2018–2025 PCNR_ data in one Excel workbook.

`PECAN_ID` is a rename of the existing `PCNR_ID`. Values, derivation and type stay the same. Only the name changes, and the name carries no `PCNR_` prefix.

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
- **NEW-03** The new files are imported with the Phase 3 conventions: explicit informats and lengths, IDs and codes read as character, `encoding='wlatin1'` for any file the probe flags as non-UTF-8 (PDD-D-23), and 5-digit case IDs normalized to `Precede#####` (PDD-D-19) if the probe shows that format.
- **NEW-04** 1:1-per-case check on each new file (PDD-D-17 extended). Any file that is not 1:1 stops at a decision gate.
- **NEW-05** Era overlap check: count case IDs that appear in both the 2018–2022 sources and the 2023–2025 sources, and conflicting values for shared columns. The precedence rule for overlapping cases is a decision gate (**PDD-D-new-1**).

### Name map extension (M3)
- **MAP-01** New headers are mapped to the existing 1,299 PCNR_ names with the Phase 4 cleaning, abbreviation and collision rules. Exact matches reuse the existing name.
- **MAP-02** Near-matches (for example, the earlier ASA and Holiday/Holidays cases) go to a human gate with value distributions side by side, decided by Gerard.
- **MAP-03** Genuinely new columns get new PCNR_ names under the same rules. Names already in use keep their meaning.
- **MAP-04** Year coverage per variable is recorded (first and last surgical year with any non-missing value, and which source files contribute).

### PECAN_ID (M4)
- **PID-01** `PCNR_ID` is renamed to `PECAN_ID` in every dataset, program, label, dictionary row and doc. Values are unchanged (checksum before and after must match). The dictionary row notes "formerly PCNR_ID; derived from encrypted MRN".
- **PID-02** PECAN_ID is derived for the 2023–2025 cases with the same rule as 2018–2022.
- **PID-03** Cross-era linkage check: the share of 2023–2025 encrypted MRNs that also appear in 2018–2022. Patients with surgeries in both eras should produce some overlap. Zero or near-zero overlap means the MRN encryption key changed between deliveries (the PCM-D-16 precedent), and the milestone stops at a decision gate (**PDD-D-new-2**) to resolve it through the MRN/ENCOUNTER crypto files or DSS.
- **PID-04** Cases-per-patient summary (PECAN_ID vs PRECEDE_STUDY_ID) for each era and combined.

### Combined dataset and dictionary 2018–2025 (M5)
- **DD-01** One combined case-level PCNR_ dataset for 2018–2025 in the `pdd` library on P: (never in git), with PECAN_ID and PRECEDE_STUDY_ID first.
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
| new-2 | What to do if encrypted MRNs don't link across eras | Stop; no PECAN_ID for 2023–2025 until resolved | Gerard (DSS if needed) |
| new-3 | Dictionary sheet inside the master xlsx | No | Gerard |
| carried | Price's sign-off on naming conventions | Still required before release | Price |

## Out of scope

- PCNC_, PCND_, CLK_, LAB_, MED_, INTRA_ families
- Recoding placeholders to missing (the PCNR_ layer keeps source values)
- Changing locked decisions PDD-D-01..23
- Any write to the shared source folder
