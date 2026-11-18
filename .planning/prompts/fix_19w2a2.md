# fix_19w2a2 - CSV readers use _INFILE_ with LRECL > 32767

After fix_19w2a the stage step compiles and writes s1_data.csv (32,975
bytes) and s1q_data.csv. 19_xlsx_test still fails T18 (all record/line/
content/quoted-max-cell checks + expected counts) and T15 (3 ERROR lines).
All 3 errors are the same:
  ERROR: The LRECL / LINESIZE for infile '...s1_data.csv' exceeds the maximum
  allowable length for an _INFILE_ or _INFILE_= variable (32,767).
Sites: %p19_csv_records (production gate used by 19b), the T18 line-compare
reader, and the T18 quoted-max-cell reader (input; _infile_ with
lrecl=1048576 length=_ln).

Do:
1. %p19_csv_records: never reference _INFILE_. Count records quote-aware by
   streaming the file in fixed chunks (e.g. infile ... recfm=n, input buffer
   $char32767. or smaller), counting '"' parity and CRLF across chunk
   boundaries (carry state between chunks). Must handle real rows longer than
   32,767 bytes. Return records and physical lines as before.
2. T18 readers: no _INFILE_ with LRECL > 32767. Read lines with length= and
   $varying (split long lines into pieces with column pointers) or reuse the
   chunk scanner; keep every existing expectation (hand-written lines 1-7,
   line 8 length 32,783, quoted max cell length/quote count).
3. Lint rule C40: an INFILE with LRECL > 32767 in a step that references
   _INFILE_ is an error. Lint test. Run both linters on all sas files.
4. Grep all sas/ for other _INFILE_ + large LRECL combinations and fix them.
5. Ruff + pytest green.

Constraints unchanged. No run against real data. Commit on
pdd-2018-2025-api; no push.
