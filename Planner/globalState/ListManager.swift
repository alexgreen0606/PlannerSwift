//
//  ListManager.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

import Combine
import SwiftData
import SwiftUI

@MainActor
final class ListManager<Item: ListItem>: ObservableObject {
    @Published var itemIdsToCheck: Set<ObjectIdentifier> = []
    @Published var itemIdsToUncheck: Set<ObjectIdentifier> = []
    @Published var selectedItems: [Item] = []
    @Published var selectedItemIds: Set<ObjectIdentifier> = []

    // Triggers fade animations for checking items.
    @Published var fadeOutTrigger: UUID? = nil

    private var pendingChecks: [Item] = []
    private var pendingUnchecks: [Item] = []
    private var task: Task<Void, Never>?
    private let delay: Duration = .seconds(3)

    deinit {
        task?.cancel()
    }

    func toggleItem(_ item: Item, type: ListToggleType) {
        switch type {
        case .staging:
            toggleSelect(item)
            return
        case .storage:
            toggleChecked(for: item)
            return
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
        if item.isChecked {
            if itemIdsToUncheck.contains(item.id) {
                // Cancel the unchecking.
                itemIdsToUncheck.remove(item.id)
                pendingUnchecks.removeAll(where: { $0.id == item.id })
                item.isChecked = true
            } else {
                // Schedule the unchecking.
                itemIdsToUncheck.insert(item.id)
                pendingUnchecks.append(item)
            }
        } else {
            if itemIdsToCheck.contains(item.id) {
                // Cancel the checking.
                itemIdsToCheck.remove(item.id)
                pendingChecks.removeAll(where: { $0.id == item.id })
                item.isChecked = false
            } else {
                // Schedule the checking.
                itemIdsToCheck.insert(item.id)
                pendingChecks.append(item)
            }
        }

        startCountdown()
    }

    private func startCountdown() {
        task?.cancel()
        fadeOutTrigger = UUID()
        task = Task {
            do {
                try await Task.sleep(for: delay)
            } catch { return }

            // Check items.
            let toCheck = pendingChecks
            for item in toCheck {
                item.isChecked = true
            }

            pendingChecks.removeAll()
            itemIdsToCheck.removeAll()

            // Uncheck items.
            let toUncheck = pendingUnchecks
            for item in toUncheck {
                item.isChecked = false
            }

            pendingUnchecks.removeAll()
            itemIdsToUncheck.removeAll()
        }
    }
}
