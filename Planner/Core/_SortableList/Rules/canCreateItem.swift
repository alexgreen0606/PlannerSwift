//
//  canCreateItem.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftUI

// Clean

func canCreateItem<Item: ListItem>(
    at index: Int,
    in sortedItems: [Item]
) -> Bool {
    // New item's upper neighbor is empty. Don't create it.
    let upperEvent =
        index > 0 ? sortedItems[index - 1] : nil
    if let upper = upperEvent, upper.title.isEmpty {
        return false
    }

    // New item's lower neighbor is empty. Don't create it.
    let lowerEvent =
        index < sortedItems.count
            ? sortedItems[index] : nil
    if let lower = lowerEvent, lower.title.isEmpty {
        return false
    }

    return true
}
