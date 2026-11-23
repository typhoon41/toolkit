# claude

The `conventions` Claude Code plugin is an opinionated, strict set of coding conventions for C#/.NET, TypeScript,
Angular, HTML/SCSS, accessibility and commits. It is not a menu of soft suggestions: it suits teams that want firm
rules applied every time. The conventions are skills, backed by hooks that:

- load the skills that own a file before Claude edits it,
- flag banned patterns in what Claude just wrote,
- format C# whitespace.

The repository root's `.claude-plugin/marketplace.json` publishes the plugin as the `toolkit` marketplace.

## Use it in a project

Commit this to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "toolkit": { "source": { "source": "github", "repo": "typhoon41/toolkit" }, "autoUpdate": true }
  },
  "enabledPlugins": {
    "conventions@toolkit": true
  }
}
```

Once a teammate trusts the folder, Claude Code registers the marketplace and reports the plugin as not installed.
Install it once with:

```sh
claude plugin install conventions@toolkit --scope project
```

With `autoUpdate`, a new plugin `version` is fetched in the background after startup; run `/reload-plugins` when
asked. To update on demand: `claude plugin update conventions@toolkit`.

To use it locally, without GitHub: `/plugin marketplace add <path to this repository>`, then
`/plugin install conventions@toolkit`.

### Prerequisites

| Needed for | What |
|---|---|
| All hooks | PowerShell 7 (`pwsh`) on `PATH`, on Windows, macOS or Linux (CI runs the tests on Linux) |
| C# formatting hook | The .NET SDK (`dotnet`) and an `.editorconfig` at the project root; without them the hook does nothing |
| `browser-verification` (optional) | A browser Claude can drive, e.g. the **Claude in Chrome** extension connected to Claude Code; `chrome-devtools-mcp@chrome-devtools-plugins` adds media emulation |
| Code navigation (optional) | `csharp-lsp@claude-plugins-official` / `typescript-lsp@claude-plugins-official`, with `csharp-ls` / `typescript-language-server` on `PATH` |

The plugin also registers the [Context7](https://context7.com) MCP server (`.mcp.json`) for up-to-date library
documentation.

## Skills

**Core** skills are tied to a technology, not to a library or repository. The skill gate requires them by file
type:

| Skill | Applies to |
|---|---|
| `code-design` | Any code: names, files, control flow, comments, failures, rich models, no enums, no second copy |
| `dotnet` | `.cs` (C#, ASP.NET Core, EF Core, FluentValidation): async naming, thin controllers, validation, nullability, repositories and queries, logging, security |
| `typescript` | Any `.ts`: arrow-function members, no getters, typing, async/await instead of subscriptions, one abstraction per module |
| `angular` | Angular 20+ projects: components, no lifecycle hooks, signals, templates, component styling, state, errors, i18n |
| `html-scss` | `.html` / `.scss`, framework-free: styling only in SCSS, selectors, mobile-first layout, values, modules |
| `accessibility` | User-facing UI: WCAG 2.2 AA |
| `browser-verification` | Finishing any UI change: lint, run, test in a real browser and measure ([Claude in Chrome tools](skills/browser-verification/claude-in-chrome.md)) |
| `conventional-commits` | Commit messages, PR titles and descriptions |

**Integration** skills cover a specific library or tooling. The gate requires them only when the project depends on
it:

| Skill | Required when | Applies to |
|---|---|---|
| `gmf-ecosystem` | the `.csproj` references `Gmf.DDD.Common`, `Gmf.Net.Core.Common` or `Gmf.Mail.Common` (package or project reference) | The Gmf types behind the `dotnet` rules: unit of work, events, conflicts, entities, Autofac, email |
| `scss-solutions` | `package.json` depends on `@typhoon41/scss-solutions` | Its utility classes and mixins |
| `toolkit-release` | (by description) the repository has a root `release.json` for the toolkit `release/` tooling | Release-note sections, version bumps |

`toolkit-release` is the one integration the hook does not gate: there is no package dependency to detect, so its
description decides when Claude loads it.

Every rule has one owner. When a convention changes, edit the skill that owns it and nothing else. Integration
skills build on core ones, framework skills on framework-free ones (`angular` on `typescript` and `html-scss`), and
never the other way round. Repository facts (component names, locale files, folder paths) belong in the project's
own `CLAUDE.md`.

## Hooks

All hooks are PowerShell 7 scripts in `hooks/` sharing the `ConventionHooks` module. They skip the folders in
`GuardedPaths.psd1` (`node_modules`, `bin`, `obj`, `dist`, `.angular`, `Migrations`) and generated files
(`*.Designer.cs`, `*.g.cs`, `*.generated.*`).

| Event | Script | What it does |
|---|---|---|
| PreToolUse `Edit\|Write\|MultiEdit` | `Invoke-SkillGate.ps1` | Blocks the edit until the skills that own the file are loaded, and names the `Skill` calls to make. `RequiredSkills.psd1` maps extensions to core skills (`.cs` → code-design + dotnet, `.ts` → code-design + typescript, `.html`/`.scss`/`.css` → code-design + html-scss, `.ps1`/`.psm1`/`.psd1`/`.yml`/`.yaml` → code-design). It adds `angular` from `@angular/core` 20 and the integration skills above when the project depends on them. Tracked per session and per subagent. |
| PostToolUse `Skill`, UserPromptExpansion | `Invoke-SkillGate.ps1` | Records a loaded `conventions:<skill>`, from the Skill tool or a `/conventions:<skill>` command. |
| PostToolUse `Edit\|Write\|MultiEdit` | `Invoke-BannedPatternGuard.ps1` | Checks only the text just written against `BannedPatterns.psd1` and the project's rules. Findings go back to Claude (exit 2) naming the owning skill; the edit is kept. Angular rules apply only in projects on `@angular/core` 20+. |
| PostToolUse `Edit\|Write\|MultiEdit` | `Invoke-DotnetFormat.ps1` | Runs `dotnet format whitespace` on an edited `.cs` file when the project root has an `.editorconfig`, and tells Claude to re-read the file if it changed. |

A dependency is detected once per hook run from the file's nearest `package.json` (npm) or nearest `.csproj`
(NuGet).

- **npm:** the package is listed in `dependencies`, `devDependencies`, `optionalDependencies` or `peerDependencies`.
  A requirement written `package>=major` also checks the declared range; it passes when any of its `||`
  alternatives allows that major.
- **NuGet:** detection is by presence only. A dependency is a `PackageReference Include` in a `.csproj` of that
  folder, or in the `Directory.Build.props` MSBuild imports for it (the nearest one, and any it imports with
  `GetPathOfFileAbove`), or a `ProjectReference` to `<Package>.csproj`. A `PackageReference Update` or a central
  `PackageVersion` alone is not a dependency. Versions are not read, so a NuGet `package>=major` requirement passes
  whenever the package is present.

## Project configuration

The defaults are strict and stay on. A project that needs a deliberate exception commits
`.claude/conventions.json`. The hooks look for it in Claude's working folder and the folders above it, up to the
repository root:

```json
{
  "hooks": { "skillGate": true, "bannedPatternGuard": true, "dotnetFormat": false },
  "disabledRules": ["css-grid"],
  "rules": [
    { "id": "no-console", "extensions": [".ts"], "pattern": "console\\.log", "message": "use the logger", "skill": "logging" }
  ],
  "requiredSkills": { ".razor": ["code-design", "dotnet"] },
  "excludedFolders": { "add": ["generated"], "remove": ["Migrations"] }
}
```

| Key | Effect |
|---|---|
| `hooks` | Switches a hook off (`false`); every hook is on by default; `null` counts as not set, and any other value that is not `true`/`false` keeps the hook on, with a warning |
| `disabledRules` | Drops rules by `Id`, as listed in `hooks/BannedPatterns.psd1` or in `rules` |
| `rules` | Adds guard rules: `id`, `extensions`, `pattern` (.NET regex, per line) and `message` are required; `skill`, `target` (`Text`/`Path`), `whenProjectDependsOn` and `excludeWhenFileMatches` are optional. An invalid rule, including a `target` other than `Text` or `Path`, is skipped with a warning |
| `requiredSkills` | Adds skills of this plugin to the gate for an extension; a name the plugin does not ship is skipped with a warning |
| `excludedFolders` | Adds folders the hooks skip, or removes defaults; removals win |

A missing or malformed file keeps the defaults, so a typo never breaks a hook. Beyond that, the user (in so many
words) or the project's `CLAUDE.md` is the only other way to override a rule.

## Development

From `claude/`:

```powershell
Invoke-Pester ./tests
Invoke-ScriptAnalyzer -Path ./hooks -Recurse -Settings ../release/PSScriptAnalyzerSettings.psd1
claude plugin validate .
```

[CONTRIBUTING.md](CONTRIBUTING.md) explains how to propose a rule or an integration and how to report a false
positive.

To release: bump `version` in `.claude-plugin/plugin.json` and in the plugin's entry in the root
`.claude-plugin/marketplace.json`. Installed copies update when the version changes.

## License

Apache License 2.0, as for the rest of the repository: see [LICENSE](../LICENSE).
