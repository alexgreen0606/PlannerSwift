//
//  SearchResultPlannerPreview.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import EventKit
import SwiftData
import SwiftUI

struct SearchResultPlannerPreviewView: View {
    let activeQuery: PlannerSearchQuery?
    let planner: Planner
    let sortedPlannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData?
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    private var tripLabel: String? {
        guard let trip = planner.trip,
              trip.searchQueryScore(activeQuery) != nil
        else {
            return nil
        }

        return trip.title
    }

    private var filteredBirthdays: [Birthday] {
        calendarDayData?.birthdays.filter {
            $0.event.searchQueryScore(activeQuery) != nil
        } ?? []
    }

    private var filteredChipEvents: [EKEvent] {
        calendarDayData?.plannerChipEvents.filter {
            $0.searchQueryScore(activeQuery) != nil
        } ?? []
    }

    private var filteredPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter {
            $0.searchQueryScore(activeQuery) != nil
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                PlannerHeaderView(
                    datestamp: planner.datestamp,
                    title:
                    // Note: Same as default, but exclude the year from the date.
                    // This is show in list section header.
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

                if let activeQuery {
                    SearchResultWeatherView(
                        activeQuery: activeQuery,
                        planner: planner,
                        settings: settings
                    )
                }
            }
            .frame(maxWidth: .infinity)

            PlannerPreviewView(
                planner: planner,
                tripLabel: tripLabel,
                sortedBirthdays: filteredBirthdays,
                sortedChipEvents: filteredChipEvents,
                sortedPlannerEvents: filteredPlannerEvents,
                hideRemainingPlans: activeQuery?.isSearching == true,
                hideEmptyLabel: true,
                settings: settings
            )
        }
        .frame(maxWidth: .infinity)
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
