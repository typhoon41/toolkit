function Invoke-NpmCommand {
    param([Parameter(ValueFromRemainingArguments)] [string[]] $Arguments)
    $output = & npm @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $standardOutput = @($output | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ })
    foreach ($line in @($output | Where-Object { $_ -is [Management.Automation.ErrorRecord] })) {
        Write-ReleaseLog "npm: $line"
    }
    if ($exitCode -ne 0) {
        throw "npm $($Arguments[0]) failed (exit code $exitCode)."
    }
    $standardOutput
}
