# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## What this is

Shared tooling consumed by other projects, one folder per tool:

- `release/` — PowerShell 7 scripts + Azure Pipelines templates that version, write release notes for, and
  publish NuGet / npm packages and GitHub releases. Projects reference this repository from Azure Pipelines
  at `main` (a `resources.repositories` entry without `ref`), so a merged change reaches every project on
  its next run and nothing is tagged by hand. Keep template parameters and script contracts backward compatible
  by default: add parameters with defaults that keep today's behaviour, never rename or remove one in place.
  A deliberate breaking change (a new default, a moved path, a removed parameter) is allowed only when the
  maintainer asks for it and the commit is marked `!` with a `BREAKING CHANGE:` footer saying what consumers must
  change. When a known consumer's files must change, a PR updating it is opened alongside and merges after the
  toolkit PR; when none must, the toolkit PR says so instead.
- `claude/` — the `conventions` Claude Code plugin, published by the root `.claude-plugin/marketplace.json`
  (marketplace `toolkit`). See "Claude plugin (`claude/`)" below.

## Commands

Run from `release/` (PowerShell 7, Pester 5.6+, PSScriptAnalyzer):

```powershell
Invoke-Pester ./tests                                    # all tests
Invoke-Pester ./tests/Versioning.Tests.ps1               # one file
Invoke-Pester ./tests/Versioning.Tests.ps1 -FullNameFilter '*Compare-ReleaseVersion*'   # one Describe/It
'./module', './scripts' | ForEach-Object { Invoke-ScriptAnalyzer -Path $_ -Recurse -Settings ./PSScriptAnalyzerSettings.psd1 }
```

CI (`azure-pipelines.yml`, root) runs exactly the analyzer (any issue fails) and Pester on ubuntu-latest.

Preview a project's release notes locally from that project's root:
`pwsh ../toolkit/release/scripts/New-ReleaseNotes.ps1 -Unit <unit> -Version 1.4.0 -Preview`

## Architecture (`release/`)

Three layers, each calling the one below:

1. **`templates/`** — Azure Pipelines YAML. `stages/package-release.yml` is the complete Build + Release
   flow for package repos (via `jobs/package-build.yml`, `jobs/package-publish.yml`); `steps/*.yml` are
   individually usable and must keep the order documented in `release/README.md`. Templates check out the
   project at `$(Build.SourcesDirectory)` and the toolkit at `$(Pipeline.Workspace)/toolkit`.
2. **`scripts/`** — one entry-point script per pipeline step. Each sets `$ErrorActionPreference='Stop'`,
   `Set-StrictMode -Version Latest`, imports the module, and keeps logic thin.
3. **`module/ReleaseTooling/`** — all logic. `ReleaseTooling.psm1` dot-sources every
   `Functions/**/*.ps1` and exports everything: **one public function per file, named after the
   function**, grouped by folder (Planning, Versioning, Notes, Releases, NuGet, Npm, GitHub, Git, Feeds…).
   Adding a function = adding a file; nothing to register.

Data flow: `Resolve-ReleasePlan.ps1` reads the consuming repo's `release.json` (units of type `nuget`,
`npm`, `pipeline`) and git history/tags, and writes `release-plan.json` (schemaVersion 1). Every later
step (`New-ReleaseNotes`, `New-ReleasePackage`, `Publish-NuGetPackage`, `Publish-NpmPackage`,
`Publish-GitHubRelease`) consumes that plan plus the `release` pipeline artifact
(`release-plan.json`, `notes/<unit>.md`, `packages/<unit>/*`).

Key invariants the code enforces (see `release/docs/RELEASING.md` for the error-message catalogue):

- A package unit releases only on the release branch, on the commit that **changes** its version, when
  that version is untagged and higher than every existing release (prereleases included). Other builds
  pack CI versions (`1.3.1-ci.4711`, `1.3.1-<branch-words>.4711`).
