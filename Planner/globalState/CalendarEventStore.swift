//
//  CalendarEventStore.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Foundation
import Combine
import EventKit
import SwiftUI

@MainActor
final class CalendarEventStore: ObservableObject {

    // MARK: - EventKit

    private let eventStore = EKEventStore()
    
    var ekEventStore: EKEventStore {
            eventStore
        }

    // MARK: - Published Maps

    /// Calendar ID → EKCalendar
    @Published private(set) var calendarsById: [String: EKCalendar] = [:]

    /// YYYY-MM-DD → [EKEvent]
    @Published private(set) var allDayEventsByDatestamp: [String: [EKEvent]] = [:]

    // MARK: - State

    private var hasLoaded = false

    // MARK: - Public API

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

    // MARK: - Permissions

    private func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            guard granted else { return }
            Task { @MainActor in
                self.load()
            }
        }
    }

    // MARK: - Load

    private func load() {
        hasLoaded = true

        loadCalendars()
        loadAllDayEvents()
    }

    // MARK: - Calendars

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

    // MARK: - Events

    private func loadAllDayEvents() {
        let calendar = Calendar.current

        // Fetch window (adjust if needed)
        let start = calendar.date(byAdding: .year, value: -1, to: Date())!
        let end = calendar.date(byAdding: .year, value: 1, to: Date())!

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

    // MARK: - Helpers

    /// Expands a multi-day all-day event into individual YYYY-MM-DD keys
    private func expandedDatestamps(for event: EKEvent) -> [String] {
        let calendar = Calendar.current
        var results: [String] = []

        // Use the calendar in UTC to avoid TZ issues
        var current = calendar.startOfDay(for: event.startDate)
        let end = calendar.startOfDay(for: event.endDate.addingTimeInterval(-1)) // subtract 1 sec

        while current <= end { // inclusive
            results.append(current.datestamp)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return results
    }

}
