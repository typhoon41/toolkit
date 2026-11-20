function Get-NpmPackageState {
    # Published means the registry holds these exact bytes, which holds because npm pack is reproducible.
    param([Parameter(Mandatory)] [string] $File, [Parameter(Mandatory)] [string] $Registry)
    $manifest = Read-NpmTarballManifest $File
    $label = "$($manifest['name']) $($manifest['version'])"
    $published = Get-NpmPublishedIntegrity -Name $manifest['name'] -Version $manifest['version'] -Registry $Registry
    if (-not $published) {
        return [pscustomobject]@{ Label = $label; State = 'Absent'; Detail = '' }
    }
    if ($published -eq (Get-NpmTarballIntegrity $File)) {
        return [pscustomobject]@{ Label = $label; State = 'Published'; Detail = 'identical to this build' }
    }
    [pscustomobject]@{ Label = $label; State = 'Foreign'; Detail = 'the registry holds different bytes under this version' }
}
