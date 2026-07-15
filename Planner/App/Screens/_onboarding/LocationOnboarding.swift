//
//  LocationOnboarding.swift
//  Planner
//
//  Created by Alex Green on 7/11/26.
//

import CoreLocation
import SwiftUI

struct LocationOnboardingView: View {
    let visitedScreens: Set<OnboardingScreen>
    let openNextScreen: () -> Void

    @EnvironmentObject private var locationService: LocationService

    // MARK: - Body

    var body: some View {
        OnboardingScreenView(
            screen: OnboardingScreen.location,
            visitedScreens: visitedScreens,
            title: "Location",
            iconConfig: IconConfig(
                name: "location"
            ),
            message:
                "Save time entering locations by using your current location.",
            buttonLabel: "Choose location access",
            openNextScreen: requestAccess,
            sample: { EmptyView() }
        )

        // MARK: Complete this screen once the access is set.
        .onChange(of: locationService.hasAccess == nil) { _, isNotDetermined in
            if !isNotDetermined {
                openNextScreen()
            }
        }
    }

    // MARK: - Functions

    private func requestAccess() {
        locationService.locationManager.requestWhenInUseAuthorization()
    }
}
