#Requires -Version 5.1
<#
.SYNOPSIS
    Check a SAS test log for hygiene issues.

.DESCRIPTION
    Scans a SAS .log file for bad NOTE/WARNING/ERROR patterns that indicate
    latent code defects. Source-echo lines and MPRINT lines are ignored.

    Exit code 0 = PASS, 1 = FAIL.

.PARAMETER Log
    Path to the SAS log file to check.

.PARAMETER Phase
    If specified, limit scanning to the section of the log between
    "Phase <Phase>" markers (useful for 99_run_all.log).

.EXAMPLE
    .\tools\check_test_log.ps1 -Log .\logs\06_profile_test.log

.EXAMPLE
    .\tools\check_test_log.ps1 -Log .\logs\99_run_all.log -Phase "6"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Log,

    [Parameter(Mandatory=$false)]
    [string]$Phase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Read log
# ---------------------------------------------------------------------------
if (-not (Test-Path $Log)) {
    Write-Host "FAIL: Log file not found: $Log"
    exit 1
}

$allLines = [System.IO.File]::ReadAllLines($Log)

# ---------------------------------------------------------------------------
# 2. Optionally slice to Phase section
# ---------------------------------------------------------------------------
if ($Phase) {
    $startPattern = "Phase\s+$([regex]::Escape($Phase))\b"
    $startIdx = -1
    $endIdx   = $allLines.Count - 1

    for ($i = 0; $i -lt $allLines.Count; $i++) {
        if ($startIdx -eq -1 -and $allLines[$i] -match $startPattern) {
            $startIdx = $i
        } elseif ($startIdx -ge 0 -and $allLines[$i] -match "Phase\s+\S+" -and
                  $allLines[$i] -notmatch $startPattern) {
            $endIdx = $i - 1
            break
        }
    }

    if ($startIdx -eq -1) {
        Write-Host "FAIL: Phase `"$Phase`" marker not found in log."
        exit 1
    }

    $lines = $allLines[$startIdx..$endIdx]
    Write-Host "INFO: Scanning Phase $Phase section (lines $($startIdx+1)-$($endIdx+1) of $($allLines.Count))."
} else {
    $lines = $allLines
    Write-Host "INFO: Scanning full log ($($lines.Count) lines)."
}

# ---------------------------------------------------------------------------
# 3. Filter out source-echo and MPRINT lines
# ---------------------------------------------------------------------------
$scanLines = $lines | Where-Object {
    $_ -notmatch '^\s*\d+\s' -and
    $_ -notmatch '^MPRINT'
}

# ---------------------------------------------------------------------------
# 4. Define patterns
# ---------------------------------------------------------------------------

# Bad NOTE patterns
$badNotePatterns = @(
    [pscustomobject]@{ Label = 'uninitialized';       Pattern = '^NOTE: Variable .* is uninitialized' }
    [pscustomobject]@{ Label = 'invalid-argument';    Pattern = '^NOTE: Invalid .* argument' }
    [pscustomobject]@{ Label = 'errors-limit';        Pattern = 'Limit set by ERRORS=' }
    [pscustomobject]@{ Label = 'multiple-lengths';    Pattern = 'Multiple lengths were specified' }
    [pscustomobject]@{ Label = 'never-referenced';    Pattern = 'has never been referenced' }
)

# Bad WARNING: any WARNING: line
$warnPattern = '^WARNING:'

# Allowed ERROR substrings (lines containing any of these are NOT bad)
$allowedErrorSubstrings = @(
    'D-08 reconciliation failed'
    'name_map does not exist'
    'Errors printed on pages'
)

# ---------------------------------------------------------------------------
# 5. Scan
# ---------------------------------------------------------------------------
$findings      = [System.Collections.Generic.List[string]]::new()
$patternCounts = @{}
$warnCount     = 0
$badErrorCount = 0

foreach ($label in ($badNotePatterns | Select-Object -ExpandProperty Label)) {
    $patternCounts[$label] = 0
}

foreach ($line in $scanLines) {

    # Bad NOTE checks
    foreach ($p in $badNotePatterns) {
        if ($line -match $p.Pattern) {
            $patternCounts[$p.Label]++
            $findings.Add("[$($p.Label)] $line")
        }
    }

    # Bad WARNING check
    if ($line -match $warnPattern) {
        $warnCount++
        $findings.Add("[warning] $line")
    }

    # Bad ERROR check
    if ($line -match '^ERROR:') {
        $isAllowed = $false
        foreach ($allow in $allowedErrorSubstrings) {
            if ($line -match [regex]::Escape($allow)) {
                $isAllowed = $true
                break
            }
        }
        if (-not $isAllowed) {
            $badErrorCount++
            $findings.Add("[bad-error] $line")
        }
    }
}

# ---------------------------------------------------------------------------
# 6. Extra metrics
# ---------------------------------------------------------------------------
$pcnrReadCount = ($lines | Where-Object { $_ -match 'observations read from the data set PDD\.PCNR' }).Count
$tc03Count     = ($lines | Where-Object { $_ -match '^TESTRESULT: TC-03' }).Count
$summaryLine   = ($lines | Where-Object { $_ -match 'TESTRESULT: SUMMARY' } | Select-Object -Last 1)

# ---------------------------------------------------------------------------
# 7. Report
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== PATTERN FINDINGS ==="
if ($findings.Count -eq 0) {
    Write-Host "  (none)"
} else {
    # Group by label prefix
    $grouped = $findings | Group-Object { ($_ -split '\]')[0].TrimStart('[') }
    foreach ($g in $grouped) {
        Write-Host "  [$($g.Name)] count=$($g.Count)"
        foreach ($item in $g.Group) {
            Write-Host "    $item"
        }
    }
}

Write-Host ""
Write-Host "=== METRICS ==="
if ($summaryLine) {
    Write-Host "  $summaryLine"
} else {
    Write-Host "  TESTRESULT SUMMARY: (not found)"
}
Write-Host "  PDD.PCNR reads : $pcnrReadCount"
Write-Host "  TC-03 results  : $tc03Count"

# ---------------------------------------------------------------------------
# 8. Determine PASS/FAIL
# ---------------------------------------------------------------------------
$fail = $false

$totalBadNotes = ($patternCounts.Values | Measure-Object -Sum).Sum
if ($totalBadNotes -gt 0) { $fail = $true }
if ($warnCount      -gt 0) { $fail = $true }
if ($badErrorCount  -gt 0) { $fail = $true }
if ($tc03Count      -eq 0) {
    $fail = $true
    Write-Host "  FAIL: No TESTRESULT: TC-03 lines found -- integration must have run."
}

Write-Host ""
if ($fail) {
    Write-Host "RESULT: FAIL"
    exit 1
} else {
    Write-Host "RESULT: PASS"
    exit 0
}
