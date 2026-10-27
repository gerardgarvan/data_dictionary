# PeCAN Data Dictionary — Claude Code Rules

## After any SAS edit

Run both linters before committing:

```
python tools\sas_lint.py sas\<file>.sas
sasjs lint
```

Both must show zero errors on the edited file.

## Python setup

The pipeline interpreter is `.venv\Scripts\python.exe` (default `PDD_PYTHON` in `run_pipeline.cmd`).
Install dependencies into it before running:

```
.venv\Scripts\python.exe -m pip install -r python\requirements.txt
```

## After any Python edit

Run both quality gates before committing:

```
ruff check python\
pytest python\tests
```

Both must show zero errors / all tests pass.

## PCM compliance (enforced by sas_lint.py)

- No open-code `%if`/`%else` outside `%macro … %mend` (C3)
- No macro keyword in a quoted PUT string (C11)
- No macro called before its `%macro` definition in the same file (C13)
- No bare `data ;` / `set ;` with no dataset name (C14)
- `LIBNAME libref <engine> "path"` — engine before path (C9)
- No `??` inside PROC SQL (C1)
- No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH…AS) (C2)

## Data locations

- Repo: `C:\data_dictionary`
- Output/library: `P:\PeCAN Master Data\Gerard\data_dictionary\`
- Source files (read-only): `P:\PeCAN Master Data\00 Shared Data\DSS Received Data\1 Data Files\Master Data`
