//
//  withConfirmation.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

private struct ConfirmationModifier: ViewModifier {
    let config: ConfirmationConfig?
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if let config,
           config.needsConfirmation
        {
            content
                .confirmationDialog(
                    config.title ?? "",
                    isPresented: $isPresented,
                    titleVisibility: .visible
                ) {
                    ForEach(config.actions.indices, id: \.self) { index in
                        let action = config.actions[index]

                        Button(
                            action.title,
                            role: action.role,
                            action: action.handler
                        )
                    }
                } message: {
                    if let message = config.message {
                        Text(message)
                    }
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
                config: config,
                isPresented: isPresented
            )
        )
    }
}
