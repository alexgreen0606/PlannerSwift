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

@MainActor
class CalendarStore: ObservableObject {
    @Published private(set) var accessDenied: Bool? = nil

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

    func refreshCalendarsAndAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            accessDenied = false
            loadCalendars()
        case .notDetermined:
            requestAccess()
        case .denied:
            accessDenied = true
        default:
            break
        }
    }

    // MARK: - Helper Functions

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, _ in
            Task { @MainActor in
                if granted {
                    self.accessDenied = false
                    self.loadCalendars()
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
