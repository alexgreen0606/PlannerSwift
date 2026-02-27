//
//  ListManager.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

import Combine
import SwiftData
import SwiftUI

typealias StatusGuard<Item> = (_ item: Item) -> Bool

@MainActor
final class ListManager<Item: ListItem>: ObservableObject {
    private var toggleItem: StatusGuard<Item>?
    private let isItemChecked: StatusGuard<Item>?

    init(
        isItemChecked: StatusGuard<Item>? = nil
    ) {
        self.isItemChecked = isItemChecked
    }

    func setToggleItem(_ toggleItem: @escaping StatusGuard<Item>) {
        self.toggleItem = toggleItem
    }

    @AppStorage("toggleTransitionDuration") private
        var toggleTransitionDuration: ToggleTransitionDuration =
            ToggleTransitionDuration.threeSeconds

    @Published var newlyCheckedIds: Set<UUID> = []
    @Published var newlyUncheckedIds: Set<UUID> = []

    @Published var selectedItems: [Item] = []
    @Published var selectedItemIds: Set<UUID> = []

    // Keeps faded items hidden for 1 second after they have moved.
    @Published var fadingItemIds: Set<UUID> = []

    // Controls fading of checked items.
    @Published var fadingOpacity: Double = 1
    
    @Published var focusedId: UUID? = nil
    
    @Published var pendingFocusId: UUID? = nil

    private var task: Task<Void, Never>?
    private var toggleType: ListToggleType = .check

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
                selectedItems = []
                selectedItemIds = []
            } else {
                focusedId = nil
                newlyCheckedIds.removeAll()
                newlyUncheckedIds.removeAll()
                fadingOpacity = 1
                task?.cancel()
                toggleType = .select
            }
        }
    }

    func toggleSelectAll(visibleItems: [Item]) {
        if selectedItemIds.count == visibleItems.count {
            selectedItemIds = []
            selectedItems = []
        } else {
            selectedItems = visibleItems
            selectedItemIds = Set(
                visibleItems.map { $0.stableId }
            )
        }
    }

    func toggleItem(_ item: Item) {
        switch toggleType {
        case .select:
            toggleSelect(item)
        case .check:
            toggleChecked(for: item)
        }
    }

    private func toggleSelect(_ item: Item) {
        if selectedItemIds.contains(item.stableId) {
            selectedItemIds.remove(item.stableId)
            selectedItems.removeAll(where: { $0.stableId == item.stableId })
        } else {
            selectedItemIds.insert(item.stableId)
            selectedItems.append(item)
        }
    }

    private func toggleChecked(for item: Item) {
        
        // Blur this item if it is focused.
        if focusedId == item.stableId {
            focusedId = nil
        }

        let isChecked = isItemChecked?(item) ?? item.isChecked

        if toggleTransitionDuration != .instant {
            if isChecked {
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

        if toggleItem?(item) != true {
            item.isChecked.toggle()
        }

    }

    private func beginFade() {
        task?.cancel()
        fadingOpacity = 1

        task = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .milliseconds(500))

                withAnimation(
                    .linear(duration: toggleTransitionDuration.duration.seconds)
                ) {
                    self.fadingOpacity = 0
                }

                // Keep items around as they fade away.
                try await Task.sleep(for: toggleTransitionDuration.duration)

                self.newlyCheckedIds.removeAll()
                self.newlyUncheckedIds.removeAll()

                // Extra delay before displaying checked items in UI (allow time for them to leave the upper list).
                try await Task.sleep(for: .seconds(1))
                self.fadingItemIds.removeAll()

            } catch {
            }
        }
    }
}
