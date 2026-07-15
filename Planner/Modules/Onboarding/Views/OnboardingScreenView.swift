//
//  OnboardingScreen.swift
//  Planner
//
//  Created by Alex Green on 7/10/26.
//

import SwiftUI

struct OnboardingScreenView<Sample: View>: View {
    @Binding private var visibleSampleCount: Int
    private let sampleCount: Int
    private let screen: OnboardingScreen
    private let visitedScreens: Set<OnboardingScreen>

    private let title: String
    private let iconConfig: IconConfig
    private let message: String
    private let buttonLabel: String
    private let hideButton: Bool
    private let openNextScreen: () -> Void
    @ViewBuilder private let sample: () -> Sample

    init(
        visibleSampleCount: Binding<Int> = .constant(0),
        sampleCount: Int = 0,
        screen: OnboardingScreen,
        visitedScreens: Set<OnboardingScreen>,
        title: String,
        iconConfig: IconConfig,
        message: String,
        buttonLabel: String,
        hideButton: Bool = false,
        openNextScreen: @escaping () -> Void,
        sample: @escaping () -> Sample
    ) {
        self._visibleSampleCount = visibleSampleCount
        self.sampleCount = sampleCount
        self.screen = screen
        self.visitedScreens = visitedScreens
        self.title = title
        self.iconConfig = iconConfig
        self.message = message
        self.buttonLabel = buttonLabel
        self.hideButton = hideButton
        self.openNextScreen = openNextScreen
        self.sample = sample
    }

    @State private var areSamplesVisible: Bool = false

    // MARK: - Body

    var body: some View {
        OnboardingFrameView(
            header: {
                VStack(spacing: 16) {
                    Image(systemName: iconConfig.name)
                        .font(.system(size: 50))
                        .foregroundStyle(
                            iconConfig.primaryColor,
                            iconConfig.secondaryColor
                        )
                        .padding(.top, 32)

                    Text(title)
                        .font(
                            .system(
                                size: 28,
                                weight: .heavy,
                                design: .rounded
                            )
                        )

                    Text(message)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            },
            content: {
                sample()
                Spacer()
            },
            button: {
                OnboardingActionButtonView(
                    buttonLabel: buttonLabel,
                    hideButton: hideButton || !areSamplesVisible,
                    onTap: openNextScreen
                )
            }
        )

        // MARK: Animations.

        .task(id: visitedScreens) {
            guard visitedScreens.contains(screen)
            else {
                return
            }

            // Incrementally display sample views.
            for i in 0..<sampleCount {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + renderDelay(for: i)
                ) {
                    withAnimation(
                        .spring(
                            duration: 0.6,
                            bounce: 0.6
                        )
                    ) {
                        visibleSampleCount = i + 1
                    }
                }
            }

            // Display the action button once all samples have rendered.
            DispatchQueue.main.asyncAfter(
                deadline: .now() + renderDelay(for: sampleCount)
            ) {
                withAnimation(.smooth) {
                    areSamplesVisible = true
                }
            }
        }
    }

    // MARK: - Functions

    private func renderDelay(for index: Int) -> Double {
        0.1 + Double(index) * 0.1
    }
}
