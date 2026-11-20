function Get-NuGetFeedHeader {
    # NUGET_FEED_READ_TOKEN is an Azure DevOps token, so only Azure Artifacts hosts get it; a private feed elsewhere
    # fails with HTTP 401 instead of receiving it.
    param([Parameter(Mandatory)] [string] $Source)
    $token = $env:NUGET_FEED_READ_TOKEN
    if (-not $token -or $token -match '^\$\(' -or (Get-FeedHostKind -Url $Source) -ne 'AzureArtifacts') {
        return @{}
    }
    $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("build:$token"))
    @{ Authorization = "Basic $basic" }
}
