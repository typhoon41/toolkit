function Test-PathInScope {
    # Whether any of -FilePaths is one of -Scope or lies under one of its directories. An empty scope is everything.
    param(
        [AllowEmptyCollection()] [string[]] $FilePaths,
        [AllowEmptyCollection()] [string[]] $Scope
    )
    if (@($Scope).Count -eq 0) {
        return $true
    }
    foreach ($file in @($FilePaths)) {
        foreach ($path in @($Scope)) {
            if ($file -eq $path -or $file.StartsWith("$path/", [StringComparison]::Ordinal)) {
                return $true
            }
        }
    }
    $false
}
