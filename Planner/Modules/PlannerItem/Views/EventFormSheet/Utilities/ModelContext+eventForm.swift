//
//  ModelContext+eventForm.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftData

extension ModelContext {
    /// The planner datestamps a calendar event appears in.
    @MainActor
    func calendarEventDatestamps(
        for ekEvent: EKEvent,
        settings: Settings
    ) -> Set<String> {
        if ekEvent.isAllDay {
            // All day events are floating. Directly compute the datestamps.
            return allDayDatestamps(
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                timeZoneId: ekEvent.timeZone?.identifier
            )
        }

        return Set(
            getSortedPlannerStartOfDays(
                for: ekEvent.startDate,
                endTime: ekEvent.endDate,
                settings: settings
            ).map(\.datestamp)
        )
    }
}
