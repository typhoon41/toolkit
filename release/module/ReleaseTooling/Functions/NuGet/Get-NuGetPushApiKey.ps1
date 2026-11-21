function Get-NuGetPushApiKey {
    # Any host but Azure Artifacts, nuget.org or a -TrustedHost is refused, so the key never reaches an unvetted feed.
    param([Parameter(Mandatory)] [string] $Source, [AllowEmptyCollection()] [string[]] $TrustedHost = @())
    $kind = Get-FeedHostKind -Url $Source -TrustedHost $TrustedHost
    if ($kind -eq 'AzureArtifacts') {
        return 'az'
    }
    if ($kind -notin 'NuGetOrg', 'Trusted') {
        throw (Get-UntrustedFeedMessage -Url $Source -VariableName 'NUGET_API_KEY')
    }
    $apiKey = $env:NUGET_API_KEY
    if (-not $apiKey -or $apiKey -match '^\$\(') {
        throw "NUGET_API_KEY is not set; it is needed to push to $(([Uri]$Source).Host)."
    }
    $apiKey
}
