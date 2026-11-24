//
//  ListItemToggleState.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

struct ListItemToggleState<Item: ListItem> {
    let isToggled: (_ item: Item) -> Bool
    let setIsToggled: (_ item: Item, _ isToggled: Bool) -> Void
}
