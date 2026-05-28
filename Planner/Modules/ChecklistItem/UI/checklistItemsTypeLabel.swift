//
//  checklistItemsTypeLabel.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

func checklistItemsTypeLabel(_ items: [ChecklistItem]) -> String {
    guard let firstType = items.first?.type else {
        return ChecklistUI.GENERIC_TYPE_LABEL
    }

    let allSameType = items.allSatisfy { $0.type == firstType }

    return allSameType
        ? firstType.rawValue : ChecklistUI.GENERIC_TYPE_LABEL
}
