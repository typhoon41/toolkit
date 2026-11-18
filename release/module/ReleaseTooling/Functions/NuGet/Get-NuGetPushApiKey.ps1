function Get-NuGetPushApiKey {
    <#
        The API key for `dotnet nuget push` to -Source:
          Azure Artifacts             'az' (the credential provider from NuGetAuthenticate@1 authenticates)
          nuget.org, a -TrustedHost   NUGET_API_KEY
          any other host              refused, so the key never reaches a feed nobody vetted
    #>
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
