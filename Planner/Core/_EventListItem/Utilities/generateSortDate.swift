//
//  generateSortDate.swift
//  Planner
//
//  Created by Alex Green on 2/19/26.
//

import SwiftDate
import SwiftUI

private let MINIMUM_SECONDS_GAP = 0.0001

func generateSortDate<Event: EventListItem>(
    at index: Int,

    // May or may not contain the event being placed.
    in sortedEvents: [Event],

    plannerDay: DateInRegion,
    getSortDate: (Event) -> Date = { $0.sortDate },
    setSortDate: (Event, Date) -> Void = { event, sortDate in
        event.sortDate = sortDate
    }
) -> Date {
    let dayStart = plannerDay.date
    let dayEnd = (plannerDay + 1.days).date

    if sortedEvents.isEmpty {
        // No events for the day. Place at noon.
        return midpoint(between: dayStart, and: dayEnd)
    }

    var prevDate = index == 0 ? dayStart : getSortDate(sortedEvents[index - 1])
    var nextDate =
        index >= sortedEvents.count ? dayEnd : getSortDate(sortedEvents[index])

    let secondsGap = nextDate.timeIntervalSince(prevDate)

    if secondsGap < MINIMUM_SECONDS_GAP {
        // Interval too small. Normalize all events.
        normalizeSortDates(
            for: sortedEvents,
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
    for events: [Event],
    startOfDay: DateInRegion,
    setSortDate: (Event, Date) -> Void = { event, sortDate in
        event.sortDate = sortDate
    }
) {
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
