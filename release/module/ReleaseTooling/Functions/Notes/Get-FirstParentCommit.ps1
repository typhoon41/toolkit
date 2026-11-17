function Get-FirstParentCommit {
    # Commits of -Range on the first-parent line (one per merged PR), newest first, limited to -Scope paths.
    param(
        [Parameter(Mandatory)] [string] $Range,
        [AllowEmptyCollection()] [string[]] $Scope = @()
    )
    $fieldSeparator = [char]0x1f
    $recordSeparator = [char]0x1e
    $arguments = @('log', '--first-parent', '--format=%H%x1f%P%x1f%s%x1f%an%x1f%b%x1e', $Range)
    if (@($Scope).Count -gt 0) {
        $arguments += @('--') + @($Scope)
    }
    $raw = (Invoke-Git @arguments) -join "`n"

    foreach ($record in $raw.Split($recordSeparator)) {
        $record = $record.Trim("`r`n".ToCharArray())
        if ([string]::IsNullOrWhiteSpace($record)) {
            continue
        }
        $hash, $parents, $subject, $author, $body = $record.Split([char[]]@($fieldSeparator), 5)
        [pscustomobject]@{
            Hash        = $hash
            ParentCount = @($parents -split ' ' | Where-Object { $_ }).Count
            Subject     = $subject
            Author      = $author
            Body        = [string]$body
        }
    }
}
