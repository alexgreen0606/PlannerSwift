//
//  ContactsOnboarding.swift
//  Planner
//
//  Created by Alex Green on 7/10/26.
//

import Contacts
import SwiftUI

struct ContactsOnboardingView: View {
    let visitedScreens: Set<OnboardingScreen>
    let openNextScreen: () -> Void

    private let BIRTHDAY_CHIP_SCALE = 1.3

    private let contactsStore = CNContactStore()

    @State private var visibleChips: Int = 0

    var body: some View {
        OnboardingScreenView(
            visibleSampleCount: $visibleChips,
            sampleCount: 4,
            screen: OnboardingScreen.contacts,
            visitedScreens: visitedScreens,
            title: "Contacts",
            iconConfig: IconConfig(
                name: "birthday.cake"
            ),
            message:
                "Never miss another birthday by syncing your contacts!",
            buttonLabel: "Choose contacts access",
            openNextScreen: requestAccess,
            sample: contactsAccessSample
        )
    }

    // MARK: - View Builders

    private func contactsAccessSample() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            chip(
                title: "Mary's 26th Birthday",
                index: 0
            )

            chip(
                title: "Jane's 28th Birthday",
                index: 1
            )

            chip(
                title: "Steve's 59th Birthday",
                index: 2
            )

            chip(
                title: "Betsy's 58th Birthday",
                index: 3
            )
        }
    }

    @ViewBuilder
    private func chip(
        title: String,
        index: Int
    ) -> some View {
        HStack(spacing: Layout.DEFAULT_ADORNMENT_SPACING * 2) {
            Image("SampleContact\(index)")
                .resizable()
                .scaledToFill()
                .frame(
                    width: 24 * BIRTHDAY_CHIP_SCALE,
                    height: 24 * BIRTHDAY_CHIP_SCALE
                )
                .clipShape(Circle())

            Value(title, scale: BIRTHDAY_CHIP_SCALE)
        }
        .padding(
            .leading,
            2 - (PlannerLayout.CHIP_HEIGHT * BIRTHDAY_CHIP_SCALE / 3)
        )
        .glassChip(height: PlannerLayout.CHIP_HEIGHT * BIRTHDAY_CHIP_SCALE) {}
        .scaleEffect(visibleChips > index ? 1 : 0.6)
        .opacity(visibleChips > index ? 1 : 0)
    }

    // MARK: - Functions

    private func requestAccess() {
        contactsStore.requestAccess(for: .contacts) { _, _ in
            openNextScreen()
        }
    }
}
