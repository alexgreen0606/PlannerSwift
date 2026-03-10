//
//  ChecklistBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct ChecklistBuilderView: View {
    private let canTransferItems: Bool
    private let closeChecklist: (ChecklistItem?) -> Void

    init(
        checklistId: UUID,
        canTransferItems: Bool,
        closeChecklist: @escaping (ChecklistItem?) -> Void
    ) {
        self.canTransferItems = canTransferItems
        self.closeChecklist = closeChecklist

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
            ChecklistView(
                checklist: checklist,
                sortedItems: sortedItems,
                canTransferItems: canTransferItems,
                closeChecklist: closeChecklist
            )
        }
    }
}
