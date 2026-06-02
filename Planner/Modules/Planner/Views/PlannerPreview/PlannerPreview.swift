//
//  PlannerPreview.swift
//  Planner
//
//  Created by Alex Green on 12/25/25.
//

import EventKit
import SwiftDate
import SwiftUI

struct PlannerPreviewView: View {
    private let variant: PlannerPreviewVariant
    private let isSearchQueryActive: Bool
    private let planner: Planner
    private let tripLabel: String?
    private let sortedBirthdays: [Birthday]
    private let sortedChipEvents: [EKEvent]
    private let sortedPlannerEvents: [PlannerEvent]
    private let settings: PlannerSettings

    init(
        variant: PlannerPreviewVariant,
        isSearchQueryActive: Bool = false,
        planner: Planner,
        tripLabel: String? = nil,
        sortedBirthdays: [Birthday],
        sortedChipEvents: [EKEvent],
        sortedPlannerEvents: [PlannerEvent],
        settings: PlannerSettings
    ) {
        self.variant = variant
        self.isSearchQueryActive = isSearchQueryActive
        self.planner = planner
        self.tripLabel = tripLabel
        self.sortedBirthdays = sortedBirthdays
        self.sortedChipEvents = sortedChipEvents
        self.sortedPlannerEvents = sortedPlannerEvents
        self.settings = settings
    }

    private let MAX_PREVIEW_SLOTS = 5

    @EnvironmentObject private var locationService: LocationService

    private var totalItemCount: Int {
        tripSlotSize
            + sortedBirthdays.count
            + sortedChipEvents.count
            + sortedPlannerEvents.count
    }

    private var hasItems: Bool {
        totalItemCount > 0
    }

    private var remainingPlansLabel: LocalizedStringKey {
        let previewCount =
            tripSlotSize
                + previewContext.birthdays.count
                + previewContext.chipEvents.count
                + previewContext.plannerEvents.count

        let remainingCount = totalItemCount - previewCount

        if remainingCount == 0 {
            if hasItems {
                return "No more plans"
            }
            return "No plans"
        }

        return "^[\(remainingCount) more plan](inflect: true)"
    }

    private var startOfDay: DateInRegion {
        planner.startOfDay(settings: settings)
    }

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    private var tripSlotSize: Int {
        tripLabel == nil ? 0 : 1
    }

    // MARK: Separate Events By Importance

    private var calendarEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { $0.calendarItemExternalIdentifier != nil }
    }

    private var timedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter {
            $0.time != nil && $0.calendarItemExternalIdentifier == nil
        }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { $0.time == nil }
    }

    // MARK: Preview Events

    private var previewContext: PreviewContext {
        // MARK: Birthdays

        var remainingSlots = MAX_PREVIEW_SLOTS - tripSlotSize
        let birthdays: [Birthday] = Array(
            sortedBirthdays.prefix(remainingSlots)
        )

        // MARK: Chips

        remainingSlots = max(0, remainingSlots - birthdays.count)
        let chipEvents: [EKEvent] = Array(
            sortedChipEvents.prefix(remainingSlots)
        )

        // MARK: Calendar Events

        remainingSlots = max(0, remainingSlots - chipEvents.count)
        let calendarEvents = calendarEvents.prefix(remainingSlots)

        // MARK: Timed Events

        remainingSlots = max(0, remainingSlots - calendarEvents.count)
        let timedEvents = timedPlannerEvents.prefix(remainingSlots)

        // MARK: Untimed Events

        remainingSlots = max(0, remainingSlots - timedEvents.count)
        let untimedEvents = untimedPlannerEvents.prefix(remainingSlots)

        let plannerEvents = (calendarEvents + timedEvents + untimedEvents)
            .sorted {
                $0.sortDate < $1.sortDate
            }

        return PreviewContext(
            birthdays: birthdays,
            chipEvents: chipEvents,
            plannerEvents: plannerEvents
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tripInfo
            birthdayChipList
            eventChipList
            PlannerEventListView(
                plannerRegion: startOfDay.region,
                events: previewContext.plannerEvents,
                isBottomOfCard: isSearchQueryActive,
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
        if let tripLabel {
            AdornedValue(
                tripLabel,
                iconConfig: IconConfig(name: "suitcase")
            )
        }
    }

    private var birthdayChipList: some View {
        ForEach(
            previewContext.birthdays,
            id: \.event.eventIdentifier
        ) {
            BirthdayLabelView(
                birthday: $0,
                settings: settings
            )
        }
    }

    private var eventChipList: some View {
        ForEach(
            previewContext.chipEvents,
            id: \.eventIdentifier
        ) { event in
            let calendarColor = event.calendar.color

            AdornedValue(
                event.title,
                iconConfig: IconConfig(
                    name: event.calendar.systemImageName(
                        settings: settings
                    ),
                    primaryColor: calendarColor,
                    secondaryColor: calendarColor
                ),
                color: calendarColor
            )
        }
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if hasItems && !isSearchQueryActive {
            EmptyLabel(remainingPlansLabel, scale: 0.8)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if variant != .search {
            ZStack {
                if !hasItems {
                    EmptyLabel(remainingPlansLabel, scale: 0.8)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
}
