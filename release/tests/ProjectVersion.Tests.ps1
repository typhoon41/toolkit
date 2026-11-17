BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
}

Describe 'Read-MSBuildVersion' {
    BeforeEach {
        $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('n'))
        New-Item -ItemType Directory -Path $root | Out-Null
        $snapshot = New-RepositorySnapshot -RepositoryRoot $root
    }

    It 'reads <Version> from Directory.Build.props when the csproj has none' {
        Set-TestFile $root 'Directory.Build.props' (New-PropsContent '1.2.0')
        Set-TestFile $root 'src/Lib/Lib.csproj' (New-ProjectContent)
        $version = Read-MSBuildVersion -Snapshot $snapshot -ProjectPath 'src/Lib/Lib.csproj'
        $version.Text | Should -Be '1.2.0'
        $version.SourceFile | Should -Be 'Directory.Build.props'
    }

    It 'lets the csproj override Directory.Build.props' {
        Set-TestFile $root 'Directory.Build.props' (New-PropsContent '1.2.0')
        Set-TestFile $root 'src/Lib/Lib.csproj' (New-ProjectContent '2.0.0-beta.1')
        $version = Read-MSBuildVersion -Snapshot $snapshot -ProjectPath 'src/Lib/Lib.csproj'
        $version.Text | Should -Be '2.0.0-beta.1'
        $version.SourceFile | Should -Be 'src/Lib/Lib.csproj'
    }

    It 'uses the nearest props file' {
        Set-TestFile $root 'Directory.Build.props' (New-PropsContent '1.0.0')
        Set-TestFile $root 'src/Directory.Build.props' (New-PropsContent '3.0.0')
        Set-TestFile $root 'src/Lib/Lib.csproj' (New-ProjectContent)
        (Read-MSBuildVersion -Snapshot $snapshot -ProjectPath 'src/Lib/Lib.csproj').Text | Should -Be '3.0.0'
    }

    It 'follows a props file that imports its parent' {
        Set-TestFile $root 'Directory.Build.props' (New-PropsContent '1.0.0')
        Set-TestFile $root 'src/Directory.Build.props' "<Project><Import Project=`"`$([MSBuild]::GetPathOfFileAbove('Directory.Build.props', '`$(MSBuildThisFileDirectory)../'))`" /></Project>"
        Set-TestFile $root 'src/Lib/Lib.csproj' (New-ProjectContent)
        (Read-MSBuildVersion -Snapshot $snapshot -ProjectPath 'src/Lib/Lib.csproj').Text | Should -Be '1.0.0'
    }

    It 'does not look past a props file that does not import its parent' {
        Set-TestFile $root 'Directory.Build.props' (New-PropsContent '1.0.0')
        Set-TestFile $root 'src/Directory.Build.props' '<Project />'
        Set-TestFile $root 'src/Lib/Lib.csproj' (New-ProjectContent)
        { Read-MSBuildVersion -Snapshot $snapshot -ProjectPath 'src/Lib/Lib.csproj' } | Should -Throw '*no <Version>*'
    }

    It 'returns nothing for a project that does not exist' {
        Read-MSBuildVersion -Snapshot $snapshot -ProjectPath 'missing/Missing.csproj' | Should -BeNullOrEmpty
    }
}

Describe 'Read-NpmVersion' {
    It 'reads name and version' {
        $root = Join-Path $TestDrive 'npm'
        Set-TestFile $root 'web/package.json' '{ "name": "@scope/web", "version": "2.1.0" }'
        $version = Read-NpmVersion -Snapshot (New-RepositorySnapshot -RepositoryRoot $root) -PackagePath 'web/package.json'
        $version.Name | Should -Be '@scope/web'
        $version.Text | Should -Be '2.1.0'
    }

    It 'refuses a private package' {
        $root = Join-Path $TestDrive 'private'
        Set-TestFile $root 'package.json' '{ "name": "app", "version": "1.0.0", "private": true }'
        { Read-NpmVersion -Snapshot (New-RepositorySnapshot -RepositoryRoot $root) -PackagePath 'package.json' } | Should -Throw '*private*'
    }
}

Describe 'New-RepositorySnapshot at a revision' {
    It 'reads files as they were in an earlier commit' {
        $repository = New-TestRepository (Join-Path $TestDrive 'history')
        Set-TestFile $repository 'Directory.Build.props' (New-PropsContent '1.0.0')
        Save-TestCommit $repository 'chore: first'
        Set-TestFile $repository 'Directory.Build.props' (New-PropsContent '1.1.0')
        Save-TestCommit $repository 'chore: second'
        Push-Location $repository
        try {
            $previous = New-RepositorySnapshot -RepositoryRoot $repository -Revision 'HEAD^'
            $previous.ReadText('Directory.Build.props') | Should -Match '1\.0\.0'
            $previous.ReadText('missing.txt') | Should -BeNullOrEmpty
        }
        finally {
            Pop-Location
        }
    }
}
