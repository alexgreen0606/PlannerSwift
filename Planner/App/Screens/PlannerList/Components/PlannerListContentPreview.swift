//
//  PlannerListContentPreview.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import SwiftDate
import SwiftUI

struct PlannerListContentPreviewView: View {
    let planner: Planner
    let context: PlannerListPreviewContext
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

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
            birthdayList
            chipList
            PlannerListItemPreviewList(
                plannerDatestamp: planner.datestamp,
                plannerRegion: startOfDay.region,
                items: context.listItems,
                hideLowerDivider: isSearching,
                settings: settings
            )
            remainingPlansIndicator
            emptyPlannerIndicator
        }
        .padding(.top, 8)
    }

    // MARK: - View Builders

    @ViewBuilder
    private var tripInfo: some View {
        if let tripLabel = context.tripLabel {
            AdornedValue(
                tripLabel,
                iconConfig: IconConfig(name: "suitcase")
            )
        }
    }

    private var birthdayList: some View {
        ForEach(context.birthdayItems) {
            BirthdayLabelView(chip: $0, settings: settings)
        }
    }

    private var chipList: some View {
        ForEach(context.chipItems) { item in
            if let ekEvent = item.ekEvent {
                let calendarColor = ekEvent.calendarColor(
                    accentColor: accentColor
                )

                AdornedValue(
                    item.title,
                    iconConfig: IconConfig(
                        name: ekEvent.calendarSystemImageName(
                            settings: settings
                        ),
                        primaryColor: calendarColor,
                        secondaryColor: calendarColor
                    ),
                    color: .label
                )
            }
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

// MARK: - List Item Preview List

private struct PlannerListItemPreviewList: View {
    let plannerDatestamp: String
    let plannerRegion: Region
    let items: [PlannerItem]
    let hideLowerDivider: Bool
    let settings: Settings

    @Environment(\.displayScale) private var displayScale

    // MARK: - Body

    var body: some View {
        ForEach(items) { item in
            HStack(alignment: .top) {
                Group {
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                    }

                    PlannerItemCalendarAdornmentView(
                        item: item,
                        settings: settings
                    )
                }
                .imageScale(.small)
                .frame(height: 17)

                Value(item.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PlannerItemTimeAdornmentView(
                    item: item,
                    plannerDatestamp: plannerDatestamp,
                    plannerRegion: plannerRegion,
                    scale: 0.8
                )
                .frame(height: 17)
            }

            if !hideLowerDivider || item.id != items.last?.id {
                dashedDivider
            }
        }
    }

    // MARK: - View Builders

    private var dashedDivider: some View {
        let lineWidth = 1 / displayScale

        return Rectangle()
            .fill(Color.clear)
            .frame(height: lineWidth)
            .overlay(
                Rectangle()
                    .stroke(
                        .tertiary,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            dash: [2, 6]
                        )
                    )
            )
    }
}
