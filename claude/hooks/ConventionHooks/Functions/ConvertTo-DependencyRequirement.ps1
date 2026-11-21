function ConvertTo-DependencyRequirement {
    # 'package' or 'package>=major' (npm or NuGet id). AcceptsVersion takes the version text a manifest declares and
    # accepts it when any alternative of an npm range (a || b) starts at or above the minimum major; NuGet ranges
    # ([2.0,3.0)) read like npm ones. An alternative without a readable major (workspace:*, latest, $(Version)) is
    # accepted, so an unknown version never drops a rule.
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
            if ($alternative -notmatch '(?<![\S])[\^~>=v\[(]*(?<major>\d+)' -or [int]$Matches['major'] -ge $this.MinimumMajorVersion) {
                return $true
            }
        }
        $false
    }
    $requirement
}
