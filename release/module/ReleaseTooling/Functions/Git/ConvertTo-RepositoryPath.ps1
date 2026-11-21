function ConvertTo-RepositoryPath {
    param([AllowEmptyString()] [string] $Path)
    $normalized = ($Path -replace '\\', '/').Trim()
    while ($normalized.StartsWith('./')) {
        $normalized = $normalized.Substring(2)
    }
    $normalized = $normalized.Trim('/')
    if ($normalized -eq '.') {
        $normalized = ''
    }
    if ($normalized -match '(^|/)\.\.(/|$)' -or $normalized -match '^[A-Za-z]:') {
        throw "Path '$Path' must be relative to the repository root and stay inside it."
    }
    $normalized
}
