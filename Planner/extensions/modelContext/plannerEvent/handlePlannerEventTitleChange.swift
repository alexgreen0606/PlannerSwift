//
//  handlePlannerEventTitleChange.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    @MainActor
    func handlePlannerEventTitleChange(
        _ event: PlannerEvent,
        plannerDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {
        
        if let calendarEvent = event.calendarEvent {
            // Event is a calendar event. Update its title in the calendar.
            calendarEvent.title = event.title
            let _ = eventKitStore.updateEvent(calendarEvent)
            return
        }

        // Scan the title for a date.
        guard let defaultLocation,
            let (date, updatedText) = event.title.separateDate(for: plannerDay)
        else {
            return
        }

        event.title = updatedText
        event.location = defaultLocation
        event.date = date
        event.hasTime = true

        self.safeSave("handlePlannerEventTitleChange")
    }

}
