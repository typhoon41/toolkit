---
name: gmf-packages
description: How to use the Gmf.DDD.Common, Gmf.Net.Core.Common and Gmf.Mail.Common packages - unit of work, domain and integration events, conflict exceptions, enumerations, Autofac registration. Apply when writing or reviewing C# in a solution that references any Gmf.* package.
---

# Gmf packages

The concrete types behind the `csharp` skill's rules when the solution uses the Gmf packages.

## Unit of work - `TransactionFilter`

`TransactionFilter` (Gmf.Net.Core.Common) is the unit of work the `csharp` skill relies on: it wraps every
controller action and calls `SaveChangesAsync()` once the action returns a 2xx result with a valid model state;
when the action throws, nothing is saved.

## Events

- **Domain events:** add them with `EntityDto.AddDomainEvent(...)` inside repository methods;
  `BaseDbContext.SaveChangesAsync` dispatches them. Never dispatch from a controller or service.
- **Integration events** (emails, notifications): `IStoreEvents.Add(...)`. `BaseDbContext` publishes them after
  `base.SaveChangesAsync`, so they fire only on a successful commit.

## Domain rules

- A broken invariant throws a subclass of `DomainConflictException` (`Gmf.DDD.Common.Concepts`);
  `DomainConflictFilter` answers 409 and `TransactionFilter` saves nothing.
- A fixed set of persisted values derives from `Enumeration<T>` (Gmf.DDD.Common).
- Entities derive from `Entity<T>`, value objects from `ValueObject`; a time range is a `Period`.

## Registration (Autofac)

Register in the project's Autofac modules, never in `Program.cs`:

| New | Registration | Module |
|---|---|---|
| Repository | `DefaultInterfaceRegistration<TRepository>()` | repository module |
| Service | `DefaultInterfaceRegistration<TService>()` | service module |
| Settings section | `SingleSelfRegistration<TSettings>()` | configuration module |

## Email

Send through Gmf.Mail.Common's `IEmailClient`, from the handler of an integration event; `EmailClientStub` stands
in where no SMTP server is configured.
