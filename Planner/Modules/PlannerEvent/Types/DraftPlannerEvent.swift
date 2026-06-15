//
//  DraftPlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import EventKit
import SwiftDate
import SwiftUI

struct DraftPlannerEvent: PlannerEventLocationHelpers {
    var title: String = ""
    var date: Date = .init()
    var hasTime: Bool = false
    var location: Location? = nil
    var ekEvent: EKEvent? = nil
}
