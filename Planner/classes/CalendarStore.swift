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
    private var cache: [String: [EKEvent]] = [:]

    @Published var loadTrigger: UUID = UUID()
    @Published var accessDenied: Bool = true

    // @Environment(\.modelContext) private var modelContext

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

    // Returns a list of all-day events.
    // Timed events will be synced to the store.
    func syncCalendarEvents(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerStartOfDay: DateInRegion,
        hiddenCalendarIds: Set<String>,
        modelContext: ModelContext
    ) -> [EKEvent] {

        let plannerKey = planner.key

        // Return cached data.
        if let existingData = cache[plannerKey] {
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

        var existingStorageCalendarEvents: [String: PlannerEvent] = [:]
        for event in storageEvents
        where event.calendarItemExternalIdentifier != nil {
            existingStorageCalendarEvents[
                event.calendarItemExternalIdentifier!
            ] = event
        }

        // Updates the calendar event if it exists in this planner, otherwise it is added in.
        func upsertCalendarEvent(_ calendarEvent: EKEvent) {
            guard
                let storageEvent = existingStorageCalendarEvents[
                    calendarEvent.calendarItemExternalIdentifier
                ]
            else {
                modelContext.addCalendarEventToPlanner(
                    calendarEvent,
                    plannerStartOfDay: plannerStartOfDay
                )
                return
            }

            existingStorageCalendarEvents.removeValue(
                forKey: calendarEvent.calendarItemExternalIdentifier
            )

            storageEvent.syncWithCalendarEvent(calendarEvent)
        }

        // Sort events in reverse order so they are chronological at the top of their planners.
        let events = eventStore.events(matching: predicate).sorted {
            $0.startDate > $1.startDate
        }

        var allDayEvents: [EKEvent] = []

        for event in events {

            if hiddenCalendarIds.contains(event.calendar.calendarIdentifier) {
                continue
            }

            if event.isAllDay {
                allDayEvents.append(event)

                if let storageEvent = existingStorageCalendarEvents[
                    event.calendarItemExternalIdentifier
                ] {
                    // The event was previously timed. Remove it from this planner.
                    modelContext.delete(storageEvent)

                    existingStorageCalendarEvents.removeValue(
                        forKey: event.calendarItemExternalIdentifier
                    )
                }
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

                    // Event is multi-day.
                    allDayEvents.append(event)

                    if startDatestamp == plannerDatestamp {

                        // This is the first day of the event.
                        upsertCalendarEvent(event)

                    }

                } else {
                    upsertCalendarEvent(event)
                }

            }
        }

        // Update any stale calendar events from this planner.
        updateStorageEvents(
            Array(existingStorageCalendarEvents.values),
            modelContext: modelContext
        )

        cache[plannerKey] = allDayEvents
        return allDayEvents
    }

    func updateStorageEvents(
        _ storageEvents: [PlannerEvent],
        modelContext: ModelContext
    ) {
        for storageEvent in storageEvents {
            guard
                let externalIdentifier = storageEvent
                    .calendarItemExternalIdentifier
            else {
                continue
            }

            // TODO: will it always be first event?
            guard
                let calendarEvent = ekEventStore.calendarItems(
                    withExternalIdentifier: externalIdentifier
                ).first as? EKEvent,
                calendarEvent.isAllDay == false
            else {
                modelContext.delete(storageEvent)
                continue
            }

            storageEvent.syncWithCalendarEvent(calendarEvent)
        }
    }

}
