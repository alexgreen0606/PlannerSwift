//
//  canCreateItem.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

@MainActor
func canCreateItem<Item: ListItem>(
    at index: Int,
    in sortedItems: [Item]
) -> Bool {
    if index > 0,
       sortedItems[index - 1].title.isEmpty
    {
        // Upper neighbor is empty. Don't create it.
        return false
    }

    if index < sortedItems.count,
       sortedItems[index].title.isEmpty
    {
        // Lower neighbor is empty. Don't create it.
        return false
    }

    return true
}
