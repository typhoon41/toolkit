# Recovering a release from a workstation

For releases whose pipeline run can no longer finish them. Normal failures only need **Rerun failed
jobs**; see [RELEASING.md](RELEASING.md) for the error messages.

## Before you start

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

Set the credentials first:

| Variable | For |
|---|---|
| `$env:GITHUB_TOKEN` | the release token (Contents: write) |
| `$env:NUGET_API_KEY` | pushing to nuget.org (any value for Azure Artifacts, with its credential provider) |
| `$env:NUGET_FEED_READ_TOKEN` | reading a **private** NuGet feed: an Azure DevOps PAT with *Packaging: Read* |
| `$env:NPM_TOKEN`, or `$env:NPM_CONFIG_USERCONFIG` | npm: a token, or the path of an authenticated `.npmrc`, for publishing and for reading a private registry |

Run one command at a time, stop at the first failure, and never publish while a push has failed.
Disable the release pipeline and wait for running instances before Restore or Abandon.

## Reconciliation: the original run is gone

```powershell
$s = '<toolkit>/release/scripts'
pwsh $s/Publish-GitHubRelease.ps1 -Action Prepare -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit> &&
pwsh $s/Publish-NuGetPackage.ps1 -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit> &&
pwsh $s/Publish-GitHubRelease.ps1 -Action Publish -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit>
```

(`Publish-NpmPackage.ps1` instead of `Publish-NuGetPackage.ps1` for an npm unit.) On a frozen draft,
Prepare only verifies the folder against the draft and records the attempt. Don't publish the draft in
the GitHub UI: that skips completing the feed side.

## Missing draft: the feed holds this build's packages but GitHub has no draft

Use the **complete** original artifacts (Restore cannot know about a package you leave out):

```powershell
$s = '<toolkit>/release/scripts'
pwsh $s/New-ReleaseNotes.ps1 -PlanFile ./recover/release-plan.json -OutDirectory ./recover/notes -Unit <unit> &&
pwsh $s/Publish-GitHubRelease.ps1 -Action Restore -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -NotesDirectory ./recover/notes -Unit <unit>
```

then continue with the three Reconciliation commands. If Restore says *a frozen draft already exists*,
continue from Prepare. Restore refuses when a package on the feed is foreign, or when none of this
build's packages is there.

## Abandon: a started release can never be completed

Only for a **version collision**: the feed holds a package under this version that is not this build's.
`recover/packages/<unit>/` must contain exactly the draft's own assets.

```powershell
$s = '<toolkit>/release/scripts'
pwsh $s/Publish-GitHubRelease.ps1 -Action Abandon -PlanFile ./recover/release-plan.json -PackagesPath ./recover/packages -Unit <unit>
```

| Feed state of the draft's packages | Decision |
|---|---|
| none foreign, at least one this build's | **Refused**: complete the release instead |
| at least one foreign | **Allowed**; this build's packages already on the feed are listed in the draft's banner |
| nothing on the feed | Allowed once the latest push attempt is 60 minutes old (`-MinimumAgeMinutes`) |

Abandon deletes nothing: the marker becomes `release-state.superseded.json` and the draft is renamed
"(superseded - do not publish)". Then bump the version and release normally.
