//
//  ListEngine.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

import Combine
import SwiftUI

@MainActor
final class ListEngine<Item: ListItem>: ObservableObject {
    deinit {
        toggleTransitionTask?.cancel()
    }

    @AppStorage("toggleTransitionDuration") private var toggleTransitionDuration: ToggleTransitionDuration =
        .threeSeconds

    @Published var focusedId: UUID? = nil
    @Published var pendingFocusId: UUID? = nil

    /// Protects items from being deleted on blur of their textfield.
    @Published var protectedId: UUID? = nil

    @Published private(set) var newlyCompletedIds: Set<UUID> = []
    @Published private(set) var newlyPendingIds: Set<UUID> = []

    @Published private(set) var fadingOpacity: Double = 1

    /// Same as newlyCompletedIds, but waits 1 second before clearing to allow UI to settle.
    @Published private(set) var fadingItemIds: Set<UUID> = []

    @Published var isSelectMode: Bool = false
    @Published private(set) var selectedItems: [Item] = []
    @Published private(set) var selectedItemIds: Set<UUID> = []

    private var toggleTransitionTask: Task<Void, Never>?

    func isItemInPendingList(_ item: Item) -> Bool {
        (!item.isCompleted
            && !newlyPendingIds.contains(item.stableId))
            || newlyCompletedIds.contains(item.stableId)
    }

    func isItemInCompletedList(_ item: Item) -> Bool {
        (item.isCompleted
            && !newlyCompletedIds.contains(item.stableId))
            || newlyPendingIds.contains(item.stableId)
    }

    func toggleItem(_ item: Item) {
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
                focusedId = nil
                toggleTransitionTask?.cancel()
                fadingOpacity = 1
                newlyCompletedIds = []
                newlyPendingIds = []
                isSelectMode = true
            }
        }
    }

    func toggleSelectAll(visibleItems: [Item]) {
        if selectedItemIds.count == visibleItems.count {
            selectedItemIds = []
            selectedItems = []
        } else {
            selectedItemIds = Set(visibleItems.map(\.stableId))
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
        if focusedId == item.stableId {
            // Item is focused. Blur it.
            focusedId = nil
        }

        if toggleTransitionDuration != .instant {
            if item.isCompleted {
                if !newlyCompletedIds.contains(item.stableId) {
                    newlyPendingIds.insert(item.stableId)
                } else {
                    newlyCompletedIds.remove(item.stableId)
                }
            } else {
                if !newlyPendingIds.contains(item.stableId) {
                    newlyCompletedIds.insert(item.stableId)
                } else {
                    newlyPendingIds.remove(item.stableId)
                }
            }

            fadingItemIds = newlyCompletedIds
            beginFade()
        } else {
            newlyCompletedIds = []
            newlyPendingIds = []
            fadingItemIds = []
        }

        item.isCompleted.toggle()
    }

    private func beginFade() {
        toggleTransitionTask?.cancel()

        fadingOpacity = 1

        toggleTransitionTask = Task {
            do {
                // Fade items out (500ms delay).
                try await Task.sleep(for: .milliseconds(500))

                withAnimation(
                    .linear(duration: toggleTransitionDuration.seconds)
                ) {
                    self.fadingOpacity = 0
                }

                // Move items to their new list (user-defined delay).
                try await Task.sleep(for: toggleTransitionDuration.duration)

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
        if selectedItemIds.contains(item.stableId) {
            selectedItemIds.remove(item.stableId)

            if let index = selectedItems.firstIndex(where: {
                $0.stableId == item.stableId
            }) {
                selectedItems.remove(at: index)
            }
        } else {
            selectedItemIds.insert(item.stableId)
            selectedItems.append(item)
        }
    }
}
