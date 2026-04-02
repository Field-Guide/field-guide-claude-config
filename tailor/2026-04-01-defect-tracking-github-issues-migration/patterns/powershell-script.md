# Pattern: PowerShell Script

## How We Do It

All build/utility scripts live in `tools/` as `.ps1` files. They follow a consistent pattern: comment-based help header, `param()` block with validation, `$ErrorActionPreference = "Stop"`, then sequential logic with colored `Write-Host` output.

## Exemplar: build.ps1 (tools/build.ps1)

### Header Pattern
```powershell
<#
.SYNOPSIS
    Build Field Guide app for a target platform and copy the artifact to releases/.
.DESCRIPTION
    Wraps `flutter build` and copies the output to:
      releases/{platform}/{buildType}/field-guide-{platform}-{buildType}-{version}-{date}.{ext}
.PARAMETER Platform
    Target platform: android, windows, ios
.PARAMETER BuildType
    Build mode: debug or release (default: release)
.PARAMETER Clean
    Run flutter clean before building
.EXAMPLE
    .\tools\build.ps1 -Platform android
    .\tools\build.ps1 -Platform android -BuildType debug
#>
```

### Parameter Validation Pattern
```powershell
param(
    [Parameter(Mandatory)]
    [ValidateSet("android", "windows", "ios")]
    [string]$Platform,

    [ValidateSet("debug", "release")]
    [string]$BuildType = "release",

    [switch]$Clean
)

$ErrorActionPreference = "Stop"
```

### Output Pattern
```powershell
Write-Host "`n[build] Building $Platform ($BuildType) v$version..." -ForegroundColor Cyan
# ... work ...
Write-Host "`n[build] Build complete!" -ForegroundColor Green
```

### Error Pattern
```powershell
Write-Error "ERROR: -DebugServer can only be used with -BuildType debug"
exit 1
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `ValidateSet` | build.ps1:21 | `[ValidateSet("val1", "val2")]` | Constrain string params to allowed values |
| `$ErrorActionPreference` | build.ps1:39 | `$ErrorActionPreference = "Stop"` | Fail-fast on any error |
| `Write-Host -ForegroundColor` | build.ps1:125 | `Write-Host "msg" -ForegroundColor Cyan` | Colored status output |
| `Write-Error + exit 1` | build.ps1:44 | `Write-Error "msg"; exit 1` | Fatal validation failure |

## Imports

N/A — PowerShell scripts are self-contained. The new script will use `gh` CLI which is available in PATH.
