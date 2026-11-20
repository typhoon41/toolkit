---
name: conventional-commits
description: Commit message and pull request title format (Conventional Commits) that the toolkit's release tooling turns into release notes, and how a package release is triggered. Apply whenever writing a commit message, a PR title, or preparing a release.
---

# Commits, PR titles and releases

Release notes are generated from commit messages by the toolkit's `release/` tooling, so what a commit says is
what users read. The human-facing version of these rules is `release/docs/CONTRIBUTING.md` in
github.com/typhoon41/toolkit.

## Format

```
type(optional scope)!: description
```

- `type` is lowercase and from the table; a colon and **one space** follow it.
- `scope` names the area: `fix(calendar): keep the week when saving an entry`.
- The description is imperative ("add", not "added"/"adds") and says what changes for the user.
- The PR title uses the same format. The PR description links the ticket, then one paragraph on what changed and
  why, written for a reviewer who has not read the ticket - not a changelog, no headings.

| Type | Release notes section |
|---|---|
| `feat` | Features |
| `fix` | Bug Fixes |
| `docs` | Documentation |
| `perf`, `refactor`, `test`, `build`, `ci`, `chore`, `style`, `revert` | Chores |

Anything else lands in Chores.

## Breaking changes

Removed or renamed public API, changed behaviour, dropped frameworks: put `!` before the colon
(`feat!: drop .NET 8 support`) or a `BREAKING CHANGE: ...` footer in the body. Mark the **commit** itself, not only
the PR title - notes are built from the PR's individual commits.

## Shape of the history

- One logical change per commit, so each becomes one accurate release-note line.
- `fixup!` / `squash!` / `amend!` and merge commits never appear in the notes.

## Releasing

- A release is a version bump merged through a PR: `<Version>` in the `.csproj` (it wins over
  `Directory.Build.props`) or `version` in `package.json`. Choose it by SemVer: breaking → major, `feat` → minor,
  otherwise patch; prereleases look like `1.3.0-beta.2`.
- The version must be higher than every existing release, prereleases included.
- Never create release tags or GitHub releases by hand: the pipeline creates them after approval.
