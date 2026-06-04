//
//  PlannerPreviewCard.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerPreviewCardView<Header: View>: View {
    private let planner: Planner
    private let tripLabel: String?
    private let sortedPlannerEvents: [PlannerEvent]
    private let calendarDayData: CalendarDayData?
    private let header: Header
    private let width: CGFloat
    private let transitionId: String
    private let settings: PlannerSettings
    private let namespace: Namespace.ID

    init(
        planner: Planner,
        tripLabel: String? = nil,
        sortedPlannerEvents: [PlannerEvent],
        calendarDayData: CalendarDayData?,
        header: Header,
        width: CGFloat = PlannerPreviewCardLayout.DEFAULT_WIDTH,
        transitionId: String,
        settings: PlannerSettings,
        namespace: Namespace.ID
    ) {
        self.planner = planner
        self.tripLabel = tripLabel
        self.sortedPlannerEvents = sortedPlannerEvents
        self.calendarDayData = calendarDayData
        self.header = header
        self.width = width
        self.transitionId = transitionId
        self.settings = settings
        self.namespace = namespace
    }

    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    private var filteredPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter {
            !$0.isCompleted
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading) {
            header

            PlannerPreviewView(
                planner: planner,
                tripLabel: tripLabel,
                sortedBirthdays: calendarDayData?.birthdays ?? [],
                sortedChipEvents: calendarDayData?.plannerChipEvents ?? [],
                sortedPlannerEvents: filteredPlannerEvents,
                settings: settings
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            PlannerCardWeatherView(
                planner: planner,
                settings: settings
            )
        }
        .padding()
        .frame(
            width: width,
            height: PlannerPreviewCardLayout.HEIGHT
        )
        .background(
            Color.cardBackground,
            in: RoundedRectangle(
                cornerRadius: PlannerPreviewCardLayout.CORNER_RADIUS
            )
        )
        .matchedTransitionSource(
            id: transitionId,
            in: namespace
        )
        .onTapGesture {
            plannerCoverStore.context = PlannerCoverContext(
                datestamp: planner.datestamp,
                transitionId: transitionId
            )
        }
    }
}
