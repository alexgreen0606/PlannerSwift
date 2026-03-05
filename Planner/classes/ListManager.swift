//
//  ListManager.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

// Clean

import Combine
import SwiftData
import SwiftUI

enum ListToggleType: String {
    case check
    case select
}

@MainActor
final class ListManager<Item: ListItem>: ObservableObject {

    @AppStorage("toggleTransitionDuration") private
        var toggleTransitionDuration: ToggleTransitionDuration =
            ToggleTransitionDuration.threeSeconds

    @Published var focusedId: UUID? = nil
    @Published var pendingFocusId: UUID? = nil

    // Protects items from being deleted on blur of their textfield.
    @Published var protectedId: UUID? = nil
    
    @Published var toggleType: ListToggleType = .check

    @Published private(set) var newlyCheckedIds: Set<UUID> = []
    @Published private(set) var newlyUncheckedIds: Set<UUID> = []

    @Published private(set) var selectedItems: [Item] = []
    @Published private(set) var selectedItemIds: Set<UUID> = []

    @Published private(set) var fadingOpacity: Double = 1

    // Same as newlyCheckedIds, but waits 1 second before clearing to allow UI to settle.
    @Published private(set) var fadingItemIds: Set<UUID> = []

    private var task: Task<Void, Never>?

    deinit {
        task?.cancel()
    }

    var isSelectMode: Bool {
        toggleType == .select
    }

    func toggleSelectMode() {
        withAnimation {
            if isSelectMode {
                toggleType = .check
                selectedItemIds = []
                selectedItems = []
            } else {
                focusedId = nil
                task?.cancel()
                fadingOpacity = 1
                newlyCheckedIds = []
                newlyUncheckedIds = []
                toggleType = .select
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

    func toggleItem(_ item: Item) {
        switch toggleType {
        case .select:
            toggleSelect(item)
        case .check:
            toggleCheck(item)
        }
    }

    // MARK: - Helper Functions

    private func toggleSelect(_ item: Item) {
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

    private func toggleCheck(_ item: Item) {

        // Blur this item if it is focused.
        if focusedId == item.stableId {
            focusedId = nil
        }

        if toggleTransitionDuration != .instant {
            if item.isChecked {
                if !newlyCheckedIds.contains(item.stableId) {
                    newlyUncheckedIds.insert(item.stableId)
                } else {
                    newlyCheckedIds.remove(item.stableId)
                }
            } else {
                if !newlyUncheckedIds.contains(item.stableId) {
                    newlyCheckedIds.insert(item.stableId)
                } else {
                    newlyUncheckedIds.remove(item.stableId)
                }
            }

            fadingItemIds = newlyCheckedIds
            beginFade()

        } else {
            newlyCheckedIds = []
            newlyUncheckedIds = []
            fadingItemIds = []
        }

        item.isChecked.toggle()
    }

    private func beginFade() {
        task?.cancel()
        fadingOpacity = 1

        task = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))

                withAnimation(
                    .linear(duration: toggleTransitionDuration.value.seconds)
                ) {
                    self.fadingOpacity = 0
                }

                // Keep items around before transitioning them to their new list.
                try await Task.sleep(for: toggleTransitionDuration.value)

                self.newlyCheckedIds = []
                self.newlyUncheckedIds = []

                // Extra delay before displaying faded items in UI (allow time for SwiftData query to update).
                try await Task.sleep(for: .seconds(1))
                self.fadingItemIds = []
            } catch {}
        }
    }

}
