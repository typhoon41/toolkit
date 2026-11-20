function Get-MissingSkill {
    param(
        [Parameter(Mandatory)] [string] $MarkerPath,
        [AllowEmptyCollection()] [string[]] $Required = @()
    )
    $loaded = if (Test-Path -LiteralPath $MarkerPath -PathType Leaf) { @(Get-Content -LiteralPath $MarkerPath) } else { @() }
    $Required | Where-Object { $loaded -notcontains $_ }
}
