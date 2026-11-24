//
//  ListItemToggleState_old.swift
//  Planner
//
//  Created by Alex Green on 6/20/26.
//

struct ListItemToggleState_old<Item: ListItemDetails> {
    let isToggled: (_ item: Item) -> Bool
    let setIsToggled: (_ item: Item, _ isToggled: Bool) -> Void
}
