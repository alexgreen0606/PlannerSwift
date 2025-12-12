//
//  ListUtils.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func generateSortIndex<Item: ListItem>(index: Int, items: [Item]) -> Double {
    var newSortIndex: Double = 0.0

    if items.isEmpty {
        newSortIndex = 0
    } else if index == 0 {
        newSortIndex = items.first!.sortIndex / 2
    } else if index >= items.count {
        newSortIndex = items.last!.sortIndex + 8
    } else {
        let beforeSortIndex = items[index - 1].sortIndex
        let afterSortIndex = items[index].sortIndex
        newSortIndex =
            beforeSortIndex + ((afterSortIndex - beforeSortIndex) / 2)
    }

    return newSortIndex
}
