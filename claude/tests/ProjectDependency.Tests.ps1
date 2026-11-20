BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../hooks/ConventionHooks') -Force

    function New-ProjectFolder {
        param([AllowNull()] [string] $Manifest)
        $root = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path (Join-Path $root 'src/app') -Force | Out-Null
        if ($Manifest) {
            Set-Content -LiteralPath (Join-Path $root 'package.json') -Value $Manifest
        }
        $root
    }
}

Describe 'Test-ProjectDependency' {
    It 'finds a dependency in the nearest package.json above the file' {
        $root = New-ProjectFolder '{ "dependencies": { "@angular/core": "^20.0.0" } }'
        Test-ProjectDependency -Path (Join-Path $root 'src/app/card.ts') -Package '@angular/core' | Should -BeTrue
    }

    It 'finds a peer dependency of a library' {
        $root = New-ProjectFolder '{ "peerDependencies": { "@angular/core": "^20.0.0" } }'
        Test-ProjectDependency -Path (Join-Path $root 'src/app/card.ts') -Package '@angular/core' | Should -BeTrue
    }

    It 'finds a dev dependency' {
        $root = New-ProjectFolder '{ "devDependencies": { "@angular/core": "^20.0.0" } }'
        Test-ProjectDependency -Path (Join-Path $root 'src/app/card.ts') -Package '@angular/core' | Should -BeTrue
    }

    It 'is false when the project does not depend on the package' {
        $root = New-ProjectFolder '{ "dependencies": { "express": "^5.0.0" } }'
        Test-ProjectDependency -Path (Join-Path $root 'src/app/server.ts') -Package '@angular/core' | Should -BeFalse
    }

    It 'stops at the nearest package.json instead of looking further up' {
        $root = New-ProjectFolder '{ "dependencies": { "@angular/core": "^20.0.0" } }'
        Set-Content -LiteralPath (Join-Path $root 'src/package.json') -Value '{ "dependencies": {} }'
        Test-ProjectDependency -Path (Join-Path $root 'src/app/card.ts') -Package '@angular/core' | Should -BeFalse
    }

    It 'is false without any package.json or with an unreadable one' {
        $bare = New-ProjectFolder $null
        Test-ProjectDependency -Path (Join-Path $bare 'src/app/card.ts') -Package '@angular/core' | Should -BeFalse
        $broken = New-ProjectFolder '{ not json'
        Test-ProjectDependency -Path (Join-Path $broken 'src/app/card.ts') -Package '@angular/core' | Should -BeFalse
    }
}
