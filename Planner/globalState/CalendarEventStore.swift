//
//  CalendarEventStore.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Foundation
import Combine
import SwiftDate
import EventKit
import SwiftUI

@MainActor
class CalendarEventStore: ObservableObject {
    static let shared = CalendarEventStore()
    private init() {}

    private let eventStore = EKEventStore()
    
    var ekEventStore: EKEventStore {
            eventStore
        }

    @Published private(set) var calendarsById: [String: EKCalendar] = [:]
    @Published private(set) var allDayEventsByDatestamp: [String: [EKEvent]] = [:]
    @Published private(set) var singleDayEventsByDatestamp: [String: [EKEvent]] = [:]

    private var hasLoaded = false

    @MainActor
    func requestAccessAndLoadIfNeeded() {
        guard !hasLoaded else { return }

        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            load()
        case .notDetermined:
            requestAccess()
        default:
            break
        }
    }

    func refresh() {
        load()
    }

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            guard granted else { return }
            Task { @MainActor in
                self.load()
            }
        }
    }

    private func load() {
        hasLoaded = true

        loadCalendars()
        loadAllDayEvents()
        loadSingleDayEvents()
    }

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

    private func loadAllDayEvents() {
        let calendar = Calendar.current

        // Fetch window (adjust if needed)
        let start = calendar.date(byAdding: .month, value: -1, to: Date())!
        let end = calendar.date(byAdding: .year, value: 3, to: Date())!

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let events = eventStore
            .events(matching: predicate)
            .filter { $0.isAllDay }

        var map: [String: [EKEvent]] = [:]

        for event in events {
            for datestamp in expandedDatestamps(for: event) {
                map[datestamp, default: []].append(event)
            }
        }

        allDayEventsByDatestamp = map
    }
    
    private func loadSingleDayEvents() {
        let calendar = Calendar.current

        let start = calendar.date(byAdding: .month, value: -1, to: Date())!
        let end = calendar.date(byAdding: .year, value: 3, to: Date())!

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let events = eventStore
            .events(matching: predicate)
            .filter { !$0.isAllDay }

        var map: [String: [EKEvent]] = [:]

        for event in events {
            let datestamp =
                event.startDate
                    .in(region: .current)
                    .date
                    .datestamp

            map[datestamp, default: []].append(event)
        }

        singleDayEventsByDatestamp = map
    }

    private func expandedDatestamps(for event: EKEvent) -> [String] {
        var results: [String] = []

        let start = event.startDate
            .in(region: .current)
            .dateAtStartOf(.day)

        let end = event.endDate
            .in(region: .current)
            .dateAtStartOf(.day)

        var current = start
        while current <= end {
            results.append(current.date.datestamp)
            current = current + 1.days
        }

        return results
    }

}
