function New-GitHubClient {
    # Connection settings for the GitHub REST API. An empty token means anonymous access (public repositories).
    param(
        [Parameter(Mandatory)] [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')] [string] $Repository,
        [AllowEmptyString()] [string] $Token,
        [string] $ApiUrl = 'https://api.github.com',
        [string] $WebUrl = 'https://github.com'
    )
    $headers = @{ Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2022-11-28' }
    # An unresolved Azure macro such as "$(GitHubReadToken)" (fork builds get no secrets) means "no token".
    if ($Token -and $Token -notmatch '^\$\(') {
        $headers.Authorization = "Bearer $Token"
    }
    [pscustomobject]@{
        Repository    = $Repository
        ApiUrl        = $ApiUrl.TrimEnd('/')
        RepositoryUrl = "$($WebUrl.TrimEnd('/'))/$Repository"
        Headers       = $headers
        HasToken      = $headers.ContainsKey('Authorization')
    }
}
