//
//  CalendarService.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Combine
import Contacts
import EventKit

@MainActor
final class CalendarService: ObservableObject {
    let settings: Settings

    init(settings: Settings) {
        self.settings = settings
    }

    private let eventStore = EKEventStore()
    private let contactStore = CNContactStore()

    @Published private var calendarsById: [String: EKCalendar] = [:]

    var ekEventStore: EKEventStore {
        eventStore
    }

    var cnContactStore: CNContactStore {
        contactStore
    }

    var hasCalendarAccess: Bool? {
        let access = EKEventStore.authorizationStatus(for: .event)

        if access == .notDetermined {
            return nil
        }

        return [.writeOnly, .fullAccess].contains(access)
    }

    var hasContactsAccess: Bool? {
        if hasCalendarAccess == false {
            return false
        }

        let access = CNContactStore.authorizationStatus(for: .contacts)

        if access == .notDetermined {
            return nil
        }

        return access == .authorized
    }

    var isOnboardingCalendars: Bool {
        hasCalendarAccess == nil || hasContactsAccess == nil
    }

    var sortedCalendars: [EKCalendar] {
        calendarsById.values
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title)
                    == .orderedAscending
            }
    }

    var sortedVisibleCalendars: [EKCalendar] {
        sortedCalendars
            .filter {
                !settings.isCalendarHidden(calendarId: $0.calendarIdentifier)
            }
    }

    func loadCalendars() {
        guard hasCalendarAccess == true else {
            calendarsById = [:]
            return
        }

        let calendars = eventStore.calendars(for: .event)

        var calendarMap: [String: EKCalendar] = [:]

        for calendar in calendars {
            settings.ensureDefaultCalendarIcon(calendar: calendar)
            calendarMap[calendar.calendarIdentifier] = calendar
        }

        self.calendarsById = calendarMap
    }
}
