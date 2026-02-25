//
//  validateNewItem.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftUI

// Generates a target index for a new item as long as the item's neighbors are not empty.
// Returns nil otherwise.

func generateTargetIndex<Item: ListItem>(
    in items: [Item],
    near baseId: UUID,
    offset: Int
) -> Int? {

    guard
        let baseIndex = items.firstIndex(where: {
            $0.stableId == baseId
        })
    else {
        assertionFailure(
            "ERROR generateTargetIndex: Item does not exist in the list with ID \(baseId)"
        )
        return nil
    }

    let targetIndex = baseIndex + offset

    // Don't create the new item if it is next to an empty item.

    let upperEvent =
        targetIndex > 0 ? items[targetIndex - 1] : nil
    if let upper = upperEvent, upper.title.isEmpty {
        return nil
    }

    let lowerEvent =
        targetIndex < items.count
        ? items[targetIndex] : nil
    if let lower = lowerEvent, lower.title.isEmpty {
        return nil
    }

    return targetIndex
}
