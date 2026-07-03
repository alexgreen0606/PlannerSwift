//
//  withConfirmation.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

private struct ConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let config: ConfirmationConfig?

    func body(content: Content) -> some View {
        if let config {
            content
                .confirmationDialog(
                    config.title,
                    isPresented: $isPresented,
                    titleVisibility: .visible
                ) {
                    ForEach(config.actions) { action in
                        Button(
                            action.title,
                            role: action.role,
                            action: action.handler
                        )
                    }
                } message: {
                    Text(config.message)
                }
        } else {
            content
        }
    }
}

extension View {
    func withConfirmation(
        _ config: ConfirmationConfig?,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            ConfirmationModifier(
                isPresented: isPresented,
                config: config
            )
        )
    }
}
