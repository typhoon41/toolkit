function New-DependencyInventory {
    # Everything the file's npm and .NET projects depend on, read once per hook run; ask it with
    # Satisfies(requirement) (ConvertTo-DependencyRequirement) as often as needed.
    param([Parameter(Mandatory)] [string] $Path)
    $packages = Read-NugetManifest -Path $Path
    $npm = Read-NpmManifest -Path $Path
    foreach ($package in $npm.Keys) {
        $packages[$package] = $npm[$package]
    }
    $inventory = [pscustomobject]@{ Packages = $packages }
    $inventory | Add-Member -MemberType ScriptMethod -Name Satisfies -Value {
        param([Parameter(Mandatory)] [object] $Requirement)
        $this.Packages.ContainsKey($Requirement.Package) -and $Requirement.AcceptsVersion($this.Packages[$Requirement.Package])
    }
    $inventory
}
