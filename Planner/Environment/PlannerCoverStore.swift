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
    init() {
        todaystampAtInit = DateInRegion(region: .local).toFormat(
            "yyyy-MM-dd",
            locale: Locale.current
        )
    }

    @Published var context: PlannerCoverContext?
    @Published var showTodayDefault: Bool = true

    /// Unlike the TodayService, this todaystamp will NOT change at midnight.
    @Published var todaystampAtInit: String
}
