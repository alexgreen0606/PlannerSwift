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
        ScrollView {
            content()
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
        }
        .safeAreaInset(edge: .top) {
            header()
        }
        .safeAreaInset(edge: .bottom) {
            button()
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 32)
    }
}
