$script:RunDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ContextPath = Join-Path $script:RunDir 'checkpoint.json'
$script:EnvPath = Join-Path (Resolve-Path (Join-Path $script:RunDir '..\..\..\tools\debug-server\.env.test')) ''

function Load-RunEnv {
  $envFile = Join-Path (Resolve-Path (Join-Path $script:RunDir '..\..\..\tools\debug-server')) '.env.test'
  foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*#' -or $line -notmatch '=') { continue }
    $parts = $line -split '=',2
    Set-Item -Path "Env:$($parts[0].Trim())" -Value $parts[1].Trim()
  }
}

function Get-RunContext {
  if (Test-Path $script:ContextPath) {
    return Get-Content $script:ContextPath -Raw | ConvertFrom-Json -AsHashtable
  }
  return @{}
}

function Save-RunContext([hashtable]$ctx) {
  $ctx | ConvertTo-Json -Depth 8 | Set-Content -Path $script:ContextPath -Encoding UTF8
}

function Invoke-DriverGet([int]$Port, [string]$Path) {
  Invoke-RestMethod -Uri ("http://127.0.0.1:{0}{1}" -f $Port,$Path)
}

function Invoke-DriverPost([int]$Port, [string]$Path, [hashtable]$Body) {
  Invoke-RestMethod -Method Post -Uri ("http://127.0.0.1:{0}{1}" -f $Port,$Path) -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Compress)
}

function Tap([int]$Port, [string]$Key, [int]$SleepMs = 800) {
  Invoke-DriverPost $Port '/driver/tap' @{ key = $Key } | Out-Null
  Start-Sleep -Milliseconds $SleepMs
}

function TypeText([int]$Port, [string]$Key, [string]$Text, [int]$SleepMs = 400) {
  Invoke-DriverPost $Port '/driver/text' @{ key = $Key; text = $Text } | Out-Null
  Start-Sleep -Milliseconds $SleepMs
}

function DismissKeyboard([int]$Port) {
  Invoke-DriverPost $Port '/driver/dismiss-keyboard' @{} | Out-Null
  Start-Sleep -Milliseconds 300
}

function Wait-Key([int]$Port, [string]$Key, [int]$TimeoutSec = 20) {
  $end = (Get-Date).AddSeconds($TimeoutSec)
  do {
    try {
      $resp = Invoke-DriverGet $Port ("/driver/find?key={0}" -f $Key)
      if ($resp.exists) { return $resp }
    } catch {}
    Start-Sleep -Milliseconds 400
  } while ((Get-Date) -lt $end)
  throw "Timed out waiting for key $Key on port $Port"
}

function Wait-Route([int]$Port, [string]$Route, [int]$TimeoutSec = 20) {
  $end = (Get-Date).AddSeconds($TimeoutSec)
  do {
    try {
      $resp = Invoke-DriverGet $Port '/driver/current-route'
      if ($resp.route -eq $Route) { return $resp }
    } catch {}
    Start-Sleep -Milliseconds 400
  } while ((Get-Date) -lt $end)
  throw "Timed out waiting for route $Route on port $Port"
}

function Capture([int]$Port, [string]$Name) {
  $path = Join-Path $script:RunDir ('screenshots\' + $Name)
  Invoke-WebRequest -Uri ("http://127.0.0.1:{0}/driver/screenshot" -f $Port) -OutFile $path | Out-Null
  return $path
}

function Wait-SyncIdle([int]$Port, [int]$TimeoutSec = 120) {
  $end = (Get-Date).AddSeconds($TimeoutSec)
  do {
    $resp = Invoke-DriverGet $Port '/driver/sync-status'
    if (-not $resp.isSyncing) { return $resp }
    Start-Sleep -Seconds 1
  } while ((Get-Date) -lt $end)
  throw "Timed out waiting for sync idle on port $Port"
}

function Sync-ViaUI([int]$Port) {
  Tap $Port 'settings_nav_button' 1000
  Wait-Key $Port 'settings_sync_button' 10 | Out-Null
  Tap $Port 'settings_sync_button' 1200
  return (Wait-SyncIdle $Port)
}

function Supabase-Headers {
  Load-RunEnv
  return @{
    apikey = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept = 'application/json'
    Prefer = 'return=representation'
  }
}

function Query-Supabase([string]$Table, [string]$Query) {
  $headers = Supabase-Headers
  $url = "$($env:SUPABASE_URL)/rest/v1/$Table?$Query"
  return Invoke-RestMethod -Uri $url -Headers $headers
}

function List-Storage([string]$Bucket, [string]$Prefix) {
  $headers = Supabase-Headers
  $headers['Content-Type'] = 'application/json'
  $url = "$($env:SUPABASE_URL)/storage/v1/object/list/$Bucket"
  return Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body (@{ prefix = $Prefix; limit = 100 } | ConvertTo-Json -Compress)
}
