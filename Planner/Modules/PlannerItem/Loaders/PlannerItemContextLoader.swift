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

    @Environment(\.modelContext) private var modelContext
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

    // Refreshes the calendar events when the planner's 24-hour window moves, and/or when the visible calendars change.
    private var ekEventReloadKey: String {
        PlannerEkEventLoader.reloadKey(
            startOfDay: startOfDay,
            calendarService: calendarService,
            settings: settings
        )
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
            let sortedListItems = mergeItems(ekEventItems)

            content(
                PlannerItemContext(
                    sortedListItems: sortedListItems,
                    sortedChipItems: chipItems,
                    sortedBirthdayItems: ekEventLoader.sortedBirthdayItems
                )
            )
            .onChange(
                of: unplacedEkEventItemIds(ekEventItems),
                initial: true
            ) { _, unplacedIds in
                guard !unplacedIds.isEmpty else { return }

                modelContext.placeNewEkEventItems(
                    in: sortedListItems,
                    startOfDay: startOfDay
                )
            }
        }
        .onChange(of: ekEventReloadKey) { _, _ in
            ekEventLoader.update(startOfDay: startOfDay)
        }
    }

    // MARK: - Functions

    /// Calendar events that don't have an `EkEventPlannerState` yet (i.e. newly-created events).
    private func unplacedEkEventItemIds(_ ekEventItems: [PlannerItem])
        -> [PlannerItemID]
    {
        ekEventItems
            .filter { $0.ekEventPlannerState == nil }
            .map(\.id)
    }

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
