//
//  OnboardingComplete.swift
//  Planner
//
//  Created by Alex Green on 7/14/26.
//

import SwiftUI

struct OnboardingCompleteView: View {
    let visitedScreens: Set<OnboardingScreen>
    let openNextScreen: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        OnboardingScreenView(
            screen: OnboardingScreen.complete,
            visitedScreens: visitedScreens,
            title: "You're all set!",
            iconConfig: IconConfig(
                name: "checkmark.circle"
            ),
            message:
                "Customize your experience even more on the Settings page. Happy planning!",
            buttonLabel: "Enter planner",
            openNextScreen: openNextScreen,
            sample: { EmptyView() }
        )
    }
}
