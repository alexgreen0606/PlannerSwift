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
    guard let eventTime = getPlannerEventTime(event: event) else {
        return prevSortIndex
    }
    
    var eventWasFound = false
    var eventNeedsMoving = false
    
    var events = events
    events.sort { $0.sortIndex < $1.sortIndex }
    for (index, pointerEvent) in events.enumerated().reversed() {
        guard let pointerEventTime = getPlannerEventTime(event: pointerEvent) else {
            continue
        }
        
        if pointerEvent.id == event.id {
            // Mark the target event as found.
            eventWasFound = true
        } else if pointerEventTime.isEarlierOrEqual(to: eventTime) {
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
    
    // Event is the earliest event.
    return (events.first?.sortIndex ?? 8) / 2
}
