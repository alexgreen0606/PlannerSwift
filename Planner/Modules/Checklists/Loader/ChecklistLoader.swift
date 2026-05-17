//
//  ChecklistBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct ChecklistBuilderView: View {
    private let rootFolder: ChecklistItem
    private let canTransferItems: Bool
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        rootFolder: ChecklistItem,
        checklistId: UUID,
        canTransferItems: Bool,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
    ) {
        self.rootFolder = rootFolder
        self.canTransferItems = canTransferItems
        self.openItem = openItem

        _checklists = Query(
            filter: #Predicate<ChecklistItem> {
                $0.stableId == checklistId
            }
        )

        // Note: Must query the items separately.
        // Using checklist.items causes too many row re-renders.
        _sortedItems = Query(
            filter: #Predicate<ChecklistItem> { item in
                item.parent?.stableId == checklistId
            },
            sort: \.sortIndex
        )
    }

    @Query private var checklists: [ChecklistItem]
    @Query private var sortedItems: [ChecklistItem]

    private var checklist: ChecklistItem? {
        checklists.first
    }

    var body: some View {
        if let checklist {
            ChecklistRootView(
                checklist: checklist,
                rootFolder: rootFolder,
                sortedItems: sortedItems,
                canTransferItems: canTransferItems,
                openItem: openItem
            )
        }
    }
}
