//
//  OnboardingActionButton.swift
//  Planner
//
//  Created by Alex Green on 7/14/26.
//

import SwiftUI

struct OnboardingActionButtonView: View {
    let buttonLabel: String
    let hideButton: Bool
    let onTap: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    private var buttonShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20)
    }

    // MARK: - Body

    var body: some View {
        Button(buttonLabel, action: handleTap)
            .font(.system(.title3, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        accentColor.swiftUiColor,
                        accentColor.swiftUiColor.opacity(0.8),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(buttonShape)
            .opacity(hideButton ? 0 : 1)
            .contentShape(buttonShape)
            .onTapGesture(perform: handleTap)
    }

    // MARK: - Function

    private func handleTap() {
        withAnimation {
            onTap()
        }
    }
}
