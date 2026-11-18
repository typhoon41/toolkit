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

## 2. Pipeline YAML

Reference this repository at a **tag**, so a change here never alters a project's pipeline until the
project moves its `ref`:

```yaml
resources:
  repositories:
    - repository: toolkit
      type: github
      name: typhoon41/toolkit
      endpoint: <GitHub service connection>
      ref: refs/tags/v1.0.0
```

- Packages: copy [../examples/azure-pipelines.packages.yml](../examples/azure-pipelines.packages.yml).
  It uses `templates/stages/package-release.yml` and needs `lockBehavior: sequential` at the root
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
| `buildSteps` | `[]` | Your restore/build/test steps (install the SDKs and Node here) |
| `releaseNotes` | `true` | Generate notes; `false` packs without notes and gives releases a minimal body |
| `environment` | `package-release` | Approval environment of the Release stage |
| `releaseVariableGroup` | `release-secrets` | `NuGetApiKey`, `NpmToken`, `GitHubToken` |
| `buildVariableGroup` | `''` | Optional group with `GitHubReadToken` for the PR check and the notes |
| `nugetAuthenticate` / `npmAuthenticate` | `false` | Azure Artifacts feeds instead of API keys; the release job authenticates first, before any feed check (`steps/authenticate-feeds.yml`) |
| `npmAccess` | `''` | `public` for scoped packages on npmjs.org |
| `enforceCommitConvention` | `false` | Fail PRs whose title/commits don't follow the convention |

## 3. GitHub tokens

Fine-grained personal access tokens limited to the repository (a service account if available), with an
expiry and a rotation reminder:

| Token | Repository permissions | Stored as |
|---|---|---|
| Release | Contents: **Read and write**; Pull requests: Read; Metadata: Read | `GitHubToken` in `release-secrets` |
| Read | Contents: Read; Pull requests: Read; Metadata: Read | `GitHubReadToken` in a build-only group |

Public repositories work without the read token (anonymous, rate-limited per IP; hosted agents share
IPs, so a token is more reliable). Plus: a **NuGet API key** scoped to *Push* for the package ids, and/or
an npm **automation token**, both in `release-secrets`.

## 4. Azure DevOps

**Pipelines → Library → `release-secrets`** (every value secret):
- Pipeline permissions: this project's pipeline only. Never "Open access".
- Approvals and checks → **Branch control**: `refs/heads/main`; tick *Verify branch protection*;
  untick *Allow resources from unknown/unverifiable branches*.

**Pipelines → Environments → `package-release`** and, for applications, **`application-release`** (or your names; the
application one needs only Branch control and the Exclusive lock, production was approved already), Approvals and checks:
- **Approvals**: the reviewer; untick *Allow approvers to approve their own runs*.
- **Branch control**: `refs/heads/main`.
- **Exclusive lock** (the YAML's `lockBehavior: sequential` goes with it).
- Pipeline permissions: this pipeline only.

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
