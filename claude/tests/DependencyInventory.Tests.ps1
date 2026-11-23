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

    function Test-Dependency {
        param([string] $Path, [string] $Requirement)
        (New-DependencyInventory -Path $Path).Satisfies((ConvertTo-DependencyRequirement -Text $Requirement))
    }
}

Describe 'Get-HighestMajorVersion' {
    It 'reads <Range> as <Expected>' -ForEach @(
        @{ Range = '^20.1.0'; Expected = 20 }
        @{ Range = '~19.2'; Expected = 19 }
        @{ Range = '19'; Expected = 19 }
        @{ Range = '19.x'; Expected = 19 }
        @{ Range = '=19.1'; Expected = 19 }
        @{ Range = 'v20.0.0'; Expected = 20 }
        @{ Range = '20.0.0-rc.1'; Expected = 20 }
        @{ Range = '<20'; Expected = 19 }
        @{ Range = '<20.0.0'; Expected = 19 }
        @{ Range = '<20.x'; Expected = 19 }
        @{ Range = '<20.1'; Expected = 20 }
        @{ Range = '<=19.4'; Expected = 19 }
        @{ Range = '>=18 <21'; Expected = 20 }
        @{ Range = '18 - 19'; Expected = 19 }
        @{ Range = '[20.0,21.0)'; Expected = 20 }
        @{ Range = '(,20.0)'; Expected = 19 }
        @{ Range = '[19.0,20.0]'; Expected = 20 }
        @{ Range = '[2.1]'; Expected = 2 }
        @{ Range = '[1.0.0.0,2.0.0.0)'; Expected = 1 }
        @{ Range = '<2.0.0.0'; Expected = 1 }
        @{ Range = '<2.0.0.1'; Expected = 2 }
        @{ Range = '1.2.3.4'; Expected = 1 }
    ) {
        Get-HighestMajorVersion -Range $Range | Should -Be $Expected
    }

    It 'has no upper bound for <Range>' -ForEach @(
        @{ Range = '>=19' }, @{ Range = '>19.1' }, @{ Range = '*' }, @{ Range = 'x' }, @{ Range = '' }, @{ Range = '[1.0,)' }, @{ Range = '[1.0.0.0,)' }
        @{ Range = 'workspace:*' }, @{ Range = 'latest' }, @{ Range = '$(GmfVersion)' }, @{ Range = 'npm:@scope/core@^19' }
    ) {
        Get-HighestMajorVersion -Range $Range | Should -BeNullOrEmpty
    }
}

Describe 'ConvertTo-DependencyRequirement' {
    It 'reads <Text>' -ForEach @(
        @{ Text = '@angular/core'; Package = '@angular/core'; Major = $null }
        @{ Text = '@angular/core>=20'; Package = '@angular/core'; Major = 20 }
        @{ Text = 'Gmf.DDD.Common >= 2'; Package = 'Gmf.DDD.Common'; Major = 2 }
    ) {
        $requirement = ConvertTo-DependencyRequirement -Text $Text
        $requirement.Package | Should -Be $Package
        $requirement.MinimumMajorVersion | Should -Be $Major
    }

    It 'rejects <Text>' -ForEach @(@{ Text = '@angular/core>20' }, @{ Text = 'a b' }, @{ Text = '>=20' }) {
        { ConvertTo-DependencyRequirement -Text $Text } | Should -Throw '*Invalid dependency requirement*'
    }

    It 'accepts <Version> for a minimum of 20: <Expected>' -ForEach @(
        @{ Version = '^20.1.0'; Expected = $true }
        @{ Version = '~21.0.0'; Expected = $true }
        @{ Version = '>=20 <22'; Expected = $true }
        @{ Version = '20.x'; Expected = $true }
        @{ Version = 'v20.0.0'; Expected = $true }
        @{ Version = '~19.2.0'; Expected = $false }
        @{ Version = '^9.0.0'; Expected = $false }
        @{ Version = 'workspace:*'; Expected = $true }
        @{ Version = '$(AngularVersion)'; Expected = $true }
        @{ Version = '^19.0.0 || ^20.0.0'; Expected = $true }
        @{ Version = '^18.0.0 || ^19.0.0'; Expected = $false }
        @{ Version = '[20.0,21.0)'; Expected = $true }
        @{ Version = '[19.0,20.0)'; Expected = $false }
        @{ Version = '<20'; Expected = $false }
        @{ Version = '<=19'; Expected = $false }
        @{ Version = '<20.0.0'; Expected = $false }
        @{ Version = '<20.1'; Expected = $true }
        @{ Version = '>=19'; Expected = $true }
        @{ Version = '>=19 <20'; Expected = $false }
        @{ Version = '>=18 <21'; Expected = $true }
        @{ Version = '18 - 19'; Expected = $false }
        @{ Version = '19 - 21'; Expected = $true }
        @{ Version = '(,20.0)'; Expected = $false }
        @{ Version = '[19.0,20.0]'; Expected = $true }
        @{ Version = '[19.0,19.9]'; Expected = $false }
        @{ Version = '[1.0.0.0,2.0.0.0)'; Expected = $false }
        @{ Version = '[20.0.0.0,21.0.0.0)'; Expected = $true }
        @{ Version = '[1.0,)'; Expected = $true }
        @{ Version = '*'; Expected = $true }
        @{ Version = 'latest'; Expected = $true }
        @{ Version = $null; Expected = $true }
    ) {
        (ConvertTo-DependencyRequirement -Text '@angular/core>=20').AcceptsVersion($Version) | Should -Be $Expected
    }

    It 'accepts any version without a minimum' {
        (ConvertTo-DependencyRequirement -Text '@angular/core').AcceptsVersion('^9.0.0') | Should -BeTrue
    }
}

