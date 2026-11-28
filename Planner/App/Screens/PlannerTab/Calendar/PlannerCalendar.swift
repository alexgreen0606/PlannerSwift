//
//  PlannerCalendar.swift
//  Planner
//
//  Created by Alex Green on 11/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

/// The calendar view of the Planner tab: a horizontally paged month grid.
struct PlannerCalendarView: View {
    let settings: Settings
    let namespace: Namespace.ID

    private let monthOffsets = Array(
        -TodayService.PLANNER_MONTHS_BEHIND...TodayService.PLANNER_MONTHS_AHEAD
    )

    private let weekdayColumns = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    @EnvironmentObject private var plannerService: PlannerService

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $plannerService.calendarMonthOffset) {
                ForEach(monthOffsets, id: \.self) { offset in
                    CalendarMonthTabView(
                        monthstamp: monthstamp(for: offset),
                        datestamps: calendarDatestamps(for: offset),
                        weekdayColumns: weekdayColumns,
                        // Note: Only the visible month and its neighbours load content.
                        isActive: abs(
                            offset - plannerService.calendarMonthOffset
                        ) <= 1,
                        settings: settings,
                        namespace: namespace
                    )
                    .tag(offset)
                }
            }
            .tabViewStyle(
                .page(indexDisplayMode: .never)
            )
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task(id: plannerService.calendarMonthOffset) {
            // Wait for paging to settle before syncing.
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }

            // Sync planners for the opened month.
            plannerService.syncPlanners(
                Set(
                    calendarDatestamps(
                        for: plannerService.calendarMonthOffset
                    ).compactMap { $0 }
                )
            )
        }
    }

    // MARK: - Functions

    private func monthstamp(for offset: Int) -> String {
        CalendarDatestampCache.shared.monthstamp(for: offset)
    }

    private func calendarDatestamps(for offset: Int) -> [String?] {
        CalendarDatestampCache.shared.datestamps(
            forMonthstamp: monthstamp(for: offset)
        )
    }
}
