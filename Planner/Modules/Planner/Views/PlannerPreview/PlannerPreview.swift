//
//  PlannerPreview.swift
//  Planner
//
//  Created by Alex Green on 12/25/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WrappingHStack

struct PlannerPreviewView: View {
    let type: PlannerPreviewType
    let searchQuery: PlannerSearchQuery?
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let plannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData?
    let settings: PlannerSettings

    init(
        type: PlannerPreviewType,
        searchQuery: PlannerSearchQuery? = nil,
        planner: Planner,
        plannerDay: DateInRegion,
        plannerLocation: Location?,
        plannerEvents: [PlannerEvent],
        calendarDayData: CalendarDayData? = nil,
        settings: PlannerSettings
    ) {
        self.type = type
        self.searchQuery = searchQuery
        self.planner = planner
        self.plannerDay = plannerDay
        self.plannerLocation = plannerLocation
        self.plannerEvents = plannerEvents
        self.calendarDayData = calendarDayData
        self.settings = settings
    }

    private let maxPreviewEvents = 5

    // MARK: - Computed Variables

    // MARK: Filtered Search Results

    private var filteredPlannerEvents: [PlannerEvent] {
        plannerEvents.filter {
            $0.searchQueryScore(searchQuery) != nil
        }
    }

    private var filteredChipEvents: [EKEvent] {
        calendarDayData?.plannerChipEvents.filter {
            $0.searchQueryScore(searchQuery) != nil
        } ?? []
    }

    private var filteredBirthdays: [Birthday] {
        calendarDayData?.birthdays.filter {
            $0.event.searchQueryScore(searchQuery) != nil
        } ?? []
    }

    // MARK: Separated Time Events
    
    // TODO: prioritize calendar events

    private var timedPlannerEvents: [PlannerEvent] {
        filteredPlannerEvents.filter { $0.time != nil }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        filteredPlannerEvents.filter { $0.time == nil }
    }

    // MARK: Preview Events

    private var tripLabel: String? {
        guard type != .trip, let trip = planner.trip,
              trip.searchQueryScore(searchQuery) != nil
        else {
            return nil
        }
        return trip.title
    }

    private var tripSlotSize: Int {
        tripLabel == nil ? 0 : 1
    }

    private var previewBirthdays: [Birthday] {
        Array(filteredBirthdays.prefix(maxPreviewEvents - tripSlotSize))
    }

    private var previewChipEvents: [EKEvent] {
        Array(
            filteredChipEvents.prefix(
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

    // MARK: Miscellaneous Helpers

    private var remainingPlansLabel: String {
        let totalEventCount =
            filteredChipEvents.count + filteredPlannerEvents.count

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

    private var hasEvents: Bool {
        (previewChipEvents.count
            + sortedPreviewPlannerEvents.count
            + tripSlotSize
            + previewBirthdays.count) > 0
    }

    private var isSearching: Bool {
        guard let searchQuery else {
            return false
        }
        return searchQuery.isSearching
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tripInfo
            birthdayChipList
            eventChipList
            PlannerEventListView(
                plannerRegion: plannerDay.region,
                events: sortedPreviewPlannerEvents,
                isBottomOfCard: isSearching
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
            filteredBirthdays,
            id: \.event.eventIdentifier
        ) {
            BirthdayView(
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
                    primaryColor: calendarColor
                ),
                color: calendarColor
            )
        }
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if hasEvents && !isSearching {
            EmptyLabel(remainingPlansLabel, scale: 0.8)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if type != .search {
            ZStack {
                if !hasEvents {
                    EmptyLabel(remainingPlansLabel, scale: 0.8)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }
}
