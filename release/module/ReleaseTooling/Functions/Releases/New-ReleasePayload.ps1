function New-ReleasePayload {
    # GitHub caps release bodies at 125,000 characters.
    param([Parameter(Mandatory)] $Context, [string] $NotesFile, [bool] $Draft = $true, [int] $MaximumLength = 120000)
    if ($NotesFile -and (Test-Path -LiteralPath $NotesFile)) {
        $body = [IO.File]::ReadAllText($NotesFile)
    }
    else {
        $body = "Release $($Context.Tag)`n"
        $previousRelease = Get-PreviousReleaseReference -UnitPlan $Context.Unit
        if ($previousRelease) {
            $body += "`n**Full Changelog**: $($Context.Client.RepositoryUrl)/compare/$previousRelease...$($Context.Tag)`n"
        }
    }
    if ($body.Length -gt $MaximumLength) {
        $cut = $body.LastIndexOf("`n", $MaximumLength - 200)
        $body = $body.Substring(0, [Math]::Max($cut, 0)) + "`n`n*Shortened.* See the full changes: $($Context.Client.RepositoryUrl)/commits/$($Context.Tag)`n"
    }
    $payload = @{
        tag_name = $Context.Tag; target_commitish = $Context.Commit; name = $Context.Tag; body = $body
        prerelease = $Context.Candidate.IsPrerelease; draft = $Draft
    }
    if (-not $Draft) {
        $payload.make_latest = if ($Context.Candidate.IsPrerelease) { 'false' } else { 'true' }
    }
    $payload
}
