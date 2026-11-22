BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../hooks/ConventionHooks') -Force
    $script:GateScript = Join-Path $PSScriptRoot '../hooks/Invoke-SkillGate.ps1'
    $script:GuardScript = Join-Path $PSScriptRoot '../hooks/Invoke-BannedPatternGuard.ps1'

    function New-ConfiguredProject {
        param([AllowNull()] [string] $Configuration)
        $root = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path (Join-Path $root '.git') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root '.claude') -Force | Out-Null
        if ($Configuration) {
            Set-Content -LiteralPath (Join-Path $root '.claude/conventions.json') -Value $Configuration
        }
        $root
    }

    function Invoke-Hook {
        param([string] $Script, [hashtable] $Payload, [string[]] $Argument = @())
        $output = $Payload | ConvertTo-Json -Depth 5 -Compress | & pwsh -NoProfile -NonInteractive -File $Script @Argument 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    }

    function New-WritePayload {
        param([string] $Root, [string] $Path, [string] $Content)
        @{ hook_event_name = 'PostToolUse'; cwd = $Root; tool_name = 'Write'; tool_input = @{ file_path = $Path; content = $Content } }
    }

    function New-EditPayload {
        param([string] $Root, [string] $Path)
        @{ hook_event_name = 'PreToolUse'; session_id = [guid]::NewGuid().ToString(); cwd = $Root; tool_name = 'Edit'; tool_input = @{ file_path = $Path; new_string = 'x' } }
    }
}

Describe 'Read-ProjectConfiguration' {
    It 'keeps the defaults without a working folder or a configuration file' {
        foreach ($root in '', (New-ConfiguredProject $null)) {
            $project = Read-ProjectConfiguration -Root $root
            $project.SkillGate, $project.BannedPatternGuard, $project.DotnetFormat | Should -Be @($true, $true, $true)
            $project.DisabledRules | Should -BeNullOrEmpty
            $project.Rules | Should -BeNullOrEmpty
            $project.ExcludedFolders | Should -Contain 'Migrations'
        }
    }

    It 'keeps the defaults for a file that is not JSON' {
        $project = Read-ProjectConfiguration -Root (New-ConfiguredProject '{ not json') 2>$null
        $project.SkillGate | Should -BeTrue
        $project.ExcludedFolders | Should -Contain 'node_modules'
    }

    It 'reads switches, disabled rules, rules, required skills and folders' {
        $root = New-ConfiguredProject (@'
{
  "hooks": { "skillGate": false, "dotnetFormat": false },
  "disabledRules": ["css-grid"],
  "rules": [ { "id": "no-console", "extensions": [".TS"], "pattern": "console\\.log", "message": "use the logger", "whenProjectDependsOn": "@angular/core" } ],
  "requiredSkills": { ".RAZOR": ["code-design", "dotnet"] },
  "excludedFolders": { "add": ["generated"], "remove": ["Migrations"] }
}
'@)
        $project = Read-ProjectConfiguration -Root $root
        $project.SkillGate | Should -BeFalse
        $project.BannedPatternGuard | Should -BeTrue
        $project.DotnetFormat | Should -BeFalse
        $project.DisabledRules | Should -Be @('css-grid')
        $project.Rules[0].Id | Should -Be 'no-console'
        $project.Rules[0].Extensions | Should -Be @('.ts')
        $project.Rules[0].WhenProjectDependsOn | Should -Be '@angular/core'
        $project.RequiredSkills['.razor'] | Should -Be @('code-design', 'dotnet')
        $project.ExcludedFolders | Should -Contain 'generated'
        $project.ExcludedFolders | Should -Not -Contain 'Migrations'
    }

    It 'keeps a hook on when its switch is <Value> instead of a boolean' -ForEach @(
        @{ Value = '0' }, @{ Value = '"false"' }, @{ Value = '[]' }, @{ Value = '{}' }, @{ Value = 'null' }
    ) {
        $project = Read-ProjectConfiguration -Root (New-ConfiguredProject "{ `"hooks`": { `"skillGate`": $Value } }") 2>$null
        $project.SkillGate | Should -BeTrue
    }

    It 'keeps only the skills the plugin ships in requiredSkills' {
        $root = New-ConfiguredProject '{ "requiredSkills": { ".razor": ["code-design", "dotnt"], ".vue": ["vue"] } }'
        $project = Read-ProjectConfiguration -Root $root 2>$null
        $project.RequiredSkills['.razor'] | Should -Be @('code-design')
        $project.RequiredSkills.ContainsKey('.vue') | Should -BeFalse
    }

    It 'finds the file in a folder above the working folder, but not past the repository root' {
        $root = New-ConfiguredProject '{ "hooks": { "skillGate": false } }'
        $nested = Join-Path $root 'src/app'
        New-Item -ItemType Directory -Path $nested -Force | Out-Null
        (Read-ProjectConfiguration -Root $nested).SkillGate | Should -BeFalse
        $inner = Join-Path $root 'packages/library'
        New-Item -ItemType Directory -Path (Join-Path $inner '.git') -Force | Out-Null
        (Read-ProjectConfiguration -Root $inner).SkillGate | Should -BeTrue
    }
}

