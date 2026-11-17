# Requirements: PeCAN Data Dictionary (PDD)

## Milestone v2.0: PCNR_ 2018-2025, PECAN_ID, PCNR_Master_Data_Nov_2026

Rewritten 2026-11-16 from the revised `.planning/MILESTONE_BRIEF_2018_2025.md` (commit 52f6ad9:
two-key PECAN_ID registry, deferred linkage). The v1.0 requirements (PDD-01..07, all satisfied,
audit passed 2026-10-27) are archived in `.planning/milestones/v1.0-REQUIREMENTS.md`.
Requirement IDs keep the brief's prefixes (PRB, RUN, NEW, MAP, PID, DD, XLS). Phases M1-M6 are
numbered 14-19 (the last existing phase in ROADMAP.md is 13).

Deliverables (cases 2018 through 2025):
- **A.** Data dictionary 2018-2025: one row per variable; `PECAN_ID` first, then `PCNR_` variables
  alphabetically, with distributions over all 2018-2025 cases.
- **B.** `PCNR_Master_Data_Nov_2026.xlsx`: all 2018-2025 PCNR_ data in one workbook.

Encryption key change (brief, confirmed by Gerard 2026-11-16): the 2023-2025 files encrypt MRNs with a
different key (K2) from 2018-2022 (K1). PECAN_IDs for the two eras are assigned separately through an
append-only registry; linkage is deferred (PDD-D-26, DECIDED). **No `probe_*.md` is committed yet**, so
the probe findings the brief cites (0 K2 MRNs in the K1 spine, K2 values 5 characters longer, wlatin1 for
2024/2025) are brief-asserted and not yet verified from a committed probe.

Working method: probe first (facts about files come only from `.planning/schemas/probe_*.md`);
headless steps via `pdd_sdk_run.py`; SAS runs and human gates are marked `PENDING SAS RUN` /
`PENDING DECISION` and done by Gerard. M1 must finish (first probe committed) before M2-M6 are planned.

**Brief-vs-repo conflicts that affect these requirements** (details in STATE.md and `docs/DECISIONS.md`):
- ~~`PCNR_ID` does not exist in the repo~~ Resolved 2026-11-16 (PDD-D-28, DECIDED): "PCNR_ID" is the master-merge `pecan_ID`; PID-01/03/04/08 are planned on that basis.
- ~~NEW-03/PDD-D-29: the brief said 0 overlap for the 2022 files under the plain rule~~ Resolved 2026-11-16 (PDD-D-29, DECIDED): that was a probe bug (padded value vs `^\d{1,5}$`); after the strip fix the 2022 files match 100% under the PDD-D-19 rule, and the same rule applies to 2023-2025.
- The brief says locked decisions are PDD-D-01..23; the repo locks through D-24.

### Probe and headless setup (Phase 14, M1)
- **PRB-01** `sas/probe_inputs.sas` committed. It reads the Master Data folder read-only and writes `.planning/schemas/probe_master_data_<yyyymmdd>.md` with, for every file and sheet: rows, blank rows, columns, encoding guess (UTF-8 vs Windows-1252 byte scan), and per column the SAS name, original header, type, length, format, non-missing count, level count, candidate placeholder count and year range for date columns. For ID-like columns it also reports distinct count, rows vs distinct (1:1 check), value-shape patterns, and overlap with the current spine's case IDs and encrypted MRNs. Counts 1–10 are shown as `<11`. No data values are written.
- **PRB-02** The first probe run is committed. It lists every new 2023–2025 file. The milestone cannot plan past M1 without it.
- **PRB-03** CLAUDE.md gains the probe-first rule and the headless-run rules (done: the addition was merged into CLAUDE.md in commit 73881aa and `CLAUDE_md_addition.md` deleted).
- **RUN-01** `pdd_sdk_run.py` is in the repo root. It refuses to run on main/master or with a dirty tree, logs each step's cost to `logs/api_runs/`, and refuses new steps once the logged total reaches the cap.

