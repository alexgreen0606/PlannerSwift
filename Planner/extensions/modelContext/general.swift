//
//  general.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import SwiftData

// Clean

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
        self.safeSave("general.safeDelete")
    }

}
