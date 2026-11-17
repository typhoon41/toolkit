function New-ReleasePayload {
    # Body of a create/update request for the context's release.
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
