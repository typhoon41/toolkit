function Get-FeedHostKind {
    <#
        What kind of host a feed URL points to, which decides the credentials it may receive:
          NuGetOrg        api.nuget.org
          Npmjs           registry.npmjs.org
          AzureArtifacts  pkgs.dev.azure.com, <organization>.pkgs.visualstudio.com
          Trusted         one of -TrustedHost (the pipeline's trustedFeedHosts, never release.json)
          Untrusted       anything else, or not an https URL
        Host names are compared exactly (case-insensitively), so look-alikes such as
        pkgs.dev.azure.com.example.io are Untrusted.
    #>
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
