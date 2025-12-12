//
//  CompletionScheduler.swift
//  Planner
//
//  Created by Alex Green on 12/2/25.
//

import SwiftUI
import SwiftData

@MainActor
final class ListController<Item: ListItem>: ObservableObject {
    @Published var completionItems: [Item] = []
    @Published var deletionItems: [Item] = []
    
    @Environment(\.modelContext) private var modelContext
    
    private var task: Task<Void, Never>?
    private let delay: Duration = .seconds(3)

    func toggleComplete(_ item: Item) {
        // Remove from deletion items if it exists there
        if deletionItems.contains(where: { $0.id == item.id }) {
            deletionItems.removeAll(where: { $0.id == item.id })
        }
        
        if completionItems.contains(where: { $0.id == item.id }) {
            completionItems.removeAll(where: { $0.id == item.id })
        } else {
            completionItems.append(item)
        }

        startCountdown()
    }
    
    func toggleDelete(_ item: Item) {
        // Remove from completion items if it exists there.
        if completionItems.contains(where: { $0.id == item.id }) {
            completionItems.removeAll(where: { $0.id == item.id })
        }
        
        if deletionItems.contains(where: { $0.id == item.id }) {
            deletionItems.removeAll(where: { $0.id == item.id })
        } else {
            deletionItems.append(item)
        }

        startCountdown()
    }

    func startCountdown() {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(for: delay)
            } catch { return }

            performTask()
        }
    }

    private func performTask() {
        let toDelete = deletionItems
        let toComplete = completionItems
        
        deletionItems = []
        completionItems = []
        
        for item in toDelete {
            modelContext.delete(item)
        }
        
        for item in toComplete {
            item.isComplete = true
        }
        
        
        // TODO: handle external deletions as well, including calendar refresh
    }
}
