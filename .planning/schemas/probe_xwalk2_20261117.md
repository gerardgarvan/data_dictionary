# Probe: xwalk vs spine, follow-up (PR-2)
 
Metadata and counts only. No MRN or ID values. Counts 1-10 shown as <11.
Written by sas/17_probe_xwalk2.sas on 2026-11-17.
Looser keys: upcase(strip(x)), compress(x,,"s") removing all whitespace, and both.
Lengths and declared lengths are not counts and are not suppressed.
 
## 1. MRN profile: spine and xwalk
 
|item|value|
|---|---|
|spine pdd.src_s09: row count|41,150|
|spine pdd.src_s09: distinct strip(ENCRYPTED_MRN) non-blank|31,136|
|spine pdd.src_s09: blank or missing ENCRYPTED_MRN|<11|
|spine pdd.src_s09: ENCRYPTED_MRN equal to NULL text|0|
|spine pdd.src_s09: declared variable length - not a count|44|
|spine pdd.src_s09: min lengthn of strip(ENCRYPTED_MRN) - not a count|8|
|spine pdd.src_s09: max lengthn of strip(ENCRYPTED_MRN) - not a count|40|
|spine pdd.src_s09: leading whitespace|0|
|spine pdd.src_s09: trailing tab or CR or LF - plain trailing blanks undetectable|0|
|spine pdd.src_s09: tab or CR or LF anywhere|0|
|spine pdd.src_s09: any whitespace character after strip|768|
|spine pdd.src_s09: embedded whitespace between non-blank characters|768|
|spine pdd.src_s09: contains lowercase letter a-z|41,149|
|spine pdd.src_s09: lengthn = 40 - possible truncation|86|
|spine pdd.src_s09: lengthn = declared variable length 44|0|
|xwalk g.pecan_id_xwalk: row count|33,031|
|xwalk g.pecan_id_xwalk: distinct strip(ENCRYPTED_MRN) non-blank|33,031|
|xwalk g.pecan_id_xwalk: blank or missing ENCRYPTED_MRN|0|
|xwalk g.pecan_id_xwalk: ENCRYPTED_MRN equal to NULL text|0|
|xwalk g.pecan_id_xwalk: declared variable length - not a count|40|
|xwalk g.pecan_id_xwalk: min lengthn of strip(ENCRYPTED_MRN) - not a count|8|
|xwalk g.pecan_id_xwalk: max lengthn of strip(ENCRYPTED_MRN) - not a count|40|
|xwalk g.pecan_id_xwalk: leading whitespace|0|
|xwalk g.pecan_id_xwalk: trailing tab or CR or LF - plain trailing blanks undetectable|0|
|xwalk g.pecan_id_xwalk: tab or CR or LF anywhere|0|
|xwalk g.pecan_id_xwalk: any whitespace character after strip|687|
|xwalk g.pecan_id_xwalk: embedded whitespace between non-blank characters|687|
|xwalk g.pecan_id_xwalk: contains lowercase letter a-z|33,031|
|xwalk g.pecan_id_xwalk: lengthn = 40 - possible truncation|27|
|xwalk g.pecan_id_xwalk: lengthn = declared variable length 40|27|
 
### 1b. Length histogram of strip(ENCRYPTED_MRN)
 
|length|spine rows|xwalk rows|
|---|---|---|
|8|<11|<11|
|12|<11|<11|
|13|<11|<11|
|14|19|14|
|15|63|73|
|16|34|32|
|17|134|117|
|18|605|639|
|19|211|203|
|20|603|488|
|21|2,595|2,391|
|22|567|535|
|23|1,359|1,053|
|24|5,664|4,891|
|25|1,153|1,110|
|26|1,883|1,434|
|27|8,005|6,219|
|28|1,464|1,439|
|29|1,394|1,060|
|30|6,703|4,605|
|31|1,737|1,409|
|32|475|404|
|33|3,606|2,471|
|34|1,207|998|
|35|74|63|
|36|981|886|
|37|499|341|
|38|20|<11|
|39|-|115|
|40|86|27|
 
## 2. Spine to xwalk match under looser rules
 
