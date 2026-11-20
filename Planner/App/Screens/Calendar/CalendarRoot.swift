//
//  CalendarRoot.swift
//  Planner
//
//  Created by Alex Green on 11/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct CalendarRootView: View {
    let settings: Settings
    let namespace: Namespace.ID

    private let monthOffsets = Array(
        -TodayService.PLANNER_MONTH_RADIUS...TodayService.PLANNER_MONTH_RADIUS
    )

    private let weekdayColumns = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerService: PlannerService

    @State private var isScrolling = false
    @State private var scrollingTask: Task<Void, Never>?

    @FocusState private var isSearchFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            PlannerSearchWrapperView(
                isSearchFocused: $isSearchFocused,
                settings: settings
            ) {
                TabView(selection: $plannerService.calendarMonthOffset) {
                    ForEach(monthOffsets, id: \.self) { offset in
                        let stamp = monthstamp(
                            for: offset
                        )

                        CalendarMonthTabView(
                            contextCache: Binding(
                                get: {
                                    plannerService.calendarContextCache[stamp]
                                        ?? [:]
                                },
                                set: {
                                    plannerService.calendarContextCache[stamp] =
                                        $0
                                }
                            ),
                            monthstamp: stamp,
                            datestamps: calendarDatestamps(for: offset),
                            weekdayColumns: weekdayColumns,
                            isScrolling: isScrolling,
                            settings: settings,
                            namespace: namespace
                        )
                        .tag(offset)
                        .toolbar {
                            if offset == plannerService.calendarMonthOffset {
                                ToolbarItem(placement: .topBarLeading) {
                                    VStack(alignment: .leading) {
                                        PageTitle(stamp.month)

                                        Text(stamp.year)
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .bold,
                                                    design: .rounded
                                                )
                                            )
                                            .foregroundStyle(
                                                Color.secondary
                                            )
                                    }
                                    .frame(width: 160, alignment: .leading)
                                }
                                .sharedBackgroundVisibility(.hidden)
                            }
                        }
                    }
                }
                .tabViewStyle(
                    .page(indexDisplayMode: .never)
                )
                .background(Color.appBackground.ignoresSafeArea())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { _ in
                            scrollingTask?.cancel()
                            scrollingTask = nil

                            isScrolling = true
                        }
                        .onEnded { _ in
                            scrollingTask?.cancel()

                            scrollingTask = Task { @MainActor in
                                do {
                                    try await Task.sleep(
                                        for: .milliseconds(1000)
                                    )
                                } catch {
                                    return
                                }

                                isScrolling = false
                                scrollingTask = nil
                            }
                        }
                )
            }
        }
        .task(id: isScrolling) {
            if !isScrolling {

                // Note: Add preload here if desired.
                // Currently not used due to lag.

                pruneCache(around: plannerService.calendarMonthOffset)

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

    private func neighbourOffsets(around offset: Int, radius: Int) -> [Int] {
        Array((offset - radius)...(offset + radius))
    }

    /// Drops cached months that are far away from the current page's month.
    private func pruneCache(
        around offset: Int
    ) {
        guard plannerService.calendarContextCache.keys.count > 9 else {
            return
        }

        let keep = Set(
            neighbourOffsets(around: offset, radius: 4)
                .filter { monthOffsets.contains($0) }
                .map { monthstamp(for: $0) }
        )

        plannerService.calendarContextCache = plannerService
            .calendarContextCache.filter {
                keep.contains($0.key)
            }
    }
}
