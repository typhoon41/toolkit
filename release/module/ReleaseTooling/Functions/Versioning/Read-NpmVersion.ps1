function Read-NpmVersion {
    param([Parameter(Mandatory)] $Snapshot, [Parameter(Mandatory)] [string] $PackagePath)
    $text = $Snapshot.ReadText($PackagePath)
    if ($null -eq $text) {
        return $null
    }
    try {
        $manifest = $text | ConvertFrom-Json -AsHashtable
    }
    catch {
        throw "$PackagePath is not valid JSON: $($_.Exception.Message)"
    }
    if (-not $manifest['name'] -or -not $manifest['version']) {
        throw "$PackagePath needs both 'name' and 'version'."
    }
    if ($manifest['private'] -eq $true) {
        throw "$PackagePath is marked private; npm refuses to publish it. Remove 'private' or the unit."
    }
    [pscustomobject]@{ Name = [string]$manifest['name']; Text = [string]$manifest['version']; SourceFile = $PackagePath }
}
