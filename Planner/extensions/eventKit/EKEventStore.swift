//
//  EKEventStore.swift
//  Planner
//
//  Created by Alex Green on 3/3/26.
//

import EventKit

// Clean

extension EKEventStore {

    func deleteEvent(_ event: EKEvent) -> Bool {
        guard event.calendar.allowsContentModifications else {
            print("Cannot delete event. Calendar is read-only.")
            
            return false
        }

        do {
            try remove(
                event,
                span: .thisEvent,
                commit: true
            )
            
            return true
        } catch {
            assertionFailure("ERROR EKEventStore.deleteEvent: \(error)")
        }
        
        return false
    }

}
