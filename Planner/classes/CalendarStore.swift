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

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    private let eventStore = EKEventStore()
    private var calendarsById: [String: EKCalendar] = [:]
    
    @Published  var cache: [String: [EKEvent]] = [:]
    @Published var loadTrigger: UUID = UUID()
    @Published var accessDenied: Bool = true

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

    func loadFreshCache(
        hiddenCalendarIds: Set<String>
    ) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            accessDenied = false
            beginCacheRefresh(
                hiddenCalendarIds: hiddenCalendarIds
            )
        case .notDetermined:
            requestAccess(
                hiddenCalendarIds: hiddenCalendarIds
            )
        case .denied:
            accessDenied = true
        default:
            break
        }
    }

    // MARK: - Helper Functions

    private func requestAccess(hiddenCalendarIds: Set<String>) {
        eventStore.requestFullAccessToEvents { granted, error in
            Task { @MainActor in
                if granted {
                    self.accessDenied = false
                    self.beginCacheRefresh(hiddenCalendarIds: hiddenCalendarIds)
                } else {
                    self.accessDenied = true
                }
            }
        }
    }

    private func beginCacheRefresh(hiddenCalendarIds: Set<String>) {
        loadCalendars()
        cache = [:]
        loadTrigger = UUID()
    }

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

}
