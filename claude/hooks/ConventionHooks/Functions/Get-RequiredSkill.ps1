function Get-RequiredSkill {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [hashtable] $Configuration
    )
    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($Configuration.Extensions.ContainsKey($extension)) {
        $Configuration.Extensions[$extension]
    }
    if (-not $Configuration.ContainsKey('WhenProjectDependsOn')) {
        return
    }
    foreach ($package in $Configuration.WhenProjectDependsOn.Keys) {
        $added = $Configuration.WhenProjectDependsOn[$package]
        if ($added.ContainsKey($extension) -and (Test-ProjectDependency -Path $Path -Package $package)) {
            $added[$extension]
        }
    }
}
