# toolkit

Shared tooling used by all projects, maintained in one place.

| Folder | What it is |
|---|---|
| [`release/`](release/README.md) | Versioning, release notes and NuGet / npm / GitHub releases for Azure Pipelines |
| [`claude/`](claude/README.md) | The `conventions` Claude Code plugin: coding-convention skills and a banned-pattern hook |

Projects consume `release/` by referencing this repository at a pinned tag, and `claude/` by adding this
repository as a Claude Code plugin marketplace (see each folder's README).
