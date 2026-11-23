function New-DependencyInventory {
    # Everything the file's npm and .NET projects depend on, package → every declared version, read once per hook run;
    # ask it with Satisfies(requirement) (ConvertTo-DependencyRequirement) as often as needed. A requirement is met
    # when any declared version of the package is accepted, so one qualifying sibling project is enough.
    param([Parameter(Mandatory)] [string] $Path)
    $packages = Read-NugetManifest -Path $Path
    $npm = Read-NpmManifest -Path $Path
    foreach ($package in $npm.Keys) {
        $packages[$package] = @(if ($packages.ContainsKey($package)) { $packages[$package] }) + @($npm[$package])
    }
    $inventory = [pscustomobject]@{ Packages = $packages }
    $inventory | Add-Member -MemberType ScriptMethod -Name Satisfies -Value {
        param([Parameter(Mandatory)] [object] $Requirement)
        if (-not $this.Packages.ContainsKey($Requirement.Package)) {
            return $false
        }
        @($this.Packages[$Requirement.Package] | Where-Object { $Requirement.AcceptsVersion($_) }).Count -gt 0
    }
    $inventory
}
