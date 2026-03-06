//
//  generateTargetIndex.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftUI

// Clean

// Generates a target index for a new item.
// Returns nil if either of its neighbors are empty.
func generateTargetIndex<Item: ListItem>(
    in sortedItems: [Item],
    near baseId: UUID,
    offset: Int
) -> Int? {
    guard
        let baseIndex = sortedItems.firstIndex(where: {
            $0.stableId == baseId
        })
    else {
        assertionFailure(
            "ERROR generateTargetIndex: Item does not exist in list with ID \(baseId)"
        )
        return nil
    }
        
    let targetIndex = baseIndex + offset

    // New item's upper neighbor is empty. Don't create it.
    let upperEvent =
        targetIndex > 0 ? sortedItems[targetIndex - 1] : nil
    if let upper = upperEvent, upper.title.isEmpty {
        return nil
    }

    // New item's lower neighbor is empty. Don't create it.
    let lowerEvent =
        targetIndex < sortedItems.count
        ? sortedItems[targetIndex] : nil
    if let lower = lowerEvent, lower.title.isEmpty {
        return nil
    }

    return targetIndex
}
