//
//  PlannerEkEventLoader.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Combine
import Contacts
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

        NotificationCenter.default
            .publisher(
                for: .EKEventStoreChanged,
                object: calendarService.ekEventStore
            )
            .merge(
                with: NotificationCenter.default.publisher(
                    for: .CNContactStoreDidChange
                )
            )
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
        guard calendarService.hasCalendarAccess == true else {
            clear()
            return
        }

        let calendars = Self.visibleCalendars(
            calendarService: calendarService,
            settings: settings
        )

        // Note: Passing an empty array to the predicate would search all calendars.
        guard !calendars.isEmpty else {
            clear()
            return
        }

        let dayStart = startOfDay.date
        let dayEnd = (startOfDay + 1.days).date
        let datestamp = startOfDay.datestamp
        let ekEventStore = calendarService.ekEventStore

        let ekEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: dayStart,
                end: dayEnd,
                calendars: calendars
            )
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
        sortedBirthdayItems = makeBirthdayItems(
            birthdayEvents.sorted(by: Self.titleOrder)
        )
    }

    // MARK: - Helpers

    private func clear() {
        sortedListEvents = []
        sortedChipEvents = []
        sortedBirthdayItems = []
    }

    /// Attaches contact thumbnails to birthday events.
    /// Note: Only lightweight keys are fetched. The full contact is loaded when its sheet opens.
    private func makeBirthdayItems(_ ekEvents: [EKEvent])
        -> [PlannerBirthdayItem]
    {
        let contactIds = ekEvents.compactMap(\.birthdayContactIdentifier)
        var thumbnailsByContactId: [String: Data] = [:]

        if calendarService.hasContactsAccess == true, !contactIds.isEmpty {
            do {
                let contacts = try calendarService.cnContactStore
                    .unifiedContacts(
                        matching: CNContact.predicateForContacts(
                            withIdentifiers: contactIds
                        ),
                        keysToFetch: [
                            CNContactIdentifierKey,
                            CNContactThumbnailImageDataKey,
                        ] as [CNKeyDescriptor]
                    )

                for contact in contacts {
                    thumbnailsByContactId[contact.identifier] =
                        contact.thumbnailImageData
                }
            } catch {
                assertionFailure(
                    "ERROR PlannerEkEventLoader makeBirthdayItems: \(error)"
                )
            }
        }

        return ekEvents.compactMap { ekEvent in
            guard let contactId = ekEvent.birthdayContactIdentifier else {
                return nil
            }

            return PlannerBirthdayItem(
                ekEvent: ekEvent,
                contactIdentifier: contactId,
                thumbnailData: thumbnailsByContactId[contactId]
            )
        }
    }

    /// The calendars to read events from.
    /// Note: `CalendarService` loads its calendars shortly after launch. Until then, read them directly
    /// from the event store so calendar events render in the same frame as Planner events.
    static func visibleCalendars(
        calendarService: CalendarService,
        settings: Settings
    ) -> [EKCalendar] {
        guard calendarService.hasCalendarAccess == true else { return [] }

        guard calendarService.sortedCalendars.isEmpty else {
            return calendarService.sortedVisibleCalendars
        }

        return calendarService.ekEventStore.calendars(for: .event)
            .filter {
                !settings.isCalendarHidden(calendarId: $0.calendarIdentifier)
            }
    }

    /// Changes when a planner's 24-hour window moves and/or when the visible calendars change.
    /// Views observe this to know when to call `update(startOfDay:)`.
    ///
    /// Note: Uses the same calendars as the loader, so the key is already stable on the first render
    /// and doesn't trigger a reload when `CalendarService` finishes loading.
    static func reloadKey(
        startOfDay: DateInRegion,
        calendarService: CalendarService,
        settings: Settings
    ) -> String {
        let calendarIds = visibleCalendars(
            calendarService: calendarService,
            settings: settings
        )
        .map(\.calendarIdentifier)
        .sorted()
        .joined(separator: ",")

        return "\(startOfDay.date.timeIntervalSince1970)|\(calendarIds)"
    }

    private static func titleOrder(_ lhs: EKEvent, _ rhs: EKEvent) -> Bool {
        (lhs.title ?? "").localizedStandardCompare(rhs.title ?? "")
            == .orderedAscending
    }
}
