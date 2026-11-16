# Schema probe: Master Data folder

- Generated: 2026-11-16 11:05 by sas/probe_inputs.sas
- Folder: `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`
- File filter (regex): `.`
- SAS session encoding: UTF-8
- WARNING: session is UTF-8, so the CSV byte scan below may be unreliable.
- Spine for linkage: 2018_2022_X_MASTER_DATASET_20240402.csv (case column: PRECEDE_Study_ID ; MRN column: ENCRYPTED_MRN )
- Privacy: no data values are written. Counts from 1 to 10 are shown as <11.
  ID columns are described by value shape only (9 = digit, A = letter; LONG = length and character class).
- Candidate placeholders counted: character '?','UNKNOWN','UNK','NULL','N/A','NA','NONE','MISSING','-999','-99','-9','.','#N/A','NAN'; numeric -9999, -999, -99, -9, 999, 9999
- Encoding guess: utf-8 = every non-ASCII line is valid UTF-8 (or there are none); wlatin1 = at least one line is not valid UTF-8.

## Files and sheets

|unit|file|sheet|rows|all-blank rows|columns|encoding guess|non-ASCII lines|not-UTF-8 lines|modified|status|
|---|---|---|---|---|---|---|---|---|---|---|
|1|2018-2022_PACU_STAY_20260813.csv||41,423|0|<11|utf-8|0|0|17Aug2026:14:20:00|OK|
|2|2018_2019_2020_Induction_Emergent20231121.csv||22,476|0|<11|utf-8|0|0|21Nov2023:09:11:57|OK|
|3|2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv||14,778|0|102|wlatin1|<11|<11|17Aug2026:11:02:36|OK|
|4|2018_2019_ENCOUNTER_Crypto_Data_20260814.csv||14,781|0|<11|utf-8|0|0|17Aug2026:14:20:00|OK|
|5|2018_2019_MRN_Crypto_Data20260814.csv||14,781|0|<11|utf-8|0|0|17Aug2026:14:20:00|OK|
|6|2018_2019_Precede_Database.xlsx|2018_2019_PRECEDE_DATABASE|14,807|0|3,987|xlsx|-|-|25Sep2023:10:32:14|OK|
|7|2018_2019_X_MASTER_DATASET_20200801.csv||14,778|0|105|wlatin1|<11|<11|17Aug2026:10:43:28|OK|
|8|2018_2022_COLONOSCOPY_20240118.xlsx|SHEET1|3,456|0|<11|xlsx|-|-|18Jan2024:11:26:53|OK|
|9|2018_2022_X_MASTER_DATASET_20240402.csv||41,150|0|124|wlatin1|<11|<11|17Aug2026:10:55:25|OK|
|10|2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv||7,695|0|114|wlatin1|<11|<11|03Jan2022:08:15:16|OK|
|11|2020_Precede_Database_Edu.xlsx|2020_PRECEDE_DATABASE_EDU|7,696|0|<11|xlsx|-|-|22Jun2022:14:38:33|OK|
|12|2020_X_MASTER_DATASET_20210519.csv||7,695|0|86|wlatin1|<11|<11|26Feb2024:12:00:24|OK|
|13|2021_Education_20240124.csv||9,462|0|<11|utf-8|0|0|05Feb2024:08:18:16|OK|
|14|2021_Frailty_20240123.csv||9,462|0|<11|utf-8|0|0|24Jan2024:09:59:34|OK|
|15|2021_X_MASTER_DATASET_20230512.csv||9,462|0|84|wlatin1|<11|<11|26Feb2024:11:55:12|OK|
|16|2022_Education_20240124.csv||9,215|0|<11|utf-8|0|0|05Feb2024:08:18:18|OK|
|17|2022_MASTER_DATASET_20231024.csv||9,215|0|84|wlatin1|<11|<11|26Feb2024:11:57:05|OK|
|18|2022_RES_20230927.csv||9,485|0|<11|utf-8|0|0|28Sep2023:09:08:24|OK|
|19|2023_X_MASTER_DATASET_20261016.csv||10,772|0|94|utf-8|0|0|10Nov2026:15:48:00|OK|
|20|2024_X_MASTER_DATASET_20261016.csv||13,029|0|94|wlatin1|18|18|10Nov2026:15:47:25|OK|
|21|2025_X_MASTER_DATASET_20261016.csv||12,689|0|94|wlatin1|26|26|10Nov2026:15:46:21|OK|
|22|ALL_AIM2_MASTER_DATASET_20210917.xlsx|SHEET1|22,473|0|68|xlsx|-|-|17Aug2026:11:20:03|OK|
|23|All_YEARS_LAT_LONG_20231127.csv||41,150|0|<11|utf-8|0|0|27Nov2023:16:57:58|OK|

## Unit 1: 2018-2022_PACU_STAY_20260813.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|18|$|41,423|41,423|0||yes|
|2|PRECEDE_ID_NUM|PRECEDE_ID_NUM|Num|8|BEST|41,423|41,422|<11||yes|
|3|Total PACU Stay Minutes|Total PACU Stay Minutes|Num|8|BEST|38,374|1,257|<11|||

## Unit 2: 2018_2019_2020_Induction_Emergent20231121.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|18|$|22,476|22,476|0||yes|
|2|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|13,330|91|<11|||
|3|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|12,918|700|0|||

## Unit 3: 2018_2019_CPT_ROLLUP_X_MASTER_DATASET_20200801.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|ID|ID|Num|8|BEST|14,778|14,778|<11||yes|
|2|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|14,778|14,778|0||yes|
|3|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|41|$|14,777|13,045|0||yes|
|4|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|46|$|14,559|14,348|0||yes|
|5|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|13,481|616|<11|||
|6|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|13,608|595|0|||
|7|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|13,478|764|<11|||
|8|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|13,050|772|0|||
|9|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|13,048|1,127|0|||
|10|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|2,740|381|0|||
|11|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|2,740|395|0|||
|12|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|13,195|780|0|||
|13|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|13,177|1,124|0|||
|14|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|12,870|803|<11|||
|15|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|10,595|1,070|<11|||
|16|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|10,341|583|0|||
|17|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|13,252|677|0|||
|18|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|10,637|645|0|||
|19|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|13,106|88|139|||
|20|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|12,927|160|0|||
|21|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|13,113|690|0|||
|22|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|2,744|78|0|||
|23|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|13,608|8|0|||
|24|Holidays|Holidays|Char|1|$|13,274|3|0|||
|25|Weekend_Indicator|Weekend_Indicator|Char|1|$|13,608|3|0|||
|26|Age at Encounter|Age at Encounter|Num|8|BEST|13,608|36|0||yes|
|27|EmployeeStatus|EmployeeStatus|Char|23|$|14,778|10|2,177|||
|28|Education|Education|Char|19|$|296|7|0|||
|29|Race|Race|Char|16|$|13,608|11|73|||
|30|Ethnicity|Ethnicity|Char|15|$|13,608|5|88|||
|31|Sex|Sex|Char|6|$|13,608|3|0|||
|32|Marital Status|Marital Status|Char|22|$|13,608|9|1,264|||
|33|Admit BMI|Admit BMI|Num|8|BEST|5,323|3,818|0|||
|34|Service|Service|Char|32|$|13,608|32|0|||
|35|Room Type|Room Type|Char|21|$|13,602|15|0|||
|36|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|12,665|6|0|||
|37|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|13,608|3|0|||
|38|Base Procedure 1|Base Procedure 1|Char|200|$|13,608|1,237|0|||
|39|Base Procedure Code 1|Base Procedure Code 1|Char|10|$|13,608|1,237|0|||
|40|CPT 1|CPT 1|Char|8|$|13,608|1,079|423|||
|41|CPT 1 Description|CPT 1 Description|Char|75|$|13,608|1,079|0|||
|42|CPT1 Class|CPT1 Class|Num|8|BEST|13,108|151|0|||
|43|CPT1 Label|CPT1 Label|Char|98|$|13,108|151|0|||
|44|Patient Type|Patient Type|Char|18|$|13,608|5|0|||
|45|LOS|LOS|Num|8|BEST|13,481|53|0|||
|46|LOS in Hours|LOS in Hours|Num|8|BEST|5,561|3,670|0|||
|47|Payer|Payer|Char|12|$|13,481|13|0|||
|48|Charges|Charges|Num|8|BEST|13,476|13,083|0|||
|49|ICD10 Principal Diagnosis Desc|ICD10 Principal Diagnosis Desc|Char|62|$|13,374|1,967|0|||
|50|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|13,374|1,967|0|||
|51|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|13,373|17|0|||
|52|COMP10_T80|COMP10_T80|Num|8|BEST|14,778|2|0|||
|53|COMP10_T81|COMP10_T81|Num|8|BEST|14,778|3|0|||
|54|COMP10_T82|COMP10_T82|Num|8|BEST|14,778|5|0|||
|55|COMP10_T83|COMP10_T83|Num|8|BEST|14,778|3|0|||
|56|COMP10_T84|COMP10_T84|Num|8|BEST|14,778|5|0|||
|57|COMP10_T85|COMP10_T85|Num|8|BEST|14,778|3|0|||
|58|COMP10_T86|COMP10_T86|Num|8|BEST|14,778|3|0|||
|59|COMP10_T87|COMP10_T87|Num|8|BEST|14,778|2|0|||
|60|COMP10_T88|COMP10_T88|Num|8|BEST|14,778|3|0|||
|61|complication_sum|complication_sum|Num|8|BEST|14,778|5|0|||
|62|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|1,112|2|0|||
|63|Preop_block|Preop_block|Char|1|$|2,744|2|0|||
|64|Admit Source|Admit Source|Char|40|$|13,481|8|<11|||
|65|Dischg Disposition|Dischg Disposition|Char|42|$|13,481|24|<11|||
|66|30_DAY_MORTALITY|30_DAY_MORTALITY|Char|1|$|13,487|3|0|||
|67|Death_Date Y/N|Death_Date Y/N|Char|1|$|13,487|3|0|||
|68|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|13,487|3|0|||
|69|Anesthesia Type|Anesthesia Type|Char|33|$|13,617|6|0|||
|70|Sleep_Apnea_YN|Sleep_Apnea_YN|Char|1|$|2,111|2|0|||
|71|Diabetes_YN|Diabetes_YN|Char|1|$|4,031|2|0|||
|72|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|7,262|2|0|||
|73|Hypertension_YN|Hypertension_YN|Char|1|$|7,291|2|0|||
|74|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|834|2|0|||
|75|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|133|2|0|||
|76|Latitude|Latitude|Num|8|BEST|13,616|10,000|0|||
|77|Longitude|Longitude|Num|8|BEST|13,616|9,981|0|||
|78|Propofol_mg_IntraOp_Total|Propofol_mg_IntraOp_Total|Num|8|BEST|14,778|4,791|0|||
|79|Ketamine_mg_IntraOp_Total|Ketamine_mg_IntraOp_Total|Num|8|BEST|14,778|217|0|||
|80|fentaNYL_SUBLIMAZE_mg_IntraOp_To|fentaNYL_SUBLIMAZE_mg_IntraOp_To|Num|8|BEST|14,778|1|0|||
|81|Sufentanil_mg_IntraOp_Total|Sufentanil_mg_IntraOp_Total|Num|8|BEST|14,778|718|0|||
|82|Hydromorphone_mg_IntraOp_Total|Hydromorphone_mg_IntraOp_Total|Num|8|BEST|14,778|38|0|||
|83|Lidocaine_mg_IntraOp_Total|Lidocaine_mg_IntraOp_Total|Num|8|BEST|14,778|65|0|||
|84|Oral_Morphine_Equiv_IntraOp_Tota|Oral_Morphine_Equiv_IntraOp_Tota|Num|8|BEST|14,778|275|0|||
|85|ISO_Exp_IntraOp_Total|ISO_Exp_IntraOp_Total|Num|8|BEST|14,778|1,752|0|||
|86|ISO_Exp_IntraOp_MAC_Average|ISO_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|2,119|0|||
|87|ISO_Exp_IntraOp_MAC_Minutes_Tota|ISO_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|14,778|603|0|||
|88|ISO_Exp_IntraOp_MAC_Total|ISO_Exp_IntraOp_MAC_Total|Num|8|BEST|14,778|1,752|0|||
|89|SEV_Exp_IntraOp_Total|SEV_Exp_IntraOp_Total|Num|8|BEST|14,778|4,431|0|||
|90|SEV_Exp_IntraOp_MAC_Average|SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|5,498|0|||
|91|SEV_Exp_IntraOp_MAC_Minutes_Tota|SEV_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|14,778|510|0|||
|92|SEV_Exp_IntraOp_MAC_Total|SEV_Exp_IntraOp_MAC_Total|Num|8|BEST|14,778|4,431|0|||
|93|ISO_SEV_Exp_IntraOp_MAC_Average|ISO_SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|7,067|0|||
|94|Propofol_mg_1_7_Total|Propofol_mg_1_7_Total|Num|8|BEST|14,778|26|0|||
|95|Ketamine_mg_1_7_Total|Ketamine_mg_1_7_Total|Num|8|BEST|14,778|9|0|||
|96|fentaNYL_SUBLIMAZE_mg__1_7_Total|fentaNYL_SUBLIMAZE_mg__1_7_Total|Num|8|BEST|14,778|1|0|||
|97|Sufentanil_mg__1_7_Total|Sufentanil_mg__1_7_Total|Num|8|BEST|14,778|1|0|||
|98|Hydromorphone_mg__1_7_Total|Hydromorphone_mg__1_7_Total|Num|8|BEST|14,778|107|0|||
|99|Lidocaine_mg_1_7_Total|Lidocaine_mg_1_7_Total|Num|8|BEST|14,778|31|0|||
|100|Oral_Morphine_Equiv_Given__1_7_T|Oral_Morphine_Equiv_Given__1_7_T|Num|8|BEST|14,778|728|0|||
|101|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|Num|8|BEST|14,778|284|0|||
|102|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|Num|8|BEST|14,778|226|0|||

## Unit 4: 2018_2019_ENCOUNTER_Crypto_Data_20260814.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|18|$|14,781|14,781|0||yes|
|2|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|46|$|14,781|14,352|0||yes|

## Unit 5: 2018_2019_MRN_Crypto_Data20260814.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|18|$|14,781|14,781|0||yes|
|2|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|41|$|14,781|13,047|0||yes|

## Unit 6: 2018_2019_Precede_Database.xlsx [sheet=2018_2019_PRECEDE_DATABASE]

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|studyid|studyid|Char|12|$|14,807|14,807|0||yes|
|2|precede_aim1_2_location|precede_aim1_2_location|Char|4|$|13,973|<11|0||yes|
|3|aim3_enroll_id|aim3_enroll_id|Char|7|$|122|123|0||yes|
|4|precede_aim1_2_Week|precede_aim1_2_Week|Num|8|BEST|14,786|107|0||yes|
|5|preop_date|preop_date|Char|8|$|14,784|514|0|||
|6|pecan_testing|pecan_testing|Num|8|BEST|8,927|<11|0||yes|
|7|pecan_flag|pecan_flag|Num|8|BEST|3,213|<11|0||yes|
|8|pecan_clock_flag|pecan_clock_flag|Num|8|BEST|2,919|<11|0||yes|
|9|pecaner|pecaner|Num|8|BEST|14,807|<11|0||yes|
|10|age|age|Num|8|BEST|14,780|35|0|||
|11|sex|sex|Char|2|$|14,722|4|0|||
|12|age_categ_organize|age_categ_organize|Num|8|BEST|14,723|35|0|||
|13|age_categ|age_categ|Num|8|BEST|14,723|5|0|||
|14|frailty_score_category|frailty_score_category|Num|8|BEST|11,628|11|0|||
|15|Frailty_Score|Frailty_Score|Num|8|BEST|11,611|11|0|||
|16|dukes_activity_scale|dukes_activity_scale|Char|1|$|0|1|0|||
|17|mmse_3word_repeat|mmse_3word_repeat|Num|8|BEST|12,061|5|0|||
|18|mmse_3word_recall|mmse_3word_recall|Num|8|BEST|12,022|5|0|||
|19|Edu_Years|Edu_Years|Num|8|BEST|11,361|32|0|||
|20|edu_categorical|edu_categorical|Num|8|BEST|11,646|13|0|||
|21|Edu_Clock_notes|Edu_Clock_notes|Char|63|$|720|174|0|||
|22|handedness|handedness|Char|12|$|10,776|10|0|||
|23|GripStrength_trial_1|GripStrength_trial_1|Num|8|BEST|11,725|69|0|||
|24|GripStrength_trial_2|GripStrength_trial_2|Num|8|BEST|11,638|72|0|||
|25|GripStrength_trial_3|GripStrength_trial_3|Num|8|BEST|11,592|73|0|||
|26|repeated_clock_instructions|repeated_clock_instructions|Char|3|$|9,744|13|0|||
|27|precede_aim1_2_notes|precede_aim1_2_notes|Char|103|$|47|33|0||yes|
|28|precede_aim1_2_clock_file_notes|precede_aim1_2_clock_file_notes|Char|17|$|684|<11|0||yes|
|29|precede_aim1_2_clock_missing|precede_aim1_2_clock_missing|Num|8|BEST|14,790|<11|0||yes|
|30|precede_aim1_2_physical_limitati|precede_aim1_2_physical_limitation|Char|75|$|146|115|0||yes|
|31|precede_aim1_2_nurse_notes|precede_aim1_2_nurse_notes|Char|165|$|261|241|0||yes|
|32|precede_aim1_2_scoring_issues|precede_aim1_2_scoring_issues|Char|68|$|<11|<11|0||yes|
|33|precede_aim1_2_clock_administrat|precede_aim1_2_clock_administrator|Char|1|$|0|<11|0||yes|
|34|Clock_Data|Clock_Data|Num|8|BEST|14,807|9|0|||
|35|Other Variables|Other Variables|Char|44|$|<11|3|0|||
|36|DigitalClockDataExpected|DigitalClockDataExpected|Char|12|$|14,711|5|0|||
|37|DigitalClockDataInfo|DigitalClockDataInfo|Char|8|$|7,160|3|1,569|||
|38|CorrectionNotes|CorrectionNotes|Char|1|$|0|1|0|||
|39|time_point|time_point|Char|1|$|0|1|0|||
|40|precede_aim1_2_year|precede_aim1_2_year|Num|8|BEST|14,790|<11|0||yes|
|41|Precede_aim1_2_month|Precede_aim1_2_month|Num|8|BEST|14,790|25|0||yes|
|42|Fiscal year|Fiscal year|Num|8|BEST|14,790|4|0|||
|43|trltid|trltid|Char|1|$|0|1|0|||
|44|group|group|Char|1|$|0|1|0|||
|45|pecan_psychometrist|pecan_psychometrist|Char|1|$|0|<11|0||yes|
|46|COM_mini_cog_clock_only|COM_mini_cog_clock_only|Char|1|$|0|1|0|||
|47|COPY_mini_cog_clock_only|COPY_mini_cog_clock_only|Char|1|$|0|1|0|||
|48|COM_libon_score|COM_libon_score|Char|1|$|0|1|0|||
|49|COPY_libon_score|COPY_libon_score|Char|1|$|0|1|0|||
|50|com_libon_sc2a_1|com_libon_sc2a_1|Char|1|$|0|1|0|||
|51|com_libon_sc2a_2|com_libon_sc2a_2|Char|1|$|0|1|0|||
|52|com_libon_sc2b_1|com_libon_sc2b_1|Char|1|$|0|1|0|||
|53|com_libon_sc2b_2|com_libon_sc2b_2|Char|1|$|0|1|0|||
|54|com_libon_sc2b_3|com_libon_sc2b_3|Char|1|$|0|1|0|||
|55|com_libon_sc2b_4|com_libon_sc2b_4|Char|1|$|0|1|0|||
|56|com_libon_sc2b_5|com_libon_sc2b_5|Char|1|$|0|1|0|||
|57|com_libon_sc2c_1|com_libon_sc2c_1|Char|1|$|0|1|0|||
|58|com_libon_sc2c_2|com_libon_sc2c_2|Char|1|$|0|1|0|||
|59|com_libon_sc2c_3|com_libon_sc2c_3|Char|1|$|0|1|0|||
|60|copy_libon_sc2a_1|copy_libon_sc2a_1|Char|1|$|0|1|0|||
|61|copy_libon_sc2a_2|copy_libon_sc2a_2|Char|1|$|0|1|0|||
|62|copy_libon_sc2b_1|copy_libon_sc2b_1|Char|1|$|0|1|0|||
|63|copy_libon_sc2b_2|copy_libon_sc2b_2|Char|1|$|0|1|0|||
|64|copy_libon_sc2b_3|copy_libon_sc2b_3|Char|1|$|0|1|0|||
|65|copy_libon_sc2b_4|copy_libon_sc2b_4|Char|1|$|0|1|0|||
|66|copy_libon_sc2b_5|copy_libon_sc2b_5|Char|1|$|0|1|0|||
|67|copy_libon_sc2c_1|copy_libon_sc2c_1|Char|1|$|0|1|0|||
|68|copy_libon_sc2c_2|copy_libon_sc2c_2|Char|1|$|0|1|0|||
|69|copy_libon_sc2c_3|copy_libon_sc2c_3|Char|1|$|0|1|0|||
|70|edu_categorical_other|edu_categorical_other|Char|1|$|0|1|0|||
|71|Redcap|Redcap|Char|1|$|0|1|0|||
|72|Aim_3_Baseline_Redcap_Comp|Aim_3_Baseline_Redcap_Comp|Char|1|$|0|1|0|||
|73|Aim_3_6Week_Redcap_Comp|Aim_3_6Week_Redcap_Comp|Char|1|$|0|1|0|||
|74|Aim_3_3Month_Redcap_Comp|Aim_3_3Month_Redcap_Comp|Char|1|$|0|1|0|||
|75|Aim_3_1Year_Redcap_Comp|Aim_3_1Year_Redcap_Comp|Char|1|$|0|1|0|||
|76|Delirium|Delirium|Char|1|$|0|1|0|||
|77|Count of psychotic drug given|Count of psychotic drug given|Num|8|BEST|55|16|0|||
|78|Presence of Preop Pyscotic Disor|Presence of Preop Pyscotic Disorder (Y/N)|Char|1|$|55|3|0|||
|79|IDR Variables Only|IDR Variables Only|Char|1|$|0|1|0|||
|80|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|40|$|14,778|13,045|0||yes|
|81|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|49|$|14,560|14,349|0||yes|
|82|surgerycancelled|surgerycancelled|Num|8|BEST|14,790|3|0|||
|83|Day_of_Week|Day_of_Week|Char|3|$|13,607|8|0|||
|84|Holiday|Holiday|Char|1|$|13,273|3|0|||
|85|Weekend_Indicator|Weekend_Indicator|Char|1|$|13,608|3|0|||
|86|Age_at_Encounter|Age_at_Encounter|Num|8|BEST|13,607|36|0||yes|
|87|Race|Race|Char|16|$|13,608|11|73|||
|88|Ethnicity|Ethnicity|Char|15|$|13,608|5|88|||
|89|Sex_1|Sex_1|Char|6|$|13,608|3|0|||
|90|Marital_Status|Marital_Status|Char|22|$|13,607|9|1,264|||
|91|Admit_BMI|Admit_BMI|Num|8|BEST|5,322|3,817|0|||
|92|Service|Service|Char|32|$|13,608|32|0|||
|93|Room_Type|Room_Type|Char|21|$|13,601|15|0|||
|94|ASA_Anest_Record|ASA_Anest_Record|Num|8|BEST|12,664|6|0|||
|95|Emergent_Anest_Record|Emergent_Anest_Record|Char|1|$|13,607|3|0|||
|96|Base_Procedure_1|Base_Procedure_1|Char|198|$|13,607|1,237|0|||
|97|Base_Procedure_Code_1|Base_Procedure_Code_1|Char|10|$|13,607|1,237|0|||
|98|CPT_1|CPT_1|Char|8|$|13,607|1,079|423|||
|99|CPT_1_Description|CPT_1_Description|Char|73|$|13,607|1,079|0|||
|100|Patient_Type|Patient_Type|Char|18|$|13,607|5|0|||
|101|LOS|LOS|Num|8|BEST|13,481|53|0|||
|102|LOS_in_Hours|LOS_in_Hours|Num|8|BEST|5,560|3,669|0|||
|103|Payer|Payer|Char|12|$|13,481|13|0|||
|104|Payer_categ|Payer_categ|Num|8|BEST|13,480|5|0|||
|105|Charges|Charges|Num|8|BEST|13,476|13,083|0|||
|106|ICD10_Principal_Diagnosis_Desc|ICD10_Principal_Diagnosis_Desc|Char|60|$|13,373|1,967|0|||
|107|ICD10_Principal_Diagnosis|ICD10_Principal_Diagnosis|Char|7|$|13,373|1,967|0|||
|108|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|13,373|17|0|||
|109|COMP10_T80|COMP10_T80|Num|8|BEST|14,778|3|0|||
|110|COMP10_T81|COMP10_T81|Num|8|BEST|14,778|4|0|||
|111|COMP10_T82|COMP10_T82|Num|8|BEST|14,778|6|0|||
|112|COMP10_T83|COMP10_T83|Num|8|BEST|14,778|4|0|||
|113|COMP10_T84|COMP10_T84|Num|8|BEST|14,778|6|0|||
|114|COMP10_T85|COMP10_T85|Num|8|BEST|14,778|4|0|||
|115|COMP10_T86|COMP10_T86|Num|8|BEST|14,778|4|0|||
|116|COMP10_T87|COMP10_T87|Num|8|BEST|14,778|3|0|||
|117|COMP10_T88|COMP10_T88|Num|8|BEST|14,778|4|0|||
|118|complication_sum|complication_sum|Num|8|BEST|14,778|6|0|||
|119|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|1,112|2|0|||
|120|Preop_block|Preop_block|Char|1|$|2,744|2|0|||
|121|Primary_Payer|Primary_Payer|Char|12|$|7,109|12|0|||
|122|Insurance|Insurance|Char|38|$|6,569|100|0|||
|123|EmployeeStatus|EmployeeStatus|Char|23|$|14,778|11|2,177|||
|124|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|13,481|616|<11|||
|125|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|13,608|595|0|||
|126|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|13,478|764|<11|||
|127|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|13,050|772|0|||
|128|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|13,048|1,127|0|||
|129|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|2,740|381|0|||
|130|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|2,740|395|0|||
|131|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|13,195|780|0|||
|132|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|13,177|1,124|0|||
|133|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|12,870|803|<11|||
|134|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|10,595|1,070|<11|||
|135|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|10,341|583|0|||
|136|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|13,252|677|0|||
|137|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|13,113|690|0|||
|138|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|2,744|78|0|||
|139|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|10,637|645|0|||
|140|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|13,106|88|139|||
|141|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|12,927|160|0|||
|142|Education|Education|Char|19|$|296|7|0|||
|143|Admit_Source|Admit_Source|Char|40|$|13,480|8|<11|||
|144|30_DAY_MORTALITY|30_DAY_MORTALITY|Char|1|$|13,487|3|0|||
|145|Death_Date Y/N|Death_Date Y/N|Char|1|$|718|3|0|||
|146|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|13,487|3|0|||
|147|Anesthesia_Type|Anesthesia_Type|Char|33|$|13,616|6|0|||
|148|Sleep_Apnea_YN|Sleep_Apnea_YN|Char|1|$|2,111|2|0|||
|149|Diabetes_YN|Diabetes_YN|Char|1|$|4,031|2|0|||
|150|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|7,262|2|0|||
|151|Hypertension_YN|Hypertension_YN|Char|1|$|7,291|2|0|||
|152|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|834|2|0|||
|153|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|133|2|0|||
|154|Latitude|Latitude|Num|8|BEST|13,616|10,000|0|||
|155|Longitude|Longitude|Num|8|BEST|13,616|9,981|0|||
|156|Dischg_Disposition|Dischg_Disposition|Char|42|$|13,480|24|<11|||
|157|Death Indicator|Death Indicator|Char|1|$|9,718|3|0|||
|158|pain_scale_desc|pain_scale_desc|Char|20|$|156|15|<11|||
|159|Propofol_mg_IntraOp_Total|Propofol_mg_IntraOp_Total|Num|8|BEST|14,778|4,792|0|||
|160|Ketamine_mg_IntraOp_Total|Ketamine_mg_IntraOp_Total|Num|8|BEST|14,778|218|0|||
|161|fentaNYL_SUBLIMAZE_mg_IntraOp_To|fentaNYL_SUBLIMAZE_mg_IntraOp_Total|Num|8|BEST|14,778|2|0|||
|162|Sufentanil_mg_IntraOp_Total|Sufentanil_mg_IntraOp_Total|Num|8|BEST|14,778|719|0|||
|163|Hydromorphone_mg_IntraOp_Total|Hydromorphone_mg_IntraOp_Total|Num|8|BEST|14,778|39|0|||
|164|Lidocaine_mg_IntraOp_Total|Lidocaine_mg_IntraOp_Total|Num|8|BEST|14,778|66|0|||
|165|Oral_Morphine_Equiv_IntraOp_Tota|Oral_Morphine_Equiv_IntraOp_Total_mg|Num|8|BEST|14,778|276|0|||
|166|ISO_Exp_IntraOp_Total|ISO_Exp_IntraOp_Total|Num|8|BEST|14,778|1,753|0|||
|167|ISO_Exp_IntraOp_MAC_Average|ISO_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|2,120|0|||
|168|ISO_Exp_IntraOp_MAC_Minutes_Tota|ISO_Exp_IntraOp_MAC_Minutes_Total|Num|8|BEST|14,778|604|0|||
|169|ISO_Exp_IntraOp_MAC_Total|ISO_Exp_IntraOp_MAC_Total|Num|8|BEST|14,778|1,753|0|||
|170|SEV_Exp_IntraOp_Total|SEV_Exp_IntraOp_Total|Num|8|BEST|14,778|4,432|0|||
|171|SEV_Exp_IntraOp_MAC_Average|SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|5,499|0|||
|172|SEV_Exp_IntraOp_MAC_Minutes_Tota|SEV_Exp_IntraOp_MAC_Minutes_Total|Num|8|BEST|14,778|511|0|||
|173|SEV_Exp_IntraOp_MAC_Total|SEV_Exp_IntraOp_MAC_Total|Num|8|BEST|14,778|4,432|0|||
|174|ISO_SEV_Exp_IntraOp_MAC_Average|ISO_SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|7,068|0|||
|175|Propofol_mg_1_7_Total|Propofol_mg_1_7_Total|Num|8|BEST|14,778|27|0|||
|176|Ketamine_mg_1_7_Total|Ketamine_mg_1_7_Total|Num|8|BEST|14,778|10|0|||
|177|fentaNYL_SUBLIMAZE_mg__1_7_Total|fentaNYL_SUBLIMAZE_mg__1_7_Total|Num|8|BEST|14,778|2|0|||
|178|Sufentanil_mg__1_7_Total|Sufentanil_mg__1_7_Total|Num|8|BEST|14,778|2|0|||
|179|Hydromorphone_mg__1_7_Total|Hydromorphone_mg__1_7_Total|Num|8|BEST|14,778|108|0|||
|180|Lidocaine_mg_1_7_Total|Lidocaine_mg_1_7_Total|Num|8|BEST|14,778|32|0|||
|181|Oral_Morphine_Equiv_Given__1_7_T|Oral_Morphine_Equiv_Given__1_7_Total_mg|Num|8|BEST|14,778|729|0|||
|182|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|Num|8|BEST|14,778|285|0|||
|183|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|Num|8|BEST|14,778|227|0|||
|184|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|Num|8|BEST|14,778|175|0|||
|185|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|Num|8|BEST|14,778|145|0|||
|186|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|Num|8|BEST|14,778|132|0|||
|187|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|Num|8|BEST|14,778|114|0|||
|188|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|Num|8|BEST|14,778|92|0|||
|189|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|14,778|447|0|||
|190|PeCANers|PeCANers|Char|1|$|0|<11|0||yes|
|191|pecan_tested|pecan_tested|Num|8|BEST|1,655|<11|0||yes|
|192|examiner|examiner|Char|25|$|1,584|31|0|||
|193|test_date|test_date|Char|31|$|1,655|831|0|||
|194|race_1|race_1|Char|8|$|1,651|5|0|||
|195|barona_region|barona_region|Char|22|$|1,537|6|0|||
|196|barona_residence|barona_residence|Char|5|$|1,591|4|0|||
|197|pecan_trainee|pecan_trainee|Char|17|$|720|25|0||yes|
|198|barona_occupations|barona_occupations|Char|22|$|1,624|8|0|||
|199|barona_edu|barona_edu|Char|3|$|1,635|18|0|||
|200|pecan_attending|pecan_attending|Char|22|$|1,490|<11|0||yes|
|201|barona_fsiq|barona_fsiq|Num|8|BEST|1,516|345|0|||
|202|wrat_total_raw|wrat_total_raw|Char|5|$|1,459|66|51|||
|203|wrat_desc|wrat_desc|Char|14|$|1,608|56|151|||
|204|mmse_orientation_total|mmse_orientation_total|Char|7|$|1,573|14|<11|||
|205|mmse_registration|mmse_registration|Char|6|$|1,573|8|<11|||
|206|mmse_attention_calc|mmse_attention_calc|Char|6|$|1,573|9|<11|||
|207|mmse_recall|mmse_recall|Char|6|$|1,573|7|<11|||
|208|mmse_naming|mmse_naming|Char|3|$|1,573|6|<11|||
|209|mmse_repetition|mmse_repetition|Char|6|$|1,573|7|<11|||
|210|mmse_comprehension|mmse_comprehension|Char|3|$|1,573|6|<11|||
|211|mmse_reading|mmse_reading|Char|3|$|1,573|6|<11|||
|212|mmse_writing|mmse_writing|Char|3|$|1,573|7|<11|||
|213|mmse_drawing|mmse_drawing|Char|3|$|1,573|7|<11|||
|214|mmse_total|mmse_total|Char|5|$|1,573|28|<11|||
|215|mmse_desc|mmse_desc|Char|3|$|1,573|6|<11|||
|216|wais_iii_forward_span_raw|wais_iii_forward_span_raw|Char|4|$|1,489|13|19|||
|217|wais_iii_forward_span_z|wais_iii_forward_span_z|Char|19|$|1,489|70|<11|||
|218|wais_iii_forward_span_percent|wais_iii_forward_span_percent|Char|3|$|1,488|28|<11|||
|219|wais_iii_forward_desc|wais_iii_forward_desc|Char|13|$|1,609|15|121|||
|220|wais_iii_backward_span_raw|wais_iii_backward_span_raw|Char|6|$|1,488|16|20|||
|221|wais_iii_backward_span_z|wais_iii_backward_span_z|Char|19|$|1,488|72|<11|||
|222|wais_iii_backward_span_percent|wais_iii_backward_span_percent|Char|10|$|1,487|26|<11|||
|223|wais_iii_backward_desc|wais_iii_backward_desc|Char|13|$|1,607|15|122|||
|224|kban_forward_time|kban_forward_time|Char|13|$|1,508|89|28|||
|225|kban_forward_omissions|kban_forward_omissions|Char|3|$|1,508|12|<11|||
|226|kban_forward_correct|kban_forward_correct|Char|13|$|142|5|0|||
|227|kban_backward_time|kban_backward_time|Char|13|$|1,508|203|36|||
|228|kban_backward_omissions|kban_backward_omissions|Char|4|$|1,508|20|<11|||
|229|kban_backward_correct|kban_backward_correct|Char|13|$|1,329|5|0|||
|230|hvlt_trial_1_raw|hvlt_trial_1_raw|Char|30|$|1,466|17|<11|||
|231|hvlt_trial_1_z|hvlt_trial_1_z|Char|18|$|1,466|66|<11|||
|232|hvlt_trial_1_percent|hvlt_trial_1_percent|Char|22|$|1,466|66|<11|||
|233|hvlt_trial_1_desc|hvlt_trial_1_desc|Char|13|$|1,466|13|<11|||
|234|hvlt_trial_2_raw|hvlt_trial_2_raw|Char|27|$|1,466|17|<11|||
|235|hvlt_trial_2_z|hvlt_trial_2_z|Char|19|$|1,464|72|<11|||
|236|hvlt_trial_2_percent|hvlt_trial_2_percent|Char|22|$|1,464|73|<11|||
|237|hvlt_trial_3_raw|hvlt_trial_3_raw|Char|15|$|1,466|19|<11|||
|238|hvlt_trial_3_z|hvlt_trial_3_z|Char|19|$|1,463|74|<11|||
|239|hvlt_trial_3_percent|hvlt_trial_3_percent|Char|22|$|1,464|75|<11|||
|240|hvlt_total|hvlt_total|Char|20|$|1,466|39|<11|||
|241|hvlt_total_z|hvlt_total_z|Char|20|$|1,466|161|<11|||
|242|hvlt_total_percent|hvlt_total_percent|Char|22|$|1,466|161|<11|||
|243|hvlt_total_desc|hvlt_total_desc|Char|12|$|1,466|11|<11|||
|244|hvlt_delay_raw|hvlt_delay_raw|Char|27|$|1,466|17|<11|||
|245|hvlt_delay_z|hvlt_delay_z|Char|19|$|1,459|75|<11|||
|246|hvlt_delay_percent|hvlt_delay_percent|Char|22|$|1,459|80|<11|||
|247|hvlt_delay_desc|hvlt_delay_desc|Char|12|$|1,461|11|<11|||
|248|hvlt_recog_true_positive|hvlt_recog_true_positive|Char|29|$|1,466|20|<11|||
|249|hvlt_recog_false_positive|hvlt_recog_false_positive|Char|8|$|1,466|17|<11|||
|250|hvlt_discrimination_index|hvlt_discrimination_index|Char|36|$|1,460|22|<11|||
|251|hvlt_discrimination_index_z|hvlt_discrimination_index_z|Char|19|$|1,458|80|<11|||
|252|hvlt_discrimination_index_percen|hvlt_discrimination_index_percent|Char|22|$|1,458|81|<11|||
|253|hvlt_discrimination_index_desc|hvlt_discrimination_index_desc|Char|12|$|1,459|10|<11|||
|254|hvlt_total_intrusions|hvlt_total_intrusions|Char|20|$|1,466|15|0|||
|255|hvlt_delay_intrusions|hvlt_delay_intrusions|Char|2|$|1,466|11|<11|||
|256|behavioral_obs_social_beh|behavioral_obs_social_beh|Char|24|$|1,535|9|0|||
|257|behavioral_obs_amb_mobil|behavioral_obs_amb_mobil|Char|39|$|1,535|19|0|||
|258|behavioral_obs_sensory|behavioral_obs_sensory|Char|38|$|1,536|12|0|||
|259|behavioral_obs_motor|behavioral_obs_motor|Char|26|$|1,534|12|0|||
|260|behavioral_obs_speech|behavioral_obs_speech|Char|35|$|1,534|12|0|||
|261|behavioral_obs_attention|behavioral_obs_attention|Char|35|$|1,534|9|0|||
|262|behavioral_obs_rapport|behavioral_obs_rapport|Char|35|$|1,534|9|0|||
|263|behavioral_obs_cooperation|behavioral_obs_cooperation|Char|35|$|1,534|7|0|||
|264|behavioral_obs_language|behavioral_obs_language|Char|47|$|1,534|13|0|||
|265|behavioral_obs_mood|behavioral_obs_mood|Char|38|$|1,535|15|0|||
|266|cam_icu_result|cam_icu_result|Char|51|$|1,189|8|<11|||
|267|cam_icu_1|cam_icu_1|Char|14|$|1,321|15|120|||
|268|cam_icu_2|cam_icu_2|Char|19|$|1,321|59|<11|||
|269|cam_icu_3|cam_icu_3|Char|14|$|1,324|8|0|||
|270|cam_icu_4|cam_icu_4|Char|25|$|1,324|46|<11|||
|271|trog_raw|trog_raw|Char|3|$|1,452|7|34|||
|272|trog_desc|trog_desc|Char|15|$|1,452|7|<11|||
|273|cowa_f_first_15_sec|cowa_f_first_15_sec|Char|7|$|1,415|17|<11|||
|274|cowa_f_second_15_sec|cowa_f_second_15_sec|Char|7|$|1,415|14|<11|||
|275|cowa_f_third_15_sec|cowa_f_third_15_sec|Char|7|$|1,415|13|<11|||
|276|cowa_f_fourth_15_sec|cowa_f_fourth_15_sec|Char|7|$|1,415|12|<11|||
|277|cowa_f_intrusions|cowa_f_intrusions|Char|7|$|1,415|16|<11|||
|278|cowa_f_total|cowa_f_total|Char|3|$|1,415|30|<11|||
|279|cowa_f_z|cowa_f_z|Char|18|$|1,415|84|<11|||
|280|cowa_f_percentile|cowa_f_percentile|Char|18|$|1,415|92|<11|||
|281|cowa_f_desc|cowa_f_desc|Char|13|$|1,415|14|<11|||
|282|animal_fluen_first_15_sec|animal_fluen_first_15_sec|Char|7|$|1,379|21|<11|||
|283|animal_fluen_second_15_sec|animal_fluen_second_15_sec|Char|7|$|1,379|15|<11|||
|284|animal_fluen_third_15_sec|animal_fluen_third_15_sec|Char|7|$|1,379|16|<11|||
|285|animal_fluen_fourth_15_sec|animal_fluen_fourth_15_sec|Char|7|$|1,379|16|<11|||
|286|animal_fluen_intrusions|animal_fluen_intrusions|Char|7|$|1,379|15|<11|||
|287|animal_fluen_total_raw|animal_fluen_total_raw|Char|5|$|1,379|38|<11|||
|288|animal_fluen_z|animal_fluen_z|Char|19|$|1,379|145|<11|||
|289|animal_fluen_percent|animal_fluen_percent|Char|17|$|1,378|165|<11|||
|290|animal_fluen_desc|animal_fluen_desc|Char|18|$|1,378|16|<11|||
|291|abba_reading_time|abba_reading_time|Char|7|$|1,470|108|83|||
|292|abba_reading_total_errors|abba_reading_total_errors|Char|7|$|1,470|13|<11|||
|293|abba_reading_desc|abba_reading_desc|Char|3|$|1,417|5|33|||
|294|abba_altern_time|abba_altern_time|Char|7|$|1,470|162|87|||
|295|abba_altern_total_errors|abba_altern_total_errors|Char|7|$|1,470|31|<11|||
|296|abba_altern_desc|abba_altern_desc|Char|14|$|1,419|8|36|||
|297|happiness_scale|happiness_scale|Char|5|$|1,443|23|44|||
|298|happiness_scale_desc|happiness_scale_desc|Char|10|$|1,443|9|<11|||
|299|gds_total|gds_total|Char|10|$|1,587|63|800|||
|300|mood_fatigue|mood_fatigue|Char|5|$|1,587|28|84|||
|301|mood_fatigue_desc|mood_fatigue_desc|Char|10|$|1,417|9|147|||
|302|mood_anxiety|mood_anxiety|Char|5|$|1,585|17|45|||
|303|mood_anxiety_desc|mood_anxiety_desc|Char|10|$|1,584|10|147|||
|304|mood_apathy|mood_apathy|Char|5|$|1,585|20|48|||
|305|mood_apathy_desc|mood_apathy_desc|Char|8|$|1,417|7|147|||
|306|mood_agency|mood_agency|Char|5|$|1,585|24|47|||
|307|mood_agency_desc|mood_agency_desc|Char|10|$|1,419|8|147|||
|308|pain_scale|pain_scale|Char|24|$|489|52|35|||
|309|adls_total|adls_total|Char|6|$|545|10|203|||
|310|cog_func_total_score|cog_func_total_score|Char|5|$|542|7|200|||
|311|less_total|less_total|Char|11|$|856|273|51|||
|312|less_total_desc|less_total_desc|Char|18|$|855|19|65|||
|313|magellan_risk_scale_total|magellan_risk_scale_total|Char|6|$|122|19|<11|||
|314|magellan_risk_scale_desc|magellan_risk_scale_desc|Char|8|$|122|7|<11|||
|315|zarit_total|zarit_total|Char|21|$|979|70|487|||
|316|zarit_total_desc|zarit_total_desc|Char|15|$|979|9|<11|||
|317|dhq_total|dhq_total|Char|13|$|366|64|41|||
|318|dhq_desc|dhq_desc|Char|22|$|363|20|0|||
|319|prospec_mem_recall|prospec_mem_recall|Char|93|$|1,579|26|47|||
|320|spat_mem_expo_name_total|spat_mem_expo_name_total|Char|5|$|1,211|12|<11|||
|321|spat_mem_imm_name_total|spat_mem_imm_name_total|Char|5|$|1,211|12|20|||
|322|spat_mem_imm_loc_total|spat_mem_imm_loc_total|Char|5|$|1,211|12|15|||
|323|spat_mem_imm_assoc_total|spat_mem_imm_assoc_total|Char|8|$|1,205|14|14|||
|324|spat_mem_delay_name_total|spat_mem_delay_name_total|Char|8|$|1,213|18|15|||
|325|spat_mem_delay_loc_total|spat_mem_delay_loc_total|Char|8|$|1,213|16|11|||
|326|spat_mem_delay_assoc_total|spat_mem_delay_assoc_total|Char|13|$|1,207|19|<11|||
|327|moca_visual_spat_total|moca_visual_spat_total|Char|3|$|73|9|<11|||
|328|moca_naming_score|moca_naming_score|Num|8|BEST|75|5|0|||
|329|moca_attention_digits|moca_attention_digits|Char|3|$|63|6|<11|||
|330|moca_attention3|moca_attention3|Num|8|BEST|63|4|0|||
|331|moca_attention4_scoring|moca_attention4_scoring|Char|3|$|63|6|<11|||
|332|moca_language1|moca_language1|Num|8|BEST|65|4|0|||
|333|moca_language2|moca_language2|Char|3|$|63|5|0|||
|334|moca_abstraction_score|moca_abstraction_score|Char|3|$|73|7|0|||
|335|moca_delayed_recall_score|moca_delayed_recall_score|Char|3|$|73|8|0|||
|336|moca_orientation_score|moca_orientation_score|Char|3|$|75|9|0|||
|337|moca_total|moca_total|Num|8|BEST|72|26|0|||
|338|moca_desc|moca_desc|Char|3|$|70|3|0|||
|339|moca_attention_score|moca_attention_score|Num|8|BEST|<11|7|0|||
|340|moca_language_score|moca_language_score|Num|8|BEST|12|5|0|||
|341|billing_code|billing_code|Char|46|$|94|20|0|||
|342|billing_neurocog_primary_diag_co|billing_neurocog_primary_diag_code|Char|61|$|83|11|0|||
|343|billing_neurocog_primary_desc|billing_neurocog_primary_desc|Char|93|$|51|22|0|||
|344|billing_neurocog_secondary_diag_|billing_neurocog_secondary_diag_code|Char|53|$|16|9|0|||
|345|billing_neurocog_secondary_desc|billing_neurocog_secondary_desc|Char|97|$|<11|5|0|||
|346|billing_psych_code|billing_psych_code|Char|6|$|17|12|0|||
|347|billing_psych_desc|billing_psych_desc|Char|57|$|11|8|0|||
|348|billing_neurodevelp_code|billing_neurodevelp_code|Char|5|$|<11|2|0|||
|349|billing_neurodevelp_desc|billing_neurodevelp_desc|Char|44|$|<11|3|0|||
|350|lbrs_total|lbrs_total|Num|8|BEST|25|4|0|||
|351|nacc_lbd_autonomic_symp|nacc_lbd_autonomic_symp|Num|8|BEST|25|4|0|||
|352|nacc_lbd_first_symp|nacc_lbd_first_symp|Char|52|$|<11|2|0|||
|353|nacc_lbd_first_symp_age|nacc_lbd_first_symp_age|Char|1|$|0|1|0|||
|354|nacc_lbd_sleepdis_age|nacc_lbd_sleepdis_age|Char|1|$|0|1|0|||
|355|nacc_lbd_smellimpair_age|nacc_lbd_smellimpair_age|Char|1|$|0|1|0|||
|356|DigitalClockData|DigitalClockData|Char|1|$|0|1|0|||
|357|COMDwgTotStrokes|COMDwgTotStrokes|Num|8|BEST|11,471|87|91|||
|358|COMDwgTotTime|COMDwgTotTime|Num|8|BEST|11,471|10,224|91|||
|359|COMClockFace1TotStrokes|COMClockFace1TotStrokes|Num|8|BEST|11,471|12|173|||
|360|COMClockFace1TotTime|COMClockFace1TotTime|Num|8|BEST|11,471|1,103|173|||
|361|COMClockFace1TotLen|COMClockFace1TotLen|Num|8|BEST|11,471|11,298|173|||
|362|COMClockFace1PnSpdQ1|COMClockFace1PnSpdQ1|Num|8|BEST|11,471|11,059|412|||
|363|COMClockFace1PnSpdQ2|COMClockFace1PnSpdQ2|Num|8|BEST|11,471|11,059|412|||
|364|COMClockFace1PnSpdQ3|COMClockFace1PnSpdQ3|Num|8|BEST|11,471|11,059|412|||
|365|COMClockFace1PnSpdQ4|COMClockFace1PnSpdQ4|Num|8|BEST|11,471|11,059|412|||
|366|COMClockFace1HorizSz|COMClockFace1HorizSz|Num|8|BEST|11,471|2,324|173|||
|367|COMClockFace1VertSz|COMClockFace1VertSz|Num|8|BEST|11,471|2,364|173|||
|368|COMClockFace1FitHSz|COMClockFace1FitHSz|Num|8|BEST|11,471|11,298|173|||
|369|COMClockFace1FitVSz|COMClockFace1FitVSz|Num|8|BEST|11,471|11,298|173|||
|370|COMClockFace1HorSymm|COMClockFace1HorSymm|Num|8|BEST|11,471|11,298|173|||
|371|COMClockFace1VertSymm|COMClockFace1VertSymm|Num|8|BEST|11,471|11,298|173|||
|372|COMClockFace1EllipHSymm|COMClockFace1EllipHSymm|Num|8|BEST|11,471|11,298|173|||
|373|COMClockFace1EllipVSymm|COMClockFace1EllipVSymm|Num|8|BEST|11,471|11,298|173|||
|374|COMClockFace1ClosedPct|COMClockFace1ClosedPct|Num|8|BEST|11,471|10,796|415|||
|375|COMClockFace1ClosedAng|COMClockFace1ClosedAng|Num|8|BEST|11,471|11,056|415|||
|376|COMClockFace1EllipAng|COMClockFace1EllipAng|Num|8|BEST|11,471|11,298|173|||
|377|COMClockFace1CenterX|COMClockFace1CenterX|Num|8|BEST|11,471|11,298|173|||
|378|COMClockFace1CenterY|COMClockFace1CenterY|Num|8|BEST|11,471|11,298|173|||
|379|COMClockFace2TotStrokes|COMClockFace2TotStrokes|Num|8|BEST|11,471|6|11,040|||
|380|COMClockFace2TotTime|COMClockFace2TotTime|Num|8|BEST|11,471|235|11,040|||
|381|COMClockFace2TotLen|COMClockFace2TotLen|Num|8|BEST|11,471|433|11,040|||
|382|COMClockFace2PnSpdQ1|COMClockFace2PnSpdQ1|Num|8|BEST|11,471|424|11,049|||
|383|COMClockFace2PnSpdQ2|COMClockFace2PnSpdQ2|Num|8|BEST|11,471|424|11,049|||
|384|COMClockFace2PnSpdQ3|COMClockFace2PnSpdQ3|Num|8|BEST|11,471|424|11,049|||
|385|COMClockFace2PnSpdQ4|COMClockFace2PnSpdQ4|Num|8|BEST|11,471|424|11,049|||
|386|COMClockFace2HorizSz|COMClockFace2HorizSz|Num|8|BEST|11,471|382|11,040|||
|387|COMClockFace2VertSz|COMClockFace2VertSz|Num|8|BEST|11,471|382|11,040|||
|388|COMClockFace2FitHSz|COMClockFace2FitHSz|Num|8|BEST|11,471|433|11,040|||
|389|COMClockFace2FitVSz|COMClockFace2FitVSz|Num|8|BEST|11,471|433|11,040|||
|390|COMClockFace2HorSymm|COMClockFace2HorSymm|Num|8|BEST|11,471|433|11,040|||
|391|COMClockFace2VertSymm|COMClockFace2VertSymm|Num|8|BEST|11,471|433|11,040|||
|392|COMClockFace2EllipHSymm|COMClockFace2EllipHSymm|Num|8|BEST|11,471|433|11,040|||
|393|COMClockFace2EllipVSymm|COMClockFace2EllipVSymm|Num|8|BEST|11,471|433|11,040|||
|394|COMClockFace2ClosedPct|COMClockFace2ClosedPct|Num|8|BEST|11,471|408|11,049|||
|395|COMClockFace2ClosedAng|COMClockFace2ClosedAng|Num|8|BEST|11,471|424|11,049|||
|396|COMClockFace2EllipAng|COMClockFace2EllipAng|Num|8|BEST|11,471|433|11,040|||
|397|COMClockFace2CenterX|COMClockFace2CenterX|Num|8|BEST|11,471|433|11,040|||
|398|COMClockFace2CenterY|COMClockFace2CenterY|Num|8|BEST|11,471|433|11,040|||
|399|COMHH1TotStrokes|COMHH1TotStrokes|Num|8|BEST|11,471|16|646|||
|400|COMHH1TotTime|COMHH1TotTime|Num|8|BEST|11,471|3,576|646|||
|401|COMHH1TotLen|COMHH1TotLen|Num|8|BEST|11,471|10,826|646|||
|402|COMHH1HandLen|COMHH1HandLen|Num|8|BEST|11,471|9,698|646|||
|403|COMHH1HandLenNorm|COMHH1HandLenNorm|Num|8|BEST|11,471|10,752|716|||
|404|COMHH1CenterX|COMHH1CenterX|Num|8|BEST|11,471|10,814|646|||
|405|COMHH1CenterY|COMHH1CenterY|Num|8|BEST|11,471|10,818|646|||
|406|COMHH1Dir|COMHH1Dir|Num|8|BEST|11,471|4|646|||
|407|COMHH1ArrowDir|COMHH1ArrowDir|Num|8|BEST|11,471|5|646|||
|408|COMHH1DistCent|COMHH1DistCent|Num|8|BEST|11,471|10,755|716|||
|409|COMHH1Angle|COMHH1Angle|Num|8|BEST|11,471|9,362|646|||
|410|COMHH1DiffIdealAng|COMHH1DiffIdealAng|Num|8|BEST|11,471|9,364|646|||
|411|COMHH1AngTo11|COMHH1AngTo11|Num|8|BEST|11,471|10,351|1,120|||
|412|COMHH2TotStrokes|COMHH2TotStrokes|Num|8|BEST|11,471|6|11,453|||
|413|COMHH2TotTime|COMHH2TotTime|Num|8|BEST|11,471|20|11,453|||
|414|COMHH2TotLen|COMHH2TotLen|Num|8|BEST|11,471|20|11,453|||
|415|COMHH2HandLen|COMHH2HandLen|Num|8|BEST|11,471|20|11,453|||
|416|COMHH2HandLenNorm|COMHH2HandLenNorm|Num|8|BEST|11,471|20|11,453|||
|417|COMHH2CenterX|COMHH2CenterX|Num|8|BEST|11,471|20|11,453|||
|418|COMHH2CenterY|COMHH2CenterY|Num|8|BEST|11,471|20|11,453|||
|419|COMHH2Dir|COMHH2Dir|Num|8|BEST|11,471|4|11,453|||
|420|COMHH2ArrowDir|COMHH2ArrowDir|Num|8|BEST|11,471|4|11,453|||
|421|COMHH2DistCent|COMHH2DistCent|Num|8|BEST|11,471|20|11,453|||
|422|COMHH2Angle|COMHH2Angle|Num|8|BEST|11,471|20|11,453|||
|423|COMHH2DiffIdealAng|COMHH2DiffIdealAng|Num|8|BEST|11,471|20|11,453|||
|424|COMHH2AngTo11|COMHH2AngTo11|Num|8|BEST|11,471|18|11,455|||
|425|COMHH3TotStrokes|COMHH3TotStrokes|Num|8|BEST|11,471|2|11,471|||
|426|COMHH3TotTime|COMHH3TotTime|Num|8|BEST|11,471|2|11,471|||
|427|COMHH3TotLen|COMHH3TotLen|Num|8|BEST|11,471|2|11,471|||
|428|COMHH3HandLen|COMHH3HandLen|Num|8|BEST|11,471|2|11,471|||
|429|COMHH3HandLenNorm|COMHH3HandLenNorm|Num|8|BEST|11,471|2|11,471|||
|430|COMHH3CenterX|COMHH3CenterX|Num|8|BEST|11,471|2|11,471|||
|431|COMHH3CenterY|COMHH3CenterY|Num|8|BEST|11,471|2|11,471|||
|432|COMHH3Dir|COMHH3Dir|Num|8|BEST|11,471|2|11,471|||
|433|COMHH3ArrowDir|COMHH3ArrowDir|Num|8|BEST|11,471|2|11,471|||
|434|COMHH3DistCent|COMHH3DistCent|Num|8|BEST|11,471|2|11,471|||
|435|COMHH3Angle|COMHH3Angle|Num|8|BEST|11,471|2|11,471|||
|436|COMHH3DiffIdealAng|COMHH3DiffIdealAng|Num|8|BEST|11,471|2|11,471|||
|437|COMHH3AngTo11|COMHH3AngTo11|Num|8|BEST|11,471|2|11,471|||
|438|COMMH1TotStrokes|COMMH1TotStrokes|Num|8|BEST|11,471|17|762|||
|439|COMMH1TotTime|COMMH1TotTime|Num|8|BEST|11,471|3,384|762|||
|440|COMMH1TotLen|COMMH1TotLen|Num|8|BEST|11,471|10,709|762|||
|441|COMMH1HandLen|COMMH1HandLen|Num|8|BEST|11,471|10,043|762|||
|442|COMMH1HandLenNorm|COMMH1HandLenNorm|Num|8|BEST|11,471|10,637|830|||
|443|COMMH1CenterX|COMMH1CenterX|Num|8|BEST|11,471|10,699|762|||
|444|COMMH1CenterY|COMMH1CenterY|Num|8|BEST|11,471|10,697|762|||
|445|COMMH1Dir|COMMH1Dir|Num|8|BEST|11,471|4|762|||
|446|COMMH1ArrowDir|COMMH1ArrowDir|Num|8|BEST|11,471|5|762|||
|447|COMMH1DistCent|COMMH1DistCent|Num|8|BEST|11,471|10,641|830|||
|448|COMMH1Angle|COMMH1Angle|Num|8|BEST|11,471|9,738|762|||
|449|COMMH1DiffIdealAng|COMMH1DiffIdealAng|Num|8|BEST|11,471|9,738|762|||
|450|COMMH1AngTo2|COMMH1AngTo2|Num|8|BEST|11,471|10,220|1,249|||
|451|COMMH2TotStrokes|COMMH2TotStrokes|Num|8|BEST|11,471|5|11,460|||
|452|COMMH2TotTime|COMMH2TotTime|Num|8|BEST|11,471|13|11,460|||
|453|COMMH2TotLen|COMMH2TotLen|Num|8|BEST|11,471|13|11,460|||
|454|COMMH2HandLen|COMMH2HandLen|Num|8|BEST|11,471|13|11,460|||
|455|COMMH2HandLenNorm|COMMH2HandLenNorm|Num|8|BEST|11,471|13|11,460|||
|456|COMMH2CenterX|COMMH2CenterX|Num|8|BEST|11,471|13|11,460|||
|457|COMMH2CenterY|COMMH2CenterY|Num|8|BEST|11,471|13|11,460|||
|458|COMMH2Dir|COMMH2Dir|Num|8|BEST|11,471|4|11,460|||
|459|COMMH2ArrowDir|COMMH2ArrowDir|Num|8|BEST|11,471|4|11,460|||
|460|COMMH2DistCent|COMMH2DistCent|Num|8|BEST|11,471|13|11,460|||
|461|COMMH2Angle|COMMH2Angle|Num|8|BEST|11,471|13|11,460|||
|462|COMMH2DiffIdealAng|COMMH2DiffIdealAng|Num|8|BEST|11,471|13|11,460|||
|463|COMMH2AngTo2|COMMH2AngTo2|Num|8|BEST|11,471|11|11,462|||
|464|COMMH3TotStrokes|COMMH3TotStrokes|Num|8|BEST|11,471|2|11,471|||
|465|COMMH3TotTime|COMMH3TotTime|Num|8|BEST|11,471|2|11,471|||
|466|COMMH3TotLen|COMMH3TotLen|Num|8|BEST|11,471|2|11,471|||
|467|COMMH3HandLen|COMMH3HandLen|Num|8|BEST|11,471|2|11,471|||
|468|COMMH3HandLenNorm|COMMH3HandLenNorm|Num|8|BEST|11,471|2|11,471|||
|469|COMMH3CenterX|COMMH3CenterX|Num|8|BEST|11,471|2|11,471|||
|470|COMMH3CenterY|COMMH3CenterY|Num|8|BEST|11,471|2|11,471|||
|471|COMMH3Dir|COMMH3Dir|Num|8|BEST|11,471|2|11,471|||
|472|COMMH3ArrowDir|COMMH3ArrowDir|Num|8|BEST|11,471|2|11,471|||
|473|COMMH3DistCent|COMMH3DistCent|Num|8|BEST|11,471|2|11,471|||
|474|COMMH3Angle|COMMH3Angle|Num|8|BEST|11,471|2|11,471|||
|475|COMMH3DiffIdealAng|COMMH3DiffIdealAng|Num|8|BEST|11,471|2|11,471|||
|476|COMMH3AngTo2|COMMH3AngTo2|Num|8|BEST|11,471|2|11,471|||
|477|COMHandPair1IntX|COMHandPair1IntX|Num|8|BEST|11,471|10,664|793|||
|478|COMHandPair1IntY|COMHandPair1IntY|Num|8|BEST|11,471|10,666|793|||
|479|COMHandPair1Angle|COMHandPair1Angle|Num|8|BEST|11,471|10,675|793|||
|480|COMHandPair2IntX|COMHandPair2IntX|Num|8|BEST|11,471|29|11,444|||
|481|COMHandPair2IntY|COMHandPair2IntY|Num|8|BEST|11,471|29|11,444|||
|482|COMHandPair2Angle|COMHandPair2Angle|Num|8|BEST|11,471|29|11,444|||
|483|COMHandPair3IntX|COMHandPair3IntX|Num|8|BEST|11,471|4|11,469|||
|484|COMHandPair3IntY|COMHandPair3IntY|Num|8|BEST|11,471|4|11,469|||
|485|COMHandPair3Angle|COMHandPair3Angle|Num|8|BEST|11,471|4|11,469|||
|486|COMHandPair4IntX|COMHandPair4IntX|Num|8|BEST|11,471|4|11,469|||
|487|COMHandPair4IntY|COMHandPair4IntY|Num|8|BEST|11,471|4|11,469|||
|488|COMHandPair4Angle|COMHandPair4Angle|Num|8|BEST|11,471|4|11,469|||
|489|COMHandPair5IntX|COMHandPair5IntX|Num|8|BEST|11,471|2|11,471|||
|490|COMHandPair5IntY|COMHandPair5IntY|Num|8|BEST|11,471|2|11,471|||
|491|COMHandPair5Angle|COMHandPair5Angle|Num|8|BEST|11,471|2|11,471|||
|492|COMHandPair6IntX|COMHandPair6IntX|Num|8|BEST|11,471|2|11,471|||
|493|COMHandPair6IntY|COMHandPair6IntY|Num|8|BEST|11,471|2|11,471|||
|494|COMHandPair6Angle|COMHandPair6Angle|Num|8|BEST|11,471|2|11,471|||
|495|COMHandPair7IntX|COMHandPair7IntX|Num|8|BEST|11,471|2|11,471|||
|496|COMHandPair7IntY|COMHandPair7IntY|Num|8|BEST|11,471|2|11,471|||
|497|COMHandPair7Angle|COMHandPair7Angle|Num|8|BEST|11,471|2|11,471|||
|498|COMHandPair8IntX|COMHandPair8IntX|Num|8|BEST|11,471|2|11,471|||
|499|COMHandPair8IntY|COMHandPair8IntY|Num|8|BEST|11,471|2|11,471|||
|500|COMHandPair8Angle|COMHandPair8Angle|Num|8|BEST|11,471|2|11,471|||
|501|COMHandPair9IntX|COMHandPair9IntX|Num|8|BEST|11,471|2|11,471|||
|502|COMHandPair9IntY|COMHandPair9IntY|Num|8|BEST|11,471|2|11,471|||
|503|COMHandPair9Angle|COMHandPair9Angle|Num|8|BEST|11,471|2|11,471|||
|504|COMDigit1Missing|COMDigit1Missing|Num|8|BEST|11,471|4|91|||
|505|COMDigit2Missing|COMDigit2Missing|Num|8|BEST|11,471|4|91|||
|506|COMDigit3Missing|COMDigit3Missing|Num|8|BEST|11,471|4|91|||
|507|COMDigit4Missing|COMDigit4Missing|Num|8|BEST|11,471|4|91|||
|508|COMDigit5Missing|COMDigit5Missing|Num|8|BEST|11,471|4|91|||
|509|COMDigit6Missing|COMDigit6Missing|Num|8|BEST|11,471|4|91|||
|510|COMDigit7Missing|COMDigit7Missing|Num|8|BEST|11,471|4|91|||
|511|COMDigit8Missing|COMDigit8Missing|Num|8|BEST|11,471|4|91|||
|512|COMDigit9Missing|COMDigit9Missing|Num|8|BEST|11,471|4|91|||
|513|COMDigit10Missing|COMDigit10Missing|Num|8|BEST|11,471|4|91|||
|514|COMDigit11Missing|COMDigit11Missing|Num|8|BEST|11,471|4|91|||
|515|COMDigit12Missing|COMDigit12Missing|Num|8|BEST|11,471|4|91|||
|516|COMDigitAvgWid|COMDigitAvgWid|Num|8|BEST|11,471|2,534|343|||
|517|COMDigitAvgHt|COMDigitAvgHt|Num|8|BEST|11,471|3,090|343|||
|518|COMDigAvgNormSizeQ1|COMDigAvgNormSizeQ1|Num|8|BEST|11,471|10,616|483|||
|519|COMDigAvgNormSizeQ2|COMDigAvgNormSizeQ2|Num|8|BEST|11,471|10,529|529|||
|520|COMDigAvgNormSizeQ3|COMDigAvgNormSizeQ3|Num|8|BEST|11,471|10,514|621|||
|521|COMDigAvgNormSizeQ4|COMDigAvgNormSizeQ4|Num|8|BEST|11,471|10,435|655|||
|522|COMDigNormSizeFirst3|COMDigNormSizeFirst3|Num|8|BEST|11,471|10,640|423|||
|523|COMDigNormSizeSecond3|COMDigNormSizeSecond3|Num|8|BEST|11,471|10,479|561|||
|524|COMDigNormSizeThird3|COMDigNormSizeThird3|Num|8|BEST|11,471|10,284|766|||
|525|COMDigNormSizeFourth3|COMDigNormSizeFourth3|Num|8|BEST|11,471|10,271|836|||
|526|COMDigit1Seq|COMDigit1Seq|Num|8|BEST|11,471|15|736|||
|527|COMDigit1Strokes|COMDigit1Strokes|Num|8|BEST|11,471|6|736|||
|528|COMDigit1Time|COMDigit1Time|Num|8|BEST|11,471|271|736|||
|529|COMDigit1Len|COMDigit1Len|Num|8|BEST|11,471|10,735|736|||
|530|COMDigit1CentX|COMDigit1CentX|Num|8|BEST|11,471|3,523|736|||
|531|COMDigit1CentY|COMDigit1CentY|Num|8|BEST|11,471|3,729|736|||
|532|COMDigit1Width|COMDigit1Width|Num|8|BEST|11,471|188|736|||
|533|COMDigit1Hgt|COMDigit1Hgt|Num|8|BEST|11,471|310|736|||
|534|COMDigit1NormHt|COMDigit1NormHt|Num|8|BEST|11,471|9,651|811|||
|535|COMDigit1Outside|COMDigit1Outside|Num|8|BEST|11,471|4|736|||
|536|COMDigit1Angle|COMDigit1Angle|Num|8|BEST|11,471|10,661|736|||
|537|COMDigit1IdealDiff|COMDigit1IdealDiff|Num|8|BEST|11,471|10,661|736|||
|538|COMDigit1DistCircum|COMDigit1DistCircum|Num|8|BEST|11,471|8,828|736|||
|539|COMDigit1IsPersev|COMDigit1IsPersev|Num|8|BEST|11,471|3|736|||
|540|COMDigit2Seq|COMDigit2Seq|Num|8|BEST|11,471|15|697|||
|541|COMDigit2Strokes|COMDigit2Strokes|Num|8|BEST|11,471|6|697|||
|542|COMDigit2Time|COMDigit2Time|Num|8|BEST|11,471|296|697|||
|543|COMDigit2Len|COMDigit2Len|Num|8|BEST|11,471|10,774|697|||
|544|COMDigit2CentX|COMDigit2CentX|Num|8|BEST|11,471|3,804|697|||
|545|COMDigit2CentY|COMDigit2CentY|Num|8|BEST|11,471|3,829|697|||
|546|COMDigit2Width|COMDigit2Width|Num|8|BEST|11,471|294|697|||
|547|COMDigit2Hgt|COMDigit2Hgt|Num|8|BEST|11,471|308|697|||
|548|COMDigit2NormHt|COMDigit2NormHt|Num|8|BEST|11,471|9,787|772|||
|549|COMDigit2Outside|COMDigit2Outside|Num|8|BEST|11,471|4|697|||
|550|COMDigit2Angle|COMDigit2Angle|Num|8|BEST|11,471|10,700|697|||
|551|COMDigit2IdealDiff|COMDigit2IdealDiff|Num|8|BEST|11,471|10,700|697|||
|552|COMDigit2DistCircum|COMDigit2DistCircum|Num|8|BEST|11,471|9,139|697|||
|553|COMDigit2IsPersev|COMDigit2IsPersev|Num|8|BEST|11,471|3|697|||
|554|COMDigit3Seq|COMDigit3Seq|Num|8|BEST|11,471|15|548|||
|555|COMDigit3Strokes|COMDigit3Strokes|Num|8|BEST|11,471|6|548|||
|556|COMDigit3Time|COMDigit3Time|Num|8|BEST|11,471|312|548|||
|557|COMDigit3Len|COMDigit3Len|Num|8|BEST|11,471|10,923|548|||
|558|COMDigit3CentX|COMDigit3CentX|Num|8|BEST|11,471|3,999|548|||
|559|COMDigit3CentY|COMDigit3CentY|Num|8|BEST|11,471|4,054|548|||
|560|COMDigit3Width|COMDigit3Width|Num|8|BEST|11,471|290|548|||
|561|COMDigit3Hgt|COMDigit3Hgt|Num|8|BEST|11,471|336|548|||
|562|COMDigit3NormHt|COMDigit3NormHt|Num|8|BEST|11,471|9,907|622|||
|563|COMDigit3Outside|COMDigit3Outside|Num|8|BEST|11,471|4|548|||
|564|COMDigit3Angle|COMDigit3Angle|Num|8|BEST|11,471|10,850|548|||
|565|COMDigit3IdealDiff|COMDigit3IdealDiff|Num|8|BEST|11,471|10,850|548|||
|566|COMDigit3DistCircum|COMDigit3DistCircum|Num|8|BEST|11,471|9,371|548|||
|567|COMDigit3IsPersev|COMDigit3IsPersev|Num|8|BEST|11,471|3|548|||
|568|COMDigit4Seq|COMDigit4Seq|Num|8|BEST|11,471|15|734|||
|569|COMDigit4Strokes|COMDigit4Strokes|Num|8|BEST|11,471|8|734|||
|570|COMDigit4Time|COMDigit4Time|Num|8|BEST|11,471|1,504|734|||
|571|COMDigit4Len|COMDigit4Len|Num|8|BEST|11,471|10,737|734|||
|572|COMDigit4CentX|COMDigit4CentX|Num|8|BEST|11,471|3,888|734|||
|573|COMDigit4CentY|COMDigit4CentY|Num|8|BEST|11,471|4,337|734|||
|574|COMDigit4Width|COMDigit4Width|Num|8|BEST|11,471|275|734|||
|575|COMDigit4Hgt|COMDigit4Hgt|Num|8|BEST|11,471|380|734|||
|576|COMDigit4NormHt|COMDigit4NormHt|Num|8|BEST|11,471|9,842|809|||
|577|COMDigit4Outside|COMDigit4Outside|Num|8|BEST|11,471|4|734|||
|578|COMDigit4Angle|COMDigit4Angle|Num|8|BEST|11,471|10,663|734|||
|579|COMDigit4IdealDiff|COMDigit4IdealDiff|Num|8|BEST|11,471|10,663|734|||
|580|COMDigit4DistCircum|COMDigit4DistCircum|Num|8|BEST|11,471|9,167|734|||
|581|COMDigit4IsPersev|COMDigit4IsPersev|Num|8|BEST|11,471|3|734|||
|582|COMDigit5Seq|COMDigit5Seq|Num|8|BEST|11,471|16|740|||
|583|COMDigit5Strokes|COMDigit5Strokes|Num|8|BEST|11,471|6|740|||
|584|COMDigit5Time|COMDigit5Time|Num|8|BEST|11,471|1,485|740|||
|585|COMDigit5Len|COMDigit5Len|Num|8|BEST|11,471|10,731|740|||
|586|COMDigit5CentX|COMDigit5CentX|Num|8|BEST|11,471|3,698|740|||
|587|COMDigit5CentY|COMDigit5CentY|Num|8|BEST|11,471|4,559|740|||
|588|COMDigit5Width|COMDigit5Width|Num|8|BEST|11,471|363|740|||
|589|COMDigit5Hgt|COMDigit5Hgt|Num|8|BEST|11,471|364|740|||
|590|COMDigit5NormHt|COMDigit5NormHt|Num|8|BEST|11,471|9,924|814|||
|591|COMDigit5Outside|COMDigit5Outside|Num|8|BEST|11,471|4|740|||
|592|COMDigit5Angle|COMDigit5Angle|Num|8|BEST|11,471|10,658|740|||
|593|COMDigit5IdealDiff|COMDigit5IdealDiff|Num|8|BEST|11,471|10,658|740|||
|594|COMDigit5DistCircum|COMDigit5DistCircum|Num|8|BEST|11,471|9,315|740|||
|595|COMDigit5IsPersev|COMDigit5IsPersev|Num|8|BEST|11,471|3|740|||
|596|COMDigit6Seq|COMDigit6Seq|Num|8|BEST|11,471|15|537|||
|597|COMDigit6Strokes|COMDigit6Strokes|Num|8|BEST|11,471|7|537|||
|598|COMDigit6Time|COMDigit6Time|Num|8|BEST|11,471|273|537|||
|599|COMDigit6Len|COMDigit6Len|Num|8|BEST|11,471|10,934|537|||
|600|COMDigit6CentX|COMDigit6CentX|Num|8|BEST|11,471|3,306|537|||
|601|COMDigit6CentY|COMDigit6CentY|Num|8|BEST|11,471|4,779|537|||
|602|COMDigit6Width|COMDigit6Width|Num|8|BEST|11,471|256|537|||
|603|COMDigit6Hgt|COMDigit6Hgt|Num|8|BEST|11,471|383|537|||
|604|COMDigit6NormHt|COMDigit6NormHt|Num|8|BEST|11,471|10,097|614|||
|605|COMDigit6Outside|COMDigit6Outside|Num|8|BEST|11,471|4|537|||
|606|COMDigit6Angle|COMDigit6Angle|Num|8|BEST|11,471|10,858|537|||
|607|COMDigit6IdealDiff|COMDigit6IdealDiff|Num|8|BEST|11,471|10,858|537|||
|608|COMDigit6DistCircum|COMDigit6DistCircum|Num|8|BEST|11,471|9,015|537|||
|609|COMDigit6IsPersev|COMDigit6IsPersev|Num|8|BEST|11,471|3|537|||
|610|COMDigit7Seq|COMDigit7Seq|Num|8|BEST|11,471|15|744|||
|611|COMDigit7Strokes|COMDigit7Strokes|Num|8|BEST|11,471|7|744|||
|612|COMDigit7Time|COMDigit7Time|Num|8|BEST|11,471|544|744|||
|613|COMDigit7Len|COMDigit7Len|Num|8|BEST|11,471|10,727|744|||
|614|COMDigit7CentX|COMDigit7CentX|Num|8|BEST|11,471|3,101|744|||
|615|COMDigit7CentY|COMDigit7CentY|Num|8|BEST|11,471|4,669|744|||
|616|COMDigit7Width|COMDigit7Width|Num|8|BEST|11,471|268|744|||
|617|COMDigit7Hgt|COMDigit7Hgt|Num|8|BEST|11,471|356|744|||
|618|COMDigit7NormHt|COMDigit7NormHt|Num|8|BEST|11,471|9,821|818|||
|619|COMDigit7Outside|COMDigit7Outside|Num|8|BEST|11,471|4|744|||
|620|COMDigit7Angle|COMDigit7Angle|Num|8|BEST|11,471|10,654|744|||
|621|COMDigit7IdealDiff|COMDigit7IdealDiff|Num|8|BEST|11,471|10,654|744|||
|622|COMDigit7DistCircum|COMDigit7DistCircum|Num|8|BEST|11,471|9,245|744|||
|623|COMDigit7IsPersev|COMDigit7IsPersev|Num|8|BEST|11,471|3|744|||
|624|COMDigit8Seq|COMDigit8Seq|Num|8|BEST|11,471|16|748|||
|625|COMDigit8Strokes|COMDigit8Strokes|Num|8|BEST|11,471|8|748|||
|626|COMDigit8Time|COMDigit8Time|Num|8|BEST|11,471|828|748|||
|627|COMDigit8Len|COMDigit8Len|Num|8|BEST|11,471|10,723|748|||
|628|COMDigit8CentX|COMDigit8CentX|Num|8|BEST|11,471|2,992|748|||
|629|COMDigit8CentY|COMDigit8CentY|Num|8|BEST|11,471|4,448|748|||
|630|COMDigit8Width|COMDigit8Width|Num|8|BEST|11,471|294|748|||
|631|COMDigit8Hgt|COMDigit8Hgt|Num|8|BEST|11,471|366|748|||
|632|COMDigit8NormHt|COMDigit8NormHt|Num|8|BEST|11,471|9,836|822|||
|633|COMDigit8Outside|COMDigit8Outside|Num|8|BEST|11,471|4|748|||
|634|COMDigit8Angle|COMDigit8Angle|Num|8|BEST|11,471|10,650|748|||
|635|COMDigit8IdealDiff|COMDigit8IdealDiff|Num|8|BEST|11,471|10,650|748|||
|636|COMDigit8DistCircum|COMDigit8DistCircum|Num|8|BEST|11,471|9,273|748|||
|637|COMDigit8IsPersev|COMDigit8IsPersev|Num|8|BEST|11,471|3|748|||
|638|COMDigit9Seq|COMDigit9Seq|Num|8|BEST|11,471|16|591|||
|639|COMDigit9Strokes|COMDigit9Strokes|Num|8|BEST|11,471|7|591|||
|640|COMDigit9Time|COMDigit9Time|Num|8|BEST|11,471|430|591|||
|641|COMDigit9Len|COMDigit9Len|Num|8|BEST|11,471|10,880|591|||
|642|COMDigit9CentX|COMDigit9CentX|Num|8|BEST|11,471|3,004|591|||
|643|COMDigit9CentY|COMDigit9CentY|Num|8|BEST|11,471|4,232|591|||
|644|COMDigit9Width|COMDigit9Width|Num|8|BEST|11,471|265|591|||
|645|COMDigit9Hgt|COMDigit9Hgt|Num|8|BEST|11,471|422|591|||
|646|COMDigit9NormHt|COMDigit9NormHt|Num|8|BEST|11,471|9,993|663|||
|647|COMDigit9Outside|COMDigit9Outside|Num|8|BEST|11,471|4|591|||
|648|COMDigit9Angle|COMDigit9Angle|Num|8|BEST|11,471|10,809|591|||
|649|COMDigit9IdealDiff|COMDigit9IdealDiff|Num|8|BEST|11,471|10,809|591|||
|650|COMDigit9DistCircum|COMDigit9DistCircum|Num|8|BEST|11,471|8,786|591|||
|651|COMDigit9IsPersev|COMDigit9IsPersev|Num|8|BEST|11,471|3|591|||
|652|COMDigit10Seq|COMDigit10Seq|Num|8|BEST|11,471|17|710|||
|653|COMDigit10Strokes|COMDigit10Strokes|Num|8|BEST|11,471|8|710|||
|654|COMDigit10Time|COMDigit10Time|Num|8|BEST|11,471|1,724|710|||
|655|COMDigit10Len|COMDigit10Len|Num|8|BEST|11,471|10,761|710|||
|656|COMDigit10CentX|COMDigit10CentX|Num|8|BEST|11,471|3,016|710|||
|657|COMDigit10CentY|COMDigit10CentY|Num|8|BEST|11,471|3,980|710|||
|658|COMDigit10Width|COMDigit10Width|Num|8|BEST|11,471|328|710|||
|659|COMDigit10Hgt|COMDigit10Hgt|Num|8|BEST|11,471|357|710|||
|660|COMDigit10NormHt|COMDigit10NormHt|Num|8|BEST|11,471|9,812|786|||
|661|COMDigit10Outside|COMDigit10Outside|Num|8|BEST|11,471|4|710|||
|662|COMDigit10Angle|COMDigit10Angle|Num|8|BEST|11,471|10,686|710|||
|663|COMDigit10IdealDiff|COMDigit10IdealDiff|Num|8|BEST|11,471|10,686|710|||
|664|COMDigit10DistCircum|COMDigit10DistCircum|Num|8|BEST|11,471|8,726|710|||
|665|COMDigit10IsPersev|COMDigit10IsPersev|Num|8|BEST|11,471|3|710|||
|666|COMDigit11Seq|COMDigit11Seq|Num|8|BEST|11,471|16|683|||
|667|COMDigit11Strokes|COMDigit11Strokes|Num|8|BEST|11,471|8|683|||
|668|COMDigit11Time|COMDigit11Time|Num|8|BEST|11,471|1,797|683|||
|669|COMDigit11Len|COMDigit11Len|Num|8|BEST|11,471|10,788|683|||
|670|COMDigit11CentX|COMDigit11CentX|Num|8|BEST|11,471|3,015|683|||
|671|COMDigit11CentY|COMDigit11CentY|Num|8|BEST|11,471|3,772|683|||
|672|COMDigit11Width|COMDigit11Width|Num|8|BEST|11,471|292|683|||
|673|COMDigit11Hgt|COMDigit11Hgt|Num|8|BEST|11,471|363|683|||
|674|COMDigit11NormHt|COMDigit11NormHt|Num|8|BEST|11,471|9,861|756|||
|675|COMDigit11Outside|COMDigit11Outside|Num|8|BEST|11,471|4|683|||
|676|COMDigit11Angle|COMDigit11Angle|Num|8|BEST|11,471|10,716|683|||
|677|COMDigit11IdealDiff|COMDigit11IdealDiff|Num|8|BEST|11,471|10,716|683|||
|678|COMDigit11DistCircum|COMDigit11DistCircum|Num|8|BEST|11,471|8,616|683|||
|679|COMDigit11IsPersev|COMDigit11IsPersev|Num|8|BEST|11,471|3|683|||
|680|COMDigit12Seq|COMDigit12Seq|Num|8|BEST|11,471|17|728|||
|681|COMDigit12Strokes|COMDigit12Strokes|Num|8|BEST|11,471|8|728|||
|682|COMDigit12Time|COMDigit12Time|Num|8|BEST|11,471|2,274|728|||
|683|COMDigit12Len|COMDigit12Len|Num|8|BEST|11,471|10,743|728|||
|684|COMDigit12CentX|COMDigit12CentX|Num|8|BEST|11,471|3,171|728|||
|685|COMDigit12CentY|COMDigit12CentY|Num|8|BEST|11,471|3,661|728|||
|686|COMDigit12Width|COMDigit12Width|Num|8|BEST|11,471|401|728|||
|687|COMDigit12Hgt|COMDigit12Hgt|Num|8|BEST|11,471|322|728|||
|688|COMDigit12NormHt|COMDigit12NormHt|Num|8|BEST|11,471|9,860|803|||
|689|COMDigit12Outside|COMDigit12Outside|Num|8|BEST|11,471|4|728|||
|690|COMDigit12Angle|COMDigit12Angle|Num|8|BEST|11,471|10,669|728|||
|691|COMDigit12IdealDiff|COMDigit12IdealDiff|Num|8|BEST|11,471|10,669|728|||
|692|COMDigit12DistCircum|COMDigit12DistCircum|Num|8|BEST|11,471|8,316|728|||
|693|COMDigit12IsPersev|COMDigit12IsPersev|Num|8|BEST|11,471|3|728|||
|694|COMHooklet1DigitCode|COMHooklet1DigitCode|Num|8|BEST|11,471|17|1,069|||
|695|COMHooklet1Type|COMHooklet1Type|Num|8|BEST|11,471|4|1,069|||
|696|COMHooklet1Length|COMHooklet1Length|Num|8|BEST|11,471|3,831|1,069|||
|697|COMHooklet1AvgSpeed|COMHooklet1AvgSpeed|Num|8|BEST|11,471|4,724|1,069|||
|698|COMHooklet1LengthPct|COMHooklet1LengthPct|Num|8|BEST|11,471|10,402|1,069|||
|699|COMHooklet1DistToNextStroke|COMHooklet1DistToNextStroke|Num|8|BEST|11,471|7,327|1,069|||
|700|COMHooklet1Slope|COMHooklet1Slope|Num|8|BEST|11,471|3,880|1,069|||
|701|COMHooklet1PtsTo|COMHooklet1PtsTo|Num|8|BEST|11,471|24|1,069|||
|702|COMHooklet2DigitCode|COMHooklet2DigitCode|Num|8|BEST|11,471|17|2,202|||
|703|COMHooklet2Type|COMHooklet2Type|Num|8|BEST|11,471|4|2,202|||
|704|COMHooklet2Length|COMHooklet2Length|Num|8|BEST|11,471|3,303|2,202|||
|705|COMHooklet2AvgSpeed|COMHooklet2AvgSpeed|Num|8|BEST|11,471|4,067|2,202|||
|706|COMHooklet2LengthPct|COMHooklet2LengthPct|Num|8|BEST|11,471|9,269|2,202|||
|707|COMHooklet2DistToNextStroke|COMHooklet2DistToNextStroke|Num|8|BEST|11,471|6,411|2,202|||
|708|COMHooklet2Slope|COMHooklet2Slope|Num|8|BEST|11,471|3,619|2,202|||
|709|COMHooklet2PtsTo|COMHooklet2PtsTo|Char|9|$|11,471|25|2,202|||
|710|COMHooklet3DigitCode|COMHooklet3DigitCode|Num|8|BEST|11,471|17|3,633|||
|711|COMHooklet3Type|COMHooklet3Type|Num|8|BEST|11,471|4|3,633|||
|712|COMHooklet3Length|COMHooklet3Length|Num|8|BEST|11,471|2,972|3,633|||
|713|COMHooklet3AvgSpeed|COMHooklet3AvgSpeed|Num|8|BEST|11,471|3,668|3,633|||
|714|COMHooklet3LengthPct|COMHooklet3LengthPct|Num|8|BEST|11,471|7,838|3,633|||
|715|COMHooklet3DistToNextStroke|COMHooklet3DistToNextStroke|Num|8|BEST|11,471|5,638|3,633|||
|716|COMHooklet3Slope|COMHooklet3Slope|Num|8|BEST|11,471|3,135|3,633|||
|717|COMHooklet3PtsTo|COMHooklet3PtsTo|Num|8|BEST|11,469|24|3,633|||
|718|COMHooklet4DigitCode|COMHooklet4DigitCode|Num|8|BEST|11,471|17|5,447|||
|719|COMHooklet4Type|COMHooklet4Type|Num|8|BEST|11,471|4|5,447|||
|720|COMHooklet4Length|COMHooklet4Length|Num|8|BEST|11,471|2,420|5,447|||
|721|COMHooklet4AvgSpeed|COMHooklet4AvgSpeed|Num|8|BEST|11,471|2,989|5,447|||
|722|COMHooklet4LengthPct|COMHooklet4LengthPct|Num|8|BEST|11,471|6,024|5,447|||
|723|COMHooklet4DistToNextStroke|COMHooklet4DistToNextStroke|Num|8|BEST|11,471|4,573|5,447|||
|724|COMHooklet4Slope|COMHooklet4Slope|Num|8|BEST|11,471|2,496|5,447|||
|725|COMHooklet4PtsTo|COMHooklet4PtsTo|Num|8|BEST|11,470|24|5,447|||
|726|COMHooklet5DigitCode|COMHooklet5DigitCode|Num|8|BEST|11,471|17|7,240|||
|727|COMHooklet5Type|COMHooklet5Type|Num|8|BEST|11,471|4|7,240|||
|728|COMHooklet5Length|COMHooklet5Length|Num|8|BEST|11,471|1,888|7,240|||
|729|COMHooklet5AvgSpeed|COMHooklet5AvgSpeed|Num|8|BEST|11,471|2,341|7,240|||
|730|COMHooklet5LengthPct|COMHooklet5LengthPct|Num|8|BEST|11,471|4,231|7,240|||
|731|COMHooklet5DistToNextStroke|COMHooklet5DistToNextStroke|Num|8|BEST|11,471|3,374|7,240|||
|732|COMHooklet5Slope|COMHooklet5Slope|Num|8|BEST|11,471|1,884|7,240|||
|733|COMHooklet5PtsTo|COMHooklet5PtsTo|Num|8|BEST|11,470|23|7,240|||
|734|COMHooklet6DigitCode|COMHooklet6DigitCode|Num|8|BEST|11,471|17|8,672|||
|735|COMHooklet6Type|COMHooklet6Type|Num|8|BEST|11,471|4|8,672|||
|736|COMHooklet6Length|COMHooklet6Length|Num|8|BEST|11,471|1,314|8,672|||
|737|COMHooklet6AvgSpeed|COMHooklet6AvgSpeed|Num|8|BEST|11,471|1,629|8,672|||
|738|COMHooklet6LengthPct|COMHooklet6LengthPct|Num|8|BEST|11,471|2,800|8,672|||
|739|COMHooklet6DistToNextStroke|COMHooklet6DistToNextStroke|Num|8|BEST|11,471|2,329|8,672|||
|740|COMHooklet6Slope|COMHooklet6Slope|Num|8|BEST|11,471|1,330|8,672|||
|741|COMHooklet6PtsTo|COMHooklet6PtsTo|Num|8|BEST|11,471|23|8,672|||
|742|COMHooklet7DigitCode|COMHooklet7DigitCode|Num|8|BEST|11,471|17|9,689|||
|743|COMHooklet7Type|COMHooklet7Type|Num|8|BEST|11,471|4|9,689|||
|744|COMHooklet7Length|COMHooklet7Length|Num|8|BEST|11,471|925|9,689|||
|745|COMHooklet7AvgSpeed|COMHooklet7AvgSpeed|Num|8|BEST|11,471|1,150|9,689|||
|746|COMHooklet7LengthPct|COMHooklet7LengthPct|Num|8|BEST|11,471|1,783|9,689|||
|747|COMHooklet7DistToNextStroke|COMHooklet7DistToNextStroke|Num|8|BEST|11,471|1,555|9,689|||
|748|COMHooklet7Slope|COMHooklet7Slope|Num|8|BEST|11,471|922|9,689|||
|749|COMHooklet7PtsTo|COMHooklet7PtsTo|Char|9|$|11,471|25|9,689|||
|750|COMHooklet8DigitCode|COMHooklet8DigitCode|Num|8|BEST|11,471|17|10,411|||
|751|COMHooklet8Type|COMHooklet8Type|Num|8|BEST|11,471|4|10,411|||
|752|COMHooklet8Length|COMHooklet8Length|Num|8|BEST|11,471|607|10,411|||
|753|COMHooklet8AvgSpeed|COMHooklet8AvgSpeed|Num|8|BEST|11,471|739|10,411|||
|754|COMHooklet8LengthPct|COMHooklet8LengthPct|Num|8|BEST|11,471|1,062|10,411|||
|755|COMHooklet8DistToNextStroke|COMHooklet8DistToNextStroke|Num|8|BEST|11,471|965|10,411|||
|756|COMHooklet8Slope|COMHooklet8Slope|Num|8|BEST|11,471|577|10,411|||
|757|COMHooklet8PtsTo|COMHooklet8PtsTo|Num|8|BEST|11,471|23|10,411|||
|758|COMHooklet9DigitCode|COMHooklet9DigitCode|Num|8|BEST|11,471|17|10,878|||
|759|COMHooklet9Type|COMHooklet9Type|Num|8|BEST|11,471|4|10,878|||
|760|COMHooklet9Length|COMHooklet9Length|Num|8|BEST|11,471|337|10,878|||
|761|COMHooklet9AvgSpeed|COMHooklet9AvgSpeed|Num|8|BEST|11,471|411|10,878|||
|762|COMHooklet9LengthPct|COMHooklet9LengthPct|Num|8|BEST|11,471|595|10,878|||
|763|COMHooklet9DistToNextStroke|COMHooklet9DistToNextStroke|Num|8|BEST|11,471|554|10,878|||
|764|COMHooklet9Slope|COMHooklet9Slope|Num|8|BEST|11,471|328|10,878|||
|765|COMHooklet9PtsTo|COMHooklet9PtsTo|Char|9|$|11,471|24|10,878|||
|766|COMHooklet10DigitCode|COMHooklet10DigitCode|Num|8|BEST|11,471|17|11,167|||
|767|COMHooklet10Type|COMHooklet10Type|Num|8|BEST|11,471|4|11,167|||
|768|COMHooklet10Length|COMHooklet10Length|Num|8|BEST|11,471|200|11,167|||
|769|COMHooklet10AvgSpeed|COMHooklet10AvgSpeed|Num|8|BEST|11,471|247|11,167|||
|770|COMHooklet10LengthPct|COMHooklet10LengthPct|Num|8|BEST|11,471|306|11,167|||
|771|COMHooklet10DistToNextStroke|COMHooklet10DistToNextStroke|Num|8|BEST|11,471|291|11,167|||
|772|COMHooklet10Slope|COMHooklet10Slope|Num|8|BEST|11,471|196|11,167|||
|773|COMHooklet10PtsTo|COMHooklet10PtsTo|Num|8|BEST|11,471|21|11,167|||
|774|COMHooklet11DigitCode|COMHooklet11DigitCode|Num|8|BEST|11,471|14|11,330|||
|775|COMHooklet11Type|COMHooklet11Type|Num|8|BEST|11,471|4|11,330|||
|776|COMHooklet11Length|COMHooklet11Length|Num|8|BEST|11,471|107|11,330|||
|777|COMHooklet11AvgSpeed|COMHooklet11AvgSpeed|Num|8|BEST|11,471|124|11,330|||
|778|COMHooklet11LengthPct|COMHooklet11LengthPct|Num|8|BEST|11,471|143|11,330|||
|779|COMHooklet11DistToNextStroke|COMHooklet11DistToNextStroke|Num|8|BEST|11,471|142|11,330|||
|780|COMHooklet11Slope|COMHooklet11Slope|Num|8|BEST|11,471|108|11,330|||
|781|COMHooklet11PtsTo|COMHooklet11PtsTo|Char|9|$|11,471|20|11,330|||
|782|COMHooklet12DigitCode|COMHooklet12DigitCode|Num|8|BEST|11,471|15|11,406|||
|783|COMHooklet12Type|COMHooklet12Type|Num|8|BEST|11,471|4|11,406|||
|784|COMHooklet12Length|COMHooklet12Length|Num|8|BEST|11,471|52|11,406|||
|785|COMHooklet12AvgSpeed|COMHooklet12AvgSpeed|Num|8|BEST|11,471|57|11,406|||
|786|COMHooklet12LengthPct|COMHooklet12LengthPct|Num|8|BEST|11,471|67|11,406|||
|787|COMHooklet12DistToNextStroke|COMHooklet12DistToNextStroke|Num|8|BEST|11,471|67|11,406|||
|788|COMHooklet12Slope|COMHooklet12Slope|Num|8|BEST|11,471|56|11,406|||
|789|COMHooklet12PtsTo|COMHooklet12PtsTo|Num|8|BEST|11,471|17|11,406|||
|790|COMHooklet13DigitCode|COMHooklet13DigitCode|Num|8|BEST|11,471|11|11,441|||
|791|COMHooklet13Type|COMHooklet13Type|Num|8|BEST|11,471|4|11,441|||
|792|COMHooklet13Length|COMHooklet13Length|Num|8|BEST|11,471|27|11,441|||
|793|COMHooklet13AvgSpeed|COMHooklet13AvgSpeed|Num|8|BEST|11,471|31|11,441|||
|794|COMHooklet13LengthPct|COMHooklet13LengthPct|Num|8|BEST|11,471|32|11,441|||
|795|COMHooklet13DistToNextStroke|COMHooklet13DistToNextStroke|Num|8|BEST|11,471|32|11,441|||
|796|COMHooklet13Slope|COMHooklet13Slope|Num|8|BEST|11,471|27|11,441|||
|797|COMHooklet13PtsTo|COMHooklet13PtsTo|Char|9|$|11,471|14|11,441|||
|798|COMHooklet14DigitCode|COMHooklet14DigitCode|Num|8|BEST|11,471|10|11,456|||
|799|COMHooklet14Type|COMHooklet14Type|Num|8|BEST|11,471|4|11,456|||
|800|COMHooklet14Length|COMHooklet14Length|Num|8|BEST|11,471|17|11,456|||
|801|COMHooklet14AvgSpeed|COMHooklet14AvgSpeed|Num|8|BEST|11,471|17|11,456|||
|802|COMHooklet14LengthPct|COMHooklet14LengthPct|Num|8|BEST|11,471|17|11,456|||
|803|COMHooklet14DistToNextStroke|COMHooklet14DistToNextStroke|Num|8|BEST|11,471|17|11,456|||
|804|COMHooklet14Slope|COMHooklet14Slope|Num|8|BEST|11,471|16|11,456|||
|805|COMHooklet14PtsTo|COMHooklet14PtsTo|Num|8|BEST|11,471|10|11,456|||
|806|COMHooklet15DigitCode|COMHooklet15DigitCode|Num|8|BEST|11,471|8|11,464|||
|807|COMHooklet15Type|COMHooklet15Type|Num|8|BEST|11,471|4|11,464|||
|808|COMHooklet15Length|COMHooklet15Length|Num|8|BEST|11,471|9|11,464|||
|809|COMHooklet15AvgSpeed|COMHooklet15AvgSpeed|Num|8|BEST|11,471|9|11,464|||
|810|COMHooklet15LengthPct|COMHooklet15LengthPct|Num|8|BEST|11,471|9|11,464|||
|811|COMHooklet15DistToNextStroke|COMHooklet15DistToNextStroke|Num|8|BEST|11,471|9|11,464|||
|812|COMHooklet15Slope|COMHooklet15Slope|Num|8|BEST|11,471|9|11,464|||
|813|COMHooklet15PtsTo|COMHooklet15PtsTo|Num|8|BEST|11,471|9|11,464|||
|814|COMCenterDotStrokeNum|COMCenterDotStrokeNum|Num|8|BEST|11,471|11|91|||
|815|COMCenterDotStrokeLen|COMCenterDotStrokeLen|Num|8|BEST|11,471|6,190|91|||
|816|COMTickMarkNum|COMTickMarkNum|Num|8|BEST|11,471|28|91|||
|817|COMTickMarkStrokeLen|COMTickMarkStrokeLen|Num|8|BEST|11,471|405|91|||
|818|COMTextStrokeNum|COMTextStrokeNum|Num|8|BEST|11,471|35|91|||
|819|COMTextStrokeLen|COMTextStrokeLen|Num|8|BEST|11,471|434|91|||
|820|COMSpokesStrokeNum|COMSpokesStrokeNum|Num|8|BEST|11,471|17|91|||
|821|COMSpokesStrokeLen|COMSpokesStrokeLen|Num|8|BEST|11,471|72|91|||
|822|COMOver12StrokeNum|COMOver12StrokeNum|Num|8|BEST|11,471|21|91|||
|823|COMOver12StrokeLen|COMOver12StrokeLen|Num|8|BEST|11,471|30|91|||
|824|COMTenElevenStroke|COMTenElevenStroke|Num|8|BEST|11,471|4|91|||
|825|COMClockFaceNonClockFaceLatency|COMClockFaceNonClockFaceLatency|Num|8|BEST|11,471|4,019|199|||
|826|COMCFNonCFTerminator|COMCFNonCFTerminator|Char|9|$|11,471|24|199|||
|827|COMClockFaceNonClockFaceNoNoiseL|COMClockFaceNonClockFaceNoNoiseLatency|Num|8|BEST|11,471|4,110|199|||
|828|COMCFNonCFNoNoiseTerminator|COMCFNonCFNoNoiseTerminator|Char|9|$|11,471|26|199|||
|829|COMPreFirstHandLatency|COMPreFirstHandLatency|Num|8|BEST|11,471|5,890|619|||
|830|COMPreFirstHandInitiator|COMPreFirstHandInitiator|Char|9|$|11,471|25|619|||
|831|COMPreFirstHandNoNoiseLatency|COMPreFirstHandNoNoiseLatency|Num|8|BEST|11,471|6,544|621|||
|832|COMPreFirstHandNoNoiseInitiator|COMPreFirstHandNoNoiseInitiator|Char|9|$|11,471|26|621|||
|833|COMPreSecondHandLatency|COMPreSecondHandLatency|Num|8|BEST|11,471|3,210|793|||
|834|COMPreSecondHandInitiator|COMPreSecondHandInitiator|Char|9|$|11,471|25|793|||
|835|COMPreSecondHandNoNoiseLatency|COMPreSecondHandNoNoiseLatency|Num|8|BEST|11,471|3,484|793|||
|836|COMPreSecondHandNoNoiseInitiator|COMPreSecondHandNoNoiseInitiator|Char|9|$|11,471|24|793|||
|837|COMPreCenterDotLatency|COMPreCenterDotLatency|Num|8|BEST|11,471|3,636|4,915|||
|838|COMPreCenterDotInitiator|COMPreCenterDotInitiator|Char|9|$|11,471|27|4,915|||
|839|COMPreCenterDotNoNoiseLatency|COMPreCenterDotNoNoiseLatency|Num|8|BEST|11,471|3,820|4,915|||
|840|COMPreCenterDotNoNoiseInitiator|COMPreCenterDotNoNoiseInitiator|Char|9|$|11,471|26|4,915|||
|841|COMPostCenterDotLatency|COMPostCenterDotLatency|Num|8|BEST|11,471|3,490|5,503|||
|842|COMPostCenterDotTerminator|COMPostCenterDotTerminator|Char|9|$|11,471|26|5,503|||
|843|COMPostCenterDotNoNoiseLatency|COMPostCenterDotNoNoiseLatency|Num|8|BEST|11,471|3,588|5,517|||
|844|COMPostCenterDotNoNoiseTerminato|COMPostCenterDotNoNoiseTerminator|Char|9|$|11,471|26|5,517|||
|845|COMInterDigitLatency|COMInterDigitLatency|Num|8|BEST|11,471|8,866|91|||
|846|COMInterDigitIntervalCount|COMInterDigitIntervalCount|Num|8|BEST|11,471|20|91|||
|847|COMAnchorDigitLatency|COMAnchorDigitLatency|Num|8|BEST|11,471|2,328|8,191|||
|848|COMAnchorLatencyIntervalCount|COMAnchorLatencyIntervalCount|Num|8|BEST|11,471|7|91|||
|849|COMTenElevenStrokeLatency|COMTenElevenStrokeLatency|Num|8|BEST|11,471|211|11,259|||
|850|COMHandsXdOutNumStrokes|COMHandsXdOutNumStrokes|Num|8|BEST|11,471|21|91|||
|851|COMHandsXdOutTotStrokeLen|COMHandsXdOutTotStrokeLen|Num|8|BEST|11,471|991|91|||
|852|COMDigitsXOutNumStrokes|COMDigitsXOutNumStrokes|Num|8|BEST|11,471|49|91|||
|853|COMDigitsXdOutTotStrokeLen|COMDigitsXdOutTotStrokeLen|Num|8|BEST|11,471|1,598|91|||
|854|COMPersevDigitsXdOutNumStrokes|COMPersevDigitsXdOutNumStrokes|Num|8|BEST|11,471|6|91|||
|855|COMPersevDigitsXdOutTotStrokeLen|COMPersevDigitsXdOutTotStrokeLen|Num|8|BEST|11,471|36|91|||
|856|COMPersevDigitsCountQ1|COMPersevDigitsCountQ1|Num|8|BEST|11,471|4|91|||
|857|COMPersevDigitsCountQ2|COMPersevDigitsCountQ2|Num|8|BEST|11,471|6|91|||
|858|COMPersevDigitsCountQ3|COMPersevDigitsCountQ3|Num|8|BEST|11,471|4|91|||
|859|COMPersevDigitsCountQ4|COMPersevDigitsCountQ4|Num|8|BEST|11,471|4|91|||
|860|COMHandSplitCount|COMHandSplitCount|Num|8|BEST|11,471|8|91|||
|861|COMDigitSplitCount|COMDigitSplitCount|Num|8|BEST|11,471|6|91|||
|862|COMClockBFCircleRadius|COMClockBFCircleRadius|Num|8|BEST|11,471|11,298|173|||
|863|COMClockBFCircCentX|COMClockBFCircCentX|Num|8|BEST|11,471|11,298|173|||
|864|COMClockBFCircCentY|COMClockBFCircCentY|Num|8|BEST|11,471|11,298|173|||
|865|COMCFBFCircInBounds|COMCFBFCircInBounds|Num|8|BEST|11,471|4|173|||
|866|COMPCF1CircleRadius|COMPCF1CircleRadius|Num|8|BEST|11,471|24|11,449|||
|867|COMPCF1CFRadiusDiff|COMPCF1CFRadiusDiff|Num|8|BEST|11,471|24|11,449|||
|868|COMPCF1CircCentX|COMPCF1CircCentX|Num|8|BEST|11,471|24|11,449|||
|869|COMPCF1CircCentY|COMPCF1CircCentY|Num|8|BEST|11,471|24|11,449|||
|870|COMPCF1LocnDiffX|COMPCF1LocnDiffX|Num|8|BEST|11,471|24|11,449|||
|871|COMPCF1LocnDiffY|COMPCF1LocnDiffY|Num|8|BEST|11,471|24|11,449|||
|872|COMPCF1PageQuad|COMPCF1PageQuad|Num|8|BEST|11,471|4|11,449|||
|873|COMPCF1CircQuad|COMPCF1CircQuad|Num|8|BEST|11,471|5|11,449|||
|874|COMPCF1InBounds|COMPCF1InBounds|Num|8|BEST|11,471|3|11,449|||
|875|COMPCF2CircleRadius|COMPCF2CircleRadius|Num|8|BEST|11,471|2|11,471|||
|876|COMPCF2CFRadiusDiff|COMPCF2CFRadiusDiff|Num|8|BEST|11,471|2|11,471|||
|877|COMPCF2CircCentX|COMPCF2CircCentX|Num|8|BEST|11,471|2|11,471|||
|878|COMPCF2CircCentY|COMPCF2CircCentY|Num|8|BEST|11,471|2|11,471|||
|879|COMPCF2LocnDiffX|COMPCF2LocnDiffX|Num|8|BEST|11,471|2|11,471|||
|880|COMPCF2LocnDiffY|COMPCF2LocnDiffY|Num|8|BEST|11,471|2|11,471|||
|881|COMPCF2PageQuad|COMPCF2PageQuad|Num|8|BEST|11,471|2|11,471|||
|882|COMPCF2CircQuad|COMPCF2CircQuad|Num|8|BEST|11,471|2|11,471|||
|883|COMPCF2InBounds|COMPCF2InBounds|Num|8|BEST|11,471|2|11,471|||
|884|COMTotInkTimeCC|COMTotInkTimeCC|Num|8|BEST|11,471|7,216|91|||
|885|COMInkLenTimeCCQ1|COMInkLenTimeCCQ1|Num|8|BEST|11,471|11,380|91|||
|886|COMInkLenTimeCCQ2|COMInkLenTimeCCQ2|Num|8|BEST|11,471|11,380|91|||
|887|COMInkLenTimeCCQ3|COMInkLenTimeCCQ3|Num|8|BEST|11,471|11,380|91|||
|888|COMInkLenTimeCCQ4|COMInkLenTimeCCQ4|Num|8|BEST|11,471|11,380|91|||
|889|COMTotInkTimeNoCC|COMTotInkTimeNoCC|Num|8|BEST|11,471|6,766|91|||
|890|COMInkLenTimeNoCCQ1|COMInkLenTimeNoCCQ1|Num|8|BEST|11,471|11,378|91|||
|891|COMInkLenTimeNoCCQ2|COMInkLenTimeNoCCQ2|Num|8|BEST|11,471|11,378|91|||
|892|COMInkLenTimeNoCCQ3|COMInkLenTimeNoCCQ3|Num|8|BEST|11,471|11,378|91|||
|893|COMInkLenTimeNoCCQ4|COMInkLenTimeNoCCQ4|Num|8|BEST|11,471|11,378|91|||
|894|COMTotInkLengthCC|COMTotInkLengthCC|Num|8|BEST|11,471|11,380|91|||
|895|COMInkTimeByLenCCQ1|COMInkTimeByLenCCQ1|Num|8|BEST|11,471|1,077|91|||
|896|COMInkTimeByLenCCQ2|COMInkTimeByLenCCQ2|Num|8|BEST|11,471|2,731|91|||
|897|COMInkTimeByLenCCQ3|COMInkTimeByLenCCQ3|Num|8|BEST|11,471|3,302|91|||
|898|COMInkTimeByLenCCQ4|COMInkTimeByLenCCQ4|Num|8|BEST|11,471|4,217|91|||
|899|COMTotInkLengthNoCC|COMTotInkLengthNoCC|Num|8|BEST|11,471|11,378|91|||
|900|COMInkTimeByLenNoCCQ1|COMInkTimeByLenNoCCQ1|Num|8|BEST|11,471|2,403|91|||
|901|COMInkTimeByLenNoCCQ2|COMInkTimeByLenNoCCQ2|Num|8|BEST|11,471|2,287|91|||
|902|COMInkTimeByLenNoCCQ3|COMInkTimeByLenNoCCQ3|Num|8|BEST|11,471|2,594|91|||
|903|COMInkTimeByLenNoCCQ4|COMInkTimeByLenNoCCQ4|Num|8|BEST|11,471|3,104|91|||
|904|COMNoiseHistoZero|COMNoiseHistoZero|Num|8|BEST|11,471|11|91|||
|905|COMNoiseHistoPt3|COMNoiseHistoPt3|Num|8|BEST|11,471|18|91|||
|906|COMNoiseHistoPt7|COMNoiseHistoPt7|Num|8|BEST|11,471|16|91|||
|907|COMNoiseHistoAbovePt7|COMNoiseHistoAbovePt7|Num|8|BEST|11,471|28|91|||
|908|COMNoiseHistoZeroQ1|COMNoiseHistoZeroQ1|Num|8|BEST|11,471|8|91|||
|909|COMNoiseHistoPt3Q1|COMNoiseHistoPt3Q1|Num|8|BEST|11,471|12|91|||
|910|COMNoiseHistoPt7Q1|COMNoiseHistoPt7Q1|Num|8|BEST|11,471|15|91|||
|911|COMNoiseHistoAbovePt7Q1|COMNoiseHistoAbovePt7Q1|Num|8|BEST|11,471|16|91|||
|912|COMNoiseHistoZeroQ2|COMNoiseHistoZeroQ2|Num|8|BEST|11,471|8|91|||
|913|COMNoiseHistoPt3Q2|COMNoiseHistoPt3Q2|Num|8|BEST|11,471|13|91|||
|914|COMNoiseHistoPt7Q2|COMNoiseHistoPt7Q2|Num|8|BEST|11,471|11|91|||
|915|COMNoiseHistoAbovePt7Q2|COMNoiseHistoAbovePt7Q2|Num|8|BEST|11,471|16|91|||
|916|COMNoiseHistoZeroQ3|COMNoiseHistoZeroQ3|Num|8|BEST|11,471|5|91|||
|917|COMNoiseHistoPt3Q3|COMNoiseHistoPt3Q3|Num|8|BEST|11,471|9|91|||
|918|COMNoiseHistoPt7Q3|COMNoiseHistoPt7Q3|Num|8|BEST|11,471|7|91|||
|919|COMNoiseHistoAbovePt7Q3|COMNoiseHistoAbovePt7Q3|Num|8|BEST|11,471|12|91|||
|920|COMNoiseHistoZeroQ4|COMNoiseHistoZeroQ4|Num|8|BEST|11,471|8|91|||
|921|COMNoiseHistoPt3Q4|COMNoiseHistoPt3Q4|Num|8|BEST|11,471|9|91|||
|922|COMNoiseHistoPt7Q4|COMNoiseHistoPt7Q4|Num|8|BEST|11,471|8|91|||
|923|COMNoiseHistoAbovePt7Q4|COMNoiseHistoAbovePt7Q4|Num|8|BEST|11,471|10|91|||
|924|COMDigit1PSeq|COMDigit1PSeq|Num|8|BEST|11,471|17|11,380|||
|925|COMDigit1PStrokes|COMDigit1PStrokes|Num|8|BEST|11,471|5|11,380|||
|926|COMDigit1PTime|COMDigit1PTime|Num|8|BEST|11,471|57|11,380|||
|927|COMDigit1PLen|COMDigit1PLen|Num|8|BEST|11,471|93|11,380|||
|928|COMDigit1PCentX|COMDigit1PCentX|Num|8|BEST|11,471|91|11,380|||
|929|COMDigit1PCentY|COMDigit1PCentY|Num|8|BEST|11,471|93|11,380|||
|930|COMDigit1PWidth|COMDigit1PWidth|Num|8|BEST|11,471|60|11,380|||
|931|COMDigit1PHgt|COMDigit1PHgt|Num|8|BEST|11,471|67|11,380|||
|932|COMDigit1PNormHt|COMDigit1PNormHt|Num|8|BEST|11,471|90|11,383|||
|933|COMDigit1POutside|COMDigit1POutside|Num|8|BEST|11,471|4|11,380|||
|934|COMDigit1PAngle|COMDigit1PAngle|Num|8|BEST|11,471|91|11,380|||
|935|COMDigit1PIdealDiff|COMDigit1PIdealDiff|Num|8|BEST|11,471|91|11,380|||
|936|COMDigit1PDistCircum|COMDigit1PDistCircum|Num|8|BEST|11,471|91|11,380|||
|937|COMDigit1PIsPersev|COMDigit1PIsPersev|Num|8|BEST|11,471|4|11,380|||
|938|COMDigit2PSeq|COMDigit2PSeq|Num|8|BEST|11,471|15|11,439|||
|939|COMDigit2PStrokes|COMDigit2PStrokes|Num|8|BEST|11,471|4|11,439|||
|940|COMDigit2PTime|COMDigit2PTime|Num|8|BEST|11,471|27|11,439|||
|941|COMDigit2PLen|COMDigit2PLen|Num|8|BEST|11,471|34|11,439|||
|942|COMDigit2PCentX|COMDigit2PCentX|Num|8|BEST|11,471|34|11,439|||
|943|COMDigit2PCentY|COMDigit2PCentY|Num|8|BEST|11,471|34|11,439|||
|944|COMDigit2PWidth|COMDigit2PWidth|Num|8|BEST|11,471|32|11,439|||
|945|COMDigit2PHgt|COMDigit2PHgt|Num|8|BEST|11,471|32|11,439|||
|946|COMDigit2PNormHt|COMDigit2PNormHt|Num|8|BEST|11,471|33|11,440|||
|947|COMDigit2POutside|COMDigit2POutside|Num|8|BEST|11,471|4|11,439|||
|948|COMDigit2PAngle|COMDigit2PAngle|Num|8|BEST|11,471|34|11,439|||
|949|COMDigit2PIdealDiff|COMDigit2PIdealDiff|Num|8|BEST|11,471|34|11,439|||
|950|COMDigit2PDistCircum|COMDigit2PDistCircum|Num|8|BEST|11,471|34|11,439|||
|951|COMDigit2PIsPersev|COMDigit2PIsPersev|Num|8|BEST|11,471|4|11,439|||
|952|COMDigit3PSeq|COMDigit3PSeq|Num|8|BEST|11,471|15|11,445|||
|953|COMDigit3PStrokes|COMDigit3PStrokes|Num|8|BEST|11,471|5|11,445|||
|954|COMDigit3PTime|COMDigit3PTime|Num|8|BEST|11,471|25|11,445|||
|955|COMDigit3PLen|COMDigit3PLen|Num|8|BEST|11,471|28|11,445|||
|956|COMDigit3PCentX|COMDigit3PCentX|Num|8|BEST|11,471|27|11,445|||
|957|COMDigit3PCentY|COMDigit3PCentY|Num|8|BEST|11,471|28|11,445|||
|958|COMDigit3PWidth|COMDigit3PWidth|Num|8|BEST|11,471|27|11,445|||
|959|COMDigit3PHgt|COMDigit3PHgt|Num|8|BEST|11,471|26|11,445|||
|960|COMDigit3PNormHt|COMDigit3PNormHt|Num|8|BEST|11,471|28|11,445|||
|961|COMDigit3POutside|COMDigit3POutside|Num|8|BEST|11,471|4|11,445|||
|962|COMDigit3PAngle|COMDigit3PAngle|Num|8|BEST|11,471|28|11,445|||
|963|COMDigit3PIdealDiff|COMDigit3PIdealDiff|Num|8|BEST|11,471|28|11,445|||
|964|COMDigit3PDistCircum|COMDigit3PDistCircum|Num|8|BEST|11,471|28|11,445|||
|965|COMDigit3PIsPersev|COMDigit3PIsPersev|Num|8|BEST|11,471|4|11,445|||
|966|COMDigit4PSeq|COMDigit4PSeq|Num|8|BEST|11,471|13|11,454|||
|967|COMDigit4PStrokes|COMDigit4PStrokes|Num|8|BEST|11,471|7|11,454|||
|968|COMDigit4PTime|COMDigit4PTime|Num|8|BEST|11,471|18|11,454|||
|969|COMDigit4PLen|COMDigit4PLen|Num|8|BEST|11,471|19|11,454|||
|970|COMDigit4PCentX|COMDigit4PCentX|Num|8|BEST|11,471|18|11,454|||
|971|COMDigit4PCentY|COMDigit4PCentY|Num|8|BEST|11,471|19|11,454|||
|972|COMDigit4PWidth|COMDigit4PWidth|Num|8|BEST|11,471|17|11,454|||
|973|COMDigit4PHgt|COMDigit4PHgt|Num|8|BEST|11,471|18|11,454|||
|974|COMDigit4PNormHt|COMDigit4PNormHt|Num|8|BEST|11,471|19|11,454|||
|975|COMDigit4POutside|COMDigit4POutside|Num|8|BEST|11,471|4|11,454|||
|976|COMDigit4PAngle|COMDigit4PAngle|Num|8|BEST|11,471|19|11,454|||
|977|COMDigit4PIdealDiff|COMDigit4PIdealDiff|Num|8|BEST|11,471|19|11,454|||
|978|COMDigit4PDistCircum|COMDigit4PDistCircum|Num|8|BEST|11,471|19|11,454|||
|979|COMDigit4PIsPersev|COMDigit4PIsPersev|Num|8|BEST|11,471|4|11,454|||
|980|COMDigit5PSeq|COMDigit5PSeq|Num|8|BEST|11,471|16|11,440|||
|981|COMDigit5PStrokes|COMDigit5PStrokes|Num|8|BEST|11,471|6|11,440|||
|982|COMDigit5PTime|COMDigit5PTime|Num|8|BEST|11,471|33|11,440|||
|983|COMDigit5PLen|COMDigit5PLen|Num|8|BEST|11,471|33|11,440|||
|984|COMDigit5PCentX|COMDigit5PCentX|Num|8|BEST|11,471|33|11,440|||
|985|COMDigit5PCentY|COMDigit5PCentY|Num|8|BEST|11,471|33|11,440|||
|986|COMDigit5PWidth|COMDigit5PWidth|Num|8|BEST|11,471|31|11,440|||
|987|COMDigit5PHgt|COMDigit5PHgt|Num|8|BEST|11,471|30|11,440|||
|988|COMDigit5PNormHt|COMDigit5PNormHt|Num|8|BEST|11,471|33|11,440|||
|989|COMDigit5POutside|COMDigit5POutside|Num|8|BEST|11,471|4|11,440|||
|990|COMDigit5PAngle|COMDigit5PAngle|Num|8|BEST|11,471|33|11,440|||
|991|COMDigit5PIdealDiff|COMDigit5PIdealDiff|Num|8|BEST|11,471|33|11,440|||
|992|COMDigit5PDistCircum|COMDigit5PDistCircum|Num|8|BEST|11,471|33|11,440|||
|993|COMDigit5PIsPersev|COMDigit5PIsPersev|Num|8|BEST|11,471|4|11,440|||
|994|COMDigit6PSeq|COMDigit6PSeq|Num|8|BEST|11,471|18|11,421|||
|995|COMDigit6PStrokes|COMDigit6PStrokes|Num|8|BEST|11,471|5|11,421|||
|996|COMDigit6PTime|COMDigit6PTime|Num|8|BEST|11,471|35|11,421|||
|997|COMDigit6PLen|COMDigit6PLen|Num|8|BEST|11,471|52|11,421|||
|998|COMDigit6PCentX|COMDigit6PCentX|Num|8|BEST|11,471|51|11,421|||
|999|COMDigit6PCentY|COMDigit6PCentY|Num|8|BEST|11,471|52|11,421|||
|1000|COMDigit6PWidth|COMDigit6PWidth|Num|8|BEST|11,471|43|11,421|||
|1001|COMDigit6PHgt|COMDigit6PHgt|Num|8|BEST|11,471|48|11,421|||
|1002|COMDigit6PNormHt|COMDigit6PNormHt|Num|8|BEST|11,471|50|11,423|||
|1003|COMDigit6POutside|COMDigit6POutside|Num|8|BEST|11,471|4|11,421|||
|1004|COMDigit6PAngle|COMDigit6PAngle|Num|8|BEST|11,471|51|11,421|||
|1005|COMDigit6PIdealDiff|COMDigit6PIdealDiff|Num|8|BEST|11,471|51|11,421|||
|1006|COMDigit6PDistCircum|COMDigit6PDistCircum|Num|8|BEST|11,471|51|11,421|||
|1007|COMDigit6PIsPersev|COMDigit6PIsPersev|Num|8|BEST|11,471|4|11,421|||
|1008|COMDigit7PSeq|COMDigit7PSeq|Num|8|BEST|11,471|13|11,452|||
|1009|COMDigit7PStrokes|COMDigit7PStrokes|Num|8|BEST|11,471|5|11,452|||
|1010|COMDigit7PTime|COMDigit7PTime|Num|8|BEST|11,471|19|11,452|||
|1011|COMDigit7PLen|COMDigit7PLen|Num|8|BEST|11,471|21|11,452|||
|1012|COMDigit7PCentX|COMDigit7PCentX|Num|8|BEST|11,471|21|11,452|||
|1013|COMDigit7PCentY|COMDigit7PCentY|Num|8|BEST|11,471|21|11,452|||
|1014|COMDigit7PWidth|COMDigit7PWidth|Num|8|BEST|11,471|20|11,452|||
|1015|COMDigit7PHgt|COMDigit7PHgt|Num|8|BEST|11,471|21|11,452|||
|1016|COMDigit7PNormHt|COMDigit7PNormHt|Num|8|BEST|11,471|20|11,453|||
|1017|COMDigit7POutside|COMDigit7POutside|Num|8|BEST|11,471|4|11,452|||
|1018|COMDigit7PAngle|COMDigit7PAngle|Num|8|BEST|11,471|21|11,452|||
|1019|COMDigit7PIdealDiff|COMDigit7PIdealDiff|Num|8|BEST|11,471|21|11,452|||
|1020|COMDigit7PDistCircum|COMDigit7PDistCircum|Num|8|BEST|11,471|21|11,452|||
|1021|COMDigit7PIsPersev|COMDigit7PIsPersev|Num|8|BEST|11,471|4|11,452|||
|1022|COMDigit8PSeq|COMDigit8PSeq|Num|8|BEST|11,471|14|11,446|||
|1023|COMDigit8PStrokes|COMDigit8PStrokes|Num|8|BEST|11,471|4|11,446|||
|1024|COMDigit8PTime|COMDigit8PTime|Num|8|BEST|11,471|23|11,446|||
|1025|COMDigit8PLen|COMDigit8PLen|Num|8|BEST|11,471|27|11,446|||
|1026|COMDigit8PCentX|COMDigit8PCentX|Num|8|BEST|11,471|27|11,446|||
|1027|COMDigit8PCentY|COMDigit8PCentY|Num|8|BEST|11,471|26|11,446|||
|1028|COMDigit8PWidth|COMDigit8PWidth|Num|8|BEST|11,471|23|11,446|||
|1029|COMDigit8PHgt|COMDigit8PHgt|Num|8|BEST|11,471|26|11,446|||
|1030|COMDigit8PNormHt|COMDigit8PNormHt|Num|8|BEST|11,471|27|11,446|||
|1031|COMDigit8POutside|COMDigit8POutside|Num|8|BEST|11,471|4|11,446|||
|1032|COMDigit8PAngle|COMDigit8PAngle|Num|8|BEST|11,471|27|11,446|||
|1033|COMDigit8PIdealDiff|COMDigit8PIdealDiff|Num|8|BEST|11,471|27|11,446|||
|1034|COMDigit8PDistCircum|COMDigit8PDistCircum|Num|8|BEST|11,471|27|11,446|||
|1035|COMDigit8PIsPersev|COMDigit8PIsPersev|Num|8|BEST|11,471|4|11,446|||
|1036|COMDigit9PSeq|COMDigit9PSeq|Num|8|BEST|11,471|13|11,435|||
|1037|COMDigit9PStrokes|COMDigit9PStrokes|Num|8|BEST|11,471|5|11,435|||
|1038|COMDigit9PTime|COMDigit9PTime|Num|8|BEST|11,471|31|11,435|||
|1039|COMDigit9PLen|COMDigit9PLen|Num|8|BEST|11,471|38|11,435|||
|1040|COMDigit9PCentX|COMDigit9PCentX|Num|8|BEST|11,471|38|11,435|||
|1041|COMDigit9PCentY|COMDigit9PCentY|Num|8|BEST|11,471|37|11,435|||
|1042|COMDigit9PWidth|COMDigit9PWidth|Num|8|BEST|11,471|34|11,435|||
|1043|COMDigit9PHgt|COMDigit9PHgt|Num|8|BEST|11,471|37|11,435|||
|1044|COMDigit9PNormHt|COMDigit9PNormHt|Num|8|BEST|11,471|38|11,435|||
|1045|COMDigit9POutside|COMDigit9POutside|Num|8|BEST|11,471|4|11,435|||
|1046|COMDigit9PAngle|COMDigit9PAngle|Num|8|BEST|11,471|38|11,435|||
|1047|COMDigit9PIdealDiff|COMDigit9PIdealDiff|Num|8|BEST|11,471|38|11,435|||
|1048|COMDigit9PDistCircum|COMDigit9PDistCircum|Num|8|BEST|11,471|38|11,435|||
|1049|COMDigit9PIsPersev|COMDigit9PIsPersev|Num|8|BEST|11,471|4|11,435|||
|1050|COMDigit10PSeq|COMDigit10PSeq|Num|8|BEST|11,471|19|11,342|||
|1051|COMDigit10PStrokes|COMDigit10PStrokes|Num|8|BEST|11,471|5|11,342|||
|1052|COMDigit10PTime|COMDigit10PTime|Num|8|BEST|11,471|128|11,342|||
|1053|COMDigit10PLen|COMDigit10PLen|Num|8|BEST|11,471|131|11,342|||
|1054|COMDigit10PCentX|COMDigit10PCentX|Num|8|BEST|11,471|130|11,342|||
|1055|COMDigit10PCentY|COMDigit10PCentY|Num|8|BEST|11,471|131|11,342|||
|1056|COMDigit10PWidth|COMDigit10PWidth|Num|8|BEST|11,471|98|11,342|||
|1057|COMDigit10PHgt|COMDigit10PHgt|Num|8|BEST|11,471|94|11,342|||
|1058|COMDigit10PNormHt|COMDigit10PNormHt|Num|8|BEST|11,471|129|11,343|||
|1059|COMDigit10POutside|COMDigit10POutside|Num|8|BEST|11,471|4|11,342|||
|1060|COMDigit10PAngle|COMDigit10PAngle|Num|8|BEST|11,471|131|11,342|||
|1061|COMDigit10PIdealDiff|COMDigit10PIdealDiff|Num|8|BEST|11,471|131|11,342|||
|1062|COMDigit10PDistCircum|COMDigit10PDistCircum|Num|8|BEST|11,471|131|11,342|||
|1063|COMDigit10PIsPersev|COMDigit10PIsPersev|Num|8|BEST|11,471|4|11,342|||
|1064|COMDigit11PSeq|COMDigit11PSeq|Num|8|BEST|11,471|18|11,378|||
|1065|COMDigit11PStrokes|COMDigit11PStrokes|Num|8|BEST|11,471|6|11,378|||
|1066|COMDigit11PTime|COMDigit11PTime|Num|8|BEST|11,471|90|11,378|||
|1067|COMDigit11PLen|COMDigit11PLen|Num|8|BEST|11,471|95|11,378|||
|1068|COMDigit11PCentX|COMDigit11PCentX|Num|8|BEST|11,471|94|11,378|||
|1069|COMDigit11PCentY|COMDigit11PCentY|Num|8|BEST|11,471|92|11,378|||
|1070|COMDigit11PWidth|COMDigit11PWidth|Num|8|BEST|11,471|68|11,378|||
|1071|COMDigit11PHgt|COMDigit11PHgt|Num|8|BEST|11,471|78|11,378|||
|1072|COMDigit11PNormHt|COMDigit11PNormHt|Num|8|BEST|11,471|94|11,378|||
|1073|COMDigit11POutside|COMDigit11POutside|Num|8|BEST|11,471|4|11,378|||
|1074|COMDigit11PAngle|COMDigit11PAngle|Num|8|BEST|11,471|95|11,378|||
|1075|COMDigit11PIdealDiff|COMDigit11PIdealDiff|Num|8|BEST|11,471|95|11,378|||
|1076|COMDigit11PDistCircum|COMDigit11PDistCircum|Num|8|BEST|11,471|95|11,378|||
|1077|COMDigit11PIsPersev|COMDigit11PIsPersev|Num|8|BEST|11,471|4|11,378|||
|1078|COMDigit12PSeq|COMDigit12PSeq|Num|8|BEST|11,471|15|11,406|||
|1079|COMDigit12PStrokes|COMDigit12PStrokes|Num|8|BEST|11,471|5|11,406|||
|1080|COMDigit12PTime|COMDigit12PTime|Num|8|BEST|11,471|64|11,406|||
|1081|COMDigit12PLen|COMDigit12PLen|Num|8|BEST|11,471|67|11,406|||
|1082|COMDigit12PCentX|COMDigit12PCentX|Num|8|BEST|11,471|65|11,406|||
|1083|COMDigit12PCentY|COMDigit12PCentY|Num|8|BEST|11,471|67|11,406|||
|1084|COMDigit12PWidth|COMDigit12PWidth|Num|8|BEST|11,471|59|11,406|||
|1085|COMDigit12PHgt|COMDigit12PHgt|Num|8|BEST|11,471|55|11,406|||
|1086|COMDigit12PNormHt|COMDigit12PNormHt|Num|8|BEST|11,471|67|11,406|||
|1087|COMDigit12POutside|COMDigit12POutside|Num|8|BEST|11,471|4|11,406|||
|1088|COMDigit12PAngle|COMDigit12PAngle|Num|8|BEST|11,471|67|11,406|||
|1089|COMDigit12PIdealDiff|COMDigit12PIdealDiff|Num|8|BEST|11,471|67|11,406|||
|1090|COMDigit12PDistCircum|COMDigit12PDistCircum|Num|8|BEST|11,471|67|11,406|||
|1091|COMDigit12PIsPersev|COMDigit12PIsPersev|Num|8|BEST|11,471|4|11,406|||
|1092|COMDigit1PPSeq|COMDigit1PPSeq|Num|8|BEST|11,471|4|11,468|||
|1093|COMDigit1PPStrokes|COMDigit1PPStrokes|Num|8|BEST|11,471|3|11,468|||
|1094|COMDigit1PPTime|COMDigit1PPTime|Num|8|BEST|11,471|5|11,468|||
|1095|COMDigit1PPLen|COMDigit1PPLen|Num|8|BEST|11,471|5|11,468|||
|1096|COMDigit1PPCentX|COMDigit1PPCentX|Num|8|BEST|11,471|5|11,468|||
|1097|COMDigit1PPCentY|COMDigit1PPCentY|Num|8|BEST|11,471|5|11,468|||
|1098|COMDigit1PPWidth|COMDigit1PPWidth|Num|8|BEST|11,471|5|11,468|||
|1099|COMDigit1PPHgt|COMDigit1PPHgt|Num|8|BEST|11,471|5|11,468|||
|1100|COMDigit1PPNormHt|COMDigit1PPNormHt|Num|8|BEST|11,471|5|11,468|||
|1101|COMDigit1PPOutside|COMDigit1PPOutside|Num|8|BEST|11,471|3|11,468|||
|1102|COMDigit1PPAngle|COMDigit1PPAngle|Num|8|BEST|11,471|5|11,468|||
|1103|COMDigit1PPIdealDiff|COMDigit1PPIdealDiff|Num|8|BEST|11,471|5|11,468|||
|1104|COMDigit1PPDistCircum|COMDigit1PPDistCircum|Num|8|BEST|11,471|5|11,468|||
|1105|COMDigit1PPIsPersev|COMDigit1PPIsPersev|Num|8|BEST|11,471|4|11,468|||
|1106|COMDigit2PPSeq|COMDigit2PPSeq|Num|8|BEST|11,471|2|11,471|||
|1107|COMDigit2PPStrokes|COMDigit2PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1108|COMDigit2PPTime|COMDigit2PPTime|Num|8|BEST|11,471|2|11,471|||
|1109|COMDigit2PPLen|COMDigit2PPLen|Num|8|BEST|11,471|2|11,471|||
|1110|COMDigit2PPCentX|COMDigit2PPCentX|Num|8|BEST|11,471|2|11,471|||
|1111|COMDigit2PPCentY|COMDigit2PPCentY|Num|8|BEST|11,471|2|11,471|||
|1112|COMDigit2PPWidth|COMDigit2PPWidth|Num|8|BEST|11,471|2|11,471|||
|1113|COMDigit2PPHgt|COMDigit2PPHgt|Num|8|BEST|11,471|2|11,471|||
|1114|COMDigit2PPNormHt|COMDigit2PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1115|COMDigit2PPOutside|COMDigit2PPOutside|Num|8|BEST|11,471|2|11,471|||
|1116|COMDigit2PPAngle|COMDigit2PPAngle|Num|8|BEST|11,471|2|11,471|||
|1117|COMDigit2PPIdealDiff|COMDigit2PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1118|COMDigit2PPDistCircum|COMDigit2PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1119|COMDigit2PPIsPersev|COMDigit2PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1120|COMDigit3PPSeq|COMDigit3PPSeq|Num|8|BEST|11,471|2|11,471|||
|1121|COMDigit3PPStrokes|COMDigit3PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1122|COMDigit3PPTime|COMDigit3PPTime|Num|8|BEST|11,471|2|11,471|||
|1123|COMDigit3PPLen|COMDigit3PPLen|Num|8|BEST|11,471|2|11,471|||
|1124|COMDigit3PPCentX|COMDigit3PPCentX|Num|8|BEST|11,471|2|11,471|||
|1125|COMDigit3PPCentY|COMDigit3PPCentY|Num|8|BEST|11,471|2|11,471|||
|1126|COMDigit3PPWidth|COMDigit3PPWidth|Num|8|BEST|11,471|2|11,471|||
|1127|COMDigit3PPHgt|COMDigit3PPHgt|Num|8|BEST|11,471|2|11,471|||
|1128|COMDigit3PPNormHt|COMDigit3PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1129|COMDigit3PPOutside|COMDigit3PPOutside|Num|8|BEST|11,471|2|11,471|||
|1130|COMDigit3PPAngle|COMDigit3PPAngle|Num|8|BEST|11,471|2|11,471|||
|1131|COMDigit3PPIdealDiff|COMDigit3PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1132|COMDigit3PPDistCircum|COMDigit3PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1133|COMDigit3PPIsPersev|COMDigit3PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1134|COMDigit4PPSeq|COMDigit4PPSeq|Num|8|BEST|11,471|2|11,471|||
|1135|COMDigit4PPStrokes|COMDigit4PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1136|COMDigit4PPTime|COMDigit4PPTime|Num|8|BEST|11,471|2|11,471|||
|1137|COMDigit4PPLen|COMDigit4PPLen|Num|8|BEST|11,471|2|11,471|||
|1138|COMDigit4PPCentX|COMDigit4PPCentX|Num|8|BEST|11,471|2|11,471|||
|1139|COMDigit4PPCentY|COMDigit4PPCentY|Num|8|BEST|11,471|2|11,471|||
|1140|COMDigit4PPWidth|COMDigit4PPWidth|Num|8|BEST|11,471|2|11,471|||
|1141|COMDigit4PPHgt|COMDigit4PPHgt|Num|8|BEST|11,471|2|11,471|||
|1142|COMDigit4PPNormHt|COMDigit4PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1143|COMDigit4PPOutside|COMDigit4PPOutside|Num|8|BEST|11,471|2|11,471|||
|1144|COMDigit4PPAngle|COMDigit4PPAngle|Num|8|BEST|11,471|2|11,471|||
|1145|COMDigit4PPIdealDiff|COMDigit4PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1146|COMDigit4PPDistCircum|COMDigit4PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1147|COMDigit4PPIsPersev|COMDigit4PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1148|COMDigit5PPSeq|COMDigit5PPSeq|Num|8|BEST|11,471|3|11,470|||
|1149|COMDigit5PPStrokes|COMDigit5PPStrokes|Num|8|BEST|11,471|3|11,470|||
|1150|COMDigit5PPTime|COMDigit5PPTime|Num|8|BEST|11,471|3|11,470|||
|1151|COMDigit5PPLen|COMDigit5PPLen|Num|8|BEST|11,471|3|11,470|||
|1152|COMDigit5PPCentX|COMDigit5PPCentX|Num|8|BEST|11,471|3|11,470|||
|1153|COMDigit5PPCentY|COMDigit5PPCentY|Num|8|BEST|11,471|3|11,470|||
|1154|COMDigit5PPWidth|COMDigit5PPWidth|Num|8|BEST|11,471|3|11,470|||
|1155|COMDigit5PPHgt|COMDigit5PPHgt|Num|8|BEST|11,471|3|11,470|||
|1156|COMDigit5PPNormHt|COMDigit5PPNormHt|Num|8|BEST|11,471|3|11,470|||
|1157|COMDigit5PPOutside|COMDigit5PPOutside|Num|8|BEST|11,471|3|11,470|||
|1158|COMDigit5PPAngle|COMDigit5PPAngle|Num|8|BEST|11,471|3|11,470|||
|1159|COMDigit5PPIdealDiff|COMDigit5PPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|1160|COMDigit5PPDistCircum|COMDigit5PPDistCircum|Num|8|BEST|11,471|3|11,470|||
|1161|COMDigit5PPIsPersev|COMDigit5PPIsPersev|Num|8|BEST|11,471|3|11,470|||
|1162|COMDigit6PPSeq|COMDigit6PPSeq|Num|8|BEST|11,471|2|11,471|||
|1163|COMDigit6PPStrokes|COMDigit6PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1164|COMDigit6PPTime|COMDigit6PPTime|Num|8|BEST|11,471|2|11,471|||
|1165|COMDigit6PPLen|COMDigit6PPLen|Num|8|BEST|11,471|2|11,471|||
|1166|COMDigit6PPCentX|COMDigit6PPCentX|Num|8|BEST|11,471|2|11,471|||
|1167|COMDigit6PPCentY|COMDigit6PPCentY|Num|8|BEST|11,471|2|11,471|||
|1168|COMDigit6PPWidth|COMDigit6PPWidth|Num|8|BEST|11,471|2|11,471|||
|1169|COMDigit6PPHgt|COMDigit6PPHgt|Num|8|BEST|11,471|2|11,471|||
|1170|COMDigit6PPNormHt|COMDigit6PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1171|COMDigit6PPOutside|COMDigit6PPOutside|Num|8|BEST|11,471|2|11,471|||
|1172|COMDigit6PPAngle|COMDigit6PPAngle|Num|8|BEST|11,471|2|11,471|||
|1173|COMDigit6PPIdealDiff|COMDigit6PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1174|COMDigit6PPDistCircum|COMDigit6PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1175|COMDigit6PPIsPersev|COMDigit6PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1176|COMDigit7PPSeq|COMDigit7PPSeq|Num|8|BEST|11,471|2|11,471|||
|1177|COMDigit7PPStrokes|COMDigit7PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1178|COMDigit7PPTime|COMDigit7PPTime|Num|8|BEST|11,471|2|11,471|||
|1179|COMDigit7PPLen|COMDigit7PPLen|Num|8|BEST|11,471|2|11,471|||
|1180|COMDigit7PPCentX|COMDigit7PPCentX|Num|8|BEST|11,471|2|11,471|||
|1181|COMDigit7PPCentY|COMDigit7PPCentY|Num|8|BEST|11,471|2|11,471|||
|1182|COMDigit7PPWidth|COMDigit7PPWidth|Num|8|BEST|11,471|2|11,471|||
|1183|COMDigit7PPHgt|COMDigit7PPHgt|Num|8|BEST|11,471|2|11,471|||
|1184|COMDigit7PPNormHt|COMDigit7PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1185|COMDigit7PPOutside|COMDigit7PPOutside|Num|8|BEST|11,471|2|11,471|||
|1186|COMDigit7PPAngle|COMDigit7PPAngle|Num|8|BEST|11,471|2|11,471|||
|1187|COMDigit7PPIdealDiff|COMDigit7PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1188|COMDigit7PPDistCircum|COMDigit7PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1189|COMDigit7PPIsPersev|COMDigit7PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1190|COMDigit8PPSeq|COMDigit8PPSeq|Num|8|BEST|11,471|2|11,471|||
|1191|COMDigit8PPStrokes|COMDigit8PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1192|COMDigit8PPTime|COMDigit8PPTime|Num|8|BEST|11,471|2|11,471|||
|1193|COMDigit8PPLen|COMDigit8PPLen|Num|8|BEST|11,471|2|11,471|||
|1194|COMDigit8PPCentX|COMDigit8PPCentX|Num|8|BEST|11,471|2|11,471|||
|1195|COMDigit8PPCentY|COMDigit8PPCentY|Num|8|BEST|11,471|2|11,471|||
|1196|COMDigit8PPWidth|COMDigit8PPWidth|Num|8|BEST|11,471|2|11,471|||
|1197|COMDigit8PPHgt|COMDigit8PPHgt|Num|8|BEST|11,471|2|11,471|||
|1198|COMDigit8PPNormHt|COMDigit8PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1199|COMDigit8PPOutside|COMDigit8PPOutside|Num|8|BEST|11,471|2|11,471|||
|1200|COMDigit8PPAngle|COMDigit8PPAngle|Num|8|BEST|11,471|2|11,471|||
|1201|COMDigit8PPIdealDiff|COMDigit8PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1202|COMDigit8PPDistCircum|COMDigit8PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1203|COMDigit8PPIsPersev|COMDigit8PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1204|COMDigit9PPSeq|COMDigit9PPSeq|Num|8|BEST|11,471|2|11,471|||
|1205|COMDigit9PPStrokes|COMDigit9PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1206|COMDigit9PPTime|COMDigit9PPTime|Num|8|BEST|11,471|2|11,471|||
|1207|COMDigit9PPLen|COMDigit9PPLen|Num|8|BEST|11,471|2|11,471|||
|1208|COMDigit9PPCentX|COMDigit9PPCentX|Num|8|BEST|11,471|2|11,471|||
|1209|COMDigit9PPCentY|COMDigit9PPCentY|Num|8|BEST|11,471|2|11,471|||
|1210|COMDigit9PPWidth|COMDigit9PPWidth|Num|8|BEST|11,471|2|11,471|||
|1211|COMDigit9PPHgt|COMDigit9PPHgt|Num|8|BEST|11,471|2|11,471|||
|1212|COMDigit9PPNormHt|COMDigit9PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1213|COMDigit9PPOutside|COMDigit9PPOutside|Num|8|BEST|11,471|2|11,471|||
|1214|COMDigit9PPAngle|COMDigit9PPAngle|Num|8|BEST|11,471|2|11,471|||
|1215|COMDigit9PPIdealDiff|COMDigit9PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1216|COMDigit9PPDistCircum|COMDigit9PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1217|COMDigit9PPIsPersev|COMDigit9PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1218|COMDigit10PPSeq|COMDigit10PPSeq|Num|8|BEST|11,471|7|11,465|||
|1219|COMDigit10PPStrokes|COMDigit10PPStrokes|Num|8|BEST|11,471|4|11,465|||
|1220|COMDigit10PPTime|COMDigit10PPTime|Num|8|BEST|11,471|8|11,465|||
|1221|COMDigit10PPLen|COMDigit10PPLen|Num|8|BEST|11,471|8|11,465|||
|1222|COMDigit10PPCentX|COMDigit10PPCentX|Num|8|BEST|11,471|8|11,465|||
|1223|COMDigit10PPCentY|COMDigit10PPCentY|Num|8|BEST|11,471|8|11,465|||
|1224|COMDigit10PPWidth|COMDigit10PPWidth|Num|8|BEST|11,471|8|11,465|||
|1225|COMDigit10PPHgt|COMDigit10PPHgt|Num|8|BEST|11,471|8|11,465|||
|1226|COMDigit10PPNormHt|COMDigit10PPNormHt|Num|8|BEST|11,471|8|11,465|||
|1227|COMDigit10PPOutside|COMDigit10PPOutside|Num|8|BEST|11,471|4|11,465|||
|1228|COMDigit10PPAngle|COMDigit10PPAngle|Num|8|BEST|11,471|8|11,465|||
|1229|COMDigit10PPIdealDiff|COMDigit10PPIdealDiff|Num|8|BEST|11,471|8|11,465|||
|1230|COMDigit10PPDistCircum|COMDigit10PPDistCircum|Num|8|BEST|11,471|8|11,465|||
|1231|COMDigit10PPIsPersev|COMDigit10PPIsPersev|Num|8|BEST|11,471|4|11,465|||
|1232|COMDigit11PPSeq|COMDigit11PPSeq|Num|8|BEST|11,471|7|11,462|||
|1233|COMDigit11PPStrokes|COMDigit11PPStrokes|Num|8|BEST|11,471|4|11,462|||
|1234|COMDigit11PPTime|COMDigit11PPTime|Num|8|BEST|11,471|11|11,462|||
|1235|COMDigit11PPLen|COMDigit11PPLen|Num|8|BEST|11,471|11|11,462|||
|1236|COMDigit11PPCentX|COMDigit11PPCentX|Num|8|BEST|11,471|11|11,462|||
|1237|COMDigit11PPCentY|COMDigit11PPCentY|Num|8|BEST|11,471|11|11,462|||
|1238|COMDigit11PPWidth|COMDigit11PPWidth|Num|8|BEST|11,471|11|11,462|||
|1239|COMDigit11PPHgt|COMDigit11PPHgt|Num|8|BEST|11,471|11|11,462|||
|1240|COMDigit11PPNormHt|COMDigit11PPNormHt|Num|8|BEST|11,471|11|11,462|||
|1241|COMDigit11PPOutside|COMDigit11PPOutside|Num|8|BEST|11,471|4|11,462|||
|1242|COMDigit11PPAngle|COMDigit11PPAngle|Num|8|BEST|11,471|11|11,462|||
|1243|COMDigit11PPIdealDiff|COMDigit11PPIdealDiff|Num|8|BEST|11,471|11|11,462|||
|1244|COMDigit11PPDistCircum|COMDigit11PPDistCircum|Num|8|BEST|11,471|11|11,462|||
|1245|COMDigit11PPIsPersev|COMDigit11PPIsPersev|Num|8|BEST|11,471|4|11,462|||
|1246|COMDigit12PPSeq|COMDigit12PPSeq|Num|8|BEST|11,471|2|11,471|||
|1247|COMDigit12PPStrokes|COMDigit12PPStrokes|Num|8|BEST|11,471|2|11,471|||
|1248|COMDigit12PPTime|COMDigit12PPTime|Num|8|BEST|11,471|2|11,471|||
|1249|COMDigit12PPLen|COMDigit12PPLen|Num|8|BEST|11,471|2|11,471|||
|1250|COMDigit12PPCentX|COMDigit12PPCentX|Num|8|BEST|11,471|2|11,471|||
|1251|COMDigit12PPCentY|COMDigit12PPCentY|Num|8|BEST|11,471|2|11,471|||
|1252|COMDigit12PPWidth|COMDigit12PPWidth|Num|8|BEST|11,471|2|11,471|||
|1253|COMDigit12PPHgt|COMDigit12PPHgt|Num|8|BEST|11,471|2|11,471|||
|1254|COMDigit12PPNormHt|COMDigit12PPNormHt|Num|8|BEST|11,471|2|11,471|||
|1255|COMDigit12PPOutside|COMDigit12PPOutside|Num|8|BEST|11,471|2|11,471|||
|1256|COMDigit12PPAngle|COMDigit12PPAngle|Num|8|BEST|11,471|2|11,471|||
|1257|COMDigit12PPIdealDiff|COMDigit12PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1258|COMDigit12PPDistCircum|COMDigit12PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1259|COMDigit12PPIsPersev|COMDigit12PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1260|COMDigit1PPPSeq|COMDigit1PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1261|COMDigit1PPPStrokes|COMDigit1PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1262|COMDigit1PPPTime|COMDigit1PPPTime|Num|8|BEST|11,471|2|11,471|||
|1263|COMDigit1PPPLen|COMDigit1PPPLen|Num|8|BEST|11,471|2|11,471|||
|1264|COMDigit1PPPCentX|COMDigit1PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1265|COMDigit1PPPCentY|COMDigit1PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1266|COMDigit1PPPWidth|COMDigit1PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1267|COMDigit1PPPHgt|COMDigit1PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1268|COMDigit1PPPNormHt|COMDigit1PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1269|COMDigit1PPPOutside|COMDigit1PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1270|COMDigit1PPPAngle|COMDigit1PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1271|COMDigit1PPPIdealDiff|COMDigit1PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1272|COMDigit1PPPDistCircum|COMDigit1PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1273|COMDigit1PPPIsPersev|COMDigit1PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1274|COMDigit2PPPSeq|COMDigit2PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1275|COMDigit2PPPStrokes|COMDigit2PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1276|COMDigit2PPPTime|COMDigit2PPPTime|Num|8|BEST|11,471|2|11,471|||
|1277|COMDigit2PPPLen|COMDigit2PPPLen|Num|8|BEST|11,471|2|11,471|||
|1278|COMDigit2PPPCentX|COMDigit2PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1279|COMDigit2PPPCentY|COMDigit2PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1280|COMDigit2PPPWidth|COMDigit2PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1281|COMDigit2PPPHgt|COMDigit2PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1282|COMDigit2PPPNormHt|COMDigit2PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1283|COMDigit2PPPOutside|COMDigit2PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1284|COMDigit2PPPAngle|COMDigit2PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1285|COMDigit2PPPIdealDiff|COMDigit2PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1286|COMDigit2PPPDistCircum|COMDigit2PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1287|COMDigit2PPPIsPersev|COMDigit2PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1288|COMDigit3PPPSeq|COMDigit3PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1289|COMDigit3PPPStrokes|COMDigit3PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1290|COMDigit3PPPTime|COMDigit3PPPTime|Num|8|BEST|11,471|2|11,471|||
|1291|COMDigit3PPPLen|COMDigit3PPPLen|Num|8|BEST|11,471|2|11,471|||
|1292|COMDigit3PPPCentX|COMDigit3PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1293|COMDigit3PPPCentY|COMDigit3PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1294|COMDigit3PPPWidth|COMDigit3PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1295|COMDigit3PPPHgt|COMDigit3PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1296|COMDigit3PPPNormHt|COMDigit3PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1297|COMDigit3PPPOutside|COMDigit3PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1298|COMDigit3PPPAngle|COMDigit3PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1299|COMDigit3PPPIdealDiff|COMDigit3PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1300|COMDigit3PPPDistCircum|COMDigit3PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1301|COMDigit3PPPIsPersev|COMDigit3PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1302|COMDigit4PPPSeq|COMDigit4PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1303|COMDigit4PPPStrokes|COMDigit4PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1304|COMDigit4PPPTime|COMDigit4PPPTime|Num|8|BEST|11,471|2|11,471|||
|1305|COMDigit4PPPLen|COMDigit4PPPLen|Num|8|BEST|11,471|2|11,471|||
|1306|COMDigit4PPPCentX|COMDigit4PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1307|COMDigit4PPPCentY|COMDigit4PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1308|COMDigit4PPPWidth|COMDigit4PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1309|COMDigit4PPPHgt|COMDigit4PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1310|COMDigit4PPPNormHt|COMDigit4PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1311|COMDigit4PPPOutside|COMDigit4PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1312|COMDigit4PPPAngle|COMDigit4PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1313|COMDigit4PPPIdealDiff|COMDigit4PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1314|COMDigit4PPPDistCircum|COMDigit4PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1315|COMDigit4PPPIsPersev|COMDigit4PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1316|COMDigit5PPPSeq|COMDigit5PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1317|COMDigit5PPPStrokes|COMDigit5PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1318|COMDigit5PPPTime|COMDigit5PPPTime|Num|8|BEST|11,471|2|11,471|||
|1319|COMDigit5PPPLen|COMDigit5PPPLen|Num|8|BEST|11,471|2|11,471|||
|1320|COMDigit5PPPCentX|COMDigit5PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1321|COMDigit5PPPCentY|COMDigit5PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1322|COMDigit5PPPWidth|COMDigit5PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1323|COMDigit5PPPHgt|COMDigit5PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1324|COMDigit5PPPNormHt|COMDigit5PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1325|COMDigit5PPPOutside|COMDigit5PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1326|COMDigit5PPPAngle|COMDigit5PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1327|COMDigit5PPPIdealDiff|COMDigit5PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1328|COMDigit5PPPDistCircum|COMDigit5PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1329|COMDigit5PPPIsPersev|COMDigit5PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1330|COMDigit6PPPSeq|COMDigit6PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1331|COMDigit6PPPStrokes|COMDigit6PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1332|COMDigit6PPPTime|COMDigit6PPPTime|Num|8|BEST|11,471|2|11,471|||
|1333|COMDigit6PPPLen|COMDigit6PPPLen|Num|8|BEST|11,471|2|11,471|||
|1334|COMDigit6PPPCentX|COMDigit6PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1335|COMDigit6PPPCentY|COMDigit6PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1336|COMDigit6PPPWidth|COMDigit6PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1337|COMDigit6PPPHgt|COMDigit6PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1338|COMDigit6PPPNormHt|COMDigit6PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1339|COMDigit6PPPOutside|COMDigit6PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1340|COMDigit6PPPAngle|COMDigit6PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1341|COMDigit6PPPIdealDiff|COMDigit6PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1342|COMDigit6PPPDistCircum|COMDigit6PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1343|COMDigit6PPPIsPersev|COMDigit6PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1344|COMDigit7PPPSeq|COMDigit7PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1345|COMDigit7PPPStrokes|COMDigit7PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1346|COMDigit7PPPTime|COMDigit7PPPTime|Num|8|BEST|11,471|2|11,471|||
|1347|COMDigit7PPPLen|COMDigit7PPPLen|Num|8|BEST|11,471|2|11,471|||
|1348|COMDigit7PPPCentX|COMDigit7PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1349|COMDigit7PPPCentY|COMDigit7PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1350|COMDigit7PPPWidth|COMDigit7PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1351|COMDigit7PPPHgt|COMDigit7PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1352|COMDigit7PPPNormHt|COMDigit7PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1353|COMDigit7PPPOutside|COMDigit7PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1354|COMDigit7PPPAngle|COMDigit7PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1355|COMDigit7PPPIdealDiff|COMDigit7PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1356|COMDigit7PPPDistCircum|COMDigit7PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1357|COMDigit7PPPIsPersev|COMDigit7PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1358|COMDigit8PPPSeq|COMDigit8PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1359|COMDigit8PPPStrokes|COMDigit8PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1360|COMDigit8PPPTime|COMDigit8PPPTime|Num|8|BEST|11,471|2|11,471|||
|1361|COMDigit8PPPLen|COMDigit8PPPLen|Num|8|BEST|11,471|2|11,471|||
|1362|COMDigit8PPPCentX|COMDigit8PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1363|COMDigit8PPPCentY|COMDigit8PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1364|COMDigit8PPPWidth|COMDigit8PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1365|COMDigit8PPPHgt|COMDigit8PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1366|COMDigit8PPPNormHt|COMDigit8PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1367|COMDigit8PPPOutside|COMDigit8PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1368|COMDigit8PPPAngle|COMDigit8PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1369|COMDigit8PPPIdealDiff|COMDigit8PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1370|COMDigit8PPPDistCircum|COMDigit8PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1371|COMDigit8PPPIsPersev|COMDigit8PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1372|COMDigit9PPPSeq|COMDigit9PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1373|COMDigit9PPPStrokes|COMDigit9PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1374|COMDigit9PPPTime|COMDigit9PPPTime|Num|8|BEST|11,471|2|11,471|||
|1375|COMDigit9PPPLen|COMDigit9PPPLen|Num|8|BEST|11,471|2|11,471|||
|1376|COMDigit9PPPCentX|COMDigit9PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1377|COMDigit9PPPCentY|COMDigit9PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1378|COMDigit9PPPWidth|COMDigit9PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1379|COMDigit9PPPHgt|COMDigit9PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1380|COMDigit9PPPNormHt|COMDigit9PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1381|COMDigit9PPPOutside|COMDigit9PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1382|COMDigit9PPPAngle|COMDigit9PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1383|COMDigit9PPPIdealDiff|COMDigit9PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1384|COMDigit9PPPDistCircum|COMDigit9PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1385|COMDigit9PPPIsPersev|COMDigit9PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1386|COMDigit10PPPSeq|COMDigit10PPPSeq|Num|8|BEST|11,471|3|11,470|||
|1387|COMDigit10PPPStrokes|COMDigit10PPPStrokes|Num|8|BEST|11,471|3|11,470|||
|1388|COMDigit10PPPTime|COMDigit10PPPTime|Num|8|BEST|11,471|3|11,470|||
|1389|COMDigit10PPPLen|COMDigit10PPPLen|Num|8|BEST|11,471|3|11,470|||
|1390|COMDigit10PPPCentX|COMDigit10PPPCentX|Num|8|BEST|11,471|3|11,470|||
|1391|COMDigit10PPPCentY|COMDigit10PPPCentY|Num|8|BEST|11,471|3|11,470|||
|1392|COMDigit10PPPWidth|COMDigit10PPPWidth|Num|8|BEST|11,471|3|11,470|||
|1393|COMDigit10PPPHgt|COMDigit10PPPHgt|Num|8|BEST|11,471|3|11,470|||
|1394|COMDigit10PPPNormHt|COMDigit10PPPNormHt|Num|8|BEST|11,471|3|11,470|||
|1395|COMDigit10PPPOutside|COMDigit10PPPOutside|Num|8|BEST|11,471|3|11,470|||
|1396|COMDigit10PPPAngle|COMDigit10PPPAngle|Num|8|BEST|11,471|3|11,470|||
|1397|COMDigit10PPPIdealDiff|COMDigit10PPPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|1398|COMDigit10PPPDistCircum|COMDigit10PPPDistCircum|Num|8|BEST|11,471|3|11,470|||
|1399|COMDigit10PPPIsPersev|COMDigit10PPPIsPersev|Num|8|BEST|11,471|3|11,470|||
|1400|COMDigit11PPPSeq|COMDigit11PPPSeq|Num|8|BEST|11,471|3|11,470|||
|1401|COMDigit11PPPStrokes|COMDigit11PPPStrokes|Num|8|BEST|11,471|3|11,470|||
|1402|COMDigit11PPPTime|COMDigit11PPPTime|Num|8|BEST|11,471|3|11,470|||
|1403|COMDigit11PPPLen|COMDigit11PPPLen|Num|8|BEST|11,471|3|11,470|||
|1404|COMDigit11PPPCentX|COMDigit11PPPCentX|Num|8|BEST|11,471|3|11,470|||
|1405|COMDigit11PPPCentY|COMDigit11PPPCentY|Num|8|BEST|11,471|3|11,470|||
|1406|COMDigit11PPPWidth|COMDigit11PPPWidth|Num|8|BEST|11,471|3|11,470|||
|1407|COMDigit11PPPHgt|COMDigit11PPPHgt|Num|8|BEST|11,471|3|11,470|||
|1408|COMDigit11PPPNormHt|COMDigit11PPPNormHt|Num|8|BEST|11,471|3|11,470|||
|1409|COMDigit11PPPOutside|COMDigit11PPPOutside|Num|8|BEST|11,471|3|11,470|||
|1410|COMDigit11PPPAngle|COMDigit11PPPAngle|Num|8|BEST|11,471|3|11,470|||
|1411|COMDigit11PPPIdealDiff|COMDigit11PPPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|1412|COMDigit11PPPDistCircum|COMDigit11PPPDistCircum|Num|8|BEST|11,471|3|11,470|||
|1413|COMDigit11PPPIsPersev|COMDigit11PPPIsPersev|Num|8|BEST|11,471|3|11,470|||
|1414|COMDigit12PPPSeq|COMDigit12PPPSeq|Num|8|BEST|11,471|2|11,471|||
|1415|COMDigit12PPPStrokes|COMDigit12PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1416|COMDigit12PPPTime|COMDigit12PPPTime|Num|8|BEST|11,471|2|11,471|||
|1417|COMDigit12PPPLen|COMDigit12PPPLen|Num|8|BEST|11,471|2|11,471|||
|1418|COMDigit12PPPCentX|COMDigit12PPPCentX|Num|8|BEST|11,471|2|11,471|||
|1419|COMDigit12PPPCentY|COMDigit12PPPCentY|Num|8|BEST|11,471|2|11,471|||
|1420|COMDigit12PPPWidth|COMDigit12PPPWidth|Num|8|BEST|11,471|2|11,471|||
|1421|COMDigit12PPPHgt|COMDigit12PPPHgt|Num|8|BEST|11,471|2|11,471|||
|1422|COMDigit12PPPNormHt|COMDigit12PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1423|COMDigit12PPPOutside|COMDigit12PPPOutside|Num|8|BEST|11,471|2|11,471|||
|1424|COMDigit12PPPAngle|COMDigit12PPPAngle|Num|8|BEST|11,471|2|11,471|||
|1425|COMDigit12PPPIdealDiff|COMDigit12PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1426|COMDigit12PPPDistCircum|COMDigit12PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1427|COMDigit12PPPIsPersev|COMDigit12PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1428|COMDigit1PPPPSeq|COMDigit1PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1429|COMDigit1PPPPStrokes|COMDigit1PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1430|COMDigit1PPPPTime|COMDigit1PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1431|COMDigit1PPPPLen|COMDigit1PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1432|COMDigit1PPPPCentX|COMDigit1PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1433|COMDigit1PPPPCentY|COMDigit1PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1434|COMDigit1PPPPWidth|COMDigit1PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1435|COMDigit1PPPPHgt|COMDigit1PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1436|COMDigit1PPPPNormHt|COMDigit1PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1437|COMDigit1PPPPOutside|COMDigit1PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1438|COMDigit1PPPPAngle|COMDigit1PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1439|COMDigit1PPPPIdealDiff|COMDigit1PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1440|COMDigit1PPPPDistCircum|COMDigit1PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1441|COMDigit1PPPPIsPersev|COMDigit1PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1442|COMDigit2PPPPSeq|COMDigit2PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1443|COMDigit2PPPPStrokes|COMDigit2PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1444|COMDigit2PPPPTime|COMDigit2PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1445|COMDigit2PPPPLen|COMDigit2PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1446|COMDigit2PPPPCentX|COMDigit2PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1447|COMDigit2PPPPCentY|COMDigit2PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1448|COMDigit2PPPPWidth|COMDigit2PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1449|COMDigit2PPPPHgt|COMDigit2PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1450|COMDigit2PPPPNormHt|COMDigit2PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1451|COMDigit2PPPPOutside|COMDigit2PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1452|COMDigit2PPPPAngle|COMDigit2PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1453|COMDigit2PPPPIdealDiff|COMDigit2PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1454|COMDigit2PPPPDistCircum|COMDigit2PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1455|COMDigit2PPPPIsPersev|COMDigit2PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1456|COMDigit3PPPPSeq|COMDigit3PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1457|COMDigit3PPPPStrokes|COMDigit3PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1458|COMDigit3PPPPTime|COMDigit3PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1459|COMDigit3PPPPLen|COMDigit3PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1460|COMDigit3PPPPCentX|COMDigit3PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1461|COMDigit3PPPPCentY|COMDigit3PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1462|COMDigit3PPPPWidth|COMDigit3PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1463|COMDigit3PPPPHgt|COMDigit3PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1464|COMDigit3PPPPNormHt|COMDigit3PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1465|COMDigit3PPPPOutside|COMDigit3PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1466|COMDigit3PPPPAngle|COMDigit3PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1467|COMDigit3PPPPIdealDiff|COMDigit3PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1468|COMDigit3PPPPDistCircum|COMDigit3PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1469|COMDigit3PPPPIsPersev|COMDigit3PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1470|COMDigit4PPPPSeq|COMDigit4PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1471|COMDigit4PPPPStrokes|COMDigit4PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1472|COMDigit4PPPPTime|COMDigit4PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1473|COMDigit4PPPPLen|COMDigit4PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1474|COMDigit4PPPPCentX|COMDigit4PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1475|COMDigit4PPPPCentY|COMDigit4PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1476|COMDigit4PPPPWidth|COMDigit4PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1477|COMDigit4PPPPHgt|COMDigit4PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1478|COMDigit4PPPPNormHt|COMDigit4PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1479|COMDigit4PPPPOutside|COMDigit4PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1480|COMDigit4PPPPAngle|COMDigit4PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1481|COMDigit4PPPPIdealDiff|COMDigit4PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1482|COMDigit4PPPPDistCircum|COMDigit4PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1483|COMDigit4PPPPIsPersev|COMDigit4PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1484|COMDigit5PPPPSeq|COMDigit5PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1485|COMDigit5PPPPStrokes|COMDigit5PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1486|COMDigit5PPPPTime|COMDigit5PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1487|COMDigit5PPPPLen|COMDigit5PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1488|COMDigit5PPPPCentX|COMDigit5PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1489|COMDigit5PPPPCentY|COMDigit5PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1490|COMDigit5PPPPWidth|COMDigit5PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1491|COMDigit5PPPPHgt|COMDigit5PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1492|COMDigit5PPPPNormHt|COMDigit5PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1493|COMDigit5PPPPOutside|COMDigit5PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1494|COMDigit5PPPPAngle|COMDigit5PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1495|COMDigit5PPPPIdealDiff|COMDigit5PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1496|COMDigit5PPPPDistCircum|COMDigit5PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1497|COMDigit5PPPPIsPersev|COMDigit5PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1498|COMDigit6PPPPSeq|COMDigit6PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1499|COMDigit6PPPPStrokes|COMDigit6PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1500|COMDigit6PPPPTime|COMDigit6PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1501|COMDigit6PPPPLen|COMDigit6PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1502|COMDigit6PPPPCentX|COMDigit6PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1503|COMDigit6PPPPCentY|COMDigit6PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1504|COMDigit6PPPPWidth|COMDigit6PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1505|COMDigit6PPPPHgt|COMDigit6PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1506|COMDigit6PPPPNormHt|COMDigit6PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1507|COMDigit6PPPPOutside|COMDigit6PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1508|COMDigit6PPPPAngle|COMDigit6PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1509|COMDigit6PPPPIdealDiff|COMDigit6PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1510|COMDigit6PPPPDistCircum|COMDigit6PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1511|COMDigit6PPPPIsPersev|COMDigit6PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1512|COMDigit7PPPPSeq|COMDigit7PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1513|COMDigit7PPPPStrokes|COMDigit7PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1514|COMDigit7PPPPTime|COMDigit7PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1515|COMDigit7PPPPLen|COMDigit7PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1516|COMDigit7PPPPCentX|COMDigit7PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1517|COMDigit7PPPPCentY|COMDigit7PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1518|COMDigit7PPPPWidth|COMDigit7PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1519|COMDigit7PPPPHgt|COMDigit7PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1520|COMDigit7PPPPNormHt|COMDigit7PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1521|COMDigit7PPPPOutside|COMDigit7PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1522|COMDigit7PPPPAngle|COMDigit7PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1523|COMDigit7PPPPIdealDiff|COMDigit7PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1524|COMDigit7PPPPDistCircum|COMDigit7PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1525|COMDigit7PPPPIsPersev|COMDigit7PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1526|COMDigit8PPPPSeq|COMDigit8PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1527|COMDigit8PPPPStrokes|COMDigit8PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1528|COMDigit8PPPPTime|COMDigit8PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1529|COMDigit8PPPPLen|COMDigit8PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1530|COMDigit8PPPPCentX|COMDigit8PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1531|COMDigit8PPPPCentY|COMDigit8PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1532|COMDigit8PPPPWidth|COMDigit8PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1533|COMDigit8PPPPHgt|COMDigit8PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1534|COMDigit8PPPPNormHt|COMDigit8PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1535|COMDigit8PPPPOutside|COMDigit8PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1536|COMDigit8PPPPAngle|COMDigit8PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1537|COMDigit8PPPPIdealDiff|COMDigit8PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1538|COMDigit8PPPPDistCircum|COMDigit8PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1539|COMDigit8PPPPIsPersev|COMDigit8PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1540|COMDigit9PPPPSeq|COMDigit9PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1541|COMDigit9PPPPStrokes|COMDigit9PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1542|COMDigit9PPPPTime|COMDigit9PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1543|COMDigit9PPPPLen|COMDigit9PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1544|COMDigit9PPPPCentX|COMDigit9PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1545|COMDigit9PPPPCentY|COMDigit9PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1546|COMDigit9PPPPWidth|COMDigit9PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1547|COMDigit9PPPPHgt|COMDigit9PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1548|COMDigit9PPPPNormHt|COMDigit9PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1549|COMDigit9PPPPOutside|COMDigit9PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1550|COMDigit9PPPPAngle|COMDigit9PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1551|COMDigit9PPPPIdealDiff|COMDigit9PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1552|COMDigit9PPPPDistCircum|COMDigit9PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1553|COMDigit9PPPPIsPersev|COMDigit9PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1554|COMDigit10PPPPSeq|COMDigit10PPPPSeq|Num|8|BEST|11,471|3|11,470|||
|1555|COMDigit10PPPPStrokes|COMDigit10PPPPStrokes|Num|8|BEST|11,471|3|11,470|||
|1556|COMDigit10PPPPTime|COMDigit10PPPPTime|Num|8|BEST|11,471|3|11,470|||
|1557|COMDigit10PPPPLen|COMDigit10PPPPLen|Num|8|BEST|11,471|3|11,470|||
|1558|COMDigit10PPPPCentX|COMDigit10PPPPCentX|Num|8|BEST|11,471|3|11,470|||
|1559|COMDigit10PPPPCentY|COMDigit10PPPPCentY|Num|8|BEST|11,471|3|11,470|||
|1560|COMDigit10PPPPWidth|COMDigit10PPPPWidth|Num|8|BEST|11,471|3|11,470|||
|1561|COMDigit10PPPPHgt|COMDigit10PPPPHgt|Num|8|BEST|11,471|3|11,470|||
|1562|COMDigit10PPPPNormHt|COMDigit10PPPPNormHt|Num|8|BEST|11,471|3|11,470|||
|1563|COMDigit10PPPPOutside|COMDigit10PPPPOutside|Num|8|BEST|11,471|3|11,470|||
|1564|COMDigit10PPPPAngle|COMDigit10PPPPAngle|Num|8|BEST|11,471|3|11,470|||
|1565|COMDigit10PPPPIdealDiff|COMDigit10PPPPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|1566|COMDigit10PPPPDistCircum|COMDigit10PPPPDistCircum|Num|8|BEST|11,471|3|11,470|||
|1567|COMDigit10PPPPIsPersev|COMDigit10PPPPIsPersev|Num|8|BEST|11,471|3|11,470|||
|1568|COMDigit11PPPPSeq|COMDigit11PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1569|COMDigit11PPPPStrokes|COMDigit11PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1570|COMDigit11PPPPTime|COMDigit11PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1571|COMDigit11PPPPLen|COMDigit11PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1572|COMDigit11PPPPCentX|COMDigit11PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1573|COMDigit11PPPPCentY|COMDigit11PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1574|COMDigit11PPPPWidth|COMDigit11PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1575|COMDigit11PPPPHgt|COMDigit11PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1576|COMDigit11PPPPNormHt|COMDigit11PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1577|COMDigit11PPPPOutside|COMDigit11PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1578|COMDigit11PPPPAngle|COMDigit11PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1579|COMDigit11PPPPIdealDiff|COMDigit11PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1580|COMDigit11PPPPDistCircum|COMDigit11PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1581|COMDigit11PPPPIsPersev|COMDigit11PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1582|COMDigit12PPPPSeq|COMDigit12PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|1583|COMDigit12PPPPStrokes|COMDigit12PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|1584|COMDigit12PPPPTime|COMDigit12PPPPTime|Num|8|BEST|11,471|2|11,471|||
|1585|COMDigit12PPPPLen|COMDigit12PPPPLen|Num|8|BEST|11,471|2|11,471|||
|1586|COMDigit12PPPPCentX|COMDigit12PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|1587|COMDigit12PPPPCentY|COMDigit12PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|1588|COMDigit12PPPPWidth|COMDigit12PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|1589|COMDigit12PPPPHgt|COMDigit12PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|1590|COMDigit12PPPPNormHt|COMDigit12PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|1591|COMDigit12PPPPOutside|COMDigit12PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|1592|COMDigit12PPPPAngle|COMDigit12PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|1593|COMDigit12PPPPIdealDiff|COMDigit12PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|1594|COMDigit12PPPPDistCircum|COMDigit12PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|1595|COMDigit12PPPPIsPersev|COMDigit12PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|1596|COMInter-TestLatency|COMInter-TestLatency|Num|8|BEST|11,471|173|91|||
|1597|COMMocaOverallScore.85hand|COMMocaOverallScore.85hand|Num|8|BEST|11,471|6|91|||
|1598|COMmocaEccen|COMmocaEccen|Num|8|BEST|11,471|11,296|175|||
|1599|COMmocaMaxAngGap|COMmocaMaxAngGap|Num|8|BEST|11,471|11,296|175|||
|1600|COMmocaMaxDist|COMmocaMaxDist|Num|8|BEST|11,471|2,356|175|||
|1601|COMmocaEllResidNorm|COMmocaEllResidNorm|Num|8|BEST|11,471|11,297|91|||
|1602|COMmocaNumbsMissing|COMmocaNumbsMissing|Num|8|BEST|11,471|4|91|||
|1603|COMmocaNumbsReptd|COMmocaNumbsReptd|Num|8|BEST|11,471|4|91|||
|1604|COMmocaOver12|COMmocaOver12|Num|8|BEST|11,471|4|91|||
|1605|COMmocaSeqErr|COMmocaSeqErr|Num|8|BEST|11,471|4|91|||
|1606|COMmocaInWrongQuad|COMmocaInWrongQuad|Num|8|BEST|11,471|4|91|||
|1607|COMmocaNotTwoHands|COMmocaNotTwoHands|Num|8|BEST|11,471|4|91|||
|1608|COMmocaHH11Angle|COMmocaHH11Angle|Num|8|BEST|11,471|10,228|1,242|||
|1609|COMmocaMH2Angle|COMmocaMH2Angle|Num|8|BEST|11,471|10,207|1,262|||
|1610|COMmocaHandRatio|COMmocaHandRatio|Num|8|BEST|11,471|10,656|815|||
|1611|COMmocaHandInterToCtrDistNorm|COMmocaHandInterToCtrDistNorm|Num|8|BEST|11,471|10,588|883|||
|1612|COMmocaScoreUpToEQHands|COMmocaScoreUpToEQHands|Num|8|BEST|11,471|6|91|||
|1613|COMmocaScoreAnyHands|COMmocaScoreAnyHands|Num|8|BEST|11,471|5|0|||
|1614|COMLPegsDomSecs|COMLPegsDomSecs|Num|8|BEST|11,471|2|11,471|||
|1615|COMLPegsDomNumDrops|COMLPegsDomNumDrops|Num|8|BEST|11,471|2|11,471|||
|1616|COMLPegsDomTScore|COMLPegsDomTScore|Num|8|BEST|11,471|2|11,471|||
|1617|COMLPegsNonDomSecs|COMLPegsNonDomSecs|Num|8|BEST|11,471|2|11,471|||
|1618|COMLPegsNonDomNumDrops|COMLPegsNonDomNumDrops|Num|8|BEST|11,471|2|11,471|||
|1619|COMLPegsNonDomTScore|COMLPegsNonDomTScore|Num|8|BEST|11,471|2|11,471|||
|1620|COMGripDomRaw|COMGripDomRaw|Num|8|BEST|11,471|2|11,471|||
|1621|COMGripDomTScore|COMGripDomTScore|Num|8|BEST|11,471|2|11,471|||
|1622|COMGripNonDomRaw|COMGripNonDomRaw|Num|8|BEST|11,471|2|11,471|||
|1623|COMGripNonDomTScore|COMGripNonDomTScore|Num|8|BEST|11,471|2|11,471|||
|1624|COMTapDomRaw|COMTapDomRaw|Num|8|BEST|11,471|2|11,471|||
|1625|COMTapDomTScore|COMTapDomTScore|Num|8|BEST|11,471|2|11,471|||
|1626|COMTapNonDomRaw|COMTapNonDomRaw|Num|8|BEST|11,471|2|11,471|||
|1627|COMTapNonDomTScore|COMTapNonDomTScore|Num|8|BEST|11,471|2|11,471|||
|1628|COMDigitWAISFwdRaw|COMDigitWAISFwdRaw|Num|8|BEST|11,471|2|11,471|||
|1629|COMDigitWAISFwdLongest|COMDigitWAISFwdLongest|Num|8|BEST|11,471|2|11,471|||
|1630|COMDigitWAISFwdAgeScaledScore|COMDigitWAISFwdAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1631|COMDigitWAISFwdAnyOrder|COMDigitWAISFwdAnyOrder|Num|8|BEST|11,471|2|11,471|||
|1632|COMDigitWAISFwdSerialOrder|COMDigitWAISFwdSerialOrder|Num|8|BEST|11,471|2|11,471|||
|1633|COMDigitWAISBwdRaw|COMDigitWAISBwdRaw|Num|8|BEST|11,471|2|11,471|||
|1634|COMDigitWAISBwdLongest|COMDigitWAISBwdLongest|Num|8|BEST|11,471|2|11,471|||
|1635|COMDigitWAISBwdAgeScaledScore|COMDigitWAISBwdAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1636|COMDigitWAISBwdAnyOrder|COMDigitWAISBwdAnyOrder|Num|8|BEST|11,471|2|11,471|||
|1637|COMDigitWAISBwdSerialOrder|COMDigitWAISBwdSerialOrder|Num|8|BEST|11,471|2|11,471|||
|1638|COMDigitWAISSeqRaw|COMDigitWAISSeqRaw|Num|8|BEST|11,471|2|11,471|||
|1639|COMDigitWAISSeqLongest|COMDigitWAISSeqLongest|Num|8|BEST|11,471|2|11,471|||
|1640|COMDigitWAISSeqAgeScaledScore|COMDigitWAISSeqAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1641|COMDigitWAISTotRaw|COMDigitWAISTotRaw|Num|8|BEST|11,471|2|11,471|||
|1642|COMDigitWAISTotAgeScaledScore|COMDigitWAISTotAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1643|COMSpatialWMSIIIFwdRaw|COMSpatialWMSIIIFwdRaw|Num|8|BEST|11,471|2|11,471|||
|1644|COMSpatialWMSIIIFwdLongestSpan|COMSpatialWMSIIIFwdLongestSpan|Num|8|BEST|11,471|2|11,471|||
|1645|COMSpatialWMSIIIFwdAgeScaledScor|COMSpatialWMSIIIFwdAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1646|COMSpatialWMSIIIRevRaw|COMSpatialWMSIIIRevRaw|Num|8|BEST|11,471|2|11,471|||
|1647|COMSpatialWMSIIIRevLongestSpan|COMSpatialWMSIIIRevLongestSpan|Num|8|BEST|11,471|2|11,471|||
|1648|COMSpatialWMSIIIRevAgeScaledScor|COMSpatialWMSIIIRevAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1649|COMSpatialWMSIIITotalRaw|COMSpatialWMSIIITotalRaw|Num|8|BEST|11,471|2|11,471|||
|1650|COMSpatialWMSIIITotalAgeScaledSc|COMSpatialWMSIIITotalAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1651|COMReitanTrailsABTrailsASecs|COMReitanTrailsABTrailsASecs|Num|8|BEST|11,471|2|11,471|||
|1652|COMReitanTrailsABTrailsANumErrs|COMReitanTrailsABTrailsANumErrs|Num|8|BEST|11,471|2|11,471|||
|1653|COMReitanTrailsABTrailsAAgeScale|COMReitanTrailsABTrailsAAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1654|COMReitanTrailsABTrailsATScore|COMReitanTrailsABTrailsATScore|Num|8|BEST|11,471|2|11,471|||
|1655|COMReitanTrailsABTrailsBSecs|COMReitanTrailsABTrailsBSecs|Num|8|BEST|11,471|2|11,471|||
|1656|COMReitanTrailsABTrailsBNumErrs|COMReitanTrailsABTrailsBNumErrs|Num|8|BEST|11,471|2|11,471|||
|1657|COMReitanTrailsABTrailsBAgeScale|COMReitanTrailsABTrailsBAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1658|COMReitanTrailsABTrailsBTScore|COMReitanTrailsABTrailsBTScore|Num|8|BEST|11,471|2|11,471|||
|1659|COMTrailsD-KEFDKEF1Secs|COMTrailsD-KEFDKEF1Secs|Num|8|BEST|11,471|2|11,471|||
|1660|COMTrailsD-KEFDKEF1NumErrs|COMTrailsD-KEFDKEF1NumErrs|Num|8|BEST|11,471|2|11,471|||
|1661|COMTrailsD-KEFDKEF1AgeScaledScor|COMTrailsD-KEFDKEF1AgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1662|COMTrailsD-KEFDKEF2Secs|COMTrailsD-KEFDKEF2Secs|Num|8|BEST|11,471|2|11,471|||
|1663|COMTrailsD-KEFDKEF2NumErrs|COMTrailsD-KEFDKEF2NumErrs|Num|8|BEST|11,471|2|11,471|||
|1664|COMTrailsD-KEFDKEF2AgeScaledScor|COMTrailsD-KEFDKEF2AgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1665|COMTrailsD-KEFDKEF3Secs|COMTrailsD-KEFDKEF3Secs|Num|8|BEST|11,471|2|11,471|||
|1666|COMTrailsD-KEFDKEF3NumErrs|COMTrailsD-KEFDKEF3NumErrs|Num|8|BEST|11,471|2|11,471|||
|1667|COMTrailsD-KEFDKEF3AgeScaledScor|COMTrailsD-KEFDKEF3AgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1668|COMTrailsD-KEFDKEF4Secs|COMTrailsD-KEFDKEF4Secs|Num|8|BEST|11,471|2|11,471|||
|1669|COMTrailsD-KEFDKEF4NumErrs|COMTrailsD-KEFDKEF4NumErrs|Num|8|BEST|11,471|2|11,471|||
|1670|COMTrailsD-KEFDKEF4AgeScaledScor|COMTrailsD-KEFDKEF4AgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1671|COMTrailsD-KEFDKEF5Secs|COMTrailsD-KEFDKEF5Secs|Num|8|BEST|11,471|2|11,471|||
|1672|COMTrailsD-KEFDKEF5NumErrs|COMTrailsD-KEFDKEF5NumErrs|Num|8|BEST|11,471|2|11,471|||
|1673|COMTrailsD-KEFDKEF5AgeScaledScor|COMTrailsD-KEFDKEF5AgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1674|COMVigilVigilKOmisNorm|COMVigilVigilKOmisNorm|Num|8|BEST|11,471|2|11,471|||
|1675|COMVigilVigilKComisNorm|COMVigilVigilKComisNorm|Num|8|BEST|11,471|2|11,471|||
|1676|COMVigilVigilKMsecNorm|COMVigilVigilKMsecNorm|Num|8|BEST|11,471|2|11,471|||
|1677|COMVigilVigilKOmisScore|COMVigilVigilKOmisScore|Num|8|BEST|11,471|2|11,471|||
|1678|COMVigilVigilKComisScore|COMVigilVigilKComisScore|Num|8|BEST|11,471|2|11,471|||
|1679|COMVigilVigilKMsecScore|COMVigilVigilKMsecScore|Num|8|BEST|11,471|2|11,471|||
|1680|COMVigilVigilAKOmisNorm|COMVigilVigilAKOmisNorm|Num|8|BEST|11,471|2|11,471|||
|1681|COMVigilVigilAKComisNorm|COMVigilVigilAKComisNorm|Num|8|BEST|11,471|2|11,471|||
|1682|COMVigilVigilAKMsecNorm|COMVigilVigilAKMsecNorm|Num|8|BEST|11,471|2|11,471|||
|1683|COMVigilVigilAKOmisScore|COMVigilVigilAKOmisScore|Num|8|BEST|11,471|2|11,471|||
|1684|COMVigilVigilAKComisScore|COMVigilVigilAKComisScore|Num|8|BEST|11,471|2|11,471|||
|1685|COMVigilVigilAKMsecScore|COMVigilVigilAKMsecScore|Num|8|BEST|11,471|2|11,471|||
|1686|COMBNTTestInfoStartNum|COMBNTTestInfoStartNum|Num|8|BEST|11,471|2|11,471|||
|1687|COMBNTTestInfoNumAdmin|COMBNTTestInfoNumAdmin|Num|8|BEST|11,471|2|11,471|||
|1688|COMBNTCorr-NoCueNumb|COMBNTCorr-NoCueNumb|Num|8|BEST|11,471|2|11,471|||
|1689|COMBNTCorr-NoCueAgeScaled|COMBNTCorr-NoCueAgeScaled|Num|8|BEST|11,471|2|11,471|||
|1690|COMBNTCorr-NoCueTScore|COMBNTCorr-NoCueTScore|Num|8|BEST|11,471|2|11,471|||
|1691|COMBNTCorrPhonCueNumb|COMBNTCorrPhonCueNumb|Num|8|BEST|11,471|2|11,471|||
|1692|COMBNTCorrSemCueNumb|COMBNTCorrSemCueNumb|Num|8|BEST|11,471|2|11,471|||
|1693|COMBNTPhonParaNumb|COMBNTPhonParaNumb|Num|8|BEST|11,471|2|11,471|||
|1694|COMBNTSemParaNumb|COMBNTSemParaNumb|Num|8|BEST|11,471|2|11,471|||
|1695|COMBNTNeolNumb|COMBNTNeolNumb|Num|8|BEST|11,471|2|11,471|||
|1696|COMBNTPercepErrNumb|COMBNTPercepErrNumb|Num|8|BEST|11,471|2|11,471|||
|1697|COMBNTPersevNumb|COMBNTPersevNumb|Num|8|BEST|11,471|2|11,471|||
|1698|COMBNTCircumlocNumb|COMBNTCircumlocNumb|Num|8|BEST|11,471|2|11,471|||
|1699|COMVerbFlDKDEFSLtrs0-15SecFB|COMVerbFlDKDEFSLtrs0-15SecFB|Num|8|BEST|11,471|2|11,471|||
|1700|COMVerbFlDKDEFSLtrs0-15SecAH|COMVerbFlDKDEFSLtrs0-15SecAH|Num|8|BEST|11,471|2|11,471|||
|1701|COMVerbFlDKDEFSLtrs0-15SecSR|COMVerbFlDKDEFSLtrs0-15SecSR|Num|8|BEST|11,471|2|11,471|||
|1702|COMVerbFlDKDEFSLtrs0-15SecAgeScS|COMVerbFlDKDEFSLtrs0-15SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1703|COMVerbFlDKDEFSLtrs15-30SecFB|COMVerbFlDKDEFSLtrs15-30SecFB|Num|8|BEST|11,471|2|11,471|||
|1704|COMVerbFlDKDEFSLtrs15-30SecAH|COMVerbFlDKDEFSLtrs15-30SecAH|Num|8|BEST|11,471|2|11,471|||
|1705|COMVerbFlDKDEFSLtrs15-30SecSR|COMVerbFlDKDEFSLtrs15-30SecSR|Num|8|BEST|11,471|2|11,471|||
|1706|COMVerbFlDKDEFSLtrs15-30SecAgeSc|COMVerbFlDKDEFSLtrs15-30SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1707|COMVerbFlDKDEFSLtrs30-45SecFB|COMVerbFlDKDEFSLtrs30-45SecFB|Num|8|BEST|11,471|2|11,471|||
|1708|COMVerbFlDKDEFSLtrs30-45SecAH|COMVerbFlDKDEFSLtrs30-45SecAH|Num|8|BEST|11,471|2|11,471|||
|1709|COMVerbFlDKDEFSLtrs30-45SecSR|COMVerbFlDKDEFSLtrs30-45SecSR|Num|8|BEST|11,471|2|11,471|||
|1710|COMVerbFlDKDEFSLtrs30-45SecAgeSc|COMVerbFlDKDEFSLtrs30-45SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1711|COMVerbFlDKDEFSLtrs45-60SecFB|COMVerbFlDKDEFSLtrs45-60SecFB|Num|8|BEST|11,471|2|11,471|||
|1712|COMVerbFlDKDEFSLtrs45-60SecAH|COMVerbFlDKDEFSLtrs45-60SecAH|Num|8|BEST|11,471|2|11,471|||
|1713|COMVerbFlDKDEFSLtrs45-60SecSR|COMVerbFlDKDEFSLtrs45-60SecSR|Num|8|BEST|11,471|2|11,471|||
|1714|COMVerbFlDKDEFSLtrs45-60SecAgeSc|COMVerbFlDKDEFSLtrs45-60SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1715|COMVerbFlDKDEFSLtrsTotalsFB|COMVerbFlDKDEFSLtrsTotalsFB|Num|8|BEST|11,471|2|11,471|||
|1716|COMVerbFlDKDEFSLtrsTotalsAH|COMVerbFlDKDEFSLtrsTotalsAH|Num|8|BEST|11,471|2|11,471|||
|1717|COMVerbFlDKDEFSLtrsTotalsSR|COMVerbFlDKDEFSLtrsTotalsSR|Num|8|BEST|11,471|2|11,471|||
|1718|COMVerbFlDKDEFSLtrsTotalsAgeScSc|COMVerbFlDKDEFSLtrsTotalsAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1719|COMVerbFlDKDEFSCateg0-15SecAnimC|COMVerbFlDKDEFSCateg0-15SecAnimCloth|Num|8|BEST|11,471|2|11,471|||
|1720|COMVerbFlDKDEFSCateg0-15SecBoyGi|COMVerbFlDKDEFSCateg0-15SecBoyGirl|Num|8|BEST|11,471|2|11,471|||
|1721|COMVerbFlDKDEFSCateg15-30SecAnim|COMVerbFlDKDEFSCateg15-30SecAnimCloth|Num|8|BEST|11,471|2|11,471|||
|1722|COMVerbFlDKDEFSCateg15-30SecBoyG|COMVerbFlDKDEFSCateg15-30SecBoyGirl|Num|8|BEST|11,471|2|11,471|||
|1723|COMVerbFlDKDEFSCateg30-45SecAnim|COMVerbFlDKDEFSCateg30-45SecAnimCloth|Num|8|BEST|11,471|2|11,471|||
|1724|COMVerbFlDKDEFSCateg30-45SecBoyG|COMVerbFlDKDEFSCateg30-45SecBoyGirl|Num|8|BEST|11,471|2|11,471|||
|1725|COMVerbFlDKDEFSCateg45-60SecAnim|COMVerbFlDKDEFSCateg45-60SecAnimCloth|Num|8|BEST|11,471|2|11,471|||
|1726|COMVerbFlDKDEFSCateg45-60SecBoyG|COMVerbFlDKDEFSCateg45-60SecBoyGirl|Num|8|BEST|11,471|2|11,471|||
|1727|COMVerbFlDKDEFSCategTotalsAnimCl|COMVerbFlDKDEFSCategTotalsAnimCloth|Num|8|BEST|11,471|2|11,471|||
|1728|COMVerbFlDKDEFSCategTotalsBoyGir|COMVerbFlDKDEFSCategTotalsBoyGirl|Num|8|BEST|11,471|2|11,471|||
|1729|COMVerbFlDKDEFSCategTotalsAgeScS|COMVerbFlDKDEFSCategTotalsAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1730|COMVerbFlDKDEFSSwitch0-15SecFFVM|COMVerbFlDKDEFSSwitch0-15SecFFVM|Num|8|BEST|11,471|2|11,471|||
|1731|COMVerbFlDKDEFSSwitch0-15SecAgeS|COMVerbFlDKDEFSSwitch0-15SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1732|COMVerbFlDKDEFSSwitch15-30SecFFV|COMVerbFlDKDEFSSwitch15-30SecFFVM|Num|8|BEST|11,471|2|11,471|||
|1733|COMVerbFlDKDEFSSwitch15-30SecAge|COMVerbFlDKDEFSSwitch15-30SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1734|COMVerbFlDKDEFSSwitch30-45SecFFV|COMVerbFlDKDEFSSwitch30-45SecFFVM|Num|8|BEST|11,471|2|11,471|||
|1735|COMVerbFlDKDEFSSwitch30-45SecAge|COMVerbFlDKDEFSSwitch30-45SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1736|COMVerbFlDKDEFSSwitch45-60SecFFV|COMVerbFlDKDEFSSwitch45-60SecFFVM|Num|8|BEST|11,471|2|11,471|||
|1737|COMVerbFlDKDEFSSwitch45-60SecAge|COMVerbFlDKDEFSSwitch45-60SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1738|COMVerbFlDKDEFSSwitchTotalsFFVM|COMVerbFlDKDEFSSwitchTotalsFFVM|Num|8|BEST|11,471|2|11,471|||
|1739|COMVerbFlDKDEFSSwitchTotalsAgeSc|COMVerbFlDKDEFSSwitchTotalsAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1740|COMVerbFlDKDEFSPctSeLossErrFFVM|COMVerbFlDKDEFSPctSeLossErrFFVM|Num|8|BEST|11,471|2|11,471|||
|1741|COMVerbFlDKDEFSPctSeLossErrAgeSc|COMVerbFlDKDEFSPctSeLossErrAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1742|COMVerbFlDKDEFSPctRepErrorFFVM|COMVerbFlDKDEFSPctRepErrorFFVM|Num|8|BEST|11,471|2|11,471|||
|1743|COMVerbFlDKDEFSPctRepErrorAgeScS|COMVerbFlDKDEFSPctRepErrorAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1744|COMVerbFlDKDEFSPctSwitchAccFFVM|COMVerbFlDKDEFSPctSwitchAccFFVM|Num|8|BEST|11,471|2|11,471|||
|1745|COMVerbFlDKDEFSPctSwitchAccAgeSc|COMVerbFlDKDEFSPctSwitchAccAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1746|COMVerbFlDKDEFSNEWTotCor0-15SecL|COMVerbFlDKDEFSNEWTotCor0-15SecLtrFluRaw|Num|8|BEST|11,471|2|11,471|||
|1747|COMVerbFlDKDEFSNEWTotCor0-15SecC|COMVerbFlDKDEFSNEWTotCor0-15SecCatFluRaw|Num|8|BEST|11,471|2|11,471|||
|1748|COMVerbFlDKDEFSNEWTotCor0-15Se_1|COMVerbFlDKDEFSNEWTotCor0-15SecCategSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1749|COMVerbFlDKDEFSNEWTotCor0-15SecT|COMVerbFlDKDEFSNEWTotCor0-15SecTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1750|COMVerbFlDKDEFSNEWTotCor0-15SecA|COMVerbFlDKDEFSNEWTotCor0-15SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1751|COMVerbFlDKDEFSNEWTotCor15-30Sec|COMVerbFlDKDEFSNEWTotCor15-30SecLtrFluRaw|Num|8|BEST|11,471|2|11,471|||
|1752|COMVerbFlDKDEFSNEWTotCor15-30S_1|COMVerbFlDKDEFSNEWTotCor15-30SecCatFluRaw|Num|8|BEST|11,471|2|11,471|||
|1753|COMVerbFlDKDEFSNEWTotCor15-30S_2|COMVerbFlDKDEFSNEWTotCor15-30SecCategSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1754|COMVerbFlDKDEFSNEWTotCor15-30S_3|COMVerbFlDKDEFSNEWTotCor15-30SecTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1755|COMVerbFlDKDEFSNEWTotCor15-30S_4|COMVerbFlDKDEFSNEWTotCor15-30SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1756|COMVerbFlDKDEFSNEWTotCor30-45Sec|COMVerbFlDKDEFSNEWTotCor30-45SecLtrFluRaw|Num|8|BEST|11,471|2|11,471|||
|1757|COMVerbFlDKDEFSNEWTotCor30-45S_1|COMVerbFlDKDEFSNEWTotCor30-45SecCatFluRaw|Num|8|BEST|11,471|2|11,471|||
|1758|COMVerbFlDKDEFSNEWTotCor30-45S_2|COMVerbFlDKDEFSNEWTotCor30-45SecCategSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1759|COMVerbFlDKDEFSNEWTotCor30-45S_3|COMVerbFlDKDEFSNEWTotCor30-45SecTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1760|COMVerbFlDKDEFSNEWTotCor30-45S_4|COMVerbFlDKDEFSNEWTotCor30-45SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1761|COMVerbFlDKDEFSNEWTotCor45-60Sec|COMVerbFlDKDEFSNEWTotCor45-60SecLtrFluRaw|Num|8|BEST|11,471|2|11,471|||
|1762|COMVerbFlDKDEFSNEWTotCor45-60S_1|COMVerbFlDKDEFSNEWTotCor45-60SecCatFluRaw|Num|8|BEST|11,471|2|11,471|||
|1763|COMVerbFlDKDEFSNEWTotCor45-60S_2|COMVerbFlDKDEFSNEWTotCor45-60SecCategSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1764|COMVerbFlDKDEFSNEWTotCor45-60S_3|COMVerbFlDKDEFSNEWTotCor45-60SecTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1765|COMVerbFlDKDEFSNEWTotCor45-60S_4|COMVerbFlDKDEFSNEWTotCor45-60SecAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1766|COMVerbFlDKDEFSNEWSet-LossErrLtr|COMVerbFlDKDEFSNEWSet-LossErrLtrFluRaw|Num|8|BEST|11,471|2|11,471|||
|1767|COMVerbFlDKDEFSNEWSet-LossErrCat|COMVerbFlDKDEFSNEWSet-LossErrCatFluRaw|Num|8|BEST|11,471|2|11,471|||
|1768|COMVerbFlDKDEFSNEWSet-LossErrC_1|COMVerbFlDKDEFSNEWSet-LossErrCategSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1769|COMVerbFlDKDEFSNEWSet-LossErrTot|COMVerbFlDKDEFSNEWSet-LossErrTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1770|COMVerbFlDKDEFSNEWSet-LossErrAge|COMVerbFlDKDEFSNEWSet-LossErrAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1771|COMVerbFlDKDEFSNEWRepErrLtrFluRa|COMVerbFlDKDEFSNEWRepErrLtrFluRaw|Num|8|BEST|11,471|2|11,471|||
|1772|COMVerbFlDKDEFSNEWRepErrCatFluRa|COMVerbFlDKDEFSNEWRepErrCatFluRaw|Num|8|BEST|11,471|2|11,471|||
|1773|COMVerbFlDKDEFSNEWRepErrCategSwi|COMVerbFlDKDEFSNEWRepErrCategSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1774|COMVerbFlDKDEFSNEWRepErrTotRawSc|COMVerbFlDKDEFSNEWRepErrTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1775|COMVerbFlDKDEFSNEWRepErrAgeScSco|COMVerbFlDKDEFSNEWRepErrAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1776|COMVerbFlDKDEFSNEWTotResponsesTo|COMVerbFlDKDEFSNEWTotResponsesTotLtrFlu|Num|8|BEST|11,471|2|11,471|||
|1777|COMVerbFlDKDEFSNEWTotResponses_1|COMVerbFlDKDEFSNEWTotResponsesTotCatFlu|Num|8|BEST|11,471|2|11,471|||
|1778|COMVerbFlDKDEFSNEWTotResponses_2|COMVerbFlDKDEFSNEWTotResponsesTotCategSwitch|Num|8|BEST|11,471|2|11,471|||
|1779|COMVerbFlDKDEFSNEWTotResponses_3|COMVerbFlDKDEFSNEWTotResponsesTotRawScore|Num|8|BEST|11,471|2|11,471|||
|1780|COMVerbFlDKDEFSNEWLetFluTotCorRa|COMVerbFlDKDEFSNEWLetFluTotCorRaw|Num|8|BEST|11,471|2|11,471|||
|1781|COMVerbFlDKDEFSNEWLetFluAgeScSco|COMVerbFlDKDEFSNEWLetFluAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1782|COMVerbFlDKDEFSNEWCatFluTotCorRa|COMVerbFlDKDEFSNEWCatFluTotCorRaw|Num|8|BEST|11,471|2|11,471|||
|1783|COMVerbFlDKDEFSNEWCatFluAgeScSco|COMVerbFlDKDEFSNEWCatFluAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1784|COMVerbFlDKDEFSNEWCategSwTotCorR|COMVerbFlDKDEFSNEWCategSwTotCorRespRaw|Num|8|BEST|11,471|2|11,471|||
|1785|COMVerbFlDKDEFSNEWCategSwTotCorS|COMVerbFlDKDEFSNEWCategSwTotCorScaledScore|Num|8|BEST|11,471|2|11,471|||
|1786|COMVerbFlDKDEFSNEWCategSwTotSwAc|COMVerbFlDKDEFSNEWCategSwTotSwAccRaw|Num|8|BEST|11,471|2|11,471|||
|1787|COMVerbFlDKDEFSNEWCategSwTotSwSc|COMVerbFlDKDEFSNEWCategSwTotSwScaledScore|Num|8|BEST|11,471|2|11,471|||
|1788|COMVerbFlDKDEFSNEWPctSeLossErrPc|COMVerbFlDKDEFSNEWPctSeLossErrPctRawScore|Num|8|BEST|11,471|2|11,471|||
|1789|COMVerbFlDKDEFSNEWPctSeLossErrAg|COMVerbFlDKDEFSNEWPctSeLossErrAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1790|COMVerbFlDKDEFSNEWPctRepErrorPct|COMVerbFlDKDEFSNEWPctRepErrorPctRawScore|Num|8|BEST|11,471|2|11,471|||
|1791|COMVerbFlDKDEFSNEWPctRepErrorAge|COMVerbFlDKDEFSNEWPctRepErrorAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1792|COMVerbFlDKDEFSNEWPctSwitchAccPc|COMVerbFlDKDEFSNEWPctSwitchAccPctRawScore|Num|8|BEST|11,471|2|11,471|||
|1793|COMVerbFlDKDEFSNEWPctSwitchAccAg|COMVerbFlDKDEFSNEWPctSwitchAccAgeScScore|Num|8|BEST|11,471|2|11,471|||
|1794|COMVerbFlCOWATLtrs0-15SecF|COMVerbFlCOWATLtrs0-15SecF|Num|8|BEST|11,471|2|11,471|||
|1795|COMVerbFlCOWATLtrs0-15SecA|COMVerbFlCOWATLtrs0-15SecA|Num|8|BEST|11,471|2|11,471|||
|1796|COMVerbFlCOWATLtrs0-15SecS|COMVerbFlCOWATLtrs0-15SecS|Num|8|BEST|11,471|2|11,471|||
|1797|COMVerbFlCOWATLtrs0-15SecTScore|COMVerbFlCOWATLtrs0-15SecTScore|Num|8|BEST|11,471|2|11,471|||
|1798|COMVerbFlCOWATLtrs15-30SecF|COMVerbFlCOWATLtrs15-30SecF|Num|8|BEST|11,471|2|11,471|||
|1799|COMVerbFlCOWATLtrs15-30SecA|COMVerbFlCOWATLtrs15-30SecA|Num|8|BEST|11,471|2|11,471|||
|1800|COMVerbFlCOWATLtrs15-30SecS|COMVerbFlCOWATLtrs15-30SecS|Num|8|BEST|11,471|2|11,471|||
|1801|COMVerbFlCOWATLtrs15-30SecTScore|COMVerbFlCOWATLtrs15-30SecTScore|Num|8|BEST|11,471|2|11,471|||
|1802|COMVerbFlCOWATLtrs30-45SecF|COMVerbFlCOWATLtrs30-45SecF|Num|8|BEST|11,471|2|11,471|||
|1803|COMVerbFlCOWATLtrs30-45SecA|COMVerbFlCOWATLtrs30-45SecA|Num|8|BEST|11,471|2|11,471|||
|1804|COMVerbFlCOWATLtrs30-45SecS|COMVerbFlCOWATLtrs30-45SecS|Num|8|BEST|11,471|2|11,471|||
|1805|COMVerbFlCOWATLtrs30-45SecTScore|COMVerbFlCOWATLtrs30-45SecTScore|Num|8|BEST|11,471|2|11,471|||
|1806|COMVerbFlCOWATLtrs45-60SecF|COMVerbFlCOWATLtrs45-60SecF|Num|8|BEST|11,471|2|11,471|||
|1807|COMVerbFlCOWATLtrs45-60SecA|COMVerbFlCOWATLtrs45-60SecA|Num|8|BEST|11,471|2|11,471|||
|1808|COMVerbFlCOWATLtrs45-60SecS|COMVerbFlCOWATLtrs45-60SecS|Num|8|BEST|11,471|2|11,471|||
|1809|COMVerbFlCOWATLtrs45-60SecTScore|COMVerbFlCOWATLtrs45-60SecTScore|Num|8|BEST|11,471|2|11,471|||
|1810|COMVerbFlCOWATLtrsTotalsF|COMVerbFlCOWATLtrsTotalsF|Num|8|BEST|11,471|2|11,471|||
|1811|COMVerbFlCOWATLtrsTotalsA|COMVerbFlCOWATLtrsTotalsA|Num|8|BEST|11,471|2|11,471|||
|1812|COMVerbFlCOWATLtrsTotalsS|COMVerbFlCOWATLtrsTotalsS|Num|8|BEST|11,471|2|11,471|||
|1813|COMVerbFlCOWATLtrsTotalsTScore|COMVerbFlCOWATLtrsTotalsTScore|Num|8|BEST|11,471|2|11,471|||
|1814|COMVerbFlCOWATCateg0-15SecAnimal|COMVerbFlCOWATCateg0-15SecAnimals|Num|8|BEST|11,471|2|11,471|||
|1815|COMVerbFlCOWATCateg15-30SecAnima|COMVerbFlCOWATCateg15-30SecAnimals|Num|8|BEST|11,471|2|11,471|||
|1816|COMVerbFlCOWATCateg30-45SecAnima|COMVerbFlCOWATCateg30-45SecAnimals|Num|8|BEST|11,471|2|11,471|||
|1817|COMVerbFlCOWATCateg45-60SecAnima|COMVerbFlCOWATCateg45-60SecAnimals|Num|8|BEST|11,471|2|11,471|||
|1818|COMVerbFlCOWATCategTotalsAnimals|COMVerbFlCOWATCategTotalsAnimals|Num|8|BEST|11,471|2|11,471|||
|1819|COMVerbFlCOWATCategTotalsTScore|COMVerbFlCOWATCategTotalsTScore|Num|8|BEST|11,471|2|11,471|||
|1820|COMVerbFlCOWATLetterTotIntru|COMVerbFlCOWATLetterTotIntru|Num|8|BEST|11,471|2|11,471|||
|1821|COMVerbFlCOWATLetterTotPersev|COMVerbFlCOWATLetterTotPersev|Num|8|BEST|11,471|2|11,471|||
|1822|COMVerbFlCOWATCategTotIntru|COMVerbFlCOWATCategTotIntru|Num|8|BEST|11,471|2|11,471|||
|1823|COMVerbFlCOWATCategTotPersev|COMVerbFlCOWATCategTotPersev|Num|8|BEST|11,471|2|11,471|||
|1824|COMVerbFlCOWATCategTotSO|COMVerbFlCOWATCategTotSO|Num|8|BEST|11,471|2|11,471|||
|1825|COMVerbFlCOWATCategTotAI|COMVerbFlCOWATCategTotAI|Num|8|BEST|11,471|2|11,471|||
|1826|COMSTROOPD-KEFSColorNameSecs|COMSTROOPD-KEFSColorNameSecs|Num|8|BEST|11,471|2|11,471|||
|1827|COMSTROOPD-KEFSColorNameErrsCorr|COMSTROOPD-KEFSColorNameErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1828|COMSTROOPD-KEFSColorNameErrsUnco|COMSTROOPD-KEFSColorNameErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1829|COMSTROOPD-KEFSColorNameAgeScale|COMSTROOPD-KEFSColorNameAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1830|COMSTROOPD-KEFSWordReadSecs|COMSTROOPD-KEFSWordReadSecs|Num|8|BEST|11,471|2|11,471|||
|1831|COMSTROOPD-KEFSWordReadErrsCorre|COMSTROOPD-KEFSWordReadErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1832|COMSTROOPD-KEFSWordReadErrsUncor|COMSTROOPD-KEFSWordReadErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1833|COMSTROOPD-KEFSWordReadAgeScaled|COMSTROOPD-KEFSWordReadAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1834|COMSTROOPD-KEFSInterferenceSecs|COMSTROOPD-KEFSInterferenceSecs|Num|8|BEST|11,471|2|11,471|||
|1835|COMSTROOPD-KEFSInterferenceErrsC|COMSTROOPD-KEFSInterferenceErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1836|COMSTROOPD-KEFSInterferenceErrsU|COMSTROOPD-KEFSInterferenceErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1837|COMSTROOPD-KEFSInterferenceAgeSc|COMSTROOPD-KEFSInterferenceAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1838|COMSTROOPD-KEFSSwitchingSecs|COMSTROOPD-KEFSSwitchingSecs|Num|8|BEST|11,471|2|11,471|||
|1839|COMSTROOPD-KEFSSwitchingErrsCorr|COMSTROOPD-KEFSSwitchingErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1840|COMSTROOPD-KEFSSwitchingErrsUnco|COMSTROOPD-KEFSSwitchingErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1841|COMSTROOPD-KEFSSwitchingAgeScale|COMSTROOPD-KEFSSwitchingAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1842|COMSTROOPColorNameSecs|COMSTROOPColorNameSecs|Num|8|BEST|11,471|2|11,471|||
|1843|COMSTROOPColorNameErrsCorrected|COMSTROOPColorNameErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1844|COMSTROOPColorNameErrsUncorrecte|COMSTROOPColorNameErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1845|COMSTROOPColorNameAgeScaledScore|COMSTROOPColorNameAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1846|COMSTROOPWordReadSecs|COMSTROOPWordReadSecs|Num|8|BEST|11,471|2|11,471|||
|1847|COMSTROOPWordReadErrsCorrected|COMSTROOPWordReadErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1848|COMSTROOPWordReadErrsUncorrected|COMSTROOPWordReadErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1849|COMSTROOPWordReadAgeScaledScore|COMSTROOPWordReadAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1850|COMSTROOPInterferenceSecs|COMSTROOPInterferenceSecs|Num|8|BEST|11,471|2|11,471|||
|1851|COMSTROOPInterferenceErrsCorrect|COMSTROOPInterferenceErrsCorrected|Num|8|BEST|11,471|2|11,471|||
|1852|COMSTROOPInterferenceErrsUncorre|COMSTROOPInterferenceErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1853|COMSTROOPInterferenceAgeScaledSc|COMSTROOPInterferenceAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1854|COMWRATSpellingRaw|COMWRATSpellingRaw|Num|8|BEST|11,471|2|11,471|||
|1855|COMWRATSpellingStandd|COMWRATSpellingStandd|Num|8|BEST|11,471|2|11,471|||
|1856|COMWRATSpellingPercentile|COMWRATSpellingPercentile|Num|8|BEST|11,471|2|11,471|||
|1857|COMWRATMathRaw|COMWRATMathRaw|Num|8|BEST|11,471|2|11,471|||
|1858|COMWRATMathStandd|COMWRATMathStandd|Num|8|BEST|11,471|2|11,471|||
|1859|COMWRATMathPercentile|COMWRATMathPercentile|Num|8|BEST|11,471|2|11,471|||
|1860|COMWRATReadingRaw|COMWRATReadingRaw|Num|8|BEST|11,471|2|11,471|||
|1861|COMWRATReadingStandd|COMWRATReadingStandd|Num|8|BEST|11,471|2|11,471|||
|1862|COMWRATReadingPercentile|COMWRATReadingPercentile|Num|8|BEST|11,471|2|11,471|||
|1863|COMWRATSentCompRaw|COMWRATSentCompRaw|Num|8|BEST|11,471|2|11,471|||
|1864|COMWRATSentCompStandd|COMWRATSentCompStandd|Num|8|BEST|11,471|2|11,471|||
|1865|COMWRATSentCompPercentile|COMWRATSentCompPercentile|Num|8|BEST|11,471|2|11,471|||
|1866|COMWRATAMNARTIQIQ|COMWRATAMNARTIQIQ|Num|8|BEST|11,471|2|11,471|||
|1867|COMHOOPERScoresRaw|COMHOOPERScoresRaw|Num|8|BEST|11,471|2|11,471|||
|1868|COMDKEFSDESIGNFilledRaw|COMDKEFSDESIGNFilledRaw|Num|8|BEST|11,471|2|11,471|||
|1869|COMDKEFSDESIGNFilledErrsUncorrec|COMDKEFSDESIGNFilledErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1870|COMDKEFSDESIGNFilledAgeScaledSco|COMDKEFSDESIGNFilledAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1871|COMDKEFSDESIGNEmptyRaw|COMDKEFSDESIGNEmptyRaw|Num|8|BEST|11,471|2|11,471|||
|1872|COMDKEFSDESIGNEmptyErrsUncorrect|COMDKEFSDESIGNEmptyErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1873|COMDKEFSDESIGNEmptyAgeScaledScor|COMDKEFSDESIGNEmptyAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1874|COMDKEFSDESIGNSwitchRaw|COMDKEFSDESIGNSwitchRaw|Num|8|BEST|11,471|2|11,471|||
|1875|COMDKEFSDESIGNSwitchErrsUncorrec|COMDKEFSDESIGNSwitchErrsUncorrected|Num|8|BEST|11,471|2|11,471|||
|1876|COMDKEFSDESIGNSwitchAgeScaledSco|COMDKEFSDESIGNSwitchAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1877|COMDKEFSDESIGNTotSetLossRaw|COMDKEFSDESIGNTotSetLossRaw|Num|8|BEST|11,471|2|11,471|||
|1878|COMDKEFSDESIGNTotSetLossAgeScale|COMDKEFSDESIGNTotSetLossAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1879|COMDKEFSDESIGNTotRepeatRaw|COMDKEFSDESIGNTotRepeatRaw|Num|8|BEST|11,471|2|11,471|||
|1880|COMDKEFSDESIGNTotRepeatAgeScaled|COMDKEFSDESIGNTotRepeatAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1881|COMDKEFSDESIGNTotAttemptRaw|COMDKEFSDESIGNTotAttemptRaw|Num|8|BEST|11,471|2|11,471|||
|1882|COMDKEFSDESIGNTotAttemptAgeScale|COMDKEFSDESIGNTotAttemptAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1883|COMDKEFSDESIGNDesignAccAccPct|COMDKEFSDESIGNDesignAccAccPct|Num|8|BEST|11,471|2|11,471|||
|1884|COMDKEFSDESIGNDesignAccAgeScaled|COMDKEFSDESIGNDesignAccAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1885|COMWMSInfoOrientNoCorrect|COMWMSInfoOrientNoCorrect|Num|8|BEST|11,471|2|11,471|||
|1886|COMWMSInfoOrientAgeSS|COMWMSInfoOrientAgeSS|Num|8|BEST|11,471|2|11,471|||
|1887|COMWMSMentCtlScore|COMWMSMentCtlScore|Num|8|BEST|11,471|2|11,471|||
|1888|COMWMSMentCtlAgeSS|COMWMSMentCtlAgeSS|Num|8|BEST|11,471|2|11,471|||
|1889|COMWMSVerbImmPartA|COMWMSVerbImmPartA|Num|8|BEST|11,471|2|11,471|||
|1890|COMWMSVerbImmPartB1|COMWMSVerbImmPartB1|Num|8|BEST|11,471|2|11,471|||
|1891|COMWMSVerbImmPartB2|COMWMSVerbImmPartB2|Num|8|BEST|11,471|2|11,471|||
|1892|COMWMSVerbImmTotal|COMWMSVerbImmTotal|Num|8|BEST|11,471|2|11,471|||
|1893|COMWMSVerbImmAgeScaledScore|COMWMSVerbImmAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1894|COMWMSVerbDelayedPartA|COMWMSVerbDelayedPartA|Num|8|BEST|11,471|2|11,471|||
|1895|COMWMSVerbDelayedPartB1|COMWMSVerbDelayedPartB1|Num|8|BEST|11,471|2|11,471|||
|1896|COMWMSVerbDelayedTotal|COMWMSVerbDelayedTotal|Num|8|BEST|11,471|2|11,471|||
|1897|COMWMSVerbDelayedAgeScaledScore|COMWMSVerbDelayedAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1898|COMWMSVerbPctRecPct|COMWMSVerbPctRecPct|Num|8|BEST|11,471|2|11,471|||
|1899|COMWMSVerbPctRecAgeSS|COMWMSVerbPctRecAgeSS|Num|8|BEST|11,471|2|11,471|||
|1900|COMWMSVerbRecogScoreA|COMWMSVerbRecogScoreA|Num|8|BEST|11,471|2|11,471|||
|1901|COMWMSVerbRecogScoreB|COMWMSVerbRecogScoreB|Num|8|BEST|11,471|2|11,471|||
|1902|COMWMSVerbRecogTotal|COMWMSVerbRecogTotal|Num|8|BEST|11,471|2|11,471|||
|1903|COMWMSVerbRecogAgeSS|COMWMSVerbRecogAgeSS|Num|8|BEST|11,471|2|11,471|||
|1904|COMWMSVisImmDesign1|COMWMSVisImmDesign1|Num|8|BEST|11,471|2|11,471|||
|1905|COMWMSVisImmDesign2|COMWMSVisImmDesign2|Num|8|BEST|11,471|2|11,471|||
|1906|COMWMSVisImmDesign3|COMWMSVisImmDesign3|Num|8|BEST|11,471|2|11,471|||
|1907|COMWMSVisImmDesign4|COMWMSVisImmDesign4|Num|8|BEST|11,471|2|11,471|||
|1908|COMWMSVisImmDesign5|COMWMSVisImmDesign5|Num|8|BEST|11,471|2|11,471|||
|1909|COMWMSVisImmTotal|COMWMSVisImmTotal|Num|8|BEST|11,471|2|11,471|||
|1910|COMWMSVisImmAgeScaledScore|COMWMSVisImmAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1911|COMWMSVisDelayedDesign1|COMWMSVisDelayedDesign1|Num|8|BEST|11,471|2|11,471|||
|1912|COMWMSVisDelayedDesign2|COMWMSVisDelayedDesign2|Num|8|BEST|11,471|2|11,471|||
|1913|COMWMSVisDelayedDesign3|COMWMSVisDelayedDesign3|Num|8|BEST|11,471|2|11,471|||
|1914|COMWMSVisDelayedDesign4|COMWMSVisDelayedDesign4|Num|8|BEST|11,471|2|11,471|||
|1915|COMWMSVisDelayedDesign5|COMWMSVisDelayedDesign5|Num|8|BEST|11,471|2|11,471|||
|1916|COMWMSVisDelayedTotal|COMWMSVisDelayedTotal|Num|8|BEST|11,471|2|11,471|||
|1917|COMWMSVisDelayedAgeScaledScore|COMWMSVisDelayedAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|1918|COMWMSVisPctRecPct|COMWMSVisPctRecPct|Num|8|BEST|11,471|2|11,471|||
|1919|COMWMSVisPctRecAgeSS|COMWMSVisPctRecAgeSS|Num|8|BEST|11,471|2|11,471|||
|1920|COMWMSVisMultChCorrect|COMWMSVisMultChCorrect|Num|8|BEST|11,471|2|11,471|||
|1921|COMWMSVisMultChAgeSS|COMWMSVisMultChAgeSS|Num|8|BEST|11,471|2|11,471|||
|1922|COMLibonMentCtlSubtest20To1AcI|COMLibonMentCtlSubtest20To1AcI|Num|8|BEST|11,471|2|11,471|||
|1923|COMLibonMentCtlSubtest20To1Triad|COMLibonMentCtlSubtest20To1Triad1|Num|8|BEST|11,471|2|11,471|||
|1924|COMLibonMentCtlSubtest20To1Tri_1|COMLibonMentCtlSubtest20To1Triad2|Num|8|BEST|11,471|2|11,471|||
|1925|COMLibonMentCtlSubtest20To1Tri_2|COMLibonMentCtlSubtest20To1Triad3|Num|8|BEST|11,471|2|11,471|||
|1926|COMLibonMentCtlSubtestAlphabetAc|COMLibonMentCtlSubtestAlphabetAcI|Num|8|BEST|11,471|2|11,471|||
|1927|COMLibonMentCtlSubtestAlphabetTr|COMLibonMentCtlSubtestAlphabetTriad1|Num|8|BEST|11,471|2|11,471|||
|1928|COMLibonMentCtlSubtestAlphabet_1|COMLibonMentCtlSubtestAlphabetTriad2|Num|8|BEST|11,471|2|11,471|||
|1929|COMLibonMentCtlSubtestAlphabet_2|COMLibonMentCtlSubtestAlphabetTriad3|Num|8|BEST|11,471|2|11,471|||
|1930|COMLibonMentCtlSubtestSerial3sAc|COMLibonMentCtlSubtestSerial3sAcI|Num|8|BEST|11,471|2|11,471|||
|1931|COMLibonMentCtlSubtestSerial3sTr|COMLibonMentCtlSubtestSerial3sTriad1|Num|8|BEST|11,471|2|11,471|||
|1932|COMLibonMentCtlSubtestSerial3s_1|COMLibonMentCtlSubtestSerial3sTriad2|Num|8|BEST|11,471|2|11,471|||
|1933|COMLibonMentCtlSubtestSerial3s_2|COMLibonMentCtlSubtestSerial3sTriad3|Num|8|BEST|11,471|2|11,471|||
|1934|COMLibonMentCtlSubtestMFAcI|COMLibonMentCtlSubtestMFAcI|Num|8|BEST|11,471|2|11,471|||
|1935|COMLibonMentCtlSubtestMFTriad1|COMLibonMentCtlSubtestMFTriad1|Num|8|BEST|11,471|2|11,471|||
|1936|COMLibonMentCtlSubtestMFTriad2|COMLibonMentCtlSubtestMFTriad2|Num|8|BEST|11,471|2|11,471|||
|1937|COMLibonMentCtlSubtestMFTriad3|COMLibonMentCtlSubtestMFTriad3|Num|8|BEST|11,471|2|11,471|||
|1938|COMLibonMentCtlSubtestMBAcI|COMLibonMentCtlSubtestMBAcI|Num|8|BEST|11,471|2|11,471|||
|1939|COMLibonMentCtlSubtestMBTriad1|COMLibonMentCtlSubtestMBTriad1|Num|8|BEST|11,471|2|11,471|||
|1940|COMLibonMentCtlSubtestMBTriad2|COMLibonMentCtlSubtestMBTriad2|Num|8|BEST|11,471|2|11,471|||
|1941|COMLibonMentCtlSubtestMBTriad3|COMLibonMentCtlSubtestMBTriad3|Num|8|BEST|11,471|2|11,471|||
|1942|COMLibonMentCtlSubtestKeyAcI|COMLibonMentCtlSubtestKeyAcI|Num|8|BEST|11,471|2|11,471|||
|1943|COMLibonMentCtlSubtestKeyTriad1|COMLibonMentCtlSubtestKeyTriad1|Num|8|BEST|11,471|2|11,471|||
|1944|COMLibonMentCtlSubtestKeyTriad2|COMLibonMentCtlSubtestKeyTriad2|Num|8|BEST|11,471|2|11,471|||
|1945|COMLibonMentCtlSubtestKeyTriad3|COMLibonMentCtlSubtestKeyTriad3|Num|8|BEST|11,471|2|11,471|||
|1946|COMLibonMentCtlSubtestCurveAcI|COMLibonMentCtlSubtestCurveAcI|Num|8|BEST|11,471|2|11,471|||
|1947|COMLibonMentCtlSubtestCurveTriad|COMLibonMentCtlSubtestCurveTriad1|Num|8|BEST|11,471|2|11,471|||
|1948|COMLibonMentCtlSubtestCurveTri_1|COMLibonMentCtlSubtestCurveTriad2|Num|8|BEST|11,471|2|11,471|||
|1949|COMLibonMentCtlSubtestCurveTri_2|COMLibonMentCtlSubtestCurveTriad3|Num|8|BEST|11,471|2|11,471|||
|1950|COMLibonMentCtlSubtestAutoMCAcI|COMLibonMentCtlSubtestAutoMCAcI|Num|8|BEST|11,471|2|11,471|||
|1951|COMLibonMentCtlSubtestNonautoMCA|COMLibonMentCtlSubtestNonautoMCAcI|Num|8|BEST|11,471|2|11,471|||
|1952|COMLibonMentCtlSubtestWMSTotalSc|COMLibonMentCtlSubtestWMSTotalScore|Num|8|BEST|11,471|2|11,471|||
|1953|COMLibonBackDigSpan3SpanAny|COMLibonBackDigSpan3SpanAny|Num|8|BEST|11,471|2|11,471|||
|1954|COMLibonBackDigSpan3SpanSerial|COMLibonBackDigSpan3SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1955|COMLibonBackDigSpan3SpanWTC|COMLibonBackDigSpan3SpanWTC|Num|8|BEST|11,471|2|11,471|||
|1956|COMLibonBackDigSpan3SpanBTC|COMLibonBackDigSpan3SpanBTC|Num|8|BEST|11,471|2|11,471|||
|1957|COMLibonBackDigSpan3SpanPer|COMLibonBackDigSpan3SpanPer|Num|8|BEST|11,471|2|11,471|||
|1958|COMLibonBackDigSpan3SpanSeq|COMLibonBackDigSpan3SpanSeq|Num|8|BEST|11,471|2|11,471|||
|1959|COMLibonBackDigSpan3SpanSpan|COMLibonBackDigSpan3SpanSpan|Num|8|BEST|11,471|2|11,471|||
|1960|COMLibonBackDigSpan4SpanAny|COMLibonBackDigSpan4SpanAny|Num|8|BEST|11,471|2|11,471|||
|1961|COMLibonBackDigSpan4SpanSerial|COMLibonBackDigSpan4SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1962|COMLibonBackDigSpan4SpanWTC|COMLibonBackDigSpan4SpanWTC|Num|8|BEST|11,471|2|11,471|||
|1963|COMLibonBackDigSpan4SpanBTC|COMLibonBackDigSpan4SpanBTC|Num|8|BEST|11,471|2|11,471|||
|1964|COMLibonBackDigSpan4SpanPer|COMLibonBackDigSpan4SpanPer|Num|8|BEST|11,471|2|11,471|||
|1965|COMLibonBackDigSpan4SpanSeq|COMLibonBackDigSpan4SpanSeq|Num|8|BEST|11,471|2|11,471|||
|1966|COMLibonBackDigSpan4SpanSpan|COMLibonBackDigSpan4SpanSpan|Num|8|BEST|11,471|2|11,471|||
|1967|COMLibonBackDigSpan5SpanAny|COMLibonBackDigSpan5SpanAny|Num|8|BEST|11,471|2|11,471|||
|1968|COMLibonBackDigSpan5SpanSerial|COMLibonBackDigSpan5SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1969|COMLibonBackDigSpan5SpanWTC|COMLibonBackDigSpan5SpanWTC|Num|8|BEST|11,471|2|11,471|||
|1970|COMLibonBackDigSpan5SpanBTC|COMLibonBackDigSpan5SpanBTC|Num|8|BEST|11,471|2|11,471|||
|1971|COMLibonBackDigSpan5SpanPer|COMLibonBackDigSpan5SpanPer|Num|8|BEST|11,471|2|11,471|||
|1972|COMLibonBackDigSpan5SpanSeq|COMLibonBackDigSpan5SpanSeq|Num|8|BEST|11,471|2|11,471|||
|1973|COMLibonBackDigSpan5SpanSpan|COMLibonBackDigSpan5SpanSpan|Num|8|BEST|11,471|2|11,471|||
|1974|COMLibonBackDigSpan6SpanAny|COMLibonBackDigSpan6SpanAny|Num|8|BEST|11,471|2|11,471|||
|1975|COMLibonBackDigSpan6SpanSerial|COMLibonBackDigSpan6SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1976|COMLibonBackDigSpan6SpanWTC|COMLibonBackDigSpan6SpanWTC|Num|8|BEST|11,471|2|11,471|||
|1977|COMLibonBackDigSpan6SpanBTC|COMLibonBackDigSpan6SpanBTC|Num|8|BEST|11,471|2|11,471|||
|1978|COMLibonBackDigSpan6SpanPer|COMLibonBackDigSpan6SpanPer|Num|8|BEST|11,471|2|11,471|||
|1979|COMLibonBackDigSpan6SpanSeq|COMLibonBackDigSpan6SpanSeq|Num|8|BEST|11,471|2|11,471|||
|1980|COMLibonBackDigSpan6SpanSpan|COMLibonBackDigSpan6SpanSpan|Num|8|BEST|11,471|2|11,471|||
|1981|COMLibonBackDigSpanMeanTotalAny|COMLibonBackDigSpanMeanTotalAny|Num|8|BEST|11,471|2|11,471|||
|1982|COMLibonBackDigSpanMeanTotalSeri|COMLibonBackDigSpanMeanTotalSerial|Num|8|BEST|11,471|2|11,471|||
|1983|COMLibonBackDigSpanMeanTotalWTC|COMLibonBackDigSpanMeanTotalWTC|Num|8|BEST|11,471|2|11,471|||
|1984|COMLibonBackDigSpanMeanTotalBTC|COMLibonBackDigSpanMeanTotalBTC|Num|8|BEST|11,471|2|11,471|||
|1985|COMLibonBackDigSpanMeanTotalPer|COMLibonBackDigSpanMeanTotalPer|Num|8|BEST|11,471|2|11,471|||
|1986|COMLibonBackDigSpanMeanTotalSeq|COMLibonBackDigSpanMeanTotalSeq|Num|8|BEST|11,471|2|11,471|||
|1987|COMLibonBackDigSpanMeanTotalSpan|COMLibonBackDigSpanMeanTotalSpan|Num|8|BEST|11,471|2|11,471|||
|1988|COMLibonObjectSpan2SpanAny|COMLibonObjectSpan2SpanAny|Num|8|BEST|11,471|2|11,471|||
|1989|COMLibonObjectSpan2SpanSerial|COMLibonObjectSpan2SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1990|COMLibonObjectSpan3SpanAny|COMLibonObjectSpan3SpanAny|Num|8|BEST|11,471|2|11,471|||
|1991|COMLibonObjectSpan3SpanSerial|COMLibonObjectSpan3SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1992|COMLibonObjectSpan4SpanAny|COMLibonObjectSpan4SpanAny|Num|8|BEST|11,471|2|11,471|||
|1993|COMLibonObjectSpan4SpanSerial|COMLibonObjectSpan4SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1994|COMLibonObjectSpan5SpanAny|COMLibonObjectSpan5SpanAny|Num|8|BEST|11,471|2|11,471|||
|1995|COMLibonObjectSpan5SpanSerial|COMLibonObjectSpan5SpanSerial|Num|8|BEST|11,471|2|11,471|||
|1996|COMLibonObjectSpanAverageAny|COMLibonObjectSpanAverageAny|Num|8|BEST|11,471|2|11,471|||
|1997|COMLibonObjectSpanAverageSerial|COMLibonObjectSpanAverageSerial|Num|8|BEST|11,471|2|11,471|||
|1998|COMCVLTIIFreeRecallTrialI|COMCVLTIIFreeRecallTrialI|Num|8|BEST|11,471|2|11,471|||
|1999|COMCVLTIIFreeRecallTrialII|COMCVLTIIFreeRecallTrialII|Num|8|BEST|11,471|2|11,471|||
|2000|COMCVLTIIFreeRecallTrialIII|COMCVLTIIFreeRecallTrialIII|Num|8|BEST|11,471|2|11,471|||
|2001|COMCVLTIIFreeRecallTrialIV|COMCVLTIIFreeRecallTrialIV|Num|8|BEST|11,471|2|11,471|||
|2002|COMCVLTIIFreeRecallTrialV|COMCVLTIIFreeRecallTrialV|Num|8|BEST|11,471|2|11,471|||
|2003|COMCVLTIIZScoreTrialI|COMCVLTIIZScoreTrialI|Num|8|BEST|11,471|2|11,471|||
|2004|COMCVLTIIZScoreTrialII|COMCVLTIIZScoreTrialII|Num|8|BEST|11,471|2|11,471|||
|2005|COMCVLTIIZScoreTrialIII|COMCVLTIIZScoreTrialIII|Num|8|BEST|11,471|2|11,471|||
|2006|COMCVLTIIZScoreTrialIV|COMCVLTIIZScoreTrialIV|Num|8|BEST|11,471|2|11,471|||
|2007|COMCVLTIIZScoreTrialV|COMCVLTIIZScoreTrialV|Num|8|BEST|11,471|2|11,471|||
|2008|COMCVLTIIRawScoreClusters|COMCVLTIIRawScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2009|COMCVLTIIRawScoreIntrusions|COMCVLTIIRawScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2010|COMCVLTIIRawScorePersev|COMCVLTIIRawScorePersev|Num|8|BEST|11,471|2|11,471|||
|2011|COMCVLTIIZScoreClusters|COMCVLTIIZScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2012|COMCVLTIIZScoreIntrusions|COMCVLTIIZScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2013|COMCVLTIIZScorePersev|COMCVLTIIZScorePersev|Num|8|BEST|11,471|2|11,471|||
|2014|COMCVLTIIListBFreeRecNumber|COMCVLTIIListBFreeRecNumber|Num|8|BEST|11,471|2|11,471|||
|2015|COMCVLTIIListBFreeRecNorm-ZScore|COMCVLTIIListBFreeRecNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2016|COMCVLTIIImmedRecallNumber|COMCVLTIIImmedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2017|COMCVLTIIImmedRecallNorm-ZScore|COMCVLTIIImmedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2018|COMCVLTIIImmedCuedRecallNumber|COMCVLTIIImmedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2019|COMCVLTIIImmedCuedRecallNorm-ZSc|COMCVLTIIImmedCuedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2020|COMCVLTIIDelayedRecallNumber|COMCVLTIIDelayedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2021|COMCVLTIIDelayedRecallNorm-ZScor|COMCVLTIIDelayedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2022|COMCVLTIIDelayedCuedRecallNumber|COMCVLTIIDelayedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2023|COMCVLTIIDelayedCuedRecallNorm-Z|COMCVLTIIDelayedCuedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2024|COMCVLTIIDelayedRecogHitsNumber|COMCVLTIIDelayedRecogHitsNumber|Num|8|BEST|11,471|2|11,471|||
|2025|COMCVLTIIDelayedRecogHitsNorm-ZS|COMCVLTIIDelayedRecogHitsNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2026|COMCVLTIIRecogFalsePosNumber|COMCVLTIIRecogFalsePosNumber|Num|8|BEST|11,471|2|11,471|||
|2027|COMCVLTIIRecogFalsePosNorm-ZScor|COMCVLTIIRecogFalsePosNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2028|COMCVLTIIForcedChoiceRecogNumber|COMCVLTIIForcedChoiceRecogNumber|Num|8|BEST|11,471|2|11,471|||
|2029|COMCVLTIIForcedChoiceRecogAgeScS|COMCVLTIIForcedChoiceRecogAgeScScore|Num|8|BEST|11,471|2|11,471|||
|2030|COMCVLTIIForcedChoiceRecogPctWTh|COMCVLTIIForcedChoiceRecogPctWThisScore|Num|8|BEST|11,471|2|11,471|||
|2031|COMCVLTIIForcedChoiceRecogCumPct|COMCVLTIIForcedChoiceRecogCumPctWBetterScore|Num|8|BEST|11,471|2|11,471|||
|2032|COMCVLTIITotRecogDiscrimRaw|COMCVLTIITotRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2033|COMCVLTIITotRecogDiscrimNorm-ZSc|COMCVLTIITotRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2034|COMCVLTIISourceRecogDiscrimRaw|COMCVLTIISourceRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2035|COMCVLTIISourceRecogDiscrimNorm-|COMCVLTIISourceRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2036|COMCVLTIISemanticRecogDiscrimRaw|COMCVLTIISemanticRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2037|COMCVLTIISemanticRecogDiscrimNor|COMCVLTIISemanticRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2038|COMCVLTIINovelRecogDiscrmRaw|COMCVLTIINovelRecogDiscrmRaw|Num|8|BEST|11,471|2|11,471|||
|2039|COMCVLTIINovelRecogDiscrmNorm-ZS|COMCVLTIINovelRecogDiscrmNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2040|COMCVLTIIRecogUnrelNumber|COMCVLTIIRecogUnrelNumber|Num|8|BEST|11,471|2|11,471|||
|2041|COMCVLTIIRecListBNotShNumber|COMCVLTIIRecListBNotShNumber|Num|8|BEST|11,471|2|11,471|||
|2042|COMCVLTIIRecListBSharedNumber|COMCVLTIIRecListBSharedNumber|Num|8|BEST|11,471|2|11,471|||
|2043|COMCVLTIIRecogPrototypNumber|COMCVLTIIRecogPrototypNumber|Num|8|BEST|11,471|2|11,471|||
|2044|COMCVLTIIImmedCuedRecallFKRaw|COMCVLTIIImmedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2045|COMCVLTIIDelayedCuedRecallFKRaw|COMCVLTIIDelayedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2046|COMCVLTIISHORTFreeRecallTrialI|COMCVLTIISHORTFreeRecallTrialI|Num|8|BEST|11,471|2|11,471|||
|2047|COMCVLTIISHORTFreeRecallTrialII|COMCVLTIISHORTFreeRecallTrialII|Num|8|BEST|11,471|2|11,471|||
|2048|COMCVLTIISHORTFreeRecallTrialIII|COMCVLTIISHORTFreeRecallTrialIII|Num|8|BEST|11,471|2|11,471|||
|2049|COMCVLTIISHORTFreeRecallTrialIV|COMCVLTIISHORTFreeRecallTrialIV|Num|8|BEST|11,471|2|11,471|||
|2050|COMCVLTIISHORTScaledZScoreTrialI|COMCVLTIISHORTScaledZScoreTrialI|Num|8|BEST|11,471|2|11,471|||
|2051|COMCVLTIISHORTScaledZScoreTria_1|COMCVLTIISHORTScaledZScoreTrialII|Num|8|BEST|11,471|2|11,471|||
|2052|COMCVLTIISHORTScaledZScoreTria_2|COMCVLTIISHORTScaledZScoreTrialIII|Num|8|BEST|11,471|2|11,471|||
|2053|COMCVLTIISHORTScaledZScoreTria_3|COMCVLTIISHORTScaledZScoreTrialIV|Num|8|BEST|11,471|2|11,471|||
|2054|COMCVLTIISHORTRawScoreClusters|COMCVLTIISHORTRawScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2055|COMCVLTIISHORTRawScoreIntrusions|COMCVLTIISHORTRawScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2056|COMCVLTIISHORTRawScorePersev|COMCVLTIISHORTRawScorePersev|Num|8|BEST|11,471|2|11,471|||
|2057|COMCVLTIISHORTZScoreClusters|COMCVLTIISHORTZScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2058|COMCVLTIISHORTZScoreIntrusions|COMCVLTIISHORTZScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2059|COMCVLTIISHORTZScorePersev|COMCVLTIISHORTZScorePersev|Num|8|BEST|11,471|2|11,471|||
|2060|COMCVLTIISHORTImmedRecallNumber|COMCVLTIISHORTImmedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2061|COMCVLTIISHORTImmedRecallNorm-ZS|COMCVLTIISHORTImmedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2062|COMCVLTIISHORTDelayedRecallNumbe|COMCVLTIISHORTDelayedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2063|COMCVLTIISHORTDelayedRecallNorm-|COMCVLTIISHORTDelayedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2064|COMCVLTIISHORTDelayedCuedRecallN|COMCVLTIISHORTDelayedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2065|COMCVLTIISHORTDelayedCuedRecal_1|COMCVLTIISHORTDelayedCuedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2066|COMCVLTIISHORTDelayedRecogHitsNu|COMCVLTIISHORTDelayedRecogHitsNumber|Num|8|BEST|11,471|2|11,471|||
|2067|COMCVLTIISHORTDelayedRecogHitsNo|COMCVLTIISHORTDelayedRecogHitsNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2068|COMCVLTIISHORTForcedChoiceRecogN|COMCVLTIISHORTForcedChoiceRecogNumber|Num|8|BEST|11,471|2|11,471|||
|2069|COMCVLTIISHORTForcedChoiceRecogA|COMCVLTIISHORTForcedChoiceRecogAgePct|Num|8|BEST|11,471|2|11,471|||
|2070|COMCVLTIISHORTForcedChoiceRecogP|COMCVLTIISHORTForcedChoiceRecogPctWThisScore|Num|8|BEST|11,471|2|11,471|||
|2071|COMCVLTIISHORTForcedChoiceRecogC|COMCVLTIISHORTForcedChoiceRecogCumPctWBetterScore|Num|8|BEST|11,471|2|11,471|||
|2072|COMCVLTIISHORTFalsePositiveNumbe|COMCVLTIISHORTFalsePositiveNumber|Num|8|BEST|11,471|2|11,471|||
|2073|COMCVLTIISHORTFalsePositiveNorm-|COMCVLTIISHORTFalsePositiveNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2074|COMCVLTIISHORTProtoRecFalsePosNu|COMCVLTIISHORTProtoRecFalsePosNumber|Num|8|BEST|11,471|2|11,471|||
|2075|COMCVLTIISHORTUnrecFalsePosNumbe|COMCVLTIISHORTUnrecFalsePosNumber|Num|8|BEST|11,471|2|11,471|||
|2076|COMCVLTIISHORTTotRecogDiscrimRaw|COMCVLTIISHORTTotRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2077|COMCVLTIISHORTTotRecogDiscrimNor|COMCVLTIISHORTTotRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2078|COMCVLTIISHORTSourceRecogDiscrim|COMCVLTIISHORTSourceRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2079|COMCVLTIISHORTSourceRecogDiscr_1|COMCVLTIISHORTSourceRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2080|COMCVLTIISHORTSemanticRecogDiscr|COMCVLTIISHORTSemanticRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2081|COMCVLTIISHORTSemanticRecogDis_1|COMCVLTIISHORTSemanticRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2082|COMCVLTIISHORTNovelRecogDiscrmRa|COMCVLTIISHORTNovelRecogDiscrmRaw|Num|8|BEST|11,471|2|11,471|||
|2083|COMCVLTIISHORTNovelRecogDiscrmNo|COMCVLTIISHORTNovelRecogDiscrmNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2084|COMCVLTIISHORTImmedCuedRecallFKR|COMCVLTIISHORTImmedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2085|COMCVLTIISHORTImmedCuedRecallFKN|COMCVLTIISHORTImmedCuedRecallFKNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2086|COMCVLTIISHORTDelayedCuedRecallF|COMCVLTIISHORTDelayedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2087|COMCVLTIISHORTDelayedCuedRecal_2|COMCVLTIISHORTDelayedCuedRecallFKNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2088|COMNineItemListFreeRecallTrialI|COMNineItemListFreeRecallTrialI|Num|8|BEST|11,471|2|11,471|||
|2089|COMNineItemListFreeRecallTrialII|COMNineItemListFreeRecallTrialII|Num|8|BEST|11,471|2|11,471|||
|2090|COMNineItemListFreeRecallTrial_1|COMNineItemListFreeRecallTrialIII|Num|8|BEST|11,471|2|11,471|||
|2091|COMNineItemListFreeRecallTrialIV|COMNineItemListFreeRecallTrialIV|Num|8|BEST|11,471|2|11,471|||
|2092|COMNineItemListFreeRecallTrialV|COMNineItemListFreeRecallTrialV|Num|8|BEST|11,471|2|11,471|||
|2093|COMNineItemListScaledZScoreTrial|COMNineItemListScaledZScoreTrialI|Num|8|BEST|11,471|2|11,471|||
|2094|COMNineItemListScaledZScoreTri_1|COMNineItemListScaledZScoreTrialII|Num|8|BEST|11,471|2|11,471|||
|2095|COMNineItemListScaledZScoreTri_2|COMNineItemListScaledZScoreTrialIII|Num|8|BEST|11,471|2|11,471|||
|2096|COMNineItemListScaledZScoreTri_3|COMNineItemListScaledZScoreTrialIV|Num|8|BEST|11,471|2|11,471|||
|2097|COMNineItemListScaledZScoreTri_4|COMNineItemListScaledZScoreTrialV|Num|8|BEST|11,471|2|11,471|||
|2098|COMNineItemListRawScoreClusters|COMNineItemListRawScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2099|COMNineItemListRawScoreIntrusion|COMNineItemListRawScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2100|COMNineItemListRawScorePersev|COMNineItemListRawScorePersev|Num|8|BEST|11,471|2|11,471|||
|2101|COMNineItemListZScoreClusters|COMNineItemListZScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2102|COMNineItemListZScoreIntrusions|COMNineItemListZScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2103|COMNineItemListZScorePersev|COMNineItemListZScorePersev|Num|8|BEST|11,471|2|11,471|||
|2104|COMNineItemListListBFreeRecNumbe|COMNineItemListListBFreeRecNumber|Num|8|BEST|11,471|2|11,471|||
|2105|COMNineItemListListBFreeRecNorm-|COMNineItemListListBFreeRecNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2106|COMNineItemListImmedRecallNumber|COMNineItemListImmedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2107|COMNineItemListImmedRecallNorm-Z|COMNineItemListImmedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2108|COMNineItemListImmedCuedRecallNu|COMNineItemListImmedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2109|COMNineItemListImmedCuedRecallNo|COMNineItemListImmedCuedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2110|COMNineItemListDelayedRecallNumb|COMNineItemListDelayedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2111|COMNineItemListDelayedRecallNorm|COMNineItemListDelayedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2112|COMNineItemListDelayedCuedRecall|COMNineItemListDelayedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2113|COMNineItemListDelayedCuedReca_1|COMNineItemListDelayedCuedRecallNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2114|COMNineItemListDelayedRecogHitsN|COMNineItemListDelayedRecogHitsNumber|Num|8|BEST|11,471|2|11,471|||
|2115|COMNineItemListDelayedRecogHit_1|COMNineItemListDelayedRecogHitsNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2116|COMNineItemListForcedChoiceRecog|COMNineItemListForcedChoiceRecogNumber|Num|8|BEST|11,471|2|11,471|||
|2117|COMNineItemListForcedChoiceRec_1|COMNineItemListForcedChoiceRecogNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2118|COMNineItemListFalsePositiveNumb|COMNineItemListFalsePositiveNumber|Num|8|BEST|11,471|2|11,471|||
|2119|COMNineItemListFalsePositiveNorm|COMNineItemListFalsePositiveNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2120|COMNineItemListRecogDiscrimRaw|COMNineItemListRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2121|COMNineItemListRecogDiscrimNorm-|COMNineItemListRecogDiscrimNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2122|COMNineItemListListBRecogFoilRaw|COMNineItemListListBRecogFoilRaw|Num|8|BEST|11,471|2|11,471|||
|2123|COMNineItemListListBRecogFoilNor|COMNineItemListListBRecogFoilNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2124|COMNineItemListRelatedFoilsRaw|COMNineItemListRelatedFoilsRaw|Num|8|BEST|11,471|2|11,471|||
|2125|COMNineItemListRelatedFoilsNorm-|COMNineItemListRelatedFoilsNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2126|COMNineItemListUnrelatedFoilsRaw|COMNineItemListUnrelatedFoilsRaw|Num|8|BEST|11,471|2|11,471|||
|2127|COMNineItemListUnrelatedFoilsNor|COMNineItemListUnrelatedFoilsNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2128|COMNineItemListImmedCuedRecallFK|COMNineItemListImmedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2129|COMNineItemListImmedCuedRecall_1|COMNineItemListImmedCuedRecallFKNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2130|COMNineItemListDelayedCuedReca_2|COMNineItemListDelayedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2131|COMNineItemListDelayedCuedReca_3|COMNineItemListDelayedCuedRecallFKNorm-ZScore|Num|8|BEST|11,471|2|11,471|||
|2132|COMPvLT12ItemFreeRecallTrialI|COMPvLT12ItemFreeRecallTrialI|Num|8|BEST|11,471|2|11,471|||
|2133|COMPvLT12ItemFreeRecallTrialII|COMPvLT12ItemFreeRecallTrialII|Num|8|BEST|11,471|2|11,471|||
|2134|COMPvLT12ItemFreeRecallTrialIII|COMPvLT12ItemFreeRecallTrialIII|Num|8|BEST|11,471|2|11,471|||
|2135|COMPvLT12ItemFreeRecallTrialIV|COMPvLT12ItemFreeRecallTrialIV|Num|8|BEST|11,471|2|11,471|||
|2136|COMPvLT12ItemFreeRecallTrialV|COMPvLT12ItemFreeRecallTrialV|Num|8|BEST|11,471|2|11,471|||
|2137|COMPvLT12ItemZScoreTrialI|COMPvLT12ItemZScoreTrialI|Num|8|BEST|11,471|2|11,471|||
|2138|COMPvLT12ItemZScoreTrialII|COMPvLT12ItemZScoreTrialII|Num|8|BEST|11,471|2|11,471|||
|2139|COMPvLT12ItemZScoreTrialIII|COMPvLT12ItemZScoreTrialIII|Num|8|BEST|11,471|2|11,471|||
|2140|COMPvLT12ItemZScoreTrialIV|COMPvLT12ItemZScoreTrialIV|Num|8|BEST|11,471|2|11,471|||
|2141|COMPvLT12ItemZScoreTrialV|COMPvLT12ItemZScoreTrialV|Num|8|BEST|11,471|2|11,471|||
|2142|COMPvLT12ItemRawScoreClusters|COMPvLT12ItemRawScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2143|COMPvLT12ItemRawScoreIntrusions|COMPvLT12ItemRawScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2144|COMPvLT12ItemRawScorePersev|COMPvLT12ItemRawScorePersev|Num|8|BEST|11,471|2|11,471|||
|2145|COMPvLT12ItemZScoreClusters|COMPvLT12ItemZScoreClusters|Num|8|BEST|11,471|2|11,471|||
|2146|COMPvLT12ItemZScoreIntrusions|COMPvLT12ItemZScoreIntrusions|Num|8|BEST|11,471|2|11,471|||
|2147|COMPvLT12ItemZScorePersev|COMPvLT12ItemZScorePersev|Num|8|BEST|11,471|2|11,471|||
|2148|COMPvLT12ItemListBFreeRecNumber|COMPvLT12ItemListBFreeRecNumber|Num|8|BEST|11,471|2|11,471|||
|2149|COMPvLT12ItemListBFreeRecTScore|COMPvLT12ItemListBFreeRecTScore|Num|8|BEST|11,471|2|11,471|||
|2150|COMPvLT12ItemImmedRecallNumber|COMPvLT12ItemImmedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2151|COMPvLT12ItemImmedRecallTScore|COMPvLT12ItemImmedRecallTScore|Num|8|BEST|11,471|2|11,471|||
|2152|COMPvLT12ItemImmedCuedRecallNumb|COMPvLT12ItemImmedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2153|COMPvLT12ItemImmedCuedRecallTSco|COMPvLT12ItemImmedCuedRecallTScore|Num|8|BEST|11,471|2|11,471|||
|2154|COMPvLT12ItemDelayedRecallNumber|COMPvLT12ItemDelayedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2155|COMPvLT12ItemDelayedRecallTScore|COMPvLT12ItemDelayedRecallTScore|Num|8|BEST|11,471|2|11,471|||
|2156|COMPvLT12ItemDelayedCuedRecallNu|COMPvLT12ItemDelayedCuedRecallNumber|Num|8|BEST|11,471|2|11,471|||
|2157|COMPvLT12ItemDelayedCuedRecallTS|COMPvLT12ItemDelayedCuedRecallTScore|Num|8|BEST|11,471|2|11,471|||
|2158|COMPvLT12ItemDelayedRecogHitsNum|COMPvLT12ItemDelayedRecogHitsNumber|Num|8|BEST|11,471|2|11,471|||
|2159|COMPvLT12ItemDelayedRecogHitsTSc|COMPvLT12ItemDelayedRecogHitsTScore|Num|8|BEST|11,471|2|11,471|||
|2160|COMPvLT12ItemFalsePositiveNumber|COMPvLT12ItemFalsePositiveNumber|Num|8|BEST|11,471|2|11,471|||
|2161|COMPvLT12ItemFalsePositiveTScore|COMPvLT12ItemFalsePositiveTScore|Num|8|BEST|11,471|2|11,471|||
|2162|COMPvLT12ItemRecogDiscrimRaw|COMPvLT12ItemRecogDiscrimRaw|Num|8|BEST|11,471|2|11,471|||
|2163|COMPvLT12ItemRecogDiscrimTScore|COMPvLT12ItemRecogDiscrimTScore|Num|8|BEST|11,471|2|11,471|||
|2164|COMPvLT12ItemListBRecogFoilRaw|COMPvLT12ItemListBRecogFoilRaw|Num|8|BEST|11,471|2|11,471|||
|2165|COMPvLT12ItemListBRecogFoilTScor|COMPvLT12ItemListBRecogFoilTScore|Num|8|BEST|11,471|2|11,471|||
|2166|COMPvLT12ItemRelatedFoilsRaw|COMPvLT12ItemRelatedFoilsRaw|Num|8|BEST|11,471|2|11,471|||
|2167|COMPvLT12ItemUnrelatedFoilsRaw|COMPvLT12ItemUnrelatedFoilsRaw|Num|8|BEST|11,471|2|11,471|||
|2168|COMPvLT12ItemImmedCuedRecallFKRa|COMPvLT12ItemImmedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2169|COMPvLT12ItemDelayedCuedRecallFK|COMPvLT12ItemDelayedCuedRecallFKRaw|Num|8|BEST|11,471|2|11,471|||
|2170|COMWAISIIIVocabRaw|COMWAISIIIVocabRaw|Num|8|BEST|11,471|2|11,471|||
|2171|COMWAISIIIVocabAgeScaledScore|COMWAISIIIVocabAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2172|COMWAISIIISimilRaw|COMWAISIIISimilRaw|Num|8|BEST|11,471|2|11,471|||
|2173|COMWAISIIISimilAgeScaledScore|COMWAISIIISimilAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2174|COMWAISIIISimilPctInSet|COMWAISIIISimilPctInSet|Num|8|BEST|11,471|2|11,471|||
|2175|COMWAISIIISimilPctOutOfSet|COMWAISIIISimilPctOutOfSet|Num|8|BEST|11,471|2|11,471|||
|2176|COMWAISIIIArithRaw|COMWAISIIIArithRaw|Num|8|BEST|11,471|2|11,471|||
|2177|COMWAISIIIArithAgeScaledScore|COMWAISIIIArithAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2178|COMWAISIIIDigSpanRaw|COMWAISIIIDigSpanRaw|Num|8|BEST|11,471|2|11,471|||
|2179|COMWAISIIIDigSpanAgeScaledScore|COMWAISIIIDigSpanAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2180|COMWAISIIIDigSpanLngestStringBwd|COMWAISIIIDigSpanLngestStringBwd|Num|8|BEST|11,471|2|11,471|||
|2181|COMWAISIIIDigSpanLngestStringFwd|COMWAISIIIDigSpanLngestStringFwd|Num|8|BEST|11,471|2|11,471|||
|2182|COMWAISIIIInfoRaw|COMWAISIIIInfoRaw|Num|8|BEST|11,471|2|11,471|||
|2183|COMWAISIIIInfoAgeScaledScore|COMWAISIIIInfoAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2184|COMWAISIIICompRaw|COMWAISIIICompRaw|Num|8|BEST|11,471|2|11,471|||
|2185|COMWAISIIICompAgeScaledScore|COMWAISIIICompAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2186|COMWAISIIIPictCompleRaw|COMWAISIIIPictCompleRaw|Num|8|BEST|11,471|2|11,471|||
|2187|COMWAISIIIPictCompleAgeScaledSco|COMWAISIIIPictCompleAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2188|COMWAISIIIDigSymbCodingRaw|COMWAISIIIDigSymbCodingRaw|Num|8|BEST|11,471|2|11,471|||
|2189|COMWAISIIIDigSymbCodingAgeScaled|COMWAISIIIDigSymbCodingAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2190|COMWAISIIIDigSymbCopyRaw|COMWAISIIIDigSymbCopyRaw|Num|8|BEST|11,471|2|11,471|||
|2191|COMWAISIIIDigSymbCopyAgeScaledSc|COMWAISIIIDigSymbCopyAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2192|COMWAISIIIBlockDesRaw|COMWAISIIIBlockDesRaw|Num|8|BEST|11,471|2|11,471|||
|2193|COMWAISIIIBlockDesAgeScaledScore|COMWAISIIIBlockDesAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2194|COMWAISIIIMatrixReasonRaw|COMWAISIIIMatrixReasonRaw|Num|8|BEST|11,471|2|11,471|||
|2195|COMWAISIIIMatrixReasonAgeScaledS|COMWAISIIIMatrixReasonAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2196|COMWAISIIIPictArrRaw|COMWAISIIIPictArrRaw|Num|8|BEST|11,471|2|11,471|||
|2197|COMWAISIIIPictArrAgeScaledScore|COMWAISIIIPictArrAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2198|COMWAISIIISymbSearchRaw|COMWAISIIISymbSearchRaw|Num|8|BEST|11,471|2|11,471|||
|2199|COMWAISIIISymbSearchAgeScaledSco|COMWAISIIISymbSearchAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2200|COMWAISIIILetNumbSeqRaw|COMWAISIIILetNumbSeqRaw|Num|8|BEST|11,471|2|11,471|||
|2201|COMWAISIIILetNumbSeqAgeScaledSco|COMWAISIIILetNumbSeqAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2202|COMWAISIIIObjAssRaw|COMWAISIIIObjAssRaw|Num|8|BEST|11,471|2|11,471|||
|2203|COMWAISIIIObjAssAgeScaledScore|COMWAISIIIObjAssAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2204|COMWAISIIIVerbIQScore|COMWAISIIIVerbIQScore|Num|8|BEST|11,471|2|11,471|||
|2205|COMWAISIIIVerbIQPct|COMWAISIIIVerbIQPct|Num|8|BEST|11,471|2|11,471|||
|2206|COMWAISIIIPerfIQScore|COMWAISIIIPerfIQScore|Num|8|BEST|11,471|2|11,471|||
|2207|COMWAISIIIPerfIQPct|COMWAISIIIPerfIQPct|Num|8|BEST|11,471|2|11,471|||
|2208|COMWAISIIIFullScaleIQScore|COMWAISIIIFullScaleIQScore|Num|8|BEST|11,471|2|11,471|||
|2209|COMWAISIIIFullScaleIQPct|COMWAISIIIFullScaleIQPct|Num|8|BEST|11,471|2|11,471|||
|2210|COMWAISIIIVerbCompIndxScore|COMWAISIIIVerbCompIndxScore|Num|8|BEST|11,471|2|11,471|||
|2211|COMWAISIIIVerbCompIndxPct|COMWAISIIIVerbCompIndxPct|Num|8|BEST|11,471|2|11,471|||
|2212|COMWAISIIIPercepOrgIndxScore|COMWAISIIIPercepOrgIndxScore|Num|8|BEST|11,471|2|11,471|||
|2213|COMWAISIIIPercepOrgIndxPct|COMWAISIIIPercepOrgIndxPct|Num|8|BEST|11,471|2|11,471|||
|2214|COMWAISIIIWorkMemIndxScore|COMWAISIIIWorkMemIndxScore|Num|8|BEST|11,471|2|11,471|||
|2215|COMWAISIIIWorkMemIndxPct|COMWAISIIIWorkMemIndxPct|Num|8|BEST|11,471|2|11,471|||
|2216|COMWAISIIIProcSpeedIndxScore|COMWAISIIIProcSpeedIndxScore|Num|8|BEST|11,471|2|11,471|||
|2217|COMWAISIIIProcSpeedIndxPct|COMWAISIIIProcSpeedIndxPct|Num|8|BEST|11,471|2|11,471|||
|2218|COMWAISIIISimlWAIS-RRaw|COMWAISIIISimlWAIS-RRaw|Num|8|BEST|11,471|2|11,471|||
|2219|COMWAISIIISimlWAIS-RAgeScaledSco|COMWAISIIISimlWAIS-RAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2220|COMWAISIIISimlWAIS-RPctInSet|COMWAISIIISimlWAIS-RPctInSet|Num|8|BEST|11,471|2|11,471|||
|2221|COMWAISIIISimlWAIS-RPctOutOfSet|COMWAISIIISimlWAIS-RPctOutOfSet|Num|8|BEST|11,471|2|11,471|||
|2222|COMWAISIIILibonDigSymbI15|COMWAISIIILibonDigSymbI15|Num|8|BEST|11,471|2|11,471|||
|2223|COMWAISIIILibonDigSymbI30|COMWAISIIILibonDigSymbI30|Num|8|BEST|11,471|2|11,471|||
|2224|COMWAISIIILibonDigSymbI45|COMWAISIIILibonDigSymbI45|Num|8|BEST|11,471|2|11,471|||
|2225|COMWAISIIILibonDigSymbI60|COMWAISIIILibonDigSymbI60|Num|8|BEST|11,471|2|11,471|||
|2226|COMWAISIIILibonDigSymbII75|COMWAISIIILibonDigSymbII75|Num|8|BEST|11,471|2|11,471|||
|2227|COMWAISIIILibonDigSymbII90|COMWAISIIILibonDigSymbII90|Num|8|BEST|11,471|2|11,471|||
|2228|COMWAISIIILibonDigSymbII105|COMWAISIIILibonDigSymbII105|Num|8|BEST|11,471|2|11,471|||
|2229|COMWAISIIILibonDigSymbII120|COMWAISIIILibonDigSymbII120|Num|8|BEST|11,471|2|11,471|||
|2230|COMWAISIIILibonDigSymbI135|COMWAISIIILibonDigSymbI135|Num|8|BEST|11,471|2|11,471|||
|2231|COMWAISIIILibonDigSymbI150|COMWAISIIILibonDigSymbI150|Num|8|BEST|11,471|2|11,471|||
|2232|COMWAISIIILibonDigSymbI165|COMWAISIIILibonDigSymbI165|Num|8|BEST|11,471|2|11,471|||
|2233|COMWAISIIILibonDigSymbI180|COMWAISIIILibonDigSymbI180|Num|8|BEST|11,471|2|11,471|||
|2234|COMWAISIIILibonSymbCopI15|COMWAISIIILibonSymbCopI15|Num|8|BEST|11,471|2|11,471|||
|2235|COMWAISIIILibonSymbCopI30|COMWAISIIILibonSymbCopI30|Num|8|BEST|11,471|2|11,471|||
|2236|COMWAISIIILibonSymbCopI45|COMWAISIIILibonSymbCopI45|Num|8|BEST|11,471|2|11,471|||
|2237|COMWAISIIILibonSymbCopI60|COMWAISIIILibonSymbCopI60|Num|8|BEST|11,471|2|11,471|||
|2238|COMWAISIIILibonSymbCopII75|COMWAISIIILibonSymbCopII75|Num|8|BEST|11,471|2|11,471|||
|2239|COMWAISIIILibonSymbCopII90|COMWAISIIILibonSymbCopII90|Num|8|BEST|11,471|2|11,471|||
|2240|COMWAISIIILibonSymbCopII105|COMWAISIIILibonSymbCopII105|Num|8|BEST|11,471|2|11,471|||
|2241|COMWAISIIILibonSymbCopII120|COMWAISIIILibonSymbCopII120|Num|8|BEST|11,471|2|11,471|||
|2242|COMWAISIIILibonSymbCopII135|COMWAISIIILibonSymbCopII135|Num|8|BEST|11,471|2|11,471|||
|2243|COMWAISIIILibonSymbCopII150|COMWAISIIILibonSymbCopII150|Num|8|BEST|11,471|2|11,471|||
|2244|COMWAISIIILibonSymbCopII165|COMWAISIIILibonSymbCopII165|Num|8|BEST|11,471|2|11,471|||
|2245|COMWAISIIILibonSymbCopII180|COMWAISIIILibonSymbCopII180|Num|8|BEST|11,471|2|11,471|||
|2246|COMWASIVocabRaw|COMWASIVocabRaw|Num|8|BEST|11,471|2|11,471|||
|2247|COMWASIVocabTScore|COMWASIVocabTScore|Num|8|BEST|11,471|2|11,471|||
|2248|COMWASIVocabAgeScaledScore|COMWASIVocabAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2249|COMWASISimilRaw|COMWASISimilRaw|Num|8|BEST|11,471|2|11,471|||
|2250|COMWASISimilTScore|COMWASISimilTScore|Num|8|BEST|11,471|2|11,471|||
|2251|COMWASISimilAgeScaledScore|COMWASISimilAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2252|COMWASIBlockDesRaw|COMWASIBlockDesRaw|Num|8|BEST|11,471|2|11,471|||
|2253|COMWASIBlockDesTScore|COMWASIBlockDesTScore|Num|8|BEST|11,471|2|11,471|||
|2254|COMWASIBlockDesAgeScaledScore|COMWASIBlockDesAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2255|COMWASIMatrixReasonRaw|COMWASIMatrixReasonRaw|Num|8|BEST|11,471|2|11,471|||
|2256|COMWASIMatrixReasonTScore|COMWASIMatrixReasonTScore|Num|8|BEST|11,471|2|11,471|||
|2257|COMWASIMatrixReasonAgeScaledScor|COMWASIMatrixReasonAgeScaledScore|Num|8|BEST|11,471|2|11,471|||
|2258|COMWASIVerbIQScore|COMWASIVerbIQScore|Num|8|BEST|11,471|2|11,471|||
|2259|COMWASIVerbIQPct|COMWASIVerbIQPct|Num|8|BEST|11,471|2|11,471|||
|2260|COMWASIPerfIQScore|COMWASIPerfIQScore|Num|8|BEST|11,471|2|11,471|||
|2261|COMWASIPerfIQPct|COMWASIPerfIQPct|Num|8|BEST|11,471|2|11,471|||
|2262|COMWASIFullScaleIQScore|COMWASIFullScaleIQScore|Num|8|BEST|11,471|2|11,471|||
|2263|COMWASIFullScaleIQPct|COMWASIFullScaleIQPct|Num|8|BEST|11,471|2|11,471|||
|2264|COMWISCONSINTotNumbCategNumber|COMWISCONSINTotNumbCategNumber|Num|8|BEST|11,471|2|11,471|||
|2265|COMWISCONSINTotNumbCategNorm|COMWISCONSINTotNumbCategNorm|Num|8|BEST|11,471|2|11,471|||
|2266|COMWISCONSINTotNumCardsNumber|COMWISCONSINTotNumCardsNumber|Num|8|BEST|11,471|2|11,471|||
|2267|COMWISCONSINTotNumCardsNorm|COMWISCONSINTotNumCardsNorm|Num|8|BEST|11,471|2|11,471|||
|2268|COMWISCONSINTotNumbPersevNumber|COMWISCONSINTotNumbPersevNumber|Num|8|BEST|11,471|2|11,471|||
|2269|COMWISCONSINTotNumbPersevNorm|COMWISCONSINTotNumbPersevNorm|Num|8|BEST|11,471|2|11,471|||
|2270|COMWISCONSINNumbLossOfSetErrNumb|COMWISCONSINNumbLossOfSetErrNumber|Num|8|BEST|11,471|2|11,471|||
|2271|COMWISCONSINNumbLossOfSetErrNorm|COMWISCONSINNumbLossOfSetErrNorm|Num|8|BEST|11,471|2|11,471|||
|2272|COMWISCONSINNumbFirstSortNumber|COMWISCONSINNumbFirstSortNumber|Num|8|BEST|11,471|2|11,471|||
|2273|COMWISCONSINNumbFirstSortNorm|COMWISCONSINNumbFirstSortNorm|Num|8|BEST|11,471|2|11,471|||
|2274|COMTOMMLearnTrial1Raw|COMTOMMLearnTrial1Raw|Num|8|BEST|11,471|2|11,471|||
|2275|COMTOMMLearnTrial2Raw|COMTOMMLearnTrial2Raw|Num|8|BEST|11,471|2|11,471|||
|2276|COMTOMMDelayedResultRaw|COMTOMMDelayedResultRaw|Num|8|BEST|11,471|2|11,471|||
|2277|COMBeckDIScoreRaw|COMBeckDIScoreRaw|Num|8|BEST|11,471|2|11,471|||
|2278|COMBeckDIScoreNorm|COMBeckDIScoreNorm|Num|8|BEST|11,471|2|11,471|||
|2279|COMBeckDIGeriatDepScaleRaw|COMBeckDIGeriatDepScaleRaw|Num|8|BEST|11,471|2|11,471|||
|2280|COMRBANSImmedMemIdxScore|COMRBANSImmedMemIdxScore|Num|8|BEST|11,471|2|11,471|||
|2281|COMRBANSImmedMemPctile|COMRBANSImmedMemPctile|Num|8|BEST|11,471|2|11,471|||
|2282|COMRBANSListLearnTotScore|COMRBANSListLearnTotScore|Num|8|BEST|11,471|2|11,471|||
|2283|COMRBANSListLearnScaled|COMRBANSListLearnScaled|Num|8|BEST|11,471|2|11,471|||
|2284|COMRBANSStoryMemTotScore|COMRBANSStoryMemTotScore|Num|8|BEST|11,471|2|11,471|||
|2285|COMRBANSStoryMemScaled|COMRBANSStoryMemScaled|Num|8|BEST|11,471|2|11,471|||
|2286|COMRBANSVisuoConstructIdxScore|COMRBANSVisuoConstructIdxScore|Num|8|BEST|11,471|2|11,471|||
|2287|COMRBANSVisuoConstructPctile|COMRBANSVisuoConstructPctile|Num|8|BEST|11,471|2|11,471|||
|2288|COMRBANSFigCopyTotScore|COMRBANSFigCopyTotScore|Num|8|BEST|11,471|2|11,471|||
|2289|COMRBANSFigCopyScaled|COMRBANSFigCopyScaled|Num|8|BEST|11,471|2|11,471|||
|2290|COMRBANSLineOrientTotScore|COMRBANSLineOrientTotScore|Num|8|BEST|11,471|2|11,471|||
|2291|COMRBANSLangIdxScore|COMRBANSLangIdxScore|Num|8|BEST|11,471|2|11,471|||
|2292|COMRBANSLangPctile|COMRBANSLangPctile|Num|8|BEST|11,471|2|11,471|||
|2293|COMRBANSPictNameTotScore|COMRBANSPictNameTotScore|Num|8|BEST|11,471|2|11,471|||
|2294|COMRBANSSemFluTotScore|COMRBANSSemFluTotScore|Num|8|BEST|11,471|2|11,471|||
|2295|COMRBANSSemFluScaled|COMRBANSSemFluScaled|Num|8|BEST|11,471|2|11,471|||
|2296|COMRBANSAttnIdxScore|COMRBANSAttnIdxScore|Num|8|BEST|11,471|2|11,471|||
|2297|COMRBANSAttnPctile|COMRBANSAttnPctile|Num|8|BEST|11,471|2|11,471|||
|2298|COMRBANSDigSpanTotScore|COMRBANSDigSpanTotScore|Num|8|BEST|11,471|2|11,471|||
|2299|COMRBANSDigSpanScaled|COMRBANSDigSpanScaled|Num|8|BEST|11,471|2|11,471|||
|2300|COMRBANSCodingTotScore|COMRBANSCodingTotScore|Num|8|BEST|11,471|2|11,471|||
|2301|COMRBANSCodingScaled|COMRBANSCodingScaled|Num|8|BEST|11,471|2|11,471|||
|2302|COMRBANSDelaymemIdxScore|COMRBANSDelaymemIdxScore|Num|8|BEST|11,471|2|11,471|||
|2303|COMRBANSDelaymemPctile|COMRBANSDelaymemPctile|Num|8|BEST|11,471|2|11,471|||
|2304|COMRBANSListRecallTotScore|COMRBANSListRecallTotScore|Num|8|BEST|11,471|2|11,471|||
|2305|COMRBANSListRecogTotScore|COMRBANSListRecogTotScore|Num|8|BEST|11,471|2|11,471|||
|2306|COMRBANSStoryRecallTotScore|COMRBANSStoryRecallTotScore|Num|8|BEST|11,471|2|11,471|||
|2307|COMRBANSStoryRecallScaled|COMRBANSStoryRecallScaled|Num|8|BEST|11,471|2|11,471|||
|2308|COMRBANSFigRecallTotScore|COMRBANSFigRecallTotScore|Num|8|BEST|11,471|2|11,471|||
|2309|COMRBANSFigRecallScaled|COMRBANSFigRecallScaled|Num|8|BEST|11,471|2|11,471|||
|2310|COMRBANSTotScaleIdxScore|COMRBANSTotScaleIdxScore|Num|8|BEST|11,471|2|11,471|||
|2311|COMRBANSTotScalePctile|COMRBANSTotScalePctile|Num|8|BEST|11,471|2|11,471|||
|2312|COMWAISIVBlockDesignTotRaw|COMWAISIVBlockDesignTotRaw|Num|8|BEST|11,471|2|11,471|||
|2313|COMWAISIVBlockDesignScaledScore|COMWAISIVBlockDesignScaledScore|Num|8|BEST|11,471|2|11,471|||
|2314|COMWAISIVBlockDesignRefGroupSS|COMWAISIVBlockDesignRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2315|COMWAISIVBlockDesignNoTimeBonus|COMWAISIVBlockDesignNoTimeBonus|Num|8|BEST|11,471|2|11,471|||
|2316|COMWAISIVSimilaritiesTotRaw|COMWAISIVSimilaritiesTotRaw|Num|8|BEST|11,471|2|11,471|||
|2317|COMWAISIVSimilaritiesScaledScore|COMWAISIVSimilaritiesScaledScore|Num|8|BEST|11,471|2|11,471|||
|2318|COMWAISIVSimilaritiesRefGroupSS|COMWAISIVSimilaritiesRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2319|COMWAISIVDigSpanTotTotRaw|COMWAISIVDigSpanTotTotRaw|Num|8|BEST|11,471|2|11,471|||
|2320|COMWAISIVDigSpanTotScaledScore|COMWAISIVDigSpanTotScaledScore|Num|8|BEST|11,471|2|11,471|||
|2321|COMWAISIVDigSpanTotRefGroupSS|COMWAISIVDigSpanTotRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2322|COMWAISIVDigSpanFwdTotRaw|COMWAISIVDigSpanFwdTotRaw|Num|8|BEST|11,471|2|11,471|||
|2323|COMWAISIVDigSpanFwdScaledScore|COMWAISIVDigSpanFwdScaledScore|Num|8|BEST|11,471|2|11,471|||
|2324|COMWAISIVDigSpanFwdRefGroupSS|COMWAISIVDigSpanFwdRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2325|COMWAISIVDigSpanFwdLDSF|COMWAISIVDigSpanFwdLDSF|Num|8|BEST|11,471|2|11,471|||
|2326|COMWAISIVDigSpanBwdTotRaw|COMWAISIVDigSpanBwdTotRaw|Num|8|BEST|11,471|2|11,471|||
|2327|COMWAISIVDigSpanBwdScaledScore|COMWAISIVDigSpanBwdScaledScore|Num|8|BEST|11,471|2|11,471|||
|2328|COMWAISIVDigSpanBwdRefGroupSS|COMWAISIVDigSpanBwdRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2329|COMWAISIVDigSpanBwdLDSB|COMWAISIVDigSpanBwdLDSB|Num|8|BEST|11,471|2|11,471|||
|2330|COMWAISIVDigSpanSeqTotRaw|COMWAISIVDigSpanSeqTotRaw|Num|8|BEST|11,471|2|11,471|||
|2331|COMWAISIVDigSpanSeqScaledScore|COMWAISIVDigSpanSeqScaledScore|Num|8|BEST|11,471|2|11,471|||
|2332|COMWAISIVDigSpanSeqRefGroupSS|COMWAISIVDigSpanSeqRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2333|COMWAISIVDigSpanSeqLDSS|COMWAISIVDigSpanSeqLDSS|Num|8|BEST|11,471|2|11,471|||
|2334|COMWAISIVMatrixReasTotRaw|COMWAISIVMatrixReasTotRaw|Num|8|BEST|11,471|2|11,471|||
|2335|COMWAISIVMatrixReasScaledScore|COMWAISIVMatrixReasScaledScore|Num|8|BEST|11,471|2|11,471|||
|2336|COMWAISIVMatrixReasRefGroupSS|COMWAISIVMatrixReasRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2337|COMWAISIVVocabTotRaw|COMWAISIVVocabTotRaw|Num|8|BEST|11,471|2|11,471|||
|2338|COMWAISIVVocabScaledScore|COMWAISIVVocabScaledScore|Num|8|BEST|11,471|2|11,471|||
|2339|COMWAISIVVocabRefGroupSS|COMWAISIVVocabRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2340|COMWAISIVArithTotRaw|COMWAISIVArithTotRaw|Num|8|BEST|11,471|2|11,471|||
|2341|COMWAISIVArithScaledScore|COMWAISIVArithScaledScore|Num|8|BEST|11,471|2|11,471|||
|2342|COMWAISIVArithRefGroupSS|COMWAISIVArithRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2343|COMWAISIVSymSearchTotRaw|COMWAISIVSymSearchTotRaw|Num|8|BEST|11,471|2|11,471|||
|2344|COMWAISIVSymSearchScaledScore|COMWAISIVSymSearchScaledScore|Num|8|BEST|11,471|2|11,471|||
|2345|COMWAISIVSymSearchRefGroupSS|COMWAISIVSymSearchRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2346|COMWAISIVSSComplTimeSecs|COMWAISIVSSComplTimeSecs|Num|8|BEST|11,471|2|11,471|||
|2347|COMWAISIVSSComplTimeNumCorr|COMWAISIVSSComplTimeNumCorr|Num|8|BEST|11,471|2|11,471|||
|2348|COMWAISIVSSComplTimeNumIncorr|COMWAISIVSSComplTimeNumIncorr|Num|8|BEST|11,471|2|11,471|||
|2349|COMWAISIVVisPuzzlTotRaw|COMWAISIVVisPuzzlTotRaw|Num|8|BEST|11,471|2|11,471|||
|2350|COMWAISIVVisPuzzlScaledScore|COMWAISIVVisPuzzlScaledScore|Num|8|BEST|11,471|2|11,471|||
|2351|COMWAISIVVisPuzzlRefGroupSS|COMWAISIVVisPuzzlRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2352|COMWAISIVInfoTotRaw|COMWAISIVInfoTotRaw|Num|8|BEST|11,471|2|11,471|||
|2353|COMWAISIVInfoScaledScore|COMWAISIVInfoScaledScore|Num|8|BEST|11,471|2|11,471|||
|2354|COMWAISIVInfoRefGroupSS|COMWAISIVInfoRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2355|COMWAISIVCodingTotRaw|COMWAISIVCodingTotRaw|Num|8|BEST|11,471|2|11,471|||
|2356|COMWAISIVCodingScaledScore|COMWAISIVCodingScaledScore|Num|8|BEST|11,471|2|11,471|||
|2357|COMWAISIVCodingRefGroupSS|COMWAISIVCodingRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2358|COMWAISIVCodingComplTime|COMWAISIVCodingComplTime|Num|8|BEST|11,471|2|11,471|||
|2359|COMWAISIVLetNumSeqTotRaw|COMWAISIVLetNumSeqTotRaw|Num|8|BEST|11,471|2|11,471|||
|2360|COMWAISIVLetNumSeqScaledScore|COMWAISIVLetNumSeqScaledScore|Num|8|BEST|11,471|2|11,471|||
|2361|COMWAISIVLetNumSeqRefGroupSS|COMWAISIVLetNumSeqRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2362|COMWAISIVLetNumSeqLLNS|COMWAISIVLetNumSeqLLNS|Num|8|BEST|11,471|2|11,471|||
|2363|COMWAISIVFigWtsTotRaw|COMWAISIVFigWtsTotRaw|Num|8|BEST|11,471|2|11,471|||
|2364|COMWAISIVFigWtsScaledScore|COMWAISIVFigWtsScaledScore|Num|8|BEST|11,471|2|11,471|||
|2365|COMWAISIVFigWtsRefGroupSS|COMWAISIVFigWtsRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2366|COMWAISIVComprehenTotRaw|COMWAISIVComprehenTotRaw|Num|8|BEST|11,471|2|11,471|||
|2367|COMWAISIVComprehenScaledScore|COMWAISIVComprehenScaledScore|Num|8|BEST|11,471|2|11,471|||
|2368|COMWAISIVComprehenRefGroupSS|COMWAISIVComprehenRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2369|COMWAISIVCancellationTotRaw|COMWAISIVCancellationTotRaw|Num|8|BEST|11,471|2|11,471|||
|2370|COMWAISIVCancellationScaledScore|COMWAISIVCancellationScaledScore|Num|8|BEST|11,471|2|11,471|||
|2371|COMWAISIVCancellationRefGroupSS|COMWAISIVCancellationRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2372|COMWAISIVCanComplTime1Secs|COMWAISIVCanComplTime1Secs|Num|8|BEST|11,471|2|11,471|||
|2373|COMWAISIVCanComplTime1NumCorr|COMWAISIVCanComplTime1NumCorr|Num|8|BEST|11,471|2|11,471|||
|2374|COMWAISIVCanComplTime1NumIncorr|COMWAISIVCanComplTime1NumIncorr|Num|8|BEST|11,471|2|11,471|||
|2375|COMWAISIVCanComplTime1ItemScore|COMWAISIVCanComplTime1ItemScore|Num|8|BEST|11,471|2|11,471|||
|2376|COMWAISIVCanComplTime2Secs|COMWAISIVCanComplTime2Secs|Num|8|BEST|11,471|2|11,471|||
|2377|COMWAISIVCanComplTime2NumCorr|COMWAISIVCanComplTime2NumCorr|Num|8|BEST|11,471|2|11,471|||
|2378|COMWAISIVCanComplTime2NumIncorr|COMWAISIVCanComplTime2NumIncorr|Num|8|BEST|11,471|2|11,471|||
|2379|COMWAISIVCanComplTime2ItemScore|COMWAISIVCanComplTime2ItemScore|Num|8|BEST|11,471|2|11,471|||
|2380|COMWAISIVPictCompleTotRaw|COMWAISIVPictCompleTotRaw|Num|8|BEST|11,471|2|11,471|||
|2381|COMWAISIVPictCompleScaledScore|COMWAISIVPictCompleScaledScore|Num|8|BEST|11,471|2|11,471|||
|2382|COMWAISIVPictCompleRefGroupSS|COMWAISIVPictCompleRefGroupSS|Num|8|BEST|11,471|2|11,471|||
|2383|COMWAISIVVerbCompSumScaled|COMWAISIVVerbCompSumScaled|Num|8|BEST|11,471|2|11,471|||
|2384|COMWAISIVVerbCompComposite|COMWAISIVVerbCompComposite|Num|8|BEST|11,471|2|11,471|||
|2385|COMWAISIVVerbCompPctileRank|COMWAISIVVerbCompPctileRank|Num|8|BEST|11,471|2|11,471|||
|2386|COMWAISIVPercepReasSumScaled|COMWAISIVPercepReasSumScaled|Num|8|BEST|11,471|2|11,471|||
|2387|COMWAISIVPercepReasComposite|COMWAISIVPercepReasComposite|Num|8|BEST|11,471|2|11,471|||
|2388|COMWAISIVPercepReasPctileRank|COMWAISIVPercepReasPctileRank|Num|8|BEST|11,471|2|11,471|||
|2389|COMWAISIVWorkingMemSumScaled|COMWAISIVWorkingMemSumScaled|Num|8|BEST|11,471|2|11,471|||
|2390|COMWAISIVWorkingMemComposite|COMWAISIVWorkingMemComposite|Num|8|BEST|11,471|2|11,471|||
|2391|COMWAISIVWorkingMemPctileRank|COMWAISIVWorkingMemPctileRank|Num|8|BEST|11,471|2|11,471|||
|2392|COMWAISIVProcessSpdSumScaled|COMWAISIVProcessSpdSumScaled|Num|8|BEST|11,471|2|11,471|||
|2393|COMWAISIVProcessSpdComposite|COMWAISIVProcessSpdComposite|Num|8|BEST|11,471|2|11,471|||
|2394|COMWAISIVProcessSpdPctileRank|COMWAISIVProcessSpdPctileRank|Num|8|BEST|11,471|2|11,471|||
|2395|COMWAISIVFullScaleSumScaled|COMWAISIVFullScaleSumScaled|Num|8|BEST|11,471|2|11,471|||
|2396|COMWAISIVFullScaleComposite|COMWAISIVFullScaleComposite|Num|8|BEST|11,471|2|11,471|||
|2397|COMWAISIVFullScalePctileRank|COMWAISIVFullScalePctileRank|Num|8|BEST|11,471|2|11,471|||
|2398|COMIADLTelUseValue|COMIADLTelUseValue|Num|8|BEST|11,471|2|11,471|||
|2399|COMIADLShoppingValue|COMIADLShoppingValue|Num|8|BEST|11,471|2|11,471|||
|2400|COMIADLFoodPrepValue|COMIADLFoodPrepValue|Num|8|BEST|11,471|2|11,471|||
|2401|COMIADLLaundryValue|COMIADLLaundryValue|Num|8|BEST|11,471|2|11,471|||
|2402|COMIADLHousekeepingValue|COMIADLHousekeepingValue|Num|8|BEST|11,471|2|11,471|||
|2403|COMIADLTransportValue|COMIADLTransportValue|Num|8|BEST|11,471|2|11,471|||
|2404|COMIADLMedResponsibValue|COMIADLMedResponsibValue|Num|8|BEST|11,471|2|11,471|||
|2405|COMIADLHandleFinancesValue|COMIADLHandleFinancesValue|Num|8|BEST|11,471|2|11,471|||
|2406|COMIADLTotalScoreValue|COMIADLTotalScoreValue|Num|8|BEST|11,471|2|11,471|||
|2407|COMIADLAbilityChangeValue|COMIADLAbilityChangeValue|Num|8|BEST|11,471|2|11,471|||
|2408|COMEDSSEDSSScore|COMEDSSEDSSScore|Num|8|BEST|11,471|2|11,471|||
|2409|COMMFISMFISScore|COMMFISMFISScore|Num|8|BEST|11,471|2|11,471|||
|2410|COMMOCASubScaleScoreVisSpaExec|COMMOCASubScaleScoreVisSpaExec|Num|8|BEST|11,471|2|11,471|||
|2411|COMMOCASubScaleScoreNaming|COMMOCASubScaleScoreNaming|Num|8|BEST|11,471|2|11,471|||
|2412|COMMOCASubScaleScoreMem1|COMMOCASubScaleScoreMem1|Num|8|BEST|11,471|2|11,471|||
|2413|COMMOCASubScaleScoreMem2|COMMOCASubScaleScoreMem2|Num|8|BEST|11,471|2|11,471|||
|2414|COMMOCASubScaleScoreDigSpan|COMMOCASubScaleScoreDigSpan|Num|8|BEST|11,471|2|11,471|||
|2415|COMMOCASubScaleScoreVigil|COMMOCASubScaleScoreVigil|Num|8|BEST|11,471|2|11,471|||
|2416|COMMOCASubScaleScoreSer7s|COMMOCASubScaleScoreSer7s|Num|8|BEST|11,471|2|11,471|||
|2417|COMMOCASubScaleScoreAttn|COMMOCASubScaleScoreAttn|Num|8|BEST|11,471|2|11,471|||
|2418|COMMOCASubScaleScoreRepeat|COMMOCASubScaleScoreRepeat|Num|8|BEST|11,471|2|11,471|||
|2419|COMMOCASubScaleScoreFluency|COMMOCASubScaleScoreFluency|Num|8|BEST|11,471|2|11,471|||
|2420|COMMOCASubScaleScoreLang|COMMOCASubScaleScoreLang|Num|8|BEST|11,471|2|11,471|||
|2421|COMMOCASubScaleScoreAbstract|COMMOCASubScaleScoreAbstract|Num|8|BEST|11,471|2|11,471|||
|2422|COMMOCASubScaleScoreDelayed|COMMOCASubScaleScoreDelayed|Num|8|BEST|11,471|2|11,471|||
|2423|COMMOCASubScaleScoreCatCue|COMMOCASubScaleScoreCatCue|Num|8|BEST|11,471|2|11,471|||
|2424|COMMOCASubScaleScoreMultChoice|COMMOCASubScaleScoreMultChoice|Num|8|BEST|11,471|2|11,471|||
|2425|COMMOCASubScaleScoreOrient|COMMOCASubScaleScoreOrient|Num|8|BEST|11,471|2|11,471|||
|2426|COMMOCASubScaleScoreTotal|COMMOCASubScaleScoreTotal|Num|8|BEST|11,471|2|11,471|||
|2427|COPYDwgTotStrokes|COPYDwgTotStrokes|Num|8|BEST|11,471|73|0|||
|2428|COPYDwgTotTime|COPYDwgTotTime|Num|8|BEST|6,943|6,283|0|||
|2429|COPYClockFace1TotStrokes|COPYClockFace1TotStrokes|Num|8|BEST|11,471|11|147|||
|2430|COPYClockFace1TotTime|COPYClockFace1TotTime|Num|8|BEST|11,471|1,130|147|||
|2431|COPYClockFace1TotLen|COPYClockFace1TotLen|Num|8|BEST|11,471|11,324|147|||
|2432|COPYClockFace1PnSpdQ1|COPYClockFace1PnSpdQ1|Num|8|BEST|11,471|11,057|414|||
|2433|COPYClockFace1PnSpdQ2|COPYClockFace1PnSpdQ2|Num|8|BEST|11,471|11,057|414|||
|2434|COPYClockFace1PnSpdQ3|COPYClockFace1PnSpdQ3|Num|8|BEST|11,471|11,057|414|||
|2435|COPYClockFace1PnSpdQ4|COPYClockFace1PnSpdQ4|Num|8|BEST|11,471|11,057|414|||
|2436|COPYClockFace1HorizSz|COPYClockFace1HorizSz|Num|8|BEST|11,471|1,567|147|||
|2437|COPYClockFace1VertSz|COPYClockFace1VertSz|Num|8|BEST|11,471|1,577|147|||
|2438|COPYClockFace1FitHSz|COPYClockFace1FitHSz|Num|8|BEST|11,471|11,324|147|||
|2439|COPYClockFace1FitVSz|COPYClockFace1FitVSz|Num|8|BEST|11,471|11,324|147|||
|2440|COPYClockFace1HorSymm|COPYClockFace1HorSymm|Num|8|BEST|11,471|11,324|147|||
|2441|COPYClockFace1VertSymm|COPYClockFace1VertSymm|Num|8|BEST|11,471|11,324|147|||
|2442|COPYClockFace1EllipHSymm|COPYClockFace1EllipHSymm|Num|8|BEST|11,471|11,324|147|||
|2443|COPYClockFace1EllipVSymm|COPYClockFace1EllipVSymm|Num|8|BEST|11,471|11,324|147|||
|2444|COPYClockFace1ClosedPct|COPYClockFace1ClosedPct|Num|8|BEST|11,471|10,755|415|||
|2445|COPYClockFace1ClosedAng|COPYClockFace1ClosedAng|Num|8|BEST|11,471|11,056|415|||
|2446|COPYClockFace1EllipAng|COPYClockFace1EllipAng|Num|8|BEST|11,471|11,324|147|||
|2447|COPYClockFace1CenterX|COPYClockFace1CenterX|Num|8|BEST|11,471|11,324|147|||
|2448|COPYClockFace1CenterY|COPYClockFace1CenterY|Num|8|BEST|11,471|11,324|147|||
|2449|COPYClockFace2TotStrokes|COPYClockFace2TotStrokes|Num|8|BEST|11,471|5|11,356|||
|2450|COPYClockFace2TotTime|COPYClockFace2TotTime|Num|8|BEST|11,471|104|11,356|||
|2451|COPYClockFace2TotLen|COPYClockFace2TotLen|Num|8|BEST|11,471|117|11,356|||
|2452|COPYClockFace2PnSpdQ1|COPYClockFace2PnSpdQ1|Num|8|BEST|11,471|114|11,359|||
|2453|COPYClockFace2PnSpdQ2|COPYClockFace2PnSpdQ2|Num|8|BEST|11,471|114|11,359|||
|2454|COPYClockFace2PnSpdQ3|COPYClockFace2PnSpdQ3|Num|8|BEST|11,471|114|11,359|||
|2455|COPYClockFace2PnSpdQ4|COPYClockFace2PnSpdQ4|Num|8|BEST|11,471|114|11,359|||
|2456|COPYClockFace2HorizSz|COPYClockFace2HorizSz|Num|8|BEST|11,471|109|11,356|||
|2457|COPYClockFace2VertSz|COPYClockFace2VertSz|Num|8|BEST|11,471|111|11,356|||
|2458|COPYClockFace2FitHSz|COPYClockFace2FitHSz|Num|8|BEST|11,471|117|11,356|||
|2459|COPYClockFace2FitVSz|COPYClockFace2FitVSz|Num|8|BEST|11,471|117|11,356|||
|2460|COPYClockFace2HorSymm|COPYClockFace2HorSymm|Num|8|BEST|11,471|117|11,356|||
|2461|COPYClockFace2VertSymm|COPYClockFace2VertSymm|Num|8|BEST|11,471|117|11,356|||
|2462|COPYClockFace2EllipHSymm|COPYClockFace2EllipHSymm|Num|8|BEST|11,471|117|11,356|||
|2463|COPYClockFace2EllipVSymm|COPYClockFace2EllipVSymm|Num|8|BEST|11,471|117|11,356|||
|2464|COPYClockFace2ClosedPct|COPYClockFace2ClosedPct|Num|8|BEST|11,471|114|11,359|||
|2465|COPYClockFace2ClosedAng|COPYClockFace2ClosedAng|Num|8|BEST|11,471|114|11,359|||
|2466|COPYClockFace2EllipAng|COPYClockFace2EllipAng|Num|8|BEST|11,471|117|11,356|||
|2467|COPYClockFace2CenterX|COPYClockFace2CenterX|Num|8|BEST|11,471|117|11,356|||
|2468|COPYClockFace2CenterY|COPYClockFace2CenterY|Num|8|BEST|11,471|117|11,356|||
|2469|COPYHH1TotStrokes|COPYHH1TotStrokes|Num|8|BEST|11,471|13|323|||
|2470|COPYHH1TotTime|COPYHH1TotTime|Num|8|BEST|11,471|3,711|323|||
|2471|COPYHH1TotLen|COPYHH1TotLen|Num|8|BEST|11,471|11,148|323|||
|2472|COPYHH1HandLen|COPYHH1HandLen|Num|8|BEST|11,471|9,523|323|||
|2473|COPYHH1HandLenNorm|COPYHH1HandLenNorm|Num|8|BEST|11,471|11,118|349|||
|2474|COPYHH1CenterX|COPYHH1CenterX|Num|8|BEST|11,471|11,118|323|||
|2475|COPYHH1CenterY|COPYHH1CenterY|Num|8|BEST|11,471|11,128|323|||
|2476|COPYHH1Dir|COPYHH1Dir|Num|8|BEST|11,471|4|323|||
|2477|COPYHH1ArrowDir|COPYHH1ArrowDir|Num|8|BEST|11,471|5|323|||
|2478|COPYHH1DistCent|COPYHH1DistCent|Num|8|BEST|11,471|11,122|349|||
|2479|COPYHH1Angle|COPYHH1Angle|Num|8|BEST|11,471|9,245|323|||
|2480|COPYHH1DiffIdealAng|COPYHH1DiffIdealAng|Num|8|BEST|11,471|9,245|323|||
|2481|COPYHH1AngTo11|COPYHH1AngTo11|Num|8|BEST|11,471|11,032|438|||
|2482|COPYHH2TotStrokes|COPYHH2TotStrokes|Num|8|BEST|11,471|3|11,469|||
|2483|COPYHH2TotTime|COPYHH2TotTime|Num|8|BEST|11,471|4|11,469|||
|2484|COPYHH2TotLen|COPYHH2TotLen|Num|8|BEST|11,471|4|11,469|||
|2485|COPYHH2HandLen|COPYHH2HandLen|Num|8|BEST|11,471|4|11,469|||
|2486|COPYHH2HandLenNorm|COPYHH2HandLenNorm|Num|8|BEST|11,471|4|11,469|||
|2487|COPYHH2CenterX|COPYHH2CenterX|Num|8|BEST|11,471|4|11,469|||
|2488|COPYHH2CenterY|COPYHH2CenterY|Num|8|BEST|11,471|4|11,469|||
|2489|COPYHH2Dir|COPYHH2Dir|Num|8|BEST|11,471|3|11,469|||
|2490|COPYHH2ArrowDir|COPYHH2ArrowDir|Num|8|BEST|11,471|3|11,469|||
|2491|COPYHH2DistCent|COPYHH2DistCent|Num|8|BEST|11,471|4|11,469|||
|2492|COPYHH2Angle|COPYHH2Angle|Num|8|BEST|11,471|4|11,469|||
|2493|COPYHH2DiffIdealAng|COPYHH2DiffIdealAng|Num|8|BEST|11,471|4|11,469|||
|2494|COPYHH2AngTo11|COPYHH2AngTo11|Num|8|BEST|11,471|4|11,469|||
|2495|COPYHH3TotStrokes|COPYHH3TotStrokes|Num|8|BEST|11,471|3|11,470|||
|2496|COPYHH3TotTime|COPYHH3TotTime|Num|8|BEST|11,471|3|11,470|||
|2497|COPYHH3TotLen|COPYHH3TotLen|Num|8|BEST|11,471|3|11,470|||
|2498|COPYHH3HandLen|COPYHH3HandLen|Num|8|BEST|11,471|3|11,470|||
|2499|COPYHH3HandLenNorm|COPYHH3HandLenNorm|Num|8|BEST|11,471|3|11,470|||
|2500|COPYHH3CenterX|COPYHH3CenterX|Num|8|BEST|11,471|3|11,470|||
|2501|COPYHH3CenterY|COPYHH3CenterY|Num|8|BEST|11,471|3|11,470|||
|2502|COPYHH3Dir|COPYHH3Dir|Num|8|BEST|11,471|3|11,470|||
|2503|COPYHH3ArrowDir|COPYHH3ArrowDir|Num|8|BEST|11,471|3|11,470|||
|2504|COPYHH3DistCent|COPYHH3DistCent|Num|8|BEST|11,471|3|11,470|||
|2505|COPYHH3Angle|COPYHH3Angle|Num|8|BEST|11,471|3|11,470|||
|2506|COPYHH3DiffIdealAng|COPYHH3DiffIdealAng|Num|8|BEST|11,471|3|11,470|||
|2507|COPYHH3AngTo11|COPYHH3AngTo11|Num|8|BEST|11,471|3|11,470|||
|2508|COPYMH1TotStrokes|COPYMH1TotStrokes|Num|8|BEST|11,471|12|325|||
|2509|COPYMH1TotTime|COPYMH1TotTime|Num|8|BEST|11,471|3,494|325|||
|2510|COPYMH1TotLen|COPYMH1TotLen|Num|8|BEST|11,471|11,146|325|||
|2511|COPYMH1HandLen|COPYMH1HandLen|Num|8|BEST|11,471|10,156|325|||
|2512|COPYMH1HandLenNorm|COPYMH1HandLenNorm|Num|8|BEST|11,471|11,120|351|||
|2513|COPYMH1CenterX|COPYMH1CenterX|Num|8|BEST|11,471|11,108|325|||
|2514|COPYMH1CenterY|COPYMH1CenterY|Num|8|BEST|11,471|11,132|325|||
|2515|COPYMH1Dir|COPYMH1Dir|Num|8|BEST|11,471|4|325|||
|2516|COPYMH1ArrowDir|COPYMH1ArrowDir|Num|8|BEST|11,471|5|325|||
|2517|COPYMH1DistCent|COPYMH1DistCent|Num|8|BEST|11,471|11,120|351|||
|2518|COPYMH1Angle|COPYMH1Angle|Num|8|BEST|11,471|9,937|325|||
|2519|COPYMH1DiffIdealAng|COPYMH1DiffIdealAng|Num|8|BEST|11,471|9,937|325|||
|2520|COPYMH1AngTo2|COPYMH1AngTo2|Num|8|BEST|11,471|11,073|397|||
|2521|COPYMH2TotStrokes|COPYMH2TotStrokes|Num|8|BEST|11,471|4|11,467|||
|2522|COPYMH2TotTime|COPYMH2TotTime|Num|8|BEST|11,471|6|11,467|||
|2523|COPYMH2TotLen|COPYMH2TotLen|Num|8|BEST|11,471|6|11,467|||
|2524|COPYMH2HandLen|COPYMH2HandLen|Num|8|BEST|11,471|6|11,467|||
|2525|COPYMH2HandLenNorm|COPYMH2HandLenNorm|Num|8|BEST|11,471|6|11,467|||
|2526|COPYMH2CenterX|COPYMH2CenterX|Num|8|BEST|11,471|6|11,467|||
|2527|COPYMH2CenterY|COPYMH2CenterY|Num|8|BEST|11,471|6|11,467|||
|2528|COPYMH2Dir|COPYMH2Dir|Num|8|BEST|11,471|3|11,467|||
|2529|COPYMH2ArrowDir|COPYMH2ArrowDir|Num|8|BEST|11,471|3|11,467|||
|2530|COPYMH2DistCent|COPYMH2DistCent|Num|8|BEST|11,471|6|11,467|||
|2531|COPYMH2Angle|COPYMH2Angle|Num|8|BEST|11,471|6|11,467|||
|2532|COPYMH2DiffIdealAng|COPYMH2DiffIdealAng|Num|8|BEST|11,471|6|11,467|||
|2533|COPYMH2AngTo2|COPYMH2AngTo2|Num|8|BEST|11,471|6|11,467|||
|2534|COPYMH3TotStrokes|COPYMH3TotStrokes|Num|8|BEST|11,471|3|11,470|||
|2535|COPYMH3TotTime|COPYMH3TotTime|Num|8|BEST|11,471|3|11,470|||
|2536|COPYMH3TotLen|COPYMH3TotLen|Num|8|BEST|11,471|3|11,470|||
|2537|COPYMH3HandLen|COPYMH3HandLen|Num|8|BEST|11,471|3|11,470|||
|2538|COPYMH3HandLenNorm|COPYMH3HandLenNorm|Num|8|BEST|11,471|3|11,470|||
|2539|COPYMH3CenterX|COPYMH3CenterX|Num|8|BEST|11,471|3|11,470|||
|2540|COPYMH3CenterY|COPYMH3CenterY|Num|8|BEST|11,471|3|11,470|||
|2541|COPYMH3Dir|COPYMH3Dir|Num|8|BEST|11,471|3|11,470|||
|2542|COPYMH3ArrowDir|COPYMH3ArrowDir|Num|8|BEST|11,471|3|11,470|||
|2543|COPYMH3DistCent|COPYMH3DistCent|Num|8|BEST|11,471|3|11,470|||
|2544|COPYMH3Angle|COPYMH3Angle|Num|8|BEST|11,471|3|11,470|||
|2545|COPYMH3DiffIdealAng|COPYMH3DiffIdealAng|Num|8|BEST|11,471|3|11,470|||
|2546|COPYMH3AngTo2|COPYMH3AngTo2|Num|8|BEST|11,471|3|11,470|||
|2547|COPYHandPair1IntX|COPYHandPair1IntX|Num|8|BEST|11,471|11,059|334|||
|2548|COPYHandPair1IntY|COPYHandPair1IntY|Num|8|BEST|11,471|11,104|334|||
|2549|COPYHandPair1Angle|COPYHandPair1Angle|Num|8|BEST|11,471|11,136|334|||
|2550|COPYHandPair2IntX|COPYHandPair2IntX|Num|8|BEST|11,471|6|11,467|||
|2551|COPYHandPair2IntY|COPYHandPair2IntY|Num|8|BEST|11,471|6|11,467|||
|2552|COPYHandPair2Angle|COPYHandPair2Angle|Num|8|BEST|11,471|6|11,467|||
|2553|COPYHandPair3IntX|COPYHandPair3IntX|Num|8|BEST|11,471|4|11,469|||
|2554|COPYHandPair3IntY|COPYHandPair3IntY|Num|8|BEST|11,471|4|11,469|||
|2555|COPYHandPair3Angle|COPYHandPair3Angle|Num|8|BEST|11,471|4|11,469|||
|2556|COPYHandPair4IntX|COPYHandPair4IntX|Num|8|BEST|11,471|4|11,469|||
|2557|COPYHandPair4IntY|COPYHandPair4IntY|Num|8|BEST|11,471|4|11,469|||
|2558|COPYHandPair4Angle|COPYHandPair4Angle|Num|8|BEST|11,471|4|11,469|||
|2559|COPYHandPair5IntX|COPYHandPair5IntX|Num|8|BEST|11,471|3|11,470|||
|2560|COPYHandPair5IntY|COPYHandPair5IntY|Num|8|BEST|11,471|3|11,470|||
|2561|COPYHandPair5Angle|COPYHandPair5Angle|Num|8|BEST|11,471|3|11,470|||
|2562|COPYHandPair6IntX|COPYHandPair6IntX|Num|8|BEST|11,471|3|11,470|||
|2563|COPYHandPair6IntY|COPYHandPair6IntY|Num|8|BEST|11,471|3|11,470|||
|2564|COPYHandPair6Angle|COPYHandPair6Angle|Num|8|BEST|11,471|3|11,470|||
|2565|COPYHandPair7IntX|COPYHandPair7IntX|Num|8|BEST|11,471|3|11,470|||
|2566|COPYHandPair7IntY|COPYHandPair7IntY|Num|8|BEST|11,471|3|11,470|||
|2567|COPYHandPair7Angle|COPYHandPair7Angle|Num|8|BEST|11,471|3|11,470|||
|2568|COPYHandPair8IntX|COPYHandPair8IntX|Num|8|BEST|11,471|3|11,470|||
|2569|COPYHandPair8IntY|COPYHandPair8IntY|Num|8|BEST|11,471|3|11,470|||
|2570|COPYHandPair8Angle|COPYHandPair8Angle|Num|8|BEST|11,471|3|11,470|||
|2571|COPYHandPair9IntX|COPYHandPair9IntX|Num|8|BEST|11,471|3|11,470|||
|2572|COPYHandPair9IntY|COPYHandPair9IntY|Num|8|BEST|11,471|3|11,470|||
|2573|COPYHandPair9Angle|COPYHandPair9Angle|Num|8|BEST|11,471|3|11,470|||
|2574|COPYDigit1Missing|COPYDigit1Missing|Num|8|BEST|11,471|3|0|||
|2575|COPYDigit2Missing|COPYDigit2Missing|Num|8|BEST|11,471|3|0|||
|2576|COPYDigit3Missing|COPYDigit3Missing|Num|8|BEST|11,471|3|0|||
|2577|COPYDigit4Missing|COPYDigit4Missing|Num|8|BEST|11,471|3|0|||
|2578|COPYDigit5Missing|COPYDigit5Missing|Num|8|BEST|11,471|3|0|||
|2579|COPYDigit6Missing|COPYDigit6Missing|Num|8|BEST|11,471|3|0|||
|2580|COPYDigit7Missing|COPYDigit7Missing|Num|8|BEST|11,471|3|0|||
|2581|COPYDigit8Missing|COPYDigit8Missing|Num|8|BEST|11,471|3|0|||
|2582|COPYDigit9Missing|COPYDigit9Missing|Num|8|BEST|11,471|3|0|||
|2583|COPYDigit10Missing|COPYDigit10Missing|Num|8|BEST|11,471|3|0|||
|2584|COPYDigit11Missing|COPYDigit11Missing|Num|8|BEST|11,471|3|0|||
|2585|COPYDigit12Missing|COPYDigit12Missing|Num|8|BEST|11,471|3|0|||
|2586|COPYDigitAvgWid|COPYDigitAvgWid|Num|8|BEST|11,471|1,781|150|||
|2587|COPYDigitAvgHt|COPYDigitAvgHt|Num|8|BEST|11,471|2,231|150|||
|2588|COPYDigAvgNormSizeQ1|COPYDigAvgNormSizeQ1|Num|8|BEST|11,471|10,847|205|||
|2589|COPYDigAvgNormSizeQ2|COPYDigAvgNormSizeQ2|Num|8|BEST|11,471|10,850|210|||
|2590|COPYDigAvgNormSizeQ3|COPYDigAvgNormSizeQ3|Num|8|BEST|11,471|10,859|253|||
|2591|COPYDigAvgNormSizeQ4|COPYDigAvgNormSizeQ4|Num|8|BEST|11,471|10,798|247|||
|2592|COPYDigNormSizeFirst3|COPYDigNormSizeFirst3|Num|8|BEST|11,471|10,780|190|||
|2593|COPYDigNormSizeSecond3|COPYDigNormSizeSecond3|Num|8|BEST|11,471|10,759|234|||
|2594|COPYDigNormSizeThird3|COPYDigNormSizeThird3|Num|8|BEST|11,471|10,776|259|||
|2595|COPYDigNormSizeFourth3|COPYDigNormSizeFourth3|Num|8|BEST|11,471|10,683|295|||
|2596|COPYDigit1Seq|COPYDigit1Seq|Num|8|BEST|11,471|15|262|||
|2597|COPYDigit1Strokes|COPYDigit1Strokes|Num|8|BEST|11,471|6|262|||
|2598|COPYDigit1Time|COPYDigit1Time|Num|8|BEST|11,471|270|262|||
|2599|COPYDigit1Len|COPYDigit1Len|Num|8|BEST|11,471|11,209|262|||
|2600|COPYDigit1CentX|COPYDigit1CentX|Num|8|BEST|11,471|1,760|262|||
|2601|COPYDigit1CentY|COPYDigit1CentY|Num|8|BEST|11,471|2,716|262|||
|2602|COPYDigit1Width|COPYDigit1Width|Num|8|BEST|11,471|166|262|||
|2603|COPYDigit1Hgt|COPYDigit1Hgt|Num|8|BEST|11,471|259|262|||
|2604|COPYDigit1NormHt|COPYDigit1NormHt|Num|8|BEST|11,471|9,974|295|||
|2605|COPYDigit1Outside|COPYDigit1Outside|Num|8|BEST|11,471|4|262|||
|2606|COPYDigit1Angle|COPYDigit1Angle|Num|8|BEST|11,471|11,177|262|||
|2607|COPYDigit1IdealDiff|COPYDigit1IdealDiff|Num|8|BEST|11,471|11,177|262|||
|2608|COPYDigit1DistCircum|COPYDigit1DistCircum|Num|8|BEST|11,471|9,393|262|||
|2609|COPYDigit1IsPersev|COPYDigit1IsPersev|Num|8|BEST|11,471|3|262|||
|2610|COPYDigit2Seq|COPYDigit2Seq|Num|8|BEST|11,471|15|202|||
|2611|COPYDigit2Strokes|COPYDigit2Strokes|Num|8|BEST|11,471|6|202|||
|2612|COPYDigit2Time|COPYDigit2Time|Num|8|BEST|11,471|294|202|||
|2613|COPYDigit2Len|COPYDigit2Len|Num|8|BEST|11,471|11,269|202|||
|2614|COPYDigit2CentX|COPYDigit2CentX|Num|8|BEST|11,471|1,971|202|||
|2615|COPYDigit2CentY|COPYDigit2CentY|Num|8|BEST|11,471|2,835|202|||
|2616|COPYDigit2Width|COPYDigit2Width|Num|8|BEST|11,471|268|202|||
|2617|COPYDigit2Hgt|COPYDigit2Hgt|Num|8|BEST|11,471|272|202|||
|2618|COPYDigit2NormHt|COPYDigit2NormHt|Num|8|BEST|11,471|10,102|236|||
|2619|COPYDigit2Outside|COPYDigit2Outside|Num|8|BEST|11,471|4|202|||
|2620|COPYDigit2Angle|COPYDigit2Angle|Num|8|BEST|11,471|11,236|202|||
|2621|COPYDigit2IdealDiff|COPYDigit2IdealDiff|Num|8|BEST|11,471|11,236|202|||
|2622|COPYDigit2DistCircum|COPYDigit2DistCircum|Num|8|BEST|11,471|9,612|202|||
|2623|COPYDigit2IsPersev|COPYDigit2IsPersev|Num|8|BEST|11,471|3|202|||
|2624|COPYDigit3Seq|COPYDigit3Seq|Num|8|BEST|11,471|14|232|||
|2625|COPYDigit3Strokes|COPYDigit3Strokes|Num|8|BEST|11,471|6|232|||
|2626|COPYDigit3Time|COPYDigit3Time|Num|8|BEST|11,471|277|232|||
|2627|COPYDigit3Len|COPYDigit3Len|Num|8|BEST|11,471|11,239|232|||
|2628|COPYDigit3CentX|COPYDigit3CentX|Num|8|BEST|11,471|2,067|232|||
|2629|COPYDigit3CentY|COPYDigit3CentY|Num|8|BEST|11,471|2,969|232|||
|2630|COPYDigit3Width|COPYDigit3Width|Num|8|BEST|11,471|242|232|||
|2631|COPYDigit3Hgt|COPYDigit3Hgt|Num|8|BEST|11,471|269|232|||
|2632|COPYDigit3NormHt|COPYDigit3NormHt|Num|8|BEST|11,471|10,061|266|||
|2633|COPYDigit3Outside|COPYDigit3Outside|Num|8|BEST|11,471|4|232|||
|2634|COPYDigit3Angle|COPYDigit3Angle|Num|8|BEST|11,471|11,206|232|||
|2635|COPYDigit3IdealDiff|COPYDigit3IdealDiff|Num|8|BEST|11,471|11,206|232|||
|2636|COPYDigit3DistCircum|COPYDigit3DistCircum|Num|8|BEST|11,471|9,294|232|||
|2637|COPYDigit3IsPersev|COPYDigit3IsPersev|Num|8|BEST|11,471|3|232|||
|2638|COPYDigit4Seq|COPYDigit4Seq|Num|8|BEST|11,471|14|245|||
|2639|COPYDigit4Strokes|COPYDigit4Strokes|Num|8|BEST|11,471|7|245|||
|2640|COPYDigit4Time|COPYDigit4Time|Num|8|BEST|11,471|1,581|245|||
|2641|COPYDigit4Len|COPYDigit4Len|Num|8|BEST|11,471|11,226|245|||
|2642|COPYDigit4CentX|COPYDigit4CentX|Num|8|BEST|11,471|2,063|245|||
|2643|COPYDigit4CentY|COPYDigit4CentY|Num|8|BEST|11,471|3,177|245|||
|2644|COPYDigit4Width|COPYDigit4Width|Num|8|BEST|11,471|228|245|||
|2645|COPYDigit4Hgt|COPYDigit4Hgt|Num|8|BEST|11,471|315|245|||
|2646|COPYDigit4NormHt|COPYDigit4NormHt|Num|8|BEST|11,471|10,223|278|||
|2647|COPYDigit4Outside|COPYDigit4Outside|Num|8|BEST|11,471|4|245|||
|2648|COPYDigit4Angle|COPYDigit4Angle|Num|8|BEST|11,471|11,194|245|||
|2649|COPYDigit4IdealDiff|COPYDigit4IdealDiff|Num|8|BEST|11,471|11,194|245|||
|2650|COPYDigit4DistCircum|COPYDigit4DistCircum|Num|8|BEST|11,471|9,431|245|||
|2651|COPYDigit4IsPersev|COPYDigit4IsPersev|Num|8|BEST|11,471|3|245|||
|2652|COPYDigit5Seq|COPYDigit5Seq|Num|8|BEST|11,471|14|260|||
|2653|COPYDigit5Strokes|COPYDigit5Strokes|Num|8|BEST|11,471|6|260|||
|2654|COPYDigit5Time|COPYDigit5Time|Num|8|BEST|11,471|1,561|260|||
|2655|COPYDigit5Len|COPYDigit5Len|Num|8|BEST|11,471|11,211|260|||
|2656|COPYDigit5CentX|COPYDigit5CentX|Num|8|BEST|11,471|1,966|260|||
|2657|COPYDigit5CentY|COPYDigit5CentY|Num|8|BEST|11,471|3,317|260|||
|2658|COPYDigit5Width|COPYDigit5Width|Num|8|BEST|11,471|299|260|||
|2659|COPYDigit5Hgt|COPYDigit5Hgt|Num|8|BEST|11,471|317|260|||
|2660|COPYDigit5NormHt|COPYDigit5NormHt|Num|8|BEST|11,471|10,188|293|||
|2661|COPYDigit5Outside|COPYDigit5Outside|Num|8|BEST|11,471|4|260|||
|2662|COPYDigit5Angle|COPYDigit5Angle|Num|8|BEST|11,471|11,179|260|||
|2663|COPYDigit5IdealDiff|COPYDigit5IdealDiff|Num|8|BEST|11,471|11,179|260|||
|2664|COPYDigit5DistCircum|COPYDigit5DistCircum|Num|8|BEST|11,471|9,276|260|||
|2665|COPYDigit5IsPersev|COPYDigit5IsPersev|Num|8|BEST|11,471|3|260|||
|2666|COPYDigit6Seq|COPYDigit6Seq|Num|8|BEST|11,471|14|224|||
|2667|COPYDigit6Strokes|COPYDigit6Strokes|Num|8|BEST|11,471|5|224|||
|2668|COPYDigit6Time|COPYDigit6Time|Num|8|BEST|11,471|279|224|||
|2669|COPYDigit6Len|COPYDigit6Len|Num|8|BEST|11,471|11,247|224|||
|2670|COPYDigit6CentX|COPYDigit6CentX|Num|8|BEST|11,471|1,784|224|||
|2671|COPYDigit6CentY|COPYDigit6CentY|Num|8|BEST|11,471|3,407|224|||
|2672|COPYDigit6Width|COPYDigit6Width|Num|8|BEST|11,471|210|224|||
|2673|COPYDigit6Hgt|COPYDigit6Hgt|Num|8|BEST|11,471|320|224|||
|2674|COPYDigit6NormHt|COPYDigit6NormHt|Num|8|BEST|11,471|10,292|258|||
|2675|COPYDigit6Outside|COPYDigit6Outside|Num|8|BEST|11,471|4|224|||
|2676|COPYDigit6Angle|COPYDigit6Angle|Num|8|BEST|11,471|11,214|224|||
|2677|COPYDigit6IdealDiff|COPYDigit6IdealDiff|Num|8|BEST|11,471|11,214|224|||
|2678|COPYDigit6DistCircum|COPYDigit6DistCircum|Num|8|BEST|11,471|8,835|224|||
|2679|COPYDigit6IsPersev|COPYDigit6IsPersev|Num|8|BEST|11,471|3|224|||
|2680|COPYDigit7Seq|COPYDigit7Seq|Num|8|BEST|11,471|15|249|||
|2681|COPYDigit7Strokes|COPYDigit7Strokes|Num|8|BEST|11,471|7|249|||
|2682|COPYDigit7Time|COPYDigit7Time|Num|8|BEST|11,471|563|249|||
|2683|COPYDigit7Len|COPYDigit7Len|Num|8|BEST|11,471|11,222|249|||
|2684|COPYDigit7CentX|COPYDigit7CentX|Num|8|BEST|11,471|1,834|249|||
|2685|COPYDigit7CentY|COPYDigit7CentY|Num|8|BEST|11,471|3,342|249|||
|2686|COPYDigit7Width|COPYDigit7Width|Num|8|BEST|11,471|231|249|||
|2687|COPYDigit7Hgt|COPYDigit7Hgt|Num|8|BEST|11,471|305|249|||
|2688|COPYDigit7NormHt|COPYDigit7NormHt|Num|8|BEST|11,471|10,146|282|||
|2689|COPYDigit7Outside|COPYDigit7Outside|Num|8|BEST|11,471|4|249|||
|2690|COPYDigit7Angle|COPYDigit7Angle|Num|8|BEST|11,471|11,190|249|||
|2691|COPYDigit7IdealDiff|COPYDigit7IdealDiff|Num|8|BEST|11,471|11,190|249|||
|2692|COPYDigit7DistCircum|COPYDigit7DistCircum|Num|8|BEST|11,471|9,342|249|||
|2693|COPYDigit7IsPersev|COPYDigit7IsPersev|Num|8|BEST|11,471|3|249|||
|2694|COPYDigit8Seq|COPYDigit8Seq|Num|8|BEST|11,471|14|264|||
|2695|COPYDigit8Strokes|COPYDigit8Strokes|Num|8|BEST|11,471|7|264|||
|2696|COPYDigit8Time|COPYDigit8Time|Num|8|BEST|11,471|855|264|||
|2697|COPYDigit8Len|COPYDigit8Len|Num|8|BEST|11,471|11,207|264|||
|2698|COPYDigit8CentX|COPYDigit8CentX|Num|8|BEST|11,471|1,850|264|||
|2699|COPYDigit8CentY|COPYDigit8CentY|Num|8|BEST|11,471|3,194|264|||
|2700|COPYDigit8Width|COPYDigit8Width|Num|8|BEST|11,471|233|264|||
|2701|COPYDigit8Hgt|COPYDigit8Hgt|Num|8|BEST|11,471|296|264|||
|2702|COPYDigit8NormHt|COPYDigit8NormHt|Num|8|BEST|11,471|10,167|296|||
|2703|COPYDigit8Outside|COPYDigit8Outside|Num|8|BEST|11,471|4|264|||
|2704|COPYDigit8Angle|COPYDigit8Angle|Num|8|BEST|11,471|11,176|264|||
|2705|COPYDigit8IdealDiff|COPYDigit8IdealDiff|Num|8|BEST|11,471|11,176|264|||
|2706|COPYDigit8DistCircum|COPYDigit8DistCircum|Num|8|BEST|11,471|9,449|264|||
|2707|COPYDigit8IsPersev|COPYDigit8IsPersev|Num|8|BEST|11,471|3|264|||
|2708|COPYDigit9Seq|COPYDigit9Seq|Num|8|BEST|11,471|15|240|||
|2709|COPYDigit9Strokes|COPYDigit9Strokes|Num|8|BEST|11,471|6|240|||
|2710|COPYDigit9Time|COPYDigit9Time|Num|8|BEST|11,471|396|240|||
|2711|COPYDigit9Len|COPYDigit9Len|Num|8|BEST|11,471|11,231|240|||
|2712|COPYDigit9CentX|COPYDigit9CentX|Num|8|BEST|11,471|1,884|240|||
|2713|COPYDigit9CentY|COPYDigit9CentY|Num|8|BEST|11,471|2,983|240|||
|2714|COPYDigit9Width|COPYDigit9Width|Num|8|BEST|11,471|224|240|||
|2715|COPYDigit9Hgt|COPYDigit9Hgt|Num|8|BEST|11,471|330|240|||
|2716|COPYDigit9NormHt|COPYDigit9NormHt|Num|8|BEST|11,471|10,238|272|||
|2717|COPYDigit9Outside|COPYDigit9Outside|Num|8|BEST|11,471|4|240|||
|2718|COPYDigit9Angle|COPYDigit9Angle|Num|8|BEST|11,471|11,200|240|||
|2719|COPYDigit9IdealDiff|COPYDigit9IdealDiff|Num|8|BEST|11,471|11,200|240|||
|2720|COPYDigit9DistCircum|COPYDigit9DistCircum|Num|8|BEST|11,471|8,576|240|||
|2721|COPYDigit9IsPersev|COPYDigit9IsPersev|Num|8|BEST|11,471|3|240|||
|2722|COPYDigit10Seq|COPYDigit10Seq|Num|8|BEST|11,471|16|289|||
|2723|COPYDigit10Strokes|COPYDigit10Strokes|Num|8|BEST|11,471|8|289|||
|2724|COPYDigit10Time|COPYDigit10Time|Num|8|BEST|11,471|1,713|289|||
|2725|COPYDigit10Len|COPYDigit10Len|Num|8|BEST|11,471|11,182|289|||
|2726|COPYDigit10CentX|COPYDigit10CentX|Num|8|BEST|11,471|1,792|289|||
|2727|COPYDigit10CentY|COPYDigit10CentY|Num|8|BEST|11,471|2,789|289|||
|2728|COPYDigit10Width|COPYDigit10Width|Num|8|BEST|11,471|253|289|||
|2729|COPYDigit10Hgt|COPYDigit10Hgt|Num|8|BEST|11,471|293|289|||
|2730|COPYDigit10NormHt|COPYDigit10NormHt|Num|8|BEST|11,471|10,114|320|||
|2731|COPYDigit10Outside|COPYDigit10Outside|Num|8|BEST|11,471|4|289|||
|2732|COPYDigit10Angle|COPYDigit10Angle|Num|8|BEST|11,471|11,152|289|||
|2733|COPYDigit10IdealDiff|COPYDigit10IdealDiff|Num|8|BEST|11,471|11,152|289|||
|2734|COPYDigit10DistCircum|COPYDigit10DistCircum|Num|8|BEST|11,471|8,796|289|||
|2735|COPYDigit10IsPersev|COPYDigit10IsPersev|Num|8|BEST|11,471|3|289|||
|2736|COPYDigit11Seq|COPYDigit11Seq|Num|8|BEST|11,471|17|272|||
|2737|COPYDigit11Strokes|COPYDigit11Strokes|Num|8|BEST|11,471|8|272|||
|2738|COPYDigit11Time|COPYDigit11Time|Num|8|BEST|11,471|1,687|272|||
|2739|COPYDigit11Len|COPYDigit11Len|Num|8|BEST|11,471|11,199|272|||
|2740|COPYDigit11CentX|COPYDigit11CentX|Num|8|BEST|11,471|1,668|272|||
|2741|COPYDigit11CentY|COPYDigit11CentY|Num|8|BEST|11,471|2,688|272|||
|2742|COPYDigit11Width|COPYDigit11Width|Num|8|BEST|11,471|243|272|||
|2743|COPYDigit11Hgt|COPYDigit11Hgt|Num|8|BEST|11,471|300|272|||
|2744|COPYDigit11NormHt|COPYDigit11NormHt|Num|8|BEST|11,471|10,141|306|||
|2745|COPYDigit11Outside|COPYDigit11Outside|Num|8|BEST|11,471|4|272|||
|2746|COPYDigit11Angle|COPYDigit11Angle|Num|8|BEST|11,471|11,166|272|||
|2747|COPYDigit11IdealDiff|COPYDigit11IdealDiff|Num|8|BEST|11,471|11,166|272|||
|2748|COPYDigit11DistCircum|COPYDigit11DistCircum|Num|8|BEST|11,471|8,776|272|||
|2749|COPYDigit11IsPersev|COPYDigit11IsPersev|Num|8|BEST|11,471|3|272|||
|2750|COPYDigit12Seq|COPYDigit12Seq|Num|8|BEST|11,471|15|249|||
|2751|COPYDigit12Strokes|COPYDigit12Strokes|Num|8|BEST|11,471|8|249|||
|2752|COPYDigit12Time|COPYDigit12Time|Num|8|BEST|11,471|2,007|249|||
|2753|COPYDigit12Len|COPYDigit12Len|Num|8|BEST|11,471|11,222|249|||
|2754|COPYDigit12CentX|COPYDigit12CentX|Num|8|BEST|11,471|1,525|249|||
|2755|COPYDigit12CentY|COPYDigit12CentY|Num|8|BEST|11,471|2,646|249|||
|2756|COPYDigit12Width|COPYDigit12Width|Num|8|BEST|11,471|330|249|||
|2757|COPYDigit12Hgt|COPYDigit12Hgt|Num|8|BEST|11,471|269|249|||
|2758|COPYDigit12NormHt|COPYDigit12NormHt|Num|8|BEST|11,471|10,090|284|||
|2759|COPYDigit12Outside|COPYDigit12Outside|Num|8|BEST|11,471|4|249|||
|2760|COPYDigit12Angle|COPYDigit12Angle|Num|8|BEST|11,471|11,188|249|||
|2761|COPYDigit12IdealDiff|COPYDigit12IdealDiff|Num|8|BEST|11,471|11,188|249|||
|2762|COPYDigit12DistCircum|COPYDigit12DistCircum|Num|8|BEST|11,471|9,015|249|||
|2763|COPYDigit12IsPersev|COPYDigit12IsPersev|Num|8|BEST|11,471|3|249|||
|2764|COPYHooklet1DigitCode|COPYHooklet1DigitCode|Num|8|BEST|11,471|17|885|||
|2765|COPYHooklet1Type|COPYHooklet1Type|Num|8|BEST|11,471|4|885|||
|2766|COPYHooklet1Length|COPYHooklet1Length|Num|8|BEST|11,471|3,587|885|||
|2767|COPYHooklet1AvgSpeed|COPYHooklet1AvgSpeed|Num|8|BEST|11,471|4,499|885|||
|2768|COPYHooklet1LengthPct|COPYHooklet1LengthPct|Num|8|BEST|11,471|10,586|885|||
|2769|COPYHooklet1DistToNextStroke|COPYHooklet1DistToNextStroke|Num|8|BEST|11,471|7,265|885|||
|2770|COPYHooklet1Slope|COPYHooklet1Slope|Num|8|BEST|11,471|3,633|885|||
|2771|COPYHooklet1PtsTo|COPYHooklet1PtsTo|Num|8|BEST|11,471|24|885|||
|2772|COPYHooklet2DigitCode|COPYHooklet2DigitCode|Num|8|BEST|11,471|17|2,035|||
|2773|COPYHooklet2Type|COPYHooklet2Type|Num|8|BEST|11,471|4|2,035|||
|2774|COPYHooklet2Length|COPYHooklet2Length|Num|8|BEST|11,471|3,154|2,035|||
|2775|COPYHooklet2AvgSpeed|COPYHooklet2AvgSpeed|Num|8|BEST|11,471|3,944|2,035|||
|2776|COPYHooklet2LengthPct|COPYHooklet2LengthPct|Num|8|BEST|11,471|9,436|2,035|||
|2777|COPYHooklet2DistToNextStroke|COPYHooklet2DistToNextStroke|Num|8|BEST|11,471|6,412|2,035|||
|2778|COPYHooklet2Slope|COPYHooklet2Slope|Num|8|BEST|11,471|3,435|2,035|||
|2779|COPYHooklet2PtsTo|COPYHooklet2PtsTo|Num|8|BEST|11,470|25|2,035|||
|2780|COPYHooklet3DigitCode|COPYHooklet3DigitCode|Num|8|BEST|11,471|17|3,487|||
|2781|COPYHooklet3Type|COPYHooklet3Type|Num|8|BEST|11,471|4|3,487|||
|2782|COPYHooklet3Length|COPYHooklet3Length|Num|8|BEST|11,471|2,883|3,487|||
|2783|COPYHooklet3AvgSpeed|COPYHooklet3AvgSpeed|Num|8|BEST|11,471|3,588|3,487|||
|2784|COPYHooklet3LengthPct|COPYHooklet3LengthPct|Num|8|BEST|11,471|7,984|3,487|||
|2785|COPYHooklet3DistToNextStroke|COPYHooklet3DistToNextStroke|Num|8|BEST|11,471|5,675|3,487|||
|2786|COPYHooklet3Slope|COPYHooklet3Slope|Num|8|BEST|11,471|3,043|3,487|||
|2787|COPYHooklet3PtsTo|COPYHooklet3PtsTo|Num|8|BEST|11,471|22|3,487|||
|2788|COPYHooklet4DigitCode|COPYHooklet4DigitCode|Num|8|BEST|11,471|17|5,409|||
|2789|COPYHooklet4Type|COPYHooklet4Type|Num|8|BEST|11,471|4|5,409|||
|2790|COPYHooklet4Length|COPYHooklet4Length|Num|8|BEST|11,471|2,471|5,409|||
|2791|COPYHooklet4AvgSpeed|COPYHooklet4AvgSpeed|Num|8|BEST|11,471|3,044|5,409|||
|2792|COPYHooklet4LengthPct|COPYHooklet4LengthPct|Num|8|BEST|11,471|6,062|5,409|||
|2793|COPYHooklet4DistToNextStroke|COPYHooklet4DistToNextStroke|Num|8|BEST|11,471|4,660|5,409|||
|2794|COPYHooklet4Slope|COPYHooklet4Slope|Num|8|BEST|11,471|2,512|5,409|||
|2795|COPYHooklet4PtsTo|COPYHooklet4PtsTo|Num|8|BEST|11,471|23|5,409|||
|2796|COPYHooklet5DigitCode|COPYHooklet5DigitCode|Num|8|BEST|11,471|17|7,429|||
|2797|COPYHooklet5Type|COPYHooklet5Type|Num|8|BEST|11,471|4|7,429|||
|2798|COPYHooklet5Length|COPYHooklet5Length|Num|8|BEST|11,471|1,812|7,429|||
|2799|COPYHooklet5AvgSpeed|COPYHooklet5AvgSpeed|Num|8|BEST|11,471|2,238|7,429|||
|2800|COPYHooklet5LengthPct|COPYHooklet5LengthPct|Num|8|BEST|11,471|4,043|7,429|||
|2801|COPYHooklet5DistToNextStroke|COPYHooklet5DistToNextStroke|Num|8|BEST|11,471|3,264|7,429|||
|2802|COPYHooklet5Slope|COPYHooklet5Slope|Num|8|BEST|11,471|1,797|7,429|||
|2803|COPYHooklet5PtsTo|COPYHooklet5PtsTo|Num|8|BEST|11,471|25|7,429|||
|2804|COPYHooklet6DigitCode|COPYHooklet6DigitCode|Num|8|BEST|11,471|16|9,078|||
|2805|COPYHooklet6Type|COPYHooklet6Type|Num|8|BEST|11,471|4|9,078|||
|2806|COPYHooklet6Length|COPYHooklet6Length|Num|8|BEST|11,471|1,195|9,078|||
|2807|COPYHooklet6AvgSpeed|COPYHooklet6AvgSpeed|Num|8|BEST|11,471|1,467|9,078|||
|2808|COPYHooklet6LengthPct|COPYHooklet6LengthPct|Num|8|BEST|11,471|2,395|9,078|||
|2809|COPYHooklet6DistToNextStroke|COPYHooklet6DistToNextStroke|Num|8|BEST|11,471|2,038|9,078|||
|2810|COPYHooklet6Slope|COPYHooklet6Slope|Num|8|BEST|11,471|1,170|9,078|||
|2811|COPYHooklet6PtsTo|COPYHooklet6PtsTo|Num|8|BEST|11,471|23|9,078|||
|2812|COPYHooklet7DigitCode|COPYHooklet7DigitCode|Num|8|BEST|11,471|17|10,220|||
|2813|COPYHooklet7Type|COPYHooklet7Type|Num|8|BEST|11,471|4|10,220|||
|2814|COPYHooklet7Length|COPYHooklet7Length|Num|8|BEST|11,471|759|10,220|||
|2815|COPYHooklet7AvgSpeed|COPYHooklet7AvgSpeed|Num|8|BEST|11,471|908|10,220|||
|2816|COPYHooklet7LengthPct|COPYHooklet7LengthPct|Num|8|BEST|11,471|1,253|10,220|||
|2817|COPYHooklet7DistToNextStroke|COPYHooklet7DistToNextStroke|Num|8|BEST|11,471|1,159|10,220|||
|2818|COPYHooklet7Slope|COPYHooklet7Slope|Num|8|BEST|11,471|734|10,220|||
|2819|COPYHooklet7PtsTo|COPYHooklet7PtsTo|Num|8|BEST|11,471|21|10,220|||
|2820|COPYHooklet8DigitCode|COPYHooklet8DigitCode|Num|8|BEST|11,471|17|10,896|||
|2821|COPYHooklet8Type|COPYHooklet8Type|Num|8|BEST|11,471|4|10,896|||
|2822|COPYHooklet8Length|COPYHooklet8Length|Num|8|BEST|11,471|357|10,896|||
|2823|COPYHooklet8AvgSpeed|COPYHooklet8AvgSpeed|Num|8|BEST|11,471|427|10,896|||
|2824|COPYHooklet8LengthPct|COPYHooklet8LengthPct|Num|8|BEST|11,471|577|10,896|||
|2825|COPYHooklet8DistToNextStroke|COPYHooklet8DistToNextStroke|Num|8|BEST|11,471|536|10,896|||
|2826|COPYHooklet8Slope|COPYHooklet8Slope|Num|8|BEST|11,471|343|10,896|||
|2827|COPYHooklet8PtsTo|COPYHooklet8PtsTo|Num|8|BEST|11,471|20|10,896|||
|2828|COPYHooklet9DigitCode|COPYHooklet9DigitCode|Num|8|BEST|11,471|14|11,250|||
|2829|COPYHooklet9Type|COPYHooklet9Type|Num|8|BEST|11,471|4|11,250|||
|2830|COPYHooklet9Length|COPYHooklet9Length|Num|8|BEST|11,471|144|11,250|||
|2831|COPYHooklet9AvgSpeed|COPYHooklet9AvgSpeed|Num|8|BEST|11,471|177|11,250|||
|2832|COPYHooklet9LengthPct|COPYHooklet9LengthPct|Num|8|BEST|11,471|223|11,250|||
|2833|COPYHooklet9DistToNextStroke|COPYHooklet9DistToNextStroke|Num|8|BEST|11,471|219|11,250|||
|2834|COPYHooklet9Slope|COPYHooklet9Slope|Num|8|BEST|11,471|143|11,250|||
|2835|COPYHooklet9PtsTo|COPYHooklet9PtsTo|Num|8|BEST|11,471|21|11,250|||
|2836|COPYHooklet10DigitCode|COPYHooklet10DigitCode|Num|8|BEST|11,471|14|11,392|||
|2837|COPYHooklet10Type|COPYHooklet10Type|Num|8|BEST|11,471|4|11,392|||
|2838|COPYHooklet10Length|COPYHooklet10Length|Num|8|BEST|11,471|63|11,392|||
|2839|COPYHooklet10AvgSpeed|COPYHooklet10AvgSpeed|Num|8|BEST|11,471|73|11,392|||
|2840|COPYHooklet10LengthPct|COPYHooklet10LengthPct|Num|8|BEST|11,471|81|11,392|||
|2841|COPYHooklet10DistToNextStroke|COPYHooklet10DistToNextStroke|Num|8|BEST|11,471|81|11,392|||
|2842|COPYHooklet10Slope|COPYHooklet10Slope|Num|8|BEST|11,471|67|11,392|||
|2843|COPYHooklet10PtsTo|COPYHooklet10PtsTo|Num|8|BEST|11,471|13|11,392|||
|2844|COPYHooklet11DigitCode|COPYHooklet11DigitCode|Num|8|BEST|11,471|12|11,440|||
|2845|COPYHooklet11Type|COPYHooklet11Type|Num|8|BEST|11,471|4|11,440|||
|2846|COPYHooklet11Length|COPYHooklet11Length|Num|8|BEST|11,471|29|11,440|||
|2847|COPYHooklet11AvgSpeed|COPYHooklet11AvgSpeed|Num|8|BEST|11,471|31|11,440|||
|2848|COPYHooklet11LengthPct|COPYHooklet11LengthPct|Num|8|BEST|11,471|33|11,440|||
|2849|COPYHooklet11DistToNextStroke|COPYHooklet11DistToNextStroke|Num|8|BEST|11,471|33|11,440|||
|2850|COPYHooklet11Slope|COPYHooklet11Slope|Num|8|BEST|11,471|30|11,440|||
|2851|COPYHooklet11PtsTo|COPYHooklet11PtsTo|Num|8|BEST|11,471|13|11,440|||
|2852|COPYHooklet12DigitCode|COPYHooklet12DigitCode|Num|8|BEST|11,471|9|11,463|||
|2853|COPYHooklet12Type|COPYHooklet12Type|Num|8|BEST|11,471|3|11,463|||
|2854|COPYHooklet12Length|COPYHooklet12Length|Num|8|BEST|11,471|10|11,463|||
|2855|COPYHooklet12AvgSpeed|COPYHooklet12AvgSpeed|Num|8|BEST|11,471|10|11,463|||
|2856|COPYHooklet12LengthPct|COPYHooklet12LengthPct|Num|8|BEST|11,471|10|11,463|||
|2857|COPYHooklet12DistToNextStroke|COPYHooklet12DistToNextStroke|Num|8|BEST|11,471|10|11,463|||
|2858|COPYHooklet12Slope|COPYHooklet12Slope|Num|8|BEST|11,471|10|11,463|||
|2859|COPYHooklet12PtsTo|COPYHooklet12PtsTo|Num|8|BEST|11,471|10|11,463|||
|2860|COPYHooklet13DigitCode|COPYHooklet13DigitCode|Num|8|BEST|11,471|4|11,468|||
|2861|COPYHooklet13Type|COPYHooklet13Type|Num|8|BEST|11,471|4|11,468|||
|2862|COPYHooklet13Length|COPYHooklet13Length|Num|8|BEST|11,471|5|11,468|||
|2863|COPYHooklet13AvgSpeed|COPYHooklet13AvgSpeed|Num|8|BEST|11,471|5|11,468|||
|2864|COPYHooklet13LengthPct|COPYHooklet13LengthPct|Num|8|BEST|11,471|5|11,468|||
|2865|COPYHooklet13DistToNextStroke|COPYHooklet13DistToNextStroke|Num|8|BEST|11,471|5|11,468|||
|2866|COPYHooklet13Slope|COPYHooklet13Slope|Num|8|BEST|11,471|5|11,468|||
|2867|COPYHooklet13PtsTo|COPYHooklet13PtsTo|Num|8|BEST|11,471|4|11,468|||
|2868|COPYHooklet14DigitCode|COPYHooklet14DigitCode|Num|8|BEST|11,471|4|11,469|||
|2869|COPYHooklet14Type|COPYHooklet14Type|Num|8|BEST|11,471|3|11,469|||
|2870|COPYHooklet14Length|COPYHooklet14Length|Num|8|BEST|11,471|4|11,469|||
|2871|COPYHooklet14AvgSpeed|COPYHooklet14AvgSpeed|Num|8|BEST|11,471|4|11,469|||
|2872|COPYHooklet14LengthPct|COPYHooklet14LengthPct|Num|8|BEST|11,471|4|11,469|||
|2873|COPYHooklet14DistToNextStroke|COPYHooklet14DistToNextStroke|Num|8|BEST|11,471|4|11,469|||
|2874|COPYHooklet14Slope|COPYHooklet14Slope|Num|8|BEST|11,471|4|11,469|||
|2875|COPYHooklet14PtsTo|COPYHooklet14PtsTo|Num|8|BEST|11,471|4|11,469|||
|2876|COPYHooklet15DigitCode|COPYHooklet15DigitCode|Num|8|BEST|11,471|4|11,469|||
|2877|COPYHooklet15Type|COPYHooklet15Type|Num|8|BEST|11,471|3|11,469|||
|2878|COPYHooklet15Length|COPYHooklet15Length|Num|8|BEST|11,471|4|11,469|||
|2879|COPYHooklet15AvgSpeed|COPYHooklet15AvgSpeed|Num|8|BEST|11,471|4|11,469|||
|2880|COPYHooklet15LengthPct|COPYHooklet15LengthPct|Num|8|BEST|11,471|4|11,469|||
|2881|COPYHooklet15DistToNextStroke|COPYHooklet15DistToNextStroke|Num|8|BEST|11,471|4|11,469|||
|2882|COPYHooklet15Slope|COPYHooklet15Slope|Num|8|BEST|11,471|4|11,469|||
|2883|COPYHooklet15PtsTo|COPYHooklet15PtsTo|Num|8|BEST|11,471|4|11,469|||
|2884|COPYCenterDotStrokeNum|COPYCenterDotStrokeNum|Num|8|BEST|11,471|7|0|||
|2885|COPYCenterDotStrokeLen|COPYCenterDotStrokeLen|Num|8|BEST|11,471|5,301|0|||
|2886|COPYTickMarkNum|COPYTickMarkNum|Num|8|BEST|11,471|17|0|||
|2887|COPYTickMarkStrokeLen|COPYTickMarkStrokeLen|Num|8|BEST|11,471|76|0|||
|2888|COPYTextStrokeNum|COPYTextStrokeNum|Num|8|BEST|11,471|31|0|||
|2889|COPYTextStrokeLen|COPYTextStrokeLen|Num|8|BEST|11,471|196|0|||
|2890|COPYSpokesStrokeNum|COPYSpokesStrokeNum|Num|8|BEST|11,471|10|0|||
|2891|COPYSpokesStrokeLen|COPYSpokesStrokeLen|Num|8|BEST|11,471|13|0|||
|2892|COPYOver12StrokeNum|COPYOver12StrokeNum|Num|8|BEST|11,471|6|0|||
|2893|COPYOver12StrokeLen|COPYOver12StrokeLen|Num|8|BEST|11,471|12|0|||
|2894|COPYTenElevenStroke|COPYTenElevenStroke|Num|8|BEST|11,471|3|0|||
|2895|COPYClockFaceNonClockFaceLatency|COPYClockFaceNonClockFaceLatency|Num|8|BEST|11,471|3,503|186|||
|2896|COPYCFNonCFTerminator|COPYCFNonCFTerminator|Num|8|BEST|11,471|23|186|||
|2897|COPYClockFaceNonClockFaceNoNoise|COPYClockFaceNonClockFaceNoNoiseLatency|Num|8|BEST|11,471|3,533|186|||
|2898|COPYCFNonCFNoNoiseTerminator|COPYCFNonCFNoNoiseTerminator|Num|8|BEST|11,471|24|186|||
|2899|COPYPreFirstHandLatency|COPYPreFirstHandLatency|Num|8|BEST|11,471|3,799|329|||
|2900|COPYPreFirstHandInitiator|COPYPreFirstHandInitiator|Char|9|$|11,471|26|329|||
|2901|COPYPreFirstHandNoNoiseLatency|COPYPreFirstHandNoNoiseLatency|Num|8|BEST|11,471|4,000|330|||
|2902|COPYPreFirstHandNoNoiseInitiator|COPYPreFirstHandNoNoiseInitiator|Char|9|$|11,471|26|330|||
|2903|COPYPreSecondHandLatency|COPYPreSecondHandLatency|Num|8|BEST|11,471|2,588|335|||
|2904|COPYPreSecondHandInitiator|COPYPreSecondHandInitiator|Char|9|$|11,471|23|335|||
|2905|COPYPreSecondHandNoNoiseLatency|COPYPreSecondHandNoNoiseLatency|Num|8|BEST|11,471|2,718|335|||
|2906|COPYPreSecondHandNoNoiseInitiato|COPYPreSecondHandNoNoiseInitiator|Char|9|$|11,471|23|335|||
|2907|COPYPreCenterDotLatency|COPYPreCenterDotLatency|Num|8|BEST|11,471|2,584|6,088|||
|2908|COPYPreCenterDotInitiator|COPYPreCenterDotInitiator|Char|9|$|11,471|25|6,088|||
|2909|COPYPreCenterDotNoNoiseLatency|COPYPreCenterDotNoNoiseLatency|Num|8|BEST|11,471|2,690|6,090|||
|2910|COPYPreCenterDotNoNoiseInitiator|COPYPreCenterDotNoNoiseInitiator|Char|9|$|11,471|24|6,090|||
|2911|COPYPostCenterDotLatency|COPYPostCenterDotLatency|Num|8|BEST|11,471|1,914|6,846|||
|2912|COPYPostCenterDotTerminator|COPYPostCenterDotTerminator|Char|9|$|11,471|25|6,846|||
|2913|COPYPostCenterDotNoNoiseLatency|COPYPostCenterDotNoNoiseLatency|Num|8|BEST|11,471|1,967|6,858|||
|2914|COPYPostCenterDotNoNoiseTerminat|COPYPostCenterDotNoNoiseTerminator|Char|9|$|11,471|24|6,858|||
|2915|COPYInterDigitLatency|COPYInterDigitLatency|Num|8|BEST|11,471|8,988|0|||
|2916|COPYInterDigitIntervalCount|COPYInterDigitIntervalCount|Num|8|BEST|11,471|16|0|||
|2917|COPYAnchorDigitLatency|COPYAnchorDigitLatency|Num|8|BEST|11,471|1,947|8,855|||
|2918|COPYAnchorLatencyIntervalCount|COPYAnchorLatencyIntervalCount|Num|8|BEST|11,471|6|0|||
|2919|COPYTenElevenStrokeLatency|COPYTenElevenStrokeLatency|Num|8|BEST|11,471|71|11,401|||
|2920|COPYHandsXdOutNumStrokes|COPYHandsXdOutNumStrokes|Num|8|BEST|11,471|14|0|||
|2921|COPYHandsXdOutTotStrokeLen|COPYHandsXdOutTotStrokeLen|Num|8|BEST|11,471|520|0|||
|2922|COPYDigitsXOutNumStrokes|COPYDigitsXOutNumStrokes|Num|8|BEST|11,471|32|0|||
|2923|COPYDigitsXdOutTotStrokeLen|COPYDigitsXdOutTotStrokeLen|Num|8|BEST|11,471|893|0|||
|2924|COPYPersevDigitsXdOutNumStrokes|COPYPersevDigitsXdOutNumStrokes|Num|8|BEST|11,471|5|0|||
|2925|COPYPersevDigitsXdOutTotStrokeLe|COPYPersevDigitsXdOutTotStrokeLen|Num|8|BEST|11,471|26|0|||
|2926|COPYPersevDigitsCountQ1|COPYPersevDigitsCountQ1|Num|8|BEST|11,471|4|0|||
|2927|COPYPersevDigitsCountQ2|COPYPersevDigitsCountQ2|Num|8|BEST|11,471|4|0|||
|2928|COPYPersevDigitsCountQ3|COPYPersevDigitsCountQ3|Num|8|BEST|11,471|5|0|||
|2929|COPYPersevDigitsCountQ4|COPYPersevDigitsCountQ4|Num|8|BEST|11,471|3|0|||
|2930|COPYHandSplitCount|COPYHandSplitCount|Num|8|BEST|11,471|5|0|||
|2931|COPYDigitSplitCount|COPYDigitSplitCount|Num|8|BEST|11,471|4|0|||
|2932|COPYClockBFCircleRadius|COPYClockBFCircleRadius|Num|8|BEST|11,471|11,324|147|||
|2933|COPYClockBFCircCentX|COPYClockBFCircCentX|Num|8|BEST|11,471|11,324|147|||
|2934|COPYClockBFCircCentY|COPYClockBFCircCentY|Num|8|BEST|11,471|11,324|147|||
|2935|COPYCFBFCircInBounds|COPYCFBFCircInBounds|Num|8|BEST|11,471|4|147|||
|2936|COPYPCF1CircleRadius|COPYPCF1CircleRadius|Num|8|BEST|11,471|12|11,461|||
|2937|COPYPCF1CFRadiusDiff|COPYPCF1CFRadiusDiff|Num|8|BEST|11,471|12|11,461|||
|2938|COPYPCF1CircCentX|COPYPCF1CircCentX|Num|8|BEST|11,471|12|11,461|||
|2939|COPYPCF1CircCentY|COPYPCF1CircCentY|Num|8|BEST|11,471|12|11,461|||
|2940|COPYPCF1LocnDiffX|COPYPCF1LocnDiffX|Num|8|BEST|11,471|12|11,461|||
|2941|COPYPCF1LocnDiffY|COPYPCF1LocnDiffY|Num|8|BEST|11,471|12|11,461|||
|2942|COPYPCF1PageQuad|COPYPCF1PageQuad|Num|8|BEST|11,471|4|11,461|||
|2943|COPYPCF1CircQuad|COPYPCF1CircQuad|Num|8|BEST|11,471|4|11,461|||
|2944|COPYPCF1InBounds|COPYPCF1InBounds|Num|8|BEST|11,471|4|11,461|||
|2945|COPYPCF2CircleRadius|COPYPCF2CircleRadius|Num|8|BEST|11,471|3|11,470|||
|2946|COPYPCF2CFRadiusDiff|COPYPCF2CFRadiusDiff|Num|8|BEST|11,471|3|11,470|||
|2947|COPYPCF2CircCentX|COPYPCF2CircCentX|Num|8|BEST|11,471|3|11,470|||
|2948|COPYPCF2CircCentY|COPYPCF2CircCentY|Num|8|BEST|11,471|3|11,470|||
|2949|COPYPCF2LocnDiffX|COPYPCF2LocnDiffX|Num|8|BEST|11,471|3|11,470|||
|2950|COPYPCF2LocnDiffY|COPYPCF2LocnDiffY|Num|8|BEST|11,471|3|11,470|||
|2951|COPYPCF2PageQuad|COPYPCF2PageQuad|Num|8|BEST|11,471|3|11,470|||
|2952|COPYPCF2CircQuad|COPYPCF2CircQuad|Num|8|BEST|11,471|3|11,470|||
|2953|COPYPCF2InBounds|COPYPCF2InBounds|Num|8|BEST|11,471|3|11,470|||
|2954|COPYTotInkTimeCC|COPYTotInkTimeCC|Num|8|BEST|11,471|6,533|0|||
|2955|COPYInkLenTimeCCQ1|COPYInkLenTimeCCQ1|Num|8|BEST|11,471|11,388|0|||
|2956|COPYInkLenTimeCCQ2|COPYInkLenTimeCCQ2|Num|8|BEST|11,471|11,388|0|||
|2957|COPYInkLenTimeCCQ3|COPYInkLenTimeCCQ3|Num|8|BEST|11,471|11,388|0|||
|2958|COPYInkLenTimeCCQ4|COPYInkLenTimeCCQ4|Num|8|BEST|11,471|11,388|0|||
|2959|COPYTotInkTimeNoCC|COPYTotInkTimeNoCC|Num|8|BEST|11,471|5,960|0|||
|2960|COPYInkLenTimeNoCCQ1|COPYInkLenTimeNoCCQ1|Num|8|BEST|11,471|11,386|0|||
|2961|COPYInkLenTimeNoCCQ2|COPYInkLenTimeNoCCQ2|Num|8|BEST|11,471|11,386|0|||
|2962|COPYInkLenTimeNoCCQ3|COPYInkLenTimeNoCCQ3|Num|8|BEST|11,471|11,386|0|||
|2963|COPYInkLenTimeNoCCQ4|COPYInkLenTimeNoCCQ4|Num|8|BEST|11,471|11,386|0|||
|2964|COPYTotInkLengthCC|COPYTotInkLengthCC|Num|8|BEST|11,471|11,388|0|||
|2965|COPYInkTimeByLenCCQ1|COPYInkTimeByLenCCQ1|Num|8|BEST|11,471|907|0|||
|2966|COPYInkTimeByLenCCQ2|COPYInkTimeByLenCCQ2|Num|8|BEST|11,471|2,274|0|||
|2967|COPYInkTimeByLenCCQ3|COPYInkTimeByLenCCQ3|Num|8|BEST|11,471|2,942|0|||
|2968|COPYInkTimeByLenCCQ4|COPYInkTimeByLenCCQ4|Num|8|BEST|11,471|3,611|0|||
|2969|COPYTotInkLengthNoCC|COPYTotInkLengthNoCC|Num|8|BEST|11,471|11,386|0|||
|2970|COPYInkTimeByLenNoCCQ1|COPYInkTimeByLenNoCCQ1|Num|8|BEST|11,471|2,000|0|||
|2971|COPYInkTimeByLenNoCCQ2|COPYInkTimeByLenNoCCQ2|Num|8|BEST|11,471|1,909|0|||
|2972|COPYInkTimeByLenNoCCQ3|COPYInkTimeByLenNoCCQ3|Num|8|BEST|11,471|2,043|0|||
|2973|COPYInkTimeByLenNoCCQ4|COPYInkTimeByLenNoCCQ4|Num|8|BEST|11,471|2,510|0|||
|2974|COPYNoiseHistoZero|COPYNoiseHistoZero|Num|8|BEST|11,471|11|0|||
|2975|COPYNoiseHistoPt3|COPYNoiseHistoPt3|Num|8|BEST|11,471|16|0|||
|2976|COPYNoiseHistoPt7|COPYNoiseHistoPt7|Num|8|BEST|11,471|14|0|||
|2977|COPYNoiseHistoAbovePt7|COPYNoiseHistoAbovePt7|Num|8|BEST|11,471|26|0|||
|2978|COPYNoiseHistoZeroQ1|COPYNoiseHistoZeroQ1|Num|8|BEST|11,471|7|0|||
|2979|COPYNoiseHistoPt3Q1|COPYNoiseHistoPt3Q1|Num|8|BEST|11,471|10|0|||
|2980|COPYNoiseHistoPt7Q1|COPYNoiseHistoPt7Q1|Num|8|BEST|11,471|11|0|||
|2981|COPYNoiseHistoAbovePt7Q1|COPYNoiseHistoAbovePt7Q1|Num|8|BEST|11,471|16|0|||
|2982|COPYNoiseHistoZeroQ2|COPYNoiseHistoZeroQ2|Num|8|BEST|11,471|8|0|||
|2983|COPYNoiseHistoPt3Q2|COPYNoiseHistoPt3Q2|Num|8|BEST|11,471|11|0|||
|2984|COPYNoiseHistoPt7Q2|COPYNoiseHistoPt7Q2|Num|8|BEST|11,471|9|0|||
|2985|COPYNoiseHistoAbovePt7Q2|COPYNoiseHistoAbovePt7Q2|Num|8|BEST|11,471|16|0|||
|2986|COPYNoiseHistoZeroQ3|COPYNoiseHistoZeroQ3|Num|8|BEST|11,471|5|0|||
|2987|COPYNoiseHistoPt3Q3|COPYNoiseHistoPt3Q3|Num|8|BEST|11,471|9|0|||
|2988|COPYNoiseHistoPt7Q3|COPYNoiseHistoPt7Q3|Num|8|BEST|11,471|7|0|||
|2989|COPYNoiseHistoAbovePt7Q3|COPYNoiseHistoAbovePt7Q3|Num|8|BEST|11,471|10|0|||
|2990|COPYNoiseHistoZeroQ4|COPYNoiseHistoZeroQ4|Num|8|BEST|11,471|6|0|||
|2991|COPYNoiseHistoPt3Q4|COPYNoiseHistoPt3Q4|Num|8|BEST|11,471|7|0|||
|2992|COPYNoiseHistoPt7Q4|COPYNoiseHistoPt7Q4|Num|8|BEST|11,471|6|0|||
|2993|COPYNoiseHistoAbovePt7Q4|COPYNoiseHistoAbovePt7Q4|Num|8|BEST|11,471|10|0|||
|2994|COPYDigit1PSeq|COPYDigit1PSeq|Num|8|BEST|11,471|13|11,428|||
|2995|COPYDigit1PStrokes|COPYDigit1PStrokes|Num|8|BEST|11,471|3|11,428|||
|2996|COPYDigit1PTime|COPYDigit1PTime|Num|8|BEST|11,471|33|11,428|||
|2997|COPYDigit1PLen|COPYDigit1PLen|Num|8|BEST|11,471|45|11,428|||
|2998|COPYDigit1PCentX|COPYDigit1PCentX|Num|8|BEST|11,471|45|11,428|||
|2999|COPYDigit1PCentY|COPYDigit1PCentY|Num|8|BEST|11,471|45|11,428|||
|3000|COPYDigit1PWidth|COPYDigit1PWidth|Num|8|BEST|11,471|33|11,428|||
|3001|COPYDigit1PHgt|COPYDigit1PHgt|Num|8|BEST|11,471|42|11,428|||
|3002|COPYDigit1PNormHt|COPYDigit1PNormHt|Num|8|BEST|11,471|44|11,429|||
|3003|COPYDigit1POutside|COPYDigit1POutside|Num|8|BEST|11,471|4|11,428|||
|3004|COPYDigit1PAngle|COPYDigit1PAngle|Num|8|BEST|11,471|45|11,428|||
|3005|COPYDigit1PIdealDiff|COPYDigit1PIdealDiff|Num|8|BEST|11,471|45|11,428|||
|3006|COPYDigit1PDistCircum|COPYDigit1PDistCircum|Num|8|BEST|11,471|45|11,428|||
|3007|COPYDigit1PIsPersev|COPYDigit1PIsPersev|Num|8|BEST|11,471|4|11,428|||
|3008|COPYDigit2PSeq|COPYDigit2PSeq|Num|8|BEST|11,471|10|11,454|||
|3009|COPYDigit2PStrokes|COPYDigit2PStrokes|Num|8|BEST|11,471|4|11,454|||
|3010|COPYDigit2PTime|COPYDigit2PTime|Num|8|BEST|11,471|17|11,454|||
|3011|COPYDigit2PLen|COPYDigit2PLen|Num|8|BEST|11,471|19|11,454|||
|3012|COPYDigit2PCentX|COPYDigit2PCentX|Num|8|BEST|11,471|19|11,454|||
|3013|COPYDigit2PCentY|COPYDigit2PCentY|Num|8|BEST|11,471|19|11,454|||
|3014|COPYDigit2PWidth|COPYDigit2PWidth|Num|8|BEST|11,471|18|11,454|||
|3015|COPYDigit2PHgt|COPYDigit2PHgt|Num|8|BEST|11,471|19|11,454|||
|3016|COPYDigit2PNormHt|COPYDigit2PNormHt|Num|8|BEST|11,471|19|11,454|||
|3017|COPYDigit2POutside|COPYDigit2POutside|Num|8|BEST|11,471|4|11,454|||
|3018|COPYDigit2PAngle|COPYDigit2PAngle|Num|8|BEST|11,471|19|11,454|||
|3019|COPYDigit2PIdealDiff|COPYDigit2PIdealDiff|Num|8|BEST|11,471|19|11,454|||
|3020|COPYDigit2PDistCircum|COPYDigit2PDistCircum|Num|8|BEST|11,471|19|11,454|||
|3021|COPYDigit2PIsPersev|COPYDigit2PIsPersev|Num|8|BEST|11,471|4|11,454|||
|3022|COPYDigit3PSeq|COPYDigit3PSeq|Num|8|BEST|11,471|10|11,448|||
|3023|COPYDigit3PStrokes|COPYDigit3PStrokes|Num|8|BEST|11,471|4|11,448|||
|3024|COPYDigit3PTime|COPYDigit3PTime|Num|8|BEST|11,471|20|11,448|||
|3025|COPYDigit3PLen|COPYDigit3PLen|Num|8|BEST|11,471|25|11,448|||
|3026|COPYDigit3PCentX|COPYDigit3PCentX|Num|8|BEST|11,471|25|11,448|||
|3027|COPYDigit3PCentY|COPYDigit3PCentY|Num|8|BEST|11,471|25|11,448|||
|3028|COPYDigit3PWidth|COPYDigit3PWidth|Num|8|BEST|11,471|23|11,448|||
|3029|COPYDigit3PHgt|COPYDigit3PHgt|Num|8|BEST|11,471|23|11,448|||
|3030|COPYDigit3PNormHt|COPYDigit3PNormHt|Num|8|BEST|11,471|24|11,449|||
|3031|COPYDigit3POutside|COPYDigit3POutside|Num|8|BEST|11,471|4|11,448|||
|3032|COPYDigit3PAngle|COPYDigit3PAngle|Num|8|BEST|11,471|25|11,448|||
|3033|COPYDigit3PIdealDiff|COPYDigit3PIdealDiff|Num|8|BEST|11,471|25|11,448|||
|3034|COPYDigit3PDistCircum|COPYDigit3PDistCircum|Num|8|BEST|11,471|25|11,448|||
|3035|COPYDigit3PIsPersev|COPYDigit3PIsPersev|Num|8|BEST|11,471|4|11,448|||
|3036|COPYDigit4PSeq|COPYDigit4PSeq|Num|8|BEST|11,471|6|11,463|||
|3037|COPYDigit4PStrokes|COPYDigit4PStrokes|Num|8|BEST|11,471|4|11,463|||
|3038|COPYDigit4PTime|COPYDigit4PTime|Num|8|BEST|11,471|10|11,463|||
|3039|COPYDigit4PLen|COPYDigit4PLen|Num|8|BEST|11,471|10|11,463|||
|3040|COPYDigit4PCentX|COPYDigit4PCentX|Num|8|BEST|11,471|10|11,463|||
|3041|COPYDigit4PCentY|COPYDigit4PCentY|Num|8|BEST|11,471|10|11,463|||
|3042|COPYDigit4PWidth|COPYDigit4PWidth|Num|8|BEST|11,471|10|11,463|||
|3043|COPYDigit4PHgt|COPYDigit4PHgt|Num|8|BEST|11,471|10|11,463|||
|3044|COPYDigit4PNormHt|COPYDigit4PNormHt|Num|8|BEST|11,471|10|11,463|||
|3045|COPYDigit4POutside|COPYDigit4POutside|Num|8|BEST|11,471|4|11,463|||
|3046|COPYDigit4PAngle|COPYDigit4PAngle|Num|8|BEST|11,471|10|11,463|||
|3047|COPYDigit4PIdealDiff|COPYDigit4PIdealDiff|Num|8|BEST|11,471|10|11,463|||
|3048|COPYDigit4PDistCircum|COPYDigit4PDistCircum|Num|8|BEST|11,471|10|11,463|||
|3049|COPYDigit4PIsPersev|COPYDigit4PIsPersev|Num|8|BEST|11,471|4|11,463|||
|3050|COPYDigit5PSeq|COPYDigit5PSeq|Num|8|BEST|11,471|9|11,458|||
|3051|COPYDigit5PStrokes|COPYDigit5PStrokes|Num|8|BEST|11,471|5|11,458|||
|3052|COPYDigit5PTime|COPYDigit5PTime|Num|8|BEST|11,471|15|11,458|||
|3053|COPYDigit5PLen|COPYDigit5PLen|Num|8|BEST|11,471|15|11,458|||
|3054|COPYDigit5PCentX|COPYDigit5PCentX|Num|8|BEST|11,471|15|11,458|||
|3055|COPYDigit5PCentY|COPYDigit5PCentY|Num|8|BEST|11,471|15|11,458|||
|3056|COPYDigit5PWidth|COPYDigit5PWidth|Num|8|BEST|11,471|15|11,458|||
|3057|COPYDigit5PHgt|COPYDigit5PHgt|Num|8|BEST|11,471|15|11,458|||
|3058|COPYDigit5PNormHt|COPYDigit5PNormHt|Num|8|BEST|11,471|14|11,459|||
|3059|COPYDigit5POutside|COPYDigit5POutside|Num|8|BEST|11,471|4|11,458|||
|3060|COPYDigit5PAngle|COPYDigit5PAngle|Num|8|BEST|11,471|15|11,458|||
|3061|COPYDigit5PIdealDiff|COPYDigit5PIdealDiff|Num|8|BEST|11,471|15|11,458|||
|3062|COPYDigit5PDistCircum|COPYDigit5PDistCircum|Num|8|BEST|11,471|15|11,458|||
|3063|COPYDigit5PIsPersev|COPYDigit5PIsPersev|Num|8|BEST|11,471|4|11,458|||
|3064|COPYDigit6PSeq|COPYDigit6PSeq|Num|8|BEST|11,471|15|11,436|||
|3065|COPYDigit6PStrokes|COPYDigit6PStrokes|Num|8|BEST|11,471|4|11,436|||
|3066|COPYDigit6PTime|COPYDigit6PTime|Num|8|BEST|11,471|32|11,436|||
|3067|COPYDigit6PLen|COPYDigit6PLen|Num|8|BEST|11,471|37|11,436|||
|3068|COPYDigit6PCentX|COPYDigit6PCentX|Num|8|BEST|11,471|36|11,436|||
|3069|COPYDigit6PCentY|COPYDigit6PCentY|Num|8|BEST|11,471|37|11,436|||
|3070|COPYDigit6PWidth|COPYDigit6PWidth|Num|8|BEST|11,471|31|11,436|||
|3071|COPYDigit6PHgt|COPYDigit6PHgt|Num|8|BEST|11,471|34|11,436|||
|3072|COPYDigit6PNormHt|COPYDigit6PNormHt|Num|8|BEST|11,471|35|11,438|||
|3073|COPYDigit6POutside|COPYDigit6POutside|Num|8|BEST|11,471|4|11,436|||
|3074|COPYDigit6PAngle|COPYDigit6PAngle|Num|8|BEST|11,471|36|11,436|||
|3075|COPYDigit6PIdealDiff|COPYDigit6PIdealDiff|Num|8|BEST|11,471|36|11,436|||
|3076|COPYDigit6PDistCircum|COPYDigit6PDistCircum|Num|8|BEST|11,471|36|11,436|||
|3077|COPYDigit6PIsPersev|COPYDigit6PIsPersev|Num|8|BEST|11,471|4|11,436|||
|3078|COPYDigit7PSeq|COPYDigit7PSeq|Num|8|BEST|11,471|6|11,465|||
|3079|COPYDigit7PStrokes|COPYDigit7PStrokes|Num|8|BEST|11,471|3|11,465|||
|3080|COPYDigit7PTime|COPYDigit7PTime|Num|8|BEST|11,471|8|11,465|||
|3081|COPYDigit7PLen|COPYDigit7PLen|Num|8|BEST|11,471|8|11,465|||
|3082|COPYDigit7PCentX|COPYDigit7PCentX|Num|8|BEST|11,471|8|11,465|||
|3083|COPYDigit7PCentY|COPYDigit7PCentY|Num|8|BEST|11,471|8|11,465|||
|3084|COPYDigit7PWidth|COPYDigit7PWidth|Num|8|BEST|11,471|8|11,465|||
|3085|COPYDigit7PHgt|COPYDigit7PHgt|Num|8|BEST|11,471|8|11,465|||
|3086|COPYDigit7PNormHt|COPYDigit7PNormHt|Num|8|BEST|11,471|8|11,465|||
|3087|COPYDigit7POutside|COPYDigit7POutside|Num|8|BEST|11,471|4|11,465|||
|3088|COPYDigit7PAngle|COPYDigit7PAngle|Num|8|BEST|11,471|8|11,465|||
|3089|COPYDigit7PIdealDiff|COPYDigit7PIdealDiff|Num|8|BEST|11,471|8|11,465|||
|3090|COPYDigit7PDistCircum|COPYDigit7PDistCircum|Num|8|BEST|11,471|8|11,465|||
|3091|COPYDigit7PIsPersev|COPYDigit7PIsPersev|Num|8|BEST|11,471|3|11,465|||
|3092|COPYDigit8PSeq|COPYDigit8PSeq|Num|8|BEST|11,471|10|11,459|||
|3093|COPYDigit8PStrokes|COPYDigit8PStrokes|Num|8|BEST|11,471|4|11,459|||
|3094|COPYDigit8PTime|COPYDigit8PTime|Num|8|BEST|11,471|14|11,459|||
|3095|COPYDigit8PLen|COPYDigit8PLen|Num|8|BEST|11,471|14|11,459|||
|3096|COPYDigit8PCentX|COPYDigit8PCentX|Num|8|BEST|11,471|14|11,459|||
|3097|COPYDigit8PCentY|COPYDigit8PCentY|Num|8|BEST|11,471|14|11,459|||
|3098|COPYDigit8PWidth|COPYDigit8PWidth|Num|8|BEST|11,471|13|11,459|||
|3099|COPYDigit8PHgt|COPYDigit8PHgt|Num|8|BEST|11,471|14|11,459|||
|3100|COPYDigit8PNormHt|COPYDigit8PNormHt|Num|8|BEST|11,471|13|11,460|||
|3101|COPYDigit8POutside|COPYDigit8POutside|Num|8|BEST|11,471|4|11,459|||
|3102|COPYDigit8PAngle|COPYDigit8PAngle|Num|8|BEST|11,471|14|11,459|||
|3103|COPYDigit8PIdealDiff|COPYDigit8PIdealDiff|Num|8|BEST|11,471|14|11,459|||
|3104|COPYDigit8PDistCircum|COPYDigit8PDistCircum|Num|8|BEST|11,471|14|11,459|||
|3105|COPYDigit8PIsPersev|COPYDigit8PIsPersev|Num|8|BEST|11,471|4|11,459|||
|3106|COPYDigit9PSeq|COPYDigit9PSeq|Num|8|BEST|11,471|8|11,458|||
|3107|COPYDigit9PStrokes|COPYDigit9PStrokes|Num|8|BEST|11,471|3|11,458|||
|3108|COPYDigit9PTime|COPYDigit9PTime|Num|8|BEST|11,471|14|11,458|||
|3109|COPYDigit9PLen|COPYDigit9PLen|Num|8|BEST|11,471|15|11,458|||
|3110|COPYDigit9PCentX|COPYDigit9PCentX|Num|8|BEST|11,471|15|11,458|||
|3111|COPYDigit9PCentY|COPYDigit9PCentY|Num|8|BEST|11,471|15|11,458|||
|3112|COPYDigit9PWidth|COPYDigit9PWidth|Num|8|BEST|11,471|15|11,458|||
|3113|COPYDigit9PHgt|COPYDigit9PHgt|Num|8|BEST|11,471|15|11,458|||
|3114|COPYDigit9PNormHt|COPYDigit9PNormHt|Num|8|BEST|11,471|14|11,459|||
|3115|COPYDigit9POutside|COPYDigit9POutside|Num|8|BEST|11,471|4|11,458|||
|3116|COPYDigit9PAngle|COPYDigit9PAngle|Num|8|BEST|11,471|15|11,458|||
|3117|COPYDigit9PIdealDiff|COPYDigit9PIdealDiff|Num|8|BEST|11,471|15|11,458|||
|3118|COPYDigit9PDistCircum|COPYDigit9PDistCircum|Num|8|BEST|11,471|15|11,458|||
|3119|COPYDigit9PIsPersev|COPYDigit9PIsPersev|Num|8|BEST|11,471|4|11,458|||
|3120|COPYDigit10PSeq|COPYDigit10PSeq|Num|8|BEST|11,471|9|11,432|||
|3121|COPYDigit10PStrokes|COPYDigit10PStrokes|Num|8|BEST|11,471|4|11,432|||
|3122|COPYDigit10PTime|COPYDigit10PTime|Num|8|BEST|11,471|41|11,432|||
|3123|COPYDigit10PLen|COPYDigit10PLen|Num|8|BEST|11,471|41|11,432|||
|3124|COPYDigit10PCentX|COPYDigit10PCentX|Num|8|BEST|11,471|41|11,432|||
|3125|COPYDigit10PCentY|COPYDigit10PCentY|Num|8|BEST|11,471|41|11,432|||
|3126|COPYDigit10PWidth|COPYDigit10PWidth|Num|8|BEST|11,471|35|11,432|||
|3127|COPYDigit10PHgt|COPYDigit10PHgt|Num|8|BEST|11,471|35|11,432|||
|3128|COPYDigit10PNormHt|COPYDigit10PNormHt|Num|8|BEST|11,471|41|11,432|||
|3129|COPYDigit10POutside|COPYDigit10POutside|Num|8|BEST|11,471|4|11,432|||
|3130|COPYDigit10PAngle|COPYDigit10PAngle|Num|8|BEST|11,471|41|11,432|||
|3131|COPYDigit10PIdealDiff|COPYDigit10PIdealDiff|Num|8|BEST|11,471|41|11,432|||
|3132|COPYDigit10PDistCircum|COPYDigit10PDistCircum|Num|8|BEST|11,471|41|11,432|||
|3133|COPYDigit10PIsPersev|COPYDigit10PIsPersev|Num|8|BEST|11,471|4|11,432|||
|3134|COPYDigit11PSeq|COPYDigit11PSeq|Num|8|BEST|11,471|11|11,435|||
|3135|COPYDigit11PStrokes|COPYDigit11PStrokes|Num|8|BEST|11,471|4|11,435|||
|3136|COPYDigit11PTime|COPYDigit11PTime|Num|8|BEST|11,471|38|11,435|||
|3137|COPYDigit11PLen|COPYDigit11PLen|Num|8|BEST|11,471|38|11,435|||
|3138|COPYDigit11PCentX|COPYDigit11PCentX|Num|8|BEST|11,471|38|11,435|||
|3139|COPYDigit11PCentY|COPYDigit11PCentY|Num|8|BEST|11,471|38|11,435|||
|3140|COPYDigit11PWidth|COPYDigit11PWidth|Num|8|BEST|11,471|35|11,435|||
|3141|COPYDigit11PHgt|COPYDigit11PHgt|Num|8|BEST|11,471|35|11,435|||
|3142|COPYDigit11PNormHt|COPYDigit11PNormHt|Num|8|BEST|11,471|38|11,435|||
|3143|COPYDigit11POutside|COPYDigit11POutside|Num|8|BEST|11,471|4|11,435|||
|3144|COPYDigit11PAngle|COPYDigit11PAngle|Num|8|BEST|11,471|38|11,435|||
|3145|COPYDigit11PIdealDiff|COPYDigit11PIdealDiff|Num|8|BEST|11,471|38|11,435|||
|3146|COPYDigit11PDistCircum|COPYDigit11PDistCircum|Num|8|BEST|11,471|38|11,435|||
|3147|COPYDigit11PIsPersev|COPYDigit11PIsPersev|Num|8|BEST|11,471|4|11,435|||
|3148|COPYDigit12PSeq|COPYDigit12PSeq|Num|8|BEST|11,471|11|11,427|||
|3149|COPYDigit12PStrokes|COPYDigit12PStrokes|Num|8|BEST|11,471|4|11,427|||
|3150|COPYDigit12PTime|COPYDigit12PTime|Num|8|BEST|11,471|44|11,427|||
|3151|COPYDigit12PLen|COPYDigit12PLen|Num|8|BEST|11,471|46|11,427|||
|3152|COPYDigit12PCentX|COPYDigit12PCentX|Num|8|BEST|11,471|44|11,427|||
|3153|COPYDigit12PCentY|COPYDigit12PCentY|Num|8|BEST|11,471|46|11,427|||
|3154|COPYDigit12PWidth|COPYDigit12PWidth|Num|8|BEST|11,471|38|11,427|||
|3155|COPYDigit12PHgt|COPYDigit12PHgt|Num|8|BEST|11,471|41|11,427|||
|3156|COPYDigit12PNormHt|COPYDigit12PNormHt|Num|8|BEST|11,471|41|11,432|||
|3157|COPYDigit12POutside|COPYDigit12POutside|Num|8|BEST|11,471|4|11,427|||
|3158|COPYDigit12PAngle|COPYDigit12PAngle|Num|8|BEST|11,471|42|11,427|||
|3159|COPYDigit12PIdealDiff|COPYDigit12PIdealDiff|Num|8|BEST|11,471|42|11,427|||
|3160|COPYDigit12PDistCircum|COPYDigit12PDistCircum|Num|8|BEST|11,471|42|11,427|||
|3161|COPYDigit12PIsPersev|COPYDigit12PIsPersev|Num|8|BEST|11,471|4|11,427|||
|3162|COPYDigit1PPSeq|COPYDigit1PPSeq|Num|8|BEST|11,471|3|11,470|||
|3163|COPYDigit1PPStrokes|COPYDigit1PPStrokes|Num|8|BEST|11,471|3|11,470|||
|3164|COPYDigit1PPTime|COPYDigit1PPTime|Num|8|BEST|11,471|3|11,470|||
|3165|COPYDigit1PPLen|COPYDigit1PPLen|Num|8|BEST|11,471|3|11,470|||
|3166|COPYDigit1PPCentX|COPYDigit1PPCentX|Num|8|BEST|11,471|3|11,470|||
|3167|COPYDigit1PPCentY|COPYDigit1PPCentY|Num|8|BEST|11,471|3|11,470|||
|3168|COPYDigit1PPWidth|COPYDigit1PPWidth|Num|8|BEST|11,471|3|11,470|||
|3169|COPYDigit1PPHgt|COPYDigit1PPHgt|Num|8|BEST|11,471|3|11,470|||
|3170|COPYDigit1PPNormHt|COPYDigit1PPNormHt|Num|8|BEST|11,471|3|11,470|||
|3171|COPYDigit1PPOutside|COPYDigit1PPOutside|Num|8|BEST|11,471|3|11,470|||
|3172|COPYDigit1PPAngle|COPYDigit1PPAngle|Num|8|BEST|11,471|3|11,470|||
|3173|COPYDigit1PPIdealDiff|COPYDigit1PPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|3174|COPYDigit1PPDistCircum|COPYDigit1PPDistCircum|Num|8|BEST|11,471|3|11,470|||
|3175|COPYDigit1PPIsPersev|COPYDigit1PPIsPersev|Num|8|BEST|11,471|3|11,470|||
|3176|COPYDigit2PPSeq|COPYDigit2PPSeq|Num|8|BEST|11,471|2|11,471|||
|3177|COPYDigit2PPStrokes|COPYDigit2PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3178|COPYDigit2PPTime|COPYDigit2PPTime|Num|8|BEST|11,471|2|11,471|||
|3179|COPYDigit2PPLen|COPYDigit2PPLen|Num|8|BEST|11,471|2|11,471|||
|3180|COPYDigit2PPCentX|COPYDigit2PPCentX|Num|8|BEST|11,471|2|11,471|||
|3181|COPYDigit2PPCentY|COPYDigit2PPCentY|Num|8|BEST|11,471|2|11,471|||
|3182|COPYDigit2PPWidth|COPYDigit2PPWidth|Num|8|BEST|11,471|2|11,471|||
|3183|COPYDigit2PPHgt|COPYDigit2PPHgt|Num|8|BEST|11,471|2|11,471|||
|3184|COPYDigit2PPNormHt|COPYDigit2PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3185|COPYDigit2PPOutside|COPYDigit2PPOutside|Num|8|BEST|11,471|2|11,471|||
|3186|COPYDigit2PPAngle|COPYDigit2PPAngle|Num|8|BEST|11,471|2|11,471|||
|3187|COPYDigit2PPIdealDiff|COPYDigit2PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3188|COPYDigit2PPDistCircum|COPYDigit2PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3189|COPYDigit2PPIsPersev|COPYDigit2PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3190|COPYDigit3PPSeq|COPYDigit3PPSeq|Num|8|BEST|11,471|3|11,470|||
|3191|COPYDigit3PPStrokes|COPYDigit3PPStrokes|Num|8|BEST|11,471|3|11,470|||
|3192|COPYDigit3PPTime|COPYDigit3PPTime|Num|8|BEST|11,471|3|11,470|||
|3193|COPYDigit3PPLen|COPYDigit3PPLen|Num|8|BEST|11,471|3|11,470|||
|3194|COPYDigit3PPCentX|COPYDigit3PPCentX|Num|8|BEST|11,471|3|11,470|||
|3195|COPYDigit3PPCentY|COPYDigit3PPCentY|Num|8|BEST|11,471|3|11,470|||
|3196|COPYDigit3PPWidth|COPYDigit3PPWidth|Num|8|BEST|11,471|3|11,470|||
|3197|COPYDigit3PPHgt|COPYDigit3PPHgt|Num|8|BEST|11,471|3|11,470|||
|3198|COPYDigit3PPNormHt|COPYDigit3PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3199|COPYDigit3PPOutside|COPYDigit3PPOutside|Num|8|BEST|11,471|3|11,470|||
|3200|COPYDigit3PPAngle|COPYDigit3PPAngle|Num|8|BEST|11,471|3|11,470|||
|3201|COPYDigit3PPIdealDiff|COPYDigit3PPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|3202|COPYDigit3PPDistCircum|COPYDigit3PPDistCircum|Num|8|BEST|11,471|3|11,470|||
|3203|COPYDigit3PPIsPersev|COPYDigit3PPIsPersev|Num|8|BEST|11,471|3|11,470|||
|3204|COPYDigit4PPSeq|COPYDigit4PPSeq|Num|8|BEST|11,471|2|11,471|||
|3205|COPYDigit4PPStrokes|COPYDigit4PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3206|COPYDigit4PPTime|COPYDigit4PPTime|Num|8|BEST|11,471|2|11,471|||
|3207|COPYDigit4PPLen|COPYDigit4PPLen|Num|8|BEST|11,471|2|11,471|||
|3208|COPYDigit4PPCentX|COPYDigit4PPCentX|Num|8|BEST|11,471|2|11,471|||
|3209|COPYDigit4PPCentY|COPYDigit4PPCentY|Num|8|BEST|11,471|2|11,471|||
|3210|COPYDigit4PPWidth|COPYDigit4PPWidth|Num|8|BEST|11,471|2|11,471|||
|3211|COPYDigit4PPHgt|COPYDigit4PPHgt|Num|8|BEST|11,471|2|11,471|||
|3212|COPYDigit4PPNormHt|COPYDigit4PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3213|COPYDigit4PPOutside|COPYDigit4PPOutside|Num|8|BEST|11,471|2|11,471|||
|3214|COPYDigit4PPAngle|COPYDigit4PPAngle|Num|8|BEST|11,471|2|11,471|||
|3215|COPYDigit4PPIdealDiff|COPYDigit4PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3216|COPYDigit4PPDistCircum|COPYDigit4PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3217|COPYDigit4PPIsPersev|COPYDigit4PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3218|COPYDigit5PPSeq|COPYDigit5PPSeq|Num|8|BEST|11,471|2|11,471|||
|3219|COPYDigit5PPStrokes|COPYDigit5PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3220|COPYDigit5PPTime|COPYDigit5PPTime|Num|8|BEST|11,471|2|11,471|||
|3221|COPYDigit5PPLen|COPYDigit5PPLen|Num|8|BEST|11,471|2|11,471|||
|3222|COPYDigit5PPCentX|COPYDigit5PPCentX|Num|8|BEST|11,471|2|11,471|||
|3223|COPYDigit5PPCentY|COPYDigit5PPCentY|Num|8|BEST|11,471|2|11,471|||
|3224|COPYDigit5PPWidth|COPYDigit5PPWidth|Num|8|BEST|11,471|2|11,471|||
|3225|COPYDigit5PPHgt|COPYDigit5PPHgt|Num|8|BEST|11,471|2|11,471|||
|3226|COPYDigit5PPNormHt|COPYDigit5PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3227|COPYDigit5PPOutside|COPYDigit5PPOutside|Num|8|BEST|11,471|2|11,471|||
|3228|COPYDigit5PPAngle|COPYDigit5PPAngle|Num|8|BEST|11,471|2|11,471|||
|3229|COPYDigit5PPIdealDiff|COPYDigit5PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3230|COPYDigit5PPDistCircum|COPYDigit5PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3231|COPYDigit5PPIsPersev|COPYDigit5PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3232|COPYDigit6PPSeq|COPYDigit6PPSeq|Num|8|BEST|11,471|2|11,471|||
|3233|COPYDigit6PPStrokes|COPYDigit6PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3234|COPYDigit6PPTime|COPYDigit6PPTime|Num|8|BEST|11,471|2|11,471|||
|3235|COPYDigit6PPLen|COPYDigit6PPLen|Num|8|BEST|11,471|2|11,471|||
|3236|COPYDigit6PPCentX|COPYDigit6PPCentX|Num|8|BEST|11,471|2|11,471|||
|3237|COPYDigit6PPCentY|COPYDigit6PPCentY|Num|8|BEST|11,471|2|11,471|||
|3238|COPYDigit6PPWidth|COPYDigit6PPWidth|Num|8|BEST|11,471|2|11,471|||
|3239|COPYDigit6PPHgt|COPYDigit6PPHgt|Num|8|BEST|11,471|2|11,471|||
|3240|COPYDigit6PPNormHt|COPYDigit6PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3241|COPYDigit6PPOutside|COPYDigit6PPOutside|Num|8|BEST|11,471|2|11,471|||
|3242|COPYDigit6PPAngle|COPYDigit6PPAngle|Num|8|BEST|11,471|2|11,471|||
|3243|COPYDigit6PPIdealDiff|COPYDigit6PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3244|COPYDigit6PPDistCircum|COPYDigit6PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3245|COPYDigit6PPIsPersev|COPYDigit6PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3246|COPYDigit7PPSeq|COPYDigit7PPSeq|Num|8|BEST|11,471|2|11,471|||
|3247|COPYDigit7PPStrokes|COPYDigit7PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3248|COPYDigit7PPTime|COPYDigit7PPTime|Num|8|BEST|11,471|2|11,471|||
|3249|COPYDigit7PPLen|COPYDigit7PPLen|Num|8|BEST|11,471|2|11,471|||
|3250|COPYDigit7PPCentX|COPYDigit7PPCentX|Num|8|BEST|11,471|2|11,471|||
|3251|COPYDigit7PPCentY|COPYDigit7PPCentY|Num|8|BEST|11,471|2|11,471|||
|3252|COPYDigit7PPWidth|COPYDigit7PPWidth|Num|8|BEST|11,471|2|11,471|||
|3253|COPYDigit7PPHgt|COPYDigit7PPHgt|Num|8|BEST|11,471|2|11,471|||
|3254|COPYDigit7PPNormHt|COPYDigit7PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3255|COPYDigit7PPOutside|COPYDigit7PPOutside|Num|8|BEST|11,471|2|11,471|||
|3256|COPYDigit7PPAngle|COPYDigit7PPAngle|Num|8|BEST|11,471|2|11,471|||
|3257|COPYDigit7PPIdealDiff|COPYDigit7PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3258|COPYDigit7PPDistCircum|COPYDigit7PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3259|COPYDigit7PPIsPersev|COPYDigit7PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3260|COPYDigit8PPSeq|COPYDigit8PPSeq|Num|8|BEST|11,471|2|11,471|||
|3261|COPYDigit8PPStrokes|COPYDigit8PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3262|COPYDigit8PPTime|COPYDigit8PPTime|Num|8|BEST|11,471|2|11,471|||
|3263|COPYDigit8PPLen|COPYDigit8PPLen|Num|8|BEST|11,471|2|11,471|||
|3264|COPYDigit8PPCentX|COPYDigit8PPCentX|Num|8|BEST|11,471|2|11,471|||
|3265|COPYDigit8PPCentY|COPYDigit8PPCentY|Num|8|BEST|11,471|2|11,471|||
|3266|COPYDigit8PPWidth|COPYDigit8PPWidth|Num|8|BEST|11,471|2|11,471|||
|3267|COPYDigit8PPHgt|COPYDigit8PPHgt|Num|8|BEST|11,471|2|11,471|||
|3268|COPYDigit8PPNormHt|COPYDigit8PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3269|COPYDigit8PPOutside|COPYDigit8PPOutside|Num|8|BEST|11,471|2|11,471|||
|3270|COPYDigit8PPAngle|COPYDigit8PPAngle|Num|8|BEST|11,471|2|11,471|||
|3271|COPYDigit8PPIdealDiff|COPYDigit8PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3272|COPYDigit8PPDistCircum|COPYDigit8PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3273|COPYDigit8PPIsPersev|COPYDigit8PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3274|COPYDigit9PPSeq|COPYDigit9PPSeq|Num|8|BEST|11,471|2|11,471|||
|3275|COPYDigit9PPStrokes|COPYDigit9PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3276|COPYDigit9PPTime|COPYDigit9PPTime|Num|8|BEST|11,471|2|11,471|||
|3277|COPYDigit9PPLen|COPYDigit9PPLen|Num|8|BEST|11,471|2|11,471|||
|3278|COPYDigit9PPCentX|COPYDigit9PPCentX|Num|8|BEST|11,471|2|11,471|||
|3279|COPYDigit9PPCentY|COPYDigit9PPCentY|Num|8|BEST|11,471|2|11,471|||
|3280|COPYDigit9PPWidth|COPYDigit9PPWidth|Num|8|BEST|11,471|2|11,471|||
|3281|COPYDigit9PPHgt|COPYDigit9PPHgt|Num|8|BEST|11,471|2|11,471|||
|3282|COPYDigit9PPNormHt|COPYDigit9PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3283|COPYDigit9PPOutside|COPYDigit9PPOutside|Num|8|BEST|11,471|2|11,471|||
|3284|COPYDigit9PPAngle|COPYDigit9PPAngle|Num|8|BEST|11,471|2|11,471|||
|3285|COPYDigit9PPIdealDiff|COPYDigit9PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3286|COPYDigit9PPDistCircum|COPYDigit9PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3287|COPYDigit9PPIsPersev|COPYDigit9PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3288|COPYDigit10PPSeq|COPYDigit10PPSeq|Num|8|BEST|11,471|2|11,471|||
|3289|COPYDigit10PPStrokes|COPYDigit10PPStrokes|Num|8|BEST|11,471|2|11,471|||
|3290|COPYDigit10PPTime|COPYDigit10PPTime|Num|8|BEST|11,471|2|11,471|||
|3291|COPYDigit10PPLen|COPYDigit10PPLen|Num|8|BEST|11,471|2|11,471|||
|3292|COPYDigit10PPCentX|COPYDigit10PPCentX|Num|8|BEST|11,471|2|11,471|||
|3293|COPYDigit10PPCentY|COPYDigit10PPCentY|Num|8|BEST|11,471|2|11,471|||
|3294|COPYDigit10PPWidth|COPYDigit10PPWidth|Num|8|BEST|11,471|2|11,471|||
|3295|COPYDigit10PPHgt|COPYDigit10PPHgt|Num|8|BEST|11,471|2|11,471|||
|3296|COPYDigit10PPNormHt|COPYDigit10PPNormHt|Num|8|BEST|11,471|2|11,471|||
|3297|COPYDigit10PPOutside|COPYDigit10PPOutside|Num|8|BEST|11,471|2|11,471|||
|3298|COPYDigit10PPAngle|COPYDigit10PPAngle|Num|8|BEST|11,471|2|11,471|||
|3299|COPYDigit10PPIdealDiff|COPYDigit10PPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3300|COPYDigit10PPDistCircum|COPYDigit10PPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3301|COPYDigit10PPIsPersev|COPYDigit10PPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3302|COPYDigit11PPSeq|COPYDigit11PPSeq|Num|8|BEST|11,471|3|11,470|||
|3303|COPYDigit11PPStrokes|COPYDigit11PPStrokes|Num|8|BEST|11,471|3|11,470|||
|3304|COPYDigit11PPTime|COPYDigit11PPTime|Num|8|BEST|11,471|3|11,470|||
|3305|COPYDigit11PPLen|COPYDigit11PPLen|Num|8|BEST|11,471|3|11,470|||
|3306|COPYDigit11PPCentX|COPYDigit11PPCentX|Num|8|BEST|11,471|3|11,470|||
|3307|COPYDigit11PPCentY|COPYDigit11PPCentY|Num|8|BEST|11,471|3|11,470|||
|3308|COPYDigit11PPWidth|COPYDigit11PPWidth|Num|8|BEST|11,471|3|11,470|||
|3309|COPYDigit11PPHgt|COPYDigit11PPHgt|Num|8|BEST|11,471|3|11,470|||
|3310|COPYDigit11PPNormHt|COPYDigit11PPNormHt|Num|8|BEST|11,471|3|11,470|||
|3311|COPYDigit11PPOutside|COPYDigit11PPOutside|Num|8|BEST|11,471|3|11,470|||
|3312|COPYDigit11PPAngle|COPYDigit11PPAngle|Num|8|BEST|11,471|3|11,470|||
|3313|COPYDigit11PPIdealDiff|COPYDigit11PPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|3314|COPYDigit11PPDistCircum|COPYDigit11PPDistCircum|Num|8|BEST|11,471|3|11,470|||
|3315|COPYDigit11PPIsPersev|COPYDigit11PPIsPersev|Num|8|BEST|11,471|3|11,470|||
|3316|COPYDigit12PPSeq|COPYDigit12PPSeq|Num|8|BEST|11,471|3|11,470|||
|3317|COPYDigit12PPStrokes|COPYDigit12PPStrokes|Num|8|BEST|11,471|3|11,470|||
|3318|COPYDigit12PPTime|COPYDigit12PPTime|Num|8|BEST|11,471|3|11,470|||
|3319|COPYDigit12PPLen|COPYDigit12PPLen|Num|8|BEST|11,471|3|11,470|||
|3320|COPYDigit12PPCentX|COPYDigit12PPCentX|Num|8|BEST|11,471|3|11,470|||
|3321|COPYDigit12PPCentY|COPYDigit12PPCentY|Num|8|BEST|11,471|3|11,470|||
|3322|COPYDigit12PPWidth|COPYDigit12PPWidth|Num|8|BEST|11,471|3|11,470|||
|3323|COPYDigit12PPHgt|COPYDigit12PPHgt|Num|8|BEST|11,471|3|11,470|||
|3324|COPYDigit12PPNormHt|COPYDigit12PPNormHt|Num|8|BEST|11,471|3|11,470|||
|3325|COPYDigit12PPOutside|COPYDigit12PPOutside|Num|8|BEST|11,471|3|11,470|||
|3326|COPYDigit12PPAngle|COPYDigit12PPAngle|Num|8|BEST|11,471|3|11,470|||
|3327|COPYDigit12PPIdealDiff|COPYDigit12PPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|3328|COPYDigit12PPDistCircum|COPYDigit12PPDistCircum|Num|8|BEST|11,471|3|11,470|||
|3329|COPYDigit12PPIsPersev|COPYDigit12PPIsPersev|Num|8|BEST|11,471|3|11,470|||
|3330|COPYDigit1PPPSeq|COPYDigit1PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3331|COPYDigit1PPPStrokes|COPYDigit1PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3332|COPYDigit1PPPTime|COPYDigit1PPPTime|Num|8|BEST|11,471|2|11,471|||
|3333|COPYDigit1PPPLen|COPYDigit1PPPLen|Num|8|BEST|11,471|2|11,471|||
|3334|COPYDigit1PPPCentX|COPYDigit1PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3335|COPYDigit1PPPCentY|COPYDigit1PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3336|COPYDigit1PPPWidth|COPYDigit1PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3337|COPYDigit1PPPHgt|COPYDigit1PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3338|COPYDigit1PPPNormHt|COPYDigit1PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3339|COPYDigit1PPPOutside|COPYDigit1PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3340|COPYDigit1PPPAngle|COPYDigit1PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3341|COPYDigit1PPPIdealDiff|COPYDigit1PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3342|COPYDigit1PPPDistCircum|COPYDigit1PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3343|COPYDigit1PPPIsPersev|COPYDigit1PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3344|COPYDigit2PPPSeq|COPYDigit2PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3345|COPYDigit2PPPStrokes|COPYDigit2PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3346|COPYDigit2PPPTime|COPYDigit2PPPTime|Num|8|BEST|11,471|2|11,471|||
|3347|COPYDigit2PPPLen|COPYDigit2PPPLen|Num|8|BEST|11,471|2|11,471|||
|3348|COPYDigit2PPPCentX|COPYDigit2PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3349|COPYDigit2PPPCentY|COPYDigit2PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3350|COPYDigit2PPPWidth|COPYDigit2PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3351|COPYDigit2PPPHgt|COPYDigit2PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3352|COPYDigit2PPPNormHt|COPYDigit2PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3353|COPYDigit2PPPOutside|COPYDigit2PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3354|COPYDigit2PPPAngle|COPYDigit2PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3355|COPYDigit2PPPIdealDiff|COPYDigit2PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3356|COPYDigit2PPPDistCircum|COPYDigit2PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3357|COPYDigit2PPPIsPersev|COPYDigit2PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3358|COPYDigit3PPPSeq|COPYDigit3PPPSeq|Num|8|BEST|11,471|3|11,470|||
|3359|COPYDigit3PPPStrokes|COPYDigit3PPPStrokes|Num|8|BEST|11,471|3|11,470|||
|3360|COPYDigit3PPPTime|COPYDigit3PPPTime|Num|8|BEST|11,471|3|11,470|||
|3361|COPYDigit3PPPLen|COPYDigit3PPPLen|Num|8|BEST|11,471|3|11,470|||
|3362|COPYDigit3PPPCentX|COPYDigit3PPPCentX|Num|8|BEST|11,471|3|11,470|||
|3363|COPYDigit3PPPCentY|COPYDigit3PPPCentY|Num|8|BEST|11,471|3|11,470|||
|3364|COPYDigit3PPPWidth|COPYDigit3PPPWidth|Num|8|BEST|11,471|3|11,470|||
|3365|COPYDigit3PPPHgt|COPYDigit3PPPHgt|Num|8|BEST|11,471|3|11,470|||
|3366|COPYDigit3PPPNormHt|COPYDigit3PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3367|COPYDigit3PPPOutside|COPYDigit3PPPOutside|Num|8|BEST|11,471|3|11,470|||
|3368|COPYDigit3PPPAngle|COPYDigit3PPPAngle|Num|8|BEST|11,471|3|11,470|||
|3369|COPYDigit3PPPIdealDiff|COPYDigit3PPPIdealDiff|Num|8|BEST|11,471|3|11,470|||
|3370|COPYDigit3PPPDistCircum|COPYDigit3PPPDistCircum|Num|8|BEST|11,471|3|11,470|||
|3371|COPYDigit3PPPIsPersev|COPYDigit3PPPIsPersev|Num|8|BEST|11,471|3|11,470|||
|3372|COPYDigit4PPPSeq|COPYDigit4PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3373|COPYDigit4PPPStrokes|COPYDigit4PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3374|COPYDigit4PPPTime|COPYDigit4PPPTime|Num|8|BEST|11,471|2|11,471|||
|3375|COPYDigit4PPPLen|COPYDigit4PPPLen|Num|8|BEST|11,471|2|11,471|||
|3376|COPYDigit4PPPCentX|COPYDigit4PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3377|COPYDigit4PPPCentY|COPYDigit4PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3378|COPYDigit4PPPWidth|COPYDigit4PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3379|COPYDigit4PPPHgt|COPYDigit4PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3380|COPYDigit4PPPNormHt|COPYDigit4PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3381|COPYDigit4PPPOutside|COPYDigit4PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3382|COPYDigit4PPPAngle|COPYDigit4PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3383|COPYDigit4PPPIdealDiff|COPYDigit4PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3384|COPYDigit4PPPDistCircum|COPYDigit4PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3385|COPYDigit4PPPIsPersev|COPYDigit4PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3386|COPYDigit5PPPSeq|COPYDigit5PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3387|COPYDigit5PPPStrokes|COPYDigit5PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3388|COPYDigit5PPPTime|COPYDigit5PPPTime|Num|8|BEST|11,471|2|11,471|||
|3389|COPYDigit5PPPLen|COPYDigit5PPPLen|Num|8|BEST|11,471|2|11,471|||
|3390|COPYDigit5PPPCentX|COPYDigit5PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3391|COPYDigit5PPPCentY|COPYDigit5PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3392|COPYDigit5PPPWidth|COPYDigit5PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3393|COPYDigit5PPPHgt|COPYDigit5PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3394|COPYDigit5PPPNormHt|COPYDigit5PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3395|COPYDigit5PPPOutside|COPYDigit5PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3396|COPYDigit5PPPAngle|COPYDigit5PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3397|COPYDigit5PPPIdealDiff|COPYDigit5PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3398|COPYDigit5PPPDistCircum|COPYDigit5PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3399|COPYDigit5PPPIsPersev|COPYDigit5PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3400|COPYDigit6PPPSeq|COPYDigit6PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3401|COPYDigit6PPPStrokes|COPYDigit6PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3402|COPYDigit6PPPTime|COPYDigit6PPPTime|Num|8|BEST|11,471|2|11,471|||
|3403|COPYDigit6PPPLen|COPYDigit6PPPLen|Num|8|BEST|11,471|2|11,471|||
|3404|COPYDigit6PPPCentX|COPYDigit6PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3405|COPYDigit6PPPCentY|COPYDigit6PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3406|COPYDigit6PPPWidth|COPYDigit6PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3407|COPYDigit6PPPHgt|COPYDigit6PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3408|COPYDigit6PPPNormHt|COPYDigit6PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3409|COPYDigit6PPPOutside|COPYDigit6PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3410|COPYDigit6PPPAngle|COPYDigit6PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3411|COPYDigit6PPPIdealDiff|COPYDigit6PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3412|COPYDigit6PPPDistCircum|COPYDigit6PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3413|COPYDigit6PPPIsPersev|COPYDigit6PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3414|COPYDigit7PPPSeq|COPYDigit7PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3415|COPYDigit7PPPStrokes|COPYDigit7PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3416|COPYDigit7PPPTime|COPYDigit7PPPTime|Num|8|BEST|11,471|2|11,471|||
|3417|COPYDigit7PPPLen|COPYDigit7PPPLen|Num|8|BEST|11,471|2|11,471|||
|3418|COPYDigit7PPPCentX|COPYDigit7PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3419|COPYDigit7PPPCentY|COPYDigit7PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3420|COPYDigit7PPPWidth|COPYDigit7PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3421|COPYDigit7PPPHgt|COPYDigit7PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3422|COPYDigit7PPPNormHt|COPYDigit7PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3423|COPYDigit7PPPOutside|COPYDigit7PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3424|COPYDigit7PPPAngle|COPYDigit7PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3425|COPYDigit7PPPIdealDiff|COPYDigit7PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3426|COPYDigit7PPPDistCircum|COPYDigit7PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3427|COPYDigit7PPPIsPersev|COPYDigit7PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3428|COPYDigit8PPPSeq|COPYDigit8PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3429|COPYDigit8PPPStrokes|COPYDigit8PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3430|COPYDigit8PPPTime|COPYDigit8PPPTime|Num|8|BEST|11,471|2|11,471|||
|3431|COPYDigit8PPPLen|COPYDigit8PPPLen|Num|8|BEST|11,471|2|11,471|||
|3432|COPYDigit8PPPCentX|COPYDigit8PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3433|COPYDigit8PPPCentY|COPYDigit8PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3434|COPYDigit8PPPWidth|COPYDigit8PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3435|COPYDigit8PPPHgt|COPYDigit8PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3436|COPYDigit8PPPNormHt|COPYDigit8PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3437|COPYDigit8PPPOutside|COPYDigit8PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3438|COPYDigit8PPPAngle|COPYDigit8PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3439|COPYDigit8PPPIdealDiff|COPYDigit8PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3440|COPYDigit8PPPDistCircum|COPYDigit8PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3441|COPYDigit8PPPIsPersev|COPYDigit8PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3442|COPYDigit9PPPSeq|COPYDigit9PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3443|COPYDigit9PPPStrokes|COPYDigit9PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3444|COPYDigit9PPPTime|COPYDigit9PPPTime|Num|8|BEST|11,471|2|11,471|||
|3445|COPYDigit9PPPLen|COPYDigit9PPPLen|Num|8|BEST|11,471|2|11,471|||
|3446|COPYDigit9PPPCentX|COPYDigit9PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3447|COPYDigit9PPPCentY|COPYDigit9PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3448|COPYDigit9PPPWidth|COPYDigit9PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3449|COPYDigit9PPPHgt|COPYDigit9PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3450|COPYDigit9PPPNormHt|COPYDigit9PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3451|COPYDigit9PPPOutside|COPYDigit9PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3452|COPYDigit9PPPAngle|COPYDigit9PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3453|COPYDigit9PPPIdealDiff|COPYDigit9PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3454|COPYDigit9PPPDistCircum|COPYDigit9PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3455|COPYDigit9PPPIsPersev|COPYDigit9PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3456|COPYDigit10PPPSeq|COPYDigit10PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3457|COPYDigit10PPPStrokes|COPYDigit10PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3458|COPYDigit10PPPTime|COPYDigit10PPPTime|Num|8|BEST|11,471|2|11,471|||
|3459|COPYDigit10PPPLen|COPYDigit10PPPLen|Num|8|BEST|11,471|2|11,471|||
|3460|COPYDigit10PPPCentX|COPYDigit10PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3461|COPYDigit10PPPCentY|COPYDigit10PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3462|COPYDigit10PPPWidth|COPYDigit10PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3463|COPYDigit10PPPHgt|COPYDigit10PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3464|COPYDigit10PPPNormHt|COPYDigit10PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3465|COPYDigit10PPPOutside|COPYDigit10PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3466|COPYDigit10PPPAngle|COPYDigit10PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3467|COPYDigit10PPPIdealDiff|COPYDigit10PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3468|COPYDigit10PPPDistCircum|COPYDigit10PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3469|COPYDigit10PPPIsPersev|COPYDigit10PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3470|COPYDigit11PPPSeq|COPYDigit11PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3471|COPYDigit11PPPStrokes|COPYDigit11PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3472|COPYDigit11PPPTime|COPYDigit11PPPTime|Num|8|BEST|11,471|2|11,471|||
|3473|COPYDigit11PPPLen|COPYDigit11PPPLen|Num|8|BEST|11,471|2|11,471|||
|3474|COPYDigit11PPPCentX|COPYDigit11PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3475|COPYDigit11PPPCentY|COPYDigit11PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3476|COPYDigit11PPPWidth|COPYDigit11PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3477|COPYDigit11PPPHgt|COPYDigit11PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3478|COPYDigit11PPPNormHt|COPYDigit11PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3479|COPYDigit11PPPOutside|COPYDigit11PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3480|COPYDigit11PPPAngle|COPYDigit11PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3481|COPYDigit11PPPIdealDiff|COPYDigit11PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3482|COPYDigit11PPPDistCircum|COPYDigit11PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3483|COPYDigit11PPPIsPersev|COPYDigit11PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3484|COPYDigit12PPPSeq|COPYDigit12PPPSeq|Num|8|BEST|11,471|2|11,471|||
|3485|COPYDigit12PPPStrokes|COPYDigit12PPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3486|COPYDigit12PPPTime|COPYDigit12PPPTime|Num|8|BEST|11,471|2|11,471|||
|3487|COPYDigit12PPPLen|COPYDigit12PPPLen|Num|8|BEST|11,471|2|11,471|||
|3488|COPYDigit12PPPCentX|COPYDigit12PPPCentX|Num|8|BEST|11,471|2|11,471|||
|3489|COPYDigit12PPPCentY|COPYDigit12PPPCentY|Num|8|BEST|11,471|2|11,471|||
|3490|COPYDigit12PPPWidth|COPYDigit12PPPWidth|Num|8|BEST|11,471|2|11,471|||
|3491|COPYDigit12PPPHgt|COPYDigit12PPPHgt|Num|8|BEST|11,471|2|11,471|||
|3492|COPYDigit12PPPNormHt|COPYDigit12PPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3493|COPYDigit12PPPOutside|COPYDigit12PPPOutside|Num|8|BEST|11,471|2|11,471|||
|3494|COPYDigit12PPPAngle|COPYDigit12PPPAngle|Num|8|BEST|11,471|2|11,471|||
|3495|COPYDigit12PPPIdealDiff|COPYDigit12PPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3496|COPYDigit12PPPDistCircum|COPYDigit12PPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3497|COPYDigit12PPPIsPersev|COPYDigit12PPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3498|COPYDigit1PPPPSeq|COPYDigit1PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3499|COPYDigit1PPPPStrokes|COPYDigit1PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3500|COPYDigit1PPPPTime|COPYDigit1PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3501|COPYDigit1PPPPLen|COPYDigit1PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3502|COPYDigit1PPPPCentX|COPYDigit1PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3503|COPYDigit1PPPPCentY|COPYDigit1PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3504|COPYDigit1PPPPWidth|COPYDigit1PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3505|COPYDigit1PPPPHgt|COPYDigit1PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3506|COPYDigit1PPPPNormHt|COPYDigit1PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3507|COPYDigit1PPPPOutside|COPYDigit1PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3508|COPYDigit1PPPPAngle|COPYDigit1PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3509|COPYDigit1PPPPIdealDiff|COPYDigit1PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3510|COPYDigit1PPPPDistCircum|COPYDigit1PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3511|COPYDigit1PPPPIsPersev|COPYDigit1PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3512|COPYDigit2PPPPSeq|COPYDigit2PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3513|COPYDigit2PPPPStrokes|COPYDigit2PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3514|COPYDigit2PPPPTime|COPYDigit2PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3515|COPYDigit2PPPPLen|COPYDigit2PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3516|COPYDigit2PPPPCentX|COPYDigit2PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3517|COPYDigit2PPPPCentY|COPYDigit2PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3518|COPYDigit2PPPPWidth|COPYDigit2PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3519|COPYDigit2PPPPHgt|COPYDigit2PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3520|COPYDigit2PPPPNormHt|COPYDigit2PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3521|COPYDigit2PPPPOutside|COPYDigit2PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3522|COPYDigit2PPPPAngle|COPYDigit2PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3523|COPYDigit2PPPPIdealDiff|COPYDigit2PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3524|COPYDigit2PPPPDistCircum|COPYDigit2PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3525|COPYDigit2PPPPIsPersev|COPYDigit2PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3526|COPYDigit3PPPPSeq|COPYDigit3PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3527|COPYDigit3PPPPStrokes|COPYDigit3PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3528|COPYDigit3PPPPTime|COPYDigit3PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3529|COPYDigit3PPPPLen|COPYDigit3PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3530|COPYDigit3PPPPCentX|COPYDigit3PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3531|COPYDigit3PPPPCentY|COPYDigit3PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3532|COPYDigit3PPPPWidth|COPYDigit3PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3533|COPYDigit3PPPPHgt|COPYDigit3PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3534|COPYDigit3PPPPNormHt|COPYDigit3PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3535|COPYDigit3PPPPOutside|COPYDigit3PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3536|COPYDigit3PPPPAngle|COPYDigit3PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3537|COPYDigit3PPPPIdealDiff|COPYDigit3PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3538|COPYDigit3PPPPDistCircum|COPYDigit3PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3539|COPYDigit3PPPPIsPersev|COPYDigit3PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3540|COPYDigit4PPPPSeq|COPYDigit4PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3541|COPYDigit4PPPPStrokes|COPYDigit4PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3542|COPYDigit4PPPPTime|COPYDigit4PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3543|COPYDigit4PPPPLen|COPYDigit4PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3544|COPYDigit4PPPPCentX|COPYDigit4PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3545|COPYDigit4PPPPCentY|COPYDigit4PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3546|COPYDigit4PPPPWidth|COPYDigit4PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3547|COPYDigit4PPPPHgt|COPYDigit4PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3548|COPYDigit4PPPPNormHt|COPYDigit4PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3549|COPYDigit4PPPPOutside|COPYDigit4PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3550|COPYDigit4PPPPAngle|COPYDigit4PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3551|COPYDigit4PPPPIdealDiff|COPYDigit4PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3552|COPYDigit4PPPPDistCircum|COPYDigit4PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3553|COPYDigit4PPPPIsPersev|COPYDigit4PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3554|COPYDigit5PPPPSeq|COPYDigit5PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3555|COPYDigit5PPPPStrokes|COPYDigit5PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3556|COPYDigit5PPPPTime|COPYDigit5PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3557|COPYDigit5PPPPLen|COPYDigit5PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3558|COPYDigit5PPPPCentX|COPYDigit5PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3559|COPYDigit5PPPPCentY|COPYDigit5PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3560|COPYDigit5PPPPWidth|COPYDigit5PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3561|COPYDigit5PPPPHgt|COPYDigit5PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3562|COPYDigit5PPPPNormHt|COPYDigit5PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3563|COPYDigit5PPPPOutside|COPYDigit5PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3564|COPYDigit5PPPPAngle|COPYDigit5PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3565|COPYDigit5PPPPIdealDiff|COPYDigit5PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3566|COPYDigit5PPPPDistCircum|COPYDigit5PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3567|COPYDigit5PPPPIsPersev|COPYDigit5PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3568|COPYDigit6PPPPSeq|COPYDigit6PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3569|COPYDigit6PPPPStrokes|COPYDigit6PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3570|COPYDigit6PPPPTime|COPYDigit6PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3571|COPYDigit6PPPPLen|COPYDigit6PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3572|COPYDigit6PPPPCentX|COPYDigit6PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3573|COPYDigit6PPPPCentY|COPYDigit6PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3574|COPYDigit6PPPPWidth|COPYDigit6PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3575|COPYDigit6PPPPHgt|COPYDigit6PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3576|COPYDigit6PPPPNormHt|COPYDigit6PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3577|COPYDigit6PPPPOutside|COPYDigit6PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3578|COPYDigit6PPPPAngle|COPYDigit6PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3579|COPYDigit6PPPPIdealDiff|COPYDigit6PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3580|COPYDigit6PPPPDistCircum|COPYDigit6PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3581|COPYDigit6PPPPIsPersev|COPYDigit6PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3582|COPYDigit7PPPPSeq|COPYDigit7PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3583|COPYDigit7PPPPStrokes|COPYDigit7PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3584|COPYDigit7PPPPTime|COPYDigit7PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3585|COPYDigit7PPPPLen|COPYDigit7PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3586|COPYDigit7PPPPCentX|COPYDigit7PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3587|COPYDigit7PPPPCentY|COPYDigit7PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3588|COPYDigit7PPPPWidth|COPYDigit7PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3589|COPYDigit7PPPPHgt|COPYDigit7PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3590|COPYDigit7PPPPNormHt|COPYDigit7PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3591|COPYDigit7PPPPOutside|COPYDigit7PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3592|COPYDigit7PPPPAngle|COPYDigit7PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3593|COPYDigit7PPPPIdealDiff|COPYDigit7PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3594|COPYDigit7PPPPDistCircum|COPYDigit7PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3595|COPYDigit7PPPPIsPersev|COPYDigit7PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3596|COPYDigit8PPPPSeq|COPYDigit8PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3597|COPYDigit8PPPPStrokes|COPYDigit8PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3598|COPYDigit8PPPPTime|COPYDigit8PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3599|COPYDigit8PPPPLen|COPYDigit8PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3600|COPYDigit8PPPPCentX|COPYDigit8PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3601|COPYDigit8PPPPCentY|COPYDigit8PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3602|COPYDigit8PPPPWidth|COPYDigit8PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3603|COPYDigit8PPPPHgt|COPYDigit8PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3604|COPYDigit8PPPPNormHt|COPYDigit8PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3605|COPYDigit8PPPPOutside|COPYDigit8PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3606|COPYDigit8PPPPAngle|COPYDigit8PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3607|COPYDigit8PPPPIdealDiff|COPYDigit8PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3608|COPYDigit8PPPPDistCircum|COPYDigit8PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3609|COPYDigit8PPPPIsPersev|COPYDigit8PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3610|COPYDigit9PPPPSeq|COPYDigit9PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3611|COPYDigit9PPPPStrokes|COPYDigit9PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3612|COPYDigit9PPPPTime|COPYDigit9PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3613|COPYDigit9PPPPLen|COPYDigit9PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3614|COPYDigit9PPPPCentX|COPYDigit9PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3615|COPYDigit9PPPPCentY|COPYDigit9PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3616|COPYDigit9PPPPWidth|COPYDigit9PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3617|COPYDigit9PPPPHgt|COPYDigit9PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3618|COPYDigit9PPPPNormHt|COPYDigit9PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3619|COPYDigit9PPPPOutside|COPYDigit9PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3620|COPYDigit9PPPPAngle|COPYDigit9PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3621|COPYDigit9PPPPIdealDiff|COPYDigit9PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3622|COPYDigit9PPPPDistCircum|COPYDigit9PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3623|COPYDigit9PPPPIsPersev|COPYDigit9PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3624|COPYDigit10PPPPSeq|COPYDigit10PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3625|COPYDigit10PPPPStrokes|COPYDigit10PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3626|COPYDigit10PPPPTime|COPYDigit10PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3627|COPYDigit10PPPPLen|COPYDigit10PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3628|COPYDigit10PPPPCentX|COPYDigit10PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3629|COPYDigit10PPPPCentY|COPYDigit10PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3630|COPYDigit10PPPPWidth|COPYDigit10PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3631|COPYDigit10PPPPHgt|COPYDigit10PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3632|COPYDigit10PPPPNormHt|COPYDigit10PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3633|COPYDigit10PPPPOutside|COPYDigit10PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3634|COPYDigit10PPPPAngle|COPYDigit10PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3635|COPYDigit10PPPPIdealDiff|COPYDigit10PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3636|COPYDigit10PPPPDistCircum|COPYDigit10PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3637|COPYDigit10PPPPIsPersev|COPYDigit10PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3638|COPYDigit11PPPPSeq|COPYDigit11PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3639|COPYDigit11PPPPStrokes|COPYDigit11PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3640|COPYDigit11PPPPTime|COPYDigit11PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3641|COPYDigit11PPPPLen|COPYDigit11PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3642|COPYDigit11PPPPCentX|COPYDigit11PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3643|COPYDigit11PPPPCentY|COPYDigit11PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3644|COPYDigit11PPPPWidth|COPYDigit11PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3645|COPYDigit11PPPPHgt|COPYDigit11PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3646|COPYDigit11PPPPNormHt|COPYDigit11PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3647|COPYDigit11PPPPOutside|COPYDigit11PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3648|COPYDigit11PPPPAngle|COPYDigit11PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3649|COPYDigit11PPPPIdealDiff|COPYDigit11PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3650|COPYDigit11PPPPDistCircum|COPYDigit11PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3651|COPYDigit11PPPPIsPersev|COPYDigit11PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3652|COPYDigit12PPPPSeq|COPYDigit12PPPPSeq|Num|8|BEST|11,471|2|11,471|||
|3653|COPYDigit12PPPPStrokes|COPYDigit12PPPPStrokes|Num|8|BEST|11,471|2|11,471|||
|3654|COPYDigit12PPPPTime|COPYDigit12PPPPTime|Num|8|BEST|11,471|2|11,471|||
|3655|COPYDigit12PPPPLen|COPYDigit12PPPPLen|Num|8|BEST|11,471|2|11,471|||
|3656|COPYDigit12PPPPCentX|COPYDigit12PPPPCentX|Num|8|BEST|11,471|2|11,471|||
|3657|COPYDigit12PPPPCentY|COPYDigit12PPPPCentY|Num|8|BEST|11,471|2|11,471|||
|3658|COPYDigit12PPPPWidth|COPYDigit12PPPPWidth|Num|8|BEST|11,471|2|11,471|||
|3659|COPYDigit12PPPPHgt|COPYDigit12PPPPHgt|Num|8|BEST|11,471|2|11,471|||
|3660|COPYDigit12PPPPNormHt|COPYDigit12PPPPNormHt|Num|8|BEST|11,471|2|11,471|||
|3661|COPYDigit12PPPPOutside|COPYDigit12PPPPOutside|Num|8|BEST|11,471|2|11,471|||
|3662|COPYDigit12PPPPAngle|COPYDigit12PPPPAngle|Num|8|BEST|11,471|2|11,471|||
|3663|COPYDigit12PPPPIdealDiff|COPYDigit12PPPPIdealDiff|Num|8|BEST|11,471|2|11,471|||
|3664|COPYDigit12PPPPDistCircum|COPYDigit12PPPPDistCircum|Num|8|BEST|11,471|2|11,471|||
|3665|COPYDigit12PPPPIsPersev|COPYDigit12PPPPIsPersev|Num|8|BEST|11,471|2|11,471|||
|3666|COPYInter-TestLatency|COPYInter-TestLatency|Num|8|BEST|11,471|173|91|||
|3667|COPYMocaOverallScore.85hand|COPYMocaOverallScore.85hand|Num|8|BEST|11,471|5|0|||
|3668|COPYmocaEccen|COPYmocaEccen|Num|8|BEST|11,471|11,324|147|||
|3669|COPYmocaMaxAngGap|COPYmocaMaxAngGap|Num|8|BEST|11,471|11,324|147|||
|3670|COPYmocaMaxDist|COPYmocaMaxDist|Num|8|BEST|11,471|2,357|147|||
|3671|COPYmocaEllResidNorm|COPYmocaEllResidNorm|Num|8|BEST|11,471|11,324|0|||
|3672|COPYmocaNumbsMissing|COPYmocaNumbsMissing|Num|8|BEST|11,471|3|0|||
|3673|COPYmocaNumbsReptd|COPYmocaNumbsReptd|Num|8|BEST|11,471|3|0|||
|3674|COPYmocaOver12|COPYmocaOver12|Num|8|BEST|11,471|3|0|||
|3675|COPYmocaSeqErr|COPYmocaSeqErr|Num|8|BEST|11,471|3|0|||
|3676|COPYmocaInWrongQuad|COPYmocaInWrongQuad|Num|8|BEST|11,471|3|0|||
|3677|COPYmocaNotTwoHands|COPYmocaNotTwoHands|Num|8|BEST|11,471|3|0|||
|3678|COPYmocaHH11Angle|COPYmocaHH11Angle|Num|8|BEST|11,471|11,021|449|||
|3679|COPYmocaMH2Angle|COPYmocaMH2Angle|Num|8|BEST|11,471|11,065|405|||
|3680|COPYmocaHandRatio|COPYmocaHandRatio|Num|8|BEST|11,471|11,134|337|||
|3681|COPYmocaHandInterToCtrDistNorm|COPYmocaHandInterToCtrDistNorm|Num|8|BEST|11,471|11,108|363|||
|3682|COPYmocaScoreUpToEQHands|COPYmocaScoreUpToEQHands|Num|8|BEST|11,471|5|0|||
|3683|COPYmocaScoreAnyHands|COPYmocaScoreAnyHands|Num|8|BEST|11,471|5|0|||
|3684|COMDigitWAISTestFormTestForm|COMDigitWAISTestFormTestForm|Char|1|$|0|1|0|||
|3685|COMVigilVigilKSlow|COMVigilVigilKSlow|Char|1|$|0|1|0|||
|3686|COMVigilVigilAKSlow|COMVigilVigilAKSlow|Char|1|$|0|1|0|||
|3687|COMVerbFlDKDEFSTestFormTestForm|COMVerbFlDKDEFSTestFormTestForm|Char|1|$|0|1|0|||
|3688|COMVerbFlDKDEFSNEWTestFormTestFo|COMVerbFlDKDEFSNEWTestFormTestForm|Char|1|$|0|1|0|||
|3689|COMSTROOPTestFormTestForm|COMSTROOPTestFormTestForm|Char|1|$|0|1|0|||
|3690|COMWRATTestFormTestForm|COMWRATTestFormTestForm|Char|1|$|0|1|0|||
|3691|COMHOOPERScoresNorm|COMHOOPERScoresNorm|Char|1|$|0|1|0|||
|3692|COMWMSFormTestForm|COMWMSFormTestForm|Char|1|$|0|1|0|||
|3693|COMCVLTIITestFormTestForm|COMCVLTIITestFormTestForm|Char|1|$|0|1|0|||
|3694|Bloods|Bloods|Char|1|$|0|1|0|||
|3695|blood_rt_RM_START_to_AN_START_mi|blood_rt_RM_START_to_AN_START_mins|Num|8|BEST|9,421|79|89|||
|3696|blood_rt_RM_START_to_INCISION_mi|blood_rt_RM_START_to_INCISION_mins|Num|8|BEST|9,296|152|0|||
|3697|blood_rt_RM_START_to_DRESS_mins|blood_rt_RM_START_to_DRESS_mins|Num|8|BEST|7,660|599|0|||
|3698|blood_rt_RM_START_to_AN_END_mins|blood_rt_RM_START_to_AN_END_mins|Num|8|BEST|9,421|639|0|||
|3699|blood_rt_RM_START_to_RM_END_mins|blood_rt_RM_START_to_RM_END_mins|Num|8|BEST|9,532|638|0|||
|3700|blood_APTT_LAB_DAYS_BEFORE_SURGE|blood_APTT_LAB_DAYS_BEFORE_SURGERY|Num|8|BEST|3,094|91|0|||
|3701|blood_APTT_LAB_RESULT_VALUE|blood_APTT_LAB_RESULT_VALUE|Char|4|$|3,094|52|0|||
|3702|blood_FIBRINOGEN_LAB_DAYS_BEFORE|blood_FIBRINOGEN_LAB_DAYS_BEFORE_SURGERY|Num|8|BEST|90|59|0|||
|3703|blood_FIBRINOGEN_LAB_RESULT_VALU|blood_FIBRINOGEN_LAB_RESULT_VALUE|Num|8|BEST|90|77|0|||
|3704|blood_HCT_LAB_DAYS_BEFORE_SURGER|blood_HCT_LAB_DAYS_BEFORE_SURGERY|Num|8|BEST|7,475|92|0|||
|3705|blood_HCT_LAB_RESULT_VALUE|blood_HCT_LAB_RESULT_VALUE|Num|8|BEST|7,473|314|0|||
|3706|blood_HEMOGLOBIN_LAB_DAYS_BEFORE|blood_HEMOGLOBIN_LAB_DAYS_BEFORE_SURGERY|Num|8|BEST|7,476|92|0|||
|3707|blood_HEMOGLOBIN_LAB_RESULT_VALU|blood_HEMOGLOBIN_LAB_RESULT_VALUE|Num|8|BEST|7,474|124|0|||
|3708|blood_PLATELET_COUNT_LAB_DAYS_BE|blood_PLATELET_COUNT_LAB_DAYS_BEFORE_SURGERY|Num|8|BEST|7,471|92|0|||
|3709|blood_PLATELET_COUNT_LAB_RESULT_|blood_PLATELET_COUNT_LAB_RESULT_VALUE|Num|8|BEST|7,467|486|0|||
|3710|blood_PROTIME_INR_LAB_DAYS_BEFOR|blood_PROTIME_INR_LAB_DAYS_BEFORE_SURGERY|Num|8|BEST|3,684|92|0|||
|3711|blood_PROTIME_INR_LAB_RESULT_VAL|blood_PROTIME_INR_LAB_RESULT_VALUE|Char|4|$|3,683|87|0|||
|3712|garvan_added_variables|garvan_added_variables|Char|1|$|0|1|0|||
|3713|garvan_magellan|garvan_magellan|Num|8|BEST|13,129|116|0|||
|3714|garvan_ACUTE|garvan_ACUTE|Num|8|BEST|5,565|3|0|||
|3715|garvan_INTENSIVE|garvan_INTENSIVE|Num|8|BEST|5,565|3|0|||
|3716|garvan_INTERMEDIATE|garvan_INTERMEDIATE|Num|8|BEST|5,565|3|0|||
|3717|garvan_icu|garvan_icu|Num|8|BEST|14,790|3|0|||
|3718|ron_extra_for_sabya|ron_extra_for_sabya|Char|1|$|0|1|0|||
|3719|ron_CPT 1|ron_CPT 1|Char|8|$|13,608|1,079|423|||
|3720|ron_CPT_1_DIGIT|ron_CPT_1_DIGIT|Char|1|$|13,608|13|423|||
|3721|ron_CPT_2_DIGIT|ron_CPT_2_DIGIT|Char|2|$|13,608|75|423|||
|3722|ron_CPT_3_DIGIT|ron_CPT_3_DIGIT|Char|3|$|13,608|305|423|||
|3723|ron_CPT_4_DIGIT|ron_CPT_4_DIGIT|Char|4|$|13,608|694|423|||
|3724|ron_Base Procedure Code 1|ron_Base Procedure Code 1|Char|10|$|13,608|1,237|0|||
|3725|ron_BPC_4_DIGIT|ron_BPC_4_DIGIT|Char|4|$|13,608|50|0|||
|3726|ron_BPC_5_DIGIT|ron_BPC_5_DIGIT|Char|5|$|13,608|60|0|||
|3727|ron_BPC_6_DIGIT|ron_BPC_6_DIGIT|Char|6|$|13,608|136|0|||
|3728|ron_BPC_7_DIGIT|ron_BPC_7_DIGIT|Char|7|$|13,608|589|0|||
|3729|LINUS|LINUS|Char|1|$|0|1|0|||
|3730|LINUS_DCTClassification|LINUS_DCTClassification|Num|8|BEST|11,505|5|0|||
|3731|LINUS_DCTClassificationString|LINUS_DCTClassificationString|Char|13|$|11,505|5|0|||
|3732|LINUS_DCTScore|LINUS_DCTScore|Num|8|BEST|11,243|10,479|0|||
|3733|LINUS_DCTScore_s|LINUS_DCTScore_s|Num|8|BEST|11,243|5,239|0|||
|3734|LINUS_COMAverageLatency|LINUS_COMAverageLatency|Num|8|BEST|11,487|2,278|0|||
|3735|LINUS_COPAverageLatency|LINUS_COPAverageLatency|Num|8|BEST|11,410|1,658|0|||
|3736|LINUS_COMAverageLatency_s|LINUS_COMAverageLatency_s|Num|8|BEST|11,487|4,475|0|||
|3737|LINUS_COPAverageLatency_s|LINUS_COPAverageLatency_s|Num|8|BEST|11,410|4,445|0|||
|3738|LINUS_COMAverageSpeed|LINUS_COMAverageSpeed|Num|8|BEST|11,392|10,992|0|||
|3739|LINUS_COPAverageSpeed|LINUS_COPAverageSpeed|Num|8|BEST|11,343|10,959|0|||
|3740|LINUS_COMAverageSpeed_s|LINUS_COMAverageSpeed_s|Num|8|BEST|11,392|4,829|0|||
|3741|LINUS_COPAverageSpeed_s|LINUS_COPAverageSpeed_s|Num|8|BEST|11,343|4,193|0|||
|3742|LINUS_COMAvgLatencyTime|LINUS_COMAvgLatencyTime|Num|8|BEST|11,487|2,278|0|||
|3743|LINUS_COPAvgLatencyTime|LINUS_COPAvgLatencyTime|Num|8|BEST|11,410|1,658|0|||
|3744|LINUS_COMAvgLatencyTimeL|LINUS_COMAvgLatencyTimeL|Num|8|BEST|11,487|1,264|0|||
|3745|LINUS_COPAvgLatencyTimeL|LINUS_COPAvgLatencyTimeL|Num|8|BEST|11,410|1,019|0|||
|3746|LINUS_COMAvgLatencyTimeL_s|LINUS_COMAvgLatencyTimeL_s|Num|8|BEST|11,487|4,475|0|||
|3747|LINUS_COPAvgLatencyTimeL_s|LINUS_COPAvgLatencyTimeL_s|Num|8|BEST|11,410|4,445|0|||
|3748|LINUS_COMAvgLatencyTime_s|LINUS_COMAvgLatencyTime_s|Num|8|BEST|11,487|4,272|0|||
|3749|LINUS_COPAvgLatencyTime_s|LINUS_COPAvgLatencyTime_s|Num|8|BEST|11,410|4,346|0|||
|3750|LINUS_COMAvgPnSpdOverall|LINUS_COMAvgPnSpdOverall|Num|8|BEST|11,392|10,992|0|||
|3751|LINUS_COPAvgPnSpdOverall|LINUS_COPAvgPnSpdOverall|Num|8|BEST|11,343|10,959|0|||
|3752|LINUS_COMAvgPnSpdOverallL|LINUS_COMAvgPnSpdOverallL|Num|8|BEST|11,392|2,665|0|||
|3753|LINUS_COPAvgPnSpdOverallL|LINUS_COPAvgPnSpdOverallL|Num|8|BEST|11,343|2,533|0|||
|3754|LINUS_COMAvgPnSpdOverallL_s|LINUS_COMAvgPnSpdOverallL_s|Num|8|BEST|11,392|4,829|0|||
|3755|LINUS_COPAvgPnSpdOverallL_s|LINUS_COPAvgPnSpdOverallL_s|Num|8|BEST|11,343|4,193|0|||
|3756|LINUS_COMAvgPnSpdOverall_s|LINUS_COMAvgPnSpdOverall_s|Num|8|BEST|11,392|3,548|0|||
|3757|LINUS_COPAvgPnSpdOverall_s|LINUS_COPAvgPnSpdOverall_s|Num|8|BEST|11,343|3,442|0|||
|3758|LINUS_COMAvgPnSpdQ1|LINUS_COMAvgPnSpdQ1|Num|8|BEST|11,392|10,944|0|||
|3759|LINUS_COPAvgPnSpdQ1|LINUS_COPAvgPnSpdQ1|Num|8|BEST|11,343|10,846|0|||
|3760|LINUS_COMAvgPnSpdQ1L|LINUS_COMAvgPnSpdQ1L|Num|8|BEST|11,392|2,731|0|||
|3761|LINUS_COPAvgPnSpdQ1L|LINUS_COPAvgPnSpdQ1L|Num|8|BEST|11,343|2,612|0|||
|3762|LINUS_COMAvgPnSpdQ1L_s|LINUS_COMAvgPnSpdQ1L_s|Num|8|BEST|11,392|4,702|0|||
|3763|LINUS_COPAvgPnSpdQ1L_s|LINUS_COPAvgPnSpdQ1L_s|Num|8|BEST|11,343|4,178|0|||
|3764|LINUS_COMAvgPnSpdQ1_s|LINUS_COMAvgPnSpdQ1_s|Num|8|BEST|11,392|3,349|0|||
|3765|LINUS_COPAvgPnSpdQ1_s|LINUS_COPAvgPnSpdQ1_s|Num|8|BEST|11,343|3,322|0|||
|3766|LINUS_COMAvgPnSpdQ4|LINUS_COMAvgPnSpdQ4|Num|8|BEST|11,392|11,025|0|||
|3767|LINUS_COPAvgPnSpdQ4|LINUS_COPAvgPnSpdQ4|Num|8|BEST|11,343|10,961|0|||
|3768|LINUS_COMAvgPnSpdQ4L|LINUS_COMAvgPnSpdQ4L|Num|8|BEST|11,392|2,942|0|||
|3769|LINUS_COPAvgPnSpdQ4L|LINUS_COPAvgPnSpdQ4L|Num|8|BEST|11,343|2,720|0|||
|3770|LINUS_COMAvgPnSpdQ4L_s|LINUS_COMAvgPnSpdQ4L_s|Num|8|BEST|11,392|4,674|0|||
|3771|LINUS_COPAvgPnSpdQ4L_s|LINUS_COPAvgPnSpdQ4L_s|Num|8|BEST|11,343|4,115|0|||
|3772|LINUS_COMAvgPnSpdQ4_s|LINUS_COMAvgPnSpdQ4_s|Num|8|BEST|11,392|3,323|0|||
|3773|LINUS_COPAvgPnSpdQ4_s|LINUS_COPAvgPnSpdQ4_s|Num|8|BEST|11,343|3,418|0|||
|3774|LINUS_COMClockSize|LINUS_COMClockSize|Num|8|BEST|11,491|10,520|0|||
|3775|LINUS_COPClockSize|LINUS_COPClockSize|Num|8|BEST|11,425|9,702|0|||
|3776|LINUS_COMClockSizeOneSided|LINUS_COMClockSizeOneSided|Num|8|BEST|11,491|7,200|0|||
|3777|LINUS_COPClockSizeOneSided|LINUS_COPClockSizeOneSided|Num|8|BEST|11,425|5,816|0|||
|3778|LINUS_COMClockSizeOneSided_s|LINUS_COMClockSizeOneSided_s|Num|8|BEST|11,491|5,459|0|||
|3779|LINUS_COPClockSizeOneSided_s|LINUS_COPClockSizeOneSided_s|Num|8|BEST|11,425|4,417|0|||
|3780|LINUS_COMClockSize_s|LINUS_COMClockSize_s|Num|8|BEST|11,491|4,086|0|||
|3781|LINUS_COPClockSize_s|LINUS_COPClockSize_s|Num|8|BEST|11,425|3,574|0|||
|3782|LINUS_COMClockfaceCircleResidual|LINUS_COMClockfaceCircleResidualNorm|Num|8|BEST|11,396|8,350|0|||
|3783|LINUS_COPClockfaceCircleResidual|LINUS_COPClockfaceCircleResidualNorm|Num|8|BEST|11,345|7,954|0|||
|3784|LINUS_COMClockfaceCircleResidu_1|LINUS_COMClockfaceCircleResidualNormL|Num|8|BEST|11,396|1,707|0|||
|3785|LINUS_COPClockfaceCircleResidu_1|LINUS_COPClockfaceCircleResidualNormL|Num|8|BEST|11,345|1,607|0|||
|3786|LINUS_COMClockfaceCircleResidu_2|LINUS_COMClockfaceCircleResidualNormL_s|Num|8|BEST|11,396|4,302|0|||
|3787|LINUS_COPClockfaceCircleResidu_2|LINUS_COPClockfaceCircleResidualNormL_s|Num|8|BEST|11,345|4,143|0|||
|3788|LINUS_COMClockfaceCircleResidu_3|LINUS_COMClockfaceCircleResidualNorm_s|Num|8|BEST|11,396|4,241|0|||
|3789|LINUS_COPClockfaceCircleResidu_3|LINUS_COPClockfaceCircleResidualNorm_s|Num|8|BEST|11,345|3,966|0|||
|3790|LINUS_COMClockfaceCircularity|LINUS_COMClockfaceCircularity|Num|8|BEST|11,396|1,707|0|||
|3791|LINUS_COPClockfaceCircularity|LINUS_COPClockfaceCircularity|Num|8|BEST|11,345|1,607|0|||
|3792|LINUS_COMClockfaceCircularity_s|LINUS_COMClockfaceCircularity_s|Num|8|BEST|11,396|4,302|0|||
|3793|LINUS_COPClockfaceCircularity_s|LINUS_COPClockfaceCircularity_s|Num|8|BEST|11,345|4,143|0|||
|3794|LINUS_COMComponentPlacement|LINUS_COMComponentPlacement|Num|8|BEST|11,504|829|0|||
|3795|LINUS_COPComponentPlacement|LINUS_COPComponentPlacement|Num|8|BEST|11,504|830|0|||
|3796|LINUS_COMComponentPlacement_s|LINUS_COMComponentPlacement_s|Num|8|BEST|11,504|5,212|0|||
|3797|LINUS_COPComponentPlacement_s|LINUS_COPComponentPlacement_s|Num|8|BEST|11,504|4,798|0|||
|3798|LINUS_COMCountLongLatencies|LINUS_COMCountLongLatencies|Num|8|BEST|11,487|20|0|||
|3799|LINUS_COPCountLongLatencies|LINUS_COPCountLongLatencies|Num|8|BEST|11,410|27|0|||
|3800|LINUS_COMCountLongLatenciesL|LINUS_COMCountLongLatenciesL|Num|8|BEST|11,487|20|0|||
|3801|LINUS_COPCountLongLatenciesL|LINUS_COPCountLongLatenciesL|Num|8|BEST|11,410|27|0|||
|3802|LINUS_COMCountLongLatenciesL_s|LINUS_COMCountLongLatenciesL_s|Num|8|BEST|11,487|43|0|||
|3803|LINUS_COPCountLongLatenciesL_s|LINUS_COPCountLongLatenciesL_s|Num|8|BEST|11,410|58|0|||
|3804|LINUS_COMCountLongLatencies_s|LINUS_COMCountLongLatencies_s|Num|8|BEST|11,487|43|0|||
|3805|LINUS_COPCountLongLatencies_s|LINUS_COPCountLongLatencies_s|Num|8|BEST|11,410|58|0|||
|3806|LINUS_COMDisplay|LINUS_COMDisplay|Num|8|BEST|11,504|3|0|||
|3807|LINUS_COPDisplay|LINUS_COPDisplay|Num|8|BEST|11,504|3|0|||
|3808|LINUS_COMDistancePaperCenter|LINUS_COMDistancePaperCenter|Num|8|BEST|11,396|10,378|0|||
|3809|LINUS_COPDistancePaperCenter|LINUS_COPDistancePaperCenter|Num|8|BEST|11,345|9,945|0|||
|3810|LINUS_COMDistancePaperCenter_s|LINUS_COMDistancePaperCenter_s|Num|8|BEST|11,396|5,736|0|||
|3811|LINUS_COPDistancePaperCenter_s|LINUS_COPDistancePaperCenter_s|Num|8|BEST|11,345|4,817|0|||
|3812|LINUS_COMDrawingEfficiency|LINUS_COMDrawingEfficiency|Num|8|BEST|11,491|10,447|0|||
|3813|LINUS_COPDrawingEfficiency|LINUS_COPDrawingEfficiency|Num|8|BEST|11,412|9,996|0|||
|3814|LINUS_COMDrawingEfficiency_s|LINUS_COMDrawingEfficiency_s|Num|8|BEST|11,491|5,621|0|||
|3815|LINUS_COPDrawingEfficiency_s|LINUS_COPDrawingEfficiency_s|Num|8|BEST|11,412|5,021|0|||
|3816|LINUS_COMDrawingProcessEfficienc|LINUS_COMDrawingProcessEfficiency|Num|8|BEST|11,491|8,530|0|||
|3817|LINUS_COPDrawingProcessEfficienc|LINUS_COPDrawingProcessEfficiency|Num|8|BEST|11,412|8,516|0|||
|3818|LINUS_COMDrawingProcessEfficie_1|LINUS_COMDrawingProcessEfficiency_s|Num|8|BEST|11,491|3,539|0|||
|3819|LINUS_COPDrawingProcessEfficie_1|LINUS_COPDrawingProcessEfficiency_s|Num|8|BEST|11,412|3,560|0|||
|3820|LINUS_COMDrawingSize|LINUS_COMDrawingSize|Num|8|BEST|11,491|10,520|0|||
|3821|LINUS_COPDrawingSize|LINUS_COPDrawingSize|Num|8|BEST|11,425|9,702|0|||
|3822|LINUS_COMDrawingSize_s|LINUS_COMDrawingSize_s|Num|8|BEST|11,491|4,086|0|||
|3823|LINUS_COPDrawingSize_s|LINUS_COPDrawingSize_s|Num|8|BEST|11,425|3,574|0|||
|3824|LINUS_COMDwgTotStrokesConformity|LINUS_COMDwgTotStrokesConformity|Num|8|BEST|11,491|61|0|||
|3825|LINUS_COPDwgTotStrokesConformity|LINUS_COPDwgTotStrokesConformity|Num|8|BEST|11,412|54|0|||
|3826|LINUS_COMDwgTotStrokesConformi_1|LINUS_COMDwgTotStrokesConformityL|Num|8|BEST|11,491|61|0|||
|3827|LINUS_COPDwgTotStrokesConformi_1|LINUS_COPDwgTotStrokesConformityL|Num|8|BEST|11,412|54|0|||
|3828|LINUS_COMDwgTotStrokesConformi_2|LINUS_COMDwgTotStrokesConformityL_s|Num|8|BEST|11,491|125|0|||
|3829|LINUS_COPDwgTotStrokesConformi_2|LINUS_COPDwgTotStrokesConformityL_s|Num|8|BEST|11,412|101|0|||
|3830|LINUS_COMDwgTotStrokesConformi_3|LINUS_COMDwgTotStrokesConformity_s|Num|8|BEST|11,491|124|0|||
|3831|LINUS_COPDwgTotStrokesConformi_3|LINUS_COPDwgTotStrokesConformity_s|Num|8|BEST|11,412|101|0|||
|3832|LINUS_COMDwgTotTime|LINUS_COMDwgTotTime|Num|8|BEST|11,491|10,294|0|||
|3833|LINUS_COPDwgTotTime|LINUS_COPDwgTotTime|Num|8|BEST|11,412|9,802|0|||
|3834|LINUS_COMDwgTotTimeL|LINUS_COMDwgTotTimeL|Num|8|BEST|11,491|2,066|0|||
|3835|LINUS_COPDwgTotTimeL|LINUS_COPDwgTotTimeL|Num|8|BEST|11,412|1,848|0|||
|3836|LINUS_COMDwgTotTimeL_s|LINUS_COMDwgTotTimeL_s|Num|8|BEST|11,491|4,446|0|||
|3837|LINUS_COPDwgTotTimeL_s|LINUS_COPDwgTotTimeL_s|Num|8|BEST|11,412|4,395|0|||
|3838|LINUS_COMDwgTotTime_s|LINUS_COMDwgTotTime_s|Num|8|BEST|11,491|3,819|0|||
|3839|LINUS_COPDwgTotTime_s|LINUS_COPDwgTotTime_s|Num|8|BEST|11,412|3,976|0|||
|3840|LINUS_COMHorizontalSpatialPlacem|LINUS_COMHorizontalSpatialPlacement|Num|8|BEST|11,396|9,088|0|||
|3841|LINUS_COPHorizontalSpatialPlacem|LINUS_COPHorizontalSpatialPlacement|Num|8|BEST|11,345|7,286|0|||
|3842|LINUS_COMHorizontalSpatialPlac_1|LINUS_COMHorizontalSpatialPlacement_s|Num|8|BEST|11,396|5,538|<11|||
|3843|LINUS_COPHorizontalSpatialPlac_1|LINUS_COPHorizontalSpatialPlacement_s|Num|8|BEST|11,345|3,682|0|||
|3844|LINUS_COMInformationProcessing|LINUS_COMInformationProcessing|Num|8|BEST|11,487|9,812|0|||
|3845|LINUS_COPInformationProcessing|LINUS_COPInformationProcessing|Num|8|BEST|11,410|9,957|0|||
|3846|LINUS_COMInformationProcessing_s|LINUS_COMInformationProcessing_s|Num|8|BEST|11,487|4,209|0|||
|3847|LINUS_COPInformationProcessing_s|LINUS_COPInformationProcessing_s|Num|8|BEST|11,410|4,204|0|||
|3848|LINUS_COMInitiationSpeed|LINUS_COMInitiationSpeed|Num|8|BEST|11,392|10,944|0|||
|3849|LINUS_COPInitiationSpeed|LINUS_COPInitiationSpeed|Num|8|BEST|11,343|10,846|0|||
|3850|LINUS_COMInitiationSpeed_s|LINUS_COMInitiationSpeed_s|Num|8|BEST|11,392|4,702|0|||
|3851|LINUS_COPInitiationSpeed_s|LINUS_COPInitiationSpeed_s|Num|8|BEST|11,343|4,178|0|||
|3852|LINUS_COMInkLength|LINUS_COMInkLength|Num|8|BEST|11,504|11,375|0|||
|3853|LINUS_COPInkLength|LINUS_COPInkLength|Num|8|BEST|11,504|11,183|0|||
|3854|LINUS_COMInkLength_s|LINUS_COMInkLength_s|Num|8|BEST|11,504|3,566|0|||
|3855|LINUS_COPInkLength_s|LINUS_COPInkLength_s|Num|8|BEST|11,504|3,556|0|||
|3856|LINUS_COMLatencyVariability|LINUS_COMLatencyVariability|Num|8|BEST|11,487|3,579|0|||
|3857|LINUS_COPLatencyVariability|LINUS_COPLatencyVariability|Num|8|BEST|11,410|2,120|0|||
|3858|LINUS_COMLatencyVariability_s|LINUS_COMLatencyVariability_s|Num|8|BEST|11,487|4,185|0|||
|3859|LINUS_COPLatencyVariability_s|LINUS_COPLatencyVariability_s|Num|8|BEST|11,410|4,141|0|||
|3860|LINUS_COMLongLatencyCount|LINUS_COMLongLatencyCount|Num|8|BEST|11,487|20|0|||
|3861|LINUS_COPLongLatencyCount|LINUS_COPLongLatencyCount|Num|8|BEST|11,410|27|0|||
|3862|LINUS_COMLongLatencyCount_s|LINUS_COMLongLatencyCount_s|Num|8|BEST|11,487|43|0|||
|3863|LINUS_COPLongLatencyCount_s|LINUS_COPLongLatencyCount_s|Num|8|BEST|11,410|58|0|||
|3864|LINUS_COMLongestLatency|LINUS_COMLongestLatency|Num|8|BEST|11,487|7,533|0|||
|3865|LINUS_COPLongestLatency|LINUS_COPLongestLatency|Num|8|BEST|11,410|5,113|0|||
|3866|LINUS_COMLongestLatencyTime|LINUS_COMLongestLatencyTime|Num|8|BEST|11,487|7,533|0|||
|3867|LINUS_COPLongestLatencyTime|LINUS_COPLongestLatencyTime|Num|8|BEST|11,410|5,113|0|||
|3868|LINUS_COMLongestLatencyTimeL|LINUS_COMLongestLatencyTimeL|Num|8|BEST|11,487|2,616|0|||
|3869|LINUS_COPLongestLatencyTimeL|LINUS_COPLongestLatencyTimeL|Num|8|BEST|11,410|2,118|0|||
|3870|LINUS_COMLongestLatencyTimeL_s|LINUS_COMLongestLatencyTimeL_s|Num|8|BEST|11,487|4,233|0|||
|3871|LINUS_COPLongestLatencyTimeL_s|LINUS_COPLongestLatencyTimeL_s|Num|8|BEST|11,410|4,067|0|||
|3872|LINUS_COMLongestLatencyTime_s|LINUS_COMLongestLatencyTime_s|Num|8|BEST|11,487|3,359|0|||
|3873|LINUS_COPLongestLatencyTime_s|LINUS_COPLongestLatencyTime_s|Num|8|BEST|11,410|3,540|0|||
|3874|LINUS_COMLongestLatency_s|LINUS_COMLongestLatency_s|Num|8|BEST|11,487|4,233|0|||
|3875|LINUS_COPLongestLatency_s|LINUS_COPLongestLatency_s|Num|8|BEST|11,410|4,067|0|||
|3876|LINUS_COMMaxPnSpdOverall|LINUS_COMMaxPnSpdOverall|Num|8|BEST|11,392|11,153|0|||
|3877|LINUS_COPMaxPnSpdOverall|LINUS_COPMaxPnSpdOverall|Num|8|BEST|11,343|11,066|0|||
|3878|LINUS_COMMaxPnSpdOverallL|LINUS_COMMaxPnSpdOverallL|Num|8|BEST|11,392|2,338|0|||
|3879|LINUS_COPMaxPnSpdOverallL|LINUS_COPMaxPnSpdOverallL|Num|8|BEST|11,343|2,167|0|||
|3880|LINUS_COMMaxPnSpdOverallL_s|LINUS_COMMaxPnSpdOverallL_s|Num|8|BEST|11,392|4,659|0|||
|3881|LINUS_COPMaxPnSpdOverallL_s|LINUS_COPMaxPnSpdOverallL_s|Num|8|BEST|11,343|3,895|0|||
|3882|LINUS_COMMaxPnSpdOverall_s|LINUS_COMMaxPnSpdOverall_s|Num|8|BEST|11,392|3,582|0|||
|3883|LINUS_COPMaxPnSpdOverall_s|LINUS_COPMaxPnSpdOverall_s|Num|8|BEST|11,343|3,451|0|||
|3884|LINUS_COMMaxSpeed|LINUS_COMMaxSpeed|Num|8|BEST|11,392|11,153|0|||
|3885|LINUS_COPMaxSpeed|LINUS_COPMaxSpeed|Num|8|BEST|11,343|11,066|0|||
|3886|LINUS_COMMaxSpeed_s|LINUS_COMMaxSpeed_s|Num|8|BEST|11,392|4,659|0|||
|3887|LINUS_COPMaxSpeed_s|LINUS_COPMaxSpeed_s|Num|8|BEST|11,343|3,895|0|||
|3888|LINUS_COMNoise|LINUS_COMNoise|Num|8|BEST|11,504|237|0|||
|3889|LINUS_COPNoise|LINUS_COPNoise|Num|8|BEST|11,504|176|0|||
|3890|LINUS_COMNoise_s|LINUS_COMNoise_s|Num|8|BEST|11,504|458|0|||
|3891|LINUS_COPNoise_s|LINUS_COPNoise_s|Num|8|BEST|11,504|279|0|||
|3892|LINUS_COMOscillatoryMotion|LINUS_COMOscillatoryMotion|Num|8|BEST|11,396|4,045|0|||
|3893|LINUS_COPOscillatoryMotion|LINUS_COPOscillatoryMotion|Num|8|BEST|11,345|3,727|0|||
|3894|LINUS_COMOscillatoryMotion_s|LINUS_COMOscillatoryMotion_s|Num|8|BEST|11,396|4,362|0|||
|3895|LINUS_COPOscillatoryMotion_s|LINUS_COPOscillatoryMotion_s|Num|8|BEST|11,345|3,955|0|||
|3896|LINUS_COMPctInkTime|LINUS_COMPctInkTime|Num|8|BEST|11,491|9,823|0|||
|3897|LINUS_COPPctInkTime|LINUS_COPPctInkTime|Num|8|BEST|11,412|9,549|0|||
|3898|LINUS_COMPctInkTimeOneSided|LINUS_COMPctInkTimeOneSided|Num|8|BEST|11,491|2,430|0|||
|3899|LINUS_COPPctInkTimeOneSided|LINUS_COPPctInkTimeOneSided|Num|8|BEST|11,412|1,845|0|||
|3900|LINUS_COMPctInkTimeOneSided_s|LINUS_COMPctInkTimeOneSided_s|Num|8|BEST|11,491|2,127|0|||
|3901|LINUS_COPPctInkTimeOneSided_s|LINUS_COPPctInkTimeOneSided_s|Num|8|BEST|11,412|1,658|0|||
|3902|LINUS_COMPctInkTime_s|LINUS_COMPctInkTime_s|Num|8|BEST|11,491|4,307|0|||
|3903|LINUS_COPPctInkTime_s|LINUS_COPPctInkTime_s|Num|8|BEST|11,412|4,209|0|||
|3904|LINUS_COMPctThinkTime|LINUS_COMPctThinkTime|Num|8|BEST|11,491|9,819|0|||
|3905|LINUS_COPPctThinkTime|LINUS_COPPctThinkTime|Num|8|BEST|11,412|9,551|0|||
|3906|LINUS_COMPctThinkTimeOneSided|LINUS_COMPctThinkTimeOneSided|Num|8|BEST|11,491|2,834|0|||
|3907|LINUS_COPPctThinkTimeOneSided|LINUS_COPPctThinkTimeOneSided|Num|8|BEST|11,412|3,069|0|||
|3908|LINUS_COMPctThinkTimeOneSided_s|LINUS_COMPctThinkTimeOneSided_s|Num|8|BEST|11,491|2,295|0|||
|3909|LINUS_COPPctThinkTimeOneSided_s|LINUS_COPPctThinkTimeOneSided_s|Num|8|BEST|11,412|2,500|0|||
|3910|LINUS_COMPctThinkTime_s|LINUS_COMPctThinkTime_s|Num|8|BEST|11,491|4,307|0|||
|3911|LINUS_COPPctThinkTime_s|LINUS_COPPctThinkTime_s|Num|8|BEST|11,412|4,209|0|||
|3912|LINUS_COMPercentInkTime|LINUS_COMPercentInkTime|Num|8|BEST|11,491|9,823|0|||
|3913|LINUS_COPPercentInkTime|LINUS_COPPercentInkTime|Num|8|BEST|11,412|9,549|0|||
|3914|LINUS_COMPercentInkTime_s|LINUS_COMPercentInkTime_s|Num|8|BEST|11,491|4,307|0|||
|3915|LINUS_COPPercentInkTime_s|LINUS_COPPercentInkTime_s|Num|8|BEST|11,412|4,209|0|||
|3916|LINUS_COMPercentThinkTime|LINUS_COMPercentThinkTime|Num|8|BEST|11,491|9,819|0|||
|3917|LINUS_COPPercentThinkTime|LINUS_COPPercentThinkTime|Num|8|BEST|11,412|9,551|0|||
|3918|LINUS_COMPercentThinkTime_s|LINUS_COMPercentThinkTime_s|Num|8|BEST|11,491|4,307|0|||
|3919|LINUS_COPPercentThinkTime_s|LINUS_COPPercentThinkTime_s|Num|8|BEST|11,412|4,209|0|||
|3920|LINUS_COMPnEnergy|LINUS_COMPnEnergy|Num|8|BEST|11,396|4,045|0|||
|3921|LINUS_COPPnEnergy|LINUS_COPPnEnergy|Num|8|BEST|11,345|3,727|0|||
|3922|LINUS_COMPnEnergy_s|LINUS_COMPnEnergy_s|Num|8|BEST|11,396|4,362|0|||
|3923|LINUS_COPPnEnergy_s|LINUS_COPPnEnergy_s|Num|8|BEST|11,345|3,955|0|||
|3924|LINUS_COMRelativeLongLatency|LINUS_COMRelativeLongLatency|Num|8|BEST|11,487|8,525|0|||
|3925|LINUS_COPRelativeLongLatency|LINUS_COPRelativeLongLatency|Num|8|BEST|11,410|6,680|0|||
|3926|LINUS_COMRelativeLongLatencyTime|LINUS_COMRelativeLongLatencyTime|Num|8|BEST|11,487|8,525|0|||
|3927|LINUS_COPRelativeLongLatencyTime|LINUS_COPRelativeLongLatencyTime|Num|8|BEST|11,410|6,680|0|||
|3928|LINUS_COMRelativeLongLatencyTi_1|LINUS_COMRelativeLongLatencyTimeL|Num|8|BEST|11,487|2,709|0|||
|3929|LINUS_COPRelativeLongLatencyTi_1|LINUS_COPRelativeLongLatencyTimeL|Num|8|BEST|11,410|2,232|0|||
|3930|LINUS_COMRelativeLongLatencyTi_2|LINUS_COMRelativeLongLatencyTimeL_s|Num|8|BEST|11,487|4,324|0|||
|3931|LINUS_COPRelativeLongLatencyTi_2|LINUS_COPRelativeLongLatencyTimeL_s|Num|8|BEST|11,410|4,268|0|||
|3932|LINUS_COMRelativeLongLatencyTi_3|LINUS_COMRelativeLongLatencyTime_s|Num|8|BEST|11,487|3,282|0|||
|3933|LINUS_COPRelativeLongLatencyTi_3|LINUS_COPRelativeLongLatencyTime_s|Num|8|BEST|11,410|3,778|0|||
|3934|LINUS_COMRelativeLongLatency_s|LINUS_COMRelativeLongLatency_s|Num|8|BEST|11,487|4,324|0|||
|3935|LINUS_COPRelativeLongLatency_s|LINUS_COPRelativeLongLatency_s|Num|8|BEST|11,410|4,268|0|||
|3936|LINUS_COMSimpleMotor|LINUS_COMSimpleMotor|Num|8|BEST|11,392|9,937|0|||
|3937|LINUS_COPSimpleMotor|LINUS_COPSimpleMotor|Num|8|BEST|11,343|9,269|0|||
|3938|LINUS_COMSimpleMotor_s|LINUS_COMSimpleMotor_s|Num|8|BEST|11,392|5,005|0|||
|3939|LINUS_COPSimpleMotor_s|LINUS_COPSimpleMotor_s|Num|8|BEST|11,343|4,351|0|||
|3940|LINUS_COMSpatialReasoning|LINUS_COMSpatialReasoning|Num|8|BEST|11,396|10,625|0|||
|3941|LINUS_COPSpatialReasoning|LINUS_COPSpatialReasoning|Num|8|BEST|11,345|10,601|0|||
|3942|LINUS_COMSpatialReasoning_s|LINUS_COMSpatialReasoning_s|Num|8|BEST|11,396|4,964|0|||
|3943|LINUS_COPSpatialReasoning_s|LINUS_COPSpatialReasoning_s|Num|8|BEST|11,345|4,530|0|||
|3944|LINUS_COMStdvLatencyTime|LINUS_COMStdvLatencyTime|Num|8|BEST|11,487|3,579|0|||
|3945|LINUS_COPStdvLatencyTime|LINUS_COPStdvLatencyTime|Num|8|BEST|11,410|2,120|0|||
|3946|LINUS_COMStdvLatencyTimeL|LINUS_COMStdvLatencyTimeL|Num|8|BEST|11,487|1,813|0|||
|3947|LINUS_COPStdvLatencyTimeL|LINUS_COPStdvLatencyTimeL|Num|8|BEST|11,410|1,342|0|||
|3948|LINUS_COMStdvLatencyTimeL_s|LINUS_COMStdvLatencyTimeL_s|Num|8|BEST|11,487|4,185|0|||
|3949|LINUS_COPStdvLatencyTimeL_s|LINUS_COPStdvLatencyTimeL_s|Num|8|BEST|11,410|4,141|0|||
|3950|LINUS_COMStdvLatencyTime_s|LINUS_COMStdvLatencyTime_s|Num|8|BEST|11,487|3,606|0|||
|3951|LINUS_COPStdvLatencyTime_s|LINUS_COPStdvLatencyTime_s|Num|8|BEST|11,410|3,843|0|||
|3952|LINUS_COMStrokeCountConformity|LINUS_COMStrokeCountConformity|Num|8|BEST|11,491|61|0|||
|3953|LINUS_COPStrokeCountConformity|LINUS_COPStrokeCountConformity|Num|8|BEST|11,412|54|0|||
|3954|LINUS_COMStrokeCountConformity_s|LINUS_COMStrokeCountConformity_s|Num|8|BEST|11,491|124|0|||
|3955|LINUS_COPStrokeCountConformity_s|LINUS_COPStrokeCountConformity_s|Num|8|BEST|11,412|101|0|||
|3956|LINUS_COMTerminationSpeed|LINUS_COMTerminationSpeed|Num|8|BEST|11,392|11,025|0|||
|3957|LINUS_COPTerminationSpeed|LINUS_COPTerminationSpeed|Num|8|BEST|11,343|10,961|0|||
|3958|LINUS_COMTerminationSpeed_s|LINUS_COMTerminationSpeed_s|Num|8|BEST|11,392|4,674|0|||
|3959|LINUS_COPTerminationSpeed_s|LINUS_COPTerminationSpeed_s|Num|8|BEST|11,343|4,115|0|||
|3960|LINUS_COMTotInkLengthCC|LINUS_COMTotInkLengthCC|Num|8|BEST|11,504|11,375|0|||
|3961|LINUS_COPTotInkLengthCC|LINUS_COPTotInkLengthCC|Num|8|BEST|11,504|11,183|0|||
|3962|LINUS_COMTotInkLengthCC_s|LINUS_COMTotInkLengthCC_s|Num|8|BEST|11,504|3,566|0|||
|3963|LINUS_COPTotInkLengthCC_s|LINUS_COPTotInkLengthCC_s|Num|8|BEST|11,504|3,556|0|||
|3964|LINUS_COMTotalTime|LINUS_COMTotalTime|Num|8|BEST|11,491|10,294|0|||
|3965|LINUS_COPTotalTime|LINUS_COPTotalTime|Num|8|BEST|11,412|9,802|0|||
|3966|LINUS_COMTotalTime_s|LINUS_COMTotalTime_s|Num|8|BEST|11,491|4,446|0|||
|3967|LINUS_COPTotalTime_s|LINUS_COPTotalTime_s|Num|8|BEST|11,412|4,395|0|||
|3968|LINUS_COMVerticalSpatialPlacemen|LINUS_COMVerticalSpatialPlacement|Num|8|BEST|11,396|10,242|0|||
|3969|LINUS_COPVerticalSpatialPlacemen|LINUS_COPVerticalSpatialPlacement|Num|8|BEST|11,345|9,973|0|||
|3970|LINUS_COMVerticalSpatialPlacem_1|LINUS_COMVerticalSpatialPlacement_s|Num|8|BEST|11,396|5,473|0|||
|3971|LINUS_COPVerticalSpatialPlacem_1|LINUS_COPVerticalSpatialPlacement_s|Num|8|BEST|11,345|4,658|0|||
|3972|LINUS_COMXDistancePaperCenter|LINUS_COMXDistancePaperCenter|Num|8|BEST|11,396|9,088|0|||
|3973|LINUS_COPXDistancePaperCenter|LINUS_COPXDistancePaperCenter|Num|8|BEST|11,345|7,286|0|||
|3974|LINUS_COMXDistancePaperCenter_s|LINUS_COMXDistancePaperCenter_s|Num|8|BEST|11,396|5,538|<11|||
|3975|LINUS_COPXDistancePaperCenter_s|LINUS_COPXDistancePaperCenter_s|Num|8|BEST|11,345|3,682|0|||
|3976|LINUS_COMYDistancePaperCenter|LINUS_COMYDistancePaperCenter|Num|8|BEST|11,396|10,242|0|||
|3977|LINUS_COPYDistancePaperCenter|LINUS_COPYDistancePaperCenter|Num|8|BEST|11,345|9,973|0|||
|3978|LINUS_COMYDistancePaperCenter_s|LINUS_COMYDistancePaperCenter_s|Num|8|BEST|11,396|5,473|0|||
|3979|LINUS_COPYDistancePaperCenter_s|LINUS_COPYDistancePaperCenter_s|Num|8|BEST|11,345|4,658|0|||
|3980|magellan|magellan|Num|8|BEST|13,130|116|0|||
|3981|cam|cam|Num|8|BEST|2,087|4|0|||
|3982|sex_cat|sex_cat|Char|6|$|14,722|3|0|||
|3983|handedness_cat|handedness_cat|Char|12|$|10,776|4|0|||
|3984|Service_PT|Service_PT|Char|24|$|13,607|7|0|||
|3985|average_pain|average_pain|Num|8|BEST|12,942|3,234|0|||
|3986|SSDI Death Y/N|SSDI Death Y/N|Char|1|$|717|3|0|||
|3987|Death_Days_After_Surgery|Death_Days_After_Surgery|Num|8|BEST|717|316|0|||

## Unit 7: 2018_2019_X_MASTER_DATASET_20200801.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|14,778|14,778|0||yes|
|2|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|41|$|14,777|13,045|0||yes|
|3|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|46|$|14,559|14,348|0||yes|
|4|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|13,481|616|<11|||
|5|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|13,608|595|0|||
|6|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|13,478|764|<11|||
|7|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|13,050|772|0|||
|8|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|13,048|1,127|0|||
|9|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|2,740|381|0|||
|10|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|2,740|395|0|||
|11|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|13,195|780|0|||
|12|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|13,177|1,124|0|||
|13|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|12,870|803|<11|||
|14|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|10,595|1,070|<11|||
|15|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|10,341|583|0|||
|16|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|13,252|677|0|||
|17|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|10,637|645|0|||
|18|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|13,106|88|139|||
|19|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|12,927|160|0|||
|20|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|13,113|690|0|||
|21|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|2,744|78|0|||
|22|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|13,608|8|0|||
|23|Holidays|Holidays|Char|1|$|13,274|3|0|||
|24|Weekend_Indicator|Weekend_Indicator|Char|1|$|13,608|3|0|||
|25|Age at Encounter|Age at Encounter|Num|8|BEST|13,608|27|0||yes|
|26|EmployeeStatus|EmployeeStatus|Char|23|$|14,778|10|2,177|||
|27|Education|Education|Char|19|$|296|7|0|||
|28|Race|Race|Char|16|$|13,608|11|73|||
|29|Ethnicity|Ethnicity|Char|15|$|13,608|5|88|||
|30|Sex|Sex|Char|6|$|13,608|3|0|||
|31|Marital Status|Marital Status|Char|22|$|13,608|9|1,264|||
|32|Admit BMI|Admit BMI|Num|8|BEST|5,323|3,818|0|||
|33|Service|Service|Char|32|$|13,608|32|0|||
|34|Room Type|Room Type|Char|21|$|13,602|15|0|||
|35|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|12,665|6|0|||
|36|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|13,608|3|0|||
|37|Base Procedure 1|Base Procedure 1|Char|200|$|13,608|1,237|0|||
|38|Base Procedure Code 1|Base Procedure Code 1|Char|10|$|13,608|1,237|0|||
|39|CPT 1|CPT 1|Char|8|$|13,608|1,079|423|||
|40|CPT 1 Description|CPT 1 Description|Char|75|$|13,608|1,079|0|||
|41|Patient Type|Patient Type|Char|18|$|13,608|5|0|||
|42|LOS|LOS|Num|8|BEST|13,481|53|0|||
|43|LOS in Hours|LOS in Hours|Num|8|BEST|5,561|3,670|0|||
|44|Payer|Payer|Char|12|$|13,481|13|0|||
|45|Charges|Charges|Num|8|BEST|13,476|13,083|0|||
|46|ICD10 Principal Diagnosis Desc|ICD10 Principal Diagnosis Desc|Char|62|$|13,374|1,967|0|||
|47|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|13,374|1,967|0|||
|48|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|13,373|17|0|||
|49|COMP10_T80|COMP10_T80|Num|8|BEST|14,778|2|0|||
|50|COMP10_T81|COMP10_T81|Num|8|BEST|14,778|3|0|||
|51|COMP10_T82|COMP10_T82|Num|8|BEST|14,778|5|0|||
|52|COMP10_T83|COMP10_T83|Num|8|BEST|14,778|3|0|||
|53|COMP10_T84|COMP10_T84|Num|8|BEST|14,778|5|0|||
|54|COMP10_T85|COMP10_T85|Num|8|BEST|14,778|3|0|||
|55|COMP10_T86|COMP10_T86|Num|8|BEST|14,778|3|0|||
|56|COMP10_T87|COMP10_T87|Num|8|BEST|14,778|2|0|||
|57|COMP10_T88|COMP10_T88|Num|8|BEST|14,778|3|0|||
|58|complication_sum|complication_sum|Num|8|BEST|14,778|5|0|||
|59|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|1,112|2|0|||
|60|Preop_block|Preop_block|Char|1|$|2,744|2|0|||
|61|Admit Source|Admit Source|Char|40|$|13,481|8|<11|||
|62|Dischg Disposition|Dischg Disposition|Char|42|$|13,481|24|<11|||
|63|30_DAY_MORTALITY|30_DAY_MORTALITY|Char|1|$|13,487|3|0|||
|64|Death_Date Y/N|Death_Date Y/N|Char|1|$|13,487|3|0|||
|65|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|13,487|3|0|||
|66|Anesthesia Type|Anesthesia Type|Char|33|$|13,617|6|0|||
|67|Sleep_Apnea_YN|Sleep_Apnea_YN|Char|1|$|2,111|2|0|||
|68|Diabetes_YN|Diabetes_YN|Char|1|$|4,031|2|0|||
|69|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|7,262|2|0|||
|70|Hypertension_YN|Hypertension_YN|Char|1|$|7,291|2|0|||
|71|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|834|2|0|||
|72|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|133|2|0|||
|73|Latitude|Latitude|Num|8|BEST|13,616|10,000|0|||
|74|Longitude|Longitude|Num|8|BEST|13,616|9,981|0|||
|75|Propofol_mg_IntraOp_Total|Propofol_mg_IntraOp_Total|Num|8|BEST|14,778|4,791|0|||
|76|Ketamine_mg_IntraOp_Total|Ketamine_mg_IntraOp_Total|Num|8|BEST|14,778|217|0|||
|77|fentaNYL_SUBLIMAZE_mg_IntraOp_To|fentaNYL_SUBLIMAZE_mg_IntraOp_To|Num|8|BEST|14,778|1|0|||
|78|Sufentanil_mg_IntraOp_Total|Sufentanil_mg_IntraOp_Total|Num|8|BEST|14,778|718|0|||
|79|Hydromorphone_mg_IntraOp_Total|Hydromorphone_mg_IntraOp_Total|Num|8|BEST|14,778|38|0|||
|80|Lidocaine_mg_IntraOp_Total|Lidocaine_mg_IntraOp_Total|Num|8|BEST|14,778|65|0|||
|81|Oral_Morphine_Equiv_IntraOp_Tota|Oral_Morphine_Equiv_IntraOp_Tota|Num|8|BEST|14,778|275|0|||
|82|ISO_Exp_IntraOp_Total|ISO_Exp_IntraOp_Total|Num|8|BEST|14,778|1,752|0|||
|83|ISO_Exp_IntraOp_MAC_Average|ISO_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|2,119|0|||
|84|ISO_Exp_IntraOp_MAC_Minutes_Tota|ISO_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|14,778|603|0|||
|85|ISO_Exp_IntraOp_MAC_Total|ISO_Exp_IntraOp_MAC_Total|Num|8|BEST|14,778|1,752|0|||
|86|SEV_Exp_IntraOp_Total|SEV_Exp_IntraOp_Total|Num|8|BEST|14,778|4,431|0|||
|87|SEV_Exp_IntraOp_MAC_Average|SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|5,498|0|||
|88|SEV_Exp_IntraOp_MAC_Minutes_Tota|SEV_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|14,778|510|0|||
|89|SEV_Exp_IntraOp_MAC_Total|SEV_Exp_IntraOp_MAC_Total|Num|8|BEST|14,778|4,431|0|||
|90|ISO_SEV_Exp_IntraOp_MAC_Average|ISO_SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|14,778|7,067|0|||
|91|Propofol_mg_1_7_Total|Propofol_mg_1_7_Total|Num|8|BEST|14,778|26|0|||
|92|Ketamine_mg_1_7_Total|Ketamine_mg_1_7_Total|Num|8|BEST|14,778|9|0|||
|93|fentaNYL_SUBLIMAZE_mg__1_7_Total|fentaNYL_SUBLIMAZE_mg__1_7_Total|Num|8|BEST|14,778|1|0|||
|94|Sufentanil_mg__1_7_Total|Sufentanil_mg__1_7_Total|Num|8|BEST|14,778|1|0|||
|95|Hydromorphone_mg__1_7_Total|Hydromorphone_mg__1_7_Total|Num|8|BEST|14,778|107|0|||
|96|Lidocaine_mg_1_7_Total|Lidocaine_mg_1_7_Total|Num|8|BEST|14,778|31|0|||
|97|Oral_Morphine_Equiv_Given__1_7_T|Oral_Morphine_Equiv_Given__1_7_T|Num|8|BEST|14,778|728|0|||
|98|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|Num|8|BEST|14,778|284|0|||
|99|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|Num|8|BEST|14,778|226|0|||
|100|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|Num|8|BEST|14,778|174|0|||
|101|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|Num|8|BEST|14,778|144|0|||
|102|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|Num|8|BEST|14,778|131|0|||
|103|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|Num|8|BEST|14,778|113|0|||
|104|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|Num|8|BEST|14,778|91|0|||
|105|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|14,778|446|0|||

## Unit 8: 2018_2022_COLONOSCOPY_20240118.xlsx [sheet=SHEET1]

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|3,456|3,456|0||yes|
|2|Base Procedure 1|Base Procedure 1|Char|161|$|3,456|13|0|||
|3|Base Procedure Code 1|Base Procedure Code 1|Char|8|$|3,456|11|0|||
|4|CPT 1|CPT 1|Char|5|$|3,456|7|<11|||
|5|CPT 1 Description|CPT 1 Description|Char|50|$|3,456|7|0|||
|6|CPT1 Class|CPT1 Class|Char|2|$|3,454|2|0|||
|7|CPT1 Label|CPT1 Label|Char|22|$|3,454|2|0|||
|8|YEAR|YEAR|Char|9|$|3,456|4|0|||

## Unit 9: 2018_2022_X_MASTER_DATASET_20240402.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE_Study_ID|PRECEDE_Study_ID|Char|12|$|41,150|41,150|0||yes|
|2|YEAR|YEAR|Num|8|BEST|41,150|5|0|||
|3|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|41|$|41,149|31,137|0||yes|
|4|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|47|$|40,229|39,753|0||yes|
|5|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|37,670|1,519|<11|||
|6|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|37,958|1,481|0|||
|7|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|37,664|1,888|<11|||
|8|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|36,637|2,449|<11|||
|9|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|36,634|2,919|14|||
|10|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|6,729|1,273|0|||
|11|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|6,729|1,282|0|||
|12|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|36,979|2,475|<11|||
|13|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|36,962|2,985|15|||
|14|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|36,049|2,530|<11|||
|15|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|29,614|2,875|12|||
|16|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|28,858|674|0|||
|17|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|37,159|786|0|||
|18|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|29,733|748|0|||
|19|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|36,772|109|380|||
|20|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|36,187|197|0|||
|21|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|36,791|812|0|||
|22|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|6,743|88|0|||
|23|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|7,717|71|0|||
|24|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|14,913|715|0|||
|25|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|37,958|8|0|||
|26|Day of Week (NUM)|Day of Week (NUM)|Num|8|BEST|17,278|8|0|||
|27|Holidays|Holidays|Char|1|$|37,186|3|0|||
|28|Weekend_Indicator|Weekend_Indicator|Char|1|$|20,680|3|0|||
|29|Age at Encounter|Age at Encounter|Num|8|BEST|38,755|37|0||yes|
|30|EmployeeCode|EmployeeCode|Num|8|BEST|18,212|11|0|||
|31|EmployeeStatus|EmployeeStatus|Char|23|$|33,127|15|4,586|||
|32|Education|Education|Char|19|$|647|7|0|||
|33|Race|Race|Char|16|$|38,755|11|232|||
|34|Ethnicity|Ethnicity|Char|15|$|38,755|6|258|||
|35|Sex|Sex|Char|6|$|38,755|3|0|||
|36|Marital Status|Marital Status|Char|22|$|38,755|10|3,505|||
|37|Admit BMI|Admit BMI|Num|8|BEST|12,726|7,822|0|||
|38|Service|Service|Char|32|$|37,926|36|0|||
|39|Room Type|Room Type|Char|22|$|37,908|28|0|||
|40|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|36,405|6|0|||
|41|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|38,755|3|0|||
|42|Base Procedure 1|Base Procedure 1|Char|201|$|37,924|2,459|0|||
|43|Base Procedure Code 1|Base Procedure Code 1|Char|10|$|37,924|1,971|0|||
|44|CPT 1|CPT 1|Char|8|$|37,924|1,619|1,326|||
|45|CPT 1 Description|CPT 1 Description|Char|77|$|37,924|1,631|0|||
|46|CPT1 Class|CPT1 Class|Num|8|BEST|36,449|160|0|||
|47|CPT1 Label|CPT1 Label|Char|98|$|36,449|160|0|||
|48|Patient Type|Patient Type|Char|18|$|38,755|7|118|||
|49|LOS|LOS|Num|8|BEST|37,670|67|0|||
|50|LOS in Hours|LOS in Hours|Num|8|BEST|13,684|6,817|0|||
|51|Payer|Payer|Char|12|$|37,670|13|0|||
|52|Charges|Charges|Num|8|BEST|37,661|36,874|0|||
|53|ICD10 Principal Diagnosis Desc|ICD10 Principal Diagnosis Desc|Char|62|$|37,413|4,645|0|||
|54|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|37,413|2,425|11,871|||
|55|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|37,397|18|0|||
|56|COMP10_T80|COMP10_T80|Num|8|BEST|40,654|3|0|||
|57|COMP10_T81|COMP10_T81|Num|8|BEST|40,654|5|0|||
|58|COMP10_T82|COMP10_T82|Num|8|BEST|40,654|6|0|||
|59|COMP10_T83|COMP10_T83|Num|8|BEST|40,654|5|0|||
|60|COMP10_T84|COMP10_T84|Num|8|BEST|40,654|6|0|||
|61|COMP10_T85|COMP10_T85|Num|8|BEST|40,654|4|0|||
|62|COMP10_T86|COMP10_T86|Num|8|BEST|40,654|4|0|||
|63|COMP10_T87|COMP10_T87|Num|8|BEST|40,654|4|0|||
|64|COMP10_T88|COMP10_T88|Num|8|BEST|40,654|4|0|||
|65|complication_sum|complication_sum|Num|8|BEST|40,654|8|0|||
|66|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|3,284|2|0|||
|67|Preop_block|Preop_block|Char|1|$|6,743|2|0|||
|68|Admit Source|Admit Source|Char|40|$|37,670|10|<11|||
|69|Dischg Disposition|Dischg Disposition|Char|43|$|37,670|25|<11|||
|70|Death_Days_After_Surgery|Death_Days_After_Surgery|Num|8|BEST|1,101|343|0|||
|71|Death_Date Y/N|Death_Date Y/N|Char|1|$|22,917|3|0|||
|72|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|29,316|3|0|||
|73|Anesthesia Type|Anesthesia Type|Char|33|$|38,764|6|0|||
|74|Sleep_Apnea_YN|Sleep_Apnea_YN|Char|1|$|3,812|2|0|||
|75|Diabetes_YN|Diabetes_YN|Char|1|$|5,983|2|0|||
|76|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|11,207|2|0|||
|77|Hypertension_YN|Hypertension_YN|Char|1|$|12,546|2|0|||
|78|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|1,357|2|0|||
|79|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|144|2|0|||
|80|Cognitive_Category|Cognitive_Category|Char|22|$|12,172|5|0|||
|81|Cognitive_Score|Cognitive_Score|Num|8|BEST|12,128|5|0|||
|82|Frailty_Category|Frailty_Category|Char|24|$|13,999|4|0|||
|83|Frailty_Score|Frailty_Score|Num|8|BEST|14,043|7|0|||
|84|Feels_Exausted_Value|Feels_Exausted_Value|Num|8|BEST|14,181|3|0|||
|85|Low_Physical_Activity_Value|Low_Physical_Activity_Value|Num|8|BEST|14,025|3|0|||
|86|Slow_Walking_Speed_Value|Slow_Walking_Speed_Value|Num|8|BEST|13,989|3|0|||
|87|Unintended_Weight_Loss_Value|Unintended_Weight_Loss_Value|Num|8|BEST|14,156|3|0|||
|88|Week_Grip_Strength_Value|Week_Grip_Strength_Value|Num|8|BEST|13,699|3|0|||
|89|Braden Activity|Braden Activity|Num|8|BEST|15,861|5|0|||
|90|Braden Mobility|Braden Mobility|Num|8|BEST|15,859|5|0|||
|91|Braden Sensory Perception|Braden Sensory Perception|Num|8|BEST|15,882|5|0|||
|92|Latitude|Latitude|Num|8|BEST|38,755|24,575|0|||
|93|Longitude|Longitude|Num|8|BEST|38,755|24,471|0|||
|94|Propofol_mg_IntraOp_Total|Propofol_mg_IntraOp_Total|Num|8|BEST|22,473|7,313|0|||
|95|Ketamine_mg_IntraOp_Total|Ketamine_mg_IntraOp_Total|Num|8|BEST|22,473|326|0|||
|96|fentaNYL_SUBLIMAZE_mg_IntraOp_To|fentaNYL_SUBLIMAZE_mg_IntraOp_To|Num|8|BEST|22,473|77|0|||
|97|Sufentanil_mg_IntraOp_Total|Sufentanil_mg_IntraOp_Total|Num|8|BEST|22,473|960|0|||
|98|Hydromorphone_mg_IntraOp_Total|Hydromorphone_mg_IntraOp_Total|Num|8|BEST|22,473|51|0|||
|99|Lidocaine_mg_IntraOp_Total|Lidocaine_mg_IntraOp_Total|Num|8|BEST|22,473|480|0|||
|100|Oral_Morphine_Equiv_IntraOp_Tota|Oral_Morphine_Equiv_IntraOp_Tota|Num|8|BEST|22,473|576|0|||
|101|ISO_Exp_IntraOp_Total|ISO_Exp_IntraOp_Total|Num|8|BEST|22,473|2,335|0|||
|102|ISO_Exp_IntraOp_MAC_Average|ISO_Exp_IntraOp_MAC_Average|Num|8|BEST|22,473|3,287|0|||
|103|ISO_Exp_IntraOp_MAC_Minutes_Tota|ISO_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|22,473|660|0|||
|104|ISO_Exp_IntraOp_MAC_Total|ISO_Exp_IntraOp_MAC_Total|Num|8|BEST|22,473|2,335|0|||
|105|SEV_Exp_IntraOp_Total|SEV_Exp_IntraOp_Total|Num|8|BEST|22,473|5,765|0|||
|106|SEV_Exp_IntraOp_MAC_Average|SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|22,473|8,203|0|||
|107|SEV_Exp_IntraOp_MAC_Minutes_Tota|SEV_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|22,473|550|0|||
|108|SEV_Exp_IntraOp_MAC_Total|SEV_Exp_IntraOp_MAC_Total|Num|8|BEST|22,473|5,765|0|||
|109|ISO_SEV_Exp_IntraOp_MAC_Average|ISO_SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|22,473|10,643|0|||
|110|Propofol_mg_1_7_Total|Propofol_mg_1_7_Total|Num|8|BEST|22,473|32|0|||
|111|Ketamine_mg_1_7_Total|Ketamine_mg_1_7_Total|Num|8|BEST|22,473|13|0|||
|112|fentaNYL_SUBLIMAZE_mg__1_7_Total|fentaNYL_SUBLIMAZE_mg__1_7_Total|Num|8|BEST|22,473|41|0|||
|113|Sufentanil_mg__1_7_Total|Sufentanil_mg__1_7_Total|Num|8|BEST|22,473|2|0|||
|114|Hydromorphone_mg__1_7_Total|Hydromorphone_mg__1_7_Total|Num|8|BEST|22,473|141|0|||
|115|Lidocaine_mg_1_7_Total|Lidocaine_mg_1_7_Total|Num|8|BEST|22,473|36|0|||
|116|Oral_Morphine_Equiv_Given__1_7_T|Oral_Morphine_Equiv_Given__1_7_T|Num|8|BEST|22,473|903|0|||
|117|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|Num|8|BEST|22,473|329|0|||
|118|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|Num|8|BEST|22,473|266|0|||
|119|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|Num|8|BEST|22,473|211|0|||
|120|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|Num|8|BEST|22,473|187|0|||
|121|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|Num|8|BEST|22,473|158|0|||
|122|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|Num|8|BEST|14,778|114|0|||
|123|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|Num|8|BEST|22,473|120|0|||
|124|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|22,473|516|0|||

## Unit 10: 2020_CPT_ROLLUP_X_MASTER_DATASET_20210609.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|ID|ID|Num|8|BEST|7,695|7,695|<11||yes|
|2|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|7,695|7,695|0||yes|
|3|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|37|$|7,695|6,679|0||yes|
|4|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|47|$|7,381|7,382|0||yes|
|5|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|2,672|56|0|||
|6|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|4,452|561|0|||
|7|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|7,016|306|0|||
|8|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|7,072|301|0|||
|9|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|7,013|381|0|||
|10|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|6,893|653|0|||
|11|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|6,893|1,000|0|||
|12|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,346|293|0|||
|13|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,346|301|0|||
|14|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|6,941|654|0|||
|15|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|6,942|994|0|||
|16|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|6,793|703|0|||
|17|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|5,630|942|<11|||
|18|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|5,508|498|0|||
|19|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|6,970|585|0|||
|20|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|5,648|552|0|||
|21|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|6,917|63|62|||
|22|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|6,819|143|0|||
|23|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|6,922|601|0|||
|24|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,350|72|0|||
|25|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|7,072|8|0|||
|26|Holidays|Holidays|Char|1|$|6,972|2|0|||
|27|Weekend_Indicator|Weekend_Indicator|Char|1|$|7,072|3|0|||
|28|Age at Encounter|Age at Encounter|Num|8|BEST|7,072|34|0||yes|
|29|EmployeeStatus|EmployeeStatus|Char|18|$|102|7|0|||
|30|Education|Education|Char|19|$|117|7|0|||
|31|Race|Race|Char|16|$|7,072|11|42|||
|32|Ethnicity|Ethnicity|Char|15|$|7,072|5|47|||
|33|Sex|Sex|Char|6|$|7,072|3|0|||
|34|Marital Status|Marital Status|Char|22|$|7,072|10|644|||
|35|Admit BMI|Admit BMI|Num|8|BEST|2,568|2,133|0|||
|36|Service|Service|Char|32|$|7,070|32|0|||
|37|Room Type|Room Type|Char|21|$|7,070|14|0|||
|38|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|6,938|6|0|||
|39|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|7,072|3|0|||
|40|Base Procedure 1|Base Procedure 1|Char|200|$|7,070|925|0|||
|41|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|7,070|925|0|||
|42|CPT 1|CPT 1|Char|6|$|7,070|805|189|||
|43|CPT 1 Description|CPT 1 Description|Char|77|$|7,070|805|0|||
|44|CPT1 Class|CPT1 Class|Num|8|BEST|6,876|139|0|||
|45|CPT1 Label|CPT1 Label|Char|98|$|6,876|139|0|||
|46|Patient Type|Patient Type|Char|18|$|7,072|6|<11|||
|47|LOS|LOS|Num|8|BEST|7,016|45|0|||
|48|LOS in Hours|LOS in Hours|Num|8|BEST|2,686|2,196|0|||
|49|Payer|Payer|Char|12|$|7,016|13|0|||
|50|Charges|Charges|Num|8|BEST|7,016|6,967|0|||
|51|ICD10 Principal Diagnosis Desc|ICD10 Principal Diagnosis Desc|Char|62|$|6,974|1,443|0|||
|52|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|6,974|1,443|0|||
|53|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|6,972|17|0|||
|54|COMP10_T80|COMP10_T80|Num|8|BEST|7,199|3|0|||
|55|COMP10_T81|COMP10_T81|Num|8|BEST|7,199|4|0|||
|56|COMP10_T82|COMP10_T82|Num|8|BEST|7,199|4|0|||
|57|COMP10_T83|COMP10_T83|Num|8|BEST|7,199|3|0|||
|58|COMP10_T84|COMP10_T84|Num|8|BEST|7,199|6|0|||
|59|COMP10_T85|COMP10_T85|Num|8|BEST|7,199|4|0|||
|60|COMP10_T86|COMP10_T86|Num|8|BEST|7,199|4|0|||
|61|COMP10_T87|COMP10_T87|Num|8|BEST|7,199|3|0|||
|62|COMP10_T88|COMP10_T88|Num|8|BEST|7,199|3|0|||
|63|complication_sum|complication_sum|Num|8|BEST|7,199|7|0|||
|64|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|798|2|0|||
|65|Preop_block|Preop_block|Char|1|$|1,350|2|0|||
|66|Admit Source|Admit Source|Char|40|$|7,016|6|<11|||
|67|Dischg Disposition|Dischg Disposition|Char|43|$|7,016|21|<11|||
|68|Death_Days_After_Surgery|Death_Days_After_Surgery|Num|8|BEST|198|131|0|||
|69|Death_Date Y/N|Death_Date Y/N|Char|1|$|205|2|0|||
|70|SSDI Death Y/N|SSDI Death Y/N|Char|1|$|7,072|3|0|||
|71|Anesthesia Type|Anesthesia Type|Char|33|$|7,072|6|0|||
|72|Sleep_Apnea|Sleep_Apnea|Char|1|$|1,701|2|0|||
|73|Diabetes|Diabetes|Char|1|$|1,952|2|0|||
|74|Hyperlipidemia|Hyperlipidemia|Char|1|$|3,945|2|0|||
|75|Hypertension|Hypertension|Char|1|$|5,255|2|0|||
|76|MovementDisorder|MovementDisorder|Char|1|$|523|2|0|||
|77|Cognitive_Disorder|Cognitive_Disorder|Char|1|$|11|2|0|||
|78|Cognitive_Category|Cognitive_Category|Char|22|$|3,677|5|0|||
|79|Cognitive_Score|Cognitive_Score|Num|8|BEST|3,653|5|0|||
|80|Frailty_Category|Frailty_Category|Char|24|$|4,172|4|0|||
|81|Frailty_Score|Frailty_Score|Num|8|BEST|4,187|7|0|||
|82|Latitude|Latitude|Num|8|BEST|7,069|5,769|0|||
|83|Longitude|Longitude|Num|8|BEST|7,069|5,782|0|||
|84|SORT_ID|SORT_ID|Num|8|BEST|7,695|7,695|<11||yes|
|85|Propofol_mg_IntraOp_Total|Propofol_mg_IntraOp_Total|Num|8|BEST|7,695|2,658|0|||
|86|Ketamine_mg_IntraOp_Total|Ketamine_mg_IntraOp_Total|Num|8|BEST|7,695|133|0|||
|87|fentaNYL_SUBLIMAZE_mg_IntraOp_To|fentaNYL_SUBLIMAZE_mg_IntraOp_To|Num|8|BEST|7,695|76|0|||
|88|Sufentanil_mg_IntraOp_Total|Sufentanil_mg_IntraOp_Total|Num|8|BEST|7,695|250|0|||
|89|Hydromorphone_mg_IntraOp_Total|Hydromorphone_mg_IntraOp_Total|Num|8|BEST|7,695|36|0|||
|90|Lidocaine_mg_IntraOp_Total|Lidocaine_mg_IntraOp_Total|Num|8|BEST|7,695|448|0|||
|91|Oral_Morphine_Equiv_IntraOp_Tota|Oral_Morphine_Equiv_IntraOp_Tota|Num|8|BEST|7,695|469|0|||
|92|ISO_Exp_IntraOp_Total|ISO_Exp_IntraOp_Total|Num|8|BEST|7,695|989|0|||
|93|ISO_Exp_IntraOp_MAC_Average|ISO_Exp_IntraOp_MAC_Average|Num|8|BEST|7,695|1,198|0|||
|94|ISO_Exp_IntraOp_MAC_Minutes_Tota|ISO_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|7,695|494|0|||
|95|ISO_Exp_IntraOp_MAC_Total|ISO_Exp_IntraOp_MAC_Total|Num|8|BEST|7,695|989|0|||
|96|SEV_Exp_IntraOp_Total|SEV_Exp_IntraOp_Total|Num|8|BEST|7,695|2,313|0|||
|97|SEV_Exp_IntraOp_MAC_Average|SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|7,695|2,931|0|||
|98|SEV_Exp_IntraOp_MAC_Minutes_Tota|SEV_Exp_IntraOp_MAC_Minutes_Tota|Num|8|BEST|7,695|436|0|||
|99|SEV_Exp_IntraOp_MAC_Total|SEV_Exp_IntraOp_MAC_Total|Num|8|BEST|7,695|2,313|0|||
|100|ISO_SEV_IntraOp_MAC_Average|ISO_SEV_IntraOp_MAC_Average|Num|8|BEST|7,695|3,692|0|||
|101|Propofol_mg_1_7_Total|Propofol_mg_1_7_Total|Num|8|BEST|7,695|18|0|||
|102|Ketamine_mg_1_7_Total|Ketamine_mg_1_7_Total|Num|8|BEST|7,695|8|0|||
|103|fentaNYL_SUBLIMAZE_mg__1_7_Total|fentaNYL_SUBLIMAZE_mg__1_7_Total|Num|8|BEST|7,695|40|0|||
|104|Sufentanil_mg__1_7_Total|Sufentanil_mg__1_7_Total|Num|8|BEST|7,695|1|0|||
|105|Hydromorphone_mg__1_7_Total|Hydromorphone_mg__1_7_Total|Num|8|BEST|7,695|90|0|||
|106|Lidocaine_mg_1_7_Total|Lidocaine_mg_1_7_Total|Num|8|BEST|7,695|20|0|||
|107|Oral_Morphine_Equiv_Given__1_7_T|Oral_Morphine_Equiv_Given__1_7_T|Num|8|BEST|7,695|505|0|||
|108|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|Num|8|BEST|7,695|220|0|||
|109|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|Num|8|BEST|7,695|172|0|||
|110|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|Num|8|BEST|7,695|132|0|||
|111|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|Num|8|BEST|7,695|120|0|||
|112|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|Num|8|BEST|7,695|89|0|||
|113|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|Num|8|BEST|7,695|68|0|||
|114|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|7,695|347|0|||

## Unit 11: 2020_Precede_Database_Edu.xlsx [sheet=2020_PRECEDE_DATABASE_EDU]

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|studyid|studyid|Char|12|$|7,696|7,696|0||yes|
|2|Edu_Years|Edu_Years|Num|8|BEST|5,114|36|0|||
|3|edu_categorical|edu_categorical|Num|8|BEST|1,245|13|0|||

## Unit 12: 2020_X_MASTER_DATASET_20210519.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|7,695|7,695|0||yes|
|2|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|37|$|7,695|6,679|0||yes|
|3|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|47|$|7,381|7,382|0||yes|
|4|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|2,672|56|0|||
|5|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|4,452|561|0|||
|6|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|7,016|306|0|||
|7|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|7,072|301|0|||
|8|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|7,013|381|0|||
|9|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|6,893|653|0|||
|10|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|6,893|1,000|0|||
|11|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,346|293|0|||
|12|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,346|301|0|||
|13|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|6,941|654|0|||
|14|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|6,942|994|0|||
|15|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|6,793|703|0|||
|16|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|5,630|942|<11|||
|17|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|5,508|498|0|||
|18|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|6,970|585|0|||
|19|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|5,648|552|0|||
|20|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|6,917|63|62|||
|21|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|6,819|143|0|||
|22|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|6,922|601|0|||
|23|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,350|72|0|||
|24|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|7,072|8|0|||
|25|Holidays|Holidays|Char|1|$|6,972|2|0|||
|26|Weekend_Indicator|Weekend_Indicator|Char|1|$|7,072|3|0|||
|27|Age at Encounter|Age at Encounter|Num|8|BEST|7,072|26|0||yes|
|28|EmployeeStatus|EmployeeStatus|Char|18|$|102|7|0|||
|29|Education|Education|Char|19|$|117|7|0|||
|30|Race|Race|Char|16|$|7,072|11|42|||
|31|Ethnicity|Ethnicity|Char|15|$|7,072|5|47|||
|32|Sex|Sex|Char|6|$|7,072|3|0|||
|33|Marital Status|Marital Status|Char|22|$|7,072|10|644|||
|34|Admit BMI|Admit BMI|Num|8|BEST|2,568|2,133|0|||
|35|Service|Service|Char|32|$|7,070|32|0|||
|36|Room Type|Room Type|Char|21|$|7,070|14|0|||
|37|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|6,938|6|0|||
|38|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|7,072|3|0|||
|39|Base Procedure 1|Base Procedure 1|Char|200|$|7,070|925|0|||
|40|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|7,070|925|0|||
|41|CPT 1|CPT 1|Char|6|$|7,070|805|189|||
|42|CPT 1 Description|CPT 1 Description|Char|77|$|7,070|805|0|||
|43|Patient Type|Patient Type|Char|18|$|7,072|6|<11|||
|44|LOS|LOS|Num|8|BEST|7,016|45|0|||
|45|LOS in Hours|LOS in Hours|Num|8|BEST|2,686|2,196|0|||
|46|Payer|Payer|Char|12|$|7,016|13|0|||
|47|Charges|Charges|Num|8|BEST|7,016|6,967|0|||
|48|ICD10 Principal Diagnosis Desc|ICD10 Principal Diagnosis Desc|Char|62|$|6,974|1,443|0|||
|49|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|6,974|1,443|0|||
|50|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|6,972|17|0|||
|51|COMP10_T80|COMP10_T80|Num|8|BEST|7,199|3|0|||
|52|COMP10_T81|COMP10_T81|Num|8|BEST|7,199|4|0|||
|53|COMP10_T82|COMP10_T82|Num|8|BEST|7,199|4|0|||
|54|COMP10_T83|COMP10_T83|Num|8|BEST|7,199|3|0|||
|55|COMP10_T84|COMP10_T84|Num|8|BEST|7,199|6|0|||
|56|COMP10_T85|COMP10_T85|Num|8|BEST|7,199|4|0|||
|57|COMP10_T86|COMP10_T86|Num|8|BEST|7,199|4|0|||
|58|COMP10_T87|COMP10_T87|Num|8|BEST|7,199|3|0|||
|59|COMP10_T88|COMP10_T88|Num|8|BEST|7,199|3|0|||
|60|complication_sum|complication_sum|Num|8|BEST|7,199|7|0|||
|61|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|798|2|0|||
|62|Preop_block|Preop_block|Char|1|$|1,350|2|0|||
|63|Admit Source|Admit Source|Char|40|$|7,016|6|<11|||
|64|Dischg Disposition|Dischg Disposition|Char|43|$|7,016|21|<11|||
|65|Death_Days_After_Surgery|Death_Days_After_Surgery|Num|8|BEST|198|131|0|||
|66|Death_Date Y/N|Death_Date Y/N|Char|1|$|205|2|0|||
|67|SSDI Death Y/N|SSDI Death Y/N|Char|1|$|7,072|3|0|||
|68|Anesthesia Type|Anesthesia Type|Char|33|$|7,072|6|0|||
|69|Sleep_Apnea|Sleep_Apnea|Char|1|$|1,701|2|0|||
|70|Diabetes|Diabetes|Char|1|$|1,952|2|0|||
|71|Hyperlipidemia|Hyperlipidemia|Char|1|$|3,945|2|0|||
|72|Hypertension|Hypertension|Char|1|$|5,255|2|0|||
|73|MovementDisorder|MovementDisorder|Char|1|$|523|2|0|||
|74|Cognitive_Disorder|Cognitive_Disorder|Char|1|$|11|2|0|||
|75|Cognitive_Category|Cognitive_Category|Char|22|$|3,677|5|0|||
|76|Cognitive_Score|Cognitive_Score|Num|8|BEST|3,653|5|0|||
|77|Frailty_Category|Frailty_Category|Char|24|$|4,172|4|0|||
|78|Frailty_Score|Frailty_Score|Num|8|BEST|4,187|7|0|||
|79|Feels_Exausted_Value|Feels_Exausted_Value|Num|8|BEST|4,173|3|0|||
|80|Low_Physical_Activity_Value|Low_Physical_Activity_Value|Num|8|BEST|4,140|3|0|||
|81|Slow_Walking_Speed_Value|Slow_Walking_Speed_Value|Num|8|BEST|4,125|3|0|||
|82|Unintended_Weight_Loss_Value|Unintended_Weight_Loss_Value|Num|8|BEST|4,162|3|0|||
|83|Week_Grip_Strength_Value|Week_Grip_Strength_Value|Num|8|BEST|4,037|3|0|||
|84|Latitude|Latitude|Num|8|BEST|7,069|5,769|0|||
|85|Longitude|Longitude|Num|8|BEST|7,069|5,782|0|||
|86|SORT_ID|SORT_ID|Num|8|BEST|7,695|7,695|<11||yes|

## Unit 13: 2021_Education_20240124.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|9,462|9,462|0||yes|
|2|Education|Education|Char|19|$|187|7|0|||

## Unit 14: 2021_Frailty_20240123.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|9,462|9,462|0||yes|
|2|Feels_Exausted|Feels_Exausted|Char|1|$|5,156|3|0|||
|3|Low_Physical_Activity|Low_Physical_Activity|Char|1|$|5,102|3|0|||
|4|Slow_Walking_Speed|Slow_Walking_Speed|Char|1|$|5,093|3|0|||
|5|Unintended_Weight_Loss|Unintended_Weight_Loss|Char|1|$|5,145|3|0|||
|6|Week_Grip_Strength|Week_Grip_Strength|Char|1|$|4,961|3|0|||

## Unit 15: 2021_X_MASTER_DATASET_20230512.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|9,462|9,462|0||yes|
|2|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|37|$|9,462|7,982|0||yes|
|3|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|47|$|9,074|9,072|0||yes|
|4|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|3,572|55|0|||
|5|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|5,248|585|0|||
|6|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|8,678|352|0|||
|7|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|8,725|345|0|||
|8|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|8,678|426|0|||
|9|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|8,473|1,298|<11|||
|10|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|8,472|1,647|<11|||
|11|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,278|589|0|||
|12|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,278|603|0|||
|13|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|8,532|1,299|<11|||
|14|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|8,533|1,662|<11|||
|15|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|8,315|1,352|<11|||
|16|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|6,735|1,590|<11|||
|17|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|6,553|514|0|||
|18|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|8,565|626|0|||
|19|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|6,756|580|0|||
|20|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|8,494|63|108|||
|21|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|8,339|149|0|||
|22|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|8,499|633|0|||
|23|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,280|62|0|||
|24|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|8,725|8|0|||
|25|Day of Week (NUM)|Day of Week (NUM)|Num|8|BEST|8,725|8|0|||
|26|Holidays|Holidays|Char|1|$|8,566|3|0|||
|27|Age at Encounter|Age at Encounter|Num|8|BEST|9,017|26|0||yes|
|28|Race|Race|Char|15|$|9,017|9|71|||
|29|Ethnicity|Ethnicity|Char|15|$|9,017|5|75|||
|30|Sex|Sex|Char|6|$|9,017|3|0|||
|31|Marital Status|Marital Status|Char|22|$|9,017|10|844|||
|32|Admit BMI|Admit BMI|Num|8|BEST|2,574|2,243|0|||
|33|EmployeeCode|EmployeeCode|Num|8|BEST|9,252|10|0|||
|34|EmployeeStatus|EmployeeStatus|Char|19|$|9,272|10|1,151|||
|35|Service|Service|Char|32|$|8,695|29|0|||
|36|Room Type|Room Type|Char|22|$|8,690|16|0|||
|37|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|8,522|6|0|||
|38|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|9,017|3|0|||
|39|Base Procedure 1|Base Procedure 1|Char|201|$|8,695|1,009|0|||
|40|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|8,695|1,009|0|||
|41|CPT 1|CPT 1|Char|6|$|8,695|882|322|||
|42|CPT 1 Description|CPT 1 Description|Char|77|$|8,695|882|0|||
|43|CPT1 Class|CPT1 Class|Num|8|BEST|8,370|144|0|||
|44|CPT1 Label|CPT1 Label|Char|98|$|8,370|144|0|||
|45|Patient Type|Patient Type|Char|18|$|9,017|7|36|||
|46|LOS|LOS|Num|8|BEST|8,678|48|0|||
|47|LOS in Hours|LOS in Hours|Num|8|BEST|2,824|2,304|0|||
|48|Payer|Payer|Char|12|$|8,678|12|0|||
|49|Charges|Charges|Num|8|BEST|8,675|8,589|0|||
|50|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|8,626|1,587|0|||
|51|ICD10 Principal Diagnosis POA|ICD10 Principal Diagnosis POA|Char|6|$|8,626|5|5,970|||
|52|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|8,619|15|0|||
|53|COMP10_T80|COMP10_T80|Num|8|BEST|9,462|2|0|||
|54|COMP10_T81|COMP10_T81|Num|8|BEST|9,462|4|0|||
|55|COMP10_T82|COMP10_T82|Num|8|BEST|9,462|4|0|||
|56|COMP10_T83|COMP10_T83|Num|8|BEST|9,462|3|0|||
|57|COMP10_T84|COMP10_T84|Num|8|BEST|9,462|5|0|||
|58|COMP10_T85|COMP10_T85|Num|8|BEST|9,462|3|0|||
|59|COMP10_T86|COMP10_T86|Num|8|BEST|9,462|2|0|||
|60|COMP10_T87|COMP10_T87|Num|8|BEST|9,462|3|0|||
|61|COMP10_T88|COMP10_T88|Num|8|BEST|9,462|2|0|||
|62|complication_sum|complication_sum|Num|8|BEST|9,462|6|0|||
|63|Death_Days_After_Surgery|Death_Days_After_Surgery|Num|8|BEST|504|272|0|||
|64|IsDead Y/N|IsDead Y/N|Char|1|$|8,730|3|0|||
|65|SSDI Death Y/N|SSDI Death Y/N|Char|1|$|8,730|3|0|||
|66|Admit Source|Admit Source|Char|40|$|8,678|5|0|||
|67|Dischg Disposition|Dischg Disposition|Char|28|$|8,678|16|0|||
|68|Anesthesia Type|Anesthesia Type|Char|33|$|9,017|6|0|||
|69|Latitude|Latitude|Num|8|BEST|9,015|7,094|0|||
|70|Longitude|Longitude|Num|8|BEST|9,015|7,092|0|||
|71|Preop_block|Preop_block|Char|1|$|1,280|2|0|||
|72|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|841|2|0|||
|73|Cognitive_Category|Cognitive_Category|Char|22|$|4,400|5|0|||
|74|Cognitive_Score|Cognitive_Score|Num|8|BEST|4,384|5|0|||
|75|Frailty_Category|Frailty_Category|Char|24|$|5,142|4|0|||
|76|Frailty_Score|Frailty_Score|Num|8|BEST|5,154|7|0|||
|77|Feels_Exausted|Feels_Exausted|Char|1|$|5,156|3|0|||
|78|Low_Physical_Activity|Low_Physical_Activity|Char|1|$|5,102|3|0|||
|79|Slow_Walking_Speed|Slow_Walking_Speed|Char|1|$|5,093|3|0|||
|80|Unintended_Weight_Loss|Unintended_Weight_Loss|Char|1|$|5,145|3|0|||
|81|Week_Grip_Strength|Week_Grip_Strength|Char|1|$|4,961|3|0|||
|82|Braden Activity|Braden Activity|Num|8|BEST|7,955|5|0|||
|83|Braden Mobility|Braden Mobility|Num|8|BEST|7,956|5|0|||
|84|Braden Sensory Perception|Braden Sensory Perception|Num|8|BEST|7,980|5|0|||

## Unit 16: 2022_Education_20240124.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Num|8|BEST|9,215|9,215|0||yes|
|2|Education|Education|Char|19|$|47|6|0|||

## Unit 17: 2022_MASTER_DATASET_20231024.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Num|8|BEST|9,215|9,215|0||yes|
|2|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|37|$|9,215|8,172|0||yes|
|3|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|45|$|9,215|9,054|0||yes|
|4|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|1,473|49|0|||
|5|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|5,213|586|0|||
|6|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|8,495|346|0|||
|7|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|8,553|336|0|||
|8|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|8,495|436|0|||
|9|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|8,221|1,169|<11|||
|10|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|8,221|1,485|<11|||
|11|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,365|585|0|||
|12|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,365|582|0|||
|13|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|8,311|1,177|<11|||
|14|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|8,310|1,511|<11|||
|15|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|8,071|1,230|<11|||
|16|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|6,654|1,472|<11|||
|17|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|6,456|517|0|||
|18|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|8,372|636|0|||
|19|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|6,692|592|0|||
|20|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|8,255|68|71|||
|21|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|8,102|149|0|||
|22|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|8,257|638|0|||
|23|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,369|65|0|||
|24|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|8,553|8|0|||
|25|Day of Week (NUM)|Day of Week (NUM)|Num|8|BEST|8,553|8|0|||
|26|Holidays|Holidays|Char|1|$|8,374|2|0|||
|27|Age at Encounter|Age at Encounter|Num|8|BEST|9,058|26|0||yes|
|28|Race|Race|Char|15|$|9,058|9|46|||
|29|Ethnicity|Ethnicity|Char|15|$|9,058|6|48|||
|30|Sex|Sex|Char|6|$|9,058|3|0|||
|31|Marital Status|Marital Status|Char|22|$|9,058|10|753|||
|32|Admit BMI|Admit BMI|Num|8|BEST|2,261|1,980|0|||
|33|EmployeeCode|EmployeeCode|Num|8|BEST|8,960|11|0|||
|34|EmployeeStatus|EmployeeStatus|Char|23|$|8,975|11|1,258|||
|35|Service|Service|Char|32|$|8,553|29|0|||
|36|Room Type|Room Type|Char|22|$|8,546|19|0|||
|37|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|8,280|6|0|||
|38|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|9,058|3|0|||
|39|Base Procedure 1|Base Procedure 1|Char|201|$|8,551|986|0|||
|40|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|8,551|986|0|||
|41|CPT 1|CPT 1|Char|6|$|8,551|850|392|||
|42|CPT 1 Description|CPT 1 Description|Char|70|$|8,551|850|0|||
|43|CPT1 Class|CPT1 Class|Num|8|BEST|8,095|141|0|||
|44|CPT1 Label|CPT1 Label|Char|98|$|8,095|141|0|||
|45|Patient Type|Patient Type|Char|18|$|9,058|7|81|||
|46|LOS|LOS|Num|8|BEST|8,495|46|0|||
|47|LOS in Hours|LOS in Hours|Num|8|BEST|2,613|2,209|0|||
|48|Payer|Payer|Char|12|$|8,495|12|0|||
|49|Charges|Charges|Num|8|BEST|8,494|8,390|0|||
|50|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|8,439|1,582|0|||
|51|ICD10 Principal Diagnosis POA|ICD10 Principal Diagnosis POA|Char|6|$|8,439|5|5,901|||
|52|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|8,433|16|0|||
|53|COMP10_T80|COMP10_T80|Num|8|BEST|9,215|2|0|||
|54|COMP10_T81|COMP10_T81|Num|8|BEST|9,215|4|0|||
|55|COMP10_T82|COMP10_T82|Num|8|BEST|9,215|3|0|||
|56|COMP10_T83|COMP10_T83|Num|8|BEST|9,215|3|0|||
|57|COMP10_T84|COMP10_T84|Num|8|BEST|9,215|5|0|||
|58|COMP10_T85|COMP10_T85|Num|8|BEST|9,215|3|0|||
|59|COMP10_T86|COMP10_T86|Num|8|BEST|9,215|3|0|||
|60|COMP10_T87|COMP10_T87|Num|8|BEST|9,215|2|0|||
|61|COMP10_T88|COMP10_T88|Num|8|BEST|9,215|2|0|||
|62|complication_sum|complication_sum|Num|8|BEST|9,215|6|0|||
|63|Death_Days_After_Surgery|Death_Days_After_Surgery|Num|8|BEST|399|232|0|||
|64|Death|Death|Char|1|$|495|2|0|||
|65|SSDI_Death|SSDI_Death|Char|1|$|27|2|0|||
|66|Admit Source|Admit Source|Char|28|$|8,495|7|0|||
|67|Anesthesia Type|Anesthesia Type|Char|33|$|9,058|6|0|||
|68|Dischg Disposition|Dischg Disposition|Char|38|$|8,495|16|0|||
|69|Latitude|Latitude|Num|8|BEST|9,055|7,023|0|||
|70|Longitude|Longitude|Num|8|BEST|9,055|7,005|0|||
|71|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|533|2|0|||
|72|Preop_block|Preop_block|Char|1|$|1,369|2|0|||
|73|Cognitive_Category|Cognitive_Category|Char|22|$|4,095|5|0|||
|74|Cognitive_Score|Cognitive_Score|Num|8|BEST|4,091|5|0|||
|75|Frailty_Category|Frailty_Category|Char|24|$|4,685|4|0|||
|76|Frailty_Score|Frailty_Score|Num|8|BEST|4,702|7|0|||
|77|Feels_Exausted|Feels_Exausted|Char|3|$|4,852|3|0|||
|78|Low_Physical_Activity|Low_Physical_Activity|Char|3|$|4,783|3|0|||
|79|Slow_Walking_Speed|Slow_Walking_Speed|Char|3|$|4,771|3|0|||
|80|Unintended_Weight_Loss|Unintended_Weight_Loss|Char|3|$|4,849|3|0|||
|81|Week_Grip_Strength|Week_Grip_Strength|Char|3|$|4,701|3|0|||
|82|Braden_Activity|Braden_Activity|Num|8|BEST|7,906|5|0|||
|83|Braden_Mobility|Braden_Mobility|Num|8|BEST|7,903|5|0|||
|84|Braden_Sensory_Perception|Braden_Sensory_Perception|Num|8|BEST|7,902|5|0|||

## Unit 18: 2022_RES_20230927.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Num|8|BEST|9,485|9,484|0||yes|
|2|Race|Race|Char|15|$|9,328|9|47|||
|3|Ethnicity|Ethnicity|Char|15|$|9,328|6|48|||
|4|Sex|Sex|Char|6|$|9,328|3|0|||

## Unit 19: 2023_X_MASTER_DATASET_20261016.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Num|8|BEST|10,772|10,772|0||yes|
|2|YEAR|YEAR|Num|8|BEST|10,772|1|0|||
|3|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|51|$|10,772|8,984|0||yes|
|4|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|63|$|10,772|10,045|0||yes|
|5|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|9,888|376|0|||
|6|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|9,990|370|0|||
|7|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|9,888|469|0|||
|8|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|9,603|1,140|<11|||
|9|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|9,604|1,391|<11|||
|10|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,393|544|0|||
|11|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,394|547|0|||
|12|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|9,722|1,138|<11|||
|13|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|9,725|1,428|<11|||
|14|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|9,383|1,182|<11|||
|15|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|7,727|1,371|<11|||
|16|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|7,426|516|<11|||
|17|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|9,780|618|0|||
|18|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|7,756|583|0|||
|19|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|9,638|72|65|||
|20|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|9,415|155|0|||
|21|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|9,644|636|0|||
|22|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,396|65|0|||
|23|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|7,281|70|0|||
|24|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|5,959|591|0|||
|25|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|9,990|8|0|||
|26|Day of Week (NUM)|Day of Week (NUM)|Num|8|BEST|9,990|8|0|||
|27|Holidays|Holidays|Char|1|$|9,780|3|0|||
|28|Weekend_Indicator|Weekend_Indicator|Char|1|$|9,990|2|0|||
|29|Age at Encounter|Age at Encounter|Num|8|BEST|9,990|37|0||yes|
|30|EmployeeCode|EmployeeCode|Num|8|BEST|10,772|10|0|||
|31|EmployeeStatus|EmployeeStatus|Char|19|$|10,772|10|1,639|||
|32|preop_edu_years|preop_edu_years|Num|8|BEST|6,377|30|0|||
|33|Race|Race|Char|31|$|9,990|13|56|||
|34|Ethnicity|Ethnicity|Char|15|$|9,990|5|58|||
|35|Sex|Sex|Char|6|$|9,990|3|0|||
|36|Marital Status|Marital Status|Char|22|$|9,990|10|900|||
|37|Admit BMI|Admit BMI|Num|8|BEST|2,197|1,851|0|||
|38|Service|Service|Char|49|$|9,990|36|0|||
|39|Room Type|Room Type|Char|22|$|9,988|24|0|||
|40|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|9,660|6|0|||
|41|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|9,990|3|0|||
|42|Base Procedure 1|Base Procedure 1|Char|201|$|9,990|1,112|0|||
|43|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|9,990|1,112|0|||
|44|CPT 1|CPT 1|Char|6|$|9,990|973|535|||
|45|CPT 1 Description|CPT 1 Description|Char|70|$|9,990|973|0|||
|46|CPT1 Class|CPT1 Class|Num|8|BEST|9,302|146|0|||
|47|CPT1 Label|CPT1 Label|Char|98|$|9,302|146|0|||
|48|Patient Type|Patient Type|Char|18|$|9,990|5|0|||
|49|LOS|LOS|Num|8|BEST|9,888|51|0|||
|50|LOS in Hours|LOS in Hours|Num|8|BEST|2,685|2,201|0|||
|51|Payer|Payer|Char|12|$|9,888|12|0|||
|52|Charges|Charges|Num|8|BEST|9,888|9,450|0|||
|53|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|9,821|1,690|0|||
|54|ICD10 Principal Diagnosis POA|ICD10 Principal Diagnosis POA|Char|6|$|9,821|5|7,192|||
|55|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|9,821|18|0|||
|56|COMP10_T80|COMP10_T80|Num|8|BEST|9,888|3|0|||
|57|COMP10_T81|COMP10_T81|Num|8|BEST|9,888|5|0|||
|58|COMP10_T82|COMP10_T82|Num|8|BEST|9,888|5|0|||
|59|COMP10_T83|COMP10_T83|Num|8|BEST|9,888|3|0|||
|60|COMP10_T84|COMP10_T84|Num|8|BEST|9,888|6|0|||
|61|COMP10_T85|COMP10_T85|Num|8|BEST|9,888|4|0|||
|62|COMP10_T86|COMP10_T86|Num|8|BEST|9,888|3|0|||
|63|COMP10_T87|COMP10_T87|Num|8|BEST|9,888|3|0|||
|64|COMP10_T88|COMP10_T88|Num|8|BEST|9,888|3|0|||
|65|complication_sum|complication_sum|Num|8|BEST|9,888|7|0|||
|66|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|475|2|0|||
|67|Preop_block|Preop_block|Char|1|$|1,396|2|0|||
|68|Admit Source|Admit Source|Char|28|$|9,888|8|0|||
|69|Dischg Disposition|Dischg Disposition|Char|28|$|9,888|15|0|||
|70|Death_Days_After_Surgery|Death_Days_After_Surgery|Char|6|$|10,248|263|0|||
|71|Death_Date Y/N|Death_Date Y/N|Char|1|$|1,033|2|0|||
|72|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|148|2|0|||
|73|Anesthesia Type|Anesthesia Type|Char|33|$|9,990|6|0|||
|74|SleepApnea_YN|SleepApnea_YN|Char|1|$|9,888|3|0|||
|75|Diabetes_YN|Diabetes_YN|Char|1|$|9,888|3|0|||
|76|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|9,888|3|0|||
|77|Hypertension_YN|Hypertension_YN|Char|1|$|9,888|3|0|||
|78|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|9,888|3|0|||
|79|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|9,888|3|0|||
|80|Cognitive_Category|Cognitive_Category|Char|22|$|3,056|5|0|||
|81|Cognitive_Score|Cognitive_Score|Num|8|BEST|3,052|5|0|||
|82|Fraility_Category|Fraility_Category|Char|24|$|3,457|4|0|||
|83|Fraility_Score|Fraility_Score|Num|8|BEST|3,467|7|0|||
|84|Feels_Exausted|Feels_Exausted|Num|8|BEST|3,583|3|0|||
|85|Low_Physical_Activity|Low_Physical_Activity|Num|8|BEST|3,528|3|0|||
|86|Slow_Walking_Speed|Slow_Walking_Speed|Num|8|BEST|3,522|3|0|||
|87|Unintended_Weight_Loss|Unintended_Weight_Loss|Num|8|BEST|3,584|3|0|||
|88|Week_Grip_Strength|Week_Grip_Strength|Num|8|BEST|3,462|3|0|||
|89|Braden Activity|Braden Activity|Num|8|BEST|8,889|5|0|||
|90|Braden Mobility|Braden Mobility|Num|8|BEST|8,879|5|0|||
|91|Braden Sensory Perception|Braden Sensory Perception|Num|8|BEST|8,884|5|0|||
|92|Latitude|Latitude|Num|8|BEST|9,988|7,528|0|||
|93|Longitude|Longitude|Num|8|BEST|9,988|7,530|0|||
|94|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|2,578|390|0|||

## Unit 20: 2024_X_MASTER_DATASET_20261016.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Num|8|BEST|13,029|13,029|0||yes|
|2|YEAR|YEAR|Num|8|BEST|13,029|1|0|||
|3|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|45|$|13,029|10,645|0||yes|
|4|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|55|$|13,029|12,251|0||yes|
|5|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|11,897|385|0|||
|6|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|12,093|382|0|||
|7|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|11,897|469|0|||
|8|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|11,506|1,135|<11|||
|9|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|11,506|1,423|<11|||
|10|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,614|558|0|||
|11|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,616|559|0|||
|12|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|11,663|1,131|<11|||
|13|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|11,667|1,431|14|||
|14|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|11,191|1,162|<11|||
|15|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|9,109|1,388|<11|||
|16|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|8,821|516|0|||
|17|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|11,808|634|0|||
|18|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|9,210|587|0|||
|19|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|11,622|78|115|||
|20|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|11,301|156|0|||
|21|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|11,626|660|0|||
|22|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,645|67|0|||
|23|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|8,727|66|<11|||
|24|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|7,040|600|0|||
|25|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|12,093|8|0|||
|26|Day of Week (NUM)|Day of Week (NUM)|Num|8|BEST|12,093|8|0|||
|27|Holidays|Holidays|Char|1|$|11,808|3|0|||
|28|Weekend_Indicator|Weekend_Indicator|Char|1|$|12,093|2|0|||
|29|Age at Encounter|Age at Encounter|Num|8|BEST|12,093|39|0||yes|
|30|EmployeeCode|EmployeeCode|Num|8|BEST|13,029|10|0|||
|31|EmployeeStatus|EmployeeStatus|Char|19|$|13,029|10|2,040|||
|32|preop_edu_years|preop_edu_years|Num|8|BEST|6,787|33|0|||
|33|Race|Race|Char|31|$|12,093|12|76|||
|34|Ethnicity|Ethnicity|Char|15|$|12,093|5|71|||
|35|Sex|Sex|Char|6|$|12,093|3|0|||
|36|Marital Status|Marital Status|Char|22|$|12,093|10|1,163|||
|37|Admit BMI|Admit BMI|Num|8|BEST|2,451|2,055|0|||
|38|Service|Service|Char|49|$|12,093|33|0|||
|39|Room Type|Room Type|Char|22|$|12,082|28|0|||
|40|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|11,641|6|0|||
|41|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|12,093|3|0|||
|42|Base Procedure 1|Base Procedure 1|Char|200|$|12,093|1,222|0|||
|43|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|12,093|1,224|0|||
|44|CPT 1|CPT 1|Char|6|$|12,093|1,054|595|||
|45|CPT 1 Description|CPT 1 Description|Char|72|$|12,093|1,054|0|||
|46|CPT1 Class|CPT1 Class|Num|8|BEST|11,280|146|0|||
|47|CPT1 Label|CPT1 Label|Char|98|$|11,280|146|0|||
|48|Patient Type|Patient Type|Char|18|$|12,093|6|<11|||
|49|LOS|LOS|Num|8|BEST|11,897|47|0|||
|50|LOS in Hours|LOS in Hours|Num|8|BEST|2,967|2,360|0|||
|51|Payer|Payer|Char|12|$|11,897|12|0|||
|52|Charges|Charges|Num|8|BEST|11,897|11,227|0|||
|53|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|11,822|1,934|0|||
|54|ICD10 Principal Diagnosis POA|ICD10 Principal Diagnosis POA|Char|6|$|11,822|4|8,895|||
|55|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|11,817|18|0|||
|56|COMP10_T80|COMP10_T80|Num|8|BEST|11,897|3|0|||
|57|COMP10_T81|COMP10_T81|Num|8|BEST|11,897|5|0|||
|58|COMP10_T82|COMP10_T82|Num|8|BEST|11,897|5|0|||
|59|COMP10_T83|COMP10_T83|Num|8|BEST|11,897|4|0|||
|60|COMP10_T84|COMP10_T84|Num|8|BEST|11,897|6|0|||
|61|COMP10_T85|COMP10_T85|Num|8|BEST|11,897|4|0|||
|62|COMP10_T86|COMP10_T86|Num|8|BEST|11,897|4|0|||
|63|COMP10_T87|COMP10_T87|Num|8|BEST|11,897|3|0|||
|64|COMP10_T88|COMP10_T88|Num|8|BEST|11,897|3|0|||
|65|complication_sum|complication_sum|Num|8|BEST|11,897|7|0|||
|66|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|728|2|0|||
|67|Preop_block|Preop_block|Char|1|$|1,645|2|0|||
|68|Admit Source|Admit Source|Char|40|$|11,897|8|0|||
|69|Dischg Disposition|Dischg Disposition|Char|38|$|11,897|18|0|||
|70|Death_Days_After_Surgery|Death_Days_After_Surgery|Char|6|$|12,700|265|0|||
|71|Death_Date Y/N|Death_Date Y/N|Char|1|$|885|2|0|||
|72|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|103|2|0|||
|73|Anesthesia Type|Anesthesia Type|Char|33|$|12,093|6|0|||
|74|SleepApnea_YN|SleepApnea_YN|Char|1|$|11,897|3|0|||
|75|Diabetes_YN|Diabetes_YN|Char|1|$|11,897|3|0|||
|76|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|11,897|3|0|||
|77|Hypertension_YN|Hypertension_YN|Char|1|$|11,897|3|0|||
|78|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|11,897|3|0|||
|79|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|11,897|3|0|||
|80|Cognitive_Category|Cognitive_Category|Char|22|$|4,694|6|0|||
|81|Cognitive_Score|Cognitive_Score|Num|8|BEST|4,694|5|0|||
|82|Fraility_Category|Fraility_Category|Char|24|$|5,607|4|0|||
|83|Fraility_Score|Fraility_Score|Num|8|BEST|5,607|7|0|||
|84|Feels_Exausted|Feels_Exausted|Num|8|BEST|5,881|3|0|||
|85|Low_Physical_Activity|Low_Physical_Activity|Num|8|BEST|5,795|3|0|||
|86|Slow_Walking_Speed|Slow_Walking_Speed|Num|8|BEST|5,770|3|0|||
|87|Unintended_Weight_Loss|Unintended_Weight_Loss|Num|8|BEST|5,911|3|0|||
|88|Week_Grip_Strength|Week_Grip_Strength|Num|8|BEST|5,641|3|0|||
|89|BRADEN_2024_OUT_Braden Activity|BRADEN_2024_OUT_Braden Activity|Num|8|BEST|10,571|5|0|||
|90|BRADEN_2024_OUT_Braden Mobility|BRADEN_2024_OUT_Braden Mobility|Num|8|BEST|10,560|5|0|||
|91|BRADEN_2024_OUT_Braden Sensory P|BRADEN_2024_OUT_Braden Sensory P|Num|8|BEST|10,580|5|0|||
|92|Latitude|Latitude|Num|8|BEST|12,093|8,879|0|||
|93|Longitude|Longitude|Num|8|BEST|12,093|8,908|0|||
|94|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|2,778|378|0|||

## Unit 21: 2025_X_MASTER_DATASET_20261016.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Num|8|BEST|12,689|12,689|0||yes|
|2|YEAR|YEAR|Num|8|BEST|12,689|1|0|||
|3|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|49|$|12,689|11,124|0||yes|
|4|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|54|$|12,689|12,302|0||yes|
|5|rt_ANCHOR_to_ADMIT_days|rt_ANCHOR_to_ADMIT_days|Num|8|BEST|11,566|363|0|||
|6|rt_ANCHOR_to_SURGERY_days|rt_ANCHOR_to_SURGERY_days|Num|8|BEST|11,813|356|0|||
|7|rt_ANCHOR_to_DISCHG_days|rt_ANCHOR_to_DISCHG_days|Num|8|BEST|11,566|451|0|||
|8|rt_ADMIT_to_AN_START_mins|rt_ADMIT_to_AN_START_mins|Num|8|BEST|11,247|1,047|<11|||
|9|rt_ADMIT_to_AN_END_mins|rt_ADMIT_to_AN_END_mins|Num|8|BEST|11,247|1,311|<11|||
|10|rt_ADMIT_to_BLOCK_START_mins|rt_ADMIT_to_BLOCK_START_mins|Num|8|BEST|1,504|535|0|||
|11|rt_ADMIT_to_BLOCK_END_mins|rt_ADMIT_to_BLOCK_END_mins|Num|8|BEST|1,503|528|0|||
|12|rt_ADMIT_to_RM_START_mins|rt_ADMIT_to_RM_START_mins|Num|8|BEST|11,357|1,061|<11|||
|13|rt_ADMIT_to_RM_END_mins|rt_ADMIT_to_RM_END_mins|Num|8|BEST|11,358|1,319|<11|||
|14|rt_ADMIT_to_INCISION_mins|rt_ADMIT_to_INCISION_mins|Num|8|BEST|10,988|1,081|<11|||
|15|rt_ADMIT_to_DRESS_mins|rt_ADMIT_to_DRESS_mins|Num|8|BEST|8,725|1,271|<11|||
|16|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Num|8|BEST|8,586|511|0|||
|17|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Num|8|BEST|11,553|635|0|||
|18|rt_RM_START_to_DRESS_mins|rt_RM_START_to_DRESS_mins|Num|8|BEST|8,872|580|<11|||
|19|rt_RM_START_to_AN_START_mins|rt_RM_START_to_AN_START_mins|Num|8|BEST|11,413|71|68|||
|20|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Num|8|BEST|11,133|156|0|||
|21|rt_AN_START_to_AN_END_mins|rt_AN_START_to_AN_END_mins|Num|8|BEST|11,416|642|0|||
|22|rt_BLOCK_START_TO_BLOCK_END_mins|rt_BLOCK_START_TO_BLOCK_END_mins|Num|8|BEST|1,564|63|0|||
|23|rt_RM_START_to_INDUCTION_mins|rt_RM_START_to_INDUCTION_mins|Num|8|BEST|8,466|63|<11|||
|24|rt_RM_START_to_EMERGENCE_mins|rt_RM_START_to_EMERGENCE_mins|Num|8|BEST|6,757|587|0|||
|25|Day of Week (CHAR)|Day of Week (CHAR)|Char|3|$|11,813|8|0|||
|26|Day of Week (NUM)|Day of Week (NUM)|Num|8|BEST|11,813|8|0|||
|27|Holidays|Holidays|Char|1|$|11,553|3|0|||
|28|Weekend_Indicator|Weekend_Indicator|Char|1|$|11,813|2|0|||
|29|Age at Encounter|Age at Encounter|Num|8|BEST|11,813|37|0||yes|
|30|EmployeeCode|EmployeeCode|Num|8|BEST|12,689|9|0|||
|31|EmployeeStatus|EmployeeStatus|Char|19|$|12,689|9|2,359|||
|32|preop_edu_years|preop_edu_years|Num|8|BEST|6,750|35|0|||
|33|Race|Race|Char|31|$|11,813|13|76|||
|34|Ethnicity|Ethnicity|Char|15|$|11,813|5|73|||
|35|Sex|Sex|Char|6|$|11,813|3|0|||
|36|Marital Status|Marital Status|Char|22|$|11,813|10|1,417|||
|37|Admit BMI|Admit BMI|Num|8|BEST|1,983|1,814|0|||
|38|Service|Service|Char|32|$|11,813|34|0|||
|39|Room Type|Room Type|Char|22|$|11,807|27|0|||
|40|ASA (Anesth Record)|ASA (Anesth Record)|Num|8|BEST|11,423|6|0|||
|41|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|1|$|11,813|3|0|||
|42|Base Procedure 1|Base Procedure 1|Char|201|$|11,813|1,207|0|||
|43|Base Procedure Code 1|Base Procedure Code 1|Num|8|BEST|11,813|1,213|0|||
|44|CPT 1|CPT 1|Char|6|$|11,813|1,038|597|||
|45|CPT 1 Description|CPT 1 Description|Char|70|$|11,813|1,038|0|||
|46|CPT1 Class|CPT1 Class|Num|8|BEST|11,017|152|0|||
|47|CPT1 Label|CPT1 Label|Char|98|$|11,017|152|0|||
|48|Patient Type|Patient Type|Char|18|$|11,813|5|0|||
|49|LOS|LOS|Num|8|BEST|11,566|51|0|||
|50|LOS in Hours|LOS in Hours|Num|8|BEST|2,568|2,165|0|||
|51|Payer|Payer|Char|12|$|11,566|12|0|||
|52|Charges|Charges|Num|8|BEST|11,565|11,179|0|||
|53|ICD10 Principal Diagnosis|ICD10 Principal Diagnosis|Char|7|$|11,472|1,771|0|||
|54|ICD10 Principal Diagnosis POA|ICD10 Principal Diagnosis POA|Char|6|$|11,472|5|8,952|||
|55|Charlson_Comorbidity_Index|Charlson_Comorbidity_Index|Num|8|BEST|11,459|16|0|||
|56|COMP10_T80|COMP10_T80|Num|8|BEST|11,566|3|0|||
|57|COMP10_T81|COMP10_T81|Num|8|BEST|11,566|5|0|||
|58|COMP10_T82|COMP10_T82|Num|8|BEST|11,566|5|0|||
|59|COMP10_T83|COMP10_T83|Num|8|BEST|11,566|4|0|||
|60|COMP10_T84|COMP10_T84|Num|8|BEST|11,566|7|0|||
|61|COMP10_T85|COMP10_T85|Num|8|BEST|11,566|4|0|||
|62|COMP10_T86|COMP10_T86|Num|8|BEST|11,566|4|0|||
|63|COMP10_T87|COMP10_T87|Num|8|BEST|11,566|4|0|||
|64|COMP10_T88|COMP10_T88|Num|8|BEST|11,566|3|0|||
|65|complication_sum|complication_sum|Num|8|BEST|11,566|7|0|||
|66|Intraop_Ketamine|Intraop_Ketamine|Char|1|$|829|2|0|||
|67|Preop_block|Preop_block|Char|1|$|1,564|2|0|||
|68|Admit Source|Admit Source|Char|40|$|11,566|8|0|||
|69|Dischg Disposition|Dischg Disposition|Char|29|$|11,566|18|0|||
|70|Death_Days_After_Surgery|Death_Days_After_Surgery|Char|6|$|12,643|251|0|||
|71|Death_Date Y/N|Death_Date Y/N|Char|1|$|497|2|0|||
|72|SSDI Death Date Y/N|SSDI Death Date Y/N|Char|1|$|32|2|0|||
|73|Anesthesia Type|Anesthesia Type|Char|33|$|11,813|6|0|||
|74|SleepApnea_YN|SleepApnea_YN|Char|1|$|11,566|3|0|||
|75|Diabetes_YN|Diabetes_YN|Char|1|$|11,566|3|0|||
|76|Hyperlipidemia_YN|Hyperlipidemia_YN|Char|1|$|11,566|3|0|||
|77|Hypertension_YN|Hypertension_YN|Char|1|$|11,566|3|0|||
|78|MovementDisorder_YN|MovementDisorder_YN|Char|1|$|11,566|3|0|||
|79|CognitiveDisorder_YN|CognitiveDisorder_YN|Char|1|$|11,566|3|0|||
|80|Cognitive_Category|Cognitive_Category|Char|22|$|5,185|7|0|||
|81|Cognitive_Score|Cognitive_Score|Num|8|BEST|5,185|5|0|||
|82|Fraility_Category|Fraility_Category|Char|24|$|7,280|4|0|||
|83|Fraility_Score|Fraility_Score|Num|8|BEST|7,280|7|0|||
|84|Feels_Exausted|Feels_Exausted|Num|8|BEST|7,485|3|0|||
|85|Low_Physical_Activity|Low_Physical_Activity|Num|8|BEST|7,469|3|0|||
|86|Slow_Walking_Speed|Slow_Walking_Speed|Num|8|BEST|7,462|3|0|||
|87|Unintended_Weight_Loss|Unintended_Weight_Loss|Num|8|BEST|7,495|3|0|||
|88|Week_Grip_Strength|Week_Grip_Strength|Num|8|BEST|7,299|3|0|||
|89|BRADEN_2025_OUT_Braden Activity|BRADEN_2025_OUT_Braden Activity|Num|8|BEST|10,138|5|0|||
|90|BRADEN_2025_OUT_Braden Mobility|BRADEN_2025_OUT_Braden Mobility|Num|8|BEST|10,140|5|0|||
|91|BRADEN_2025_OUT_Braden Sensory P|BRADEN_2025_OUT_Braden Sensory P|Num|8|BEST|10,153|5|0|||
|92|Latitude|Latitude|Num|8|BEST|11,813|9,273|0|||
|93|Longitude|Longitude|Num|8|BEST|11,813|9,333|0|||
|94|ICU_LOS_TOTAL_TIME_HOURS|ICU_LOS_TOTAL_TIME_HOURS|Num|8|BEST|2,428|380|0|||

## Unit 22: ALL_AIM2_MASTER_DATASET_20210917.xlsx [sheet=SHEET1]

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|22,473|22,473|0||yes|
|2|ENCRYPTED_MRN|ENCRYPTED_MRN|Char|40|$|22,472|18,802|0||yes|
|3|ENCRYPTED_ENCOUNTER|ENCRYPTED_ENCOUNTER|Char|46|$|22,254|21,697|314||yes|
|4|rt_RM_START_to_INCISION_mins|rt_RM_START_to_INCISION_mins|Char|4|$|22,473|172|2,727|||
|5|rt_INCISE_to_DRESS_mins|rt_INCISE_to_DRESS_mins|Char|4|$|22,473|626|6,624|||
|6|rt_RM_START_to_RM_END_mins|rt_RM_START_to_RM_END_mins|Char|4|$|22,473|718|2,251|||
|7|Age at Encounter|Age at Encounter|Char|4|$|22,473|37|1,793||yes|
|8|EmployeeStatus|EmployeeStatus|Char|23|$|22,473|15|9,770|||
|9|Education|Education|Char|19|$|22,473|7|22,060|||
|10|Race|Race|Char|16|$|22,473|11|1,908|||
|11|Ethnicity|Ethnicity|Char|15|$|22,473|5|1,928|||
|12|Sex|Sex|Char|6|$|22,473|3|1,793|||
|13|Marital Status|Marital Status|Char|22|$|22,473|10|3,701|||
|14|Admit BMI|Admit BMI|Char|11|$|22,473|5,221|14,582|||
|15|Service|Service|Char|32|$|22,473|36|1,795|||
|16|ASA (Anesth Record)|ASA (Anesth Record)|Char|4|$|22,473|6|2,870|||
|17|Emergent Y/N (Anesth Record)|Emergent Y/N (Anesth Record)|Char|4|$|22,473|3|1,793|||
|18|Base Procedure 1|Base Procedure 1|Char|198|$|22,473|1,519|1,795|||
|19|Base Procedure Code 1|Base Procedure Code 1|Char|10|$|22,473|1,517|1,795|||
|20|CPT 1|CPT 1|Char|8|$|22,473|1,288|2,407|||
|21|CPT 1 Description|CPT 1 Description|Char|75|$|22,473|1,288|1,795|||
|22|Intraop_Ketamine|Intraop_Ketamine|Char|4|$|22,473|2|20,563|||
|23|Preop_block|Preop_block|Char|4|$|22,473|2|18,379|||
|24|Cognitive_Category|Cognitive_Category|Char|22|$|22,473|9|10,351|||
|25|Cognitive_Score|Cognitive_Score|Char|4|$|22,473|5|10,408|||
|26|Frailty_Category|Frailty_Category|Char|24|$|22,473|4|16,512|||
|27|Frailty_Score|Frailty_Score|Char|4|$|22,473|7|9,018|||
|28|Propofol_mg_IntraOp_Total|Propofol_mg_IntraOp_Total|Num|8|BEST|22,473|7,311|0|||
|29|Ketamine_mg_IntraOp_Total|Ketamine_mg_IntraOp_Total|Num|8|BEST|22,473|325|0|||
|30|Oral_Morphine_Equiv_IntraOp_Tota|Oral_Morphine_Equiv_IntraOp_Total_mg|Num|8|BEST|22,473|575|0|||
|31|ISO_Exp_IntraOp_Total|ISO_Exp_IntraOp_Total|Num|8|BEST|3,626|929|0|||
|32|ISO_Exp_IntraOp_MAC_Total|ISO_Exp_IntraOp_MAC_Total|Num|8|BEST|3,218|928|0|||
|33|ISO_Exp_IntraOp_MAC_Average|ISO_Exp_IntraOp_MAC_Average|Num|8|BEST|3,218|1,272|0|||
|34|ISO_Exp_IntraOp_MAC_Minutes_Tota|ISO_Exp_IntraOp_MAC_Minutes_Total|Num|8|BEST|3,218|62|0|||
|35|SEV_Exp_IntraOp_Total|SEV_Exp_IntraOp_Total|Num|8|BEST|9,521|3,229|0|||
|36|SEV_Exp_IntraOp_MAC_Total|SEV_Exp_IntraOp_MAC_Total|Num|8|BEST|7,874|3,228|0|||
|37|SEV_Exp_IntraOp_MAC_Average|SEV_Exp_IntraOp_MAC_Average|Num|8|BEST|7,874|4,536|0|||
|38|SEV_Exp_IntraOp_MAC_Minutes_Tota|SEV_Exp_IntraOp_MAC_Minutes_Total|Num|8|BEST|7,874|62|0|||
|39|ISO_SEV_MAC_TOTAL_Exp|ISO_SEV_MAC_TOTAL_Exp|Num|8|BEST|10,788|5,621|0|||
|40|Propofol_mg_1_7_Total|Propofol_mg_1_7_Total|Num|8|BEST|22,473|31|0|||
|41|Ketamine_mg_1_7_Total|Ketamine_mg_1_7_Total|Num|8|BEST|22,473|12|0|||
|42|Oral_Morphine_Equiv_Given__1_7_T|Oral_Morphine_Equiv_Given__1_7_Total_mg|Num|8|BEST|22,473|902|0|||
|43|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|ORAL_MORPHINE_EQUIV_mg_POD_DAY1|Num|8|BEST|22,473|328|0|||
|44|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|ORAL_MORPHINE_EQUIV_mg_POD_DAY2|Num|8|BEST|22,473|265|0|||
|45|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|ORAL_MORPHINE_EQUIV_mg_POD_DAY3|Num|8|BEST|22,473|210|0|||
|46|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|ORAL_MORPHINE_EQUIV_mg_POD_DAY4|Num|8|BEST|22,473|186|0|||
|47|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|ORAL_MORPHINE_EQUIV_mg_POD_DAY5|Num|8|BEST|22,473|157|0|||
|48|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|ORAL_MORPHINE_EQUIV_mg_POD_DAY6|Num|8|BEST|22,473|143|0|||
|49|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|ORAL_MORPHINE_EQUIV_mg_POD_DAY7|Num|8|BEST|22,473|119|0|||
|50|ABP_LESS_THAN_60_COUNT|ABP_LESS_THAN_60_COUNT|Num|8|BEST|3,519|229|0|||
|51|ABP_LESS_THAN_70_COUNT|ABP_LESS_THAN_70_COUNT|Num|8|BEST|3,919|370|0|||
|52|ABP_LESS_THAN_80_COUNT|ABP_LESS_THAN_80_COUNT|Num|8|BEST|4,010|521|0|||
|53|BIS_INDEX_LESS_30_COUNT|BIS_INDEX_LESS_30_COUNT|Num|8|BEST|3,604|229|0|||
|54|BIS_INDEX_LESS_40_COUNT|BIS_INDEX_LESS_40_COUNT|Num|8|BEST|5,173|352|0|||
|55|NIBP_LESS_60_COUNT|NIBP_LESS_60_COUNT|Num|8|BEST|7,549|61|0|||
|56|NIBP_LESS_70_COUNT|NIBP_LESS_70_COUNT|Num|8|BEST|13,229|115|0|||
|57|NIBP_LESS_80_COUNT|NIBP_LESS_80_COUNT|Num|8|BEST|16,846|177|0|||
|58|SD_ABP_Mean|SD_ABP_Mean|Num|8|BEST|4,005|2,696|0|||
|59|SD_NIBP_mean|SD_NIBP_mean|Num|8|BEST|18,054|16,123|0|||
|60|SD_BIS_index|SD_BIS_index|Num|8|BEST|5,601|5,470|0|||
|61|AVG_ABP_Mean|AVG_ABP_Mean|Num|8|BEST|4,005|2,696|0|||
|62|AVG_NIBP_mean|AVG_NIBP_mean|Num|8|BEST|18,866|7,143|0|||
|63|AVG_BIS_index|AVG_BIS_index|Num|8|BEST|5,609|4,398|0|||
|64|Total_Phenylephrine_HCl_Pressors|Total_Phenylephrine_HCl_Pressors_mg|Num|8|BEST|22,473|12,926|0|||
|65|Total_EPHEDRINE_SULFATE_PRESSORS|Total_EPHEDRINE_SULFATE_PRESSORS_mg|Num|8|BEST|22,473|54|0|||
|66|Total_Midazolam_mg|Total_Midazolam_mg|Num|8|BEST|22,473|18|0|||
|67|Total_Phenylephrine_HCI_mg|Total_Phenylephrine_HCI_mg|Num|8|BEST|22,473|3|0|||
|68|Total_Norepinephrine_Bitartrate_|Total_Norepinephrine_Bitartrate_MAR_mg|Num|8|BEST|22,473|250|0|||

## Unit 23: All_YEARS_LAT_LONG_20231127.csv

|#|SAS name|header|type|len|format|non-missing|levels|placeholders|years|ID|
|---|---|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|PRECEDE Study ID|Char|12|$|41,150|41,150|0||yes|
|2|Latitude|Latitude|Num|8|BEST|38,755|24,575|0|||
|3|Longitude|Longitude|Num|8|BEST|38,755|24,471|0|||
|4|YEAR|YEAR|Char|9|$|41,150|4|0|||

## ID-like columns

Case-ID overlap uses 5-digit IDs normalized to Precede##### (PDD-D-19). MRN overlap compares raw values.

|unit|column|non-missing rows|distinct|1 row per value|in spine case IDs|not in spine case IDs|in spine MRNs|not in spine MRNs|
|---|---|---|---|---|---|---|---|---|
|1|PRECEDE Study ID|41,423|41,423|yes|31,438|9,985|0|41,423|
|1|PRECEDE_ID_NUM|41,423|41,422|no|0|41,422|0|41,422|
|2|PRECEDE Study ID|22,476|22,476|yes|22,472|<11|0|22,476|
|3|Age at Encounter|13,608|35|no|0|35|0|35|
|3|ENCRYPTED_ENCOUNTER|14,559|14,347|no|0|14,347|0|14,347|
|3|ENCRYPTED_MRN|14,777|13,044|no|0|13,044|13,044|0|
|3|ID|14,778|14,778|yes|0|14,778|0|14,778|
|3|PRECEDE Study ID|14,778|14,778|yes|14,778|0|0|14,778|
|4|ENCRYPTED_ENCOUNTER|14,781|14,352|no|0|14,352|<11|14,351|
|4|PRECEDE Study ID|14,781|14,781|yes|14,777|<11|0|14,781|
|5|ENCRYPTED_MRN|14,781|13,047|no|0|13,047|13,045|<11|
|5|PRECEDE Study ID|14,781|14,781|yes|14,777|<11|0|14,781|
|6|Age_at_Encounter|13,607|35|no|0|35|0|35|
|6|ENCRYPTED_ENCOUNTER|14,560|14,348|no|0|14,348|0|14,348|
|6|ENCRYPTED_MRN|14,778|13,044|no|0|13,044|0|13,044|
|6|Precede_aim1_2_month|14,790|24|no|0|24|0|24|
|6|aim3_enroll_id|122|122|yes|0|122|0|122|
|6|pecan_attending|1,490|<11|no|0|<11|0|<11|
|6|pecan_clock_flag|2,919|<11|no|0|<11|0|<11|
|6|pecan_flag|3,213|<11|no|0|<11|0|<11|
|6|pecan_tested|1,655|<11|no|0|<11|0|<11|
|6|pecan_testing|8,927|<11|no|0|<11|0|<11|
|6|pecan_trainee|720|24|no|0|24|0|24|
|6|pecaner|14,807|<11|no|0|<11|0|<11|
|6|precede_aim1_2_Week|14,786|106|no|0|106|0|106|
|6|precede_aim1_2_clock_file_notes|684|<11|no|0|<11|0|<11|
|6|precede_aim1_2_clock_missing|14,790|<11|no|0|<11|0|<11|
|6|precede_aim1_2_location|13,973|<11|no|0|<11|0|<11|
|6|precede_aim1_2_notes|47|32|no|0|32|0|32|
|6|precede_aim1_2_nurse_notes|261|240|no|0|240|0|240|
|6|precede_aim1_2_physical_limitati|146|114|no|0|114|0|114|
|6|precede_aim1_2_scoring_issues|<11|<11|no|0|<11|0|<11|
|6|precede_aim1_2_year|14,790|<11|no|0|<11|0|<11|
|6|studyid|14,807|14,807|yes|14,778|29|0|14,807|
|7|Age at Encounter|13,608|26|no|0|26|0|26|
|7|ENCRYPTED_ENCOUNTER|14,559|14,347|no|0|14,347|0|14,347|
|7|ENCRYPTED_MRN|14,777|13,044|no|0|13,044|13,044|0|
|7|PRECEDE Study ID|14,778|14,778|yes|14,778|0|0|14,778|
|8|PRECEDE Study ID|3,456|3,456|yes|2,688|768|0|3,456|
|9|Age at Encounter|38,755|36|no|0|36|0|36|
|9|ENCRYPTED_ENCOUNTER|40,229|39,752|no|0|39,752|<11|39,751|
|9|ENCRYPTED_MRN|41,149|31,136|no|0|31,136|31,136|0|
|9|PRECEDE_Study_ID|41,150|41,150|yes|41,150|0|0|41,150|
|10|Age at Encounter|7,072|33|no|0|33|0|33|
|10|ENCRYPTED_ENCOUNTER|7,381|7,381|yes|0|7,381|0|7,381|
|10|ENCRYPTED_MRN|7,695|6,679|no|0|6,679|6,679|0|
|10|ID|7,695|7,695|yes|0|7,695|0|7,695|
|10|PRECEDE Study ID|7,695|7,695|yes|7,695|0|0|7,695|
|10|SORT_ID|7,695|7,695|yes|0|7,695|0|7,695|
|11|studyid|7,696|7,696|yes|7,695|<11|0|7,696|
|12|Age at Encounter|7,072|25|no|0|25|0|25|
|12|ENCRYPTED_ENCOUNTER|7,381|7,381|yes|0|7,381|0|7,381|
|12|ENCRYPTED_MRN|7,695|6,679|no|0|6,679|6,679|0|
|12|PRECEDE Study ID|7,695|7,695|yes|7,695|0|0|7,695|
|12|SORT_ID|7,695|7,695|yes|0|7,695|0|7,695|
|13|PRECEDE Study ID|9,462|9,462|yes|9,462|0|0|9,462|
|14|PRECEDE Study ID|9,462|9,462|yes|9,462|0|0|9,462|
|15|Age at Encounter|9,017|25|no|0|25|0|25|
|15|ENCRYPTED_ENCOUNTER|9,074|9,071|no|0|9,071|0|9,071|
|15|ENCRYPTED_MRN|9,462|7,982|no|0|7,982|7,982|0|
|15|PRECEDE Study ID|9,462|9,462|yes|9,462|0|0|9,462|
|16|PRECEDE Study ID|9,215|9,215|yes|0|9,215|0|9,215|
|17|Age at Encounter|9,058|25|no|0|25|0|25|
|17|ENCRYPTED_ENCOUNTER|9,215|9,054|no|0|9,054|<11|9,053|
|17|ENCRYPTED_MRN|9,215|8,172|no|0|8,172|8,172|0|
|17|PRECEDE Study ID|9,215|9,215|yes|0|9,215|0|9,215|
|18|PRECEDE Study ID|9,485|9,484|no|0|9,484|0|9,484|
|19|Age at Encounter|9,990|36|no|0|36|0|36|
|19|ENCRYPTED_ENCOUNTER|10,772|10,045|no|0|10,045|<11|10,044|
|19|ENCRYPTED_MRN|10,772|8,984|no|0|8,984|0|8,984|
|19|PRECEDE Study ID|10,772|10,772|yes|0|10,772|0|10,772|
|20|Age at Encounter|12,093|38|no|0|38|0|38|
|20|ENCRYPTED_ENCOUNTER|13,029|12,251|no|0|12,251|<11|12,250|
|20|ENCRYPTED_MRN|13,029|10,645|no|0|10,645|0|10,645|
|20|PRECEDE Study ID|13,029|13,029|yes|0|13,029|0|13,029|
|21|Age at Encounter|11,813|36|no|0|36|0|36|
|21|ENCRYPTED_ENCOUNTER|12,689|12,302|no|0|12,302|<11|12,301|
|21|ENCRYPTED_MRN|12,689|11,124|no|0|11,124|0|11,124|
|21|PRECEDE Study ID|12,689|12,689|yes|0|12,689|0|12,689|
|22|Age at Encounter|22,473|37|no|0|37|0|37|
|22|ENCRYPTED_ENCOUNTER|22,254|21,696|no|0|21,696|0|21,696|
|22|ENCRYPTED_MRN|22,472|18,801|no|0|18,801|18,801|0|
|22|PRECEDE Study ID|22,473|22,473|yes|22,473|0|0|22,473|
|23|PRECEDE Study ID|41,150|41,150|yes|31,935|9,215|0|41,150|

## ID value shapes (top 5 per column)

|unit|column|rank|shape|rows|
|---|---|---|---|---|
|1|PRECEDE Study ID|1|AAAAAAA99999|31,442|
|1|PRECEDE Study ID|2|99999|9,980|
|1|PRECEDE Study ID|3|LONG len=18 mixed|<11|
|1|PRECEDE_ID_NUM|1|99999|31,451|
|1|PRECEDE_ID_NUM|2|9999|8,989|
|1|PRECEDE_ID_NUM|3|999|890|
|1|PRECEDE_ID_NUM|4|99|84|
|1|PRECEDE_ID_NUM|5|9|<11|
|2|PRECEDE Study ID|1|AAAAAAA99999|22,475|
|2|PRECEDE Study ID|2|LONG len=18 mixed|<11|
|3|Age at Encounter|1|99|13,607|
|3|Age at Encounter|2|999|<11|
|3|ENCRYPTED_ENCOUNTER|1|LONG len=34 mixed|3,634|
|3|ENCRYPTED_ENCOUNTER|2|LONG len=37 mixed|3,451|
|3|ENCRYPTED_ENCOUNTER|3|LONG len=31 mixed|2,314|
|3|ENCRYPTED_ENCOUNTER|4|LONG len=40 mixed|1,837|
|3|ENCRYPTED_ENCOUNTER|5|LONG len=28 mixed|1,012|
|3|ENCRYPTED_MRN|1|LONG len=30 mixed|2,269|
|3|ENCRYPTED_MRN|2|LONG len=27 mixed|2,097|
|3|ENCRYPTED_MRN|3|LONG len=33 mixed|1,482|
|3|ENCRYPTED_MRN|4|LONG len=31 mixed|1,377|
|3|ENCRYPTED_MRN|5|LONG len=24 mixed|1,219|
|3|ID|1|9999|9,000|
|3|ID|2|99999|4,779|
|3|ID|3|999|900|
|3|ID|4|99|90|
|3|ID|5|9|<11|
|3|PRECEDE Study ID|1|AAAAAAA99999|14,778|
|4|ENCRYPTED_ENCOUNTER|1|LONG len=34 mixed|3,634|
|4|ENCRYPTED_ENCOUNTER|2|LONG len=37 mixed|3,452|
|4|ENCRYPTED_ENCOUNTER|3|LONG len=31 mixed|2,314|
|4|ENCRYPTED_ENCOUNTER|4|LONG len=40 mixed|1,838|
|4|ENCRYPTED_ENCOUNTER|5|LONG len=28 mixed|1,013|
|4|PRECEDE Study ID|1|AAAAAAA99999|14,780|
|4|PRECEDE Study ID|2|LONG len=18 mixed|<11|
|5|ENCRYPTED_MRN|1|LONG len=30 mixed|2,271|
|5|ENCRYPTED_MRN|2|LONG len=27 mixed|2,098|
|5|ENCRYPTED_MRN|3|LONG len=33 mixed|1,482|
|5|ENCRYPTED_MRN|4|LONG len=31 mixed|1,377|
|5|ENCRYPTED_MRN|5|LONG len=24 mixed|1,219|
|5|PRECEDE Study ID|1|AAAAAAA99999|14,780|
|5|PRECEDE Study ID|2|LONG len=18 mixed|<11|
|6|Age_at_Encounter|1|99|13,606|
|6|Age_at_Encounter|2|999|<11|
|6|ENCRYPTED_ENCOUNTER|1|LONG len=43 mixed|3,601|
|6|ENCRYPTED_ENCOUNTER|2|LONG len=40 mixed|3,533|
|6|ENCRYPTED_ENCOUNTER|3|LONG len=37 mixed|2,208|
|6|ENCRYPTED_ENCOUNTER|4|LONG len=46 mixed|1,912|
|6|ENCRYPTED_ENCOUNTER|5|LONG len=34 mixed|776|
|6|ENCRYPTED_MRN|1|LONG len=27 mixed|1,962|
|6|ENCRYPTED_MRN|2|LONG len=24 mixed|1,593|
|6|ENCRYPTED_MRN|3|LONG len=30 mixed|1,580|
|6|ENCRYPTED_MRN|4|LONG len=31 mixed|1,241|
|6|ENCRYPTED_MRN|5|LONG len=33 mixed|1,093|
|6|Precede_aim1_2_month|1|99|9,379|
|6|Precede_aim1_2_month|2|9|5,411|
|6|aim3_enroll_id|1|AAAA999|122|
|6|pecan_attending|1|AA. AAAAA|654|
|6|pecan_attending|2|AA. AAAAAA|601|
|6|pecan_attending|3|AA. AAAA|210|
|6|pecan_attending|4|AA. AAAAAAA|15|
|6|pecan_attending|5|AAAAA|<11|
|6|pecan_clock_flag|1|9|2,919|
|6|pecan_flag|1|99|2,651|
|6|pecan_flag|2|9|562|
|6|pecan_tested|1|9|1,655|
|6|pecan_testing|1|9|8,927|
|6|pecan_trainee|1|AA|292|
|6|pecan_trainee|2|AAAAA|132|
|6|pecan_trainee|3|A. AAAAA|131|
|6|pecan_trainee|4|A. AAAAAAAA|80|
|6|pecan_trainee|5|A. AAAAAA|44|
|6|pecaner|1|9|14,807|
|6|precede_aim1_2_Week|1|99|12,597|
|6|precede_aim1_2_Week|2|9|1,297|
|6|precede_aim1_2_Week|3|999|892|
|6|precede_aim1_2_clock_file_notes|1|9|679|
|6|precede_aim1_2_clock_file_notes|2|LONG len=17 mixed|<11|
|6|precede_aim1_2_clock_file_notes|3|AAA AAAAAA|<11|
|6|precede_aim1_2_clock_missing|1|9|14,790|
|6|precede_aim1_2_location|1|AA|6,962|
|6|precede_aim1_2_location|2|AAA|4,999|
|6|precede_aim1_2_location|3|AAAA|2,012|
|6|precede_aim1_2_notes|1|LONG len=29 mixed|<11|
|6|precede_aim1_2_notes|2|AA AAA AAAAAA|<11|
|6|precede_aim1_2_notes|3|LONG len=44 mixed|<11|
|6|precede_aim1_2_notes|4|LONG len=19 mixed|<11|
|6|precede_aim1_2_notes|5|AAAAA AAAA|<11|
|6|precede_aim1_2_nurse_notes|1|LONG len=32 mixed|<11|
|6|precede_aim1_2_nurse_notes|2|AA AAAAAAA|<11|
|6|precede_aim1_2_nurse_notes|3|LONG len=20 mixed|<11|
|6|precede_aim1_2_nurse_notes|4|LONG len=16 mixed|<11|
|6|precede_aim1_2_nurse_notes|5|LONG len=37 mixed|<11|
|6|precede_aim1_2_physical_limitati|1|AAAAA|18|
|6|precede_aim1_2_physical_limitati|2|AAA|<11|
|6|precede_aim1_2_physical_limitati|3|LONG len=19 mixed|<11|
|6|precede_aim1_2_physical_limitati|4|AAAAAAA AAAAAAA|<11|
|6|precede_aim1_2_physical_limitati|5|LONG len=18 mixed|<11|
|6|precede_aim1_2_scoring_issues|1|LONG len=18 mixed|<11|
|6|precede_aim1_2_scoring_issues|2|LONG len=68 mixed|<11|
|6|precede_aim1_2_scoring_issues|3|AAAAAAA AAAA|<11|
|6|precede_aim1_2_scoring_issues|4|AA A AAAAA|<11|
|6|precede_aim1_2_year|1|9|14,790|
|6|studyid|1|AAAAAAA99999|14,807|
|7|Age at Encounter|1|99|13,608|
|7|ENCRYPTED_ENCOUNTER|1|LONG len=34 mixed|3,634|
|7|ENCRYPTED_ENCOUNTER|2|LONG len=37 mixed|3,451|
|7|ENCRYPTED_ENCOUNTER|3|LONG len=31 mixed|2,314|
|7|ENCRYPTED_ENCOUNTER|4|LONG len=40 mixed|1,837|
|7|ENCRYPTED_ENCOUNTER|5|LONG len=28 mixed|1,012|
|7|ENCRYPTED_MRN|1|LONG len=30 mixed|2,269|
|7|ENCRYPTED_MRN|2|LONG len=27 mixed|2,097|
|7|ENCRYPTED_MRN|3|LONG len=33 mixed|1,482|
|7|ENCRYPTED_MRN|4|LONG len=31 mixed|1,377|
|7|ENCRYPTED_MRN|5|LONG len=24 mixed|1,219|
|7|PRECEDE Study ID|1|AAAAAAA99999|14,778|
|8|PRECEDE Study ID|1|AAAAAAA99999|2,688|
|8|PRECEDE Study ID|2|99999|768|
|9|Age at Encounter|1|99|38,754|
|9|Age at Encounter|2|999|<11|
|9|ENCRYPTED_ENCOUNTER|1|LONG len=37 mixed|9,506|
|9|ENCRYPTED_ENCOUNTER|2|LONG len=34 mixed|9,080|
|9|ENCRYPTED_ENCOUNTER|3|LONG len=40 mixed|5,852|
|9|ENCRYPTED_ENCOUNTER|4|LONG len=31 mixed|5,208|
|9|ENCRYPTED_ENCOUNTER|5|LONG len=43 mixed|1,971|
|9|ENCRYPTED_MRN|1|LONG len=27 mixed|8,005|
|9|ENCRYPTED_MRN|2|LONG len=30 mixed|6,703|
|9|ENCRYPTED_MRN|3|LONG len=24 mixed|5,664|
|9|ENCRYPTED_MRN|4|LONG len=33 mixed|3,606|
|9|ENCRYPTED_MRN|5|LONG len=21 mixed|2,595|
|9|PRECEDE_Study_ID|1|AAAAAAA99999|41,150|
|10|Age at Encounter|1|99|7,072|
|10|ENCRYPTED_ENCOUNTER|1|LONG len=37 mixed|1,818|
|10|ENCRYPTED_ENCOUNTER|2|LONG len=40 mixed|1,538|
|10|ENCRYPTED_ENCOUNTER|3|LONG len=34 mixed|1,178|
|10|ENCRYPTED_ENCOUNTER|4|LONG len=43 mixed|767|
|10|ENCRYPTED_ENCOUNTER|5|LONG len=31 mixed|446|
|10|ENCRYPTED_MRN|1|LONG len=27 mixed|1,695|
|10|ENCRYPTED_MRN|2|LONG len=30 mixed|1,455|
|10|ENCRYPTED_MRN|3|LONG len=24 mixed|1,201|
|10|ENCRYPTED_MRN|4|LONG len=33 mixed|735|
|10|ENCRYPTED_MRN|5|LONG len=21 mixed|527|
|10|ID|1|9999|6,696|
|10|ID|2|999|900|
|10|ID|3|99|90|
|10|ID|4|9|<11|
|10|PRECEDE Study ID|1|AAAAAAA99999|7,695|
|10|SORT_ID|1|9999|6,696|
|10|SORT_ID|2|999|900|
|10|SORT_ID|3|99|90|
|10|SORT_ID|4|9|<11|
|11|studyid|1|AAAAAAA99999|7,696|
|12|Age at Encounter|1|99|7,072|
|12|ENCRYPTED_ENCOUNTER|1|LONG len=37 mixed|1,818|
|12|ENCRYPTED_ENCOUNTER|2|LONG len=40 mixed|1,538|
|12|ENCRYPTED_ENCOUNTER|3|LONG len=34 mixed|1,178|
|12|ENCRYPTED_ENCOUNTER|4|LONG len=43 mixed|767|
|12|ENCRYPTED_ENCOUNTER|5|LONG len=31 mixed|446|
|12|ENCRYPTED_MRN|1|LONG len=27 mixed|1,695|
|12|ENCRYPTED_MRN|2|LONG len=30 mixed|1,455|
|12|ENCRYPTED_MRN|3|LONG len=24 mixed|1,201|
|12|ENCRYPTED_MRN|4|LONG len=33 mixed|735|
|12|ENCRYPTED_MRN|5|LONG len=21 mixed|527|
|12|PRECEDE Study ID|1|AAAAAAA99999|7,695|
|12|SORT_ID|1|9999|6,696|
|12|SORT_ID|2|999|900|
|12|SORT_ID|3|99|90|
|12|SORT_ID|4|9|<11|
|13|PRECEDE Study ID|1|AAAAAAA99999|9,462|
|14|PRECEDE Study ID|1|AAAAAAA99999|9,462|
|15|Age at Encounter|1|99|9,017|
|15|ENCRYPTED_ENCOUNTER|1|LONG len=34 mixed|2,027|
|15|ENCRYPTED_ENCOUNTER|2|LONG len=37 mixed|2,009|
|15|ENCRYPTED_ENCOUNTER|3|LONG len=40 mixed|1,263|
|15|ENCRYPTED_ENCOUNTER|4|LONG len=31 mixed|1,152|
|15|ENCRYPTED_ENCOUNTER|5|LONG len=43 mixed|453|
|15|ENCRYPTED_MRN|1|LONG len=27 mixed|2,155|
|15|ENCRYPTED_MRN|2|LONG len=24 mixed|1,634|
|15|ENCRYPTED_MRN|3|LONG len=30 mixed|1,617|
|15|ENCRYPTED_MRN|4|LONG len=33 mixed|783|
|15|ENCRYPTED_MRN|5|LONG len=21 mixed|778|
|15|PRECEDE Study ID|1|AAAAAAA99999|9,462|
|16|PRECEDE Study ID|1|99999|9,215|
|17|Age at Encounter|1|99|9,058|
|17|ENCRYPTED_ENCOUNTER|1|LONG len=34 mixed|2,241|
|17|ENCRYPTED_ENCOUNTER|2|LONG len=37 mixed|2,228|
|17|ENCRYPTED_ENCOUNTER|3|LONG len=31 mixed|1,296|
|17|ENCRYPTED_ENCOUNTER|4|LONG len=40 mixed|1,214|
|17|ENCRYPTED_ENCOUNTER|5|LONG len=28 mixed|421|
|17|ENCRYPTED_MRN|1|LONG len=27 mixed|2,058|
|17|ENCRYPTED_MRN|2|LONG len=24 mixed|1,610|
|17|ENCRYPTED_MRN|3|LONG len=30 mixed|1,362|
|17|ENCRYPTED_MRN|4|LONG len=21 mixed|832|
|17|ENCRYPTED_MRN|5|LONG len=33 mixed|606|
|17|PRECEDE Study ID|1|99999|9,215|
|18|PRECEDE Study ID|1|99999|9,485|
|19|Age at Encounter|1|99|9,990|
|19|ENCRYPTED_ENCOUNTER|1|LONG len=42 mixed|2,093|
|19|ENCRYPTED_ENCOUNTER|2|LONG len=45 mixed|2,090|
|19|ENCRYPTED_ENCOUNTER|3|LONG len=48 mixed|1,416|
|19|ENCRYPTED_ENCOUNTER|4|LONG len=39 mixed|1,315|
|19|ENCRYPTED_ENCOUNTER|5|LONG len=36 mixed|554|
|19|ENCRYPTED_MRN|1|LONG len=32 mixed|1,907|
|19|ENCRYPTED_MRN|2|LONG len=35 mixed|1,713|
|19|ENCRYPTED_MRN|3|LONG len=29 mixed|1,512|
|19|ENCRYPTED_MRN|4|LONG len=38 mixed|1,072|
|19|ENCRYPTED_MRN|5|LONG len=26 mixed|759|
|19|PRECEDE Study ID|1|99999|10,772|
|20|Age at Encounter|1|99|12,093|
|20|ENCRYPTED_ENCOUNTER|1|LONG len=42 mixed|2,264|
|20|ENCRYPTED_ENCOUNTER|2|LONG len=39 mixed|2,172|
|20|ENCRYPTED_ENCOUNTER|3|LONG len=45 mixed|1,841|
|20|ENCRYPTED_ENCOUNTER|4|LONG len=36 mixed|1,550|
|20|ENCRYPTED_ENCOUNTER|5|LONG len=48 mixed|1,232|
|20|ENCRYPTED_MRN|1|LONG len=32 mixed|2,544|
|20|ENCRYPTED_MRN|2|LONG len=35 mixed|2,086|
|20|ENCRYPTED_MRN|3|LONG len=29 mixed|1,960|
|20|ENCRYPTED_MRN|4|LONG len=38 mixed|1,203|
|20|ENCRYPTED_MRN|5|LONG len=26 mixed|918|
|20|PRECEDE Study ID|1|99999|13,029|
|21|Age at Encounter|1|99|11,813|
|21|ENCRYPTED_ENCOUNTER|1|LONG len=39 mixed|2,668|
|21|ENCRYPTED_ENCOUNTER|2|LONG len=42 mixed|2,499|
|21|ENCRYPTED_ENCOUNTER|3|LONG len=36 mixed|1,992|
|21|ENCRYPTED_ENCOUNTER|4|LONG len=45 mixed|1,470|
|21|ENCRYPTED_ENCOUNTER|5|LONG len=33 mixed|1,017|
|21|ENCRYPTED_MRN|1|LONG len=32 mixed|2,198|
|21|ENCRYPTED_MRN|2|LONG len=35 mixed|2,099|
|21|ENCRYPTED_MRN|3|LONG len=29 mixed|1,549|
|21|ENCRYPTED_MRN|4|LONG len=38 mixed|1,438|
|21|ENCRYPTED_MRN|5|LONG len=26 mixed|734|
|21|PRECEDE Study ID|1|99999|12,689|
|22|Age at Encounter|1|99|20,679|
|22|Age at Encounter|2|AAAA|1,793|
|22|Age at Encounter|3|999|<11|
|22|ENCRYPTED_ENCOUNTER|1|LONG len=37 mixed|5,269|
|22|ENCRYPTED_ENCOUNTER|2|LONG len=34 mixed|4,812|
|22|ENCRYPTED_ENCOUNTER|3|LONG len=40 mixed|3,375|
|22|ENCRYPTED_ENCOUNTER|4|LONG len=31 mixed|2,760|
|22|ENCRYPTED_ENCOUNTER|5|LONG len=43 mixed|1,207|
|22|ENCRYPTED_MRN|1|LONG len=27 mixed|3,792|
|22|ENCRYPTED_MRN|2|LONG len=30 mixed|3,724|
|22|ENCRYPTED_MRN|3|LONG len=24 mixed|2,420|
|22|ENCRYPTED_MRN|4|LONG len=33 mixed|2,217|
|22|ENCRYPTED_MRN|5|LONG len=31 mixed|1,510|
|22|PRECEDE Study ID|1|AAAAAAA99999|22,473|
|23|PRECEDE Study ID|1|AAAAAAA99999|31,935|
|23|PRECEDE Study ID|2|99999|9,215|

End of probe.
