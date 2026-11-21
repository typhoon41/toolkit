function Get-ContinuousIntegrationVersion {
    # The label (branch words, or 'ci' on the release branch) tells where a package came from.
    param(
        [Parameter(Mandatory)] $Version,
        [Parameter(Mandatory)] [ValidatePattern('^[0-9]+$')] [string] $BuildId,
        [Parameter(Mandatory)] [ValidatePattern('^[0-9a-z-]+$')] [string] $Label,
        [switch] $AlreadyReleased
    )
    $buildNumber = [bigint]::Parse($BuildId).ToString()
    if ($Version.IsPrerelease) {
        return "$($Version.Text).$Label.$buildNumber"
    }
    if ($AlreadyReleased) {
        return "$($Version.Major).$($Version.Minor).$($Version.Patch + 1)-$Label.$buildNumber"
    }
    "$($Version.Text)-$Label.$buildNumber"
}
