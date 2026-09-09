<#
.SYNOPSIS
    Rebuilds pluginmaster.json from each plugin listed in plugins.json.

.DESCRIPTION
    For every entry in plugins.json, this fetches that repo's latest GitHub Release (for the
    download link, publish time, and download count) plus the base manifest committed in that
    repo at <configFolder>/<repo>.json, merges the two, and writes the combined list to
    pluginmaster.json.

    pluginmaster.json is generated - don't hand-edit it, edit plugins.json (to add/remove a
    plugin) or the plugin's own <repo>.json (to change its metadata) instead.

    Run from the repo root: .\generate-repo.ps1
    Set $env:GITHUB_TOKEN first to avoid GitHub's low unauthenticated API rate limit; the
    release workflow does this automatically via secrets.GITHUB_TOKEN.
#>

$ErrorActionPreference = "Stop"

$headers = @{}
if ($env:GITHUB_TOKEN) {
    $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
}

$pluginList = Get-Content ".\plugins.json" -Raw | ConvertFrom-Json
$pluginsOut = @()

foreach ($plugin in $pluginList) {
    $username = $plugin.username
    $repo = $plugin.repo
    $branch = $plugin.branch
    $configFolder = $plugin.configFolder

    Write-Output "Processing $username/$repo..."

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$repo/releases/latest" -Headers $headers
    $asset = $release.assets | Select-Object -First 1
    if (-not $asset) {
        Write-Warning "No release assets found for $username/$repo - skipping."
        continue
    }

    $configUrl = "https://raw.githubusercontent.com/$username/$repo/$branch/$configFolder/$repo.json"
    $config = Invoke-RestMethod -Uri $configUrl -Headers $headers
    if ($null -eq $config) {
        Write-Warning "Config for $username/$repo at $configUrl came back empty - skipping."
        continue
    }

    $publishedUnix = [int](New-TimeSpan -Start (Get-Date "1970-01-01Z") -End ([DateTime]$release.published_at)).TotalSeconds

    $config | Add-Member -NotePropertyName IsHide -NotePropertyValue $false -Force
    $config | Add-Member -NotePropertyName IsTestingExclusive -NotePropertyValue $false -Force
    $config | Add-Member -NotePropertyName LastUpdated -NotePropertyValue $publishedUnix -Force
    $config | Add-Member -NotePropertyName DownloadCount -NotePropertyValue $asset.download_count -Force
    $config | Add-Member -NotePropertyName DownloadLinkInstall -NotePropertyValue $asset.browser_download_url -Force
    $config | Add-Member -NotePropertyName DownloadLinkUpdate -NotePropertyValue $asset.browser_download_url -Force
    $config | Add-Member -NotePropertyName DownloadLinkTesting -NotePropertyValue $asset.browser_download_url -Force

    $pluginsOut += $config
}

ConvertTo-Json -InputObject $pluginsOut -Depth 10 | Set-Content -Path "pluginmaster.json" -Encoding utf8
Write-Output "Wrote pluginmaster.json with $($pluginsOut.Count) plugin(s)."
