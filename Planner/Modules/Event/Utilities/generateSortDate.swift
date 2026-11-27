//
//  generateSortDate.swift
//  Planner
//
//  Created by Alex Green on 2/19/26.
//

import SwiftData
import SwiftDate
import SwiftUI

private let MINIMUM_SECONDS_GAP = 0.0001

// MARK: Planner Item Caller
@MainActor
func generatePlannerItemSortDate(
    at index: Int,
    /// May or may not contain the event being placed.
    in sortedItems: [PlannerItem],
    startOfDay: DateInRegion,
    modelContext: ModelContext
) -> Date {
    generateSortDate(
        at: index,
        in: sortedItems,
        startOfDay: startOfDay,
        getSortDate: {
            $0.sortDate
        },
        setSortDate: { event, sortDate in
            modelContext.setSortDate(sortDate, for: event)
        }
    )
}

// MARK: Bulk Planner Item Caller
/// Generates evenly spaced sort dates for several items inserted together at the same index.
/// The returned dates are ascending, in the order the items should appear.
@MainActor
func generatePlannerItemSortDates(
    count: Int,
    at index: Int,
    /// Should not contain the items being placed.
    in sortedItems: [PlannerItem],
    startOfDay: DateInRegion,
    modelContext: ModelContext
) -> [Date] {
    generateSortDates(
        count: count,
        at: index,
        in: sortedItems,
        startOfDay: startOfDay,
        getSortDate: {
            $0.sortDate
        },
        setSortDate: { event, sortDate in
            modelContext.setSortDate(sortDate, for: event)
        }
    )
}

// MARK: Planner Event Caller
@MainActor
func generatePlannerEventSortDate(
    at index: Int,
    /// May or may not contain the event being placed.
    in sortedEvents: [PlannerEvent],
    startOfDay: DateInRegion
) -> Date {
    generateSortDate(
        at: index,
        in: sortedEvents,
        startOfDay: startOfDay,
        getSortDate: {
            $0.sortDate
        },
        setSortDate: { event, sortDate in
            event.sortDate = sortDate
        }
    )
}

// MARK: Routine Event Caller
@MainActor
func generateRoutineEventSortDate(
    at index: Int,
    /// May or may not contain the event being placed.
    in sortedRoutineEvents: [RoutineEvent],
    startOfDay: DateInRegion,
    routine: Routine
) -> Date {
    generateSortDate(
        at: index,
        in: sortedRoutineEvents,
        startOfDay: startOfDay,
        getSortDate: {
            $0.sortDate
        },
        setSortDate: { event, sortDate in
            event.sortDate = sortDate
        }
    )
}

// MARK: - Generation Logic

@MainActor
private func generateSortDate<Event>(
    at index: Int,
    /// May or may not contain the event being placed.
    in sortedEvents: [Event],
    startOfDay: DateInRegion,
    getSortDate: @MainActor (Event) -> Date,
    setSortDate: @MainActor (Event, Date) -> Void
) -> Date {
    generateSortDates(
        count: 1,
        at: index,
        in: sortedEvents,
        startOfDay: startOfDay,
        getSortDate: getSortDate,
        setSortDate: setSortDate
    )[0]
}

/// Evenly divides the gap at the index into `count + 1` intervals.
/// Note: A single event in an empty day is placed at noon.
@MainActor
private func generateSortDates<Event>(
    count: Int,
    at index: Int,
    in sortedEvents: [Event],
    startOfDay: DateInRegion,
    getSortDate: @MainActor (Event) -> Date,
    setSortDate: @MainActor (Event, Date) -> Void
) -> [Date] {
    guard count > 0 else { return [] }

    // Note: An empty day (or an index past the end) inserts between the last event and the end of the day.
    let index = min(max(index, 0), sortedEvents.count)

    let dayStart = startOfDay.date
    let dayEnd = (startOfDay + 1.days).date

    func bounds() -> (prevDate: Date, nextDate: Date) {
        (
            index == 0 ? dayStart : getSortDate(sortedEvents[index - 1]),
            index >= sortedEvents.count
                ? dayEnd : getSortDate(sortedEvents[index])
        )
    }

    var (prevDate, nextDate) = bounds()
    var interval = nextDate.timeIntervalSince(prevDate) / Double(count + 1)

    if interval < MINIMUM_SECONDS_GAP {
        // Interval too small. Normalize all events.
        normalizeSortDates(
            for: sortedEvents,
            startOfDay: startOfDay,
            setSortDate: setSortDate
        )

        (prevDate, nextDate) = bounds()
        interval = nextDate.timeIntervalSince(prevDate) / Double(count + 1)
    }

    return (1...count).map {
        prevDate.addingTimeInterval(interval * Double($0))
    }
}

// MARK: - Helper Functions

@MainActor
private func normalizeSortDates<Event>(
    for events: [Event],
    startOfDay: DateInRegion,
    setSortDate: @MainActor (Event, Date) -> Void
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
