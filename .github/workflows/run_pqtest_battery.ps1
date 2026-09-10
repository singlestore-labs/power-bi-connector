<#
  Runs a PQTest `run-compare` battery and turns its event stream into a pass/fail exit code.

  run-compare emits one JSON object per line, each prefixed with an event name ("runStart:",
  "testStart:", "testEnd:", "runEnd:"). It is NOT a single JSON array, and it exits 0 even when
  a test fails — so we parse the event stream ourselves and throw on any failure or a missing
  runEnd. Shared by every tier (Tier 1 unit tests, Tier 2 folding, future Tier 3) so this parsing
  logic lives in exactly one place.
#>
param(
    [Parameter(Mandatory = $true)] [string] $PqTestExe,        # full path to PQTest.exe
    [Parameter(Mandatory = $true)] [string] $SettingsFile,     # -sf testsettings.json
    [string] $BatteryName      = "PQTest",                     # label used in log/error messages
    [string] $ResultsDirectory = ".\test\TestResults"          # TrxReportPath target; created if missing
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $ResultsDirectory | Out-Null

# NOTE: run-compare in the pinned SDK (2.155.2) has no diagnostic-channel flag, so folded-SQL
# capture isn't available here. Folding is instead enforced by FailOnFoldingFailure in the
# settings file; this runner only compares data (.pqout) and parses the pass/fail event stream.
$arguments = @("run-compare", "-sf", $SettingsFile)

$output = & $PqTestExe @arguments 2>&1
$exitCode = $LASTEXITCODE
$text = $output | Out-String
Write-Host $text

$failures = @()
$runEndSeen = $false

foreach ($line in ($text -split "`r?`n")) {
    if ($line -notmatch '^\s*(\w+):\s*(\{.*\})\s*$') { continue }
    $eventName = $Matches[1]
    try   { $payload = $Matches[2] | ConvertFrom-Json }
    catch { continue }

    if ($eventName -eq "testEnd" -and $payload.status -ne "Passed") {
        $msg = if ($payload.error.message) { $payload.error.message } else { $payload.status }
        $failures += "$($payload.name): $msg"
    }
    elseif ($eventName -eq "runEnd") {
        $runEndSeen = $true
        if ([int]$payload.failed -gt 0) {
            $failures += "runEnd reported $($payload.failed) failed test(s)."
        }
    }
}

if (-not $runEndSeen) {
    throw "$BatteryName produced no runEnd event. Exit code: $exitCode. Output:`n$text"
}
if ($exitCode -ne 0 -or $failures.Count -gt 0) {
    throw "$BatteryName battery failed:`n$($failures -join "`n")"
}

Write-Host "$BatteryName battery passed."
