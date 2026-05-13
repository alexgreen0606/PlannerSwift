//
//  PlannerCoverStore.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import Combine
import SwiftDate
import SwiftUI

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
final class PlannerCoverStore: ObservableObject {
    @Published var context: PlannerCoverContext?
    @Published var isPresentingDefault: Bool = true
    @Published var todaystampAtInit: String

    init() {
        todaystampAtInit = DateInRegion(region: .local).toFormat(
            "yyyy-MM-dd",
            locale: Locale.current
        )
    }
}
