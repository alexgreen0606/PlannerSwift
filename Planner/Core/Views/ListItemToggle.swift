//
//  ListItemToggle.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct ListItemToggleView<Item: ListItemDetails>: View {
    private let item: Item
    private let opacity: Double
    private let customToggleConfig: ToggleConfig?

    init(
        item: Item,
        color: Color? = nil,
        opacity: Double,
        customToggleConfig: ToggleConfig? = nil
    ) {
        self.item = item
        self.opacity = opacity
        self.customToggleConfig = customToggleConfig

        customColor = color
    }

    private let customColor: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var listEngine: ListEngine<Item>

    @State private var isConfirmationOpen: Bool = false

    private var isChecked: Bool {
        if listEngine.isSelectMode {
            return listEngine.selectedItemIds.contains(item.stableId)
        }

        return listEngine.isItemToggled(item)
    }

    private var toggleConfig: ToggleConfig {
        if let customConfig = customToggleConfig,
           !listEngine.isSelectMode
        {
            return customConfig
        }

        return ToggleConfig(
            completedIconConfig: IconConfig(
                name: "circle.inset.filled",
                primaryColor: color
            )
        )
    }

    private var color: Color {
        guard let customColor else {
            return accentColor.swiftUiColor
        }

        return listEngine.isSelectMode ? accentColor.swiftUiColor : customColor
    }

    private var systemImageName: String {
        isChecked
            ? toggleConfig.completedIconConfig.name
            : toggleConfig.pendingIconConfig.name
    }

    private var primaryColor: Color {
        isChecked
            ? toggleConfig.completedIconConfig.primaryColor
            : toggleConfig.pendingIconConfig.primaryColor
    }

    private var secondaryColor: Color {
        isChecked
            ? toggleConfig.completedIconConfig.secondaryColor
            : toggleConfig.pendingIconConfig.secondaryColor
    }

    private var needsConfirmation: Bool {
        toggleConfig.confirmation != nil
    }

    // MARK: - Body

    var body: some View {
        Image(systemName: systemImageName)
            .imageScale(.large)
            .contentTransition(
                .symbolEffect(
                    .replace.downUp
                )
            )
            .foregroundStyle(
                primaryColor,
                secondaryColor
            )
            .opacity(opacity)
            .withConfirmation(
                toggleConfig.confirmation,
                isPresented: $isConfirmationOpen
            )
            .contentShape(Rectangle())
            .onTapGesture {
                customToggleConfig?.onClick?()

                if needsConfirmation {
                    isConfirmationOpen = true
                } else {
                    listEngine.toggleItem(item)
                }
            }
    }
}
