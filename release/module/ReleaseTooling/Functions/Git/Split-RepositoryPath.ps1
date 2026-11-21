function Split-RepositoryPath {
    param([AllowEmptyString()] [string] $Path)
    $normalized = ConvertTo-RepositoryPath $Path
    $index = $normalized.LastIndexOf('/')
    if ($index -lt 0) {
        return ''
    }
    $normalized.Substring(0, $index)
}
