function ConvertTo-DependencyRequirement {
    # 'package' or 'package>=major' (npm or NuGet id). AcceptsVersion takes the version text a manifest declares and
    # accepts it when any alternative of an npm range (a || b) allows a major at or above the minimum
    # (Get-HighestMajorVersion). An alternative with no upper bound, or one that cannot be read (workspace:*, latest,
    # $(Version)), is accepted, so an unknown version never drops a rule.
    param([Parameter(Mandatory)] [string] $Text)
    if ($Text -notmatch '^\s*(?<package>[^\s>=]+)\s*(?:>=\s*(?<major>\d+))?\s*$') {
        throw "Invalid dependency requirement '$Text': expected 'package' or 'package>=major'."
    }
    $requirement = [pscustomobject]@{
        Text                = $Text
        Package             = $Matches.package
        MinimumMajorVersion = if ($Matches.ContainsKey('major')) { [int]$Matches['major'] } else { $null }
    }
    $requirement | Add-Member -MemberType ScriptMethod -Name AcceptsVersion -Value {
        param([AllowNull()] [string] $Version)
        if ($null -eq $this.MinimumMajorVersion) {
            return $true
        }
        foreach ($alternative in ([string]$Version -split '\|\|')) {
            $highest = Get-HighestMajorVersion -Range $alternative
            if ($null -eq $highest -or $highest -ge $this.MinimumMajorVersion) {
                return $true
            }
        }
        $false
    }
    $requirement
}
