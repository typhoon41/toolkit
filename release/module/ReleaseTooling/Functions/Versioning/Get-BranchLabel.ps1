function Get-BranchLabel {
    param([AllowNull()] [AllowEmptyString()] [string] $BranchName, [int] $MaximumWords = 3)
    if (-not $BranchName) {
        return ''
    }
    $typeFolders = @('feature', 'features', 'bugfix', 'bugfixes', 'hotfix', 'hotfixes', 'fix', 'fixes',
                     'release', 'releases', 'chore', 'chores', 'task', 'tasks', 'topic', 'topics', 'dev', 'pull')
    $fillerWords = @('a', 'an', 'and', 'the', 'for', 'of', 'to', 'in', 'on', 'with', 'merge', 'head')

    $segments = [Collections.Generic.List[string]]::new()
    $segments.AddRange([string[]](($BranchName -replace '^refs/heads/', '') -split '/' | Where-Object { $_ }))
    if ($segments.Count -gt 2 -and $segments[0] -in 'users', 'user') {
        $segments.RemoveRange(0, 2)
    }
    if ($segments.Count -gt 1 -and $segments[0].ToLowerInvariant() -in $typeFolders) {
        $segments.RemoveAt(0)
    }

    $words = @(($segments -join '-').ToLowerInvariant() -split '[^a-z0-9]+' | Where-Object {
        $_ -and $_ -notmatch '^[0-9]+$' -and $_ -notin $fillerWords
    })
    ($words | Select-Object -First $MaximumWords) -join '-'
}
