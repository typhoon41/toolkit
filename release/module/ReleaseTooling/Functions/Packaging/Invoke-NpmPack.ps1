function Invoke-NpmPack {
    # `npm version` also rewrites the lock and shrinkwrap files, so the package directory is restored afterwards.
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [string] $OutDirectory,
        [string] $NotesFile
    )
    $packageDirectory = Split-Path -Parent ([IO.Path]::GetFullPath($UnitPlan.package, (Get-Location).Path))
    $notesTarget = Join-Path $packageDirectory 'RELEASE-NOTES.md'
    $backups = @{}
    foreach ($name in 'package.json', 'package-lock.json', 'npm-shrinkwrap.json', 'RELEASE-NOTES.md') {
        $path = Join-Path $packageDirectory $name
        $backups[$path] = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllBytes($path) } else { $null }
    }
    New-Item -ItemType Directory -Force -Path $OutDirectory | Out-Null
    $destination = (Resolve-Path -LiteralPath $OutDirectory).Path

    Push-Location -LiteralPath $packageDirectory
    try {
        Invoke-NpmCommand version $UnitPlan.packageVersion --no-git-tag-version --allow-same-version | Out-Null
        if ($NotesFile) {
            Copy-Item -LiteralPath $NotesFile -Destination $notesTarget -Force
            $manifest = Get-Content -LiteralPath 'package.json' -Raw | ConvertFrom-Json -AsHashtable
            if ($manifest.ContainsKey('files') -and @($manifest['files']) -notcontains 'RELEASE-NOTES.md') {
                Invoke-NpmCommand pkg set 'files[]=RELEASE-NOTES.md' | Out-Null
            }
        }
        Write-ReleaseLog "npm pack $($UnitPlan.package) ($($UnitPlan.packageVersion))"
        Invoke-NpmCommand pack --pack-destination $destination | ForEach-Object { Write-ReleaseLog "  $_" }
        # Derived, not parsed: lifecycle scripts may print to stdout.
        $tarball = Join-Path $destination ("$(($UnitPlan.packageNames[0] -replace '^@', '') -replace '/', '-')-$($UnitPlan.packageVersion).tgz")
        if (-not (Test-Path -LiteralPath $tarball)) {
            throw "npm pack did not produce $tarball."
        }
        if ($NotesFile -and -not (Test-NpmTarballEntry -Path $tarball -Name 'RELEASE-NOTES.md')) {
            throw ("$($UnitPlan.package) excludes RELEASE-NOTES.md from its package, so the release notes would be missing. " +
                   'Add RELEASE-NOTES.md to "files" in package.json, or un-ignore it in .npmignore.')
        }
        $tarball
    }
    finally {
        Pop-Location
        foreach ($path in $backups.Keys) {
            if ($null -eq $backups[$path]) {
                Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue
            }
            else {
                [IO.File]::WriteAllBytes($path, $backups[$path])
            }
        }
    }
}
