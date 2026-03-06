//
//  RowToggleView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct RowConfirmationConfig<Item: ListItem> {
    let title: String?
    let message: String?
    let needsConfirmation: (Item) -> Bool
    let actions: [ConfirmationAction<Item>]
}

struct RowToggleConfig<Item: ListItem> {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let confirmation: RowConfirmationConfig<Item>?
    
    @ViewBuilder
    func iconView(
        item: Item,
        opacity: Double,
        isChecked: Bool,
        isConfirmationOpen: Binding<Bool>,
        toggle: @escaping () -> Void
    ) -> some View {
        Image(systemName: iconName(isChecked: isChecked))
            .opacity(opacity)
            .imageScale(.large)
            .foregroundStyle(
                primary(
                    isChecked: isChecked,
                ),
                secondary(isChecked: isChecked)
            )
            .contentTransition(
                .symbolEffect(
                    .replace.downUp
                )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if needsConfirmation(for: item) {
                    isConfirmationOpen.wrappedValue = true
                } else {
                    toggle()
                }
            }
            .withToggleConfirmation(
                confirmation,
                item: item,
                isPresented: isConfirmationOpen
            )
    }

    func iconName(isChecked: Bool) -> String {
        isChecked ? name : "circle"
    }

    func primary(
        isChecked: Bool,
    ) -> Color {
        isChecked ? primaryColor : .secondary
    }

    func secondary(isChecked: Bool) -> Color {
        isChecked ? secondaryColor : .secondary
    }

    func needsConfirmation(for item: Item) -> Bool {
        confirmation?.needsConfirmation(item) == true
    }

}

struct RowToggleView<Item: ListItem>: View {
    let item: Item
    let tint: Color
    let isChecked: Bool
    let opacity: Double
    let customIconConfig: RowToggleConfig<Item>?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var listManager: ListManager<Item>

    @State private var isConfirmationOpen: Bool = false

    private var activeTint: Color {
        listManager.isSelectMode ? accentColor.color : tint
    }

    var body: some View {
        if let config = customIconConfig,
            !listManager.isSelectMode
        {
            config.iconView(
                item: item,
                opacity: opacity,
                isChecked: isChecked,
                isConfirmationOpen: $isConfirmationOpen,
                toggle: handleToggle
            )
        } else {
            ToggleView(
                isOn: isChecked,
                tint: activeTint,
                opacity: opacity,
                toggle: handleToggle
            )
        }
    }

    private func handleToggle() {
        listManager.toggleItem(item)
    }
}
