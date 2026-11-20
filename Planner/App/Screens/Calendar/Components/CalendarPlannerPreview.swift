//
//  CalendarPlannerPreview.swift
//  Planner
//
//  Created by Alex Green on 11/14/26.
//

import SwiftData
import SwiftUI

struct CalendarPlannerPreviewView: View {
    @Binding var contextCache: [String: StructuredPlannerPreviewContext]
    let datestamp: String
    let isScrolling: Bool
    let height: CGFloat
    let settings: Settings
    let namespace: Namespace.ID

    private let BORDER_RADIUS: CGFloat = 8
    private let TEXT_SCALE = 0.6

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerService: PlannerService

    private var isToday: Bool {
        datestamp == todayService.todaystamp
    }

    private var hasLoadedContent: Bool {
        !isScrolling || contextCache[datestamp] != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(datestamp.dayDigit ?? 0))
                .fontWeight(.heavy)
                .fontDesign(.rounded)
                .foregroundStyle(isToday ? Color.inverseLabel : Color.label)
                .frame(maxWidth: .infinity)
                .opacity(isToday || hasLoadedContent ? 1 : 0.2)
                .background {
                    if isToday {
                        UnevenRoundedRectangle(
                            topLeadingRadius: BORDER_RADIUS,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: BORDER_RADIUS
                        )
                        .fill(accentColor.swiftUiColor)
                    }
                }

            if !isScrolling {
                PlannerContextLoaderView(
                    datestamp: datestamp,
                    settings: settings
                ) { plannerContext in
                    ZStack {
                        let context = structuredPlannerPreviewContext(
                            for: plannerContext
                        )

                        content(context)
                            .onDisappear {
                                contextCache[datestamp] = context
                            }
                    }
                }
            } else if let cachedContext = contextCache[datestamp] {
                content(cachedContext)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .clipped()
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: BORDER_RADIUS)
                    .strokeBorder(accentColor.swiftUiColor, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tertiary)
                .frame(height: 1)
        }
        .matchedTransitionSource(
            id: datestamp,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture {
            plannerCoverStore.context = PlannerCoverContext(
                datestamp: datestamp
            )
        }
    }

    // MARK: - View Builders

    private func content(_ context: StructuredPlannerPreviewContext)
        -> some View
    {
        VStack(spacing: 3) {
            VStack(alignment: .leading, spacing: 2) {
                tripInfo(context)
                birthdayChipList(context)
                eventChipList(context)
                plannerEventList(context)
            }
            .padding(.leading, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.7),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }

            if context.remainingItemCount > 0 {
                Text("+\(context.remainingItemCount)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func tripInfo(_ context: StructuredPlannerPreviewContext)
        -> some View
    {
        if let tripLabel = context.tripLabel {
            AdornedValue(
                tripLabel,
                iconConfig: IconConfig(name: "suitcase"),
                lineLimit: 1,
                scale: TEXT_SCALE
            )
        }
    }

    private func birthdayChipList(_ context: StructuredPlannerPreviewContext)
        -> some View
    {
        ForEach(
            context.birthdayEvents
        ) {
            BirthdayLabelView(
                plannerEvent: $0,
                lineLimit: 1,
                scale: TEXT_SCALE,
                settings: settings
            )
        }
    }

    private func eventChipList(_ context: StructuredPlannerPreviewContext)
        -> some View
    {
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
                lineLimit: 1,
                color: .label,
                scale: TEXT_SCALE
            )
        }
    }

    @ViewBuilder
    private func plannerEventList(_ context: StructuredPlannerPreviewContext)
        -> some View
    {
        ForEach(
            context.plannerEvents
        ) { event in
            HStack(spacing: Layout.DEFAULT_ADORNMENT_SPACING * TEXT_SCALE) {
                let iconConfig: IconConfig? = {
                    guard event.eKEventContext != nil else {
                        return nil
                    }

                    let calendarColor = event.calendarColor(
                        accentColor: accentColor
                    )

                    return IconConfig(
                        name: event.calendarSystemImageName(settings: settings),
                        primaryColor: calendarColor,
                        secondaryColor: calendarColor
                    )
                }()

                if event.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: Layout.TEXT * TEXT_SCALE))
                }

                AdornedValue(
                    event.title,
                    iconConfig: iconConfig,
                    lineLimit: 1,
                    color: .label,
                    scale: TEXT_SCALE
                )
            }
        }
    }

    // MARK: - Functions

    func structuredPlannerPreviewContext(
        for plannerContext: PlannerContext
    ) -> StructuredPlannerPreviewContext {
        StructuredPlannerPreviewContext(
            planner: plannerContext.planner,
            activeQuery: plannerService.activeQuery,
            sortedBirthdayEvents: plannerContext.eventContext
                .sortedBirthdayChips,
            sortedEventChips: plannerContext.eventContext
                .sortedEventChips,
            sortedPlannerEvents: plannerContext.eventContext
                .sortedPlannerEvents.filterOutRoutineUnlessSearching(
                    activeQuery: plannerService.activeQuery
                ),
            maxPreviewSlots: 4
        )
    }
}
