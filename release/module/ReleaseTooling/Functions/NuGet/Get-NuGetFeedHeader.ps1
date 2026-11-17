function Get-NuGetFeedHeader {
    <#
        Headers for reading a feed. nuget.org is public; a private feed (Azure Artifacts) is read with the
        NUGET_FEED_READ_TOKEN environment variable, e.g. $(System.AccessToken) of the pipeline.
    #>
    param([Parameter(Mandatory)] [string] $Source)
    $token = $env:NUGET_FEED_READ_TOKEN
    if ($Source -match '^https://api\.nuget\.org/' -or -not $token -or $token -match '^\$\(') {
        return @{}
    }
    $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("build:$token"))
    @{ Authorization = "Basic $basic" }
}
