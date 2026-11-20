BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../hooks/ConventionHooks') -Force
    $script:GateScript = Join-Path $PSScriptRoot '../hooks/Invoke-SkillGate.ps1'

    function Invoke-Gate {
        param([hashtable] $Payload, [string] $MarkerRoot)
        $output = $Payload | ConvertTo-Json -Depth 5 -Compress |
            & pwsh -NoProfile -NonInteractive -File $script:GateScript -MarkerRoot $MarkerRoot 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    }

    function New-EditPayload {
        param([string] $Path, [string] $Agent)
        $payload = @{ hook_event_name = 'PreToolUse'; session_id = 'session-1'; tool_name = 'Edit'; tool_input = @{ file_path = $Path; new_string = 'x' } }
        if ($Agent) {
            $payload.agent_id = $Agent
        }
        $payload
    }

    function New-SkillPayload {
        param([string] $Skill, [string] $Agent)
        $payload = @{ hook_event_name = 'PostToolUse'; session_id = 'session-1'; tool_name = 'Skill'; tool_input = @{ skill = $Skill } }
        if ($Agent) {
            $payload.agent_id = $Agent
        }
        $payload
    }
}

Describe 'Get-SkillMarkerPath' {
    It 'separates subagents from their session' {
        $session = Get-SkillMarkerPath -Payload ([pscustomobject]@{ session_id = 'abc' }) -MarkerRoot 'root'
        $agent = Get-SkillMarkerPath -Payload ([pscustomobject]@{ session_id = 'abc'; agent_id = 'agent-7' }) -MarkerRoot 'root'
        $session | Should -Not -Be $agent
        Split-Path -Leaf $agent | Should -Be 'abc-agent-7.txt'
    }

    It 'falls back to an hourly bucket without a session id' {
        Split-Path -Leaf (Get-SkillMarkerPath -Payload ([pscustomobject]@{}) -MarkerRoot 'root') |
            Should -Match '^\d{8}-\d{2}\.txt$'
    }
}

Describe 'Get-MissingSkill' {
    It 'returns the required skills not recorded yet, in order' {
        $marker = Join-Path $TestDrive 'marker.txt'
        Add-LoadedSkill -MarkerPath $marker -Skill 'csharp'
        Get-MissingSkill -MarkerPath $marker -Required @('code-design', 'csharp') | Should -Be @('code-design')
    }

    It 'returns every required skill without a marker file' {
        Get-MissingSkill -MarkerPath (Join-Path $TestDrive 'absent.txt') -Required @('a', 'b') | Should -Be @('a', 'b')
    }
}

Describe 'Invoke-SkillGate.ps1' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid())
    }

    It 'blocks an edit and names every missing Skill call' {
        $result = Invoke-Gate (New-EditPayload 'C:\repo\src\Service.cs') $script:Root
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'conventions:code-design'
        $result.Output | Should -Match 'conventions:csharp'
    }

    It 'allows the edit once the skills were loaded with the Skill tool' {
        Invoke-Gate (New-SkillPayload 'conventions:code-design') $script:Root | Out-Null
        Invoke-Gate (New-SkillPayload 'conventions:csharp') $script:Root | Out-Null
        (Invoke-Gate (New-EditPayload 'C:\repo\src\Service.cs') $script:Root).ExitCode | Should -Be 0
    }

    It 'still names only the skill that is missing' {
        Invoke-Gate (New-SkillPayload 'conventions:code-design') $script:Root | Out-Null
        $result = Invoke-Gate (New-EditPayload 'C:\repo\src\card.scss') $script:Root
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'conventions:html-scss'
        $result.Output | Should -Not -Match 'conventions:code-design'
    }

    It 'records a skill the user ran as a slash command' {
        foreach ($skill in 'code-design', 'typescript', 'angular', 'html-scss') {
            Invoke-Gate @{ hook_event_name = 'UserPromptExpansion'; session_id = 'session-1'; command_name = "conventions:$skill"; command_source = 'plugin' } $script:Root | Out-Null
        }
        (Invoke-Gate (New-EditPayload 'C:\repo\src\week.ts') $script:Root).ExitCode | Should -Be 0
    }

    It 'requires only code-design and typescript for TypeScript outside an Angular project' {
        $project = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path (Join-Path $project 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $project 'package.json') -Value '{ "dependencies": { "express": "^5.0.0" } }'
        $result = Invoke-Gate (New-EditPayload (Join-Path $project 'src/server.ts')) $script:Root
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'conventions:typescript'
        $result.Output | Should -Not -Match 'conventions:angular'
        foreach ($skill in 'code-design', 'typescript') {
            Invoke-Gate (New-SkillPayload "conventions:$skill") $script:Root | Out-Null
        }
        (Invoke-Gate (New-EditPayload (Join-Path $project 'src/server.ts')) $script:Root).ExitCode | Should -Be 0
    }

    It 'adds angular to <File> in an Angular project' -ForEach @(
        @{ File = 'card.ts' }, @{ File = 'card.html' }, @{ File = 'card.scss' }
    ) {
        $project = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path (Join-Path $project 'src/app') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $project 'package.json') -Value '{ "dependencies": { "@angular/core": "^20.0.0" } }'
        $result = Invoke-Gate (New-EditPayload (Join-Path $project "src/app/$File")) $script:Root
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'conventions:angular'
    }

    It 'ignores skills of other plugins with the same name' {
        Invoke-Gate (New-SkillPayload 'other:code-design') $script:Root | Out-Null
        Invoke-Gate (New-SkillPayload 'csharp') $script:Root | Out-Null
        (Invoke-Gate (New-EditPayload 'C:\repo\src\Service.cs') $script:Root).ExitCode | Should -Be 2
    }

    It 'does not let a subagent use the skills its parent loaded' {
        Invoke-Gate (New-SkillPayload 'conventions:code-design') $script:Root | Out-Null
        Invoke-Gate (New-SkillPayload 'conventions:csharp') $script:Root | Out-Null
        (Invoke-Gate (New-EditPayload 'C:\repo\src\Service.cs' -Agent 'agent-1') $script:Root).ExitCode | Should -Be 2
    }

    It 'lets through <Path>' -ForEach @(
        @{ Path = 'C:\repo\README.md' }
        @{ Path = 'C:\repo\node_modules\lib\index.ts' }
        @{ Path = 'C:\repo\Infrastructure\Migrations\20260101_Init.cs' }
    ) {
        (Invoke-Gate (New-EditPayload $Path) $script:Root).ExitCode | Should -Be 0
    }
}
