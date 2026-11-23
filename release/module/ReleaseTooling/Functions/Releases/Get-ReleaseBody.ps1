function Get-ReleaseBody {
    # GitHub caps release bodies at 125,000 characters.
    param([Parameter(Mandatory)] $Context, [string] $NotesFile, [int] $MaximumLength = 120000)
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
    if ($body.Length -le $MaximumLength) {
        return $body
    }
    $cut = $body.LastIndexOf("`n", $MaximumLength - 200)
    $body.Substring(0, [Math]::Max($cut, 0)) + "`n`n*Shortened.* See the full changes: $($Context.Client.RepositoryUrl)/commits/$($Context.Tag)`n"
}
