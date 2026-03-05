//
//  RowToggleConfirmationModifier.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

private struct RowToggleConfirmationModifier<Item: ListItem>: ViewModifier {
    let config: RowConfirmationConfig<Item>?
    let item: Item
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if let config,
            config.needsConfirmation(item)
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
                            role: action.role
                        ) {
                            action.handler(item)
                            isPresented = false
                        }
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

    func withToggleConfirmation<Item: ListItem>(
        _ config: RowConfirmationConfig<Item>?,
        item: Item,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            RowToggleConfirmationModifier(
                config: config,
                item: item,
                isPresented: isPresented
            )
        )
    }

}
