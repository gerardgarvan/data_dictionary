# Probe: surgery key spine vs g.MASTER_DATA_HARMONIZED, dup pairs (PR-3)
 
Metadata and counts only. No MRN, case ID or pecan_ID values. Counts 1-10 shown as <11.
Written by sas/17_probe_xwalk3.sas on 2026-11-17.
Lengths are not counts and are not suppressed.
Row order key: the row number on each side, valid only if neither dataset was re-sorted.
Dup pair: two pecan_IDs that share one spine MRN. Side A = ID sorting first as text.
 
## 1. Row counts and the best key
 
|item|value|
|---|---|
|spine pdd.src_s09 row count|41,150|
|g.master_data_harmonized row count|41,150|
|BLANK OR NULL SPINE MRN ROWS|<11|
|best key spine column - see section 1c for the name|-|
|best key gives a one-to-one match of all spine rows - 1 yes and 0 no|1|
 
### 1a. Candidate key columns (column names matching the candidate pattern on either side)
 
|name upcased|spine column|spine type|spine length|harmonized column|harmonized type|harmonized length|on both sides|
|---|---|---|---|---|---|---|---|
|AGE_AT_ENCOUNTER|Age_at_Encounter|num|8|Age_at_Encounter|num|8|yes|
|DEATH_DAYS_AFTER_SURGERY|Death_Days_After_Surgery|num|8|Death_Days_After_Surgery|num|8|yes|
|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|char|50|ENCRYPTED_ENCOUNTER|char|49|yes|
|NORM_PSID|norm_psid|char|64|||.|no|
|PECAN_ID|||.|pecan_ID|num|8|no|
|PRECEDE_STUDY_ID|PRECEDE_Study_ID|char|16|PRECEDE_STUDY_ID|char|12|yes|
|RT_ANCHOR_TO_SURGERY_DAYS|rt_ANCHOR_to_SURGERY_days|num|8|rt_ANCHOR_to_SURGERY_days|num|8|yes|
|SORT_ID|||.|SORT_ID|num|8|no|
 
### 1b. Key tests (spine pdd.src_s09 to g.master_data_harmonized)
 
mode: raw = as delivered; norm = PDD-D-19 normalized (norm_psid); rid = row number.
skip: 0 tested; 1 no non-missing key on a side; 2 fewer distinct values than half of the non-missing rows (not joined).
 
|spine column|harmonized column|mode|skip|spine rows|harmonized rows|spine distinct|harmonized distinct|spine rows matched 0|spine rows matched 1|spine rows matched 2+|harmonized rows matched by 2+ spine rows|one-to-one for all spine rows|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Age_at_Encounter|Age_at_Encounter|raw|2|41,150|41,150|36|36|-|-|-|-|no|
|Death_Days_After_Surgery|Death_Days_After_Surgery|raw|2|41,150|41,150|342|342|-|-|-|-|no|
|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|raw|0|41,150|41,150|39,752|39,787|15,446|25,397|307|341|no|
|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|norm|0|41,150|41,150|39,752|39,787|15,446|25,397|307|341|no|
|PRECEDE_Study_ID|PRECEDE_STUDY_ID|raw|0|41,150|41,150|41,150|41,150|0|41,150|0|0|YES|
|PRECEDE_Study_ID|PRECEDE_STUDY_ID|norm|0|41,150|41,150|41,150|41,150|0|41,150|0|0|YES|
|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|raw|2|41,150|41,150|1,480|1,480|-|-|-|-|no|
|row order|row order|rid|0|41,150|41,150|41,150|41,150|0|41,150|0|0|YES|
 
### 1c. Best key
 
Spine column: PRECEDE_Study_ID ; harmonized column: PRECEDE_STUDY_ID ; mode: norm ; one-to-one for all spine rows (1 yes, 0 no): 1
Order of preference: one-to-one first, then a real key before row order, then most spine rows matched once, then norm before raw.
 
## 2. Best key: spine MRN to pecan_ID, dup pairs
 
|item|value|
|---|---|
|best key joined rows spine to harmonized|41,150|
|best key joined rows where spine row number equals harmonized row number|41,150|
|joined rows with missing pecan_ID|0|
|spine distinct non-blank MRN with a pecan_ID|31,136|
|spine MRN with 1 distinct pecan_ID|29,241|
|spine MRN with 2 distinct pecan_IDs|1,895|
|spine MRN with 3 or more distinct pecan_IDs|0|
|distinct pecan_ID on the joined spine rows|33,031|
|pecan_ID with 1 distinct spine MRN|33,031|
|pecan_ID with 2 distinct spine MRN|0|
|pecan_ID with 3 or more distinct spine MRN|0|
|implied dup pairs - two pecan_IDs sharing a spine MRN|1,895|
 
## 3. Dup pairs by spine YEAR (surgeries on each side)
 
IDs = distinct pecan_IDs of that side with at least one surgery in the year; rows = spine surgeries.
 
|year|side A IDs|side A rows|side B IDs|side B rows|
|---|---|---|---|---|
|2018|218|313|1,677|2,052|
|2020|858|1,031|64|78|
|2021|792|995|116|132|
|2022|549|657|102|123|
 
## 3b. Dup pairs: same-year overlap
 
|item|value|
|---|---|
|dup pairs with a spine surgery in the same YEAR on both sides|0|
|pecan_ID that is side A in one pair and side B in another|0|
 
## 4. Spine MRN with no exact xwalk match, by spine YEAR
 
Distinct MRN can repeat across years, so the yearly distinct counts do not add up to the total.
 
|year|unmatched rows|unmatched distinct MRN|matched rows|matched distinct MRN|
|---|---|---|---|---|
|2018|11,863|10,665|2,365|1,895|
|2019|549|549|-|-|
|2020|-|-|7,695|6,679|
|2021|-|-|9,462|7,982|
|2022|-|-|9,215|8,172|
 
## 4b. Totals
 
|item|value|
|---|---|
|xwalk distinct non-blank MRN|33,031|
|spine distinct MRN with no exact xwalk match|11,149|
|spine rows with no exact xwalk match|12,412|
|spine distinct MRN with an exact xwalk match|19,987|
|unmatched spine MRN that carry 2 or more pecan_IDs - needs section 2|0|
