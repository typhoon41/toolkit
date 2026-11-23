# release

PowerShell 7 scripts and Azure Pipelines templates that version, document and release every project
from one place:

- **Versions** come from `<Version>` in the `.csproj` (it wins) or `Directory.Build.props`, from
  `package.json`, or, for full-stack applications, from the pipeline itself.
- **Releases** go to NuGet and npm (nuget.org, npmjs.org or Azure Artifacts) plus a GitHub release and
  tag. Only the commit that bumps a version releases it, after approval. Every step can be re-run.
- **Release notes** are generated from commit messages and grouped like
  [ESLint's releases](https://github.com/eslint/eslint/releases): Breaking Changes, Features, Bug Fixes,
  Documentation, Chores. A commit that doesn't follow the [convention](docs/CONTRIBUTING.md) is a chore.
  The notes are optional and, when on, ship inside the NuGet/npm package and form the GitHub release.
- **Run names** show the version and build id (`1.3.0+4711`, `1.3.1-ci.4711`), with up to three words
  of the branch name on feature branches (`1.3.1-calendar-fixes.4711`).
- **Mono- and multi-repos**: a `release.json` lists the release units; each has its own version, tags
  (`<unit>/v1.2.3` when there are several) and notes limited to its own paths.

## Quick start

1. Add `release.json` to the project root ([examples/release.json](examples/release.json)).
2. Reference this repository in the pipeline and use a template:
   - packages: [examples/azure-pipelines.packages.yml](examples/azure-pipelines.packages.yml)
   - full-stack application: [examples/azure-pipelines.application.yml](examples/azure-pipelines.application.yml)
3. Do the one-time Azure DevOps and GitHub setup in [docs/ADOPTING.md](docs/ADOPTING.md).

Preview the notes of an upcoming release locally from the project root:

```powershell
pwsh ../toolkit/release/scripts/New-ReleaseNotes.ps1 -Unit <unit> -Version 1.4.0 -Preview
```

## Using the step templates on their own

`stages/package-release.yml` already runs every step in the right order. When you assemble a release job
yourself, keep this order. `publish-packages.yml` doesn't authenticate by itself, so for Azure Artifacts
run `authenticate-feeds.yml` before the first step that touches a feed (Prepare already reads them):

```yaml
steps:   # inside a deployment job, after the Build stage published the 'release' artifact
  - template: release/templates/steps/checkout.yml@toolkit
  - download: current
    artifact: release
  - template: release/templates/steps/authenticate-feeds.yml@toolkit     # Azure Artifacts only
    parameters: { nugetAuthenticate: true, npmAuthenticate: true, npmrcFile: $(Build.SourcesDirectory)/.npmrc }
  - template: release/templates/steps/publish-github-release.yml@toolkit
    parameters: { action: Prepare, npmAuthenticate: true, npmrcFile: $(Build.SourcesDirectory)/.npmrc }
  - template: release/templates/steps/publish-packages.yml@toolkit
    parameters: { npmAuthenticate: true, npmrcFile: $(Build.SourcesDirectory)/.npmrc }
  - template: release/templates/steps/publish-github-release.yml@toolkit
    parameters: { action: Publish, npmAuthenticate: true, npmrcFile: $(Build.SourcesDirectory)/.npmrc }
```

Pass `nugetAuthenticate` only to `authenticate-feeds.yml`. Give `npmAuthenticate`/`npmrcFile` to every
step that reads or writes the npm feed. With nuget.org and npmjs.org, leave out `authenticate-feeds.yml`
and those parameters; the `NuGetApiKey` / `NpmToken` variables are used instead.

Service connections instead of secrets ([docs/ADOPTING.md](docs/ADOPTING.md#service-connections-instead-of-secrets)):
pass `npmServiceConnection` to `authenticate-feeds.yml` and `npmAuthenticate: true` to the later npm steps; for
GitHub, give `checkout.yml` `persistToolkitCredentials: true` and both `publish-github-release.yml` steps
`useGitHubServiceConnection: true`.

## Layout

| Path | Contents |
|---|---|
| `scripts/` | Entry points the templates call (one per pipeline step) |
| `module/ReleaseTooling/` | The functions behind them, one per file |
| `templates/steps/` | Step templates, usable one by one |
| `templates/jobs/`, `templates/stages/package-release.yml` | Complete Build + Release stages for package repositories |
| `tests/` | Pester 5 tests: `Invoke-Pester ./tests` |
| `docs/` | [Commit convention](docs/CONTRIBUTING.md), [adoption](docs/ADOPTING.md), [re-runs and errors](docs/RELEASING.md), [recovery](docs/RECOVERY.md) |

| Script | Step |
|---|---|
| `Resolve-ReleasePlan.ps1` | Versions, release decision and run name for every unit → `release-plan.json` |
| `New-ReleaseNotes.ps1` | Release notes per releasing unit (`<unit>.md`, `<unit>.txt`); local `-Preview` |
| `New-ReleasePackage.ps1` | `dotnet pack` / `npm pack` with the planned versions, notes embedded |
| `Publish-NuGetPackage.ps1` | Idempotent NuGet push |
| `Publish-NpmPackage.ps1` | Idempotent npm publish (`latest`, or `next` for prereleases) |
| `Publish-GitHubRelease.ps1` | Draft → (feed push) → publish; Abandon / Restore for maintainers |
| `Test-PullRequest.ps1` | PR title and commit convention check (warn-only by default) |

## Development

```powershell
Invoke-Pester ./tests                       # Pester 5.6+
'./module', './scripts' | ForEach-Object { Invoke-ScriptAnalyzer -Path $_ -Recurse -Settings ./PSScriptAnalyzerSettings.psd1 }
```

Projects reference `main` (`ref: refs/heads/main`), so a merged change reaches them on their next run; nothing is tagged by hand.
