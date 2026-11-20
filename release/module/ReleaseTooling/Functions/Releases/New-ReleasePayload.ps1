function New-ReleasePayload {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] [string] $Body, [bool] $Draft = $true)
    @{
        tag_name         = $Context.Tag
        target_commitish = $Context.Commit
        name             = $Context.Tag
        body             = $Body
        prerelease       = $Context.Candidate.IsPrerelease
        draft            = $Draft
    }
}
