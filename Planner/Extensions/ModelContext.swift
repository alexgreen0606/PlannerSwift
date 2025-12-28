//
//  ModelContext.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import SwiftData

extension ModelContext {
    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) -> Planner {
        if let existing = planners.first {
            return existing
        }

        let planner = Planner(datestamp: datestamp)
        insert(planner)

        do {
            try save()
        } catch {
            assertionFailure("Failed to save Planner: \(error)")
        }

        return planner
    }
}
