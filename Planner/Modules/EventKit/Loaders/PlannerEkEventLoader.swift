//
//  PlannerEkEventLoader.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Combine
import EventKit
import Foundation
import SwiftDate

/// Loads a planner's calendar events directly from EventKit (and birthday contacts from Contacts).
@MainActor
final class PlannerEkEventLoader: ObservableObject {
    private let calendarService: CalendarService
    private let settings: Settings
    private var startOfDay: DateInRegion
    private var cancellables: Set<AnyCancellable> = []

    init(
        calendarService: CalendarService,
        settings: Settings,
        startOfDay: DateInRegion
    ) {
        self.calendarService = calendarService
        self.settings = settings
        self.startOfDay = startOfDay

        reload()

        calendarService.ekEventChangesPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    /// Timed events that start on this day. Displayed as list rows.
    ///  Sorted chronologically.
    @Published private(set) var sortedListEvents: [EKEvent] = []

    /// All-day events on this day, and timed events that span outside of this day.
    /// Sorted alphabetically.
    @Published private(set) var sortedChipEvents: [EKEvent] = []

    /// Birthday calendar events on this day.
    /// Sorted alphabetically.
    @Published private(set) var sortedBirthdayItems: [PlannerBirthdayItem] =
        []

    func update(startOfDay: DateInRegion) {
        self.startOfDay = startOfDay
        reload()
    }

    func reload() {
        let dayStart = startOfDay.date
        let dayEnd = (startOfDay + 1.days).date
        let datestamp = startOfDay.datestamp

        let ekEvents = calendarService.fetchEkEvents(
            in: DateInterval(start: dayStart, end: dayEnd),
            settings: settings
        )

        var listEvents: [EKEvent] = []
        var chipEvents: [EKEvent] = []
        var birthdayEvents: [EKEvent] = []

        for ekEvent in ekEvents {
            guard ekEvent.calendarItemExternalIdentifier != nil,
                let startDate = ekEvent.startDate,
                let endDate = ekEvent.endDate
            else { continue }

            if ekEvent.birthdayContactIdentifier != nil {

                // MARK: Birthday events that exist on this day.

                if !ekEvent.isAllDay || allDayRangeContains(
                    datestamp: datestamp,
                    startDate: startDate,
                    endDate: endDate,
                    timeZoneId: ekEvent.timeZone?.identifier
                ) {
                    birthdayEvents.append(ekEvent)
                }

            } else if ekEvent.isAllDay {

                // MARK: All-day events that exist on this day.

                if allDayRangeContains(
                    datestamp: datestamp,
                    startDate: startDate,
                    endDate: endDate,
                    timeZoneId: ekEvent.timeZone?.identifier
                ) {
                    chipEvents.append(ekEvent)
                }

            } else if startDate >= dayStart && startDate < dayEnd {

                // MARK: Timed events that start on this day.

                listEvents.append(ekEvent)

            } else if startDate < dayStart && endDate > dayStart {

                // MARK: Timed events that exist on this day and start before it.

                chipEvents.append(ekEvent)
            }
        }

        sortedListEvents = listEvents.sorted { $0.startDate < $1.startDate }
        sortedChipEvents = chipEvents.sorted(by: Self.titleOrder)
        sortedBirthdayItems = calendarService.makeBirthdayItems(
            birthdayEvents.sorted(by: Self.titleOrder)
        )
    }

    // MARK: - Helpers

    /// Changes when a planner's 24-hour window moves and/or when the visible calendars change.
    /// Views observe this to know when to call `update(startOfDay:)`.
    static func reloadKey(
        startOfDay: DateInRegion,
        calendarService: CalendarService,
        settings: Settings
    ) -> String {
        calendarService.ekEventReloadKey(
            range: DateInterval(
                start: startOfDay.date,
                end: (startOfDay + 1.days).date
            ),
            settings: settings
        )
    }

    private static func titleOrder(_ lhs: EKEvent, _ rhs: EKEvent) -> Bool {
        (lhs.title ?? "").localizedStandardCompare(rhs.title ?? "")
            == .orderedAscending
    }
}
