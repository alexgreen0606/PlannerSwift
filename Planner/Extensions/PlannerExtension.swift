//
//  PlannerExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit

extension Planner {
    func synchronizeCalendarEventPositions(
        for calendarEvents: [EKEvent],
        from positions: [CalendarEventPosition]
    ) -> ([PlannerEvent], [String: Double]) {

        var sortedPlannerEvents = self.events.filter { !$0.isChecked }.sorted {
            $0.sortIndex < $1.sortIndex
        }
        let sortedCalendarEvents = calendarEvents.sorted {
            $0.startDate < $1.startDate
        }

        for calEvent in sortedCalendarEvents {
            let sortIndex =
                positions.first(where: {
                    $0.eventId == calEvent.eventIdentifier
                })?.sortIndex ?? (sortedPlannerEvents.last?.sortIndex ?? 0 + 8)

            // Dummy event for UI representation. No persistence to storage.
            let plannerEvent = PlannerEvent(
                sortIndex: sortIndex,
                calendarEvent: calEvent
            )
            
            sortedPlannerEvents.append(plannerEvent)

            // 4. Safety check for chronological ordering.
            // 5. Add then planner event and its index to the map.
        }

        return (sortedPlannerEvents, [:])
    }
}
