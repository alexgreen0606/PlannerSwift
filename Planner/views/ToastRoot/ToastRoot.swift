//
//  ToastRoot.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

// Clean

extension EnvironmentValues {
    @Entry var showToast: (Toast) -> Void = { _ in }
}

struct ToastRootView<Content: View>: View {
    @ViewBuilder var content: Content

    private let animation: Animation = .interpolatingSpring(
        duration: 0.35,
        bounce: 0,
        initialVelocity: 0
    )

    @State private var activeToast: Toast? = nil

    @State private var toastDismissWorkItem: DispatchWorkItem?

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let activeToast {
                    ToastView(config: activeToast)
                }
            }
            .environment(\.showToast) { toast in

                withAnimation(
                    animation.logicallyComplete(after: 0.17),
                    completionCriteria: .logicallyComplete
                ) {
                    if activeToast != nil {
                        activeToast = nil
                    }
                } completion: {
                    toastDismissWorkItem?.cancel()

                    withAnimation(animation) {
                        activeToast = toast
                    }

                    toastDismissWorkItem = .init(block: dismiss)

                    if let toastDismissWorkItem {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 6,
                            execute: toastDismissWorkItem
                        )
                    }
                }
            }
    }

    // MARK: - Functions

    private func dismiss() {
        withAnimation(animation) {
            activeToast = nil
        }

        toastDismissWorkItem?.cancel()
    }
}
