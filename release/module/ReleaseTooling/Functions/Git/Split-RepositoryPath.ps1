function Split-RepositoryPath {
    # Parent directory of a repository-relative path ('' for the root).
    param([AllowEmptyString()] [string] $Path)
    $normalized = ConvertTo-RepositoryPath $Path
    $index = $normalized.LastIndexOf('/')
    if ($index -lt 0) {
        return ''
    }
    $normalized.Substring(0, $index)
}