Describe 'Get-PluginSkill' {
    It 'lists every skill folder of the plugin' {
        $skills = @(Get-PluginSkill)
        $skills | Should -Contain 'dotnet'
        $skills | Should -Contain 'gmf-ecosystem'
        $skills.Count | Should -Be @(Get-ChildItem (Join-Path $PSScriptRoot '../skills') -Directory).Count
    }
}

Describe 'Test-GuardedPath with project folders' {
    It 'skips an added folder and guards a removed one' {
        Test-GuardedPath -Path '/repo/generated/Client.ts' -ExcludedFolder @('generated') | Should -BeFalse
        Test-GuardedPath -Path '/repo/Infrastructure/Migrations/Init.cs' -ExcludedFolder @('bin') | Should -BeTrue
        Test-GuardedPath -Path '/repo/src/Api.g.cs' -ExcludedFolder @() | Should -BeFalse
    }
}

Describe 'Invoke-BannedPatternGuard.ps1 with a project configuration' {
    It 'does not report a rule the project disables' {
        $root = New-ConfiguredProject '{ "disabledRules": ["getter"] }'
        $result = Invoke-Hook -Script $script:GuardScript -Payload (New-WritePayload -Root $root -Path (Join-Path $root 'src/week.ts') -Content 'get label() {')
        $result.ExitCode | Should -Be 0
    }

    It 'reports a project rule, naming its skill' {
        $root = New-ConfiguredProject '{ "rules": [ { "id": "no-console", "extensions": [".ts"], "pattern": "console\\.log", "message": "use the logger", "skill": "logging" } ] }'
        $result = Invoke-Hook -Script $script:GuardScript -Payload (New-WritePayload -Root $root -Path (Join-Path $root 'src/week.ts') -Content 'console.log(1);')
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'no-console: use the logger \(skill logging\)'
    }

    It 'skips an invalid project rule and keeps the bundled ones' {
        $root = New-ConfiguredProject '{ "rules": [ { "id": "broken", "extensions": [".ts"], "pattern": "(", "message": "x" }, { "id": "empty", "extensions": [".ts"], "message": "x" }, { "id": "bad-dependency", "extensions": [".ts"], "pattern": "x", "message": "x", "whenProjectDependsOn": "package>20" } ] }'
        $result = Invoke-Hook -Script $script:GuardScript -Payload (New-WritePayload -Root $root -Path (Join-Path $root 'src/week.ts') -Content 'get label() {')
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match "Ignoring project rule 'broken'"
        $result.Output | Should -Match "Ignoring project rule 'empty'"
        $result.Output | Should -Match "Ignoring project rule 'bad-dependency'"
        $result.Output | Should -Match 'getter'
    }

    It 'exits 0 when the project switches the guard off' {
        $root = New-ConfiguredProject '{ "hooks": { "bannedPatternGuard": false } }'
        $result = Invoke-Hook -Script $script:GuardScript -Payload (New-WritePayload -Root $root -Path (Join-Path $root 'src/week.ts') -Content 'enum Status { Open }')
        $result.ExitCode | Should -Be 0
    }
}

