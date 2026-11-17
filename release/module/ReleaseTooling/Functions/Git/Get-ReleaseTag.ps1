function Get-ReleaseTag {
    # Release tags with -Prefix in the local clone; optionally only those reachable from -MergedInto.
    param([Parameter(Mandatory)] [string] $Prefix, [string] $MergedInto)
    $arguments = @('tag', '--list', "$Prefix*")
    if ($MergedInto) {
        $arguments += @('--merged', $MergedInto)
    }
    foreach ($name in @(Invoke-Git @arguments)) {
        $tag = ConvertTo-ReleaseTag -TagName $name -Prefix $Prefix
        if ($tag) {
            $tag
        }
    }
}
