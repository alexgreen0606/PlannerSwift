//
//  ListItemToggle.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

// Clean

struct ToggleConfig {
    let iconConfig: IconConfig
    let uncheckedIconConfig: IconConfig
    let confirmation: ConfirmationConfig?
    let onClick: (() -> Void)?

    init(
        iconConfig: IconConfig,
        uncheckedIconConfig: IconConfig = IconConfig(name: "circle"),
        confirmation: ConfirmationConfig? = nil,
        onClick: (() -> Void)? = nil
    ) {
        self.iconConfig = iconConfig
        self.uncheckedIconConfig = uncheckedIconConfig
        self.confirmation = confirmation
        self.onClick = onClick
    }
}

struct ConfirmationConfig {
    let title: String?
    let message: String?
    let needsConfirmation: Bool
    let actions: [ConfirmationAction]

    init(
        title: String?,
        message: String? = nil,
        needsConfirmation: Bool = true,
        actions: [ConfirmationAction]
    ) {
        self.title = title
        self.message = message
        self.needsConfirmation = needsConfirmation
        self.actions = actions
    }
}

struct ListItemToggleView<Item: ListItem>: View {
    let item: Item
    let tint: Color
    let isChecked: Bool
    let opacity: Double
    let customToggleConfig: ToggleConfig?

    init(
        item: Item,
        tint: Color,
        isChecked: Bool,
        opacity: Double,
        customToggleConfig: ToggleConfig? = nil
    ) {
        self.item = item
        self.tint = tint
        self.isChecked = isChecked
        self.opacity = opacity
        self.customToggleConfig = customToggleConfig
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var ListStore: ListStore<Item>

    /// Only used by custom toggles that require confirmation.
    @State private var isConfirmationOpen: Bool = false

    private var activeTint: Color {
        ListStore.isSelectMode ? accentColor.color : tint
    }

    private var toggleConfig: ToggleConfig {
        if let customConfig = customToggleConfig,
           !ListStore.isSelectMode
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
        toggleConfig.confirmation?.needsConfirmation == true
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
                    ListStore.toggleItem(item)
                }
            }
            .withConfirmation(
                toggleConfig.confirmation,
                isPresented: $isConfirmationOpen
            )
    }
}
