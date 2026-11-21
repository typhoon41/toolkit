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
        $conditional = @(
            if ($Configuration.ContainsKey('WhenProjectDependsOn')) {
                $Configuration.WhenProjectDependsOn.Keys | Where-Object { $Configuration.WhenProjectDependsOn[$_].ContainsKey($extension) }
            }
        )
        if ($conditional.Count -gt 0) {
            $inventory = New-DependencyInventory -Path $Path
            foreach ($dependency in $conditional) {
                if ($inventory.Satisfies((ConvertTo-DependencyRequirement -Text $dependency))) {
                    $Configuration.WhenProjectDependsOn[$dependency][$extension]
                }
            }
        }
        if ($ProjectRequiredSkill.ContainsKey($extension)) {
            $ProjectRequiredSkill[$extension]
        }
    )
    $skills | Select-Object -Unique
}
