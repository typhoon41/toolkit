function New-RepositorySnapshot {
    <#
        The repository's files as they are in the working tree, or at -Revision (e.g. HEAD^).
        Ask it with $snapshot.ReadText('path/relative/to/root'), which returns $null when the file
        does not exist there, and $snapshot.Exists('path').
    #>
    param(
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [string] $Revision
    )
    $snapshot = [pscustomobject]@{
        Root     = (Resolve-Path -LiteralPath $RepositoryRoot).Path
        Revision = $Revision
    }
    $snapshot | Add-Member -MemberType ScriptMethod -Name ReadText -Value {
        param([string] $Path)
        $relative = ConvertTo-RepositoryPath $Path
        if (-not $this.Revision) {
            $full = Join-Path $this.Root $relative
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                return $null
            }
            return [IO.File]::ReadAllText($full)
        }
        Push-Location -LiteralPath $this.Root
        try {
            & git cat-file -e "$($this.Revision):$relative" 2>$null
            if ($LASTEXITCODE -ne 0) {
                return $null
            }
            (Invoke-Git show "$($this.Revision):$relative") -join "`n"
        }
        finally {
            Pop-Location
        }
    }
    $snapshot | Add-Member -MemberType ScriptMethod -Name Exists -Value {
        param([string] $Path)
        $null -ne $this.ReadText($Path)
    }
    $snapshot
}
