//
//  Onboarding.swift
//  Planner
//
//  Created by Alex Green on 7/10/26.
//

import Contacts
import EventKit
import SwiftData
import SwiftUI

struct OnboardingView: View {
    private let settings: Settings

    init(
        locationService: LocationService,
        settings: Settings
    ) {
        self.settings = settings

        var screens: [OnboardingScreen] = [OnboardingScreen.welcome]

        if EKEventStore.authorizationStatus(for: .event) == .notDetermined {
            screens.append(.calendar)
        }

        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined
            && EKEventStore.authorizationStatus(for: .event) != .denied
        {
            screens.append(.contacts)
        }

        if locationService.locationManager.authorizationStatus == .notDetermined
        {
            screens.append(.location)
        }

        if settings.homeLocation == nil {
            screens.append(.home)
        }

        screens.append(.complete)

        self._isOnboarding = State(initialValue: screens.count > 2)
        self._screens = State(initialValue: screens)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("lastCleansedMonthstamp") var lastCleansedMonthstamp: String =
        ""

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    @State private var screens: [OnboardingScreen]

    @State private var isOnboarding: Bool
    @State private var onboardingIndex: Int = 0

    @State private var visitedScreens: Set<OnboardingScreen> = []

    private var canSyncPlanners: Bool {
        !calendarService.isOnboardingCalendars
            && settings.homeLocation != nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if isOnboarding {
                ZStack {
                    ForEach(
                        Array(screens.enumerated()),
                        id: \.element
                    ) { index, screen in
                        onboardingScreen(index: index, screen: screen)
                            .opacity(index == onboardingIndex ? 1 : 0)
                            .offset(
                                x: index == onboardingIndex
                                    ? 0 : index < onboardingIndex ? -800 : 200
                            )
                    }
                }

                // MARK: Track which onboarding screens have been opened.

                .task(id: onboardingIndex) {
                    if onboardingIndex < screens.count {
                        visitedScreens.insert(screens[onboardingIndex])
                    }
                }
            } else {
                RootTabView(settings: settings)
                    .transition(.scale)
            }
        }

        // MARK: App Setup

        .task {
            staggerMainActorInteraction(delay: 1) {
                // Build the initial planners in the UI.
                calendarService.loadCalendars()
                plannerService.refresh()

                // Update the app icon to match the theme settings.
                if appColorScheme == .system {
                    syncAppIconWithSettings(
                        accentColor: accentColor,
                        systemColorScheme: systemColorScheme
                    )
                }

                // Ensure the root folder exists.
                modelContext.ensureRootFolder()

                // Initialize results for the search page.
                plannerService.search()

                // Clean stale storage data.
                cleanseStorage()
            }
        }

        // MARK: Refresh external data when app focuses.

        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                calendarService.loadCalendars()
                plannerService.refreshCalendar()

                if appColorScheme == .system {
                    syncAppIconWithSettings(
                        accentColor: accentColor,
                        systemColorScheme: systemColorScheme
                    )
                }
            }
        }

        // MARK: Refresh calendars when calendar access changes.

        .onChange(of: calendarService.hasCalendarAccess) { _, _ in
            calendarService.loadCalendars()
        }

        // MARK: Initialize planners after onboarding.

        .onChange(of: canSyncPlanners) { _, _ in
            plannerService.refresh()
            plannerService.search()
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func onboardingScreen(index: Int, screen: OnboardingScreen)
        -> some View
    {
        switch screen {
        case .welcome:
            WelcomeOnboardingView(
                openNextScreen: handleScreenCompletion
            )
        case .calendar:
            CalendarOnboardingView(
                screens: $screens,
                visitedScreens: visitedScreens,
                openNextScreen: handleScreenCompletion
            )
        case .contacts:
            ContactsOnboardingView(
                visitedScreens: visitedScreens,
                openNextScreen: handleScreenCompletion
            )
        case .location:
            LocationOnboardingView(
                visitedScreens: visitedScreens,
                openNextScreen: handleScreenCompletion
            )
        case .home:
            HomeOnboardingView(
                visitedScreens: visitedScreens,
                settings: settings,
                openNextScreen: handleScreenCompletion
            )
        case .complete:
            OnboardingCompleteView(
                visitedScreens: visitedScreens,
                openNextScreen: handleScreenCompletion
            )
        }
    }

    // MARK: - Functions

    private func handleScreenCompletion() {
        if onboardingIndex == screens.count - 1 {
            withAnimation(.linear) {
                isOnboarding = false
            }
            return
        }

        withAnimation {
            onboardingIndex += 1
        }
    }

    /// Runs at most once a month.
    private func cleanseStorage() {
        guard lastCleansedMonthstamp != todayService.todaystamp.monthstamp
        else {
            return
        }

        lastCleansedMonthstamp = todayService.todaystamp.monthstamp

        if settings.keepPastEventsDuration != .forever {
            modelContext.deleteStaleData(
                cutoffDate: settings.keepPastEventsDuration.cutoffDate
            )
        }

        modelContext.safeSave("Onboarding cleanseStorage")
    }

    private func staggerMainActorInteraction(
        delay: Double,
        _ interaction: @escaping () -> Void
    ) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            interaction()
        }
    }
}
