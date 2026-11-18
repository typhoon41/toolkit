function Get-NuGetFeedHeader {
    <#
        Headers for reading a feed. NUGET_FEED_READ_TOKEN (e.g. $(System.AccessToken)) is an Azure DevOps token, so
        it is sent only to Azure Artifacts hosts; every other feed is read anonymously (nuget.org is public, and a
        private feed elsewhere fails with HTTP 401 instead of receiving the token).
    #>
    param([Parameter(Mandatory)] [string] $Source)
    $token = $env:NUGET_FEED_READ_TOKEN
    if (-not $token -or $token -match '^\$\(' -or (Get-FeedHostKind -Url $Source) -ne 'AzureArtifacts') {
        return @{}
    }
    $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("build:$token"))
    @{ Authorization = "Basic $basic" }
}
