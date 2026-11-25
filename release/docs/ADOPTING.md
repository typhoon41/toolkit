# Adopting release tooling in a project

A checklist for wiring a project (Claude can follow it). Most of the security lives in Azure DevOps and
GitHub settings, not in YAML: a pull request can change any YAML, so the server-side protections below
are what keep publishing credentials away from untrusted code.

## 1. `release.json` at the repository root

```json
{
  "units": [
    { "name": "Gmf.DDD.Common", "type": "nuget", "projects": ["Packages/Gmf.DDD.Common/Gmf.DDD.Common.csproj"] },
    { "name": "web-ui", "type": "npm", "package": "Site/Ui/package.json" },
    { "name": "marush", "type": "pipeline" }
  ],
  "runNameUnit": "marush"
}
```

| Field | Meaning |
|---|---|
| `name` | Unit name: letters, digits, `.`, `_`, `-`. Names the tag prefix, notes and package folders |
| `type` | `nuget`, `npm` or `pipeline` (application; version passed by the pipeline) |
| `projects` | nuget: the `.csproj` files packed together; their `<Version>` must agree |
| `package` | npm: path of the `package.json` (must not be `"private": true`) |
| `paths` | Optional. What counts as the unit's changes in its notes. Default: the project/package folders plus the `Directory.Build.props` that supplies the version; the whole repository for a single-unit repository or a `pipeline` unit |
| `tagPrefix` | Optional. Default `v` for a single unit, `<name>/v` for several |
| `nugetSource` | Optional, `https://` only. Default `https://api.nuget.org/v3/index.json`; Azure Artifacts: the feed's `index.json`. Credentials go only to nuget.org, Azure Artifacts or hosts in the pipeline's `trustedFeedHosts` |
| `npmRegistry` | Optional, `https://` only. Default `https://registry.npmjs.org/`. `NpmToken` goes only to npmjs.org, Azure Artifacts or `trustedFeedHosts` |
| `runNameUnit` | Optional. Which unit names the run when there are several (default: the first unit that releases in the build, otherwise the first unit) |

Versions: NuGet units read `<Version>` from the `.csproj`, else from the nearest
`Directory.Build.props` above it (a props file that imports its parent through
`GetPathOfFileAbove('Directory.Build.props', ...)` is followed). Use one unconditional `<Version>`, not
`VersionPrefix`/`VersionSuffix`; a `<Version>` under a `Condition` or in a `Choose` block is refused.

Existing tags keep working when their form matches: a single-unit repository uses `v1.2.3`.

**No tags by hand.** The version in `package.json` / the `.csproj` is the only thing you change; the pipeline
creates every release tag. A unit's notes cover the commits since its previous release tag, and before the first
one (a repository adopting the tooling), since the commit that set the previous version: bumping 1.1.6 to 1.1.7
lists only the commits after the one that set 1.1.6.

**Switching npm registry.** `package-lock.json` keeps each package's `resolved` URL. When those point at
a private feed and its `.npmrc` goes away, `npm ci` fails in CI. Rewrite the host to the new registry
(e.g. `https://registry.npmjs.org/`); the `integrity` hashes stay valid, and `npm ci` verifies them.

## 2. Pipeline YAML

Reference this repository; without a `ref`, Azure Pipelines uses its default branch, `main`:

```yaml
resources:
  repositories:
    - repository: toolkit
      type: github
      name: typhoon41/toolkit
      endpoint: <GitHub service connection>
```

A change merged here reaches every project's next run; `main` takes changes only through reviewed PRs with
passing CI. To stay on an older version, add a `ref` to a branch or tag, e.g. `ref: refs/tags/v1.0.0`.
`endpoint` is the name of a GitHub service connection (**Project settings → Service connections →
New → GitHub**). It fetches the templates, so any connection that can read this public repository works; with
`useGitHubServiceConnection` it also creates the GitHub releases (§3).

