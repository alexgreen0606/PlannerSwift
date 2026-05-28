//
//  ScrollViewProxy+.swift
//  Planner
//
//  Created by Alex Green on 5/20/26.
//

import SwiftUI

extension ScrollViewProxy {
    func scrollToBottomOfList() {
        DispatchQueue.main.async {
            withAnimation {
                scrollTo(
                    ListIds.PENDING_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }

    func scrollToNewItem<C: Collection, ID: Hashable>(
        oldItems: C,
        newItems: C,
        getId: @escaping (C.Element) -> ID
    ) where C.Element: Hashable {
        guard
            let newItem = Set(newItems)
            .subtracting(Set(oldItems))
            .first
        else { return }

        DispatchQueue.main.async {
            withAnimation {
                scrollTo(
                    getId(newItem),
                    anchor: .bottom
                )
            }
        }
    }
}
