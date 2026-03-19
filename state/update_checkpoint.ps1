param([string]$Substep)
$path = 'C:/Users/rseba/Projects/Field_Guide_App/.claude/state/implement-checkpoint.json'
$json = Get-Content $path | ConvertFrom-Json
$phase = $json.phases[0]
if ($null -eq $phase.substeps) {
    $substeps = New-Object PSObject
    $phase | Add-Member -MemberType NoteProperty -Name 'substeps' -Value $substeps -Force
}
$phase.substeps | Add-Member -MemberType NoteProperty -Name $Substep -Value 'done' -Force
$json | ConvertTo-Json -Depth 10 | Set-Content $path
Write-Host "Checkpoint updated: $Substep = done"
