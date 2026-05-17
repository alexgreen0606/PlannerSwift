//
//  generateSortIndex.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

// TODO: remove sort index from ListItem?

func generateSortIndex<Item: ListItem>(
    index: Int,

    // May or may not contain the item being placed.
    sortedItems: [Item]
) -> Double {
    if sortedItems.isEmpty {
        return 8.0

    } else if index == 0 {
        return sortedItems.first!.sortIndex / 2

    } else if index >= sortedItems.count {
        return sortedItems.last!.sortIndex + 8
    }

    let beforeSortIndex = sortedItems[index - 1].sortIndex
    let afterSortIndex = sortedItems[index].sortIndex

    return beforeSortIndex + ((afterSortIndex - beforeSortIndex) / 2)
}
