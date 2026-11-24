//
//  PlannerEventContextLoader.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import Contacts
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerEventContextLoaderView_old<Content: View>: View {
    private let planner: Planner
    private let settings: Settings
    private var content: (PlannerEventContext_old) -> Content

    init(
        planner: Planner,
        plannerService: PlannerService,
        settings: Settings,
        @ViewBuilder content:
            @escaping (PlannerEventContext_old) -> Content
    ) {
        self.planner = planner
        self.settings = settings
        self.content = content

        let startOfDay = planner.startOfDay(settings: settings)

        _sortedPlannerEvents = Query(
            filter: PlannerEvent.listEvents(
                on: startOfDay
            ),
            sort: \.sortDate
        )

        _sortedChipItems = Query(
            filter: PlannerEvent.eventChips(on: startOfDay),
            sort: [
                SortDescriptor(
                    \PlannerEvent.title,
                    comparator: .localizedStandard
                )
            ]
        )

        _sortedBirthdayItems = Query(
            filter: PlannerEvent.birthdayChips(on: startOfDay),
            sort: [
                SortDescriptor(
                    \PlannerEvent.title,
                    comparator: .localizedStandard
                )
            ]
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    @Query private var sortedPlannerEvents: [PlannerEvent]
    @Query private var sortedChipItems: [PlannerEvent]
    @Query private var sortedBirthdayItems: [PlannerEvent]

    private var plannerLocation: Location? {
        planner.location(
            settings: settings
        )
    }

    // MARK: Filter for special case all-day events.

    private var safeEventChips: [PlannerEvent] {
        filterAllDayEvents(sortedChipItems)
    }

    private var safeBirthdayChips: [PlannerEvent] {
        filterAllDayEvents(sortedBirthdayItems)
    }

    // MARK: - Body

    var body: some View {
        content(
            PlannerEventContext_old(
                sortedPlannerEvents: sortedPlannerEvents,
                sortedChipItems: safeEventChips,
                sortedBirthdayItems: safeBirthdayChips,
            )
        )
    }

    // MARK: - Functions

    private func filterAllDayEvents(_ events: [PlannerEvent]) -> [PlannerEvent]
    {
        events.filter {
            $0.belongsIn(datestamp: planner.datestamp)
        }
    }
}
