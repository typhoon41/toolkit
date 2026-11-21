function Test-ProjectDependency {
    # True when the file's npm project or .NET project depends on the requirement (ConvertTo-DependencyRequirement).
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [object] $Requirement
    )
    (Test-NpmDependency -Path $Path -Requirement $Requirement) -or (Test-NugetDependency -Path $Path -Requirement $Requirement)
}
