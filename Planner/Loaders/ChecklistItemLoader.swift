//
//  ChecklistItemLoader.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct ChecklistItemContext {
    let item: ChecklistItem
    let sortedItems: [ChecklistItem]
    let sortedPendingItems: [ChecklistItem]
    let sortedCompletedItems: [ChecklistItem]
}

struct ChecklistItemLoaderView<Content: View>: View {
    private let rootFolder: ChecklistItem
    private let openItem: (ChecklistItem, ChecklistItem) -> Void
    private let content: (ChecklistItemContext) -> Content

    init(
        rootFolder: ChecklistItem,
        stableId: UUID,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void,
        @ViewBuilder content: @escaping (ChecklistItemContext) -> Content
    ) {
        self.rootFolder = rootFolder
        self.openItem = openItem
        self.content = content

        _items = Query(
            filter: #Predicate<ChecklistItem> {
                $0.stableId == stableId
            }
        )

        _sortedItems = Query(
            filter: #Predicate<ChecklistItem> { item in
                item.parent?.stableId == stableId
            },
            sort: \.sortIndex
        )
    }

    @StateObject private var checklistItemEngine = ListEngine<ChecklistItem>()

    @Query private var items: [ChecklistItem]
    @Query private var sortedItems: [ChecklistItem]

    private var item: ChecklistItem? {
        items.first
    }

    private var sortedPendingItems: [ChecklistItem] {
        sortedItems.filter {
            checklistItemEngine.isItemInPendingList($0)
        }
    }

    private var sortedCompletedItems: [ChecklistItem] {
        sortedItems.filter {
            checklistItemEngine.isItemInCompletedList($0)
        }
    }

    var body: some View {
        if let item {
            content(
                ChecklistItemContext(
                    item: item,
                    sortedItems: sortedItems,
                    sortedPendingItems: sortedPendingItems,
                    sortedCompletedItems: sortedCompletedItems
                )
            )
            .environmentObject(checklistItemEngine)
        }
    }
}
