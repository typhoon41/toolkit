function Get-RequiredSkill {
    # The bundled extension and dependency mappings, plus the project's own extension mapping
    # (.claude/conventions.json requiredSkills), each skill once.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [hashtable] $Configuration,
        [hashtable] $ProjectRequiredSkill = @{}
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
        if ($ProjectRequiredSkill.ContainsKey($extension)) {
            $ProjectRequiredSkill[$extension]
        }
    )
    $skills | Select-Object -Unique
}
