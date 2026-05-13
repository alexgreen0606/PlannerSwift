//
//  TripDayPreviewCard.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct TripDayPreviewCardView: View {
    let datestamp: String
    let index: Int
    let trip: Trip
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    var body: some View {
        PlannerLoaderView(datestamp: datestamp, settings: settings) { context in
            VStack(alignment: .leading) {

                PlannerHeaderView(
                    datestamp: datestamp,
                    title: "Day \(index + 1)",
                    subtitle: datestamp.weekday,
                    iconFormat: .shortMonth
                )

                if let calendarDayData = context.calendarDayData {
                    PlannerPreviewView(
                        type: .trip,
                        searchQuery: nil,
                        header: EmptyView(),
                        planner: context.planner,
                        plannerDay: context.plannerDay,
                        plannerLocation: context.plannerLocation,
                        plannerEvents: context.sortedPlannerEvents,
                        calendarDayData: calendarDayData,  // TODO: allow this to be nil
                        settings: settings
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                }

                PlannerCardWeatherView(
                    planner: context.planner,
                    plannerDay: context.plannerDay,
                    plannerLocation: context.plannerLocation,
                    settings: settings
                )
            }
            .padding()
            .frame(
                width: 240,
                height: PlannerLayout.PREVIEW_CARD_HEIGHT,
                alignment: .top
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
            )
            .matchedTransitionSource(
                id: trip.transitionId(
                    for: datestamp
                ),
                in: namespace
            )
            .contentShape(Rectangle())
            .onTapGesture {
                plannerCoverStore.context = PlannerCoverContext(
                    datestamp: datestamp,
                    source: trip.transitionId(
                        for: datestamp
                    )
                )
            }
        }
    }

}
