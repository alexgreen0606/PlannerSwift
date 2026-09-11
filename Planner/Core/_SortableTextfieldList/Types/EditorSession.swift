//
//  EditorSession.swift
//  Planner
//
//  Created by Alex Green on 9/9/26.
//

import Combine
import Foundation

final class EditorSession<Item: ListItemDetails>: ObservableObject {
    let item: Item
    
    private let deleteItem: (Item) -> Void
    private let onCommit: ((Item) -> Void)?

    init(
        item: Item,
        deleteItem: @escaping (Item) -> Void,
        onCommit: ((Item) -> Void)?
    ) {
        self.item = item
        self.deleteItem = deleteItem
        self.onCommit = onCommit

        self.title = item.title
        self.height = item.height
    }

    private var hasCommitted = false

    @Published var title: String
    @Published var height: CGFloat

    var hasEmptyTitle: Bool {
        title.trimmed.isEmpty
    }
    
    func belongs(to itemId: UUID) -> Bool {
        item.stableId == itemId
    }

    func invalidate() {
        hasCommitted = false
    }

    func finalizeEdit() {
        guard !hasCommitted else { return }
        hasCommitted = true
        
        let trimmedTitle = title.trimmed

        if trimmedTitle.isEmpty {
            deleteItem(item)
        } else {
            commit(trimmedTitle: trimmedTitle)
        }
    }
    
    func commit(trimmedTitle: String? = nil) {
        item.title = trimmedTitle ?? title.trimmed
        item.height = height
        
        if let onCommit {
            onCommit(item)
            title = item.title
        }
    }
    
    func delete() {
        deleteItem(item)
    }
}
