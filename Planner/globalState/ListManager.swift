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
    private var isItemChecked: StatusGuard<Item>?

    func setToggleItem(_ toggleItem: @escaping StatusGuard<Item>) {
        self.toggleItem = toggleItem
    }
    
    func setStatusChecker(_ isItemChecked: @escaping StatusGuard<Item>) {
        self.isItemChecked = isItemChecked
    }

    init() {}

    @Published var newlyCheckedIds: Set<PersistentIdentifier> = []
    @Published var newlyUncheckedIds: Set<PersistentIdentifier> = []

    // Keeps faded items hidden for 1 second after they have moved.
    @Published var fadingItemIds: Set<PersistentIdentifier> = []

    @Published var selectedItems: [Item] = []
    @Published var selectedItemIds: Set<PersistentIdentifier> = []

    // Controls fading of checked items.
    @Published var fadingOpacity: Double = 1

    private var task: Task<Void, Never>?
    private let fadeDuration: Duration = .seconds(3)

    deinit {
        task?.cancel()
    }

    func toggleItem(_ item: Item, type: ListToggleType) {
        switch type {
        case .staging:
            toggleSelect(item)
        case .storage:
            toggleChecked(for: item)
        }
    }

    private func toggleSelect(_ item: Item) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
            selectedItems.removeAll(where: { $0.id == item.id })
        } else {
            selectedItemIds.insert(item.id)
            selectedItems.append(item)
        }
    }

    private func toggleChecked(for item: Item) {
        let isChecked = isItemChecked?(item) ?? item.isChecked
        
        if isChecked {
            if !newlyCheckedIds.contains(item.id) {
                newlyUncheckedIds.insert(item.id)
            } else {
                newlyCheckedIds.remove(item.id)
            }
        } else {
            if !newlyUncheckedIds.contains(item.id) {
                newlyCheckedIds.insert(item.id)
            } else {
                newlyUncheckedIds.remove(item.id)
            }
        }

        if toggleItem?(item) != true {
            item.isChecked.toggle()
        }

        fadingItemIds = newlyCheckedIds

        beginFade()
    }

    private func beginFade() {
        task?.cancel()
        fadingOpacity = 1

        task = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .milliseconds(500))

                withAnimation(.linear(duration: fadeDuration.seconds)) {
                    self.fadingOpacity = 0
                }

                // Keep items around as they fade away.
                try await Task.sleep(for: fadeDuration)

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
