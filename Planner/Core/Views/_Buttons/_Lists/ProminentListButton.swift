//
//  ProminentListButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct ProminentListButtonView<Item: ListItemDetails>: View {
    private let color: Color?
    private let createItem: () -> Void

    init(color: Color? = nil, createItem: @escaping () -> Void) {
        self.color = color
        self.createItem = createItem
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var listEngine: ListEngine<Item>

    private var systemImageName: String {
        listEngine.isFocused ? "checkmark" : "plus"
    }

    // MARK: - Body

    var body: some View {
        GlassIconButtonView(
            systemImageName: systemImageName,
            prominent: true,
            onTap: {
                if listEngine.isFocused {
                    listEngine.blur()
                } else {
                    createItem()
                }
            }
        )
        .tint(color ?? accentColor.swiftUiColor)
        .foregroundStyle(Color.inverseLabel)
    }
}
