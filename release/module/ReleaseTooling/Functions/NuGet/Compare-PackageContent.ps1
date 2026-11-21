function Compare-PackageContent {
    param([Parameter(Mandatory)] [string] $LocalPath, [Parameter(Mandatory)] [string] $RemotePath)
    $local = Get-PackageEntryMap $LocalPath
    $remote = Get-PackageEntryMap $RemotePath
    $differences = [Collections.Generic.List[string]]::new()
    foreach ($name in $local.Keys) {
        if (-not $remote.ContainsKey($name)) {
            $differences.Add("only in this build: $name")
        }
        elseif ($local[$name] -ne $remote[$name]) {
            $differences.Add("differs: $name")
        }
    }
    foreach ($name in $remote.Keys) {
        if (-not $local.ContainsKey($name)) {
            $differences.Add("only on the feed: $name")
        }
    }
    , $differences.ToArray()
}
