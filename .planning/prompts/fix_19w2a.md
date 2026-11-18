# fix_19w2a - stage writer declares a character variable longer than 32767

19_xlsx_test.sas on SAS (synthetic): all tests pass except T18 and T15.
Root cause (log): %p19_stage generates
  length _pv $65540 _ps $64 _pl 8 _pn 8;
-> ERROR 353-185: The length of character variables is 1-32767.
The stage step never compiled, so s1_data.csv was not written; the two
"Physical file does not exist" errors (%p19_csv_records and the T18 line
check) and T18 records/lines/lines-match/expected-counts FAILs follow from it.
T15 counts those 3 ERROR lines.

Do:
1. Rewrite the character-cell path of %p19_stage so no variable exceeds
   $32767 and nothing is silently truncated: when a value needs quoting,
   write it in pieces directly with PUT (opening quote, then each segment
   between '"' characters followed by '""', then closing quote), using
   +(-1)/@ as needed, rather than building the quoted string in a variable.
   Keep the output byte-for-byte identical to docs/xlsx_stage_contract.md.
2. Extend T18 with a 32,767-character cell that ALSO contains several '"'
   characters, and check its line length equals 32,767 + doubled quotes +
   delimiters + 2 enclosing quotes. Keep the existing hand-written expected
   lines.
3. Add lint rule C39 to tools/sas_lint.py: a LENGTH statement (including
   one generated via put "..." text in a macro) declaring a character length
   > 32767 is an error. Add a lint test. Run both linters on all sas files.
4. Ruff + pytest green. Update 19-SAS-RUN.md only if the run order changes.

Constraints unchanged. No run against real data. Commit on
pdd-2018-2025-api; no push.
