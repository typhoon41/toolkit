# C# project notes

<!-- Facts about this repository that the conventions:csharp skill relies on. Keep only what was verified in the
     repository; delete a line rather than guess. Rules never go here - only facts. -->

## Layout

- Domain models / exceptions / enumerations: `<folders>`
- Service and repository contracts: `<folders>`
- Service implementations: `<folder>`
- Repository implementations and persistence records: `<folders>`
- DI registration (modules): `<folder>`, repository module `<name>`, service module `<name>`, configuration module
  `<name>`

## Validation

- Validator location: `<folder>`
- Message language and source: `<e.g. resource Labels.* for public models; plain Serbian literals for admin-only models>`

## Culture and outgoing messages

- How a recipient's culture is set: `<e.g. cultureResolver.SetCulture(language), language from AppointmentDto.Language>`
- Email templates: `<folder>`

## Wire formats

- `<e.g. shared DateOnly/TimeOnly converters serialize with CurrentCulture; never pin them>`
