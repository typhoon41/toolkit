function Get-ContinuousIntegrationVersion {
    <#
        Version for a build that is not a release. The label is the branch words on feature branches
        and 'ci' on the release branch, so a package always tells where it came from:
          1.3.0         not yet released -> 1.3.0-<label>.<build>
          1.3.0         already released -> 1.3.1-<label>.<build>
          1.3.0-beta.1                   -> 1.3.0-beta.1.<label>.<build>
    #>
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
