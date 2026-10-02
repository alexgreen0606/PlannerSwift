//
//  ChecklistItemSheetContext.swift
//  Planner
//
//  Created by Alex Green on 9/28/26.
//

struct ChecklistItemSheetContext: Identifiable {
    var checklistItem: ChecklistItem

    var id: String {
        checklistItem.transitionId
    }
}
