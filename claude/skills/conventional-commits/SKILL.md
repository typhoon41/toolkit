---
name: conventional-commits
description: Commit message and pull request title format (Conventional Commits) - type, scope, imperative description, breaking-change markers, one logical change per commit, PR descriptions. Apply whenever writing a commit message, a PR title or a PR description.
---

# Commits and PR titles

What a commit says is what a release note or a reviewer reads, so each one describes a single change in the format
below.

## Format

`type(optional scope)!: description` - lowercase type, a colon and one space, a scope naming the area, and an
imperative description of what changes for the user: `fix(calendar): keep the week when saving an entry`.

Types: `feat`, `fix`, `docs`, `perf`, `refactor`, `test`, `build`, `ci`, `chore`, `style`, `revert`.

The PR title uses the same format. The PR description links the ticket, then one paragraph on what changed and why
for a reviewer who has not read the ticket - not a changelog, no headings.

One logical change per commit, so each becomes one accurate release-note line.

## Breaking changes

Removed or renamed public API, changed behaviour, dropped frameworks: `!` before the colon
(`feat!: drop .NET 8 support`) or a `BREAKING CHANGE: ...` footer. Mark the **commit** itself, not only the PR title:
release notes are built from the PR's individual commits.
