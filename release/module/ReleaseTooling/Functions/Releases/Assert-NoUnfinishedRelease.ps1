function Assert-NoUnfinishedRelease {
    param([Parameter(Mandatory)] $Context, [AllowEmptyCollection()] [object[]] $Releases = @())
    foreach ($draft in @(@($Releases) | Where-Object { $_.draft })) {
        $tag = ConvertTo-ReleaseTag -TagName $draft.tag_name -Prefix $Context.Prefix
        if (-not $tag -or $tag.Version.Text -eq $Context.Candidate.Text) {
            continue
        }
        if (Test-ReleaseSuperseded -Context $Context -Release $draft) {
            Write-ReleaseLog "Draft $($draft.tag_name) was superseded by a maintainer; ignoring it."
            continue
        }
        if (Test-PublicationStarted -Context $Context -VersionText $tag.Version.Text -Release $draft) {
            throw ("Release $($draft.tag_name) is unfinished: its feed push was started but its GitHub release is still a " +
                   "draft. Re-run that release's job (Rerun failed jobs) to complete it before releasing $($Context.Tag), or " +
                   'follow docs/RECOVERY.md (Reconciliation). Do not delete that draft.')
        }
        Write-PipelineIssue -Type warning -Message "Abandoned draft release $($draft.tag_name) exists (its feed push never started). You can delete it on GitHub."
    }
}
