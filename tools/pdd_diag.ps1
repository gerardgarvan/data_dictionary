# tools/pdd_diag.ps1
# PeCAN Data Dictionary -- quick diagnostic for Phase 03 state.
# Run from the repo root:  .\tools\pdd_diag.ps1
# Checks: linter, git status, key output files, source inventory.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$repo = Split-Path $PSScriptRoot -Parent

Write-Host "`n=== PDD Diagnostic ===" -ForegroundColor Cyan

# ── 1. SAS linter ────────────────────────────────────────────────────────────
Write-Host "`n[1] SAS linter (sas/03_import.sas)" -ForegroundColor Yellow
$lint = python "$PSScriptRoot\sas_lint.py" "$repo\sas\03_import.sas" 2>&1
$lint | ForEach-Object { Write-Host "    $_" }
if ($LASTEXITCODE -eq 0) {
    Write-Host "    PASS" -ForegroundColor Green
} else {
    Write-Host "    FAIL (exit $LASTEXITCODE)" -ForegroundColor Red
}

# ── 2. sasjs lint ────────────────────────────────────────────────────────────
Write-Host "`n[2] sasjs lint" -ForegroundColor Yellow
$sasjs = & sasjs lint 2>&1
$sasjs | ForEach-Object { Write-Host "    $_" }
if ($LASTEXITCODE -eq 0) {
    Write-Host "    PASS" -ForegroundColor Green
} else {
    Write-Host "    FAIL (exit $LASTEXITCODE)" -ForegroundColor Red
}

# ── 3. Git status ────────────────────────────────────────────────────────────
Write-Host "`n[3] Git status" -ForegroundColor Yellow
$st = git -C $repo status --short 2>&1
if ($st) { $st | ForEach-Object { Write-Host "    $_" } }
else      { Write-Host "    (clean)" -ForegroundColor Green }

$ahead = git -C $repo rev-list --count origin/master..HEAD 2>&1
Write-Host "    commits ahead of origin/master: $ahead"

# ── 4. Key output files ───────────────────────────────────────────────────────
Write-Host "`n[4] Key generated files" -ForegroundColor Yellow
$files = @(
    "$repo\docs\import_spec_generated.csv",
    "P:\PeCAN Master Data\Gerard\data_dictionary\03_generated_import.sas",
    "P:\PeCAN Master Data\Gerard\data_dictionary\logs\03_import.log"
)
foreach ($f in $files) {
    if (Test-Path $f) {
        $sz = (Get-Item $f).Length
        Write-Host ("    OK  {0,-60} ({1:N0} bytes)" -f $f, $sz) -ForegroundColor Green
    } else {
        Write-Host "    MISS $f" -ForegroundColor Red
    }
}

# ── 5. Phase status summary ───────────────────────────────────────────────────
Write-Host "`n[5] Phase 03 status" -ForegroundColor Yellow
$phaseFile = "$repo\.planning\phases\03_import"
if (Test-Path "$phaseFile\STATUS.md") {
    Get-Content "$phaseFile\STATUS.md" | Select-Object -First 10 |
        ForEach-Object { Write-Host "    $_" }
} else {
    Write-Host "    No STATUS.md found at $phaseFile"
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
