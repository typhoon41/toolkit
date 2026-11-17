function Get-GitHubCollection {
    # Every item of a paged GitHub list endpoint.
    param([Parameter(Mandatory)] $Client, [Parameter(Mandatory)] [string] $Path, [int] $MaximumPages = 50)
    $separator = if ($Path.Contains('?')) { '&' } else { '?' }
    for ($page = 1; $page -le $MaximumPages; $page++) {
        $batch = @(Invoke-GitHubApi -Client $Client -Path "$Path${separator}per_page=100&page=$page")
        $batch
        if ($batch.Count -lt 100) {
            return
        }
    }
    throw "Stopped paging $Path after $MaximumPages pages"
}
