//
//  generateSortDate.swift
//  Planner
//
//  Created by Alex Green on 2/19/26.
//

import EventKit
import SwiftDate
import SwiftUI

@MainActor
func generateSortDate<Event: EventListItem>(
    at index: Int,
    in sortedEvents: [Event], // May or may not contain the event being placed.
    plannerDay: DateInRegion,
    getSortDate: (Event) -> Date = { $0.sortDate },
    setSortDate: (Event, Date) -> Void = { event, sortDate in
        event.sortDate = sortDate
    }
) -> Date {
    let dayStart = plannerDay.date
    let dayEnd = (plannerDay + 1.days).date

    // No events for the day. Place at noon.
    if sortedEvents.isEmpty {
        return dayStart + 12.hours
    }

    var prevDate = index == 0 ? dayStart : getSortDate(sortedEvents[index - 1])
    var nextDate =
        index >= sortedEvents.count ? dayEnd : getSortDate(sortedEvents[index])
    let interval = nextDate.timeIntervalSince(prevDate)

    if interval < 1.0 {
        // Interval too small. Normalize all events.
        normalizeSortDates(
            events: sortedEvents,
            startOfDay: plannerDay,
            setSortDate: setSortDate
        )

        prevDate = index == 0 ? dayStart : getSortDate(sortedEvents[index - 1])
        nextDate =
            index >= sortedEvents.count
                ? dayEnd : getSortDate(sortedEvents[index])
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
    startOfDay: DateInRegion,
    setSortDate: (Event, Date) -> Void = { event, sortDate in
        event.sortDate = sortDate
    }
) {
    guard !events.isEmpty else { return }

    let dayStart = startOfDay.date
    let dayEnd = (startOfDay + 1.days).date
    let increment =
        dayEnd.timeIntervalSince(dayStart) / Double(events.count + 1)

    for (i, event) in events.enumerated() {
        setSortDate(
            event,
            dayStart.addingTimeInterval(increment * Double(i + 1))
        )
    }
}
