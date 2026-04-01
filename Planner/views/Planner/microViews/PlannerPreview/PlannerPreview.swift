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
import WeatherKit
import WrappingHStack

// Clean

struct PlannerPreviewView<Header: View>: View {
    let type: PlannerPreviewType
    let searchQuery: PlannerSearchQuery?
    let header: Header
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let plannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData
    let settings: PlannerSettings

    private let maxPreviewEvents = 5

    @EnvironmentObject private var todaystampManager: TodaystampWatcher

    // MARK: - Computed Variables

    // MARK: Filtered Search Results

    private var filteredPlannerEvents: [PlannerEvent] {
        plannerEvents.filter {
            $0.searchQueryScore(searchQuery) != nil
        }
    }

    private var filteredChipEvents: [EKEvent] {
        calendarDayData.plannerChipEvents.filter {
            $0.searchQueryScore(searchQuery) != nil
        }
    }

    // MARK: Separated Time Events

    private var timedPlannerEvents: [PlannerEvent] {
        filteredPlannerEvents.filter { $0.hasTime }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        filteredPlannerEvents.filter { !$0.hasTime }
    }

    // MARK: Preview Events

    private var tripLabel: String? {
        guard type != .trip, let trip = planner.trip, trip.searchQueryScore(searchQuery) != nil
        else {
            return nil
        }
        return trip.title
    }

    private var previewChipEvents: [EKEvent] {
        Array(filteredChipEvents.prefix(maxPreviewEvents))
    }

    private var sortedPreviewPlannerEvents: [PlannerEvent] {
        let tripSlot = tripLabel == nil ? 0 : 1
        let slots = max(
            0,
            maxPreviewEvents - previewChipEvents.count - tripSlot
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
        (previewChipEvents.count + sortedPreviewPlannerEvents.count) > 0
    }

    private var isSearching: Bool {
        guard let searchQuery else {
            return false
        }
        return searchQuery.isSearching
    }

    // MARK: - Body

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top) {
                header

                Spacer()

                if type == .search {
                    weatherInfo
                }
            }

            tripInfo
            
            ForEach(
                calendarDayData.birthdays,
                id: \.event.eventIdentifier,
                content: birthdayChip
            )

            PlannerChipListView(
                events: previewChipEvents,
                settings: settings
            )

            PlannerEventListView(
                plannerRegion: plannerDay.region,
                events: sortedPreviewPlannerEvents,
                isBottomOfCard: isSearching
            )

            remainingPlansIndicator
            emptyPlannerIndicator

            if type != .search {
                weatherInfo
            }
        }

        if type != .search {
            content
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(
                    width: todaystampManager.todaystamp == planner.datestamp
                        && type != .trip ? 350 : 240
                )
                .frame(
                    height: PlannerLayout.PREVIEW_CARD_HEIGHT,
                    alignment: .top
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                )
        } else {
            content
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var tripInfo: some View {
        if let tripLabel {
            HStack(spacing: 6) {
                Image(
                    systemName: "suitcase"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(Color.secondary)

                Text(tripLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.label)
            }
        }
    }

    @ViewBuilder
    private var weatherInfo: some View {
        WeatherInfoView(
            previewType: type,
            plannerSearchQuery: searchQuery,
            planner: planner,
            plannerDay: plannerDay,
            plannerLocation: plannerLocation,
            settings: settings
        )
    }
    
    @ViewBuilder
    private func birthdayChip(_ birthday: Birthday) -> some View {
        BirthdayView(
            birthday: birthday,
            settings: settings
        )
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if hasEvents && !isSearching {
            Text(remainingPlansLabel)
                .font(
                    .system(size: 12, weight: .heavy, design: .rounded)
                )
                .foregroundStyle(Color.secondary)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if type != .search {
            VStack {
                if !hasEvents {
                    Text(remainingPlansLabel)
                        .font(
                            .system(size: 12, weight: .heavy, design: .rounded)
                        )
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
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
