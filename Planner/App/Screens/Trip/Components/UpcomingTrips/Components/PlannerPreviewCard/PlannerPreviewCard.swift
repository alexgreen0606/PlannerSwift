//
//  PlannerPreviewCard.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftUI

struct PlannerPreviewCardView<Header: View>: View {
    let planner: Planner
    let context: PlannerPreviewContext
    let header: Header
    let defaultLocationLabel: String?
    let transitionId: String
    let settings: Settings
    let namespace: Namespace.ID

    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading) {
            header

            PlannerPreviewContentView(
                planner: planner,
                context: context,
                settings: settings
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            PlannerCardWeatherView(
                planner: planner,
                customDefaultLocationLabel: defaultLocationLabel,
                settings: settings
            )
        }
        .padding()
        .frame(
            width: PlannerPreviewCardLayout.DEFAULT_WIDTH,
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
