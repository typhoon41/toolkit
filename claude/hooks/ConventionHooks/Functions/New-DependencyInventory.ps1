function New-DependencyInventory {
    # Everything the file's npm and .NET projects depend on, package → declared versions, read once per hook run; ask
    # it with Satisfies(requirement) (ConvertTo-DependencyRequirement) as often as needed. npm packages carry their
    # declared range; NuGet packages are presence only (an unknown version, which every requirement accepts). A
    # package package.json declares is judged by its npm range alone, so a same-named NuGet reference can never lift
    # it past a minimum.
    param([Parameter(Mandatory)] [string] $Path)
    $packages = Read-NugetManifest -Path $Path
    $npm = Read-NpmManifest -Path $Path
    foreach ($package in $npm.Keys) {
        $packages[$package] = @($npm[$package])
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
