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
