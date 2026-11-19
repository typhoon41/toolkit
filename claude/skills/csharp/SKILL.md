---
name: csharp
description: C# and ASP.NET Core conventions - async naming, thin controllers, rich domain models instead of enums, repository split, explicit persistence mapping, side effects after commit. Apply whenever writing, refactoring or reviewing any .cs file.
---

# C# / ASP.NET Core

Builds on `code-design` (names, files, braces, models), which is not repeated here. Where the solution references
the Gmf packages, `gmf-packages` names the concrete types.

## No `Async` suffix

A method returning `Task` / `Task<T>` / `ValueTask` has no `Async` suffix; the return type says it. Keep the suffix
only where a framework member forces the name: `BackgroundService.ExecuteAsync` / `StartAsync` / `StopAsync`,
EF Core `SaveChangesAsync` (and overrides), filter `OnActionExecutionAsync` / `OnResultExecutionAsync`, middleware
`InvokeAsync`, `IAsyncDisposable.DisposeAsync`, `IHostedService` members.

## Thin controllers

An action binds the request, calls one service method and maps the result to a status code. Mapping helpers,
date arithmetic, change detection, notification decisions and multi-step orchestration belong in a service behind
an interface in the domain's service contracts. Request-to-domain mapping is a `ToDomain()` method on the request
model.

```csharp
// Wrong - the controller decides, maps and notifies
var existing = await repository.GetEntry(id);
if (existing is null) { return NotFound(); }
await repository.UpdateEntry(id, MapToDomain(id, request));
if (existing.Date != request.Date) { await SendRescheduleEmail(existing, request); }
return NoContent();

// Right
public async Task<IActionResult> UpdateEntry(Guid id, EntryRequest request) =>
    await calendarService.UpdateEntry(id, request.ToDomain(id)) ? NoContent() : NotFound();
```

## Models instead of enums

How `code-design`'s no-enum rule looks in C#:

- The rule lives on a domain model in `Domain/Models/`, which answers or refuses; the service only orchestrates.
- Found / not found is `bool` or a nullable return; the controller maps it with `? NoContent() : NotFound()`.
- A broken invariant is a domain exception in `Domain/Exceptions/`, translated to `409 Conflict` by one filter.
- A fixed set of persisted values is an enumeration class with named static instances (it can carry behaviour)
  in `Domain/Enumerations/`.

```csharp
// Wrong - an outcome enum, the rule in the service, a switch to read it back
public enum SaveOutcome { Saved, NotFound, Overlapping }

// Right - the model owns the rule and refuses by throwing
var booking = new CalendarBooking(entry, existing);
booking.Claim(booking.ClaimsSlot && await repository.IsOccupied(booking));
```

## Repositories and persistence

- Each aggregate has two repository contracts: `I{Aggregate}RetrievalRepository` (queries) and
  `I{Aggregate}ModificationRepository` (writes). Never mix reads and writes in one interface.
- Repositories add and modify entities on the `DbContext`; the unit of work commits once per request, so they
  never call `SaveChangesAsync`.
- Persistence records own their mapping: `static MapFrom(domain)` builds the record, `MapTo{Model}()` returns the
  domain model. No mapping frameworks.

## Side effects after commit

Never send an email, message or other outward effect from inside an action or service call: it would go out even
if the commit fails. Raise an integration or domain event that is dispatched only after a successful
`SaveChangesAsync`.

## Culture-aware output

Never hard-code a date or time format. Set the recipient's culture first, then format with
`CultureInfo.CurrentCulture` (`"d"`, `"t"`), so dates and resource strings render in their language.
