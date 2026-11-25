function Set-PipelineBuildNumber {
    # Only for values built by this module (versions and branch words), never untrusted text.
    param([Parameter(Mandatory)] [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*[A-Za-z0-9]$')] [string] $BuildNumber)
    Write-Host "##vso[build.updatebuildnumber]$BuildNumber"
}
