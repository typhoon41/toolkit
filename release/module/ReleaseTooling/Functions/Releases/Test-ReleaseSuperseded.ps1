function Test-ReleaseSuperseded {
    param([Parameter(Mandatory)] $Context, [AllowNull()] $Release)
    [bool](Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Superseded)
}
