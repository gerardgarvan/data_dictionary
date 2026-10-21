/* Standalone hash test -- run in SAS to verify _compute_file_sha256.
   Expected: two 64-char hex strings for code_sha, one for spec_sha. */
%include "C:\data_dictionary\sas\00_config.sas";

/* ---- copy of the fixed helper only ---- */
%macro _compute_file_sha256(path=, outmv=);
  %let &outmv = ;
  filename _shpipe pipe "certutil -hashfile ""&path"" SHA256";
  data _null_;
    infile _shpipe truncover lrecl=400;
    length line $400 compressed $400;
    input line $400.;
    compressed = compress(line, ' ');
    if lengthn(compressed) = 64 and notxdigit(strip(compressed)) = 0 then
      call symputx("&outmv", lowcase(compressed));
  run;
  filename _shpipe clear;
%mend _compute_file_sha256;

%macro _test_hashes;
  %local _sha03 _sha00 _sha_gen;
  %_compute_file_sha256(path=C:\data_dictionary\sas\03_import.sas, outmv=_sha03);
  %_compute_file_sha256(path=C:\data_dictionary\sas\00_config.sas,  outmv=_sha00);
  %_compute_file_sha256(path=C:\data_dictionary\docs\import_spec_generated.csv, outmv=_sha_gen);
  %put NOTE: sha03=&_sha03;
  %put NOTE: sha00=&_sha00;
  %put NOTE: code_sha=&_sha03.&_sha00;
  %put NOTE: spec_sha=&_sha_gen;
%mend _test_hashes;
%_test_hashes;