Describe 'New-DependencyInventory with npm' {
    It 'finds a dependency in the nearest package.json above the file' {
        $root = New-ProjectFolder '{ "dependencies": { "@angular/core": "^20.0.0" } }'
        Test-Dependency (Join-Path $root 'src/app/card.ts') '@angular/core' | Should -BeTrue
    }

    It 'finds a peer dependency of a library' {
        $root = New-ProjectFolder '{ "peerDependencies": { "@angular/core": "^20.0.0" } }'
        Test-Dependency (Join-Path $root 'src/app/card.ts') '@angular/core' | Should -BeTrue
    }

    It 'finds a dev dependency' {
        $root = New-ProjectFolder '{ "devDependencies": { "@angular/core": "^20.0.0" } }'
        Test-Dependency (Join-Path $root 'src/app/card.ts') '@angular/core' | Should -BeTrue
    }

    It 'finds an optional dependency' {
        $root = New-ProjectFolder '{ "optionalDependencies": { "@angular/core": "^20.0.0" } }'
        Test-Dependency (Join-Path $root 'src/app/card.ts') '@angular/core>=20' | Should -BeTrue
    }

    It 'is false when the project does not depend on the package' {
        $root = New-ProjectFolder '{ "dependencies": { "express": "^5.0.0" } }'
        Test-Dependency (Join-Path $root 'src/app/server.ts') '@angular/core' | Should -BeFalse
    }

    It 'stops at the nearest package.json instead of looking further up' {
        $root = New-ProjectFolder '{ "dependencies": { "@angular/core": "^20.0.0" } }'
        Set-Content -LiteralPath (Join-Path $root 'src/package.json') -Value '{ "dependencies": {} }'
        Test-Dependency (Join-Path $root 'src/app/card.ts') '@angular/core' | Should -BeFalse
    }

    It 'is false without any package.json or with an unreadable one' {
        $bare = New-ProjectFolder $null
        Test-Dependency (Join-Path $bare 'src/app/card.ts') '@angular/core' | Should -BeFalse
        $broken = New-ProjectFolder '{ not json'
        Test-Dependency (Join-Path $broken 'src/app/card.ts') '@angular/core' | Should -BeFalse
    }

    It 'applies the minimum major version' {
        $current = New-ProjectFolder '{ "dependencies": { "@angular/core": "^20.0.0" } }'
        Test-Dependency (Join-Path $current 'src/app/card.ts') '@angular/core>=20' | Should -BeTrue
        $older = New-ProjectFolder '{ "dependencies": { "@angular/core": "~19.2.0" } }'
        Test-Dependency (Join-Path $older 'src/app/card.ts') '@angular/core>=20' | Should -BeFalse
    }
}

