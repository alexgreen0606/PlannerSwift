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

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Published private(set) var cache: [String: CalendarDayData] =
        [:]
    @Published private(set) var accessDenied: Bool? = nil

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

    func cacheData(_ data: CalendarDayData, plannerKey: String) {
        cache[plannerKey] = data
    }

    func attemptFreshLoad(hiddenCalendarIds: Set<String>) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            accessDenied = false
            beginFreshReload(
                hiddenCalendarIds: hiddenCalendarIds
            )
        case .notDetermined:
            requestAccess(
                hiddenCalendarIds: hiddenCalendarIds
            )
        case .denied:
            accessDenied = true
        default:
            break
        }
    }

    // MARK: - Helper Functions

    private func beginFreshReload(hiddenCalendarIds: Set<String>) {
        loadCalendars()
        cache = [:]
        reloadTrigger = UUID()
    }

    private func requestAccess(hiddenCalendarIds: Set<String>) {
        eventStore.requestFullAccessToEvents { granted, error in
            Task { @MainActor in
                if granted {
                    self.accessDenied = false
                    self.beginFreshReload(hiddenCalendarIds: hiddenCalendarIds)
                } else {
                    self.accessDenied = true
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
