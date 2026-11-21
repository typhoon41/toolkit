function Get-UntrustedFeedMessage {
    param([Parameter(Mandatory)] [string] $Url, [Parameter(Mandatory)] [string] $VariableName)
    $hostName = try { ([Uri]$Url).Host } catch { $Url }
    "$hostName is not a known feed host, so $VariableName is not sent to it. If it is your feed, add '$hostName' to the " +
    "pipeline's trustedFeedHosts parameter (-TrustedFeedHost when running the scripts yourself)."
}
