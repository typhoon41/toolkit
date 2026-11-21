function Get-RequiredSkill {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [hashtable] $Configuration
    )
    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $skills = @(
        if ($Configuration.Extensions.ContainsKey($extension)) {
            $Configuration.Extensions[$extension]
        }
        if ($Configuration.ContainsKey('WhenProjectDependsOn')) {
            foreach ($dependency in $Configuration.WhenProjectDependsOn.Keys) {
                $added = $Configuration.WhenProjectDependsOn[$dependency]
                if ($added.ContainsKey($extension) -and
                    (Test-ProjectDependency -Path $Path -Requirement (ConvertTo-DependencyRequirement -Text $dependency))) {
                    $added[$extension]
                }
            }
        }
    )
    $skills | Select-Object -Unique
}
