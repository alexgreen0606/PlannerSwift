//
//  SelectItemsButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct SelectItemsButtonView_old<Item: ListItemDetails>: View {
    private let itemsLabel: String
    private let hasVisibleItem: Bool

    init(itemsLabel: String = "Items", hasVisibleItem: Bool) {
        self.itemsLabel = itemsLabel
        self.hasVisibleItem = hasVisibleItem
    }

    @EnvironmentObject private var listEngine: ListEngine_old<Item>

    // MARK: - Body

    var body: some View {
        Button {
            listEngine.toggleSelectMode()
        } label: {
            Label(
                "Select \(itemsLabel)",
                systemImage: "checklist"
            )
        }
        .disabled(!hasVisibleItem)
    }
}