- Packages: copy [../examples/azure-pipelines.packages.yml](../examples/azure-pipelines.packages.yml).
  It uses `templates/stages/package-release.yml`, whose Release stage already sets `lockBehavior: sequential`
  (assembling the steps yourself: [README](../README.md#using-the-step-templates-on-their-own)).
- Applications: copy the relevant parts of
  [../examples/azure-pipelines.application.yml](../examples/azure-pipelines.application.yml): add
  `steps/checkout.yml` + `steps/resolve-release-plan.yml` (with `pipelineVersion: $(Build.BuildNumber)`
  and `publishPlan: true`) to the build job, and `steps/release-application.yml` after the production
  deployment.

The templates check the project out at `$(Build.SourcesDirectory)` and this toolkit at
`$(Pipeline.Workspace)/toolkit`. Agents need PowerShell 7 (`pwsh`) and git; `ubuntu-latest` and
`windows-latest` have both.

| Template parameter (package-release.yml) | Default | Meaning |
|---|---|---|
| `buildSteps` | `[]` | Your restore/build/test steps |
| `nodeVersion` / `dotnetVersion` | `''` | Installs Node (`UseNode@1`) / the .NET SDK (`UseDotNet@2`) before `buildSteps`, e.g. `22.x` / `10.x` |
| `releaseNotes` | `true` | Generate notes; `false` packs without notes and gives releases a minimal body |
| `environment` | `package-release` | Approval environment of the Release stage |
| `releaseVariableGroup` | `''` | Group with `NuGetApiKey`, `NpmToken` and/or `GitHubToken` (e.g. `release-secrets`), for whatever service connections don't replace |
| `buildVariableGroup` | `''` | Optional group with `GitHubReadToken` for the PR check and the notes |
| `nugetAuthenticate` / `npmAuthenticate` | `false` | Azure Artifacts feeds instead of API keys; the release job authenticates first, before any feed check (`steps/authenticate-feeds.yml`) |
| `npmServiceConnection` | `''` | npm service connection used instead of `NpmToken` (see §3) |
| `useGitHubServiceConnection` | `true` | The toolkit resource's `endpoint` connection instead of `GitHubToken` in the release job; `false` uses `GitHubToken` (see §3) |
| `npmAccess` | `''` | `public` for scoped packages on npmjs.org |
| `enforceCommitConvention` | `true` | Fail PRs whose title/commits don't follow the convention; `false` only warns |

## 3. GitHub tokens and service connections

Fine-grained personal access tokens limited to the repository (a service account if available), with an
expiry and a rotation reminder:

| Token | Repository permissions | Stored as |
|---|---|---|
| Release | Contents: **Read and write**; Pull requests: Read; Metadata: Read | `GitHubToken` in `release-secrets` |
| Read | Contents: Read; Pull requests: Read; Metadata: Read | `GitHubReadToken` in a build-only group |

Public repositories work without the read token (anonymous, rate-limited per IP; hosted agents share
IPs, so a token is more reliable). Plus: a **NuGet API key** scoped to *Push* for the package ids, and/or
an npm **automation token**, both in `release-secrets`.

### Service connections instead of secrets

The GitHub connection is the default in `package-release.yml`; npm and NuGet use secrets unless configured.

- **GitHub** (`useGitHubServiceConnection`, on by default in `package-release.yml`): the release job checks the toolkit out with
  `persistCredentials: true` and uses the token of its resource's `endpoint`, the connection named in your YAML.
  That connection needs Contents: **write** on the project repository too: a personal-access-token connection's
  token needs that scope, a GitHub App connection needs the *Azure Pipelines* app installed on the project
  repository. The Build stage keeps `GitHubReadToken` or anonymous access: it runs pull-request code, so it never
  persists credentials.
- **npm** (`npmServiceConnection: <name>`): an *npm* service connection (**Service connections → New → npm**,
  registry URL plus an automation token). `npmAuthenticate@0` writes its credentials into `npmrcFile`, so commit an
  `.npmrc` that lists the registry, e.g. `registry=https://registry.npmjs.org/`.

Any secret still needed (`NuGetApiKey`, `NpmToken`, or `GitHubToken` with `useGitHubServiceConnection: false`) comes
from the group named in `releaseVariableGroup`; with both connections and no NuGet unit, no group is needed.

## 4. Azure DevOps

**Pipelines → Library → `release-secrets`** (every value secret):
- Pipeline permissions: this project's pipeline only. Never "Open access".
- Approvals and checks → **Branch control**: `refs/heads/main`; tick *Verify branch protection*;
  untick *Allow resources from unknown/unverifiable branches*.

**Pipelines → Environments → New environment `package-release`** (resource: None) and, for applications,
**`application-release`** (or your names; the application one needs only Branch control and the Exclusive lock,
production was approved already). **Create it before merging the first version bump**: Azure DevOps creates a
missing environment on its first deployment without any checks, so that release would publish unapproved.
Approvals and checks:
- **Approvals**: the reviewer. Untick *Allow approvers to approve their own runs* when a second person reviews;
  a sole maintainer keeps it allowed, otherwise nobody can approve the run they started by merging.
- **Branch control**: `refs/heads/main`.
- **Exclusive lock** (`package-release.yml`'s Release stage sets `lockBehavior: sequential` to go with it).
- Pipeline permissions: this pipeline only.

To approve a release, open the run: its Release stage shows *Waiting*; choose **Review → Approve**.
Rejecting it skips the whole Release stage, so nothing is published.

**Pipeline triggers**: CI on `main`, PR validation on PRs to `main`. Leave *Make secrets available to
builds of forks* off, and require a team member's comment before building fork PRs.

## 5. GitHub

- **Branch ruleset for `main`**: require a PR with 1 approval (dismiss stale approvals), require the
  pipeline's status check, no bypass, block force pushes and deletions. Allow **squash merging only**.
- **Tag ruleset** for the release tags (`v*`, or `*/v*` with several units): restrict updates and
  deletions; optionally restrict creations with the release token's account on the bypass list.

## 6. Claude

Projects inherit the commit convention from the global `~/.claude/CLAUDE.md`, so commits Claude writes
land in the right release-note section. A project's own CLAUDE.md needs nothing extra.
