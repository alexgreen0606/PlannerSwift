//
//  SelectItemsButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct SelectItemsButtonView<Item: ListItem>: View {
    let itemsLabel: String
    let hasVisibleItem: Bool

    init(itemsLabel: String = "Items", hasVisibleItem: Bool) {
        self.itemsLabel = itemsLabel
        self.hasVisibleItem = hasVisibleItem
    }

    @EnvironmentObject private var listEngine: ListEngine<Item>

    // MARK: - Body

    var body: some View {
        Button {
            listEngine.toggleSelectMode()
        } label: {
            Label(
                "Select \(itemsLabel)",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(!hasVisibleItem)
    }
}
