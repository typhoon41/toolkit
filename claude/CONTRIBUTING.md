# Contributing to the conventions plugin

The plugin is deliberately strict and opinionated. A proposal is welcome when it makes a rule sharper, finds a
false positive, or adds a technology or library that projects actually use. It is not a place for softer defaults
or optional style profiles: a project that needs an exception declares it in its own `.claude/conventions.json`.

## Where a rule goes

| The rule is about | It goes in |
|---|---|
| Any language (names, files, control flow, models) | `skills/code-design` |
| A language, framework or platform (C#/.NET, TypeScript, Angular, HTML/SCSS) | That technology's core skill |
| One library or tool (Gmf, scss-solutions, the toolkit release tooling) | Its integration skill, never a core skill |
| One repository (component names, folder paths) | That repository's `CLAUDE.md`, not this plugin |

- Every rule has exactly one owning skill. Other skills refer to it by name and never restate it.
- A new integration skill is gated in `hooks/RequiredSkills.psd1` under `WhenProjectDependsOn`, as
  `'package'` or `'package>=major'` (the minimum is checked for npm packages only; NuGet packages are detected by
  presence). Add a gate test in `tests/SkillGate.Tests.ps1`.
- Integration skills may build on core skills; core skills never name an integration.

## Guard rules

`hooks/BannedPatterns.psd1` holds a rule only when a regular expression finds it without false positives in normal
code.

1. Scan a real project for the pattern before adding it.
2. Add a reporting case and an accepting case to `tests/BannedPatternGuard.Tests.ps1`.
3. Name the owning skill in `Skill`. A framework rule sets `WhenProjectDependsOn`.

## Reporting a false positive

Open an issue with:
- the rule id from the guard's report,
- the line that was flagged,
- why it is correct code.

Until the fix ships, the project can list the id under `disabledRules` in `.claude/conventions.json`.

## Before a pull request

From `claude/`:

```powershell
Invoke-Pester ./tests
Invoke-ScriptAnalyzer -Path ./hooks -Recurse -Settings ../release/PSScriptAnalyzerSettings.psd1
claude plugin validate .
```

Commits follow Conventional Commits (the `conventional-commits` skill). Breaking changes, such as a renamed skill or
a changed configuration shape, are marked with `!` on the commit itself.