Describe 'Invoke-SkillGate.ps1 with a project configuration' {
    BeforeEach {
        $script:Markers = Join-Path $TestDrive ([guid]::NewGuid())
    }

    It 'lets every edit through when the project switches the gate off' {
        $root = New-ConfiguredProject '{ "hooks": { "skillGate": false } }'
        (Invoke-Hook -Script $script:GateScript -Payload (New-EditPayload $root (Join-Path $root 'src/Service.cs')) -Argument @('-MarkerRoot', $script:Markers)).ExitCode | Should -Be 0
    }

    It 'keeps gating, with a warning, when the gate switch is <Value>' -ForEach @(@{ Value = '"false"' }, @{ Value = '[]' }) {
        $root = New-ConfiguredProject "{ `"hooks`": { `"skillGate`": $Value } }"
        $result = Invoke-Hook -Script $script:GateScript -Payload (New-EditPayload $root (Join-Path $root 'src/Service.cs')) -Argument @('-MarkerRoot', $script:Markers)
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'Ignoring skillGate in .*conventions\.json: expected true or false'
    }

    It 'keeps gating without a warning when the gate switch is null' {
        $root = New-ConfiguredProject '{ "hooks": { "skillGate": null } }'
        $result = Invoke-Hook -Script $script:GateScript -Payload (New-EditPayload $root (Join-Path $root 'src/Service.cs')) -Argument @('-MarkerRoot', $script:Markers)
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Not -Match 'Ignoring skillGate'
    }

    It 'requires the skills the project maps to an extension' {
        $root = New-ConfiguredProject '{ "requiredSkills": { ".razor": ["code-design", "dotnet"] } }'
        $result = Invoke-Hook -Script $script:GateScript -Payload (New-EditPayload $root (Join-Path $root 'src/Page.razor')) -Argument @('-MarkerRoot', $script:Markers)
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'conventions:dotnet'
    }

    It 'asks only for known skills when a required skill is misspelled, then lets the edit through' {
        $root = New-ConfiguredProject '{ "requiredSkills": { ".razor": ["code-design", "dotnt"] } }'
        $payload = New-EditPayload $root (Join-Path $root 'src/Page.razor')
        $result = Invoke-Hook -Script $script:GateScript -Payload $payload -Argument @('-MarkerRoot', $script:Markers)
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match "Ignoring unknown skill 'dotnt' for \.razor"
        $result.Output | Should -Match 'conventions:code-design'
        $result.Output | Should -Not -Match 'conventions:dotnt'
        $skill = @{ hook_event_name = 'PostToolUse'; session_id = $payload.session_id; cwd = $root; tool_name = 'Skill'; tool_input = @{ skill = 'conventions:code-design' } }
        Invoke-Hook -Script $script:GateScript -Payload $skill -Argument @('-MarkerRoot', $script:Markers) | Out-Null
        (Invoke-Hook -Script $script:GateScript -Payload $payload -Argument @('-MarkerRoot', $script:Markers)).ExitCode | Should -Be 0
    }

    It 'gates a folder the project removes from the exclusions' {
        $root = New-ConfiguredProject '{ "excludedFolders": { "remove": ["Migrations"] } }'
        $result = Invoke-Hook -Script $script:GateScript -Payload (New-EditPayload $root (Join-Path $root 'Migrations/Init.cs')) -Argument @('-MarkerRoot', $script:Markers)
        $result.ExitCode | Should -Be 2
    }
}
