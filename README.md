# toolkit

Shared tooling used by all projects, maintained in one place.

| Folder | What it is |
|---|---|
| [`release/`](release/README.md) | Versioning, release notes and NuGet / npm / GitHub releases for Azure Pipelines |
| [`claude/`](claude/README.md) | The `conventions` Claude Code plugin: strict coding-convention skills, plus hooks that gate edits on the owning skills, flag banned patterns and format C# |

Projects consume `release/` by referencing this repository's `main` branch, and `claude/` by adding this
repository as a Claude Code plugin marketplace (see each folder's README).
