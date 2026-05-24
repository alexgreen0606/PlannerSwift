//
//  getInsertionIndex.swift
//  Planner
//
//  Created by Alex Green on 5/24/26.
//

func getInsertionIndex<Item: ListItem>(
    pendingIndex: Int,
    sortedPendingItems: [Item],
    sortedItems: [Item]
) -> Int {
    guard !sortedItems.isEmpty else {
        return 0
    }

    if pendingIndex > 0 {
        let upperItem = sortedPendingItems[pendingIndex - 1]

        if let index = sortedItems.firstIndex(where: {
            $0.stableId == upperItem.stableId
        }) {
            // Insert below upper pending item.
            return index + 1
        }
    }

    if pendingIndex < sortedPendingItems.count {
        let lowerItem = sortedPendingItems[pendingIndex]

        if let index = sortedItems.firstIndex(where: {
            $0.stableId == lowerItem.stableId
        }) {
            // Insert above lower pending item.
            return index
        }
    }

    // Fallback to placing the item at the bottom of the list.
    return sortedItems.count
}
