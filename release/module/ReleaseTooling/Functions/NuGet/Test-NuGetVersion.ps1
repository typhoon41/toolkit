function Test-NuGetVersion {
    <#
        200 -> look in the version list; 404 -> the id has never been published; anything else fails closed
        (an outage must never be read as "not published").
    #>
    param(
        [Parameter(Mandatory)] [string] $FlatContainer,
        [Parameter(Mandatory)] [string] $Id,
        [Parameter(Mandatory)] [string] $Version,
        [hashtable] $Headers = @{}
    )
    $indexUrl = "$FlatContainer$($Id.ToLowerInvariant())/index.json"
    $versions = Invoke-RestMethod -Uri $indexUrl -Headers $Headers -SkipHttpErrorCheck -StatusCodeVariable status
    switch ($status) {
        200 { return (@($versions.versions) -contains $Version.ToLowerInvariant()) }
        404 { return $false }
        default { throw "NuGet feed returned HTTP $status for $indexUrl; cannot tell whether $Id $Version is published." }
    }
}
