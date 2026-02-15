//
//  plannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {

    @MainActor
    func createEvent(
        startOfDay: DateInRegion,
        at index: Int,
        in events: [PlannerEvent]
    ) {

        let sortIndex = generateSortIndex(index: index, items: events)

        let newEvent = PlannerEvent(
            date: startOfDay.date,
            calendarEvent: nil,
            sortIndex: sortIndex
        )

        insert(newEvent)

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.createEvent: \(error)"
            )
        }
    }

    @MainActor
    func moveEvent(
        from: Int,
        to: Int,
        events: [PlannerEvent],
        calendarSettings: CalendarSettings
    ) {
        guard from != to else { return }

        // 1: Force-save the event to its new position.
        let movedEvent = events[from]
        let eventsWithoutEvent = events.filter {
            $0.id != movedEvent.id
        }
        let newSortIndex = generateSortIndex(
            index: to,
            items: eventsWithoutEvent
        )
        movedEvent.sortIndex = newSortIndex

        // Save the calendar event position.
        if movedEvent.calendarEvent != nil {
            calendarSettings.sortIndexMap[
                movedEvent.calendarEvent!.calendarItemExternalIdentifier
            ] = movedEvent.sortIndex
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR: plannerEvent.moveEvent(1): \(error)"
            )
        }

        // 2: After UI settles, validate correct chronological insertion.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 sec

            let validSortIndex = generateValidPlannerEventSortIndex(
                for: movedEvent,
                in: events
            )
            if validSortIndex != newSortIndex {
                movedEvent.sortIndex = validSortIndex

                // Save the calendar event position.
                if movedEvent.calendarEvent != nil {
                    calendarSettings.sortIndexMap[
                        movedEvent.calendarEvent!.calendarItemExternalIdentifier
                    ] = movedEvent.sortIndex
                }

                do {
                    try save()
                } catch {
                    assertionFailure(
                        "ERROR: plannerEvent.moveEvent(2): \(error)"
                    )
                }
            }
        }
    }

    @MainActor
    func transferPlannerEvents(
        _ events: [PlannerEvent],
        to startOfDay: DateInRegion,
        preserveTimeOfDay: Bool = true
    ) {

        let targetRegion = startOfDay.region

        for event in events {
            if event.untimed {
                event.date = startOfDay.date
            } else {

                // TODO: shift date and preserve time of day if needed.

                //                if let newDate = event.date.shiftDate(to: self.datestamp, in: region) {
                //                    print("P: \(event.date) -> \(newDate)")
                //                    event.date = newDate
                //                } else {
                //                    assertionFailure(
                //                        "ERROR PlannerEventExtension.inheritEvents: Failed to shift event to new date."
                //                    )
                //                    // TODO: still need to shift event somehow
                //                    event.untimed = true
                //                }
            }
        }

        // TODO: normalize sort indices

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.transferPlannerEvents: \(error)"
            )
        }
    }

    @MainActor
    func deletePlannerEvents(
        _ events: [PlannerEvent]
    ) {

        for event in events {
            delete(event)
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete plan: \(error)"
            )
        }
    }

    @MainActor
    func deleteCheckedPlans(
        from plans: [PlannerEvent]
    ) {

        for event in plans {
            if event.isChecked {
                print("Deleting checked event: \(event.id)")
                delete(event)
            }
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete checked plans: \(error)"
            )
        }
    }

}
