# Releases: re-runs, errors and recovery

The Release stage resumes with **Rerun failed jobs on the same run**. Every step is idempotent:

- **Prepare** creates or resumes a **draft** GitHub release (invisible, no tag yet) for each releasing
  unit, makes its assets match the build's packages, and finally uploads a `release-state.json`
  marker: *publication has started*. The marker is never modified; from then on the draft is frozen.
  Each Prepare also adds a `release-attempt-<utc time>.json` asset dating the latest push attempt.
- **Push**: if a version is already on the feed, the published package is compared with this build
  (NuGet: entry by entry, ignoring repository signing; npm: tarball integrity). Identical → skipped;
  anything else fails. NuGet symbol packages are retried on every run.
- **Publish** re-checks that no higher version was released meanwhile, verifies the assets and
  publishes the draft, which creates the tag. An already published release is only verified.

Application units have no assets: their release and tag are created in one idempotent step.

## Error messages

| You see | Meaning and fix |
|---|---|
| *Version '...' from ... is invalid: ...* | Fix `<Version>` / `version`; the message names the rule. |
| *Version X must be higher than the latest release Y* | Choose a version above Y. Prereleases count. |
| *Version X was already released as ...* | The bump went to a released version. Bump again. |
| Warning: *Version X is not released, but this commit didn't change it* | The bump's release never ran or failed. Re-run the bump commit's pipeline, or bump again. |
| *The projects of unit '...' must share one version* | A unit packs several projects; align their `<Version>`. |
| Release stage **skipped** | No unit's version changed in this merge. |
| *Y is already released, so X can no longer be published* | A higher version was released while this one waited. Bump. |
| *... is already on the feed and is not this build* | The version is taken by a different build. Bump; if a frozen draft blocks it, see **Abandon**. |
| *Release X was superseded by a maintainer* | That version was abandoned. Bump. |
| *The feed already holds version X but GitHub has no draft release* | Pushed outside the pipeline. Foreign → bump; this build's own → **Missing draft**. |
| *Tag X already exists and points to ...* | A tag was created by hand. Remove it if it was a mistake, or bump. |
| *Release Y is unfinished* | Finish Y first (Rerun failed jobs on Y's run, or **Reconciliation**). Never delete that draft. |
| *Publication of X has already started from commit ...* | The same version from another commit. Re-run the original run, or bump. |
| *... assets are frozen* | A new run of a commit whose package is already published. Re-run the original run. |
| *... has version '...' but this release of '...' is ...* | Something overrides the version at pack time. Remove it. |
| Warning: *Abandoned draft release Y exists* | Its approval was rejected before publishing started. Delete the draft. |
| Publish: *Prepare did not complete for X* | The draft has no marker: Prepare failed or was skipped. **Rerun failed jobs**; Prepare and the push run first. |
| Publish: *... not on the feed yet, so X stays a draft* | The push succeeded but the feed hasn't indexed it within `feedWaitMinutes`. **Rerun failed jobs** in a few minutes. |
| Anything else | **Rerun failed jobs**. If a feed reported a conflict, wait a few minutes first. |

## Drafts: which may be deleted

| Draft | Meaning | What to do |
|---|---|---|
| without `release-state.json` | Prepare never completed; nothing was pushed | Harmless; delete it or leave it |
| with `release-state.json` | Publication started; some packages may be on the feed | **Never delete.** Complete it (re-run, or Reconciliation); if impossible, **Abandon** |
| with `release-state.superseded.json` | Abandoned by a maintainer | Leave it as a record |

## Working from a workstation

The procedures below run the pipeline's scripts locally with PowerShell 7, git and the SDKs (`dotnet`
for NuGet, `npm` for npm). They need the plan and the packages laid out as in the pipeline's `release`
artifact:

```
recover/
  release-plan.json
  notes/<unit>.md                 # optional
  packages/<unit>/*.nupkg|*.snupkg|*.tgz
```

The run's `release` artifact is exactly that. If it is gone, check out the release commit with full
history and tags and recreate the plan, then download the draft's assets (everything except the
release-state files) into `recover/packages/<unit>/`:

```powershell
git fetch --tags origin && git checkout <sha> &&
pwsh <toolkit>/release/scripts/Resolve-ReleasePlan.ps1 -SourceBranch refs/heads/main -BuildId 0 -OutFile ./recover/release-plan.json -KeepRunName
```

Set `$env:GITHUB_TOKEN` (release token) and `$env:NUGET_API_KEY` / `$env:NPM_TOKEN` first. Run one
command at a time, stop at the first failure, and never publish while a push has failed. Disable the
release pipeline and wait for running instances before Restore or Abandon.

### Reconciliation: the original run is gone

```powershell
$s = '<toolkit>/release/scripts'
pwsh $s/Publish-GitHubRelease.ps1 -Action Prepare -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit> &&
pwsh $s/Publish-NuGetPackage.ps1 -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit> &&
pwsh $s/Publish-GitHubRelease.ps1 -Action Publish -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit>
```

(`Publish-NpmPackage.ps1` instead of `Publish-NuGetPackage.ps1` for an npm unit.) On a frozen draft,
Prepare only verifies the folder against the draft and records the attempt. Don't publish the draft in
the GitHub UI: that skips completing the feed side.

### Missing draft: the feed holds this build's packages but GitHub has no draft

Use the **complete** original artifacts (Restore cannot know about a package you leave out):

```powershell
pwsh $s/New-ReleaseNotes.ps1 -PlanFile ./recover/release-plan.json -OutDirectory ./recover/notes -Unit <unit> &&
pwsh $s/Publish-GitHubRelease.ps1 -Action Restore -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -NotesDirectory ./recover/notes -Unit <unit> &&
```

then continue with the three Reconciliation commands. If Restore says *a frozen draft already exists*,
continue from Prepare. Restore refuses when a package on the feed is foreign, or when none of this
build's packages is there.

### Abandon: a started release can never be completed

Only for a **version collision**: the feed holds a package under this version that is not this build's.
`recover/packages/<unit>/` must contain exactly the draft's own assets.

```powershell
pwsh $s/Publish-GitHubRelease.ps1 -Action Abandon -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit>
```

| Feed state of the draft's packages | Decision |
|---|---|
| none foreign, at least one this build's | **Refused**: complete the release instead |
| at least one foreign | **Allowed**; this build's packages already on the feed are listed in the draft's banner |
| nothing on the feed | Allowed once the latest push attempt is 60 minutes old (`-MinimumAgeMinutes`) |

Abandon deletes nothing: the marker becomes `release-state.superseded.json` and the draft is renamed
"(superseded - do not publish)". Then bump the version and release normally.

## What packages reveal

Packages record the repository URL and commit (NuGet `RepositoryUrl`/`RepositoryCommit`). The tooling
uses them to prove idempotency. A private repository's URL becomes visible in a public package.
