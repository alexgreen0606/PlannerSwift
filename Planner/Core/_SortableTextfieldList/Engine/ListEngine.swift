//
//  ListEngine.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

import Combine
import SwiftUI

@MainActor
final class ListEngine<Item: ListItemDetails>: ObservableObject {
    private let toggleState: ListItemToggleState<Item>?
    private let settings: Settings

    init(toggleState: ListItemToggleState<Item>? = nil, settings: Settings) {
        self.toggleState = toggleState
        self.settings = settings
    }

    deinit {
        toggleTransitionTask?.cancel()
    }

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var toggleTransitionTask: Task<Void, Never>?

    @Published var focusedId: UUID? = nil
    @Published var pendingFocusId: UUID? = nil
    @Published var keyboardOwnerId: UUID? = nil

    /// Protects items from being deleted on blur of their textfield.
    @Published var protectedId: UUID? = nil
    
    @Published var forceSyncFocusedItem: Bool = false

    @Published private(set) var newlyCompletedIds: Set<UUID> = []
    @Published private(set) var newlyPendingIds: Set<UUID> = []

    @Published private(set) var fadingOpacity: Double = 1

    /// Same as newlyCompletedIds, but waits 1 second before clearing to allow UI to settle.
    @Published private(set) var fadingItemIds: Set<UUID> = []

    @Published var isSelectMode: Bool = false
    @Published private(set) var selectedItems: [Item] = []
    @Published private(set) var selectedItemIds: Set<UUID> = []

    var canToggleItems: Bool {
        toggleState != nil
    }

    func isItemToggled(_ item: Item) -> Bool {
        toggleState?.isToggled(item) ?? false
    }

    func isItemInPendingList(_ item: Item) -> Bool {
        (!isItemToggled(item)
            && !newlyPendingIds.contains(item.stableId))
            || newlyCompletedIds.contains(item.stableId)
    }

    func isItemInCompletedList(_ item: Item) -> Bool {
        (isItemToggled(item)
            && !newlyCompletedIds.contains(item.stableId))
            || newlyPendingIds.contains(item.stableId)
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
        feedbackGenerator.impactOccurred()

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
        guard let toggleState else { return }

        if focusedId == item.stableId {
            // Item is focused. Blur it.
            focusedId = nil
        }

        if settings.toggleTransitionDuration != .instant {
            if toggleState.isToggled(item) {
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
                try await Task.sleep(for: settings.toggleTransitionDuration.duration)

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
