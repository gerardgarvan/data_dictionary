param(
  [string]$Root      = "P:\PeCAN Master Data\Gerard\data_dictionary",
  [string]$Repo      = "C:\data_dictionary",
  [string]$SrcRanges = ""     # e.g. "700-800,900-950" : lines of sas\03_import.sas to include
)
$logs  = Join-Path $Root "logs"
$log   = Join-Path $logs "99_run_all.log"
$gen   = Join-Path $logs "03_generated_import.sas"
$src   = Join-Path $Repo "sas\03_import.sas"
$out   = Join-Path $logs ("logdiag_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmm"))
$lines = Get-Content $log
$r     = New-Object System.Collections.Generic.List[string]
function Sec($t) { $r.Add(""); $r.Add("===== $t =====") }
function Num($arr, $start) { $i = $start; foreach ($l in $arr) { $r.Add(("{0,6}: {1}" -f $i, $l)); $i++ } }
function Hits($pattern, $max) {
  $m = @($lines | Select-String -Pattern $pattern)
  $m | Select-Object -First $max | ForEach-Object { $r.Add(("{0,6}: {1}" -f $_.LineNumber, $_.Line)) }
  if ($m.Count -gt $max) { $r.Add("  ... $($m.Count - $max) more not shown") }
}

Sec "RUN"
$r.Add("diag created : $(Get-Date)")
$r.Add("log modified : $((Get-Item $log).LastWriteTime)")
Push-Location $Repo
$r.Add("git HEAD     : $(git log -1 --oneline)")
git status -s | ForEach-Object { $r.Add("  git status: $_") }
Pop-Location
Hits "\[99 run_all\]|PIPELINE (STOPPED|FAILED|COMPLETE)|User asked for termination" 10

Sec "PHASE 2 SUMMARY"
Hits "\[02_source_guard\] (PASS|FAIL)|Phase 2 complete|n_disagreements" 20

Sec "PHASE 3 NOTES"
Hits "\[03_import\]" 250

Sec "PHASE 4 NOTES"
Hits "\[04_name_map\]" 250

Sec "PHASE 5 NOTES"
Hits "\[05_build_pcnr\]" 500

Sec "PHASE 6 NOTES"
Hits "\[06_profile\]" 250

Sec "ERRORS AND WARNINGS AFTER PHASE 4"
$p4end = 0
$p4m = $lines | Select-String -Pattern "\[04_name_map\].*complete" | Select-Object -Last 1
if ($p4m) { $p4end = $p4m.LineNumber }
$errsAfterP4 = @($lines | Select-String -Pattern "^ERROR|^WARNING" | Where-Object { $_.LineNumber -gt $p4end })
if ($errsAfterP4.Count -eq 0) { $r.Add("no ERROR or WARNING after Phase 4") }
else {
  $errsAfterP4 | Select-Object -First 60 | ForEach-Object { $r.Add(("{0,6}: {1}" -f $_.LineNumber, $_.Line)) }
  if ($errsAfterP4.Count -gt 60) { $r.Add("  ... $($errsAfterP4.Count - 60) more not shown") }
}

Sec "PHASE 5 PYTHON LOG (last 50 lines)"
$qcLog = Join-Path $logs "write_pcnr_qc_console.txt"
if (Test-Path $qcLog) {
  $qcLines = Get-Content $qcLog
  $start = [Math]::Max(0, $qcLines.Count - 50)
  Num $qcLines[$start..($qcLines.Count - 1)] ($start + 1)
} else { $r.Add("not found: $qcLog") }

Sec "PDD DATASETS WRITTEN"
Hits "The data set PDD\.\S+ has" 80

Sec "ERRORS (first 60)"
Hits "^ERROR" 60

Sec "WARNINGS (first 40, known original_header truncations excluded)"
$w = @($lines | Select-String -Pattern "^WARNING" | Where-Object { $_.Line -notmatch "original_header" })
$w | Select-Object -First 40 | ForEach-Object { $r.Add(("{0,6}: {1}" -f $_.LineNumber, $_.Line)) }

Sec "CONTEXT AROUND FIRST ERROR AFTER PHASE 2"
$p2 = 0
$p2m = $lines | Select-String -Pattern "---- Phase 2 complete" | Select-Object -Last 1
if ($p2m) { $p2 = $p2m.LineNumber }
$e = $lines | Select-String -Pattern "^ERROR" | Where-Object { $_.LineNumber -gt $p2 } | Select-Object -First 1
if ($e) {
  $a = [Math]::Max($p2, $e.LineNumber - 70)
  $b = [Math]::Min($lines.Count - 1, $e.LineNumber + 15)
  Num $lines[$a..$b] ($a + 1)
} else { $r.Add("no ERROR after Phase 2") }

Sec "GENERATED FILES IN logs"
Get-ChildItem $logs -Filter "03_generated*.sas" | ForEach-Object {
  $r.Add(("{0}  {1:N0} bytes  {2} lines  modified {3}" -f $_.Name, $_.Length, (Get-Content $_.FullName).Count, $_.LastWriteTime))
}

Sec "GENERATED CSV FILE (first 40 lines)"
if (Test-Path $gen) { Num (Get-Content $gen -TotalCount 40) 1 } else { $r.Add("not found") }

Sec "MACRO MAP: sas\03_import.sas"
Select-String -Path $src -Pattern "^\s*%macro|^\s*%mend" | ForEach-Object { $r.Add(("{0,6}: {1}" -f $_.LineNumber, $_.Line.Trim())) }

if ($SrcRanges) {
  $srcLines = Get-Content $src
  foreach ($rg in $SrcRanges.Split(",")) {
    $p = $rg.Trim().Split("-"); $a = [int]$p[0]; $b = [Math]::Min([int]$p[1], $srcLines.Count)
    Sec "SOURCE sas\03_import.sas lines $a-$b"
    Num $srcLines[($a - 1)..($b - 1)] $a
  }
}

$r | Out-File -FilePath $out -Encoding utf8
Write-Host "Log diag written: $out"
notepad $out
