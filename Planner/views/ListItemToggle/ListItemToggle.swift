//
//  ListItemToggle.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

// Clean

struct ToggleConfig<Item: ListItem> {
    let iconConfig: IconConfig
    let uncheckedIconConfig: IconConfig
    let confirmation: ConfirmationConfig<Item>?
    let onClick: (() -> Void)?

    init(
        iconConfig: IconConfig,
        uncheckedIconConfig: IconConfig = IconConfig(name: "circle"),
        confirmation: ConfirmationConfig<Item>? = nil,
        onClick: (() -> Void)? = nil
    ) {
        self.iconConfig = iconConfig
        self.uncheckedIconConfig = uncheckedIconConfig
        self.confirmation = confirmation
        self.onClick = onClick
    }
}

struct ConfirmationConfig<Item: ListItem> {
    let title: String?
    let message: String?
    let needsConfirmation: (Item) -> Bool
    let actions: [ConfirmationAction<Item>]
}

struct ListItemToggleView<Item: ListItem>: View {
    let item: Item
    let tint: Color
    let isChecked: Bool
    let opacity: Double
    let customToggleConfig: ToggleConfig<Item>?

    init(
        item: Item,
        tint: Color,
        isChecked: Bool,
        opacity: Double,
        customToggleConfig: ToggleConfig<Item>? = nil
    ) {
        self.item = item
        self.tint = tint
        self.isChecked = isChecked
        self.opacity = opacity
        self.customToggleConfig = customToggleConfig
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var listManager: ListManager<Item>

    // Only used by custom toggles that require confirmation.
    @State private var isConfirmationOpen: Bool = false

    private var activeTint: Color {
        listManager.isSelectMode ? accentColor.color : tint
    }

    private var toggleConfig: ToggleConfig<Item> {
        if let customConfig = customToggleConfig,
            !listManager.isSelectMode
        {
            return customConfig
        }

        return ToggleConfig(
            iconConfig: IconConfig(
                name: "circle.inset.filled",
                primaryColor: activeTint
            )
        )
    }

    private var systemImageName: String {
        isChecked
            ? toggleConfig.iconConfig.name
            : toggleConfig.uncheckedIconConfig.name
    }

    private var primaryColor: Color {
        isChecked
            ? toggleConfig.iconConfig.primaryColor
            : toggleConfig.uncheckedIconConfig.primaryColor
    }

    private var secondaryColor: Color {
        isChecked
            ? toggleConfig.iconConfig.secondaryColor
            : toggleConfig.uncheckedIconConfig.secondaryColor
    }

    private var needsConfirmation: Bool {
        toggleConfig.confirmation?.needsConfirmation(item) == true
    }

    var body: some View {
        Image(systemName: systemImageName)
            .opacity(opacity)
            .imageScale(.large)
            .foregroundStyle(
                primaryColor,
                secondaryColor
            )
            .contentTransition(
                .symbolEffect(
                    .replace.downUp
                )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                customToggleConfig?.onClick?()
                
                if needsConfirmation {
                    isConfirmationOpen = true
                } else {
                    listManager.toggleItem(item)
                }
            }
            .withToggleConfirmation(
                toggleConfig.confirmation,
                item: item,
                isPresented: $isConfirmationOpen
            )
    }
}
