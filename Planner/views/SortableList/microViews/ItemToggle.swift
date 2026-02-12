//
//  ItemToggleView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct ConfirmationConfig<Item: ListItem> {
    let title: String?
    let message: String?
    let destructiveKeys: Set<String>
    let needsConfirmation: (Item) -> Bool
    let actions: [String: (Item) -> Void]
    let destructiveActions: [String: (Item) -> Void]
}

struct CustomIconConfig<Item: ListItem> {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let confirmation: ConfirmationConfig<Item>?
}

struct ItemToggleView<Item: ListItem>: View {
    let item: Item
    let tint: Color
    let isChecked: Bool
    let opacity: Double
    let customIconConfig: CustomIconConfig<Item>?
    let onToggleChecked: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject var listManager: ListManager<Item>

    @State private var isConfirmationOpen: Bool = false

    private var iconName: String {
        !isChecked ? "circle" : customIconConfig?.name ?? "circle.inset.filled"
    }

    private var primaryColor: Color {
        !isChecked
            ? Color(uiColor: .secondaryLabel)
            : listManager.isSelectMode
                ? accentColor.swiftUIColor
                : customIconConfig?.primaryColor ?? tint
    }

    private var secondaryColor: Color {
        !isChecked
            ? Color(uiColor: .secondaryLabel)
            : customIconConfig?.secondaryColor
                ?? Color(uiColor: .secondaryLabel)
    }

    private var needsConfirmation: Bool {
        customIconConfig?.confirmation?.needsConfirmation(item) == true
    }

    var body: some View {
        let img = Image(systemName: iconName)
            .imageScale(.large)
            .foregroundStyle(
                primaryColor,
                secondaryColor
            )
            .opacity(opacity)
            .contentTransition(
                .symbolEffect(
                    customIconConfig != nil
                        ? .replace.downUp : .replace
                )
            )
            .contentShape(Circle())
            .onTapGesture {
                if needsConfirmation {
                    isConfirmationOpen = true
                    return
                }

                onToggleChecked()
            }

        if needsConfirmation {
            img
                .confirmationDialog(
                    customIconConfig?.confirmation?.title ?? "",
                    isPresented: $isConfirmationOpen,
                    titleVisibility: .visible,
                    actions: {
                        if let actions = customIconConfig?.confirmation?
                            .actions,
                            let destructiveActions = customIconConfig?
                                .confirmation?.destructiveActions
                        {
                            ForEach(Array(actions.keys), id: \.self) { key in
                                Button(
                                    key,
                                    role: customIconConfig?.confirmation?
                                        .destructiveKeys.contains(key) == true
                                        ? .destructive : .confirm
                                ) {
                                    actions[key]?(item)
                                    isConfirmationOpen = false
                                }
                            }
                            ForEach(Array(destructiveActions.keys), id: \.self)
                            { key in
                                Button(
                                    key,
                                    role: customIconConfig?.confirmation?
                                        .destructiveKeys.contains(key) == true
                                        ? .destructive : .confirm
                                ) {
                                    destructiveActions[key]?(item)
                                    isConfirmationOpen = false
                                }
                            }
                        }
                    },
                    message: {
                        if let message = customIconConfig?.confirmation?.message
                        {
                            Text(message)
                        }
                    }
                )
        } else {
            img
        }
    }
}
