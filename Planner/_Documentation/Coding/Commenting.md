# Commenting

## Comment Styles

Use comment syntax consistently based on the purpose of the comment.

### Documentation Comments (`///`)

Use triple-slash comments to document declarations that define your API or data model. These comments should explain **what** the declaration represents or does, not how it is implemented.

```swift
/// The title displayed to the user.
var title: String

/// Returns all planner events occurring on the specified date.
func plannerEvents(on date: DateInRegion) -> [PlannerEvent]
```

---

### Implementation Comments (`//`)

Use double-slash comments within functions to explain implementation details, reasoning, or non-obvious logic.

Comments should explain **why** the code exists or clarify complex behavior, rather than restating what the code already makes obvious.

✔ Good

```swift
// Exclude events that belong to hidden calendars.
guard !query.isCalendarHidden(calendarId: id) else {
    return nil
}
```

✘ Avoid

```swift
// Increment the index.
index += 1
```

Prefer expressive code over excessive comments whenever possible.
