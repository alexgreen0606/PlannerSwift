//
//  PlannerCoverManager.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import Combine
import SwiftUI

// Clean

struct PlannerCoverContext: Identifiable, Equatable {
    let datestamp: String
    let source: String?

    init(datestamp: String, source: String? = nil) {
        self.datestamp = datestamp
        self.source = source
    }

    var id: String { source ?? datestamp }
}

@MainActor
final class PlannerCoverManager: ObservableObject {
    @Published var context: PlannerCoverContext?
}
