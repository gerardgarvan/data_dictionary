@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  run_pipeline.cmd -- PeCAN Data Dictionary (PDD)
REM  Batch driver. Calls sas.exe for each pipeline program.
REM
REM  Exit codes:
REM    0   = pipeline PASSED (zero ERRORs, zero WARNINGs in master log)
REM    1   = pipeline FAILED (ERROR or WARNING lines found, or :fail)
REM    2+  = STOP (sas.exe abort detected; exit code passed through)
REM
REM  Usage: run_pipeline.cmd           (full run, phases 2 3)
REM         run_pipeline.cmd 3         (dev: phase 3 only, requires prior full run)
REM         run_pipeline.cmd 2 3       (explicit: space-separated, no quotes needed)
REM  Log:   %LOGS_PATH%\99_run_all.log  (master log with per-program summary)
REM
REM  Machine override: create config.local.cmd at repo root to set SAS_EXE.
REM ============================================================

REM ---- Fixed path variables ----
set SAS_PATH=C:\data_dictionary\sas
set LOGS_PATH=P:\PeCAN Master Data\Gerard\data_dictionary\logs
set MASTER_LOG=%LOGS_PATH%\99_run_all.log

REM ---- Initialise master log ----
echo Pipeline started: %DATE% %TIME% > "%MASTER_LOG%"
echo ============================================================ >> "%MASTER_LOG%"

REM ---- Internal subroutine: run one SAS program ----
REM    Usage: call :run_program <label> <sas_file_basename>
REM    Writes one summary line to MASTER_LOG per program.
REM    Stops driver (goto :fail from caller) on exit code >= 2.
goto :main

:run_python
  set _LABEL=%~1
  set _SCRIPT=%~2
  set _LOG_FILE=%LOGS_PATH%\%~n2.log

  echo Running %_LABEL% ...
  "%PDD_PYTHON%" "%~dp0python\scripts\%_SCRIPT%" > "%LOGS_PATH%\%~n2_console.txt" 2>&1
  set _EC=!ERRORLEVEL!

  echo %DATE% %TIME%  [%_LABEL%]  exit=%_EC% >> "%MASTER_LOG%"

  if !_EC! NEQ 0 (
    echo.
    echo PIPELINE STOPPED: %_LABEL% exited with code !_EC!
    echo See log: %_LOG_FILE%
    echo PIPELINE STOPPED: %_LABEL% exit=!_EC! >> "%MASTER_LOG%"
    exit /b !_EC!
  )
  exit /b 0

:run_program
  set _LABEL=%~1
  set _PROG=%~2
  set _SAS_FILE=%SAS_PATH%\%_PROG%
  set _LOG_FILE=%LOGS_PATH%\%_PROG:.sas=%.log

  echo Running %_LABEL% ...
  start "" /wait "%SAS_EXE%" ^
      -sysin "%_SAS_FILE%" ^
      -log "%_LOG_FILE%" ^
      -nosplash -icon -sasuser WORK ^
      -config "%SAS_CFG%" ^
      -encoding utf8 ^
      -set RUN_ALL 1 ^
      -set PDD_PHASES "!PDD_PHASES!"

  set _EC=!ERRORLEVEL!

  REM Count WARNING lines in the per-program log (line-start match)
  set _WARNS=0
  for /f %%W in ('findstr /b /c:"WARNING" "%_LOG_FILE%" 2^>nul ^| find /c /v ""') do set _WARNS=%%W

  echo %DATE% %TIME%  [%_LABEL%]  exit=%_EC%  warnings=%_WARNS% >> "%MASTER_LOG%"

  if !_EC! GEQ 2 (
    echo.
    echo PIPELINE STOPPED: %_LABEL% exited with code !_EC!
    echo See log: %_LOG_FILE%
    echo PIPELINE STOPPED: %_LABEL% exit=!_EC! >> "%MASTER_LOG%"
    exit /b !_EC!
  )
  exit /b 0

:main

