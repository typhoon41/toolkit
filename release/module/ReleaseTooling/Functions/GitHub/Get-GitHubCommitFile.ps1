function Get-GitHubCommitFile {
    # Paths a commit changed (renames count under both names), cached in -Cache by SHA.
    param([Parameter(Mandatory)] $Client, [Parameter(Mandatory)] [string] $Commit, [Parameter(Mandatory)] [hashtable] $Cache)
    if (-not $Cache.ContainsKey($Commit)) {
        $details = Invoke-GitHubApi -Client $Client -Path "commits/$Commit"
        $Cache[$Commit] = @(foreach ($file in @($details.files)) {
            $file.filename
            if ($file.PSObject.Properties['previous_filename'] -and $file.previous_filename) {
                $file.previous_filename
            }
        })
    }
    , $Cache[$Commit]
}
