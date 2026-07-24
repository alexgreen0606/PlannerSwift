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

    private var isFocused: Bool {
        listEngine.focusedId != nil
    }

    private var systemImageName: String {
        isFocused ? "checkmark" : "plus"
    }

    // MARK: - Body

    var body: some View {
        GlassIconButtonView(
            systemImageName: systemImageName,
            prominent: true,
            onTap: {
                if isFocused {
                    listEngine.focusedId = nil
                    return
                }

                createItem()
            }
        )
        .tint(color ?? accentColor.swiftUiColor)
        .foregroundStyle(Color.inverseLabel)
        .contentTransition(
            .symbolEffect(
                .replace.upUp
            )
        )
    }
}
