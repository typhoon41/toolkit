BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')

    function Invoke-TestNpmPack([string] $Repository, [switch] $WithNotes) {
        Set-TestFile $Repository 'notes/web.md' '## Features'
        $unitPlan = [pscustomobject]@{ name = 'web'; package = 'web/package.json'; packageVersion = '2.1.0-ci.5'; packageNames = @('@x/web') }
        $notes = if ($WithNotes) { Join-Path $Repository 'notes/web.md' } else { '' }
        Push-Location $Repository
        try {
            Invoke-NpmPack -UnitPlan $unitPlan -OutDirectory (Join-Path $Repository 'out') -NotesFile $notes
        }
        finally {
            Pop-Location
        }
    }
}

Describe 'New-ReleaseNotesTargetsFile' {
    It 'reads the notes file from MSBuild' {
        $notes = Join-Path $TestDrive 'Lib & Co.txt'
        Set-Content -LiteralPath $notes -Value 'notes'
        $targets = New-ReleaseNotesTargetsFile -NotesFile $notes -OutFile (Join-Path $TestDrive 'notes.targets')
        $xml = [xml](Get-Content -LiteralPath $targets -Raw)
        $xml.Project.PropertyGroup.PackageReleaseNotes | Should -BeLike '*ReadAllText(*Lib & Co.txt*'
    }
}

Describe 'Invoke-NpmPack' -Tag 'Npm' -Skip:(-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    It 'packs with the planned version and the notes, and restores the package' {
        $repository = Join-Path $TestDrive 'listed-files'
        Set-TestFile $repository 'web/package.json' "{`n  `"name`": `"@x/web`",`n  `"version`": `"2.0.0`",`n  `"files`": [`"dist`"]`n}`n"
        Set-TestFile $repository 'web/dist/index.js' 'export {}'
        $original = Get-Content -LiteralPath (Join-Path $repository 'web/package.json') -Raw
        $tarball = Invoke-TestNpmPack $repository -WithNotes
        (Read-NpmTarballManifest $tarball)['version'] | Should -Be '2.1.0-ci.5'
        Test-NpmTarballEntry -Path $tarball -Name 'RELEASE-NOTES.md' | Should -BeTrue
        Get-NpmTarballIntegrity $tarball | Should -Match '^sha512-'
        Get-Content -LiteralPath (Join-Path $repository 'web/package.json') -Raw | Should -BeExactly $original
        Test-Path (Join-Path $repository 'web/RELEASE-NOTES.md') | Should -BeFalse
    }

    It 'fails when .npmignore leaves the notes out' {
        $repository = Join-Path $TestDrive 'ignored-notes'
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.0.0" }'
        Set-TestFile $repository 'web/.npmignore' '*.md'
        Set-TestFile $repository 'web/index.js' 'export {}'
        { Invoke-TestNpmPack $repository -WithNotes } | Should -Throw '*excludes RELEASE-NOTES.md*'
        Test-Path (Join-Path $repository 'web/RELEASE-NOTES.md') | Should -BeFalse
    }

    It 'restores npm-shrinkwrap.json' {
        $repository = Join-Path $TestDrive 'shrinkwrap'
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.0.0" }'
        Set-TestFile $repository 'web/npm-shrinkwrap.json' "{`n  `"name`": `"@x/web`",`n  `"version`": `"2.0.0`",`n  `"lockfileVersion`": 3,`n  `"requires`": true,`n  `"packages`": { `"`": { `"name`": `"@x/web`", `"version`": `"2.0.0`" } }`n}`n"
        $original = [IO.File]::ReadAllBytes((Join-Path $repository 'web/npm-shrinkwrap.json'))
        Invoke-TestNpmPack $repository | Out-Null
        [IO.File]::ReadAllBytes((Join-Path $repository 'web/npm-shrinkwrap.json')) | Should -Be $original
    }
}
