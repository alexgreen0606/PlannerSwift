//
//  PlannerCoverStore.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import Combine
import SwiftDate
import SwiftUI

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
