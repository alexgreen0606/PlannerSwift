//
//  ListController.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

import Combine
import SwiftData
import SwiftUI

// TODO: add modelType to PlannerEvents to ensure that this controller can call the deletion handler functions as needed.

@MainActor
final class ListController<Item: ListItem>: ObservableObject {
    @Environment(\.modelContext) private var modelContext
    
    // TODO: watch environment variable to know when the focused list has changed. When it has, immediately execute the task.
    
    @Published var completingItems: [Item] = []
    @Published var completingItemIds: Set<ObjectIdentifier> = []
    
    @Published var deletingItems: [Item] = []
    @Published var deletingItemIds: Set<ObjectIdentifier> = []
    
    @Published var selectedItems: [Item] = []
    @Published var selectedItemIds: Set<ObjectIdentifier> = []
    
    // Triggers fade animations for deleting and completing items.
    @Published var fadeOutTrigger: UUID? = nil

    private var task: Task<Void, Never>?
    private let delay: Duration = .seconds(3)
    
    func toggleItem(_ item: Item, type: ToggleType) {
        switch type {
        case .select:
            toggleSelect(item)
            return;
        case .delete:
            toggleDelete(item)
            return;
        case .complete:
            toggleComplete(item)
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

    private func toggleComplete(_ item: Item) {
        if completingItemIds.contains(item.id) {
            completingItemIds.remove(item.id)
            completingItems.removeAll(where: { $0.id == item.id })
        } else {
            completingItemIds.insert(item.id)
            completingItems.append(item)
        }

        startCountdown()
    }
    
    private func toggleDelete(_ item: Item) {
        if deletingItemIds.contains(item.id) {
            deletingItemIds.remove(item.id)
            deletingItems.removeAll(where: { $0.id == item.id })
            item.isComplete = false
        } else {
            deletingItemIds.insert(item.id)
            deletingItems.append(item)
            item.isComplete = true
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

            // Delete queued items.
            let toDelete = deletingItems
            deletingItems.removeAll()
            deletingItemIds.removeAll()
            
            for item in toDelete {
                modelContext.delete(item)
                
                // TODO: trigger side effects of deletion
            }
            
            // Complete queued items.
            let toComplete = completingItems
            completingItems.removeAll()
            completingItemIds.removeAll()
            
            for item in toComplete {
                item.isComplete = true
                
                // TODO: move all items to the bottom of their list, appending 8 to each sortIndex
            }
        }
    }
}
