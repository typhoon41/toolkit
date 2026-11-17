function Set-PipelineBuildNumber {
    # Renames the Azure Pipelines run. Only for values built by this module (versions and branch words).
    param([Parameter(Mandatory)] [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._+-]*[A-Za-z0-9]$')] [string] $BuildNumber)
    Write-Host "##vso[build.updatebuildnumber]$BuildNumber"
}
