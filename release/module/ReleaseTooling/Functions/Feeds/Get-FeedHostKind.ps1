function Get-FeedHostKind {
    # Hosts are compared exactly, so a look-alike such as pkgs.dev.azure.com.example.io is Untrusted.
    # Trusted hosts come only from the pipeline's trustedFeedHosts, never from release.json.
    param([Parameter(Mandatory)] [string] $Url, [AllowEmptyCollection()] [string[]] $TrustedHost = @())
    $parsed = $null
    if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$parsed) -or $parsed.Scheme -ne 'https') {
        return 'Untrusted'
    }
    $hostName = $parsed.Host.ToLowerInvariant()
    if ($hostName -eq 'api.nuget.org') {
        return 'NuGetOrg'
    }
    if ($hostName -eq 'registry.npmjs.org') {
        return 'Npmjs'
    }
    if ($hostName -eq 'pkgs.dev.azure.com' -or $hostName -match '^[a-z0-9][a-z0-9-]*\.pkgs\.visualstudio\.com$') {
        return 'AzureArtifacts'
    }
    if (@($TrustedHost | Where-Object { $_ } | ForEach-Object { $_.Trim().ToLowerInvariant() }) -contains $hostName) {
        return 'Trusted'
    }
    'Untrusted'
}
