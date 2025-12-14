//
//  ListUtils.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func generateSortIndex<Item: ListItem>(
    index: Int,
    items: [Item] // May or may not contain the item.
) -> Double {
    if items.isEmpty {
        return 8.0
    } else if index == 0 {
        return items.first!.sortIndex / 2
    } else if index >= items.count {
        return items.last!.sortIndex + 8
    } else {
        let beforeSortIndex = items[index - 1].sortIndex
        let afterSortIndex = items[index].sortIndex
        return beforeSortIndex + ((afterSortIndex - beforeSortIndex) / 2)
    }
}
