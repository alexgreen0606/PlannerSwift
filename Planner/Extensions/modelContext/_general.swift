//
//  _general.swift
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
            assertionFailure("ERROR \(source)_safeSave: \(error)")
        }
    }

    @MainActor
    func safeDelete<Item: PersistentModel>(_ item: Item) {
        self.delete(item)
        self.safeSave("_general.safeDelete")
    }

    @MainActor
    func safeBulkDelete<Item: PersistentModel>(_ items: [Item]) {
        for item in items {
            self.delete(item)
        }
        self.safeSave("_general.safeBulkDelete")
    }

    @MainActor
    func insertIfNeeded<Item: PersistentModel>(_ item: Item) {
        guard item.modelContext == nil else { return }
        insert(item)
    }

}
