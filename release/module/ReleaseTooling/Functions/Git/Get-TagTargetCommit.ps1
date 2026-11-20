function Get-TagTargetCommit {
    param([Parameter(Mandatory)] [string] $Tag)
    $commit = & git rev-parse --verify --quiet "refs/tags/$Tag^{commit}" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $commit) {
        return $null
    }
    [string]$commit
}
