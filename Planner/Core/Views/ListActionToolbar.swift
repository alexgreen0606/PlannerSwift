//
//  ListActionToolbar.swift
//  Planner
//
//  Created by Alex Green on 5/28/26.
//

import SwiftUI

struct ListActionToolbarView<Item: ListItemDetails, SelectedItemActions: View>: View {
    private let keyboardAccessory: ListKeyboardAccessoryView<Item>?
    private let selectedItemActions: SelectedItemActions
    private let createItem: () -> Void

    init(
        accentColor: Color? = nil,
        keyboardAccessory: ListKeyboardAccessoryView<Item>? = nil,
        selectedItemActions: SelectedItemActions,
        createItem: @escaping () -> Void
    ) {
        self.selectedItemActions = selectedItemActions
        self.keyboardAccessory = keyboardAccessory
        self.createItem = createItem

        customAccentColor = accentColor
    }

    private let customAccentColor: Color?

    @EnvironmentObject private var listEngine: ListEngine<Item>

    private var isFocused: Bool {
        listEngine.focusedId != nil
    }

    private var padding: EdgeInsets {
        if isFocused {
            return EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 8,
                trailing: 16
            )
        }

        return EdgeInsets(
            top: 0,
            leading: 16,
            bottom: -8,
            trailing: 16
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !listEngine.isSelectMode {
                HStack(alignment: .bottom) {
                    if isFocused {
                        keyboardAccessory
                    }

                    Spacer()

                    ProminentListButtonView<Item>(
                        color: customAccentColor,
                        createItem: createItem
                    )
                }
                .frame(maxWidth: .infinity)
            } else {
                selectedItemActions
            }
        }
        .padding(padding)
    }
}
