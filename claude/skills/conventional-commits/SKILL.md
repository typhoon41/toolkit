---
name: conventional-commits
description: Commit message and pull request title format (Conventional Commits) that the toolkit's release tooling turns into release notes, and how a package release is triggered. Apply whenever writing a commit message, a PR title or description, or preparing a release.
---

# Commits, PR titles and releases

The toolkit's `release/` tooling builds release notes from commit messages (human version:
`release/docs/CONTRIBUTING.md` in github.com/typhoon41/toolkit), so what a commit says is what users read.

## Format

`type(optional scope)!: description` - lowercase type, a colon and one space, a scope naming the area, and an
imperative description of what changes for the user: `fix(calendar): keep the week when saving an entry`.

Sections: `feat` → Features, `fix` → Bug Fixes, `docs` → Documentation; `perf`, `refactor`, `test`, `build`, `ci`,
`chore`, `style`, `revert` and anything else → Chores.

The PR title uses the same format. The PR description links the ticket, then one paragraph on what changed and why
for a reviewer who has not read the ticket - not a changelog, no headings.

One logical change per commit, so each becomes one accurate release-note line.

## Breaking changes

Removed or renamed public API, changed behaviour, dropped frameworks: `!` before the colon
(`feat!: drop .NET 8 support`) or a `BREAKING CHANGE: ...` footer. Mark the **commit** itself, not only the PR title:
notes are built from the PR's individual commits.

## Releasing

- A release is a version bump merged through a PR: `<Version>` in the `.csproj` (it wins over
  `Directory.Build.props`) or `version` in `package.json`. SemVer: breaking → major, `feat` → minor, otherwise patch;
  prereleases look like `1.3.0-beta.2`. It must be higher than every existing release, prereleases included.
- Never create release tags or GitHub releases by hand: the pipeline creates them after approval.
