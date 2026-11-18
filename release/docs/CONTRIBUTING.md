# Commit convention and releasing

Release notes are generated from commit messages. What you write in a commit is what users read.

## The short version

1. Write every commit message as `type: description`, e.g. `feat: add retry policy`.
2. Give your pull request a title in the same format.
3. To release a package, bump its version in a PR and merge it; approve the release in Azure DevOps.
   Tags, packages and GitHub release notes are created automatically.

## Commit messages

```
type(optional scope)!: description
```

- **type** is required, **lowercase**, from the table below.
- **scope** is optional and names the area: `fix(parser): ...`
- **!** marks a breaking change (see below).
- **description** follows a colon and one space, in the imperative ("add", not "added").

| Type       | Use it for                                               | Release notes section |
|------------|----------------------------------------------------------|-----------------------|
| `feat`     | New functionality for users                              | Features              |
| `fix`      | A bug fix users will notice                              | Bug Fixes             |
| `docs`     | Documentation only                                       | Documentation         |
| `perf`     | Performance improvement                                  | Chores                |
| `refactor` | Code change that neither fixes a bug nor adds a feature  | Chores                |
| `test`     | Adding or fixing tests                                   | Chores                |
| `build`    | Build system, project files, dependencies                | Chores                |
| `ci`       | Pipeline changes                                         | Chores                |
| `chore`    | Anything else                                            | Chores                |
| `style`    | Formatting, whitespace                                   | Chores                |
| `revert`   | Reverting an earlier change                              | Chores                |

**A commit that doesn't follow the format is not rejected: it is listed under Chores.** The PR check
warns about it (projects can make it strict with `enforceCommitConvention: true`).

| Good                                    | Not recognised (→ Chores)   | Why                           |
|-----------------------------------------|-----------------------------|-------------------------------|
| `feat: add retry policy`                | `added retry policy`        | no type                       |
| `fix(parser): handle empty input`       | `Fix: handle empty input`   | type must be lowercase        |
| `chore: bump Polly to 8.4`              | `chore:bump Polly`          | needs a space after the colon |
| `feat!: drop .NET 8 support`            | `feature: add retry`        | `feature` isn't a type        |

### Breaking changes

Anything that can break users: removed or renamed public APIs, changed behaviour, dropped frameworks.
Put `!` before the colon (`feat!: remove obsolete overload`) or add a footer line to the body:

```
fix: make Config required

BREAKING CHANGE: Client constructor now throws when Config is null.
```

Mark the **commit** itself: release notes are built from the individual commits of each PR.

### What the release notes contain

For each PR merged since the previous release of the package:

- if at least one commit in the PR follows the convention: every commit of the PR, one line each, in
  its section (commits that don't follow it under Chores);
- if none does: the PR's title (as it is on GitHub now, so a merged PR's title can still be fixed);
- in a repository with several packages, only commits that touched that package's folder; a PR that
  touched only other packages doesn't appear.

Merge commits and `fixup!` / `squash!` / `amend!` commits never appear. Commits pushed directly to
the release branch appear as themselves.

## Releasing

### Where the version lives

| Kind | Version source |
|---|---|
| NuGet package | `<Version>` in the `.csproj`; if absent, in the nearest `Directory.Build.props` above it |
| npm package | `"version"` in its `package.json` |
| Application (full-stack) | the pipeline, e.g. `name: 1.4.$(Rev:r)`; every deploy of `main` is a release |

Choose the next version with [Semantic Versioning](https://semver.org): a breaking change bumps
**major**, a `feat` bumps **minor**, anything else bumps **patch**. Prereleases look like
`1.3.0-alpha`, `1.3.0-beta.2`, `1.3.0-rc.1`.

The pipeline enforces, so a tag and a package version can never disagree:

- lowercase prerelease labels, no leading zeros, no `+build` metadata;
- **always higher than every existing release of that package, prereleases included.**

### How a package release happens

1. Bump the version in a PR (a `chore: release 1.3.0` PR or part of the last feature PR) and merge.
2. The build on `main` packs exactly `1.3.0`, with the release notes inside. Its **Release** stage
   waits for approval in Azure DevOps.
3. After approval: a draft GitHub release with the packages attached is prepared, the packages are
   pushed, then the release is published, which creates the tag (`v1.3.0`, or `<unit>/v1.3.0`).

**Only the merge that changes the version releases it.** Other merges build CI versions such as
`1.3.1-ci.4711` (`1.3.1-calendar-fixes.4711` on a feature branch) that are never published.

If a release step fails, use **Rerun failed jobs** on that same run; it resumes where it stopped.
**Never create release tags by hand.** See [RELEASING.md](RELEASING.md) for every error message.
