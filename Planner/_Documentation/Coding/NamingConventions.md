# Naming Conventions

## Variables

Use names that describe what the object represents. Avoid generic terms like `event` or `record`.

| Preferred | Meaning |
|-----------|---------|
| `calendarRecords` | Planner events backed by EventKit |
| `routineEventRecords` | Planner events backed by a RoutineEvent |

---

## Functions

Use parameter labels consistently.

| Type | Label |
|------|-------|
| `Weekday` | `for` |
| `Routine` | `for` |
| `DateInRegion` | `on` |

Examples:

```swift
events(for weekday: Weekday)
events(for routine: Routine)
events(on startOfDay: DateInRegion)
```

---

## Context vs Details

Use the suffixes consistently.

### Context

Represents actual stored data.

Usually a class or struct.

Examples:

- `EKEventContext`
- `CalendarContext`

### Details

Represents protocol-based or lightweight information.

Examples:

- `EventDetails`
- `RoutineDetails`
