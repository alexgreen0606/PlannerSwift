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
    private let type: PlannerPreviewType
    let datestamp: String
    let header: Header
    let width: CGFloat
    let settings: PlannerSettings
    let namespace: Namespace.ID
    let transitionId: String

    init(
        type: PlannerPreviewType,
        datestamp: String,
        header: Header,
        width: CGFloat = PlannerPreviewCardLayout.DEFAULT_WIDTH,
        settings: PlannerSettings,
        namespace: Namespace.ID,
        transitionId: String
    ) {
        self.type = type
        self.datestamp = datestamp
        self.header = header
        self.width = width
        self.settings = settings
        self.namespace = namespace
        self.transitionId = transitionId
    }

    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    var body: some View {
        PlannerContextLoaderView(datestamp: datestamp, settings: settings) {
            context in
            VStack(alignment: .leading) {
                header

                PlannerPreviewView(
                    type: type,
                    planner: context.planner,
                    plannerEvents: context.eventContext.sortedPlannerEvents,
                    calendarDayData: context.eventContext.calendarDayData,
                    settings: settings
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

                PlannerCardWeatherView(
                    planner: context.planner,
                    settings: settings
                )
            }
            .padding()
            .frame(
                width: width,
                height: PlannerPreviewCardLayout.HEIGHT,
                alignment: .top
            )
            .background(
                RoundedRectangle(
                    cornerRadius: PlannerPreviewCardLayout.CORNER_RADIUS
                )
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
                    transitionId: transitionId
                )
            }
        }
    }
}
