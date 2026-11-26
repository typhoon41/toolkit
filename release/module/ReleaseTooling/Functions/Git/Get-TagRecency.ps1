function Get-TagRecency {
    # Tag name -> position of its commit in HEAD's history (0 = HEAD), only for tags reachable from HEAD. One history
    # walk and one tag listing, however many tags there are.
    $position = @{}
    $index = 0
    foreach ($commit in @(Invoke-Git rev-list --topo-order HEAD)) {
        $position[$commit] = $index
        $index++
    }
    $recency = @{}
    foreach ($line in @(Invoke-Git for-each-ref refs/tags '--format=%(refname:short)%09%(*objectname)%09%(objectname)')) {
        $name, $peeled, $object = $line -split "`t"
        $commit = if ($peeled) { $peeled } else { $object }      # annotated tags point at a tag object first
        if ($position.ContainsKey($commit)) {
            $recency[$name] = $position[$commit]
        }
    }
    $recency
}
