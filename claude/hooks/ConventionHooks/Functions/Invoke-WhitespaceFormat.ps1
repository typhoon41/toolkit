function Invoke-WhitespaceFormat {
    # Runs `dotnet format whitespace` on one file in folder mode (no project load, fast) and returns whether the
    # file changed. The root's .editorconfig is the style; without it, or without dotnet, nothing runs.
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $Path
    )
    $canFormat = (Test-Path -LiteralPath (Join-Path $Root '.editorconfig') -PathType Leaf) -and
        (Test-Path -LiteralPath $Path -PathType Leaf) -and (Get-Command dotnet -ErrorAction SilentlyContinue)
    if (-not $canFormat) {
        return $false
    }
    $before = (Get-FileHash -LiteralPath $Path).Hash
    & dotnet format whitespace $Root --folder --include $Path *> $null
    $before -ne (Get-FileHash -LiteralPath $Path).Hash
}
