//
//  CalendarOnboarding.swift
//  Planner
//
//  Created by Alex Green on 7/10/26.
//

import EventKit
import SwiftUI
import WrappingHStack

struct CalendarOnboardingView: View {
    @Binding var screens: [OnboardingScreen]
    let visitedScreens: Set<OnboardingScreen>
    let openNextScreen: () -> Void

    @EnvironmentObject private var calendarService: CalendarService

    @State private var visibleChips: Int = 0

    // MARK: - Body

    var body: some View {
        OnboardingScreenView(
            visibleSampleCount: $visibleChips,
            sampleCount: 4,
            screen: OnboardingScreen.calendar,
            visitedScreens: visitedScreens,
            title: "Calendar",
            iconConfig: IconConfig(
                name: "calendar"
            ),
            message:
                "Keep your schedule in one place by syncing your calendar.",
            buttonLabel: "Choose calendar access",
            openNextScreen: requestAccess,
            sample: calendarAccessSample
        )
    }

    // MARK: - View Builders

    private func calendarAccessSample() -> some View {
        WrappingHStack {
            chip(
                title: "Final Exam",
                icon: "briefcase",
                color: .green,
                index: 0
            )

            chip(
                title: "Tara's 30th Birthday",
                icon: "birthday.cake.fill",
                color: .blue,
                index: 1
            )

            chip(
                title: "Devil's Lake",
                icon: "mountain.2",
                color: .pink,
                index: 2
            )

            chip(
                title: "Puerto Rico",
                icon: "airplane",
                color: .orange,
                index: 3
            )
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func chip(
        title: String,
        icon: String,
        color: Color,
        index: Int
    ) -> some View {
        AdornedValue(
            title,
            iconConfig: IconConfig(
                name: icon,
                primaryColor: color,
                secondaryColor: color
            ),
            color: color
        )
        .glassChip(height: PlannerLayout.CHIP_HEIGHT) {}
        .scaleEffect(visibleChips > index ? 1 : 0.6)
        .opacity(visibleChips > index ? 1 : 0)
        .offset(y: visibleChips > index ? 0 : 16)
    }

    // MARK: - Functions

    private func requestAccess() {
        calendarService.ekEventStore.requestFullAccessToEvents { granted, _ in
            Task { @MainActor in
                if !granted {
                    screens.removeAll(
                        where: { $0 == OnboardingScreen.contacts }
                    )
                }

                openNextScreen()
            }
        }
    }
}
