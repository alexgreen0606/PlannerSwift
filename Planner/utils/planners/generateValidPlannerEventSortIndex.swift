//
//  generateValidPlannerEventSortIndex.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func generateValidPlannerEventSortIndex(
    event: PlannerEvent,
    events: [PlannerEvent]  // Must contain the event.
) -> Double {
    let prevSortIndex = event.sortIndex

    // Maintain current position.
    guard let eventDate = event.date else {
        return prevSortIndex
    }
    
    var eventWasFound = false
    var eventNeedsMoving = false
    
    var events = events
    events.sort { $0.sortIndex < $1.sortIndex }
    for (index, pointerEvent) in events.enumerated().reversed() {
        guard let pointerEventDate = pointerEvent.date else {
            continue
        }
        
        if pointerEvent.id == event.id {
            // Mark the target event as found.
            eventWasFound = true
        } else if pointerEventDate <= eventDate {
            if !eventWasFound || eventNeedsMoving {
                // Slide down to below this event.
                return generateSortIndex(
                    index: index + 1,
                    items: events
                )
            } else {
                // Maintain current position.
                return prevSortIndex
            }
        } else if eventWasFound {
            // Mark the target event as needing to move.
            eventNeedsMoving = true
        }
    }
    
    // No time conflicts found.
    if !eventNeedsMoving {
        return prevSortIndex
    }
    
    // Event is the earliest event.
    return (events.first?.sortIndex ?? 8) / 2
}
