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
    @Environment(\.modelContext) private var modelContext
    
    // TODO: watch environment variable to know when the focused list has changed. When it has, immediately execute the task.
    
    @Published var showChecked: Bool = false
    @Published var itemIdsToCheck: Set<ObjectIdentifier> = []
    @Published var itemIdsToUncheck: Set<ObjectIdentifier> = []
    @Published var selectedItems: [Item] = []
    @Published var selectedItemIds: Set<ObjectIdentifier> = []
    
    // Triggers fade animations for checking items.
    @Published var fadeOutTrigger: UUID? = nil
    
    private var itemsToCheck: [Item] = []
    private var itemsToUncheck: [Item] = []
    private var task: Task<Void, Never>?
    private let delay: Duration = .seconds(3)
    
    func toggleItem(_ item: Item, type: ListToggleType) {
        switch type {
        case .staging:
            toggleSelect(item)
            return;
        case .storage: // TODO: change to be local or global (check vs select vs action)
            toggleChecked(for: item)
            return;
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
                itemsToUncheck.removeAll(where: { $0.id == item.id })
                item.isChecked = true
            } else {
                // Schedule the unchecking.
                itemIdsToUncheck.insert(item.id)
                itemsToUncheck.append(item)
            }
        } else {
            if itemIdsToCheck.contains(item.id) {
                // Cancel the checking.
                itemIdsToCheck.remove(item.id)
                itemsToCheck.removeAll(where: { $0.id == item.id })
                item.isChecked = false
            } else {
                // Schedule the checking.
                itemIdsToCheck.insert(item.id)
                itemsToCheck.append(item)
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
            let toCheck = itemsToCheck
            for item in toCheck {
                item.isChecked = true
            }
            
            itemsToCheck.removeAll()
            itemIdsToCheck.removeAll()
            
            // Uncheck items.
            let toUncheck = itemsToUncheck
            for item in toUncheck {
                item.isChecked = false
            }
            
            itemsToUncheck.removeAll()
            itemIdsToUncheck.removeAll()
        }
    }
}
