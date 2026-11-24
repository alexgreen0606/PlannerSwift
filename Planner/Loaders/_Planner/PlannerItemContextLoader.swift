//
//  PlannerItemContextLoader.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerItemContext {
    /// Planner-owned events and calendar events, merged and sorted by sortDate.
    let sortedListItems: [PlannerItem]
    /// All-day and multi-day calendar events, read directly from EventKit and sorted by title.
    let sortedChipItems: [PlannerItem]
    /// Birthday calendar events, read directly from EventKit  and sorted by title.
    let sortedBirthdayItems: [PlannerBirthdayItem]
}

struct PlannerItemContextLoaderView<Content: View>: View {
    private let planner: Planner
    private let settings: Settings
    private let content: (PlannerItemContext) -> Content

    init(
        planner: Planner,
        calendarService: CalendarService,
        settings: Settings,
        @ViewBuilder content: @escaping (PlannerItemContext) -> Content
    ) {
        self.planner = planner
        self.settings = settings
        self.content = content

        let startOfDay = planner.startOfDay(settings: settings)

        _ekEventLoader = StateObject(
            wrappedValue: PlannerEkEventLoader(
                calendarService: calendarService,
                settings: settings,
                startOfDay: startOfDay
            )
        )

        _sortedPlannerEvents = Query(
            filter: PlannerEvent.listEvents(on: startOfDay),
            sort: \.sortDate
        )
    }

    @EnvironmentObject private var calendarService: CalendarService

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @StateObject private var ekEventLoader: PlannerEkEventLoader

    private var startOfDay: DateInRegion {
        planner.startOfDay(settings: settings)
    }

    // TODO: this won't be needed once we have a function to convert ekEventContexts to new state approach.
    /// Planner-owned events only. Calendar events (including chips) are read directly from EventKit.
    private var sortedOwnedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { $0.eKEventContext == nil }
    }

    // TODO: why reload with this key type?
    private var ekEventReloadKey: String {
        // Note: Uses the same calendars as the loader, so the key is already stable on the first render
        // and doesn't trigger a reload when `CalendarService` finishes loading.
        let calendarIds = PlannerEkEventLoader.visibleCalendars(
            calendarService: calendarService,
            settings: settings
        )
        .map(\.calendarIdentifier)
        .sorted()
        .joined(separator: ",")

        return "\(startOfDay.date.timeIntervalSince1970)|\(calendarIds)"
    }

    /// Chips carry no Planner-only data, so they never need an `EkEventPlannerState`.
    private var chipItems: [PlannerItem] {
        ekEventLoader.sortedChipEvents.compactMap {
            PlannerItem(
                ekEvent: $0,
                state: nil
            )
        }
    }

    // MARK: - Body

    var body: some View {
        EkEventPlannerStateLoaderView(
            ekEvents: ekEventLoader.sortedListEvents
        ) { ekEventItems in
            content(
                PlannerItemContext(
                    sortedListItems: mergeItems(ekEventItems),
                    sortedChipItems: chipItems,
                    sortedBirthdayItems: ekEventLoader.sortedBirthdayItems
                )
            )
        }
        .onChange(of: ekEventReloadKey) { _, _ in
            ekEventLoader.update(startOfDay: startOfDay)
        }
    }

    // MARK: - Functions

    private func mergeItems(_ ekEventItems: [PlannerItem])
        -> [PlannerItem]
    {
        (sortedOwnedPlannerEvents.map { PlannerItem(plannerEvent: $0) }
            + ekEventItems)
            .sorted {
                $0.sortDate < $1.sortDate
            }
    }
}

// MARK: - Calendar Event Planner State Loader

/// Pairs each calendar event with its persisted Planner state (if any).
private struct EkEventPlannerStateLoaderView<Content: View>: View {
    private let ekEvents: [EKEvent]
    private let content: ([PlannerItem]) -> Content

    init(
        ekEvents: [EKEvent],
        @ViewBuilder content: @escaping ([PlannerItem]) -> Content
    ) {
        self.ekEvents = ekEvents
        self.content = content

        let externalIdentifiers = Array(
            Set(ekEvents.compactMap(\.calendarItemExternalIdentifier))
        )

        // TODO: make this a predicate by itself
        _states = Query(
            filter: #Predicate<EkEventPlannerState> { state in
                externalIdentifiers.contains(state.externalIdentifier)
            }
        )
    }

    @Query private var states: [EkEventPlannerState]

    private var items: [PlannerItem] {
        let statesByExternalIdentifier = Dictionary(
            grouping: states,
            by: \.externalIdentifier
        )

        return ekEvents.compactMap { ekEvent in
            let state = statesByExternalIdentifier[
                ekEvent.calendarItemExternalIdentifier
            ]?.first {
                $0.recurrenceOccurrenceDate == ekEvent.occurrenceDate
            }

            return PlannerItem(
                ekEvent: ekEvent,
                state: state
            )
        }
    }

    // MARK: - Body

    var body: some View {
        content(items)
    }
}
