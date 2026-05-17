//
//  checklistItemsType.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

// Clean

func checklistItemsType(_ items: [ChecklistItem]) -> String {
    guard let firstType = items.first?.type else {
        return "item"
    }

    let allSameType = items.allSatisfy { $0.type == firstType }

    return allSameType ? firstType.rawValue : "item"
}
