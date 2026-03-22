//
//  DraftTrip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftUI

// Clean

struct DraftTrip {
    var title: String = ""
    var location: Location? = nil
    var startDate: Date
    var endDate: Date
    var hideRoutines: Bool = true

    init() {
        let now = Date()
        self.startDate = now
        self.endDate = now
    }

}
