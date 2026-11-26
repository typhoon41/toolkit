function Get-TagRecency {
    # Tag name -> position of its commit in HEAD's history (0 = HEAD), only for tags reachable from HEAD. One history
    # walk and one tag listing, however many tags there are.
    $position = @{}
    $index = 0
    foreach ($commit in @(Invoke-Git rev-list --topo-order HEAD)) {
        $position[$commit] = $index
        $index++
    }
    # Ordinal keys: tags may differ only in case. lstrip=2 keeps the bare tag name even when a branch shares it.
    $recency = [Collections.Generic.Dictionary[string, int]]::new([StringComparer]::Ordinal)
    foreach ($line in @(Invoke-Git for-each-ref refs/tags '--format=%(refname:lstrip=2)%09%(*objectname)%09%(objectname)')) {
        $name, $peeled, $object = $line -split "`t"
        $commit = if ($peeled) { $peeled } else { $object }      # annotated tags point at a tag object first
        if ($position.ContainsKey($commit)) {
            $recency[$name] = $position[$commit]
        }
    }
    $recency
}
