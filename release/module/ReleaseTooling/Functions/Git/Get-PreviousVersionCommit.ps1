function Get-PreviousVersionCommit {
    # Without release tags, the previous release is the commit that set the version file to the version before
    # -Version. Walks the version files' first-parent history from newest to oldest; '' when there is none.
    param(
        [Parameter(Mandatory)] $Unit,
        [Parameter(Mandatory)] [string] $Version,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $SourceFiles,
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [string] $Ref = 'HEAD'
    )
    if ($SourceFiles.Count -eq 0) {
        return ''
    }
    Push-Location -LiteralPath $RepositoryRoot
    try {
        $commits = @(Invoke-Git log --first-parent --format=%H $Ref -- @SourceFiles)
    }
    finally {
        Pop-Location
    }
    $previousVersion = $null
    $boundary = ''
    foreach ($commit in $commits) {
        try {
            $text = (Read-UnitVersion -Unit $Unit -Snapshot (New-RepositorySnapshot -RepositoryRoot $RepositoryRoot -Revision $commit))?.Text
        }
        catch {
            # Older history with disagreeing project versions ends the walk: the boundary found so far stands.
            Write-ReleaseLog "Stopped reading the version history at ${commit}: $($_.Exception.Message)"
            break
        }
        if (-not $previousVersion) {
            if ($text -and $text -ne $Version) {
                $previousVersion = $text
                $boundary = $commit
            }
            continue
        }
        if ($text -ne $previousVersion) {
            break
        }
        $boundary = $commit
    }
    $boundary
}
