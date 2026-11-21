function Invoke-WhitespaceFormat {
    # Folder mode needs no project load, so it is fast. --include takes the path relative to the root, the form every
    # dotnet format mode accepts.
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $Path
    )
    $relative = [IO.Path]::GetRelativePath($Root, $Path)
    $insideRoot = -not [IO.Path]::IsPathRooted($relative) -and $relative -notmatch '^\.\.(?:[\\/]|$)'
    $canFormat = $insideRoot -and (Test-Path -LiteralPath (Join-Path $Root '.editorconfig') -PathType Leaf) -and
        (Test-Path -LiteralPath $Path -PathType Leaf) -and (Get-Command dotnet -ErrorAction SilentlyContinue)
    if (-not $canFormat) {
        return $false
    }
    $before = (Get-FileHash -LiteralPath $Path).Hash
    & dotnet format whitespace $Root --folder --include $relative *> $null
    $before -ne (Get-FileHash -LiteralPath $Path).Hash
}
