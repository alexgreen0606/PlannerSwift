//
//  ItemToggleView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftUI

struct CustomIconConfig {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
}

enum ListToggleType: String {
    case storage
    case staging
}

struct ItemToggleView<Item: ListItem>: View {
    let type: ListToggleType
    let isChecked: Bool
    let isDisabled: Bool
    let opacity: Double
    let customIconConfig: CustomIconConfig?
    let onToggleChecked: () -> Void

    var iconName: String {
        !isChecked ? "circle" : customIconConfig?.name ?? "circle.inset.filled"
    }

    var primaryColor: Color {
        isDisabled
            ? Color(uiColor: .tertiaryLabel)
            : !isChecked
                ? Color(uiColor: .secondaryLabel)
        : customIconConfig?.primaryColor ?? .accentColor
    }

    var secondaryColor: Color {
        isDisabled
            ? Color(uiColor: .tertiaryLabel)
            : !isChecked
                ? Color(uiColor: .secondaryLabel)
                : customIconConfig?.secondaryColor
                    ?? Color(uiColor: .secondaryLabel)
    }

    var body: some View {
        Image(systemName: iconName)
            .imageScale(.large)
            .foregroundStyle(
                primaryColor,
                secondaryColor
            )
            .opacity(opacity)
            .contentTransition(
                .symbolEffect(.replace.magic(fallback: .replace))
            )
            .contentShape(Circle())
            .onTapGesture(perform: onToggleChecked)
    }
}
