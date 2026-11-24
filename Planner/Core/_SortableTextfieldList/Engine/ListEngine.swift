//
//  ListEngine.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Combine
import SwiftUI

@MainActor
final class ListEngine<Item: ListItem>: ObservableObject {
    private let toggleState: ListItemToggleState<Item>?
    private let settings: Settings

    init(
        toggleState: ListItemToggleState<Item>? = nil,
        settings: Settings
    ) {
        self.toggleState = toggleState
        self.settings = settings
    }

    deinit {
        toggleTransitionTask?.cancel()
    }

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var toggleTransitionTask: Task<Void, Never>?

    /// Drafts are stored here (rather than on the items) so items can be lightweight value types.
    /// Intentionally not published: drafts are `@Observable` themselves.
    private var drafts: [Item.ID: Item.Draft] = [:]

    @Published var pendingFocusId: Item.ID? = nil

    @Published private(set) var activeEditor: EditorSession<Item>?
    @Published private(set) var previousEditor: EditorSession<Item>?

    @Published private(set) var newlyCompletedIds: Set<Item.ID> = []
    @Published private(set) var newlyPendingIds: Set<Item.ID> = []

    @Published private(set) var fadingOpacity: Double = 1

    /// Same as newlyCompletedIds, but waits 1 second before clearing to allow UI to settle.
    @Published private(set) var fadingItemIds: Set<Item.ID> = []

    @Published var isSelectMode: Bool = false
    @Published private(set) var selectedItems: [Item] = []
    @Published private(set) var selectedItemIds: Set<Item.ID> = []

    var isFocused: Bool {
        activeEditor != nil
    }

    var canToggleItems: Bool {
        toggleState != nil
    }

    var dimWhenSelecting: Color? {
        isSelectMode ? Color.tertiary : nil
    }

    // MARK: - Draft Functions

    /// Returns the item's draft, creating one if needed.
    func draft(for item: Item) -> Item.Draft {
        if let draft = existingDraft(for: item.id) {
            return draft
        }

        let newDraft = Item.Draft(item: item)
        drafts[item.id] = newDraft
        return newDraft
    }

    /// Returns the item's draft only if one already exists.
    func existingDraft(for itemId: Item.ID) -> Item.Draft? {
        drafts[itemId]
    }

    func discardDraft(for itemId: Item.ID) {
        drafts[itemId] = nil
    }

    // MARK: - Focus Control Functions

    func isItemFocused(_ item: Item) -> Bool {
        activeEditor?.belongs(to: item.id) == true
    }

    func wasItemFocused(_ item: Item) -> Bool {
        previousEditor?.belongs(to: item.id) == true
    }

    /// Passes the first responder to this item.
    func beginEditing(_ editor: EditorSession<Item>) {
        if activeEditor?.belongs(to: editor.item.id) != true {
            // Editing a new item. Ensure its draft reflects the latest item data.
            editor.syncDraft()
        }

        if activeEditor !== editor {
            editor.invalidate()
        }

        previousEditor = activeEditor
        activeEditor = editor
    }

    /// Finalizes edits once the first responder releases this item.
    func handleEndEditing(_ editor: EditorSession<Item>) {
        editor.finalizeEdit()

        if previousEditor === editor {
            previousEditor = nil
        }

        if activeEditor === editor {
            activeEditor = nil
        }
    }

    func blur() {
        previousEditor = activeEditor
        activeEditor = nil
    }

    func openSheet(for item: Item, open: @escaping () -> Void) {
        if let activeEditor {
            if activeEditor.belongs(to: item.id) {
                /// Force-commit the focused item instead of allowing the blur handler to potentially
                /// delete it.
                activeEditor.commit()
            }

            blur()
        }

        DispatchQueue.main.async {
            open()
        }
    }

    /// New items cannot be created next to empty titles.
    /// This ensures all items in the list have up-to-date titles before evaluating new item creation.
    func commitFocusedItemTitle() {
        activeEditor?.commitTitle()
    }

    // MARK: - Toggle Functions

    func isItemToggled(_ item: Item) -> Bool {
        toggleState?.isToggled(item) ?? false
    }

    func isItemInPendingList(_ item: Item) -> Bool {
        (!isItemToggled(item)
            && !newlyPendingIds.contains(item.id))
            || newlyCompletedIds.contains(item.id)
    }

    func isItemInCompletedList(_ item: Item) -> Bool {
        (isItemToggled(item)
            && !newlyCompletedIds.contains(item.id))
            || newlyPendingIds.contains(item.id)
    }

    func toggleItem(_ item: Item) {
        feedbackGenerator.impactOccurred()

        if isSelectMode {
            toggleSelection(item)
        } else {
            toggleCompletion(item)
        }
    }

    func toggleSelectMode() {
        withAnimation {
            if isSelectMode {
                isSelectMode = false
                selectedItemIds = []
                selectedItems = []
            } else {
                blur()
                toggleTransitionTask?.cancel()
                fadingOpacity = 1
                newlyCompletedIds = []
                newlyPendingIds = []
                isSelectMode = true
            }
        }
    }

    func toggleSelectAll(visibleItems: [Item]) {
        feedbackGenerator.impactOccurred()

        if selectedItemIds.count == visibleItems.count {
            selectedItemIds = []
            selectedItems = []
        } else {
            selectedItemIds = Set(visibleItems.map(\.id))
            selectedItems = visibleItems
        }
    }

    func clearSelections() {
        selectedItemIds = []
        selectedItems = []
    }

    // MARK: - Helper Functions

    // MARK: Completed Items

    private func toggleCompletion(_ item: Item) {
        guard let toggleState else { return }

        if isFocused { blur() }

        if settings.toggleTransitionDuration != .instant {
            if toggleState.isToggled(item) {
                if !newlyCompletedIds.contains(item.id) {
                    newlyPendingIds.insert(item.id)
                } else {
                    newlyCompletedIds.remove(item.id)
                }
            } else {
                if !newlyPendingIds.contains(item.id) {
                    newlyCompletedIds.insert(item.id)
                } else {
                    newlyPendingIds.remove(item.id)
                }
            }

            fadingItemIds = newlyCompletedIds
            beginFade()
        } else {
            newlyCompletedIds = []
            newlyPendingIds = []
            fadingItemIds = []
        }

        toggleState.setIsToggled(item, !toggleState.isToggled(item))
    }

    private func beginFade() {
        toggleTransitionTask?.cancel()

        fadingOpacity = 1

        toggleTransitionTask = Task {
            do {
                // Fade items out (500ms delay).
                try await Task.sleep(for: .milliseconds(500))

                withAnimation(
                    .linear(duration: settings.toggleTransitionDuration.seconds)
                ) {
                    self.fadingOpacity = 0
                }

                // Move items to their new list (user-defined delay).
                try await Task.sleep(
                    for: settings.toggleTransitionDuration.duration
                )

                withAnimation {
                    self.newlyCompletedIds = []
                    self.newlyPendingIds = []
                }

                // Display faded items in UI. Allows time for UI filters to update (1 second delay).
                try await Task.sleep(for: .seconds(1))

                self.fadingItemIds = []
            } catch {}
        }
    }

    // MARK: Selected Items

    private func toggleSelection(_ item: Item) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)

            if let index = selectedItems.firstIndex(where: {
                $0.id == item.id
            }) {
                selectedItems.remove(at: index)
            }
        } else {
            selectedItemIds.insert(item.id)
            selectedItems.append(item)
        }
    }
}
