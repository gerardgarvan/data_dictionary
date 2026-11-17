# Probe: g.pecan_id_xwalk (PR-1)
 
Metadata and counts only. No MRN or ID values. Counts 1-10 shown as <11.
Written by sas/17_probe_xwalk.sas on 2026-11-17.
 
## Variables
 
|varnum|name|type|length|format|informat|
|---|---|---|---|---|---|
|1|ENCRYPTED_MRN|Char|40|$40.|$40.|
|2|pecan_ID|Num|8|||
 
## Counts
 
|item|value|
|---|---|
|row count g.pecan_id_xwalk|33,031|
|distinct non-missing pecan_ID|33,031|
|blank or missing pecan_ID|0|
|distinct strip(ENCRYPTED_MRN) non-blank|33,031|
|blank or missing ENCRYPTED_MRN|0|
|ENCRYPTED_MRN equal to NULL text|0|
|min lengthn of strip(ENCRYPTED_MRN)|8|
|max lengthn of strip(ENCRYPTED_MRN)|40|
|leading whitespace in ENCRYPTED_MRN|0|
|trailing tab or CR or LF in ENCRYPTED_MRN - plain trailing blanks undetectable|0|
|embedded whitespace in ENCRYPTED_MRN|687|
|lengthn = 40 - possible truncation|27|
|lengthn = declared variable length 40|27|
|pdd.src_s09 distinct non-blank MRN|31,136|
|pdd.src_s09 MRN also in xwalk - exact strip match|19,987|
|pdd.src_s09 MRN not in xwalk|11,149|
|pdd.src_s09 MRN not matched exactly but first 40 chars equal an xwalk MRN|0|
|pdd.nsrc_s21 distinct non-blank MRN|8,984|
|pdd.nsrc_s21 MRN also in xwalk - exact strip match|0|
|pdd.nsrc_s21 MRN not in xwalk|8,984|
|pdd.nsrc_s21 MRN not matched exactly but first 40 chars equal an xwalk MRN|0|
|pdd.nsrc_s22 distinct non-blank MRN|10,645|
|pdd.nsrc_s22 MRN also in xwalk - exact strip match|0|
|pdd.nsrc_s22 MRN not in xwalk|10,645|
|pdd.nsrc_s22 MRN not matched exactly but first 40 chars equal an xwalk MRN|0|
|pdd.nsrc_s23 distinct non-blank MRN|11,124|
|pdd.nsrc_s23 MRN also in xwalk - exact strip match|0|
|pdd.nsrc_s23 MRN not in xwalk|11,124|
|pdd.nsrc_s23 MRN not matched exactly but first 40 chars equal an xwalk MRN|0|
