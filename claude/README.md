# claude

The `conventions` Claude Code plugin: the coding conventions every project follows, as skills, plus hooks that
make sure the owning skills are loaded before Claude edits a file, flag banned patterns in what it wrote, and
format C# whitespace. The repository root's `.claude-plugin/marketplace.json` publishes it as the `toolkit`
marketplace.

## Use it in a project

Commit this to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "toolkit": { "source": { "source": "github", "repo": "typhoon41/toolkit" }, "autoUpdate": true },
    "chrome-devtools-plugins": { "source": { "source": "github", "repo": "ChromeDevTools/chrome-devtools-mcp" } }
  },
  "enabledPlugins": {
    "conventions@toolkit": true,
    "csharp-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "chrome-devtools-mcp@chrome-devtools-plugins": true
  }
}
```

Once a teammate trusts the folder, Claude Code registers the marketplace and reports the plugin as not installed;
install it once with:

```sh
claude plugin install conventions@toolkit --scope project
```

With `autoUpdate`, a new plugin `version` is fetched in the background after startup; run `/reload-plugins` when
asked. On demand: `claude plugin update conventions@toolkit`.

The language servers (`csharp-ls`, `typescript-language-server`) come from the official LSP plugins and must be on
`PATH`. chrome-devtools gives `browser-verification` a browser. Drop the entries a project doesn't need.

Locally, without GitHub: `/plugin marketplace add <path to this repository>`, then
`/plugin install conventions@toolkit`.

## Skills

| Skill | Applies to |
|---|---|
| `code-design` | Any code: names, files, control flow, comments, failures, rich models, no enums, no second copy |
| `csharp` | `.cs`: async naming, thin controllers, validation, nullability, repositories and queries, logging, security |
| `gmf-packages` | C# in solutions referencing `Gmf.*` packages: unit of work, events, conflicts, Autofac |
| `angular` | `.ts` / Angular templates: components, signal APIs, templates, class style, TypeScript, state, errors, i18n |
| `html-scss` | `.html` / `.scss`: styling only in SCSS, host elements, selectors, mobile-first layout, values, modules |
| `scss-solutions` | Projects using `@typhoon41/scss-solutions`: utility classes and mixins |
| `accessibility` | User-facing UI: WCAG 2.2 AA |
| `browser-verification` | Finishing any UI change: lint, run and measure in a browser |
| `conventional-commits` | Commit messages, PR titles and descriptions, releases |

Every rule has one owner. When a convention changes, edit the skill that owns it and nothing else.

## Hooks

All hooks are PowerShell 7 scripts in `hooks/` sharing the `ConventionHooks` module. They skip `node_modules`,
`bin`, `obj`, `dist`, `.angular`, EF migrations and generated files (`*.Designer.cs`, `*.g.cs`, `*.generated.*`).

| Event | Script | What it does |
|---|---|---|
| PreToolUse `Edit\|Write\|MultiEdit` | `Invoke-SkillGate.ps1` | Blocks the edit until the skills that own the file are loaded (`RequiredSkills.psd1`: `.cs` → code-design + csharp, `.ts` and `.html` → code-design + angular + html-scss, `.scss`/`.css` → code-design + html-scss), naming the `Skill` calls to make. Tracked per session and per subagent. |
| PostToolUse `Skill`, UserPromptExpansion | `Invoke-SkillGate.ps1` | Records a loaded `conventions:<skill>`, from the Skill tool or a `/conventions:<skill>` command. |
| PostToolUse `Edit\|Write\|MultiEdit` | `Invoke-BannedPatternGuard.ps1` | Checks only the text just written against `BannedPatterns.psd1`; findings go back to Claude (exit 2) naming the owning skill. The edit is kept. |
| PostToolUse `Edit\|Write\|MultiEdit` | `Invoke-DotnetFormat.ps1` | Runs `dotnet format whitespace` on an edited `.cs` file when the project root has an `.editorconfig`, and tells Claude to re-read the file if it changed. |

Add a guard rule only when a regular expression finds it without false positives (scan a real project first), and
add a reporting and an accepting case to `tests/BannedPatternGuard.Tests.ps1`.

## Development

From `claude/`:

```powershell
Invoke-Pester ./tests
Invoke-ScriptAnalyzer -Path ./hooks -Recurse -Settings ../release/PSScriptAnalyzerSettings.psd1
claude plugin validate .
```

Releasing: bump `version` in `.claude-plugin/plugin.json` and the plugin's entry in the root
`.claude-plugin/marketplace.json`; installed copies update when the version changes.
