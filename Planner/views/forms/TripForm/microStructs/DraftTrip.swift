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
    var hideRoutines: Bool = true
    var selectedDates: Set<DateComponents> = []
}
