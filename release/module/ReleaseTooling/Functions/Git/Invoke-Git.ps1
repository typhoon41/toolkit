function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments)] [string[]] $Arguments)
    if ([Console]::OutputEncoding.WebName -ne 'utf-8') {
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new()   # non-ASCII author names and file content
    }
    $output = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed (exit code $LASTEXITCODE)"
    }
    $output
}
