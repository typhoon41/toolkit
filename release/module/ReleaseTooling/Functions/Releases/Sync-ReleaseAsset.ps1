function Sync-ReleaseAsset {
    <#
        Makes the release's assets match the context's files exactly (state assets aside): uploads what is
        missing, replaces what differs, removes what this build didn't produce. -VerifyOnly changes nothing
        and fails with -FrozenReason on any difference.
    #>
    param(
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Release,
        [switch] $VerifyOnly,
        [string] $FrozenReason
    )
    $assets = @(Get-ReleaseAsset -Context $Context -Release $Release)
    $uploadBase = $Release.upload_url -replace '\{.*\}$', ''

    foreach ($file in $Context.Files) {
        $existing = @($assets | Where-Object { $_.name -eq $file.Name }) | Select-Object -First 1
        if ($existing -and (Test-ReleaseAssetMatch -Context $Context -Asset $existing -File $file)) {
            Write-ReleaseLog "Asset OK: $($file.Name)"
            continue
        }
        if ($VerifyOnly) {
            throw "Asset $($file.Name) on release $($Context.Tag) is missing or differs from this build. $FrozenReason"
        }
        if ($existing) {
            Write-ReleaseLog "Replacing incomplete or different asset $($file.Name)"
            Invoke-GitHubApi -Client $Context.Client -Method Delete -Path "releases/assets/$($existing.id)" | Out-Null
        }
        Invoke-GitHubApi -Client $Context.Client -Method Post -InFile $file.FullName -Path "${uploadBase}?name=$([Uri]::EscapeDataString($file.Name))" | Out-Null
        Write-ReleaseLog "Uploaded $($file.Name)"
    }

    $names = @($Context.Files.Name)
    foreach ($extra in @($assets | Where-Object { $_.name -notin $names -and -not (Test-ReleaseStateAsset $_.name) })) {
        if ($VerifyOnly) {
            throw "Release $($Context.Tag) has an asset this build didn't produce: $($extra.name). $FrozenReason"
        }
        Write-ReleaseLog "Removing stale asset $($extra.name)"
        Invoke-GitHubApi -Client $Context.Client -Method Delete -Path "releases/assets/$($extra.id)" | Out-Null
    }
}
