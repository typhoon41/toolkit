function ConvertTo-ReleaseUnit {
    # One validated release unit from a release.json "units" entry.
    param([Parameter(Mandatory)] [hashtable] $Definition, [switch] $IsOnlyUnit)
    $name = [string]$Definition['name']
    if ($name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw "Release unit name '$name' must contain only letters, digits, '.', '_' and '-'."
    }
    $type = [string]$Definition['type']
    if ($type -notin 'nuget', 'npm', 'pipeline') {
        throw "Release unit '$name' has type '$type'; use nuget, npm or pipeline."
    }

    $projects = @($Definition['projects'] | Where-Object { $_ } | ForEach-Object { ConvertTo-RepositoryPath $_ })
    if ($type -eq 'nuget' -and $projects.Count -eq 0) {
        throw "NuGet unit '$name' needs 'projects': the .csproj files it packs."
    }
    $package = if ($Definition['package']) { ConvertTo-RepositoryPath $Definition['package'] } else { '' }
    if ($type -eq 'npm' -and -not $package) {
        throw "npm unit '$name' needs 'package': the path of its package.json."
    }

    $tagPrefix = if ($Definition['tagPrefix']) { [string]$Definition['tagPrefix'] }
                 elseif ($IsOnlyUnit) { 'v' }
                 else { "$name/v" }
    if ($tagPrefix -notmatch '^[A-Za-z0-9._/-]*$' -or $tagPrefix -match '//|^/') {
        throw "Release unit '$name' has an invalid tagPrefix '$tagPrefix'."
    }

    $paths = if ($null -ne $Definition['paths']) {
        @($Definition['paths'] | ForEach-Object { ConvertTo-RepositoryPath $_ })
    }
    else {
        $null      # defaults are decided by the plan, which knows where the version came from
    }

    [pscustomobject]@{
        Name        = $name
        Type        = $type
        Projects    = $projects
        Package     = $package
        TagPrefix   = $tagPrefix
        Paths       = $paths
        IsOnlyUnit  = [bool]$IsOnlyUnit
        NuGetSource = ConvertTo-FeedUrl -Value $Definition['nugetSource'] -Default 'https://api.nuget.org/v3/index.json' -Field "$name.nugetSource"
        NpmRegistry = ConvertTo-FeedUrl -Value $Definition['npmRegistry'] -Default 'https://registry.npmjs.org/' -Field "$name.npmRegistry"
    }
}
