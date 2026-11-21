function Test-GuardedPath {
    # Excluded folders (GuardedPaths.psd1, extended by the project configuration) and generated files (*.Designer.cs,
    # *.g.cs, *.generated.*) are changed through their source and regenerated.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [AllowEmptyCollection()] [string[]] $ExcludedFolder = (Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot '../../GuardedPaths.psd1')).ExcludedFolders
    )
    $folders = @($ExcludedFolder | Where-Object { $_ } | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $inExcludedFolder = $folders -and $Path -match "(?i)(?:^|[\\/])(?:$folders)[\\/]"
    -not $inExcludedFolder -and $Path -notmatch '(?i)\.(?:designer|g|generated)\.[a-z]+$'
}
