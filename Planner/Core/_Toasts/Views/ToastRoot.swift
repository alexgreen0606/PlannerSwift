//
//  ToastRoot.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

@MainActor
struct ToastRootView<Content: View>: View {
    private let isKeyboardFocused: Bool
    private let blurFocusedItem: () -> Void
    private var content: Content

    // MARK: Tab Page (Dashboard)
    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isKeyboardFocused = false
        self.blurFocusedItem = {}
        self.content = content()
    }

    // MARK: List Page (Planner, Checklist, Routine)
    init<Item: ListItemDetails>(
        listEngine: ListEngine<Item>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isKeyboardFocused = listEngine.focusedId != nil
        self.blurFocusedItem = { listEngine.focusedId = nil }
        self.content = content()
    }

    private let animation: Animation = .interpolatingSpring(
        duration: 0.35,
        bounce: 0,
        initialVelocity: 0
    )

    @State private var activeToast: Toast? = nil

    @State private var toastDismissWorkItem: DispatchWorkItem?

    private var keyboardPadding: CGFloat {
        isKeyboardFocused ? 16 : 0
    }

    // MARK: - Body

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let activeToast {
                    ToastView(
                        toast: activeToast,
                        blurFocusedItem: blurFocusedItem,
                        dismiss: dismiss
                    )
                    .padding(.bottom, keyboardPadding)
                }
            }
            .environment(\.showToast) { toast in
                withAnimation(
                    animation.logicallyComplete(after: 0.2),
                    completionCriteria: .logicallyComplete
                ) {
                    if activeToast != nil {
                        activeToast = nil
                    }
                } completion: {
                    toastDismissWorkItem?.cancel()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(animation) {
                            activeToast = toast
                        }
                    }

                    toastDismissWorkItem = .init(block: dismiss)

                    if let toastDismissWorkItem {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 7,
                            execute: toastDismissWorkItem
                        )
                    }
                }
            }
    }

    // MARK: - Function

    private func dismiss() {
        withAnimation(animation) {
            activeToast = nil
        }

        toastDismissWorkItem?.cancel()
    }
}
