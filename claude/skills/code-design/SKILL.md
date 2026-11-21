---
name: code-design
description: Language-independent rules for names, files, control flow, comments, failures and models - full words, one type per file, size limits, rich models, no enums, one object per input, no second copy. Apply whenever writing, refactoring or reviewing code in any language (C#, TypeScript, SCSS, PowerShell, ...).
---

# Code design

Only the user, in so many words, overrides a rule here.

## Names

- **Full words only** in every identifier, file name, CSS class and parameter: never `btn`, `el`, `idx`, `repo`,
  `cfg`, `cdr`. Numeronyms (`a11y`, `i18n`) count. A name that feels too long means the concept needs a better one.
- Accepted acronyms: `Id`, `Url`, `Http`, `Api`; `Dto` only as a persistence-record suffix.
- An abbreviation in a file you edit is renamed in the same change.
- Locals and constants are camelCase (`slotHeight`), never `SLOT_HEIGHT`.
- No `utils`, `helpers`, `common`, `misc` or `*Manager` files, modules or classes: name the abstraction
  (`CalendarSlotCalculator`, not `calendar-utils`).

## Files

- **One type per file** (class, record, interface, type alias), named after it - never a second type in an existing
  file, however small.
- **One abstraction per file.** Split unrelated exports by responsibility; functions sharing a subject become a class
  named after it.
- **~120 lines splits a file** into the abstractions it hides (a collaborator owning one step, a
  retrieval/modification pair, a value object); **~20-30 lines splits a function**.

## Control flow

- Braces on every `if` / `else` / `for` / `foreach` / `while` / `switch` body, 1TBS, even for one statement.
- Guard clauses first so the main path stays flat; more than 3-4 nesting levels means split.
- Don't pass an argument equal to the parameter's default.

## Comments

A comment says only what the code cannot: a reason, a constraint, a trap in an external system. If the name, the
signature or the next line already says it, write no comment - rename or extract instead.

- **No header restating the name.** `Add-ReleaseStateAsset` needs no "Uploads a state asset to a release"; a
  parameter list needs no prose copy of its parameters, types or return shape.
- **Help blocks only on entry points** others run or call (scripts, hooks, public package APIs): a one-line synopsis,
  plus only what a caller must know (exit codes, side effects). Internal functions get none.
- **One or two lines.** No banners, no end-of-line narration (`# loop over units`), no history (`now`, `previously`,
  `fixed`, `new`) - that belongs in the commit message.
- Delete a comment your change makes redundant; fix one it makes untrue. No commented-out code; no `TODO` without a
  ticket reference.

```text
Wrong:  # Returns the releases of the repository.
        function Get-GitHubRelease { ... }
Right:  # Drafts are listed only for a token with Contents: write.
```

## Failures

- **Never swallow a failure**: a `catch` recovers with a real fallback or rethrows with context. An empty catch or
  log-and-continue is a defect, and exceptions never branch on an expected outcome.
- Validate at system boundaries (requests, files, deserialisation, external responses); trust the types inside.
- **No blanket suppressions** (`@ts-ignore`, `@ts-nocheck`, `#pragma warning disable` without a rule id, a locally
  lowered lint severity). When unavoidable: one rule, one line, the reason beside it.
- Never hand-edit generated code: change its source and regenerate.

## Models

- **Rich models, thin services.** A model owns the rules and values derived from its data; a service orchestrates
  (load, ask the model, save, raise events) and holds no rule.
- **No `enum`**, nor a string union returned for a caller to switch on: it pushes the rule into whoever switches. Put
  the rule on the model. Found / not found is `bool` or `null`; a broken invariant is a domain exception; a fixed set
  of persisted values is a class with named instances.
- **Build one object, then ask it** - never a static helper called once per value:

  ```text
  Wrong:  start = Schedule.At(period.Start); end = Schedule.At(period.End); span = Schedule.Span(period)
  Right:  slot = CalendarSlot.Of(period);    slot.Start, slot.End, slot.Span
  ```

  A value belonging to one type is its member (`appointment.End()`), not a static function taking it.

## No second copy

Search the feature before adding a constant, factory, formatting expression or rule; the second copy is the defect.
A shared magic value lives once, on the model owning the concept; an object built the same way twice gets a factory
on its class; a rule checked twice (a validator and an error message) is written once and called from both.
