//
//  ToastRoot.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var showToast: (Toast) -> Void = { _ in }
}

struct ToastRootView<Content: View, ListItemType: ListItem>: View {
    let listManager: ListManager<ListItemType>?
    @ViewBuilder var content: Content

    init(
        listManager: ListManager<ListItemType>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.listManager = listManager
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
        listManager?.focusedId != nil ? -40 : 0
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let activeToast {
                    ToastView(config: activeToast, listManager: listManager)
                        .padding(.bottom, keyboardPadding)
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

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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

    // MARK: - Functions

    private func dismiss() {
        withAnimation(animation) {
            activeToast = nil
        }

        toastDismissWorkItem?.cancel()
    }
}
