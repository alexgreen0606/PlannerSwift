//
//  generateSortIndex.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func generateSortIndex(
    index: Int,
    // May or may not contain the item being placed.
    sortedItems: [ChecklistItem]
) -> Double {
    guard !sortedItems.isEmpty else {
        return ChecklistsData.SORT_INDEX_SPACING
    }

    if index >= sortedItems.count {
        return sortedItems.last!.sortIndex
            + ChecklistsData.SORT_INDEX_SPACING
    }

    var beforeSortIndex = index == 0 ? 0 : sortedItems[index - 1].sortIndex
    var afterSortIndex = sortedItems[index].sortIndex

    let gap = afterSortIndex - beforeSortIndex
    if gap < ChecklistsData.MINIMUM_SORT_INDEX_GAP {
        normalizeSortIndices(items: sortedItems)

        beforeSortIndex = index == 0 ? 0 : sortedItems[index - 1].sortIndex
        afterSortIndex = sortedItems[index].sortIndex
    }

    return beforeSortIndex + ((afterSortIndex - beforeSortIndex) / 2)
}

// MARK: - Normalization Function

@MainActor
private func normalizeSortIndices(items: [ChecklistItem]) {
    for (i, item) in items.enumerated() {
        item.sortIndex =
            ChecklistsData.SORT_INDEX_SPACING * Double(i + 1)
    }
}
