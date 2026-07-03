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
    private let planner: Planner
    private let tripLabel: String?
    private let sortedBirthdayEvents: [PlannerEvent]
    private let sortedEventChips: [PlannerEvent]
    private let sortedPlannerEvents: [PlannerEvent]
    private let hideRemainingPlans: Bool
    private let hideEmptyLabel: Bool
    private let settings: Settings

    init(
        planner: Planner,
        tripLabel: String? = nil,
        sortedBirthdayEvents: [PlannerEvent],
        sortedEventChips: [PlannerEvent],
        sortedPlannerEvents: [PlannerEvent],
        hideRemainingPlans: Bool = false,
        hideEmptyLabel: Bool = false,
        settings: Settings
    ) {
        self.planner = planner
        self.tripLabel = tripLabel
        self.sortedBirthdayEvents = sortedBirthdayEvents
        self.sortedEventChips = sortedEventChips
        self.sortedPlannerEvents = sortedPlannerEvents
        self.hideRemainingPlans = hideRemainingPlans
        self.hideEmptyLabel = hideEmptyLabel
        self.settings = settings
    }

    private let MAX_PREVIEW_SLOTS = 5

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService

    private var totalItemCount: Int {
        tripSlotSize
            + sortedBirthdayEvents.count
            + sortedEventChips.count
            + sortedPlannerEvents.count
    }

    private var hasItems: Bool {
        totalItemCount > 0
    }

    private var remainingPlansLabel: LocalizedStringKey {
        let previewCount =
            tripSlotSize
            + previewContext.birthdayEvents.count
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
        sortedPlannerEvents.filter { $0.eKEventContext != nil }
    }

    private var timedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter {
            $0.time != nil && $0.eKEventContext == nil
        }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter {
            $0.time == nil && $0.eKEventContext == nil
        }
    }

    // MARK: Preview Events

    private var previewContext: PreviewContext {
        // MARK: Birthdays

        var remainingSlots = MAX_PREVIEW_SLOTS - tripSlotSize
        let birthdays = Array(
            sortedBirthdayEvents.prefix(remainingSlots)
        )

        // MARK: Chips

        remainingSlots = max(0, remainingSlots - birthdays.count)
        let chips = Array(
            sortedEventChips.prefix(remainingSlots)
        )

        // MARK: Calendar Events

        remainingSlots = max(0, remainingSlots - chips.count)
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
            birthdayEvents: birthdays,
            chipEvents: chips,
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
                hideLowerDivider: hideRemainingPlans,
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
            previewContext.birthdayEvents
        ) {
            BirthdayLabelView(
                plannerEvent: $0,
                settings: settings
            )
        }
    }

    private var eventChipList: some View {
        ForEach(
            previewContext.chipEvents
        ) { event in
            let calendarColor = event.tint(accentColor: accentColor)
            AdornedValue(
                event.title,
                iconConfig: IconConfig(
                    name: event.calendarSystemImageName(settings: settings),
                    primaryColor: calendarColor,
                    secondaryColor: calendarColor
                ),
                color: calendarColor
            )
        }
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if hasItems && !hideRemainingPlans {
            EmptyLabel(remainingPlansLabel, scale: 0.8)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if !hideEmptyLabel {
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
