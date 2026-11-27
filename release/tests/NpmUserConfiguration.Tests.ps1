BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
}

Describe 'Initialize-NpmUserConfiguration' {
    BeforeEach {
        $path = Join-Path $TestDrive "npmrc-$([Guid]::NewGuid().ToString('n'))"
    }

    It 'writes an .npmrc naming registry.npmjs.org when the project has none' {
        Initialize-NpmUserConfiguration -Path $path | Should -BeTrue
        Get-Content -LiteralPath $path -Raw | Should -Be "registry=https://registry.npmjs.org/`n"
    }

    It 'names the given registry' {
        Initialize-NpmUserConfiguration -Path $path -Registry 'https://contoso.example/npm/' | Should -BeTrue
        Get-Content -LiteralPath $path -Raw | Should -Be "registry=https://contoso.example/npm/`n"
    }

    It 'leaves a committed .npmrc untouched' {
        $committed = 'registry=https://pkgs.dev.azure.com/org/_packaging/feed/npm/registry/'
        Set-Content -LiteralPath $path -Value $committed -NoNewline
        Initialize-NpmUserConfiguration -Path $path | Should -BeFalse
        Get-Content -LiteralPath $path -Raw | Should -Be $committed
    }

    It 'writes no byte order mark' {
        Initialize-NpmUserConfiguration -Path $path | Out-Null
        [IO.File]::ReadAllBytes($path)[0] | Should -Be ([byte][char]'r')
    }
}
