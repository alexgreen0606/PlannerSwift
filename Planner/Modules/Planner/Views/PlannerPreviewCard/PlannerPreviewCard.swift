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
    private let variant: PlannerPreviewVariant
    private let datestamp: String
    private let header: Header
    private let width: CGFloat
    private let transitionId: String
    private let settings: PlannerSettings
    private let namespace: Namespace.ID

    init(
        variant: PlannerPreviewVariant,
        datestamp: String,
        header: Header,
        width: CGFloat = PlannerPreviewCardLayout.DEFAULT_WIDTH,
        transitionId: String,
        settings: PlannerSettings,
        namespace: Namespace.ID
    ) {
        self.variant = variant
        self.datestamp = datestamp
        self.header = header
        self.width = width
        self.transitionId = transitionId
        self.settings = settings
        self.namespace = namespace
    }

    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    // MARK: - Body

    var body: some View {
        PlannerContextLoaderView(datestamp: datestamp, settings: settings) {
            context in
            VStack(alignment: .leading) {
                header

                PlannerPreviewView(
                    variant: variant,
                    planner: context.planner,
                    tripLabel: tripLabel(for: context.planner),
                    sortedBirthdays: context.eventContext.calendarDayData?
                        .birthdays ?? [],
                    sortedChipEvents: context.eventContext.calendarDayData?
                        .plannerChipEvents ?? [],
                    sortedPlannerEvents: context.eventContext
                        .sortedPlannerEvents,
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
                    datestamp: datestamp,
                    transitionId: transitionId
                )
            }
        }
    }

    // MARK: - Functions

    private func tripLabel(for planner: Planner) -> String? {
        if variant == .trip {
            return nil
        }

        return planner.trip?.title
    }
}
