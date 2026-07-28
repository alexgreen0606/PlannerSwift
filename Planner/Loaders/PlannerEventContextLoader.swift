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

struct PlannerEventContextLoaderView<Content: View>: View {
    private let planner: Planner
    private let settings: Settings
    private var content: (PlannerEventContext) -> Content

    init(
        planner: Planner,
        plannerService: PlannerService,
        settings: Settings,
        @ViewBuilder content:
            @escaping (PlannerEventContext) -> Content
    ) {
        self.planner = planner
        self.settings = settings
        self.content = content

        let startOfDay = planner.startOfDay(settings: settings)

        _sortedPlannerEvents = Query(
            filter: PlannerEvent.listEvents(on: startOfDay),
            sort: \.sortDate
        )

        _sortedEventChips = Query(
            filter: PlannerEvent.eventChips(on: startOfDay),
            sort: [
                SortDescriptor(
                    \PlannerEvent.title,
                    comparator: .localizedStandard
                )
            ]
        )

        _sortedBirthdayChips = Query(
            filter: PlannerEvent.birthdayChips(on: startOfDay),
            sort: [
                SortDescriptor(
                    \PlannerEvent.title,
                    comparator: .localizedStandard
                )
            ]
        )

        self.startOfDay = startOfDay
    }

    private let startOfDay: DateInRegion

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    @Query private var sortedPlannerEvents: [PlannerEvent]
    @Query private var sortedEventChips: [PlannerEvent]
    @Query private var sortedBirthdayChips: [PlannerEvent]

    private var plannerLocation: Location? {
        planner.location(
            settings: settings
        )
    }

    // MARK: - Body

    var body: some View {
        content(
            PlannerEventContext(
                sortedPlannerEvents: sortedPlannerEvents,
                sortedEventChips: sortedEventChips,
                sortedBirthdayChips: sortedBirthdayChips
            )
        )
    }
}
