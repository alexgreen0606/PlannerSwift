//
//  ModelContext+.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import SwiftData

extension ModelContext {
    @MainActor
    func safeSave(_ source: String) {
        do {
            try save()
        } catch {
            assertionFailure("ERROR ModelContext+.safeSave_\(source): \(error)")
        }
    }

    @MainActor
    func safeDelete<Item: PersistentModel>(_ item: Item) {
        delete(item)
        safeSave("ModelContext+.safeDelete")
    }

    @MainActor
    func safeBulkDelete<Item: PersistentModel>(_ items: [Item]) {
        do {
            try transaction {
                for item in items {
                    delete(item)
                }
            }
        } catch {
            assertionFailure(
                "ERROR ModelContext+.safeBulkDelete.transaction: \(error)"
            )
            return
        }

        safeSave("ModelContext+.safeBulkDelete")
    }

    @MainActor
    func insertIfNeeded<Item: PersistentModel>(_ item: Item) {
        guard item.modelContext == nil else { return }
        insert(item)
    }
}
