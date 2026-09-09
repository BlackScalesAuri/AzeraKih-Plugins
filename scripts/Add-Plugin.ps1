<#
.SYNOPSIS
    Copies a plugin's Release build into this repo and adds/updates its entry in pluginmaster.json.

.DESCRIPTION
    Run this after `dotnet build -c Release` on a plugin. It reads the manifest DalamudPackager
    generated (<AssemblyName>.json in the Release output folder), copies <AssemblyName>/latest.zip
    into plugins/<InternalName>/latest.zip here, and writes/updates that plugin's entry in
    pluginmaster.json with download links pointing at this repo.

    This only edits files on disk - it does not commit or push. Review the diff and do that
    yourself.

.PARAMETER ReleaseOutputDir
    Path to the plugin's Release output folder, e.g.
    C:\...\MyPlugin\MyPlugin\bin\x64\Release

.PARAMETER RepoBaseUrl
    Raw base URL this repo is served from, e.g.
    https://raw.githubusercontent.com/AzeraKih/AzeraKih-Plugins/main

.EXAMPLE
    .\scripts\Add-Plugin.ps1 `
        -ReleaseOutputDir "C:\Users\AzeraKih\Documents\PROJETOS\Dalamud Plugins\HideBeasts\HideBeasts\bin\x64\Release" `
        -RepoBaseUrl "https://raw.githubusercontent.com/AzeraKih/AzeraKih-Plugins/main"
#>
param(
    [Parameter(Mandatory)] [string]$ReleaseOutputDir,
    [Parameter(Mandatory)] [string]$RepoBaseUrl
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

# The Release output folder also contains *.deps.json and possibly packages.lock.json,
# neither of which is the plugin manifest - identify it by the InternalName property instead
# of guessing from the filename.
$manifest = $null
foreach ($file in Get-ChildItem -Path $ReleaseOutputDir -Filter "*.json" -File) {
    $candidate = Get-Content $file.FullName -Raw | ConvertFrom-Json
    if ($candidate.InternalName) {
        $manifest = $candidate
        break
    }
}
if (-not $manifest) {
    throw "No plugin manifest json found directly in $ReleaseOutputDir - did you build in Release?"
}

$internalName = $manifest.InternalName

$zipSource = Join-Path $ReleaseOutputDir "$internalName\latest.zip"
if (-not (Test-Path $zipSource)) {
    throw "Zip not found at $zipSource"
}

$destDir = Join-Path $repoRoot "plugins\$internalName"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item $zipSource -Destination (Join-Path $destDir "latest.zip") -Force

$downloadUrl = "$RepoBaseUrl/plugins/$internalName/latest.zip"
$manifest | Add-Member -NotePropertyName DownloadLinkInstall -NotePropertyValue $downloadUrl -Force
$manifest | Add-Member -NotePropertyName DownloadLinkUpdate -NotePropertyValue $downloadUrl -Force
$manifest | Add-Member -NotePropertyName DownloadLinkTesting -NotePropertyValue $downloadUrl -Force

$masterPath = Join-Path $repoRoot "pluginmaster.json"
$master = @()
if (Test-Path $masterPath) {
    $master = @(Get-Content $masterPath -Raw | ConvertFrom-Json)
}

$existingIndex = -1
for ($i = 0; $i -lt $master.Count; $i++) {
    if ($master[$i].InternalName -eq $internalName) { $existingIndex = $i; break }
}

if ($existingIndex -ge 0) {
    $master[$existingIndex] = $manifest
    Write-Output "Updated existing entry for '$internalName' (version $($manifest.AssemblyVersion))."
} else {
    $master += $manifest
    Write-Output "Added new entry for '$internalName' (version $($manifest.AssemblyVersion))."
}

ConvertTo-Json -InputObject $master -Depth 10 | Set-Content -Path $masterPath -Encoding utf8

Write-Output "Done. Review the diff, then commit and push."
