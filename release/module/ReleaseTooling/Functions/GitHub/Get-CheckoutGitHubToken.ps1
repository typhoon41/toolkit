function Get-CheckoutGitHubToken {
    # Azure Pipelines exposes a GitHub service connection to scripts only through the authorization header that
    # `checkout` with persistCredentials leaves in the repository's git config.
    param([string] $RepositoryPath = (Get-Location).Path)
    $missingMessage = "No GitHub credentials are persisted in $RepositoryPath. Check the repository out with persistCredentials: true."
    try {
        $entries = @(Invoke-Git -C $RepositoryPath config --local --get-regexp '^http\..*extraheader$')
    }
    catch {
        throw "$missingMessage ($($_.Exception.Message))"
    }
    foreach ($entry in $entries) {
        if ($entry -match '(?i)authorization:\s*bearer\s+(?<token>\S+)') {
            return $Matches['token']
        }
        if ($entry -match '(?i)authorization:\s*basic\s+(?<credentials>\S+)') {
            $credentials = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Matches['credentials']))
            $separator = $credentials.IndexOf(':')
            if ($separator -ge 0 -and $separator -lt $credentials.Length - 1) {
                return $credentials.Substring($separator + 1)
            }
        }
    }
    throw $missingMessage
}
