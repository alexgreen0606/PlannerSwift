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
        from positions: CalendarEventPositions
    ) -> [PlannerEvent] {
        var sortedPlannerEvents = self.events.filter { !$0.isChecked }.sorted {
            $0.sortIndex < $1.sortIndex
        }
        let sortedCalendarEvents = calendarEvents.sorted {
            $0.startDate < $1.startDate
        }
        
        var plannerEvents: [PlannerEvent] = []

        for calEvent in sortedCalendarEvents {
            let sortIndex = positions.values[calEvent.eventIdentifier]
                ?? (sortedPlannerEvents.last?.sortIndex ?? 0 + 8)

            // Dummy event for UI representation. No persistence to storage.
            let plannerEvent = PlannerEvent(
                sortIndex: sortIndex,
                calendarEvent: calEvent
            )
            
            sortedPlannerEvents.append(plannerEvent)
            
            plannerEvent.sortIndex = generateValidPlannerEventSortIndex(
                event: plannerEvent,
                events: sortedPlannerEvents
            )
            
            plannerEvents.append(plannerEvent)
            positions.values[calEvent.eventIdentifier] = plannerEvent.sortIndex
        }

        return plannerEvents
    }
}
