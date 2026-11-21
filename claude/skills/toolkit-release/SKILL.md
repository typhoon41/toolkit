---
name: toolkit-release
description: Releasing through the toolkit release/ tooling (github.com/typhoon41/toolkit) - how commits become release-note sections, version bumps through a PR, SemVer, pipeline-created tags. Apply when preparing a release or writing commits in a repository with a root release.json.
---

# Releasing with the toolkit tooling

Builds on `conventional-commits`. The toolkit `release/` tooling builds release notes from commit messages (human
version: `release/docs/CONTRIBUTING.md` in github.com/typhoon41/toolkit), so what a commit says is what users read.

## Release-note sections

`feat` → Features, `fix` → Bug Fixes, `docs` → Documentation; `perf`, `refactor`, `test`, `build`, `ci`, `chore`,
`style`, `revert` and anything else → Chores.

## Releasing

- A release is a version bump merged through a PR: `<Version>` in the `.csproj` (it wins over
  `Directory.Build.props`) or `version` in `package.json`. SemVer: breaking → major, `feat` → minor, otherwise patch;
  prereleases look like `1.3.0-beta.2`. It must be higher than every existing release, prereleases included.
- Never create release tags or GitHub releases by hand: the pipeline creates them after approval.
