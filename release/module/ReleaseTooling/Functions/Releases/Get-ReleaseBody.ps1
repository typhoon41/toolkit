function Get-ReleaseBody {
    <#
        The GitHub release body: the generated notes when -NotesFile exists, otherwise a minimal body (release
        notes turned off). GitHub caps bodies at 125,000 characters; longer notes are cut at a line break.
    #>
    param([Parameter(Mandatory)] $Context, [string] $NotesFile, [int] $MaximumLength = 120000)
    if ($NotesFile -and (Test-Path -LiteralPath $NotesFile)) {
        $body = [IO.File]::ReadAllText($NotesFile)
    }
    else {
        $body = "Release $($Context.Tag)`n"
        if ($Context.Unit.previousTag) {
            $body += "`n**Full Changelog**: $($Context.Client.RepositoryUrl)/compare/$($Context.Unit.previousTag)...$($Context.Tag)`n"
        }
    }
    if ($body.Length -le $MaximumLength) {
        return $body
    }
    $cut = $body.LastIndexOf("`n", $MaximumLength - 200)
    $body.Substring(0, [Math]::Max($cut, 0)) + "`n`n*Shortened.* See the full changes: $($Context.Client.RepositoryUrl)/commits/$($Context.Tag)`n"
}
