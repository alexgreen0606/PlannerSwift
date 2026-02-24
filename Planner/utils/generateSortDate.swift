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
func generateSortDate(
    startOfDay: DateInRegion,
    index: Int,
    events: [PlannerEvent],
    settings: PlannerSettings
) -> Date {

    let dayStart = startOfDay.date
    let dayEnd = (startOfDay + 1.days).date

    // No events for the day. Place at noon.
    if events.isEmpty {
        return dayStart + 12.hours
    }

    // Determine neighboring dates
    var prevDate = index == 0 ? dayStart : events[index - 1].sortDate
    var nextDate = index >= events.count ? dayEnd : events[index].sortDate

    // Calculate midpoint
    let interval = nextDate.timeIntervalSince(prevDate)
    print(interval)
    if interval < 1.0 {

        // Interval too small → normalize all events
        normalizeEvents(
            events: events,
            startOfDay: startOfDay,
            settings: settings
        )

        // Recalculate after normalization
        prevDate = index == 0 ? dayStart : events[index - 1].sortDate
        nextDate = index >= events.count ? dayEnd : events[index].sortDate
    }

    return midpoint(between: prevDate, and: nextDate)
}

private func midpoint(between a: Date, and b: Date) -> Date {
    let interval = b.timeIntervalSince(a)
    return a.addingTimeInterval(interval / 2)
}

@MainActor
func normalizeEvents(
    events: [PlannerEvent],
    startOfDay: DateInRegion,
    settings: PlannerSettings
) {
    guard !events.isEmpty else { return }

    let dayStart = startOfDay.date
    let dayEnd = (startOfDay + 1.days).date
    let totalEvents = events.count
    let totalSeconds = dayEnd.timeIntervalSince(dayStart)
    let increment = totalSeconds / Double(totalEvents + 1)

    for (i, event) in events.enumerated() {
        event.sortDate = dayStart.addingTimeInterval(increment * Double(i + 1))

        if let calEvent = event.calendarEvent {
            settings.calendarSortDateMap[
                calEvent.calendarItemExternalIdentifier
            ] = event.sortDate
        }
    }
}
