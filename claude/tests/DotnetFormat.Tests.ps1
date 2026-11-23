BeforeDiscovery {
    # -Skip is evaluated during discovery, before BeforeAll runs.
    $script:HasDotnet = [bool](Get-Command dotnet -ErrorAction SilentlyContinue)
}

BeforeAll {
    $script:FormatScript = Join-Path $PSScriptRoot '../hooks/Invoke-DotnetFormat.ps1'
    $script:Misindented = "namespace Demo;`n`npublic class Sample`n{`n        public int Value { get; set; }`n}`n"

    function Invoke-Format {
        param([string] $Root, [string] $Path)
        $payload = @{ hook_event_name = 'PostToolUse'; cwd = $Root; tool_name = 'Edit'; tool_input = @{ file_path = $Path } }
        $output = $payload | ConvertTo-Json -Depth 5 -Compress | & pwsh -NoProfile -NonInteractive -File $script:FormatScript 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    }

    function New-Project {
        param([switch] $WithEditorConfig)
        $root = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $root | Out-Null
        if ($WithEditorConfig) {
            Set-Content -LiteralPath (Join-Path $root '.editorconfig') -Value "root = true`n`n[*.cs]`nindent_style = space`nindent_size = 4`n"
        }
        $file = Join-Path $root 'Sample.cs'
        [IO.File]::WriteAllText($file, $script:Misindented)
        [pscustomobject]@{ Root = $root; File = $file }
    }
}

Describe 'Invoke-DotnetFormat.ps1' {
    It 'reformats a mis-indented file and tells Claude to re-read it' -Skip:(-not $script:HasDotnet) {
        $project = New-Project -WithEditorConfig
        $result = Invoke-Format $project.Root $project.File
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Re-read it before editing it again'
        [IO.File]::ReadAllText($project.File) | Should -Match '(?m)^    public int Value'
    }

    It 'leaves the file alone when the project switches the hook off' -Skip:(-not $script:HasDotnet) {
        $project = New-Project -WithEditorConfig
        New-Item -ItemType Directory -Path (Join-Path $project.Root '.claude') | Out-Null
        Set-Content -LiteralPath (Join-Path $project.Root '.claude/conventions.json') -Value '{ "hooks": { "dotnetFormat": false } }'
        $result = Invoke-Format $project.Root $project.File
        $result.ExitCode | Should -Be 0
        $result.Output.Trim() | Should -BeNullOrEmpty
        [IO.File]::ReadAllText($project.File) | Should -Be $script:Misindented
    }

    It 'stays silent when the file already matches' -Skip:(-not $script:HasDotnet) {
        $project = New-Project -WithEditorConfig
        Invoke-Format $project.Root $project.File | Out-Null
        $result = Invoke-Format $project.Root $project.File
        $result.ExitCode | Should -Be 0
        $result.Output.Trim() | Should -BeNullOrEmpty
    }

    It 'does nothing without an .editorconfig' {
        $project = New-Project
        $result = Invoke-Format $project.Root $project.File
        $result.ExitCode | Should -Be 0
        $result.Output.Trim() | Should -BeNullOrEmpty
        [IO.File]::ReadAllText($project.File) | Should -Be $script:Misindented
    }

    It 'leaves a file outside the project root untouched' -Skip:(-not $script:HasDotnet) {
        $project = New-Project -WithEditorConfig
        $outside = New-Project
        $result = Invoke-Format $project.Root $outside.File
        $result.ExitCode | Should -Be 0
        $result.Output.Trim() | Should -BeNullOrEmpty
        [IO.File]::ReadAllText($outside.File) | Should -Be $script:Misindented
    }

    It 'ignores files that are not C#' {
        $project = New-Project -WithEditorConfig
        $other = Join-Path $project.Root 'notes.ts'
        Set-Content -LiteralPath $other -Value 'x'
        (Invoke-Format $project.Root $other).Output.Trim() | Should -BeNullOrEmpty
    }
}
