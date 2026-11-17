function Get-GitHubTagCommit {
    # SHA of the commit a tag points to on GitHub, or $null when the tag doesn't exist.
    param([Parameter(Mandatory)] $Client, [Parameter(Mandatory)] [string] $Tag)
    $escaped = ($Tag -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
    $reference = Invoke-GitHubApi -Client $Client -Path "git/ref/tags/$escaped" -AllowNotFound
    if (-not $reference) {
        return $null
    }
    $object = $reference.object
    while ($object.type -eq 'tag') {
        $object = (Invoke-GitHubApi -Client $Client -Path "git/tags/$($object.sha)").object      # annotated tag
    }
    $object.sha
}
