# Initialization

## Prefer Specialized Initializers

When a type can be created in multiple distinct ways, define a separate initializer for each case rather than a single initializer with optional parameters.

Each initializer should clearly communicate the required information for that specific use case and prevent invalid or ambiguous states.

✔ Preferred

```swift
struct PlannerEvent {

    init(calendarEvent: EKEvent) {
        ...
    }

    init(routineEvent: RoutineEvent) {
        ...
    }
}
```

✘ Avoid

```swift
struct PlannerEvent {

    init(
        calendarEvent: EKEvent? = nil,
        routineEvent: RoutineEvent? = nil
    ) {
        ...
    }
}
```

Separate initializers make the API more self-documenting, eliminate invalid parameter combinations, and reduce the need for conditional logic inside the initializer.

If an initializer requires values that are only relevant to one creation path, it should be its own `init` rather than introducing optional parameters used by other paths.
