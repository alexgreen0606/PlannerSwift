//
//  PlannerListPreview.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import EventKit
import SwiftData
import SwiftUI

struct PlannerListPreviewView: View {
    let planner: Planner
    let sortedPlannerEvents: [PlannerEvent]
    let sortedEventChips: [PlannerEvent]
    let sortedBirthdayChips: [PlannerEvent]
    let settings: Settings
    let namespace: Namespace.ID

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerService: PlannerService

    private var activeQuery: PlannerSearchQuery? {
        plannerService.activeQuery
    }

    private var isSearching: Bool {
        activeQuery != nil
    }

    private var tripLabel: String? {
        guard let trip = planner.trip else {
            return nil
        }

        if let activeQuery,
            trip.searchQueryScore(activeQuery) == nil
        {
            return nil
        }

        return trip.title
    }

    private var filteredBirthdayChips: [PlannerEvent] {
        guard let activeQuery else {
            return sortedBirthdayChips
        }

        return sortedBirthdayChips.filter {
            $0.searchQueryScore(activeQuery, in: planner.datestamp) != nil
        }
    }

    private var filteredEventChips: [PlannerEvent] {
        guard let activeQuery else {
            return sortedEventChips
        }

        return sortedEventChips.filter {
            $0.searchQueryScore(activeQuery, in: planner.datestamp) != nil
        }
    }

    private var filteredPlannerEvents: [PlannerEvent] {
        guard let activeQuery else {
            return sortedPlannerEvents.filter {
                !$0.isCompleted
            }
        }

        return sortedPlannerEvents.filter {
            $0.searchQueryScore(activeQuery, in: planner.datestamp) != nil
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                PlannerHeaderView(
                    datestamp: planner.datestamp,
                    iconDetailOffset: planner.datestamp.isNext7Days(
                        todaystamp: todayService.todaystamp
                    ) ? 2.5 : nil,
                    title:
                        // Note: Same as default, but exclude the year from the date.
                        // This is shown in list section header.
                        planner.datestamp.proximityFormat(
                            using: [
                                ProximityRule(
                                    proximity:
                                        .next7Days,
                                    format: .weekday
                                ),
                                ProximityRule(
                                    proximity:
                                        .fallback,
                                    format:
                                        .dateWithoutYear
                                ),
                            ],
                            todaystamp:
                                todayService
                                .todaystamp
                        )
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                PlannerListWeatherView(
                    planner: planner,
                    settings: settings
                )
            }
            .frame(maxWidth: .infinity)

            PlannerPreviewView(
                planner: planner,
                tripLabel: tripLabel,
                sortedBirthdayEvents: filteredBirthdayChips,
                sortedEventChips: filteredEventChips,
                sortedPlannerEvents: filteredPlannerEvents,
                hideRemainingPlans: isSearching,
                hideEmptyLabel: isSearching,
                settings: settings
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: isSearching ? nil : 235, alignment: .top)
        .matchedTransitionSource(
            id: planner.datestamp,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture {
            plannerCoverStore.context = PlannerCoverContext(
                datestamp: planner.datestamp
            )
        }
    }
}
