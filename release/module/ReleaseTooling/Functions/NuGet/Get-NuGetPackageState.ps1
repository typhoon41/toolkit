function Get-NuGetPackageState {
    # Published means the same commit and the same content apart from signing.
    param(
        [Parameter(Mandatory)] [string] $File,
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Commit
    )
    $headers = Get-NuGetFeedHeader -Source $Source
    $flatContainer = Get-NuGetFlatContainer -Source $Source -Headers $headers
    $local = Read-PackageNuspec $File
    $label = "$($local.Id) $($local.Version)"
    if (-not (Test-NuGetVersion -FlatContainer $flatContainer -Id $local.Id -Version $local.Version -Headers $headers)) {
        return [pscustomobject]@{ Label = $label; State = 'Absent'; Detail = '' }
    }
    $remoteFile = Save-NuGetPackage -FlatContainer $flatContainer -Id $local.Id -Version $local.Version -Headers $headers
    try {
        $remote = Read-PackageNuspec $remoteFile
        $differences = Compare-PackageContent -LocalPath $File -RemotePath $remoteFile
    }
    finally {
        Remove-Item -LiteralPath $remoteFile -ErrorAction SilentlyContinue
    }
    if ($remote.Commit -eq $Commit -and $differences.Count -eq 0) {
        return [pscustomobject]@{ Label = $label; State = 'Published'; Detail = 'identical to this build' }
    }
    $first = if ($differences.Count -gt 0) { ", e.g. '$($differences[0])'" } else { '' }
    [pscustomobject]@{ Label = $label; State = 'Foreign'; Detail = "feed has commit '$($remote.Commit)', $($differences.Count) difference(s)$first" }
}
