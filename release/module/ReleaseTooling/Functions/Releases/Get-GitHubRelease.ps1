function Get-GitHubRelease {
    # All releases of the repository, drafts included (drafts need a token with Contents: write).
    param([Parameter(Mandatory)] $Client)
    , @(Get-GitHubCollection -Client $Client -Path 'releases')
}
