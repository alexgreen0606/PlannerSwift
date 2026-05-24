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

    // Insert below upper pending item.
    if pendingIndex > 0 {
        let upperItem = sortedPendingItems[pendingIndex - 1]

        if let index = sortedItems.firstIndex(where: {
            $0.stableId == upperItem.stableId
        }) {
            return index + 1
        }
    }

    // Insert above lower pending item.
    if pendingIndex < sortedPendingItems.count {
        let lowerItem = sortedPendingItems[pendingIndex]

        if let index = sortedItems.firstIndex(where: {
            $0.stableId == lowerItem.stableId
        }) {
            return index
        }
    }

    return sortedItems.count
}
