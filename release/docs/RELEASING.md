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
| *... is already on the feed and is not this build* | The version is taken by a different build. Bump; if a frozen draft blocks it, see [RECOVERY.md](RECOVERY.md), Abandon. |
| *Release X was superseded by a maintainer* | That version was abandoned. Bump. |
| *The feed already holds version X but GitHub has no draft release* | Pushed outside the pipeline. Foreign → bump; this build's own → [RECOVERY.md](RECOVERY.md), Missing draft. |
| *Tag X already exists and points to ...* | A tag was created by hand. Remove it if it was a mistake, or bump. |
| *Release Y is unfinished* | Finish Y first (Rerun failed jobs on Y's run, or [RECOVERY.md](RECOVERY.md), Reconciliation). Never delete that draft. |
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
| with `release-state.json` | Publication started; some packages may be on the feed | **Never delete.** Complete it (re-run, or [Reconciliation](RECOVERY.md)); if impossible, [Abandon](RECOVERY.md) |
| with `release-state.superseded.json` | Abandoned by a maintainer | Leave it as a record |

When the original run is gone, or a draft is missing or must be abandoned, follow
[RECOVERY.md](RECOVERY.md).

## What packages reveal

Packages record the repository URL and commit (NuGet `RepositoryUrl`/`RepositoryCommit`). The tooling
uses them to prove idempotency. A private repository's URL becomes visible in a public package.
