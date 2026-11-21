function Get-GitHubRelease {
    # Drafts are listed only for a token with Contents: write.
    param([Parameter(Mandatory)] $Client)
    , @(Get-GitHubCollection -Client $Client -Path 'releases')
}
