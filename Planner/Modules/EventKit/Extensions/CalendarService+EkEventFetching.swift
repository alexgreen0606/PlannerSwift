//
//  CalendarService+EkEventFetching.swift
//  Planner
//
//  Created by Alex Green on 11/27/26.
//

import Combine
import Contacts
import EventKit
import Foundation

/// Shared EventKit reads used by the planner and calendar loaders.
extension CalendarService {

    // MARK: - Calendars

    /// The calendars to read events from.
    /// Note: `CalendarService` loads its calendars shortly after launch. Until then, read them directly
    /// from the event store so calendar events render in the same frame as Planner events.
    func visibleCalendars(settings: Settings) -> [EKCalendar] {
        guard hasCalendarAccess == true else { return [] }

        guard sortedCalendars.isEmpty else {
            return sortedVisibleCalendars
        }

        return ekEventStore.calendars(for: .event)
            .filter {
                !settings.isCalendarHidden(calendarId: $0.calendarIdentifier)
            }
    }

    // MARK: - Events

    /// Every event in the visible calendars that overlaps the range.
    func fetchEkEvents(in range: DateInterval, settings: Settings) -> [EKEvent] {
        let calendars = visibleCalendars(settings: settings)

        // Note: Passing an empty array to the predicate would search all calendars.
        guard !calendars.isEmpty else { return [] }

        return ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: range.start,
                end: range.end,
                calendars: calendars
            )
        )
    }

    /// Changes when the range moves and/or when the visible calendars change.
    /// Views observe this to know when to reload, since neither change posts `EKEventStoreChanged`.
    ///
    /// Note: Uses the same calendars as the fetch, so the key is already stable on the first render
    /// and doesn't trigger a reload when `CalendarService` finishes loading.
    func ekEventReloadKey(range: DateInterval?, settings: Settings) -> String {
        let calendarIds = visibleCalendars(settings: settings)
            .map(\.calendarIdentifier)
            .sorted()
            .joined(separator: ",")

        let start = range?.start.timeIntervalSince1970 ?? 0
        let end = range?.end.timeIntervalSince1970 ?? 0

        return "\(start)|\(end)|\(calendarIds)"
    }

    /// Fires whenever calendar events or contacts change outside of the app's view of them.
    var ekEventChangesPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: .EKEventStoreChanged, object: ekEventStore)
            .merge(
                with: NotificationCenter.default.publisher(
                    for: .CNContactStoreDidChange
                )
            )
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Birthdays

    /// Contact thumbnails for the birthday events, keyed by contact identifier.
    /// Note: Only lightweight keys are fetched. The full contact is loaded when its sheet opens.
    func birthdayThumbnails(for ekEvents: [EKEvent]) -> [String: Data] {
        let contactIds = Array(
            Set(ekEvents.compactMap(\.birthdayContactIdentifier))
        )

        guard hasContactsAccess == true, !contactIds.isEmpty else {
            return [:]
        }

        do {
            let contacts = try cnContactStore.unifiedContacts(
                matching: CNContact.predicateForContacts(
                    withIdentifiers: contactIds
                ),
                keysToFetch: [
                    CNContactIdentifierKey,
                    CNContactThumbnailImageDataKey,
                ] as [CNKeyDescriptor]
            )

            var thumbnails: [String: Data] = [:]

            for contact in contacts {
                thumbnails[contact.identifier] = contact.thumbnailImageData
            }

            return thumbnails
        } catch {
            assertionFailure(
                "ERROR CalendarService birthdayThumbnails: \(error)"
            )
            return [:]
        }
    }

    /// Pairs birthday events with their contact thumbnails.
    func makeBirthdayItems(_ ekEvents: [EKEvent]) -> [PlannerBirthdayItem] {
        let thumbnails = birthdayThumbnails(for: ekEvents)

        return ekEvents.compactMap { ekEvent in
            guard let contactId = ekEvent.birthdayContactIdentifier else {
                return nil
            }

            return PlannerBirthdayItem(
                ekEvent: ekEvent,
                contactIdentifier: contactId,
                thumbnailData: thumbnails[contactId]
            )
        }
    }
}
