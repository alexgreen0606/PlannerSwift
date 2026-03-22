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

struct PlannerPreviewView: View {
    let type: PlannerPreviewType
    let searchQuery: PlannerSearchQuery?
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let plannerEvents: [PlannerEvent]
    let plannerChipEvents: [EKEvent]
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
        plannerChipEvents.filter {
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

    private var previewChipEvents: [EKEvent] {
        Array(filteredChipEvents.prefix(maxPreviewEvents))
    }

    private var sortedPreviewPlannerEvents: [PlannerEvent] {
        let slots = max(0, maxPreviewEvents - previewChipEvents.count)

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
                PlannerDateInfoView(
                    plannerDay: plannerDay,
                    type: type
                )

                Spacer()

                if type == .search {
                    weatherInfo
                }
            }

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
                .frame(width: todaystampManager.todaystamp == planner.datestamp && type != .trip ? 330 : 240)
                .frame(height: 330, alignment: .top)
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
