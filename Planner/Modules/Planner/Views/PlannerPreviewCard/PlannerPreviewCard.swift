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
    let datestamp: String
    let header: Header
    let width: CGFloat
    let settings: PlannerSettings
    let namespace: Namespace.ID
    let transitionId: String

    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    var body: some View {
        PlannerLoaderView(datestamp: datestamp, settings: settings) { context in
            VStack(alignment: .leading) {
                header

                if let calendarDayData = context.calendarDayData {
                    PlannerPreviewView(
                        type: .planner,
                        searchQuery: nil, // TODO: make this optional
                        header: EmptyView(),
                        planner: context.planner,
                        plannerDay: context.plannerDay,
                        plannerLocation: context.plannerLocation,
                        plannerEvents: context.sortedPlannerEvents,
                        calendarDayData: calendarDayData, // TODO: allow this to be nil
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
                width: width,
                height: PlannerLayout.PREVIEW_CARD_HEIGHT,
                alignment: .top
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
            )
            .matchedTransitionSource(
                id: transitionId,
                in: namespace
            )
            .contentShape(Rectangle())
            .onTapGesture {
                plannerCoverStore.context = PlannerCoverContext(
                    datestamp: datestamp,
                    source: transitionId
                )
            }
        }
    }
}
