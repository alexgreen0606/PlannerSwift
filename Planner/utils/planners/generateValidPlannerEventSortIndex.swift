//
//  generateValidPlannerEventSortIndex.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func generateValidPlannerEventSortIndex(
    event: PlannerEvent,
    events: [PlannerEvent] // Must contain the event.
) -> Double {
    let prevSortIndex = event.sortIndex

    // Untimed event: maintain current position.
    guard let eventTime = getPlannerEventTime(event: event) else {
        return prevSortIndex
    }
    
    var events = events
    events.sort { $0.sortIndex < $1.sortIndex }
    let eventsWithoutEvent = events.filter { $0.id != event.id }
    let eventsWithTime = events.filter { getPlannerEventTime(event: $0) != nil }

    guard
        let timedIndex = eventsWithTime.firstIndex(where: { $0.id == event.id })
    else {
        return prevSortIndex
    }

    // First or last timed event: maintain current position.
    guard timedIndex > 0 && timedIndex < eventsWithTime.count - 1 else {
        return prevSortIndex
    }
    
    guard let earlierTime = getPlannerEventTime(event: eventsWithTime[timedIndex - 1]) else {
        return prevSortIndex
    }
    guard let laterTime = getPlannerEventTime(event: eventsWithTime[timedIndex + 1]) else {
        return prevSortIndex
    }

    // No conflicts: maintain current position.
    if isTimeEarlierOrEqual(time1: earlierTime, time2: eventTime)
        && isTimeEarlierOrEqual(time1: eventTime, time2: laterTime)
    {
        return prevSortIndex
    }

    // Traverse the list in reverse to find the last event that starts before or at the same time.
    guard
        let earlierEventIndex = eventsWithoutEvent.lastIndex(where: {
            guard let time = getPlannerEventTime(event: $0) else {
                return false
            }
            return isTimeEarlierOrEqual(time1: time, time2: eventTime)
        })
    else {
        // Earliest event: place it at the top of the list.
        return (eventsWithoutEvent.first?.sortIndex ?? 0) / 2
    }

    // Found event that starts before or at the same time: place right below it.
    return generateSortIndex(index: earlierEventIndex + 1, items: eventsWithoutEvent)
}
