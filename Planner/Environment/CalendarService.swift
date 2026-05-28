//
//  CalendarService.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Combine
import EventKit

@MainActor
final class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()

    private var calendarsById: [String: EKCalendar] = [:]

    @Published private(set) var hasAccess: Bool? = nil

    var ekEventStore: EKEventStore {
        eventStore
    }

    var sortedCalendars: [EKCalendar] {
        calendarsById.values
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title)
                    == .orderedAscending
            }
    }

    func refreshCalendarsAndAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            hasAccess = true
            loadCalendars()
        case .notDetermined:
            requestAccess()
        case .denied:
            hasAccess = false
            calendarsById = [:]
        default:
            break
        }
    }

    // MARK: - Helper Functions

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, _ in
            Task { @MainActor in
                if granted {
                    self.hasAccess = true
                    self.loadCalendars()
                } else {
                    self.hasAccess = false
                    self.calendarsById = [:]
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
