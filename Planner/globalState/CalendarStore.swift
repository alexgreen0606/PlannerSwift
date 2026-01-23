//
//  CalendarEventStore.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Combine
import EventKit
import SwiftDate
import SwiftUI

@MainActor
class CalendarStore: ObservableObject {
    static let shared = CalendarStore()
    private init() {}

    private let eventStore = EKEventStore()

    @Published private(set) var calendarsById: [String: EKCalendar] = [:]
    @Published private(set) var allDayEventsByDatestamp: [String: [EKEvent]] =
        [:]
    @Published private(set) var singleDayEventsByDatestamp:
        [String: [EKEvent]] = [:]
    @Published var refreshKey: UUID? = nil
    @Published private(set) var existingEventIds: Set<String> = []

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

    @MainActor
    func requestAccessAndLoadIfNeeded(
        hiddenCalendarIds: Set<String>,
        minCalendarDate: Date
    ) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            load(
                hiddenCalendarIds: hiddenCalendarIds,
                minCalendarDate: minCalendarDate
            )
        case .notDetermined:
            requestAccess(
                hiddenCalendarIds: hiddenCalendarIds,
                minCalendarDate: minCalendarDate
            )
        default:
            break
        }
    }

    func refresh(hiddenCalendarIds: Set<String>, minCalendarDate: Date) {
        load(
            hiddenCalendarIds: hiddenCalendarIds,
            minCalendarDate: minCalendarDate
        )
    }

    // More up-to-date than using event.calendar.cgColor directly.
    func calendarColor(for id: String) -> Color {
        guard let calendar = calendarsById[id] else {
            return Color(uiColor: .secondaryLabel)
        }

        return Color(calendar.cgColor)
    }

    private func requestAccess(
        hiddenCalendarIds: Set<String>,
        minCalendarDate: Date
    ) {
        eventStore.requestFullAccessToEvents { granted, error in
            guard granted else { return }
            Task { @MainActor in
                self.load(
                    hiddenCalendarIds: hiddenCalendarIds,
                    minCalendarDate: minCalendarDate
                )
            }
        }
    }

    private func load(hiddenCalendarIds: Set<String>, minCalendarDate: Date) {
        loadCalendars()
        loadEvents(
            hiddenCalendarIds: hiddenCalendarIds,
            minCalendarDate: minCalendarDate
        )
    }

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

    private func loadEvents(
        hiddenCalendarIds: Set<String>,
        minCalendarDate: Date
    ) {
        let start =
            minCalendarDate == .distantPast
            ? DateInRegion(Date(), region: .local)
                .date : minCalendarDate

        let end = DateInRegion(Date(), region: .local)
            .dateByAdding(3, .year)
            .date

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        var allDayMap: [String: [EKEvent]] = [:]
        var singleDayMap: [String: [EKEvent]] = [:]
        var eventIds: Set<String> = []

        for event in events {
            eventIds.insert(event.eventIdentifier)

            if hiddenCalendarIds.contains(event.calendar.calendarIdentifier) {
                continue
            }

            if event.isAllDay {
                // All-day events can span multiple days.
                for datestamp in expandedDatestamps(for: event) {
                    allDayMap[datestamp, default: []].append(event)
                }
            } else {
                //TODO: handle MULTI_DAY. For now, Timed events belong only to their start day
                let datestamp =
                    event.startDate
                    .in(region: .local)
                    .date
                    .datestamp

                singleDayMap[datestamp, default: []].append(event)
            }
        }

        existingEventIds = eventIds
        allDayEventsByDatestamp = allDayMap
        singleDayEventsByDatestamp = singleDayMap
        refreshKey = UUID()
    }

    @MainActor
    func ensureCalendarEvents(
        for datestamp: String,
        hiddenCalendarIds: Set<String>
    ) {
        // Already loaded for this day.
        if allDayEventsByDatestamp[datestamp] != nil
            || singleDayEventsByDatestamp[datestamp] != nil
        {
            return
        }

        guard let date = datestamp.date else {
            assertionFailure("Invalid datestamp: \(datestamp)")
            return
        }

        let start =
            date
            .in(region: .local)
            .dateAtStartOf(.day)
            .date

        let end = start + 1.days

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        var allDayEvents: [EKEvent] = []
        var singleDayEvents: [EKEvent] = []

        for event in events {
            existingEventIds.insert(event.eventIdentifier)

            if hiddenCalendarIds.contains(event.calendar.calendarIdentifier) {
                continue
            }

            if event.isAllDay {
                allDayEvents.append(event)
            } else {
                singleDayEvents.append(event)
            }
        }

        allDayEventsByDatestamp[datestamp] = allDayEvents
        singleDayEventsByDatestamp[datestamp] = singleDayEvents
        refreshKey = UUID()
    }

    // TODO: use this for ALL-DAY events, then create a new one for MULTI_DAY
    private func expandedDatestamps(for event: EKEvent) -> [String] {
        var results: [String] = []

        let start = event.startDate
            .in(region: .local)
            .dateAtStartOf(.day)

        let end = event.endDate
            .in(region: .local)
            .dateAtStartOf(.day)

        var current = start
        while current <= end {
            results.append(current.date.datestamp)
            current = current + 1.days
        }

        return results
    }

    @MainActor
    func delete(event: EKEvent) {
        guard event.calendar.allowsContentModifications else {
            print("Cannot delete event. Calendar is read-only.")
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
        } catch {
            assertionFailure("Failed to delete event: \(error)")
        }
    }

}
