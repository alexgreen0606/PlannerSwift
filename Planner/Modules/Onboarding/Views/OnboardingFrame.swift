//
//  OnboardingFrame.swift
//  Planner
//
//  Created by Alex Green on 7/14/26.
//

import SwiftUI

struct OnboardingFrameView<Header: View, Content: View, Button: View>: View {
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder let button: () -> Button

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            header()
                .padding(.bottom, 32)

            content()

            button()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}
