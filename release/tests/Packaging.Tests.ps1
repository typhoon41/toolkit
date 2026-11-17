BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
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

Describe 'Invoke-NpmPack' -Tag 'Npm' {
    It 'packs with the planned version and the notes, and restores the package' -Skip:(-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        $repository = Join-Path $TestDrive 'npm'
        Set-TestFile $repository 'web/package.json' "{`n  `"name`": `"@x/web`",`n  `"version`": `"2.0.0`",`n  `"files`": [`"dist`"]`n}`n"
        Set-TestFile $repository 'web/dist/index.js' 'export {}'
        Set-TestFile $repository 'notes/web.md' '## Features'
        $original = Get-Content -LiteralPath (Join-Path $repository 'web/package.json') -Raw
        $unitPlan = [pscustomobject]@{ name = 'web'; package = 'web/package.json'; packageVersion = '2.1.0-ci.5'; packageNames = @('@x/web') }
        Push-Location $repository
        try {
            $tarball = Invoke-NpmPack -UnitPlan $unitPlan -OutDirectory (Join-Path $repository 'out') -NotesFile (Join-Path $repository 'notes/web.md')
        }
        finally {
            Pop-Location
        }
        (Read-NpmTarballManifest $tarball)['version'] | Should -Be '2.1.0-ci.5'
        Get-NpmTarballIntegrity $tarball | Should -Match '^sha512-'
        Get-Content -LiteralPath (Join-Path $repository 'web/package.json') -Raw | Should -BeExactly $original
        Test-Path (Join-Path $repository 'web/RELEASE-NOTES.md') | Should -BeFalse
    }
}