Describe 'New-DependencyInventory with NuGet' {
    BeforeEach {
        $script:Solution = Join-Path $TestDrive ([guid]::NewGuid())
        $script:Project = Join-Path $script:Solution 'src/Api'
        New-Item -ItemType Directory -Path (Join-Path $script:Project 'Controllers') -Force | Out-Null
        $script:File = Join-Path $script:Project 'Controllers/EntryController.cs'
    }

    It 'judges a package that package.json also declares by its npm range alone' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><PackageReference Include="shared-package" /></ItemGroup></Project>'
        Set-Content -LiteralPath (Join-Path $script:Project 'package.json') -Value '{ "dependencies": { "shared-package": "^19.0.0" } }'
        Test-Dependency $script:File 'shared-package' | Should -BeTrue
        Test-Dependency $script:File 'shared-package>=20' | Should -BeFalse
    }

    It 'finds a PackageReference in the nearest .csproj' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" Version="2.1.0" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeTrue
    }

    It 'detects NuGet packages by presence only: any major passes' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" Version="1.0.0" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common>=20' | Should -BeTrue
    }

    It 'finds a ProjectReference to the library built from source' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><ProjectReference Include="..\..\Packages\Gmf.Net.Core.Common\Gmf.Net.Core.Common.csproj" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.Net.Core.Common' | Should -BeTrue
        Test-Dependency $script:File 'Core.Common' | Should -BeFalse
    }

    It 'does not count a central PackageVersion the project never references' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><PackageReference Include="Other" /></ItemGroup></Project>'
        Set-Content -LiteralPath (Join-Path $script:Solution 'Directory.Packages.props') -Value '<Project><ItemGroup><PackageVersion Include="Gmf.Mail.Common" Version="1.0.0" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.Mail.Common' | Should -BeFalse
    }

    It 'finds a PackageReference in Directory.Build.props above the project' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project />'
        Set-Content -LiteralPath (Join-Path $script:Solution 'Directory.Build.props') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common"><Version>2.0.0</Version></PackageReference></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeTrue
    }

    It 'ignores a parent Directory.Build.props that the nearest one does not import' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project />'
        Set-Content -LiteralPath (Join-Path $script:Solution 'Directory.Build.props') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" /></ItemGroup></Project>'
        Set-Content -LiteralPath (Join-Path $script:Solution 'src/Directory.Build.props') -Value '<Project><PropertyGroup><Nullable>enable</Nullable></PropertyGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeFalse
    }

    It 'follows a Directory.Build.props that imports its parent with GetPathOfFileAbove' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project />'
        Set-Content -LiteralPath (Join-Path $script:Solution 'Directory.Build.props') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" /></ItemGroup></Project>'
        Set-Content -LiteralPath (Join-Path $script:Solution 'src/Directory.Build.props') -Value '<Project><Import Project="$([MSBuild]::GetPathOfFileAbove(''Directory.Build.props'', ''$(MSBuildThisFileDirectory)../''))" /></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeTrue
    }

    It 'reads every .csproj in the project folder' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project />'
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.Tools.csproj') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeTrue
    }

    It 'does not count a PackageReference Update without an Include' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><PackageReference Update="Gmf.DDD.Common" Version="2.0.0" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeFalse
    }

    It 'reads no Directory.Build.props outside a .NET project' {
        Set-Content -LiteralPath (Join-Path $script:Solution 'Directory.Build.props') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeFalse
    }

    It 'reads single-quoted attributes and ignores commented-out references' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value "<Project><ItemGroup><PackageReference Include='Gmf.DDD.Common' Version='2.0.0' /><!-- <PackageReference Include=`"Gmf.Mail.Common`" /> --></ItemGroup></Project>"
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeTrue
        Test-Dependency $script:File 'Gmf.Mail.Common' | Should -BeFalse
    }

    It 'skips a .csproj that is not XML' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeFalse
    }

    It 'ignores a .csproj of a parent folder once the project is found' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project />'
        Set-Content -LiteralPath (Join-Path $script:Solution 'Tools.csproj') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeFalse
    }

    It 'is false without any reference' {
        Set-Content -LiteralPath (Join-Path $script:Project 'Api.csproj') -Value '<Project><ItemGroup><PackageReference Include="Gmf.DDD.Common.Extra" /></ItemGroup></Project>'
        Test-Dependency $script:File 'Gmf.DDD.Common' | Should -BeFalse
    }
}
