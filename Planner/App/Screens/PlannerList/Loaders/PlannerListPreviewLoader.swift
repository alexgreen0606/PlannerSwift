//
//  PlannerListPreviewLoader.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

/// Loads everything a planner preview needs and structures it into a `PlannerListPreviewContext`.
/// Used by both the planner list and the trip day previews.
///
/// Unlike `PlannerContextLoaderView`, this loader is read-only: it never creates
/// `EkEventPlannerState`s for new calendar events. Placement happens when the planner is opened.
struct PlannerListPreviewLoaderView<Content: View>: View {
    private let datestamp: String
    private let activeQuery: PlannerSearchQuery?
    private let includeTrip: Bool
    private let settings: Settings
    private let content: (Planner, PlannerListPreviewContext) -> Content

    init(
        datestamp: String,
        activeQuery: PlannerSearchQuery? = nil,
        /// False when the preview is already shown within its trip.
        includeTrip: Bool = true,
        settings: Settings,
        @ViewBuilder content: @escaping (Planner, PlannerListPreviewContext) ->
            Content
    ) {
        self.datestamp = datestamp
        self.activeQuery = activeQuery
        self.includeTrip = includeTrip
        self.settings = settings
        self.content = content
    }

    @EnvironmentObject private var calendarService: CalendarService

    // MARK: - Body

    var body: some View {
        PlannerLoaderView(datestamp: datestamp) { planner in
            PlannerPreviewItemLoaderView(
                planner: planner,
                calendarService: calendarService,
                settings: settings
            ) { items in
                content(
                    planner,
                    PlannerListPreviewContext(
                        planner: planner,
                        activeQuery: activeQuery,
                        items: items,
                        includeTrip: includeTrip
                    )
                )
            }
        }
    }
}

// MARK: - Preview Items

/// The raw, unfiltered items of a planner's day.
struct PlannerPreviewItems {
    /// Birthday calendar events, sorted by title.
    let sortedBirthdayItems: [PlannerBirthdayItem]
    /// All-day and multi-day calendar events, sorted by title.
    let sortedChipItems: [PlannerItem]
    /// Timed calendar events that start on this day, paired with their state and sorted by sortDate.
    let sortedEkEventItems: [PlannerItem]
    /// Planner-owned events, sorted by sortDate.
    let sortedPlannerEvents: [PlannerEvent]
}

// MARK: - Preview Item Loader

private struct PlannerPreviewItemLoaderView<Content: View>: View {
    private let planner: Planner
    private let settings: Settings
    private let content: (PlannerPreviewItems) -> Content

    init(
        planner: Planner,
        calendarService: CalendarService,
        settings: Settings,
        @ViewBuilder content: @escaping (PlannerPreviewItems) -> Content
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

        // Note: Unlimited so the preview can count the remaining plans.
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

    private var ekEventReloadKey: String {
        PlannerEkEventLoader.reloadKey(
            startOfDay: startOfDay,
            calendarService: calendarService,
            settings: settings
        )
    }

    private var chipItems: [PlannerItem] {
        ekEventLoader.sortedChipEvents.compactMap {
            PlannerItem(ekEvent: $0, state: nil)
        }
    }

    // MARK: - Body

    var body: some View {
        EkEventPlannerStateLoaderView(
            ekEvents: ekEventLoader.sortedListEvents
        ) { ekEventItems in
            content(
                PlannerPreviewItems(
                    sortedBirthdayItems: ekEventLoader.sortedBirthdayItems,
                    sortedChipItems: chipItems,
                    sortedEkEventItems: ekEventItems.sorted {
                        $0.sortDate < $1.sortDate
                    },
                    sortedPlannerEvents: sortedPlannerEvents
                )
            )
        }
        .onChange(of: ekEventReloadKey) { _, _ in
            ekEventLoader.update(startOfDay: startOfDay)
        }
    }
}