REM ---- Machine-specific SAS_EXE override ----
if exist "%~dp0config.local.cmd" call "%~dp0config.local.cmd"
if not defined SAS_EXE    set "SAS_EXE=C:\Program Files\SAS94\SASFoundation\9.4\sas.exe"
if not defined SAS_CFG    set "SAS_CFG=C:\Program Files\SAS94\SASFoundation\9.4\nls\u8\sasv9.cfg"
if not defined PDD_PYTHON set "PDD_PYTHON=%~dp0.venv\Scripts\python.exe"
if not exist "%SAS_EXE%" (
  echo SAS_EXE not found: "%SAS_EXE%"
  echo SAS_EXE not found: "%SAS_EXE%" >> "%MASTER_LOG%"
  goto :fail
)

REM ---- Phase selector (space-separated; default: 2 3 4) ----
set PDD_PHASES=%*
if "%PDD_PHASES%"=="" set PDD_PHASES=2 3 4
echo Running phases: %PDD_PHASES%
echo Running phases: %PDD_PHASES% >> "%MASTER_LOG%"

REM ---- Phase 1 skeleton: pipeline runner only ----
REM ---- Later phases will add 02_source_guard.sas, 03_import.sas, etc. ----
call :run_program "99 run_all" "99_run_all.sas"
if !ERRORLEVEL! NEQ 0 goto :fail

REM ---- Phase 4 Python: write name map review workbook ----
call :run_python "Phase 4 Python write_name_map_review" "write_name_map_review.py"
if !ERRORLEVEL! NEQ 0 goto :fail

REM ---- Phase 5 Python: write pcnr_qc.xlsx (only when phase 5 requested) ----
echo %PDD_PHASES% | findstr /i "\<5\>" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
  echo Phase 5 Python: writing pcnr_qc.xlsx
  set _P5_EXCHANGE=P:\PeCAN Master Data\Gerard\data_dictionary\exchange
  set _P5_QC=P:\PeCAN Master Data\Gerard\data_dictionary\qc
  "%PDD_PYTHON%" "%~dp0python\scripts\write_pcnr_qc.py" --exchange "%_P5_EXCHANGE%" --qc "%_P5_QC%" --logs "%LOGS_PATH%" >> "%LOGS_PATH%\write_pcnr_qc_console.txt" 2>&1
  if !ERRORLEVEL! NEQ 0 (
    echo Phase 5 Python FAILED -- see logs\write_pcnr_qc_console.txt
    echo Phase 5 Python FAILED >> "%MASTER_LOG%"
    goto :fail
  )
  echo Phase 5 Python complete.
) else (
  echo Phase 5 Python skipped -- phase 5 not in PDD_PHASES
)

REM ---- Scan master log for ERROR lines ----
set _ERRS=0
for /f %%E in ('findstr /b /c:"ERROR" "%MASTER_LOG%" 2^>nul ^| find /c /v ""') do set _ERRS=%%E
if !_ERRS! GTR 0 (
  echo.
  echo PIPELINE FAILED: %_ERRS% ERROR line(s) found in master log.
  echo See: %MASTER_LOG%
  echo PIPELINE FAILED: %_ERRS% ERROR lines found >> "%MASTER_LOG%"
  exit /b 1
)

REM ---- Scan master log for WARNING lines ----
set _MASTER_WARNS=0
for /f %%W in ('findstr /b /c:"WARNING" "%MASTER_LOG%" 2^>nul ^| find /c /v ""') do set _MASTER_WARNS=%%W
if !_MASTER_WARNS! GTR 0 (
  echo.
  echo PIPELINE FAILED: !_MASTER_WARNS! WARNING line(s) found in master log.
  echo See: %MASTER_LOG%
  echo PIPELINE FAILED: !_MASTER_WARNS! WARNING lines found >> "%MASTER_LOG%"
  exit /b 1
)

echo ============================================================ >> "%MASTER_LOG%"
echo Pipeline PASSED: %DATE% %TIME% >> "%MASTER_LOG%"
echo.
echo PIPELINE PASSED -- all programs completed successfully.
echo Summary log: %MASTER_LOG%
exit /b 0

:fail
echo ============================================================ >> "%MASTER_LOG%"
echo Pipeline FAILED: %DATE% %TIME% >> "%MASTER_LOG%"
echo.
echo PIPELINE FAILED -- see master log: %MASTER_LOG%
exit /b 1
