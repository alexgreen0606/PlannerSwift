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
    private var hasLoaded = false

    @Published private(set) var calendarsById: [String: EKCalendar] = [:]
    @Published private(set) var allDayEventsByDatestamp: [String: [EKEvent]] =
        [:]
    @Published private(set) var singleDayEventsByDatestamp:
        [String: [EKEvent]] = [:]
    @Published var refreshKey: UUID? = nil

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
    func requestAccessAndLoadIfNeeded(hiddenCalendarIds: Set<String>) {
        guard !hasLoaded else { return }

        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            load(hiddenCalendarIds: hiddenCalendarIds)
        case .notDetermined:
            requestAccess(hiddenCalendarIds: hiddenCalendarIds)
        default:
            break
        }
    }

    func refresh(hiddenCalendarIds: Set<String>) {
        load(hiddenCalendarIds: hiddenCalendarIds)
    }

    private func requestAccess(hiddenCalendarIds: Set<String>) {
        eventStore.requestFullAccessToEvents { granted, error in
            guard granted else { return }
            Task { @MainActor in
                self.load(hiddenCalendarIds: hiddenCalendarIds)
            }
        }
    }

    private func load(hiddenCalendarIds: Set<String>) {
        hasLoaded = true

        loadCalendars()
        loadEvents(hiddenCalendarIds: hiddenCalendarIds)

        // TODO: cleanup positions object for sort indices
    }

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

    private func loadEvents(hiddenCalendarIds: Set<String>) {
        let start = DateInRegion(Date(), region: .local)
            .dateByAdding(-1, .month)
            .date

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

        for event in events {
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

        allDayEventsByDatestamp = allDayMap
        singleDayEventsByDatestamp = singleDayMap
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
}
