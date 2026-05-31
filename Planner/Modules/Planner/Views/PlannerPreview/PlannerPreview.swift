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

    private let maxPreviewEvents = 5

    @EnvironmentObject private var locationService: LocationService

    private var hasEvents: Bool {
        (tripSlotSize
            + previewBirthdays.count
            + previewChipEvents.count
            + sortedPreviewPlannerEvents.count) > 0
    }

    private var remainingPlansLabel: String {
        let totalEventCount =
            sortedChipEvents.count + sortedPlannerEvents.count

        let previewCount =
            previewChipEvents.count + sortedPreviewPlannerEvents.count

        let remainingCount = totalEventCount - previewCount

        if remainingCount == 0 {
            if previewCount > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(remainingCount) more plan\(remainingCount == 1 ? "" : "s")"
    }

    private var startOfDay: DateInRegion {
        planner.datestamp.startOfDay(in: planner.region(settings: settings))
    }

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    // MARK: Separated Time Events

    // TODO: prioritize calendar events

    private var timedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { $0.time != nil }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { $0.time == nil }
    }

    // MARK: Preview Events

    private var tripSlotSize: Int {
        tripLabel == nil ? 0 : 1
    }

    private var previewBirthdays: [Birthday] {
        Array(sortedBirthdays.prefix(maxPreviewEvents - tripSlotSize))
    }

    private var previewChipEvents: [EKEvent] {
        Array(
            sortedChipEvents.prefix(
                maxPreviewEvents - tripSlotSize - previewBirthdays.count
            )
        )
    }

    private var sortedPreviewPlannerEvents: [PlannerEvent] {
        let slots = max(
            0,
            maxPreviewEvents - tripSlotSize - previewBirthdays.count
                - previewChipEvents.count
        )

        let timed = Array(timedPlannerEvents.prefix(slots))
        let remaining = slots - timed.count
        let untimed = untimedPlannerEvents.prefix(max(0, remaining))

        return (timed + untimed).sorted { $0.sortDate < $1.sortDate }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tripInfo
            birthdayChipList
            eventChipList
            PlannerEventListView(
                plannerRegion: startOfDay.region,
                events: sortedPreviewPlannerEvents,
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
            sortedBirthdays,
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
            previewChipEvents,
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
        if hasEvents && !isSearchQueryActive {
            EmptyLabel(remainingPlansLabel, scale: 0.8)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if variant != .search {
            ZStack {
                if !hasEvents {
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
