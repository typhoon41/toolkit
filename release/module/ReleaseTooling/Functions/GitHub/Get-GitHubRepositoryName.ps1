function Get-GitHubRepositoryName {
    # owner/repository of the 'origin' remote, for local runs that don't pass -Repository.
    $remoteUrl = [string](Invoke-Git remote get-url origin)
    if ($remoteUrl -notmatch '[:/](?<owner>[A-Za-z0-9._-]+)/(?<name>[A-Za-z0-9._-]+?)(?:\.git)?/?$') {
        throw "Cannot tell the GitHub repository from the origin remote '$remoteUrl'; pass -Repository owner/name."
    }
    "$($Matches['owner'])/$($Matches['name'])"
}
