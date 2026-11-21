function Find-ProjectConfigurationFile {
    # .claude/conventions.json in the hook's working folder or the nearest folder above it, never past the repository
    # root (the folder holding .git). Returns nothing when there is none.
    param([AllowEmptyString()] [string] $Root = '')
    if (-not $Root) {
        return
    }
    $folder = [IO.Path]::GetFullPath($Root)
    while ($folder) {
        $candidate = Join-Path $folder '.claude/conventions.json'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
        if (Test-Path -LiteralPath (Join-Path $folder '.git')) {
            return
        }
        $folder = Split-Path -Parent $folder
    }
}
