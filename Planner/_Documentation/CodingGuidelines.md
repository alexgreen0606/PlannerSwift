# Coding Guidelines

These conventions exist to keep the codebase consistent and predictable.

---

# SwiftUI

## Modifier Order

Apply view modifiers in a consistent order.

```swift
Text("Title")
    // Identity / Animation
    .id(...)
    .animation(...)

    // View-Specific
    .textSelection(...)
    .scrollTransition(...)

    // Styling
    .font(...)
    .foregroundStyle(...)
    .opacity(...)
    .background(...)

    // Layout
    .frame(...)
    .padding(...)

    // Safe Area
    .ignoresSafeArea(...)
    .safeAreaInset(...)

    // Overlay
    .overlay(...)
    .background(...)

    // Toolbar
    .toolbar(...)

    // Custom
    .plannerStyle(...)

    // Transition
    .transition(...)

    // User Interaction
    .onTapGesture(...)

    // Async
    .task(...)
    .onChange(...)

    // Presentation
    .sheet(...)
    .fullScreenCover(...)
```

---

# SwiftData

## Property Order

Declare properties in the following order:

1. Identifiers
2. UI properties
3. Internal/private logic properties
4. Parent relationships
5. Sibling relationships
6. Child relationships

Example:

```swift

// Identifier
var id: UUID

// UI
var title: String

// Internal
var sortIndex: Int

// Parent
var planner: Planner?

// Sibling
var routine: Routine?

// Children
var checklistItems: [ChecklistItem]?
```

## Relationship Types

### Parent

The current model is owned by another model.

Deleting the parent deletes this model.

### Sibling

Two-way ownership.

Declare sibling relationships on the less common ("smaller") model whenever possible.

### Child

The current model owns another model.

Deleting this model deletes its children.

## Relationship Rules

### Always Set Both Sides of a Relationship

When creating or modifying relationships, always update **both** objects involved.

SwiftData may eventually synchronize inverse relationships, but relying on this behavior can lead to inconsistent in-memory state or subtle bugs. Explicitly setting both sides keeps relationships predictable and immediately accurate.

✔ Preferred

```swift
trip.events.append(event)
event.trip = trip
```

✔ Likewise, when removing a relationship

```swift
trip.events.removeAll { $0 == event }
event.trip = nil
```

This rule applies to all parent, child, and sibling relationships.

---

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

---

# Confirmation Dialog Guidelines

## Titles

### Single Delete

Use the item's title unless currently inside that item's edit form.

✔ Outside form

```
Delete checklist "Shopping"?
```

✔ Inside form

```
Delete this checklist?
```

---

### Delete Selected Items

Use the selection count.

```
Delete 4 checklists?
```

---

### Delete by Category

Use the plural item type and category.

```
Delete completed items from April 17?
```

---

## Messages

### Single Delete

Include only details specific to that item.

```
Event will be removed from the calendar.
```

### Delete Selected Items

Include only details relevant to the selected items.

✔ One of the events is from the calendar

```
Events will be removed from the calendar. This cannot be undone.
```

✔ None of the events are from the calendar

```
This cannot be undone.
```

### Delete by Category

Always explain exactly what will be deleted. Don't relate it to the events directly.

```
Events will be removed from the calendar. Routines will not be affected.
```

---

## Buttons

### Single Delete

Do **not** include the item's title. Use the item's type.

✔

```
Delete Checklist
```

✘

```
Delete "Shopping"
```

---

### Delete Selected Items

Use the item count.

```
Delete 4 Checklists
```

---

### Delete by Category

Use the total number of affected items.

```
Delete 23 Items
```

---

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

---

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