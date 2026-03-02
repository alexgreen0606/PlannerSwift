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

struct PlannerCalendarData {
    let allDayEvents: [EKEvent]
    let timedEvents: [EKEvent]
}

typealias PlannerDataLoader = (
    _ planner: Planner,
    _ skipCache: Bool,
    _ plannerStartOfDay: DateInRegion,
    _ hiddenCalendarIds: Set<String>
) -> PlannerCalendarData

@MainActor
class CalendarStore: ObservableObject {

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    private let eventStore = EKEventStore()

    @Published var loadTrigger: UUID = UUID()
    @Published var accessDenied: Bool = true

    private var calendarsById: [String: EKCalendar] = [:]
    private var cache: [String: PlannerCalendarData] = [:]

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

    // TODO: is this still needed? Test changing an EKEvent's calendar color
    // More up-to-date than using event.calendar.cgColor directly.
    func calendarColor(for id: String) -> Color {
        guard let calendar = calendarsById[id] else {
            return Color.secondary
        }

        return calendar.color
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

    func loadPlannerData(
        for planner: Planner,
        skipCache: Bool = false,
        plannerStartOfDay: DateInRegion,
        hiddenCalendarIds: Set<String>
    ) -> PlannerCalendarData {

        let plannerKey = planner.key

        // Return cached data.
        if !skipCache, let existingData = cache[plannerKey] {
            return existingData
        }

        let plannerRegion = plannerStartOfDay.region
        let plannerDatestamp = planner.datestamp
        let startOfNextPlannerDay = plannerStartOfDay + 1.days

        let predicate = eventStore.predicateForEvents(
            withStart: plannerStartOfDay.date,
            end: startOfNextPlannerDay.date,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        var allDayEvents: [EKEvent] = []
        var timedEvents: [EKEvent] = []

        for event in events {

            if hiddenCalendarIds.contains(event.calendar.calendarIdentifier) {
                continue
            }

            if event.isAllDay {
                allDayEvents.append(event)
            } else {
                let startDatestamp = DateInRegion(
                    event.startDate,
                    region: plannerRegion
                ).datestamp
                let endDatestamp = DateInRegion(
                    event.endDate,
                    region: plannerRegion
                ).datestamp

                if startDatestamp != endDatestamp {
                    allDayEvents.append(event)

                    if startDatestamp == plannerDatestamp {
                        timedEvents.append(event)
                    }

                    continue
                }

                timedEvents.append(event)
            }
        }

        let newData = PlannerCalendarData(
            allDayEvents: allDayEvents,
            timedEvents: timedEvents
        )

        cache[plannerKey] = newData
        return newData
    }

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
