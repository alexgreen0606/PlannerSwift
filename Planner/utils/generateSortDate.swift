//
//  generateSortDate.swift
//  Planner
//
//  Created by Alex Green on 2/19/26.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

@MainActor
func generateSortDate<Event: EventListItem>(
    at index: Int,
    in sortedEvents: [Event],  // May or may not contain the event being placed.
    plannerDay: DateInRegion
) -> Date {

    let dayStart = plannerDay.date
    let dayEnd = (plannerDay + 1.days).date

    // No events for the day. Place at noon.
    if sortedEvents.isEmpty {
        return dayStart + 12.hours
    }

    var prevDate = index == 0 ? dayStart : sortedEvents[index - 1].sortDate
    var nextDate =
        index >= sortedEvents.count ? dayEnd : sortedEvents[index].sortDate
    let interval = nextDate.timeIntervalSince(prevDate)

    if interval < 1.0 {

        // Interval too small. Normalize all events.
        normalizeSortDates(
            events: sortedEvents,
            startOfDay: plannerDay
        )

        prevDate = index == 0 ? dayStart : sortedEvents[index - 1].sortDate
        nextDate =
            index >= sortedEvents.count ? dayEnd : sortedEvents[index].sortDate
    }

    return midpoint(between: prevDate, and: nextDate)
}

// MARK: - Helper Functions

private func midpoint(between a: Date, and b: Date) -> Date {
    let interval = b.timeIntervalSince(a)
    return a.addingTimeInterval(interval / 2)
}

@MainActor
private func normalizeSortDates<Event: EventListItem>(
    events: [Event],
    startOfDay: DateInRegion
) {
    guard !events.isEmpty else { return }

    let dayStart = startOfDay.date
    let dayEnd = (startOfDay + 1.days).date
    let increment =
        dayEnd.timeIntervalSince(dayStart) / Double(events.count + 1)

    for (i, event) in events.enumerated() {
        event.sortDate = dayStart.addingTimeInterval(increment * Double(i + 1))
    }
}
