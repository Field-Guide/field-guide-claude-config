# Run custom_lint — baseline-aware: known violations pass, new violations block
# FROM SPEC: Section 10 — "custom_lint check"
# Uses lint_baseline.json to distinguish tracked vs new violations

param()

Write-Host "=== Running custom_lint ===" -ForegroundColor Cyan

$output = & dart run custom_lint 2>&1
$exitCode = $LASTEXITCODE

# Parse violation lines from output (format: file:line:col • message • rule_name • SEVERITY)
$violationLines = @($output | Where-Object { $_ -match '^\s+\S+:\d+:\d+\s+' })

if ($violationLines.Count -eq 0 -and $exitCode -eq 0) {
    Write-Host "PASSED: custom_lint (0 violations)" -ForegroundColor Green
    exit 0
}

# Load baseline
$baselinePath = Join-Path (Get-Location) "lint_baseline.json"
$baseline = @{}
if (Test-Path $baselinePath) {
    $baselineData = Get-Content $baselinePath -Raw | ConvertFrom-Json
    foreach ($entry in $baselineData.baseline) {
        $key = "$($entry.rule)|$($entry.file)"
        $baseline[$key] = $entry.count
    }
}

# Group violations by rule+file
$groups = @{}
foreach ($line in $violationLines) {
    # Parse: "  path\file.dart:line:col • message • rule_name • SEVERITY"
    if ($line -match '^\s+(.+?):(\d+):\d+\s+.*?\u2022\s+(\S+)\s+\u2022') {
        $file = $Matches[1] -replace '\\', '/'
        $rule = $Matches[3]
        $key = "$rule|$file"
        if ($groups.ContainsKey($key)) {
            $groups[$key]++
        } else {
            $groups[$key] = 1
        }
    }
}

# Compare against baseline
$newViolations = 0
$baselinedViolations = 0

foreach ($key in $groups.Keys) {
    $count = $groups[$key]
    if ($baseline.ContainsKey($key) -and $count -le $baseline[$key]) {
        $baselinedViolations += $count
    } else {
        $newViolations += $count
        $parts = $key -split '\|', 2
        Write-Host "  NEW: $($parts[0]) in $($parts[1]) ($count violation(s))" -ForegroundColor Red
    }
}

if ($baselinedViolations -gt 0) {
    Write-Host "  Baselined: $baselinedViolations known violation(s) (tracked in lint_baseline.json)" -ForegroundColor Yellow
}

if ($newViolations -gt 0) {
    Write-Host "FAILED: $newViolations NEW lint violation(s) not in baseline" -ForegroundColor Red
    exit 1
}

Write-Host "PASSED: custom_lint ($baselinedViolations baselined, 0 new)" -ForegroundColor Green
exit 0
