//
//  DraftTrip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftUI

struct DraftTrip {
    var title: String = ""
    var selectedDates: Set<DateComponents> = []
    var location: Location? = nil
    var excludeRoutines: Bool = true

    var datestamps: [String] {
        selectedDates.compactMap { $0.datestamp }
    }
}
