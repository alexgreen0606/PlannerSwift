//
//  HomeOnboarding.swift
//  Planner
//
//  Created by Alex Green on 7/11/26.
//

import SwiftData
import SwiftUI

struct HomeOnboardingView: View {
    let visitedScreens: Set<OnboardingScreen>
    let settings: Settings
    let openNextScreen: () -> Void

    private let BIRTHDAY_CHIP_SCALE = 1.3

    private let HOME_CHIP_ID = "home"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService

    @State private var showLocationSheet: Bool = false

    @State private var homeLocation: Location? = nil

    @Namespace private var namespace

    private var chipIconConfig: IconConfig {
        guard homeLocation != nil else {
            return IconConfig(
                name: "house",
                primaryColor: accentColor.swiftUiColor
            )
        }

        return IconConfig(
            name: "mappin.and.ellipse",
            primaryColor: accentColor.swiftUiColor
        )
    }

    // MARK: - Body

    var body: some View {
        OnboardingScreenView(
            screen: OnboardingScreen.home,
            visitedScreens: visitedScreens,
            title: "Home Location",
            iconConfig: IconConfig(
                name: "house"
            ),
            message:
                "Your home location keeps event times accurate when planning across different time zones.",
            buttonLabel: "Save home location",
            hideButton: homeLocation == nil,
            openNextScreen: saveSelection,
            sample: homeSample
        )
    }

    // MARK: - View Builders

    private func homeSample() -> some View {
        AdornedValue(
            homeLocation?.name ?? "Select Home Location",
            iconConfig: chipIconConfig,
            color: homeLocation != nil ? Color.label : accentColor.swiftUiColor,
            scale: BIRTHDAY_CHIP_SCALE
        )
        .glassChip(height: PlannerLayout.CHIP_HEIGHT * BIRTHDAY_CHIP_SCALE) {
            showLocationSheet = true
        }
        .matchedTransitionSource(
            id: HOME_CHIP_ID,
            in: namespace
        )

        // MARK: Location Search Form

        .sheet(isPresented: $showLocationSheet) {
            LocationFormView(
                variant: .home,
                initialLocation: homeLocation,
                settings: settings,
                saveSelection: { location in
                    homeLocation = location
                }
            )
            .navigationTransition(
                .zoom(
                    sourceID: HOME_CHIP_ID,
                    in: namespace
                )
            )
        }
    }

    // MARK: - Functions

    private func saveSelection() {
        guard let homeLocation else {
            return
        }

        modelContext.updateHomeLocation(in: settings, to: homeLocation)
        openNextScreen()
    }
}
