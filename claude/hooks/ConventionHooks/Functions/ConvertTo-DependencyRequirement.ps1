function ConvertTo-DependencyRequirement {
    # 'package' or 'package>=major' (npm or NuGet id). AcceptsVersion takes the version text a manifest declares; a
    # range without a readable major (workspace:*, latest, $(Version)) is accepted, so an unknown version never drops a rule.
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
        if ($null -eq $this.MinimumMajorVersion -or $Version -notmatch '(?<!\S)[\^~>=v]*(?<major>\d+)') {
            return $true
        }
        [int]$Matches.major -ge $this.MinimumMajorVersion
    }
    $requirement
}