### New-source intake (Phase 15, M2)
- **NEW-01** The source guard is extended: the existing 20-file SHA-256 baseline still has to match unchanged, and the new files get their own baseline entries. Adding the new baseline is an explicit, approved step, not a silent re-baseline.
- **NEW-02** The header inventory (Phase 2 output) is extended to the new files and covers the same file × header matrix.
- **NEW-03** The new files are imported with the Phase 3 conventions: explicit informats and lengths, IDs and codes read as character, `encoding='wlatin1'` for the 2024 and 2025 files (the 2026-11-16 probe flags them; 2023 is UTF-8) per PDD-D-23. All three use 5-digit case IDs, normalized with the PDD-D-19 rule unchanged (`cats('Precede', put(input(strip(id), ?? 8.), z5.))`) per PDD-D-29 (DECIDED 2026-11-16).
- **NEW-03a** Header variants found by the probe are mapped, not renamed at source: the Braden columns differ by year (`Braden Activity` in 2023, `Braden_2024_OUT_Braden Activity` and `Braden_2025_OUT_…` later), and several names differ from the older files (`Fraility_Score` in 2023–2025 vs `Frailty_Score`, `SleepApnea_YN` vs `Sleep_Apnea_YN`, `Preop_Edu_Years` vs `Education`). Type changes go to the map review: `Death_Days_After_Surgery` is character in 2023–2025, and the five frailty components are numeric where the 2022 master has character.
- **NEW-04** 1:1-per-case check on each new file (PDD-D-17 extended). Any file that is not 1:1 stops at a decision gate.
- **NEW-05** Era overlap check: count case IDs that appear in both the 2018–2022 sources and the 2023–2025 sources, and conflicting values for shared columns. The probe (strip-fix rerun, 2026-11-16) found 0 of the 2023-2025 normalized case IDs in the 2018-2022 spine, so PDD-D-25 (precedence) is CLOSED - NOT NEEDED (PDD-D-29 item 2); the check is still run and reported to QC. **Within-new-files gate (PDD-D-29 item 3):** the probe compares each file only to the spine, so Phase 15 must also count normalized case IDs shared between each pair of the 2023, 2024 and 2025 files (2023-2024, 2023-2025, 2024-2025). If any are shared, stop at a decision gate (do not stack) and list the counts per pair.

