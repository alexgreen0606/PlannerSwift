//
//  PlannerTabRoot.swift
//  Planner
//
//  Created by Alex Green on 11/27/26.
//

import SwiftUI

/// The prominent Planner tab. Switches between the planner list and the calendar.
struct PlannerTabRootView: View {
    let settings: Settings
    let namespace: Namespace.ID

    @AppStorage("plannerTabMode") private var mode: PlannerTabMode = .list

    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    @State private var navigationPath = NavigationPath()

    @FocusState private var isSearchFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            PlannerSearchWrapperView(
                isSearchFocused: $isSearchFocused,
                settings: settings
            ) {
                content
                    .toolbar {
                        PlannerSearchToolbarContent(
                            isSearchFocused: $isSearchFocused,
                            settings: settings
                        )

                        ToolbarItem(placement: .topBarTrailing) {
                            Button("", systemImage: mode.toggleSystemImageName)
                            {
                                // Note: Animated by `content`, since @AppStorage
                                // doesn't reliably carry a withAnimation transaction.
                                mode = mode.toggled
                            }
                        }

                        ToolbarSpacer(.fixed, placement: .topBarTrailing)

                        ToolbarItem(placement: .topBarTrailing) {
                            overflowMenu
                        }
                    }
            }
            .navigationDestination(for: PlannerTabPageId.self) {
                destination in
                switch destination {
                case .settings:
                    SettingsRootView(
                        settings: settings,
                        namespace: namespace
                    )
                }
            }
        }
    }

    // MARK: - View Builders

    /// Infrequent actions, kept out of the way of the main toolbar.
    private var overflowMenu: some View {
        Menu {
            Button("Refresh", systemImage: "arrow.clockwise") {
                refresh()
            }

            Divider()

            Button("Settings", systemImage: "gear") {
                isSearchFocused = false
                navigationPath.append(PlannerTabPageId.settings)
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }

    /// Cross-fades between the list and the calendar.
    private var content: some View {
        ZStack {
            switch mode {
            case .list:
                PlannerListView(
                    settings: settings,
                    namespace: namespace
                )
                .transition(.opacity)
            case .calendar:
                PlannerCalendarView(settings: settings, namespace: namespace)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: mode)
    }

    // MARK: - Functions

    /// Mirrors the planner list's pull-to-refresh.
    private func refresh() {
        calendarService.loadCalendars()
        locationService.loadDeviceLocation()
        plannerService.refresh()
        plannerService.loadPlannerList()
    }
}
