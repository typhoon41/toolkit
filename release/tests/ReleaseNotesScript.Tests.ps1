BeforeAll {
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
    $script = (Resolve-Path (Join-Path $PSScriptRoot '../scripts/New-ReleaseNotes.ps1')).Path
}

Describe 'New-ReleaseNotes.ps1' {
    It 'succeeds without notes when no unit releases, as on every branch and pull-request build' {
        $repository = New-TestRepository (Join-Path $TestDrive 'no-release')
        Save-TestCommit $repository 'feat: initial'
        $planFile = Join-Path $TestDrive 'release-plan.json'
        Set-Content -LiteralPath $planFile -Value '{ "schemaVersion": 1, "units": [ { "name": "config", "type": "npm", "canRelease": false } ] }'
        $notesDirectory = Join-Path $TestDrive 'notes'

        $output = & pwsh -NoProfile -NonInteractive -File $script -PlanFile $planFile -OutDirectory $notesDirectory `
            -Repository 'owner/demo' -RepositoryRoot $repository 2>&1

        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        ($output -join "`n") | Should -Match 'No unit releases in this build'
        Test-Path -LiteralPath $notesDirectory | Should -BeFalse
    }
}
