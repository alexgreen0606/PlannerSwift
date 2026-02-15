//
//  generateValidPlannerEventSortIndex.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func generateValidPlannerEventSortIndex(
    for event: PlannerEvent,
    in events: [PlannerEvent]  // Must contain the event.
) -> Double {
    let prevSortIndex = event.sortIndex

    // Maintain current position.
    guard !event.untimed else {
        return prevSortIndex
    }
    
    let eventDate = event.date
    
    var eventWasFound = false
    var eventNeedsMoving = false
    
    let events = events.sorted { $0.sortIndex < $1.sortIndex }
    
    for (index, pointerEvent) in events.enumerated().reversed() {
        guard !pointerEvent.untimed else {
            continue
        }
        
        let pointerEventDate = pointerEvent.date
        
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