|item|value|
|---|---|
|xwalk distinct MRN exact|33,031|
|xwalk distinct after upcase - fewer means case collisions|33,031|
|xwalk distinct after compress whitespace|33,031|
|xwalk distinct after upcase and compress|33,031|
|spine distinct MRN exact|31,136|
|spine distinct after upcase|31,136|
|spine distinct after compress whitespace|31,136|
|spine distinct after upcase and compress|31,136|
|rule exact strip: spine distinct MRN matched|19,987|
|rule exact strip: spine distinct MRN not matched|11,149|
|rule exact strip: spine rows matched|28,737|
|rule exact strip: spine rows not matched|12,412|
|rule exact strip: distinct MRN gained over exact match|0|
|rule upcase(strip): spine distinct MRN matched|19,987|
|rule upcase(strip): spine distinct MRN not matched|11,149|
|rule upcase(strip): spine rows matched|28,737|
|rule upcase(strip): spine rows not matched|12,412|
|rule upcase(strip): distinct MRN gained over exact match|0|
|rule compress all whitespace: spine distinct MRN matched|19,987|
|rule compress all whitespace: spine distinct MRN not matched|11,149|
|rule compress all whitespace: spine rows matched|28,737|
|rule compress all whitespace: spine rows not matched|12,412|
|rule compress all whitespace: distinct MRN gained over exact match|0|
|rule upcase and compress: spine distinct MRN matched|19,987|
|rule upcase and compress: spine distinct MRN not matched|11,149|
|rule upcase and compress: spine rows matched|28,737|
|rule upcase and compress: spine rows not matched|12,412|
|rule upcase and compress: distinct MRN gained over exact match|0|
 
## 3. By spine YEAR (rows and distinct MRN; distinct MRN can repeat across years)
 
|year|rows|blank MRN rows|exact matched rows|exact unmatched rows|exact matched distinct|exact unmatched distinct|upcase+compress matched rows|upcase+compress unmatched rows|upcase+compress matched distinct|upcase+compress unmatched distinct|
|---|---|---|---|---|---|---|---|---|---|---|
|2018|14,229|<11|2,365|11,863|1,895|10,665|2,365|11,863|1,895|10,665|
|2019|549|0|0|549|-|549|0|549|-|549|
|2020|7,695|0|7,695|0|6,679|-|7,695|0|6,679|-|
|2021|9,462|0|9,462|0|7,982|-|9,462|0|7,982|-|
|2022|9,215|0|9,215|0|8,172|-|9,215|0|8,172|-|
 
## 4. pdd.src_s01..s20 MRN-like columns: members
 
|item|value|
|---|---|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
|pdd.src_s MRN-like columns - count|<11|
|pdd.src_s MRN-like columns - count|0|
 
### 4b. Columns with MRN in the SAS name (distinct MRN, overlap with xwalk and spine)
 
|member|column|type|length|rows|non-blank|distinct|in xwalk exact|in xwalk upcase+compress|in spine exact|in spine upcase+compress|
|---|---|---|---|---|---|---|---|---|---|---|
|SRC_S03|ENCRYPTED_MRN|char|44|14,778|14,777|13,044|1,895|1,895|13,044|13,044|
|SRC_S05|ENCRYPTED_MRN|char|44|14,781|14,781|13,047|1,896|1,896|13,045|13,045|
|SRC_S06|ENCRYPTED_MRN|char|44|14,807|14,778|13,044|13,044|13,044|0|0|
|SRC_S07|ENCRYPTED_MRN|char|44|14,778|14,777|13,044|1,895|1,895|13,044|13,044|
|SRC_S09|ENCRYPTED_MRN|char|44|41,150|41,149|31,136|19,987|19,987|31,136|31,136|
|SRC_S10|ENCRYPTED_MRN|char|40|7,695|7,695|6,679|6,679|6,679|6,679|6,679|
|SRC_S12|ENCRYPTED_MRN|char|40|7,695|7,695|6,679|6,679|6,679|6,679|6,679|
|SRC_S15|ENCRYPTED_MRN|char|40|9,462|9,462|7,982|7,982|7,982|7,982|7,982|
|SRC_S17|ENCRYPTED_MRN|char|40|9,215|9,215|8,172|8,172|8,172|8,172|8,172|
|SRC_S19|ENCRYPTED_MRN|char|44|22,473|22,472|18,801|7,652|7,652|18,801|18,801|
 
## 5. Datasets in libname g (and g2 if set) with a pecan_ID or PCNR_ID named column
 
MRN-named = character column with MRN in its name. A blank MRN column means none found.
 
|lib|dataset|ID column|ID type|rows|distinct IDs|missing IDs|MRN column|distinct MRN|MRN in spine exact|MRN in spine upcase+compress|
|---|---|---|---|---|---|---|---|---|---|---|
|G|ANALYTIC_COHORT|pecan_ID|num|13,890|12,763|0|ENCRYPTED_MRN|12,763|7,509|7,509|
|G|MASTER_DATA_HARMONIZED|pecan_ID|num|41,150|33,031|0|ENCRYPTED_MRN|33,031|19,987|19,987|
|G|PCNR_ANALYTIC_COHORT|pecan_ID|num|13,890|12,763|0|ENCRYPTED_MRN|12,763|7,509|7,509|
|G|PCNR_HARMONIZED|pecan_ID|num|41,150|33,031|0|ENCRYPTED_MRN|33,031|19,987|19,987|
|G|PECAN_ID_XWALK|pecan_ID|num|33,031|33,031|0|ENCRYPTED_MRN|33,031|19,987|19,987|
