//
//  ChecklistItemLoader.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftData
import SwiftUI

struct ChecklistItemLoaderView<Content: View>: View {
    private let content: (ChecklistItemContext) -> Content

    init(
        stableId: UUID,
        @ViewBuilder content: @escaping (ChecklistItemContext) -> Content
    ) {
        self.content = content

        _items = Query(
            filter: ChecklistItem.checklistItems(stableId: stableId)
        )

        _sortedItems = Query(
            filter: ChecklistItem.checklistItems(parentId: stableId),
            sort: \.sortIndex
        )
    }

    @Query private var items: [ChecklistItem]
    @Query private var sortedItems: [ChecklistItem]

    private var item: ChecklistItem? {
        items.first
    }

    // MARK: - Body

    var body: some View {
        if let item {
            content(
                ChecklistItemContext(
                    item: item,
                    sortedItems: sortedItems
                )
            )
        }
    }
}
