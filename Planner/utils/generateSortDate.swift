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
func generateSortDate(
    startOfDay: DateInRegion,
    index: Int,
    events: [PlannerEvent]
) -> Date {

    let dayStart = startOfDay.date
    let dayEnd = (startOfDay + 1.days).date

    // No events for the day. Place at noon.
    if events.isEmpty {
        return dayStart + 12.hours
    }

    var prevDate = index == 0 ? dayStart : events[index - 1].sortDate
    var nextDate = index >= events.count ? dayEnd : events[index].sortDate
    let interval = nextDate.timeIntervalSince(prevDate)

    if interval < 1.0 {

        // Interval too small. Normalize all events.
        normalizeSortDates(
            events: events,
            startOfDay: startOfDay
        )

        prevDate = index == 0 ? dayStart : events[index - 1].sortDate
        nextDate = index >= events.count ? dayEnd : events[index].sortDate
    }

    return midpoint(between: prevDate, and: nextDate)
}

// MARK: - Helper Functions

private func midpoint(between a: Date, and b: Date) -> Date {
    let interval = b.timeIntervalSince(a)
    return a.addingTimeInterval(interval / 2)
}

@MainActor
private func normalizeSortDates(
    events: [PlannerEvent],
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
