//
//  SelectAllToggle.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct SelectAllToggleView<Item: ListItemDetails>: View {
    let visibleItems: [Item]

    @EnvironmentObject private var listEngine: ListEngine<Item>

    private var isAllSelected: Bool {
        !visibleItems.isEmpty
            && listEngine.selectedItemIds.count == visibleItems.count
    }

    // MARK: - Body

    var body: some View {
        Button {
            listEngine.toggleSelectAll(visibleItems: visibleItems)
        } label: {
            Text(isAllSelected ? "Deselect All" : "Select All")
                .fontWeight(.semibold)
        }
        .disabled(visibleItems.isEmpty)
    }
}
