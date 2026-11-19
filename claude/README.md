# claude

The `conventions` Claude Code plugin: the coding conventions every project follows, as skills Claude loads when
the task matches, plus a hook that flags banned patterns in what Claude has just written. The repository root's
`.claude-plugin/marketplace.json` publishes it as the `toolkit` marketplace.

## Use it in a project

Commit this to the project's `.claude/settings.json`; everyone who trusts the folder is offered the plugins:

```json
{
  "extraKnownMarketplaces": {
    "toolkit": { "source": { "source": "github", "repo": "typhoon41/toolkit" } },
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

The language servers (`csharp-ls`, `typescript-language-server`) come from the official LSP plugins and must be on
`PATH`. chrome-devtools gives `browser-verification` a browser. Drop the entries a project doesn't need.

Locally, without GitHub: `/plugin marketplace add <path to this repository>`, then
`/plugin install conventions@toolkit`.

Project-specific rules (component names, locales, wire formats, folder paths) stay in the project's own
`CLAUDE.md` or `.claude/skills/`; they build on these skills and never repeat them.

## Skills

| Skill | Applies to |
|---|---|
| `code-design` | Any code: names, files, braces, rich models, no enums, one object per input, no second copy |
| `csharp` | `.cs`: async naming, thin controllers, enum replacements, repositories, side effects after commit |
| `gmf-packages` | C# in solutions referencing `Gmf.*` packages: unit of work, events, conflicts, Autofac |
| `angular` | `.ts` / Angular templates: components, signals, class style, state, HTTP, forms, i18n |
| `html-scss` | `.html` / `.scss`: styling only in SCSS, host elements, selectors, layout, DRY modules |
| `scss-solutions` | Projects using `@typhoon41/scss-solutions`: utility classes and mixins |
| `accessibility` | User-facing UI: WCAG 2.2 AA |
| `browser-verification` | Finishing any UI change: run and measure in a browser |
| `conventional-commits` | Commit messages, PR titles, releases |

Every rule has one owner. When a convention changes, edit the skill that owns it and nothing else.

## Banned-pattern guard

`hooks/hooks.json` runs `hooks/Invoke-BannedPatternGuard.ps1` (PowerShell 7) after every Edit / Write. It checks
only the text that was written, so existing code is never reported, and skips `node_modules`, `bin`, `obj`, `dist`
and EF migrations. Findings are fed back to Claude (exit code 2) with the owning skill; the edit itself is kept.

Rules are data in `hooks/BannedPatterns.psd1`. Add a rule only when a regular expression finds it without false
positives, and add a reporting and an accepting case to `tests/BannedPatternGuard.Tests.ps1`.

## Development

From `claude/`:

```powershell
Invoke-Pester ./tests
Invoke-ScriptAnalyzer -Path ./hooks -Recurse -Settings ../release/PSScriptAnalyzerSettings.psd1
claude plugin validate .
```

Releasing: bump `version` in `.claude-plugin/plugin.json` and the plugin's entry in the root
`.claude-plugin/marketplace.json`; installed copies update when the version changes.