- Versions: strict SemVer subset (lowercase prerelease labels, no leading zeros, no `+build`). NuGet reads
  one unconditional `<Version>` from the csproj, else the nearest `Directory.Build.props`.
- **Every release step is idempotent and resumable** ("Rerun failed jobs"): Prepare creates/resumes a draft
  GitHub release and uploads an immutable `release-state.json` marker (draft is frozen after it); Push
  compares an existing feed version to this build (NuGet entry-by-entry, npm tarball integrity) and skips
  only if identical; Publish re-checks ordering, then publishes the draft, which creates the tag. Preserve
  these guarantees when changing anything under `Releases/`, `NuGet/`, `Npm/`.
- Credentials go only to nuget.org / npmjs.org / Azure Artifacts or explicitly `trustedFeedHosts`
  (`Feeds/`); log output passes through `Protect-LogText`.
- Release notes come from Conventional Commits per merged PR, scoped to the unit's paths
  (`release/docs/CONTRIBUTING.md`).

## Conventions

- `Write-Host` is intentional: Azure Pipelines reads `##vso[...]` logging commands from it (use the
  `Logging/` functions). The analyzer excludes `PSAvoidUsingWriteHost`, `PSUseShouldProcessForStateChangingFunctions`,
  `PSUseToExportFieldsInManifest` for these reasons.
- Run git through `Invoke-Git` (throws on non-zero exit, forces UTF-8).
- Tests: `*.Tests.ps1` import the module in `BeforeAll`; `tests/TestRepository.ps1` builds throwaway git
  repos (`New-TestRepository`, `Set-TestFile`, `Save-TestCommit`) and `tests/ReleaseTestContext.ps1`
  builds fake GitHub release contexts — dot-source them in `BeforeAll`.
- User-facing docs live in `release/docs/` (CONTRIBUTING, ADOPTING, RELEASING, RECOVERY); update them
  when behaviour or error messages change.

## Claude plugin (`claude/`)

```powershell
Invoke-Pester ./tests                                                                      # from claude/
Invoke-ScriptAnalyzer -Path ./hooks -Recurse -Settings ../release/PSScriptAnalyzerSettings.psd1
claude plugin validate .        # plugin; run at the repository root for the marketplace
```

- `skills/<name>/SKILL.md` — one skill per concern. **Every rule has exactly one owning skill**; others refer
  to it by name (`code-design` holds the cross-language rules). No checklists that restate a skill's body.
  Skills are repository-agnostic: technology-specific core skills (`dotnet`, `typescript`, `angular`, ...)
  stay library-free. A library's rules live only in its integration skill (`gmf-ecosystem`, `scss-solutions`,
  `toolkit-release`), gated by `RequiredSkills.psd1`. Repository facts go in the consuming project's `CLAUDE.md`.
  The defaults stay strict; projects declare exceptions in `.claude/conventions.json`, never through softer
  defaults.
- `hooks/` — PowerShell 7 entry scripts, all importing the one module `ConventionHooks/` (one function per file,
  as in `release/`); `claude/README.md` has the event table and the `.claude/conventions.json` reference.
  - `Invoke-SkillGate.ps1` blocks edits until the skills in `RequiredSkills.psd1` (by extension, and by npm/NuGet
    dependency written `package` or `package>=major`) are loaded. The marker lives per session/subagent in the
    temp folder.
  - `Invoke-BannedPatternGuard.ps1` checks only newly written text against `BannedPatterns.psd1` plus the
    project's rules, and reports via stderr + exit 2. It never undoes the edit.
  - `Invoke-DotnetFormat.ps1` formats `.cs` whitespace when an `.editorconfig` exists.

  Every hook reads the project configuration first and keeps the defaults when it is missing or malformed. The
  plugin name comes only from `.claude-plugin/plugin.json`. A new guard rule needs a reporting and an accepting
  test case and a scan of a real project for false positives (`claude/CONTRIBUTING.md`).
- Releasing: bump `version` in `claude/.claude-plugin/plugin.json` and in the marketplace entry together.
