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
    private let onCommit: ((Item, Item) -> Void)?

    init(
        item: Item,
        deleteItem: @escaping (Item) -> Void,
        onCommit: ((Item, Item) -> Void)? = nil
    ) {
        self.item = item
        self.deleteItem = deleteItem
        self.onCommit = onCommit
        
        self.draft = Item(draftOf: item)
    }

    private var hasFinished = false

    @Published var draft: Item

    var hasEmptyTitle: Bool {
        draft.title.trimmed.isEmpty
    }

    func belongs(to itemId: UUID) -> Bool {
        item.stableId == itemId
    }

    func invalidate() {
        hasFinished = false
    }

    func finalizeEdit() {
        guard !hasFinished else { return }
        hasFinished = true

        let trimmedTitle = draft.title.trimmed

        if trimmedTitle.isEmpty {
            deleteItem(item)
        } else {
            item.title = trimmedTitle
            item.height = draft.height
            
            onCommit?(item, draft)
        }
    }

    func commit() {
        guard !hasFinished else { return }
        hasFinished = true

        item.title = draft.title.trimmed
        item.height = draft.height

        onCommit?(item, draft)
    }

    func delete() {
        guard !hasFinished else { return }
        hasFinished = true

        deleteItem(item)
    }

    /// Special handler called before creating new items.
    func commitTitle() {
        item.title = draft.title.trimmed
    }
}
