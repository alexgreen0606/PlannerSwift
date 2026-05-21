//
//  ChecklistItemLoader.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct ChecklistItemLoaderView<Content: View>: View {
    private let rootFolder: ChecklistItem
    private let openItem: (ChecklistItem, ChecklistItem) -> Void
    private let content:
        (ChecklistItem, [ChecklistItem], [ChecklistItem]) -> Content

    init(
        rootFolder: ChecklistItem,
        stableId: UUID,
        listEngine: ListEngine<ChecklistItem>,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void,
        @ViewBuilder content:
            @escaping (ChecklistItem, [ChecklistItem], [ChecklistItem]) ->
            Content
    ) {
        self.rootFolder = rootFolder
        self.openItem = openItem
        self.content = content

        // MARK: Load the parent item.
        _items = Query(
            filter: #Predicate<ChecklistItem> {
                $0.stableId == stableId
            }
        )

        let newlyCheckedIds = listEngine.newlyCheckedIds
        let newlyUncheckedIds = listEngine.newlyUncheckedIds

        // MARK: Load the unchecked child items.
        _sortedUncheckedChildItems = Query(
            filter: #Predicate<ChecklistItem> { item in
                item.parent?.stableId == stableId
                    && ((!item.isCompleted
                        && !newlyUncheckedIds.contains(item.stableId))
                        || newlyCheckedIds.contains(item.stableId))
            },
            sort: \.sortIndex
        )

        // MARK: Load the checked child items.
        _sortedCheckedChildItems = Query(
            filter: #Predicate<ChecklistItem> { item in
                item.parent?.stableId == stableId
                    && ((item.isCompleted
                        && !newlyCheckedIds.contains(item.stableId))
                        || newlyUncheckedIds.contains(item.stableId))
            },
            sort: \.sortIndex
        )
    }

    @Query private var items: [ChecklistItem]
    @Query private var sortedUncheckedChildItems: [ChecklistItem]
    @Query private var sortedCheckedChildItems: [ChecklistItem]

    private var item: ChecklistItem? {
        items.first
    }

    var body: some View {
        if let item {
            content(item, sortedUncheckedChildItems, sortedCheckedChildItems)
        }
    }
}
