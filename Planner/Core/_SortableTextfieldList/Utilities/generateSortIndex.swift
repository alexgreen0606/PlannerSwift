//
//  generateSortIndex.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

private let SORT_INDEX_SPACING = 512.0
private let MINIMUM_SORT_INDEX_GAP = 0.0001

func generateSortIndex(
    index: Int,

    // May or may not contain the item being placed.
    sortedItems: [ChecklistItem]
) -> Double {
    guard !sortedItems.isEmpty else {
        return SORT_INDEX_SPACING
    }

    if index >= sortedItems.count {
        return sortedItems.last!.sortIndex + SORT_INDEX_SPACING
    }

    var beforeSortIndex = index == 0 ? 0 : sortedItems[index - 1].sortIndex
    var afterSortIndex = sortedItems[index].sortIndex

    let gap = afterSortIndex - beforeSortIndex
    if gap < MINIMUM_SORT_INDEX_GAP {
        normalizeSortIndices(items: sortedItems)

        beforeSortIndex = index == 0 ? 0 : sortedItems[index - 1].sortIndex
        afterSortIndex = sortedItems[index].sortIndex
    }

    return beforeSortIndex + ((afterSortIndex - beforeSortIndex) / 2)
}

// MARK: - Body

@MainActor
private func normalizeSortIndices(items: [ChecklistItem]) {
    for (i, item) in items.enumerated() {
        item.sortIndex = SORT_INDEX_SPACING * Double(i + 1)
    }
}
