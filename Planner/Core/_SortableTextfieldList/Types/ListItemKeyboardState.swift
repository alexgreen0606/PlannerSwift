//
//  ListItemKeyboardState.swift
//  Planner
//
//  Created by Alex Green on 9/22/26.
//

/// Allows for state communication from the parent View down to the list items.
struct ListItemKeyboardState<Item: ListItemDetails> {
    let onFocus: (_ item: Item) -> Void
    let onBlur: (_ item: Item) -> Void
}
