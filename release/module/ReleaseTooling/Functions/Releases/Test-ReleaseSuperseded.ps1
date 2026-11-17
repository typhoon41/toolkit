function Test-ReleaseSuperseded {
    # Whether a maintainer abandoned this draft (it must never be published).
    param([Parameter(Mandatory)] $Context, [AllowNull()] $Release)
    [bool](Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Superseded)
}
