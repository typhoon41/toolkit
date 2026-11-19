---
name: code-design
description: Language-independent design and naming rules - full-word names, one type per file, file size, rich models, no enums, one object per input, no duplication. Apply whenever writing, refactoring or reviewing code in any language (C#, TypeScript, SCSS, PowerShell, ...).
---

# Code design

These rules hold in every stack. Stack skills (`csharp`, `angular`, `html-scss`) add how each one is realised
there; they never restate a rule from here. A rule is overridden only by the user, in so many words.

## Names

- **Full words only.** Every identifier, file name, CSS class, parameter and injected dependency is written in
  full: `button`, `element`, `index`, `repository`, `configuration`, `changeDetector` - never `btn`, `el`, `idx`,
  `repo`, `cfg`, `cdr`. Numeronyms (`a11y`, `i18n` as an identifier) count as abbreviations. If a full name feels
  too long, the concept needs a better name.
- Accepted acronyms, written as words: `Id`, `Url`, `Http`, `Api`, and `Dto` only as the suffix of a
  persistence record.
- An abbreviation already in a file you edit is not grandfathered: rename it in the same change.
- **camelCase for locals and constants.** `const slotHeight = 36`, never `SLOT_HEIGHT`.
- **Name the abstraction, not the bag.** No `utils`, `helpers`, `common`, `misc` or `*Manager` files, modules or
  classes: `CalendarSlotCalculator`, not `calendar-utils`.

## Files

- **One type per file**, named after the type: each class, record, interface or type alias. Never a second type
  in an existing file, however small.
- **One abstraction per file.** A file collecting unrelated exports is split by responsibility. Prefer a class
  over a pile of loose functions; when several functions share a subject, that subject is the class.
- **~120 lines is a split trigger.** A file approaching it holds more than one responsibility: split it into the
  abstractions it hides (a collaborator that owns one step, a retrieval/modification pair, a value object).

## Control flow

Every `if`, `else`, `for`, `foreach`, `while` and `switch` body has braces, 1TBS: `{` on the keyword's line, the
body and the closing `}` on lines of their own - also for one-statement bodies.

## Models

- **Rich models, thin services.** A model owns the rules and the values derived from its own data. A service
  orchestrates (load, ask the model, save, raise events) and holds no rule.
- **No `enum`.** An enum of outcomes or states is a missing abstraction: it pushes the rule into whoever switches
  on it. Put the rule on the model and let it answer. Found / not found is a `bool` or `null`; a broken invariant
  is a domain exception; a fixed set of persisted values is a class with named instances. The same applies to a
  string union returned for a caller to switch on.
- **Build one object, then ask it.** When several values derive from one input, create one object through a
  single factory and read its members - never call a static helper once per value:

  ```text
  Wrong:  start = Schedule.At(period.Start); end = Schedule.At(period.End); span = Schedule.Span(period)
  Right:  slot = CalendarSlot.Of(period);    slot.Start, slot.End, slot.Span
  ```

  A value that belongs to one type is a member of that type (`appointment.End()`), not a static function taking
  it as an argument.

## No second copy

Before adding a constant, a factory, a formatting expression or a rule, search the feature for an existing one;
the second copy is the defect.

- A magic value needed in two places lives once, on the model that owns the concept.
- An object built the same way in several places gets a factory on its class.
- A rule checked in two places (a validator and an error message) is written once and called from both.
