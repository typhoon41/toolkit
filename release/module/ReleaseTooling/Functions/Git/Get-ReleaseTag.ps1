function Get-ReleaseTag {
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
