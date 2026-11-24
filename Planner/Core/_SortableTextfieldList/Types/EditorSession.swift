//
//  EditorSession.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Combine
import Foundation

final class EditorSession<Item: ListItem>: ObservableObject {
    let item: Item

    private let deleteItem: (Item) -> Void
    private let onCommit: ((Item) -> Void)?

    init(
        item: Item,
        draft: Item.Draft,
        deleteItem: @escaping (Item) -> Void,
        onCommit: ((Item) -> Void)? = nil
    ) {
        self.item = item
        self.deleteItem = deleteItem
        self.onCommit = onCommit

        self.draft = draft
    }

    private var hasFinished = false

    @Published var draft: Item.Draft

    var hasEmptyTitle: Bool {
        draft.title.trimmed.isEmpty
    }

    func belongs(to itemId: Item.ID) -> Bool {
        item.id == itemId
    }

    func invalidate() {
        hasFinished = false
    }

    func finalizeEdit() {
        guard !hasFinished else { return }
        hasFinished = true

        if hasEmptyTitle {
            deleteItem(item)
        } else {
            commitDraft()
        }
    }

    func commit() {
        guard !hasFinished else { return }
        hasFinished = true

        commitDraft()
    }

    func delete() {
        guard !hasFinished else { return }
        hasFinished = true

        deleteItem(item)
    }

    /// Special handler called before creating new items.
    func commitTitle() {
        draft.commitTitle(to: item)
    }

    /// Re-syncs the draft with its item. Called when editing begins so that external changes
    /// (ex: an EventKit update) are never overwritten by a stale draft.
    func syncDraft() {
        draft.sync(from: item)
    }

    // MARK: - Helpers

    private func commitDraft() {
        draft.commit(to: item)
        onCommit?(item)
        draft.sync(from: item)
    }
}
