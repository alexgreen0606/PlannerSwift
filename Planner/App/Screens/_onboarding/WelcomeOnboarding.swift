//
//  WelcomeOnboarding.swift
//  Planner
//
//  Created by Alex Green on 7/12/26.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    let openNextScreen: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @State private var visibleFeatures: Int = 0

    @State private var showButton: Bool = false

    // MARK: - Body

    var body: some View {
        OnboardingFrameView(
            header: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome to your")
                        .font(
                            .system(size: 16, weight: .heavy, design: .rounded)
                        )
                        .foregroundStyle(Color.secondary)
                        .padding(.bottom, -6)

                    Text("Planner")
                        .font(
                            .system(size: 48, weight: .black, design: .rounded)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            },
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    feature(
                        title: "Create Checklists",
                        iconName: "list.bullet",
                        index: 0
                    )

                    feature(
                        title: "Schedule Events",
                        iconName: "calendar.day.timeline.leading",
                        index: 1
                    )

                    feature(
                        title: "Build Routines",
                        iconName: "repeat",
                        index: 2
                    )

                    feature(
                        title: "Plan Trips",
                        iconName: "suitcase",
                        index: 3
                    )

                    Spacer()

                    Text(
                        "Just a few quick steps to get everything set up."
                    )
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color.secondary)
                }
            },
            button: {
                OnboardingActionButtonView(
                    buttonLabel: "Begin",
                    hideButton: !showButton,
                    onTap: openNextScreen
                )
            }
        )

        // MARK: Incrementally display the features.
        .task {
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + renderDelay(for: i)
                ) {
                    withAnimation(.linear(duration: 0.6)) {
                        visibleFeatures = i + 1
                    }
                }
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + renderDelay(for: 4)
            ) {
                withAnimation(.linear) {
                    showButton = true
                }
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func feature(
        title: String,
        iconName: String,
        index: Int
    ) -> some View {
        AdornedValue(
            title,
            iconConfig: IconConfig(
                name: iconName
            ),
            color: Color.label,
            scale: 1.2
        )
        .scaleEffect(visibleFeatures > index ? 1 : 0.6)
        .opacity(visibleFeatures > index ? 1 : 0)
        .offset(y: visibleFeatures > index ? 0 : 16)
    }

    private func renderDelay(for index: Int) -> Double {
        0.1 + Double(index) * 0.3
    }
}
