//
//  PlannerContentPreview.swift
//  Planner
//
//  Created by Alex Green on 11/16/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerContentPreviewView: View {
    private let planner: Planner
    private let settings: Settings

    init(
        planner: Planner,
        activeQuery: PlannerSearchQuery? = nil,
        sortedBirthdayEvents: [PlannerEvent],
        sortedEventChips: [PlannerEvent],
        sortedPlannerEvents: [PlannerEvent],
        settings: Settings
    ) {
        self.planner = planner
        self.settings = settings

        self.context = StructuredPlannerPreviewContext(
            planner: planner,
            activeQuery: activeQuery,
            sortedBirthdayEvents: sortedBirthdayEvents,
            sortedEventChips: sortedEventChips,
            sortedPlannerEvents: sortedPlannerEvents
        )
    }

    private let context: StructuredPlannerPreviewContext

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerService: PlannerService

    private var startOfDay: DateInRegion {
        planner.startOfDay(settings: settings)
    }

    private var isSearching: Bool {
        plannerService.activeQuery != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tripInfo
            birthdayChipList
            eventChipList
            PlannerEventListView(
                plannerDatestamp: planner.datestamp,
                plannerRegion: startOfDay.region,
                events: context.plannerEvents,
                hideLowerDivider: isSearching,
                settings: settings
            )
            remainingPlansIndicator
            emptyPlannerIndicator
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var tripInfo: some View {
        if let tripLabel = context.tripLabel {
            AdornedValue(
                tripLabel,
                iconConfig: IconConfig(name: "suitcase")
            )
        }
    }

    private var birthdayChipList: some View {
        ForEach(
            context.birthdayEvents
        ) {
            BirthdayLabelView(
                plannerEvent: $0,
                settings: settings
            )
        }
    }

    private var eventChipList: some View {
        ForEach(
            context.chipEvents
        ) { event in
            let calendarColor = event.calendarColor(accentColor: accentColor)
            AdornedValue(
                event.title,
                iconConfig: IconConfig(
                    name: event.calendarSystemImageName(settings: settings),
                    primaryColor: calendarColor,
                    secondaryColor: calendarColor
                ),
                color: .label
            )
        }
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if context.hasItems && !isSearching {
            EmptyLabel(context.remainingPlansLabel, scale: 0.8)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if !isSearching {
            ZStack {
                if !context.hasItems {
                    EmptyLabel(context.remainingPlansLabel, scale: 0.8)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
}
