function Read-ProjectConfiguration {
    # The project's .claude/conventions.json on top of the plugin defaults: it switches hooks off, disables rules by id,
    # adds rules and required skills, and adds or removes excluded folders. Removals win over additions. A missing file
    # keeps the defaults; an unreadable one keeps them too, with one warning on stderr, so a hook never fails on it.
    param(
        [AllowEmptyString()] [string] $Root = '',
        [string] $DefaultsPath = (Join-Path $PSScriptRoot '../../GuardedPaths.psd1')
    )
    $settings = $null
    $file = Find-ProjectConfigurationFile -Root $Root
    if ($file) {
        try {
            $settings = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
        }
        catch {
            [Console]::Error.WriteLine("Ignoring ${file}: it is not valid JSON ($($_.Exception.Message)).")
        }
    }
    $hooks = Get-JsonProperty -Object $settings -Name 'hooks'
    $folders = Get-JsonProperty -Object $settings -Name 'excludedFolders'
    $removed = @(Get-JsonProperty -Object $folders -Name 'remove' -Default @())
    $defaults = (Import-PowerShellDataFile -LiteralPath $DefaultsPath).ExcludedFolders
    $requiredSkills = @{}
    $extensions = Get-JsonProperty -Object $settings -Name 'requiredSkills'
    if ($extensions -is [pscustomobject]) {
        # A skill the plugin does not ship could never be loaded, so the gate would block that extension for good.
        $known = @(Get-PluginSkill)
        foreach ($extension in $extensions.PSObject.Properties) {
            $name = $extension.Name.ToLowerInvariant()
            $skills = @($extension.Value | ForEach-Object { [string]$_ } | Where-Object {
                    if ($known -notcontains $_) {
                        [Console]::Error.WriteLine("Ignoring unknown skill '$_' for $name in ${file}.")
                    }
                    $known -contains $_
                })
            if ($skills.Count -gt 0) {
                $requiredSkills[$name] = $skills
            }
        }
    }
    [pscustomobject]@{
        SkillGate          = Get-BooleanSetting -Object $hooks -Name 'skillGate' -Default $true -Source $file
        BannedPatternGuard = Get-BooleanSetting -Object $hooks -Name 'bannedPatternGuard' -Default $true -Source $file
        DotnetFormat       = Get-BooleanSetting -Object $hooks -Name 'dotnetFormat' -Default $true -Source $file
        DisabledRules      = @(Get-JsonProperty -Object $settings -Name 'disabledRules' -Default @() | ForEach-Object { [string]$_ })
        Rules              = @(Get-JsonProperty -Object $settings -Name 'rules' -Default @() | ForEach-Object { ConvertTo-BannedPatternDefinition -Rule $_ })
        RequiredSkills     = $requiredSkills
        ExcludedFolders    = @(@($defaults) + @(Get-JsonProperty -Object $folders -Name 'add' -Default @()) |
                Where-Object { $removed -notcontains $_ } | Select-Object -Unique)
    }
}
