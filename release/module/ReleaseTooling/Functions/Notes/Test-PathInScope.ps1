function Test-PathInScope {
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
