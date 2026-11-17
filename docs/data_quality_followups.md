# Data quality follow-ups

Counts and names only; no data values. Source: Gerard's Phase 16 review (2026-11-16).

| # | Item | Counts | Action |
|---|------|--------|--------|
| a | Death_Days_After_Surgery is `#Error` while Death_Date_Y_N = Y (real deaths whose days value failed) | 116 rows: s21 43, s22 43, s23 30 | Ask DSS whether the days can be recomputed. Values stay as delivered (PDD-D-31). |
| b | preop_edu_years values above 30 years, likely entry errors | max 114 in the 2024 file (s22), max 244 in the 2025 file (s23) | Ask DSS to confirm or correct. Values stay as delivered. |
| c | Sleep_Apnea_YN before 2023 records only Y or blank | s03, s06, s07, s09 | Dictionary note (PDD-D-31); ask DSS whether blank means N in the older extracts. |
