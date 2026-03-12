//
//  CalendarStore.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Combine
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

@MainActor
class CalendarStore: ObservableObject {

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Published private(set) var allDayEventsByPlannerKey: [String: [EKEvent]] =
        [:]
    @Published private(set) var calendarAccessDenied: Bool? = nil

    // Tells views to re-load their calendar data.
    @Published private(set) var reloadTrigger: UUID? = nil

    private let eventStore = EKEventStore()
    private var calendarsById: [String: EKCalendar] = [:]

    var ekEventStore: EKEventStore {
        eventStore
    }

    var sortedCalendars: [EKCalendar] {
        Array(calendarsById.values)
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title)
                    == .orderedAscending
            }
    }

    func cachePlannerChips(_ plannerChipEvents: [EKEvent], plannerKey: String) {
        allDayEventsByPlannerKey[plannerKey] = plannerChipEvents
    }

    func attemptFreshLoad(hiddenCalendarIds: Set<String>) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            calendarAccessDenied = false
            beginFreshReload(
                hiddenCalendarIds: hiddenCalendarIds
            )
        case .notDetermined:
            requestAccess(
                hiddenCalendarIds: hiddenCalendarIds
            )
        case .denied:
            calendarAccessDenied = true
        default:
            break
        }
    }

    // MARK: - Helper Functions

    private func beginFreshReload(hiddenCalendarIds: Set<String>) {
        loadCalendars()
        allDayEventsByPlannerKey = [:]
        reloadTrigger = UUID()
    }

    private func requestAccess(hiddenCalendarIds: Set<String>) {
        eventStore.requestFullAccessToEvents { granted, error in
            Task { @MainActor in
                if granted {
                    self.calendarAccessDenied = false
                    self.beginFreshReload(hiddenCalendarIds: hiddenCalendarIds)
                } else {
                    self.calendarAccessDenied = true
                }
            }
        }
    }

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

}
