function Compare-PrereleaseIdentifier {
    param([Parameter(Mandatory)] [string] $Left, [Parameter(Mandatory)] [string] $Right)
    $leftIsNumber = $Left -match '^[0-9]+$'
    $rightIsNumber = $Right -match '^[0-9]+$'
    $comparison = if ($leftIsNumber -and $rightIsNumber) { ([bigint]$Left).CompareTo([bigint]$Right) }
                  elseif ($leftIsNumber) { -1 }
                  elseif ($rightIsNumber) { 1 }
                  else { [string]::CompareOrdinal($Left, $Right) }
    [Math]::Sign($comparison)
}
