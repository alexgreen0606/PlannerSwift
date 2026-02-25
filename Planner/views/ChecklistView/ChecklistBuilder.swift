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
    private let canTransferItems: Bool
    private let closeChecklist: (ChecklistItem?) -> Void

    init(
        checklistId: UUID,
        canTransferItems: Bool,
        closeChecklist: @escaping (ChecklistItem?) -> Void
    ) {
        self.closeChecklist = closeChecklist
        self.canTransferItems = canTransferItems

        _checklists = Query(
            filter: #Predicate<ChecklistItem> {
                $0.stableId == checklistId
            }
        )
    }

    @Query private var checklists: [ChecklistItem]

    private var checklist: ChecklistItem? {
        checklists.first
    }

    var body: some View {
        if let checklist {
            ChecklistView(
                checklist: checklist,
                canTransferItems: canTransferItems,
                closeChecklist: closeChecklist
            )
        }
    }
}
