//
//  CalendarStore.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Combine
import EventKit
import SwiftDate
import SwiftUI

struct PlannerData {
    let allDayEvents: [EKEvent]
    let timedEvents: [EKEvent]
}

@MainActor
class CalendarStore: ObservableObject {

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    private let eventStore = EKEventStore()

    @Published private(set) var calendarsById: [String: EKCalendar] = [:]

    @Published private(set) var plannerData: [String: PlannerData] = [:]
    
    @Published private(set) var loadedPlannerKeys: Set<String> = []

    // TODO: we can no longer use this. We aren't loading in all existing events
    @Published private(set) var existingEventIds: Set<String> = []

    @Published var loadId: UUID = UUID()
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

    @MainActor
    func requestAccessAndLoad(
        hiddenCalendarIds: Set<String>
    ) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            accessDenied = false
            load(
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

    @MainActor
    func refresh(hiddenCalendarIds: Set<String>) {
        requestAccessAndLoad(hiddenCalendarIds: hiddenCalendarIds)
    }

    // More up-to-date than using event.calendar.cgColor directly.
    func calendarColor(for id: String) -> Color {
        guard let calendar = calendarsById[id] else {
            return Color.secondary
        }

        return calendar.color
    }
    
    func allDayEvents(for planner: Planner) -> [EKEvent] {
        plannerData[planner.key]?.allDayEvents ?? []
    }
    
    func timedEvents(for planner: Planner) -> [EKEvent] {
        plannerData[planner.key]?.timedEvents ?? []
    }

    private func requestAccess(hiddenCalendarIds: Set<String>) {
        eventStore.requestFullAccessToEvents { granted, error in
            Task { @MainActor in
                if granted {
                    self.accessDenied = false
                    self.load(hiddenCalendarIds: hiddenCalendarIds)
                } else {
                    self.accessDenied = true
                }
            }
        }
    }

    private func load(hiddenCalendarIds: Set<String>) {
        loadCalendars()
        loadedPlannerKeys = []
        loadId = UUID()
    }

    private func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)

        calendarsById = Dictionary(
            uniqueKeysWithValues: calendars.map { ($0.calendarIdentifier, $0) }
        )
    }

    @MainActor
    func ensurePlannerData(
        plannerKey: String,
        startOfDay: DateInRegion,
        hiddenCalendarIds: Set<String>
    ) {

        // Exit if the planner data has already been loaded.
        if loadedPlannerKeys.contains(plannerKey) {
            return
        } else {
            loadedPlannerKeys.insert(plannerKey)
        }

        let startOfNextDay = startOfDay + 1.days

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay.date,
            end: startOfNextDay.date,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        var allDayEvents: [EKEvent] = []
        var timedEvents: [EKEvent] = []

        for event in events {
            existingEventIds.insert(event.calendarItemExternalIdentifier)

            if hiddenCalendarIds.contains(event.calendar.calendarIdentifier) {
                continue
            }

            if event.isAllDay {
                allDayEvents.append(event)
            } else {
                timedEvents.append(event)
            }
        }

        let newData = PlannerData(
            allDayEvents: allDayEvents,
            timedEvents: timedEvents
        )
        
        plannerData[plannerKey] = newData
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

    @MainActor
    func transfer(event: EKEvent, into date: Date) {
        guard event.calendar.allowsContentModifications else {
            print("Cannot transfer event. Calendar is read-only.")
            return
        }

        do {
            // TODO: transfer event start date to new date. Maintain time range.
        } catch {
            assertionFailure("Failed to transfer event: \(error)")
        }
    }
    
    func doesPlannerHaveData(key: String) -> Bool {
        loadedPlannerKeys.contains(key) && plannerData[key] != nil
    }

}