### Name map extension (Phase 16, M3)
- **MAP-01** New headers are mapped to the existing PCNR_ names (1,297 PCNR_ variables after D-24; the brief's 1,299 still counts the two LINKAGE_ONLY columns) with the Phase 4 cleaning, abbreviation and collision rules. Exact matches reuse the existing name.
- **MAP-02** Near-matches (for example, the earlier ASA and Holiday/Holidays cases) go to a human gate with value distributions side by side, decided by Gerard.
- **MAP-03** Genuinely new columns get new PCNR_ names under the same rules. Names already in use keep their meaning.
- **MAP-04** Year coverage per variable is recorded (first and last surgical year with any non-missing value, and which source files contribute).

### PECAN_ID (Phase 17, M4)
- **PID-01** PECAN_ID = master-merge `pecan_ID`, carried unchanged (PDD-D-28). No value changes; the dictionary row uses the PDD-D-28 wording.
- **PID-02** Key eras: `K1` = 2018–2022 MRN encryption, `K2` = 2023–2025 MRN encryption. Every encrypted MRN is tagged with its key era. MRNs from different eras are never compared directly.
- **PID-03** Persistent registry `pdd.pecan_id_registry` (on P:, never in git), append-only: `PECAN_ID` (num 8), `ENCRYPTED_MRN $64`, `KEY_ERA $2`, `ASSIGNED_RUN` (date), `SOURCE $32`, `LINKED_TO_PECAN_ID` (blank for now), `LINK_SOURCE $64` (blank), `STATUS $10` (ACTIVE / SUPERSEDED). [SUPERSEDED by PDD-D-32: K1 rows come from a surgery-level join of the spine to `g.MASTER_DATA_HARMONIZED`; dup patients go to `pdd.pecan_id_dup_link`] ~~Seeded once from `g.pecan_id_xwalk`, every row copied unchanged with `KEY_ERA='K1'`, `SOURCE='master_merge_xwalk'`.~~ ~~Seed checks: row count and sum of pecan_ID match the source; pecan_ID unique; ENCRYPTED_MRN unique;~~ [superseded, see 17-02] seeded MRN set equals the distinct non-blank, non-NULL MRNs of the 2018-2022 spine (abort with counts on any difference). Reruns look up the registry on (ENCRYPTED_MRN, KEY_ERA) first: a known MRN keeps its ID, only unseen MRNs get a new one. No ID is ever renumbered or reused. Every registry change writes a dated backup under the PDD output root on P:; abort if the registry differs from its latest backup before an append.
- **PID-04** K2 IDs: numeric `PECAN_ID = 1000000 + rank`, rank by smallest numeric PRECEDE study number per MRN with MRN as tie-breaker (same rule as K1) over the 2023-2025 files. Append-only: re-runs keep existing IDs; new K2 MRNs get `max(K2 PECAN_ID) + n`. Deterministic for the same inputs (PDD-D-28).
- **PID-05** The combined dataset carries `PECAN_ID` and `PECAN_ID_KEY_ERA`. The dictionary and the master workbook's KEY sheet state plainly that patients with surgeries in both eras currently have two PECAN_IDs, so patient counts across 2018–2025 are overestimates until the IDs are linked.
- **PID-06** A linkage program (`sas/pecan_id_link.sas`) is written and tested but not run. Given a crosswalk (K2 encrypted MRN → K1 encrypted MRN, or both eras re-encrypted under one key), it fills `LINKED_TO_PECAN_ID` and `LINK_SOURCE`, marks matched K2 IDs as SUPERSEDED, and rebuilds the dataset so linked patients carry their K1 PECAN_ID. A QC report lists every ID that changes. Running it later is the whole "revisit".
- **PID-07** Cases-per-patient summary (PECAN_ID vs PRECEDE_STUDY_ID) for each era, plus the same summary combined with the caveat from PID-05.
- **PID-08** Phase 17 reads `g.pecan_id_xwalk` read-only through a libname defined in `sas/00_config.sas` (new macro variable for the master-merge g path); no PDD program writes to that library.

### Combined dataset and dictionary 2018–2025 (Phase 18, M5)
- **DD-01** One combined case-level PCNR_ dataset for 2018–2025 in the `pdd` library on P: (never in git), with PECAN_ID and PRECEDE_STUDY_ID first. Apply PDD-D-30: s22 wins, s23 gap-fills for the 142 shared cases (YEAR = 2024); QC the conflicts.
- **DD-02** Values are kept exactly as in source (no recoding), as in the existing PCNR_ layer.
- **DD-03** The data dictionary workbook is regenerated for 2018–2025: KEY sheet leftmost, PECAN_ID first, then PCNR_ variables alphabetically, with distributions over all 2018–2025 cases plus the year coverage and source columns from MAP-04.
- **DD-01a** Apply the PDD-D-31 combined types for the TYPE_CONFLICT_EXACT variables (numeric, text, text with each era's coding, text with `#Error` verbatim). Record which way ASA_Anesth_Record and CPT1_Class went.
- **DD-03a** The dictionary carries the PDD-D-31 notes: era coding of the five frailty indicator flags, the Death_Days_After_Surgery `#Error` meaning (116 death-flagged rows), and Sleep_Apnea_YN recording only Y or blank before 2023. QC reports the count of death-flagged `#Error` Death_Days rows per source file (expected 43 / 43 / 30 for s21 / s22 / s23).
- **DD-04** Reconciliation: dictionary row count equals combined dataset column count; per-variable non-missing counts match the dataset; 2018–2022 distributions match the previous dictionary except where new data adds cases.

### Master Excel export (Phase 19, M6)
- **XLS-01** `PCNR_Master_Data_Nov_2026.xlsx` written to `P:\PeCAN Master Data\Gerard\data_dictionary\out\` with sheets KEY (leftmost: source, date, row/column counts, ID definitions, missing-value convention) and DATA.
- **XLS-02** Pre-export limit checks stop the run if rows ≥ 1,048,575, columns ≥ 16,384 or any text cell exceeds 32,767 characters.
- **XLS-03** Round-trip QC: re-import the workbook and compare row count, column names in order, and per-column non-missing counts with the SAS dataset. Write the results to `qc/`.
- **XLS-04** Whether the dictionary is also included as a sheet in the master file is a decision gate (**PDD-D-new-3**, default: no, the dictionary stays its own workbook).

## Traceability

| Requirement | Phase |
|-------------|-------|
| PRB-01, PRB-02, PRB-03, RUN-01 | 14 (M1) |
| NEW-01..NEW-05 (NEW-03a included) | 15 (M2) |
| MAP-01..MAP-04 | 16 (M3) |
| PID-01..PID-08 | 17 (M4) |
| DD-01..DD-04 | 18 (M5) |
| XLS-01..XLS-04 | 19 (M6) |

## Out of scope

- PCNC_, PCND_, CLK_, LAB_, MED_, INTRA_ families (v1.x phases 8-13 stay gated)
- Recoding placeholders to missing (the PCNR_ layer keeps source values)
- Changing locked decisions (brief: PDD-D-01..23; repo also locks D-24)
- Any write to the shared source folder
- Running `sas/pecan_id_link.sas` (written and tested in M4, run later when a crosswalk or common key exists)
